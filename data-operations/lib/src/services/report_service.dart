import 'dart:io';

import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import '../db/database.dart';
import '../mappers.dart';
import '../reports/report_csv.dart';
import '../reports/report_data.dart';
import '../reports/report_fonts.dart';
import '../reports/report_pdf.dart';
import '../reports/sightings_report.dart';
import '../repositories/location_repository.dart' show locationSubtree;
import '../repositories/sighting_repository.dart' show activeSightings;
import '../support.dart';
import 'scope.dart';

/// Provenance note of the installed model (`EngineInfo.modelNote`), or null
/// when unknown. Wired by the app.
typedef ModelNoteSource = Future<String?> Function();

/// Builds CSV/PDF reports from stored records and writes them into an
/// app-private directory. Archived items never appear in new reports.
class DriftReportService implements ReportService {
  DriftReportService(
    this._db,
    this._outputDirectory,
    this._clock, {
    this._fontLoader,
    this._modelNote,
  });

  final KernelDatabase _db;
  final Directory _outputDirectory;
  final Clock _clock;
  final ReportFontLoader? _fontLoader;
  final ModelNoteSource? _modelNote;
  Future<ReportFonts>? _fonts;

  /// Items must match every filter in [scope]: owned by `scope.role`, placed
  /// in `scope.locationId` or a location nested below it, in `scope.lotId`,
  /// in `scope.harvestId`, listed in `scope.itemIds`, and not archived. Null
  /// filters are ignored. [ReportKind.sightings] has its own scope rules;
  /// see [loadSightings].
  ///
  /// Throws [ArgumentError] for [ReportKind.sackLabels] as CSV, a
  /// [ReportKind.lotSummary] without a known `lotId`, or a
  /// [ReportKind.preSale] with an unknown `harvestId`.
  @override
  Future<String> export(ReportScope scope, ReportFormat format) async {
    if (scope.kind == ReportKind.sackLabels && format == ReportFormat.csv) {
      throw ArgumentError.value(
        format,
        'format',
        'sack labels are available as PDF only',
      );
    }
    if (scope.kind == ReportKind.lotSummary && scope.lotId == null) {
      throw ArgumentError.value(
        scope.lotId,
        'scope.lotId',
        'a lot summary needs a lot',
      );
    }
    final List<int> bytes;
    switch (scope.kind) {
      case ReportKind.history:
        final data = await load(scope);
        bytes = switch (format) {
          ReportFormat.csv => renderCsv(data),
          ReportFormat.pdf => await renderPdf(data, await _kit()),
        };
      case ReportKind.preSale:
        final data = await loadPreSale(scope);
        bytes = switch (format) {
          ReportFormat.csv => renderPreSaleCsv(data),
          ReportFormat.pdf => await renderPreSalePdf(data, await _kit()),
        };
      case ReportKind.lotSummary:
        final data = await loadLotSummary(scope);
        bytes = switch (format) {
          ReportFormat.csv => renderLotSummaryCsv(data),
          ReportFormat.pdf => await renderLotSummaryPdf(data, await _kit()),
        };
      case ReportKind.sackLabels:
        bytes = await renderSackLabelsPdf(
          await loadSackLabels(scope),
          await _kit(),
        );
      case ReportKind.sightings:
        final data = await loadSightings(scope);
        bytes = switch (format) {
          ReportFormat.csv => renderSightingsCsv(data),
          ReportFormat.pdf => await renderSightingsPdf(data, await _kit()),
        };
    }
    return _write(scope, format, bytes);
  }

