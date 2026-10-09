import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/record_tiles.dart';

/// Immutable scan history, newest first.
class ScanHistorySection extends ConsumerWidget {
  const ScanHistorySection({super.key, required this.item});

  final GrainItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scans = ref.watch(scansForItemProvider(item.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.scanHistoryTitle),
        const SizedBox(height: 4),
        Text(l.scanHistoryAppendOnly),
        const SizedBox(height: 8),
        AsyncView<List<ScanRecord>>(
          value: scans,
          data: (scans) => scans.isEmpty
              ? QuietNote(l.scanHistoryEmpty(item.ownerRole.itemKind))
              : Column(
                  key: const Key('scan-history'),
                  children: [
                    for (final scan in scans)
                      ScanRecordTile(
                        scan: scan,
                        onTap: () =>
                            context.push(Routes.result(item.id, scan.id)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Assign (or clear) who follows up an inspection.
Future<void> assignInspection(
  BuildContext context,
  WidgetRef ref,
  Inspection inspection, {
  List<String> suggestions = const [],
}) async {
  final l = context.l10n;
  final name = await promptText(
    context,
    title: l.assignDialogTitle,
    label: l.assignDialogLabel,
    initial: inspection.assignedTo,
    helper: l.assignDialogHelper,
    suggestions: suggestions,
    clearLabel: inspection.assignedTo == null ? null : l.assignClear,
  );
  if (name == null) return;
  await ref
      .read(inspectionRepositoryProvider)
      .assign(inspection.id, name.isEmpty ? null : name);
}

class InspectionsSection extends ConsumerWidget {
  const InspectionsSection({super.key, required this.item});

  final GrainItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final inspections = ref.watch(inspectionsForItemProvider(item.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.inspectionsTitle),
        const SizedBox(height: 8),
        AsyncView<List<Inspection>>(
          value: inspections,
          data: (inspections) => inspections.isEmpty
              ? QuietNote(l.inspectionsEmpty)
              : Column(
                  children: [
                    for (final inspection in inspections)
                      InspectionTile(
                        inspection: inspection,
                        onFollowUpChanged: (status) => ref
                            .read(inspectionRepositoryProvider)
                            .updateFollowUp(inspection.id, status),
                        onAssign: () =>
                            assignInspection(context, ref, inspection),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key, required this.item});

  final GrainItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final reminders = ref.watch(remindersForItemProvider(item.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.remindersTitle),
        const SizedBox(height: 8),
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
            if (active.isEmpty) return QuietNote(l.remindersEmpty);
            return Column(
              children: [
                for (final reminder in active)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: KernelColors.paper,
                      borderRadius: BorderRadius.circular(KernelRadii.md),
                      border: Border.all(color: KernelColors.hairline),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.alarm_rounded),
                      title: Text(
                        l.recheckOn(formatDateTime(context, reminder.dueAt)),
                      ),
                      subtitle: Text(reminder.status.label(l)),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: l.reminderMarkDone,
                            icon: const Icon(Icons.check_rounded),
                            onPressed: () => ref
                                .read(reminderRepositoryProvider)
                                .markDone(reminder.id),
                          ),
                          IconButton(
                            tooltip: l.reminderCancel,
                            icon: const Icon(Icons.close_rounded),
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
}
