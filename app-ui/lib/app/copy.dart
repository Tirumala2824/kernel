import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

// Plain-language copy. Result wording follows docs/design-tokens.md exactly.

extension RoleCopy on Role {
  String get title => switch (this) {
    Role.farmer => 'Farmer',
    Role.household => 'Household',
    Role.storageFpo => 'Storage/FPO',
    Role.buyer => 'Buyer',
  };

  /// Role selection card subtitle.
  String get tagline => switch (this) {
    Role.farmer => 'Harvest and pre-sale checks',
    Role.household => 'Containers and reminders',
    Role.storageFpo => 'Warehouse and batch inspections',
    Role.buyer => 'Supplier and lot screening',
  };

  /// Bottom navigation label for the Inventory tab.
  String get inventoryLabel => switch (this) {
    Role.farmer => 'My Grain',
    Role.household => 'My Containers',
    Role.storageFpo => 'Warehouse',
    Role.buyer => 'Lots',
  };

  String get itemNoun => this == Role.household ? 'container' : 'sack';
  String get itemNounPlural => this == Role.household ? 'containers' : 'sacks';

  String get registerItemAction =>
      this == Role.household ? 'Add container' : 'Register sack';

  String get reportTitle => switch (this) {
    Role.farmer => 'Pre-sale report',
    Role.household => 'Storage report',
    Role.storageFpo => 'Warehouse report',
    Role.buyer => 'Lot screening report',
  };

  IconData get icon => switch (this) {
    Role.farmer => Icons.agriculture,
    Role.household => Icons.kitchen,
    Role.storageFpo => Icons.warehouse,
    Role.buyer => Icons.local_shipping,
  };

  /// Location type offered first when this role adds a place.
  LocationType get defaultLocationType => switch (this) {
    Role.household => LocationType.home,
    Role.storageFpo => LocationType.warehouse,
    Role.farmer => LocationType.home,
    Role.buyer => LocationType.warehouse,
  };
}

String countLabel(int n, String singular, String plural) =>
    '$n ${n == 1 ? singular : plural}';

extension LocationTypeCopy on LocationType {
  String get label => switch (this) {
    LocationType.home => 'Home',
    LocationType.container => 'Container',
    LocationType.warehouse => 'Warehouse',
    LocationType.room => 'Room',
    LocationType.stack => 'Stack',
  };
}

extension ScreeningStatusCopy on ScreeningStatus {
  String get label => switch (this) {
    ScreeningStatus.pending => 'Pending',
    ScreeningStatus.screening => 'Screening',
    ScreeningStatus.needsPhysicalCheck => 'Pending physical check',
    ScreeningStatus.reviewed => 'Reviewed',
  };
}

extension VerifiedFindingCopy on VerifiedFinding {
  String get label => switch (this) {
    VerifiedFinding.noneFound => 'None found',
    VerifiedFinding.pestsFound => 'Pests found',
    VerifiedFinding.inconclusive => 'Inconclusive',
  };

  String get help => switch (this) {
    VerifiedFinding.noneFound => 'I checked and saw no insects or damage',
    VerifiedFinding.pestsFound => 'I saw insects, larvae, webbing or damage',
    VerifiedFinding.inconclusive => 'I could not tell from the check',
  };
}

extension FollowUpStatusCopy on FollowUpStatus {
  String get label => switch (this) {
    FollowUpStatus.open => 'Open',
    FollowUpStatus.inProgress => 'In progress',
    FollowUpStatus.done => 'Done',
  };
}

extension ReminderStatusCopy on ReminderStatus {
  String get label => switch (this) {
    ReminderStatus.scheduled => 'Scheduled',
    ReminderStatus.fired => 'Due now',
    ReminderStatus.done => 'Done',
    ReminderStatus.cancelled => 'Cancelled',
  };
}

extension QualityReasonCopy on QualityReason {
  /// Readable reason plus what to do about it.
  String get explanation => switch (this) {
    QualityReason.silence =>
      'Too quiet: almost no sound reached the microphone. Press the phone '
          'firmly against the grain.',
    QualityReason.clipping =>
      'Too loud: the sound was distorted. Do not tap or knock while '
          'recording.',
    QualityReason.highNoise =>
      'Too much background noise. Move somewhere quieter and keep still.',
    QualityReason.tooShort =>
      'The recording was too short. Keep the phone still for the full '
          '2 seconds.',
    QualityReason.permissionDenied =>
      'Microphone access is off. Allow it in the phone settings to scan.',
    QualityReason.captureError =>
      'The microphone could not record. Close other apps that use the '
          'microphone and try again.',
  };
}

extension ScanQualityCopy on ScanQuality {
  String get label => this == ScanQuality.pass ? 'Pass' : 'Retry';
}

extension ClassificationCopy on Classification {
  /// Short label for a model prediction. Always shown as unverified.
  String get predictionLabel => switch (this) {
    Classification.clean => 'No signal detected',
    Classification.uncertain => 'Uncertain',
    Classification.infested => 'Possible infestation',
    Classification.notEvaluated => 'Not evaluated',
  };
}

// Result headlines (docs/design-tokens.md, "Result headline states").
const retryHeadline = 'Recording not usable — try again';
const notEvaluatedHeadline =
    'Not evaluated — no model installed. Inspect physically.';
const notEvaluatedWithModelHeadline =
    'Not evaluated — the model could not process this recording. '
    'Inspect physically.';
const inspectionNeededHeadline =
    'Inspection needed — model result is not verified';
const cleanHeadline =
    'No signal detected — not a guarantee; inspect before sale/storage '
    'decisions';

/// Physical inspection disclaimer shown with every result.
const physicalInspectionNote =
    'Acoustic screening is experimental. A physical inspection is required '
    'before any storage or sale decision.';

String resultHeadline({
  required ScanQuality quality,
  required Classification classification,
  required String modelVersion,
}) {
  if (quality == ScanQuality.retry) return retryHeadline;
  return switch (classification) {
    Classification.notEvaluated =>
      modelVersion == noModelVersion
          ? notEvaluatedHeadline
          : notEvaluatedWithModelHeadline,
    Classification.infested ||
    Classification.uncertain => inspectionNeededHeadline,
    Classification.clean => cleanHeadline,
  };
}

/// Model provenance line, e.g. "Model: none — Not evaluated" or
/// "Model v1 — Experimental".
String provenanceLine({
  required String modelVersion,
  required bool experimental,
}) {
  if (modelVersion == noModelVersion) return 'Model: none — Not evaluated';
  return 'Model $modelVersion — ${experimental ? 'Experimental' : 'Validated'}';
}

String formatQuantity(double value, String unit) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
  return '$text $unit';
}

String formatDate(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatMediumDate(value.toLocal());

String formatDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final l10n = MaterialLocalizations.of(context);
  return '${l10n.formatMediumDate(local)}, '
      '${l10n.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

int daysSince(DateTime date, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final start = DateUtils.dateOnly(date.toLocal());
  final days = today.difference(start).inDays;
  return days < 0 ? 0 : days;
}
