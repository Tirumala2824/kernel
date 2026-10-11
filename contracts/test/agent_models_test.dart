import 'dart:typed_data';

import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('Tokenization and Vector Helpers', () {
    test('tokenizeText extracts clean tokens and filters stop words', () {
      final tokens = tokenizeText(
        'The insect with high frequency sound in sack LOT-024',
      );
      expect(
        tokens,
        containsAll([
          'insect',
          'high',
          'frequency',
          'sound',
          'sack',
          'lot',
          '024',
        ]),
      );
      expect(tokens, isNot(contains('the')));
      expect(tokens, isNot(contains('with')));
      expect(tokens, isNot(contains('in')));
    });

    test('cosineSimilarityFloat32 correctly calculates dot product of normalized vectors', () {
      final a = Float32List.fromList([1.0, 0.0, 0.0]);
      final b = Float32List.fromList([1.0, 0.0, 0.0]);
      final c = Float32List.fromList([0.0, 1.0, 0.0]);
      expect(cosineSimilarityFloat32(a, b), closeTo(1.0, 1e-5));
      expect(cosineSimilarityFloat32(a, c), closeTo(0.0, 1e-5));
    });
  });

  group('Quality Indexes (ASQI and VQI)', () {
    test('AudioSignalQualityIndex preserves the scan engine quality score', () {
      final asqi = AudioSignalQualityIndex(
        score: 0.94,
        sampleRate: 16000,
        durationSeconds: 2.0,
        sensorType: SensorType.contactPiezo,
      );
      expect(asqi.compositeScore, 0.94);
      expect(asqi.badge, equals(QualityBadge.clear));
    });

    test('AudioSignalQualityIndex keeps missing quality unavailable', () {
      final asqi = AudioSignalQualityIndex(
        score: null,
        sampleRate: 16000,
        durationSeconds: 2.0,
        sensorType: SensorType.audioAir,
      );
      expect(asqi.compositeScore, isNull);
      expect(asqi.badge, equals(QualityBadge.unavailable));
    });

    test('VisualQualityIndex evaluates sharpness and exposure', () {
      final sharpVqi = VisualQualityIndex(
        laplacianSharpness: 120.0,
        meanLuminance: 128.0,
        cropWidth: 600,
        cropHeight: 600,
      );
      expect(sharpVqi.badge, equals(QualityBadge.clear));

      final blurryVqi = VisualQualityIndex(
        laplacianSharpness: 25.0,
        meanLuminance: 30.0,
        cropWidth: 200,
        cropHeight: 200,
      );
      expect(blurryVqi.badge, equals(QualityBadge.noisy));
    });
  });
}
