// Migrated wrapper regressions: preserve results, not heuristic evidence.
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/agents/agents.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/chat_fixtures.dart';

void main() {
  test('transient native sound failures allow one explicit retry', () async {
    for (final reason in [
      'memory_unavailable',
      'inference_failed',
      'native_failure',
    ]) {
      final classifier = ChatSoundClassifier()
        ..result = InsectSoundResult(
          status: InsectSoundStatus.unavailable,
          reasons: [reason],
        );
      final agent = OrchestratorAgent(soundClassifier: () => classifier);
      final task = OrchestratorTask(userMessage: '', audioMedia: chatAudio());
      final failed = await agent.execute(task);
      expect(failed.retryable, isTrue, reason: reason);
      expect(failed.sound!.topLabels, isEmpty);
      classifier.result = ChatSoundClassifier().result;
      final recovered = await agent.execute(task);
      expect(recovered.sound!.status, InsectSoundStatus.evaluated);
      expect(recovered.retryable, isFalse);
    }
  });

  test(
    'native identification level and scores are never promoted or fused',
    () async {
      for (final level in InsectIdentificationLevel.values) {
        final native = InsectSoundResult(
          status: InsectSoundStatus.evaluated,
          level: level,
          label: level == InsectIdentificationLevel.unknown
              ? null
              : 'Native label',
          topLabels: [
            ScoredLabel(
              label: level == InsectIdentificationLevel.species
                  ? 'Native label'
                  : 'Native candidate',
              score: level == InsectIdentificationLevel.species ? 0.7 : 0.42,
            ),
          ],
          reasons: const ['closed-set-match'],
          modelVersion: 'test-native',
          modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
          sampleRate: 44100,
          durationMs: 2000,
        );
        final classifier = ChatSoundClassifier()..result = native;
        final result = await OrchestratorAgent(
          soundClassifier: () => classifier,
        ).execute(OrchestratorTask(userMessage: '', audioMedia: chatAudio()));
        expect(result.sound, same(native));
        expect(result.sound!.level, level);
        expect(result.sound!.topLabels, same(native.topLabels));

        expect(result.analysis, isNull);
        expect(result.cards, isEmpty);
        expect(result.generated, isNull);
      }
    },
  );

  test(
    'unavailable or rejected recordings have no invented identification',
    () async {
      for (final status in [
        InsectSoundStatus.unavailable,
        InsectSoundStatus.rejected,
      ]) {
        final native = InsectSoundResult(
          status: status,
          reasons: const ['native-reason'],
        );
        final result = await OrchestratorAgent(
          soundClassifier: () => ChatSoundClassifier()..result = native,
        ).execute(OrchestratorTask(userMessage: '', audioMedia: chatAudio()));
        expect(result.sound, same(native));
        expect(result.sound!.label, isNull);
        expect(result.sound!.topLabels, isEmpty);
        expect(result.sound!.level, InsectIdentificationLevel.unknown);

        expect(result.retryable, isFalse);
      }
    },
  );

  test(
    'missing photo model produces no inferred quality or fallback species',
    () async {
      final result = await OrchestratorAgent(
        analyzer: () => ChatAnalyzer()..result = null,
        knowledge: () => ChatKnowledge(),
      ).execute(OrchestratorTask(userMessage: '', visualMedia: chatPhoto()));
      expect(result.analysis, isNull);
      expect(result.cards, isEmpty);
      expect(result.generated, isNull);
      expect(result.notices, {ChatNotice.imageUnavailable});
      expect(result.retryable, isFalse);
    },
  );

  test(
    'guidance is the actual curated card, not generic seeded IPM copy',
    () async {
      final card = chatCard(extraSafety: {SafetyLevel.protectedWildlife});
      final result = await OrchestratorAgent(
        knowledge: () => ChatKnowledge()..cards = [card],
      ).execute(const OrchestratorTask(userMessage: 'storage'));
      expect(result.cards.single, same(card));
      expect(result.cards.single.safeSteps, same(card.safeSteps));
      expect(result.cards.single.sources, same(card.sources));
      expect(result.safetyLevels, {
        SafetyLevel.caution,
        SafetyLevel.protectedWildlife,
      });
      expect(result.generated, isNull);
    },
  );

  test('different native audio and photo results stay separate', () async {
    final sound = ChatSoundClassifier();
    final analyzer = ChatAnalyzer();
    final result =
        await OrchestratorAgent(
          soundClassifier: () => sound,
          analyzer: () => analyzer,
          knowledge: () => ChatKnowledge(),
        ).execute(
          OrchestratorTask(
            userMessage: '',
            audioMedia: chatAudio(),
            visualMedia: chatPhoto(),
          ),
        );
    expect(result.sound, same(sound.result));
    expect(result.analysis, same(analyzer.result));
    expect(result.sound!.label, isNot(result.analysis!.commonName));
  });

  test('general chat without matching knowledge fabricates nothing', () async {
    final analyzer = ChatAnalyzer();
    final result = await OrchestratorAgent(
      knowledge: () => ChatKnowledge()..cards = [],
      analyzer: () => analyzer,
    ).execute(const OrchestratorTask(userMessage: 'tell me a joke'));
    expect(result.cards, isEmpty);
    expect(result.analysis, isNull);
    expect(result.sound, isNull);

    expect(result.generated, isNull);
    expect(result.safetyLevels, isEmpty);
    expect(analyzer.guides, isEmpty);
    expect(result.notices, {ChatNotice.noKnowledge});
  });

  test(
    'unknown native photo ID never becomes an invented card or guide',
    () async {
      final analyzer = ChatAnalyzer()
        ..result = chatAnalysis(cardId: 'not-in-library');
      final result =
          await OrchestratorAgent(
            analyzer: () => analyzer,
            knowledge: () => ChatKnowledge()..searchCards = [],
          ).execute(
            OrchestratorTask(
              userMessage: 'What next?',
              visualMedia: chatPhoto(),
            ),
          );
      expect(result.analysis, same(analyzer.result));
      expect(result.cards, isEmpty);
      expect(result.generated, isNull);
      expect(analyzer.guides, isEmpty);
    },
  );
}
