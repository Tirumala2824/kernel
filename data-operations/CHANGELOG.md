## Unreleased (contracts v3)

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
