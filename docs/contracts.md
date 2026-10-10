# Contracts and data model

The Dart source of truth lives in `contracts/` (pure Dart package). This file is the human-readable spec. **Changing a contract needs the lead to edit `contracts/` and all three owners to agree.** Subagents propose changes and never edit `contracts/` directly.

## ScanEngine (owner: D2 / audio-ai-dev)
```dart
abstract interface class ScanEngine {
  /// Records ~2 s of mono PCM at 16 kHz, runs the quality gate, then local inference.
  /// Never throws for audio/model problems. Those come back as RETRY or NOT_EVALUATED.
  /// retainAudio mirrors the user's explicit opt-in; false = buffer discarded after analysis.
  Future<ScanOutcome> captureAndAnalyze(String itemId, {bool retainAudio = false});
  Future<EngineInfo> info(); // modelPresent, modelVersion, experimental, target/effective sample rate, delegate, device
  Future<void> deleteRetainedAudio(); // wipes opt-in recordings; called by PrivacyService.deleteAllHistory
}

enum ScanQuality { pass, retry }
enum QualityReason { silence, clipping, highNoise, tooShort, permissionDenied, captureError }
enum Classification { clean, uncertain, infested, notEvaluated }

class ScanOutcome {
  final String scanId;            // UUID v4, generated on device
  final String itemId;
  final DateTime capturedAt;      // UTC
  final ScanQuality quality;
  final List<QualityReason> qualityReasons;
  final Classification classification;  // notEvaluated if quality == retry, no model, or failure
  final double? confidence;       // null unless a real model produced it
  final bool experimental;        // true until a model is validated
  final String modelVersion;      // "none" when no model is bundled
  final int latencyMs;            // capture end -> outcome
  final int durationMs;           // actual recorded duration
  final int sampleRate;           // effective device rate (record what the device really gave)
  final String deviceModel;       // Build.MODEL
  final String osVersion;         // Android release + SDK int
  List<String> invariantViolations(); // empty == valid; repositories refuse to persist otherwise
}
```
Invariants (enforced by `ScanOutcome.invariantViolations()` and tested in `contracts/test`):
- `quality == retry` ⇒ `classification == notEvaluated`.
- No model asset ⇒ `classification == notEvaluated`, `modelVersion == "none"`, `experimental == true`.
- `confidence == null` whenever `classification == notEvaluated`.

## Repository interfaces (owner: D3 / data-ops-dev, consumed by D1)
All methods are local (SQLite via drift) and work offline. Streams emit on change, so UIs stay reactive.
Exact signatures: `contracts/lib/src/repositories.dart`.
```dart
ItemRepository       create(GrainItemDraft) · update(GrainItem) · get(id) · watchByRole(Role) · watchByLocation(id) · watchByLot(id)
LocationRepository   create(LocationDraft) · get(id) · watchChildren(parentId?)
LotRepository        create(LotDraft) · get(id) · watchAll() · updateScreeningStatus(id, status)   // human-set only
ScanRepository       record(ScanOutcome)  // append-only; throws ArgumentError on invariant violations
                     watchForItem(itemId) · watchRecent(limit) · latestValidForItem(itemId)
InspectionRepository create(InspectionDraft) · watchForItem(itemId) · watchOpen() · updateFollowUp(id, status)
ReminderRepository   schedule(itemId, dueAt) · cancel(id) · markDone(id) · watchForItem(itemId) · watchUpcoming()
SettingsRepository   watchActiveRole() · setActiveRole(role) · watchRetainAudioOptIn() · setRetainAudioOptIn(bool)
RankingService       watchQueue({role?, locationId?, lotId?}) -> Stream<InspectionQueue{ranked, needsScan, modelVersion}>
ReportService        export(ReportScope, ReportFormat.csv|pdf) -> absolute path (app-private), shared via share_plus
PrivacyService       deleteAllHistory()
```

