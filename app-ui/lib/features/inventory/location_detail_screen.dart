import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/export_panel.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/record_tiles.dart';

class LocationDetailScreen extends ConsumerWidget {
  const LocationDetailScreen({super.key, required this.locationId});

  final String locationId;

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Location location,
  ) async {
    final l = context.l10n;
    final ok = await confirmArchive(
      context,
      kind: ArchiveKind.location,
      name: location.name,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(locationRepositoryProvider).archive(location.id);
    messenger.showSnackBar(SnackBar(content: Text(l.archivedSnack)));
    if (context.mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final location = ref.watch(locationProvider(locationId));
    final children = ref.watch(childLocationsProvider(locationId));
    final items = ref.watch(itemsByLocationProvider(locationId));
    final role = ref.watch(activeRoleProvider).value ?? Role.farmer;
    final kind = role.itemKind;
    final loaded = location.value;

    return Scaffold(
      appBar: KernelAppBar(
        title: l.locationAppBar,
        actions: [
          if (loaded != null && !loaded.isArchived)
            IconButton(
              key: const Key('archive-location'),
              tooltip: l.archiveAction,
              icon: const Icon(Icons.inventory_rounded),
              onPressed: () => _archive(context, ref, loaded),
            ),
        ],
      ),
      body: AsyncView<Location?>(
        value: location,
        data: (location) {
          if (location == null) return NotFoundNote(l.locationNotFound);
          return PageList(
            children: [
              ScreenHeader(
                title: location.name,
                subtitle: location.type.label(l),
              ),
              if (location.isArchived) QuietNote(l.archivedLocationNotice),
              ActionWrap(
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        context.push(Routes.newItem(locationId: location.id)),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.registerHere(kind)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push(Routes.newLocation(parentId: location.id)),
                    icon: const Icon(Icons.add_home_work_rounded),
                    label: Text(l.addInside),
                  ),
                  if (role == Role.storageFpo)
                    OutlinedButton.icon(
                      key: const Key('batch-here'),
                      onPressed: () => context.push(
                        Routes.batchRun(locationId: location.id),
                      ),
                      icon: const Icon(Icons.playlist_play_rounded),
                      label: Text(l.batchHere),
                    ),
                ],
              ),
              SectionTitle(l.insideTitle),
              AsyncView<List<Location>>(
                value: children,
                data: (children) => children.isEmpty
                    ? QuietNote(l.insideEmpty)
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
              SectionTitle(l.itemsHereTitle(kind)),
              AsyncView<List<GrainItem>>(
                value: items,
                data: (items) => items.isEmpty
                    ? QuietNote(l.itemsHereEmpty(kind))
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
              SackLabelsPanel(
                scope: ReportScope(
                  role: role,
                  kind: ReportKind.sackLabels,
                  locationId: location.id,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
