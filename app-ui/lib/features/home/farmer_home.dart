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

class FarmerHome extends ConsumerWidget {
  const FarmerHome({super.key});

  static const role = Role.farmer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(itemsByRoleProvider(role));
    final stats = ref.watch(inspectionStatsProvider(roleScope(role))).value;
    final harvests = ref.watch(harvestsProvider).value ?? const <Harvest>[];
    final latest = ([...harvests]
          ..sort((a, b) => b.harvestedAt.compareTo(a.harvestedAt)))
        .firstOrNull;
    return PageList(
      children: [
        ScreenHeader(
          title: l.farmerHomeTitle,
          subtitle: latest == null
              ? role.tagline(l)
              : l.farmerHomeHarvestSubtitle(latest.name),
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('empty-items'),
                illustration: KernelIllustrations.sacks,
                message: l.emptyItemsMessage(role.itemKind),
                detail: l.farmerEmptyDetail,
                actionLabel: l.emptyItemsAction(role.itemKind),
                onAction: () => context.push(Routes.newItem()),
              );
            }
            final followUps = stats == null ? 0 : stats.open + stats.inProgress;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NextStepSection(
                  role: role,
                  fallback: HeroActionCard(
                    key: const Key('hero-scan'),
                    eyebrow: l.heroEyebrowListen,
                    title: l.farmerHeroTitle,
                    subtitle: l.farmerHeroSubtitle,
                    actionLabel: l.heroStartScan,
                    onTap: () => context.go(Routes.scan),
                  ),
                ),
                const SizedBox(height: 12),
                KernelCard(
                  key: const Key('items-summary'),
                  icon: Icons.inventory_2_rounded,
                  title: l.registeredSacks(items.length),
                  subtitle: followUps == 0
                      ? l.noFollowUps
                      : l.sacksRequireFollowUp(followUps),
                  onTap: () => context.go(Routes.inventory),
                ),
              ],
            );
          },
        ),
        const InsightsCard(),
        KernelCard(
          key: const Key('harvests-card'),
          tone: KernelCardTone.ivory,
          icon: Icons.grass_rounded,
          title: l.harvestsTitle,
          subtitle: harvests.isEmpty
              ? l.harvestsEmptyCard
              : l.harvestsCount(harvests.length),
          onTap: () => context.push(
            latest == null ? Routes.newHarvest : Routes.harvest(latest.id),
          ),
        ),
        KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.format_list_numbered_rounded,
          title: l.queueTitle,
          subtitle: l.queueCardSubtitle,
          onTap: () => context.push(Routes.queue),
        ),
        KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.description_rounded,
          title: l.reportTitleFarmer,
          subtitle: latest == null
              ? l.preSaleCardSubtitle
              : l.preSaleCardHarvest(latest.name),
          onTap: () => latest == null
              ? context.go(Routes.reports)
              : context.push(Routes.harvest(latest.id)),
        ),
      ],
    );
  }
}
