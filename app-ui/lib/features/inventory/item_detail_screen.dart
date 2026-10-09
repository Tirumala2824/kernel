import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';

/// Item fields, its immutable scan history (newest first), inspections and
/// re-check reminders.
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemProvider(itemId));
    return Scaffold(
      appBar: const KernelAppBar(title: 'Details'),
      body: AsyncView<GrainItem?>(
        value: item,
        data: (item) => item == null
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('This item was not found on this phone.'),
              )
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
    final scans = ref.watch(scansForItemProvider(item.id));
    final inspections = ref.watch(inspectionsForItemProvider(item.id));
    final reminders = ref.watch(remindersForItemProvider(item.id));
    final noun = item.ownerRole.itemNoun;

    return PageList(
      children: [
        ScreenHeader(title: item.label, subtitle: item.grainType),
        ItemSummaryCard(item: item),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const Key('action-scan-item'),
              onPressed: () => context.push(Routes.scanItem(item.id)),
              icon: const Icon(Icons.graphic_eq),
              label: Text('Scan this $noun'),
            ),
            OutlinedButton.icon(
              key: const Key('action-inspect'),
              onPressed: () => context.push(Routes.inspect(item.id)),
              icon: const Icon(Icons.person_search),
              label: const Text('Record inspection'),
            ),
            OutlinedButton.icon(
              key: const Key('action-reminder'),
              onPressed: () => _scheduleReminder(context, ref),
              icon: const Icon(Icons.alarm_add),
              label: const Text('Set re-check reminder'),
            ),
          ],
        ),
        const SectionTitle('Scan history'),
        const Text(
          'Every scan is kept as recorded. A new scan never changes an '
          'earlier one.',
        ),
        AsyncView<List<ScanRecord>>(
          value: scans,
          data: (scans) => scans.isEmpty
              ? Text('No scans yet. Use "Scan this $noun" to record one.')
              : Column(
                  key: const Key('scan-history'),
                  children: [
                    for (final scan in scans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ScanRecordTile(
                          scan: scan,
                          onTap: () =>
                              context.push(Routes.result(item.id, scan.id)),
                        ),
                      ),
                  ],
                ),
        ),
        const SectionTitle('Inspections'),
        AsyncView<List<Inspection>>(
          value: inspections,
          data: (inspections) => inspections.isEmpty
              ? const Text('No inspections recorded yet.')
              : Column(
                  children: [
                    for (final inspection in inspections)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InspectionTile(
                          inspection: inspection,
                          onFollowUpChanged: (status) => ref
                              .read(inspectionRepositoryProvider)
                              .updateFollowUp(inspection.id, status),
                        ),
                      ),
                  ],
                ),
        ),
        const SectionTitle('Reminders'),
        AsyncView<List<Reminder>>(
          value: reminders,
          data: (reminders) {
            final active =
                reminders
                    .where(
                      (r) =>
                          r.status == ReminderStatus.scheduled ||
                          r.status == ReminderStatus.fired,
                    )
                    .toList()
                  ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
            if (active.isEmpty) return const Text('No reminders set.');
            return Column(
              children: [
                for (final reminder in active)
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      minTileHeight: 56,
                      leading: const Icon(Icons.alarm),
                      title: Text(
                        'Re-check on ${formatDate(context, reminder.dueAt)}',
                      ),
                      subtitle: Text(reminder.status.label),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Mark done',
                            icon: const Icon(Icons.check),
                            onPressed: () => ref
                                .read(reminderRepositoryProvider)
                                .markDone(reminder.id),
                          ),
                          IconButton(
                            tooltip: 'Cancel reminder',
                            icon: const Icon(Icons.close),
                            onPressed: () => ref
                                .read(reminderRepositoryProvider)
                                .cancel(reminder.id),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _scheduleReminder(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: DateUtils.dateOnly(now),
      lastDate: now.add(const Duration(days: 366)),
      helpText: 'Re-check date',
    );
    if (picked == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final access = await ref
        .read(devicePermissionsProvider)
        .requestNotifications();
    try {
      await ref
          .read(reminderRepositoryProvider)
          .schedule(
            item.id,
            DateTime(picked.year, picked.month, picked.day, 9),
          );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            access == PermissionAccess.granted
                ? 'Reminder set'
                : 'Reminder saved. Notifications are off, so it will only '
                      'show inside the app.',
          ),
        ),
      );
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not set reminder: $e')),
      );
    }
  }
}

/// Item card reused by the detail and result screens.
class ItemSummaryCard extends ConsumerWidget {
  const ItemSummaryCard({super.key, required this.item, this.onTap});

  final GrainItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationId = item.locationId;
    final lotId = item.lotId;
    final location = locationId == null
        ? null
        : ref.watch(locationProvider(locationId)).value;
    final lot = lotId == null ? null : ref.watch(lotProvider(lotId)).value;
    return KernelCard(
      key: const Key('item-card'),
      title: item.label,
      subtitle: item.grainType,
      icon: Icons.inventory_2_outlined,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldRow(
            label: 'Quantity',
            value: formatQuantity(item.quantity, item.quantityUnit),
          ),
          FieldRow(
            label: 'Stored since',
            value:
                '${formatDate(context, item.storageDate)} '
                '(${countLabel(daysSince(item.storageDate), 'day', 'days')})',
          ),
          if (location != null)
            FieldRow(
              label: 'Location',
              value: '${location.name} (${location.type.label})',
            ),
          if (lot != null) FieldRow(label: 'Lot', value: lot.code),
          const SizedBox(height: 4),
          StatusChip(
            label: 'Registered as ${item.ownerRole.title}',
            icon: item.ownerRole.icon,
          ),
        ],
      ),
    );
  }
}
