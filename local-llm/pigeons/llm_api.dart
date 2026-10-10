// Pigeon definition for the local-llm Dart <-> Kotlin bridge.
//
// Regenerate after any change (from local-llm/):
//   dart run pigeon --input pigeons/llm_api.dart
//
// This bridge is internal to local-llm. The app only sees the contracts
// types (AdviceStatus, AdviceText, EmbeddingVector, PestAnalysis, ...)
// through LocalAdviceEngine, LocalEmbedder, LiteRtModelProbe,
// LocalPestAnalyzer and LocalModelManager.
//
// Isolation (docs/guardrails.md §8 and its Phase 4 amendment):
// - The grain advice path (`generate`) carries rendered prompt strings
//   only. It has no byte buffer, file content or audio field, and the
//   Kotlin side builds its engine text-only (LlmConfig).
// - Only the Pest ID path (`pestGenerate`, `embed`) may carry a
//   user-validated image crop or audio clip (<= 30 s), in memory, to the
//   on-device engine. Nothing here is written to disk or logged.
// - `modelPath` is an absolute path inside the app's own storage (the
//   model-hub install directory); null means the legacy
//   getExternalFilesDir("llm") discovery.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'local_llm',
    dartOut: 'lib/src/llm_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/com/kernel/local_llm/LlmApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.kernel.local_llm',
      errorClassName: 'LlmApiError',
    ),
  ),
)
/// Lifecycle of the single native LiteRT-LM engine slot.
enum NativeEngineState {
  /// No engine in memory (never loaded, idle-unloaded or trimmed).
  unloaded,
  loading,
  ready,

  /// One request is running; others are rejected.
  busy,

  /// The last load attempt failed on every backend.
  failed,
}

/// Which engine occupies the runtime. Only one is ever in memory.
enum NativeRuntimeSlot {
  /// Gemma, text-only (grain advice).
  advice,

  /// Gemma with the vision and audio encoders (Pest ID mode only).
  pestId,

  /// EmbeddingGemma.
  embedder,
}

/// Engine state plus whether a model file is installed.
class NativeEngineStatus {
  NativeEngineStatus({
    required this.state,
    required this.modelPresent,
    required this.backend,
    this.slot,
  });

  NativeEngineState state;

  /// A language model is present in the legacy getExternalFilesDir("llm")
  /// directory. Callers with a model-path resolver decide presence
  /// themselves.
  bool modelPresent;

  /// "gpu", "cpu" or "none" while nothing is loaded.
  String backend;

  /// Slot of the loaded engine, or of the load attempt while loading or
  /// failed. Null when nothing is loaded or attempted.
  NativeRuntimeSlot? slot;
}

class NativeModelInfo {
  NativeModelInfo({
    required this.id,
    required this.version,
    required this.sizeBytes,
    required this.backend,
  });

  /// File name without the .litertlm extension.
  String id;

  /// `<id>@<first 12 hex chars of the sha256>`.
  String version;
  int sizeBytes;

  /// "gpu", "cpu" or "none" before the first load.
  String backend;
}

enum NativeGenerateStatus {
  ok,

  /// Another request is running.
  busy,
  noModel,

  /// The engine could not be loaded on any backend.
  loadFailed,
  timeout,
  cancelled,

  /// Native runtime error (message is never forwarded: it may echo text).
  error,

  /// The model cannot take this input (e.g. no vision or audio encoder).
  unsupported,
}

class NativeGenerateResult {
  NativeGenerateResult({
    required this.status,
    required this.text,
    required this.modelVersion,
    required this.backend,
    required this.loadMs,
    required this.firstTokenMs,
    required this.totalMs,
  });

  NativeGenerateStatus status;

  /// Full raw model output; empty unless [status] is ok. The Dart side runs
  /// the output guard / parser on it before anything reaches the UI.
  String text;
  String modelVersion;
  String backend;

  /// Engine load time spent inside this request (0 when already loaded).
  int loadMs;

  /// Time to the first streamed chunk; -1 when none arrived.
  int firstTokenMs;
  int totalMs;
}

/// One streamed chunk while a generation runs. Carries the request id and
/// sizes only; the text itself stays on the native side until the full,
/// final output is returned and guarded.
class NativeGenerationProgress {
  NativeGenerationProgress({
    required this.requestId,
    required this.chunks,
    required this.chars,
    required this.elapsedMs,
  });

  String requestId;
  int chunks;
  int chars;
  int elapsedMs;
}

enum NativeImportPhase { copying, verifying, done, failed }

class NativeImportProgress {
  NativeImportProgress({
    required this.importId,
    required this.phase,
    required this.bytesCopied,
    required this.totalBytes,
    required this.error,
  });

  String importId;
  NativeImportPhase phase;
  int bytesCopied;

  /// Null when the source does not report its size.
  int? totalBytes;

  /// Technical reason when [phase] is failed. Never contains file content.
  String? error;
}

/// Constrained decoding for a Pest ID generation.
enum NativeResponseFormat { none, json, regex }

