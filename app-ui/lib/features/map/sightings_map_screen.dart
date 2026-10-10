import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../pest_id/pest_platform.dart';
import '../pest_id/pest_providers.dart';
import '../pest_id/sightings_screen.dart';
import 'map_launcher.dart';
import 'map_route_panel.dart';
import 'map_view.dart';
import 'maps_config.dart';
import 'maps_consent.dart';
import 'routes_client.dart';

GeoPoint? sightingPoint(Sighting s) => s.latitude == null || s.longitude == null
    ? null
    : GeoPoint(s.latitude!, s.longitude!);

/// Sighting pins with accuracy circles, a walking route and the Google
/// Maps hand-off. Nothing reaches Google until maps consent is given, and
/// then only the map view and the route endpoints.
class SightingsMapScreen extends ConsumerStatefulWidget {
  const SightingsMapScreen({super.key, this.sightingId});

  final String? sightingId;

  @override
  ConsumerState<SightingsMapScreen> createState() => _SightingsMapState();
}

class _SightingsMapState extends ConsumerState<SightingsMapScreen> {
  String? _selectedId;
  RouteSummary? _route;
  bool _routing = false;
  RouteProblem? _problem;
  bool _navFailed = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.sightingId;
  }

  void _select(String id) => setState(() {
    _selectedId = id;
    _route = null;
    _problem = null;
    _navFailed = false;
  });

  Future<void> _computeRoute(GeoPoint destination) async {
    final config = ref.read(mapsConfigProvider).value;
    if (config == null || !config.isConfigured) return;
    setState(() {
      _routing = true;
      _problem = null;
    });
    final fix = await ref.read(sightingLocatorProvider).locate();
    if (!mounted) return;
    if (!fix.hasPosition) {
      setState(() {
        _routing = false;
        _problem = RouteProblem.needsLocation;
      });
      return;
    }
    final client = RoutesClient(
      client: ref.read(routesHttpClientProvider),
      config: config,
    );
    final route = await client.computeRoute(
      GeoPoint(fix.latitude!, fix.longitude!),
      destination,
    );
    if (!mounted) return;
    setState(() {
      _routing = false;
      _route = route;
      _problem = route == null ? RouteProblem.failed : null;
    });
  }

  Future<void> _navigate(GeoPoint destination) async {
    final ok = await startNavigation(
      ref.read(externalMapLauncherProvider),
      destination,
    );
    if (mounted) setState(() => _navFailed = !ok);
  }

  Future<void> _openGeo(GeoPoint p) async {
    final ok = await ref.read(externalMapLauncherProvider).launch(geoUri(p));
    if (mounted) setState(() => _navFailed = !ok);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = ref.watch(activeRoleProvider).value;
    final sightings = ref.watch(recentSightingsProvider(role));
    return Scaffold(
      appBar: KernelAppBar(title: l.mapTitle),
      body: AsyncView<List<Sighting>>(
        value: sightings,
        data: (all) {
          final pinned = [
            for (final s in all)
              if (sightingPoint(s) != null) s,
          ];
          if (pinned.isEmpty) {
            return PageList(
              children: [
                EmptyState(
                  key: const Key('map-no-pins'),
                  message: l.mapNoPins,
                  detail: l.mapNoPinsDetail,
                  actionLabel: l.mapNoPinsAction,
                  actionIcon: Icons.list_alt_rounded,
                  onAction: () => context.pushReplacement(Routes.sightings),
                ),
              ],
            );
          }
          return _consented(l, pinned);
        },
      ),
    );
  }

  Widget _consented(AppLocalizations l, List<Sighting> pinned) {
    final consent = ref.watch(mapsConsentProvider);
    if (!consent.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (consent.value != true) {
      return PageList(
        children: [
          NoticeBanner(
            key: const Key('map-consent-needed'),
            title: l.mapConsentTitle,
            text: l.mapConsentNeeded,
            icon: Icons.map_outlined,
          ),
          FilledButton.icon(
            key: const Key('map-consent-open'),
            onPressed: () => showMapsConsentSheet(context, ref),
            icon: const Icon(Icons.map_rounded),
            label: Text(l.mapConsentAllow),
          ),
          ..._pinList(l, pinned, withGeo: false),
        ],
      );
    }
    final config = ref.watch(mapsConfigProvider);
    return AsyncView<MapsPlatformConfig>(
      value: config,
      data: (config) =>
          config.isConfigured ? _map(l, pinned) : _notConfigured(l, pinned),
    );
  }

  Widget _notConfigured(AppLocalizations l, List<Sighting> pinned) => PageList(
    children: [
      NoticeBanner(
        key: const Key('map-not-configured'),
        title: l.mapNotConfigured,
        text: l.mapNotConfiguredBody,
        icon: Icons.map_outlined,
      ),
      if (_navFailed) ErrorNote(l.mapNavigationFailed),
      ..._pinList(l, pinned, withGeo: true),
    ],
  );

  Widget _map(AppLocalizations l, List<Sighting> pinned) {
    final selected =
        pinned.where((s) => s.id == _selectedId).firstOrNull ?? pinned.first;
    final destination = sightingPoint(selected)!;
    final build = ref.watch(mapViewBuilderProvider);
    final data = MapViewData(
      pins: [
        for (final s in pinned)
          MapPin(
            id: s.id,
            position: sightingPoint(s)!,
            accuracyMeters: s.accuracyMeters ?? maxPinAccuracyMeters,
            title: l.mapPinLabel(formatDateTime(context, s.observedAt)),
          ),
      ],
      selectedId: selected.id,
      route: _route?.path ?? const [],
      onSelect: _select,
    );
    final cards = ref.watch(knowledgeCardsProvider).value ?? const [];
    final lang = Localizations.localeOf(context).languageCode;
    return PageList(
      children: [
        SizedBox(
          key: const Key('map-view'),
          height: 360,
          child: build(context, data),
        ),
        MapRoutePanel(
          title: sightingTitle(l, selected, cards, lang),
          route: _route,
          routing: _routing,
          problem: _problem,
          navigationFailed: _navFailed,
          onRoute: () => _computeRoute(destination),
          onNavigate: () => _navigate(destination),
        ),
        ..._pinList(l, pinned, withGeo: false, selectable: true),
      ],
    );
  }

  List<Widget> _pinList(
    AppLocalizations l,
    List<Sighting> pinned, {
    required bool withGeo,
    bool selectable = false,
  }) {
    final cards = ref.watch(knowledgeCardsProvider).value ?? const [];
    final lang = Localizations.localeOf(context).languageCode;
    return [
      for (final s in pinned) ...[
        ListTile(
          key: Key('map-pin-${s.id}'),
          minTileHeight: 48,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            selectable && s.id == _selectedId
                ? Icons.location_on_rounded
                : Icons.location_on_outlined,
          ),
          title: Text(sightingTitle(l, s, cards, lang)),
          subtitle: Text(formatDateTime(context, s.observedAt)),
          onTap: selectable ? () => _select(s.id) : null,
        ),
        if (withGeo)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: Key('map-geo-${s.id}'),
              onPressed: () => _openGeo(sightingPoint(s)!),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(l.mapOpenInGoogleMaps),
            ),
          ),
      ],
    ];
  }
}
