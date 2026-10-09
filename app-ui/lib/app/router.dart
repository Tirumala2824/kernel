import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../features/home/home_screen.dart';
import '../features/inspection/inspection_form_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/inventory/item_detail_screen.dart';
import '../features/inventory/item_form_screen.dart';
import '../features/inventory/location_detail_screen.dart';
import '../features/inventory/location_form_screen.dart';
import '../features/lots/lot_detail_screen.dart';
import '../features/lots/lot_form_screen.dart';
import '../features/queue/queue_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/role/role_selection_screen.dart';
import '../features/scan/guided_scan_screen.dart';
import '../features/scan/result_screen.dart';
import '../features/scan/scan_tab_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/start/start_screen.dart';
import 'data_providers.dart';
import 'routes.dart';

/// Pure redirect rule, kept separate so it is easy to reason about:
/// - while the active role is unknown, stay on the start screen;
/// - no role yet (first run) -> role selection;
/// - role set -> leave start/role screens for Home, unless the user opened
///   role selection on purpose to switch roles.
String? kernelRedirect(AsyncValue<Role?> activeRole, Uri location) {
  final path = location.path;
  if (!activeRole.hasValue) {
    return path == Routes.start ? null : Routes.start;
  }
  final role = activeRole.value;
  if (role == null) return path == Routes.role ? null : Routes.role;
  if (path == Routes.start) return Routes.home;
  if (path == Routes.role && location.queryParameters['switch'] != '1') {
    return Routes.home;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final activeRole = ValueNotifier<AsyncValue<Role?>>(const AsyncLoading());
  ref.listen<AsyncValue<Role?>>(
    activeRoleProvider,
    (_, next) => activeRole.value = next,
    fireImmediately: true,
  );

  final router = GoRouter(
    initialLocation: Routes.start,
    refreshListenable: activeRole,
    redirect: (context, state) => kernelRedirect(activeRole.value, state.uri),
    routes: [
      GoRoute(path: Routes.start, builder: (_, _) => const StartScreen()),
      GoRoute(
        path: Routes.role,
        builder: (_, state) => RoleSelectionScreen(
          switching: state.uri.queryParameters['switch'] == '1',
        ),
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
                builder: (_, _) => const ReportsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.queue, builder: (_, _) => const QueueScreen()),
      GoRoute(
        path: '/items/new',
        builder: (_, state) => ItemFormScreen(
          locationId: state.uri.queryParameters['locationId'],
          lotId: state.uri.queryParameters['lotId'],
        ),
      ),
      GoRoute(
        path: '/items/:itemId',
        builder: (_, state) =>
            ItemDetailScreen(itemId: state.pathParameters['itemId']!),
        routes: [
          GoRoute(
            path: 'scan',
            builder: (_, state) =>
                GuidedScanScreen(itemId: state.pathParameters['itemId']!),
          ),
          GoRoute(
            path: 'scans/:scanId',
            builder: (_, state) => ResultScreen(
              itemId: state.pathParameters['itemId']!,
              scanId: state.pathParameters['scanId']!,
            ),
          ),
          GoRoute(
            path: 'inspect',
            builder: (_, state) => InspectionFormScreen(
              itemId: state.pathParameters['itemId']!,
              scanId: state.uri.queryParameters['scanId'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/locations/new',
        builder: (_, state) =>
            LocationFormScreen(parentId: state.uri.queryParameters['parentId']),
      ),
      GoRoute(
        path: '/locations/:locationId',
        builder: (_, state) => LocationDetailScreen(
          locationId: state.pathParameters['locationId']!,
        ),
      ),
      GoRoute(path: Routes.newLot, builder: (_, _) => const LotFormScreen()),
      GoRoute(
        path: '/lots/:lotId',
        builder: (_, state) =>
            LotDetailScreen(lotId: state.pathParameters['lotId']!),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    activeRole.dispose();
  });
  return router;
}, name: 'routerProvider');
