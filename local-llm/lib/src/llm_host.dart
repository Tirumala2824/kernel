import 'llm_api.g.dart';
import 'llm_api.g.dart'
    as bridge
    show engineStatus, generationProgress, importProgress;

/// The native side as seen by the engines in this package. Production uses
/// [PigeonLlmHost]; tests substitute their own host from `test/`.
///
/// `modelPath` everywhere is an absolute path in the app's own storage
/// (from an injected resolver, e.g. model-hub) or null for the legacy
/// getExternalFilesDir("llm") discovery.
abstract interface class LlmHost {
  Future<NativeEngineStatus> status();
  Future<NativeModelInfo?> modelInfo(String? modelPath, NativeRuntimeSlot slot);
  Future<NativeEngineStatus> load(String? modelPath);

  /// Grain advice: text-only.
  Future<NativeGenerateResult> generate(
    String requestId,
    String? modelPath,
    String systemInstruction,
    String prompt,
    int timeoutMs,
  );

  /// Pest ID mode only (guardrails §8 amendment).
  Future<NativeGenerateResult> pestGenerate(
    String requestId,
    NativePestRequest request,
  );
  Future<NativeEmbedResult> embed(String requestId, NativeEmbedRequest request);
  Future<NativeProbeResult?> probe(String absolutePath);
  Future<void> cancel(String requestId);
  Future<void> unload();
  Future<NativeImportProgress> importFromUri(
    String importId,
    String contentUri,
  );
  Future<void> deleteModel();
  Future<int> freeSpaceBytes();
  Future<String?> pickLitertlmUri();

  Stream<NativeEngineStatus> get engineStatus;
  Stream<NativeImportProgress> get importProgress;
  Stream<NativeGenerationProgress> get generationProgress;
}

/// [LlmHost] over the pigeon bridge to the Kotlin plugin.
class PigeonLlmHost implements LlmHost {
  PigeonLlmHost() : _api = LlmHostApi();

  final LlmHostApi _api;

  // One broadcast stream per channel for the whole process: the native side
  // has a single sink per channel, and a second EventChannel listener would
  // replace the first.
  static final Stream<NativeEngineStatus> _status = bridge
      .engineStatus()
      .handleError((Object _) {})
      .asBroadcastStream();
  static final Stream<NativeImportProgress> _imports = bridge
      .importProgress()
      .handleError((Object _) {})
      .asBroadcastStream();
  static final Stream<NativeGenerationProgress> _generation = bridge
      .generationProgress()
      .handleError((Object _) {})
      .asBroadcastStream();

  @override
  Future<NativeEngineStatus> status() => _api.status();

  @override
  Future<NativeModelInfo?> modelInfo(
    String? modelPath,
    NativeRuntimeSlot slot,
  ) => _api.modelInfo(modelPath, slot);

  @override
  Future<NativeEngineStatus> load(String? modelPath) => _api.load(modelPath);

  @override
  Future<NativeGenerateResult> generate(
    String requestId,
    String? modelPath,
    String systemInstruction,
    String prompt,
    int timeoutMs,
  ) => _api.generate(
    requestId,
    modelPath,
    systemInstruction,
    prompt,
    timeoutMs,
  );

  @override
  Future<NativeGenerateResult> pestGenerate(
    String requestId,
    NativePestRequest request,
  ) => _api.pestGenerate(requestId, request);

  @override
  Future<NativeEmbedResult> embed(
    String requestId,
    NativeEmbedRequest request,
  ) => _api.embed(requestId, request);

  @override
  Future<NativeProbeResult?> probe(String absolutePath) =>
      _api.probe(absolutePath);

  @override
  Future<void> cancel(String requestId) => _api.cancel(requestId);

  @override
  Future<void> unload() => _api.unload();

  @override
  Future<NativeImportProgress> importFromUri(
    String importId,
    String contentUri,
  ) => _api.importFromUri(importId, contentUri);

  @override
  Future<void> deleteModel() => _api.deleteModel();

  @override
  Future<int> freeSpaceBytes() => _api.freeSpaceBytes();

  @override
  Future<String?> pickLitertlmUri() => _api.pickLitertlmUri();

  @override
  Stream<NativeEngineStatus> get engineStatus => _status;

  @override
  Stream<NativeImportProgress> get importProgress => _imports;

  @override
  Stream<NativeGenerationProgress> get generationProgress => _generation;
}
