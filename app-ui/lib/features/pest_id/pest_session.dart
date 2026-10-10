import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/providers.dart';

/// One Pest ID flow: a user-confirmed camera tile or sound clip, the
/// on-device AI analysis of it, the user's own card pick and an optional
/// distance. Held in memory only; [PestSession.finish] drops it together
/// with every buffered still and clip in the sense engine.
@immutable
class PestSessionState {
  const PestSessionState({
    this.source = SignalSource.camera,
    this.still,
    this.tile,
    this.candidate,
    this.analysisRan = false,
    this.analysis,
    this.fallbackCard,
    this.cards = const [],
    this.userCardId,
    this.distance,
    this.soundLabels = const [],
    this.clip,
    this.sound,
    this.soundCards = const [],
  });

  final SignalSource source;

  /// Camera path: the captured still and the tile the user confirmed.
  final CapturedStill? still;
  final ImageTile? tile;

  /// The confirmed signal (camera box or sound event).
  final SignalCandidate? candidate;

  /// True once analyzeImage has been called for [tile].
  final bool analysisRan;

  /// AI analysis; null when analysis was unavailable.
  final PestAnalysis? analysis;

  /// Top knowledge-search card shown when [analysis] is null.
  final KnowledgeCard? fallbackCard;

  /// Every knowledge card (the constrained label set).
  final List<KnowledgeCard> cards;

  /// Card the user picked to correct the AI label.
  final String? userCardId;
  final DistanceEstimate? distance;

  /// Microphone path: sound-classifier labels, the WAV clip (in memory
  /// only), the experimental description and the matching cards.
  final List<ScoredLabel> soundLabels;
  final Uint8List? clip;
  final SoundAnalysis? sound;
  final List<KnowledgeCard> soundCards;

  bool get hasSignal => tile != null || candidate != null;

  /// Card id the UI shows: the user's pick wins over the AI label.
  String? get shownCardId =>
      userCardId ?? analysis?.cardId ?? fallbackCard?.id;

  KnowledgeCard? cardById(String? id) {
    if (id == null) return null;
    for (final card in [...cards, ...soundCards, ?fallbackCard]) {
      if (card.id == id) return card;
    }
    return null;
  }
}

class PestSession extends Notifier<PestSessionState> {
  @override
  PestSessionState build() => const PestSessionState();

  /// The user confirmed [tile] of [still] (userValidated).
  void confirmTile(
    CapturedStill still,
    ImageTile tile,
    SignalCandidate? candidate,
  ) => state = PestSessionState(
    source: SignalSource.camera,
    still: still,
    tile: tile,
    candidate: candidate,
  );

  void setAnalysis(
    PestAnalysis? analysis, {
    KnowledgeCard? fallbackCard,
    required List<KnowledgeCard> cards,
  }) {
    final s = state;
    state = PestSessionState(
      source: s.source,
      still: s.still,
      tile: s.tile,
      candidate: s.candidate,
      analysisRan: true,
      analysis: analysis,
      fallbackCard: fallbackCard,
      cards: cards,
      userCardId: s.userCardId,
      distance: s.distance,
    );
  }

  /// The user confirmed a sound event (userValidated).
  void confirmSound(
    SignalCandidate candidate,
    List<ScoredLabel> labels,
    Uint8List? clip,
  ) => state = PestSessionState(
    source: SignalSource.microphone,
    candidate: candidate,
    soundLabels: labels,
    clip: clip,
  );

  void setSound(
    SoundAnalysis? sound, {
    required List<KnowledgeCard> soundCards,
    required List<KnowledgeCard> cards,
  }) {
    final s = state;
    state = PestSessionState(
      source: s.source,
      candidate: s.candidate,
      soundLabels: s.soundLabels,
      clip: s.clip,
      analysisRan: true,
      sound: sound,
      soundCards: soundCards,
      cards: cards,
      userCardId: s.userCardId,
    );
  }

  void pickCard(String? cardId) => state = _copy(userCardId: () => cardId);

  void setDistance(DistanceEstimate distance) =>
      state = _copy(distance: () => distance);

  PestSessionState _copy({
    String? Function()? userCardId,
    DistanceEstimate? Function()? distance,
  }) {
    final s = state;
    return PestSessionState(
      source: s.source,
      still: s.still,
      tile: s.tile,
      candidate: s.candidate,
      analysisRan: s.analysisRan,
      analysis: s.analysis,
      fallbackCard: s.fallbackCard,
      cards: s.cards,
      userCardId: userCardId == null ? s.userCardId : userCardId(),
      distance: distance == null ? s.distance : distance(),
      soundLabels: s.soundLabels,
      clip: s.clip,
      sound: s.sound,
      soundCards: s.soundCards,
    );
  }

  /// Ends the flow: drops buffered media in the engine and forgets the
  /// session. Called after saving or cancelling.
  Future<void> finish() async {
    state = const PestSessionState();
    await discardPestMedia(ref.read(pestSenseEngineProvider));
  }
}

/// Never lets a failing engine block leaving the flow.
Future<void> discardPestMedia(PestSenseEngine engine) async {
  try {
    await engine.discardMedia();
  } on Object catch (error) {
    debugPrint('Kernel: discarding Pest ID media failed: $error');
  }
}

final pestSessionProvider = NotifierProvider<PestSession, PestSessionState>(
  PestSession.new,
  name: 'pestSessionProvider',
);
