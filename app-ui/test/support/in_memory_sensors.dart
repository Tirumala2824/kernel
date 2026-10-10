// Test-only sensor link and sensor repositories.

import 'dart:async';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'changes.dart';

SensorNode testNode({
  String? id,
  String name = 'Node A',
  SensorType type = SensorType.usAir,
  String? locationId,
  String? itemId,
  int? batteryPercent = 80,
}) {
  final now = DateTime(2026, 10, 1, 9);
  return SensorNode(
    id: id ?? testId('node'),
    deviceAddress: 'AA:BB:CC:DD:EE:01',
    name: name,
    type: type,
    protocolVersion: 1,
    firmwareVersion: '0.3.1',
    keyFingerprint: '1a2b3c4d',
    createdAt: now,
    updatedAt: now,
    syncState: SyncState.localOnly,
    locationId: locationId,
    itemId: itemId,
    batteryPercent: batteryPercent,
  );
}

SensorEvent testEvent(
  String nodeId,
  int seq, {
  required DateTime at,
  String? signatureId = 'mouse_usv',
  int durationMs = 120,
  SensorEventClass eventClass = SensorEventClass.fmSweep,
}) => SensorEvent(
  nodeId: nodeId,
  seq: seq,
  startedAt: at,
  durationMs: durationMs,
  eventClass: eventClass,
  peakHz: 62000,
  minHz: 55000,
  maxHz: 70000,
  slopeHzPerMs: -40,
  snrDb: 14,
  peakDbfs: -38,
  impulses: 0,
  repRateHz: 0,
  harmonics: 1,
  match: signatureId == null
      ? null
      : SignatureMatch(
          signatureId: signatureId,
          packVersion: 'sig-0.1',
          score: 0.71,
        ),
);

class ScriptedSensorLink implements SensorLink {
  SensorNode? associateResult;
  Object? associateError;
  final associatePayloads = <String>[];
  final forgotten = <String>[];
  final surveys = <(String, Duration)>[];
  final sessionsStarted = <String>[];
  final sessionsStopped = <String>[];
  final syncCalls = <String>[];

  /// Events [syncEvents] emits on [events] (and counts).
  List<SensorEvent> toSync = [];

  /// When set, startSurvey waits for it.
  Completer<void>? surveyGate;

  final _statusChanges = Changes();
  final _statuses = <String, SensorStatus>{};
  final _bandChanges = Changes();
  final _bands = <String, BandFrame>{};
  final _events = StreamController<SensorEvent>.broadcast(sync: true);

  void setStatus(SensorStatus status) {
    _statuses[status.nodeId] = status;
    _statusChanges.notify();
  }

  void setBands(BandFrame frame) {
    _bands[frame.nodeId] = frame;
    _bandChanges.notify();
  }

  void emitEvent(SensorEvent event) => _events.add(event);

  @override
  Future<SensorNode?> associate({required String qrPayload}) async {
    associatePayloads.add(qrPayload);
    final error = associateError;
    if (error != null) throw error;
    return associateResult;
  }

  @override
  Future<void> forget(String nodeId) async => forgotten.add(nodeId);

  @override
  Stream<SensorStatus> watchStatus(String nodeId) => _statusChanges
      .watch(() => _statuses[nodeId])
      .where((s) => s != null)
      .cast<SensorStatus>();

  @override
  Stream<BandFrame> liveBands(String nodeId) => _bandChanges
      .watch(() => _bands[nodeId])
      .where((f) => f != null)
      .cast<BandFrame>();

  @override
  Stream<SensorEvent> events() => _events.stream;

  @override
  Future<void> startSurvey(
    String nodeId, {
    Duration duration = const Duration(minutes: 5),
  }) async {
    surveys.add((nodeId, duration));
    await surveyGate?.future;
  }

  @override
  Future<void> startSession(String nodeId) async => sessionsStarted.add(nodeId);

  @override
  Future<void> stopSession(String nodeId) async => sessionsStopped.add(nodeId);

  @override
  Future<int> syncEvents(String nodeId) async {
    syncCalls.add(nodeId);
    final batch = [
      for (final e in toSync)
        if (e.nodeId == nodeId) e,
    ];
    batch.forEach(_events.add);
    return batch.length;
  }
}

class InMemorySensorNodeRepository implements SensorNodeRepository {
  final _changes = Changes();
  final _nodes = <String, SensorNode>{};
  final placements = <(String, SensorPlacement)>[];

  @override
  Future<SensorNode> upsert(SensorNode node) async {
    _nodes[node.id] = node;
    _changes.notify();
    return node;
  }

  @override
  Future<SensorNode?> get(String id) async => _nodes[id];

  @override
  Stream<List<SensorNode>> watchAll() =>
      _changes.watch(() => List.unmodifiable(_nodes.values));

  @override
  Future<SensorNode> setPlacement(String id, SensorPlacement placement) async {
    placements.add((id, placement));
    final n = _nodes[id]!;
    final placed = SensorNode(
      id: n.id,
      deviceAddress: n.deviceAddress,
      name: n.name,
      type: n.type,
      protocolVersion: n.protocolVersion,
      firmwareVersion: n.firmwareVersion,
      keyFingerprint: n.keyFingerprint,
      createdAt: n.createdAt,
      updatedAt: DateTime.now(),
      syncState: n.syncState,
      locationId: placement.locationId,
      itemId: placement.itemId,
      lastSeenAt: n.lastSeenAt,
      batteryPercent: n.batteryPercent,
    );
    _nodes[id] = placed;
    _changes.notify();
    return placed;
  }

  @override
  Future<void> delete(String id) async {
    _nodes.remove(id);
    _changes.notify();
  }

  SensorNode? operator [](String id) => _nodes[id];
}

class InMemorySensorEventRepository implements SensorEventRepository {
  InMemorySensorEventRepository(this.nodes);

  final InMemorySensorNodeRepository nodes;
  final _changes = Changes();
  final _events = <SensorEvent>[];

  List<SensorEvent> get all => List.unmodifiable(_events);

  @override
  Future<int> record(List<SensorEvent> events) async {
    var added = 0;
    for (final e in events) {
      if (_events.any((x) => x.nodeId == e.nodeId && x.seq == e.seq)) continue;
      _events.add(e);
      added++;
    }
    if (added > 0) _changes.notify();
    return added;
  }

  List<SensorEvent> _newestFirst(bool Function(SensorEvent) keep) =>
      [..._events.where(keep)]
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  bool _inWindow(SensorEvent e, Duration? window) =>
      window == null || e.startedAt.isAfter(DateTime.now().subtract(window));

  @override
  Stream<List<SensorEvent>> watchForNode(String nodeId, {int limit = 500}) =>
      _changes.watch(
        () => _newestFirst((e) => e.nodeId == nodeId).take(limit).toList(),
      );

  @override
  Stream<List<SensorEvent>> watchForLocation(
    String locationId, {
    Duration? window,
  }) => _changes.watch(
    () => _newestFirst(
      (e) => nodes[e.nodeId]?.locationId == locationId && _inWindow(e, window),
    ),
  );

  @override
  Stream<List<SensorEvent>> watchForItem(String itemId, {Duration? window}) =>
      _changes.watch(
        () => _newestFirst(
          (e) => nodes[e.nodeId]?.itemId == itemId && _inWindow(e, window),
        ),
      );

  @override
  Future<int?> lastSeq(String nodeId) async {
    final seqs = [
      for (final e in _events)
        if (e.nodeId == nodeId) e.seq,
    ];
    return seqs.isEmpty ? null : seqs.reduce((a, b) => a > b ? a : b);
  }
}
