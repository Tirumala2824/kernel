# Guardrails (non-negotiable)

Every contributor and every subagent reads this file before changing code. If a request conflicts with a rule here, stop and raise the conflict. Do not work around it.

## 1. No fake data, no simulated results
- No seeded or sample sacks, lots, scans, counts or inspections in app code, assets or DB migrations. Screens bind to the real local DB and show an empty state when there is nothing to show.
- No simulated or random classifications. If no trained model is bundled, a scan still does a real mic capture and a real quality gate, then returns `classification = NOT_EVALUATED` with `modelVersion = "none"`.
- Test doubles (fake ScanEngine, in-memory DB, fixture audio) are allowed **only** under `test/`, `integration_test/` or `/tests`. They must never be reachable from the production app's dependency graph.
- Wireframe numbers in the PRD ("12 registered sacks", "LOT-024") are layout illustrations only. Never hard-code them.

## 2. AI stays on the device
- Capture, quality checks, log-mel, spectrograms and inference all run on the phone.
- Never call Gemini, Vertex AI, Cloud Vision, Speech-to-Text or any hosted inference from the app or backend.
- The model is a versioned asset packaged with the app. No automatic model updates from user scans.

## 3. Audio privacy
- Raw audio and spectrograms are never uploaded, logged or sent to crash reporting or analytics.
- By default, audio buffers are discarded after analysis. Local audio retention exists only behind an explicit opt-in setting, in app-private storage, with a delete action.
- Logs may contain technical errors and record IDs. Never audio, tokens or unnecessary personal data.

## 4. Result honesty
- Quality `RETRY` means no pest class is persisted. Show retry guidance and never a confident verdict.
- Every scan stores `modelVersion` and `experimental`. Every result screen and export shows model provenance and experimental status.
- The predicted class (AI) and the verified finding (human inspection) are separate fields and stay separate in the UI and in reports.
- A "Clean" result is not a guarantee. Copy must say that physical inspection is required for decisions.
- Never claim real pest detection, or an accuracy figure, until a model has been trained and evaluated on labelled data (see device-validation.md).

## 5. Decision safety
- Buyer flow: never auto-accept or auto-reject a lot from acoustic predictions.
- Never recommend fumigation or any treatment automatically. Any treatment guidance needs user confirmation and safety text.
- Batch ranking uses only valid, comparable scans. Unscanned or RETRY-only items show "needs scan" and are never ranked as if they had been evaluated.
- The F08 batch scan is sequential, one sack per scan. Never claim multi-sack detection.

## 6. Data integrity
- Scan history is append-only. A rescan creates a new ScanRecord and never overwrites an earlier one.
- Verified inspection outcomes are never silently overwritten, locally or by sync.
- Every row has a UUID plus `createdAt`, `updatedAt` and `syncState`.

## 7. Offline first
- Core flows (role select, item entry, scan, history, inspections, reminders, local report export, Pest ID analysis, sensors) make **zero** network calls.
- **Allowed network (Phase 4, user decision):**
  - **Model catalogs and model downloads** in `model-hub/` only: the AI Edge Gallery catalog on `raw.githubusercontent.com`, Hugging Face, and Google AI Edge / MediaPipe model storage. Downloads need a one-time consent, use Wi-Fi by default, are pinned to a full commit and verified by sha256, and come only from ungated repos with approved licences.
  - **Google Maps SDK tiles and the Routes API**, only after maps consent. Only the map viewport and route origin/destination are sent, never species, notes, media or audio.
- All inference, embeddings, search and data handling run on the phone. Nothing captured (images, audio, sensor data, LLM prompts or outputs) is ever sent over the network.
- GCP is optional, metadata-only and deferred (see gcp-deferred.md). No secrets or service-account keys go in the APK. The Maps key is an Android-restricted key supplied from `local.properties` and is never committed.

