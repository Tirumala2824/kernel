import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

void main() {
  group('Reports tab', () {
    testWidgets('exports CSV for the role scope and shares the file', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.reports);

      expect(find.text('Pre-sale report'), findsWidgets);
      await tapVisible(tester, find.byKey(const Key('export-csv')));

      final (scope, format) = env.reports.calls.single;
      expect(scope.role, Role.farmer);
      expect(format, ReportFormat.csv);
      expect(env.sharer.shared, [
        '/data/user/0/com.kernel.kernel_app/files/report.csv',
      ]);
    });

    testWidgets('shows an error when export fails', (tester) async {
      final env = TestEnv(role: Role.storageFpo);
      env.reports.failWith = StateError('disk full');
      await pumpKernelApp(tester, env, location: Routes.reports);

      await tapVisible(tester, find.byKey(const Key('export-pdf')));

      expect(env.reports.calls.single.$2, ReportFormat.pdf);
      expect(find.textContaining('could not be created'), findsOneWidget);
      expect(find.textContaining('disk full'), findsOneWidget);
      expect(env.sharer.shared, isEmpty);
    });

    testWidgets('recent scans list only this role and show provenance', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final mine = await env.addItem(label: 'Mine');
      final other = await env.addItem(role: Role.buyer, label: 'Theirs');
      await env.scans.record(notEvaluatedOutcome(mine.id));
      await env.scans.record(notEvaluatedOutcome(other.id));
      await pumpKernelApp(tester, env, location: Routes.reports);

      expect(find.textContaining('Mine ·'), findsOneWidget);
      expect(find.textContaining('Theirs'), findsNothing);
      expect(find.text('Model: none — Not evaluated'), findsOneWidget);
    });
  });

  group('Settings', () {
    testWidgets('retain-audio opt-in is off by default and toggles', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.settings);

      final toggle = find.byKey(const Key('retain-audio'));
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(find.textContaining('never uploaded'), findsWidgets);

      await tapVisible(tester, toggle);
      expect(env.settings.retainAudio, isTrue);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    });

    testWidgets('delete all history asks for confirmation first', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      await env.scans.record(notEvaluatedOutcome(item.id));
      await pumpKernelApp(tester, env, location: Routes.settings);

      await tapVisible(tester, find.byKey(const Key('delete-history')));
      expect(find.text('Delete all history?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(env.privacy.deleteCalls, 0);

      await tapVisible(tester, find.byKey(const Key('delete-history')));
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();
      expect(env.privacy.deleteCalls, 1);
      expect(env.scans.scans, isEmpty);
      // Items are kept.
      expect(env.items.items, hasLength(1));
      expect(find.text('All history deleted'), findsOneWidget);
    });

    testWidgets('shows engine provenance when no model is installed', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.settings);
      expect(find.text('Model: none — Not evaluated'), findsOneWidget);
      expect(find.textContaining('No model is installed'), findsOneWidget);
    });
  });
}
