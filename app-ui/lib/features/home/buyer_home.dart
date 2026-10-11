import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../brand/illustrations.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';
import '../pest_id/pest_hub.dart';
import 'next_step_section.dart';

class BuyerHome extends ConsumerWidget {
  const BuyerHome({super.key});

  static const role = Role.buyer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lots = ref.watch(lotsProvider);
    final statsValue = ref.watch(inspectionStatsProvider(roleScope(role)));
    final stats = statsValue.isLoading || statsValue.hasError
        ? null
        : statsValue.value;
    final registerLot = HeroActionCard(
      key: const Key('hero-register-lot'),
      eyebrow: l.heroEyebrowDelivery,
      title: l.buyerHeroTitle,
      subtitle: l.buyerHeroSubtitle,
      actionLabel: l.buyerHeroAction,
      icon: Icons.local_shipping_rounded,
      onTap: () => context.push(Routes.newLot),
    );
    return PageList(
      children: [
        ScreenHeader(title: l.buyerHomeTitle, subtitle: l.buyerHomeSubtitle),
        AsyncView<List<Lot>>(
          value: lots,
          data: (lots) {
            if (lots.isEmpty) {
              return EmptyState(
                key: const Key('empty-lots'),
                illustration: KernelIllustrations.lots,
                message: l.lotsEmptyMessage,
                detail: l.lotsEmptyDetail,
                actionLabel: l.lotsEmptyAction,
                onAction: () => context.push(Routes.newLot),
              );
            }
            final sorted = [...lots]
              ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
            final open = stats == null ? 0 : stats.open + stats.inProgress;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NextStepSection(
                  role: role,
                  fallback: registerLot,
                  shortcut: OutlinedButton.icon(
                    key: const Key('quick-register-lot'),
                    onPressed: () => context.push(Routes.newLot),
                    icon: const Icon(Icons.local_shipping_rounded),
                    label: Text(l.buyerHeroAction),
                  ),
                ),
                if (stats != null && stats.total > 0) ...[
                  const SizedBox(height: 12),
                  QuietNote(
                    open == 0 ? l.assignedNone : l.inspectionsOpen(open),
                    key: const Key('buyer-inspections'),
                    icon: Icons.person_search_rounded,
                  ),
                ],
                const SizedBox(height: 12),
                for (final lot in sorted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LotCard(lot: lot),
                  ),
              ],
            );
          },
        ),
        const InsightsCard(),
        const PestIdActionCard(),
        KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.description_rounded,
          title: l.buyerReportCardTitle,
          subtitle: l.buyerReportCardSubtitle,
          onTap: () => context.go(Routes.reports),
        ),
      ],
    );
  }
}

StatusTone screeningTone(ScreeningStatus status) => switch (status) {
  ScreeningStatus.needsPhysicalCheck => StatusTone.attention,
  ScreeningStatus.reviewed => StatusTone.positive,
  ScreeningStatus.pending || ScreeningStatus.screening => StatusTone.neutral,
};

/// `{lot} / {grain}` with "{s} of {n} sacks screened" from the ranking
/// service: only sacks with a valid, comparable scan count as screened.
class LotCard extends ConsumerWidget {
  const LotCard({super.key, required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final queueValue = ref.watch(
      inspectionQueueProvider((role: null, locationId: null, lotId: lot.id)),
    );
    final queue = queueValue.isLoading || queueValue.hasError
        ? null
        : queueValue.value;
    final screened = queue?.ranked.length ?? 0;
    final total = queue == null
        ? 0
        : queue.ranked.length + queue.needsScan.length;
    return KernelCard(
      key: Key('lot-${lot.id}'),
      tone: KernelCardTone.ivory,
      icon: Icons.inventory_rounded,
      title: l.lotTitle(lot.code, lot.grainType),
      subtitle: queueValue.isLoading
          ? l.loading
          : queueValue.hasError
          ? l.errorCouldNotLoad
          : queue == null
          ? null
          : total == 0
          ? l.lotNoSacks
          : l.lotScreenedCount(screened, total),
      onTap: () => context.push(Routes.lot(lot.id)),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusChip(
            label: lot.screeningStatus.label(l),
            tone: screeningTone(lot.screeningStatus),
            icon: Icons.fact_check_rounded,
          ),
          if (lot.supplierName case final supplier? when supplier.isNotEmpty)
            StatusChip(
              label: l.supplierChip(supplier),
              icon: Icons.storefront_rounded,
            ),
        ],
      ),
    );
  }
}
