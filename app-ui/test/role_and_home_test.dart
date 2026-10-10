import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  group('Role selection (F01)', () {
    testWidgets('first run shows role selection with wireframe copy', (
      tester,
    ) async {
      final env = TestEnv();
      await pumpKernelApp(tester, env);

      expect(find.text('Select your role'), findsOneWidget);
      expect(find.text('One app. Four workflows.'), findsOneWidget);
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('Harvest and pre-sale checks'), findsOneWidget);
      expect(find.text('Household'), findsOneWidget);
      expect(find.text('Containers and reminders'), findsOneWidget);
      expect(find.text('Storage/FPO'), findsOneWidget);
      expect(find.text('Warehouse and batch inspections'), findsOneWidget);
      expect(find.text('Buyer'), findsOneWidget);
      expect(find.text('Supplier and lot screening'), findsOneWidget);
      // No bottom nav before a role exists.
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('choosing a role persists it and opens that home', (
      tester,
    ) async {
      final env = TestEnv();
      await pumpKernelApp(tester, env);

      await tester.tap(find.byKey(const Key('role-farmer')));
      await tester.pumpAndSettle();

      expect(env.settings.roleWrites, [Role.farmer]);
      expect(find.text('Farmer dashboard'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('My Grain'), findsOneWidget);
    });

    testWidgets('switching role keeps records and relabels navigation', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await env.addItem(label: 'Sack R-1');
      await pumpKernelApp(tester, env);
      expect(find.text('1 registered sack'), findsOneWidget);

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch role'));
      await tester.pumpAndSettle();
      expect(find.text('Select your role'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('role-buyer')));
      expect(find.text('Incoming lots'), findsOneWidget);
      expect(find.text('Lots'), findsWidgets);

      // Back to farmer: the earlier record is still there.
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch role'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('role-farmer')));
      expect(env.items.items, hasLength(1));
      expect(find.text('1 registered sack'), findsOneWidget);
    });
  });

  group('Role home empty states', () {
    final cases = <Role, (String title, String empty, String nav)>{
      Role.farmer: ('Farmer dashboard', 'No sacks yet', 'My Grain'),
      Role.household: (
        'Household storage',
        'No containers yet',
        'My Containers',
      ),
      Role.storageFpo: ('Warehouse overview', 'No sacks yet', 'Warehouse'),
      Role.buyer: ('Incoming lots', 'No lots yet', 'Lots'),
    };

    for (final MapEntry(key: role, value: (title, empty, nav))
        in cases.entries) {
      testWidgets('${role.name} home shows a real empty state', (tester) async {
        final env = TestEnv(role: role);
        await pumpKernelApp(tester, env);

        expect(find.text(title), findsOneWidget);
        expect(find.text(empty), findsOneWidget);
        // Exactly one next action in the empty state.
        final emptyCard = find.byKey(
          Key(role == Role.buyer ? 'empty-lots' : 'empty-items'),
        );
        expect(emptyCard, findsOneWidget);
        expect(
          find.descendant(of: emptyCard, matching: find.byType(FilledButton)),
          findsOneWidget,
        );
        // Role-specific Inventory label in the bottom nav.
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(nav),
          ),
          findsOneWidget,
        );
        // No counts are invented when nothing is stored.
        expect(
          find.textContaining(RegExp(r'\b[1-9]\d* registered')),
          findsNothing,
        );
      });
    }

    testWidgets('empty-state action opens the registration form', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env);
      await tester.tap(find.text('Register your first sack'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('field-label')), findsOneWidget);
    });
  });

  group('Home counts come from repository streams', () {
    testWidgets('farmer count and follow-ups update live', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final a = await env.addItem(label: 'Sack A');
      await env.addItem(label: 'Sack B');
      // An item owned by another role is not counted.
      await env.addItem(role: Role.buyer, label: 'Other');
      await pumpKernelApp(tester, env);

      expect(find.text('2 registered sacks'), findsOneWidget);
      expect(find.text('No follow-up inspections open'), findsOneWidget);

      await env.inspections.create(
        InspectionDraft(
          itemId: a.id,
          inspectedAt: DateTime.now(),
          inspector: 'R. Devi',
          observations: '',
          verifiedFinding: VerifiedFinding.inconclusive,
        ),
      );
      await env.addItem(label: 'Sack C');
      await tester.pumpAndSettle();
      expect(find.text('3 registered sacks'), findsOneWidget);
      expect(find.text('1 sack requires follow-up inspection'), findsOneWidget);
    });

    testWidgets('FPO queue puts unscanned sacks under needs scan', (
      tester,
    ) async {
      final env = TestEnv(role: Role.storageFpo);
      await env.addItem(role: Role.storageFpo, label: 'S-1');
      await env.addItem(role: Role.storageFpo, label: 'S-2');
      await pumpKernelApp(tester, env);

      expect(find.text('2 registered sacks'), findsOneWidget);
      expect(find.text('No scans today'), findsOneWidget);
      expect(find.text('0 flagged · 2 sacks need a scan'), findsOneWidget);
    });

    testWidgets('buyer lot card shows screened count from ranking', (
      tester,
    ) async {
      final env = TestEnv(role: Role.buyer);
      final lot = await env.lots.create(
        LotDraft(
          code: 'L-77',
          grainType: 'Rice',
          declaredQuantity: 10,
          quantityUnit: 'tonne',
          receivedAt: DateTime(2026, 10, 1),
          supplierName: 'Coop',
        ),
      );
      await env.addItem(role: Role.buyer, label: 'B-1', lotId: lot.id);
      await pumpKernelApp(tester, env);

      expect(find.text('L-77 / Rice'), findsOneWidget);
      expect(find.text('0 of 1 sack screened'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });
  });

  testWidgets('offline indicator is shown in the app bar', (tester) async {
    final env = TestEnv(role: Role.farmer);
    await pumpKernelApp(tester, env);
    expect(find.byKey(const Key('offline-indicator')), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('online state is informational only', (tester) async {
    final env = TestEnv(role: Role.farmer, offline: false);
    await pumpKernelApp(tester, env);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Farmer dashboard'), findsOneWidget);
  });
}
