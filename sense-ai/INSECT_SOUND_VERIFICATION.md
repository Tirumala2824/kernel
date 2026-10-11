# Insect-sound adapter verification

## Pinned assets and upstream inspection

Source: `https://huggingface.co/ganesh333/kernel-insect-classifier`
Revision: `001425d7fab4b44af5cc571174410f1c78552d0e` (ungated, CC BY 4.0 weights/card).
Downloaded using the pinned `/resolve/<revision>/...` URLs, not `main`.
Inspected `src/audio.py`, `src/inference.py`, `src/model.py`, `export_litert.py`,
README, deployment notes, configuration and all 32 labels before executing
upstream code. Python validation loaded HDF5 tensors via the inspected loader;
no `model.pt` or pickle was fetched/executed. Only TFLite/JSON/card/license and
attribution are bundled, with no runtime network code.

| Asset | SHA-256 |
|---|---|
| model.tflite (646352 bytes) | `55ad541b87d1ae0bae5a71c7ec9091fc40617051f479ac3f12996bacda6f597e` |
| labels.json | `c71894abb1c95dc877b59d48c7028cb3e9aa898d8352113ee280240b92b33748` |
| config.json | `52d8010c97b0d01a87f4f32a4e2294e6a03d1ff769352568a200e2404c618f6d` |

The interpreter actually reported FLOAT32 input `[1,1,64,201]` and FLOAT32
output `[1,32]`. Output is logits, not softmax probabilities. The model has
only this fixed spectrogram input and is incompatible with YAMNet waveform
input. Existing YAMNet/frontend/listen contracts are unchanged.

## Numerical parity (not recognition accuracy)

Five deterministic **synthetic test signals**, stored only under native test
resources, cover mono 16 kHz, short right-padded audio, five-crop 16 kHz audio
with ties-to-even offsets, stereo 44.1 kHz and mono 48 kHz.
`test/tools/generate_insect_parity.py` verifies upstream hashes before import
and regenerates WAV/features/logits/probabilities from actual upstream code.
The stored outputs are genuine model execution, not fabricated predictions;
these numerical fixtures are not insect recordings and prove no field accuracy.

Observed:
- Upstream safe-H5 PyTorch vs downloaded TFLite maximum absolute logit
  difference: **9.5367431640625e-06** over the five signals/all crops.
- Kotlin tests compare every resampled sample (tolerance `2e-6`) and every
  normalized feature (tolerance `3e-5`). All passed without widening tolerances.
  A float FFT initially missed the feature tolerance at `4.4822693e-5`;
  double FFT intermediates fixed that. The 44.1 kHz resampler matched the
  reference samples exactly in that diagnostic.
- On the attached **iQOO I2501, Android 16**, the real LiteRT interpreter passed
  all logits against desktop TFLite (`1e-4`), and the production adapter's
  WAV-to-top-five probabilities/hierarchy matched upstream (`2e-5`).
- Flutter's public adapter also returned `evaluated` through the registered
  native channel for a test-only numerical waveform. Silence returned
  `rejected`, with no labels. A missing file returned `file_unreadable`.
- Inspected the built example APK: the model hash was unchanged; it contained
  the six production insect assets and **no `insect_parity` test resources**.

## Executed commands and results

From `sense-ai/` with Flutter's bin directory on PATH:

```bash
flutter test --no-pub
# 36 tests passed
flutter analyze --no-pub
# No issues found
```

From `sense-ai/example/android/`:

```bash
"C:/Program Files/Android/Android Studio/jbr/bin/java.exe" \
  -classpath gradle/wrapper/gradle-wrapper.jar \
  org.gradle.wrapper.GradleWrapperMain \
  :sense_ai:testDebugUnitTest :sense_ai:connectedDebugAndroidTest --console=plain
# BUILD SUCCESSFUL; 52 JVM tests, 2 connected-device tests, zero failures/skips
```

From `sense-ai/example/`:

```bash
flutter test --no-pub integration_test/insect_sound_test.dart -d 10BFAT1SQT000XP
# All tests passed: native file/quality gates and real evaluated channel response
```

The checked-in Gradle shell wrapper initially could not find
`org.gradle.wrapper.GradleWrapperMain` under this Git Bash/MSYS path setup.
Direct Java invocation of the same wrapper JAR resolved it without changing
root projects or toolchain configuration. Existing AGP/Kotlin deprecation and
JDK native-access warnings remain; tests have no new failures.

For upstream regeneration, create a scratch-only Python 3.12 environment with
numpy, scipy, h5py, torch and tensorflow, then:

```bash
<scratch-venv>/Scripts/python.exe test/tools/generate_insect_parity.py \
  <inspected-pinned-upstream-directory> android/src/test/resources/insect_parity
```

Recorded library versions are in `parity.json`. On this Windows host, torch/TF
initially could not load the VC runtime. Adding Android Studio JBR's `bin` and
the venv's `Scripts` with `os.add_dll_directory` (retaining the returned handles)
resolved loading; `msvc-runtime` was installed only into the scratch venv.
No system-wide runtime installer or repository Python environment was changed.

## Behavioral RED → GREEN evidence

- Dart envelope mapping: `UnimplementedError` → mapped native fields.
- Missing plugin: escaped `MissingPluginException` → explicit unavailable.
- Malformed native envelope: null check failure/identification leakage →
  unavailable with no identification.
- Native frontend/WAV slices: `NotImplementedError` → upstream parity/reader tests.
- Native inference on phone: `NotImplementedError: local inference` → real
  WAV-to-model parity passes. The asset-only interpreter test was independently
  green and was not mistaken for adapter coverage.
