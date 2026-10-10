import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:model_hub/model_hub.dart';

import 'support/doubles.dart';

void main() {
  group('Gallery allowlist parse', () {
    final list = parseAllowlist(readAsset('gallery_allowlist_1_0_20.json'))!;

    test('bundled 1_0_20 snapshot parses all entries', () {
      expect(list.models, hasLength(11));
      final g = list.models.firstWhere((m) => m.name == 'Gemma-4-E2B-it');
      expect(g.modelId, 'litert-community/gemma-4-E2B-it-litert-lm');
      expect(g.commitHash, '6e5c4f1e395deb959c494953478fa5cec4b8008f');
      expect(g.sizeInBytes, 2588147712);
      expect(g.minDeviceMemoryInGb, 8);
      expect(g.llmSupportImage && g.llmSupportAudio, isTrue);
      expect(g.defaultConfig['topK'], 64);
      expect(g.defaultConfig['accelerators'], 'gpu,cpu');
      expect(g.updatableModelFiles.single['commitHash'], isNotNull);
      final mt = list.models.firstWhere((m) => m.modelId == 'magic_touch');
      expect(mt.url, startsWith('https://storage.googleapis.com/'));
    });

    test('lenient: unknown keys, wrong types and bad entries', () {
      final l = parseAllowlist('''
      {"models":[
        {"name":"A","modelId":"o/a","modelFile":"a.litertlm","sizeInBytes":"12",
         "futureKey":{"x":1},"taskTypes":["llm_chat", 3],"disabled":"false",
         "defaultConfig":"oops","minDeviceMemoryInGb":6.0},
        {"name":"no file","modelId":"o/b"},
        "not an object",
        {"name":"C","modelId":"o/c","modelFile":"c.tflite","disabled":true}
      ], "aicoreRequirements":{"k":1}, "flags":[1]}
      ''')!;
      expect(l.models.map((m) => m.name), ['A', 'C']);
      final a = l.models.first;
      expect(a.sizeInBytes, 12);
      expect(a.taskTypes, ['llm_chat', '3']);
      expect(a.defaultConfig, isEmpty);
      expect(a.minDeviceMemoryInGb, 6);
      expect(l.aicoreRequirements, {'k': 1});
      expect(l.flags, isNull);
      expect(parseAllowlist('not json'), isNull);
      expect(parseAllowlist('{"models":{}}'), isNull);
      // Disabled entries never become catalog entries.
      expect(buildGalleryEntries(l).map((e) => e.name), ['A']);
    });

    test('Gallery versionName to allowlist key', () {
      expect(galleryVersionKey('1.0.20'), '1_0_20');
      expect(galleryVersionKey('1.0.21-beta (2)'), '1_0_21');
      expect(galleryVersionKey('beta'), isNull);
      expect(galleryVersionKey(null), isNull);
    });
  });

  group('Gallery entries', () {
    final entries = buildGalleryEntries(
      parseAllowlist(readAsset('gallery_allowlist_1_0_20.json'))!,
      socKey: 'sm8850',
    );
    CatalogEntry byName(String n) => entries.firstWhere((e) => e.name == n);

    test('download URL rule: url ?: HF resolve at the pinned commit', () {
      final g = byName('Gemma-4-E2B-it');
      expect(
        g.downloadUrl,
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/'
        'resolve/6e5c4f1e395deb959c494953478fa5cec4b8008f/gemma-4-E2B-it.litertlm?download=true',
      );
      expect(g.id, gemmaId);
      expect(g.source, ModelSource.galleryCatalog);
      // Gallery publishes no sha256/licence: unknown and gated until resolved.
      expect(g.sha256, isNull);
      expect(g.license, 'unknown');
      expect(g.gated, isTrue);
      final mt = byName('Magic touch');
      expect(mt.downloadUrl, contains('interactive_segmentation.task'));
      expect(mt.format, ModelFormat.mediapipeTask);
    });

    test('capability inference', () {
      expect(byName('Gemma-4-E2B-it').capabilities, {
        ModelCapability.textGen,
        ModelCapability.imageIn,
        ModelCapability.audioIn,
      });
      expect(byName('Gemma3-1B-IT').capabilities, {ModelCapability.textGen});
      expect(byName('TinyGarden-270M').capabilities, {ModelCapability.textGen});
      expect(byName('EmbeddingGemma-2 (GPU)').capabilities, {
        ModelCapability.embedText,
        ModelCapability.embedImage,
      });
      expect(byName('Magic touch').capabilities, {ModelCapability.segment});
    });

    const socJson = '''
    {"models":[
      {"name":"Gen","modelId":"o/gen","modelFile":"gen.litertlm",
       "commitHash":"1111111111111111111111111111111111111111","sizeInBytes":100,
       "defaultConfig":{"accelerators":"gpu,cpu"},"taskTypes":["llm_chat"],
       "socToModelFiles":{"SM8850":{"modelFile":"gen_qualcomm_sm8850.litertlm",
         "commitHash":"2222222222222222222222222222222222222222","sizeInBytes":120}}},
      {"name":"NpuOnly","modelId":"o/npu","modelFile":"npu.litertlm",
       "commitHash":"3333333333333333333333333333333333333333","sizeInBytes":50,
       "defaultConfig":{"accelerators":"npu"},"taskTypes":["llm_chat"],
       "socToModelFiles":{"sm8750":{"url":"https://huggingface.co/o/npu/resolve/4444444444444444444444444444444444444444/npu_sm8750.litertlm?download=true",
         "modelFile":"npu_sm8750.litertlm","sizeInBytes":55}}}
    ]}''';

    test('SoC override adds a variant with file, commit, url and size', () {
      final out = buildGalleryEntries(
        parseAllowlist(socJson)!,
        socKey: 'sm8850',
      );
      expect(out, hasLength(2), reason: 'generic + sm8850 variant; NPU-only dropped');
      final generic = out.firstWhere((e) => e.socVariant == null);
      expect(generic.fileName, 'gen.litertlm');
      expect(generic.revision, '1111111111111111111111111111111111111111');
      final v = out.firstWhere((e) => e.socVariant == 'sm8850');
      expect(v.fileName, 'gen_qualcomm_sm8850.litertlm');
      expect(v.revision, '2222222222222222222222222222222222222222');
      expect(v.sizeBytes, 120);
      expect(
        v.downloadUrl,
        'https://huggingface.co/o/gen/resolve/2222222222222222222222222222222222222222/gen_qualcomm_sm8850.litertlm?download=true',
      );
      expect(downloadBlockReason(v), 'gated'); // unresolved, and NPU anyway
    });

    test('NPU-only entries are dropped without an SoC match', () {
      final none = buildGalleryEntries(parseAllowlist(socJson)!);
      expect(none.map((e) => e.repoId), ['o/gen']);
      final match = buildGalleryEntries(
        parseAllowlist(socJson)!,
        socKey: 'sm8750',
      );
      final npu = match.firstWhere((e) => e.repoId == 'o/npu');
      expect(npu.socVariant, 'sm8750');
      expect(npu.downloadUrl, contains('npu_sm8750.litertlm'));
      expect(npu.sizeBytes, 55);
      expect(npu.revision, '3333333333333333333333333333333333333333');
    });
  });

  group('Kernel catalog and merge', () {
    final kernel = parseKernelCatalog(readAsset('kernel_catalog.json'));
    final gallery = buildGalleryEntries(
      parseAllowlist(readAsset('gallery_allowlist_1_0_20.json'))!,
    );

    test('Kernel entries are pinned with sha256, licence and capabilities', () {
      expect(kernel.entries, hasLength(5));
      final g = kernel.entries.firstWhere((e) => e.id == gemmaId);
      expect(g.sha256, gemmaSha);
      expect(g.sizeBytes, gemmaSize);
      expect(g.license, 'apache-2.0');
      expect(g.gated, isFalse);
      expect(g.source, ModelSource.kernelCatalog);
      expect(downloadBlockReason(g), isNull);
      final e = kernel.entries.firstWhere((e) => e.id == embedId);
      expect(e.sha256, embedSha);
      expect(e.capabilities, {
        ModelCapability.embedText,
        ModelCapability.embedImage,
        ModelCapability.embedAudio,
      });
      final y = kernel.entries.firstWhere((e) => e.id == yamnetId);
      expect(y.downloadUrl, startsWith('https://storage.googleapis.com/mediapipe-models/'));
      expect(y.format, ModelFormat.tflite);
      expect(y.capabilities, {ModelCapability.audioClassify});
      expect(isPinnedRevision(y.revision), isTrue);
      expect(y.sha256!.startsWith(y.revision), isTrue);
      expect(downloadBlockReason(y), isNull);
      final insect = kernel.entries.firstWhere(
        (e) => e.repoId == 'ganesh333/kernel-insect-classifier',
      );
      expect(insect.sha256, '55ad541b87d1ae0bae5a71c7ec9091fc40617051f479ac3f12996bacda6f597e');
      expect(insect.sizeBytes, 646352);
      expect(insect.capabilities, {ModelCapability.audioClassify});
      expect(insect.format, ModelFormat.tflite);
      expect(downloadBlockReason(insect), isNull);
      final mt = kernel.entries.firstWhere((e) => e.repoId == 'magic_touch');
      expect(downloadBlockReason(mt), 'license_not_approved');
      expect(kernel.preference[gemmaId], 100);
    });

    test('merge: Kernel wins over Gallery, duplicates collapse', () {
      final merged = mergeEntries([kernel.entries, gallery]);
      // 5 Kernel + 11 Gallery - 3 duplicates (Gemma 4 E2B, EmbeddingGemma, Magic touch).
      expect(merged, hasLength(13));
      final g = merged.where((e) => e.repoId.contains('gemma-4-E2B'));
      expect(g.single.source, ModelSource.kernelCatalog);
      expect(g.single.sha256, gemmaSha);
      final mt = merged.where((e) => e.repoId == 'magic_touch').single;
      expect(mt.source, ModelSource.kernelCatalog);
      expect(mt.downloadUrl, contains('/int8/1/'));
      expect(merged.map((e) => e.id).toSet(), hasLength(merged.length));
    });

    test('merge dedupes by (repo, file) across revisions and by sha256', () {
      CatalogEntry e(String repo, String rev, String file, String? sha, ModelSource s) =>
          CatalogEntry(
            id: entryIdOf(repo, rev, file),
            name: file,
            repoId: repo,
            revision: rev,
            fileName: file,
            sizeBytes: 1,
            sha256: sha,
            format: ModelFormat.litertlm,
            capabilities: const {ModelCapability.textGen},
            license: 'apache-2.0',
            gated: false,
            source: s,
            downloadUrl: hfResolveUrl(repo, rev, file),
          );
      final a = 'a' * 40, b = 'b' * 40, h = 'c' * 64;
      final merged = mergeEntries([
        [e('o/x', a, 'x.litertlm', null, ModelSource.galleryCatalog)],
        [
          e('o/x', b, 'x.litertlm', 'd' * 64, ModelSource.huggingFaceSearch),
          e('o/y', a, 'y.litertlm', h, ModelSource.huggingFaceSearch),
          e('o/y-copy', a, 'y.litertlm', h, ModelSource.huggingFaceSearch),
        ],
      ]);
      expect(merged.map((m) => m.repoId), ['o/x', 'o/y']);
      expect(merged.first.revision, a, reason: 'curated pin shadows newer main');
    });
  });
}
