import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  group('LocationRepository', () {
    test('creates a hierarchy and watches children', () async {
      final top = h.ops.locations.watchChildren(null);
      expect(await top.first, isEmpty);

      final warehouse = await h.ops.locations.create(
        const LocationDraft(type: LocationType.warehouse, name: 'Godown 1'),
      );
      expect(warehouse.id, isUuid);
      expect(warehouse.syncState, SyncState.localOnly);
      expect(warehouse.parentId, isNull);

      final room = await h.ops.locations.create(
        LocationDraft(
          type: LocationType.room,
          name: 'Room B',
          parentId: warehouse.id,
        ),
      );
      final stack = await h.ops.locations.create(
        LocationDraft(
          type: LocationType.stack,
          name: 'Stack 3',
          parentId: room.id,
        ),
      );

      final topLevel = await firstWhere(top, (l) => l.isNotEmpty);
      expect(topLevel.map((l) => l.id), [warehouse.id]);
      expect(
        (await h.ops.locations.watchChildren(warehouse.id).first).map(
          (l) => l.id,
        ),
        [room.id],
      );
      expect((await h.ops.locations.get(stack.id))?.parentId, room.id);
      expect(await h.ops.locations.get('missing'), isNull);
    });

    test('rejects an unknown parent and a blank name', () async {
      expect(
        () => h.ops.locations.create(
          const LocationDraft(
            type: LocationType.room,
            name: 'Orphan',
            parentId: 'nope',
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => h.ops.locations.create(
          const LocationDraft(type: LocationType.home, name: ' '),
        ),
        throwsArgumentError,
      );
    });
  });

  group('LotRepository', () {
    LotDraft draft(String code, DateTime receivedAt) => LotDraft(
      code: code,
      grainType: 'Maize',
      declaredQuantity: 2000,
      quantityUnit: 'kg',
      receivedAt: receivedAt,
      supplierName: 'Supplier ${code.toLowerCase()}',
    );

    test('creates lots pending screening and lists newest first', () async {
      final older = await h.ops.lots.create(
        draft('L-A', DateTime.utc(2026, 9, 1)),
      );
      final newer = await h.ops.lots.create(
        draft('L-B', DateTime.utc(2026, 9, 5)),
      );
      expect(older.id, isUuid);
      expect(older.screeningStatus, ScreeningStatus.pending);
      expect(older.supplierName, 'Supplier l-a');
      expect(older.supplierId, isNull);
      expect(older.syncState, SyncState.localOnly);

      final all = await h.ops.lots.watchAll().first;
      expect(all.map((l) => l.id), [newer.id, older.id]);
      expect((await h.ops.lots.get(older.id))?.code, 'L-A');
    });

    test('updateScreeningStatus is persisted and streamed', () async {
      final lot = await h.ops.lots.create(
        draft('L-C', DateTime.utc(2026, 9, 1)),
      );
      final stream = h.ops.lots.watchAll();
      expect(
        (await stream.first).single.screeningStatus,
        ScreeningStatus.pending,
      );

      h.clock.advance(const Duration(minutes: 5));
      final updated = await h.ops.lots.updateScreeningStatus(
        lot.id,
        ScreeningStatus.needsPhysicalCheck,
      );
      expect(updated.screeningStatus, ScreeningStatus.needsPhysicalCheck);
      expect(updated.updatedAt, h.clock.now);
      expect(updated.createdAt, lot.createdAt);

      final emitted = await firstWhere(
        stream,
        (lots) =>
            lots.single.screeningStatus == ScreeningStatus.needsPhysicalCheck,
      );
      expect(emitted.single.id, lot.id);
      expect(
        () => h.ops.lots.updateScreeningStatus(
          'missing',
          ScreeningStatus.reviewed,
        ),
        throwsArgumentError,
      );
    });
  });
}
