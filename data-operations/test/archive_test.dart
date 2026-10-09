import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/csv.dart';
import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  Future<Lot> addLot([String code = 'LOT-1']) => h.ops.lots.create(
    LotDraft(
      code: code,
      grainType: 'Wheat',
      declaredQuantity: 100,
      quantityUnit: 'kg',
      receivedAt: DateTime.utc(2026, 9, 20),
    ),
  );

  test('an archived item leaves every list, queue and new report but get() '
      'and its history remain', () async {
    final location = await h.ops.locations.create(
      const LocationDraft(type: LocationType.warehouse, name: 'Godown'),
    );
    final lot = await addLot();
    final harvest = await h.addHarvest();
    final kept = await h.addItem(label: 'Sack A');
    final gone = await h.addItem(
      label: 'Sack B',
      locationId: location.id,
      lotId: lot.id,
      harvestId: harvest.id,
    );
    final scan = await h.recordModelScan(gone.id, Classification.infested);
    await h.recordModelScan(kept.id, Classification.clean);
    final inspection = await h.addInspection(
      gone.id,
      VerifiedFinding.pestsFound,
      scanId: scan.id,
    );

    final byRole = h.ops.items.watchByRole(Role.farmer);
    expect((await byRole.first).map((i) => i.id), [kept.id, gone.id]);

    h.clock.advance(const Duration(minutes: 5));
    await h.ops.items.archive(gone.id);

    expect((await firstWhere(byRole, (l) => l.length == 1)).single.id, kept.id);
    expect(await h.ops.items.watchByLocation(location.id).first, isEmpty);
    expect(await h.ops.items.watchByLot(lot.id).first, isEmpty);
    expect(await h.ops.items.watchByHarvest(harvest.id).first, isEmpty);

    final archived = (await h.ops.items.get(gone.id))!;
    expect(archived.isArchived, isTrue);
    expect(archived.archivedAt, h.clock.now);
    expect(archived.updatedAt, h.clock.now);

    // History is kept and still reachable per item.
    expect((await h.ops.scans.watchForItem(gone.id).first).single.id, scan.id);
    expect((await h.ops.scans.get(scan.id))?.id, scan.id);
    expect(
      (await h.ops.inspections.watchForItem(gone.id).first).single.id,
      inspection.id,
    );
    // ...but it is hidden from cross-item lists and queues.
    expect((await h.ops.scans.watchRecent().first).map((s) => s.itemId), [
      kept.id,
    ]);
    expect(
      (await h.ops.scans.watchSince(DateTime.utc(2026)).first).map(
        (s) => s.itemId,
      ),
      [kept.id],
    );
    expect(await h.ops.inspections.watchOpen().first, isEmpty);
    final queue = await h.ops.ranking.watchQueue().first;
    expect(queue.ranked.map((e) => e.item.id), [kept.id]);
    expect(queue.needsScan, isEmpty);

    final csv = await readCsv(
      await h.ops.reports.export(
        const ReportScope(role: Role.farmer),
        ReportFormat.csv,
      ),
    );
    expect(csv.rows.map((r) => r['item_id']).toSet(), {kept.id});

    // Archiving twice keeps the first timestamp.
    final firstArchivedAt = archived.archivedAt;
    h.clock.advance(const Duration(hours: 1));
    await h.ops.items.archive(gone.id);
    expect((await h.ops.items.get(gone.id))!.archivedAt, firstArchivedAt);

    await h.ops.items.unarchive(gone.id);
    expect((await h.ops.items.get(gone.id))!.isArchived, isFalse);
    expect((await firstWhere(byRole, (l) => l.length == 2)).map((i) => i.id), [
      kept.id,
      gone.id,
    ]);
    expect(await h.ops.inspections.watchOpen().first, hasLength(1));
    expect(
      (await h.ops.ranking.watchQueue().first).ranked.first.item.id,
      gone.id,
    );
  });

  test('archive, unarchive and update keep the archive state apart', () async {
    final item = await h.addItem();
    await h.ops.items.archive(item.id);
    final archived = (await h.ops.items.get(item.id))!;
    // update() edits fields only; it never un-archives.
    final edited = await h.ops.items.update(
      GrainItem(
        id: archived.id,
        ownerRole: archived.ownerRole,
        label: 'Renamed',
        grainType: archived.grainType,
        quantity: archived.quantity,
        quantityUnit: archived.quantityUnit,
        storageDate: archived.storageDate,
        locationId: null,
        lotId: null,
        createdAt: archived.createdAt,
        updatedAt: archived.updatedAt,
        syncState: archived.syncState,
      ),
    );
    expect(edited.label, 'Renamed');
    expect(edited.isArchived, isTrue);

    await h.ops.items.unarchive(item.id);
    await h.ops.items.unarchive(item.id); // harmless when not archived
    expect((await h.ops.items.get(item.id))!.isArchived, isFalse);

    await expectLater(h.ops.items.archive('nope'), throwsArgumentError);
    await expectLater(h.ops.items.unarchive('nope'), throwsArgumentError);
  });

  test('archiving an item silences its reminders until unarchived', () async {
    final item = await h.addItem();
    final soon = await h.ops.reminders.schedule(
      item.id,
      h.clock.now.add(const Duration(hours: 1)),
    );
    final later = await h.ops.reminders.schedule(
      item.id,
      h.clock.now.add(const Duration(days: 3)),
    );
    final ids = {
      for (final n in h.scheduler.scheduled) n.reminderId: n.notificationId,
    };
    expect(h.scheduler.pending, hasLength(2));
    final upcoming = h.ops.reminders.watchUpcoming();
    expect(await upcoming.first, hasLength(2));

    await h.ops.items.archive(item.id);
    expect(h.scheduler.pending, isEmpty);
    expect(h.scheduler.cancelled, containsAll([ids[soon.id], ids[later.id]]));
    expect(await firstWhere(upcoming, (l) => l.isEmpty), isEmpty);
    // The reminders themselves are kept, unchanged.
    expect(
      (await h.ops.reminders.watchForItem(item.id).first).map((r) => r.status),
      [ReminderStatus.scheduled, ReminderStatus.scheduled],
    );
    // An app restart does not bring them back while archived.
    await h.ops.restoreReminders();
    expect(h.scheduler.pending, isEmpty);
    await expectLater(
      h.ops.reminders.schedule(
        item.id,
        h.clock.now.add(const Duration(days: 1)),
      ),
      throwsArgumentError,
    );

    // The first one falls due while archived.
    h.clock.advance(const Duration(hours: 2));
    await h.ops.items.unarchive(item.id);
    expect(h.scheduler.pending.keys, [ids[later.id]]);
    final restored = await h.ops.reminders.watchForItem(item.id).first;
    expect(
      {for (final r in restored) r.id: r.status},
      {soon.id: ReminderStatus.fired, later.id: ReminderStatus.scheduled},
    );
    expect(await upcoming.first, hasLength(2));
  });

  test('locations: archive hides them from watchChildren and watchAll and '
      'blocks new placements', () async {
    final home = await h.ops.locations.create(
      const LocationDraft(type: LocationType.home, name: 'Home'),
    );
    final store = await h.ops.locations.create(
      const LocationDraft(type: LocationType.warehouse, name: 'Store'),
    );
    final room = await h.ops.locations.create(
      LocationDraft(type: LocationType.room, name: 'Room', parentId: store.id),
    );
    final item = await h.addItem(locationId: store.id);
    final all = h.ops.locations.watchAll();
    expect((await all.first).map((l) => l.name), ['Home', 'Room', 'Store']);

    await h.ops.locations.archive(store.id);
    expect((await firstWhere(all, (l) => l.length == 2)).map((l) => l.name), [
      'Home',
      'Room',
    ]);
    expect((await h.ops.locations.watchChildren(null).first).map((l) => l.id), [
      home.id,
    ]);
    // Archiving is not recursive.
    expect(
      (await h.ops.locations.watchChildren(store.id).first).single.id,
      room.id,
    );
    expect((await h.ops.locations.get(store.id))!.isArchived, isTrue);
    // Existing placements stay; new ones are refused.
    expect((await h.ops.items.get(item.id))!.locationId, store.id);
    await expectLater(h.addItem(locationId: store.id), throwsArgumentError);
    await expectLater(
      h.ops.locations.create(
        LocationDraft(type: LocationType.room, name: 'X', parentId: store.id),
      ),
      throwsArgumentError,
    );
    // An unchanged archived reference does not block other edits.
    final stored = (await h.ops.items.get(item.id))!;
    final renamed = await h.ops.items.update(
      GrainItem(
        id: stored.id,
        ownerRole: stored.ownerRole,
        label: 'Kept here',
        grainType: stored.grainType,
        quantity: stored.quantity,
        quantityUnit: stored.quantityUnit,
        storageDate: stored.storageDate,
        locationId: stored.locationId,
        lotId: stored.lotId,
        createdAt: stored.createdAt,
        updatedAt: stored.updatedAt,
        syncState: stored.syncState,
      ),
    );
    expect(renamed.label, 'Kept here');
    await expectLater(h.ops.locations.archive('nope'), throwsArgumentError);
  });

  test(
    'lots: archive hides them from watchAll, get() still returns them',
    () async {
      final keep = await addLot('LOT-1');
      final old = await addLot('LOT-2');
      final item = await h.addItem(role: Role.buyer, lotId: old.id);
      final lots = h.ops.lots.watchAll();
      expect(await lots.first, hasLength(2));

      await h.ops.lots.archive(old.id);
      expect((await firstWhere(lots, (l) => l.length == 1)).single.id, keep.id);
      expect((await h.ops.lots.get(old.id))!.isArchived, isTrue);
      expect((await h.ops.items.get(item.id))!.lotId, old.id);
      await expectLater(
        h.addItem(role: Role.buyer, lotId: old.id),
        throwsArgumentError,
      );
      await expectLater(h.ops.lots.archive('nope'), throwsArgumentError);
    },
  );
}
