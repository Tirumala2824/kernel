# Decisions log

Append new decisions at the bottom. Never rewrite past entries; supersede them with a new one.

| # | Date | Decision | Why |
|---|---|---|---|
| 1 | 2026-10-09 | **Flutter UI + native Kotlin Android plugin** for audio/AI | Team choice. The audio pipeline stays native (AudioRecord, DSP, LiteRT) and is reached via pigeon |
| 2 | 2026-10-09 | **No mocks in the first pass.** The PRD's V0.1 clickable mock is replaced by a real-data foundation. With no model, scans return NOT_EVALUATED | No fake data or simulated results anywhere in the app; test doubles only in test folders |
| 3 | 2026-10-09 | **GCP deferred** to V3, metadata-only | Single-device demo; PRD B-12.2 says GCP is not mandatory |
| 4 | 2026-10-09 | Repo layout `contracts/ app-ui/ audio-ai/ data-operations/ tests/ docs/` as a Dart pub workspace | PRD handoff boundaries plus one shared contracts package |
| 5 | 2026-10-09 | Stack: riverpod, go_router, drift, pigeon, flutter_local_notifications, pdf/csv/share_plus, permission_handler, connectivity_plus | Typed, testable, offline |
| 6 | 2026-10-09 | Three project subagents: ui-dev, audio-ai-dev, data-ops-dev. The lead (main session) owns `contracts/` and root files | Mirrors PRD D1/D2/D3 ownership |

