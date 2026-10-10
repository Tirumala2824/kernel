import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:local_llm/local_llm.dart';
import 'package:local_llm/src/llm_api.g.dart';
import 'package:local_llm/src/local_embedder.dart'
    show sanitizeEmbedText, truncateAndNormalize;

import 'support/fake_llm_host.dart';
import 'support/media.dart';

/// 768 values whose first 256 are 2.0 and the rest 1.0 (not normalised).
List<double> fullVector() => [
  for (var i = 0; i < 768; i++) i < 256 ? 2.0 : 1.0,
];

double norm(List<double> v) => math.sqrt(v.fold(0.0, (s, x) => s + x * x));

void main() {
  late FakeLlmHost host;
  late LocalEmbedder embedder;

  setUp(() {
    host = FakeLlmHost()
      ..onEmbed = ((_, _) async => nativeEmbed(values: fullVector()));
    embedder = LocalEmbedder(host: host);
  });

  group('null paths (never throws)', () {
    test('no model installed', () async {
      host.onEmbed = (_, _) async =>
          nativeEmbed(status: NativeGenerateStatus.noModel);
      expect(await embedder.embedText('weevil'), isNull);
      host.embedderInfo = null;
      expect(await embedder.isAvailable(), isFalse);
      expect(await embedder.modelVersion(), isNull);
    });

    test('a resolver without a model never falls back to the legacy dir', () async {
      final e = LocalEmbedder(host: host, modelPath: () async => null);
      expect(await e.embedText('weevil'), isNull);
      expect(await e.isAvailable(), isFalse);
      expect(host.calls, isEmpty);
      final throwing = LocalEmbedder(
        host: host,
        modelPath: () async => throw StateError('registry closed'),
      );
      expect(await throwing.embedText('weevil'), isNull);
    });

    test('unsupported Matryoshka sizes', () async {
      for (final dim in [0, 64, 300, 1024]) {
        expect(await embedder.embedText('weevil', dim: dim), isNull);
        expect(await embedder.embedImage(pngBytes(), dim: dim), isNull);
      }
      expect(host.calls, isEmpty);
    });

    test('empty or control-only text', () async {
      expect(await embedder.embedText(''), isNull);
      expect(await embedder.embedText(' \n\t\u0000 '), isNull);
      expect(host.calls, isEmpty);
    });

    test('bytes that are not PNG/JPEG are not images', () async {
      expect(await embedder.embedImage(wavBytes()), isNull);
      expect(await embedder.embedImage(Uint8List(0)), isNull);
      expect(host.calls, isEmpty);
    });

    test('clips must be RIFF WAV mono 16 kHz 16-bit, at most 30 s', () async {
      expect(await embedder.embedAudio(wavBytes(channels: 2)), isNull);
      expect(await embedder.embedAudio(wavBytes(sampleRate: 44100)), isNull);
      expect(await embedder.embedAudio(wavBytes(bits: 8)), isNull);
      expect(await embedder.embedAudio(wavBytes(format: 3, bits: 16)), isNull);
      expect(await embedder.embedAudio(wavBytes(seconds: 31)), isNull);
      expect(await embedder.embedAudio(wavBytes(seconds: 0)), isNull);
      expect(await embedder.embedAudio(pngBytes()), isNull);
      expect(host.calls, isEmpty);
    });

    test('non-ok native statuses', () async {
      for (final s in [
        NativeGenerateStatus.busy,
        NativeGenerateStatus.loadFailed,
        NativeGenerateStatus.timeout,
        NativeGenerateStatus.cancelled,
        NativeGenerateStatus.error,
        NativeGenerateStatus.unsupported,
      ]) {
        host.onEmbed = (_, _) async => nativeEmbed(status: s);
        expect(await embedder.embedText('weevil'), isNull, reason: '$s');
      }
    });

    test('missing, short, zero or non-finite vectors', () async {
      host.onEmbed = (_, _) async => nativeEmbed();
      expect(await embedder.embedText('weevil'), isNull);
      host.onEmbed = (_, _) async => nativeEmbed(values: List.filled(128, 1));
      expect(await embedder.embedText('weevil', dim: 256), isNull);
      host.onEmbed = (_, _) async => nativeEmbed(values: List.filled(768, 0));
      expect(await embedder.embedText('weevil'), isNull);
      host.onEmbed = (_, _) async =>
          nativeEmbed(values: [double.nan, ...List.filled(767, 1.0)]);
      expect(await embedder.embedText('weevil'), isNull);
      host.onEmbed = (_, _) async =>
          nativeEmbed(values: fullVector(), modelVersion: '');
      expect(await embedder.embedText('weevil'), isNull);
    });

    test('bridge errors', () async {
      host.onEmbed = (_, _) async => throw PlatformException(code: 'boom');
      expect(await embedder.embedText('weevil'), isNull);
    });

    test('timeout cancels the native request', () async {
      final slow = LocalEmbedder(
        host: host,
        timeout: const Duration(milliseconds: 40),
      );
      host.onEmbed = (_, _) => Completer<NativeEmbedResult>().future;
      expect(await slow.embedText('weevil'), isNull);
      expect(host.cancelled, hasLength(1));
    });
  });

  group('vectors', () {
    test('truncated to the Matryoshka size and re-normalised', () async {
      for (final dim in [128, 256, 512, 768]) {
        final v = await embedder.embedText('weevil', dim: dim);
        expect(v, isNotNull, reason: '$dim');
        expect(v!.dim, dim);
        expect(norm(v.values), closeTo(1.0, 1e-5));
        expect(v.modelVersion, 'embeddinggemma-2@abcdef012345');
      }
      // dim 256: every kept value was 2.0, so each is 1/sqrt(256).
      final v = (await embedder.embedText('weevil'))!;
      expect(v.values.first, closeTo(1 / 16, 1e-6));
      expect(v.cosine(v), closeTo(1.0, 1e-5));
    });

    test('EmbeddingGemma prompts per task', () async {
      await embedder.embedText('rice weevil');
      await embedder.embedText(
        'Rice weevil card',
        task: EmbeddingTask.searchDocument,
      );
      await embedder.embedText('x', task: EmbeddingTask.classification);
      await embedder.embedText('y', task: EmbeddingTask.similarity);
      expect(host.embedCalls.map((c) => c.text), [
        'task: search result | query: rice weevil',
        'title: none | text: Rice weevil card',
        'task: classification | query: x',
        'task: sentence similarity | query: y',
      ]);
      expect(host.embedCalls.every((c) => c.kind == NativeEmbedKind.text), isTrue);
    });

    test('images and clips go to the native embedder as bytes', () async {
      expect(await embedder.embedImage(jpegBytes()), isNotNull);
      expect(await embedder.embedAudio(wavBytes(seconds: 30)), isNotNull);
      expect(host.embedCalls.map((c) => c.kind), [
        NativeEmbedKind.image,
        NativeEmbedKind.audio,
      ]);
      expect(host.embedCalls.first.text, isNull);
      expect(host.embedCalls.first.bytes, jpegBytes());
    });

    test('the resolver path is passed through', () async {
      final e = LocalEmbedder(
        host: host,
        modelPath: () async => '/data/user/0/app/files/models/eg2.litertlm',
      );
      expect(await e.embedText('weevil'), isNotNull);
      expect(await e.modelVersion(), 'embeddinggemma-2@abcdef012345');
      expect(
        host.embedCalls.single.modelPath,
        '/data/user/0/app/files/models/eg2.litertlm',
      );
      expect(host.modelInfoCalls.last, (
        '/data/user/0/app/files/models/eg2.litertlm',
        NativeRuntimeSlot.embedder,
      ));
    });

    test('legacy discovery passes no path', () async {
      expect(await embedder.isAvailable(), isTrue);
      await embedder.embedText('weevil');
      expect(host.embedCalls.single.modelPath, isNull);
      expect(host.modelInfoCalls.single, (null, NativeRuntimeSlot.embedder));
    });
  });

  group('helpers', () {
    test('truncateAndNormalize', () {
      expect(truncateAndNormalize([3, 4, 100], 2), [closeTo(0.6, 1e-6), closeTo(0.8, 1e-6)]);
      expect(truncateAndNormalize([1], 2), isNull);
      expect(truncateAndNormalize([0, 0], 2), isNull);
      expect(truncateAndNormalize([double.infinity, 1], 2), isNull);
    });

    test('sanitizeEmbedText', () {
      expect(sanitizeEmbedText('  rice\n\nweevil\u0007 '), 'rice weevil');
      expect(sanitizeEmbedText('x' * 5000).length, 2000);
      expect(embeddingDims, {128, 256, 512, 768});
    });
  });
}
