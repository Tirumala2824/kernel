import 'dart:typed_data';

import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_data.dart';
import 'report_fonts.dart';

/// Shared PDF building blocks.
///
/// With [fonts], text is drawn with the bundled Noto fonts and per-character
/// fallback, so Latin and the bundled Indian scripts render without
/// substitution. The pdf package does no OpenType shaping (see README).
/// Without [fonts], the built-in PDF fonts are used; they cover Latin-1
/// only, so text goes through [pdfSafe].
class PdfKit {
  const PdfKit({this.fonts, this.compress = true});

  final ReportFonts? fonts;

  /// False writes an uncompressed PDF 1.4 (tests inspect its objects).
  final bool compress;

  /// Text ready for the active fonts.
  String t(String text) => fonts == null ? pdfSafe(text) : text;

  pw.TextStyle style({double size = 8, bool bold = false}) => pw.TextStyle(
    fontSize: size,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    // Bold fallbacks first; the theme adds the regular ones after them.
    fontFallback: bold ? (fonts?.boldFallback ?? const []) : const [],
  );

  pw.Document document(String title) {
    final f = fonts;
    return pw.Document(
      title: title,
      creator: 'Kernel',
      compress: compress,
      version: compress ? PdfVersion.pdf_1_5 : PdfVersion.pdf_1_4,
      theme: f == null
          ? null
          : pw.ThemeData.withFont(
              base: f.regular,
              bold: f.bold,
              fontFallback: f.regularFallback,
            ),
    );
  }

  pw.Widget text(
    String value, {
    double size = 8,
    bool bold = false,
    pw.TextAlign? align,
    int? maxLines,
  }) => pw.Text(
    t(value),
    style: style(size: size, bold: bold),
    textAlign: align,
    maxLines: maxLines,
  );

  pw.Widget title(String value) => text(value, size: 18, bold: true);

  pw.Widget heading(String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
    child: text(value, size: 12, bold: true),
  );

  pw.Widget table(List<String> headers, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: [for (final h in headers) t(h)],
        data: [
          for (final row in rows) [for (final cell in row) t(cell)],
        ],
        headerStyle: style(bold: true),
        cellStyle: style(),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        cellPadding: const pw.EdgeInsets.all(3),
        headerAlignment: pw.Alignment.centerLeft,
      );

  /// Two-column label/value table without a header row.
  pw.Widget facts(List<(String, String)> rows) => pw.Table(
    columnWidths: const {0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth()},
    children: [
      for (final (label, value) in rows)
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 8, bottom: 2),
              child: text(label, bold: true),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: text(value),
            ),
          ],
        ),
    ],
  );

  /// Bordered box with a bold heading, for disclaimers and notices.
  pw.Widget notice(String heading, List<String> lines) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(6),
    decoration: pw.BoxDecoration(border: pw.Border.all()),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        text(heading, bold: true),
        for (final line in lines) text(line),
      ],
    ),
  );

  pw.Widget empty(String value) => text(value);

  /// Boxed "Drafted on this phone" section for an included on-phone
  /// narrative, or nothing when it is absent or incomplete. It is a table
  /// with one row per paragraph, so a long draft can continue on the next
  /// page. Never mixed into record tables or findings.
  List<pw.Widget> narrative(ReportScope scope) {
    final draft = includedNarrative(scope);
    if (draft == null) return const [];
    const side = pw.BorderSide();
    pw.TableRow row(pw.Widget child, {double bottom = 2}) => pw.TableRow(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.fromLTRB(6, 2, 6, bottom),
          child: child,
        ),
      ],
    );
    final paragraphs = [
      for (final line in draft.text.split(RegExp(r'\r?\n')))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    return [
      pw.SizedBox(height: 8),
      pw.Table(
        border: const pw.TableBorder(
          left: side,
          top: side,
          right: side,
          bottom: side,
        ),
        children: [
          row(text(narrativeTitle, size: 10, bold: true)),
          row(text(narrativeByLine(draft)), bottom: 4),
          for (final paragraph in paragraphs) row(text(paragraph), bottom: 4),
        ],
      ),
    ];
  }

  List<pw.Widget> modelNote(String? note) => [
    if (note != null) text('Model note (installed model): $note'),
  ];

  pw.Widget footer(pw.Context context, String note) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: text(note)),
        text('Page ${context.pageNumber} of ${context.pagesCount}'),
      ],
    ),
  );

  pw.MultiPage reportPages({
    required String footerNote,
    required List<pw.Widget> Function(pw.Context context) build,
    PdfPageFormat? format,
  }) => pw.MultiPage(
    pageFormat: format ?? PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(28),
    footer: (context) => footer(context, footerNote),
    build: build,
  );
}

const _cleanFooter =
    'A "Clean" result is not a guarantee. Physical inspection is required '
    'for decisions.';

