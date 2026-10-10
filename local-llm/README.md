# local_llm

Kernel's on-device LiteRT-LM layer, built on Google AI Edge **LiteRT-LM**
(`com.google.ai.edge.litertlm:litertlm-android:0.18.0`, pinned):
- grain advice (opt-in, text in, text out, never audio)
- EmbeddingGemma embeddings and model-header probing
- the Pest ID multimodal analyzer (Gemma 4 E2B, Pest ID mode only)

See [docs/guardrails.md §8 (with its amendment) and §9](../docs/guardrails.md)
and "Contracts v3/v4" in [docs/contracts.md](../docs/contracts.md).

## Public API (`package:local_llm/local_llm.dart`)

| Symbol | What it does |
|---|---|
| `RuntimeManager({LlmHost? host})`, `RuntimeManager.shared` | Owns the native engines for every class below: one engine in memory at a time (Gemma text-only, Gemma Pest ID, or EmbeddingGemma), serialised requests, unload after 3 min idle (`runtimeIdleUnload`) and on memory pressure (`trimMemory()`; the plugin also handles `onTrimMemory`). The engines use `shared` unless one is passed. |
| `typedef ModelPathResolver = Future<String?> Function()` | Injected model path (e.g. model-hub's registry). Null = no model, with no legacy fallback. Without a resolver the legacy `getExternalFilesDir("llm")` discovery is used. Paths must lie in the app's own storage (checked natively). |
| `LocalAdviceEngine({required Stream<bool> optIn, ModelPathResolver? modelPath, RuntimeManager? runtime})` | Implements `AdviceEngine`. Pass the settings opt-in stream (`watchLocalAdviceOptIn`). Behaviour as in Phase 3; waiting for the runtime counts against the 25 s budget. |
| `LocalEmbedder({ModelPathResolver? modelPath, RuntimeManager? runtime})` | Implements `Embedder` (EmbeddingGemma). Text uses the EmbeddingGemma prompts (`embeddingPrompt`); image/audio need a model whose header lists them. Matryoshka 128/256/512/768, re-normalised. Null on any failure; 15 s budget (`embedTimeout`). |
| `LiteRtModelProbe()` | Implements `ModelProbe` via `ModelInfo.from` (header only, never loads weights, not serialised). |
| `LocalPestAnalyzer({ModelPathResolver? modelPath, RuntimeManager? runtime, Stream<bool>? enabled})` | Implements `PestAnalyzer`. `enabled` defaults to always on. See "Pest ID" below. |
| `checkPestOutput` | The Pest ID guard (grain rules plus certainty, "harmless" claims, rodenticides, poisons, doses). |
| `pestPromptVersion`, `pestAnalysisBudget` (45 s), `pestGuideTimeout` (25 s), `selfConsistencySamples` (3) | Pest ID provenance and budgets. |
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

## Pest ID (`LocalPestAnalyzer`)
- **Engine:** Gemma with `visionBackend` on the main backend (GPU, CPU fallback), `audioBackend = CPU`, `maxNumImages = 2`, `ExperimentalFlags.visualTokenBudget = 560` set before the engine is created (`PestIdConfig.kt`).
- **`analyzeImage`:** three label-only runs (regex over the sanitized `allowedCardIds` + `none`, temperature 0.7, seeds 1-3), then one constrained-JSON analysis (cardId, commonName, group, taxonomyPath, aiConfidence, keyFeatures, anomalies, insights, safety, isPest). With a strict majority (2 or 3 of 3), the JSON cardId enum is that one label, so the label, its description and `agreement` (= majority count / 3) match. With a three-way split the JSON may pick any allowed id and `agreement` is the share of votes for the reported label. Images (crop, then the optional context frame) go before the text. The whole call has a 45 s budget, including queue wait and load; past it, null. Free-text fields go through `checkPestOutput`: failing list items are dropped, a failing name drops the analysis. `isPest: false` is reported as `PestGroup.notAPest`.
- **`describeSound`:** a WAV (mono, 16 kHz, 16-bit, ≤ 30 s) plus the cleaned classifier labels give a one- or two-sentence experimental description. `groupHint` is a lookup of the top classifier label (score ≥ 0.3), not an LLM output.
- **`proposeRegions`:** Gemma `box_2d` (`[ymin, xmin, ymax, xmax]`, 0-1000) as `NormalizedBox`. Empty on any failure.
- **`guide`:** text-only, grounded in up to 3 provided cards (name in the requested language, group, summary, signs, look-alikes, health risks, steps, when to call a professional, `firstAid` as "If bitten or stung:", legal text). `sources`, the `safety` enum and `reviewStatus` are never rendered; the safety level only adds a "Required wording" line ("Stay well back. If bitten or stung: get medical care…" or "Do not harm, catch or injure it; contact the State Forest Department or a licensed rescuer."). One guarded `AdviceText` or an empty stream.
- **Wording:** every Pest ID instruction forbids "safe", "safety", "treatment", "medicine", "first aid", "poison", "venom" and "kill" (plus सुरक्षित, उपचार, इलाज, दवा, ज़हर, विष for Hindi/Marathi), because `checkPestOutput` has no allowances: even "do not kill" or "safe distance" is rejected.

## Isolation guarantees
- **Pest ID only (amendment):** a user-validated crop or clip may reach the on-device engine through `pestGenerate`/`embed`. Only `PestIdConfig.kt` and `EmbedConfig.kt` may name an encoder or image/audio content; `test/isolation_test.dart` checks this.
- **No audio path for grain advice.** Prompts are rendered in `lib/src/prompts.dart` from the typed DTO fields only:
  - Enums become plain words and numbers become digits with units.
  - The one free-text field, `grainType`, is sanitized: control characters, newlines, braces, quotes and path separators are removed, and it is capped at 40 characters.

  No byte buffer or recording crosses the bridge on the advice path: `generate` carries strings (and an optional model path) only.
- **Text-only advice engine.** `LlmConfig.engineConfig` sets only the model path, the text backend (GPU, then CPU) and the cache dir. The multimodal backends of the Gemma 4 model are never configured for advice. `android/src/test/.../LlmConfigTest.kt` asserts this.
- **No `audio_ai` dependency.** `local_llm` never imports the audio-ai plugin, and audio-ai never imports this one.
- **No network.** There is no network code and no permission in the plugin manifest. This package never downloads anything; model-hub provisions files and the app passes their path.
- **No logging of prompts or outputs.** Kotlin logs only the exception class name of load or generation failures, because native messages can quote text. Native log severity is ERROR. The generation-progress event channel carries sizes and timings only, never text.
- **Output guard** (`lib/src/output_guard.dart`). It rejects:
  - treatment and chemical wording (fumigation, phosphine, celphos, pesticides, sprays, "keetnashak", "कीटनाशक", "दवा छिड़क" and equivalents in 10 Indic scripts)
  - safety claims (safe, pest-free, guaranteed)
  - lot decisions (accept, reject, approve, buy or sell advice)
  - URLs, and markdown headings and code fences

  Invisible characters and nukta variants are folded first, so they can't split a word past the guard. A rejection just means fallback.

`test/isolation_test.dart` enforces these rules on the shipped sources: no `audio_ai`, multimodal identifiers only in the two Pest ID configs, a text-only advice path, no network APIs and no print or `Log.d/i/v`.

## Engine behaviour (Kotlin, `LlmEngineHost`)
- **One engine:** loading a slot (advice, Pest ID, embedder) first closes whatever else is loaded. Status events carry the `slot`.
- **Model files:** `ModelResolver` accepts injected paths only inside the app's own storage (`PathPolicy`, canonical paths), refuses a file whose header says it is the wrong kind, and versions it as `<id>@<sha256[0..12]>` (hashed once, cached in `noBackupFilesDir/local-llm-versions`; nothing is written next to model-hub files). Legacy discovery picks the first file of the right kind (`ModelInfo` header, file-name fallback), so an EmbeddingGemma file in `llm/` is never used for advice.
- **Loading:** lazy, on `warmUp` or the first request. It tries `Backend.GPU()` first, then `Backend.CPU()`, with `cacheDir = context.cacheDir`.
- **Requests:**
  - Each request gets one short-lived `Conversation` with `SamplerConfig(topK = 40, topP = 0.9, temperature = 0.3)` and `maxOutputToken = 220`. The conversation is closed afterwards.
  - Only one request runs at a time. Others get `busy`.
  - The 25 s budget includes waiting for the load, but a timed-out request does not abort the load.
- **Unloading:** after 3 minutes idle, on `onTrimMemory(>= TRIM_MEMORY_RUNNING_LOW)` (which includes the app going to the background), on opt-out, before an import replaces the model, and before a delete.
- **GPU / NPU libraries:** the plugin manifest declares `libOpenCL.so`, `libvndksupport.so` and `libcdsprpc.so` (Qualcomm FastRPC) as optional `<uses-native-library>` entries. Manifest merging copies them into the app's `<application>`, so the app manifest needs no change.
- **R8:** `consumer-rules.pro` keeps `com.google.ai.edge.litertlm.**`, because the JNI library calls back into it by name.

## Commands
```bash
# from local-llm/
flutter analyze
flutter test                                   # prompts, guards, engines, runtime, Pest ID, isolation
dart run pigeon --input pigeons/llm_api.dart   # after bridge changes
# from local-llm/example/android (after one `flutter build apk` in example/)
./gradlew :local_llm:testDebugUnitTest         # LlmConfig (text-only), PestIdConfig, EmbedConfig, ModelStore, ModelResolver
# on the device (lead only), from local-llm/example
flutter test integration_test -d <device-id>
```

## To verify on the iQOO 15
- Which backend gets used (`gpu` vs `cpu`), the load time, the time to the first token and the total time. The integration test prints these.
- `liblitertlm_jni.so` looks up `libLiteRtGpuAccelerator.so`, `libLiteRtOpenClAccelerator.so` and others by name, and the AAR doesn't ship them. If GPU init fails, the engine falls back to CPU; check which one is reported.
- Peak memory while loaded, whether it unloads when the app goes to the background, and coexistence with a scan (audio-ai LiteRT 1.4.2) in the same process.
- Output quality in English and Hindi, and how often the guard rejects.
- Phase 4: Pest ID load time with the vision/audio encoders and the full `analyzeImage` time (3 votes + JSON) against the 45 s budget; whether `SamplerConfig.seed` makes the votes differ; whether constrained decoding (`ResponseFormat.json/regex`) is honoured; `ModelInfo.from` cost on a 2.5 GB file; EmbeddingGemma 2 header (modalities, dimension) and embedding latency; the model-hub path passing `PathPolicy` (canonical `/storage/emulated/0/...`).
