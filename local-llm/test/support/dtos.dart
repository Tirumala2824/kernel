// Test-only DTO builders. Lives under test/ only.
import 'package:kernel_contracts/kernel_contracts.dart';

ResultAdviceInput resultInput({
  Role role = Role.farmer,
  String grainType = 'Wheat',
  Classification classification = Classification.infested,
  double? confidence = 0.8312,
  ScanQuality quality = ScanQuality.pass,
  List<QualityReason> qualityReasons = const [],
  int storageDays = 42,
  bool pestModelExperimental = true,
  VerifiedFinding? latestVerifiedFinding,
}) => ResultAdviceInput(
  role: role,
  grainType: grainType,
  classification: classification,
  confidence: confidence,
  quality: quality,
  qualityReasons: qualityReasons,
  storageDays: storageDays,
  pestModelExperimental: pestModelExperimental,
  latestVerifiedFinding: latestVerifiedFinding,
);

ReminderAdviceInput reminderInput({
  String grainType = 'Rice',
  Classification? lastResult = Classification.uncertain,
}) => ReminderAdviceInput(
  role: Role.household,
  grainType: grainType,
  storageDays: 10,
  lastResult: lastResult,
  suggestedDueAt: DateTime(2026, 10, 24, 9),
);

ReportNarrativeInput reportInput() => ReportNarrativeInput(
  role: Role.buyer,
  kind: ReportKind.lotSummary,
  summary: AnalyticsSummary(
    role: Role.buyer,
    kind: ReportKind.lotSummary,
    items: 12,
    itemsNeedingScan: 2,
    rates: const ResultRates(
      clean: 6,
      uncertain: 2,
      infested: 1,
      notEvaluated: 1,
      retry: 3,
    ),
    quality: const QualityFailures({
      QualityReason.highNoise: 2,
      QualityReason.silence: 1,
      QualityReason.clipping: 0,
    }),
    inspections: const InspectionStats(open: 1, inProgress: 1, done: 4),
    firstScanAt: DateTime(2026, 9, 1, 10),
    lastScanAt: DateTime(2026, 10, 9, 18),
  ),
);
