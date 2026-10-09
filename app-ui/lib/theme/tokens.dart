import 'package:flutter/painting.dart';

/// Colour tokens from docs/design-tokens.md.
///
/// Contrast (WCAG relative luminance), checked in test/theme_test.dart:
/// - ink on ivory ~13:1, ink on sage ~12:1, ink on amber ~6.5:1
/// - onForest (white) on forest ~9.7:1
/// - inkMuted on ivory ~8:1
abstract final class KernelColors {
  /// Primary: hero action cards, headings, primary buttons.
  static const Color forest = Color(0xFF234C38);

  /// Secondary cards and surfaces.
  static const Color sage = Color(0xFFE6EFE4);

  /// App background and tertiary cards.
  static const Color ivory = Color(0xFFF6F3E9);

  /// Attention: "Inspection needed", "Review due", warnings. Text on amber
  /// must be [ink], never white.
  static const Color amber = Color(0xFFD9A441);

  /// Text on forest.
  static const Color onForest = Color(0xFFFFFFFF);

  /// Body text on light surfaces.
  static const Color ink = Color(0xFF1B2A22);

  /// Secondary text on light surfaces.
  static const Color inkMuted = Color(0xFF3F4D45);

  /// Destructive actions and errors (white text on it).
  static const Color danger = Color(0xFF9B2C1F);

  /// Borders and dividers.
  static const Color outline = Color(0xFF6E7B72);
}

/// Spacing and size tokens.
abstract final class KernelSizes {
  /// Minimum touch target (dp).
  static const double minTouchTarget = 48;
  static const double gap = 12;
  static const double pagePadding = 16;
  static const double cardRadius = 16;
}
