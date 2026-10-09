import 'package:kernel_contracts/kernel_contracts.dart';

/// Everything a report shows, loaded from stored records only.
class ReportData {
  const ReportData({
    required this.scope,
    required this.generatedAt,
    required this.locationLabel,
    required this.lotLabel,
    required this.items,
  });

  final ReportScope scope;

  /// UTC.
  final DateTime generatedAt;

  /// Scope location path, or null when the report is not location-scoped.
  final String? locationLabel;

  /// Scope lot code, or null when the report is not lot-scoped.
  final String? lotLabel;
  final List<ReportItem> items;

  int get scanCount => items.fold(0, (sum, i) => sum + i.scans.length);
  int get inspectionCount =>
      items.fold(0, (sum, i) => sum + i.inspections.length);
}

class ReportItem {
  const ReportItem({
    required this.item,
    required this.locationPath,
    required this.lot,
    required this.scans,
    required this.inspections,
  });

  final GrainItem item;
  final String? locationPath;
  final Lot? lot;

  /// Oldest first.
  final List<ScanRecord> scans;

  /// Oldest first.
  final List<Inspection> inspections;
}

/// Disclaimer printed on every report (guardrails §4).
const reportDisclaimer = <String>[
  'AI predictions come from an experimental on-device model. They are '
      'screening aids only and are listed separately from human-verified '
      'inspection findings.',
  'A "Clean" result is not a guarantee that the grain is free of pests. '
      'Physical inspection is required before any storage, sale, purchase or '
      'treatment decision.',
  'This report was built only from records stored on this device. Scans '
      'marked "Not evaluated" carry no AI prediction.',
];

const notEvaluatedNoModel = 'Not evaluated — no model installed';
const notEvaluatedRetry = 'Not evaluated — recording needs a retry';
const notEvaluatedOther = 'Not evaluated';
const noScanRecorded = 'No scan recorded';

/// Human-readable AI result. Never mixed with a verified finding.
String predictedClassLabel(ScanRecord scan) => switch (scan.result) {
  Classification.clean => 'Clean',
  Classification.uncertain => 'Uncertain',
  Classification.infested => 'Infested',
  Classification.notEvaluated when scan.quality == ScanQuality.retry =>
    notEvaluatedRetry,
  Classification.notEvaluated when scan.modelVersion == noModelVersion =>
    notEvaluatedNoModel,
  Classification.notEvaluated => notEvaluatedOther,
};

String verifiedFindingLabel(VerifiedFinding finding) => switch (finding) {
  VerifiedFinding.noneFound => 'No pests found',
  VerifiedFinding.pestsFound => 'Pests found',
  VerifiedFinding.inconclusive => 'Inconclusive',
};

String followUpLabel(FollowUpStatus status) => switch (status) {
  FollowUpStatus.open => 'Open',
  FollowUpStatus.inProgress => 'In progress',
  FollowUpStatus.done => 'Done',
};

String roleLabel(Role role) => switch (role) {
  Role.farmer => 'Farmer',
  Role.household => 'Household',
  Role.storageFpo => 'Storage/FPO',
  Role.buyer => 'Buyer',
};

String qualityLabel(ScanQuality quality) => switch (quality) {
  ScanQuality.pass => 'PASS',
  ScanQuality.retry => 'RETRY',
};

String qualityReasonsLabel(List<QualityReason> reasons) =>
    reasons.map((r) => r.name).join('; ');

String yesNo(bool value) => value ? 'yes' : 'no';

/// ISO-8601 UTC, second precision.
String utcStamp(DateTime value) {
  final utc = value.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
      '${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}Z';
}

/// Calendar date (UTC) for user-entered dates such as storageDate.
String utcDate(DateTime value) => utcStamp(value).substring(0, 10);

String formatQuantity(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
