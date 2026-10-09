import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/record_tiles.dart';
import '../home/buyer_home.dart';

/// Inventory tab. Same data model for every role, with role-specific
/// labels and sections (places for Household/FPO, lots for Buyer).
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
    final items = ref.watch(itemsByRoleProvider(role));
    final showPlaces = role == Role.household || role == Role.storageFpo;
    return PageList(
      children: [
        ScreenHeader(
          title: role.inventoryLabel,
          subtitle: switch (role) {
            Role.farmer => 'Your registered sacks',
            Role.household => 'Your grain containers and where they are kept',
            Role.storageFpo => 'Warehouses, rooms, stacks and sacks',
            Role.buyer => 'Incoming lots and their sacks',
          },
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (role == Role.buyer)
              FilledButton.icon(
                key: const Key('action-new-lot'),
                onPressed: () => context.push(Routes.newLot),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Register delivery'),
              ),
            FilledButton.icon(
              key: const Key('action-new-item'),
              onPressed: () => context.push(Routes.newItem()),
              icon: const Icon(Icons.add),
              label: Text(role.registerItemAction),
            ),
            if (showPlaces)
              OutlinedButton.icon(
                key: const Key('action-new-location'),
                onPressed: () => context.push(Routes.newLocation()),
                icon: const Icon(Icons.add_home_work_outlined),
                label: Text(
                  role == Role.household ? 'Add place' : 'Add location',
                ),
              ),
          ],
        ),
        if (role == Role.buyer) const _LotsSection(),
        if (showPlaces) _PlacesSection(role: role),
        SectionTitle(
          role.itemNounPlural[0].toUpperCase() +
              role.itemNounPlural.substring(1),
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('empty-items'),
                message: 'No ${role.itemNounPlural} yet',
                actionLabel: role == Role.household
                    ? 'Add your first container'
                    : 'Register your first sack',
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

class _LotsSection extends ConsumerWidget {
  const _LotsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lots = ref.watch(lotsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Lots'),
        AsyncView<List<Lot>>(
          value: lots,
          data: (lots) => lots.isEmpty
              ? const Text('No lots yet. Register a delivery to add one.')
              : Column(
                  children: [
                    for (final lot in lots)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LotCard(lot: lot),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _PlacesSection extends ConsumerWidget {
  const _PlacesSection({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(childLocationsProvider(null));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(role == Role.household ? 'Places' : 'Locations'),
        AsyncView<List<Location>>(
          value: places,
          data: (places) => places.isEmpty
              ? Text(
                  role == Role.household
                      ? 'No places yet. Add one to say where containers are kept.'
                      : 'No warehouse yet. Add one, then its rooms and stacks.',
                )
              : Column(
                  children: [
                    for (final place in places)
                      LocationTile(
                        location: place,
                        onTap: () => context.push(Routes.location(place.id)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class LocationTile extends StatelessWidget {
  const LocationTile({super.key, required this.location, required this.onTap});

  final Location location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        minTileHeight: 56,
        leading: Icon(switch (location.type) {
          LocationType.home => Icons.home_outlined,
          LocationType.container => Icons.kitchen,
          LocationType.warehouse => Icons.warehouse_outlined,
          LocationType.room => Icons.meeting_room_outlined,
          LocationType.stack => Icons.layers_outlined,
        }),
        title: Text(location.name),
        subtitle: Text(location.type.label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
