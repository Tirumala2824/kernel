# local_llm

Kernel's opt-in, on-device language-model advice layer, built on Google AI Edge
**LiteRT-LM** (`com.google.ai.edge.litertlm:litertlm-android:0.18.0`, pinned).
It takes text in and gives text out, and it never handles audio. See
[docs/guardrails.md §8](../docs/guardrails.md) and "Contracts v3" in
[docs/contracts.md](../docs/contracts.md).

## Public API (`package:local_llm/local_llm.dart`)

| Symbol | What it does |
|---|---|
| `LocalAdviceEngine({required Stream<bool> optIn})` | Implements `AdviceEngine`. Pass the settings opt-in stream (`watchLocalAdviceOptIn`). |
| `LocalAdviceEngine.warmUp()` | Optional. Loads the model ahead of the first request, for example when a result screen opens. It does nothing unless the user has opted in. |
| `LocalAdviceEngine.dispose()` | Stops the opt-in and native subscriptions. |
| `LocalModelManager()` | Implements `AdviceModelManager`, with `importFromUri`, `deleteModel` and `freeSpaceBytes`. |
| `Future<String?> pickLitertlmUri()` | Opens the system file picker (ACTION_OPEN_DOCUMENT, any type, files on the phone only). Returns a `content://` URI if the picked file's name ends in `.litertlm`, otherwise null. It also returns null on cancel or when no activity is attached. |
| `checkOutput`, `GuardResult`, `GuardCategory` | The on-device output guard, exported so the app can reuse it. |
| `promptVersion` | Version of the prompt templates (`kernel-advice-prompts-v1`). |
| `adviceTimeout` | 25 s, the whole-request budget. |

### Status (`watchStatus()`)
New listeners get the current status first, then every change.

| Status | Meaning |
|---|---|
| `optedOut` | The opt-in is false or has not been read yet. Nothing reaches the native side. Switching it off also unloads the model. |
| `noModel` | Opted in, but there is no `.litertlm` in the model folder. |
| `ready` | A model is installed. If it isn't in memory yet, it loads on the first request. |
| `loading` | The engine is initializing (up to about 10 s). It tries GPU first, then CPU. |
| `busy` | A generation is running. Other requests end at once (fallback). |
| `failed` | The model failed on both GPU and CPU, or the plugin is unreachable. It is not retried until the model file changes. |

### Generation
`explainResult`, `draftReportNarrative` and `suggestReminderText` never throw. Each stream emits **at most one event**: the complete text, after it passes the guard, with `complete: true`, `experimental: true`, `modelVersion` from the sidecar and the language tag that was asked for. **An empty stream means "show the static localized copy".** That happens when:
- the user is opted out, there's no model, the engine is busy, or the load failed
- the 25 s budget runs out (the native request is cancelled)
- there is a native error
- the guard rejects the text

Cancelling the subscription cancels the native request. Partial output is never released, because the guard needs the full text.

The app must label the text "Generated on this phone — experimental" plus its `modelVersion`, and must not request advice while a scan capture is running.

## Model import
1. `final uri = await pickLitertlmUri();` The user picks the file, e.g. the `gemma-4-E2B-it.litertlm` downloaded by AI Edge Gallery.
2. `LocalModelManager().importFromUri(uri)` streams `ModelImportProgress`:
   - Name check: the file must be `*.litertlm`. The name is sanitized to `[A-Za-z0-9._-]`.
   - Free-space check: it needs size + 10 %. Otherwise it reports `failed` with `insufficient_space: need N bytes, free M bytes`.
   - `copying`: the file is stream-copied through the ContentResolver to `files/llm/<name>.part` and hashed on the way. Progress arrives about 4 times a second.
   - `verifying`: the size is checked and the `.part` is re-read for a streamed sha256 that must match.
   - It then unloads the engine, deletes any previous model and sidecar, and renames `.part` to `<name>`.
   - It writes the sidecar `<id>.json` = `{id, version: "<id>@<sha256[0..12]>", sizeBytes, importedAt}`.
   - `done`, or `failed` with a short technical reason. The stream always ends with exactly one terminal event and then closes.
3. `deleteModel()` unloads first, then removes the model, the sidecar and any partial copy. It throws if a file can't be deleted.

The model folder is `getExternalFilesDir("llm")`, which is `/sdcard/Android/data/<package>/files/llm/`. It is app-specific, needs no permission, is removed on uninstall, and is excluded from git (`*.litertlm`). Discovery uses the first `*.litertlm` by name. Partial `.part` files are ignored.