| 7 | 2026-10-09 | Ranking tie-break: the queue uses the modelVersion shared by the most latest-valid scans. A tie goes to the most recently used, then the greatest version string. Ties within the queue are broken by item id | data-ops-dev proposal, accepted |
| 8 | 2026-10-09 | `locationId` filters in ranking/reports include nested locations. `watchByLocation` matches the item's own location only. ReportScope filters are AND, and role is always applied | data-ops-dev proposal, accepted |
| 9 | 2026-10-09 | Scans and verified inspection findings are immutable at the DB level (triggers). A correction is a new inspection | Guardrail §6 |
| 10 | 2026-10-09 | `ScanEngine.deleteRetainedAudio()` added to the contract. PrivacyService calls it via `DataOperations.open(deleteRetainedAudio:)` | Retained audio lives in the audio-ai filesDir |
| 11 | 2026-10-09 | `connectivity_plus` pinned to 7.3.1 | 7.3.2 → nm 0.6 → dbus ^0.8 conflicts with flutter_local_notifications_linux (dbus ^0.7). Linux-only; unpin when the notifications plugin moves to dbus 0.8 |
| 12 | 2026-10-09 | Android Auto Backup disabled (`allowBackup=false`) | Stops the grain DB from leaving the device through cloud backup |
| 13 | 2026-10-09 | No harvest/session entity in V0.1. The farmer subtitle uses the role tagline; FPO "scanned this session" is shown as "scanned today" | Avoids a new entity before it is needed |
| 14 | 2026-10-09 | The UI requests the mic and POST_NOTIFICATIONS permissions. The engine returns RETRY/permissionDenied and never prompts | One owner per permission prompt |
| 15 | 2026-10-10 | Audio source is VOICE_RECOGNITION (AGC and noise suppression off by spec), to be compared against UNPROCESSED on the iQOO 15 | Specified sensitivity on Android; UNPROCESSED is about 18 dB quieter |
| 16 | 2026-10-10 | LiteRT pinned to 1.4.2 (CPU, 4 threads) | 2.3.0 pulls Play AI delivery and androidx.work, which bring network services and extra permissions. That breaks the bundled-model-only and no-network rules |
| 17 | 2026-10-10 | A model ships as `models/<name>.tflite` plus `<name>.properties` (version, labels, output type, input layout, every log-mel param). Missing or invalid manifest ⇒ treated as no model | Model integrity; preprocessing travels with the model |
| 18 | 2026-10-10 | Provisional log-mel: 512-pt FFT, 25 ms window, 10 ms hop, 64 mels, 125–7500 Hz, log offset 0.001 | Common 16 kHz front end (YAMNet-style) until the training pipeline is known |
| 19 | 2026-10-10 | Provisional quality gate: too-short <1500 ms; silence RMS < -70 dBFS; clipping >0.1% of samples ≥99% FS; high noise when the quietest 10% > -45 dBFS. SNR is logged but not gated | Must be calibrated on the iQOO 15 with real sacks |
| 20 | 2026-10-10 | App compileSdk 37 | permission_handler_android 13 requires it |
| 21 | 2026-10-10 | `ScanOutcome.sampleRate` is the rate AudioRecord actually delivered to the app. The hardware rate is in logcat (`AudioAi`) only | audio-ai-dev interpretation, accepted for V0.1 |
| 22 | 2026-10-10 | Phase 2 model strategy: a **proxy** model trained on public, licence-clear insect-acoustic data, always `experimental=true` and `validation=proxy` with a visible note. Plus research recording mode, so the model can be retrained on the team's own inspection-confirmed grain samples | User choice. A working product without false claims |
| 23 | 2026-10-10 | Brand: "grain + sound wave" mark (forest kernel, amber waveform seam). Manrope for Latin UI. Indic UI text falls back to Android system Noto fonts. Noto Indic fonts are bundled only in data-operations for PDFs | User choice. Avoids duplicating ~MBs of fonts |
| 24 | 2026-10-10 | Sack QR payload `kernel:item:<itemId>`. Any other payload is ignored | Shared by the label PDF and the scanner |
| 25 | 2026-10-10 | Languages: en plus hi, bn, te, mr, ta, gu, kn, ml, or, pa. Machine-drafted, with native review required (docs/glossary.md) | User: "all major languages" |
| 26 | 2026-10-10 | Archiving is a soft delete (`archivedAt`). Scan history is never deleted except by the user's "delete all history" | Guardrail §6 and the PRD's immutable history |
| 27 | 2026-10-10 | Model manifest is strict:<br>• `validation` required<br>• a proxy model needs a non-empty `note` (≤500 chars) as well as `experimental=true`<br>• unknown keys are rejected except `meta.*`<br>Full spec: `audio-ai/README.md` | Stops a typo from silently disabling the uncertain band, or a proxy model losing its disclaimer |
| 28 | 2026-10-10 | Supersedes #21: the hardware input rate is now exposed as `EngineInfo.deviceInputSampleRate` (API 29+, after the first capture). `ScanOutcome.sampleRate` is still the rate delivered to the app | W2 |
| 29 | 2026-10-10 | `latencyMs` = capture end to result (includes the WAV write when retained). Total including capture appears only in logcat `bench … totalMs` | Keeps the v1 contract meaning |
| 30 | 2026-10-10 | `captureLevels()` is one process-wide broadcast stream. The UI subscribes before calling `captureAndAnalyze` | The native side has a single event sink |
| 31 | 2026-10-10 | DB schema v2. The migration only adds columns, tables, indexes and triggers, and never changes rows. Immutability triggers now also cover `audio_retained`, `photo_paths` and labels | W4 |
| 32 | 2026-10-10 | Archiving:<br>• hides records from every `watch*`, ranking and report (`get`/`watchForItem` still resolve them)<br>• cancels the item's reminders; unarchiving reschedules them<br>• new records can't reference archived parents | W4, accepted |
| 33 | 2026-10-10 | Labelled samples:<br>• one label per recording<br>• a RETRY recording can only be `unknown`<br>• research mode must be on | Guardrail: RETRY never carries a pest class |
| 34 | 2026-10-10 | PDF Indic text renders with correct glyphs but **without complex shaping** (pdf 3.13.1 has no GSUB/GPOS). Conjuncts and pre-base vowel signs look wrong; text is readable but not typographically correct. CSV is exact UTF-8. Revisit: rasterise text runs, or switch PDF engine | W4 finding |
| 35 | 2026-10-10 | `deleteAllHistory` also deletes exported dataset ZIPs (they contain audio) | Privacy |
| 36 | 2026-10-10 | Proxy model kernel-proxy-0.1 trained on TreeVibes field recordings (CC0) with provenance-grouped TV-PAVC folds (CC BY 4.0), with `uncertain_below=0.7`. Test results on unseen trees: balanced accuracy 67.3%, about 50% uncertain. The graph is band-limited to 3.8 kHz | W3, see model-training/MODEL_CARD.md |
| 37 | 2026-10-10 | 10 Indic locales shipped, **all machine-drafted, with native review pending**: hi, bn, te, mr, ta, gu, kn, ml, or, pa. English is the fallback for unsupported device languages (`preferred-supported-locales: [en]`) | W5. Uncertain terms are listed in the W5 report: scan vs inspection, "Clean" label, "experimental" |
| 38 | 2026-10-10 | Release builds ship per ABI (arm64 is about 38 MB). No INTERNET permission in release; mobile_scanner's ML Kit telemetry INTERNET is removed through the release manifest | W1/W6 |
| 39 | 2026-10-10 | Phase 3: an on-device LLM advice layer on Google AI Edge **LiteRT-LM**, in a new isolated plugin `local-llm/`. Opt-in, text-only DTO inputs (audio excluded by type), output guard, silent fallback to static copy | User request. Guardrails §8 |
| 40 | 2026-10-10 | LLM model delivery is **import only** (SAF picker into `getExternalFilesDir("llm")`, or a file already in that folder). There is no in-app download, so release keeps no INTERNET | User choice |
| 41 | 2026-10-10 | Default LLM: **Gemma 4 E2B-it** (`gemma-4-E2B-it.litertlm`, 2.59 GB), the file AI Edge Gallery downloaded on the iQOO 15. Text-only, GPU→CPU. Kernel uses temperature 0.3 and ≤220 output tokens for advice. Gallery's defaults are topK 64, topP 0.95, temperature 1.0 | User: "follow AI Edge Gallery" |
| 42 | 2026-10-10 | Generated advice is shown, not persisted. The only persisted LLM text is an opt-in report narrative, which carries its modelVersion inside the exported file | Keeps records human/sensor-sourced |
| 43 | 2026-10-10 | Next-action and analytics logic lives in data-operations (`AnalyticsService`), which returns typed kinds and counts. The UI localizes them. No English strings come out of the data layer | Keeps l10n correct |
| 44 | 2026-10-10 | Next-action semantics:<br>• "scanned" = any PASS scan (incl. not-evaluated), so items don't need a scan forever while no model is bundled<br>• export prompts wait until flagged sacks are inspected<br>• "flagged" is cleared only by an inspection at or after the scan (`inspectedAt`)<br>Full rule table: data-operations/README.md | W2, accepted |
| 45 | 2026-10-10 | Analytics and ranking streams recompute only when the DB changes. The UI re-subscribes on app resume and when the date changes, so "today", ageDays and staleness stay correct | W2 finding |
| 46 | 2026-10-10 | LiteRT-LM pinned to `litertlm-android:0.18.0`. It ships only `liblitertlm_jni.so` (22 MB), with no clash with LiteRT 1.4.2, no permissions and no services. Release arm64 is 60.0 MB (+20.3 MB) | W1 spike + W4 audit |
| 47 | 2026-10-10 | Advice streams emit **one** event, the complete guarded text. Partial tokens never cross the bridge (the progress channel carries counts and timings only) | W1. Simplest way to guarantee the guard runs before display |
| 48 | 2026-10-10 | Reminder wording from the LLM is display-only and is not written into the scheduled notification | Decision 42 |
| 49 | 2026-10-10 | **Phase 4 Pest & Animal ID mode** inside Kernel: the camera finds subtle signals, the user validates, then on-device Gemma analyses. The mic has a listen mode. Guidance comes from curated cards (RAG via EmbeddingGemma) | User request. 74-agent verified research |
| 50 | 2026-10-10 | **Supersedes #40 (import-only):** `model-hub` auto-provisions models. It reads AI Edge Gallery's public catalog and downloads the same pinned files from Hugging Face (Gemma 4 E2B-it 2.59 GB; EmbeddingGemma 2 740m generic 485 MB), about 3.1 GB duplicated. Kernel cannot read Gallery's files: Android 11+ blocks other apps' `Android/data` even with MANAGE_EXTERNAL_STORAGE or SAF, and Gallery exports nothing | User choice. Platform limit verified in AOSP |
| 51 | 2026-10-10 | Guardrails §7 amended: INTERNET is added only for model catalogs/downloads and Google Maps/Routes (consent). All AI, search and embeddings stay on the phone | User decision |
| 52 | 2026-10-10 | Guardrails §8 amended: in Pest ID mode only, validated image crops and ≤30 s clips may go to the on-device LLM/embedder. The grain advice path stays text-only | User decision. Gemma 4 audio is documented for speech only, so YAMNet-class detection is primary |
| 53 | 2026-10-10 | No training or HF hosting in this repo (the team works on it in parallel). A future team classifier is picked up automatically from the catalog | User decision |
| 54 | 2026-10-10 | Maps: Google Maps SDK + Routes API. Turn-by-turn is handed off to the Google Maps app (`google.navigation:`), since the in-app Navigation SDK is a separate paid product. The key is Android-restricted, comes from `local.properties`, and is never committed | User choice |
| 55 | 2026-10-10 | Distance is shown only via a runtime-checked ARCore depth (the global I2501 isn't on the ARCore list; the China V2505A is) or AF-locked focus distance at 0.1–0.6 m. Monocular or pinhole estimates are never displayed | Research + user requirement "only if reliable" |
| 56 | 2026-10-10 | **Dedicated BLE frequency-detection sensor nodes** (additional feature; nothing existing changes): US_AIR (ESP32-S3 + SPH0641LU4H-1 PDM, about 192 kSPS, up to about 80 kHz), CONTACT (piezo + JFET or IIS3DWB) and AUDIO_AIR. Detection runs on the node and only features go over BLE. Open protocol `docs/sensor-protocol.md`, CDM pairing plus a QR-key HMAC, an experimental signature pack | User choice. BLE can't carry ultrasound and the phone mic stops at a 24 kHz Nyquist |
| 57 | 2026-10-10 | Pin the `audio-ai` grain capture to `TYPE_BUILTIN_MIC` (`setPreferredDevice`) | Research: a USB or BT mic would silently take over capture. No feature change |
| 58 | 2026-10-10 | Do not use `flutter_blue_plus` (no longer free for commercial use). BLE is native Kotlin + Pigeon | Licence |
| 59 | 2026-10-10 | model-hub: download consent also gates **catalog** fetches. With no consent, or on a metered network while Wi-Fi only, there is zero network. Gallery entries are fail-closed (treated as gated, licence unknown) until the HF revision API confirms licence, gating and sha256 | Keeps core flows at zero network |
| 60 | 2026-10-10 | Pins:<br>• EmbeddingGemma 2 740m @ `86b903a293f96d042bb92e1b7af333d94114458f`, sha256 `e7a8a220…df77f4c`, 484,622,336 B<br>• YAMNet: MediaPipe GCS `float32/1/yamnet.tflite`, sha256 `4d8b4a53…4c584faf`, 4,126,810 B, Apache-2.0 (Kaggle google/yamnet), pinned by `sha256-prefix` because GCS has no commit<br>• MagicTouch: listed, but licence unknown, so it is never auto-downloaded | model-hub W1 |

## Contract follow-ups (proposed by agents, not yet done)
- **PestSenseEngine (from sense-ai):**
  - add `cameraStatus()` (thermal, gyro gating, torch, low-light boost)
  - add `rankStill(still)` for Stage-1 embedding candidates, or `hint`/`score` on `ImageTile`
  - add `keepMedia(id)`, returning an app-private path under `files/sense_media/`; `PrivacyService.deleteAllHistory` must also wipe that folder
  - document the `listen()` error semantics (start/native failure gives a `SenseException(reason)` and closes the stream; a user stop closes the stream with no error) and the reason keys the UI must localize
  - Stage 1 needs a **multimodal** embedder (EmbeddingGemma 2 **740m** is text+image+audio; the 270m text model can't rank images)
- **NextAction** gains optional `cardId`, `sightingId` and `nodeId`. Add `SightingRepository.setUserValidation(id, {userValidated, userCardId})` and `KnowledgeService.warmUp()` (from data-ops v3).
- `ModelProvisioner.install(entryId)` (a user-chosen entry from search) and `blockReason(entry)`. Document `CatalogEntry.revision` as a git commit or `sha256[:40]` for non-git hosts. Document that `ModelSearchHit.score` is a keyword share in fallback mode.
- **LLM GPU accelerator libraries:** LiteRT-LM looks up `libLiteRtGpuAccelerator.so` / `libLiteRtOpenClAccelerator.so`, which the AAR does not ship, so the iQOO 15 may run on CPU. Measure latency against the 25 s budget. If it's too slow, bundle the accelerator libs or lower `maxOutputToken`.
- `AdviceModelManager.importFromUri`: cancelling only stops listening; the native copy keeps going. Add a native abort, and document that the first event is `copying` at 0 bytes.
- `AdviceText.promptVersion` for stored narratives.
- The `sacksScannedToday` l10n key is unused since the FPO home switched to `scansTodayCount`. Remove it.
- `NextActionKind.addSacks`, for a harvest or lot with zero sacks. Until then the detail empty states offer "Add sacks".
- Captures between 1.5 and 2 s pass the gate, but the model needs 198 frames (2.0 s), so they show NOT_EVALUATED. Raise the gate minimum to 2.0 s, giving RETRY, which is more actionable.
- `ScanOutcome`/`ScanRecord.modelNote` so older scans keep their provenance text. Shared `kernelItemQrPrefix` constant in contracts.
- The English `languageSheetBody` still says "More Indian languages are on the way", and the translations carry the same sentence. Update all 11.
- Language picker order: list by native name, not by locale code.
- On-device check: onboarding showed "Buyer — Current" on step 3 and, after picking Farmer, landed on the Scan tab. Either it was concurrent manual taps, or a race between `setActiveRole` and `setOnboardingDone` (the redirect self-corrects on the next settings emission). Reproduce on the device.
- `LabeledSampleRepository.relabel(id, draft)`, to upgrade `unknown` once an inspection confirms the label.
- `unarchive` for locations, lots and harvests (only items have it).
- `deleteAllHistory` should also delete exported report files, which contain copies of the history (recommended: yes).
- `ScanOutcome.audioRetained` flag (retained files are `files/recordings/<scanId>.wav`).
- An in-app haptics toggle: `captureAndAnalyze(..., {bool haptics = true})`.
- `EngineInfo.audioSource` / `deviceInputSampleRate` for the device log.
- `LocationRepository.watchAll()`: the UI currently walks `watchChildren`.
- `ScanRepository.watchSince(DateTime)`: for the FPO "scanned today" count.
- Document `watchForItem` ordering (newest first) and the `watchOpen()` semantics (open plus inProgress).
- `InspectionQueue.experimental` flag.
- Delete for items, lots and locations, which currently have none.
- Handling a reminder notification that launches the app from closed (`getNotificationAppLaunchDetails`).
- PDF Unicode font (Noto Sans / Noto Sans Devanagari) for local-language reports. Built-in PDF fonts are Latin-1 only.

## Open questions
- [ ] Does a trained grain-pest CNN exist? What were its training preprocessing parameters (n_mels, n_fft, hop, fmin/fmax, normalization)?
- [ ] Is labelled grain-pest audio available, and from which pests and grain types?
- [ ] Does the iQOO 15 mic deliver true 16 kHz, and which audio source (MIC / UNPROCESSED / VOICE_RECOGNITION)?
- [ ] Which local languages are needed for labels and TTS?
- [ ] Is multi-user sync needed for the hackathon at all?
