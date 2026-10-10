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
import 'dart:io';
import 'dart:typed_data';

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
    if (await host.modelInfo(null, NativeRuntimeSlot.advice) == null) {
      // ignore: avoid_print
      print('local_llm: no model installed, generation not tested');
      return;
    }
    final load = await host.load(null);
    // ignore: avoid_print
    print('local_llm load: state ${load.state.name} backend ${load.backend}');
    expect(load.state, NativeEngineState.ready);
    expect(['gpu', 'cpu'], contains(load.backend));

    for (final lang in ['en', 'hi']) {
      final p = renderResultPrompt(_input, languageTag: lang);
      final r = await host.generate(
        'it-$lang',
        null,
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
    final first = host.generate(
      'it-a',
      null,
      p.systemInstruction,
      p.prompt,
      25000,
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final second = await host.generate(
      'it-b',
      null,
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

  // ---- Phase 4: probe, embedder, Pest ID (iQOO 15 verification) ----------

  testWidgets('model headers are probed without loading', (tester) async {
    final dir = Directory(_legacyDir);
    final files = dir.existsSync()
        ? dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.litertlm'))
              .toList()
        : <File>[];
    final probe = LiteRtModelProbe();
    for (final f in files) {
      final watch = Stopwatch()..start();
      final r = await probe.probe(f.path);
      // ignore: avoid_print
      print(
        'local_llm probe ${f.uri.pathSegments.last}: ${r?.kind.name} '
        'inputs ${r?.inputModalities} backends ${r?.backends} '
        'context ${r?.maxContextTokens} dim ${r?.embeddingDim} '
        'soc ${r?.socName} npu ${r?.npuBrand} in ${watch.elapsedMilliseconds} ms',
      );
    }
    expect(await probe.probe('/system/etc/hosts'), isNull);
  });

  testWidgets('embedder returns unit vectors or null', (tester) async {
    final embedder = LocalEmbedder();
    if (!await embedder.isAvailable()) {
      // ignore: avoid_print
      print('local_llm: no embedding model, embedder not tested');
      expect(await embedder.embedText('rice weevil'), isNull);
      return;
    }
    final watch = Stopwatch()..start();
    final q = await embedder.embedText('small brown beetle in rice');
    final d = await embedder.embedText(
      'Rice weevil: a small brown snout beetle found in stored rice.',
      task: EmbeddingTask.searchDocument,
    );
    final o = await embedder.embedText(
      'Monitor lizard: a large protected reptile.',
      task: EmbeddingTask.searchDocument,
    );
    // ignore: avoid_print
    print(
      'local_llm embed: 3 texts in ${watch.elapsedMilliseconds} ms, '
      'dim ${q?.dim}, version ${q?.modelVersion}, '
      'related ${q != null && d != null ? q.cosine(d).toStringAsFixed(3) : '-'} '
      'unrelated ${q != null && o != null ? q.cosine(o).toStringAsFixed(3) : '-'}',
    );
    expect(q?.dim, 256);
    final image = await embedder.embedImage(_png(64, 64));
    // ignore: avoid_print
    print('local_llm embedImage: ${image == null ? 'unsupported' : image.dim}');
  });

  testWidgets('Pest ID analysis fits the budget or returns null', (
    tester,
  ) async {
    final analyzer = LocalPestAnalyzer();
    final watch = Stopwatch()..start();
    final a = await analyzer.analyzeImage(
      PestImageRequest(
        crop: _png(256, 256),
        allowedCardIds: const ['german_cockroach', 'rice_weevil', 'house_rat'],
      ),
    );
    // ignore: avoid_print
    print(
      'local_llm analyzeImage: ${a == null ? 'null' : 'card ${a.cardId} '
                'agreement ${a.agreement} samples ${a.samples} '
                'latency ${a.latencyMs} ms'} after ${watch.elapsedMilliseconds} ms',
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 50)));
    if (a != null) {
      expect(a.experimental, isTrue);
      expect(a.samples, 3);
    }
    await analyzer.dispose();
  });
}

const String _legacyDir =
    '/storage/emulated/0/Android/data/com.kernel.local_llm_example/files/llm';

/// A plain grey RGB PNG (stored on the fly; no fixtures shipped).
Uint8List _png(int width, int height) {
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0);
    for (var x = 0; x < width; x++) {
      raw.add(const [128, 128, 128]);
    }
  }
  Uint8List chunk(String type, List<int> data) {
    final b = BytesBuilder();
    final len = ByteData(4)..setUint32(0, data.length);
    b.add(len.buffer.asUint8List());
    final body = [...type.codeUnits, ...data];
    b.add(body);
    final crc = ByteData(4)..setUint32(0, _crc32(body));
    b.add(crc.buffer.asUint8List());
    return b.toBytes();
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 2);
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    ...chunk('IHDR', header.buffer.asUint8List()),
    ...chunk('IDAT', zlib.encode(raw.toBytes())),
    ...chunk('IEND', const []),
  ]);
}

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c ^= b;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
  }
  return c ^ 0xFFFFFFFF;
}
