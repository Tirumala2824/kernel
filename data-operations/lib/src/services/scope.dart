import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../repositories/location_repository.dart';

/// Non-archived items matching every given filter. [locationId] includes
/// items in nested locations (a warehouse covers its rooms and stacks). Null
/// filters are ignored. Ordered by label for stable output.
Future<List<ItemRow>> itemsInScope(
  KernelDatabase db, {
  Role? role,
  String? locationId,
  String? lotId,
  String? harvestId,
  List<String>? itemIds,
}) async {
  if (itemIds != null && itemIds.isEmpty) return const [];
  final locationIds = locationId == null
      ? null
      : await locationSubtree(db, locationId);
  final query = db.select(db.items)
    ..where((i) {
      final filters = <Expression<bool>>[
        i.archivedAt.isNull(),
        if (role != null) i.ownerRole.equalsValue(role),
        if (locationIds != null) i.locationId.isIn(locationIds),
        if (lotId != null) i.lotId.equals(lotId),
        if (harvestId != null) i.harvestId.equals(harvestId),
        if (itemIds != null) i.id.isIn(itemIds),
      ];
      return Expression.and(filters);
    })
    ..orderBy([
      (i) => OrderingTerm.asc(i.label),
      (i) => OrderingTerm.asc(i.createdAt),
      (i) => OrderingTerm.asc(i.id),
    ]);
  return query.get();
}
