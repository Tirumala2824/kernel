/// Kernel BLE link to dedicated frequency-detection sensor nodes
/// (docs/sensor-protocol.md). Native Kotlin + Pigeon; no network code.
///
/// Nodes send features, never audio. Events are matched against the
/// experimental signature pack and are signals, not diagnoses (guardrails §10).
library;

export 'src/ble_sensor_link.dart' show BleSensorLink, LastSeqLookup, SensorSessionException;
export 'src/mapping.dart'
    show NodeClock, bitsNotEvaluated, healthFromBits, isEvaluated, nodeTime, sensorTypeFromWire, sensorTypeToWire, toBandFrame, toSensorEvent;
export 'src/protocol.dart';
export 'src/qr.dart' show SensorQrFormatException, SensorQrLabel;
export 'src/sensor_api.g.dart' show NativeNodeInfo;
export 'src/signature_pack.dart';
export 'src/snippet.dart' show SensorSnippet;
