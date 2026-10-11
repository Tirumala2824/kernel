import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:test/test.dart';

void main() {
  test('evaluated result requires scored model evidence', () {
    for (final level in InsectIdentificationLevel.values) {
      final result = InsectSoundResult(
        status: InsectSoundStatus.evaluated,
        level: level,
        label: level == InsectIdentificationLevel.unknown ? null : 'Test label',
        modelVersion: 'test-model',
        modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
      );
      expect(result.invariantViolations(), contains('missing-scored-evidence'));
    }
  });

  test(
    'species identification must agree with the highest supported score',
    () {
      for (final candidates in [
        const [ScoredLabel(label: 'Different species', score: 0.7)],
        const [ScoredLabel(label: 'Test species', score: 0.59)],
        const [
          ScoredLabel(label: 'Test species', score: 0.6),
          ScoredLabel(label: 'Different species', score: 0.7),
        ],
      ]) {
        final result = InsectSoundResult(
          status: InsectSoundStatus.evaluated,
          level: InsectIdentificationLevel.species,
          label: 'Test species',
          topLabels: candidates,
          modelVersion: 'test-model',
          modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
        );
        expect(
          result.invariantViolations(),
          contains('unsupported-species-identification'),
        );
      }
      const atBoundary = InsectSoundResult(
        status: InsectSoundStatus.evaluated,
        level: InsectIdentificationLevel.species,
        label: 'Test species',
        topLabels: [
          ScoredLabel(label: 'Other species', score: 0.2),
          ScoredLabel(label: 'Test species', score: 0.6),
        ],
        modelVersion: 'test-model',
        modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
      );
      expect(atBoundary.invariantViolations(), isEmpty);
    },
  );

  test('a named identification requires a nonblank actual label', () {
    for (final label in <String?>[null, '', '   ']) {
      final result = InsectSoundResult(
        status: InsectSoundStatus.evaluated,
        level: InsectIdentificationLevel.species,
        label: label,
        modelVersion: 'test-model',
        modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
      );
      expect(
        result.invariantViolations(),
        contains('missing-identification-label'),
      );
    }
  });

  test('model scores must be finite values in the unit interval', () {
    for (final score in [double.nan, double.infinity, -0.1, 1.1]) {
      final result = InsectSoundResult(
        status: InsectSoundStatus.evaluated,
        modelVersion: 'test-model',
        modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
        topLabels: [ScoredLabel(label: 'test-only candidate', score: score)],
      );
      expect(result.invariantViolations(), contains('invalid-model-score'));
    }
  });

  test('unknown identification is never promoted to a raw top label', () {
    const result = InsectSoundResult(
      status: InsectSoundStatus.evaluated,
      label: 'test-only top species',
      modelVersion: 'test-model',
      modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
    );
    expect(result.invariantViolations(), contains('unknown-has-label'));
  });

  test('evaluated result must retain real model provenance', () {
    const result = InsectSoundResult(status: InsectSoundStatus.evaluated);
    expect(result.invariantViolations(), contains('missing-model-provenance'));
  });

  test('rejected or unavailable audio must not carry a species match', () {
    for (final status in [
      InsectSoundStatus.rejected,
      InsectSoundStatus.unavailable,
    ]) {
      final result = InsectSoundResult(
        status: status,
        level: InsectIdentificationLevel.species,
        label: 'test-only species',
        topLabels: const [ScoredLabel(label: 'test-only species', score: 0.9)],
      );
      expect(
        result.invariantViolations(),
        contains('unevaluated-identification'),
      );
    }
  });
}
