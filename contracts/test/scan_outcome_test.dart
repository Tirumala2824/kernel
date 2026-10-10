import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:test/test.dart';

ScanOutcome _outcome({
  ScanQuality quality = ScanQuality.pass,
  List<QualityReason> reasons = const [],
  Classification classification = Classification.notEvaluated,
  double? confidence,
  bool experimental = true,
  String modelVersion = noModelVersion,
}) => ScanOutcome(
  scanId: 's1',
  itemId: 'i1',
  capturedAt: DateTime.utc(2026, 10, 9),
  quality: quality,
  qualityReasons: reasons,
  classification: classification,
  confidence: confidence,
  experimental: experimental,
  modelVersion: modelVersion,
  latencyMs: 10,
  durationMs: 2000,
  sampleRate: 16000,
  deviceModel: 'test',
  osVersion: 'test',
);

void main() {
  test('no-model pass outcome is valid', () {
    expect(_outcome().invariantViolations(), isEmpty);
  });

  test('retry with reason and notEvaluated is valid', () {
    expect(
      _outcome(
        quality: ScanQuality.retry,
        reasons: [QualityReason.silence],
      ).invariantViolations(),
      isEmpty,
    );
  });

  test('retry must not carry a pest class', () {
    expect(
      _outcome(
        quality: ScanQuality.retry,
        reasons: [QualityReason.clipping],
        classification: Classification.infested,
        modelVersion: 'm1',
      ).invariantViolations(),
      isNotEmpty,
    );
  });

  test('retry must state a reason', () {
    expect(
      _outcome(quality: ScanQuality.retry).invariantViolations(),
      isNotEmpty,
    );
  });

  test('no model cannot classify', () {
    expect(
      _outcome(
        classification: Classification.clean,
        confidence: 0.9,
      ).invariantViolations(),
      isNotEmpty,
    );
  });

  test('no model must be experimental', () {
    expect(_outcome(experimental: false).invariantViolations(), isNotEmpty);
  });

  test('notEvaluated must not carry confidence', () {
    expect(_outcome(confidence: 0.5).invariantViolations(), isNotEmpty);
  });

  test('real model result is valid', () {
    expect(
      _outcome(
        classification: Classification.uncertain,
        confidence: 0.6,
        modelVersion: 'grain-cnn-0.1',
      ).invariantViolations(),
      isEmpty,
    );
  });
}
