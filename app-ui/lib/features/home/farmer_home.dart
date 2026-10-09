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

class FarmerHome extends ConsumerWidget {
  const FarmerHome({super.key});

  static const role = Role.farmer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsByRoleProvider(role));
    final open = ref.watch(openInspectionsProvider);
    return PageList(
      children: [
        const ScreenHeader(
          title: 'Farmer dashboard',
          subtitle: 'Harvest and pre-sale checks',
        ),
        KernelCard(
          key: const Key('hero-scan'),
          tone: KernelCardTone.hero,
          icon: Icons.graphic_eq,
          title: 'Scan grain',
          subtitle: 'Start a guided 2-second recording',
          onTap: () => context.go(Routes.scan),
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('empty-items'),
                message: 'No sacks yet',
                detail: 'Register a sack to start scanning and tracking it.',
                actionLabel: 'Register your first sack',
                onAction: () => context.push(Routes.newItem()),
              );
            }
            final followUps = openFor(open.value ?? const [], items).length;
            return KernelCard(
              key: const Key('items-summary'),
              icon: Icons.inventory_2_outlined,
              title: countLabel(
                items.length,
                'registered sack',
                'registered sacks',
              ),
              subtitle: followUps == 0
                  ? 'No follow-up inspections open'
                  : '${countLabel(followUps, 'sack requires', 'sacks require')}'
                        ' follow-up inspection',
              onTap: () => context.go(Routes.inventory),
            );
          },
        ),
        KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.grass,
          title: 'My grain',
          subtitle: 'Sacks, storage dates and scan history',
          onTap: () => context.go(Routes.inventory),
        ),
        KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.format_list_numbered,
          title: 'Inspection queue',
          subtitle: 'Which sacks to check first',
          onTap: () => context.push(Routes.queue),
        ),
        KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.description_outlined,
          title: 'Pre-sale report',
          subtitle: 'Export a summary built from your stored records',
          onTap: () => context.go(Routes.reports),
        ),
      ],
    );
  }
}
