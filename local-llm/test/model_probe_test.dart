import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:local_llm/local_llm.dart';
import 'package:local_llm/src/llm_api.g.dart';
import 'package:local_llm/src/model_probe.dart' show mapProbeResult;

import 'support/fake_llm_host.dart';

NativeProbeResult header({
  NativeProbedKind kind = NativeProbedKind.llm,
  bool text = true,
  bool vision = false,
  bool audio = false,
  bool video = false,
  List<String> backends = const ['cpu', 'gpu'],
  int? maxContextTokens = 32768,
  int? embeddingDim,
  String? socName,
  String? npuBrand,
}) => NativeProbeResult(
  kind: kind,
  text: text,
  vision: vision,
  audio: audio,
  video: video,
  backends: backends,
  maxContextTokens: maxContextTokens,
  embeddingDim: embeddingDim,
  socName: socName,
  npuBrand: npuBrand,
);

void main() {
  group('mapping', () {
    test('Gemma 4 E2B: LLM with vision and audio', () {
      final r = mapProbeResult(
        header(vision: true, audio: true, backends: ['gpu', 'cpu', 'npu']),
      );
      expect(r.kind, ProbedKind.llm);
      expect(r.inputModalities, {'text', 'vision', 'audio'});
      expect(r.backends, ['gpu', 'cpu', 'npu']);
      expect(r.maxContextTokens, 32768);
      expect(r.embeddingDim, isNull);
    });

    test('EmbeddingGemma: embedding with its dimension', () {
      final r = mapProbeResult(
        header(
          kind: NativeProbedKind.embedding,
          embeddingDim: 768,
          maxContextTokens: 2048,
        ),
      );
      expect(r.kind, ProbedKind.embedding);
      expect(r.inputModalities, {'text'});
      expect(r.embeddingDim, 768);
    });

    test('a dimension on a non-embedding model is dropped', () {
      expect(mapProbeResult(header(embeddingDim: 768)).embeddingDim, isNull);
    });

    test('unknown kind, video, SoC and NPU fields', () {
      final r = mapProbeResult(
        header(
          kind: NativeProbedKind.unknown,
          text: false,
          video: true,
          socName: ' sm8850 ',
          npuBrand: 'qualcomm',
        ),
      );
      expect(r.kind, ProbedKind.unknown);
      expect(r.inputModalities, {'video'});
      expect(r.socName, 'sm8850');
      expect(r.npuBrand, 'qualcomm');
    });

    test('unknown backends, duplicates and non-positive numbers are dropped', () {
      final r = mapProbeResult(
        header(
          backends: ['GPU', 'gpu', 'tpu', ' cpu '],
          maxContextTokens: 0,
          socName: '  ',
        ),
      );
      expect(r.backends, ['gpu', 'cpu']);
      expect(r.maxContextTokens, isNull);
      expect(r.socName, isNull);
    });
  });

  group('LiteRtModelProbe', () {
    late FakeLlmHost host;
    late LiteRtModelProbe probe;

    setUp(() {
      host = FakeLlmHost();
      probe = LiteRtModelProbe(host: host);
    });

    test('maps the native header', () async {
      host.onProbe = (path) async =>
          path.endsWith('gemma.litertlm') ? header(vision: true) : null;
      final r = await probe.probe('/data/app/files/models/gemma.litertlm');
      expect(r!.inputModalities, {'text', 'vision'});
      expect(await probe.probe('/data/app/files/models/other.bin'), isNull);
    });

    test('never throws and never loads the runtime', () async {
      host.onProbe = (_) async => throw PlatformException(code: 'jni');
      expect(await probe.probe('/x.litertlm'), isNull);
      expect(await probe.probe('  '), isNull);
      expect(host.calls, ['probe'], reason: 'empty path is not sent');
      expect(host.calls, isNot(contains('load')));
      expect(host.calls, isNot(contains('unload')));
    });

    test('a null header (unreadable file or outside app storage) is null', () async {
      host.onProbe = (_) async => null;
      expect(await probe.probe('/sdcard/Download/gemma.litertlm'), isNull);
    });
  });
}
