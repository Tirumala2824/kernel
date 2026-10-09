import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_card.dart';
import 'home_screen.dart';

/// How many recent scans to read for the "scanned today" count.
const recentScanWindow = 500;

class FpoHome extends ConsumerWidget {
  const FpoHome({super.key});

  static const role = Role.storageFpo;
  static const QueueScope queueScope = (
    role: role,
    locationId: null,
    lotId: null,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsByRoleProvider(role));
    final places = ref.watch(childLocationsProvider(null)).value ?? const [];
    final recent = ref.watch(recentScansProvider(recentScanWindow)).value;
    final queue = ref.watch(inspectionQueueProvider(queueScope)).value;
    final open = ref.watch(openInspectionsProvider).value ?? const [];

    return PageList(
      children: [
        ScreenHeader(
          title: 'Warehouse overview',
          subtitle: places.isEmpty
              ? 'Warehouses, rooms and stacks'
              : places.map((p) => p.name).join(' • '),
        ),
        KernelCard(
          key: const Key('hero-scan'),
          tone: KernelCardTone.hero,
          icon: Icons.playlist_play,
          title: 'Batch scan',
          subtitle: 'Scan sacks one at a time',
          onTap: () => context.go(Routes.scan),
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('empty-items'),
                message: 'No sacks yet',
                detail:
                    'Register sacks, then scan them one at a time to build '
                    'an inspection queue.',
                actionLabel: 'Register your first sack',
                onAction: () => context.push(Routes.newItem()),
              );
            }
            final ids = {for (final item in items) item.id};
            final today = DateUtils.dateOnly(DateTime.now());
            final scannedToday = (recent ?? const [])
                .where(
                  (s) =>
                      ids.contains(s.itemId) &&
                      !s.capturedAt.toLocal().isBefore(today),
                )
                .map((s) => s.itemId)
                .toSet()
                .length;
            final assigned = openFor(open, items);
            final flagged = queue == null
                ? 0
                : queue.ranked
                      .where(
                        (e) =>
                            e.latestValidScan.result ==
                                Classification.infested ||
                            e.latestValidScan.result ==
                                Classification.uncertain,
                      )
                      .length;
            return Column(
              children: [
                KernelCard(
                  key: const Key('items-summary'),
                  icon: Icons.inventory_2_outlined,
                  title: countLabel(
                    items.length,
                    'registered sack',
                    'registered sacks',
                  ),
                  subtitle:
                      '${countLabel(scannedToday, 'sack', 'sacks')} '
                      'scanned today',
                  onTap: () => context.go(Routes.inventory),
                ),
                const SizedBox(height: 12),
                KernelCard(
                  key: const Key('queue-card'),
                  tone: flagged > 0
                      ? KernelCardTone.attention
                      : KernelCardTone.sage,
                  icon: Icons.format_list_numbered,
                  title: 'Inspection queue',
                  subtitle: queue == null
                      ? 'Loading queue'
                      : '$flagged flagged · '
                            '${countLabel(queue.needsScan.length, 'sack needs', 'sacks need')}'
                            ' a scan',
                  onTap: () => context.push(Routes.queue),
                ),
                const SizedBox(height: 12),
                KernelCard(
                  key: const Key('assigned-card'),
                  tone: KernelCardTone.ivory,
                  icon: Icons.assignment_ind_outlined,
                  title: 'Assigned inspections',
                  subtitle: assigned.isEmpty
                      ? 'No open inspections'
                      : '${countLabel(assigned.length, 'inspection', 'inspections')}'
                            ' open',
                  onTap: assigned.isEmpty
                      ? null
                      : () => context.push(Routes.item(assigned.first.itemId)),
                ),
              ],
            );
          },
        ),
        KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.add_home_work_outlined,
          title: 'Add warehouse, room or stack',
          subtitle: 'Organise sacks by where they are stored',
          onTap: () => context.push(Routes.newLocation()),
        ),
      ],
    );
  }
}
