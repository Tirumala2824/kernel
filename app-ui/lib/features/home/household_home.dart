import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';

class HouseholdHome extends ConsumerWidget {
  const HouseholdHome({super.key});

  static const role = Role.household;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsByRoleProvider(role));
    final upcoming = ref.watch(upcomingRemindersProvider);
    return PageList(
      children: [
        const ScreenHeader(
          title: 'Household storage',
          subtitle: 'Home grain tracker',
        ),
        KernelCard(
          key: const Key('hero-scan'),
          tone: KernelCardTone.hero,
          icon: Icons.graphic_eq,
          title: 'Scan a container',
          subtitle: 'Record grain condition',
          onTap: () => context.go(Routes.scan),
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('empty-items'),
                message: 'No containers yet',
                detail: 'Add a grain container to track its storage time.',
                actionLabel: 'Add your first container',
                onAction: () => context.push(Routes.newItem()),
              );
            }
            final reminders = upcoming.value ?? const <Reminder>[];
            return Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ContainerCard(
                      item: item,
                      nextReminder: _nextFor(item.id, reminders),
                    ),
                  ),
              ],
            );
          },
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            final ids = {for (final item in items) item.id};
            final mine = (upcoming.value ?? const <Reminder>[])
                .where((r) => ids.contains(r.itemId))
                .toList();
            return KernelCard(
              key: const Key('reminders-card'),
              tone: KernelCardTone.ivory,
              icon: Icons.alarm,
              title: 'Inspection reminders',
              subtitle: mine.isEmpty
                  ? 'No reminders scheduled. Open a container to set one.'
                  : '${countLabel(mine.length, 'reminder', 'reminders')} '
                        'scheduled',
            );
          },
        ),
      ],
    );
  }

  static Reminder? _nextFor(String itemId, List<Reminder> reminders) {
    final mine = reminders.where((r) => r.itemId == itemId).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return mine.firstOrNull;
  }
}

class _ContainerCard extends ConsumerWidget {
  const _ContainerCard({required this.item, required this.nextReminder});

  final GrainItem item;
  final Reminder? nextReminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationId = item.locationId;
    final place = locationId == null
        ? null
        : ref.watch(locationProvider(locationId)).value?.name;
    final scans = ref.watch(scansForItemProvider(item.id)).value;
    final latest = scans?.firstOrNull;
    final reminder = nextReminder;
    final reviewDue =
        reminder != null && !reminder.dueAt.isAfter(DateTime.now());

    return KernelCard(
      title: '${item.grainType} / ${place ?? item.label}',
      subtitle:
          'Stored ${countLabel(daysSince(item.storageDate), 'day', 'days')}',
      icon: Icons.kitchen,
      onTap: () => context.push(Routes.item(item.id)),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (latest == null)
            const StatusChip(label: 'Not scanned yet', tone: StatusTone.neutral)
          else
            ScanResultChip(quality: latest.quality, result: latest.result),
          if (reminder != null)
            StatusChip(
              label: reviewDue
                  ? 'Review due'
                  : 'Review on ${formatDate(context, reminder.dueAt)}',
              tone: reviewDue ? StatusTone.attention : StatusTone.neutral,
              icon: Icons.alarm,
            ),
        ],
      ),
    );
  }
}
