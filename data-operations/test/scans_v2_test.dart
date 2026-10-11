import 'package:data_operations/src/db/database.dart';
import 'package:data_operations/src/repositories/item_repository.dart';
import 'package:data_operations/src/repositories/scan_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  test('watchSince returns scans at or after the instant, newest first, '
      'optionally for one role', () async {
    final farmerSack = await h.addItem(role: Role.farmer, label: 'F');
    final fpoSack = await h.addItem(role: Role.storageFpo, label: 'S');
    final old = await h.recordScan(fpoSack.id, minutesAgo: 120);
    final boundary = await h.recordScan(fpoSack.id, minutesAgo: 60);
    final farmer = await h.recordScan(farmerSack.id, minutesAgo: 30);
    final retry = await h.recordScan(
      fpoSack.id,
      minutesAgo: 10,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.clipping],
    );
    final since = h.clock.now.subtract(const Duration(minutes: 60));

    expect((await h.ops.scans.watchSince(since).first).map((s) => s.id), [
      retry.id,
      farmer.id,
      boundary.id,
    ]);
    expect(
      (await h.ops.scans.watchSince(since, role: Role.storageFpo).first).map(
        (s) => s.id,
      ),
      [retry.id, boundary.id],
    );
    expect(
      await h.ops.scans.watchSince(since, role: Role.buyer).first,
      isEmpty,
    );
    // A non-UTC instant means the same moment.
    expect((await h.ops.scans.watchSince(since.toLocal()).first).length, 3);
    expect(
      (await h.ops.scans.watchSince(DateTime.utc(2000)).first).last.id,
      old.id,
    );

    // The stream follows new recordings.
    final stream = h.ops.scans.watchSince(since, role: Role.storageFpo);
    expect(await stream.first, hasLength(2));
    final next = await h.recordScan(fpoSack.id);
    expect((await firstWhere(stream, (l) => l.length == 3)).first.id, next.id);
  });

  test('get returns a stored scan with audioRetained, or null', () async {
    final item = await h.addItem();
    final kept = await h.recordScan(item.id, audioRetained: true);
    final dropped = await h.recordScan(item.id, minutesAgo: 1);
    expect(kept.audioRetained, isTrue);
    expect(dropped.audioRetained, isFalse);
    expect((await h.ops.scans.get(kept.id))?.audioRetained, isTrue);
    expect((await h.ops.scans.get(dropped.id))?.audioRetained, isFalse);
    expect(await h.ops.scans.get('nope'), isNull);
  });

  test(
    'watchRecent filters role before limit and excludes archived items',
    () async {
      final farmer = await h.addItem(role: Role.farmer, label: 'Farmer');
      final buyer = await h.addItem(role: Role.buyer, label: 'Buyer');
      final archived = await h.addItem(role: Role.farmer, label: 'Archived');
      await h.recordScan(farmer.id, minutesAgo: 20);
      final older = await h.recordScan(farmer.id, minutesAgo: 15);
      final newer = await h.recordScan(farmer.id, minutesAgo: 10);
      await h.recordScan(buyer.id, minutesAgo: 2);
      final newestBuyer = await h.recordScan(buyer.id, minutesAgo: 1);
      await h.recordScan(archived.id);
      await h.ops.items.archive(archived.id);

      final stream = h.ops.scans.watchRecent(limit: 2, role: Role.farmer);
      expect((await stream.first).map((s) => s.id), [newer.id, older.id]);
      expect(
        (await h.ops.scans.watchRecent(limit: 1).first).single.id,
        newestBuyer.id,
      );
      expect(
        await h.ops.scans.watchRecent(role: Role.household).first,
        isEmpty,
      );

      final latest = await h.recordScan(farmer.id);
      expect(
        (await firstWhere(
          stream,
          (scans) => scans.first.id == latest.id,
        )).map((s) => s.id),
        [latest.id, newer.id],
      );
    },
  );

  test('watchForItem and watchRecent stay newest first', () async {
    final item = await h.addItem();
    final a = await h.recordScan(item.id, minutesAgo: 9);
    final b = await h.recordScan(item.id, minutesAgo: 5);
    final c = await h.recordScan(item.id, minutesAgo: 1);
    expect((await h.ops.scans.watchForItem(item.id).first).map((s) => s.id), [
      c.id,
      b.id,
      a.id,
    ]);
    expect((await h.ops.scans.watchRecent().first).map((s) => s.id), [
      c.id,
      b.id,
      a.id,
    ]);
  });

  test('audio_retained is covered by the append-only trigger', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final clock = TestClock(DateTime.utc(2026, 10, 1));
    final item = await DriftItemRepository(db, clock.call).create(
      GrainItemDraft(
        ownerRole: Role.farmer,
        label: 'Sack',
        grainType: 'Wheat',
        quantity: 1,
        quantityUnit: 'kg',
        storageDate: DateTime.utc(2026, 9, 1),
      ),
    );
    final scan = await DriftScanRepository(
      db,
      clock.call,
    ).record(outcome(itemId: item.id, audioRetained: true));
    await expectLater(
      db.customStatement('UPDATE scans SET audio_retained = 0 WHERE id = ?', [
        scan.id,
      ]),
      throwsA(isA<SqliteException>()),
    );
  });
}
