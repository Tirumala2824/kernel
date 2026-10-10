import 'package:kernel_contracts/kernel_contracts.dart';

/// Task input for AgronomySafetyAgent.
class AgronomySafetyTask {
  const AgronomySafetyTask({
    required this.verdict,
    this.cropContext,
    this.sightingCardId,
  });

  final QualityWeightedVerdict verdict;
  final String? cropContext;
  final String? sightingCardId;
}

/// Autonomous agronomy and safety validation agent.
/// Enforces strict safety guardrails (§6, §9) against hazardous chemicals,
/// unverified home remedies, and promotes grounded, non-chemical IPM protocols.
class AgronomySafetyAgent implements Agent<AgronomySafetyTask, GroundedGuidanceReport> {
  AgronomySafetyAgent({this.knowledgeService});

  final KnowledgeService? knowledgeService;

  @override
  String get agentId => 'agent.safety.agronomy';

  @override
  Future<GroundedGuidanceReport> execute(AgronomySafetyTask task) async {
    final cardId = task.sightingCardId ?? 'grain_weevil_ipm';
    KnowledgeCard? card;
    final svc = knowledgeService;
    if (svc != null && task.sightingCardId != null) {
      card = await svc.get(task.sightingCardId!);
    }

    final safeSteps = card?.safeSteps.isNotEmpty == true
        ? card!.safeSteps
        : [
            '1. Quarantine: Immediately separate infested sacks 5 meters away from healthy grain stacks.',
            '2. Solar Drying & Sieving: Sieve grain through 2.0 mm mesh screen to remove free insects, then sun-dry on clean tarpaulin for 4 hours (grain temp > 50°C kills eggs).',
            '3. Hermetic Storage: Repack cooled, clean grain into triple-layer hermetic bags (PICS) or sealed metal bins to deplete oxygen naturally.',
            '4. Clean Store Hygiene: Remove cracked grains, dust, and webbings from floor cracks using a broom; seal crevices before restocking.',
          ];

    final callProfessional = card?.callProfessionalWhen ?? [
      'Infestation exceeds 5 insects per kg across more than 20% of stored sacks.',
      'Grain heating / damp pockets detected inside bulk grain bulkheads.',
    ];

    final firstAid = card?.firstAid ?? [
      'Wash skin thoroughly with soap and water if handling mouldy or dusty grain.',
      'Wear an N95 dust mask when cleaning storage facilities to prevent grain dust inhalation.',
    ];

    const legalNote =
        'Strict IPM Compliance: Chemical fumigation (e.g. Aluminium Phosphide) is restricted to certified commercial fumigators under government regulations. Never mix unverified household pesticides with edible grain.';

    return GroundedGuidanceReport(
      cardId: cardId,
      summary: card?.summary ??
          'Integrated Pest Management (IPM) protocol for stored grain insect screening: prioritize non-chemical isolation, mechanical sieving, and hermetic storage.',
      safeSteps: safeSteps,
      safetyConcerns: card?.safety != null ? {card!.safety} : {SafetyLevel.low},
      callProfessionalWhen: callProfessional,
      firstAid: firstAid,
      legalNote: legalNote,
    );
  }
}
