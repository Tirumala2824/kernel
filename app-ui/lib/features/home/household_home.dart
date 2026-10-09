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
import '../household/container_card.dart';

class HouseholdHome extends ConsumerWidget {
  const HouseholdHome({super.key});

  static const role = Role.household;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(itemsByRoleProvider(role));
    final upcoming = ref.watch(upcomingRemindersProvider);
    return PageList(
      children: [
        ScreenHeader(
          title: l.householdHomeTitle,
          subtitle: l.householdHomeSubtitle,
        ),
        HeroActionCard(
          key: const Key('hero-scan'),
          eyebrow: l.heroEyebrowListen,
          title: l.householdHeroTitle,
          subtitle: l.householdHeroSubtitle,
          actionLabel: l.heroStartScan,
          onTap: () => context.go(Routes.scan),
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('empty-items'),
                illustration: KernelIllustrations.container,
                message: l.emptyItemsMessage(role.itemKind),
                detail: l.householdEmptyDetail,
                actionLabel: l.emptyItemsAction(role.itemKind),
                onAction: () => context.push(Routes.newItem()),
              );
            }
            final reminders = upcoming.value ?? const <Reminder>[];
            final ids = {for (final item in items) item.id};
            final mine = reminders.where((r) => ids.contains(r.itemId)).length;
            return Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ContainerCard(
                      item: item,
                      nextReminder: _nextFor(item.id, reminders),
                    ),
                  ),
                KernelCard(
                  key: const Key('reminders-card'),
                  tone: KernelCardTone.ivory,
                  icon: Icons.alarm_rounded,
                  title: l.remindersCardTitle,
                  subtitle: mine == 0
                      ? l.remindersCardEmpty
                      : l.remindersScheduled(mine),
                ),
              ],
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