/// One Pest ID generation (guardrails §8 amendment): images first, then the
/// optional audio clip, then the text prompt, in a fresh conversation.
class NativePestRequest {
  NativePestRequest({
    required this.modelPath,
    required this.systemInstruction,
    required this.prompt,
    required this.images,
    required this.audioWav,
    required this.format,
    required this.formatSpec,
    required this.temperature,
    required this.topK,
    required this.topP,
    required this.seed,
    required this.maxOutputTokens,
    required this.timeoutMs,
  });

  String? modelPath;
  String systemInstruction;
  String prompt;

  /// PNG or JPEG, user-confirmed crop first, optional context frame second.
  List<Uint8List> images;

  /// RIFF WAV, mono, 16 kHz, 16-bit, at most 30 s.
  Uint8List? audioWav;
  NativeResponseFormat format;

  /// JSON schema (json) or pattern (regex); null for none.
  String? formatSpec;
  double temperature;
  int topK;
  double topP;
  int seed;
  int maxOutputTokens;

  /// Bounds load plus generation of this one request.
  int timeoutMs;
}

enum NativeEmbedKind { text, image, audio }

class NativeEmbedRequest {
  NativeEmbedRequest({
    required this.modelPath,
    required this.kind,
    required this.text,
    required this.bytes,
    required this.timeoutMs,
  });

  String? modelPath;
  NativeEmbedKind kind;

  /// Already prompt-formatted (EmbeddingGemma task prefix) for [kind] text.
  String? text;

  /// PNG/JPEG for image, RIFF WAV for audio.
  Uint8List? bytes;
  int timeoutMs;
}

class NativeEmbedResult {
  NativeEmbedResult({
    required this.status,
    required this.values,
    required this.modelVersion,
    required this.backend,
    required this.totalMs,
  });

  NativeGenerateStatus status;

  /// Full-length embedding; null unless [status] is ok. Dart truncates
  /// (Matryoshka) and re-normalises.
  Float64List? values;
  String modelVersion;
  String backend;
  int totalMs;
}

enum NativeProbedKind { llm, embedding, unknown }

/// LiteRT-LM ModelInfo header fields. Reading them never loads weights.
class NativeProbeResult {
  NativeProbeResult({
    required this.kind,
    required this.text,
    required this.vision,
    required this.audio,
    required this.video,
    required this.backends,
    required this.maxContextTokens,
    required this.embeddingDim,
    required this.socName,
    required this.npuBrand,
  });

  NativeProbedKind kind;
  bool text;
  bool vision;
  bool audio;
  bool video;

  /// "cpu", "gpu", "npu" for the text modality (main backend).
  List<String> backends;
  int? maxContextTokens;
  int? embeddingDim;
  String? socName;
  String? npuBrand;
}

@HostApi()
abstract class LlmHostApi {
  @async
  NativeEngineStatus status();

  /// Null when no model is found. [modelPath] null = legacy discovery of
  /// the first model of [slot]'s kind in getExternalFilesDir("llm").
  /// The first call for a new file hashes it once (sha256) for the version.
  @async
  NativeModelInfo? modelInfo(String? modelPath, NativeRuntimeSlot slot);

  /// Loads the text-only advice engine now (GPU, then CPU). Returns the
  /// final status.
  @async
  NativeEngineStatus load(String? modelPath);

  /// Grain advice: one short-lived text-only conversation. Rejects with
  /// busy while another request runs. [timeoutMs] bounds the generation;
  /// loading is not counted.
  @async
  NativeGenerateResult generate(
    String requestId,
    String? modelPath,
    String systemInstruction,
    String prompt,
    int timeoutMs,
  );

  /// Pest ID only: one multimodal conversation on the Pest ID engine.
  @async
  NativeGenerateResult pestGenerate(String requestId, NativePestRequest request);

  /// One embedding on EmbeddingGemma.
  @async
  NativeEmbedResult embed(String requestId, NativeEmbedRequest request);

  /// Reads the model header (LiteRT-LM ModelInfo) without loading weights.
  /// Null when the file is not a readable LiteRT-LM model or lies outside
  /// the app's own storage.
  @async
  NativeProbeResult? probe(String absolutePath);

  /// Cancels [requestId] if it is the running request. No-op otherwise.
  void cancel(String requestId);

  /// Frees whichever engine is loaded (cancels a running request first).
  @async
  void unload();

  /// Copies a SAF content:// URI into app-specific storage, verifies it and
  /// writes the sidecar. Progress arrives on [LlmEvents.importProgress];
  /// the reply is the final event.
  @async
  NativeImportProgress importFromUri(String importId, String contentUri);

  /// Unloads, then removes every model file, sidecar and partial copy.
  @async
  void deleteModel();

  @async
  int freeSpaceBytes();

  /// System document picker (ACTION_OPEN_DOCUMENT, any MIME type). Returns the
  /// content:// URI of a picked .litertlm file, or null.
  @async
  String? pickLitertlmUri();
}

@EventChannelApi()
abstract class LlmEvents {
  /// Engine state changes (load, busy, unload, failure, model add/remove).
  NativeEngineStatus engineStatus();

  /// Streaming progress of the running generation (sizes only, no text).
  NativeGenerationProgress generationProgress();

  /// Import progress, throttled to about 4 per second.
  NativeImportProgress importProgress();
}
