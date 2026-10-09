import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'providers.dart';

// Reactive read models over the repository interfaces. Every number on
// screen is derived from one of these streams; nothing is hard-coded.

final activeRoleProvider = StreamProvider<Role?>(
  (ref) => ref.watch(settingsRepositoryProvider).watchActiveRole(),
  name: 'activeRoleProvider',
);

final retainAudioOptInProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchRetainAudioOptIn(),
  name: 'retainAudioOptInProvider',
);

final itemsByRoleProvider = StreamProvider.autoDispose
    .family<List<GrainItem>, Role>(
      (ref, role) => ref.watch(itemRepositoryProvider).watchByRole(role),
    );

final itemsByLocationProvider = StreamProvider.autoDispose
    .family<List<GrainItem>, String>(
      (ref, locationId) =>
          ref.watch(itemRepositoryProvider).watchByLocation(locationId),
    );

final itemsByLotProvider = StreamProvider.autoDispose
    .family<List<GrainItem>, String>(
      (ref, lotId) => ref.watch(itemRepositoryProvider).watchByLot(lotId),
    );

final itemProvider = FutureProvider.autoDispose.family<GrainItem?, String>(
  (ref, id) => ref.watch(itemRepositoryProvider).get(id),
);

/// Top-level locations when the argument is null.
final childLocationsProvider = StreamProvider.autoDispose
    .family<List<Location>, String?>(
      (ref, parentId) =>
          ref.watch(locationRepositoryProvider).watchChildren(parentId),
    );

final locationProvider = FutureProvider.autoDispose.family<Location?, String>(
  (ref, id) => ref.watch(locationRepositoryProvider).get(id),
);

/// One-shot snapshot of the whole location tree (depth-first), for pickers.
/// The contract has no watchAll(), so this walks watchChildren().first.
final allLocationsProvider = FutureProvider.autoDispose<List<Location>>((
  ref,
) async {
  final repo = ref.watch(locationRepositoryProvider);
  final result = <Location>[];
  Future<void> walk(String? parentId, int depth) async {
    if (depth > 8) return;
    final children = await repo.watchChildren(parentId).first;
    for (final child in children) {
      result.add(child);
      await walk(child.id, depth + 1);
    }
  }

  await walk(null, 0);
  return result;
});

final lotsProvider = StreamProvider.autoDispose<List<Lot>>(
  (ref) => ref.watch(lotRepositoryProvider).watchAll(),
);

/// Reactive single lot, derived from [lotsProvider] so a human-set
/// screening status change shows up immediately.
final lotProvider = Provider.autoDispose.family<AsyncValue<Lot?>, String>(
  (ref, id) => ref
      .watch(lotsProvider)
      .whenData((lots) => lots.where((lot) => lot.id == id).firstOrNull),
);

List<ScanRecord> newestFirst(List<ScanRecord> scans) =>
    [...scans]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

/// Immutable scan history for one item, newest first.
final scansForItemProvider = StreamProvider.autoDispose
    .family<List<ScanRecord>, String>(
      (ref, itemId) => ref
          .watch(scanRepositoryProvider)
          .watchForItem(itemId)
          .map(newestFirst),
    );

final recentScansProvider = StreamProvider.autoDispose
    .family<List<ScanRecord>, int>(
      (ref, limit) => ref
          .watch(scanRepositoryProvider)
          .watchRecent(limit: limit)
          .map(newestFirst),
    );

final inspectionsForItemProvider = StreamProvider.autoDispose
    .family<List<Inspection>, String>((ref, itemId) {
      return ref
          .watch(inspectionRepositoryProvider)
          .watchForItem(itemId)
          .map(
            (list) =>
                [...list]
                  ..sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt)),
          );
    });

final openInspectionsProvider = StreamProvider.autoDispose<List<Inspection>>(
  (ref) => ref.watch(inspectionRepositoryProvider).watchOpen(),
);

final remindersForItemProvider = StreamProvider.autoDispose
    .family<List<Reminder>, String>(
      (ref, itemId) =>
          ref.watch(reminderRepositoryProvider).watchForItem(itemId),
    );

final upcomingRemindersProvider = StreamProvider.autoDispose<List<Reminder>>(
  (ref) => ref.watch(reminderRepositoryProvider).watchUpcoming(),
);

/// Arguments for [inspectionQueueProvider]. Records compare by value.
typedef QueueScope = ({Role? role, String? locationId, String? lotId});

final inspectionQueueProvider = StreamProvider.autoDispose
    .family<InspectionQueue, QueueScope>(
      (ref, scope) => ref
          .watch(rankingServiceProvider)
          .watchQueue(
            role: scope.role,
            locationId: scope.locationId,
            lotId: scope.lotId,
          ),
    );

final engineInfoProvider = FutureProvider.autoDispose<EngineInfo>(
  (ref) => ref.watch(scanEngineProvider).info(),
);
