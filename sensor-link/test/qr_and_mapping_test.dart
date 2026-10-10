import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sensor_link/sensor_link.dart';

import 'vectors.dart';

void main() {
  group('QR labels (qr_v1.json)', () {
    final qr = loadJson('qr_v1.json');
    for (final v in (qr['valid'] as List).cast<Map<String, dynamic>>()) {
      test('valid ${(v['payload'] as String).substring(0, 30)}', () {
        final (label, key) = SensorQrLabel.parseWithKey(v['payload'] as String);
        expect(label.address, v['address']);
        expect(toHex(key), v['keyHex']);
        expect(label.keyLength, 32);
        expect(label.type, SensorType.values.byName(v['sensorType'] as String));
      });
    }
    for (final v in (qr['invalid'] as List).cast<Map<String, dynamic>>()) {
      test('invalid ${v['reason']}', () {
        expect(
          () => SensorQrLabel.parse(v['payload'] as String),
          throwsA(isA<SensorQrFormatException>().having((e) => e.reason, 'reason', v['reason'])),
        );
      });
    }
  });

  group('health mapping', () {
    final statuses = {
      for (final c in (loadJson('protocol_v1.json')['cases'] as List).cast<Map<String, dynamic>>())
        if (c['kind'] == 'status') c['name'] as String: WireStatus.decode(hex(c['hex'] as String)),
    };

    test('jammed and clipped are not evaluated', () {
      final h = healthFromBits(statuses['status_jammed_clipped']!.health);
      expect(h, {SensorHealth.jammed, SensorHealth.clipped});
      expect(isEvaluated(h), isFalse);
      expect(bitsNotEvaluated(statuses['status_jammed_clipped']!.health), isTrue);
    });

    test('survey needed or running is not evaluated; low battery is reported', () {
      final h = healthFromBits(statuses['status_survey_low_batt']!.health);
      expect(h, {SensorHealth.surveyNeeded, SensorHealth.lowBattery});
      expect(isEvaluated(h), isFalse);
      expect(isEvaluated(healthFromBits(HealthBits.surveyActive)), isFalse);
      expect(statuses['status_survey_low_batt']!.batteryPercent, 9);
    });

    test('ok only when nothing applies', () {
      final h = healthFromBits(statuses['status_ok_session']!.health);
      expect(h, {SensorHealth.ok});
      expect(isEvaluated(h), isTrue);
      expect(isEvaluated(healthFromBits(HealthBits.lowBattery)), isTrue);
    });

    test('a sensor fault never reads as ok', () {
      final s = statuses['status_fault_unknown_batt']!;
      final h = healthFromBits(s.health);
      expect(h.contains(SensorHealth.ok), isFalse);
      expect(isEvaluated(h), isFalse);
      expect(bitsNotEvaluated(s.health), isTrue);
      expect(s.batteryPercent, isNull);
    });

    test('auth failure is not evaluated', () {
      final h = healthFromBits(0, authFailed: true);
      expect(h, {SensorHealth.authFailed});
      expect(isEvaluated(h), isFalse);
    });
  });

  group('time mapping', () {
    test('epoch timestamps are used as-is', () {
      final t = nodeTime(timeValid: true, tStartS: 1767225601, tStartMs: 501, bootLow: 7);
      expect(t, DateTime.utc(2026, 1, 1, 0, 0, 1, 501));
    });

    test('uptime timestamps resolve only within the same boot', () {
      final clock = NodeClock(bootCount: 0x0107, uptimeS: 1000, receivedAt: DateTime.utc(2026, 3, 1, 12));
      expect(nodeTime(timeValid: false, tStartS: 900, tStartMs: 0, bootLow: 0x07, clock: clock), DateTime.utc(2026, 3, 1, 11, 58, 20));
      expect(nodeTime(timeValid: false, tStartS: 900, tStartMs: 0, bootLow: 0x06, clock: clock), isNull);
      expect(nodeTime(timeValid: false, tStartS: 900, tStartMs: 0, bootLow: 0x07), isNull);
      expect(nodeTime(timeValid: false, tStartS: 2000, tStartMs: 0, bootLow: 0x07, clock: clock), isNull);
    });

    test('events and band frames map to contracts types', () {
      final v = loadJson('detect_us_rat_22k.json');
      final w = WireEvent.decode(hex(((v['events'] as List).first as Map<String, dynamic>)['hex'] as String));
      final e = toSensorEvent('node-1', w)!;
      expect(e.seq, 1);
      expect(e.eventClass, SensorEventClass.flatTone);
      expect(e.peakHz, w.peakHz10 * 10.0);
      expect(e.snrDb, w.snrHalfDb / 2);
      expect(e.match, isNull);
      expect(sensorTypeFromWire(sensorTypeToWire(SensorType.contactAccel)), SensorType.contactAccel);
      expect(sensorTypeFromWire(9), isNull);

      final cases = (loadJson('protocol_v1.json')['cases'] as List).cast<Map<String, dynamic>>();
      final table = WireBandTable.decode(hex(cases.firstWhere((c) => c['name'] == 'band_table_us_air')['hex'] as String));
      final frame = WireBandFrame.decode(hex(cases.firstWhere((c) => c['name'] == 'band_frame_us_rat_22k')['hex'] as String));
      final bf = toBandFrame('node-1', frame, table, receivedAt: DateTime.utc(2026));
      expect(bf.bandEdgesHz.length, bf.bandsDbAboveFloor.length + 1);
      expect(bf.bandEdgesHz.first, 20000);
      expect(bf.bandEdgesHz.last, 92000);
      expect(bf.noiseFloorDbfs, frame.noiseFloorDeciDbfs / 10);
      final wrong = WireBandTable([2000, 2400]);
      expect(() => toBandFrame('node-1', frame, wrong, receivedAt: DateTime.utc(2026)), throwsA(isA<ProtocolException>()));
    });
  });
}
