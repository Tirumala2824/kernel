import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  test(
    'exposes every contract interface and delegates permission requests',
    () async {
      final h = await Harness.create();
      addTearDown(h.dispose);
      final ops = h.ops;

      // Static types are the contracts interfaces, nothing drift-specific.
      final ItemRepository items = ops.items;
      final LocationRepository locations = ops.locations;
      final LotRepository lots = ops.lots;
      final ScanRepository scans = ops.scans;
      final InspectionRepository inspections = ops.inspections;
      final ReminderRepository reminders = ops.reminders;
      final SettingsRepository settings = ops.settings;
      final RankingService ranking = ops.ranking;
      final ReportService reports = ops.reports;
      final PrivacyService privacy = ops.privacy;
      expect([
        items,
        locations,
        lots,
        scans,
        inspections,
        reminders,
        settings,
        ranking,
        reports,
        privacy,
      ], everyElement(isNotNull));

      expect(await ops.requestNotificationPermission(), isTrue);
      await ops.restoreReminders(); // nothing to restore on a fresh database
      expect(h.scheduler.scheduled, isEmpty);
    },
  );
}
