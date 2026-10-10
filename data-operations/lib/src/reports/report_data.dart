import 'package:kernel_contracts/kernel_contracts.dart';

/// Everything a history report shows, loaded from stored records only.
class ReportData {
  const ReportData({
    required this.scope,
    required this.generatedAt,
    required this.locationLabel,
    required this.lotLabel,
    required this.items,
    this.harvestLabel,
    this.modelNote,
  });

  final ReportScope scope;

  /// UTC.
  final DateTime generatedAt;

  /// Scope location path, or null when the report is not location-scoped.
  final String? locationLabel;

  /// Scope lot code, or null when the report is not lot-scoped.
  final String? lotLabel;

  /// Scope harvest name, or null when the report is not harvest-scoped.
  final String? harvestLabel;

  /// Provenance note of the installed model, when known.
  final String? modelNote;
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
    this.harvest,
  });

  final GrainItem item;
  final String? locationPath;
  final Lot? lot;
  final Harvest? harvest;

  /// Oldest first.
  final List<ScanRecord> scans;

  /// Oldest first.
  final List<Inspection> inspections;

  /// Most recent scan of any quality, or null.
  ScanRecord? get latestScan => scans.isEmpty ? null : scans.last;

  /// Most recent human inspection, or null.
  Inspection? get latestInspection =>
      inspections.isEmpty ? null : inspections.last;

  /// Has at least one valid scan (PASS with a real model result).
  bool get screened => scans.any((scan) => scan.isValid);
}

/// Farmer pre-sale summary: per sack, the latest AI screening next to the
/// latest human inspection. The two are never combined into one verdict.
class PreSaleData {
  const PreSaleData({
    required this.scope,
    required this.generatedAt,
    required this.harvest,
    required this.modelNote,
    required this.sacks,
  });

  final ReportScope scope;
  final DateTime generatedAt;

  /// Null when the summary covers every sack in scope.
  final Harvest? harvest;
  final String? modelNote;
  final List<ReportItem> sacks;

  String get harvestLabel => harvest?.name ?? 'All harvests';

  /// Sacks by the result of their latest scan.
  List<(String, int)> get aiCounts => latestAiCounts(sacks);

  /// Sacks by the finding of their latest inspection.
  List<(String, int)> get humanCounts => [
    for (final finding in VerifiedFinding.values)
      (
        verifiedFindingLabel(finding),
        sacks
            .where((s) => s.latestInspection?.verifiedFinding == finding)
            .length,
      ),
    (notInspected, sacks.where((s) => s.latestInspection == null).length),
  ];

  int get screenedCount => sacks.where((s) => s.screened).length;
}

/// Buyer lot screening summary. Shows the human-set screening status; it is
/// never an accept/reject decision.
class LotSummaryData {
  const LotSummaryData({
    required this.scope,
    required this.generatedAt,
    required this.lot,
    required this.modelNote,
    required this.sacks,
  });

  final ReportScope scope;
  final DateTime generatedAt;
  final Lot lot;
  final String? modelNote;
  final List<ReportItem> sacks;

  int get screenedCount => sacks.where((s) => s.screened).length;
  int get checkedCount => sacks.where((s) => s.inspections.isNotEmpty).length;
  int get checkCount => sacks.fold(0, (sum, s) => sum + s.inspections.length);

  /// Every physical check by verified finding.
  List<(String, int)> get findingCounts => [
    for (final finding in VerifiedFinding.values)
      (
        verifiedFindingLabel(finding),
        sacks
            .expand((s) => s.inspections)
            .where((i) => i.verifiedFinding == finding)
            .length,
      ),
  ];

  List<(String, int)> get aiCounts => latestAiCounts(sacks);
}

/// One printable sack label.
class SackLabel {
  const SackLabel({
    required this.itemId,
    required this.label,
    required this.grainType,
  });

  final String itemId;
  final String label;
  final String grainType;

  /// What the QR code encodes.
  String get payload => sackLabelPayload(itemId);
}

/// QR payload for a sack label: `kernel:item:<itemId>`.
String sackLabelPayload(String itemId) => 'kernel:item:$itemId';

/// Sacks by the result of their latest scan (any quality).
List<(String, int)> latestAiCounts(List<ReportItem> sacks) {
  int count(bool Function(ScanRecord scan) test) => sacks.where((s) {
    final scan = s.latestScan;
    return scan != null && test(scan);
  }).length;
  return [
    ('Clean', count((s) => s.result == Classification.clean)),
    ('Uncertain', count((s) => s.result == Classification.uncertain)),
    ('Infested', count((s) => s.result == Classification.infested)),
    (notEvaluatedOther, count((s) => s.result == Classification.notEvaluated)),
    (noScanRecorded, sacks.where((s) => s.latestScan == null).length),
  ];
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

/// The optional on-phone draft the user chose to include, or null when it
/// is absent, still incomplete or blank. data_operations only renders it,
/// in its own labelled section; it never generates text.
AdviceText? includedNarrative(ReportScope scope) {
  final narrative = scope.narrative;
  if (narrative == null || !narrative.complete) return null;
  if (narrative.text.trim().isEmpty) return null;
  return narrative;
}

/// Heading of the narrative section (guardrails §8).
const narrativeTitle = 'Drafted on this phone';

/// Provenance line under [narrativeTitle]. Generated text is always shown
/// as experimental.
String narrativeByLine(AdviceText narrative) {
  final model = narrative.modelVersion.trim();
  return 'By ${model.isEmpty ? 'an unknown model' : model} — experimental. '
      'Not a record or a decision; check before sharing.';
}

/// Pre-sale summary note (shown with [reportDisclaimer]).
const preSaleNotice =
    'This summary is prepared by the seller from records on this device. It '
    'is not a quality certificate; buyers should confirm by physical '
    'inspection.';

/// Lot summary statement (guardrails §5).
const lotDecisionNotice =
    'This summary is not an accept/reject decision. Kernel never accepts or '
    'rejects a lot from acoustic screening. The screening status was set by '
    'a person, and any decision requires physical inspection.';

const notEvaluatedNoModel = 'Not evaluated — no model installed';
const notEvaluatedRetry = 'Not evaluated — recording needs a retry';
const notEvaluatedOther = 'Not evaluated';
const noScanRecorded = 'No scan recorded';
const notInspected = 'Not inspected';

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

String screeningStatusLabel(ScreeningStatus status) => switch (status) {
  ScreeningStatus.pending => 'Pending',
  ScreeningStatus.screening => 'Screening',
  ScreeningStatus.needsPhysicalCheck => 'Needs physical check',
  ScreeningStatus.reviewed => 'Reviewed',
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
