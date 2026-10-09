import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';

class BuyerHome extends ConsumerWidget {
  const BuyerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lots = ref.watch(lotsProvider);
    return PageList(
      children: [
        const ScreenHeader(
          title: 'Incoming lots',
          subtitle: 'Procurement screening',
        ),
        KernelCard(
          key: const Key('hero-register-lot'),
          tone: KernelCardTone.hero,
          icon: Icons.local_shipping_outlined,
          title: 'Register delivery',
          subtitle: 'Supplier, lot, grain, quantity',
          onTap: () => context.push(Routes.newLot),
        ),
        AsyncView<List<Lot>>(
          value: lots,
          data: (lots) {
            if (lots.isEmpty) {
              return EmptyState(
                key: const Key('empty-lots'),
                message: 'No lots yet',
                detail: 'Register a delivery to screen its sacks.',
                actionLabel: 'Register your first delivery',
                onAction: () => context.push(Routes.newLot),
              );
            }
            final sorted = [...lots]
              ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
            return Column(
              children: [
                for (final lot in sorted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LotCard(lot: lot),
                  ),
              ],
            );
          },
        ),
        KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.description_outlined,
          title: 'Inspection report',
          subtitle: 'Export lot screening from your stored records',
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
    final queue = ref
        .watch(
          inspectionQueueProvider((
            role: null,
            locationId: null,
            lotId: lot.id,
          )),
        )
        .value;
    final screened = queue?.ranked.length ?? 0;
    final total = queue == null
        ? 0
        : queue.ranked.length + queue.needsScan.length;
    return KernelCard(
      key: Key('lot-${lot.id}'),
      icon: Icons.inventory_outlined,
      title: '${lot.code} / ${lot.grainType}',
      subtitle: queue == null
          ? 'Loading sacks'
          : total == 0
          ? 'No sacks registered in this lot yet'
          : '$screened of ${countLabel(total, 'sack', 'sacks')} screened',
      onTap: () => context.push(Routes.lot(lot.id)),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusChip(
            label: lot.screeningStatus.label,
            tone: screeningTone(lot.screeningStatus),
          ),
          if (lot.supplierName case final supplier? when supplier.isNotEmpty)
            StatusChip(
              label: 'Supplier: $supplier',
              icon: Icons.store_outlined,
            ),
        ],
      ),
    );
  }
}
