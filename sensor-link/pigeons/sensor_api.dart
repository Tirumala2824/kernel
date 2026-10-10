// Pigeon definition for the sensor-link Dart <-> Kotlin bridge.
//
// Regenerate after any change (from sensor-link/):
//   dart run pigeon --input pigeons/sensor_api.dart
//
// The bridge carries only protocol bytes (features, never audio) and node
// metadata. The per-device key never crosses it after association: Kotlin
// imports it into Android Keystore and only the fingerprint comes back.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'sensor_link',
    dartOut: 'lib/src/sensor_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/com/kernel/sensor_link/SensorApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.kernel.sensor_link',
      errorClassName: 'SensorApiError',
    ),
  ),
)
/// Mirrors contracts SensorLinkState.
enum NativeLinkState {
  unpaired,
  pairing,
  connecting,
  connected,
  authenticated,
  disconnected,
  error,
}

class NativeNodeInfo {
  NativeNodeInfo({
    required this.nodeId,
    required this.address,
    required this.name,
    required this.sensorType,
    required this.keyFingerprint,
    required this.protocolVersion,
    required this.firmwareVersion,
  });

  String nodeId;
  String address;
  String name;

  /// Wire sensor type (1 usAir, 2 contactPiezo, 3 contactAccel, 4 audioAir).
  int sensorType;
  String keyFingerprint;
  int protocolVersion;

  /// "major.minor.patch", or null until DeviceInfo has been read.
  String? firmwareVersion;
}

class NativeSyncResult {
  NativeSyncResult({
    required this.count,
    required this.lastSeq,
    required this.oldestSeq,
  });

  /// Events the node indicated for this request (EVENTS_DONE.count).
  int count;
  int lastSeq;

  /// Oldest seq still in the node's ring; > sinceSeq + 1 means a gap.
  int oldestSeq;
}

class NativeSnippet {
  NativeSnippet({required this.meta, required this.tiles});

  /// REQUEST_SNIPPET response payload (14 B).
  Uint8List meta;

  /// Snippet characteristic notifications, in tile order. Memory only.
  List<Uint8List> tiles;
}

@HostApi()
abstract class SensorHostApi {
  /// Parses the QR label, imports the key into Android Keystore and runs the
  /// CompanionDeviceManager association. Null when the user cancels.
  @async
  NativeNodeInfo? associate(String qrPayload);

  @async
  void forget(String nodeId);

  List<NativeNodeInfo> knownNodes();

  /// Connect, bond, MTU, PHY, discover, subscribe, authenticate, SET_TIME,
  /// then GET_EVENTS_SINCE(lastSeq from SensorFlutterApi.lastSeq).
  @async
  void connect(String nodeId);

  @async
  void disconnect(String nodeId);

  @async
  NativeSyncResult syncEvents(String nodeId, int sinceSeq);

  @async
  void startSurvey(String nodeId, int durationS);

  /// Starts the connectedDevice foreground service; fails with
  /// `not_visible` unless the app is in the foreground.
  @async
  void startSession(String nodeId);

  @async
  void stopSession(String nodeId);

  @async
  void setLiveBands(String nodeId, bool enabled);

  @async
  NativeSnippet? requestSnippet(String nodeId, int eventSeq);
}

@FlutterApi()
abstract class SensorFlutterApi {
  void onLinkState(String nodeId, NativeLinkState state, int? rssi, bool authFailed);

  void onDeviceInfo(String nodeId, Uint8List bytes);

  void onBandTable(String nodeId, Uint8List bytes);

  void onStatus(String nodeId, Uint8List bytes, int receivedAtMs);

  void onBandFrame(String nodeId, Uint8List bytes);

  void onEvent(String nodeId, Uint8List bytes, int receivedAtMs);

  /// Latest persisted seq for GET_EVENTS_SINCE (the injected lookup).
  @async
  int? lastSeq(String nodeId);
}