  /// Pest ID sightings and sensor event counts in [scope], in one
  /// consistent snapshot. A sighting or event is in scope when it is not in
  /// an archived location or on an archived item, and:
  /// - with `lotId`, `harvestId` or `itemIds`: it is on an item in scope;
  /// - else with `locationId`: its location is that location or one nested
  ///   below it, or it is on an item in scope;
  /// - else: it is on no item, or on an item in scope.
  ///
  /// Items in scope follow the usual rules (role, nested location, lot,
  /// harvest, item ids, not archived). Sightings must also have been saved
  /// under `scope.role`; sensor events have no role, so an event placed
  /// only in a location counts for every role. Events use the placement
  /// they were recorded under.
  Future<SightingsReportData> loadSightings(ReportScope scope) {
    return _db.transaction(() async {
      final generatedAt = _clock().toUtc();
      final scoped = {
        for (final row in await itemsInScope(
          _db,
          role: scope.role,
          locationId: scope.locationId,
          lotId: scope.lotId,
          harvestId: scope.harvestId,
          itemIds: scope.itemIds,
        ))
          row.id,
      };
      final narrowsItems =
          scope.lotId != null ||
          scope.harvestId != null ||
          scope.itemIds != null;
      final locationId = scope.locationId;
      final subtree = locationId == null
          ? null
          : await locationSubtree(_db, locationId);
      final locations = {
        for (final row in await _db.select(_db.locations).get()) row.id: row,
      };
      final items = {
        for (final row in await _db.select(_db.items).get()) row.id: row,
      };
      final lots = {
        for (final row in await _db.select(_db.lots).get()) row.id: row,
      };
      final harvests = {
        for (final row in await _db.select(_db.harvests).get()) row.id: row,
      };
      final paths = _Snapshot(generatedAt, locations, const {}, const {});

      bool inScope(String? itemId, String? placeId) {
        if (placeId != null && locations[placeId]?.archivedAt != null) {
          return false;
        }
        if (itemId != null && items[itemId]?.archivedAt != null) return false;
        final onScopedItem = itemId != null && scoped.contains(itemId);
        if (narrowsItems) return onScopedItem;
        if (subtree != null) {
          return (placeId != null && subtree.contains(placeId)) || onScopedItem;
        }
        return itemId == null || onScopedItem;
      }

      final sightings = [
        for (final s in (await activeSightings(_db, role: scope.role)).reversed)
          if (inScope(s.itemId, s.locationId))
            ReportSighting(
              sighting: s,
              locationPath: paths.pathOf(s.locationId),
              itemLabel: s.itemId == null ? null : items[s.itemId]?.label,
            ),
      ];

      final nodes = {
        for (final row in await _db.select(_db.sensorNodes).get())
          row.id: row.toModel(),
      };
      final eventRows =
          await (_db.select(_db.sensorEvents)..orderBy([
                (e) => OrderingTerm.asc(e.startedAt),
                (e) => OrderingTerm.asc(e.seq),
              ]))
              .get();
      final groups = <(String, String?), List<SensorEventRow>>{};
      for (final row in eventRows) {
        if (!inScope(row.itemId, row.locationId)) continue;
        groups.putIfAbsent((row.nodeId, row.signatureId), () => []).add(row);
      }
      String placementOf(SensorEventRow row) {
        final itemLabel = row.itemId == null ? null : items[row.itemId]?.label;
        final path = paths.pathOf(row.locationId);
        return [?itemLabel, ?path].join(' @ ');
      }

      final sensor = [
        for (final MapEntry(key: (nodeId, signatureId), value: rows)
            in groups.entries)
          if (nodes[nodeId] case final node?)
            SensorEventCount(
              node: node,
              placements: {for (final row in rows) placementOf(row)}
                  .where((p) => p.isNotEmpty)
                  .join('; '),
              signatureId: signatureId,
              packVersion: blankToNull(
                {for (final row in rows) ?row.packVersion}.join('; '),
              ),
              events: rows.length,
              firstStartedAt: rows.first.startedAt,
              lastEndedAt: rows
                  .map(
                    (r) =>
                        r.startedAt.add(Duration(milliseconds: r.durationMs)),
                  )
                  .reduce((a, b) => a.isAfter(b) ? a : b),
              experimental: rows.any((r) => r.matchExperimental != false),
            ),
      ]..sort(_bySensorRow);

      return SightingsReportData(
        scope: scope,
        generatedAt: generatedAt,
        locationLabel: paths.pathOf(scope.locationId),
        lotLabel: scope.lotId == null
            ? null
            : (lots[scope.lotId]?.code ?? scope.lotId),
        harvestLabel: scope.harvestId == null
            ? null
            : (harvests[scope.harvestId]?.name ?? scope.harvestId),
        sightings: List.unmodifiable(sightings),
        sensor: List.unmodifiable(sensor),
      );
    });
  }