- Quality/model failure: quality attempted model load, absent file/assets threw
  → quality blocks inference and unavailable envelopes carry no labels/scores.
- Memory failure: `Memory failure escaped the adapter` → unavailable.
- Channel: handler absent → background registration, dispatch, detach pass.
- Flutter registration test: expected `['file_unreadable']`, received
  `['platform_unavailable']` → wiring added to plugin attach/detach, same test
  green, then extended to verify a real evaluated inference response as well.
- Existing native and Dart sensing regressions stayed green. Additional
  hierarchy boundary tests characterize species/genus/group/unknown behavior.

## Follow-up: constant-crop parity and selected-window veto (JVM)

Reverified the pinned `src/audio.py` against the pinned remote bytes and SHA-256
`df78b3a6c79840569ac5c7fb073ac390c28de138cf493ba618073931f5975e85`
before executing it. NumPy 2.5.3 / SciPy 1.18.1 reproduced the reported four-second
PCM16 signal: first two seconds zero, next two seconds alternating ±4096. Its
whole-file quality passes and its crop starts are `[0,8000,16000,24000,32000]`.
The first crop's 12,864 raw log-mel values are all `-18.42068099975586`, but the
upstream float32 mean is `-18.420682907104492` and standard deviation is
`1.9073486328125e-06`. Consequently **every normalized first-crop value is
`0.16018247604370117`**, not zero.

Two sequential behavioral RED → GREEN cycles were run:

1. `InsectFrontendTest.silentCropsMatchEveryUpstreamFloat32NormalizedFeature`
   first failed with `silence16 feature error 0.16018248; first expected
   0.16018248, actual 0.0`. The fix implements contiguous NumPy float32
   pairwise reduction (128-value/eight-lane blocks) and float32 mean/std,
   centering, and epsilon arithmetic. The double FFT intermediates remain.
   Final maximum absolute feature errors: **0.0** for `silence16` and
   **9.536743E-7** across all five `silent_first16` crops. Existing `3e-5`
   feature and `2e-6` sample tolerances are unchanged; all old goldens pass.
2. `InsectSafetyTest.signalOutsideEverySelectedWindowRejectsBeforeAnyAssetRead`
   first failed with asset reads `expected: <0> but was: <1>`. The 30-second,
   16 kHz signal has alternating ±4096 only during seconds 3–4. Pinned upstream
   whole-file RMS is `0.02282177470624447` (quality passes), but all selected
   `[0,112000,224000,336000,448000]` crops are silent. The fixed adapter returns
   `status=rejected`, `reasons=[no_signal_in_selected_windows]`, `level=unknown`,
   `label=null`, `topLabels=[]`, and `modelVersion=none`, with **zero asset reads**.

The new gate checks the existing `0.002` RMS floor on actual selected/resampled,
right-padded two-second windows **before peak normalization**. It is an
all-windows veto only: if any selected window has usable level, every original
crop (including quiet crops), ties-to-even offset, and per-crop softmax averaging
is retained. It neither searches for replacement windows nor filters/renormalizes
crop weights. Buffer clearing and model/config/label pins are unchanged.

Additional passing characterization tests cover nonzero-but-low selected windows,
48 kHz out-of-band input attenuated by the real resampler, pre-gain/padded RMS,
unchanged waveform/offsets, and a usable window at each of the five locations.
Accepted-path JVM checks intentionally stop at the existing asset boundary;
no interpreter substitute is presented as real runtime evidence.

The two new fixture sets are **frontend-only**, generated by
`test/tools/generate_insect_normalization_parity.py`. They contain no model
predictions. Source hashes, versions, crop offsets, and provenance are recorded
in `android/src/test/resources/insect_parity/normalization.json`. All seven new
fixture files regenerated byte-for-byte in a separate scratch directory.
Regenerate from `sense-ai/` with the inspected source and NumPy/SciPy:

```bash
<scratch-venv>/Scripts/python.exe test/tools/generate_insect_normalization_parity.py \
  <inspected-pinned-upstream-directory> android/src/test/resources/insect_parity
```

Final command from `sense-ai/example/android/`:

```bash
"C:/Program Files/Android/Android Studio/jbr/bin/java.exe" \
  -classpath gradle/wrapper/gradle-wrapper.jar \
  org.gradle.wrapper.GradleWrapperMain :sense_ai:testDebugUnitTest --console=plain
# BUILD SUCCESSFUL; JUnit XML: 68 total, 67 passed, 1 skipped, 0 failures/errors.
# Insect-only subset: 16 passed, 0 skipped/failures/errors.
```

The skip is the pre-existing Windows symlink test
`ChatMediaStoreTest.canonicalContainmentNeverFollowsAnOwnedPathSymlink`; it was
also skipped in the baseline. Existing Gradle/AGP/Kotlin/JDK warnings remain.
Model/config/label asset hashes were rechecked against the pins above. This
follow-up did **not** rerun connected-device, Flutter, or APK-packaging checks;
the earlier runtime/device evidence above predates this fix. No commits made.

## Remaining limits

This is a verified numerical port and one-device runtime integration, **not a
validated mobile insect detector**. No labeled field-recording accuracy,
unknown-species rejection, ambient-noise validation, sustained thermal/battery
benchmark, microphone capture chain, or cross-device acceptance was established.
The quality gates check empty/low level/clipping on the file and usable level in
selected resampled inference windows; they are not an OOD or insect/non-insect
detector. Short nonempty clips are padded exactly as upstream and must have
usable padded-window RMS, not independently validated as adequate recordings.
Unsupported WAV encodings
and sample rates are honestly rejected. App-level capture/retention/UI wiring is
outside this package. No grain cleanliness, infestation, safety, or ultrasound
claims are supported.