## Data model (all tables also have `createdAt`, `updatedAt`, `syncState`)
| Entity | Fields |
|---|---|
| GrainItem | id, ownerRole, label (user-entered, e.g. "Sack R-004"), grainType, quantity, quantityUnit, storageDate, locationId?, lotId? |
| ScanRecord | id, itemId, capturedAt, durationMs, sampleRate, quality (PASS/RETRY), qualityReasons, modelVersion, result (Classification), confidence?, experimental, latencyMs, deviceModel, osVersion. `isValid` = PASS and result ≠ notEvaluated |
| Inspection | id, itemId, scanId?, inspectedAt, inspector, observations, verifiedFinding (none_found / pests_found / inconclusive), followUpStatus (open / in_progress / done) |
| Lot | id, code (user-entered lot ref), supplierId?, supplierName?, grainType, declaredQuantity, quantityUnit, receivedAt, screeningStatus (pending / screening / needs_physical_check / reviewed) |
| Location | id, type (home / warehouse / room / stack / container), name, parentId? |
| Reminder | id, itemId, dueAt, status (scheduled / fired / done / cancelled) |
| AppSettings | activeRole, retainAudioOptIn (default false) |

Enum `Role { farmer, household, storageFpo, buyer }`. Switching role only changes `activeRole` and never deletes records.

## Ranking rule (F08)
Rank only items whose **latest valid scan** (quality PASS and classification not notEvaluated) shares the same `modelVersion` as the others in the queue. Order: infested > uncertain > clean, then oldest scan first. Every other item goes into a separate "needs scan" group. While no model is bundled, every item is "needs scan". That is the honest, expected behaviour.

## Contracts v2 (2026-10-10)
The source of truth is `contracts/lib/src/`. New fields are optional with defaults, so v1 call sites still compile. New interface methods must be implemented.

**ScanEngine**
- `captureAndAnalyze(itemId, {retainAudio, haptics = true})`
- `Stream<CaptureLevel> captureLevels()`: about 20 Hz, carrying `elapsedMs`, `targetMs`, `rmsDbfs` and `peakDbfs`. Levels only, never samples.
- `retainedAudioPath(scanId)`
- `ScanOutcome.audioRetained`
- `EngineInfo.modelNote`: provenance from the model manifest. The UI shows it with every result and the PDF header includes it.
- `EngineInfo.audioSource` and `EngineInfo.deviceInputSampleRate`

**Models**
- `archivedAt` on GrainItem, Location, Lot and Harvest. Archiving is a soft delete: hidden from `watch*`, queues and new reports, and scan history is kept.
- `Harvest` + `HarvestDraft`, and `GrainItem.harvestId`.
- `Inspection.assignedTo` and `Inspection.photoPaths` (app-private evidence photos).
- `LabeledSample` + `LabeledSampleDraft`, with `SampleLabel {clean, infested, unknown}`.
- `InspectionQueue.experimental`
- `ReportScope.kind` (`ReportKind {history, preSale, lotSummary, sackLabels}`) and `ReportScope.harvestId`.

**Repositories and services**
- `ItemRepository.watchByHarvest`, plus `archive`/`unarchive`.
- `LocationRepository.watchAll` and `archive`. `LotRepository.archive`.
- `HarvestRepository`.
- `ScanRepository.watchSince(since, {role})` and `get(scanId)`.
- `InspectionRepository.assign(id, assignee)`.
- `ReminderRepository.takeLaunchItemId()`: the reminder that opened the app, consumed once.
- `LabeledSampleRepository`: clean or infested requires `inspectionId` whose verified finding agrees (noneFound / pestsFound). Otherwise it throws ArgumentError.
- `SettingsRepository` adds research-mode opt-in, `languageTag`, haptics, voice prompts and onboardingDone.
- `DatasetExportService.exportZip()`: retained WAVs plus a CSV manifest, written locally. The user shares it through the share sheet and the app never uploads it.
- `PrivacyService.deleteAllHistory` also removes inspection photos and labeled samples.

**Ordering**
- `watchForItem` (scans and inspections), `watchRecent` and `watchSince` return newest first.
- `watchOpen` returns open and inProgress inspections, oldest first.

**Model manifest keys** (`models/<name>.properties`, owned by audio-ai): the v1 keys plus `validation=proxy|field` and `note=<text>`. `note` becomes `EngineInfo.modelNote`. A proxy model is always `experimental=true`.

