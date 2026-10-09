import 'package:flutter/material.dart';

import 'tokens.dart';

/// Material 3 theme built from the Kernel design tokens.
ThemeData buildKernelTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: KernelColors.forest,
    onPrimary: KernelColors.onForest,
    primaryContainer: KernelColors.sage,
    onPrimaryContainer: KernelColors.ink,
    secondary: KernelColors.forest,
    onSecondary: KernelColors.onForest,
    secondaryContainer: KernelColors.sage,
    onSecondaryContainer: KernelColors.ink,
    tertiary: KernelColors.amber,
    onTertiary: KernelColors.ink,
    tertiaryContainer: KernelColors.amber,
    onTertiaryContainer: KernelColors.ink,
    error: KernelColors.danger,
    onError: KernelColors.onForest,
    surface: KernelColors.ivory,
    onSurface: KernelColors.ink,
    onSurfaceVariant: KernelColors.inkMuted,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: KernelColors.ivory,
    surfaceContainer: KernelColors.sage,
    surfaceContainerHigh: KernelColors.sage,
    surfaceContainerHighest: KernelColors.sage,
    outline: KernelColors.outline,
    outlineVariant: Color(0xFFC9D3C8),
  );

  const minButton = Size(
    KernelSizes.minTouchTarget,
    KernelSizes.minTouchTarget,
  );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    scaffoldBackgroundColor: KernelColors.ivory,
    textTheme: base.textTheme.apply(
      bodyColor: KernelColors.ink,
      displayColor: KernelColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: KernelColors.ivory,
      foregroundColor: KernelColors.forest,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: KernelColors.sage,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KernelSizes.cardRadius),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KernelColors.forest,
        foregroundColor: KernelColors.onForest,
        minimumSize: minButton,
        padding: buttonPadding,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KernelColors.forest,
        minimumSize: minButton,
        padding: buttonPadding,
        shape: buttonShape,
        side: const BorderSide(color: KernelColors.forest),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KernelColors.forest,
        minimumSize: minButton,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: minButton),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: KernelColors.sage,
      indicatorColor: KernelColors.amber,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: KernelColors.sage,
      selectedColor: KernelColors.forest,
      secondarySelectedColor: KernelColors.forest,
      labelStyle: const TextStyle(color: KernelColors.ink),
      secondaryLabelStyle: const TextStyle(color: KernelColors.onForest),
      side: const BorderSide(color: KernelColors.outline),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 8,
      iconColor: KernelColors.forest,
    ),
  );
}
