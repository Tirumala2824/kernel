// Test-only in-memory items, locations, lots and harvests.

import 'package:kernel_contracts/kernel_contracts.dart';

import 'changes.dart';

GrainItem _copyItem(GrainItem i, {DateTime? archivedAt, bool clear = false}) =>
    GrainItem(
      id: i.id,
      ownerRole: i.ownerRole,
      label: i.label,
      grainType: i.grainType,
      quantity: i.quantity,
      quantityUnit: i.quantityUnit,
      storageDate: i.storageDate,
      locationId: i.locationId,
      lotId: i.lotId,
      harvestId: i.harvestId,
      archivedAt: clear ? null : (archivedAt ?? i.archivedAt),
      createdAt: i.createdAt,
      updatedAt: DateTime.now().toUtc(),
      syncState: i.syncState,
    );

class InMemoryItemRepository implements ItemRepository {
  final items = <GrainItem>[];
  final _changes = Changes();
  Stream<void> get changes => _changes.stream;

  Iterable<GrainItem> get _live => items.where((i) => !i.isArchived);

  @override
  Future<GrainItem> create(GrainItemDraft draft) async {
    final now = DateTime.now().toUtc();
    final item = GrainItem(
      id: testId('item'),
      ownerRole: draft.ownerRole,
      label: draft.label,
      grainType: draft.grainType,
      quantity: draft.quantity,
      quantityUnit: draft.quantityUnit,
      storageDate: draft.storageDate,
      locationId: draft.locationId,
      lotId: draft.lotId,
      harvestId: draft.harvestId,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    items.add(item);
    _changes.notify();
    return item;
  }

  @override
  Future<GrainItem> update(GrainItem item) async {
    final index = items.indexWhere((i) => i.id == item.id);
    items[index] = item;
    _changes.notify();
    return item;
  }

  @override
  Future<GrainItem?> get(String id) async =>
      items.where((i) => i.id == id).firstOrNull;

  @override
  Stream<List<GrainItem>> watchByRole(Role role) =>
      _changes.watch(() => _live.where((i) => i.ownerRole == role).toList());

  @override
  Stream<List<GrainItem>> watchByLocation(String locationId) => _changes.watch(
    () => _live.where((i) => i.locationId == locationId).toList(),
  );

  @override
  Stream<List<GrainItem>> watchByLot(String lotId) =>
      _changes.watch(() => _live.where((i) => i.lotId == lotId).toList());

  @override
  Stream<List<GrainItem>> watchByHarvest(String harvestId) => _changes.watch(
    () => _live.where((i) => i.harvestId == harvestId).toList(),
  );

  @override
  Future<void> archive(String id) async {
    final index = items.indexWhere((i) => i.id == id);
    items[index] = _copyItem(items[index], archivedAt: DateTime.now().toUtc());
    _changes.notify();
  }

  @override
  Future<void> unarchive(String id) async {
    final index = items.indexWhere((i) => i.id == id);
    items[index] = _copyItem(items[index], clear: true);
    _changes.notify();
  }
}

class InMemoryLocationRepository implements LocationRepository {
  final locations = <Location>[];
  final _changes = Changes();

  Iterable<Location> get _live => locations.where((x) => !x.isArchived);

  @override
  Future<Location> create(LocationDraft draft) async {
    final now = DateTime.now().toUtc();
    final location = Location(
      id: testId('loc'),
      type: draft.type,
      name: draft.name,
      parentId: draft.parentId,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    locations.add(location);
    _changes.notify();
    return location;
  }

  @override
  Future<Location?> get(String id) async =>
      locations.where((x) => x.id == id).firstOrNull;

  @override
  Stream<List<Location>> watchChildren(String? parentId) =>
      _changes.watch(() => _live.where((x) => x.parentId == parentId).toList());

  @override
  Stream<List<Location>> watchAll() => _changes.watch(() => _live.toList());

  @override
  Future<void> archive(String id) async {
    final index = locations.indexWhere((x) => x.id == id);
    final old = locations[index];
    locations[index] = Location(
      id: old.id,
      type: old.type,
      name: old.name,
      parentId: old.parentId,
      archivedAt: DateTime.now().toUtc(),
      createdAt: old.createdAt,
      updatedAt: DateTime.now().toUtc(),
      syncState: old.syncState,
    );
    _changes.notify();
  }
}

class InMemoryLotRepository implements LotRepository {
  final lots = <Lot>[];
  final _changes = Changes();

  Lot _copy(Lot old, {ScreeningStatus? status, DateTime? archivedAt}) => Lot(
    id: old.id,
    code: old.code,
    supplierId: old.supplierId,
    supplierName: old.supplierName,
    grainType: old.grainType,
    declaredQuantity: old.declaredQuantity,
    quantityUnit: old.quantityUnit,
    receivedAt: old.receivedAt,
    screeningStatus: status ?? old.screeningStatus,
    archivedAt: archivedAt ?? old.archivedAt,
    createdAt: old.createdAt,
    updatedAt: DateTime.now().toUtc(),
    syncState: old.syncState,
  );

  @override
  Future<Lot> create(LotDraft draft) async {
    final now = DateTime.now().toUtc();
    final lot = Lot(
      id: testId('lot'),
      code: draft.code,
      supplierId: draft.supplierId,
      supplierName: draft.supplierName,
      grainType: draft.grainType,
      declaredQuantity: draft.declaredQuantity,
      quantityUnit: draft.quantityUnit,
      receivedAt: draft.receivedAt,
      screeningStatus: ScreeningStatus.pending,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    lots.add(lot);
    _changes.notify();
    return lot;
  }

  @override
  Future<Lot?> get(String id) async =>
      lots.where((x) => x.id == id).firstOrNull;

  @override
  Stream<List<Lot>> watchAll() =>
      _changes.watch(() => lots.where((x) => !x.isArchived).toList());

  @override
  Future<Lot> updateScreeningStatus(String id, ScreeningStatus status) async {
    final index = lots.indexWhere((x) => x.id == id);
    lots[index] = _copy(lots[index], status: status);
    _changes.notify();
    return lots[index];
  }

  @override
  Future<void> archive(String id) async {
    final index = lots.indexWhere((x) => x.id == id);
    lots[index] = _copy(lots[index], archivedAt: DateTime.now().toUtc());
    _changes.notify();
  }
}

class InMemoryHarvestRepository implements HarvestRepository {
  final harvests = <Harvest>[];
  final _changes = Changes();

  @override
  Future<Harvest> create(HarvestDraft draft) async {
    final now = DateTime.now().toUtc();
    final harvest = Harvest(
      id: testId('harvest'),
      name: draft.name,
      grainType: draft.grainType,
      harvestedAt: draft.harvestedAt,
      notes: draft.notes,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    harvests.add(harvest);
    _changes.notify();
    return harvest;
  }

  @override
  Future<Harvest?> get(String id) async =>
      harvests.where((h) => h.id == id).firstOrNull;

  @override
  Stream<List<Harvest>> watchAll() =>
      _changes.watch(() => harvests.where((h) => h.archivedAt == null).toList());

  @override
  Future<void> archive(String id) async {
    final index = harvests.indexWhere((h) => h.id == id);
    final old = harvests[index];
    harvests[index] = Harvest(
      id: old.id,
      name: old.name,
      grainType: old.grainType,
      harvestedAt: old.harvestedAt,
      notes: old.notes,
      archivedAt: DateTime.now().toUtc(),
      createdAt: old.createdAt,
      updatedAt: DateTime.now().toUtc(),
      syncState: old.syncState,
    );
    _changes.notify();
  }
}
