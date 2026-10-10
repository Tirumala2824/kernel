import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../brand/illustrations.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_card.dart';
import 'next_step_section.dart';

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
    final l = context.l10n;
    final items = ref.watch(itemsByRoleProvider(role));
    final places = ref.watch(childLocationsProvider(null)).value ?? const [];
    final activity = ref.watch(scanActivityProvider(roleScope(role))).value;
    final stats = ref.watch(inspectionStatsProvider(roleScope(role))).value;
    final queue = ref.watch(inspectionQueueProvider(queueScope)).value;

    return PageList(
      children: [
        ScreenHeader(
          title: l.fpoHomeTitle,
          subtitle: places.isEmpty
              ? l.fpoHomeSubtitle
              : places.map((p) => p.name).join(' • '),
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('empty-items'),
                illustration: KernelIllustrations.sacks,
                message: l.emptyItemsMessage(role.itemKind),
                detail: l.fpoEmptyDetail,
                actionLabel: l.emptyItemsAction(role.itemKind),
                onAction: () => context.push(Routes.newItem()),
              );
            }
            final open = stats == null ? 0 : stats.open + stats.inProgress;
            final flagged = queue?.ranked
                .where((e) => e.reason != RankReason.clean)
                .length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NextStepSection(
                  role: role,
                  fallback: HeroActionCard(
                    key: const Key('hero-scan'),
                    eyebrow: l.heroEyebrowListen,
                    title: l.batchScanTitle,
                    subtitle: l.batchScanSubtitle,
                    actionLabel: l.heroStartBatch,
                    icon: Icons.playlist_play_rounded,
                    onTap: () => context.push(Routes.batchSetup),
                  ),
                ),
                const SizedBox(height: 12),
                KernelCard(
                  key: const Key('items-summary'),
                  icon: Icons.inventory_2_rounded,
                  title: l.registeredSacks(items.length),
                  subtitle: activity == null
                      ? l.loading
                      : l.scansTodayCount(activity.today),
                  onTap: () => context.push(Routes.scansToday),
                ),
                const SizedBox(height: 12),
                KernelCard(
                  key: const Key('queue-card'),
                  tone: (flagged ?? 0) > 0
                      ? KernelCardTone.attention
                      : KernelCardTone.sage,
                  icon: Icons.format_list_numbered_rounded,
                  title: l.queueTitle,
                  subtitle: queue == null || flagged == null
                      ? l.loading
                      : l.queueSummary(flagged, queue.needsScan.length),
                  onTap: () => context.push(Routes.queue),
                ),
                const SizedBox(height: 12),
                KernelCard(
                  key: const Key('assigned-card'),
                  tone: KernelCardTone.ivory,
                  icon: Icons.assignment_ind_rounded,
                  title: l.assignedTitle,
                  subtitle: open == 0 ? l.assignedNone : l.inspectionsOpen(open),
                  onTap: () => context.push(Routes.assignedInspections),
                ),
              ],
            );
          },
        ),
        const InsightsCard(),
        KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.add_home_work_rounded,
          title: l.fpoAddLocationTitle,
          subtitle: l.fpoAddLocationSubtitle,
          onTap: () => context.push(Routes.newLocation()),
        ),
      ],
    );
  }
}
