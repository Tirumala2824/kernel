import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../app/rules.dart';
import '../../l10n/l10n.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';
import 'reminder_sheet.dart';

/// Review status chip from the last usable scan (rules.reviewStatus).
class ReviewChip extends StatelessWidget {
  const ReviewChip({super.key, required this.status});

  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (status.state) {
      ReviewState.neverScanned => StatusChip(
        label: l.reviewNeverScanned,
        tone: StatusTone.attention,
        icon: Icons.event_busy_rounded,
      ),
      ReviewState.due => StatusChip(
        label: l.reviewDueSince(status.daysSinceScan ?? 0),
        tone: StatusTone.attention,
        icon: Icons.event_repeat_rounded,
      ),
      ReviewState.upToDate => StatusChip(
        label: l.reviewNextIn(status.daysUntilDue ?? 0),
        tone: StatusTone.positive,
        icon: Icons.event_available_rounded,
      ),
    };
  }
}

/// One household container: `{grain} / {place}`, storage days, review
/// status, latest scan, next reminder, and Recheck / Remind me actions.
class ContainerCard extends ConsumerWidget {
  const ContainerCard({
    super.key,
    required this.item,
    required this.nextReminder,
  });

  final GrainItem item;
  final Reminder? nextReminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locationId = item.locationId;
    final place = locationId == null
        ? null
        : ref.watch(locationProvider(locationId)).value?.name;
    final scans = ref.watch(scansForItemProvider(item.id)).value;
    final latest = scans?.firstOrNull;
    final reminder = nextReminder;
    final reminderDue =
        reminder != null && !reminder.dueAt.isAfter(DateTime.now());

    return KernelCard(
      key: Key('container-${item.id}'),
      title: l.containerTitle(item.grainType, place ?? item.label),
      subtitle: l.storedDays(daysSince(item.storageDate)),
      icon: Icons.kitchen_rounded,
      onTap: () => context.push(Routes.item(item.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (scans != null) ReviewChip(status: reviewStatus(scans)),
              if (latest != null)
                ScanResultChip(quality: latest.quality, result: latest.result),
              if (reminder != null)
                StatusChip(
                  label: reminderDue
                      ? l.reviewDue
                      : l.reminderOn(formatDate(context, reminder.dueAt)),
                  tone: reminderDue ? StatusTone.attention : StatusTone.neutral,
                  icon: Icons.alarm_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: Key('recheck-${item.id}'),
                onPressed: () => context.push(Routes.scanItem(item.id)),
                icon: const Icon(Icons.graphic_eq_rounded),
                label: Text(l.recheckAction),
              ),
              OutlinedButton.icon(
                key: Key('remind-${item.id}'),
                onPressed: () => showReminderSheet(
                  context,
                  itemId: item.id,
                  itemLabel: item.label,
                ),
                icon: const Icon(Icons.alarm_add_rounded),
                label: Text(l.remindMeAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
