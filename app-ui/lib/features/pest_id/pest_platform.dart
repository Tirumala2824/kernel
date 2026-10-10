import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Platform services for saving sightings: a one-shot location fix and
// app-private storage for kept media. Each sits behind a small interface so
// widget tests bind test doubles under test/.

/// A GPS pin is shown and stored only at this accuracy or better
/// (guardrails §9).
const maxPinAccuracyMeters = 25.0;

enum LocationFixStatus { precise, imprecise, denied, serviceOff, failed }

@immutable
class LocationFix {
  const LocationFix(
    this.status, {
    this.latitude,
    this.longitude,
    this.accuracyMeters,
  });

  final LocationFixStatus status;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;

  bool get hasPosition => latitude != null && longitude != null;
  bool get isPrecise => status == LocationFixStatus.precise;
}

/// Applies the 25 m accuracy gate. Approximate-only permission is never
/// precise, whatever accuracy it reports.
LocationFix classifyFix(
  double latitude,
  double longitude,
  double accuracyMeters, {
  bool reducedAccuracy = false,
}) {
  final precise =
      !reducedAccuracy &&
      accuracyMeters > 0 &&
      accuracyMeters <= maxPinAccuracyMeters;
  return LocationFix(
    precise ? LocationFixStatus.precise : LocationFixStatus.imprecise,
    latitude: latitude,
    longitude: longitude,
    accuracyMeters: accuracyMeters,
  );
}

abstract interface class SightingLocator {
  /// Asks for precise and approximate location together, right now, and
  /// reads one position. Only called when the user taps "Save location"
  /// or asks for a route.
  Future<LocationFix> locate();
}

class GeolocatorSightingLocator implements SightingLocator {
  const GeolocatorSightingLocator();

  @override
  Future<LocationFix> locate() async {
    try {
      // On Android this requests ACCESS_FINE_LOCATION and
      // ACCESS_COARSE_LOCATION in one dialog, so the user can choose
      // precise or approximate.
      await Permission.locationWhenInUse.request();
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationFix(LocationFixStatus.denied);
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationFix(LocationFixStatus.serviceOff);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 20),
        ),
      );
      final reduced =
          await Geolocator.getLocationAccuracy() ==
          LocationAccuracyStatus.reduced;
      return classifyFix(
        position.latitude,
        position.longitude,
        position.accuracy,
        reducedAccuracy: reduced,
      );
    } on Object catch (error) {
      debugPrint('Kernel: location unavailable: $error');
      return const LocationFix(LocationFixStatus.failed);
    }
  }
}

final sightingLocatorProvider = Provider<SightingLocator>(
  (ref) => const GeolocatorSightingLocator(),
  name: 'sightingLocatorProvider',
);

abstract interface class SightingMediaStore {
  /// Writes a validated still or clip into app-private storage and returns
  /// its absolute path. Only when the user turned "keep media" on.
  Future<String?> keep(Uint8List bytes, {required String extension});
}

class AppPrivateSightingMediaStore implements SightingMediaStore {
  AppPrivateSightingMediaStore();

  int _sequence = 0;

  @override
  Future<String?> keep(Uint8List bytes, {required String extension}) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/sighting_media');
      await dir.create(recursive: true);
      final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
      final file = File(
        '${dir.path}/sighting_${stamp}_${_sequence++}.$extension',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on Object catch (error) {
      debugPrint('Kernel: could not keep sighting media: $error');
      return null;
    }
  }
}

final sightingMediaStoreProvider = Provider<SightingMediaStore>(
  (ref) => AppPrivateSightingMediaStore(),
  name: 'sightingMediaStoreProvider',
);
