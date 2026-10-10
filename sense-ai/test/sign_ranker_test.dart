import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sense_ai/sense_ai.dart';

import 'support/test_embedder.dart';

const _prompts = [
  SignPrompt('droppings', 'mouse droppings on a floor'),
  SignPrompt('roach', 'a cockroach'),
  SignPrompt('web', 'a spider web in a corner'),
  SignPrompt('floor', 'a clean empty tiles', background: true),
];

const _box = NormalizedBox(left: 0.1, top: 0.2, width: 0.3, height: 0.3);

ImageTile _tile(String id, String content) =>
    ImageTile(candidateId: id, box: _box, image: bytesOf(content));

void main() {
  final at = DateTime.utc(2026, 10, 10, 12);

  TestEmbedder embedder() =>
      TestEmbedder(['droppings', 'cockroach', 'web', 'tiles']);

  SignRanker ranker(TestEmbedder e, {double minSimilarity = 0.2}) => SignRanker(
    e,
    prompts: _prompts,
    minSimilarity: minSimilarity,
    clock: () => at,
  );

  test(
    'best prompt becomes an embeddingMatch with its id and similarity',
    () async {
      final e = embedder();
      final r = ranker(e);
      final out = await r.rankTiles([_tile('motion-1', 'a cockroach')]);
      expect(out, hasLength(1));
      final c = out.single;
      expect(c.kind, SignalKind.embeddingMatch);
      expect(c.source, SignalSource.camera);
      expect(c.hint, 'roach');
      expect(c.score, closeTo(1.0, 1e-6));
      expect(c.id, 'sign:motion-1');
      expect(c.box, same(_box));
      expect(c.detectedAt, at);
    },
  );

  test('similarity is the cosine, not a probability', () async {
    final r = ranker(embedder());
    // Mentions two concepts: cosine 1/sqrt(2) with each.
    final matches = await r.scoreImage(bytesOf('cockroach near a web'));
    expect(matches.first.similarity, closeTo(0.7071, 1e-3));
    expect(
      matches.map((m) => m.similarity),
      orderedEquals(
        [...matches.map((m) => m.similarity)]..sort((a, b) => b.compareTo(a)),
      ),
    );
  });

  test('prompt vectors are embedded once and cached', () async {
    final e = embedder();
    final r = ranker(e);
    await r.rankTiles([_tile('a', 'cockroach'), _tile('b', 'droppings')]);
    await r.rankTiles([_tile('c', 'web')]);
    expect(e.textCalls, hasLength(_prompts.length));
    expect(e.imageCalls, 3);
  });

  test('a new embedder model version re-embeds the prompts', () async {
    final e = embedder();
    final r = ranker(e);
    await r.rankTiles([_tile('a', 'cockroach')]);
    e.version = 'test-embed-2';
    final out = await r.rankTiles([_tile('b', 'cockroach')]);
    expect(e.textCalls, hasLength(2 * _prompts.length));
    expect(out.single.hint, 'roach');
  });

  test('background best match or low similarity gives no candidate', () async {
    final r = ranker(embedder(), minSimilarity: 0.8);
    expect(
      await r.rankTiles([_tile('a', 'clean tiles')]),
      isEmpty,
      reason: 'background',
    );
    expect(
      await r.rankTiles([_tile('b', 'a sofa')]),
      isEmpty,
      reason: 'unrelated',
    );
    expect(
      await r.rankTiles([_tile('c', 'cockroach on a web')]),
      isEmpty,
      reason: '0.71 < 0.8',
    );
  });

  test('unavailable embedder: no candidates and no model calls', () async {
    final e = embedder()..available = false;
    expect(await ranker(e).rankTiles([_tile('a', 'cockroach')]), isEmpty);
    expect(e.textCalls, isEmpty);
    expect(e.imageCalls, 0);
  });

  test('image vectors from another model or size are not compared', () async {
    final e = embedder()..imageVersion = 'other-model';
    expect(await ranker(e).rankTiles([_tile('a', 'cockroach')]), isEmpty);
    final f = embedder()..imageDim = 128;
    expect(await ranker(f).rankTiles([_tile('a', 'cockroach')]), isEmpty);
  });

  test('failed prompt embeddings are retried on the next call', () async {
    final e = embedder()..nullTexts.add('a cockroach');
    final r = ranker(e);
    final first = await r.rankTiles([_tile('a', 'cockroach')]);
    expect(first, isEmpty, reason: 'no roach vector yet');
    e.nullTexts.clear();
    final second = await r.rankTiles([_tile('b', 'cockroach')]);
    expect(second.single.hint, 'roach');
    expect(e.textCalls.where((t) => t == 'a cockroach'), hasLength(2));
    expect(
      e.textCalls.where((t) => t == 'a spider web in a corner'),
      hasLength(1),
    );
  });

  test('embedder errors never throw', () async {
    final e = embedder()..throwOnImage = true;
    expect(await ranker(e).rankTiles([_tile('a', 'cockroach')]), isEmpty);
    expect(await ranker(e).rankTile(_tile('a', 'cockroach')), isNull);
  });

  test(
    'default prompts cover the pest signs and include background prompts',
    () {
      final ids = defaultSignPrompts.map((p) => p.id).toSet();
      expect(ids, hasLength(defaultSignPrompts.length), reason: 'unique ids');
      expect(
        ids,
        containsAll([
          'rodent_droppings',
          'cockroach',
          'gecko',
          'spider_web',
          'termite_mud_tube',
        ]),
      );
      expect(defaultSignPrompts.where((p) => p.background), isNotEmpty);
      expect(
        defaultSignPrompts.firstWhere((p) => p.id == 'gecko').text,
        'a gecko on a wall',
      );
    },
  );

  test('works with the default prompt list', () async {
    final e = TestEmbedder(['gecko']);
    final out = await SignRanker(e).rankTiles([_tile('grid-r0c0', 'a gecko')]);
    expect(out.single.hint, 'gecko');
  });
}
