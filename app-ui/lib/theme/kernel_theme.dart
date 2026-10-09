import 'package:flutter/material.dart';

import 'tokens.dart';

/// Kernel type scale (Manrope). Sizes are in logical pixels and scale with
/// the user's font size; nothing assumes a fixed line count.
TextTheme kernelTextTheme() {
  const ink = KernelColors.ink;
  TextStyle s(double size, double height, FontWeight weight, {double ls = 0}) =>
      TextStyle(
        fontFamily: kernelFontFamily,
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: ls,
        color: ink,
      );
  return TextTheme(
    displayLarge: s(44, 52, FontWeight.w800, ls: -0.8),
    displayMedium: s(36, 44, FontWeight.w800, ls: -0.6),
    displaySmall: s(30, 38, FontWeight.w800, ls: -0.4),
    headlineLarge: s(28, 36, FontWeight.w800, ls: -0.3),
    headlineMedium: s(25, 32, FontWeight.w800, ls: -0.2),
    headlineSmall: s(22, 29, FontWeight.w800, ls: -0.1),
    titleLarge: s(20, 27, FontWeight.w700),
    titleMedium: s(17, 24, FontWeight.w700),
    titleSmall: s(15, 21, FontWeight.w700),
    bodyLarge: s(16, 24, FontWeight.w500),
    bodyMedium: s(15, 22, FontWeight.w500),
    bodySmall: s(13, 19, FontWeight.w500),
    labelLarge: s(15, 20, FontWeight.w700, ls: 0.1),
    labelMedium: s(13, 18, FontWeight.w700, ls: 0.2),
    labelSmall: s(12, 16, FontWeight.w700, ls: 0.4),
  );
}

/// Material 3 theme built from the Kernel design tokens.
ThemeData buildKernelTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: KernelColors.forest,
    onPrimary: KernelColors.onForest,
    primaryContainer: KernelColors.sage,
    onPrimaryContainer: KernelColors.ink,
    secondary: KernelColors.forestSoft,
    onSecondary: KernelColors.onForest,
    secondaryContainer: KernelColors.sageDeep,
    onSecondaryContainer: KernelColors.ink,
    tertiary: KernelColors.amber,
    onTertiary: KernelColors.ink,
    tertiaryContainer: KernelColors.amberSoft,
    onTertiaryContainer: KernelColors.amberInk,
    error: KernelColors.danger,
    onError: KernelColors.onForest,
    errorContainer: KernelColors.dangerSoft,
    onErrorContainer: KernelColors.danger,
    surface: KernelColors.ivory,
    onSurface: KernelColors.ink,
    onSurfaceVariant: KernelColors.inkMuted,
    surfaceContainerLowest: KernelColors.paper,
    surfaceContainerLow: KernelColors.paper,
    surfaceContainer: KernelColors.ivory,
    surfaceContainerHigh: KernelColors.sage,
    surfaceContainerHighest: KernelColors.sage,
    outline: KernelColors.outline,
    outlineVariant: KernelColors.hairline,
  );

  final text = kernelTextTheme();
  const minButton = Size(KernelSizes.minTouchTarget, KernelSizes.buttonHeight);
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(KernelRadii.md),
  );
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  final inputRadius = BorderRadius.circular(KernelRadii.md);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kernelFontFamily,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    scaffoldBackgroundColor: KernelColors.ivory,
    textTheme: text,
    primaryTextTheme: text.apply(
      bodyColor: KernelColors.onForest,
      displayColor: KernelColors.onForest,
    ),
    iconTheme: const IconThemeData(color: KernelColors.forest, size: 24),
    appBarTheme: AppBarTheme(
      backgroundColor: KernelColors.ivory,
      foregroundColor: KernelColors.forest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: KernelSpace.lg,
      titleTextStyle: text.titleLarge?.copyWith(
        color: KernelColors.forest,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: KernelColors.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KernelRadii.lg),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KernelColors.forest,
        foregroundColor: KernelColors.onForest,
        disabledBackgroundColor: KernelColors.sageDeep,
        disabledForegroundColor: KernelColors.inkMuted,
        minimumSize: minButton,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KernelColors.forest,
        backgroundColor: KernelColors.paper,
        minimumSize: minButton,
        padding: buttonPadding,
        shape: buttonShape,
        side: const BorderSide(color: KernelColors.forest, width: 1.5),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KernelColors.forest,
        minimumSize: const Size(
          KernelSizes.minTouchTarget,
          KernelSizes.minTouchTarget,
        ),
        textStyle: text.labelLarge,
        shape: buttonShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(
          KernelSizes.minTouchTarget,
          KernelSizes.minTouchTarget,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KernelColors.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: text.bodyLarge?.copyWith(color: KernelColors.inkMuted),
      floatingLabelStyle: text.bodyMedium?.copyWith(
        color: KernelColors.forest,
        fontWeight: FontWeight.w700,
      ),
      helperStyle: text.bodySmall?.copyWith(color: KernelColors.inkMuted),
      helperMaxLines: 4,
      errorMaxLines: 4,
      border: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: const BorderSide(color: KernelColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: const BorderSide(color: KernelColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: const BorderSide(color: KernelColors.forest, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: const BorderSide(color: KernelColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: const BorderSide(color: KernelColors.danger, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KernelColors.paper,
      surfaceTintColor: Colors.transparent,
      indicatorColor: KernelColors.sageDeep,
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          color: states.contains(WidgetState.selected)
              ? KernelColors.forest
              : KernelColors.inkMuted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? KernelColors.forest
              : KernelColors.inkMuted,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: KernelColors.paper,
      selectedColor: KernelColors.forest,
      disabledColor: KernelColors.sage,
      checkmarkColor: KernelColors.onForest,
      labelStyle: text.labelLarge?.copyWith(color: KernelColors.ink),
      secondaryLabelStyle: text.labelLarge?.copyWith(
        color: KernelColors.onForest,
      ),
      side: const BorderSide(color: KernelColors.outline),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KernelColors.onForest
            : KernelColors.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KernelColors.forest
            : KernelColors.sage,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KernelColors.forest
            : KernelColors.outline,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KernelColors.forest
            : KernelColors.outline,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: KernelColors.forest,
      linearTrackColor: KernelColors.sageDeep,
      circularTrackColor: KernelColors.sageDeep,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: KernelColors.forestDeep,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: KernelColors.onForest,
      ),
      actionTextColor: KernelColors.amber,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KernelRadii.md),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: KernelColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KernelRadii.xl),
      ),
      titleTextStyle: text.titleLarge?.copyWith(color: KernelColors.ink),
      contentTextStyle: text.bodyLarge?.copyWith(color: KernelColors.ink),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: KernelColors.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: KernelColors.outline,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KernelRadii.xl),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: KernelColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KernelRadii.md),
      ),
      textStyle: text.bodyLarge,
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 10,
      iconColor: KernelColors.forest,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodyMedium?.copyWith(
        color: KernelColors.inkMuted,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KernelRadii.md),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: KernelColors.hairline,
      thickness: 1,
      space: 1,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: KernelColors.forest,
        selectedForegroundColor: KernelColors.onForest,
        foregroundColor: KernelColors.forest,
        side: const BorderSide(color: KernelColors.forest),
        minimumSize: const Size(
          KernelSizes.minTouchTarget,
          KernelSizes.minTouchTarget,
        ),
        textStyle: text.labelLarge,
      ),
    ),
  );
}
