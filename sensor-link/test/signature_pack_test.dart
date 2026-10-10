import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sensor_link/sensor_link.dart';

import 'vectors.dart';

void main() {
  final pack = SignaturePack.parse(packText());

  group('pack file', () {
    test('is versioned, experimental and complete', () {
      expect(pack.id, 'kernel-sensor-signatures');
      expect(pack.version, '0.1.0');
      expect(pack.protocol, 1);
      expect(pack.experimental, isTrue);
      expect(pack.rules.map((r) => r.id), [
        'mouse_usv',
        'rat_22k',
        'rat_50k',
        'grain_larva',
        'termite_drum',
        'mosquito_wingbeat',
        'cricket_chirp',
      ]);
      for (final r in pack.rules) {
        expect(r.source, isNotEmpty);
        expect(r.minHz, lessThan(r.maxHz));
      }
      final larva = pack.rule('grain_larva')!;
      expect(larva.possibleRatePerS, 0.02);
      expect(larva.minWindowS, 180);
      expect(pack.rule('termite_drum')!.regular, RegularRule.required);
    });

    test('rejects unknown keys', () {
      expect(() => SignaturePack.parse('${packText()}\nsig.mouse_usv.confidence=0.9\n'), throwsFormatException);
      expect(() => SignaturePack.parse('${packText()}\npack.author=x\n'), throwsFormatException);
      expect(() => SignaturePack.parse('${packText()}\nsig.unlisted.minHz=1\n'), throwsFormatException);
    });

    test('rejects a pack not marked experimental', () {
      expect(() => SignaturePack.parse(packText().replaceFirst('pack.experimental=true', 'pack.experimental=false')),
          throwsFormatException);
      expect(() => SignaturePack.parse(packText().replaceFirst('pack.experimental=true\n', '')), throwsFormatException);
    });

    test('rejects malformed rules', () {
      expect(() => SignaturePack.parse(packText().replaceFirst('sig.rat_22k.minHz=18000', 'sig.rat_22k.minHz=x')),
          throwsFormatException);
      expect(() => SignaturePack.parse(packText().replaceFirst('sig.rat_22k.classes=flatTone,tonal', 'sig.rat_22k.classes=squeak')),
          throwsFormatException);
      expect(() => SignaturePack.parse(packText().replaceFirst('sig.termite_drum.regular=required', 'sig.termite_drum.regular=often')),
          throwsFormatException);
      expect(() => SignaturePack.parse(packText().replaceFirst('pack.protocol=1', 'pack.protocol=2')), throwsFormatException);
      expect(() => SignaturePack.parse('${packText()}\npack.id=again\n'), throwsFormatException);
    });
  });

  group('matching the firmware/reference vectors', () {
    for (final file in detectFiles()) {
      final v = loadFile(file);
      test(v['scenario'], () {
        final type = SensorType.values.byName(v['sensorTypeName'] as String);
        final expectSig = (v['expect'] as Map<String, dynamic>)['signature'] as String?;
        final events = (v['events'] as List).cast<Map<String, dynamic>>();
        if (expectSig == null) {
          // White noise, repellers and clipping: the node emits nothing to match.
          expect(events, isEmpty);
          return;
        }
        expect(events, isNotEmpty);
        for (final e in events) {
          final m = pack.match(WireEvent.decode(hex(e['hex'] as String)), type);
          expect(m, isNotNull, reason: '${e['className']} should match');
          expect(m!.signatureId, expectSig);
          expect(m.experimental, isTrue);
          expect(m.packVersion, '0.1.0');
          expect(m.score, inInclusiveRange(0.5, 1.0));
        }
      });
    }
  });

  group('gates', () {
    WireEvent ev({
      int cls = 1,
      int peak = 5400,
      int min = 4600,
      int max = 5700,
      int dur = 40,
      int flags = 1,
      int imp = 0,
      int rep = 0,
      int harm = 0,
    }) =>
        WireEvent(
          seq: 1,
          tStartS: 0,
          tStartMs: 0,
          durationMs: dur,
          eventClass: cls,
          flags: flags,
          peakHz10: peak,
          minHz10: min,
          maxHz10: max,
          slopeDHzPerMs: 0,
          snrHalfDb: 40,
          peakDbfs: -50,
          impulses: imp,
          harmonics: harm,
          repRateCHz: rep,
          ipiCvPct: 255,
          bootLow: 0,
        );

    test('sensor type gates the rule', () {
      expect(pack.match(ev(), SensorType.usAir)?.signatureId, 'rat_50k');
      expect(pack.match(ev(), SensorType.contactPiezo), isNull);
      expect(pack.match(ev(), SensorType.audioAir), isNull);
    });

    test('frequency, duration and class gates', () {
      expect(pack.match(ev(peak: 9500, min: 9000, max: 10000), SensorType.usAir)?.signatureId, 'mouse_usv'); // 90-100 kHz: mouse only
      expect(pack.match(ev(max: 12000), SensorType.usAir), isNull); // above 110 kHz
      expect(pack.match(ev(dur: 400), SensorType.usAir), isNull); // too long for USV/50k, not flat
      expect(pack.match(ev(cls: 3), SensorType.usAir), isNull); // impulse burst on an air node
    });

    test('termite needs a regular train in 10-26 Hz', () {
      final regular = ev(cls: 3, peak: 284, min: 225, max: 340, dur: 735, flags: 3, imp: 12, rep: 1500);
      expect(pack.match(regular, SensorType.contactPiezo)?.signatureId, 'termite_drum');
      final irregular = ev(cls: 3, peak: 284, min: 225, max: 340, dur: 735, flags: 1, imp: 12, rep: 1500);
      expect(pack.match(irregular, SensorType.contactPiezo)?.signatureId, 'grain_larva');
      final tooFast = ev(cls: 3, peak: 284, min: 225, max: 340, dur: 300, flags: 3, imp: 12, rep: 4000);
      expect(pack.match(tooFast, SensorType.contactPiezo)?.signatureId, 'grain_larva');
      expect(pack.match(ev(cls: 3, peak: 284, min: 225, max: 340, imp: 2), SensorType.contactPiezo), isNull);
    });

    test('unknown event class never matches', () {
      expect(pack.match(ev(cls: 9), SensorType.usAir), isNull);
    });
  });

  group('rates', () {
    test('Mankin bursts: 6 in 3 minutes is possible', () {
      final v = loadJson('detect_contact_larva_bursts.json');
      final count = (v['events'] as List).length;
      final window = Duration(seconds: ((v['rate'] as Map<String, dynamic>)['windowS'] as num).round());
      final r = pack.assessRate('grain_larva', count: count, window: window);
      expect(r.level, RateLevel.possible);
      expect(r.summary, '6 events in 3 minutes');
      expect(r.perSecond, closeTo(6 / 180, 1e-9));
      expect(r.packVersion, '0.1.0');
    });

    test('below threshold, short window and not-evaluated windows', () {
      expect(pack.assessRate('grain_larva', count: 2, window: const Duration(minutes: 10)).level, RateLevel.belowThreshold);
      expect(pack.assessRate('grain_larva', count: 6, window: const Duration(minutes: 1)).level, RateLevel.notEvaluated);
      expect(pack.assessRate('grain_larva', count: 9, window: const Duration(minutes: 5), notEvaluated: true).level,
          RateLevel.notEvaluated);
      expect(pack.assessRate('mouse_usv', count: 3, window: const Duration(minutes: 5)).level, isNull);
      expect(() => pack.assessRate('nope', count: 1, window: const Duration(minutes: 5)), throwsArgumentError);
      expect(rateSummary(1, const Duration(minutes: 1)), '1 event in 1 minute');
    });
  });
}
