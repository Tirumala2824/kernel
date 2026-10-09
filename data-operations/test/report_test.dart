import 'dart:convert';
import 'dart:io';

import 'package:data_operations/src/reports/report_csv.dart';
import 'package:data_operations/src/reports/report_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import 'support/csv.dart';
import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  test('an empty scope still yields a valid CSV and PDF', () async {
    final csvPath = await h.ops.reports.export(
      const ReportScope(role: Role.farmer),
      ReportFormat.csv,
    );
    final parsed = await readCsv(csvPath);
    expect(parsed.header, csvColumns);
    expect(parsed.rows, isEmpty);

    final pdfPath = await h.ops.reports.export(
      const ReportScope(role: Role.farmer),
      ReportFormat.pdf,
    );
    expect(await File(pdfPath).exists(), isTrue);
  });

  test(
    'CSV has provenance, separate AI and human columns, and the disclaimer',
    () async {
      final store = await h.ops.locations.create(
        const LocationDraft(type: LocationType.warehouse, name: 'Godown'),
      );
      final room = await h.ops.locations.create(
        LocationDraft(
          type: LocationType.room,
          name: 'Room 2',
          parentId: store.id,
        ),
      );
      final scanned = await h.addItem(label: 'Sack R-004', locationId: room.id);
      final unscanned = await h.addItem(label: 'Sack R-005');

      final noModel = await h.recordScan(scanned.id, minutesAgo: 30);
      final retry = await h.recordScan(
        scanned.id,
        minutesAgo: 20,
        quality: ScanQuality.retry,
        reasons: const [QualityReason.silence, QualityReason.highNoise],
      );
      final modelScan = await h.recordModelScan(
        scanned.id,
        Classification.clean,
        minutesAgo: 10,
      );
      final linked = await h.ops.inspections.create(
        InspectionDraft(
          itemId: scanned.id,
          scanId: noModel.id,
          inspectedAt: DateTime.utc(2026, 10, 1, 9),
          inspector: 'Ravi',
          observations: 'Two live insects in sieve sample',
          verifiedFinding: VerifiedFinding.pestsFound,
        ),
      );
      final unlinked = await h.ops.inspections.create(
        InspectionDraft(
          itemId: scanned.id,
          inspectedAt: DateTime.utc(2026, 10, 1, 10),
          inspector: 'Ravi',
          observations: '=SUM(A1)',
          verifiedFinding: VerifiedFinding.inconclusive,
        ),
      );

      final path = await h.ops.reports.export(
        const ReportScope(role: Role.farmer),
        ReportFormat.csv,
      );
      expect(p.isAbsolute(path), isTrue);
      expect(p.isWithin(h.reportDir.path, path), isTrue);
      expect(p.extension(path), '.csv');

      final csv = await readCsv(path);
      expect(csv.header, csvColumns);
      for (final column in [
        'model_version',
        'experimental',
        'quality',
        'quality_reasons',
        'ai_predicted_class',
        'human_verified_finding',
      ]) {
        expect(csv.header, contains(column));
      }

      final preambleText = csv.preamble.expand((r) => r).join(' ');
      expect(preambleText, contains('"Clean" result is not a guarantee'));
      expect(preambleText, contains('Physical inspection is required'));
      expect(preambleText, contains('Farmer'));

      final scans = csv.ofType('scan');
      expect(scans.map((r) => r['scan_id']), [
        noModel.id,
        retry.id,
        modelScan.id,
      ]);

      final noModelRow = scans[0];
      expect(noModelRow['model_version'], noModelVersion);
      expect(noModelRow['experimental'], 'yes');
      expect(noModelRow['quality'], 'PASS');
      expect(noModelRow['ai_predicted_class'], 'notEvaluated');
      expect(
        noModelRow['ai_predicted_label'],
        'Not evaluated — no model installed',
      );
      expect(noModelRow['ai_confidence'], '');
      expect(noModelRow['location'], 'Godown / Room 2');
      // Human-verified columns, kept apart from the AI ones.
      expect(noModelRow['inspection_id'], linked.id);
      expect(noModelRow['human_verified_finding'], 'Pests found');
      expect(noModelRow['human_inspector'], 'Ravi');

      final retryRow = scans[1];
      expect(retryRow['quality'], 'RETRY');
      expect(retryRow['quality_reasons'], 'silence; highNoise');
      expect(retryRow['ai_predicted_class'], 'notEvaluated');
      expect(retryRow['human_verified_finding'], '');

      final modelRow = scans[2];
      expect(modelRow['model_version'], 'test-model-1');
      expect(modelRow['ai_predicted_class'], 'clean');
      expect(modelRow['ai_predicted_label'], 'Clean');
      expect(modelRow['ai_confidence'], '0.800');
      expect(modelRow['device_model'], 'test-device');
      expect(modelRow['sample_rate_hz'], '16000');

      final inspectionRow = csv.ofType('inspection').single;
      expect(inspectionRow['inspection_id'], unlinked.id);
      expect(inspectionRow['scan_id'], '');
      expect(inspectionRow['ai_predicted_class'], '');
      expect(inspectionRow['human_verified_finding'], 'Inconclusive');
      expect(inspectionRow['human_observations'], "'=SUM(A1)");

      final itemRow = csv.ofType('item').single;
      expect(itemRow['item_id'], unscanned.id);
      expect(itemRow['ai_predicted_label'], 'No scan recorded');
    },
  );

  test('scope filters by role, location subtree, lot and itemIds', () async {
    final store = await h.ops.locations.create(
      const LocationDraft(type: LocationType.warehouse, name: 'Godown'),
    );
    final stack = await h.ops.locations.create(
      LocationDraft(
        type: LocationType.stack,
        name: 'Stack 1',
        parentId: store.id,
      ),
    );
    final lot = await h.ops.lots.create(
      LotDraft(
        code: 'LOT-7',
        grainType: 'Wheat',
        declaredQuantity: 500,
        quantityUnit: 'kg',
        receivedAt: DateTime.utc(2026, 9, 28),
        supplierName: 'Village co-op',
      ),
    );
    final a = await h.addItem(
      role: Role.storageFpo,
      label: 'a',
      locationId: stack.id,
    );
    final b = await h.addItem(role: Role.storageFpo, label: 'b', lotId: lot.id);
    final c = await h.addItem(role: Role.storageFpo, label: 'c');
    await h.addItem(role: Role.buyer, label: 'buyer item', lotId: lot.id);

    Future<List<String>> itemIds(ReportScope scope) async {
      final csv = await readCsv(
        await h.ops.reports.export(scope, ReportFormat.csv),
      );
      return [for (final row in csv.rows) row['item_id']!];
    }

    expect(await itemIds(const ReportScope(role: Role.storageFpo)), [
      a.id,
      b.id,
      c.id,
    ]);
    expect(
      await itemIds(ReportScope(role: Role.storageFpo, locationId: store.id)),
      [a.id],
    );
    expect(await itemIds(ReportScope(role: Role.storageFpo, lotId: lot.id)), [
      b.id,
    ]);
    expect(
      await itemIds(ReportScope(role: Role.storageFpo, itemIds: [c.id, a.id])),
      [a.id, c.id],
    );
    expect(
      await itemIds(const ReportScope(role: Role.storageFpo, itemIds: [])),
      isEmpty,
    );

    final lotCsv = await readCsv(
      await h.ops.reports.export(
        ReportScope(role: Role.storageFpo, lotId: lot.id),
        ReportFormat.csv,
      ),
    );
    expect(lotCsv.rows.single['lot_code'], 'LOT-7');
    expect(lotCsv.rows.single['supplier_name'], 'Village co-op');
    expect(lotCsv.preamble.firstWhere((r) => r.first == 'Lot')[1], 'LOT-7');
  });

  test('PDF export writes a PDF file into the report directory', () async {
    final item = await h.addItem(label: 'Sack R-010');
    await h.recordScan(item.id);
    await h.recordModelScan(item.id, Classification.infested, minutesAgo: 5);
    await h.ops.inspections.create(
      InspectionDraft(
        itemId: item.id,
        inspectedAt: DateTime.utc(2026, 10, 1, 9),
        inspector: 'Ravi',
        observations: 'Checked by sieve',
        verifiedFinding: VerifiedFinding.noneFound,
      ),
    );

    final path = await h.ops.reports.export(
      const ReportScope(role: Role.farmer),
      ReportFormat.pdf,
    );
    expect(p.isAbsolute(path), isTrue);
    expect(p.isWithin(h.reportDir.path, path), isTrue);
    expect(p.extension(path), '.pdf');
    final bytes = await File(path).readAsBytes();
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('each export creates a new file', () async {
    const scope = ReportScope(role: Role.household);
    final first = await h.ops.reports.export(scope, ReportFormat.csv);
    final second = await h.ops.reports.export(scope, ReportFormat.csv);
    expect(first, isNot(second));
    expect(await File(first).exists(), isTrue);
    expect(await File(second).exists(), isTrue);
  });

  test(
    'pdfSafe keeps Latin-1 and replaces what the built-in fonts cannot draw',
    () {
      expect(pdfSafe('Not evaluated — no model'), 'Not evaluated - no model');
      expect(pdfSafe('“Clean” · café'), '"Clean" · café');
      expect(pdfSafe('गेहूं'), '?????');
    },
  );
}
