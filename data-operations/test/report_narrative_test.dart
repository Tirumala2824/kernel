import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:data_operations/src/reports/report_data.dart';
import 'package:data_operations/src/reports/report_fonts.dart';
import 'package:data_operations/src/reports/report_pdf.dart';
import 'package:data_operations/src/services/report_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/csv.dart';
import 'support/harness.dart';

/// Test-only draft text, standing in for what the on-phone model returned.
const _draftText =
    'Kharif sacks look steady overall.\n\nRescan Sack B soon, then '
    'confirm by hand.';

AdviceText _draft({
  String text = _draftText,
  bool complete = true,
  String modelVersion = 'gemma-test-e2b',
}) => AdviceText(
  text: text,
  complete: complete,
  modelVersion: modelVersion,
  languageTag: 'en',
  generatedAt: DateTime.utc(2026, 10, 1, 7, 30),
);

ReportScope _withNarrative(ReportScope scope, AdviceText? narrative) =>
    ReportScope(
      role: scope.role,
      kind: scope.kind,
      locationId: scope.locationId,
      lotId: scope.lotId,
      harvestId: scope.harvestId,
      itemIds: scope.itemIds,
      narrative: narrative,
    );

/// Words drawn with the built-in fonts of an uncompressed PDF, in order.
List<String> pdfWords(List<int> bytes) => [
  for (final m in RegExp(
    r'\[\(((?:\\.|[^\\)])*)\)\]TJ',
  ).allMatches(latin1.decode(bytes)))
    m.group(1)!.replaceAllMapped(RegExp(r'\\(.)'), (x) => x.group(1)!),
];

/// The report kit with the bundled fonts, recording every string it draws
/// in document order (the build callbacks create widgets in that order).
class RecordingKit extends PdfKit {
  RecordingKit(ReportFonts fonts) : super(fonts: fonts, compress: false);

  final drawn = <String>[];

  @override
  String t(String text) {
    drawn.add(text);
    return super.t(text);
  }
}

