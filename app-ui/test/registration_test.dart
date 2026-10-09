import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  group('Item registration (F02)', () {
    testWidgets('validates required fields and does not save', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.newItem());

      await tapVisible(tester, find.byKey(const Key('save')));

      expect(find.text('Enter a label'), findsOneWidget);
      expect(find.text('Enter the grain type'), findsOneWidget);
      expect(find.text('Enter the quantity'), findsOneWidget);
      expect(env.items.items, isEmpty);
    });

    testWidgets('rejects a zero or non-numeric quantity', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.newItem());

      await tester.enterText(find.byKey(const Key('field-label')), 'R-004');
      await tester.enterText(find.byKey(const Key('field-grain')), 'Wheat');
      await tester.enterText(find.byKey(const Key('field-quantity')), '0');
      await tapVisible(tester, find.byKey(const Key('save')));
      expect(find.text('Enter a number above 0'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('field-quantity')), 'abc');
      await tapVisible(tester, find.byKey(const Key('save')));
      expect(find.text('Enter a number above 0'), findsOneWidget);
      expect(env.items.items, isEmpty);
    });

    testWidgets('saves a sack for the active role and opens its detail', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final store = await env.locations.create(
        const LocationDraft(type: LocationType.home, name: 'Back store'),
      );
      await pumpKernelApp(
        tester,
        env,
        location: Routes.newItem(locationId: store.id),
      );

      await tester.enterText(find.byKey(const Key('field-label')), 'R-004');
      await tester.enterText(find.byKey(const Key('field-grain')), 'Wheat');
      await tester.enterText(find.byKey(const Key('field-quantity')), '48,5');
      await tapVisible(tester, find.byKey(const Key('save')));

      expect(env.items.items, hasLength(1));
      final saved = env.items.items.single;
      expect(saved.ownerRole, Role.farmer);
      expect(saved.label, 'R-004');
      expect(saved.grainType, 'Wheat');
      expect(saved.quantity, 48.5);
      expect(saved.quantityUnit, 'kg');
      expect(saved.locationId, store.id);
      expect(saved.lotId, isNull);

      // Detail screen with an empty, immutable history.
      expect(find.text('Scan history'), findsOneWidget);
      expect(find.textContaining('No scans yet'), findsOneWidget);
      expect(find.text('Back store (Home)'), findsOneWidget);
    });

    testWidgets('household registers a container', (tester) async {
      final env = TestEnv(role: Role.household);
      await pumpKernelApp(tester, env, location: Routes.newItem());
      expect(find.text('Add container'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('field-label')), 'Steel bin');
      await tester.enterText(find.byKey(const Key('field-grain')), 'Rice');
      await tester.enterText(find.byKey(const Key('field-quantity')), '20');
      await tapVisible(tester, find.byKey(const Key('save')));

      expect(env.items.items.single.ownerRole, Role.household);
    });
  });

  group('Location registration', () {
    testWidgets('saves a room inside a warehouse', (tester) async {
      final env = TestEnv(role: Role.storageFpo);
      final warehouse = await env.locations.create(
        const LocationDraft(type: LocationType.warehouse, name: 'North'),
      );
      await pumpKernelApp(
        tester,
        env,
        location: Routes.newLocation(parentId: warehouse.id),
      );

      // Parent is a warehouse, so the type defaults to room.
      expect(find.text('Room'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('save')));
      expect(find.text('Enter a name'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('field-name')), 'Room 2');
      await tapVisible(tester, find.byKey(const Key('save')));

      final saved = env.locations.locations.last;
      expect(saved.name, 'Room 2');
      expect(saved.type, LocationType.room);
      expect(saved.parentId, warehouse.id);
      expect(find.text('Room 2'), findsWidgets);
    });
  });

  group('Lot registration (Buyer)', () {
    testWidgets('validates and saves a delivery', (tester) async {
      final env = TestEnv(role: Role.buyer);
      await pumpKernelApp(tester, env, location: Routes.newLot);

      await tapVisible(tester, find.byKey(const Key('save')));
      expect(find.text('Enter the lot code'), findsOneWidget);
      expect(env.lots.lots, isEmpty);

      await tester.enterText(find.byKey(const Key('field-code')), 'LOT-9');
      await tester.enterText(find.byKey(const Key('field-supplier')), 'Coop A');
      await tester.enterText(find.byKey(const Key('field-grain')), 'Maize');
      await tester.enterText(find.byKey(const Key('field-quantity')), '12');
      await tapVisible(tester, find.byKey(const Key('save')));

      final lot = env.lots.lots.single;
      expect(lot.code, 'LOT-9');
      expect(lot.supplierName, 'Coop A');
      expect(lot.grainType, 'Maize');
      expect(lot.declaredQuantity, 12);
      expect(lot.screeningStatus, ScreeningStatus.pending);

      // Lot detail: human-set status, no accept/reject actions.
      expect(find.text('Screening status'), findsOneWidget);
      expect(
        find.textContaining(RegExp('accept', caseSensitive: false)),
        findsOneWidget,
      ); // only the explanatory "never accepts" sentence
      expect(find.widgetWithText(FilledButton, 'Accept'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Reject'), findsNothing);
    });

    testWidgets('screening status changes only by a person', (tester) async {
      final env = TestEnv(role: Role.buyer);
      final lot = await env.lots.create(
        LotDraft(
          code: 'LOT-1',
          grainType: 'Rice',
          declaredQuantity: 5,
          quantityUnit: 'tonne',
          receivedAt: DateTime(2026, 10, 2),
        ),
      );
      await pumpKernelApp(tester, env, location: Routes.lot(lot.id));

      await tapVisible(
        tester,
        find.byKey(const Key('status-needsPhysicalCheck')),
      );
      expect(
        env.lots.lots.single.screeningStatus,
        ScreeningStatus.needsPhysicalCheck,
      );
      expect(find.text('Current: Pending physical check'), findsOneWidget);
    });
  });
}
