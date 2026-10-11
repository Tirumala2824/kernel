import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;

import 'media_picker_service.dart';

enum ChatNotice {
  noKnowledge,
  audioUnavailable,
  imageUnavailable,
  unsupportedMedia,
  requestFailed,
}

class OrchestratorTask {
  const OrchestratorTask({
    required this.userMessage,
    this.audioMedia,
    this.visualMedia,
    this.contextAnalysis,
    this.languageTag = 'en',
  });
  final String userMessage;
  final PickedMedia? audioMedia;
  final PickedMedia? visualMedia;
  final PestAnalysis? contextAnalysis;
  final String languageTag;
}

class OrchestratorResponse {
  const OrchestratorResponse({
    this.sound,
    this.analysis,
    this.cards = const [],
    this.generated,
    this.notices = const {},
    this.safetyLevels = const {},
    this.retryable = false,
  });

  final InsectSoundResult? sound;
  final PestAnalysis? analysis;
  final List<KnowledgeCard> cards;
  final AdviceText? generated;
  final Set<ChatNotice> notices;
  final Set<SafetyLevel> safetyLevels;
  final bool retryable;
}

/// Input-driven local service selection; no synthesized evidence.
class OrchestratorAgent
    implements Agent<OrchestratorTask, OrchestratorResponse> {
  OrchestratorAgent({
    this.soundClassifier,
    this.analyzer,
    this.knowledge,
    this.operationBudget = const Duration(seconds: 50),
    this.knowledgeBudget = const Duration(seconds: 8),
    this.guideBudget = const Duration(seconds: 25),
  });
  final InsectSoundClassifier Function()? soundClassifier;
  final PestAnalyzer Function()? analyzer;
  final KnowledgeService Function()? knowledge;
  final Duration operationBudget;
  final Duration knowledgeBudget;
  final Duration guideBudget;

  // Keep only real observed cards with their analysis identity. Expando keys
  // are weak: clearing the session releases context without a history store.
  final _contextCards = Expando<List<KnowledgeCard>>();
  @override
  String get agentId => 'agent.orchestrator.multimodal';
  @override
  Future<OrchestratorResponse> execute(OrchestratorTask task) async {
    final notices = <ChatNotice>{};
    var retryable = false;
    Future<T?> attempt<T>(
      Future<T?> Function() operation,
      ChatNotice failure, {
      Duration? budget,
    }) async {
      try {
        return await operation().timeout(budget ?? operationBudget);
      } on Object catch (error) {
        notices.add(failure);
        // Riverpod wraps unbound optional providers; they are not transient.
        var cause = error;
        while (cause is ProviderException) {
          cause = cause.exception;
        }
        retryable = retryable || cause is! UnimplementedError;
        return null;
      }
    }

    final query = task.userMessage.trim();
    final audio = task.audioMedia;
    final visual = task.visualMedia;
    final priorAnalysis = audio == null && visual == null
        ? task.contextAnalysis
        : null;
    final validAudio =
        audio != null &&
        audio.isAudio &&
        audio.path.trim().isNotEmpty &&
        RegExp(r'\.(wav|wave)$', caseSensitive: false).hasMatch(audio.fileName);
    final validVisual =
        visual != null && visual.isImage && visual.bytes.isNotEmpty;
    if ((audio != null && !validAudio) || (visual != null && !validVisual)) {
      notices.add(ChatNotice.unsupportedMedia);
    }
    final service =
        knowledge == null ||
            (query.isEmpty && !validVisual && priorAnalysis == null)
        ? null
        : await attempt<KnowledgeService>(
            () async => knowledge!(),
            ChatNotice.noKnowledge,
            budget: knowledgeBudget,
          );
    final hits = query.isEmpty || service == null
        ? const <KnowledgeHit>[]
        : await attempt<List<KnowledgeHit>>(
            () => service.search(query, limit: 3),
            ChatNotice.noKnowledge,
            budget: knowledgeBudget,
          );
    var sound = !validAudio || soundClassifier == null
        ? null
        : await attempt<InsectSoundResult>(
            () => soundClassifier!().classifyWavFile(audio.path),
            ChatNotice.audioUnavailable,
          );
    if (sound != null && sound.invariantViolations().isNotEmpty) {
      sound = null;
      notices.add(ChatNotice.audioUnavailable);
      retryable = true;
    }
    // Native APIs return availability as data, not exceptions. Only transient
    // failures can reuse the same input; unsupported format/platform or corrupt
    // assets need a different file/setup and must not offer a futile retry.
    const transientSoundReasons = {
      'memory_unavailable', 'inference_failed', 'native_failure',
    };
    if (sound?.status == InsectSoundStatus.unavailable &&
        sound!.reasons.isNotEmpty &&
        sound.reasons.every(transientSoundReasons.contains)) {
      retryable = true;
    }
    final observedCards = priorAnalysis == null
        ? const <KnowledgeCard>[]
        : _contextCards[priorAnalysis] ?? const <KnowledgeCard>[];
    final cards = <String, KnowledgeCard>{
      for (final hit in hits ?? const <KnowledgeHit>[]) hit.card.id: hit.card,
    };
    for (final observed in observedCards) {
      final latest = cards[observed.id];
      cards[observed.id] = latest == null
          ? observed
          : _retainObservedSafety(latest, observed);
    }
    PestAnalysis? analysis;
    if (validVisual && analyzer != null && service != null) {
      final availableCards = await attempt<List<KnowledgeCard>>(
        () => service.all(),
        ChatNotice.imageUnavailable,
        budget: knowledgeBudget,
      );
      if (availableCards != null && availableCards.isNotEmpty) {
        analysis = await attempt<PestAnalysis>(
          () => analyzer!().analyzeImage(
            PestImageRequest(
              crop: visual.bytes,
              allowedCardIds: [for (final card in availableCards) card.id],
              languageTag: task.languageTag,
            ),
          ),
          ChatNotice.imageUnavailable,
        );
        for (final card in availableCards) {
          if (card.id == analysis?.cardId) cards[card.id] = card;
        }
      }
    }
    // New attachments must not inherit a diagnosis from an older image.
    final guideAnalysis = analysis ?? priorAnalysis;
    final guideCardId = guideAnalysis?.cardId;
    if (guideCardId != null &&
        service != null &&
        !cards.containsKey(guideCardId)) {
      final card = await attempt<KnowledgeCard>(
        () => service.get(guideCardId),
        ChatNotice.noKnowledge,
        budget: knowledgeBudget,
      );
      if (card != null && card.id == guideCardId) cards[card.id] = card;
    }
    if (guideAnalysis != null) {
      _contextCards[guideAnalysis] = List.unmodifiable(cards.values);
    }
    AdviceText? generated;
    if (query.isNotEmpty &&
        guideAnalysis != null &&
        cards.containsKey(guideCardId) &&
        analyzer != null) {
      try {
        generated = await analyzer!()
            .guide(
              PestGuideInput(
                analysis: guideAnalysis,
                cards: List.unmodifiable(cards.values),
                question: query,
                languageTag: task.languageTag,
              ),
            )
            .where((part) => part.complete && part.text.trim().isNotEmpty)
            .timeout(guideBudget)
            .first;
      } on Object {
        // Optional generation must never erase actual cards or safety.
      }
    }
    if (validAudio && sound == null) notices.add(ChatNotice.audioUnavailable);
    if (validVisual && analysis == null) {
      notices.add(ChatNotice.imageUnavailable);
    }
    if (cards.isNotEmpty) notices.remove(ChatNotice.noKnowledge);
    if (cards.isEmpty &&
        (query.isNotEmpty ||
            (notices.isEmpty && sound == null && analysis == null))) {
      notices.add(ChatNotice.noKnowledge);
    }
    if (retryable && sound == null && analysis == null && cards.isEmpty) {
      notices.add(ChatNotice.requestFailed);
    }
    return OrchestratorResponse(
      sound: sound,
      analysis: analysis,
      generated: generated,
      cards: List.unmodifiable(cards.values),
      safetyLevels: safetyConcerns(
        aiLevel: guideAnalysis?.safety,
        cards: cards.values,
      ),
      notices: Set.unmodifiable(notices),
      retryable: retryable,
    );
  }
}

// Keep current content, but pass all observed concerns to both guide and UI.
KnowledgeCard _retainObservedSafety(
  KnowledgeCard latest,
  KnowledgeCard observed,
) {
  final retainedSafety = safetyConcerns(cards: [observed, latest])
      .difference(safetyConcerns(cards: [latest]));
  if (retainedSafety.isEmpty) return latest;
  return KnowledgeCard(
    id: latest.id,
    names: latest.names,
    group: latest.group,
    safety: latest.safety,
    extraSafety: Set.unmodifiable({...latest.extraSafety, ...retainedSafety}),
    summary: latest.summary,
    signs: latest.signs,
    lookAlikes: latest.lookAlikes,
    healthRisks: latest.healthRisks,
    safeSteps: latest.safeSteps,
    trapSteps: latest.trapSteps,
    callProfessionalWhen: latest.callProfessionalWhen,
    firstAid: latest.firstAid,
    legal: latest.legal,
    sources: latest.sources,
    reviewStatus: latest.reviewStatus,
  );
}
