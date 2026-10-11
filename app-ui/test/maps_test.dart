// Sightings map: nothing reaches Google before consent, the missing-key
// fallback, the Routes request (only origin and destination), ETA and
// polyline, and the navigation hand-off URIs.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/map/map_launcher.dart';
import 'package:kernel_app/features/map/maps_config.dart';
import 'package:kernel_app/features/map/routes_client.dart';
import 'package:kernel_app/features/pest_id/pest_platform.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/test_pest.dart';

const _config = MapsPlatformConfig(
  apiKey: 'test-key-not-real',
  packageName: 'com.kernel.kernel_app',
  certSha1: 'AB12CD34',
);

Future<(PestEnv, Sighting)> _pinnedEnv({bool consent = false}) async {
  final env = PestEnv(role: Role.household, offline: false);
  final s = await env.sightings.add(
    latitude: 12.971610,
    longitude: 77.594560,
    accuracyMeters: 9,
  );
  if (consent) await env.settings.setMapsConsent(true);
  return (env, s);
}

void main() {
  group('URIs and parsing', () {
    const p = GeoPoint(12.97161, 77.59456);

    test('navigation intent and fallbacks carry only coordinates', () {
      expect(
        navigationUri(p).toString(),
        'google.navigation:q=12.971610,77.594560&mode=w',
      );
      expect(
        webDirectionsUri(p).toString(),
        'https://www.google.com/maps/dir/?api=1&destination=12.971610,77.594560',
      );
      expect(
        geoUri(p).toString(),
        'geo:12.971610,77.594560?q=12.971610,77.594560',
      );
    });

    test('startNavigation falls back to the web URL when unresolved', () async {
      final launcher = RecordingMapLauncher()..resolvable = {'https'};
      expect(await startNavigation(launcher, p), isTrue);
      expect(launcher.launched.map((u) => u.scheme), [
        'google.navigation',
        'https',
      ]);

      final app = RecordingMapLauncher();
      expect(await startNavigation(app, p), isTrue);
      expect(app.launched.single, navigationUri(p));
    });

    test('decodes the Google polyline example', () {
      final points = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(points, const [
        GeoPoint(38.5, -120.2),
        GeoPoint(40.7, -120.95),
        GeoPoint(43.252, -126.453),
      ]);
    });

    test('incomplete route measurements never become zero-valued facts', () {
      for (final route in <Map<String, Object?>>[
        {},
        {'duration': '10s'},
        {'distanceMeters': 10},
        {'distanceMeters': -1, 'duration': '10s'},
        {'distanceMeters': '10', 'duration': '10s'},
        {'distanceMeters': 1.5, 'duration': '10s'},
        {'distanceMeters': 10, 'duration': 'n/a'},
        {'distanceMeters': 10, 'duration': 's10s'},
        {'distanceMeters': 10, 'duration': '-1s'},
        {'distanceMeters': 10, 'duration': 'NaNs'},
        {'distanceMeters': 10, 'duration': 'Infinitys'},
      ]) {
        expect(
          RoutesClient.parseRoute(
            jsonEncode({
              'routes': [route],
            }),
          ),
          isNull,
          reason: '$route',
        );
      }
      final zero = RoutesClient.parseRoute(
        '{"routes":[{"distanceMeters":0,"duration":"0s"}]}',
      );
      expect(zero, isNotNull);
      expect(zero!.distanceMeters, 0);
      expect(zero.duration, Duration.zero);
      final fraction = RoutesClient.parseRoute(
        '{"routes":[{"distanceMeters":3,"duration":"0.5s"}]}',
      );
      expect(fraction!.duration, const Duration(milliseconds: 500));
    });

    test('the request body has only origin and destination', () {
      final body = RoutesClient.requestBody(
        const GeoPoint(1, 2),
        const GeoPoint(3, 4),
      );
      expect(body.keys, unorderedEquals(['origin', 'destination']));
      expect(jsonEncode(body), contains('"latitude":1'));
    });
  });

  testWidgets('no consent: no map, no config read and no route call', (
    tester,
  ) async {
    final (env, s) = await _pinnedEnv();
    env.mapsConfig.config = _config;
    await pumpKernelApp(
      tester,
      env,
      location: Routes.sightingsMap(sightingId: s.id),
    );

    expect(find.byKey(const Key('map-consent-needed')), findsOneWidget);
    expect(find.byKey(const Key('test-map')), findsNothing);
    expect(find.byKey(const Key('map-route')), findsNothing);
    expect(env.mapsConfig.reads, 0);
    expect(env.routesHttp.requests, isEmpty);
    expect(env.launcher.launched, isEmpty);
  });

  testWidgets('the consent sheet explains, and declining keeps maps off', (
    tester,
  ) async {
    final (env, _) = await _pinnedEnv();
    await pumpKernelApp(tester, env, location: Routes.sightingsMap());

    await tapVisible(tester, find.byKey(const Key('map-consent-open')));
    expect(find.text(en.mapConsentBody), findsOneWidget);
    expect(find.text(en.mapConsentNever), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('maps-consent-decline')));

    expect(env.settings.mapsConsent, isFalse);
    expect(env.routesHttp.requests, isEmpty);
    expect(find.byKey(const Key('map-consent-needed')), findsOneWidget);
  });

  testWidgets('allowing maps shows pins with accuracy circles', (tester) async {
    final (env, s) = await _pinnedEnv();
    env.mapsConfig.config = _config;
    await pumpKernelApp(tester, env, location: Routes.sightingsMap());

    await tapVisible(tester, find.byKey(const Key('map-consent-open')));
    await tapVisible(tester, find.byKey(const Key('maps-consent-allow')));

    expect(env.settings.mapsConsentWrites, [true]);
    expect(find.byKey(const Key('test-map')), findsOneWidget);
    expect(find.text('pin ${s.id} ±9'), findsOneWidget);
    // Still no route request until the user asks for one.
    expect(env.routesHttp.requests, isEmpty);
  });

  testWidgets('missing key: "Maps not configured" with a geo: fallback', (
    tester,
  ) async {
    final (env, s) = await _pinnedEnv(consent: true);
    await pumpKernelApp(tester, env, location: Routes.sightingsMap());

    expect(find.text(en.mapNotConfigured), findsOneWidget);
    expect(find.byKey(const Key('test-map')), findsNothing);
    await tapVisible(tester, find.byKey(Key('map-geo-${s.id}')));

    expect(
      env.launcher.launched.single.toString(),
      'geo:12.971610,77.594560?q=12.971610,77.594560',
    );
    expect(env.routesHttp.requests, isEmpty);
  });

  testWidgets('route: POSTs only origin and destination with the key and '
      'app headers; shows distance, ETA and the polyline', (tester) async {
    final (env, _) = await _pinnedEnv(consent: true);
    env.mapsConfig.config = _config;
    env.locator.fix = classifyFix(12.9700, 77.5900, 15);
    await pumpKernelApp(tester, env, location: Routes.sightingsMap());

    await tapVisible(tester, find.byKey(const Key('map-route')));

    final request = env.routesHttp.requests.single;
    expect(request.method, 'POST');
    expect(
      request.url.toString(),
      'https://routes.googleapis.com/directions/v2:computeRoutes',
    );
    expect(request.headers['X-Goog-Api-Key'], 'test-key-not-real');
    expect(
      request.headers['X-Goog-FieldMask'],
      'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
    );
    expect(request.headers['X-Android-Package'], 'com.kernel.kernel_app');
    expect(request.headers['X-Android-Cert'], 'AB12CD34');
    final body = jsonDecode(request.body) as Map<String, Object?>;
    expect(body.keys, unorderedEquals(['origin', 'destination']));
    expect(body, {
      'origin': {
        'location': {
          'latLng': {'latitude': 12.97, 'longitude': 77.59},
        },
      },
      'destination': {
        'location': {
          'latLng': {'latitude': 12.97161, 'longitude': 77.59456},
        },
      },
    });
    // Species, notes and media never appear in the request.
    expect(request.body, isNot(contains('cockroach')));

    expect(
      find.text(en.mapRouteSummary(en.mapDistanceKm('1.3'), 15)),
      findsOneWidget,
    );
    expect(find.text('route points 2'), findsOneWidget);
  });

  testWidgets('route without a location asks for it and sends nothing', (
    tester,
  ) async {
    final (env, _) = await _pinnedEnv(consent: true);
    env.mapsConfig.config = _config;
    env.locator.fix = const LocationFix(LocationFixStatus.denied);
    await pumpKernelApp(tester, env, location: Routes.sightingsMap());

    await tapVisible(tester, find.byKey(const Key('map-route')));

    expect(find.text(en.mapRouteNeedsLocation), findsOneWidget);
    expect(env.routesHttp.requests, isEmpty);
  });

  testWidgets(
    'incomplete route response shows unavailable without zero distance or ETA',
    (tester) async {
      final (env, _) = await _pinnedEnv(consent: true);
      env.mapsConfig.config = _config;
      env.locator.fix = classifyFix(12.97, 77.59, 15);
      env.routesHttp.responseBody = '{"routes":[{}]}';
      await pumpKernelApp(tester, env, location: Routes.sightingsMap());
      await tapVisible(tester, find.byKey(const Key('map-route')));
      expect(find.text(en.mapRouteFailed), findsOneWidget);
      expect(find.byKey(const Key('map-route-summary')), findsNothing);
    },
  );

  testWidgets('a failed route says so', (tester) async {
    final (env, _) = await _pinnedEnv(consent: true);
    env.mapsConfig.config = _config;
    env.locator.fix = classifyFix(12.97, 77.59, 15);
    env.routesHttp.statusCode = 403;
    await pumpKernelApp(tester, env, location: Routes.sightingsMap());

    await tapVisible(tester, find.byKey(const Key('map-route')));

    expect(find.text(en.mapRouteFailed), findsOneWidget);
  });

  testWidgets('Start navigation hands off the walking intent', (tester) async {
    final (env, _) = await _pinnedEnv(consent: true);
    env.mapsConfig.config = _config;
    await pumpKernelApp(tester, env, location: Routes.sightingsMap());

    await tapVisible(tester, find.byKey(const Key('map-navigate')));

    expect(
      env.launcher.launched.single.toString(),
      'google.navigation:q=12.971610,77.594560&mode=w',
    );
  });

  testWidgets('Start navigation falls back to the web directions', (
    tester,
  ) async {
    final (env, _) = await _pinnedEnv(consent: true);
    env.mapsConfig.config = _config;
    env.launcher.resolvable = {'https'};
    await pumpKernelApp(tester, env, location: Routes.sightingsMap());

    await tapVisible(tester, find.byKey(const Key('map-navigate')));

    expect(
      env.launcher.launched.last.toString(),
      startsWith('https://www.google.com/maps/dir/?api=1&destination='),
    );
    expect(find.text(en.mapNavigationFailed), findsNothing);
  });

  testWidgets('no pinned sightings: empty state, nothing sent', (tester) async {
    final env = PestEnv(role: Role.household);
    await env.sightings.add();
    await env.settings.setMapsConsent(true);
    await pumpKernelApp(tester, env, location: Routes.sightingsMap());

    expect(find.byKey(const Key('map-no-pins')), findsOneWidget);
    expect(env.mapsConfig.reads, 0);
    expect(env.routesHttp.requests, isEmpty);
  });
}