/// History report PDF. AI predictions and human-verified findings are
/// separate tables; the disclaimer is shown up front and in every footer.
Future<Uint8List> renderPdf(ReportData data, [PdfKit kit = const PdfKit()]) {
  final doc = kit.document('Kernel grain screening report');

  final scanRows = <List<String>>[
    for (final entry in data.items)
      for (final scan in entry.scans)
        [
          entry.item.label,
          utcStamp(scan.capturedAt),
          scan.modelVersion,
          yesNo(scan.experimental),
          qualityLabel(scan.quality),
          qualityReasonsLabel(scan.qualityReasons),
          predictedClassLabel(scan),
          scan.confidence?.toStringAsFixed(3) ?? '',
        ],
  ];
  final scanTimes = {
    for (final entry in data.items)
      for (final scan in entry.scans) scan.id: utcStamp(scan.capturedAt),
  };
  final inspectionRows = <List<String>>[
    for (final entry in data.items)
      for (final inspection in entry.inspections)
        [
          entry.item.label,
          utcStamp(inspection.inspectedAt),
          inspection.inspector,
          verifiedFindingLabel(inspection.verifiedFinding),
          inspection.observations,
          followUpLabel(inspection.followUpStatus),
          inspection.scanId == null
              ? ''
              : (scanTimes[inspection.scanId] ?? inspection.scanId!),
        ],
  ];

  doc.addPage(
    kit.reportPages(
      footerNote: _cleanFooter,
      build: (context) => [
        kit.title('Kernel grain screening report'),
        pw.SizedBox(height: 6),
        kit.text(
          'Generated ${utcStamp(data.generatedAt)} (UTC) · '
          'Role: ${roleLabel(data.scope.role)} · '
          'Location: ${data.locationLabel ?? 'All'} · '
          'Lot: ${data.lotLabel ?? 'All'} · '
          'Harvest: ${data.harvestLabel ?? 'All'}',
        ),
        kit.text(
          'Items: ${data.items.length} · Scans: ${data.scanCount} · '
          'Inspections: ${data.inspectionCount}',
        ),
        ...kit.modelNote(data.modelNote),
        pw.SizedBox(height: 8),
        kit.notice('Disclaimer', reportDisclaimer),
        ...kit.narrative(data.scope),
        kit.heading('Items'),
        if (data.items.isEmpty)
          kit.empty('No items in this scope.')
        else
          kit.table(
            const [
              'Item',
              'Grain',
              'Quantity',
              'Storage date (UTC)',
              'Location',
              'Lot',
              'Scans',
              'Inspections',
            ],
            [
              for (final entry in data.items)
                [
                  entry.item.label,
                  entry.item.grainType,
                  '${formatQuantity(entry.item.quantity)} '
                      '${entry.item.quantityUnit}',
                  utcDate(entry.item.storageDate),
                  entry.locationPath ?? '',
                  entry.lot?.code ?? '',
                  '${entry.scans.length}',
                  '${entry.inspections.length}',
                ],
            ],
          ),
        kit.heading('Scans — AI predictions (experimental)'),
        if (scanRows.isEmpty)
          kit.empty('$noScanRecorded in this scope.')
        else
          kit.table(const [
            'Item',
            'Captured (UTC)',
            'Model version',
            'Experimental',
            'Quality',
            'Quality reasons',
            'AI predicted class',
            'AI confidence',
          ], scanRows),
        kit.heading('Inspections — human-verified findings'),
        if (inspectionRows.isEmpty)
          kit.empty('No inspections recorded in this scope.')
        else
          kit.table(const [
            'Item',
            'Inspected (UTC)',
            'Inspector',
            'Human-verified finding',
            'Observations',
            'Follow-up',
            'Linked scan (captured UTC)',
          ], inspectionRows),
      ],
    ),
  );
  return doc.save();
}

/// AI screening cells of a sack's latest scan, for the per-sack tables.
List<String> _latestScanCells(ReportItem sack) {
  final scan = sack.latestScan;
  if (scan == null) return ['', '', '', '', noScanRecorded, ''];
  return [
    utcStamp(scan.capturedAt),
    scan.modelVersion,
    yesNo(scan.experimental),
    qualityLabel(scan.quality),
    predictedClassLabel(scan),
    scan.confidence?.toStringAsFixed(3) ?? '',
  ];
}

const _latestScanHeaders = [
  'Scanned (UTC)',
  'Model version',
  'Experimental',
  'Quality',
  'AI predicted class',
  'AI confidence',
];

String _quantity(ReportItem sack) =>
    '${formatQuantity(sack.item.quantity)} ${sack.item.quantityUnit}';

