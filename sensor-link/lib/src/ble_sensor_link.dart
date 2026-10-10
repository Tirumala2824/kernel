import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:kernel_contracts/kernel_contracts.dart';

import 'mapping.dart';
import 'protocol.dart';
import 'qr.dart';
import 'sensor_api.g.dart';
import 'signature_pack.dart';
import 'snippet.dart';

/// Looks up the latest persisted event seq for a node (for GET_EVENTS_SINCE).
/// The lead wires this to `SensorEventRepository.lastSeq`.
typedef LastSeqLookup = Future<int?> Function(String nodeId);

/// Thrown by [BleSensorLink.startSession] when the app is not in the
/// foreground: the connectedDevice service may only start while visible.
class SensorSessionException implements Exception {
  SensorSessionException(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() => 'SensorSessionException($code${message == null ? '' : ': $message'})';
}

class _Node {
  _Node(this.id);
  final String id;
  NativeLinkState link = NativeLinkState.disconnected;
  int? rssi;
  bool authFailed = false;
  WireStatus? status;
  NodeClock? clock;
  WireBandTable? table;
  WireDeviceInfo? info;
  SensorType? type;
  int watchers = 0;
  int bandListeners = 0;
  int syncEmitted = 0;
  int untimedSkipped = 0;
  final statusCtl = StreamController<SensorStatus>.broadcast();
  final bandsCtl = StreamController<BandFrame>.broadcast();
}

/// [SensorLink] over BLE: native Kotlin (CompanionDeviceManager, GATT,
/// Android Keystore HMAC auth, connectedDevice foreground service) behind
/// Pigeon, with protocol decoding, time mapping and experimental signature
/// matching here. Radio problems never throw from the streams; they appear
/// in [watchStatus]. No network code; no audio crosses the bridge.
class BleSensorLink implements SensorLink {
  BleSensorLink({
    required this.lastSeqOf,
    SignaturePack? pack,
    SensorHostApi? host,
    DateTime Function()? now,
    bool registerCallbacks = true,
  })  : _host = host ?? SensorHostApi(),
        _now = now ?? DateTime.now,
        _pack = pack != null ? Future.value(pack) : SignaturePack.load() {
    _callbacks = _Callbacks(this);
    if (registerCallbacks) SensorFlutterApi.setUp(_callbacks);
  }

  /// Injected persisted-seq lookup (see [LastSeqLookup]).
  final LastSeqLookup lastSeqOf;
  final SensorHostApi _host;
  final DateTime Function() _now;
  final Future<SignaturePack> _pack;
  late final _Callbacks _callbacks;
  SignaturePack? _loadedPack;
  final _nodes = <String, _Node>{};
  final _events = StreamController<SensorEvent>.broadcast();
  final _healthChanges = StreamController<SensorHealthChange>.broadcast();

  /// Native callbacks; exposed so tests can drive the link without a device.
  @visibleForTesting
  SensorFlutterApi get callbacks => _callbacks;

  _Node _node(String id) => _nodes.putIfAbsent(id, () => _Node(id));

  Future<SignaturePack> get signaturePack => _pack;

  // ------------------------------------------------------------- pairing

  @override
  Future<SensorNode?> associate({required String qrPayload}) async {
    final label = SensorQrLabel.parse(qrPayload); // FormatException on a bad label
    final NativeNodeInfo? info;
    try {
      info = await _host.associate(qrPayload);
    } on PlatformException catch (e) {
      if (e.code == 'invalid_qr') throw SensorQrFormatException(e.message ?? 'native');
      rethrow;
    }
    if (info == null) return null;
    final n = _node(info.nodeId)..type = sensorTypeFromWire(info.sensorType) ?? label.type;
    final at = _now();
    return SensorNode(
      id: info.nodeId,
      deviceAddress: info.address,
      name: info.name,
      type: n.type!,
      protocolVersion: info.protocolVersion,
      firmwareVersion: info.firmwareVersion ?? 'unknown',
      keyFingerprint: info.keyFingerprint,
      createdAt: at,
      updatedAt: at,
      syncState: SyncState.localOnly,
    );
  }

  /// Nodes whose keys are in Android Keystore (for reconciling with the DB).
  Future<List<NativeNodeInfo>> knownNodes() => _host.knownNodes();

  @override
  Future<void> forget(String nodeId) async {
    await _host.forget(nodeId);
    final n = _nodes.remove(nodeId);
    if (n != null) {
      n.link = NativeLinkState.unpaired;
      n.statusCtl.add(_statusOf(n));
      await n.statusCtl.close();
      await n.bandsCtl.close();
    }
  }