## 8. Local LLM advice (on-device, opt-in)
- The advice layer lives in `local-llm/` (LiteRT-LM) and is **completely separate** from the pest path (`audio-ai/`). `local_llm` never imports `audio_ai`, and `audio_ai` never imports `local_llm`.
- **No audio, ever.** The LLM receives only the typed DTOs in `contracts/lib/src/advice.dart`: primitives and enums. It never gets PCM, WAV paths, spectrograms, log-mel tensors or retained files. Multimodal backends (`audioBackend`, `visionBackend`) are never configured.
- **Opt-in and offline.** It is off by default. Inference is always offline. *(Superseded in Phase 4: models are fetched automatically by `model-hub` under §7; they are no longer import-only, and the release has INTERNET for that and for maps only.)*
- **Never blocking.** If the model is missing, busy, out of memory, slow (25 s timeout) or filtered, the UI falls back silently to the static localized copy. Generation never runs during a capture.
- **Output safety.** Text that recommends treatment or chemicals (fumigation, phosphine, pesticides…), claims grain is safe or pest-free, or accepts or rejects a lot is dropped on the device. Prompts and outputs are never logged.
- **Provenance.** Generated text is always labelled "Generated on this phone — experimental" with its `modelVersion`. It is never presented as a record, a verified finding or a decision. A report narrative appears only if the user chooses to include it, in its own labelled section.
- **Amendment (Phase 4, user decision).** The grain advice path above stays text-only. In **Pest ID mode** only:
  - A user-validated image crop or audio clip (≤30 s) may be passed to the **on-device** LLM or embedder, configured with `visionBackend` / `audioBackend`.
  - These inputs never leave the phone.
  - They are discarded after analysis unless the user saves the sighting with "keep media" on.
- Gemma's audio understanding is documented for speech only. Sound detection uses a dedicated sound classifier, and any LLM description of a clip is labelled experimental.

## 9. Pest & Animal ID safety
- **Never claim certainty.** The AI label, its self-reported confidence and the self-consistency agreement are always shown as "AI-estimated — not calibrated". "Not a pest" or "no match" is never presented as proof of absence.
- **Three separate records:** the AI analysis, the user's validation or correction, and a human verified finding, in both data and UI. The AI analysis is never edited after saving.
- **Dangerous animals:**
  - Venomous or medically important ones (widow or recluse spiders, scorpions, rats, Aedes, Anopheles): advise keeping distance and getting medical care for bites or stings. No home remedies.
  - Protected wildlife (e.g. monitor lizards, Wild Life (Protection) Act Schedule I): do not harm, catch or injure it; contact the State Forest Department or a licensed rescuer.
- **No poisons.** No pesticide, rodenticide or fumigant dosing or recommendations, from the LLM or the cards. Guidance is sanitation, exclusion, traps where lawful, and professional help. The output guard covers rodenticides, poisons and pesticides.
- **Grounding.** Guidance is grounded in the curated knowledge cards (sourced, marked "needs expert review"). The LLM may only rephrase and explain card content.
- **Distance** is shown only when the method's reliability gates pass. Otherwise the app says "Distance not available" and gives the reason.
- **Location** is a room for indoor sightings. A GPS pin is shown only when accuracy is 25 m or better. Location is taken only when the user taps "Save location".

## 10. Sensors (BLE frequency-detection nodes)
- **Features, not audio.** Nodes run the FFT and detection on board and send band energies and events only. Raw contact-vibration audio is never stored or sent. The ultrasonic path is high-passed at 20 kHz or above in firmware before any buffering. Spectrogram snippets are sent only on explicit request, held in memory, and never uploaded.
- **Secure links.** Every characteristic requires encryption and bonding (LE Secure Connections), plus an app-layer HMAC challenge using the per-device key from the node's QR label. The key is stored with Android Keystore protection.
- **Signals, not diagnoses.** Events are matched against a versioned, literature-derived signature pack marked **experimental**. Results are reported as "N events in M minutes". A jammed, clipped or survey-needed node is "not evaluated", never "nothing there".
- **Additive only.** Sensor evidence is shown alongside existing records (e.g. "Sensor evidence" on a sack) and never changes `ScanRecord`, the acoustic grain scan or the phone-mic features.
