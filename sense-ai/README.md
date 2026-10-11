# sense_ai

Kernel Pest ID sensing (Android): camera signals, listen mode and distance
measurement. Everything runs on the phone. The plugin has no network code,
logs no media, and keeps images and audio in memory until `discardMedia()`.

## Use

```dart
final engine = SenseEngine(
  embedder: embedder,                // contracts Embedder; null = no Stage 1
  soundModelPath: () => hub.pathFor(soundClassifier), // null = unlabelled events
);

// Mount to bind the camera; candidate boxes map onto `overlay`.
SenseCameraPreview(lowLightBoost: true, overlay: myBoxes);

engine.cameraCandidates();           // Stage 0 (+ Stage 1) lists, <= 5 Hz
engine.cameraStatus();               // thermal level, fps, torch, gyro gating
final still = await engine.captureStill(candidates: current);
await engine.rankStill(still!);      // Stage-1 embeddingMatch candidates
engine.listen(ListenMode.general);   // sound-event candidates
await engine.measure(target: box);   // DistanceEstimate, or unavailable + reason
await engine.keepMedia(still.stillId); // only for "keep media" sightings
await engine.discardMedia();
```

The app requests `CAMERA` and `RECORD_AUDIO` (and `POST_NOTIFICATIONS` on
Android 13+ for the night-listening notification) before use.

## Pipeline and thresholds (all need on-device calibration)

| Stage | Rule |
|---|---|
| Gyro gate | peak rate > 0.05 rad/s since the last frame: background reset, frame skipped |
| Motion | `|frame - bg| > max(12 DN, 3 * 1.4826 * MAD)`; > 5 % of pixels = global change, reset; blobs 0.0002-0.02 of the frame; 3 of 5 frames |
| Dark specks | > 25 DN below the 31x31 mean, blobs 2-200 px (not line-like), >= 3 within 5 % of the long edge, 2 runs in a row; score <= 0.5 |
| Eyeshine | torch pulse: on >= 235 DN and +60 DN over the torch-off frame, 1-6 px, surround < 160 DN, 150-2000 ms after torch on; pairs score 0.9 |
| Stage 1 | cosine(image tile, prompt) >= 0.2 and the best prompt is not a background prompt |
| Listen | 64-band log-mel (512/160 at 16 kHz, 125-7500 Hz); onset = > 6 bands newly above floor + 9 dB and a flux peak (mean + 0.07); 1 s merge; clip = 5 s before to 1 s after |
| Pre-filter | YAMNet-class model on 15600 samples; top class speech/music/TV = dropped; hint = best allow-listed class >= 0.05 |
| Thermal | headroom 0.85 -> 5 fps Stage 0, 0.95 -> no Stage 1, 1.0 -> camera paused (polled every 10 s, 0.03 hysteresis) |
| Distance | ARCore: TRACKING, >= 3 depth updates in 1 s, raw confidence >= 0.5 (or AUTOMATIC valid), 0.3-5 m, 10 agreeing readings within 6 %. Focus: AF FOCUSED_LOCKED, APPROXIMATE/CALIBRATED lens, 0.1-0.6 m, depth-of-field band |

Distance reason keys: `arcore_unsupported`, `move_phone_slowly`,
`tap_to_focus`, `out_of_range`, plus `cancelled`, `camera_permission`,
`measure_failed` and (capability only) `arcore_not_installed`.

The Measure screen and night-listening notification use the Android string
resources in `android/src/main/res/values/strings.xml`; the app can translate
them by defining the same names.

## Dedicated insect-sound classifier (experimental)

```dart
final classifier = NativeInsectSoundClassifier();
final result = await classifier.classifyWavFile(privateWavPath);
```

This separate adapter bundles `ganesh333/kernel-insect-classifier` at revision
`001425d7fab4b44af5cc571174410f1c78552d0e`. It never passes that model to the
existing YAMNet `SoundClassifier`, changes `PestSenseEngine`, or downloads at
runtime. Classification runs on a serial Android background task queue.

- Input: local RIFF PCM16 WAV, mono or stereo, **16 / 44.1 / 48 kHz**, at most
  30 seconds and 6,000,000 file bytes. Other formats/rates are rejected, not
  approximately decoded. The caller owns the source file and its deletion;
  the adapter neither records nor retains or deletes it.
- Processing: scaled PCM mixed to mono; upstream RMS/peak quality gate before
  gain normalization; Kaiser-5 polyphase resampling; 2-second peak-normalized
  windows (right-zero-pad shorter clips), five evenly spaced crops for longer
  clips; centered periodic-Hann STFT 512/160, spectrum scaling, integer-bin
  0–8 kHz mel bank, natural log, per-crop standardization.
- Real LiteRT CPU inference: FLOAT32 `[1,1,64,201]` → `[1,32]` **logits**;
  softmax per crop then average; inclusive 0.6 species → genus → group rule.
  Unknown has no identification label; top labels are raw closed-set scores.
- Quality rejection and unavailable model/runtime/input have **no labels or
  scores**. Assets and metadata are SHA-256 checked. Evaluated results preserve
  `0.1.0-experimental` and the full revision; all results are experimental.
- It recognizes only 32 trained audible, sound-producing species. It is not
  grain screening, ultrasonic sensing, evidence of absence, or calibrated
  identification of arbitrary unseen species. Passing quality checks does not
  establish an insect sound: tones/noise can receive strong closed-set scores.

Weights/card: CC BY 4.0; frontend source: MIT. Attribution and the unchanged
upstream card/license are in `android/src/main/assets/insect_sound/`.
See [INSECT_SOUND_VERIFICATION.md](INSECT_SOUND_VERIFICATION.md) for actual
parity, device test commands, RED/GREEN evidence, and remaining limitations.

## Develop

```bash
dart run pigeon --input pigeons/sense_api.dart     # after bridge changes
flutter test                                       # Dart (engine mapping, SignRanker)
(cd example/android && ./gradlew :sense_ai:testDebugUnitTest)  # Kotlin (Stage 0, listen DSP, gates)
(cd example && flutter build apk --debug)          # developer harness
```
