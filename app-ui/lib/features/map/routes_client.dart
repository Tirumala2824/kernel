import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'maps_config.dart';

@immutable
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => '$latitude,$longitude';
}

@immutable
class RouteSummary {
  const RouteSummary({
    required this.distanceMeters,
    required this.duration,
    required this.path,
  });

  final int distanceMeters;
  final Duration duration;
  final List<GeoPoint> path;
}

/// Google Routes API (computeRoutes). Only called after maps consent. The
/// request body carries ONLY the origin and destination coordinates.
class RoutesClient {
  RoutesClient({required this.client, required this.config});

  static final endpoint = Uri.parse(
    'https://routes.googleapis.com/directions/v2:computeRoutes',
  );
  static const fieldMask =
      'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline';

  final http.Client client;
  final MapsPlatformConfig config;

  /// The exact JSON body sent: origin and destination, nothing else.
  static Map<String, Object?> requestBody(GeoPoint origin, GeoPoint destination) =>
      {
        'origin': _waypoint(origin),
        'destination': _waypoint(destination),
      };

  static Map<String, Object?> _waypoint(GeoPoint p) => {
    'location': {
      'latLng': {'latitude': p.latitude, 'longitude': p.longitude},
    },
  };

  /// Null when no route is returned or the call fails.
  Future<RouteSummary?> computeRoute(GeoPoint origin, GeoPoint destination) async {
    if (!config.isConfigured) return null;
    try {
      final response = await client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': config.apiKey,
              'X-Goog-FieldMask': fieldMask,
              'X-Android-Package': config.packageName,
              'X-Android-Cert': config.certSha1,
            },
            body: jsonEncode(requestBody(origin, destination)),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        debugPrint('Kernel: route request failed (${response.statusCode})');
        return null;
      }
      return parseRoute(response.body);
    } on Object catch (error) {
      debugPrint('Kernel: route request failed: $error');
      return null;
    }
  }

  static RouteSummary? parseRoute(String body) {
    final json = jsonDecode(body);
    if (json is! Map) return null;
    final routes = json['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final route = routes.first;
    if (route is! Map) return null;
    final meters = route['distanceMeters'];
    final duration = '${route['duration'] ?? ''}';
    final polyline = route['polyline'];
    final encoded = polyline is Map ? '${polyline['encodedPolyline'] ?? ''}' : '';
    final seconds = double.tryParse(duration.replaceAll('s', ''));
    return RouteSummary(
      distanceMeters: meters is num ? meters.round() : 0,
      duration: Duration(seconds: (seconds ?? 0).round()),
      path: decodePolyline(encoded),
    );
  }
}

/// Decodes a Google encoded polyline (precision 5).
List<GeoPoint> decodePolyline(String encoded) {
  final points = <GeoPoint>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  int next() {
    var result = 0;
    var shift = 0;
    int b;
    do {
      if (index >= encoded.length) throw const FormatException('truncated');
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  try {
    while (index < encoded.length) {
      lat += next();
      lng += next();
      points.add(GeoPoint(lat / 1e5, lng / 1e5));
    }
  } on FormatException {
    return points;
  }
  return points;
}

/// Injected HTTP client so tests can record requests.
final routesHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}, name: 'routesHttpClientProvider');
