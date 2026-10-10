import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../advice/advice_card.dart';
import 'pest_analysis_sections.dart';
import 'pest_card_picker.dart';
import 'pest_copy.dart';
import 'pest_providers.dart';
import 'pest_session.dart';
import 'pest_widgets.dart';

/// Search words for a candidate when the AI analysis is unavailable.
String fallbackQuery(SignalCandidate? candidate) {
  final hint = candidate?.hint;
  if (hint != null && hint.trim().isNotEmpty) return hint.replaceAll('_', ' ');
  return switch (candidate?.kind) {
    SignalKind.darkSpecks => 'droppings specks',
    SignalKind.eyeshine => 'eyes shine at night',
    SignalKind.soundEvent => 'sound',
    _ => 'pest',
  };
}

/// On-device analysis of the confirmed tile, the safety banner, the
/// knowledge card and the follow-up actions.
class PestAnalysisScreen extends ConsumerStatefulWidget {
  const PestAnalysisScreen({super.key});

  @override
  ConsumerState<PestAnalysisScreen> createState() =>
      _PestAnalysisScreenState();
}

class _PestAnalysisScreenState extends ConsumerState<PestAnalysisScreen> {
  bool _explaining = false;
  int _explainRun = 0;
  bool _measuring = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(pestSessionProvider);
    if (session.tile != null && !session.analysisRan) {
      // After the first frame: the language tag reads an inherited widget.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_analyse(session));
      });
    }
  }

  Future<void> _analyse(PestSessionState session) async {
    final tile = session.tile!;
    final lang = adviceLanguageTag(context);
    final cards = await ref.read(knowledgeCardsProvider.future);
    PestAnalysis? analysis;
    try {
      analysis = await ref
          .read(pestAnalyzerProvider)
          .analyzeImage(
            PestImageRequest(
              crop: tile.image,
              context: session.still?.contextImage,
              candidate: session.candidate,
              allowedCardIds: [for (final c in cards) c.id],
              languageTag: lang,
            ),
          );
    } on Object {
      analysis = null;
    }
    KnowledgeCard? fallback;
    if (analysis == null) {
      try {
        final hits = await ref
            .read(knowledgeServiceProvider)
            .search(fallbackQuery(session.candidate), limit: 3);
        fallback = hits.firstOrNull?.card;
      } on Object {
        fallback = null;
      }
    } else if (analysis.cardId != null &&
        !cards.any((c) => c.id == analysis!.cardId)) {
      try {
        fallback = await ref.read(knowledgeServiceProvider).get(analysis.cardId!);
      } on Object {
        fallback = null;
      }
    }
    if (!mounted) return;
    ref
        .read(pestSessionProvider.notifier)
        .setAnalysis(analysis, fallbackCard: fallback, cards: cards);
  }

  Future<void> _measure(PestSessionState s) async {
    setState(() => _measuring = true);
    DistanceEstimate estimate;
    try {
      estimate = await ref
          .read(pestSenseEngineProvider)
          .measure(target: s.candidate?.box ?? s.tile?.box);
    } on Object {
      estimate = const DistanceEstimate(method: DistanceMethod.unavailable);
    }
    if (!mounted) return;
    ref.read(pestSessionProvider.notifier).setDistance(estimate);
    setState(() => _measuring = false);
  }

  Future<void> _discard() async {
    final router = GoRouter.of(context);
    await ref.read(pestSessionProvider.notifier).finish();
    router.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(pestSessionProvider);
    return Scaffold(
      appBar: KernelAppBar(title: l.pestAnalysisTitle),
      body: s.tile == null
          ? _NoSignal(onRestart: () => context.go(Routes.pestHub))
          : !s.analysisRan
          ? PageList(
              children: [
                const SizedBox(height: KernelSpace.xl),
                const Center(child: CircularProgressIndicator()),
                Text(
                  l.pestAnalysing,
                  key: const Key('pest-analysing'),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : PageList(children: _results(l, s)),
    );
  }

  List<Widget> _results(AppLocalizations l, PestSessionState s) {
    final analysis = s.analysis;
    final shownId = s.shownCardId;
    final card = s.cardById(shownId);
    final userPicked = s.userCardId != null;
    final level = moreSerious(
      analysis?.safety ?? card?.safety ?? SafetyLevel.low,
      card?.safety,
    );
    final capability = ref.watch(distanceCapabilityProvider).value;
    final canMeasure =
        capability != null && (capability.arcoreDepth || capability.focusDistance);
    return [
      if (s.tile case final tile?)
        ClipRRect(
          borderRadius: BorderRadius.circular(KernelRadii.md),
          child: SizedBox(
            height: 160,
            child: Image.memory(
              tile.image,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      PestSafetyBanner(level: level),
      if (analysis != null)
        PestAiAnalysisCard(analysis: analysis)
      else
        const PestAnalysisUnavailable(),
      if (card != null)
        KnowledgeCardView(card: card, userPicked: userPicked)
      else
        QuietNote(l.pestNoCardFound, key: const Key('pest-no-card')),
      if (analysis != null && card != null) ...[
        if (_explaining)
          AdviceStreamCard(
            key: ValueKey('pest-explain-$_explainRun'),
            title: l.pestExplainTitle,
            request: () => ref
                .read(pestAnalyzerProvider)
                .guide(
                  PestGuideInput(
                    analysis: analysis,
                    cards: [card],
                    languageTag: adviceLanguageTag(context),
                  ),
                ),
            fallback: QuietNote(
              l.pestExplainFallback,
              key: const Key('pest-explain-fallback'),
            ),
          )
        else
          OutlinedButton.icon(
            key: const Key('pest-explain'),
            onPressed: () => setState(() {
              _explaining = true;
              _explainRun++;
            }),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(l.pestExplain),
          ),
      ],
      ActionWrap(
        children: [
          OutlinedButton.icon(
            key: const Key('pest-pick-card'),
            onPressed: s.cards.isEmpty
                ? null
                : () => showPestCardPicker(
                    context,
                    cards: s.cards,
                    selectedId: s.userCardId,
                    onPicked: (id) =>
                        ref.read(pestSessionProvider.notifier).pickCard(id),
                  ),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(l.pestPickCard),
          ),
          if (canMeasure)
            OutlinedButton.icon(
              key: const Key('pest-measure'),
              onPressed: _measuring ? null : () => _measure(s),
              icon: const Icon(Icons.straighten_rounded),
              label: Text(_measuring ? l.pestMeasuring : l.pestMeasure),
            ),
        ],
      ),
      if (s.distance case final distance?) PestDistanceNote(estimate: distance),
      FilledButton.icon(
        key: const Key('pest-save'),
        onPressed: () => context.push(Routes.pestSave),
        icon: const Icon(Icons.bookmark_add_rounded),
        label: Text(l.pestSave),
      ),
      TextButton.icon(
        key: const Key('pest-discard'),
        onPressed: _discard,
        icon: const Icon(Icons.delete_outline_rounded),
        label: Text(l.pestDiscard),
      ),
    ];
  }
}

class _NoSignal extends StatelessWidget {
  const _NoSignal({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PageList(
      children: [
        EmptyState(
          key: const Key('pest-no-signal'),
          message: l.pestNoSignal,
          actionLabel: l.pestStartAgain,
          actionIcon: Icons.replay_rounded,
          onAction: onRestart,
        ),
      ],
    );
  }
}