## Contracts v3 (2026-10-10): analytics + on-device LLM advice
The source of truth is `contracts/lib/src/analytics.dart`, `advice.dart` and `repositories.dart`.

**Analytics** (`AnalyticsService`, implemented by data-operations). Computed locally from stored records, excluding archived ones:
- `watchResultRates`, `watchQualityFailures`, `watchItemFreshness`, `watchInspectionStats` and `watchScanActivity`, all taking an optional `AnalyticsFilter {role, locationId (nested), lotId, window}`.
- `watchNextActions(role)`: `NextAction {kind, priority (lower = more urgent), count, itemId?, lotId?, harvestId?, locationId?, label?}`. The UI localizes `NextActionKind`.
- `summarize(scope)` returns an `AnalyticsSummary`.

**Ranking**
- `watchQueue(..., {Classification? result, Duration? maxAge})`. `result` filters the ranked entries. `maxAge` moves entries whose latest valid scan is older than that into needsScan.
- `QueueEntry.ageDays` and the computed `QueueEntry.reason` (`RankReason`).

**Reminders:** `suggestDueAt(itemId)` is rule-based, always in the future, and only a suggestion. The user confirms.

**Settings:** `watchLocalAdviceOptIn` / `setLocalAdviceOptIn` (default false).

**Advice** (`AdviceEngine` + `AdviceModelManager`, implemented by `local-llm`)
- **Never throws.** An empty stream, or a stream that ends without `complete`, means "use static copy".
- **Inputs:**
  - `ResultAdviceInput`
  - `ReminderAdviceInput`
  - `ReportNarrativeInput` (wraps `AnalyticsSummary`)

  All are primitives and enums only. There are no paths, bytes or ScanRecords, so audio cannot reach the LLM by construction.
- **Output:** `AdviceText {text, complete, modelVersion, languageTag, generatedAt, experimental = true}`.
- **Model management:** `AdviceModelManager.importFromUri(contentUri)` streams `ModelImportProgress`; also `deleteModel()` and `freeSpaceBytes()`.

**Reports:** `ReportScope.narrative` (`AdviceText?`). data-operations only renders it, in a labelled section, and never calls an LLM.

## Contracts v4 (2026-10-10): model hub, embeddings, Pest ID, sensors
The source of truth is `contracts/lib/src/model_hub.dart`, `embedding.dart`, `pest_id.dart` and `sensor.dart`.

**Model hub** (`model-hub/`)
- `ModelCatalog.entries()` merges Gallery's `model_allowlists/<ver>.json`, Kernel's catalog and anonymous HF search. Every `CatalogEntry` is pinned to a 40-char revision with its sha256, licence and `gated`.
- `ModelRegistry` watches installed files, probes them with `ModelProbe` and answers `bestFor(capability)`.
- `ModelProvisioner`: consent (Wi-Fi by default), `plan` / `ensure(required capabilities)`, then a sha256-verified install.
- `ModelSearch`: EmbeddingGemma semantic search over entries and model cards.

**Embeddings** (`local-llm/`)
- `Embedder.embedText/embedImage/embedAudio` returns an L2-normalised `EmbeddingVector` with a Matryoshka dimension of 128/256/512/768. Null means unavailable.
- `ModelProbe.probe(path)` reads the LiteRT-LM `ModelInfo` header without loading the model.

**Pest ID**
- `PestSenseEngine` (`sense-ai/`): camera candidates, `captureStill` with tiles, torch, `listen(mode)` with clips and sound labels, `distanceCapability`, `measure`, `discardMedia`.
- `PestAnalyzer` (`local-llm/`):
  - `analyzeImage` returns a `PestAnalysis` (cardId from the constrained set, taxonomy, self-reported `aiConfidence`, self-consistency `agreement`, features, anomalies, insights, safety, model/prompt version, always experimental)
  - `describeSound`
  - `proposeRegions` (box_2d)
  - `guide` (card-grounded `AdviceText` stream)

  It never throws.
- `KnowledgeService` (data-operations): cards with semantic search, plus a keyword fallback.
- `SightingRepository` (data-operations): the AI `analysis`, the `userValidated` / `userCardId` validation and the human `verifiedFinding` are separate. `verifiedFinding` is set once.
- `DistanceEstimate.method` is `arcoreDepth`, `focusDistance` or `unavailable` (with a reason).

