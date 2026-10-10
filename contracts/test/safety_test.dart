import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:test/test.dart';

KnowledgeCard _card(
  String id,
  SafetyLevel safety, {
  Set<SafetyLevel> extra = const {},
}) => KnowledgeCard(
  id: id,
  names: {'en': id},
  group: PestGroup.reptile,
  safety: safety,
  extraSafety: extra,
  summary: '',
  signs: const [],
  lookAlikes: const [],
  healthRisks: const [],
  safeSteps: const [],
  callProfessionalWhen: const [],
  firstAid: const [],
  legal: null,
  sources: const ['test'],
  reviewStatus: 'needs-expert-review',
);

void main() {
  group('safetyConcerns', () {
    test('keeps the AI card level when the user picks a milder card', () {
      final concerns = safetyConcerns(
        aiLevel: SafetyLevel.caution,
        cards: [
          _card('monitor_lizard', SafetyLevel.protectedWildlife),
          _card('skink', SafetyLevel.caution),
        ],
      );
      expect(concerns, {SafetyLevel.caution, SafetyLevel.protectedWildlife});
      expect(mostSerious(concerns), SafetyLevel.protectedWildlife);
    });

    test('includes extra levels so a snake is venomous and protected', () {
      final concerns = safetyConcerns(
        cards: [
          _card(
            'snake',
            SafetyLevel.venomous,
            extra: {SafetyLevel.protectedWildlife},
          ),
        ],
      );
      expect(concerns, {SafetyLevel.venomous, SafetyLevel.protectedWildlife});
    });

    test('drops low when anything else applies, keeps it alone', () {
      expect(
        safetyConcerns(
          aiLevel: SafetyLevel.low,
          cards: [_card('bat', SafetyLevel.medicalRisk)],
        ),
        {SafetyLevel.medicalRisk},
      );
      expect(safetyConcerns(aiLevel: SafetyLevel.low), {SafetyLevel.low});
    });

    test('is empty when nothing is known', () {
      expect(safetyConcerns(cards: [null]), isEmpty);
      expect(mostSerious(const []), isNull);
    });
  });

  group('SensorStatus.notEvaluated', () {
    SensorStatus status(
      Set<SensorHealth> health, {
      SensorLinkState link = SensorLinkState.authenticated,
    }) => SensorStatus(nodeId: 'n1', linkState: link, health: health);

    test('ok is evaluated; faults, jams, gaps and errors are not', () {
      expect(status({SensorHealth.ok}).notEvaluated, isFalse);
      expect(
        status({SensorHealth.ok, SensorHealth.lowBattery}).notEvaluated,
        isFalse,
      );
      for (final h in notEvaluatedHealth) {
        expect(status({h}).notEvaluated, isTrue, reason: '$h');
      }
      expect(status(const {}).notEvaluated, isTrue);
      expect(
        status({SensorHealth.ok}, link: SensorLinkState.error).notEvaluated,
        isTrue,
      );
    });
  });
}
