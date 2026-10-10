import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/status_chip.dart';

/// "Search models & pest info": on-phone semantic search over the model
/// catalog (ModelSearch) and the curated pest knowledge cards
/// (KnowledgeService), each hit shown with its similarity score.
class HubSearchPanel extends ConsumerStatefulWidget {
  const HubSearchPanel({super.key});

  @override
  ConsumerState<HubSearchPanel> createState() => _HubSearchPanelState();
}

typedef _Outcome<T> = ({List<T> hits, String? error});

class _HubSearchPanelState extends ConsumerState<HubSearchPanel> {
  final _controller = TextEditingController();
  bool _searching = false;
  String? _query;
  _Outcome<ModelSearchHit>? _models;
  _Outcome<KnowledgeHit>? _cards;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<_Outcome<T>> _run<T>(Future<List<T>> Function() search) async {
    try {
      return (hits: await search(), error: null);
    } on Object catch (e) {
      return (hits: <T>[], error: '$e');
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    final (models, cards) = await (
      _run<ModelSearchHit>(() => ref.read(modelSearchProvider).search(query)),
      _run<KnowledgeHit>(() => ref.read(knowledgeServiceProvider).search(query)),
    ).wait;
    if (!mounted) return;
    setState(() {
      _searching = false;
      _query = query;
      _models = models;
      _cards = cards;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final models = _models;
    final cards = _cards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('hub-search-field'),
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            labelText: l.hubSearchHint,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: KernelSpace.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            key: const Key('hub-search-go'),
            onPressed: _searching ? null : _search,
            icon: const Icon(Icons.search_rounded),
            label: Text(l.hubSearchAction),
          ),
        ),
        const SizedBox(height: KernelSpace.sm),
        QuietNote(l.hubSearchNote, icon: Icons.phonelink_lock_rounded),
        if (_searching)
          const Padding(
            padding: EdgeInsets.all(KernelSpace.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!_searching && _query != null && models != null && cards != null)
          ...[
            const SizedBox(height: KernelSpace.md),
            _ResultGroup<ModelSearchHit>(
              key: const Key('hub-search-models'),
              title: l.hubSearchModels,
              outcome: models,
              builder: (hit) => _HitTile(
                title: hit.title,
                body: hit.snippet ?? hit.entry?.description,
                score: hit.score,
              ),
            ),
            const SizedBox(height: KernelSpace.md),
            _ResultGroup<KnowledgeHit>(
              key: const Key('hub-search-cards'),
              title: l.hubSearchPestInfo,
              outcome: cards,
              builder: (hit) => _HitTile(
                title: _cardName(context, hit.card),
                body: hit.card.summary,
                score: hit.score,
                needsReview: hit.card.reviewStatus != 'reviewed',
              ),
            ),
          ],
      ],
    );
  }

  String _cardName(BuildContext context, KnowledgeCard card) {
    final lang = Localizations.localeOf(context).languageCode;
    return card.names[lang] ?? card.names['en'] ?? card.id;
  }
}

class _ResultGroup<T> extends StatelessWidget {
  const _ResultGroup({
    super.key,
    required this.title,
    required this.outcome,
    required this.builder,
  });

  final String title;
  final _Outcome<T> outcome;
  final Widget Function(T hit) builder;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: KernelColors.forest),
        ),
        const SizedBox(height: KernelSpace.xs),
        if (outcome.error != null)
          ErrorNote(l.hubSearchFailed(outcome.error!))
        else if (outcome.hits.isEmpty)
          QuietNote(l.hubSearchNoResults, icon: Icons.search_off_rounded)
        else
          for (final hit in outcome.hits) builder(hit),
      ],
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({
    required this.title,
    required this.score,
    this.body,
    this.needsReview = false,
  });

  final String title;
  final String? body;
  final double score;
  final bool needsReview;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final text = body?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: KernelSpace.sm),
      padding: const EdgeInsets.all(KernelSpace.md),
      decoration: BoxDecoration(
        color: KernelColors.paper,
        borderRadius: BorderRadius.circular(KernelRadii.md),
        border: Border.all(color: KernelColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall),
          if (text != null && text.isNotEmpty) ...[
            const SizedBox(height: KernelSpace.xxs),
            Text(text, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: KernelSpace.xs),
          Wrap(
            spacing: KernelSpace.sm,
            runSpacing: KernelSpace.xs,
            children: [
              StatusChip(
                label: l.hubSearchScore(score.toStringAsFixed(2)),
                icon: Icons.straighten_rounded,
              ),
              if (needsReview)
                StatusChip(
                  label: l.hubNeedsReview,
                  tone: StatusTone.attention,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
