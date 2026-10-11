import 'package:kernel_contracts/kernel_contracts.dart';

/// Task input for the local knowledge and safety agent.
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

/// Provides safety guidance only from the reviewed, bundled knowledge cards.
/// If the local corpus has no applicable card, it returns an explicit
/// unavailable state rather than inventing treatment thresholds or legal claims.
class AgronomySafetyAgent
    implements Agent<AgronomySafetyTask, GroundedGuidanceReport> {
  AgronomySafetyAgent({this.knowledgeService});

  final KnowledgeService? knowledgeService;

  @override
  String get agentId => 'agent.safety.local_knowledge';

  @override
  Future<GroundedGuidanceReport> execute(AgronomySafetyTask task) async {
    final cardId = task.sightingCardId;
    final service = knowledgeService;
    if (cardId == null || service == null) return _unavailable;
    final card = await service.get(cardId);
    return card == null ? _unavailable : _fromCard(card);
  }

  /// Answers a text-only chat turn with the best matching local knowledge
  /// card. It does not call a network model or fabricate unsupported facts.
  Future<GroundedGuidanceReport> answerQuestion(String question) async {
    final service = knowledgeService;
    if (service == null || question.trim().isEmpty) return _unavailable;
    final hits = await service.search(question.trim(), limit: 1);
    if (hits.isEmpty) return _unavailable;
    return _fromCard(hits.first.card);
  }

  GroundedGuidanceReport _fromCard(KnowledgeCard card) =>
      GroundedGuidanceReport(
        cardId: card.id,
        summary: card.summary,
        safeSteps: card.safeSteps,
        safetyConcerns: safetyConcerns(cards: [card]),
        callProfessionalWhen: card.callProfessionalWhen,
        firstAid: card.firstAid,
        legalNote: card.legal,
        sources: card.sources,
      );

  static const _unavailable = GroundedGuidanceReport(
    cardId: 'unavailable',
    summary: 'No matching reviewed local knowledge card is available. Do not rely on an AI or sensor result as a confirmed finding; consult a qualified local expert for advice.',
    safeSteps: [],
    safetyConcerns: {},
  );
}
