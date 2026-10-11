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
import '../../widgets/record_tiles.dart';

/// Harvest detail: its sacks, a pre-sale report (ReportKind.preSale for
/// this harvest), printable sack labels and archive.
class HarvestDetailScreen extends ConsumerWidget {
  const HarvestDetailScreen({super.key, required this.harvestId});

  final String harvestId;

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Harvest harvest,
  ) async {
    final l = context.l10n;
    final ok = await confirmArchive(
      context,
      kind: ArchiveKind.harvest,
      name: harvest.name,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(harvestRepositoryProvider).archive(harvest.id);
    messenger.showSnackBar(SnackBar(content: Text(l.archivedSnack)));
    if (context.mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final harvest = ref.watch(harvestProvider(harvestId));
    final loaded = harvest.value;
    return Scaffold(
      appBar: KernelAppBar(
        title: l.harvestAppBar,
        actions: [
          if (loaded != null && loaded.archivedAt == null)
            IconButton(
              key: const Key('archive-harvest'),
              tooltip: l.archiveAction,
              icon: const Icon(Icons.inventory_rounded),
              onPressed: () => _archive(context, ref, loaded),
            ),
        ],
      ),
      body: AsyncView<Harvest?>(
        value: harvest,
        data: (harvest) => harvest == null
            ? NotFoundNote(l.harvestNotFound)
            : _HarvestBody(harvest: harvest),
      ),
    );
  }
}

class _HarvestBody extends ConsumerWidget {
  const _HarvestBody({required this.harvest});

  final Harvest harvest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sacks = ref.watch(itemsByHarvestProvider(harvest.id));
    final notes = harvest.notes;
    return PageList(
      children: [
        ScreenHeader(
          eyebrow: l.harvestsTitle,
          title: harvest.name,
          subtitle: l.harvestCardSubtitle(
            harvest.grainType,
            formatDate(context, harvest.harvestedAt),
          ),
        ),
        if (notes != null && notes.isNotEmpty) QuietNote(notes),
        ActionWrap(
          children: [
            FilledButton.icon(
              key: const Key('harvest-add-sack'),
              onPressed: () =>
                  context.push(Routes.newItem(harvestId: harvest.id)),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.harvestAddSack),
            ),
          ],
        ),
        SectionTitle(l.harvestSacksTitle),
        AsyncView<List<GrainItem>>(
          value: sacks,
          data: (sacks) {
            if (sacks.isEmpty) {
              return EmptyState(
                key: const Key('empty-harvest-sacks'),
                illustration: KernelIllustrations.harvest,
                message: l.harvestSacksEmpty,
                detail: l.harvestSacksEmptyDetail,
                actionLabel: l.harvestAddSack,
                onAction: () =>
                    context.push(Routes.newItem(harvestId: harvest.id)),
              );
            }
            return Column(
              children: [
                for (final sack in sacks) _HarvestSackTile(item: sack),
              ],
            );
          },
        ),
        ExportPanel(
          key: const Key('pre-sale-panel'),
          scope: ReportScope(
            role: Role.farmer,
            kind: ReportKind.preSale,
            harvestId: harvest.id,
          ),
          title: l.preSaleCardHarvest(harvest.name),
          subtitle: l.preSaleBody,
        ),
        SackLabelsPanel(
          scope: ReportScope(
            role: Role.farmer,
            kind: ReportKind.sackLabels,
            harvestId: harvest.id,
          ),
        ),
      ],
    );
  }
}

class _HarvestSackTile extends ConsumerWidget {
  const _HarvestSackTile({required this.item});

  final GrainItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scans = ref.watch(scansForItemProvider(item.id));
    return ItemTile(
      item: item,
      onTap: () => context.push(Routes.item(item.id)),
      footer: CurrentDataView<List<ScanRecord>>(
        value: scans,
        data: (records) {
          final latest = records.firstOrNull;
          return latest == null
              ? Text(l.notScannedYet)
              : ScanResultChip(quality: latest.quality, result: latest.result);
        },
      ),
    );
  }
}
