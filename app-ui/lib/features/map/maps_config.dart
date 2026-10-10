import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maps key and app identity for the Routes API headers. The key is an
/// Android-restricted key from `local.properties` (never committed); it is
/// read from the manifest meta-data by MainActivity.
@immutable
class MapsPlatformConfig {
  const MapsPlatformConfig({
    required this.apiKey,
    required this.packageName,
    required this.certSha1,
  });

  static const empty = MapsPlatformConfig(
    apiKey: '',
    packageName: '',
    certSha1: '',
  );

  final String apiKey;

  /// For the X-Android-Package header.
  final String packageName;

  /// Signing certificate SHA-1, upper-case hex without colons, for the
  /// X-Android-Cert header.
  final String certSha1;

  bool get isConfigured => apiKey.trim().isNotEmpty;
}

abstract interface class MapsConfigSource {
  Future<MapsPlatformConfig> read();
}

/// Reads the config over a tiny MethodChannel in MainActivity.
class ChannelMapsConfigSource implements MapsConfigSource {
  const ChannelMapsConfigSource();

  static const channel = MethodChannel('com.kernel.kernel_app/maps_config');

  @override
  Future<MapsPlatformConfig> read() async {
    try {
      final map = await channel.invokeMapMethod<String, Object?>('read');
      if (map == null) return MapsPlatformConfig.empty;
      return MapsPlatformConfig(
        apiKey: '${map['apiKey'] ?? ''}',
        packageName: '${map['packageName'] ?? ''}',
        certSha1: '${map['certSha1'] ?? ''}',
      );
    } on Object catch (error) {
      debugPrint('Kernel: maps config unavailable: $error');
      return MapsPlatformConfig.empty;
    }
  }
}

final mapsConfigSourceProvider = Provider<MapsConfigSource>(
  (ref) => const ChannelMapsConfigSource(),
  name: 'mapsConfigSourceProvider',
);

final mapsConfigProvider = FutureProvider<MapsPlatformConfig>(
  (ref) => ref.watch(mapsConfigSourceProvider).read(),
  name: 'mapsConfigProvider',
);
