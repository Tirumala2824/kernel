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
- Core flows (role select, item entry, scan, history, inspections, reminders, local report export) make **zero** network calls.
- GCP is optional, metadata-only and deferred (see gcp-deferred.md). No secrets or service-account keys are ever placed in the APK.
