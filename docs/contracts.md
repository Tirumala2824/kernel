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

## Package entry points (what the lead wires in `app-ui/lib/bootstrap.dart`)
- `package:audio_ai/audio_ai.dart` exports `class NativeScanEngine implements ScanEngine` with a no-arg constructor.
- `package:data_operations/data_operations.dart` exports `class DataOperations` with:
  - `static Future<DataOperations> open()` (app-private DB file and real notification scheduler)
  - fields `items`, `locations`, `lots`, `scans`, `inspections`, `reminders`, `settings`, `ranking`, `reports`, `privacy` (typed by the contracts interfaces)
  - `Future<void> close()`

  Tests may construct it over an in-memory executor and test-only scheduler, from inside `test/`.
- `app-ui` declares one riverpod provider per interface. Providers are unbound by default, and `bootstrap.dart` overrides them with the real implementations.

## Native bridge (audio-ai internal)
Dart ↔ Kotlin goes through a **pigeon**-generated API in `audio-ai/pigeons/`. The Dart `ScanEngine` implementation in `audio-ai/lib/` maps the pigeon types to the `contracts` types. The app-ui never touches the channel directly.
