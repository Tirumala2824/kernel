import 'package:data_operations/src/services/knowledge_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/cards.dart';
import 'support/harness.dart';

void main() {
  group('parseKnowledgePack', () {
    test('keeps valid cards and skips ones breaking the schema rules', () {
      final pack = parseKnowledgePack(
        testPack(
          cards: [
            ...validTestCards(),
            testCard('no_english', names: {'hi': 'कुछ'}),
            testCard('No-Snake-Case'),
            testCard('no_sources', sources: const []),
            testCard('bad_group', group: 'dragon'),
            testCard('protected_no_legal', safety: 'protectedWildlife'),
            testCard('blank_review', reviewStatus: ' '),
            testCard('german_cockroach'), // duplicate id: first wins
          ],
        ),
      );
      expect(pack.version, 'kernel-cards-test-0.1');
      expect(
        [for (final c in pack.cards) c.id],
        [
          'german_cockroach',
          'house_rat',
          'indian_red_scorpion',
          'bengal_monitor',
        ],
      );
      expect(pack.skipped, [
        'no_english',
        'No-Snake-Case',
        'no_sources',
        'bad_group',
        'protected_no_legal',
        'blank_review',
        'german_cockroach',
      ]);
      final roach = pack.cards.first;
      expect(roach.names, {'en': 'German cockroach', 'hi': 'तिलचट्टा'});
      expect(roach.group, PestGroup.insect);
      expect(roach.safety, SafetyLevel.caution);
      expect(roach.signs, ['Pepper-like droppings', 'Egg cases (oothecae)']);
      expect(roach.reviewStatus, 'needs-expert-review');
      expect(pack.cards.last.legal, 'Fixture legal text.');
    });

    test('rejects an unusable document', () {
      expect(() => parseKnowledgePack('not json'), throwsFormatException);
      expect(() => parseKnowledgePack('[]'), throwsFormatException);
      expect(() => parseKnowledgePack('{"cards": []}'), throwsFormatException);
      expect(
        () => parseKnowledgePack('{"version": "v", "cards": {}}'),
        throwsFormatException,
      );
    });
  });

  group('loading', () {
    test('a fresh install without a source has no cards', () async {
      final h = await Harness.create();
      addTearDown(h.dispose);
      expect(await h.ops.knowledge.all(), isEmpty);
      expect(await h.ops.knowledge.get('german_cockroach'), isNull);
      expect(await h.ops.knowledge.search('cockroach'), isEmpty);
    });

    test('the pack is loaded on first use, mirrored into the table and '
        'served by id', () async {
      var reads = 0;
      final h = await Harness.create(
        knowledgeCardsJson: () async {
          reads++;
          return testPack();
        },
      );
      addTearDown(h.dispose);
      final all = await h.ops.knowledge.all();
      expect(
        [for (final c in all) c.id],
        [
          'bengal_monitor',
          'german_cockroach',
          'house_rat',
          'indian_red_scorpion',
        ],
      );
      final rat = (await h.ops.knowledge.get('house_rat'))!;
      expect(rat.safety, SafetyLevel.medicalRisk);
      expect(rat.sources, ['https://fixture.invalid/source']);
      await h.ops.knowledge.all();
      expect(reads, 1, reason: 'read once, then cached');
    });

    test('a changed pack updates cards and removes dropped ones on the next '
        'open', () async {
      final executor = TestDatabase.shared();
      addTearDown(executor.close);
      var pack = testPack();
      final first = await Harness.create(
        executor: executor.connection(),
        knowledgeCardsJson: () async => pack,
      );
      await first.ops.knowledge.all();
      await first.dispose();

      final cards = validTestCards()..removeAt(3);
      cards[0] = testCard(
        'german_cockroach',
        names: {'en': 'German cockroach'},
        summary: 'Edited summary.',
      );
      pack = testPack(version: 'kernel-cards-test-0.2', cards: cards);
      final second = await Harness.create(
        executor: executor.connection(),
        knowledgeCardsJson: () async => pack,
      );
      addTearDown(second.dispose);
      final all = await second.ops.knowledge.all();
      expect(
        [for (final c in all) c.id],
        ['german_cockroach', 'house_rat', 'indian_red_scorpion'],
      );
      expect(all.first.summary, 'Edited summary.');
      expect(all.first.names, {'en': 'German cockroach'});
    });

    test('a failing or malformed source keeps the stored cards and is '
        'retried', () async {
      var calls = 0;
      final h = await Harness.create(
        knowledgeCardsJson: () async {
          calls++;
          if (calls == 1) throw StateError('asset missing');
          if (calls == 2) return '{oops';
          return testPack();
        },
      );
      addTearDown(h.dispose);
      expect(await h.ops.knowledge.all(), isEmpty);
      expect(await h.ops.knowledge.search('rat'), isEmpty);
      expect(await h.ops.knowledge.all(), hasLength(4));
      expect(calls, 3);
    });
  });

  group('keyword search', () {
    late Harness h;
    setUp(() async {
      h = await Harness.create(knowledgeCardsJson: () async => testPack());
    });
    tearDown(() => h.dispose());

    test('matches names first, then signs, then the summary', () async {
      final byName = await h.ops.knowledge.search('cockroach');
      expect(byName.first.card.id, 'german_cockroach');
      expect(byName.first.score, 1.0);

      // "gnaw" appears in the rat's signs and summary: sign weight wins.
      final bySign = await h.ops.knowledge.search('gnaw');
      expect(bySign.single.card.id, 'house_rat');
      expect(bySign.single.score, closeTo(2 / 3, 1e-9));

      final bySummary = await h.ops.knowledge.search('venomous');
      expect(bySummary.single.card.id, 'indian_red_scorpion');
      expect(bySummary.single.score, closeTo(1 / 3, 1e-9));
    });

    test('folds plurals, drops stop words, finds other-language names and '
        'respects the limit', () async {
      expect(
        (await h.ops.knowledge.search('the cockroaches in my kitchen'))
            .first
            .card
            .id,
        'german_cockroach',
      );
      expect((await h.ops.knowledge.search('rats')).first.card.id, 'house_rat');
      expect(
        (await h.ops.knowledge.search('तिलचट्टा')).single.card.id,
        'german_cockroach',
      );
      final many = await h.ops.knowledge.search(
        'cockroach rat scorpion monitor',
        limit: 2,
      );
      expect(many, hasLength(2));
      expect(await h.ops.knowledge.search('  '), isEmpty);
      expect(await h.ops.knowledge.search('rat', limit: 0), isEmpty);
      expect(await h.ops.knowledge.search('xylophone'), isEmpty);
    });
  });

  group('semantic search', () {
    test('falls back to keywords until vectors are cached, then ranks by '
        'cosine similarity', () async {
      final embedder = ConceptEmbedder();
      final h = await Harness.create(
        knowledgeCardsJson: () async => testPack(),
        embedder: embedder,
      );
      addTearDown(h.dispose);
      final service = h.ops.knowledge as DriftKnowledgeService;

      // "roach" is no word prefix of any card text: keywords find nothing.
      expect(await h.ops.knowledge.search('roach behind the fridge'), isEmpty);
      // That search scheduled indexing in the background.
      expect(await service.indexEmbeddings(), isTrue);
      expect(embedder.documentCalls, 4);

      final hits = await h.ops.knowledge.search('roach behind the fridge');
      expect(hits.first.card.id, 'german_cockroach');
      expect(hits.first.score, greaterThan(0.9));
      expect(hits, hasLength(3));
      final stinger = await h.ops.knowledge.search('it can sting', limit: 1);
      expect(stinger.single.card.id, 'indian_red_scorpion');

      // Cached: a second index run embeds nothing new.
      expect(await service.indexEmbeddings(), isTrue);
      expect(embedder.documentCalls, 4);
    });

    test(
      'vectors are per model version and recomputed when a card changes',
      () async {
        final embedder = ConceptEmbedder();
        final executor = TestDatabase.shared();
        addTearDown(executor.close);
        var pack = testPack();
        final first = await Harness.create(
          executor: executor.connection(),
          knowledgeCardsJson: () async => pack,
          embedder: embedder,
        );
        final service = first.ops.knowledge as DriftKnowledgeService;
        expect(await service.indexEmbeddings(), isTrue);
        expect(embedder.documentCalls, 4);

        embedder.version = 'embed-test-2';
        expect(
          await first.ops.knowledge.search('roach'),
          isEmpty,
          reason: 'new model version: keyword fallback while re-indexing',
        );
        expect(await service.indexEmbeddings(), isTrue);
        expect(embedder.documentCalls, 8);
        expect(
          (await first.ops.knowledge.search('roach')).first.card.id,
          'german_cockroach',
        );
        await first.dispose();

        final cards = validTestCards();
        cards[1] = testCard(
          'house_rat',
          names: {'en': 'House rat'},
          group: 'rodent',
          safety: 'medicalRisk',
          summary: 'Edited rodent summary.',
        );
        pack = testPack(cards: cards);
        final second = await Harness.create(
          executor: executor.connection(),
          knowledgeCardsJson: () async => pack,
          embedder: embedder,
        );
        addTearDown(second.dispose);
        final again = second.ops.knowledge as DriftKnowledgeService;
        expect(await again.indexEmbeddings(), isTrue);
        expect(embedder.documentCalls, 9, reason: 'only the edited card');
      },
    );

    test('never throws: a missing, busy or failing embedder means keyword '
        'search', () async {
      final embedder = ConceptEmbedder();
      final h = await Harness.create(
        knowledgeCardsJson: () async => testPack(),
        embedder: embedder,
      );
      addTearDown(h.dispose);
      final service = h.ops.knowledge as DriftKnowledgeService;

      embedder.available = false;
      expect((await h.ops.knowledge.search('rat')).first.card.id, 'house_rat');
      expect(await service.indexEmbeddings(), isFalse);

      embedder.available = true;
      embedder.version = null;
      expect((await h.ops.knowledge.search('rat')).first.card.id, 'house_rat');

      embedder.version = 'embed-test-1';
      embedder.refuseDocuments = true;
      expect(await service.indexEmbeddings(), isFalse);
      expect((await h.ops.knowledge.search('rat')).first.card.id, 'house_rat');

      embedder.refuseDocuments = false;
      embedder.failing = true;
      expect((await h.ops.knowledge.search('rat')).first.card.id, 'house_rat');
      expect(await service.indexEmbeddings(), isFalse);
      expect(embedder.queryCalls, 0);
    });
  });
}
