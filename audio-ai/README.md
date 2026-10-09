# audio_ai

The Kernel on-device acoustic scan engine is a Flutter plugin with an Android/Kotlin implementation. It has no network code. Owner: `audio-ai-dev`.

## Public API
`package:audio_ai/audio_ai.dart` exports one class:

```dart
class NativeScanEngine implements ScanEngine {   // kernel_contracts
  NativeScanEngine();
  Future<ScanOutcome> captureAndAnalyze(String itemId, {bool retainAudio = false});
  Future<EngineInfo> info();
  Future<void> deleteRetainedAudio();  // not in the contract yet; lead adds it at integration
}
```
`captureAndAnalyze` never throws. Audio, permission, bridge and model problems all come back as RETRY or NOT_EVALUATED outcomes that pass `invariantViolations()`. The app requests RECORD_AUDIO itself.

## Pipeline (Kotlin, `android/src/main/kotlin/com/kernel/audio_ai/`)
1. `ScanEngineHost`: checks the permission, plays the start cue and waits it out, then captures on its own thread.
2. `AudioCapture`: AudioRecord with VOICE_RECOGNITION, mono PCM16. It requests 16 kHz and falls back to 48/44.1 kHz. A 100 ms warm-up is discarded, then 2000 ms are kept. It records the effective rate and, on API 29+, the HAL rate.
3. `QualityGate`: pure Kotlin, run on the raw device PCM. Checks silence, clipping, high noise (noise floor) and too-short.
4. `Resampler` → 16 kHz, only when the device delivered another rate (Hann-windowed sinc).
5. `LogMel` + `LogMelConfig`: pure Kotlin. `LogMelConfig.PROVISIONAL` is a placeholder until the training pipeline is known.
6. `ModelRunner`: LiteRT `Interpreter` on the CPU, used only if a model is bundled. With no model the result is NOT_EVALUATED, `modelVersion "none"`, `experimental true` and `confidence null`.
7. `Haptics`: start, finish and retry cues. They respect the system touch-feedback setting.
8. `RecordingStore`: only with `retainAudio: true`. Writes `files/recordings/<scanId>.wav` in app-private storage.

## Bundling a model (V0.3)
Put exactly one `<name>.tflite` and `<name>.properties` under `android/src/main/assets/models/`. The manifest format is documented in `ModelManifest.kt`. Every preprocessing key is required, and `experimental` stays true unless set to `false` explicitly. A model with a missing or invalid manifest, or with mismatched tensors, is treated as no model.

## Development
```bash
dart run pigeon --input pigeons/scan_api.dart            # after editing the bridge
flutter analyze && flutter test                          # Dart (from audio-ai/)
(cd example/android && ./gradlew :audio_ai:testDebugUnitTest)   # Kotlin unit tests
(cd example && flutter build apk --debug)                # developer screen app
```
Logs (tag `AudioAi`) contain only technical data: the capture config, and in debuggable builds the aggregate gate levels in dBFS. They never contain audio or spectrogram values.
