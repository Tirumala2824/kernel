# audio_ai

The Kernel on-device acoustic scan engine is a Flutter plugin with an Android/Kotlin implementation. It has no network code. Owner: `audio-ai-dev`.

## Public API (contracts v2)
`package:audio_ai/audio_ai.dart` exports one class:

```dart
class NativeScanEngine implements ScanEngine {   // kernel_contracts
  NativeScanEngine();
  Future<ScanOutcome> captureAndAnalyze(String itemId, {bool retainAudio = false, bool haptics = true});
  Stream<CaptureLevel> captureLevels();          // broadcast, ~20 Hz, only while recording
  Future<EngineInfo> info();
  Future<void> deleteRetainedAudio();
  Future<String?> retainedAudioPath(String scanId);
}
```
- `captureAndAnalyze` never throws. Audio, permission, bridge and model problems all come back as RETRY or NOT_EVALUATED outcomes that pass `invariantViolations()`. The app requests RECORD_AUDIO itself.
  - `haptics: false` means no vibration at all (no start, finish or retry cue, and no settle wait).
  - `ScanOutcome.audioRetained` is true only if `files/recordings/<scanId>.wav` was actually written. That needs `retainAudio: true`, a successful write, and a capture the system did not silence. A kept RETRY recording also reports true.
  - `latencyMs` is capture end to result ready: gate, resample, log-mel, inference, and the WAV write if one was retained.
- `captureLevels()` is one process-wide broadcast stream. All listeners and all `NativeScanEngine` instances share it, because the native side has a single event sink.
  - It emits one `CaptureLevel` per 50 ms of kept audio while a capture is recording: 40 readings for a full 2 s scan, the last one with `elapsedMs == targetMs`.
  - Each reading has `elapsedMs`, `targetMs`, `rmsDbfs` and `peakDbfs`. RMS is taken after removing the window mean. Both values are pinned to [-120, 0] dBFS.
  - Nothing is emitted while idle, during the start cue, during the 100 ms warm-up, or after the recording ends. Levels only, never samples.
  - Listen before calling `captureAndAnalyze`. Error events are dropped.
- `retainedAudioPath(scanId)` returns the absolute app-private path, or null if not retained, deleted, or the id is not a UUID. It throws if the native side is unreachable, as does `deleteRetainedAudio`, so an export never silently drops files.
- `EngineInfo` fields:
  - `modelNote`: the manifest `note`, null with no usable model.
  - `audioSource`: `"VOICE_RECOGNITION"`.
  - `effectiveSampleRate`: the rate AudioRecord gave the app.
  - `deviceInputSampleRate`: the HAL capture rate before resampling, from `AudioRecordingConfiguration` (API 29+).

  Both rates are null until the first capture in the process.

## Pipeline (Kotlin, `android/src/main/kotlin/com/kernel/audio_ai/`)
1. `ScanEngineHost`: checks the permission, plays the start cue (if haptics are on) and waits it out, then captures on its own audio-priority thread.
2. `AudioCapture`: AudioRecord with VOICE_RECOGNITION, mono PCM16.
   - It requests 16 kHz and falls back to 48 or 44.1 kHz.
   - A 100 ms warm-up is discarded, then 2000 ms are kept, read in 50 ms blocks.
   - It records the effective rate and, on API 29+, the HAL rate.
3. `LevelMeter`: inside the read loop, it computes one RMS/peak dBFS reading per 50 ms window from running sums. `CaptureLevelEmitter` posts each reading to the platform thread for the pigeon event channel.
4. `QualityGate`: pure Kotlin, run on the raw device PCM. Checks silence, clipping, high noise (noise floor) and too-short.
5. `Resampler` → 16 kHz, only when the device delivered another rate (Hann-windowed sinc).
6. `LogMel` + `LogMelConfig`: pure Kotlin. With a model bundled, the config comes from its manifest. `LogMelConfig.PROVISIONAL` is used only while no model is bundled.
7. `ModelRunner`: LiteRT 1.4.2 `Interpreter` on the CPU (4 threads), used only if a valid model is bundled. With no model the result is NOT_EVALUATED, `modelVersion "none"`, `experimental true` and `confidence null`.
8. `Haptics`: start, finish and retry cues. They respect the in-app flag and the system touch-feedback setting.
9. `RecordingStore`: only with `retainAudio: true`. Writes `files/recordings/<scanId>.wav` (PCM16 mono at the effective rate) atomically in app-private storage.