/// Farmer pre-sale summary PDF. Per sack, the latest AI screening and the
/// latest physical inspection are in separate tables.
Future<Uint8List> renderPreSalePdf(
  PreSaleData data, [
  PdfKit kit = const PdfKit(),
]) {
  final doc = kit.document('Kernel pre-sale summary');
  final harvest = data.harvest;
  doc.addPage(
    kit.reportPages(
      footerNote: _cleanFooter,
      build: (context) => [
        kit.title('Kernel pre-sale summary'),
        pw.SizedBox(height: 6),
        kit.text(
          'Generated ${utcStamp(data.generatedAt)} (UTC) · '
          'Role: ${roleLabel(data.scope.role)} · '
          'Harvest: ${data.harvestLabel}',
        ),
        if (harvest != null)
          kit.text(
            'Harvested ${utcDate(harvest.harvestedAt)} (UTC) · '
            'Grain: ${harvest.grainType}'
            '${harvest.archivedAt == null ? '' : ' · Archived'}',
          ),
        ...kit.modelNote(data.modelNote),
        pw.SizedBox(height: 8),
        kit.notice('Disclaimer', [preSaleNotice, ...reportDisclaimer]),
        kit.heading('Summary'),
        kit.facts([
          ('Sacks', '${data.sacks.length}'),
          ('Sacks with a valid AI screening', '${data.screenedCount}'),
        ]),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: kit.table(
                const ['Latest AI screening (experimental)', 'Sacks'],
                [
                  for (final (label, n) in data.aiCounts) [label, '$n'],
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: kit.table(
                const ['Latest physical inspection (human-verified)', 'Sacks'],
                [
                  for (final (label, n) in data.humanCounts) [label, '$n'],
                ],
              ),
            ),
          ],
        ),
        ...kit.narrative(data.scope),
        kit.heading('Latest AI screening per sack (experimental)'),
        if (data.sacks.isEmpty)
          kit.empty('No sacks in this scope.')
        else
          kit.table(
            const ['Sack', 'Grain', 'Quantity', ..._latestScanHeaders],
            [
              for (final sack in data.sacks)
                [
                  sack.item.label,
                  sack.item.grainType,
                  _quantity(sack),
                  ..._latestScanCells(sack),
                ],
            ],
          ),
        kit.heading('Latest physical inspection per sack (human-verified)'),
        if (data.sacks.isEmpty)
          kit.empty('No sacks in this scope.')
        else
          kit.table(
            const [
              'Sack',
              'Inspected (UTC)',
              'Inspector',
              'Human-verified finding',
              'Follow-up',
            ],
            [
              for (final sack in data.sacks)
                switch (sack.latestInspection) {
                  null => [sack.item.label, '', '', notInspected, ''],
                  final inspection => [
                    sack.item.label,
                    utcStamp(inspection.inspectedAt),
                    inspection.inspector,
                    verifiedFindingLabel(inspection.verifiedFinding),
                    followUpLabel(inspection.followUpStatus),
                  ],
                },
            ],
          ),
      ],
    ),
  );
  return doc.save();
}

