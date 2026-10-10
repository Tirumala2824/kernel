// Pigeon definition for the local-llm Dart <-> Kotlin bridge.
//
// Regenerate after any change (from local-llm/):
//   dart run pigeon --input pigeons/llm_api.dart
//
// This bridge is internal to local-llm. The app only sees the contracts
// types (AdviceStatus, AdviceText, ModelImportProgress, ...) through
// LocalAdviceEngine and LocalModelManager.
//
// Isolation (docs/guardrails.md §8): text crosses this bridge in one
// direction only, as a rendered prompt string built from typed DTO fields.
// There is no byte buffer, file path or audio field anywhere in this file,
// and the Kotlin side never configures an audio or vision backend.
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
/// Lifecycle of the native LiteRT-LM engine.
enum NativeEngineState {
  /// No engine in memory (never loaded, idle-unloaded or trimmed).
  unloaded,
  loading,
  ready,

  /// One generation is running; others are rejected.
  busy,

  /// The last load attempt failed on both GPU and CPU.
  failed,
}

/// Engine state plus whether a model file is installed.
class NativeEngineStatus {
  NativeEngineStatus({
    required this.state,
    required this.modelPresent,
    required this.backend,
  });

  NativeEngineState state;
  bool modelPresent;

  /// "gpu", "cpu" or "none" while nothing is loaded.
  String backend;
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

  /// `<id>@<first 12 hex chars of the sha256>`, from the sidecar.
  String version;
  int sizeBytes;

  /// "gpu", "cpu" or "none" before the first load.
  String backend;
}

enum NativeGenerateStatus {
  ok,

  /// Another generation is running.
  busy,
  noModel,

  /// The engine could not be loaded on GPU or CPU.
  loadFailed,
  timeout,
  cancelled,

  /// Native runtime error (message is never forwarded: it may echo text).
  error,
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
  /// the output guard on it before anything reaches the UI.
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

@HostApi()
abstract class LlmHostApi {
  @async
  NativeEngineStatus status();

  /// Null when no .litertlm is installed. Writes the sidecar on first use
  /// for a file copied in by adb (one streamed sha256 pass).
  @async
  NativeModelInfo? modelInfo();

  /// Loads the engine now (GPU, then CPU). Returns the final status.
  @async
  NativeEngineStatus load();

  /// One short-lived conversation. Rejects with busy while another runs.
  /// [timeoutMs] bounds the generation itself; loading is not counted.
  @async
  NativeGenerateResult generate(
    String requestId,
    String systemInstruction,
    String prompt,
    int timeoutMs,
  );

  /// Cancels [requestId] if it is the running generation. No-op otherwise.
  void cancel(String requestId);

  /// Frees the engine (cancels a running generation first).
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
