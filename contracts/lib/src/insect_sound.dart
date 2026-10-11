import 'pest_id.dart' show ScoredLabel;

/// Audible insect sound classification, separate from grain screening.
enum InsectSoundStatus { evaluated, rejected, unavailable }

enum InsectIdentificationLevel { species, genus, group, unknown }

/// An experimental match against a closed set, never an infestation finding.
class InsectSoundResult {
  const InsectSoundResult({
    required this.status,
    this.level = InsectIdentificationLevel.unknown,
    this.label,
    this.topLabels = const [],
    this.reasons = const [],
    this.modelId = 'ganesh333/kernel-insect-classifier',
    this.modelVersion = 'none',
    this.modelRevision,
    this.sampleRate,
    this.durationMs,
    this.experimental = true,
  });

  final InsectSoundStatus status;
  final InsectIdentificationLevel level;
  final String? label;
  final List<ScoredLabel> topLabels;
  final List<String> reasons;
  final String modelId;
  final String modelVersion;
  final String? modelRevision;
  final int? sampleRate;
  final int? durationMs;
  final bool experimental;

  /// Contract validation. Rejected or unavailable audio has no identification.
  List<String> invariantViolations() => [
    if (status == InsectSoundStatus.evaluated && topLabels.isEmpty)
      'missing-scored-evidence',
    // The pinned model identifies a species only at its inclusive 0.6
    // threshold. Never repair an inconsistent label by promoting a raw score.
    if (status == InsectSoundStatus.evaluated &&
        level == InsectIdentificationLevel.species &&
        !topLabels.any(
          (candidate) =>
              candidate.label == label &&
              candidate.score >= 0.6 &&
              topLabels.every((other) => other.score <= candidate.score),
        ))
      'unsupported-species-identification',
    if (topLabels.any(
      (candidate) =>
          !candidate.score.isFinite ||
          candidate.score < 0 ||
          candidate.score > 1,
    ))
      'invalid-model-score',
    if (level != InsectIdentificationLevel.unknown &&
        (label == null || label!.trim().isEmpty))
      'missing-identification-label',
    if (level == InsectIdentificationLevel.unknown && label != null)
      'unknown-has-label',
    if (status == InsectSoundStatus.evaluated &&
        (modelVersion.isEmpty ||
            modelVersion == 'none' ||
            modelId.isEmpty ||
            !RegExp(r'^[0-9a-f]{40}$').hasMatch(modelRevision ?? '')))
      'missing-model-provenance',
    if (status != InsectSoundStatus.evaluated &&
        (level != InsectIdentificationLevel.unknown ||
            label != null ||
            topLabels.isNotEmpty))
      'unevaluated-identification',
  ];
}

abstract interface class InsectSoundClassifier {
  /// Reads a local WAV; never uploads audio or opens the microphone.
  Future<InsectSoundResult> classifyWavFile(String path);
}
