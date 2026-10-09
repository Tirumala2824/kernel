import 'dart:io';

import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import '../db/database.dart';
import '../mappers.dart';
import '../reports/report_csv.dart';
import '../reports/report_data.dart';
import '../reports/report_pdf.dart';
import '../support.dart';
import 'scope.dart';

/// Builds CSV/PDF reports from stored records and writes them into an
/// app-private directory.
class DriftReportService implements ReportService {
  DriftReportService(this._db, this._outputDirectory, this._clock);

  final KernelDatabase _db;
  final Directory _outputDirectory;
  final Clock _clock;

  /// Items must match every filter in [scope]: owned by `scope.role`, placed
  /// in `scope.locationId` or a location nested below it, in `scope.lotId`,
  /// and listed in `scope.itemIds`. Null filters are ignored.
  @override
  Future<String> export(ReportScope scope, ReportFormat format) async {
    final data = await load(scope);
    final bytes = switch (format) {
      ReportFormat.csv => renderCsv(data),
      ReportFormat.pdf => await renderPdf(data),
    };
    await _outputDirectory.create(recursive: true);
    final stamp = utcStamp(data.generatedAt)
        .replaceAll(RegExp('[-:]'), '')
        .replaceAll('T', '-');
    final suffix = newId().substring(0, 8);
    final file = File(
      p.join(
        _outputDirectory.path,
        'kernel-report-${scope.role.name}-$stamp-$suffix.${format.name}',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.absolute.path;
  }

  /// Reads everything the report shows, in one consistent snapshot.
  Future<ReportData> load(ReportScope scope) {
    return _db.transaction(() async {
      final generatedAt = _clock().toUtc();
      final itemRows = await itemsInScope(
        _db,
        role: scope.role,
        locationId: scope.locationId,
        lotId: scope.lotId,
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

      return ReportData(
        scope: scope,
        generatedAt: generatedAt,
        locationLabel: pathOf(scope.locationId),
        lotLabel: scope.lotId == null
            ? null
            : (lots[scope.lotId]?.code ?? scope.lotId),
        items: [
          for (final row in itemRows)
            ReportItem(
              item: row.toModel(),
              locationPath: pathOf(row.locationId),
              lot: row.lotId == null ? null : lots[row.lotId],
              scans: List.unmodifiable(scans[row.id] ?? const []),
              inspections: List.unmodifiable(inspections[row.id] ?? const []),
            ),
        ],
      );
    });
  }
}
