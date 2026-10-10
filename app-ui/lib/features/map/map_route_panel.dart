import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import 'routes_client.dart';

enum RouteProblem { needsLocation, failed }

String formatRouteDistance(AppLocalizations l, int meters) => meters >= 1000
    ? l.mapDistanceKm((meters / 1000).toStringAsFixed(1))
    : l.mapDistanceM(meters);

int etaMinutes(Duration d) => d.inSeconds <= 0 ? 0 : (d.inSeconds / 60).ceil();

/// Selected sighting: route from here, distance and ETA, and the hand-off
/// to Google Maps for turn-by-turn walking navigation.
class MapRoutePanel extends StatelessWidget {
  const MapRoutePanel({
    super.key,
    required this.title,
    required this.route,
    required this.routing,
    required this.problem,
    required this.navigationFailed,
    required this.onRoute,
    required this.onNavigate,
  });

  final String title;
  final RouteSummary? route;
  final bool routing;
  final RouteProblem? problem;
  final bool navigationFailed;
  final VoidCallback onRoute;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final route = this.route;
    return Container(
      key: const Key('map-route-panel'),
      padding: const EdgeInsets.all(KernelSpace.lg),
      decoration: BoxDecoration(
        color: KernelColors.paper,
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        border: Border.all(color: KernelColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: KernelColors.forest,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: KernelSpace.sm),
          if (route != null) ...[
            Text(
              l.mapRouteSummary(
                formatRouteDistance(l, route.distanceMeters),
                etaMinutes(route.duration),
              ),
              key: const Key('map-route-summary'),
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: KernelSpace.sm),
          ],
          if (problem != null) ...[
            ErrorNote(
              problem == RouteProblem.needsLocation
                  ? l.mapRouteNeedsLocation
                  : l.mapRouteFailed,
            ),
            const SizedBox(height: KernelSpace.sm),
          ],
          ActionWrap(
            children: [
              OutlinedButton.icon(
                key: const Key('map-route'),
                onPressed: routing ? null : onRoute,
                icon: const Icon(Icons.route_rounded),
                label: Text(routing ? l.mapRouting : l.mapRoute),
              ),
              FilledButton.icon(
                key: const Key('map-navigate'),
                onPressed: onNavigate,
                icon: const Icon(Icons.directions_walk_rounded),
                label: Text(l.mapStartNavigation),
              ),
            ],
          ),
          if (navigationFailed) ...[
            const SizedBox(height: KernelSpace.sm),
            ErrorNote(l.mapNavigationFailed),
          ],
        ],
      ),
    );
  }
}
