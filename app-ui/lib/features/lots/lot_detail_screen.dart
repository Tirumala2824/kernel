import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../brand/illustrations.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/export_panel.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';
import '../home/buyer_home.dart';
import 'lot_sections.dart';

/// Lot detail. The screening status is set by a person after review; there
/// is no accept/reject action driven by scan predictions.
class LotDetailScreen extends ConsumerWidget {
  const LotDetailScreen({super.key, required this.lotId});

  final String lotId;

  Future<void> _archive(BuildContext context, WidgetRef ref, Lot lot) async {
    final l = context.l10n;
    final ok = await confirmArchive(
      context,
      kind: ArchiveKind.lot,
      name: lot.code,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(lotRepositoryProvider).archive(lot.id);
    messenger.showSnackBar(SnackBar(content: Text(l.archivedSnack)));
    if (context.mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lot = ref.watch(lotProvider(lotId));
    final loaded = lot.value;
    return Scaffold(
      appBar: KernelAppBar(
        title: l.lotAppBar,
        actions: [
          if (loaded != null && !loaded.isArchived)
            IconButton(
              key: const Key('archive-lot'),
              tooltip: l.archiveAction,
              icon: const Icon(Icons.inventory_rounded),
              onPressed: () => _archive(context, ref, loaded),
            ),
        ],
      ),
      body: AsyncView<Lot?>(
        value: lot,
        data: (lot) =>
            lot == null ? NotFoundNote(l.lotNotFound) : _LotBody(lot: lot),
      ),
    );
  }
}

class _LotBody extends ConsumerWidget {
  const _LotBody({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
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
    final sacks = items.value ?? const <GrainItem>[];
    return PageList(
      children: [
        ScreenHeader(title: lot.code, subtitle: lot.grainType),
        KernelCard(
          icon: Icons.local_shipping_rounded,
          title: l.lotTitle(lot.code, lot.grainType),
          subtitle: lot.supplierName == null
              ? l.supplierNotRecorded
              : l.supplierChip(lot.supplierName!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldRow(
                label: l.fieldDeclaredQuantity,
                value: formatQuantity(lot.declaredQuantity, lot.quantityUnit),
              ),
              FieldRow(
                label: l.fieldReceived,
                value: formatDate(context, lot.receivedAt),
              ),
              if (queue != null)
                FieldRow(
                  label: l.fieldScreened,
                  value: l.lotScreenedCount(
                    queue.ranked.length,
                    queue.ranked.length + queue.needsScan.length,
                  ),
                ),
            ],
          ),
        ),
        SectionTitle(l.screeningStatusTitle),
        Text(l.screeningStatusBody),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in ScreeningStatus.values)
              ChoiceChip(
                key: Key('status-${status.name}'),
                label: Text(status.label(l)),
                selected: lot.screeningStatus == status,
                onSelected: (_) => ref
                    .read(lotRepositoryProvider)
                    .updateScreeningStatus(lot.id, status),
              ),
          ],
        ),
        StatusChip(
          label: l.currentStatus(lot.screeningStatus.label(l)),
          tone: screeningTone(lot.screeningStatus),
          icon: Icons.fact_check_rounded,
        ),
        SectionTitle(
          l.lotSacksTitle,
          trailing: TextButton.icon(
            onPressed: () => context.push(Routes.newItem(lotId: lot.id)),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.registerItemAction('sack')),
          ),
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) => items.isEmpty
              ? EmptyState(
                  key: const Key('empty-lot-sacks'),
                  illustration: KernelIllustrations.sacks,
                  message: l.lotSacksEmpty,
                  actionLabel: l.lotSacksEmptyAction,
                  onAction: () => context.push(Routes.newItem(lotId: lot.id)),
                )
              : QuietNote(l.sackCount(items.length)),
        ),
        if (sacks.isNotEmpty) ...[
          SampleScansSection(lot: lot, sacks: sacks),
          PhysicalChecksSection(sacks: sacks),
        ],
        ExportPanel(
          key: const Key('lot-summary-panel'),
          scope: ReportScope(
            role: Role.buyer,
            kind: ReportKind.lotSummary,
            lotId: lot.id,
          ),
          title: l.lotSummaryTitle(lot.code),
          subtitle: l.lotSummaryBody,
        ),
        SackLabelsPanel(
          scope: ReportScope(
            role: Role.buyer,
            kind: ReportKind.sackLabels,
            lotId: lot.id,
          ),
        ),
      ],
    );
  }
}
