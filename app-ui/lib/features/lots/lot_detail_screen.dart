import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';
import '../home/buyer_home.dart';
import '../reports/reports_screen.dart';

/// Lot detail. The screening status is set by a person after review; there
/// is no accept/reject action driven by scan predictions.
class LotDetailScreen extends ConsumerWidget {
  const LotDetailScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lot = ref.watch(lotProvider(lotId));
    return Scaffold(
      appBar: const KernelAppBar(title: 'Lot'),
      body: AsyncView<Lot?>(
        value: lot,
        data: (lot) => lot == null
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('This lot was not found on this phone.'),
              )
            : _LotBody(lot: lot),
      ),
    );
  }
}

class _LotBody extends ConsumerWidget {
  const _LotBody({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsByLotProvider(lot.id));
    final queue = ref
        .watch(
          inspectionQueueProvider((
            role: null,
            locationId: null,
            lotId: lot.id,
          )),
        )
        .value;
    return PageList(
      children: [
        ScreenHeader(title: lot.code, subtitle: lot.grainType),
        KernelCard(
          icon: Icons.local_shipping_outlined,
          title: '${lot.code} / ${lot.grainType}',
          subtitle: lot.supplierName == null
              ? 'Supplier not recorded'
              : 'Supplier: ${lot.supplierName}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldRow(
                label: 'Declared quantity',
                value: formatQuantity(lot.declaredQuantity, lot.quantityUnit),
              ),
              FieldRow(
                label: 'Received',
                value: formatDate(context, lot.receivedAt),
              ),
              if (queue != null)
                FieldRow(
                  label: 'Screened',
                  value:
                      '${queue.ranked.length} of ${countLabel(queue.ranked.length + queue.needsScan.length, 'sack', 'sacks')}',
                ),
            ],
          ),
        ),
        const SectionTitle('Screening status'),
        const Text(
          'You set this after reviewing scans and physical checks. Scans '
          'never change it, and Kernel never accepts or rejects a lot.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in ScreeningStatus.values)
              ChoiceChip(
                key: Key('status-${status.name}'),
                label: Text(status.label),
                selected: lot.screeningStatus == status,
                onSelected: (_) => ref
                    .read(lotRepositoryProvider)
                    .updateScreeningStatus(lot.id, status),
              ),
          ],
        ),
        StatusChip(
          label: 'Current: ${lot.screeningStatus.label}',
          tone: screeningTone(lot.screeningStatus),
        ),
        SectionTitle(
          'Sacks in this lot',
          trailing: TextButton.icon(
            onPressed: () => context.push(Routes.newItem(lotId: lot.id)),
            icon: const Icon(Icons.add),
            label: const Text('Register sack'),
          ),
        ),
        ExportPanel(
          scope: ReportScope(role: Role.buyer, lotId: lot.id),
          title: 'Lot ${lot.code} screening report',
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) => items.isEmpty
              ? EmptyState(
                  message: 'No sacks in this lot yet',
                  actionLabel: 'Register a sack in this lot',
                  onAction: () => context.push(Routes.newItem(lotId: lot.id)),
                )
              : Column(
                  children: [
                    for (final item in items)
                      ItemTile(
                        item: item,
                        onTap: () => context.push(Routes.item(item.id)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