### Developer shortcut (adb)
On the iQOO 15, AI Edge Gallery already has the model:
```bash
adb shell mkdir -p /sdcard/Android/data/com.kernel.kernel_app/files/llm/
adb shell cp /sdcard/Android/data/com.google.ai.edge.gallery/files/Gemma_4_E2B_it/6e5c4f1e395deb959c494953478fa5cec4b8008f/gemma-4-E2B-it.litertlm /sdcard/Android/data/com.kernel.kernel_app/files/llm/
```
For the example harness, use `com.kernel.local_llm_example` instead of `com.kernel.kernel_app`. A file copied this way has no sidecar. The first `modelInfo()` call (which every request makes) "adopts" it: it does one streamed sha256 pass of about 2.5 GB, takes a few seconds, and writes the sidecar.

## Isolation guarantees
- **No audio path.** Prompts are rendered in `lib/src/prompts.dart` from the typed DTO fields only:
  - Enums become plain words and numbers become digits with units.
  - The one free-text field, `grainType`, is sanitized: control characters, newlines, braces, quotes and path separators are removed, and it is capped at 40 characters.

  No path, byte buffer or recording ever crosses the bridge. The pigeon API (`pigeons/llm_api.dart`) has no such field.
- **Text-only engine.** `LlmConfig.engineConfig` sets only the model path, the text backend (GPU, then CPU) and the cache dir. The multimodal backends of the Gemma 4 model are never configured. `android/src/test/.../LlmConfigTest.kt` asserts this.
- **No `audio_ai` dependency.** `local_llm` never imports the audio-ai plugin, and audio-ai never imports this one.
- **No network.** There is no network code and no permission in the plugin manifest. The model is never downloaded; the user imports it.
- **No logging of prompts or outputs.** Kotlin logs only the exception class name of load or generation failures, because native messages can quote text. Native log severity is ERROR. The generation-progress event channel carries sizes and timings only, never text.
- **Output guard** (`lib/src/output_guard.dart`). It rejects:
  - treatment and chemical wording (fumigation, phosphine, celphos, pesticides, sprays, "keetnashak", "कीटनाशक", "दवा छिड़क" and equivalents in 10 Indic scripts)
  - safety claims (safe, pest-free, guaranteed)
  - lot decisions (accept, reject, approve, buy or sell advice)
  - URLs, and markdown headings and code fences

  Invisible characters and nukta variants are folded first, so they can't split a word past the guard. A rejection just means fallback.

`test/isolation_test.dart` enforces these rules on the shipped sources: no `audio_ai`, no multimodal content or backend identifiers, no network APIs and no print or `Log.d/i/v`.

## Engine behaviour (Kotlin, `LlmEngineHost`)
- **Loading:** lazy, on `warmUp` or the first request. It tries `Backend.GPU()` first, then `Backend.CPU()`, with `cacheDir = context.cacheDir`.
- **Requests:**
  - Each request gets one short-lived `Conversation` with `SamplerConfig(topK = 40, topP = 0.9, temperature = 0.3)` and `maxOutputToken = 220`. The conversation is closed afterwards.
  - Only one request runs at a time. Others get `busy`.
  - The 25 s budget includes waiting for the load, but a timed-out request does not abort the load.
- **Unloading:** after 3 minutes idle, on `onTrimMemory(>= TRIM_MEMORY_RUNNING_LOW)` (which includes the app going to the background), on opt-out, before an import replaces the model, and before a delete.
- **GPU libraries:** the plugin manifest declares `libOpenCL.so` and `libvndksupport.so` as optional `<uses-native-library>` entries. Manifest merging copies them into the app's `<application>`, so the app manifest needs no change.
- **R8:** `consumer-rules.pro` keeps `com.google.ai.edge.litertlm.**`, because the JNI library calls back into it by name.

## Commands
```bash
# from local-llm/
flutter analyze
flutter test                                   # prompts, guard, engine, manager, isolation
dart run pigeon --input pigeons/llm_api.dart   # after bridge changes
# from local-llm/example/android (after one `flutter build apk` in example/)
./gradlew :local_llm:testDebugUnitTest         # LlmConfig (text-only) + ModelStore
# on the device (lead only), from local-llm/example
flutter test integration_test -d <device-id>
```

## To verify on the iQOO 15
- Which backend gets used (`gpu` vs `cpu`), the load time, the time to the first token and the total time. The integration test prints these.
- `liblitertlm_jni.so` looks up `libLiteRtGpuAccelerator.so`, `libLiteRtOpenClAccelerator.so` and others by name, and the AAR doesn't ship them. If GPU init fails, the engine falls back to CPU; check which one is reported.
- Peak memory while loaded, whether it unloads when the app goes to the background, and coexistence with a scan (audio-ai LiteRT 1.4.2) in the same process.
- Output quality in English and Hindi, and how often the guard rejects.
