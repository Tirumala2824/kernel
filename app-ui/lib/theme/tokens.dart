import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Colour tokens from docs/design-tokens.md plus the tints derived from them.
///
/// Contrast (WCAG relative luminance), checked in test/theme_test.dart:
/// - ink on ivory ~13:1, ink on sage ~12:1, ink on amber ~6.5:1
/// - onForest (white) on forest ~9.7:1, amberInk on amberSoft > 7:1
/// - inkMuted on ivory and on paper > 7:1
abstract final class KernelColors {
  /// Primary: hero action cards, headings, primary buttons.
  static const Color forest = Color(0xFF234C38);

  /// Deeper forest for the hero gradient and pressed states.
  static const Color forestDeep = Color(0xFF183828);

  /// Lighter forest facet (the left half of the brand kernel).
  static const Color forestSoft = Color(0xFF2E6249);

  /// Secondary cards and surfaces.
  static const Color sage = Color(0xFFE6EFE4);

  /// Sage one step darker: selected navigation, dividers on sage.
  static const Color sageDeep = Color(0xFFCFDECB);

  /// App background and tertiary cards.
  static const Color ivory = Color(0xFFF6F3E9);

  /// Elevated cards and inputs on the ivory background.
  static const Color paper = Color(0xFFFFFDF8);

  /// Attention: "Inspection needed", "Review due", warnings. Text on amber
  /// must be [ink], never white.
  static const Color amber = Color(0xFFD9A441);

  /// Amber tint for attention chips and banners.
  static const Color amberSoft = Color(0xFFF6E6C2);

  /// Text and icons on [amberSoft].
  static const Color amberInk = Color(0xFF5A3E06);

  /// Text on forest.
  static const Color onForest = Color(0xFFFFFFFF);

  /// Body text on light surfaces.
  static const Color ink = Color(0xFF1B2A22);

  /// Secondary text on light surfaces.
  static const Color inkMuted = Color(0xFF3F4D45);

  /// Destructive actions and errors (white text on it).
  static const Color danger = Color(0xFF9B2C1F);

  /// Tint for error notes.
  static const Color dangerSoft = Color(0xFFF7E3DE);

  /// Borders on interactive elements (>= 3:1 against ivory).
  static const Color outline = Color(0xFF6E7B72);

  /// Decorative hairlines only (never the sole boundary of a control).
  static const Color hairline = Color(0xFFDCE2D8);
}

/// 4-pt spacing scale.
abstract final class KernelSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal page margin.
  static const double page = 20;
}

abstract final class KernelRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

/// Soft, forest-tinted shadows. Elevation is expressed by blur and offset,
/// never by heavy grey shadows.
abstract final class KernelShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F183828), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A183828), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> lifted = [
    BoxShadow(color: Color(0x1A183828), blurRadius: 28, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0D183828), blurRadius: 6, offset: Offset(0, 2)),
  ];
}

/// Motion durations and curves. Decorative motion is skipped when the
/// platform asks for reduced motion (MediaQuery.disableAnimations).
abstract final class KernelMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration reveal = Duration(milliseconds: 700);

  /// One cycle of the listening-rings motif.
  static const Duration ringCycle = Duration(milliseconds: 2600);

  /// Pause on a batch result before moving to the next sack.
  static const Duration batchAdvance = Duration(seconds: 3);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
  static const Curve gentle = Curves.easeInOutSine;
}

/// Size tokens.
abstract final class KernelSizes {
  /// Minimum touch target (dp).
  static const double minTouchTarget = 48;

  /// Primary button height.
  static const double buttonHeight = 52;
  static const double gap = KernelSpace.md;
  static const double pagePadding = KernelSpace.page;
  static const double cardRadius = KernelRadii.lg;
}

/// Brand typeface (bundled, OFL). Indic scripts fall back to the system's
/// Noto fonts, so nothing is fetched at runtime.
const String kernelFontFamily = 'Manrope';
