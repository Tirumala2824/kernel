import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'report_data.dart';

/// Column header of the record table. AI prediction columns (`ai_*`) and
/// human inspection columns (`human_*`) are always separate.
const csvColumns = <String>[
  'row_type',
  'item_id',
  'item_label',
  'owner_role',
  'grain_type',
  'quantity',
  'quantity_unit',
  'storage_date_utc',
  'location',
  'lot_code',
  'supplier_name',
  'scan_id',
  'scan_captured_at_utc',
  'model_version',
  'experimental',
  'quality',
  'quality_reasons',
  'ai_predicted_class',
  'ai_predicted_label',
  'ai_confidence',
  'scan_duration_ms',
  'sample_rate_hz',
  'device_model',
  'os_version',
  'inspection_id',
  'inspection_scan_id',
  'human_inspected_at_utc',
  'human_inspector',
  'human_verified_finding',
  'human_observations',
  'human_follow_up_status',
];

/// Marks the line that starts the record table, after the preamble.
const csvTableMarker = 'row_type';

/// UTF-8 (with BOM, for spreadsheet apps) CSV bytes.
///
/// Layout: a short preamble (title, scope, disclaimer), a blank line, then
/// the record table with [csvColumns]. Rows:
/// - `scan`: one per stored scan; human columns are filled only when an
///   inspection explicitly references that scan.
/// - `inspection`: inspections not linked to a scan.
/// - `item`: items with no scans and no inspections.
List<int> renderCsv(ReportData data) {
  final rows = <List<Object?>>[
    ['Kernel grain screening report'],
    ['Generated (UTC)', utcStamp(data.generatedAt)],
    ['Role', roleLabel(data.scope.role)],
    ['Location', data.locationLabel ?? 'All'],
    ['Lot', data.lotLabel ?? 'All'],
    ['Harvest', data.harvestLabel ?? 'All'],
    ..._modelNoteRows(data.modelNote),
    ['Items', data.items.length],
    ['Scans', data.scanCount],
    ['Inspections', data.inspectionCount],
    for (final line in reportDisclaimer) ['Disclaimer', line],
    [],
    csvColumns,
  ];

  for (final entry in data.items) {
    final itemCells = _itemCells(entry);
    final linked = <String, List<Inspection>>{};
    final unlinked = <Inspection>[];
    for (final inspection in entry.inspections) {
      final scanId = inspection.scanId;
      if (scanId == null) {
        unlinked.add(inspection);
      } else {
        linked.putIfAbsent(scanId, () => []).add(inspection);
      }
    }
    for (final scan in entry.scans) {
      final inspections = linked.remove(scan.id) ?? const <Inspection>[];
      if (inspections.isEmpty) {
        rows.add(['scan', ...itemCells, ..._scanCells(scan), ..._noInspection]);
      }
      for (final inspection in inspections) {
        rows.add([
          'scan',
          ...itemCells,
          ..._scanCells(scan),
          ..._inspectionCells(inspection),
        ]);
      }
    }
    // Links to scans outside this report cannot happen (scans are per item),
    // but never drop a stored inspection.
    unlinked.addAll(linked.values.expand((list) => list));
    for (final inspection in unlinked) {
      rows.add([
        'inspection',
        ...itemCells,
        ..._noScan,
        ..._inspectionCells(inspection),
      ]);
    }
    if (entry.scans.isEmpty && entry.inspections.isEmpty) {
      rows.add(['item', ...itemCells, ..._noScanRecorded, ..._noInspection]);
    }
  }

  return utf8.encode(Csv(addBom: true).encode(rows));
}

/// Columns of the pre-sale table: one `sack` row per sack. The latest AI
/// screening (`latest_scan_*`, `ai_*`) and the latest human inspection
/// (`latest_inspection_id`, `human_*`) are separate column groups.
const preSaleCsvColumns = <String>[
  'row_type',
  'item_id',
  'item_label',
  'grain_type',
  'quantity',
  'quantity_unit',
  'storage_date_utc',
  'location',
  'harvest',
  'latest_scan_id',
  'latest_scan_captured_at_utc',
  'model_version',
  'experimental',
  'quality',
  'ai_predicted_class',
  'ai_predicted_label',
  'ai_confidence',
  'latest_inspection_id',
  'human_inspected_at_utc',
  'human_inspector',
  'human_verified_finding',
  'human_follow_up_status',
];

