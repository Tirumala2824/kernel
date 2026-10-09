import 'dart:convert';
import 'dart:io';

import 'package:data_operations/src/reports/report_csv.dart';
import 'package:data_operations/src/reports/report_data.dart';
import 'package:data_operations/src/reports/report_fonts.dart';
import 'package:data_operations/src/reports/report_pdf.dart';
import 'package:data_operations/src/services/report_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;

import 'support/csv.dart';
import 'support/harness.dart';

const _note = 'Proxy model trained on non-grain recordings';

void expectPdfFile(String path, Directory dir) {
  expect(p.isAbsolute(path), isTrue);
  expect(p.isWithin(dir.path, path), isTrue);
  expect(p.extension(path), '.pdf');
  final bytes = File(path).readAsBytesSync();
  expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  expect(bytes.length, greaterThan(1000));
}

/// Pages in an uncompressed PDF 1.4.
int pageCount(List<int> bytes) =>
    RegExp(r'/Type\s*/Page(?!s)').allMatches(latin1.decode(bytes)).length;

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create(modelNote: _note));
  tearDown(() => h.dispose());

  group('preSale', () {
    late Harvest harvest;
    late GrainItem a, b, c, otherHarvest;
    late ScanRecord aLatest;
    late Inspection aLatestCheck;

    setUp(() async {
      harvest = await h.addHarvest(name: 'Rabi 2026');
      final other = await h.addHarvest(name: 'Kharif 2025');
      a = await h.addItem(label: 'Sack A', harvestId: harvest.id);
      b = await h.addItem(label: 'Sack B', harvestId: harvest.id);
      c = await h.addItem(label: 'Sack C', harvestId: harvest.id);
      otherHarvest = await h.addItem(label: 'Sack D', harvestId: other.id);
      final archived = await h.addItem(label: 'Sack E', harvestId: harvest.id);
      await h.ops.items.archive(archived.id);

      await h.recordScan(a.id, minutesAgo: 60);
      aLatest = await h.recordModelScan(
        a.id,
        Classification.clean,
        minutesAgo: 10,
      );
      await h.addInspection(
        a.id,
        VerifiedFinding.noneFound,
        inspectedAt: DateTime.utc(2026, 9, 30),
      );
      aLatestCheck = await h.addInspection(
        a.id,
        VerifiedFinding.pestsFound,
        inspectedAt: DateTime.utc(2026, 10, 1, 7),
      );
      await h.recordScan(
        b.id,
        quality: ScanQuality.retry,
        reasons: const [QualityReason.highNoise],
      );
    });

    test('CSV: per sack the latest AI screening and the latest human finding '
        'stay separate, with counts, disclaimers and the model note', () async {
      final csv = await readCsv(
        await h.ops.reports.export(
          ReportScope(
            role: Role.farmer,
            kind: ReportKind.preSale,
            harvestId: harvest.id,
          ),
          ReportFormat.csv,
        ),
      );
      expect(csv.header, preSaleCsvColumns);
      expect(csv.rows.map((r) => r['item_id']), [a.id, b.id, c.id]);
      expect(csv.rows.map((r) => r['row_type']).toSet(), {'sack'});

      final rowA = csv.rows[0];
      expect(rowA['harvest'], 'Rabi 2026');
      expect(rowA['latest_scan_id'], aLatest.id);
      expect(rowA['model_version'], 'test-model-1');
      expect(rowA['experimental'], 'yes');
      expect(rowA['quality'], 'PASS');
      expect(rowA['ai_predicted_class'], 'clean');
      expect(rowA['ai_predicted_label'], 'Clean');
      // The human finding disagrees and is shown as recorded, not merged.
      expect(rowA['latest_inspection_id'], aLatestCheck.id);
      expect(rowA['human_verified_finding'], 'Pests found');
      expect(rowA['human_inspector'], 'Ravi');

      final rowB = csv.rows[1];
      expect(rowB['quality'], 'RETRY');
      expect(rowB['ai_predicted_class'], 'notEvaluated');
      expect(rowB['ai_predicted_label'], notEvaluatedRetry);
      expect(rowB['human_verified_finding'], notInspected);

      final rowC = csv.rows[2];
      expect(rowC['latest_scan_id'], '');
      expect(rowC['ai_predicted_label'], noScanRecorded);
      expect(rowC['latest_inspection_id'], '');

      expect(csv.preambleValue('Harvest'), 'Rabi 2026');
      expect(csv.preambleValue('Model note (installed model)'), _note);
      expect(csv.preambleValue('Sacks'), '3');
      expect(csv.preambleValue('Sacks with a valid AI screening'), '1');
      expect(csv.preambleValue('Latest AI screening: Clean'), '1');
      expect(csv.preambleValue('Latest AI screening: Infested'), '0');
      expect(csv.preambleValue('Latest AI screening: Not evaluated'), '1');
      expect(csv.preambleValue('Latest AI screening: No scan recorded'), '1');
      expect(csv.preambleValue('Latest physical inspection: Pests found'), '1');
      expect(
        csv.preambleValue('Latest physical inspection: No pests found'),
        '0',
      );
      expect(
        csv.preambleValue('Latest physical inspection: Not inspected'),
        '2',
      );
      expect(csv.preambleValue('Notice'), preSaleNotice);
      expect(
        csv.preambleValues('Disclaimer').join(' '),
        contains('"Clean" result is not a guarantee'),
      );
    });

    test('without a harvest it covers every non-archived sack of the role; '
        'an unknown harvest is rejected', () async {
      final csv = await readCsv(
        await h.ops.reports.export(
          const ReportScope(role: Role.farmer, kind: ReportKind.preSale),
          ReportFormat.csv,
        ),
      );
      expect(csv.preambleValue('Harvest'), 'All harvests');
      expect(csv.rows.map((r) => r['item_id']), [
        a.id,
        b.id,
        c.id,
        otherHarvest.id,
      ]);
      await expectLater(
        h.ops.reports.export(
          const ReportScope(
            role: Role.farmer,
            kind: ReportKind.preSale,
            harvestId: 'nope',
          ),
          ReportFormat.csv,
        ),
        throwsArgumentError,
      );
    });

    test('PDF is produced', () async {
      final path = await h.ops.reports.export(
        ReportScope(
          role: Role.farmer,
          kind: ReportKind.preSale,
          harvestId: harvest.id,
        ),
        ReportFormat.pdf,
      );
      expectPdfFile(path, h.reportDir);
      expect(p.basename(path), startsWith('kernel-presale-farmer-'));
    });
  });

  group('lotSummary', () {
    late Lot lot;
    late GrainItem s1, s2, s3;
    late Inspection pests, unsure;

    setUp(() async {
      lot = await h.ops.lots.create(
        LotDraft(
          code: 'LOT-024',
          grainType: 'Wheat',
          declaredQuantity: 1200,
          quantityUnit: 'kg',
          receivedAt: DateTime.utc(2026, 9, 28),
          supplierName: 'Village co-op',
          supplierId: 'SUP-9',
        ),
      );
      final otherLot = await h.ops.lots.create(
        LotDraft(
          code: 'LOT-025',
          grainType: 'Wheat',
          declaredQuantity: 10,
          quantityUnit: 'kg',
          receivedAt: DateTime.utc(2026, 9, 29),
        ),
      );
      s1 = await h.addItem(role: Role.buyer, label: 'S1', lotId: lot.id);
      s2 = await h.addItem(role: Role.buyer, label: 'S2', lotId: lot.id);
      s3 = await h.addItem(role: Role.buyer, label: 'S3', lotId: lot.id);
      await h.addItem(role: Role.buyer, label: 'S4', lotId: otherLot.id);
      final gone = await h.addItem(
        role: Role.buyer,
        label: 'S5',
        lotId: lot.id,
      );
      await h.ops.items.archive(gone.id);
      await h.ops.lots.updateScreeningStatus(
        lot.id,
        ScreeningStatus.needsPhysicalCheck,
      );

      await h.recordModelScan(s1.id, Classification.infested, minutesAgo: 30);
      pests = await h.addInspection(
        s1.id,
        VerifiedFinding.pestsFound,
        inspectedAt: DateTime.utc(2026, 10, 1, 6),
      );
      unsure = await h.addInspection(
        s1.id,
        VerifiedFinding.inconclusive,
        inspectedAt: DateTime.utc(2026, 10, 1, 7),
      );
      await h.recordScan(s2.id, minutesAgo: 20);
    });

    ReportScope scope() => ReportScope(
      role: Role.buyer,
      kind: ReportKind.lotSummary,
      lotId: lot.id,
    );

    test('CSV: lot details, screened of total, physical checks, the '
        'human-set status and the not-a-decision statement', () async {
      final csv = await readCsv(
        await h.ops.reports.export(scope(), ReportFormat.csv),
      );
      expect(csv.header, lotSummaryCsvColumns);
      expect(csv.preambleValue('Lot'), 'LOT-024');
      expect(csv.preambleValue('Supplier'), 'Village co-op');
      expect(csv.preambleValue('Supplier ID'), 'SUP-9');
      expect(csv.preambleValue('Declared quantity'), '1200 kg');
      expect(csv.preambleValue('Received (UTC)'), '2026-09-28');
      expect(
        csv.preambleValue('Screening status (set by a person)'),
        'Needs physical check',
      );
      expect(csv.preambleValue('Sacks screened (valid scans)'), '1 of 3');
      expect(csv.preambleValue('Sacks physically checked'), '1 of 3');
      expect(csv.preambleValue('Physical checks'), '2');
      expect(csv.preambleValue('Physical checks: Pests found'), '1');
      expect(csv.preambleValue('Physical checks: Inconclusive'), '1');
      expect(csv.preambleValue('Physical checks: No pests found'), '0');
      expect(
        csv.preambleValue('Decision'),
        contains('not an accept/reject decision'),
      );
      expect(csv.preambleValue('Model note (installed model)'), _note);

      final sacks = csv.ofType('sack');
      expect(sacks.map((r) => r['item_id']), [s1.id, s2.id, s3.id]);
      expect(sacks.map((r) => r['screened']), ['yes', 'no', 'no']);
      expect(sacks[0]['ai_predicted_class'], 'infested');
      expect(sacks[1]['ai_predicted_label'], notEvaluatedNoModel);
      expect(sacks[2]['ai_predicted_label'], noScanRecorded);
      for (final row in sacks) {
        expect(row['human_verified_finding'], '', reason: 'kept apart');
      }

      final checks = csv.ofType('check');
      expect(checks.map((r) => r['inspection_id']), [pests.id, unsure.id]);
      expect(checks.map((r) => r['human_verified_finding']), [
        'Pests found',
        'Inconclusive',
      ]);
      for (final row in checks) {
        expect(row['item_id'], s1.id);
        expect(row['ai_predicted_class'], '', reason: 'kept apart');
        expect(row['latest_scan_id'], '');
      }

      // Exporting never changes the human-set status.
      expect(
        (await h.ops.lots.get(lot.id))!.screeningStatus,
        ScreeningStatus.needsPhysicalCheck,
      );
    });

    test('PDF is produced; a missing or unknown lot is rejected', () async {
      expectPdfFile(
        await h.ops.reports.export(scope(), ReportFormat.pdf),
        h.reportDir,
      );
      for (final format in ReportFormat.values) {
        await expectLater(
          h.ops.reports.export(
            const ReportScope(role: Role.buyer, kind: ReportKind.lotSummary),
            format,
          ),
          throwsArgumentError,
        );
        await expectLater(
          h.ops.reports.export(
            const ReportScope(
              role: Role.buyer,
              kind: ReportKind.lotSummary,
              lotId: 'nope',
            ),
            format,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('sackLabels', () {
    test('CSV is rejected', () async {
      await h.addItem();
      await expectLater(
        h.ops.reports.export(
          const ReportScope(role: Role.farmer, kind: ReportKind.sackLabels),
          ReportFormat.csv,
        ),
        throwsArgumentError,
      );
    });

    test('labels encode kernel:item:<itemId> with label and grain type, '
        'skip archived sacks, and fill 12 per page', () async {
      final sacks = [
        for (var i = 1; i <= 14; i++)
          await h.addItem(
            label: 'Sack R-${i.toString().padLeft(3, '0')}',
            grainType: i.isEven ? 'Wheat' : 'Paddy',
          ),
      ];
      await h.ops.items.archive(sacks.last.id);
      final service = h.ops.reports as DriftReportService;
      const scope = ReportScope(role: Role.farmer, kind: ReportKind.sackLabels);

      final labels = await service.loadSackLabels(scope);
      expect(labels, hasLength(13));
      final first = labels.first;
      expect(first.itemId, sacks.first.id);
      expect(first.label, 'Sack R-001');
      expect(first.grainType, 'Paddy');
      expect(first.payload, 'kernel:item:${sacks.first.id}');
      final payload = RegExp(
        r'^kernel:item:[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
        r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      for (final label in labels) {
        expect(label.payload, matches(payload));
        expect(pw.Barcode.qrCode().isValid(label.payload), isTrue);
      }
      expect(sackLabelPayload('abc'), 'kernel:item:abc');

      final bytes = await renderSackLabelsPdf(
        labels,
        PdfKit(fonts: await ReportFonts.load(diskReportFont), compress: false),
      );
      expect(pageCount(bytes), 2);

      final path = await h.ops.reports.export(scope, ReportFormat.pdf);
      expectPdfFile(path, h.reportDir);
      expect(p.basename(path), startsWith('kernel-sack-labels-farmer-'));
    });

    test('an empty scope still prints one page', () async {
      final bytes = await renderSackLabelsPdf(
        const [],
        PdfKit(fonts: await ReportFonts.load(diskReportFont), compress: false),
      );
      expect(pageCount(bytes), 1);
    });
  });

  test(
    'history reports can be scoped to a harvest and carry the model note',
    () async {
      final harvest = await h.addHarvest(name: 'Rabi 2026');
      final inHarvest = await h.addItem(label: 'In', harvestId: harvest.id);
      await h.addItem(label: 'Out');
      final csv = await readCsv(
        await h.ops.reports.export(
          ReportScope(role: Role.farmer, harvestId: harvest.id),
          ReportFormat.csv,
        ),
      );
      expect(csv.header, csvColumns);
      expect(csv.rows.single['item_id'], inHarvest.id);
      expect(csv.preambleValue('Harvest'), 'Rabi 2026');
      expect(csv.preambleValue('Model note (installed model)'), _note);
    },
  );

  test('without a model note source the note is simply omitted', () async {
    final plain = await Harness.create();
    addTearDown(plain.dispose);
    final csv = await readCsv(
      await plain.ops.reports.export(
        const ReportScope(role: Role.farmer),
        ReportFormat.csv,
      ),
    );
    expect(
      csv.preamble.where((r) => r.first.startsWith('Model note')),
      isEmpty,
    );
  });
}
