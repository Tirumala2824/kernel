import 'analytics.dart';
import 'enums.dart';

// On-device LLM advice (LiteRT-LM). Opt-in, offline, experimental.
//
// Isolation: inputs are primitives and enums only. There are no paths,
// byte buffers, ScanRecords or anything else that could carry audio, so
// audio can never reach the language model. See docs/guardrails.md §8.

enum AdviceStatus {
  /// The user has not enabled the on-phone assistant.
  optedOut,

  /// Enabled, but no model file is installed.
  noModel,
  loading,
  ready,

  /// Generating; new requests wait or fall back.
  busy,

  /// The model failed to load; the app uses static copy.
  failed,
}

class AdviceModelInfo {
  const AdviceModelInfo({
    required this.id,
    required this.version,
    required this.sizeBytes,
    required this.backend,
  });

  /// e.g. "gemma-4-E2B-it".
  final String id;

  /// Stable provenance string shown and stored with generated text.
  final String version;
  final int sizeBytes;

  /// "gpu", "cpu" or "none" before the first load.
  final String backend;
}

/// Text generated on this phone. Streams emit growing [text]; the last
/// event has [complete] true. Always experimental.
class AdviceText {
  const AdviceText({
    required this.text,
    required this.complete,
    required this.modelVersion,
    required this.languageTag,
    required this.generatedAt,
    this.experimental = true,
  });

  final String text;
  final bool complete;
  final String modelVersion;
  final String? languageTag;
  final DateTime generatedAt;

  /// Always true for on-phone LLM text (guardrails §8). Producers must not
  /// pass false; reports always print it as experimental.
  final bool experimental;
}

class ResultAdviceInput {
  const ResultAdviceInput({
    required this.role,
    required this.grainType,
    required this.classification,
    required this.confidence,
    required this.quality,
    required this.qualityReasons,
    required this.storageDays,
    required this.pestModelExperimental,
    this.latestVerifiedFinding,
  });

  final Role role;

  /// User-entered; the engine sanitizes it before prompting.
  final String grainType;
  final Classification classification;
  final double? confidence;
  final ScanQuality quality;
  final List<QualityReason> qualityReasons;
  final int storageDays;
  final bool pestModelExperimental;
  final VerifiedFinding? latestVerifiedFinding;
}

class ReminderAdviceInput {
  const ReminderAdviceInput({
    required this.role,
    required this.grainType,
    required this.storageDays,
    required this.lastResult,
    required this.suggestedDueAt,
  });

  final Role role;
  final String grainType;
  final int storageDays;
  final Classification? lastResult;
  final DateTime suggestedDueAt;
}

class ReportNarrativeInput {
  const ReportNarrativeInput({
    required this.role,
    required this.kind,
    required this.summary,
  });

  final Role role;
  final ReportKind kind;
  final AnalyticsSummary summary;
}

/// Opt-in local language model. Every method never throws: an empty
/// stream, or a stream that ends without a complete event, means "use the
/// static localized copy". Output is filtered on the device; anything that
/// recommends treatment, claims safety or accepts/rejects is dropped.
abstract interface class AdviceEngine {
  Stream<AdviceStatus> watchStatus();

  /// Null when no model is installed.
  Future<AdviceModelInfo?> modelInfo();

  Stream<AdviceText> explainResult(
    ResultAdviceInput input, {
    String? languageTag,
  });

  Stream<AdviceText> draftReportNarrative(
    ReportNarrativeInput input, {
    String? languageTag,
  });

  Stream<AdviceText> suggestReminderText(
    ReminderAdviceInput input, {
    String? languageTag,
  });
}

enum ModelImportPhase { copying, verifying, done, failed }

class ModelImportProgress {
  const ModelImportProgress({
    required this.phase,
    required this.bytesCopied,
    required this.totalBytes,
    this.error,
  });

  final ModelImportPhase phase;
  final int bytesCopied;

  /// Null when the source does not report its size.
  final int? totalBytes;

  /// Technical reason when [phase] is failed (e.g. not enough space).
  final String? error;
}

/// Installs the model file into app-specific storage. No network: the user
/// picks a .litertlm file they already have (e.g. from AI Edge Gallery).
abstract interface class AdviceModelManager {
  /// [contentUri] is a SAF content:// URI from the system file picker.
  Stream<ModelImportProgress> importFromUri(String contentUri);
  Future<void> deleteModel();
  Future<int> freeSpaceBytes();
}
