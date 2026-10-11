import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/data_providers.dart';
import 'package:kernel_app/features/inspection/assigned_inspections_screen.dart';
import 'package:kernel_app/l10n/l10n.dart';
import 'package:kernel_app/widgets/common.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

class _AssignedData {
  final env = TestEnv(role: Role.storageFpo);
  final role = StreamController<Role?>.broadcast();
  final items = StreamController<List<GrainItem>>.broadcast();
  final inspections = StreamController<List<Inspection>>.broadcast();

  Future<ProviderContainer> pump(WidgetTester tester) async {
    addTearDown(role.close);
    addTearDown(items.close);
    addTearDown(inspections.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides,
          activeRoleProvider.overrideWith((ref) => role.stream),
          itemsByRoleProvider(Role.storageFpo)
              .overrideWith((ref) => items.stream),
          openInspectionsProvider.overrideWith((ref) => inspections.stream),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AssignedInspectionsScreen(),
        ),
      ),
    );
    await tester.pump();
    return ProviderScope.containerOf(
      tester.element(find.byType(AssignedInspectionsScreen)),
    );
  }
}

void _expectNoSummary() {
  expect(find.text(en.assignedNone), findsNothing);
  expect(find.text(en.inspectionsOpen(0)), findsNothing);
  expect(find.byKey(const Key('filter-all')), findsNothing);
}

void main() {
  testWidgets('pending and failed items cannot hide loaded inspections', (
    tester,
  ) async {
    final data = _AssignedData();
    final item = await data.env.addItem(role: Role.storageFpo);
    final task = await data.env.addInspection(
      item.id,
      VerifiedFinding.inconclusive,
    );
    await data.pump(tester);
    data.role.add(Role.storageFpo);
    data.inspections.add([task]);
    await tester.pump();
    await tester.pump();

    _expectNoSummary();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    data.items.addError(StateError('items unavailable'));
    await tester.pump();
    await tester.pump();
    _expectNoSummary();
    expect(find.byType(ErrorNote), findsOneWidget);

    data.items.add([]);
    await tester.pumpAndSettle();
    expect(find.text(en.assignedNone), findsOneWidget);
    expect(find.text(en.inspectionsOpen(0)), findsOneWidget);

    data.items.add([item]);
    await tester.pumpAndSettle();
    expect(find.byKey(Key('task-${task.id}')), findsOneWidget);
    expect(find.text(en.inspectionsOpen(1)), findsOneWidget);

    data.items.addError(StateError('items failed after data'));
    await tester.pump();
    await tester.pump();
    _expectNoSummary();
    expect(find.byType(ErrorNote), findsOneWidget);
    expect(find.byKey(Key('task-${task.id}')), findsNothing);
  });
}
