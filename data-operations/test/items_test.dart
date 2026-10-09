import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  test('a fresh database is empty', () async {
    for (final role in Role.values) {
      expect(await h.ops.items.watchByRole(role).first, isEmpty);
    }
    expect(await h.ops.locations.watchChildren(null).first, isEmpty);
    expect(await h.ops.lots.watchAll().first, isEmpty);
    expect(await h.ops.scans.watchRecent().first, isEmpty);
    expect(await h.ops.inspections.watchOpen().first, isEmpty);
    expect(await h.ops.reminders.watchUpcoming().first, isEmpty);
    final queue = await h.ops.ranking.watchQueue().first;
    expect(queue.ranked, isEmpty);
    expect(queue.needsScan, isEmpty);
  });

  test('create stores a tracked item and get returns it', () async {
    final item = await h.addItem(label: '  Sack R-004 ', quantity: 25.5);
    expect(item.id, isUuid);
    expect(item.label, 'Sack R-004');
    expect(item.quantity, 25.5);
    expect(item.ownerRole, Role.farmer);
    expect(item.syncState, SyncState.localOnly);
    expect(item.createdAt, h.clock.now);
    expect(item.updatedAt, h.clock.now);
    expect(item.storageDate, DateTime.utc(2026, 9, 1));

    final loaded = await h.ops.items.get(item.id);
    expect(loaded?.label, 'Sack R-004');
    expect(await h.ops.items.get('missing'), isNull);
  });

  test('watchByRole emits on create and update', () async {
    final stream = h.ops.items.watchByRole(Role.household);
    expect(await stream.first, isEmpty);

    final item = await h.addItem(role: Role.household, label: 'Rice tin');
    final afterCreate = await firstWhere(stream, (list) => list.isNotEmpty);
    expect(afterCreate.single.id, item.id);

    h.clock.advance(const Duration(hours: 1));
    final updated = await h.ops.items.update(
      GrainItem(
        id: item.id,
        ownerRole: item.ownerRole,
        label: 'Rice tin (kitchen)',
        grainType: 'Rice',
        quantity: 5,
        quantityUnit: 'kg',
        storageDate: item.storageDate,
        locationId: null,
        lotId: null,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        syncState: item.syncState,
      ),
    );
    expect(updated.label, 'Rice tin (kitchen)');
    expect(updated.grainType, 'Rice');
    expect(updated.createdAt, item.createdAt);
    expect(updated.updatedAt, h.clock.now);

    final afterUpdate = await firstWhere(
      stream,
      (list) => list.single.label == 'Rice tin (kitchen)',
    );
    expect(afterUpdate.single.quantity, 5);
    expect(await h.ops.items.watchByRole(Role.farmer).first, isEmpty);
  });

  test('watchByLocation and watchByLot filter items', () async {
    final store = await h.ops.locations.create(
      const LocationDraft(type: LocationType.warehouse, name: 'Store A'),
    );
    final lot = await h.ops.lots.create(
      LotDraft(
        code: 'L-1',
        grainType: 'Wheat',
        declaredQuantity: 1000,
        quantityUnit: 'kg',
        receivedAt: DateTime.utc(2026, 9, 20),
      ),
    );
    final inStore = await h.addItem(label: 'A', locationId: store.id);
    final inLot = await h.addItem(label: 'B', lotId: lot.id);
    await h.addItem(label: 'C');

    expect(
      (await h.ops.items.watchByLocation(store.id).first).map((i) => i.id),
      [inStore.id],
    );
    expect((await h.ops.items.watchByLot(lot.id).first).map((i) => i.id), [
      inLot.id,
    ]);
  });

  test(
    'rejects blank labels, negative quantities and unknown references',
    () async {
      expect(() => h.addItem(label: '   '), throwsArgumentError);
      expect(() => h.addItem(quantity: -1), throwsArgumentError);
      expect(() => h.addItem(locationId: 'nope'), throwsArgumentError);
      expect(() => h.addItem(lotId: 'nope'), throwsArgumentError);
    },
  );

  test('update of an unknown item throws', () async {
    final item = await h.addItem();
    final ghost = GrainItem(
      id: 'missing',
      ownerRole: item.ownerRole,
      label: item.label,
      grainType: item.grainType,
      quantity: item.quantity,
      quantityUnit: item.quantityUnit,
      storageDate: item.storageDate,
      locationId: null,
      lotId: null,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      syncState: item.syncState,
    );
    expect(() => h.ops.items.update(ghost), throwsArgumentError);
  });
}
