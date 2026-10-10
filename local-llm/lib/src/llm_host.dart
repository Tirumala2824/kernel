import 'llm_api.g.dart';
import 'llm_api.g.dart'
    as bridge
    show engineStatus, generationProgress, importProgress;

/// The native side as seen by [LocalAdviceEngine] and [LocalModelManager].
/// Production uses [PigeonLlmHost]; tests substitute their own host from
/// `test/`.
abstract interface class LlmHost {
  Future<NativeEngineStatus> status();
  Future<NativeModelInfo?> modelInfo();
  Future<NativeEngineStatus> load();
  Future<NativeGenerateResult> generate(
    String requestId,
    String systemInstruction,
    String prompt,
    int timeoutMs,
  );
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
  Future<NativeModelInfo?> modelInfo() => _api.modelInfo();

  @override
  Future<NativeEngineStatus> load() => _api.load();

  @override
  Future<NativeGenerateResult> generate(
    String requestId,
    String systemInstruction,
    String prompt,
    int timeoutMs,
  ) => _api.generate(requestId, systemInstruction, prompt, timeoutMs);

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
