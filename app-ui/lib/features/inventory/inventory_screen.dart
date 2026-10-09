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
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/record_tiles.dart';
import 'inventory_sections.dart';

/// Inventory tab. Same data model for every role, with role-specific
/// labels and sections (harvests for Farmer, places for Household/FPO,
/// lots for Buyer).
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleProvider).value;
    return Scaffold(
      appBar: const KernelAppBar(showMenu: true),
      body: role == null ? const SizedBox.shrink() : _InventoryBody(role: role),
    );
  }
}

class _InventoryBody extends ConsumerWidget {
  const _InventoryBody({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(itemsByRoleProvider(role));
    final showPlaces = role == Role.household || role == Role.storageFpo;
    final kind = role.itemKind;
    return PageList(
      children: [
        ScreenHeader(
          title: role.inventoryLabel(l),
          subtitle: switch (role) {
            Role.farmer => l.inventorySubtitleFarmer,
            Role.household => l.inventorySubtitleHousehold,
            Role.storageFpo => l.inventorySubtitleFpo,
            Role.buyer => l.inventorySubtitleBuyer,
          },
        ),
        ActionWrap(
          children: [
            if (role == Role.buyer)
              FilledButton.icon(
                key: const Key('action-new-lot'),
                onPressed: () => context.push(Routes.newLot),
                icon: const Icon(Icons.local_shipping_rounded),
                label: Text(l.buyerHeroTitle),
              ),
            if (role == Role.farmer)
              FilledButton.icon(
                key: const Key('action-new-harvest'),
                onPressed: () => context.push(Routes.newHarvest),
                icon: const Icon(Icons.grass_rounded),
                label: Text(l.newHarvestAction),
              ),
            FilledButton.icon(
              key: const Key('action-new-item'),
              onPressed: () => context.push(Routes.newItem()),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.registerItemAction(kind)),
            ),
            if (showPlaces)
              OutlinedButton.icon(
                key: const Key('action-new-location'),
                onPressed: () => context.push(Routes.newLocation()),
                icon: const Icon(Icons.add_home_work_rounded),
                label: Text(
                  role == Role.household ? l.addPlace : l.addLocation,
                ),
              ),
          ],
        ),
        if (role == Role.farmer) const HarvestsSection(),
        if (role == Role.buyer) const LotsSection(),
        if (showPlaces) PlacesSection(role: role),
        SectionTitle(l.itemsSectionTitle(kind)),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('empty-items'),
                illustration: role == Role.household
                    ? KernelIllustrations.container
                    : KernelIllustrations.sacks,
                message: l.emptyItemsMessage(kind),
                actionLabel: l.emptyItemsAction(kind),
                onAction: () => context.push(Routes.newItem()),
              );
            }
            final sorted = [...items]
              ..sort(
                (a, b) =>
                    a.label.toLowerCase().compareTo(b.label.toLowerCase()),
              );
            return Column(
              children: [
                for (final item in sorted)
                  ItemTile(
                    item: item,
                    onTap: () => context.push(Routes.item(item.id)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
