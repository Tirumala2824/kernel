import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/router.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/theme/kernel_theme.dart';
import 'package:kernel_app/theme/tokens.dart';
import 'package:kernel_app/widgets/kernel_card.dart';
import 'package:kernel_app/widgets/status_chip.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('Design tokens', () {
    test('token values match docs/design-tokens.md', () {
      expect(KernelColors.forest, const Color(0xFF234C38));
      expect(KernelColors.sage, const Color(0xFFE6EFE4));
      expect(KernelColors.ivory, const Color(0xFFF6F3E9));
      expect(KernelColors.amber, const Color(0xFFD9A441));
    });

    test('text colours meet 4.5:1 contrast on their surfaces', () {
      expect(contrast(KernelColors.ink, KernelColors.ivory), greaterThan(4.5));
      expect(contrast(KernelColors.ink, KernelColors.sage), greaterThan(4.5));
      expect(contrast(KernelColors.ink, KernelColors.amber), greaterThan(4.5));
      expect(
        contrast(KernelColors.onForest, KernelColors.forest),
        greaterThan(4.5),
      );
      expect(
        contrast(KernelColors.inkMuted, KernelColors.ivory),
        greaterThan(4.5),
      );
      expect(
        contrast(KernelColors.forest, KernelColors.sage),
        greaterThan(4.5),
      );
      expect(
        contrast(KernelColors.onForest, KernelColors.danger),
        greaterThan(4.5),
      );
    });

    test('theme uses Material 3 with padded tap targets', () {
      final theme = buildKernelTheme();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, KernelColors.forest);
      expect(theme.scaffoldBackgroundColor, KernelColors.ivory);
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('tappable cards meet the 48dp target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildKernelTheme(),
          home: Scaffold(
            body: Center(
              child: KernelCard(title: 'X', onTap: () {}),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(InkWell));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('Router redirect', () {
    test('waits on start, sends first run to role selection', () {
      expect(
        kernelRedirect(const AsyncLoading(), Uri.parse(Routes.home)),
        Routes.start,
      );
      expect(
        kernelRedirect(const AsyncData(null), Uri.parse(Routes.home)),
        Routes.role,
      );
      expect(
        kernelRedirect(const AsyncData(Role.farmer), Uri.parse(Routes.start)),
        Routes.home,
      );
      expect(
        kernelRedirect(const AsyncData(Role.farmer), Uri.parse(Routes.role)),
        Routes.home,
      );
      expect(
        kernelRedirect(
          const AsyncData(Role.farmer),
          Uri.parse(Routes.switchRole),
        ),
        isNull,
      );
    });
  });

  group('Visual system', () {
    test('every status chip pairs text and fill at >= 4.5:1', () {
      for (final tone in StatusTone.values) {
        final (bg, fg, _) = statusColors(tone);
        expect(contrast(fg, bg), greaterThan(4.5), reason: tone.name);
      }
    });

    test('tints and paper keep body text readable', () {
      expect(contrast(KernelColors.ink, KernelColors.paper), greaterThan(4.5));
      expect(
        contrast(KernelColors.inkMuted, KernelColors.paper),
        greaterThan(4.5),
      );
      expect(
        contrast(KernelColors.amberInk, KernelColors.amberSoft),
        greaterThan(4.5),
      );
      expect(
        contrast(KernelColors.forest, KernelColors.paper),
        greaterThan(4.5),
      );
      expect(
        contrast(KernelColors.onForest, KernelColors.forestDeep),
        greaterThan(4.5),
      );
      expect(
        contrast(KernelColors.onForest, KernelColors.forestSoft),
        greaterThan(4.5),
      );
      expect(contrast(KernelColors.ink, KernelColors.sageDeep), greaterThan(4.5));
    });

    test('theme uses the bundled Manrope type scale', () {
      final theme = buildKernelTheme();
      expect(theme.textTheme.bodyLarge?.fontFamily, kernelFontFamily);
      expect(theme.textTheme.headlineMedium?.fontWeight, FontWeight.w800);
      expect(KernelMotion.reveal, greaterThan(KernelMotion.fast));
      expect(KernelRadii.lg, greaterThan(KernelRadii.sm));
    });
  });

  final largeTextRoutes = <String, Future<String> Function(TestEnv)>{
    'guided scan': (env) async =>
        Routes.scanItem((await env.addItem(label: 'A long sack label')).id),
    'settings': (env) async => Routes.settings,
    'diagnostics': (env) async => Routes.diagnostics,
    'batch setup': (env) async => Routes.batchSetup,
    'qr': (env) async => Routes.qr,
  };
  for (final MapEntry(key: name, value: route) in largeTextRoutes.entries) {
    testWidgets('$name has no overflow at 200% font scale', (tester) async {
      final env = TestEnv(role: Role.storageFpo);
      final location = await route(env);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpKernelApp(tester, env, location: location);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('onboarding has no overflow at 200% font scale', (tester) async {
    final env = TestEnv(onboardingDone: false);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpKernelApp(tester, env);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final role in Role.values) {
    testWidgets('${role.name} home has no overflow at 200% font scale', (
      tester,
    ) async {
      final env = TestEnv(role: role);
      await env.addItem(role: role, label: 'A long label for scaling checks');
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpKernelApp(tester, env);
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);

      // Result screen at 200% as well.
      final item = env.items.items.single;
      final scan = await env.scans.record(notEvaluatedOutcome(item.id));
      routerOf(tester).go(Routes.result(item.id, scan.id));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Screening result'), findsOneWidget);
    });
  }
}