/// Pre-sale summary CSV: preamble (harvest, model note, summary counts,
/// disclaimers), then [preSaleCsvColumns].
List<int> renderPreSaleCsv(PreSaleData data) {
  final rows = <List<Object?>>[
    ['Kernel pre-sale summary'],
    ['Generated (UTC)', utcStamp(data.generatedAt)],
    ['Role', roleLabel(data.scope.role)],
    ['Harvest', userText(data.harvestLabel)],
    if (data.harvest case final harvest?) ...[
      ['Harvested (UTC)', utcDate(harvest.harvestedAt)],
      ['Harvest grain', userText(harvest.grainType)],
      if (harvest.archivedAt != null) ['Harvest archived', 'yes'],
    ],
    ..._modelNoteRows(data.modelNote),
    ['Sacks', data.sacks.length],
    ['Sacks with a valid AI screening', data.screenedCount],
    for (final (label, count) in data.aiCounts)
      ['Latest AI screening: $label', count],
    for (final (label, count) in data.humanCounts)
      ['Latest physical inspection: $label', count],
    ['Notice', preSaleNotice],
    for (final line in reportDisclaimer) ['Disclaimer', line],
    [],
    preSaleCsvColumns,
  ];
  for (final sack in data.sacks) {
    final item = sack.item;
    final scan = sack.latestScan;
    final inspection = sack.latestInspection;
    rows.add([
      'sack',
      item.id,
      userText(item.label),
      userText(item.grainType),
      formatQuantity(item.quantity),
      userText(item.quantityUnit),
      utcDate(item.storageDate),
      userText(sack.locationPath ?? ''),
      userText(sack.harvest?.name ?? ''),
      ..._latestScanCells(scan),
      inspection?.id ?? '',
      inspection == null ? '' : utcStamp(inspection.inspectedAt),
      inspection == null ? '' : userText(inspection.inspector),
      inspection == null
          ? notInspected
          : verifiedFindingLabel(inspection.verifiedFinding),
      inspection == null ? '' : followUpLabel(inspection.followUpStatus),
    ]);
  }
  return utf8.encode(Csv(addBom: true).encode(rows));
}

/// Columns of the lot summary table. `sack` rows carry the latest AI
/// screening; `check` rows carry one human physical check each. The two
/// column groups never share a row.
const lotSummaryCsvColumns = <String>[
  'row_type',
  'item_id',
  'item_label',
  'grain_type',
  'quantity',
  'quantity_unit',
  'screened',
  'latest_scan_id',
  'latest_scan_captured_at_utc',
  'model_version',
  'experimental',
  'quality',
  'ai_predicted_class',
  'ai_predicted_label',
  'ai_confidence',
  'inspection_id',
  'human_inspected_at_utc',
  'human_inspector',
  'human_verified_finding',
  'human_observations',
  'human_follow_up_status',
];

