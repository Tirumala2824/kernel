import 'package:data_operations/src/db/database.dart';
import 'package:data_operations/src/repositories/inspection_repository.dart';
import 'package:data_operations/src/repositories/item_repository.dart';
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

  InspectionDraft draft({
    String? itemId,
    String? scanId,
    VerifiedFinding finding = VerifiedFinding.pestsFound,
    FollowUpStatus status = FollowUpStatus.open,
    DateTime? inspectedAt,
  }) => InspectionDraft(
    itemId: itemId ?? item.id,
    scanId: scanId,
    inspectedAt: inspectedAt ?? DateTime.utc(2026, 10, 1, 9),
    inspector: 'Inspector A',
    observations: 'Live weevils near the bottom seam',
    verifiedFinding: finding,
    followUpStatus: status,
  );

  test('creates a tracked inspection linked to a scan', () async {
    final scan = await h.recordScan(item.id);
    final inspection = await h.ops.inspections.create(draft(scanId: scan.id));
    expect(inspection.id, isUuid);
    expect(inspection.scanId, scan.id);
    expect(inspection.itemId, item.id);
    expect(inspection.verifiedFinding, VerifiedFinding.pestsFound);
    expect(inspection.followUpStatus, FollowUpStatus.open);
    expect(inspection.inspector, 'Inspector A');
    expect(inspection.syncState, SyncState.localOnly);

    final forItem = await h.ops.inspections.watchForItem(item.id).first;
    expect(forItem.single.id, inspection.id);
  });

  test(
    'a verified finding never changes the scan prediction, or vice versa',
    () async {
      final scan = await h.recordScan(item.id); // no model: notEvaluated
      await h.ops.inspections.create(draft(scanId: scan.id));

      final storedScan = (await h.ops.scans.watchForItem(item.id).first).single;
      expect(storedScan.result, Classification.notEvaluated);
      expect(storedScan.isValid, isFalse);
      expect(await h.ops.scans.latestValidForItem(item.id), isNull);

      // A human finding does not make the item "evaluated" for ranking.
      final queue = await h.ops.ranking.watchQueue().first;
      expect(queue.ranked, isEmpty);
      expect(queue.needsScan.map((i) => i.id), [item.id]);
    },
  );

  test(
    'rejects unknown items, unknown scans and scans of another item',
    () async {
      final other = await h.addItem(label: 'Other');
      final otherScan = await h.recordScan(other.id);
      expect(
        () => h.ops.inspections.create(draft(itemId: 'nope')),
        throwsArgumentError,
      );
      expect(
        () => h.ops.inspections.create(draft(scanId: 'nope')),
        throwsArgumentError,
      );
      expect(
        () => h.ops.inspections.create(draft(scanId: otherScan.id)),
        throwsArgumentError,
      );
    },
  );

  test('watchOpen tracks follow-up status; the finding is preserved', () async {
    final open = h.ops.inspections.watchOpen();
    expect(await open.first, isEmpty);

    final first = await h.ops.inspections.create(
      draft(inspectedAt: DateTime.utc(2026, 10, 1, 9)),
    );
    final second = await h.ops.inspections.create(
      draft(
        finding: VerifiedFinding.noneFound,
        inspectedAt: DateTime.utc(2026, 10, 1, 10),
      ),
    );
    await h.ops.inspections.create(
      draft(finding: VerifiedFinding.inconclusive, status: FollowUpStatus.done),
    );
    expect((await firstWhere(open, (l) => l.length == 2)).map((i) => i.id), [
      first.id,
      second.id,
    ]);

    h.clock.advance(const Duration(hours: 2));
    final progressed = await h.ops.inspections.updateFollowUp(
      first.id,
      FollowUpStatus.inProgress,
    );
    expect(progressed.followUpStatus, FollowUpStatus.inProgress);
    expect(progressed.verifiedFinding, VerifiedFinding.pestsFound);
    expect(progressed.updatedAt, h.clock.now);

    await h.ops.inspections.updateFollowUp(first.id, FollowUpStatus.done);
    final remaining = await firstWhere(open, (l) => l.length == 1);
    expect(remaining.single.id, second.id);

    final all = await h.ops.inspections.watchForItem(item.id).first;
    final done = all.firstWhere((i) => i.id == first.id);
    expect(done.verifiedFinding, VerifiedFinding.pestsFound);
    expect(done.observations, 'Live weevils near the bottom seam');

    expect(
      () => h.ops.inspections.updateFollowUp('missing', FollowUpStatus.done),
      throwsArgumentError,
    );
  });

  test('the database refuses to overwrite a verified finding', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final clock = TestClock(DateTime.utc(2026, 10, 1));
    final stored = await DriftItemRepository(db, clock.call).create(
      GrainItemDraft(
        ownerRole: Role.buyer,
        label: 'Sample bag',
        grainType: 'Wheat',
        quantity: 1,
        quantityUnit: 'kg',
        storageDate: DateTime.utc(2026, 9, 1),
      ),
    );
    final inspections = DriftInspectionRepository(db, clock.call);
    final inspection = await inspections.create(draft(itemId: stored.id));

    await expectLater(
      db.customStatement(
        "UPDATE inspections SET verified_finding = 'noneFound' WHERE id = ?",
        [inspection.id],
      ),
      throwsA(isA<SqliteException>()),
    );
    final reread = await inspections.watchForItem(stored.id).first;
    expect(reread.single.verifiedFinding, VerifiedFinding.pestsFound);
  });
}
