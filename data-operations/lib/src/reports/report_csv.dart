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
