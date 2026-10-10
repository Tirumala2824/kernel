import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sensor_link/sensor_link.dart';
import 'package:sensor_link/src/sensor_api.g.dart';

import 'vectors.dart';

/// Test double for the native host: records calls and replays node traffic
/// through the Flutter callbacks the way the Kotlin link does.
class RecordingHost extends SensorHostApi {
  RecordingHost() : super(binaryMessenger: null);

  final calls = <String>[];
  late SensorFlutterApi callbacks;
  NativeNodeInfo? associateResult;
  List<Uint8List> eventsToSend = [];
  String? startSessionError;

  @override
  Future<NativeNodeInfo?> associate(String qrPayload) async {
    calls.add('associate');
    return associateResult;
  }

  @override
  Future<void> connect(String nodeId) async => calls.add('connect $nodeId');

  @override
  Future<void> disconnect(String nodeId) async => calls.add('disconnect $nodeId');

  @override
  Future<void> setLiveBands(String nodeId, bool enabled) async => calls.add('liveBands $nodeId $enabled');

  @override
  Future<void> startSurvey(String nodeId, int durationS) async => calls.add('survey $nodeId $durationS');

  @override
  Future<void> startSession(String nodeId) async {
    calls.add('startSession $nodeId');
    if (startSessionError != null) throw PlatformException(code: startSessionError!);
  }

  @override
  Future<NativeSyncResult> syncEvents(String nodeId, int sinceSeq) async {
    calls.add('sync $nodeId $sinceSeq');
    for (final e in eventsToSend) {
      callbacks.onEvent(nodeId, e, DateTime.utc(2026, 1, 1).millisecondsSinceEpoch);
    }
    return NativeSyncResult(count: eventsToSend.length, lastSeq: sinceSeq + eventsToSend.length, oldestSeq: 1);
  }
}



