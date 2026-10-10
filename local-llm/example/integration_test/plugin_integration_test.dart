// On-device check of the real plugin. Run from local-llm/example on the
// iQOO 15:
//
//   flutter test integration_test -d <device-id>
//
// Without a model in /sdcard/Android/data/com.kernel.local_llm_example/files/llm/
// the model-dependent tests only check the honest "no model" behaviour.
// To test generation, copy a model first (see the README), e.g.
//
//   adb shell mkdir -p /sdcard/Android/data/com.kernel.local_llm_example/files/llm
//   adb shell cp <gallery file> /sdcard/Android/data/com.kernel.local_llm_example/files/llm/
//
// Only timings, backend and sizes are printed, never prompts or outputs.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:local_llm/local_llm.dart';
import 'package:local_llm/src/llm_api.g.dart';
import 'package:local_llm/src/llm_host.dart';
import 'package:local_llm/src/output_guard.dart';
import 'package:local_llm/src/prompts.dart';

const ResultAdviceInput _input = ResultAdviceInput(
  role: Role.farmer,
  grainType: 'Wheat',
  classification: Classification.uncertain,
  confidence: 0.55,
  quality: ScanQuality.pass,
  qualityReasons: [],
  storageDays: 30,
  pestModelExperimental: true,
);

Stream<bool> _on() => Stream<bool>.value(true);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opted out: no status but optedOut, no text', (tester) async {
    final engine = LocalAdviceEngine(optIn: Stream<bool>.value(false));
    expect(await engine.watchStatus().first, AdviceStatus.optedOut);
    expect(await engine.explainResult(_input).toList(), isEmpty);
    await engine.dispose();
  });

  testWidgets('free space is reported', (tester) async {
    expect(await LocalModelManager().freeSpaceBytes(), greaterThan(0));
  });

  testWidgets('status and model info agree', (tester) async {
    final engine = LocalAdviceEngine(optIn: _on());
    final status = await engine
        .watchStatus()
        .firstWhere((s) => s != AdviceStatus.optedOut)
        .timeout(const Duration(seconds: 30));
    final info = await engine.modelInfo();
    if (info == null) {
      expect(status, AdviceStatus.noModel);
      expect(await engine.explainResult(_input).toList(), isEmpty);
    } else {
      expect(status, isNot(AdviceStatus.noModel));
      expect(info.version, startsWith('${info.id}@'));
      expect(info.version.length, info.id.length + 1 + 12);
      // ignore: avoid_print
      print(
        'local_llm model ${info.id} version ${info.version} size ${info.sizeBytes}',
      );
    }
    await engine.dispose();
  });

  testWidgets('load, generate and unload with timings', (tester) async {
    final host = PigeonLlmHost();
    if (await host.modelInfo() == null) {
      // ignore: avoid_print
      print('local_llm: no model installed, generation not tested');
      return;
    }
    final load = await host.load();
    // ignore: avoid_print
    print('local_llm load: state ${load.state.name} backend ${load.backend}');
    expect(load.state, NativeEngineState.ready);
    expect(['gpu', 'cpu'], contains(load.backend));

    for (final lang in ['en', 'hi']) {
      final p = renderResultPrompt(_input, languageTag: lang);
      final r = await host.generate(
        'it-$lang',
        p.systemInstruction,
        p.prompt,
        25000,
      );
      final verdict = checkOutput(tidyOutput(r.text));
      // ignore: avoid_print
      print(
        'local_llm generate[$lang]: ${r.status.name} backend ${r.backend} '
        'load ${r.loadMs} ms, first token ${r.firstTokenMs} ms, '
        'total ${r.totalMs} ms, ${r.text.length} chars, '
        'guard ${verdict.allowed ? 'pass' : verdict.category!.name}',
      );
      expect(r.status, NativeGenerateStatus.ok);
      expect(r.totalMs, lessThan(25000));
    }

    // A second request while one runs is rejected as busy.
    final p = renderResultPrompt(_input);
    final first = host.generate('it-a', p.systemInstruction, p.prompt, 25000);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final second = await host.generate(
      'it-b',
      p.systemInstruction,
      p.prompt,
      25000,
    );
    expect(second.status, NativeGenerateStatus.busy);
    await host.cancel('it-a');
    expect(
      (await first).status,
      isIn([NativeGenerateStatus.cancelled, NativeGenerateStatus.ok]),
    );

    await host.unload();
    expect((await host.status()).state, NativeEngineState.unloaded);
  });

  testWidgets('engine end to end yields guarded text or nothing', (
    tester,
  ) async {
    final engine = LocalAdviceEngine(optIn: _on());
    if (await engine.modelInfo() == null) {
      await engine.dispose();
      return;
    }
    final watch = Stopwatch()..start();
    final texts = await engine.explainResult(_input).toList();
    // ignore: avoid_print
    print(
      'local_llm explainResult: ${texts.length} event(s) in ${watch.elapsedMilliseconds} ms',
    );
    expect(texts.length, lessThanOrEqualTo(1));
    if (texts.isNotEmpty) {
      expect(texts.single.complete, isTrue);
      expect(texts.single.experimental, isTrue);
      expect(checkOutput(texts.single.text).allowed, isTrue);
    }
    await engine.dispose();
  });
}
