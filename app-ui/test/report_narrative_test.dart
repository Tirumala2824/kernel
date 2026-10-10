import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

Future<TestEnv> _env({bool advice = true}) async {
  final env = TestEnv(role: Role.farmer);
  final a = await env.addItem(label: 'Sack A');
  await env.addItem(label: 'Sack B');
  await env.scans.record(notEvaluatedOutcome(a.id));
  if (advice) await env.enableAdvice();
  return env;
}

void main() {
  group('AI-drafted report summary', () {
    testWidgets('no switch while the assistant is off', (tester) async {
      final env = await _env(advice: false);
      await pumpKernelApp(tester, env, location: Routes.reports);
      expect(find.byKey(const Key('ai-summary')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('export-csv')));
      expect(env.reports.calls.single.$1.narrative, isNull);
      expect(env.analytics.summarizeCalls, isEmpty);
      expect(env.advice.narrativeCalls, isEmpty);
    });

    testWidgets('sack labels never offer a summary', (tester) async {
      final env = await _env();
      await pumpKernelApp(tester, env, location: Routes.reports);
      expect(find.byKey(const Key('ai-summary')), findsOneWidget);
      expect(find.byKey(const Key('ai-summary-sackLabels')), findsNothing);
    });

    testWidgets('include: summarize, draft, preview, then export with it', (
      tester,
    ) async {
      final env = await _env();
      env.advice.narrativeScript = adviceEvents([
        'Two sacks are registered.',
        'One was scanned; no model result yet.',
      ]);
      await pumpKernelApp(tester, env, location: Routes.reports);

      final toggle = find.byKey(const Key('ai-summary'));
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tapVisible(tester, toggle);
      await tapVisible(tester, find.byKey(const Key('export-csv')));

      // Preview first; nothing exported yet.
      expect(find.byKey(const Key('narrative-preview')), findsOneWidget);
      expect(env.reports.calls, isEmpty);
      const text =
          'Two sacks are registered. One was scanned; no model result yet.';
      expect(find.text(text), findsOneWidget);
      expect(
        find.text(en.adviceProvenance(testAdviceModelVersion)),
        findsOneWidget,
      );
      expect(find.text(en.adviceNotDecision), findsOneWidget);
      // No editing: the draft is plain text, not a field.
      expect(
        find.descendant(
          of: find.byKey(const Key('narrative-preview')),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );

      final summaryScope = env.analytics.summarizeCalls.single;
      expect(summaryScope.role, Role.farmer);
      expect(summaryScope.kind, ReportKind.history);
      final (input, tag) = env.advice.narrativeCalls.single;
      expect(tag, 'en');
      expect(input.role, Role.farmer);
      expect(input.kind, ReportKind.history);
      expect(input.summary.items, 2);
      expect(input.summary.rates.notEvaluated, 1);

      await tapVisible(tester, find.byKey(const Key('narrative-include')));
      final (scope, format) = env.reports.calls.single;
      expect(format, ReportFormat.csv);
      expect(scope.role, Role.farmer);
      expect(scope.narrative?.text, text);
      expect(scope.narrative?.modelVersion, testAdviceModelVersion);
      expect(scope.narrative?.experimental, isTrue);
      expect(env.sharer.shared, hasLength(1));
    });

    testWidgets('skip exports without the summary', (tester) async {
      final env = await _env();
      env.advice.narrativeScript = adviceEvents(['A draft.']);
      await pumpKernelApp(tester, env, location: Routes.reports);
      await tapVisible(tester, find.byKey(const Key('ai-summary')));
      await tapVisible(tester, find.byKey(const Key('export-pdf')));
      expect(find.byKey(const Key('narrative-preview')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('narrative-skip')));
      expect(find.byKey(const Key('narrative-preview')), findsNothing);
      final (scope, format) = env.reports.calls.single;
      expect(format, ReportFormat.pdf);
      expect(scope.narrative, isNull);
    });

    testWidgets('include waits for a complete draft', (tester) async {
      final env = await _env();
      env.advice.narrativeScript = adviceEvents(['Half a'], complete: false);
      await pumpKernelApp(tester, env, location: Routes.reports);
      await tapVisible(tester, find.byKey(const Key('ai-summary')));
      await tapVisible(tester, find.byKey(const Key('export-csv')));
      // No complete draft: the preview closes by itself and the report is
      // exported as usual, without an error.
      expect(find.byKey(const Key('narrative-preview')), findsNothing);
      expect(env.reports.calls.single.$1.narrative, isNull);
      expect(find.textContaining('could not be created'), findsNothing);
    });

    testWidgets('pre-sale preset in Reports carries the harvest scope', (
      tester,
    ) async {
      final env = await _env();
      final harvest = await env.harvests.create(
        HarvestDraft(
          name: 'Rabi 2026',
          grainType: 'Wheat',
          harvestedAt: DateTime(2026, 4, 1),
        ),
      );
      env.advice.narrativeScript = adviceEvents(['Pre-sale draft.']);
      await pumpKernelApp(
        tester,
        env,
        location: Routes.reportPreset(
          ReportKind.preSale,
          harvestId: harvest.id,
        ),
      );
      expect(find.byKey(const Key('report-preset')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('ai-summary-preSale')));
      await tapVisible(tester, find.byKey(const Key('export-preSale-pdf')));
      await tapVisible(tester, find.byKey(const Key('narrative-include')));
      final (scope, _) = env.reports.calls.single;
      expect(scope.kind, ReportKind.preSale);
      expect(scope.harvestId, harvest.id);
      expect(scope.narrative?.text, 'Pre-sale draft.');
      expect(env.analytics.summarizeCalls.single.harvestId, harvest.id);
    });
  });
}
