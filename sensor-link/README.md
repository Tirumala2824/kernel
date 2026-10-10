# sensor_link

The Flutter plugin for Kernel's BLE frequency-detection sensor nodes. The protocol is in [docs/sensor-protocol.md](../docs/sensor-protocol.md) and the guardrails in §10.

- **Native side:** Kotlin + Pigeon. It handles CompanionDeviceManager pairing, LE Secure Connections bonding, the HMAC-SHA256 app-layer auth with the per-device key in Android Keystore, the GATT link and the `connectedDevice` foreground session. `flutter_blue_plus` is not used, and the package has no network code.
- **Dart side:** `BleSensorLink implements SensorLink`. It decodes the protocol, maps node time, matches events against the **experimental** signature pack (`assets/signature_pack_v0_1.properties`) and maps health. Jammed, clipped and survey-needed all mean "not evaluated".

## Wiring (lead)
```dart
final link = BleSensorLink(
  lastSeqOf: (nodeId) => sensorEventRepository.lastSeq(nodeId), // injected
);
link.events().listen((e) => sensorEventRepository.record([e]));  // idempotent on (nodeId, seq)
final node = await link.associate(qrPayload: scanned);           // null if the user cancels
if (node != null) await sensorNodeRepository.upsert(node);
```

- The link connects on demand: `watchStatus`, `liveBands`, `syncEvents`, `startSurvey` and `startSession` each open it. A watcher's subscription keeps it open.
- `startSession` throws `SensorSessionException('not_visible')` unless the app is in the foreground.
- `SignaturePack.assessRate` turns counts into "N events in M minutes" plus a `RateLevel`.
- `requestSnippet` returns a u8 feature spectrogram that is held in memory only.

## Host app requirements
- Ask the user for `BLUETOOTH_CONNECT`, and for `BLUETOOTH_SCAN` (used only by the presence fallback), at runtime on Android 12+. No location permission is requested.
- Ask for `POST_NOTIFICATIONS` (Android 13+) so the session notification is visible.

## Tests
```bash
flutter test                                                        # Dart: codec, QR, pack, mapping, link
(cd example/android && ./gradlew :sensor_link:testDebugUnitTest)   # Kotlin: codec, auth, QR, reconnect plan
```
Both suites decode the shared vectors in `firmware/reference/vectors`.
