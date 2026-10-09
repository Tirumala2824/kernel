import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../l10n/l10n.dart';

// Enum-to-copy mapping. Every string lives in lib/l10n/app_en.arb; result
// wording follows docs/design-tokens.md exactly.

extension RoleCopy on Role {
  String title(AppLocalizations l) => switch (this) {
    Role.farmer => l.roleFarmer,
    Role.household => l.roleHousehold,
    Role.storageFpo => l.roleStorageFpo,
    Role.buyer => l.roleBuyer,
  };

  /// Role selection card subtitle.
  String tagline(AppLocalizations l) => switch (this) {
    Role.farmer => l.roleFarmerTagline,
    Role.household => l.roleHouseholdTagline,
    Role.storageFpo => l.roleStorageFpoTagline,
    Role.buyer => l.roleBuyerTagline,
  };

  /// Bottom navigation label for the Inventory tab.
  String inventoryLabel(AppLocalizations l) => switch (this) {
    Role.farmer => l.navInventoryFarmer,
    Role.household => l.navInventoryHousehold,
    Role.storageFpo => l.navInventoryFpo,
    Role.buyer => l.navInventoryBuyer,
  };

  String reportTitle(AppLocalizations l) => switch (this) {
    Role.farmer => l.reportTitleFarmer,
    Role.household => l.reportTitleHousehold,
    Role.storageFpo => l.reportTitleFpo,
    Role.buyer => l.reportTitleBuyer,
  };

  /// Selector for ICU `select` messages: `container` or `sack`.
  String get itemKind => this == Role.household ? 'container' : 'sack';

  IconData get icon => switch (this) {
    Role.farmer => Icons.agriculture_rounded,
    Role.household => Icons.kitchen_rounded,
    Role.storageFpo => Icons.warehouse_rounded,
    Role.buyer => Icons.local_shipping_rounded,
  };

  /// Location type offered first when this role adds a place.
  LocationType get defaultLocationType => switch (this) {
    Role.household => LocationType.home,
    Role.storageFpo => LocationType.warehouse,
    Role.farmer => LocationType.home,
    Role.buyer => LocationType.warehouse,
  };
}

extension LocationTypeCopy on LocationType {
  String label(AppLocalizations l) => switch (this) {
    LocationType.home => l.locationTypeHome,
    LocationType.container => l.locationTypeContainer,
    LocationType.warehouse => l.locationTypeWarehouse,
    LocationType.room => l.locationTypeRoom,
    LocationType.stack => l.locationTypeStack,
  };

  IconData get icon => switch (this) {
    LocationType.home => Icons.home_rounded,
    LocationType.container => Icons.kitchen_rounded,
    LocationType.warehouse => Icons.warehouse_rounded,
    LocationType.room => Icons.meeting_room_rounded,
    LocationType.stack => Icons.layers_rounded,
  };
}

extension ScreeningStatusCopy on ScreeningStatus {
  String label(AppLocalizations l) => switch (this) {
    ScreeningStatus.pending => l.screeningPending,
    ScreeningStatus.screening => l.screeningScreening,
    ScreeningStatus.needsPhysicalCheck => l.screeningNeedsPhysicalCheck,
    ScreeningStatus.reviewed => l.screeningReviewed,
  };
}

extension VerifiedFindingCopy on VerifiedFinding {
  String label(AppLocalizations l) => switch (this) {
    VerifiedFinding.noneFound => l.findingNoneFound,
    VerifiedFinding.pestsFound => l.findingPestsFound,
    VerifiedFinding.inconclusive => l.findingInconclusive,
  };

  String help(AppLocalizations l) => switch (this) {
    VerifiedFinding.noneFound => l.findingNoneFoundHelp,
    VerifiedFinding.pestsFound => l.findingPestsFoundHelp,
    VerifiedFinding.inconclusive => l.findingInconclusiveHelp,
  };
}

extension FollowUpStatusCopy on FollowUpStatus {
  String label(AppLocalizations l) => switch (this) {
    FollowUpStatus.open => l.followUpOpen,
    FollowUpStatus.inProgress => l.followUpInProgress,
    FollowUpStatus.done => l.followUpDone,
  };
}

extension ReminderStatusCopy on ReminderStatus {
  String label(AppLocalizations l) => switch (this) {
    ReminderStatus.scheduled => l.reminderScheduled,
    ReminderStatus.fired => l.reminderFired,
    ReminderStatus.done => l.reminderDone,
    ReminderStatus.cancelled => l.reminderCancelled,
  };
}

extension QualityReasonCopy on QualityReason {
  /// Readable reason plus what to do about it.
  String explanation(AppLocalizations l) => switch (this) {
    QualityReason.silence => l.reasonSilence,
    QualityReason.clipping => l.reasonClipping,
    QualityReason.highNoise => l.reasonHighNoise,
    QualityReason.tooShort => l.reasonTooShort,
    QualityReason.permissionDenied => l.reasonPermissionDenied,
    QualityReason.captureError => l.reasonCaptureError,
  };
}

extension ScanQualityCopy on ScanQuality {
  String label(AppLocalizations l) =>
      this == ScanQuality.pass ? l.qualityPass : l.qualityRetry;
}

extension ClassificationCopy on Classification {
  /// Short label for a model prediction. Always shown as unverified.
  String predictionLabel(AppLocalizations l) => switch (this) {
    Classification.clean => l.predictionClean,
    Classification.uncertain => l.predictionUncertain,
    Classification.infested => l.predictionInfested,
    Classification.notEvaluated => l.predictionNotEvaluated,
  };
}

extension SampleLabelCopy on SampleLabel {
  String label(AppLocalizations l) => switch (this) {
    SampleLabel.clean => l.sampleLabelClean,
    SampleLabel.infested => l.sampleLabelInfested,
    SampleLabel.unknown => l.sampleLabelUnknown,
  };
}

/// Result headline (docs/design-tokens.md, "Result headline states").
String resultHeadline(
  AppLocalizations l, {
  required ScanQuality quality,
  required Classification classification,
  required String modelVersion,
}) {
  if (quality == ScanQuality.retry) return l.headlineRetry;
  return switch (classification) {
    Classification.notEvaluated =>
      modelVersion == noModelVersion
          ? l.headlineNotEvaluated
          : l.headlineNotEvaluatedWithModel,
    Classification.infested ||
    Classification.uncertain => l.headlineInspectionNeeded,
    Classification.clean => l.headlineClean,
  };
}

/// Model provenance line, e.g. "Model: none — Not evaluated" or
/// "Model v1 — Experimental".
String provenanceLine(
  AppLocalizations l, {
  required String modelVersion,
  required bool experimental,
}) {
  if (modelVersion == noModelVersion) return l.provenanceNone;
  return experimental
      ? l.provenanceExperimental(modelVersion)
      : l.provenanceValidated(modelVersion);
}

String formatQuantity(double value, String unit) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
  return '$text $unit';
}

String formatDate(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatMediumDate(value.toLocal());

String formatTime(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(value.toLocal()));

String formatDateTime(BuildContext context, DateTime value) =>
    context.l10n.dateTimeJoin(
      formatDate(context, value),
      formatTime(context, value),
    );

int daysSince(DateTime date, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final start = DateUtils.dateOnly(date.toLocal());
  final days = today.difference(start).inDays;
  return days < 0 ? 0 : days;
}

/// Local midnight at the start of today.
DateTime startOfToday({DateTime? now}) =>
    DateUtils.dateOnly(now ?? DateTime.now());
