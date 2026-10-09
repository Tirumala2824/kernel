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

/// F08 batch scan, step 1: choose the room or stack to walk. Sacks are then
/// scanned sequentially, one sack per recording.
class BatchSetupScreen extends ConsumerWidget {
  const BatchSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locations = ref.watch(allLocationsProvider);
    return Scaffold(
      appBar: KernelAppBar(title: l.batchScanTitle),
      body: AsyncView<List<Location>>(
        value: locations,
        data: (all) {
          // Rooms and stacks first; warehouses are offered too because the
          // queue includes nested places.
          final order = {
            LocationType.stack: 0,
            LocationType.room: 1,
            LocationType.warehouse: 2,
          };
          final places =
              all.where((x) => order.containsKey(x.type)).toList()..sort(
                (a, b) => order[a.type]!.compareTo(order[b.type]!) != 0
                    ? order[a.type]!.compareTo(order[b.type]!)
                    : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
          return PageList(
            children: [
              ScreenHeader(
                title: l.batchSetupTitle,
                subtitle: l.batchSetupSubtitle,
              ),
              QuietNote(l.batchSequentialNote, icon: Icons.touch_app_rounded),
              if (places.isEmpty)
                EmptyState(
                  key: const Key('batch-no-places'),
                  illustration: KernelIllustrations.queue,
                  message: l.batchNoPlaces,
                  detail: l.batchNoPlacesDetail,
                  actionLabel: l.addLocation,
                  onAction: () => context.push(Routes.newLocation()),
                )
              else
                for (final place in places) _PlaceTile(location: place),
            ],
          );
        },
      ),
    );
  }
}

class _PlaceTile extends ConsumerWidget {
  const _PlaceTile({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final queue = ref
        .watch(
          inspectionQueueProvider((
            role: Role.storageFpo,
            locationId: location.id,
            lotId: null,
          )),
        )
        .value;
    final total = queue == null
        ? null
        : queue.ranked.length + queue.needsScan.length;
    return LocationTile(
      key: Key('batch-place-${location.id}'),
      location: location,
      subtitle: total == null
          ? location.type.label(l)
          : l.batchPlaceSubtitle(
              location.type.label(l),
              total,
              queue!.needsScan.length,
            ),
      onTap: () => context.push(Routes.batchRun(locationId: location.id)),
    );
  }
}
