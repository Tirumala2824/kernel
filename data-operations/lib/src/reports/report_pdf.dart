import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_data.dart';

/// PDF bytes. AI predictions and human-verified findings are separate
/// tables; the disclaimer is shown up front and in every page footer.
///
/// Uses the built-in PDF fonts, which cover Latin-1 only, so other
/// characters are replaced (see [pdfSafe]). The CSV keeps full UTF-8.
Future<Uint8List> renderPdf(ReportData data) {
  final doc = pw.Document(
    title: 'Kernel grain screening report',
    creator: 'Kernel',
  );
  final small = pw.TextStyle(fontSize: 8);
  final header = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);

  pw.Widget table(List<String> headers, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: [for (final h in headers) pdfSafe(h)],
        data: [
          for (final row in rows) [for (final cell in row) pdfSafe(cell)],
        ],
        headerStyle: header,
        cellStyle: small,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        cellPadding: const pw.EdgeInsets.all(3),
        headerAlignment: pw.Alignment.centerLeft,
      );

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
    child: pw.Text(
      pdfSafe(text),
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
  );

  pw.Widget empty(String text) => pw.Text(pdfSafe(text), style: small);

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
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                pdfSafe(
                  'A "Clean" result is not a guarantee. Physical inspection '
                  'is required for decisions.',
                ),
                style: small,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: small,
            ),
          ],
        ),
      ),
      build: (context) => [
        pw.Text(
          'Kernel grain screening report',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          pdfSafe(
            'Generated ${utcStamp(data.generatedAt)} (UTC) · '
            'Role: ${roleLabel(data.scope.role)} · '
            'Location: ${data.locationLabel ?? 'All'} · '
            'Lot: ${data.lotLabel ?? 'All'}',
          ),
          style: small,
        ),
        pw.Text(
          'Items: ${data.items.length} · Scans: ${data.scanCount} · '
          'Inspections: ${data.inspectionCount}',
          style: small,
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Disclaimer', style: header),
              for (final line in reportDisclaimer)
                pw.Text(pdfSafe(line), style: small),
            ],
          ),
        ),
        heading('Items'),
        if (data.items.isEmpty)
          empty('No items in this scope.')
        else
          table(
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
        heading('Scans — AI predictions (experimental)'),
        if (scanRows.isEmpty)
          empty('$noScanRecorded in this scope.')
        else
          table(const [
            'Item',
            'Captured (UTC)',
            'Model version',
            'Experimental',
            'Quality',
            'Quality reasons',
            'AI predicted class',
            'AI confidence',
          ], scanRows),
        heading('Inspections — human-verified findings'),
        if (inspectionRows.isEmpty)
          empty('No inspections recorded in this scope.')
        else
          table(const [
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

/// Maps text onto the Latin-1 range the built-in PDF fonts can draw.
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
