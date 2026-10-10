import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/insights/insights_screen.dart';
import 'package:kernel_app/l10n/app_localizations.dart';
import 'package:kernel_app/theme/tokens.dart';
import 'package:kernel_app/widgets/bar_chart.dart';
import 'package:kernel_app/widgets/common.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

String? _barValue(WidgetTester tester, String id) =>
    tester.widget<Text>(find.byKey(Key('bar-value-$id'))).data;

/// A farmer with three sacks: one possible infestation and one clean scan
/// today, two RETRYs on the third, one clean scan 40 days ago, and two
/// inspections (one open, one done).
Future<TestEnv> _populated() async {
  final env = TestEnv(role: Role.farmer);
  final a = await env.addItem(label: 'Sack A');
  final b = await env.addItem(label: 'Sack B');
  final c = await env.addItem(label: 'Sack C');
  await env.scans.record(modelOutcome(a.id, Classification.infested));
  await env.scans.record(modelOutcome(b.id, Classification.clean));
  await env.scans.record(
    modelOutcome(
      b.id,
      Classification.clean,
      at: DateTime.now().subtract(const Duration(days: 40)),
    ),
  );
  await env.scans.record(
    retryOutcome(c.id, reasons: const [QualityReason.highNoise]),
  );
  await env.scans.record(
    retryOutcome(c.id, reasons: const [QualityReason.clipping]),
  );
  await env.addInspection(a.id, VerifiedFinding.inconclusive);
  await env.addInspection(
    b.id,
    VerifiedFinding.noneFound,
    status: FollowUpStatus.done,
  );
  return env;
}

void main() {
  test('bar colours keep contrast; text is never the only signal', () {
    expect(_contrast(barFillColor, barTrackColor), greaterThanOrEqualTo(3));
    expect(
      _contrast(barAttentionColor, barTrackColor),
      greaterThanOrEqualTo(3),
    );
    expect(
      _contrast(barTextColor, KernelColors.paper),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(barTextColor, KernelColors.ivory),
      greaterThanOrEqualTo(4.5),
    );
  });

  group('Insights', () {
    testWidgets('empty: no scans shows one next action', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await env.addItem(label: 'Sack A');
      await pumpKernelApp(tester, env, location: Routes.insights);

      final empty = find.byKey(const Key('insights-empty'));
      expect(empty, findsOneWidget);
      expect(find.text(en.insightsRatesEmpty), findsOneWidget);
      expect(
        find.descendant(of: empty, matching: find.byType(FilledButton)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('quality-empty')), findsOneWidget);
      expect(find.byKey(const Key('inspections-empty')), findsOneWidget);
      expect(find.text(en.staleNeverScanned), findsOneWidget);
      expect(find.byKey(const Key('stat-today')), findsOneWidget);
      // No invented figures.
      expect(find.byType(LabeledBarChart), findsNothing);

      await tapVisible(
        tester,
        find.descendant(of: empty, matching: find.byType(FilledButton)),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('no items: the stale list says so', (tester) async {
      final env = TestEnv(role: Role.buyer);
      await pumpKernelApp(tester, env, location: Routes.insights);
      expect(find.byKey(const Key('stale-empty')), findsOneWidget);
    });

    testWidgets('populated: rates, quality, inspections, stale items', (
      tester,
    ) async {
      final env = await _populated();
      await pumpKernelApp(tester, env, location: Routes.insights);

      expect(find.byKey(const Key('insights-experimental')), findsOneWidget);
      expect(find.text(en.insightsExperimentalNote), findsOneWidget);
      // Default window is 30 days: the 40-day-old scan is outside it.
      expect(_barValue(tester, 'infested'), en.insightsBarValue(1, 25));
      expect(_barValue(tester, 'clean'), en.insightsBarValue(1, 25));
      expect(_barValue(tester, 'retry'), en.insightsBarValue(2, 50));
      expect(_barValue(tester, 'notEvaluated'), en.insightsBarValue(0, 0));
      expect(find.text(en.insightsTotalScans(4)), findsOneWidget);
      // Labels in words next to every bar.
      expect(find.text(en.predictionInfested), findsWidgets);
      expect(find.text(en.insightsRetryLabel), findsOneWidget);

      expect(_barValue(tester, 'quality-highNoise'), en.insightsBarValue(1, 50));
      expect(_barValue(tester, 'quality-clipping'), en.insightsBarValue(1, 50));
      expect(find.text(en.qualityShortHighNoise), findsOneWidget);

      expect(_barValue(tester, 'open'), en.insightsBarValue(1, 50));
      expect(_barValue(tester, 'done'), en.insightsBarValue(1, 50));
      expect(find.text(en.insightsClosureRate(50)), findsOneWidget);

      expect(
        tester.widget<StatTile>(find.byKey(const Key('stat-today'))).value,
        '2',
      );
      // Never-scanned (only RETRYs) comes first among stale items.
      final stale = find.byKey(const Key('insights-stale'));
      expect(
        find.descendant(of: stale, matching: find.text(en.staleNeverScanned)),
        findsOneWidget,
      );
    });

    testWidgets('window selector re-reads the figures', (tester) async {
      final env = await _populated();
      await pumpKernelApp(tester, env, location: Routes.insights);
      expect(find.text(en.insightsTotalScans(4)), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('window-all')));
      expect(find.text(en.insightsTotalScans(5)), findsOneWidget);
      expect(_barValue(tester, 'clean'), en.insightsBarValue(2, 40));
      expect(env.analytics.filters.any((f) => f.window == null), isTrue);

      await tapVisible(tester, find.byKey(const Key('window-days7')));
      expect(find.text(en.insightsTotalScans(4)), findsOneWidget);
      expect(
        env.analytics.filters.any(
          (f) => f.window == const Duration(days: 7) && f.role == Role.farmer,
        ),
        isTrue,
      );
    });

    testWidgets('reached from Home and from Reports', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await env.addItem(label: 'Sack A');
      await pumpKernelApp(tester, env);
      await tapVisible(tester, find.byKey(const Key('open-insights')));
      expect(find.byType(InsightsScreen), findsOneWidget);

      routerOf(tester).go(Routes.reports);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('reports-insights')));
      expect(find.byType(InsightsScreen), findsOneWidget);
    });

    for (final code in ['en', 'ta', 'ml']) {
      testWidgets('$code: populated insights at 200% text', (tester) async {
        final env = await _populated();
        await env.settings.setLanguageTag(code);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpKernelApp(tester, env, location: Routes.insights);
        expect(tester.takeException(), isNull);
        final l = lookupAppLocalizations(Locale(code));
        expect(find.text(l.insightsTitle), findsWidgets);
        expect(find.text(l.insightsExperimentalNote), findsOneWidget);
      });
    }
  });
}
