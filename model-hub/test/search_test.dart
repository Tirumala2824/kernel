import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:model_hub/model_hub.dart';
import 'package:model_hub/src/hub_search.dart';

import 'support/doubles.dart';

void main() {
  late ScriptedPlatform platform;
  late Directory dir;

  ModelHub hub({Embedder? embedder}) => ModelHub.withPlatform(
    platform: platform,
    http: RecordingHttp(),
    probe: HeaderProbe(),
    embedder: embedder,
    assets: FileAssets(),
    storageDir: dir,
  );

  setUp(() {
    platform = ScriptedPlatform();
    dir = tempDir();
  });

  test('semantic ranking with the injected embedder (searchQuery vs searchDocument, dim 256)', () async {
    final e = BagOfWordsEmbedder();
    final h = hub(embedder: e);
    final hits = await h.search.search('sound classifier for insects', limit: 3);
    expect(hits.first.entry!.id, yamnetId);
    expect(hits.first.title, 'YAMNet sound classifier');
    expect(hits.first.snippet, isNotNull);
    for (final hit in hits) {
      expect(hit.score, inInclusiveRange(-1.0, 1.0));
    }
    expect(hits.length, 3);
    final docs = e.calls.where((c) => c.$2 == EmbeddingTask.searchDocument);
    final queries = e.calls.where((c) => c.$2 == EmbeddingTask.searchQuery);
    expect(docs.length, 13, reason: 'every catalog entry indexed once');
    expect(queries.single.$1, 'sound classifier for insects');

    final emb = await h.search.search('semantic embedding retrieval', limit: 1);
    expect(emb.single.entry!.repoId, contains('embeddinggemma'));
  });

  test('document vectors are cached as app-private JSON and reused', () async {
    final e = BagOfWordsEmbedder();
    await hub(embedder: e).search.search('chat');
    expect(e.documentCalls, 13);
    expect(File('${dir.path}/search_index.json').existsSync(), isTrue);

    final e2 = BagOfWordsEmbedder();
    await hub(embedder: e2).search.search('chat');
    expect(e2.documentCalls, 0, reason: 'loaded from the cache');

    final e3 = BagOfWordsEmbedder()..version = 'bow-2';
    await hub(embedder: e3).search.search('chat');
    expect(e3.documentCalls, 13, reason: 'new model version re-embeds');

    final h4 = hub(embedder: e3);
    await h4.search.reindex();
    expect(e3.documentCalls, 26);
  });

  test('keyword fallback without an embedder or when it is unavailable', () async {
    final plain = await hub().search.search('segmentation', limit: 2);
    expect(plain.first.entry!.repoId, 'magic_touch');
    expect(plain.first.score, inInclusiveRange(0.0, 1.0));

    final off = BagOfWordsEmbedder()..available = false;
    final hits = await hub(embedder: off).search.search('YAMNet');
    expect(hits.first.entry!.id, yamnetId);
    expect(off.calls, isEmpty);
    expect(await hub().search.search('   '), isEmpty);
  });

  test('installed files without a catalog match are searchable', () async {
    platform
      ..hubPaths = const HubPaths(filesDir: '/f', modelsDir: '/m')
      ..addFile('/m/x/y/custom-bird-sounds.tflite', 10, 'e' * 64);
    final h = hub();
    await h.registry.rescan();
    final hits = await h.search.search('custom bird');
    expect(hits.first.installed!.path, '/m/x/y/custom-bird-sounds.tflite');
    expect(hits.first.entry, isNull);
  });

  test('search documents carry title, description and capability words', () {
    final docs = buildSearchDocs(
      parseKernelCatalog(readAsset('kernel_catalog.json')).entries,
      const [],
    );
    final y = docs.firstWhere((d) => d.key == yamnetId);
    expect(y.text, contains('YAMNet sound classifier'));
    expect(y.text, contains('sound classification'));
    expect(textHash(y.text), textHash(y.text));
    expect(textHash('a'), isNot(textHash('b')));
  });
}
