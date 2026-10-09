import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import 'support/harness.dart';

void main() {
  test('deleteAllHistory also removes inspection photos, labeled samples '
      'and dataset ZIPs, and still deletes retained audio', () async {
    var audioDeletes = 0;
    final h = await Harness.create(
      deleteRetainedAudio: () async => audioDeletes++,
      retainedAudio: const {},
    );
    addTearDown(h.dispose);
    final photos = await Directory.systemTemp.createTemp('kernel_photos_');
    addTearDown(() async {
      if (photos.existsSync()) await photos.delete(recursive: true);
    });
    final photoA = File(p.join(photos.path, 'a.jpg'))..writeAsBytesSync([1]);
    final photoB = File(p.join(photos.path, 'b.jpg'))..writeAsBytesSync([2]);
    final alreadyGone = p.join(photos.path, 'gone.jpg');
    final unrelated = File(p.join(photos.path, 'keep.jpg'))
      ..writeAsBytesSync([3]);
    // A directory listed by mistake is never deleted.
    final folder = Directory(p.join(photos.path, 'folder'))..createSync();

    final harvest = await h.addHarvest();
    final item = await h.addItem(harvestId: harvest.id);
    await h.ops.settings.setResearchModeOptIn(true);
    final scan = await h.recordScan(item.id, audioRetained: true);
    final inspection = await h.addInspection(
      item.id,
      VerifiedFinding.noneFound,
      scanId: scan.id,
      photoPaths: [photoA.path, alreadyGone, folder.path],
    );
    await h.addInspection(
      item.id,
      VerifiedFinding.inconclusive,
      photoPaths: [photoB.path],
    );
    await h.ops.labeledSamples.create(
      LabeledSampleDraft(
        scanId: scan.id,
        label: SampleLabel.clean,
        inspectionId: inspection.id,
        grainType: 'Wheat',
      ),
    );
    final zip = await h.ops.datasetExport.exportZip();
    expect(File(zip).existsSync(), isTrue);
    final samples = h.ops.labeledSamples.watchAll();
    expect(await samples.first, hasLength(1));

    await h.ops.privacy.deleteAllHistory();

    expect(await firstWhere(samples, (l) => l.isEmpty), isEmpty);
    expect(photoA.existsSync(), isFalse);
    expect(photoB.existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue, reason: 'not listed');
    expect(folder.existsSync(), isTrue, reason: 'directories are skipped');
    expect(File(zip).existsSync(), isFalse, reason: 'contains audio copies');
    expect(audioDeletes, 1);
    expect(await h.ops.scans.watchForItem(item.id).first, isEmpty);
    expect(await h.ops.inspections.watchForItem(item.id).first, isEmpty);
    // Not history: harvests, items and settings stay.
    expect(await h.ops.harvests.get(harvest.id), isNotNull);
    expect(await h.ops.items.get(item.id), isNotNull);
    expect(await h.ops.settings.watchResearchModeOptIn().first, isTrue);

    // Running it again, with the files already gone, is harmless.
    await h.ops.privacy.deleteAllHistory();
    expect(audioDeletes, 2);
  });

  test(
    'deleteAllHistory wipes scans, inspections and reminders only',
    () async {
      var audioDeletes = 0;
      final h = await Harness.create(
        deleteRetainedAudio: () async => audioDeletes++,
      );
      addTearDown(h.dispose);

      final location = await h.ops.locations.create(
        const LocationDraft(type: LocationType.home, name: 'Kitchen'),
      );
      final lot = await h.ops.lots.create(
        LotDraft(
          code: 'L-1',
          grainType: 'Rice',
          declaredQuantity: 10,
          quantityUnit: 'kg',
          receivedAt: DateTime.utc(2026, 9, 1),
        ),
      );
      final item = await h.addItem(
        role: Role.household,
        label: 'Rice tin',
        locationId: location.id,
        lotId: lot.id,
      );
      await h.ops.settings.setActiveRole(Role.household);
      await h.ops.settings.setRetainAudioOptIn(true);

      final scan = await h.recordModelScan(item.id, Classification.uncertain);
      await h.recordScan(
        item.id,
        quality: ScanQuality.retry,
        reasons: const [QualityReason.silence],
      );
      await h.ops.inspections.create(
        InspectionDraft(
          itemId: item.id,
          scanId: scan.id,
          inspectedAt: DateTime.utc(2026, 10, 1),
          inspector: 'Me',
          observations: 'Looked fine',
          verifiedFinding: VerifiedFinding.noneFound,
        ),
      );
      final active = await h.ops.reminders.schedule(
        item.id,
        h.clock.now.add(const Duration(days: 7)),
      );
      final finished = await h.ops.reminders.schedule(
        item.id,
        h.clock.now.add(const Duration(days: 8)),
      );
      await h.ops.reminders.markDone(finished.id);
      final activeNotification = h.scheduler.scheduled
          .firstWhere((n) => n.reminderId == active.id)
          .notificationId;
      h.scheduler.cancelled.clear();

      final recent = h.ops.scans.watchRecent();
      expect(await recent.first, hasLength(2));

      await h.ops.privacy.deleteAllHistory();

      expect(await firstWhere(recent, (l) => l.isEmpty), isEmpty);
      expect(await h.ops.scans.watchForItem(item.id).first, isEmpty);
      expect(await h.ops.scans.latestValidForItem(item.id), isNull);
      expect(await h.ops.inspections.watchForItem(item.id).first, isEmpty);
      expect(await h.ops.inspections.watchOpen().first, isEmpty);
      expect(await h.ops.reminders.watchForItem(item.id).first, isEmpty);
      expect(h.scheduler.cancelled, [activeNotification]);
      expect(h.scheduler.pending, isEmpty);
      expect(audioDeletes, 1);

      // Records and settings that are not history stay.
      expect((await h.ops.items.get(item.id))?.label, 'Rice tin');
      expect(await h.ops.locations.get(location.id), isNotNull);
      expect(await h.ops.lots.get(lot.id), isNotNull);
      expect(await h.ops.settings.watchActiveRole().first, Role.household);
      expect(await h.ops.settings.watchRetainAudioOptIn().first, isTrue);

      final queue = await h.ops.ranking.watchQueue().first;
      expect(queue.ranked, isEmpty);
      expect(queue.needsScan.single.id, item.id);

      // New history can be recorded afterwards, and a second wipe is harmless.
      await h.recordScan(item.id);
      await h.ops.privacy.deleteAllHistory();
      expect(await h.ops.scans.watchRecent().first, isEmpty);
      expect(audioDeletes, 2);
    },
  );
}