  /// Node name, node id, then signature (unmatched last).
  static int _bySensorRow(SensorEventCount a, SensorEventCount b) {
    final byName = a.node.name.compareTo(b.node.name);
    if (byName != 0) return byName;
    final byNode = a.node.id.compareTo(b.node.id);
    if (byNode != 0) return byNode;
    final sa = a.signatureId;
    final sb = b.signatureId;
    if (sa == null || sb == null) {
      return sa == sb ? 0 : (sa == null ? 1 : -1);
    }
    return sa.compareTo(sb);
  }

  /// Reads everything the history report shows, in one consistent snapshot.
  Future<ReportData> load(ReportScope scope) async {
    final note = await _currentModelNote();
    final s = await _snapshot(scope);
    return ReportData(
      scope: scope,
      generatedAt: s.generatedAt,
      locationLabel: s.pathOf(scope.locationId),
      lotLabel: scope.lotId == null
          ? null
          : (s.lots[scope.lotId]?.code ?? scope.lotId),
      harvestLabel: scope.harvestId == null
          ? null
          : (s.harvests[scope.harvestId]?.name ?? scope.harvestId),
      modelNote: note,
      items: s.items,
    );
  }

  Future<PreSaleData> loadPreSale(ReportScope scope) async {
    final note = await _currentModelNote();
    final s = await _snapshot(scope);
    final harvestId = scope.harvestId;
    final harvest = harvestId == null ? null : s.harvests[harvestId];
    if (harvestId != null && harvest == null) {
      throw ArgumentError.value(
        harvestId,
        'scope.harvestId',
        'unknown harvest',
      );
    }
    return PreSaleData(
      scope: scope,
      generatedAt: s.generatedAt,
      harvest: harvest,
      modelNote: note,
      sacks: s.items,
    );
  }

  Future<LotSummaryData> loadLotSummary(ReportScope scope) async {
    final note = await _currentModelNote();
    final s = await _snapshot(scope);
    final lot = s.lots[scope.lotId];
    if (lot == null) {
      throw ArgumentError.value(scope.lotId, 'scope.lotId', 'unknown lot');
    }
    return LotSummaryData(
      scope: scope,
      generatedAt: s.generatedAt,
      lot: lot,
      modelNote: note,
      sacks: s.items,
    );
  }

  Future<List<SackLabel>> loadSackLabels(ReportScope scope) async {
    final rows = await itemsInScope(
      _db,
      role: scope.role,
      locationId: scope.locationId,
      lotId: scope.lotId,
      harvestId: scope.harvestId,
      itemIds: scope.itemIds,
    );
    return [
      for (final row in rows)
        SackLabel(itemId: row.id, label: row.label, grainType: row.grainType),
    ];
  }