/// Buyer lot summary PDF. States that it is not an accept/reject decision
/// and shows the screening status a person set.
Future<Uint8List> renderLotSummaryPdf(
  LotSummaryData data, [
  PdfKit kit = const PdfKit(),
]) {
  final doc = kit.document('Kernel lot screening summary');
  final lot = data.lot;
  final total = data.sacks.length;
  final checks = [
    for (final sack in data.sacks)
      for (final inspection in sack.inspections)
        [
          sack.item.label,
          utcStamp(inspection.inspectedAt),
          inspection.inspector,
          verifiedFindingLabel(inspection.verifiedFinding),
          inspection.observations,
          followUpLabel(inspection.followUpStatus),
        ],
  ];
  doc.addPage(
    kit.reportPages(
      footerNote: 'Not an accept/reject decision. $_cleanFooter',
      build: (context) => [
        kit.title('Kernel lot screening summary'),
        pw.SizedBox(height: 6),
        kit.text(
          'Generated ${utcStamp(data.generatedAt)} (UTC) · '
          'Role: ${roleLabel(data.scope.role)}',
        ),
        pw.SizedBox(height: 8),
        kit.notice('Not an accept/reject decision', [lotDecisionNotice]),
        kit.heading('Lot'),
        kit.facts([
          ('Lot', lot.code),
          ('Supplier', lot.supplierName ?? ''),
          if (lot.supplierId != null) ('Supplier ID', lot.supplierId!),
          ('Grain', lot.grainType),
          (
            'Declared quantity',
            '${formatQuantity(lot.declaredQuantity)} ${lot.quantityUnit}',
          ),
          ('Received (UTC)', utcDate(lot.receivedAt)),
          (
            'Screening status (set by a person)',
            screeningStatusLabel(lot.screeningStatus),
          ),
          if (lot.archivedAt != null) ('Archived', 'yes'),
        ]),
        ...kit.modelNote(data.modelNote),
        kit.heading('Screening'),
        kit.facts([
          ('Sacks screened (valid scans)', '${data.screenedCount} of $total'),
          ('Sacks physically checked', '${data.checkedCount} of $total'),
          ('Physical checks', '${data.checkCount}'),
        ]),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: kit.table(
                const ['Latest AI screening (experimental)', 'Sacks'],
                [
                  for (final (label, n) in data.aiCounts) [label, '$n'],
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: kit.table(
                const ['Physical checks (human-verified)', 'Checks'],
                [
                  for (final (label, n) in data.findingCounts) [label, '$n'],
                ],
              ),
            ),
          ],
        ),
        ...kit.narrative(data.scope),
        kit.heading('Sacks — latest AI screening (experimental)'),
        if (data.sacks.isEmpty)
          kit.empty('No sacks in this lot.')
        else
          kit.table(
            const [
              'Sack',
              'Grain',
              'Quantity',
              'Screened',
              ..._latestScanHeaders,
            ],
            [
              for (final sack in data.sacks)
                [
                  sack.item.label,
                  sack.item.grainType,
                  _quantity(sack),
                  yesNo(sack.screened),
                  ..._latestScanCells(sack),
                ],
            ],
          ),
        kit.heading('Physical checks — human-verified findings'),
        if (checks.isEmpty)
          kit.empty('No physical checks recorded for this lot.')
        else
          kit.table(const [
            'Sack',
            'Inspected (UTC)',
            'Inspector',
            'Human-verified finding',
            'Observations',
            'Follow-up',
          ], checks),
        pw.SizedBox(height: 8),
        kit.notice('Disclaimer', reportDisclaimer),
      ],
    ),
  );
  return doc.save();
}

/// Labels per A4 page: 3 columns by 4 rows.
const sackLabelColumns = 3;
const sackLabelRows = 4;

/// Printable QR sack labels, A4 portrait. Each QR encodes
/// [SackLabel.payload]; the label text and grain type are printed below.
Future<Uint8List> renderSackLabelsPdf(
  List<SackLabel> labels, [
  PdfKit kit = const PdfKit(),
]) {
  final doc = kit.document('Kernel sack labels');
  const format = PdfPageFormat.a4;
  const margin = 24.0;
  const headerHeight = 24.0;
  const perPage = sackLabelColumns * sackLabelRows;
  final cellWidth = (format.width - 2 * margin) / sackLabelColumns;
  final cellHeight =
      (format.height - 2 * margin - headerHeight) / sackLabelRows;
  final qr = pw.Barcode.qrCode(
    errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
  );
  final pageCount = labels.isEmpty ? 1 : (labels.length / perPage).ceil();

  pw.Widget cell(SackLabel? label) => pw.Container(
    width: cellWidth,
    height: cellHeight,
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
    ),
    child: label == null
        ? null
        : pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.BarcodeWidget(
                barcode: qr,
                data: label.payload,
                width: 112,
                height: 112,
                drawText: false,
              ),
              pw.SizedBox(height: 6),
              kit.text(
                label.label,
                size: 11,
                bold: true,
                align: pw.TextAlign.center,
                maxLines: 2,
              ),
              kit.text(
                label.grainType,
                size: 9,
                align: pw.TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
  );

  for (var page = 0; page < pageCount; page++) {
    final chunk = labels.skip(page * perPage).take(perPage).toList();
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(margin),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              height: headerHeight,
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: kit.text(
                      labels.isEmpty
                          ? 'Kernel sack labels — no sacks in this scope.'
                          : 'Kernel sack labels — scan a code in the app to '
                                'open that sack.',
                    ),
                  ),
                  kit.text('Page ${page + 1} of $pageCount'),
                ],
              ),
            ),
            for (var row = 0; row < sackLabelRows; row++)
              if (row * sackLabelColumns < chunk.length)
                pw.Row(
                  children: [
                    for (var col = 0; col < sackLabelColumns; col++)
                      cell(
                        row * sackLabelColumns + col < chunk.length
                            ? chunk[row * sackLabelColumns + col]
                            : null,
                      ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
  return doc.save();
}

/// Maps text onto the Latin-1 range the built-in PDF fonts can draw. Used
/// only when no Unicode fonts are loaded.
String pdfSafe(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    switch (rune) {
      case 0x2013 || 0x2014:
        out.write('-');
      case 0x2018 || 0x2019:
        out.write("'");
      case 0x201C || 0x201D:
        out.write('"');
      case 0x2022:
        out.writeCharCode(0xB7);
      case <= 0xFF:
        out.writeCharCode(rune);
      default:
        out.write('?');
    }
  }
  return out.toString();
}
