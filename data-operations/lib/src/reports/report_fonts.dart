import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Loads the bytes of one bundled font file, e.g. `NotoSans-Regular.ttf`.
/// Production reads the package assets ([bundledReportFont]); tests inject
/// the bytes.
typedef ReportFontLoader = Future<ByteData> Function(String fontFile);

/// Noto Sans families bundled in `assets/fonts/` (SIL OFL 1.1, see OFL.txt).
/// The first is the base font (Latin, Greek, Cyrillic); the rest are
/// fallbacks for Indian scripts, tried in this order.
const reportFontFamilies = <String>[
  'NotoSans',
  'NotoSansDevanagari',
  'NotoSansBengali',
  'NotoSansTelugu',
  'NotoSansTamil',
  'NotoSansGujarati',
  'NotoSansKannada',
  'NotoSansMalayalam',
  'NotoSansOriya',
  'NotoSansGurmukhi',
];

/// File name of a bundled font.
String reportFontFile(String family, {required bool bold}) =>
    '$family-${bold ? 'Bold' : 'Regular'}.ttf';

/// Asset key prefix of the bundled fonts as seen from the app.
const bundledFontAssetPrefix = 'packages/data_operations/assets/fonts/';

/// Asset key of the bundled font licence.
const bundledFontLicenseAsset = '${bundledFontAssetPrefix}OFL.txt';

/// [ReportFontLoader] reading the package assets through rootBundle.
Future<ByteData> bundledReportFont(String fontFile) =>
    rootBundle.load('$bundledFontAssetPrefix$fontFile');

/// Unicode report fonts: a base font plus per-script fallbacks, in regular
/// and bold. The pdf package picks, per character, the first font that has
/// a glyph for it.
class ReportFonts {
  ReportFonts._(
    this.regular,
    this.bold,
    this.regularFallback,
    this.boldFallback,
  );

  /// Loads and parses every font in [reportFontFamilies].
  static Future<ReportFonts> load(ReportFontLoader loader) async {
    Future<List<pw.Font>> weight({required bool bold}) async => [
      for (final family in reportFontFamilies)
        pw.Font.ttf(await loader(reportFontFile(family, bold: bold))),
    ];
    final regular = await weight(bold: false);
    final bold = await weight(bold: true);
    return ReportFonts._(
      regular.first,
      bold.first,
      List.unmodifiable(regular.skip(1)),
      List.unmodifiable(bold.skip(1)),
    );
  }

  final pw.Font regular;
  final pw.Font bold;
  final List<pw.Font> regularFallback;
  final List<pw.Font> boldFallback;
}
