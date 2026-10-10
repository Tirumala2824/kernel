import 'dart:typed_data';

import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('Tokenization and Vector Helpers', () {
    test('tokenizeText extracts clean tokens and filters stop words', () {
      final tokens = tokenizeText('The insect with high frequency sound in sack LOT-024');
      expect(tokens, containsAll(['insect', 'high', 'frequency', 'sound', 'sack', 'lot', '024']));
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
    test('AudioSignalQualityIndex rewards high SNR and piezo sensor', () {
      final asqi = AudioSignalQualityIndex(
        snrDb: 22.0,
        noiseFloorDbfs: -55.0,
        clipRatio: 0.0,
        sampleRate: 16000,
        durationSeconds: 2.0,
        sensorType: SensorType.contactPiezo,
      );
      expect(asqi.compositeScore, greaterThan(0.8));
      expect(asqi.badge, equals(QualityBadge.clear));
    });

    test('AudioSignalQualityIndex penalizes low SNR and air microphone', () {
      final asqi = AudioSignalQualityIndex(
        snrDb: 6.0,
        noiseFloorDbfs: -32.0,
        clipRatio: 0.05,
        sampleRate: 16000,
        durationSeconds: 1.5,
        sensorType: SensorType.audioAir,
      );
      expect(asqi.compositeScore, lessThan(0.6));
      expect(asqi.badge, equals(QualityBadge.noisy));
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
