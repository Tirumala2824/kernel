// Test harness: builds KernelApp over in-memory test doubles.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_app/app/kernel_app.dart';
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_app/app/router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'in_memory.dart';

class TestEnv {
  TestEnv({Role? role, this.offline = true})
    : settings = InMemorySettingsRepository(activeRole: role) {
    ranking = InMemoryRankingService(items, scans);
    privacy = RecordingPrivacyService(
      onDelete: () {
        scans.clear();
        inspections.clear();
        reminders.clear();
      },
    );
  }

  final bool offline;
  final InMemorySettingsRepository settings;
  final items = InMemoryItemRepository();
  final locations = InMemoryLocationRepository();
  final lots = InMemoryLotRepository();
  final scans = InMemoryScanRepository();
  final inspections = InMemoryInspectionRepository();
  final reminders = InMemoryReminderRepository();
  late final InMemoryRankingService ranking;
  final reports = RecordingReportService();
  late final RecordingPrivacyService privacy;
  final engine = ScriptedScanEngine();
  final permissions = ScriptedPermissions();
  final sharer = RecordingSharer();
  final feedback = RecordingFeedback();

  List<Override> get overrides => [
    scanEngineProvider.overrideWithValue(engine),
    itemRepositoryProvider.overrideWithValue(items),
    locationRepositoryProvider.overrideWithValue(locations),
    lotRepositoryProvider.overrideWithValue(lots),
    scanRepositoryProvider.overrideWithValue(scans),
    inspectionRepositoryProvider.overrideWithValue(inspections),
    reminderRepositoryProvider.overrideWithValue(reminders),
    settingsRepositoryProvider.overrideWithValue(settings),
    rankingServiceProvider.overrideWithValue(ranking),
    reportServiceProvider.overrideWithValue(reports),
    privacyServiceProvider.overrideWithValue(privacy),
    connectivityResultsProvider.overrideWith(
      (ref) => Stream.value([
        offline ? ConnectivityResult.none : ConnectivityResult.wifi,
      ]),
    ),
    devicePermissionsProvider.overrideWithValue(permissions),
    reportSharerProvider.overrideWithValue(sharer),
    scanFeedbackProvider.overrideWithValue(feedback),
  ];

  Future<GrainItem> addItem({
    Role role = Role.farmer,
    String label = 'Sack A',
    String grain = 'Wheat',
    String? locationId,
    String? lotId,
  }) => items.create(
    GrainItemDraft(
      ownerRole: role,
      label: label,
      grainType: grain,
      quantity: 50,
      quantityUnit: 'kg',
      storageDate: DateTime(2026, 9, 1),
      locationId: locationId,
      lotId: lotId,
    ),
  );
}

/// Pumps the full app at phone width (360 dp). The viewport is tall
/// (2000 dp) so lazily built list sections exist without scrolling.
Future<void> pumpKernelApp(
  WidgetTester tester,
  TestEnv env, {
  String? location,
}) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(overrides: env.overrides, child: const KernelApp()),
  );
  await tester.pumpAndSettle();
  if (location != null) {
    routerOf(tester).go(location);
    await tester.pumpAndSettle();
  }
}

GoRouter routerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(KernelApp)))
        .read(routerProvider);

/// Brings an already-built widget on screen, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
