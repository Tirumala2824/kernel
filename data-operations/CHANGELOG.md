## Unreleased (contracts v2)

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
