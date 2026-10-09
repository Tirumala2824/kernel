import 'package:kernel_contracts/kernel_contracts.dart';

// Pure app rules, kept free of Flutter so they are easy to test.

// ---------------------------------------------------------------------------
// QR sack labels.

/// Payload printed on sack labels: `kernel:item:<itemId>`.
const kernelItemPayloadPrefix = 'kernel:item:';

String kernelItemPayload(String itemId) => '$kernelItemPayloadPrefix$itemId';

final _itemIdPattern = RegExp(r'^[A-Za-z0-9._-]{1,128}$');

/// Item id from a scanned QR payload, or null when it is not a Kernel sack
/// label. Anything else (URLs, other apps' codes) is ignored.
String? parseKernelItemPayload(String raw) {
  final text = raw.trim();
  if (text.length <= kernelItemPayloadPrefix.length) return null;
  final prefix = text.substring(0, kernelItemPayloadPrefix.length);
  if (prefix.toLowerCase() != kernelItemPayloadPrefix) return null;
  final id = text.substring(kernelItemPayloadPrefix.length);
  return _itemIdPattern.hasMatch(id) ? id : null;
}

// ---------------------------------------------------------------------------
// Research labels: clean/infested need a human inspection that agrees.

/// The verified finding a label needs, or null for [SampleLabel.unknown].
VerifiedFinding? requiredFindingFor(SampleLabel label) => switch (label) {
  SampleLabel.clean => VerifiedFinding.noneFound,
  SampleLabel.infested => VerifiedFinding.pestsFound,
  SampleLabel.unknown => null,
};

/// Inspections of the item that confirm [label], newest first.
List<Inspection> agreeingInspections(
  SampleLabel label,
  Iterable<Inspection> inspections,
) {
  final needed = requiredFindingFor(label);
  if (needed == null) return const [];
  return inspections.where((i) => i.verifiedFinding == needed).toList()
    ..sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt));
}

/// Labels the user may choose. Unknown is always allowed; clean and
/// infested only when an agreeing inspection exists.
Set<SampleLabel> allowedSampleLabels(Iterable<Inspection> inspections) => {
  SampleLabel.unknown,
  for (final label in [SampleLabel.clean, SampleLabel.infested])
    if (agreeingInspections(label, inspections).isNotEmpty) label,
};

/// True when [label] can be saved with [inspection] as its evidence.
bool sampleLabelSupported(SampleLabel label, Inspection? inspection) {
  final needed = requiredFindingFor(label);
  if (needed == null) return true;
  return inspection != null && inspection.verifiedFinding == needed;
}

/// A research recording can be labelled only when it was usable and its
/// audio was actually kept.
bool recordingUsableForResearch(ScanRecord scan) =>
    scan.quality == ScanQuality.pass && scan.audioRetained;

// ---------------------------------------------------------------------------
// Live capture hints (from levels only; never from samples).

/// Average RMS below this means the phone is not picking up the grain.
const quietRmsDbfs = -65.0;

/// A peak above this is close to clipping: rubbing, tapping or knocking.
const loudPeakDbfs = -1.0;

enum LevelHint { waiting, tooQuiet, tooLoud, holdStill }

/// Hint for the last ~0.3 s of levels.
LevelHint levelHint(List<CaptureLevel> levels, {int window = 6}) {
  if (levels.isEmpty) return LevelHint.waiting;
  final recent = levels.length > window
      ? levels.sublist(levels.length - window)
      : levels;
  if (recent.any((l) => l.peakDbfs > loudPeakDbfs)) return LevelHint.tooLoud;
  final mean =
      recent.map((l) => l.rmsDbfs).reduce((a, b) => a + b) / recent.length;
  if (mean < quietRmsDbfs) return LevelHint.tooQuiet;
  return LevelHint.holdStill;
}

/// Maps dBFS (-90..0) onto 0..1 for meters.
double levelFraction(double dbfs, {double floor = -90}) =>
    ((dbfs - floor) / -floor).clamp(0.0, 1.0);

// ---------------------------------------------------------------------------
// Household review: a container is due for a check when its last usable
// recording is older than the interval, or it was never scanned.

const householdReviewInterval = Duration(days: 14);

enum ReviewState { neverScanned, due, upToDate }

class ReviewStatus {
  const ReviewStatus(this.state, {this.daysSinceScan, this.daysUntilDue});

  final ReviewState state;
  final int? daysSinceScan;
  final int? daysUntilDue;
}

ReviewStatus reviewStatus(Iterable<ScanRecord> scans, {DateTime? now}) {
  final usable = scans.where((s) => s.quality == ScanQuality.pass).toList()
    ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  if (usable.isEmpty) return const ReviewStatus(ReviewState.neverScanned);
  final current = (now ?? DateTime.now()).toLocal();
  final last = usable.first.capturedAt.toLocal();
  final today = DateTime(current.year, current.month, current.day);
  final lastDay = DateTime(last.year, last.month, last.day);
  final since = today.difference(lastDay).inDays.clamp(0, 1 << 30);
  final interval = householdReviewInterval.inDays;
  if (since >= interval) {
    return ReviewStatus(ReviewState.due, daysSinceScan: since);
  }
  return ReviewStatus(
    ReviewState.upToDate,
    daysSinceScan: since,
    daysUntilDue: interval - since,
  );
}

// ---------------------------------------------------------------------------
// Device log row for docs/device-validation.md
// (| Date | Who | Build | Test | Result / notes |).

String deviceLogRow({
  required DateTime date,
  required String build,
  required EngineInfo info,
}) {
  String cell(Object? value) =>
      (value ?? '-').toString().replaceAll('|', '/').replaceAll('\n', ' ');
  final d = date.toLocal();
  final day =
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  final notes = [
    'model=${info.modelVersion}${info.experimental ? ' (experimental)' : ''}',
    'note=${cell(info.modelNote)}',
    'delegate=${info.delegate.name}',
    'target=${info.targetSampleRate} Hz',
    'effective=${info.effectiveSampleRate == null ? 'not measured' : '${info.effectiveSampleRate} Hz'}',
    'device input=${info.deviceInputSampleRate == null ? '-' : '${info.deviceInputSampleRate} Hz'}',
    'source=${cell(info.audioSource)}',
    'device=${cell(info.deviceModel)}',
    'os=${cell(info.osVersion)}',
  ].join('; ');
  return '| $day |  | ${cell(build)} | Diagnostics (EngineInfo) | $notes |';
}