**Sensors** (`sensor-link/`, data-operations)
- `SensorLink`: QR-key association through CDM, status (jammed/clipped mean not evaluated), live `BandFrame`s, signature-matched `SensorEvent`s, survey, sessions, store-and-forward `syncEvents`.
- `SensorNodeRepository` and `SensorEventRepository`. `record` is idempotent on (nodeId, seq).
- Protocol: `docs/sensor-protocol.md`.

**Settings:** `watchMapsConsent` / `setMapsConsent` and `watchKeepSightingMedia` / `setKeepSightingMedia`, both default false.

## Contracts v4.1 (2026-10-10): W3 review fixes
- **Several safety levels at once.** `KnowledgeCard.extraSafety` (JSON `extraSafety`, default empty) adds levels to a card, e.g. a venomous snake that is also protected, or a protected bat that is also a medical risk. `safetyConcerns(aiLevel:, cards:)` joins the AI level with the primary and extra levels of every card involved, both the AI-matched card and the user's pick, and drops `low` when anything else applies. Banners, the guide prompt, the output guard, next actions and reports all use it. An empty set means unknown, so the app shows "stay back, don't touch". `mostSerious(levels)` orders them.
- `KnowledgeCard.trapSteps` (JSON `trapSteps`) holds the "where lawful" trap steps, apart from `safeSteps`. They are hidden from the UI and the prompt whenever a concern is `protectedWildlife`.
- `SoundAnalysis.cardIds` holds the cards suggested by the sound match, best first. They are saved so the banners survive, and they are never the user's pick.
- **Sensor health:**
  - `SensorHealth` gains `sensorFault` and `eventsOverwritten`. `notEvaluatedHealth` = {jammed, clipped, surveyNeeded, sensorFault, eventsOverwritten}.
  - `SensorStatus.notEvaluated` is also true for a link error or an empty health set.
  - `SensorStatus.errorCode` is one of `bt_permission`, `bt_off`, `re_pair_needed`, `not_visible`, `fgs_not_allowed` or `link`, and the UI localizes it.
  - `SensorStatus.sessionActive` reports a running session.
- **Health history:**
  - `SensorLink.healthChanges()` carries live status changes plus health records replayed from the node's ring (protocol v1.1). This includes an `eventsOverwritten` gap.
  - `SensorEventRepository.recordHealth` stores them, and `watchNotEvaluated({nodeId, locationId, itemId, window})` returns `SensorNotEvaluatedPeriod`s.
  - Any summary or rate whose window overlaps such a period says "not evaluated". "N events in M minutes" uses the watched window for M, not the span between the first and last event.

## Package entry points (what the lead wires in `app-ui/lib/bootstrap.dart`)
- `package:audio_ai/audio_ai.dart` exports `class NativeScanEngine implements ScanEngine` with a no-arg constructor.
- `package:data_operations/data_operations.dart` exports `class DataOperations` with:
  - `static Future<DataOperations> open()` (app-private DB file and real notification scheduler)
  - fields `items`, `locations`, `lots`, `scans`, `inspections`, `reminders`, `settings`, `ranking`, `reports`, `privacy` (typed by the contracts interfaces)
  - `Future<void> close()`

  Tests may construct it over an in-memory executor and test-only scheduler, from inside `test/`.
- v2 `DataOperations.open` takes these parameters:
  - `deleteRetainedAudio: engine.deleteRetainedAudio`
  - `retainedAudioPath: engine.retainedAudioPath`
  - `currentModelNote: () async => (await engine.info()).modelNote`
  - `onReminderTapped:`
  - `notificationIcon:`

  New fields: `harvests`, `labeledSamples`, `datasetExport`.
- `app-ui` declares one riverpod provider per interface. Providers are unbound by default, and `bootstrap.dart` overrides them with the real implementations.

## Native bridge (audio-ai internal)
Dart ↔ Kotlin goes through a **pigeon**-generated API in `audio-ai/pigeons/`. The Dart `ScanEngine` implementation in `audio-ai/lib/` maps the pigeon types to the `contracts` types. The app-ui never touches the channel directly.