  Future<_Snapshot> _snapshot(ReportScope scope) {
    return _db.transaction(() async {
      final generatedAt = _clock().toUtc();
      final itemRows = await itemsInScope(
        _db,
        role: scope.role,
        locationId: scope.locationId,
        lotId: scope.lotId,
        harvestId: scope.harvestId,
        itemIds: scope.itemIds,
      );
      final ids = [for (final row in itemRows) row.id];

      final locations = {
        for (final row in await _db.select(_db.locations).get()) row.id: row,
      };
      final lots = {
        for (final row in await _db.select(_db.lots).get())
          row.id: row.toModel(),
      };
      final harvests = {
        for (final row in await _db.select(_db.harvests).get())
          row.id: row.toModel(),
      };

      final scans = <String, List<ScanRecord>>{};
      final inspections = <String, List<Inspection>>{};
      if (ids.isNotEmpty) {
        final scanRows =
            await (_db.select(_db.scans)
                  ..where((s) => s.itemId.isIn(ids))
                  ..orderBy([
                    (s) => OrderingTerm.asc(s.capturedAt),
                    (s) => OrderingTerm.asc(s.createdAt),
                    (s) => OrderingTerm.asc(s.id),
                  ]))
                .get();
        for (final row in scanRows) {
          scans.putIfAbsent(row.itemId, () => []).add(row.toModel());
        }
        final inspectionRows =
            await (_db.select(_db.inspections)
                  ..where((i) => i.itemId.isIn(ids))
                  ..orderBy([
                    (i) => OrderingTerm.asc(i.inspectedAt),
                    (i) => OrderingTerm.asc(i.createdAt),
                    (i) => OrderingTerm.asc(i.id),
                  ]))
                .get();
        for (final row in inspectionRows) {
          inspections.putIfAbsent(row.itemId, () => []).add(row.toModel());
        }
      }

      final snapshot = _Snapshot(generatedAt, locations, lots, harvests);
      snapshot.items = [
        for (final row in itemRows)
          ReportItem(
            item: row.toModel(),
            locationPath: snapshot.pathOf(row.locationId),
            lot: row.lotId == null ? null : lots[row.lotId],
            harvest: row.harvestId == null ? null : harvests[row.harvestId],
            scans: List.unmodifiable(scans[row.id] ?? const []),
            inspections: List.unmodifiable(inspections[row.id] ?? const []),
          ),
      ];
      return snapshot;
    });
  }

  /// The model note, if a source is wired and it answers. A report never
  /// fails because the engine could not be asked.
  Future<String?> _currentModelNote() async {
    final source = _modelNote;
    if (source == null) return null;
    try {
      return blankToNull(await source());
    } on Exception {
      return null;
    }
  }

  Future<PdfKit> _kit() async {
    final loader = _fontLoader;
    if (loader == null) return const PdfKit();
    final pending = _fonts ??= ReportFonts.load(loader);
    try {
      return PdfKit(fonts: await pending);
    } catch (_) {
      // Allow a later export to retry loading.
      if (identical(_fonts, pending)) _fonts = null;
      rethrow;
    }
  }

  Future<String> _write(
    ReportScope scope,
    ReportFormat format,
    List<int> bytes,
  ) async {
    await _outputDirectory.create(recursive: true);
    final stamp = utcStamp(_clock())
        .replaceAll(RegExp('[-:]'), '')
        .replaceAll('T', '-');
    final suffix = newId().substring(0, 8);
    final kind = switch (scope.kind) {
      ReportKind.history => 'report',
      ReportKind.preSale => 'presale',
      ReportKind.lotSummary => 'lot-summary',
      ReportKind.sackLabels => 'sack-labels',
      ReportKind.sightings => 'sightings',
    };
    final file = File(
      p.join(
        _outputDirectory.path,
        'kernel-$kind-${scope.role.name}-$stamp-$suffix.${format.name}',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.absolute.path;
  }
}

class _Snapshot {
  _Snapshot(this.generatedAt, this.locations, this.lots, this.harvests);

  final DateTime generatedAt;
  final Map<String, LocationRow> locations;
  final Map<String, Lot> lots;
  final Map<String, Harvest> harvests;
  List<ReportItem> items = const [];

  /// "Warehouse / Room 2" for a location id, or null.
  String? pathOf(String? locationId) {
    if (locationId == null) return null;
    final names = <String>[];
    final seen = <String>{};
    String? current = locationId;
    while (current != null && seen.add(current)) {
      final row = locations[current];
      if (row == null) break;
      names.add(row.name);
      current = row.parentId;
    }
    return names.reversed.join(' / ');
  }
}
