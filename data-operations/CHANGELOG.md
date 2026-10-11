## Unreleased (contracts v4, schema v4)

* Persist sensor health observations with idempotent, merged not-evaluated
  intervals, placement and overlap filters, and live database watches.
* Additive schema v4: health table/index and a nullable per-node privacy cutoff;
  no synthesized health history on upgrade. Wipe/forget removes health history,
  with stale replay protection across database reopen.

* Drift schema v3 with an additive v2 -> v3 migration: `sightings`,
  `sensor_nodes`, `sensor_events` (UNIQUE(node_id, seq)), `knowledge_cards`
  and `card_embeddings`. New triggers: `sightings_analysis_immutable`,
  `sightings_verified_once` and `sensor_events_append_only`. Every v2
  trigger is kept.
* `DataOperations.sightings`, `sensorNodes`, `sensorEvents` and `knowledge`.
* `DataOperations.open` / constructor take `knowledgeCardsJson`, `embedder`
  and `sensorAttention`.
* Next actions: `pestSafetyAlert` (1), `pestSightingsRepeated` (12),
  `sensorActivity` (12) and `sensorNeedsAttention` (25).
* `ReportKind.sightings`, as CSV and PDF.
* Settings: `mapsConsent` and `keepSightingMedia`, both default false.
* `deleteAllHistory` also deletes sightings with their media and sensor
  events. Paired nodes are kept, and wiped events are never re-imported.

## contracts v3

* No schema change (still v2). Everything below is computed from the
  existing tables.
* `DataOperations.analytics` (`DriftAnalyticsService`): result rates,
  quality failures, item freshness, inspection stats, scan activity,
  rule-based next actions per role, and `summarize(scope)` matching the
  report scope.
* Ranking: `result` filter, `maxAge` (stale scans go to needsScan) and
  `QueueEntry.ageDays`.
* `ReminderRepository.suggestDueAt` (rule-based, 09:00 local, never
  schedules).
* Settings: `localAdviceOptIn` (default false).
* Reports render an included, complete on-phone narrative in its own
  "Drafted on this phone" PDF section and as `narrative_*` CSV header lines.

## contracts v2

* Drift schema v2 with a v1 -> v2 migration: `archived_at` on items,
  locations and lots; `harvests` and `items.harvest_id`;
  `inspections.assigned_to` and `photo_paths`; `scans.audio_retained`;
  `labeled_samples`. Immutability triggers are recreated to cover the new
  immutable columns.
* Archive/unarchive, HarvestRepository, `watchSince`, `ScanRepository.get`,
  `InspectionRepository.assign`, `takeLaunchItemId`,
  LabeledSampleRepository, the new settings, and DatasetExportService.
* Report kinds preSale, lotSummary and sackLabels (QR), plus Unicode PDFs
  using bundled Noto Sans fonts.

## 0.1.0

* V0.1 foundation: drift schema v1 (items, locations, lots, scans,
  inspections, reminders, settings), implementations of every
  `kernel_contracts` repository and service, CSV/PDF reports, and on-device
  reminders through flutter_local_notifications.
