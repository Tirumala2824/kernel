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

## Contract follow-ups (proposed by agents, not yet done)
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
