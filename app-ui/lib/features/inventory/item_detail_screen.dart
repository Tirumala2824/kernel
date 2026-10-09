import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';
import '../household/reminder_sheet.dart';
import 'item_sections.dart';

/// Item fields, its immutable scan history (newest first), inspections,
/// re-check reminders, archive, and (research mode) labelled recordings.
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  Future<void> _archive(BuildContext context, WidgetRef ref, GrainItem item) async {
    final l = context.l10n;
    final ok = await confirmArchive(
      context,
      kind: ArchiveKind.item,
      name: item.label,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(itemRepositoryProvider).archive(item.id);
    messenger.showSnackBar(SnackBar(content: Text(l.archivedSnack)));
    ref.invalidate(itemProvider(item.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final item = ref.watch(itemProvider(itemId));
    final loaded = item.value;
    return Scaffold(
      appBar: KernelAppBar(
        title: l.itemDetailAppBar,
        actions: [
          if (loaded != null && !loaded.isArchived)
            PopupMenuButton<String>(
              key: const Key('item-menu'),
              tooltip: l.menuTooltip,
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (_) => _archive(context, ref, loaded),
              itemBuilder: (_) => [
                PopupMenuItem(
                  key: const Key('archive-item'),
                  value: 'archive',
                  child: ListTile(
                    leading: const Icon(Icons.inventory_rounded),
                    title: Text(l.archiveItemMenu(loaded.ownerRole.itemKind)),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: AsyncView<GrainItem?>(
        value: item,
        data: (item) => item == null
            ? NotFoundNote(l.itemNotFound)
            : _ItemDetailBody(item: item),
      ),
    );
  }
}

class _ItemDetailBody extends ConsumerWidget {
  const _ItemDetailBody({required this.item});

  final GrainItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final kind = item.ownerRole.itemKind;
    final research = ref.watch(researchModeProvider).value ?? false;

    return PageList(
      children: [
        ScreenHeader(title: item.label, subtitle: item.grainType),
        if (item.isArchived)
          NoticeBanner(
            key: const Key('archived-banner'),
            title: l.archivedBadge,
            text: l.archivedItemNotice,
            tone: StatusTone.neutral,
            icon: Icons.inventory_rounded,
          ),
        if (item.isArchived)
          OutlinedButton.icon(
            key: const Key('restore-item'),
            onPressed: () async {
              await ref.read(itemRepositoryProvider).unarchive(item.id);
              ref.invalidate(itemProvider(item.id));
            },
            icon: const Icon(Icons.unarchive_rounded),
            label: Text(l.restoreAction),
          ),
        ItemSummaryCard(item: item),
        if (!item.isArchived)
          ActionWrap(
            children: [
              FilledButton.icon(
                key: const Key('action-scan-item'),
                onPressed: () => context.push(Routes.scanItem(item.id)),
                icon: const Icon(Icons.graphic_eq_rounded),
                label: Text(l.scanThisItem(kind)),
              ),
              OutlinedButton.icon(
                key: const Key('action-inspect'),
                onPressed: () => context.push(Routes.inspect(item.id)),
                icon: const Icon(Icons.person_search_rounded),
                label: Text(l.actionRecordInspection),
              ),
              OutlinedButton.icon(
                key: const Key('action-reminder'),
                onPressed: () => showReminderSheet(
                  context,
                  itemId: item.id,
                  itemLabel: item.label,
                ),
                icon: const Icon(Icons.alarm_add_rounded),
                label: Text(l.setReminderAction),
              ),
            ],
          ),
        if (research && !item.isArchived)
          KernelCard(
            key: const Key('action-research'),
            tone: KernelCardTone.ivory,
            icon: Icons.science_rounded,
            title: l.researchRecordTitle,
            subtitle: l.researchRecordSubtitle,
            onTap: () => context.push(Routes.researchScan(item.id)),
          ),
        ScanHistorySection(item: item),
        InspectionsSection(item: item),
        RemindersSection(item: item),
      ],
    );
  }
}

/// Item card reused by the detail and result screens.
class ItemSummaryCard extends ConsumerWidget {
  const ItemSummaryCard({super.key, required this.item, this.onTap});

  final GrainItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locationId = item.locationId;
    final lotId = item.lotId;
    final harvestId = item.harvestId;
    final location = locationId == null
        ? null
        : ref.watch(locationProvider(locationId)).value;
    final lot = lotId == null ? null : ref.watch(lotProvider(lotId)).value;
    final harvest = harvestId == null
        ? null
        : ref.watch(harvestProvider(harvestId)).value;
    return KernelCard(
      key: const Key('item-card'),
      title: item.label,
      subtitle: item.grainType,
      icon: item.ownerRole == Role.household
          ? Icons.kitchen_rounded
          : Icons.inventory_2_rounded,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldRow(
            label: l.fieldQuantity,
            value: formatQuantity(item.quantity, item.quantityUnit),
          ),
          FieldRow(
            label: l.fieldStoredSince,
            value: l.storedSinceValue(
              formatDate(context, item.storageDate),
              daysSince(item.storageDate),
            ),
          ),
          if (location != null)
            FieldRow(
              label: l.fieldLocation,
              value: l.nameWithType(location.name, location.type.label(l)),
            ),
          if (lot != null) FieldRow(label: l.fieldLot, value: lot.code),
          if (harvest != null)
            FieldRow(label: l.fieldHarvest, value: harvest.name),
          const SizedBox(height: 4),
          StatusChip(
            label: l.registeredAs(item.ownerRole.title(l)),
            icon: item.ownerRole.icon,
          ),
        ],
      ),
    );
  }
}
