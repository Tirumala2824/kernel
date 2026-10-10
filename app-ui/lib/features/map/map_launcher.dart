import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'routes_client.dart';

String _coord(double v) => v.toStringAsFixed(6);

/// Turn-by-turn walking navigation in the Google Maps app.
Uri navigationUri(GeoPoint p) => Uri.parse(
  'google.navigation:q=${_coord(p.latitude)},${_coord(p.longitude)}&mode=w',
);

/// Browser fallback when the Maps app cannot take the navigation intent.
Uri webDirectionsUri(GeoPoint p) => Uri.parse(
  'https://www.google.com/maps/dir/?api=1'
  '&destination=${_coord(p.latitude)},${_coord(p.longitude)}',
);

/// "Open in Google Maps" when the app has no maps key. Coordinates only.
Uri geoUri(GeoPoint p) {
  final c = '${_coord(p.latitude)},${_coord(p.longitude)}';
  return Uri.parse('geo:$c?q=$c');
}

abstract interface class ExternalMapLauncher {
  /// Hands [uri] to another app. False when nothing can handle it.
  Future<bool> launch(Uri uri);
}

class UrlLauncherExternalMapLauncher implements ExternalMapLauncher {
  const UrlLauncherExternalMapLauncher();

  @override
  Future<bool> launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (error) {
      debugPrint('Kernel: could not open $uri: $error');
      return false;
    }
  }
}

final externalMapLauncherProvider = Provider<ExternalMapLauncher>(
  (ref) => const UrlLauncherExternalMapLauncher(),
  name: 'externalMapLauncherProvider',
);

/// Starts walking navigation: the Maps app intent first, then the web
/// directions URL. False when neither could be opened.
Future<bool> startNavigation(ExternalMapLauncher launcher, GeoPoint to) async {
  if (await launcher.launch(navigationUri(to))) return true;
  return launcher.launch(webDirectionsUri(to));
}
