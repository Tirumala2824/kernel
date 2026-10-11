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


}
