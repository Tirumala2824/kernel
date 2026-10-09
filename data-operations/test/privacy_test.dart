import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
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
