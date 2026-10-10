// Test-only stand-in for the Kotlin side (LlmHost). Lives under test/ only;
// never reachable from the production dependency graph.
import 'dart:async';
import 'dart:typed_data';

import 'package:local_llm/src/llm_api.g.dart';
import 'package:local_llm/src/llm_host.dart';

NativeEngineStatus nativeStatus({
  NativeEngineState state = NativeEngineState.unloaded,
  bool modelPresent = true,
  String backend = 'none',
  NativeRuntimeSlot? slot,
}) => NativeEngineStatus(
  state: state,
  modelPresent: modelPresent,
  backend: backend,
  slot: slot,
);

NativeModelInfo nativeInfo({
  String id = 'gemma-4-E2B-it',
  String version = 'gemma-4-E2B-it@0123456789ab',
  int sizeBytes = 2588147712,
  String backend = 'none',
}) => NativeModelInfo(
  id: id,
  version: version,
  sizeBytes: sizeBytes,
  backend: backend,
);

NativeGenerateResult nativeResult({
  NativeGenerateStatus status = NativeGenerateStatus.ok,
  String text =
      'The scan heard likely insect sounds. Please open the sack '
      'and check the grain yourself. This model is experimental.',
  String modelVersion = 'gemma-4-E2B-it@0123456789ab',
  String backend = 'gpu',
}) => NativeGenerateResult(
  status: status,
  text: text,
  modelVersion: modelVersion,
  backend: backend,
  loadMs: 0,
  firstTokenMs: 120,
  totalMs: 900,
);

NativeEmbedResult nativeEmbed({
  NativeGenerateStatus status = NativeGenerateStatus.ok,
  List<double>? values,
  String modelVersion = 'embeddinggemma-2@abcdef012345',
}) => NativeEmbedResult(
  status: status,
  values: values == null ? null : Float64List.fromList(values),
  modelVersion: modelVersion,
  backend: 'gpu',
  totalMs: 40,
);

class GenerateCall {
  GenerateCall(
    this.requestId,
    this.systemInstruction,
    this.prompt,
    this.timeoutMs, {
    this.modelPath,
  });

  final String requestId;
  final String systemInstruction;
  final String prompt;
  final int timeoutMs;
  final String? modelPath;
}

class FakeLlmHost implements LlmHost {
  NativeEngineStatus currentStatus = nativeStatus();
  NativeModelInfo? info = nativeInfo();
  NativeModelInfo? embedderInfo = nativeInfo(
    id: 'embeddinggemma-2',
    version: 'embeddinggemma-2@abcdef012345',
    sizeBytes: 485000000,
  );

  /// Answer for generate; may return a never-completing future.
  Future<NativeGenerateResult> Function(GenerateCall call)? onGenerate;
  Future<NativeGenerateResult> Function(String id, NativePestRequest r)?
  onPest;
  Future<NativeEmbedResult> Function(String id, NativeEmbedRequest r)? onEmbed;
  Future<NativeProbeResult?> Function(String path)? onProbe;
  Future<NativeImportProgress> Function(String importId, String uri)? onImport;
  Object? statusError;
  Object? freeSpaceError;
  int freeSpace = 10 * 1024 * 1024 * 1024;
  String? pickResult;
  Object? pickError;

  final List<String> calls = [];
  final List<GenerateCall> generateCalls = [];
  final List<NativePestRequest> pestCalls = [];
  final List<String> pestIds = [];
  final List<NativeEmbedRequest> embedCalls = [];
  final List<String> cancelled = [];
  final List<(String?, NativeRuntimeSlot)> modelInfoCalls = [];
  final List<String?> loadPaths = [];

  final StreamController<NativeEngineStatus> statusEvents =
      StreamController<NativeEngineStatus>.broadcast(sync: true);
  final StreamController<NativeImportProgress> importEvents =
      StreamController<NativeImportProgress>.broadcast(sync: true);
  final StreamController<NativeGenerationProgress> generationEvents =
      StreamController<NativeGenerationProgress>.broadcast(sync: true);

  /// Simulates a native status push.
  void push(NativeEngineStatus status) {
    currentStatus = status;
    statusEvents.add(status);
  }

  @override
  Future<NativeEngineStatus> status() async {
    calls.add('status');
    if (statusError != null) throw statusError!;
    return currentStatus;
  }

  @override
  Future<NativeModelInfo?> modelInfo(
    String? modelPath,
    NativeRuntimeSlot slot,
  ) async {
    calls.add('modelInfo');
    modelInfoCalls.add((modelPath, slot));
    return slot == NativeRuntimeSlot.embedder ? embedderInfo : info;
  }

  @override
  Future<NativeEngineStatus> load(String? modelPath) async {
    calls.add('load');
    loadPaths.add(modelPath);
    return currentStatus;
  }

  @override
  Future<NativeGenerateResult> generate(
    String requestId,
    String? modelPath,
    String systemInstruction,
    String prompt,
    int timeoutMs,
  ) {
    calls.add('generate');
    final call = GenerateCall(
      requestId,
      systemInstruction,
      prompt,
      timeoutMs,
      modelPath: modelPath,
    );
    generateCalls.add(call);
    return (onGenerate ?? (_) async => nativeResult())(call);
  }

  @override
  Future<NativeGenerateResult> pestGenerate(
    String requestId,
    NativePestRequest request,
  ) {
    calls.add('pestGenerate');
    pestIds.add(requestId);
    pestCalls.add(request);
    final answer = onPest;
    if (answer == null) {
      return Future.value(
        nativeResult(status: NativeGenerateStatus.noModel, text: ''),
      );
    }
    return answer(requestId, request);
  }

  @override
  Future<NativeEmbedResult> embed(
    String requestId,
    NativeEmbedRequest request,
  ) {
    calls.add('embed');
    embedCalls.add(request);
    final answer = onEmbed;
    if (answer == null) {
      return Future.value(nativeEmbed(status: NativeGenerateStatus.noModel));
    }
    return answer(requestId, request);
  }

  @override
  Future<NativeProbeResult?> probe(String absolutePath) {
    calls.add('probe');
    final answer = onProbe;
    return answer == null ? Future.value(null) : answer(absolutePath);
  }

  @override
  Future<void> cancel(String requestId) async {
    calls.add('cancel');
    cancelled.add(requestId);
  }

  @override
  Future<void> unload() async {
    calls.add('unload');
  }

  @override
  Future<NativeImportProgress> importFromUri(
    String importId,
    String contentUri,
  ) {
    calls.add('importFromUri');
    return onImport!(importId, contentUri);
  }

  @override
  Future<void> deleteModel() async {
    calls.add('deleteModel');
  }

  @override
  Future<int> freeSpaceBytes() async {
    calls.add('freeSpaceBytes');
    if (freeSpaceError != null) throw freeSpaceError!;
    return freeSpace;
  }

  @override
  Future<String?> pickLitertlmUri() async {
    calls.add('pickLitertlmUri');
    if (pickError != null) throw pickError!;
    return pickResult;
  }

  @override
  Stream<NativeEngineStatus> get engineStatus => statusEvents.stream;

  @override
  Stream<NativeImportProgress> get importProgress => importEvents.stream;

  @override
  Stream<NativeGenerationProgress> get generationProgress =>
      generationEvents.stream;
}
