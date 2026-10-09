import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  test('create trims input, stamps the row and get() returns it', () async {
    final harvest = await h.ops.harvests.create(
      HarvestDraft(
        name: '  Kharif 2026 ',
        grainType: ' Paddy ',
        harvestedAt: DateTime.utc(2026, 10, 2),
        notes: '   ',
      ),
    );
    expect(harvest.id, isUuid);
    expect(harvest.name, 'Kharif 2026');
    expect(harvest.grainType, 'Paddy');
    expect(harvest.notes, isNull);
    expect(harvest.harvestedAt, DateTime.utc(2026, 10, 2));
    expect(harvest.createdAt, h.clock.now);
    expect(harvest.syncState, SyncState.localOnly);
    expect(harvest.archivedAt, isNull);
    expect((await h.ops.harvests.get(harvest.id))?.name, 'Kharif 2026');
    expect(await h.ops.harvests.get('nope'), isNull);

    await expectLater(
      h.ops.harvests.create(
        HarvestDraft(
          name: ' ',
          grainType: 'Wheat',
          harvestedAt: DateTime.utc(2026),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('watchAll lists non-archived harvests, most recent first', () async {
    Future<Harvest> add(String name, int month) => h.ops.harvests.create(
      HarvestDraft(
        name: name,
        grainType: 'Wheat',
        harvestedAt: DateTime.utc(2026, month),
      ),
    );
    final spring = await add('Spring', 4);
    final autumn = await add('Autumn', 10);
    final all = h.ops.harvests.watchAll();
    expect((await all.first).map((x) => x.id), [autumn.id, spring.id]);

    await h.ops.harvests.archive(spring.id);
    expect((await firstWhere(all, (l) => l.length == 1)).single.id, autumn.id);
    final archived = (await h.ops.harvests.get(spring.id))!;
    expect(archived.archivedAt, h.clock.now);
    await expectLater(h.ops.harvests.archive('nope'), throwsArgumentError);
  });

  test('sacks link to a harvest and watchByHarvest follows them', () async {
    final rabi = await h.addHarvest(name: 'Rabi');
    final kharif = await h.addHarvest(name: 'Kharif');
    final a = await h.addItem(label: 'A', harvestId: rabi.id);
    final b = await h.addItem(label: 'B', harvestId: rabi.id);
    final c = await h.addItem(label: 'C');
    expect(a.harvestId, rabi.id);
    expect(c.harvestId, isNull);

    final ofRabi = h.ops.items.watchByHarvest(rabi.id);
    expect((await ofRabi.first).map((i) => i.id), [a.id, b.id]);

    // Moving a sack to another harvest.
    final moved = await h.ops.items.update(
      GrainItem(
        id: b.id,
        ownerRole: b.ownerRole,
        label: b.label,
        grainType: b.grainType,
        quantity: b.quantity,
        quantityUnit: b.quantityUnit,
        storageDate: b.storageDate,
        locationId: b.locationId,
        lotId: b.lotId,
        harvestId: kharif.id,
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
        syncState: b.syncState,
      ),
    );
    expect(moved.harvestId, kharif.id);
    expect((await firstWhere(ofRabi, (l) => l.length == 1)).single.id, a.id);
    expect((await h.ops.items.watchByHarvest(kharif.id).first).single.id, b.id);

    // Archiving a harvest keeps its sacks (they are not archived).
    await h.ops.harvests.archive(rabi.id);
    expect((await h.ops.items.get(a.id))!.isArchived, isFalse);
    expect((await h.ops.items.watchByHarvest(rabi.id).first).single.id, a.id);
    // ...but no new sack can join it.
    await expectLater(h.addItem(harvestId: rabi.id), throwsArgumentError);
    await expectLater(h.addItem(harvestId: 'nope'), throwsArgumentError);
  });
}