  // ------------------------------------------------------------- streams

  SensorStatus _statusOf(_Node n) {
    final bits = n.status?.health ?? 0;
    final health = n.status == null
        ? (n.authFailed ? {SensorHealth.authFailed} : <SensorHealth>{})
        : healthFromBits(bits, authFailed: n.authFailed);
    var link = switch (n.link) {
      NativeLinkState.unpaired => SensorLinkState.unpaired,
      NativeLinkState.pairing => SensorLinkState.pairing,
      NativeLinkState.connecting => SensorLinkState.connecting,
      NativeLinkState.connected => SensorLinkState.connected,
      NativeLinkState.authenticated => SensorLinkState.authenticated,
      NativeLinkState.disconnected => SensorLinkState.disconnected,
      NativeLinkState.error => SensorLinkState.error,
    };
    // A sensor fault has no SensorHealth value; surface it as a link error.
    if (bits & HealthBits.sensorFault != 0 && link == SensorLinkState.authenticated) link = SensorLinkState.error;
    return SensorStatus(
      nodeId: n.id,
      linkState: link,
      health: health,
      batteryPercent: n.status?.batteryPercent,
      rssi: n.rssi,
    );
  }

  void _emitStatus(_Node n) {
    if (!n.statusCtl.isClosed) n.statusCtl.add(_statusOf(n));
  }

  Future<void> _quiet(Future<void> Function() f) async {
    try {
      await f();
    } on PlatformException {
      // Radio problems are reported through watchStatus (onLinkState).
    }
  }

  void _releaseIfIdle(_Node n) {
    if (n.watchers == 0 && n.bandListeners == 0) unawaited(_quiet(() => _host.disconnect(n.id)));
  }

  @override
  Stream<SensorStatus> watchStatus(String nodeId) {
    final n = _node(nodeId);
    late final StreamController<SensorStatus> out;
    StreamSubscription<SensorStatus>? sub;
    out = StreamController<SensorStatus>(
      onListen: () {
        n.watchers++;
        out.add(_statusOf(n));
        sub = n.statusCtl.stream.listen(out.add);
        unawaited(_quiet(() => _host.connect(nodeId)));
      },
      onCancel: () async {
        n.watchers--;
        await sub?.cancel();
        _releaseIfIdle(n);
      },
    );
    return out.stream;
  }

  @override
  Stream<BandFrame> liveBands(String nodeId) {
    final n = _node(nodeId);
    late final StreamController<BandFrame> out;
    StreamSubscription<BandFrame>? sub;
    out = StreamController<BandFrame>(
      onListen: () {
        n.bandListeners++;
        sub = n.bandsCtl.stream.listen(out.add);
        unawaited(_quiet(() => _host.setLiveBands(nodeId, true)));
      },
      onCancel: () async {
        n.bandListeners--;
        await sub?.cancel();
        if (n.bandListeners == 0) await _quiet(() => _host.setLiveBands(nodeId, false));
        _releaseIfIdle(n);
      },
    );
    return out.stream;
  }

  @override
  Stream<SensorEvent> events() => _events.stream;

  @override
  Stream<SensorHealthChange> healthChanges() => _healthChanges.stream;

  // ---------------------------------------------------------- procedures

  @override
  Future<void> startSurvey(String nodeId, {Duration duration = const Duration(minutes: 5)}) =>
      _quiet(() => _host.startSurvey(nodeId, duration.inSeconds.clamp(30, 3600)));

  @override
  Future<void> startSession(String nodeId) async {
    try {
      await _host.startSession(nodeId);
    } on PlatformException catch (e) {
      if (e.code == 'not_visible') throw SensorSessionException(e.code, e.message);
      // Other failures: the session keeps retrying natively; state via watchStatus.
    }
  }

  @override
  Future<void> stopSession(String nodeId) => _quiet(() => _host.stopSession(nodeId));

  /// Pulls store-and-forward events after the injected lastSeq. Returns how
  /// many SensorEvents were emitted on [events] (0 when the node is out of reach).
  @override
  Future<int> syncEvents(String nodeId) async {
    final n = _node(nodeId);
    final since = await lastSeqOf(nodeId) ?? 0;
    final before = n.syncEmitted;
    try {
      await _host.syncEvents(nodeId, since);
    } on PlatformException {
      // Out of reach or refused: whatever arrived before the failure still counts.
    }
    await _callbacks.drained;
    return n.syncEmitted - before;
  }

  /// Events skipped because the node clock could not place them in time.
  int untimedSkipped(String nodeId) => _node(nodeId).untimedSkipped;

