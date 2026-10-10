import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';

/// A [NextAction] turned into action-led, localized copy plus where it
/// leads. AnalyticsService returns only kinds, counts and record labels;
/// every word on screen comes from the ARB files.
class NextStep {
  const NextStep({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.location,
    this.tab = false,
    this.scan = false,
    this.attention = false,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;

  /// Route to open.
  final String location;

  /// True for bottom-nav tab routes (opened with `go`, not pushed).
  final bool tab;

  /// True when the step itself starts a scan, so no extra scan shortcut is
  /// needed next to it.
  final bool scan;

  /// Amber attention styling ("Inspection needed", "Review due").
  final bool attention;

  void open(BuildContext context) =>
      tab ? context.go(location) : context.push(location);
}

NextStep describeNextAction(AppLocalizations l, Role role, NextAction a) {
  final kind = role.itemKind;
  final label = a.label?.trim();
  final anyName = label != null && label.isNotEmpty ? label : null;
  final name = a.count <= 1 ? anyName : null;
  final batchScope = a.locationId != null || a.lotId != null;
  switch (a.kind) {
    case NextActionKind.registerFirst:
      final lot = role == Role.buyer;
      return NextStep(
        title: lot ? l.nextRegisterFirstLot : l.nextRegisterFirst(kind),
        subtitle: lot ? l.nextRegisterFirstLotBody : l.nextRegisterFirstBody,
        actionLabel: l.nextActionRegister,
        icon: Icons.add_rounded,
        location: lot
            ? Routes.newLot
            : Routes.newItem(
                locationId: a.locationId,
                lotId: a.lotId,
                harvestId: a.harvestId,
              ),
      );
    case NextActionKind.scanNeeded:
      final batch = a.itemId == null && batchScope;
      return NextStep(
        title: name != null
            ? l.nextScanOne(name)
            : (kind == 'container'
                  ? l.nextScanContainers(a.count)
                  : l.nextScanSacks(a.count)),
        subtitle: l.nextScanBody(kind),
        actionLabel: batch ? l.nextActionBatch : l.nextActionScan,
        icon: batch ? Icons.playlist_play_rounded : Icons.graphic_eq_rounded,
        location: a.itemId != null
            ? Routes.scanItem(a.itemId!)
            : batch
            ? Routes.batchRun(locationId: a.locationId, lotId: a.lotId)
            : Routes.scan,
        tab: a.itemId == null && !batch,
        scan: true,
      );
    case NextActionKind.inspectFlagged:
      return NextStep(
        title: name != null
            ? l.nextInspectOne(name)
            : (kind == 'container'
                  ? l.nextInspectContainers(a.count)
                  : l.nextInspectSacks(a.count)),
        subtitle: l.nextInspectBody,
        actionLabel: a.itemId != null ? l.nextActionOpen : l.nextActionQueue,
        icon: Icons.person_search_rounded,
        location: a.itemId != null ? Routes.item(a.itemId!) : Routes.queue,
        attention: true,
      );
    case NextActionKind.reviewDue:
      return NextStep(
        title: name != null
            ? l.nextReviewOne(name)
            : (kind == 'container'
                  ? l.nextReviewContainers(a.count)
                  : l.nextReviewSacks(a.count)),
        subtitle: l.nextReviewBody,
        actionLabel: l.nextActionOpen,
        icon: Icons.event_repeat_rounded,
        location: a.itemId != null ? Routes.item(a.itemId!) : Routes.inventory,
        tab: a.itemId == null,
        attention: true,
      );
    case NextActionKind.reminderDue:
      return NextStep(
        title: name != null
            ? l.nextReminderOne(name)
            : l.nextReminderMany(a.count),
        subtitle: l.nextReminderBody,
        actionLabel: l.nextActionOpen,
        icon: Icons.alarm_rounded,
        location: a.itemId != null ? Routes.item(a.itemId!) : Routes.inventory,
        tab: a.itemId == null,
        attention: true,
      );
    case NextActionKind.physicalCheckPending:
      return NextStep(
        title: name != null
            ? l.nextPhysicalOne(name)
            : l.nextPhysicalMany(a.count),
        subtitle: l.nextPhysicalBody,
        actionLabel: l.nextActionOpenLot,
        icon: Icons.fact_check_rounded,
        location: a.lotId != null ? Routes.lot(a.lotId!) : Routes.inventory,
        tab: a.lotId == null,
        attention: true,
      );
    case NextActionKind.finishBatch:
      return NextStep(
        title: anyName != null
            ? l.nextFinishBatchOne(anyName)
            : l.nextFinishBatch,
        subtitle: l.nextFinishBatchBody(a.count),
        actionLabel: l.nextActionContinueBatch,
        icon: Icons.playlist_play_rounded,
        location: batchScope
            ? Routes.batchRun(locationId: a.locationId, lotId: a.lotId)
            : Routes.batchSetup,
        scan: true,
      );
    case NextActionKind.exportPreSale:
      return NextStep(
        title: anyName != null ? l.nextPreSaleOne(anyName) : l.nextPreSale,
        subtitle: l.nextExportBody,
        actionLabel: l.nextActionReport,
        icon: Icons.description_rounded,
        location: Routes.reportPreset(
          ReportKind.preSale,
          harvestId: a.harvestId,
        ),
        tab: true,
      );
    case NextActionKind.exportLotSummary:
      return NextStep(
        title: anyName != null
            ? l.nextLotSummaryOne(anyName)
            : l.nextLotSummary,
        subtitle: l.nextExportBody,
        actionLabel: l.nextActionReport,
        icon: Icons.description_rounded,
        location: Routes.reportPreset(ReportKind.lotSummary, lotId: a.lotId),
        tab: true,
      );
    case NextActionKind.pestSightingsRepeated:
      return NextStep(
        title: anyName != null
            ? l.pestNextRepeatedOne(anyName, a.count)
            : l.pestNextRepeated(a.count),
        subtitle: l.pestNextRepeatedBody,
        actionLabel: l.pestNextAction,
        icon: Icons.pest_control_rounded,
        location: Routes.sightings,
        attention: true,
      );
    case NextActionKind.pestSafetyAlert:
      return NextStep(
        title: l.pestNextSafety,
        subtitle: l.pestNextSafetyBody,
        actionLabel: l.pestNextAction,
        icon: Icons.health_and_safety_rounded,
        location: Routes.sightings,
        attention: true,
      );
    // Sensors (Phase 4 part B) own their copy and screens; until those land
    // these open Settings with the record label, so the switch stays total.
    case NextActionKind.sensorActivity:
    case NextActionKind.sensorNeedsAttention:
      return NextStep(
        title: anyName ?? l.menuSettings,
        subtitle: l.settingsSubtitle,
        actionLabel: l.nextActionOpen,
        icon: Icons.sensors_rounded,
        location: Routes.settings,
      );
  }
}
