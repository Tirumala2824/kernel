import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

void main() {
  testWidgets('bottom nav: Scan tab picks an item, then guided scan', (
    tester,
  ) async {
    final env = TestEnv(role: Role.farmer);
    await env.addItem(label: 'Sack Z');
    await pumpKernelApp(tester, env);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Scan'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Guided acoustic scan'), findsOneWidget);

    await tapVisible(tester, find.text('Sack Z'));
    expect(find.text('Ready to listen'), findsOneWidget);
    expect(find.text('Wheat • Sack Z'), findsOneWidget);
  });

  testWidgets('Scan tab empty state offers one next action', (tester) async {
    final env = TestEnv(role: Role.household);
    await pumpKernelApp(tester, env, location: Routes.scan);
    expect(find.text('No containers yet'), findsOneWidget);
    expect(find.text('Add your first container'), findsOneWidget);
  });

  testWidgets('household home shows one card per container', (tester) async {
    final env = TestEnv(role: Role.household);
    final kitchen = await env.locations.create(
      const LocationDraft(type: LocationType.home, name: 'Kitchen'),
    );
    final bin = await env.addItem(
      role: Role.household,
      label: 'Steel bin',
      grain: 'Rice',
      locationId: kitchen.id,
    );
    await env.scans.record(retryOutcome(bin.id));
    await pumpKernelApp(tester, env);

    expect(find.text('Rice / Kitchen'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Stored \d+ days?$')), findsOneWidget);
    expect(find.text('Retry needed'), findsOneWidget);
    expect(
      find.text('No reminders scheduled. Open a container to set one.'),
      findsOneWidget,
    );

    await env.reminders.schedule(
      bin.id,
      DateTime.now().add(const Duration(days: 3)),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 reminder scheduled'), findsOneWidget);
  });

  testWidgets('inventory tab lists role items and opens detail', (
    tester,
  ) async {
    final env = TestEnv(role: Role.storageFpo);
    final north = await env.locations.create(
      const LocationDraft(type: LocationType.warehouse, name: 'North'),
    );
    await env.addItem(
      role: Role.storageFpo,
      label: 'S-1',
      locationId: north.id,
    );
    await env.addItem(role: Role.farmer, label: 'Not mine');
    await pumpKernelApp(tester, env, location: Routes.inventory);

    expect(find.text('Warehouse'), findsWidgets);
    expect(find.text('North'), findsOneWidget);
    expect(find.text('S-1'), findsOneWidget);
    expect(find.text('Not mine'), findsNothing);

    await tapVisible(tester, find.text('S-1'));
    expect(find.text('Scan history'), findsOneWidget);
    expect(find.text('North (Warehouse)'), findsOneWidget);
  });

  testWidgets('buyer inventory shows lots and sacks', (tester) async {
    final env = TestEnv(role: Role.buyer);
    await env.lots.create(
      LotDraft(
        code: 'L-5',
        grainType: 'Wheat',
        declaredQuantity: 3,
        quantityUnit: 'tonne',
        receivedAt: DateTime(2026, 10, 3),
      ),
    );
    await pumpKernelApp(tester, env, location: Routes.inventory);
    expect(find.text('L-5 / Wheat'), findsOneWidget);
    expect(find.text('No sacks yet'), findsOneWidget);
  });

  testWidgets('item form preselects a location passed in', (tester) async {
    final env = TestEnv(role: Role.household);
    final kitchen = await env.locations.create(
      const LocationDraft(type: LocationType.home, name: 'Kitchen'),
    );
    await pumpKernelApp(
      tester,
      env,
      location: Routes.newItem(locationId: kitchen.id),
    );
    expect(find.text('Kitchen (Home)'), findsOneWidget);
  });
}
