import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../features/batch/batch_session_screen.dart';
import '../features/batch/batch_setup_screen.dart';
import '../features/harvest/harvest_detail_screen.dart';
import '../features/harvest/harvest_form_screen.dart';
import '../features/home/home_screen.dart';
import '../features/inspection/assigned_inspections_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/inspection/inspection_form_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/inventory/item_detail_screen.dart';
import '../features/inventory/item_form_screen.dart';
import '../features/inventory/location_detail_screen.dart';
import '../features/inventory/location_form_screen.dart';
import '../features/lots/lot_detail_screen.dart';
import '../features/lots/lot_form_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/qr/qr_scan_screen.dart';
import '../features/queue/queue_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/research/sample_label_screen.dart';
import '../features/research/samples_screen.dart';
import '../features/role/role_selection_screen.dart';
import '../features/scan/guided_scan_screen.dart';
import '../features/scan/result_screen.dart';
import '../features/scan/scan_tab_screen.dart';
import '../features/scan/scans_today_screen.dart';
import '../features/settings/diagnostics_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/start/start_screen.dart';
import 'data_providers.dart';
import 'routes.dart';

/// Pure redirect rule, kept separate so it is easy to reason about:
/// - while settings are unknown, stay on the start screen;
/// - onboarding not done (first launch) -> onboarding;
/// - no role yet -> role selection;
/// - role set -> leave start/onboarding/role screens for Home, unless the
///   user opened role selection on purpose to switch roles.
String? kernelRedirect(
  AsyncValue<Role?> activeRole,
  Uri location, {
  AsyncValue<bool> onboardingDone = const AsyncData(true),
}) {
  final path = location.path;
  if (!activeRole.hasValue || !onboardingDone.hasValue) {
    return path == Routes.start ? null : Routes.start;
  }
  if (onboardingDone.value != true) {
    return path == Routes.onboarding ? null : Routes.onboarding;
  }
  final role = activeRole.value;
  if (role == null) return path == Routes.role ? null : Routes.role;
  if (path == Routes.start || path == Routes.onboarding) return Routes.home;
  if (path == Routes.role && location.queryParameters['switch'] != '1') {
    return Routes.home;
  }
  return null;
}

typedef _Gate = ({AsyncValue<Role?> role, AsyncValue<bool> onboarding});

final routerProvider = Provider<GoRouter>((ref) {
  final gate = ValueNotifier<_Gate>((
    role: const AsyncLoading(),
    onboarding: const AsyncLoading(),
  ));
  ref.listen<AsyncValue<Role?>>(
    activeRoleProvider,
    (_, next) => gate.value = (role: next, onboarding: gate.value.onboarding),
    fireImmediately: true,
  );
  ref.listen<AsyncValue<bool>>(
    onboardingDoneProvider,
    (_, next) => gate.value = (role: gate.value.role, onboarding: next),
    fireImmediately: true,
  );

  String id(GoRouterState s, String name) => s.pathParameters[name]!;
  String? q(GoRouterState s, String name) => s.uri.queryParameters[name];

  final router = GoRouter(
    initialLocation: Routes.start,
    refreshListenable: gate,
    redirect: (context, state) => kernelRedirect(
      gate.value.role,
      state.uri,
      onboardingDone: gate.value.onboarding,
    ),
    routes: [
      GoRoute(path: Routes.start, builder: (_, _) => const StartScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.role,
        builder: (_, s) =>
            RoleSelectionScreen(switching: q(s, 'switch') == '1'),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.scan,
                builder: (_, _) => const ScanTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.inventory,
                builder: (_, _) => const InventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.reports,
                builder: (_, s) => ReportsScreen(
                  presetKind: ReportsScreen.kindFromQuery(q(s, 'kind')),
                  harvestId: q(s, 'harvestId'),
                  lotId: q(s, 'lotId'),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'diagnostics',
            builder: (_, _) => const DiagnosticsScreen(),
          ),
          GoRoute(path: 'research', builder: (_, _) => const SamplesScreen()),
        ],
      ),
      GoRoute(path: Routes.queue, builder: (_, _) => const QueueScreen()),
      GoRoute(
        path: Routes.insights,
        builder: (_, _) => const InsightsScreen(),
      ),
      GoRoute(path: Routes.qr, builder: (_, _) => const QrScanScreen()),
      GoRoute(
        path: Routes.scansToday,
        builder: (_, _) => const ScansTodayScreen(),
      ),
      GoRoute(
        path: Routes.assignedInspections,
        builder: (_, _) => const AssignedInspectionsScreen(),
      ),
      GoRoute(
        path: Routes.batchSetup,
        builder: (_, _) => const BatchSetupScreen(),
        routes: [
          GoRoute(
            path: 'run',
            builder: (_, s) => BatchSessionScreen(
              locationId: q(s, 'locationId'),
              lotId: q(s, 'lotId'),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/items/new',
        builder: (_, s) => ItemFormScreen(
          locationId: q(s, 'locationId'),
          lotId: q(s, 'lotId'),
          harvestId: q(s, 'harvestId'),
        ),
      ),
      GoRoute(
        path: '/items/:itemId',
        builder: (_, s) => ItemDetailScreen(itemId: id(s, 'itemId')),
        routes: [
          GoRoute(
            path: 'scan',
            builder: (_, s) => GuidedScanScreen(itemId: id(s, 'itemId')),
          ),
          GoRoute(
            path: 'research',
            builder: (_, s) =>
                GuidedScanScreen(itemId: id(s, 'itemId'), research: true),
          ),
          GoRoute(
            path: 'scans/:scanId',
            builder: (_, s) => ResultScreen(
              itemId: id(s, 'itemId'),
              scanId: id(s, 'scanId'),
            ),
          ),
          GoRoute(
            path: 'inspect',
            builder: (_, s) => InspectionFormScreen(
              itemId: id(s, 'itemId'),
              scanId: q(s, 'scanId'),
            ),
          ),
          GoRoute(
            path: 'samples/:scanId',
            builder: (_, s) => SampleLabelScreen(
              itemId: id(s, 'itemId'),
              scanId: id(s, 'scanId'),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/locations/new',
        builder: (_, s) => LocationFormScreen(parentId: q(s, 'parentId')),
      ),
      GoRoute(
        path: '/locations/:locationId',
        builder: (_, s) =>
            LocationDetailScreen(locationId: id(s, 'locationId')),
      ),
      GoRoute(path: Routes.newLot, builder: (_, _) => const LotFormScreen()),
      GoRoute(
        path: '/lots/:lotId',
        builder: (_, s) => LotDetailScreen(lotId: id(s, 'lotId')),
      ),
      GoRoute(
        path: Routes.newHarvest,
        builder: (_, _) => const HarvestFormScreen(),
      ),
      GoRoute(
        path: '/harvests/:harvestId',
        builder: (_, s) => HarvestDetailScreen(harvestId: id(s, 'harvestId')),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
}, name: 'routerProvider');
