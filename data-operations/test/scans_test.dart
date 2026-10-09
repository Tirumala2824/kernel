import 'package:data_operations/src/db/database.dart';
import 'package:data_operations/src/repositories/item_repository.dart';
import 'package:data_operations/src/repositories/scan_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late GrainItem item;

  setUp(() async {
    h = await Harness.create();
    item = await h.addItem();
  });
  tearDown(() => h.dispose());

  test('records a no-model NOT_EVALUATED scan as-is', () async {
    final scan = outcome(
      itemId: item.id,
      capturedAt: DateTime.utc(2026, 10, 1, 7),
    );
    final record = await h.ops.scans.record(scan);
    expect(record.id, scan.scanId);
    expect(record.itemId, item.id);
    expect(record.result, Classification.notEvaluated);
    expect(record.modelVersion, noModelVersion);
    expect(record.experimental, isTrue);
    expect(record.confidence, isNull);
    expect(record.quality, ScanQuality.pass);
    expect(record.capturedAt, DateTime.utc(2026, 10, 1, 7));
    expect(record.durationMs, 2000);
    expect(record.sampleRate, 16000);
    expect(record.latencyMs, 120);
    expect(record.deviceModel, 'test-device');
    expect(record.osVersion, 'Android 16 (SDK 36)');
    expect(record.syncState, SyncState.localOnly);
    expect(record.isValid, isFalse);
  });

  test('is append-only: a rescan adds a record and keeps the first', () async {
    final stream = h.ops.scans.watchForItem(item.id);
    expect(await stream.first, isEmpty);

    final first = await h.recordScan(item.id, minutesAgo: 10);
    final second = await h.recordScan(
      item.id,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.highNoise],
    );

    final both = await firstWhere(stream, (list) => list.length == 2);
    expect(both.map((s) => s.id), [second.id, first.id]); // newest first
    expect(both.last.quality, ScanQuality.pass);
    expect(both.first.quality, ScanQuality.retry);
  });

  test('re-recording the same scan id is refused', () async {
    final scan = outcome(itemId: item.id);
    await h.ops.scans.record(scan);
    final changed = outcome(
      itemId: item.id,
      scanId: scan.scanId,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.silence],
    );
    await expectLater(h.ops.scans.record(changed), throwsStateError);
    final stored = await h.ops.scans.watchForItem(item.id).first;
    expect(stored.single.quality, ScanQuality.pass);
  });

  group('invariant rejection', () {
    test(
      'RETRY with a pest class throws ArgumentError and stores nothing',
      () async {
        final bad = outcome(
          itemId: item.id,
          quality: ScanQuality.retry,
          reasons: const [QualityReason.clipping],
          classification: Classification.infested,
          confidence: 0.9,
          modelVersion: 'test-model-1',
        );
        await expectLater(h.ops.scans.record(bad), throwsArgumentError);
        expect(await h.ops.scans.watchRecent().first, isEmpty);
      },
    );

    test('no model with a class throws ArgumentError', () async {
      final bad = outcome(
        itemId: item.id,
        classification: Classification.clean,
        confidence: 0.7,
      );
      await expectLater(h.ops.scans.record(bad), throwsArgumentError);
      expect(await h.ops.scans.watchRecent().first, isEmpty);
    });

    test('other contract violations are refused too', () async {
      final noReason = outcome(itemId: item.id, quality: ScanQuality.retry);
      final confidenceWithoutClass = outcome(itemId: item.id, confidence: 0.5);
      final notExperimental = outcome(itemId: item.id, experimental: false);
      for (final bad in [noReason, confidenceWithoutClass, notExperimental]) {
        await expectLater(h.ops.scans.record(bad), throwsArgumentError);
      }
      expect(await h.ops.scans.watchRecent().first, isEmpty);
    });

    test('RETRY is persisted as notEvaluated with its reasons', () async {
      final record = await h.recordScan(
        item.id,
        quality: ScanQuality.retry,
        reasons: const [QualityReason.silence, QualityReason.tooShort],
      );
      expect(record.result, Classification.notEvaluated);
      final stored = (await h.ops.scans.watchForItem(item.id).first).single;
      expect(stored.qualityReasons, [
        QualityReason.silence,
        QualityReason.tooShort,
      ]);
      expect(stored.result, Classification.notEvaluated);
    });

    test('an unknown item is refused', () async {
      await expectLater(
        h.ops.scans.record(outcome(itemId: 'missing')),
        throwsArgumentError,
      );
    });
  });

  group('latestValidForItem', () {
    test('is null while only NOT_EVALUATED or RETRY scans exist', () async {
      await h.recordScan(item.id, minutesAgo: 5);
      await h.recordScan(
        item.id,
        quality: ScanQuality.retry,
        reasons: const [QualityReason.silence],
      );
      expect(await h.ops.scans.latestValidForItem(item.id), isNull);
    });

    test(
      'returns the newest valid scan and ignores newer invalid ones',
      () async {
        await h.recordModelScan(item.id, Classification.clean, minutesAgo: 30);
        final newestValid = await h.recordModelScan(
          item.id,
          Classification.uncertain,
          minutesAgo: 20,
        );
        await h.recordScan(
          item.id,
          minutesAgo: 1,
          quality: ScanQuality.retry,
          reasons: const [QualityReason.highNoise],
        );
        final latest = await h.ops.scans.latestValidForItem(item.id);
        expect(latest?.id, newestValid.id);
        expect(latest?.isValid, isTrue);
      },
    );
  });

  test(
    'watchRecent spans items, newest first, and honours the limit',
    () async {
      final other = await h.addItem(label: 'Sack R-002');
      final a = await h.recordScan(item.id, minutesAgo: 3);
      final b = await h.recordScan(other.id, minutesAgo: 2);
      final c = await h.recordScan(item.id, minutesAgo: 1);
      expect((await h.ops.scans.watchRecent().first).map((s) => s.id), [
        c.id,
        b.id,
        a.id,
      ]);
      expect((await h.ops.scans.watchRecent(limit: 2).first).map((s) => s.id), [
        c.id,
        b.id,
      ]);
    },
  );

  test('the database itself refuses to modify a recorded scan', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final clock = TestClock(DateTime.utc(2026, 10, 1));
    final items = DriftItemRepository(db, clock.call);
    final scans = DriftScanRepository(db, clock.call);
    final stored = await items.create(
      GrainItemDraft(
        ownerRole: Role.farmer,
        label: 'Sack',
        grainType: 'Wheat',
        quantity: 1,
        quantityUnit: 'kg',
        storageDate: DateTime.utc(2026, 9, 1),
      ),
    );
    final record = await scans.record(outcome(itemId: stored.id));

    await expectLater(
      db.customStatement("UPDATE scans SET result = 'infested' WHERE id = ?", [
        record.id,
      ]),
      throwsA(isA<SqliteException>()),
    );
    // Sync bookkeeping stays writable for the deferred V3 sync.
    await db.customStatement(
      "UPDATE scans SET sync_state = 'pending' WHERE id = ?",
      [record.id],
    );
    final reread = await scans.watchForItem(stored.id).first;
    expect(reread.single.result, Classification.notEvaluated);
    expect(reread.single.syncState, SyncState.pending);
  });
}
