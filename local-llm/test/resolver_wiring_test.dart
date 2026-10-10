// The injected model-path resolver (wired to model-hub by the lead) and the
// legacy getExternalFilesDir("llm") discovery when none is given.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:local_llm/local_llm.dart';
import 'package:local_llm/src/llm_api.g.dart';

import 'support/dtos.dart';
import 'support/fake_llm_host.dart';
import 'support/media.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

const String hubPath = '/data/user/0/com.kernel.kernel_app/files/models/gemma.litertlm';

void main() {
  late FakeLlmHost host;
  late StreamController<bool> optIn;

  setUp(() {
    host = FakeLlmHost();
    optIn = StreamController<bool>.broadcast();
  });

  tearDown(() => optIn.close());

  Future<LocalAdviceEngine> advice(ModelPathResolver? resolver) async {
    final e = LocalAdviceEngine(
      optIn: optIn.stream,
      host: host,
      modelPath: resolver,
    );
    e.watchStatus().listen((_) {});
    optIn.add(true);
    await settle();
    await settle();
    return e;
  }

  test('advice: the resolved path reaches modelInfo, generate and load', () async {
    final e = await advice(() async => hubPath);
    final texts = await e.explainResult(resultInput()).toList();
    expect(texts, hasLength(1));
    expect(host.modelInfoCalls.last, (hubPath, NativeRuntimeSlot.advice));
    expect(host.generateCalls.single.modelPath, hubPath);
    await e.warmUp();
    expect(host.loadPaths, [hubPath]);
    expect((await e.modelInfo())!.version, 'gemma-4-E2B-it@0123456789ab');
    await e.dispose();
  });

  test('advice: no legacy fallback when the resolver has no model', () async {
    final e = await advice(() async => null);
    expect(await e.watchStatus().first, AdviceStatus.noModel);
    expect(await e.explainResult(resultInput()).toList(), isEmpty);
    expect(await e.modelInfo(), isNull);
    expect(host.calls, isNot(contains('generate')));
    expect(host.calls, isNot(contains('modelInfo')));
    await e.dispose();
  });

  test('advice: a model installed later is used on the next request', () async {
    String? path;
    final e = await advice(() async => path);
    expect(await e.explainResult(resultInput()).toList(), isEmpty);
    path = hubPath;
    expect(await e.explainResult(resultInput()).toList(), hasLength(1));
    expect(await e.watchStatus().first, AdviceStatus.ready);
    await e.dispose();
  });

  test('advice: a throwing resolver counts as no model', () async {
    final e = await advice(() async => throw StateError('registry closed'));
    expect(await e.explainResult(resultInput()).toList(), isEmpty);
    await e.dispose();
  });

  test('advice: without a resolver the legacy directory is used', () async {
    final e = await advice(null);
    expect(await e.explainResult(resultInput()).toList(), hasLength(1));
    expect(host.generateCalls.single.modelPath, isNull);
    expect(host.modelInfoCalls.single, (null, NativeRuntimeSlot.advice));
    await e.dispose();
  });

  test('embedder and analyzer accept the same resolver type', () async {
    Future<String?> resolver() async => hubPath;
    final embedder = LocalEmbedder(host: host, modelPath: resolver);
    host.onEmbed = (_, _) async => nativeEmbed(values: List.filled(768, 0.5));
    expect(await embedder.embedText('weevil'), isNotNull);
    expect(host.embedCalls.single.modelPath, hubPath);

    final analyzer = LocalPestAnalyzer(host: host, modelPath: resolver);
    host.onPest = (_, _) async => nativeResult(
      text: '[{"box_2d": [0, 0, 500, 500], "label": "rat"}]',
    );
    final boxes = await analyzer.proposeRegions(
      jpegBytes(),
      labels: const ['rat'],
    );
    expect(boxes, hasLength(1));
    expect(host.pestCalls.single.modelPath, hubPath);
    await analyzer.dispose();
  });

  test('the shared runtime is used when one is passed', () async {
    final runtime = RuntimeManager(host: host);
    final e = LocalAdviceEngine(optIn: optIn.stream, runtime: runtime);
    e.watchStatus().listen((_) {});
    optIn.add(true);
    await settle();
    await e.explainResult(resultInput()).toList();
    expect(runtime.loadedSlot, RuntimeSlot.advice);
    await e.dispose();
    // Disposing the engine leaves a shared runtime alone.
    expect(await runtime.run(RuntimeSlot.embedder, () async => 1), 1);
    await runtime.dispose();
  });

  test('a waiting advice request keeps its 25 s budget semantics', () async {
    final runtime = RuntimeManager(host: host);
    final e = LocalAdviceEngine(
      optIn: optIn.stream,
      runtime: runtime,
      timeout: const Duration(milliseconds: 50),
    );
    e.watchStatus().listen((_) {});
    optIn.add(true);
    await settle();
    // A long Pest ID request holds the runtime.
    final gate = Completer<void>();
    final pest = runtime.run(RuntimeSlot.pestId, () => gate.future);
    expect(await e.explainResult(resultInput()).toList(), isEmpty);
    expect(host.calls, isNot(contains('generate')));
    gate.complete();
    await pest;
    await e.dispose();
    await runtime.dispose();
  });
}