void main() {
  final pack = SignaturePack.parse(packText());
  final protocolCases = (loadJson('protocol_v1.json')['cases'] as List).cast<Map<String, dynamic>>();
  Uint8List fixture(String name) => hex(protocolCases.firstWhere((c) => c['name'] == name)['hex'] as String);
  List<Uint8List> detectEvents(String scenario) => [
        for (final e in (loadJson('detect_$scenario.json')['events'] as List).cast<Map<String, dynamic>>())
          hex(e['hex'] as String),
      ];

  late RecordingHost host;
  late BleSensorLink link;
  final asked = <String>[];

  setUp(() {
    host = RecordingHost();
    asked.clear();
    link = BleSensorLink(
      lastSeqOf: (id) async {
        asked.add(id);
        return id == 'node-a' ? 41 : null;
      },
      pack: pack,
      host: host,
      registerCallbacks: false,
    );
    host.callbacks = link.callbacks;
  });

  test('syncEvents asks the injected lookup and emits matched events', () async {
    host.callbacks.onDeviceInfo('node-a', fixture('device_info_us_air'));
    host.eventsToSend = [...detectEvents('us_rat_22k'), ...detectEvents('us_rat_50k'), ...detectEvents('us_mouse_70k')];
    final got = <SensorEvent>[];
    final sub = link.events().listen(got.add);
    final n = await link.syncEvents('node-a');
    await Future<void>.delayed(Duration.zero);
    expect(asked, ['node-a']);
    expect(host.calls, ['sync node-a 41']);
    expect(n, 3);
    expect(got.map((e) => e.match?.signatureId), ['rat_22k', 'rat_50k', 'mouse_usv']);
    expect(got.every((e) => e.match!.experimental), isTrue);
    expect(got.first.startedAt, DateTime.utc(2026, 1, 1, 0, 0, 1, 519));
    await sub.cancel();
  });

  test('a node never synced starts from seq 0', () async {
    await link.syncEvents('node-b');
    expect(host.calls, ['sync node-b 0']);
  });

  test('the native lastSeq callback is the injected lookup', () async {
    expect(await host.callbacks.lastSeq('node-a'), 41);
    expect(await host.callbacks.lastSeq('node-z'), isNull);
  });

  test('contact events match only once the sensor type is known', () async {
    host.eventsToSend = detectEvents('contact_termite_15hz');
    final got = <SensorEvent>[];
    final sub = link.events().listen(got.add);
    await link.syncEvents('node-c');
    await Future<void>.delayed(Duration.zero);
    expect(got.single.match, isNull); // type unknown: unmatched, still reported
    final info = WireDeviceInfo.decode(fixture('device_info_us_air'));
    final contact = WireDeviceInfo(
      protoMajor: 1,
      protoMinor: 0,
      sensorType: 2,
      hwRev: info.hwRev,
      fwMajor: 0,
      fwMinor: 1,
      fwPatch: 0,
      nBands: 17,
      capabilities: info.capabilities,
      sampleRateHz: 48000,
      fftSize: 512,
      hopSize: 256,
      ringCapacity: 1920,
      cfgVersion: 1,
    );
    host.callbacks.onDeviceInfo('node-c', contact.encode());
    await link.syncEvents('node-c');
    await Future<void>.delayed(Duration.zero);
    expect(got.last.match?.signatureId, 'termite_drum');
    await sub.cancel();
  });

  test('untimed events from an earlier boot are skipped, not guessed', () async {
    host.eventsToSend = [fixture('event_untimed_saturated')];
    final got = <SensorEvent>[];
    final sub = link.events().listen(got.add);
    expect(await link.syncEvents('node-a'), 0);
    await Future<void>.delayed(Duration.zero);
    expect(got, isEmpty);
    expect(link.untimedSkipped('node-a'), 1);
    await sub.cancel();
  });

  test('watchStatus connects on demand and maps jammed/clipped health', () async {
    final seen = <SensorStatus>[];
    final sub = link.watchStatus('node-a').listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    expect(host.calls, ['connect node-a']);
    host.callbacks.onLinkState('node-a', NativeLinkState.authenticated, -61, false);
    host.callbacks.onStatus('node-a', fixture('status_jammed_clipped'), 0);
    await Future<void>.delayed(Duration.zero);
    final last = seen.last;
    expect(last.linkState, SensorLinkState.authenticated);
    expect(last.health, {SensorHealth.jammed, SensorHealth.clipped});
    expect(isEvaluated(last.health), isFalse);
    expect(last.rssi, -61);
    expect(last.batteryPercent, 50);

    host.callbacks.onStatus('node-a', fixture('status_fault_unknown_batt'), 0);
    await Future<void>.delayed(Duration.zero);
    expect(seen.last.linkState, SensorLinkState.error);
    expect(seen.last.health.contains(SensorHealth.ok), isFalse);

    host.callbacks.onLinkState('node-a', NativeLinkState.error, null, true);
    await Future<void>.delayed(Duration.zero);
    expect(seen.last.health, contains(SensorHealth.authFailed));
    await sub.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(host.calls.last, 'disconnect node-a');
  });

  test('liveBands subscribes and maps frames with the band table', () async {
    host.callbacks.onBandTable('node-a', fixture('band_table_us_air'));
    final frames = <BandFrame>[];
    final sub = link.liveBands('node-a').listen(frames.add);
    await Future<void>.delayed(Duration.zero);
    host.callbacks.onBandFrame('node-a', fixture('band_frame_us_rat_22k'));
    host.callbacks.onBandFrame('node-a', fixture('band_frame_24_bands_jammed')); // band count mismatch: dropped
    await Future<void>.delayed(Duration.zero);
    expect(frames, hasLength(1));
    expect(frames.single.bandEdgesHz, hasLength(19));
    await sub.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(host.calls, ['liveBands node-a true', 'liveBands node-a false', 'disconnect node-a']);
  });

  test('associate validates the QR before the native call and maps cancel to null', () async {
    expect(() => link.associate(qrPayload: 'kernel:sensor:v2:x'), throwsA(isA<SensorQrFormatException>()));
    expect(host.calls, isEmpty);
    final payload = ((loadJson('qr_v1.json')['valid'] as List).first as Map<String, dynamic>)['payload'] as String;
    expect(await link.associate(qrPayload: payload), isNull);
    host.associateResult = NativeNodeInfo(
      nodeId: 'node-q',
      address: 'C0:FF:EE:12:34:56',
      name: 'Kernel-3456',
      sensorType: 1,
      keyFingerprint: '630dcd29',
      protocolVersion: 1,
      firmwareVersion: '0.1.0',
    );
    final paired = await link.associate(qrPayload: payload);
    expect(paired!.type, SensorType.usAir);
    expect(paired.keyFingerprint, '630dcd29');
    expect(paired.syncState, SyncState.localOnly);
  });

  test('sessions refuse to start in the background', () async {
    host.startSessionError = 'not_visible';
    expect(() => link.startSession('node-a'), throwsA(isA<SensorSessionException>()));
    host.startSessionError = 'link';
    await link.startSession('node-a'); // radio failure: reported via status, not thrown
    await link.startSurvey('node-a', duration: const Duration(seconds: 5));
    expect(host.calls.last, 'survey node-a 30');
  });
}
