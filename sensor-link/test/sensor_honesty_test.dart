import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sensor_link/sensor_link.dart';
import 'package:sensor_link/src/sensor_api.g.dart';

import 'ble_sensor_link_test.dart' show RecordingHost;
import 'vectors.dart';

WireStatus statusWith(int health) => WireStatus(
  health: health,
  battPct: 80,
  battMv: 3900,
  lastSeq: 0,
  oldestSeq: 1,
  uptimeS: 100,
  bootCount: 1,
  surveyRemainingS: 0,
);

Future<void> flushCallbacks() => Future<void>.delayed(Duration.zero);

class FailingHost extends RecordingHost {
  PlatformException? syncError;
  PlatformException? stopError;

  @override
  Future<NativeSyncResult> syncEvents(String nodeId, int sinceSeq) async {
    final result = await super.syncEvents(nodeId, sinceSeq);
    if (syncError != null) throw syncError!;
    return result;
  }

  @override
  Future<void> stopSession(String nodeId) async {
    calls.add('stopSession $nodeId');
    if (stopError != null) throw stopError!;
  }
}

void main() {
  test('reported health changes are emitted without inventing history', () async {
    final host = RecordingHost();
    final link = BleSensorLink(
      lastSeqOf: (_) async => null,
      host: host,
      pack: SignaturePack.parse(packText()),
      registerCallbacks: false,
    );
    host.callbacks = link.callbacks;
    final changes = <SensorHealthChange>[];
    final sub = link.healthChanges().listen(changes.add);
    addTearDown(sub.cancel);
    expect(changes, isEmpty);
    host.callbacks.onStatus('node', statusWith(HealthBits.jammed).encode(), 1000);
    host.callbacks.onStatus('node', statusWith(HealthBits.jammed).encode(), 1100);
    host.callbacks.onStatus('node', statusWith(0).encode(), 2000);
    await flushCallbacks();
    expect(changes, hasLength(2));
    expect(changes.first.health, {SensorHealth.jammed});
    expect(changes.first.at, DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true));
    expect(changes.last.health, {SensorHealth.ok});
  });

  test('fault and overwritten flags are explicit not-evaluated health', () {
    final health = healthFromBits(HealthBits.sensorFault | HealthBits.eventsOverwritten);
    expect(health, {SensorHealth.sensorFault, SensorHealth.eventsOverwritten});
    expect(isEvaluated(health), isFalse);
    expect(bitsNotEvaluated(HealthBits.eventsOverwritten), isTrue);
  });

  test('command failures are not returned as successful empty syncs or sessions', () async {
    final host = FailingHost();
    final link = BleSensorLink(
      lastSeqOf: (_) async => null,
      host: host,
      pack: SignaturePack.parse(packText()),
      registerCallbacks: false,
    );
    host.callbacks = link.callbacks;
    expect(await link.syncEvents('node'), 0, reason: 'a real successful empty sync');
    host.syncError = PlatformException(code: 'link');
    await expectLater(link.syncEvents('node'), throwsA(isA<PlatformException>()));
    host.startSessionError = 'fgs_not_allowed';
    await expectLater(link.startSession('node'), throwsA(isA<SensorSessionException>()));
    host.stopError = PlatformException(code: 'link');
    await expectLater(link.stopSession('node'), throwsA(isA<SensorSessionException>()));
  });

  test('session activity comes only from fresh authenticated telemetry', () async {
    final host = RecordingHost();
    final link = BleSensorLink(
      lastSeqOf: (_) async => null,
      host: host,
      pack: SignaturePack.parse(packText()),
      registerCallbacks: false,
    );
    host.callbacks = link.callbacks;
    final seen = <SensorStatus>[];
    final sub = link.watchStatus('node').listen(seen.add);
    addTearDown(sub.cancel);
    await flushCallbacks();
    await link.startSession('node');
    expect(seen.last.sessionActive, isFalse);
    host.callbacks.onLinkState('node', NativeLinkState.authenticated, -50, false);
    host.callbacks.onStatus('node', statusWith(HealthBits.sessionActive).encode(), 1000);
    await flushCallbacks();
    expect(seen.last.sessionActive, isTrue);
    host.callbacks.onStatus('node', statusWith(0).encode(), 2000);
    await flushCallbacks();
    expect(seen.last.sessionActive, isFalse);
    host.callbacks.onStatus('node', statusWith(HealthBits.sessionActive).encode(), 3000);
    host.callbacks.onLinkState('node', NativeLinkState.disconnected, null, false);
    await flushCallbacks();
    expect(seen.last.sessionActive, isFalse);
    expect(seen.last.notEvaluated, isTrue);
    host.callbacks.onLinkState('node', NativeLinkState.authenticated, -50, false);
    await flushCallbacks();
    expect(seen.last.sessionActive, isFalse, reason: 'old telemetry is not a fresh confirmation');
  });
}