/// Buyer lot summary CSV: preamble (lot details, human-set screening
/// status, counts, the not-a-decision statement, disclaimers), then
/// [lotSummaryCsvColumns].
List<int> renderLotSummaryCsv(LotSummaryData data) {
  final lot = data.lot;
  final total = data.sacks.length;
  final rows = <List<Object?>>[
    ['Kernel lot screening summary'],
    ['Generated (UTC)', utcStamp(data.generatedAt)],
    ['Role', roleLabel(data.scope.role)],
    ['Lot', userText(lot.code)],
    ['Supplier', userText(lot.supplierName ?? '')],
    ['Supplier ID', userText(lot.supplierId ?? '')],
    ['Grain', userText(lot.grainType)],
    [
      'Declared quantity',
      userText('${formatQuantity(lot.declaredQuantity)} ${lot.quantityUnit}'),
    ],
    ['Received (UTC)', utcDate(lot.receivedAt)],
    [
      'Screening status (set by a person)',
      screeningStatusLabel(lot.screeningStatus),
    ],
    if (lot.archivedAt != null) ['Lot archived', 'yes'],
    ..._modelNoteRows(data.modelNote),
    ['Sacks', total],
    ['Sacks screened (valid scans)', '${data.screenedCount} of $total'],
    for (final (label, count) in data.aiCounts)
      ['Latest AI screening: $label', count],
    ['Sacks physically checked', '${data.checkedCount} of $total'],
    ['Physical checks', data.checkCount],
    for (final (label, count) in data.findingCounts)
      ['Physical checks: $label', count],
    ['Decision', lotDecisionNotice],
    for (final line in reportDisclaimer) ['Disclaimer', line],
    [],
    lotSummaryCsvColumns,
  ];
  for (final sack in data.sacks) {
    final item = sack.item;
    final itemCells = [
      item.id,
      userText(item.label),
      userText(item.grainType),
      formatQuantity(item.quantity),
      userText(item.quantityUnit),
    ];
    rows.add([
      'sack',
      ...itemCells,
      yesNo(sack.screened),
      ..._latestScanCells(sack.latestScan),
      ...List.filled(6, ''),
    ]);
    for (final inspection in sack.inspections) {
      rows.add([
        'check',
        ...itemCells,
        '',
        ...List.filled(_latestScanCellCount, ''),
        inspection.id,
        utcStamp(inspection.inspectedAt),
        userText(inspection.inspector),
        verifiedFindingLabel(inspection.verifiedFinding),
        userText(inspection.observations),
        followUpLabel(inspection.followUpStatus),
      ]);
    }
  }
  return utf8.encode(Csv(addBom: true).encode(rows));
}

const _latestScanCellCount = 8;

/// latest_scan_id .. ai_confidence for the most recent scan, or "No scan
/// recorded".
List<Object?> _latestScanCells(ScanRecord? scan) => scan == null
    ? ['', '', '', '', '', '', noScanRecorded, '']
    : [
        scan.id,
        utcStamp(scan.capturedAt),
        scan.modelVersion,
        yesNo(scan.experimental),
        qualityLabel(scan.quality),
        scan.result.name,
        predictedClassLabel(scan),
        scan.confidence?.toStringAsFixed(3) ?? '',
      ];

List<List<Object?>> _modelNoteRows(String? note) => [
  if (note != null) ['Model note (installed model)', userText(note)],
];

/// User-entered text, neutralised so spreadsheet apps never evaluate it as a
/// formula when the shared CSV is opened.
String userText(String value) =>
    value.startsWith(RegExp(r'[=+\-@\t\r]')) ? "'$value" : value;

List<Object?> _itemCells(ReportItem entry) {
  final item = entry.item;
  return [
    item.id,
    userText(item.label),
    roleLabel(item.ownerRole),
    userText(item.grainType),
    formatQuantity(item.quantity),
    userText(item.quantityUnit),
    utcDate(item.storageDate),
    userText(entry.locationPath ?? ''),
    userText(entry.lot?.code ?? ''),
    userText(entry.lot?.supplierName ?? ''),
  ];
}

List<Object?> _scanCells(ScanRecord scan) => [
  scan.id,
  utcStamp(scan.capturedAt),
  scan.modelVersion,
  yesNo(scan.experimental),
  qualityLabel(scan.quality),
  qualityReasonsLabel(scan.qualityReasons),
  scan.result.name,
  predictedClassLabel(scan),
  scan.confidence?.toStringAsFixed(3) ?? '',
  scan.durationMs,
  scan.sampleRate,
  scan.deviceModel,
  scan.osVersion,
];

List<Object?> _inspectionCells(Inspection inspection) => [
  inspection.id,
  inspection.scanId ?? '',
  utcStamp(inspection.inspectedAt),
  userText(inspection.inspector),
  verifiedFindingLabel(inspection.verifiedFinding),
  userText(inspection.observations),
  followUpLabel(inspection.followUpStatus),
];

const _scanCellCount = 13;
const _inspectionCellCount = 7;

final List<Object?> _noScan = List.filled(_scanCellCount, '');
final List<Object?> _noInspection = List.filled(_inspectionCellCount, '');

/// Scan columns for an item that was never scanned.
final List<Object?> _noScanRecorded = [
  for (var i = 0; i < _scanCellCount; i++) i == 7 ? noScanRecorded : '',
];