### Benchmark log
Debuggable builds log one line per scan to logcat tag `AudioAi`. Values are in ms. There are no audio values.
```
bench scan=<id> settleMs= captureMs= gateMs= resampleMs= logMelMs= inferenceMs= retainMs= latencyMs= totalMs=
```
- `capture`: AudioRecord setup + warm-up + 2 s.
- `latencyMs`: what `ScanOutcome.latencyMs` reports.
- `total`: start cue to result.

The `gate` line has the dBFS levels used to calibrate the quality gate, and `capture config` has the source plus the client and HAL rates. Read them with `adb logcat -s AudioAi`.

## Model manifest
This is the format `model-training/` exports. A model is **two files** with the same base name, placed in `android/src/main/assets/models/` (the APK's `assets/models/`):

```
models/<name>.tflite        LiteRT flatbuffer
models/<name>.properties    this manifest (UTF-8)
```
There must be exactly one `.tflite` in that folder. If any rule below is broken (no manifest, an unknown key, a bad value, more than one model, or tensor shapes that don't match), the model is **unusable**. The engine then logs `bundled model unusable: <reason>` to tag `AudioAi` and behaves exactly as if no model were bundled: NOT_EVALUATED, `modelVersion "none"`, `experimental true`, `modelNote null`. Nothing is guessed.

### Syntax
The file uses Java `.properties` syntax, read as UTF-8:
- Write one `key=value` per line.
- `#` or `!` starts a comment **only at the start of a line**. A `#` after a value is part of the value.
- Leading and trailing whitespace of values is ignored.
- `\` is an escape character: a trailing `\` continues the line, and `\uXXXX` is accepted.
- Keys are case-sensitive.
- Enum and boolean values are case-insensitive.

### Keys
| Key | Type | Required | Rule |
|---|---|---|---|
| `version` | string | yes | Non-empty, not `none`. Stored on every scan (`ScanOutcome.modelVersion`) and used by ranking to compare scans, so it must be unique and immutable per exported model, e.g. `proxy-cnn-2026-10-12`. |
| `labels` | comma list | yes | Output tensor index order. 2 or more unique names from `clean`, `uncertain`, `infested` (see mapping below). Spaces around names are ignored. |
| `output` | enum | yes | `probabilities`: each score must be in [-0.001, 1.001], clamped to [0, 1]. A sum of 1 is not checked. `logits`: softmax is applied on the device in float64. |
| `input_layout` | enum | yes | `mels_frames` or `frames_mels` (see tensors below). |
| `validation` | enum | yes | `proxy`: trained/evaluated on non-grain proxy recordings. `field`: evaluated on labelled recordings of real sacks. |
| `experimental` | boolean | no (default `true`) | `true` or `false`. **`validation=proxy` requires `true`**; `proxy` with `false` makes the model unusable. Only `field` may say `false`. Becomes `ScanOutcome.experimental`. |
| `note` | string | **yes for `proxy`**, optional for `field` | Human-readable provenance, at most 500 characters on one logical line, e.g. `Trained on non-grain proxy insect recordings. Not validated on grain sacks.` Becomes `EngineInfo.modelNote`, which the UI shows with every result and puts in PDF headers. |
| `uncertain_below` | decimal | no | Uncertain confidence band. It must be strictly between `1/len(labels)` and `1`. See classification below. |
| `sample_rate` | int | yes | Must be `16000`. |
| `n_fft` | int | yes | Power of two, at least 2. |
| `win_length` | int | yes | 1 to `n_fft`. |
| `hop_length` | int | yes | At least 1. |
| `n_mels` | int | yes | At least 1. Must equal the mel dimension of the input tensor. |
| `f_min` | decimal Hz | yes | 0 or more. |
| `f_max` | decimal Hz | yes | Above `f_min` and at most `sample_rate / 2`. |
| `log_offset` | decimal | yes | Above 0. |
| `power` | decimal | yes | `1` = magnitude spectrum, `2` = power spectrum. |
| `meta.*` | string | no | Free-form (dataset id, git commit, export date). Ignored by the engine. |

Any other key makes the model unusable, so a typo such as `uncertian_below` cannot silently disable a rule. Integers are plain decimal digits (`16000`, not `16000.0`). Decimals are Java `Double.parseDouble` syntax (`125`, `7500.0`, `1e-3`) and must be finite.

### Label mapping
| Manifest label | Contract `Classification` |
|---|---|
| `clean` | `clean` |
| `uncertain` | `uncertain` |
| `infested` | `infested` |

`notEvaluated` is never a model label. The engine reports it whenever the gate says RETRY, no valid model is bundled, the output is invalid (wrong length, non-finite, probabilities out of range), or inference fails. A binary model uses `labels=clean,infested`.

### Classification and confidence
Inference runs only on recordings that pass the quality gate.
1. `p` = the probabilities (or `softmax(logits)`), as float32 widened to float64.
2. `top` = the index of the largest `p`. The first index wins a tie.
3. `confidence = p[top]`, always the probability of the model's top output class.
4. If `uncertain_below` is set and `p[top] < uncertain_below`, the class is `uncertain` and `confidence` stays `p[top]`, which is below the band. Otherwise the class is `labels[top]`.

The band test is strict and done in float64 after widening. For example, `0.7f` widens to 0.69999998, which is below `0.7`. Choose thresholds with that in mind, or use values that are exact in float32 (0.75, 0.625).

### Tensors
The model must have exactly one input and one output. Both are **float32**: quantised I/O is rejected, but internal weight quantisation with float I/O is fine. Use builtin ops only (`tf.lite.OpsSet.TFLITE_BUILTINS`). The app bundles plain `litert:1.4.2` with no Flex/select-TF ops.

| `input_layout` | Input shape | Element `[.., a, b]` |
|---|---|---|
| `mels_frames` | `[1, n_mels, F]` or `[1, n_mels, F, 1]` | `[m, t]` |
| `frames_mels` | `[1, F, n_mels]` or `[1, F, n_mels, 1]` | `[t, m]` |

- The batch is 1.
- `F` (frames) is read from the model and must be at least 1. A full 2000 ms capture gives **198 frames** at the default params (`1 + floor((32000 - 400) / 160)`). The engine feeds frames `0..F-1`, oldest first, and ignores the rest. Use `F <= 198`. A capture that produced fewer than `F` frames is NOT_EVALUATED. That only happens to interrupted captures of 1500 to 2000 ms; 1500 ms gives 148 frames.
- `m = 0` is the lowest mel band.
- Values are raw `ln(mel + log_offset)`. No mean/variance normalisation, dB scaling or clipping is applied on the device. Any normalisation must be **inside the model graph**, with constants baked in.
- Output shape must be exactly `[1, len(labels)]`.

### Log-mel algorithm (`LogMel.kt`, must be matched in Python)
The keys above are the only free parameters. Everything else is fixed:
1. Audio: VOICE_RECOGNITION source, mono PCM16. A 100 ms warm-up is dropped, then 2000 ms are kept. The quality gate runs on this PCM, and failing clips never reach the model.
2. If the device delivered 48 or 44.1 kHz, the audio is resampled to 16 kHz with a Hann-windowed sinc: 16 zero crossings, cutoff 0.95 x the lower Nyquist, normalised by the kernel sum, output length `floor(n * 16000 / rate)`. Train on 16 kHz audio and use a high-quality resampler for other source rates.
3. `x[n] = pcm[n] / 32768` in float32. No DC removal, pre-emphasis or dither.
4. Framing: frame `t` covers samples `[t*hop_length, t*hop_length + win_length)`. The frame count is `1 + floor((N - win_length) / hop_length)`, or 0 if `N < win_length`. There is no centre or reflect padding, and trailing samples that do not fill a frame are dropped.
5. Window: periodic Hann of length `win_length`, `w[n] = 0.5 - 0.5*cos(2*pi*n / win_length)`. This is `scipy.signal.get_window('hann', win_length, fftbins=True)` or `torch.hann_window(win_length, periodic=True)`.
6. The windowed frame is placed at the start of an `n_fft` buffer and zero-padded at the end. Then a real FFT, keeping bins `0..n_fft/2`, and `S[k] = |X[k]|` (to the power `power`).
7. Mel filterbank:
   - HTK scale: `mel(f) = 1127 * ln(1 + f/700)`.
   - `n_mels + 2` edges are equally spaced in mel from `mel(f_min)` to `mel(f_max)`.
   - Bin `k` sits at `mel(k * sample_rate / n_fft)`.
   - Band `m` has edges `(e[m], e[m+1], e[m+2])` and weight `max(0, min((mel_k - e[m]) / (e[m+1] - e[m]), (e[m+2] - mel_k) / (e[m+2] - e[m+1])))`.
   - The DC bin's weight is 0. There is no area or Slaney normalisation.

   This is exactly `tf.signal.linear_to_mel_weight_matrix(n_mels, n_fft//2 + 1, sample_rate, f_min, f_max)`, transposed.
8. `out[t, m] = ln(sum_k W[m, k] * S[k] + log_offset)`: natural log, computed in float64 and stored as float32.

Steps 3 to 8 match `tf.signal.stft(x, frame_length=win_length, frame_step=hop_length, fft_length=n_fft, window_fn=tf.signal.hann_window (periodic), pad_end=False)`, then `abs`, then the mel matmul above, then `log(. + log_offset)`. They do **not** match `librosa.stft`. librosa frames by `n_fft` and centres a shorter window inside it, which shifts each frame by `(n_fft - win_length) / 2` samples and changes the frame count, and its default `center=True` pads the signal. librosa's default mel filters are also Slaney-normalised.

The defaults (`LogMelConfig.PROVISIONAL`, decisions-log #18) are 512-point FFT, 400-sample (25 ms) window, 160-sample (10 ms) hop, 64 mels, 125 to 7500 Hz, `log_offset=0.001`, `power=1`. A manifest may choose other values within the rules. Parity between the Python port and `LogMel.kt` is proved by the golden fixtures in `tests/fixtures/logmel/`, which `model-training/` owns.

### Example (proxy model)
```properties
version=proxy-cnn-2026-10-12
# Output index order of the [1, 2] output tensor.
labels=clean,infested
output=logits
input_layout=mels_frames
validation=proxy
experimental=true
note=Trained on non-grain proxy insect recordings. Not validated on grain sacks.
uncertain_below=0.75
sample_rate=16000
n_fft=512
win_length=400
hop_length=160
n_mels=64
f_min=125
f_max=7500
log_offset=0.001
power=1
meta.dataset=proxy-v1
meta.git_commit=0000000
```
With this manifest the input tensor is `[1, 64, F, 1]` (or `[1, 64, F]`) with `F <= 198`, and the output is `[1, 2]` logits.

## Development
```bash
dart run pigeon --input pigeons/scan_api.dart            # after editing the bridge
flutter analyze && flutter test                          # Dart (from audio-ai/)
(cd example/android && ./gradlew :audio_ai:testDebugUnitTest)   # Kotlin unit tests
(cd example && flutter build apk --debug)                # developer screen app (live levels)
```
`example/android/gradlew` is gitignored. The first `flutter build apk` in `example/` generates it.

Logs (tag `AudioAi`) contain only technical data: the capture config, and in debuggable builds the aggregate gate levels in dBFS and the stage timings. They never contain audio, live levels or spectrogram values.
