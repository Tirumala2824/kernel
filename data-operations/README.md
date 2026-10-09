# data_operations

Kernel's local data and operations layer. It implements every repository and
service interface from `package:kernel_contracts` on an on-device SQLite
database (drift). It works fully offline and makes no network calls.

## Usage

```dart
import 'package:data_operations/data_operations.dart';

final engine = NativeScanEngine();
final data = await DataOperations.open(
  deleteRetainedAudio: engine.deleteRetainedAudio,
  retainedAudioPath: engine.retainedAudioPath,
  currentModelNote: () async => (await engine.info()).modelNote,
);
// data.items, data.locations, data.lots, data.harvests, data.scans,
// data.inspections, data.reminders, data.labeledSamples, data.settings,
// data.ranking, data.reports, data.datasetExport, data.privacy
final openedFrom = await data.reminders.takeLaunchItemId(); // once per launch
await data.close();
```

Tests construct `DataOperations(executor: NativeDatabase.memory(), ...)` with a
test scheduler, a temporary report directory and font bytes read from
`assets/fonts/` (see `test/support/`).

## Rules enforced here

- A fresh database is empty. Migrations never insert rows.
- Scans are append-only: there is no update and no single delete, and a
  database trigger rejects edits to recorded fields (including
  `audio_retained`). `ScanRepository.record` throws `ArgumentError` when
  `ScanOutcome.invariantViolations()` is non-empty.
- Verified inspection findings and evidence photo lists are immutable
  (trigger-guarded). Only the follow-up status and the assignee change.
- Archiving is a soft delete. Archived items, locations, lots and harvests
  are hidden from `watch*`, the ranking queue and new reports; `get()` still
  returns them and per-item history stays. Archiving an item silences its
  reminder notifications until it is unarchived.
- Labeled samples need the research opt-in and a scan with retained audio.
  `clean`/`infested` need an inspection of the same item that found no pests /
  pests; a RETRY recording can only be `unknown`. One immutable label per
  recording.
- Ranking follows the rule in `docs/contracts.md`. Items without a comparable
  valid scan go to `needsScan`.
- Reports are built only from stored records. They carry model provenance on
  every scan row, keep AI and human columns separate, and include the
  "Clean is not a guarantee" disclaimer. The lot summary states that it is not
  an accept/reject decision and shows the human-set screening status.
- The dataset ZIP and reports are written to app-private storage and never
  uploaded. `deleteAllHistory` also removes inspection photos, labeled samples
  and exported dataset ZIPs (they contain audio copies).

## PDF fonts and script support

`assets/fonts/` bundles static Noto Sans Regular and Bold TTFs (unhinted,
from the notofonts project, SIL Open Font License 1.1, see
`assets/fonts/OFL.txt`): Noto Sans (Latin, Greek, Cyrillic) plus Devanagari,
Bengali, Telugu, Tamil, Gujarati, Kannada, Malayalam, Oriya and Gurmukhi.
`DataOperations.open` loads them through rootBundle
(`packages/data_operations/assets/fonts/...`) and registers the licence with
`LicenseRegistry`. Each character uses the first font in that order that has
a glyph, so mixed-script text renders.

Limitation: the `pdf` package (3.13) does no OpenType shaping (no GSUB/GPOS).
Each code point becomes its own glyph, so every character is drawn, but
conjuncts (e.g. क्ष) show as consonant + virama + consonant, pre-base vowel
signs (Devanagari ि, Bengali ি ে, Malayalam െ) appear after their consonant
instead of before it, two-part vowels (Tamil ொ ோ, Oriya ୋ) are not split
around the consonant, and mark positioning is approximate. Reports
stay readable but are not typographically correct for Indian scripts; CSV
exports keep exact UTF-8 text.

## Schema changes

Current schema: version 2 (`drift_schemas/kernel_database/`).

1. Edit `lib/src/db/tables.dart` and bump `schemaVersion`.
2. Run `dart run build_runner build` and then `dart run drift_dev make-migrations`.
3. Add the step to `KernelDatabase._upgrade` (`stepByStep`), plus an upgrade
   test and a data-integrity test in
   `test/drift/kernel_database/migration_test.dart`.

## Android app requirements (reminders)

The app's `AndroidManifest.xml` must declare `RECEIVE_BOOT_COMPLETED` and the
`ScheduledNotificationReceiver` / `ScheduledNotificationBootReceiver`
receivers from flutter_local_notifications. The app module must also enable
core library desugaring. Reminders use inexact scheduling, so no exact-alarm
permission is needed. On Android 13+, call
`DataOperations.requestNotificationPermission()` from a user action.