  /// Spectrogram tiles for one event, on explicit user request only. Memory
  /// only: callers must not persist or upload it. Null if the node no longer has it.
  Future<SensorSnippet?> requestSnippet(String nodeId, int eventSeq) async {
    final s = await _host.requestSnippet(nodeId, eventSeq);
    if (s == null) return null;
    return SensorSnippet.fromWire(s.meta, s.tiles);
  }

  Future<void> dispose() async {
    SensorFlutterApi.setUp(null);
    await _events.close();
    await _healthChanges.close();
    for (final n in _nodes.values) {
      await n.statusCtl.close();
      await n.bandsCtl.close();
    }
  }

  // ----------------------------------------------------- native callbacks

  void _onLinkState(String nodeId, NativeLinkState state, int? rssi, bool authFailed) {
    final n = _node(nodeId);
    n.link = state;
    if (rssi != null) n.rssi = rssi;
    if (authFailed) n.authFailed = true;
    if (state == NativeLinkState.authenticated) n.authFailed = false;
    _emitStatus(n);
  }

  void _onDeviceInfo(String nodeId, Uint8List bytes) {
    try {
      final info = WireDeviceInfo.decode(bytes);
      final n = _node(nodeId)
        ..info = info
        ..type = sensorTypeFromWire(info.sensorType) ?? _node(nodeId).type;
      _emitStatus(n);
    } on ProtocolException {
      // ignored: malformed characteristic value
    }
  }

  void _onBandTable(String nodeId, Uint8List bytes) {
    try {
      _node(nodeId).table = WireBandTable.decode(bytes);
    } on ProtocolException {
      // ignored
    }
  }

  void _onStatus(String nodeId, Uint8List bytes, int receivedAtMs) {
    try {
      final s = WireStatus.decode(bytes);
      final n = _node(nodeId)
        ..status = s
        ..clock = NodeClock(
          bootCount: s.bootCount,
          uptimeS: s.uptimeS,
          receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtMs, isUtc: true),
        );
      _emitStatus(n);
    } on ProtocolException {
      // ignored
    }
  }

  void _onBandFrame(String nodeId, Uint8List bytes) {
    final n = _node(nodeId);
    final table = n.table;
    if (table == null || n.bandsCtl.isClosed) return;
    try {
      n.bandsCtl.add(toBandFrame(nodeId, WireBandFrame.decode(bytes), table, receivedAt: _now()));
    } on ProtocolException {
      // ignored
    }
  }

  Future<void> _onEvent(String nodeId, Uint8List bytes, int receivedAtMs) async {
    final n = _node(nodeId);
    final WireEvent wire;
    try {
      wire = WireEvent.decode(bytes);
    } on ProtocolException {
      return;
    }
    SignaturePack? pack;
    try {
      pack = _loadedPack ??= await _pack;
    } catch (_) {
      pack = null; // no pack: events are still reported, just unmatched
    }
    final type = n.type;
    final match = (type == null || pack == null) ? null : pack.match(wire, type);
    final ev = toSensorEvent(nodeId, wire, clock: n.clock, match: match);
    if (ev == null) {
      n.untimedSkipped++;
      return;
    }
    n.syncEmitted++;
    if (!_events.isClosed) _events.add(ev);
  }
}

class _Callbacks extends SensorFlutterApi {
  _Callbacks(this._l);
  final BleSensorLink _l;

  // Events are decoded in arrival order; the pack future resolves once.
  Future<void> _chain = Future.value();

  @override
  void onLinkState(String nodeId, NativeLinkState state, int? rssi, bool authFailed) =>
      _l._onLinkState(nodeId, state, rssi, authFailed);

  @override
  void onDeviceInfo(String nodeId, Uint8List bytes) => _l._onDeviceInfo(nodeId, bytes);

  @override
  void onBandTable(String nodeId, Uint8List bytes) => _l._onBandTable(nodeId, bytes);

  @override
  void onStatus(String nodeId, Uint8List bytes, int receivedAtMs) => _l._onStatus(nodeId, bytes, receivedAtMs);

  @override
  void onBandFrame(String nodeId, Uint8List bytes) => _l._onBandFrame(nodeId, bytes);

  @override
  void onEvent(String nodeId, Uint8List bytes, int receivedAtMs) {
    _chain = _chain.then((_) => _l._onEvent(nodeId, bytes, receivedAtMs));
  }

  /// Completes after every event delivered so far has been emitted.
  Future<void> get drained => _chain;

  @override
  Future<int?> lastSeq(String nodeId) => _l.lastSeqOf(nodeId);
}
