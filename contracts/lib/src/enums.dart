enum Role { farmer, household, storageFpo, buyer }

enum ScanQuality { pass, retry }

enum QualityReason {
  silence,
  clipping,
  highNoise,
  tooShort,
  permissionDenied,
  captureError,
}

/// Model output. [notEvaluated] is the only honest value when the recording
/// was unusable, no model is bundled, or processing failed.
enum Classification { clean, uncertain, infested, notEvaluated }

enum InferenceDelegate { none, cpu, nnapi, gpu }

enum LocationType { home, container, warehouse, room, stack }

enum ScreeningStatus { pending, screening, needsPhysicalCheck, reviewed }

/// Human-verified result of a physical inspection. Never derived from a model.
enum VerifiedFinding { noneFound, pestsFound, inconclusive }

enum FollowUpStatus { open, inProgress, done }

enum ReminderStatus { scheduled, fired, done, cancelled }

enum SyncState { localOnly, pending, synced, conflict }

enum ReportFormat { csv, pdf }

/// history: all records in scope. preSale: farmer harvest summary.
/// lotSummary: buyer screening report. sackLabels: printable QR labels (PDF only).
/// sightings: Pest ID sightings and sensor events in scope.
enum ReportKind { history, preSale, lotSummary, sackLabels, sightings }

/// Why an item sits where it does in the inspection queue. The UI localizes.
enum RankReason { infested, uncertain, clean }

/// Label on a research recording. clean/infested require a linked human
/// inspection that confirms it; otherwise the label is unknown.
enum SampleLabel { clean, infested, unknown }
