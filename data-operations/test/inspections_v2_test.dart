import 'dart:io';

import 'package:data_operations/src/db/database.dart';
import 'package:data_operations/src/repositories/inspection_repository.dart';
import 'package:data_operations/src/repositories/item_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  test('assign sets, replaces and clears the assignee without touching the '
      'verified finding', () async {
    final item = await h.addItem();
    final inspection = await h.addInspection(
      item.id,
      VerifiedFinding.pestsFound,
      assignedTo: '  ',
    );
    expect(inspection.assignedTo, isNull);

    h.clock.advance(const Duration(minutes: 1));
    final assigned = await h.ops.inspections.assign(inspection.id, ' Asha ');
    expect(assigned.assignedTo, 'Asha');
    expect(assigned.updatedAt, h.clock.now);
    expect(assigned.verifiedFinding, VerifiedFinding.pestsFound);
    expect(assigned.followUpStatus, FollowUpStatus.open);
    expect(assigned.inspector, inspection.inspector);
    expect(assigned.createdAt, inspection.createdAt);

    final moved = await h.ops.inspections.assign(inspection.id, 'Vikram');
    expect(moved.assignedTo, 'Vikram');
    final progressed = await h.ops.inspections.updateFollowUp(
      inspection.id,
      FollowUpStatus.inProgress,
    );
    expect(progressed.assignedTo, 'Vikram', reason: 'follow-up keeps it');
    expect(
      (await h.ops.inspections.assign(inspection.id, null)).assignedTo,
      isNull,
    );
    expect(
      (await h.ops.inspections.assign(inspection.id, '')).assignedTo,
      isNull,
    );

    final stored = (await h.ops.inspections.watchForItem(item.id).first).single;
    expect(stored.verifiedFinding, VerifiedFinding.pestsFound);
    expect(stored.followUpStatus, FollowUpStatus.inProgress);

    await expectLater(
      h.ops.inspections.assign('nope', 'Asha'),
      throwsArgumentError,
    );
  });

  test('assignedTo and photoPaths are stored from the draft; photo paths '
      'must be absolute', () async {
    final item = await h.addItem();
    final dir = await Directory.systemTemp.createTemp('kernel_photos_');
    addTearDown(() => dir.delete(recursive: true));
    final photo = p.join(dir.path, 'evidence-1.jpg');
    final inspection = await h.addInspection(
      item.id,
      VerifiedFinding.noneFound,
      assignedTo: 'Asha',
      photoPaths: [photo],
    );
    expect(inspection.assignedTo, 'Asha');
    expect(inspection.photoPaths, [photo]);
    expect(
      (await h.ops.inspections.watchForItem(item.id).first).single.photoPaths,
      [photo],
    );

    await expectLater(
      h.addInspection(
        item.id,
        VerifiedFinding.noneFound,
        photoPaths: const ['relative/photo.jpg'],
      ),
      throwsArgumentError,
    );
    await expectLater(
      h.addInspection(
        item.id,
        VerifiedFinding.noneFound,
        photoPaths: const [' '],
      ),
      throwsArgumentError,
    );
  });

  test('watchForItem is newest first; watchOpen is open and in progress, '
      'oldest first', () async {
    final item = await h.addItem();
    final t0 = DateTime.utc(2026, 10, 1, 9);
    final first = await h.addInspection(
      item.id,
      VerifiedFinding.inconclusive,
      inspectedAt: t0,
    );
    final second = await h.addInspection(
      item.id,
      VerifiedFinding.pestsFound,
      inspectedAt: t0.add(const Duration(hours: 1)),
      followUpStatus: FollowUpStatus.inProgress,
    );
    final third = await h.addInspection(
      item.id,
      VerifiedFinding.noneFound,
      inspectedAt: t0.add(const Duration(hours: 2)),
      followUpStatus: FollowUpStatus.done,
    );
    expect(
      (await h.ops.inspections.watchForItem(item.id).first).map((i) => i.id),
      [third.id, second.id, first.id],
    );
    expect((await h.ops.inspections.watchOpen().first).map((i) => i.id), [
      first.id,
      second.id,
    ]);
  });

  test(
    'the database keeps assigned_to writable and photo_paths immutable',
    () async {
      final db = KernelDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final clock = TestClock(DateTime.utc(2026, 10, 1));
      final item = await DriftItemRepository(db, clock.call).create(
        GrainItemDraft(
          ownerRole: Role.storageFpo,
          label: 'Stack 3',
          grainType: 'Rice',
          quantity: 1,
          quantityUnit: 't',
          storageDate: DateTime.utc(2026, 9, 1),
        ),
      );
      final inspection = await DriftInspectionRepository(db, clock.call).create(
        InspectionDraft(
          itemId: item.id,
          inspectedAt: DateTime.utc(2026, 10, 1),
          inspector: 'Ravi',
          observations: 'Webbing on surface',
          verifiedFinding: VerifiedFinding.pestsFound,
        ),
      );
      await db.customStatement(
        "UPDATE inspections SET assigned_to = 'Asha' WHERE id = ?",
        [inspection.id],
      );
      await expectLater(
        db.customStatement(
          "UPDATE inspections SET photo_paths = '[]' WHERE id = ?",
          [inspection.id],
        ),
        throwsA(isA<SqliteException>()),
      );
    },
  );
}
