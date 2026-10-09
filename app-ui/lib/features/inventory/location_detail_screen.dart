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
import 'inventory_screen.dart';

class LocationDetailScreen extends ConsumerWidget {
  const LocationDetailScreen({super.key, required this.locationId});

  final String locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider(locationId));
    final children = ref.watch(childLocationsProvider(locationId));
    final items = ref.watch(itemsByLocationProvider(locationId));
    final role = ref.watch(activeRoleProvider).value ?? Role.farmer;

    return Scaffold(
      appBar: const KernelAppBar(title: 'Location'),
      body: AsyncView<Location?>(
        value: location,
        data: (location) {
          if (location == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('This location was not found on this phone.'),
            );
          }
          return PageList(
            children: [
              ScreenHeader(title: location.name, subtitle: location.type.label),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        context.push(Routes.newItem(locationId: location.id)),
                    icon: const Icon(Icons.add),
                    label: Text('${role.registerItemAction} here'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push(Routes.newLocation(parentId: location.id)),
                    icon: const Icon(Icons.add_home_work_outlined),
                    label: const Text('Add inside'),
                  ),
                ],
              ),
              const SectionTitle('Inside'),
              AsyncView<List<Location>>(
                value: children,
                data: (children) => children.isEmpty
                    ? const Text('Nothing inside this location yet.')
                    : Column(
                        children: [
                          for (final child in children)
                            LocationTile(
                              location: child,
                              onTap: () =>
                                  context.push(Routes.location(child.id)),
                            ),
                        ],
                      ),
              ),
              SectionTitle(
                '${role.itemNounPlural[0].toUpperCase()}'
                '${role.itemNounPlural.substring(1)} here',
              ),
              AsyncView<List<GrainItem>>(
                value: items,
                data: (items) => items.isEmpty
                    ? Text('No ${role.itemNounPlural} stored here yet.')
                    : Column(
                        children: [
                          for (final item in items)
                            ItemTile(
                              item: item,
                              onTap: () => context.push(Routes.item(item.id)),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
