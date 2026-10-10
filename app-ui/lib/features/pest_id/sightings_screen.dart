import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/status_chip.dart';
import 'pest_copy.dart';
import 'pest_providers.dart';

/// Title for a sighting: the user's card pick, else the AI label, else
/// the top sound label. The UI marks which one it is.
String sightingTitle(
  AppLocalizations l,
  Sighting s,
  List<KnowledgeCard> cards,
  String languageTag,
) {
  final pick = s.userCardId;
  if (pick != null) {
    for (final card in cards) {
      if (card.id == pick) return cardName(card, languageTag);
    }
  }
  final ai = s.analysis?.commonName.trim();
  if (ai != null && ai.isNotEmpty) return ai;
  final sound = s.sound?.preFilter.firstOrNull?.label.trim();
  if (sound != null && sound.isNotEmpty) return sound;
  return l.pestSightingUnnamed;
}

class SightingsScreen extends ConsumerWidget {
  const SightingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final role = ref.watch(activeRoleProvider).value;
    final sightings = ref.watch(recentSightingsProvider(role));
    final cards = ref.watch(knowledgeCardsProvider).value ?? const [];
    final places = {
      for (final p in ref.watch(allLocationsProvider).value ?? const <Location>[])
        p.id: p.name,
    };
    return Scaffold(
      appBar: KernelAppBar(
        title: l.pestSightingsTitle,
        actions: [
          IconButton(
            key: const Key('sightings-map'),
            tooltip: l.mapTitle,
            onPressed: () => context.push(Routes.sightingsMap()),
            icon: const Icon(Icons.map_rounded),
          ),
        ],
      ),
      body: PageList(
        children: [
          ScreenHeader(
            title: l.pestSightingsTitle,
            subtitle: l.pestSightingsSubtitle,
          ),
          AsyncView<List<Sighting>>(
            value: sightings,
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  key: const Key('sightings-empty'),
                  message: l.pestSightingsEmpty,
                  detail: l.pestSightingsEmptyDetail,
                  actionLabel: l.pestHeroAction,
                  actionIcon: Icons.pest_control_rounded,
                  onAction: () => context.push(Routes.pestHub),
                );
              }
              return Column(
                children: [
                  for (final s in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: KernelSpace.md),
                      child: SightingTile(
                        sighting: s,
                        cards: cards,
                        placeName: places[s.locationId],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SightingTile extends StatelessWidget {
  const SightingTile({
    super.key,
    required this.sighting,
    required this.cards,
    this.placeName,
  });

  final Sighting sighting;
  final List<KnowledgeCard> cards;
  final String? placeName;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final s = sighting;
    final finding = s.verifiedFinding;
    return Material(
      color: KernelColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        side: const BorderSide(color: KernelColors.hairline),
      ),
      child: InkWell(
        key: Key('sighting-${s.id}'),
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        onTap: () => context.push(Routes.sighting(s.id)),
        child: Padding(
          padding: const EdgeInsets.all(KernelSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(s.source.icon, color: KernelColors.forest),
              const SizedBox(width: KernelSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sightingTitle(l, s, cards, lang),
                      style: textTheme.titleMedium?.copyWith(
                        color: KernelColors.forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: KernelSpace.xxs),
                    Text(
                      [
                        formatDateTime(context, s.observedAt),
                        s.source.label(l),
                        ?placeName,
                      ].join(' · '),
                      style: textTheme.bodyMedium?.copyWith(
                        color: KernelColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: KernelSpace.xs),
                    Wrap(
                      spacing: KernelSpace.xs,
                      runSpacing: KernelSpace.xs,
                      children: [
                        if (s.userCardId != null)
                          StatusChip(
                            label: l.pestCardYourPick,
                            tone: StatusTone.positive,
                            icon: Icons.person_rounded,
                          )
                        else if (s.analysis != null || s.sound != null)
                          StatusChip(
                            label: l.pestAiEstimated,
                            tone: StatusTone.info,
                            icon: Icons.science_rounded,
                          ),
                        StatusChip(
                          label: finding == null
                              ? l.pestNoFindingYet
                              : l.pestFindingChip(finding.label(l)),
                          tone: finding == null
                              ? StatusTone.neutral
                              : StatusTone.positive,
                          icon: Icons.fact_check_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
