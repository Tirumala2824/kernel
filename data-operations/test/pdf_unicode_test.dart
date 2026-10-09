import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:data_operations/src/reports/report_data.dart';
import 'package:data_operations/src/reports/report_fonts.dart';
import 'package:data_operations/src/reports/report_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';

import 'support/harness.dart';

/// Words in each bundled script (sample text only, never stored).
const scriptSamples = <String, String>{
  'Devanagari': 'गेहूं की बोरी क्षेत्र',
  'Bengali': 'গমের বস্তা',
  'Telugu': 'గోధుమ బస్తా',
  'Tamil': 'கோதுமை மூட்டை',
  'Gujarati': 'ઘઉંની થેલી',
  'Kannada': 'ಗೋಧಿ ಚೀಲ',
  'Malayalam': 'ഗോതമ്പ് ചാക്ക്',
  'Oriya': 'ଗହମ ବସ୍ତା',
  'Gurmukhi': 'ਕਣਕ ਦੀ ਬੋਰੀ',
  'Latin and symbols': 'Sack R-004 · “Clean” — café ₹ 50 kg',
};

/// Runs [body] and returns everything it printed. The pdf package prints
/// "Unable to find a font to draw ..." (debug builds) when it falls back to
/// a placeholder box for a character.
Future<List<String>> capturePrints(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  late ReportFonts fonts;

  setUpAll(() async => fonts = await ReportFonts.load(diskReportFont));

  test('every character of each bundled script has a glyph in the font '
      'chain', () {
    final chain = [
      for (final family in reportFontFamilies)
        TtfParser(
          File(p.join('assets', 'fonts', reportFontFile(family, bold: false)))
              .readAsBytesSync()
              .buffer
              .asByteData(),
        ),
    ];
    for (final MapEntry(key: script, value: text) in scriptSamples.entries) {
      for (final rune in text.runes) {
        if (rune == 0x20) continue;
        expect(
          chain.any((font) => font.charToGlyphIndexMap.containsKey(rune)),
          isTrue,
          reason: '$script U+${rune.toRadixString(16)}',
        );
      }
    }
  });

  test('bold fonts cover the same scripts', () {
    for (final family in reportFontFamilies) {
      final regular = TtfParser(
        File(p.join('assets', 'fonts', reportFontFile(family, bold: false)))
            .readAsBytesSync()
            .buffer
            .asByteData(),
      );
      final bold = TtfParser(
        File(p.join('assets', 'fonts', reportFontFile(family, bold: true)))
            .readAsBytesSync()
            .buffer
            .asByteData(),
      );
      expect(bold.fontName, contains('Bold'), reason: family);
      expect(
        bold.charToGlyphIndexMap.keys.toSet(),
        containsAll(
          regular.charToGlyphIndexMap.keys.where((r) => r >= 0x0900).toSet(),
        ),
        reason: family,
      );
    }
  });

  test('Devanagari and mixed-script text renders with the Noto fonts, no '
      'placeholder and no "?" substitution', () async {
    final labels = [
      for (final entry in scriptSamples.entries)
        SackLabel(itemId: entry.key, label: entry.value, grainType: 'गेहूं'),
    ];
    late List<int> bytes;
    final prints = await capturePrints(() async {
      bytes = await renderSackLabelsPdf(
        labels,
        PdfKit(fonts: fonts, compress: false),
      );
    });
    expect(prints.where((l) => l.contains('Unable to find a font')), isEmpty);
    final pdf = latin1.decode(bytes);
    expect(pdf, contains('NotoSansDevanagari'));
    expect(pdf, contains('NotoSansTamil'));
    expect(pdf, contains('NotoSansGurmukhi'));
    // The ToUnicode map lists the Devanagari code points that were drawn.
    expect(pdf.toLowerCase(), contains('0917'), reason: 'ग');
    expect(pdf.toLowerCase(), contains('0939'), reason: 'ह');

    // With fonts the text is passed through unchanged.
    final kit = PdfKit(fonts: fonts);
    expect(kit.t('गेहूं'), 'गेहूं');
  });

  test('every report kind renders Indian-script user text', () async {
    final h = await Harness.create();
    addTearDown(h.dispose);
    final harvest = await h.addHarvest(name: 'रबी 2026', grainType: 'गेहूं');
    final item = await h.addItem(
      label: 'बोरी ১ ಚೀಲ',
      grainType: 'గోధుమ',
      harvestId: harvest.id,
    );
    await h.recordScan(item.id);
    await h.ops.inspections.create(
      InspectionDraft(
        itemId: item.id,
        inspectedAt: DateTime.utc(2026, 10, 1),
        inspector: 'ਰਵੀ',
        observations: 'கோதுமை நன்றாக உள்ளது',
        verifiedFinding: VerifiedFinding.noneFound,
      ),
    );
    final prints = await capturePrints(() async {
      for (final kind in [
        ReportKind.history,
        ReportKind.preSale,
        ReportKind.sackLabels,
      ]) {
        final path = await h.ops.reports.export(
          ReportScope(role: Role.farmer, kind: kind, harvestId: harvest.id),
          ReportFormat.pdf,
        );
        expect(File(path).lengthSync(), greaterThan(1000));
      }
    });
    expect(prints.where((l) => l.contains('Unable to find a font')), isEmpty);
  });

  test('a script outside the bundle is reported, proving the check above '
      'can fail', () async {
    final prints = await capturePrints(() async {
      await renderSackLabelsPdf(const [
        SackLabel(itemId: 'x', label: '小麦', grainType: 'Wheat'),
      ], PdfKit(fonts: fonts, compress: false));
    });
    expect(
      prints.where((l) => l.contains('Unable to find a font')),
      isNotEmpty,
    );
  });

  test(
    'without injected fonts the built-in Latin-1 path is still used',
    () async {
      final kit = const PdfKit(compress: false);
      expect(kit.t('गेहूं'), '?????');
      final bytes = await renderSackLabelsPdf(const [
        SackLabel(itemId: 'x', label: 'Sack', grainType: 'Wheat'),
      ], kit);
      expect(latin1.decode(bytes), isNot(contains('NotoSans')));
    },
  );
}