void main() {
  late Harness h;
  late Harvest harvest;
  late Lot lot;

  setUp(() async {
    h = await Harness.create();
    harvest = await h.addHarvest(name: 'Kharif');
    lot = await h.addLot(code: 'LOT-9');
    final a = await h.addItem(label: 'Sack A', harvestId: harvest.id);
    final b = await h.addItem(label: 'Sack B', harvestId: harvest.id);
    await h.recordModelScan(a.id, Classification.clean);
    await h.recordScan(
      b.id,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.highNoise],
    );
    await h.addInspection(a.id, VerifiedFinding.noneFound);
    final bought = await h.addItem(
      role: Role.buyer,
      label: 'Lot sack',
      lotId: lot.id,
    );
    await h.recordModelScan(bought.id, Classification.uncertain);
    await h.addInspection(bought.id, VerifiedFinding.inconclusive);
  });
  tearDown(() => h.dispose());

  DriftReportService service() => h.ops.reports as DriftReportService;

  ReportScope history() => ReportScope(role: Role.farmer);
  ReportScope preSale() => ReportScope(
    role: Role.farmer,
    kind: ReportKind.preSale,
    harvestId: harvest.id,
  );
  ReportScope lotSummary() =>
      ReportScope(role: Role.buyer, kind: ReportKind.lotSummary, lotId: lot.id);

  Future<ParsedCsv> csv(ReportScope scope) async =>
      readCsv(await h.ops.reports.export(scope, ReportFormat.csv));

  Future<List<int>> render(ReportScope scope, PdfKit kit) async {
    final s = service();
    return switch (scope.kind) {
      ReportKind.history => await renderPdf(await s.load(scope), kit),
      ReportKind.preSale => await renderPreSalePdf(
        await s.loadPreSale(scope),
        kit,
      ),
      ReportKind.lotSummary => await renderLotSummaryPdf(
        await s.loadLotSummary(scope),
        kit,
      ),
      ReportKind.sackLabels => await renderSackLabelsPdf(
        await s.loadSackLabels(scope),
        kit,
      ),
    };
  }

  /// Words of a history PDF drawn with the built-in fonts (the pre-sale and
  /// lot summary layouts need the Unicode fonts to lay out in debug mode).
  Future<List<String>> words(ReportScope scope) async =>
      pdfWords(await render(scope, const PdfKit(compress: false)));

  Future<RecordingKit> recordingKit() async =>
      RecordingKit(await ReportFonts.load(diskReportFont));

  group('CSV', () {
    test('a complete narrative adds header-block lines only', () async {
      for (final scope in [history(), preSale(), lotSummary()]) {
        final plain = await csv(scope);
        final included = await csv(_withNarrative(scope, _draft()));
        expect(included.preambleValue('narrative_model'), 'gemma-test-e2b');
        expect(included.preambleValue('narrative_experimental'), 'yes');
        expect(included.preambleValue('narrative_text'), _draftText);
        // Placed in the header block, after the disclaimers.
        final keys = [for (final r in included.preamble) r.isEmpty ? '' : r[0]];
        expect(
          keys.indexOf('narrative_model'),
          greaterThan(keys.lastIndexOf('Disclaimer')),
        );
        expect(
          included.preamble.where(
            (r) => r.isNotEmpty && r[0].startsWith('narr'),
          ),
          hasLength(3),
        );
        // Records and findings are untouched.
        expect(included.header, plain.header);
        expect(included.rows, plain.rows);
        for (final row in included.rows) {
          expect(row.values.any((v) => v.contains('steady')), isFalse);
        }
        // Everything else in the preamble is as before.
        expect([
          for (final r in included.preamble)
            if (r.isEmpty || !r[0].startsWith('narrative_')) r,
        ], plain.preamble);
      }
    });

    test('narrative text and model are guarded against formula '
        'injection', () async {
      final parsed = await csv(
        _withNarrative(
          history(),
          _draft(text: '=HYPERLINK("x")', modelVersion: '+model'),
        ),
      );
      expect(parsed.preambleValue('narrative_text'), "'=HYPERLINK(\"x\")");
      expect(parsed.preambleValue('narrative_model'), "'+model");
      final dash = await csv(
        _withNarrative(history(), _draft(text: '-1 sacks', modelVersion: 'm')),
      );
      expect(dash.preambleValue('narrative_text'), "'-1 sacks");
    });

    test('an absent, incomplete or blank narrative leaves the CSV as '
        'today', () async {
      for (final scope in [history(), preSale(), lotSummary()]) {
        final plain = await csv(scope);
        for (final narrative in [
          null,
          _draft(complete: false),
          _draft(text: '  \n '),
        ]) {
          final other = await csv(_withNarrative(scope, narrative));
          expect(other.preamble, plain.preamble);
          expect(other.header, plain.header);
          expect(other.rows, plain.rows);
        }
      }
    });
  });

  group('PDF', () {
    test('a complete narrative is its own labelled section after the '
        'summary and before the records, in the report fonts', () async {
      // (scope, last summary text, first record heading)
      final cases = [
        (history(), reportDisclaimer.last, 'Items'),
        (
          preSale(),
          'Latest physical inspection (human-verified)',
          'Latest AI screening per sack (experimental)',
        ),
        (
          lotSummary(),
          'Physical checks (human-verified)',
          'Sacks — latest AI screening (experimental)',
        ),
      ];
      for (final (scope, summaryEnd, recordsStart) in cases) {
        final kit = await recordingKit();
        await render(_withNarrative(scope, _draft()), kit);
        final s = kit.drawn;
        final title = s.indexOf(narrativeTitle);
        expect(title, greaterThan(0), reason: '${scope.kind}');
        expect(s.sublist(title, title + 4), [
          'Drafted on this phone',
          'By gemma-test-e2b — experimental. Not a record or a decision; '
              'check before sharing.',
          'Kharif sacks look steady overall.',
          'Rescan Sack B soon, then confirm by hand.',
        ]);
        expect(s.where((x) => x.contains('steady')), hasLength(1));
        expect(s.indexOf(summaryEnd), lessThan(title), reason: summaryEnd);
        expect(s.indexOf(recordsStart), title + 4, reason: recordsStart);
      }
    });

    test('an absent or incomplete narrative leaves the PDF as today', () async {
      for (final scope in [
        history(),
        preSale(),
        lotSummary(),
        ReportScope(role: Role.farmer, kind: ReportKind.sackLabels),
      ]) {
        Future<List<String>> drawn(AdviceText? narrative) async {
          final kit = await recordingKit();
          await render(_withNarrative(scope, narrative), kit);
          return kit.drawn;
        }

        final plain = await drawn(null);
        expect(plain, isNot(contains(narrativeTitle)));
        expect(await drawn(_draft(complete: false)), plain);
        expect(await drawn(_draft(text: ' \n')), plain);
        if (scope.kind == ReportKind.sackLabels) {
          // Labels never carry a narrative.
          expect(await drawn(_draft()), plain);
        }
      }
      // Byte-level check on the built-in font path.
      expect(
        await words(_withNarrative(history(), _draft(complete: false))),
        await words(history()),
      );
    });

    test('the built-in font path draws the section too', () async {
      final w = await words(_withNarrative(history(), _draft()));
      final title = w.indexOf('Drafted');
      expect(w.sublist(title, title + 6), [
        'Drafted',
        'on',
        'this',
        'phone',
        'By',
        'gemma-test-e2b',
      ]);
      // The em dash becomes "-" without Unicode fonts.
      expect(w[title + 6], '-');
      expect(w.indexOf('steady'), greaterThan(title));
      expect(w.indexOf('Items'), greaterThan(w.indexOf('Rescan')));
    });

    test('the narrative is drawn with the report fonts, including Indian '
        'scripts', () async {
      final prints = <String>[];
      await runZoned(
        () async {
          for (final scope in [history(), preSale(), lotSummary()]) {
            final path = await h.ops.reports.export(
              _withNarrative(
                scope,
                _draft(text: 'बोरी B को फिर से जाँचें।\nகோதுமை நன்றாக உள்ளது'),
              ),
              ReportFormat.pdf,
            );
            final bytes = File(path).readAsBytesSync();
            expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
          }
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => prints.add(line),
        ),
      );
      expect(prints.where((l) => l.contains('Unable to find a font')), isEmpty);
    });

    test('a long narrative continues across pages', () async {
      final long = List.generate(
        120,
        (i) => 'Paragraph $i about storage checks on this phone.',
      ).join('\n');
      final w = await words(_withNarrative(history(), _draft(text: long)));
      expect(w.where((x) => x == 'Paragraph'), hasLength(120));
      expect(w.indexOf('Items'), greaterThan(w.lastIndexOf('Paragraph')));
    });
  });

  test('includedNarrative ignores absent, incomplete and blank drafts', () {
    expect(includedNarrative(history()), isNull);
    expect(
      includedNarrative(_withNarrative(history(), _draft(complete: false))),
      isNull,
    );
    expect(
      includedNarrative(_withNarrative(history(), _draft(text: '\n'))),
      isNull,
    );
    expect(includedNarrative(_withNarrative(history(), _draft())), isNotNull);
    expect(
      narrativeByLine(_draft(modelVersion: ' ')),
      startsWith('By an unknown model — experimental.'),
    );
  });
}
