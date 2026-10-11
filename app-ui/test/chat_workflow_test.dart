import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/agents/media_picker_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:kernel_app/agents/orchestrator_agent.dart';

import 'support/chat_fixtures.dart';
export 'support/chat_fixtures.dart';

AdviceText _advice(String text, {bool complete = true}) => AdviceText(
  text: text,
  complete: complete,
  modelVersion: 'test-guide',
  languageTag: 'en',
  generatedAt: DateTime.utc(2026),
);

void main() {
  test('same-ID card update adds newly observed medical risk to guide and response', () async {
    final original = chatCard();
    final latest = chatCard(extraSafety: {SafetyLevel.medicalRisk});
    final knowledge = ChatKnowledge()..cards = [original];
    final analyzer = ChatAnalyzer();
    final agent = OrchestratorAgent(
      knowledge: () => knowledge,
      analyzer: () => analyzer,
    );
    final photo = await agent.execute(
      OrchestratorTask(userMessage: '', visualMedia: chatPhoto()),
    );
    expect(photo.analysis, same(analyzer.result));
    expect(photo.safetyLevels, {SafetyLevel.caution});
    knowledge.cards = [latest];
    final followUp = await agent.execute(
      OrchestratorTask(
        userMessage: 'What next?',
        contextAnalysis: photo.analysis,
      ),
    );
    const expectedSafety = {SafetyLevel.caution, SafetyLevel.medicalRisk};
    expect(followUp.safetyLevels, expectedSafety);
    expect(followUp.cards.single.id, original.id);
    expect(followUp.cards.single.extraSafety, {SafetyLevel.medicalRisk});
    final guide = analyzer.guides.single;
    expect(guide.analysis, same(photo.analysis));
    expect(guide.cards.single.id, original.id);
    expect(guide.cards.single.extraSafety, {SafetyLevel.medicalRisk});
    expect(
      safetyConcerns(aiLevel: guide.analysis.safety, cards: guide.cards),
      expectedSafety,
    );
    expect(followUp.analysis, isNull);
    expect(original.extraSafety, isEmpty);
  });

  test(
    'same-ID reverse update retains protected concern with newest card content',
    () async {
      KnowledgeCard revision({
        required String name,
        required PestGroup group,
        required SafetyLevel safety,
        required Set<SafetyLevel> extraSafety,
      }) => KnowledgeCard(
        id: 'test-weevil',
        names: {'en': '$name test name'},
        group: group,
        safety: safety,
        extraSafety: extraSafety,
        summary: '$name test summary',
        signs: ['$name test sign'],
        lookAlikes: ['$name test look-alike'],
        healthRisks: ['$name test health risk'],
        safeSteps: ['$name test safe step'],
        trapSteps: ['$name test trap step'],
        callProfessionalWhen: ['$name test professional referral'],
        firstAid: ['$name test first aid'],
        legal: '$name test legal note',
        sources: ['https://example.org/test-only/$name'],
        reviewStatus: '$name-test-review-status',
      );
      final original = revision(
        name: 'original',
        group: PestGroup.insect,
        safety: SafetyLevel.protectedWildlife,
        extraSafety: {SafetyLevel.medicalRisk},
      );
      final latest = revision(
        name: 'latest',
        group: PestGroup.other,
        safety: SafetyLevel.caution,
        extraSafety: {SafetyLevel.venomous},
      );
      final knowledge = ChatKnowledge()..cards = [original];
      final analyzer = ChatAnalyzer()
        ..result = chatAnalysis(safety: SafetyLevel.low);
      final agent = OrchestratorAgent(
        knowledge: () => knowledge,
        analyzer: () => analyzer,
      );
      final photo = await agent.execute(
        OrchestratorTask(userMessage: '', visualMedia: chatPhoto()),
      );
      expect(photo.safetyLevels, {
        SafetyLevel.protectedWildlife,
        SafetyLevel.medicalRisk,
      });
      knowledge.cards = [latest];
      final followUp = await agent.execute(
        OrchestratorTask(
          userMessage: 'What next?',
          contextAnalysis: photo.analysis,
        ),
      );
      const expectedSafety = {
        SafetyLevel.caution,
        SafetyLevel.venomous,
        SafetyLevel.protectedWildlife,
        SafetyLevel.medicalRisk,
      };
      expect(followUp.safetyLevels, expectedSafety);
      final guide = analyzer.guides.single;
      expect(guide.analysis, same(photo.analysis));
      expect(
        safetyConcerns(aiLevel: guide.analysis.safety, cards: guide.cards),
        expectedSafety,
      );
      for (final card in [followUp.cards.single, guide.cards.single]) {
        expect(card.id, latest.id);
        expect(card.names, latest.names);
        expect(card.group, latest.group);
        expect(card.safety, latest.safety);
        expect(card.extraSafety, {
          SafetyLevel.venomous,
          SafetyLevel.protectedWildlife,
          SafetyLevel.medicalRisk,
        });
        expect(card.summary, latest.summary);
        expect(card.signs, latest.signs);
        expect(card.lookAlikes, latest.lookAlikes);
        expect(card.healthRisks, latest.healthRisks);
        expect(card.safeSteps, latest.safeSteps);
        expect(card.trapSteps, latest.trapSteps);
        expect(card.callProfessionalWhen, latest.callProfessionalWhen);
        expect(card.firstAid, latest.firstAid);
        expect(card.legal, latest.legal);
        expect(card.sources, latest.sources);
        expect(card.reviewStatus, latest.reviewStatus);
      }
      expect(followUp.analysis, isNull);
      expect(photo.cards.single, same(original));
      expect(original.safety, SafetyLevel.protectedWildlife);
      expect(original.extraSafety, {SafetyLevel.medicalRisk});
      expect(latest.extraSafety, {SafetyLevel.venomous});

      // The merged safety must survive another turn without fresh knowledge.
      knowledge.cards = [];
      final later = await agent.execute(
        OrchestratorTask(
          userMessage: 'Anything else?',
          contextAnalysis: photo.analysis,
        ),
      );
      expect(later.safetyLevels, expectedSafety);
      expect(later.cards.single, same(followUp.cards.single));
      expect(analyzer.guides, hasLength(2));
      final laterGuide = analyzer.guides.last;
      expect(laterGuide.analysis, same(photo.analysis));
      expect(laterGuide.cards.single, same(followUp.cards.single));
      expect(
        safetyConcerns(
          aiLevel: laterGuide.analysis.safety,
          cards: laterGuide.cards,
        ),
        expectedSafety,
      );
    },
  );

  test(
    'follow-up retains observed card safety when knowledge later disappears',
    () async {
      final card = chatCard(
        extraSafety: {SafetyLevel.protectedWildlife, SafetyLevel.medicalRisk},
      );
      final knowledge = ChatKnowledge()..cards = [card];
      final analyzer = ChatAnalyzer();
      final agent = OrchestratorAgent(
        knowledge: () => knowledge,
        analyzer: () => analyzer,
      );
      final photo = await agent.execute(
        OrchestratorTask(userMessage: '', visualMedia: chatPhoto()),
      );
      knowledge.cards = [];
      final followUp = await agent.execute(
        OrchestratorTask(
          userMessage: 'What next?',
          contextAnalysis: photo.analysis,
        ),
      );
      expect(
        followUp.safetyLevels,
        containsAll([SafetyLevel.protectedWildlife, SafetyLevel.medicalRisk]),
      );
      expect(followUp.cards.single, same(card));
      expect(analyzer.guides.single.cards.single, same(card));
    },
  );

  // Characterization coverage for fallback branches and boundary preservation.
  test(
    'empty filtered or failing guide keeps actual knowledge and prior safety',
    () async {
      for (final output in <Stream<AdviceText>>[
        const Stream.empty(),
        Stream.fromIterable([
          _advice('partial', complete: false),
          _advice('  '),
        ]),
        Stream.error(StateError('test filtered guide')),
      ]) {
        final knowledge = ChatKnowledge()
          ..cards = [
            chatCard(extraSafety: {SafetyLevel.protectedWildlife}),
          ];
        final analyzer = ChatAnalyzer()..guideStream = output;
        final result =
            await OrchestratorAgent(
              analyzer: () => analyzer,
              knowledge: () => knowledge,
            ).execute(
              OrchestratorTask(
                userMessage: 'What next?',
                contextAnalysis: chatAnalysis(safety: SafetyLevel.venomous),
              ),
            );
        expect(result.generated, isNull);
        expect(result.cards.single, same(knowledge.cards.single));
        expect(
          result.safetyLevels,
          containsAll([SafetyLevel.venomous, SafetyLevel.protectedWildlife]),
        );
        expect(result.retryable, isFalse);
        expect(result.notices, isEmpty);
      }
    },
  );

  test(
    'fresh image guides from the actual result and all retrieved safety',
    () async {
      final matched = chatCard(extraSafety: {SafetyLevel.protectedWildlife});
      final other = chatCard(
        id: 'other',
        extraSafety: {SafetyLevel.medicalRisk},
      );
      final knowledge = ChatKnowledge()
        ..cards = [matched, other]
        ..searchCards = [other];
      final analyzer = ChatAnalyzer()
        ..guideOutput = [_advice('Keep distance.')];
      final result =
          await OrchestratorAgent(
            analyzer: () => analyzer,
            knowledge: () => knowledge,
          ).execute(
            OrchestratorTask(
              userMessage: 'What next?',
              visualMedia: chatPhoto(),
            ),
          );
      expect(analyzer.guides.single.analysis, same(analyzer.result));
      expect(analyzer.guides.single.cards, containsAll([matched, other]));
      expect(analyzer.images.single.allowedCardIds, ['test-weevil', 'other']);
      expect(
        result.safetyLevels,
        containsAll([SafetyLevel.protectedWildlife, SafetyLevel.medicalRisk]),
      );
      expect(result.generated, same(analyzer.guideOutput.single));
    },
  );

  test(
    'unbound providers allow ordinary text when only knowledge is bound',
    () async {
      final knowledge = ChatKnowledge();
      final container = ProviderContainer(
        overrides: [knowledgeServiceProvider.overrideWithValue(knowledge)],
      );
      addTearDown(container.dispose);
      final result = await container
          .read(orchestratorAgentProvider)
          .execute(const OrchestratorTask(userMessage: 'storage'));
      expect(result.cards.single, same(knowledge.cards.single));
      expect(result.retryable, isFalse);
      expect(result.notices, isEmpty);
    },
  );

  test(
    'throwing factories still preserve another requested modality',
    () async {
      final classifier = ChatSoundClassifier();
      final analyzer = ChatAnalyzer();
      final audioFailed =
          await OrchestratorAgent(
            soundClassifier: () => throw StateError('test audio binding'),
            analyzer: () => analyzer,
            knowledge: () => ChatKnowledge(),
          ).execute(
            OrchestratorTask(
              userMessage: '',
              audioMedia: chatAudio(),
              visualMedia: chatPhoto(),
            ),
          );
      expect(audioFailed.analysis, same(analyzer.result));
      expect(audioFailed.retryable, isTrue);
      final knowledgeFailed =
          await OrchestratorAgent(
            soundClassifier: () => classifier,
            knowledge: () => throw StateError('test knowledge binding'),
            analyzer: () => analyzer,
          ).execute(
            OrchestratorTask(
              userMessage: 'storage',
              audioMedia: chatAudio(),
              visualMedia: chatPhoto(),
            ),
          );
      expect(knowledgeFailed.sound, same(classifier.result));
      expect(
        knowledgeFailed.notices,
        containsAll([ChatNotice.noKnowledge, ChatNotice.imageUnavailable]),
      );
      expect(knowledgeFailed.retryable, isTrue);
    },
  );

  test(
    'failed text search offers retry rather than pretending it completed',
    () async {
      final result = await OrchestratorAgent(
        knowledge: () => ChatKnowledge()..fail = true,
      ).execute(const OrchestratorTask(userMessage: 'storage'));
      expect(result.cards, isEmpty);
      expect(result.generated, isNull);
      expect(result.retryable, isTrue);
      expect(result.notices, contains(ChatNotice.requestFailed));
    },
  );

  test(
    'new audio does not resolve or guide with stale photo context',
    () async {
      var unrelatedCalls = 0;
      final classifier = ChatSoundClassifier();
      final result =
          await OrchestratorAgent(
            soundClassifier: () => classifier,
            knowledge: () {
              unrelatedCalls++;
              throw StateError('not requested');
            },
            analyzer: () {
              unrelatedCalls++;
              throw StateError('not requested');
            },
          ).execute(
            OrchestratorTask(
              userMessage: '',
              audioMedia: chatAudio(),
              contextAnalysis: chatAnalysis(safety: SafetyLevel.venomous),
            ),
          );
      expect(unrelatedCalls, 0);
      expect(result.sound, same(classifier.result));
      expect(result.safetyLevels, isEmpty);
      expect(result.generated, isNull);
      expect(result.notices, isEmpty);
    },
  );

  test(
    'photo without curated labels is unavailable, not unconstrained inference',
    () async {
      final analyzer = ChatAnalyzer();
      final result = await OrchestratorAgent(
        analyzer: () => analyzer,
        knowledge: () => ChatKnowledge()..cards = [],
      ).execute(OrchestratorTask(userMessage: '', visualMedia: chatPhoto()));
      expect(analyzer.images, isEmpty);
      expect(result.analysis, isNull);
      expect(result.cards, isEmpty);
      expect(result.notices, contains(ChatNotice.imageUnavailable));
      expect(result.retryable, isFalse);
    },
  );

  test(
    'guide timeout cancels listening and preserves cards and all safety',
    () async {
      var cancelled = false;
      final stream = StreamController<AdviceText>(
        onCancel: () {
          cancelled = true;
        },
      );
      addTearDown(stream.close);
      final analyzer = ChatAnalyzer()..guideStream = stream.stream;
      final knowledge = ChatKnowledge()
        ..cards = [
          chatCard(
            extraSafety: {
              SafetyLevel.protectedWildlife,
              SafetyLevel.medicalRisk,
            },
          ),
        ];
      final pending =
          OrchestratorAgent(
            analyzer: () => analyzer,
            knowledge: () => knowledge,
            guideBudget: const Duration(milliseconds: 10),
          ).execute(
            OrchestratorTask(
              userMessage: 'What next?',
              contextAnalysis: chatAnalysis(safety: SafetyLevel.venomous),
            ),
          );
      stream.add(_advice('Partial only', complete: false));
      final result = await pending.timeout(const Duration(milliseconds: 300));
      expect(result.generated, isNull);
      expect(result.cards.single, same(knowledge.cards.single));
      expect(
        result.safetyLevels,
        containsAll([
          SafetyLevel.venomous,
          SafetyLevel.medicalRisk,
          SafetyLevel.protectedWildlife,
        ]),
      );
      expect(result.retryable, isFalse);
      expect(result.notices, isEmpty);
      expect(cancelled, isTrue);
    },
  );

  test('only complete nonempty guarded guide output is returned', () async {
    final finalAnswer = _advice('Keep a safe distance.');
    final analyzer = ChatAnalyzer()
      ..guideOutput = [
        _advice('Unsafe incomplete chunk', complete: false),
        _advice('  '),
        finalAnswer,
      ];
    final result =
        await OrchestratorAgent(
          analyzer: () => analyzer,
          knowledge: () => ChatKnowledge(),
        ).execute(
          OrchestratorTask(
            userMessage: 'What next?',
            contextAnalysis: chatAnalysis(),
          ),
        );
    expect(result.generated, same(finalAnswer));
  });

  test(
    'grounded follow-up passes only the question and actual analysis',
    () async {
      final prior = chatAnalysis(safety: SafetyLevel.venomous);
      final card = chatCard(extraSafety: {SafetyLevel.protectedWildlife});
      final knowledge = ChatKnowledge()
        ..cards = [card]
        ..searchCards = [];
      final answer = AdviceText(
        text: 'Keep your distance.',
        complete: true,
        modelVersion: 'test-guide',
        languageTag: 'hi',
        generatedAt: DateTime.utc(2026),
      );
      final analyzer = ChatAnalyzer()..guideOutput = [answer];
      final result =
          await OrchestratorAgent(
            analyzer: () => analyzer,
            knowledge: () => knowledge,
          ).execute(
            OrchestratorTask(
              userMessage: '  What should I do?  ',
              contextAnalysis: prior,
              languageTag: 'hi',
            ),
          );
      expect(analyzer.guides, hasLength(1));
      expect(analyzer.guides.single.analysis, same(prior));
      expect(analyzer.guides.single.cards.single, same(card));
      expect(analyzer.guides.single.question, 'What should I do?');
      expect(analyzer.guides.single.languageTag, 'hi');
      expect(analyzer.images, isEmpty);
      expect(knowledge.lookups, ['test-weevil']);
      expect(result.generated, same(answer));
      expect(result.cards.single, same(card));
      expect(
        result.safetyLevels,
        containsAll([SafetyLevel.venomous, SafetyLevel.protectedWildlife]),
      );
      expect(result.notices, isEmpty);
    },
  );

  test('slow services time out without discarding another modality', () async {
    final classifier = ChatSoundClassifier();
    final analyzer = ChatAnalyzer();
    final knowledge = ChatKnowledge();
    const slow = Duration(milliseconds: 60);
    final agent = OrchestratorAgent(
      soundClassifier: () => classifier,
      analyzer: () => analyzer,
      knowledge: () => knowledge,
      operationBudget: const Duration(milliseconds: 10),
      knowledgeBudget: const Duration(milliseconds: 10),
    );
    final task = OrchestratorTask(
      userMessage: 'storage',
      audioMedia: chatAudio(),
      visualMedia: chatPhoto(),
    );
    classifier.delay = slow;
    final audioTimeout = await agent.execute(task);
    expect(audioTimeout.sound, isNull);
    expect(audioTimeout.analysis, same(analyzer.result));
    expect(audioTimeout.notices, contains(ChatNotice.audioUnavailable));
    expect(audioTimeout.retryable, isTrue);
    classifier.delay = Duration.zero;
    analyzer.delay = slow;
    final imageTimeout = await agent.execute(task);
    expect(imageTimeout.sound, same(classifier.result));
    expect(imageTimeout.analysis, isNull);
    expect(imageTimeout.notices, contains(ChatNotice.imageUnavailable));
    expect(imageTimeout.retryable, isTrue);
    analyzer.delay = Duration.zero;
    knowledge.delay = slow;
    final knowledgeTimeout = await agent.execute(task);
    expect(knowledgeTimeout.sound, same(classifier.result));
    expect(knowledgeTimeout.cards, isEmpty);
    expect(
      knowledgeTimeout.notices,
      containsAll([ChatNotice.noKnowledge, ChatNotice.imageUnavailable]),
    );
    expect(knowledgeTimeout.retryable, isTrue);
  });

  test('unsupported attachments never resolve a service', () async {
    var calls = 0;
    for (final task in [
      OrchestratorTask(
        userMessage: '',
        audioMedia: chatAudio(name: 'sound.mp3'),
      ),
      OrchestratorTask(
        userMessage: '',
        audioMedia: PickedMedia(
          path: '',
          fileName: 'sound.wav',
          bytes: Uint8List(0),
          mediaType: 'audio',
        ),
      ),
      OrchestratorTask(
        userMessage: '',
        visualMedia: PickedMedia(
          path: '/test/movie.mp4',
          fileName: 'movie.mp4',
          bytes: Uint8List.fromList([1, 2]),
          mediaType: 'video',
        ),
      ),
      OrchestratorTask(
        userMessage: '',
        visualMedia: PickedMedia(
          path: '/test/empty.png',
          fileName: 'empty.png',
          bytes: Uint8List(0),
          mediaType: 'image',
        ),
      ),
    ]) {
      final result = await OrchestratorAgent(
        soundClassifier: () {
          calls++;
          throw StateError('not requested');
        },
        analyzer: () {
          calls++;
          throw StateError('not requested');
        },
        knowledge: () {
          calls++;
          throw StateError('not requested');
        },
      ).execute(task);
      expect(calls, 0);
      expect(result.notices, {ChatNotice.unsupportedMedia});
      expect(result.retryable, isFalse);
    }
  });

  test('invalid sound DTOs are withheld rather than repaired', () async {
    for (final invalid in [
      const InsectSoundResult(
        status: InsectSoundStatus.evaluated,
        label: 'Must not escape',
        level: InsectIdentificationLevel.species,
        topLabels: [ScoredLabel(label: 'Different species', score: 0.7)],
        modelVersion: 'test-model',
        modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
      ),
      const InsectSoundResult(
        status: InsectSoundStatus.rejected,
        label: 'Must not escape',
        level: InsectIdentificationLevel.species,
      ),
      const InsectSoundResult(
        status: InsectSoundStatus.evaluated,
        label: 'Missing provenance',
        level: InsectIdentificationLevel.species,
      ),
    ]) {
      final classifier = ChatSoundClassifier()..result = invalid;
      final result = await OrchestratorAgent(soundClassifier: () => classifier)
          .execute(OrchestratorTask(userMessage: '', audioMedia: chatAudio()));
      expect(result.sound, isNull);
      expect(result.notices, contains(ChatNotice.audioUnavailable));
      expect(result.retryable, isTrue);
    }
  });

  test(
    'missing services report availability without offering a retry',
    () async {
      final task = OrchestratorTask(
        userMessage: 'storage',
        audioMedia: chatAudio(),
        visualMedia: chatPhoto(),
      );
      for (final agent in [
        OrchestratorAgent(),
        OrchestratorAgent(
          soundClassifier: () => throw UnimplementedError(),
          analyzer: () => throw UnimplementedError(),
          knowledge: () => throw UnimplementedError(),
        ),
      ]) {
        final result = await agent.execute(task);
        expect(
          result.notices,
          containsAll([
            ChatNotice.audioUnavailable,
            ChatNotice.imageUnavailable,
            ChatNotice.noKnowledge,
          ]),
        );
        expect(result.retryable, isFalse);
        expect(result.sound, isNull);
        expect(result.analysis, isNull);
      }
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final unbound = await container
          .read(orchestratorAgentProvider)
          .execute(task);
      expect(
        unbound.notices,
        containsAll([
          ChatNotice.audioUnavailable,
          ChatNotice.imageUnavailable,
          ChatNotice.noKnowledge,
        ]),
      );
      expect(unbound.retryable, isFalse);
    },
  );

  test('a throwing modality preserves the other real results', () async {
    final classifier = ChatSoundClassifier()..fail = true;
    final analyzer = ChatAnalyzer();
    final knowledge = ChatKnowledge();
    final agent = OrchestratorAgent(
      soundClassifier: () => classifier,
      analyzer: () => analyzer,
      knowledge: () => knowledge,
    );
    final task = OrchestratorTask(
      userMessage: 'storage',
      audioMedia: chatAudio(),
      visualMedia: chatPhoto(),
    );
    final audioFailed = await agent.execute(task);
    expect(audioFailed.analysis, same(analyzer.result));
    expect(audioFailed.sound, isNull);
    expect(audioFailed.cards, isNotEmpty);
    expect(audioFailed.notices, {ChatNotice.audioUnavailable});
    expect(audioFailed.retryable, isTrue);
    classifier.fail = false;
    analyzer.fail = true;
    final imageFailed = await agent.execute(task);
    expect(imageFailed.sound, same(classifier.result));
    expect(imageFailed.analysis, isNull);
    expect(imageFailed.cards, isNotEmpty);
    expect(imageFailed.notices, {ChatNotice.imageUnavailable});
    expect(imageFailed.retryable, isTrue);
    analyzer.fail = false;
    knowledge.fail = true;
    final searchFailed = await agent.execute(task);
    expect(searchFailed.analysis, same(analyzer.result));
    expect(searchFailed.sound, same(classifier.result));
    expect(searchFailed.cards, isNotEmpty);
    expect(searchFailed.retryable, isTrue);
  });

  test('photo analyzes actual bytes against all local card IDs', () async {
    final analyzer = ChatAnalyzer();
    final photo = chatPhoto();
    final knowledge = ChatKnowledge()
      ..cards = [
        chatCard(
          extraSafety: {SafetyLevel.venomous, SafetyLevel.protectedWildlife},
        ),
      ];
    final result =
        await OrchestratorAgent(
          analyzer: () => analyzer,
          knowledge: () => knowledge,
          soundClassifier: () => throw StateError('not requested'),
        ).execute(
          OrchestratorTask(
            userMessage: '',
            visualMedia: photo,
            languageTag: 'hi',
          ),
        );
    expect(analyzer.images.single.crop, same(photo.bytes));
    expect(analyzer.images.single.allowedCardIds, ['test-weevil']);
    expect(analyzer.images.single.languageTag, 'hi');
    expect(result.analysis, same(analyzer.result));
    expect(result.cards.single, same(knowledge.cards.single));
    expect(
      result.safetyLevels,
      containsAll([
        SafetyLevel.caution,
        SafetyLevel.venomous,
        SafetyLevel.protectedWildlife,
      ]),
    );
    expect(result.notices, isEmpty);
  });

  test(
    'audio uses the dedicated classifier without unrelated services',
    () async {
      final classifier = ChatSoundClassifier();
      final audio = chatAudio();
      final result = await OrchestratorAgent(
        soundClassifier: () => classifier,
        knowledge: () => throw StateError('not requested'),
        analyzer: () => throw StateError('not requested'),
      ).execute(OrchestratorTask(userMessage: '', audioMedia: audio));
      expect(classifier.paths, [audio.path]);
      expect(result.sound, same(classifier.result));
      expect(result.analysis, isNull);
      expect(result.generated, isNull);
      expect(result.notices, isEmpty);
    },
  );

  test('no matching local knowledge is reported honestly', () async {
    final result = await OrchestratorAgent().execute(
      const OrchestratorTask(userMessage: 'unknown topic'),
    );
    expect(result.cards, isEmpty);
    expect(result.notices, contains(ChatNotice.noKnowledge));
    expect(result.generated, isNull);
  });

  test('text-only request searches local knowledge', () async {
    final knowledge = ChatKnowledge();
    var soundCalls = 0;
    var imageCalls = 0;
    final result = await OrchestratorAgent(
      knowledge: () => knowledge,
      soundClassifier: () {
        soundCalls++;
        throw StateError('not requested');
      },
      analyzer: () {
        imageCalls++;
        throw StateError('not requested');
      },
    ).execute(const OrchestratorTask(userMessage: 'How do I store grain?'));
    expect(knowledge.queries, ['How do I store grain?']);
    expect(result.cards.single.id, 'test-weevil');
    expect(soundCalls, 0);
    expect(imageCalls, 0);
    expect(result.generated, isNull);
  });
}
