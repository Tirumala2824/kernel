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
// data.ranking, data.analytics, data.reports, data.datasetExport,
// data.privacy
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

## Ranking filters (contracts v3)

`ranking.watchQueue(..., result:, maxAge:)` keeps the ranking rule:

- `maxAge`: a latest valid scan captured more than `maxAge` before now is
  too old to compare. Its item goes to `needsScan`, and the common model
  version is chosen among the fresh scans only.
- `result`: applied after ranking. It keeps only the ranked entries of that
  class and never changes the model version or `needsScan`.
  `modelVersion` is null when nothing is left.
- `QueueEntry.ageDays`: whole days since the latest valid scan.

Time is read from the injected clock whenever the stream recomputes (on a
table change). The streams do not tick on their own.

## Analytics (`data.analytics`)

Everything is computed on the device from the stored tables. Nothing is
cached or sent anywhere, and there is no schema change.

**Scope.** Only non-archived items count, together with their scans and
inspections. `AnalyticsFilter` fields combine as AND:

- `role` is the owner role.
- `locationId` covers that location and every location nested below it.
- `lotId` is the item's lot.
- `window` keeps scans captured, and inspections inspected, at or after
  `now - window`. Item freshness ignores the window, because it describes
  items rather than scans.

**Metrics**

- **ResultRates** counts each scan once:
  - RETRY counts as retry.
  - PASS + notEvaluated counts as notEvaluated.
  - Other PASS scans count by their class.
- **QualityFailures** has every `QualityReason`, in enum order and zero when
  unseen, with the number of RETRY scans that carried it.
- **ItemFreshness** uses the latest scan of any quality. Never-scanned items
  come first, in label order, then the oldest last scan.
- **InspectionStats** counts by follow-up status.
- **ScanActivity**: `today` starts at local midnight, and `last7Days` covers
  the rolling 7 × 24 h.

**`summarize(scope)`** uses the report scope rules: role, nested location,
lot, harvest, item ids, non-archived. It covers all of those items' scans and
inspections, so `items`, the scan totals and the inspection totals match the
report. `itemsNeedingScan` is the number of items with no valid scan.

### Next actions (`watchNextActions(role)`)

These are deterministic rules over the role's non-archived items. Lower
priority is more urgent.

Terms:

- **Latest PASS scan**: the newest PASS scan, with any result.
- **Latest valid scan**: the newest PASS scan that has a model result.
- **Flagged**: the item's latest valid scan is infested or uncertain, and no
  inspection addresses it. An inspection addresses it if it links that scan
  (`scanId`), or if it was inspected at or after the scan's capture.
- **Open inspection**: follow-up `open` or `inProgress`.
- **Today**: since local midnight.

| Kind | Priority | Roles | Fires when | Target / count |
|---|---|---|---|---|
| registerFirst | 0 | all | The role has no items. For the buyer: there are no lots | — |
| reminderDue | 5 | household | A reminder has fired, or is scheduled and past due, and is not done or cancelled | items |
| inspectFlagged | 10 | farmer, household, FPO; buyer only for sacks outside a listed lot | The item is flagged | items |
| physicalCheckPending | 10 | buyer | A lot has flagged sacks | `lotId`, label = lot code, count = flagged sacks |
| reviewDue | 15 | household | No PASS scan, or the latest PASS scan is ≥ 30 whole days old | items |
| finishBatch | 15 | FPO | In a location, ≥ 1 sack has a PASS scan today and ≥ 1 does not | `locationId`, label = location name, count = sacks still to do |
| scanNeeded | 20 | farmer, FPO | No PASS scan, or the latest PASS scan is > 14 days old | items |
| scanNeeded | 20 | buyer | A lot has sacks with no PASS scan and no inspection | `lotId`, label, count = those sacks |
| exportPreSale | 40 | farmer | Per non-archived harvest with ≥ 1 sack: every sack has a PASS scan within 14 days, none is flagged, and none has an open inspection | `harvestId`, label = harvest name, count = sacks |
| exportLotSummary | 40 | buyer | Per lot with ≥ 1 sack: every sack has a valid scan or an inspection, none is flagged, and the screening status is not reviewed | `lotId`, label = lot code, count = sacks |

The "items" actions are aggregated into one action whose `count` is the
number of items. `itemId` and `label` are set only when `count == 1`.

Ordering is by priority, then by kind (enum order), then by label, then by
target id.

Deliberate choices:

- PASS scans without a model result count as checked for staleness, review
  and pre-sale readiness. Otherwise every item would need a scan forever
  while no model is bundled.
- A buyer lot whose sacks have only such scans gets neither a scan prompt
  nor a summary prompt.
- Export prompts wait until flagged sacks are inspected.

None of these actions accepts, rejects or treats anything.

## Reminder suggestion

`reminders.suggestDueAt(itemId)` only reads. It never persists or schedules
anything. The item's latest PASS scan decides, because a RETRY carries no
result:

| Latest PASS scan | Suggested day |
|---|---|
| infested or uncertain | now + 3 days |
| clean | now + 14 days, or + 7 days when stored for more than 90 days |
| notEvaluated, or no PASS scan (RETRY-only or never scanned) | now + 1 day |

The time is set to 09:00 local on that day and moved a day later until it is
after now. It is returned in local time. An unknown or archived item throws
`ArgumentError`.

## Report narrative

`ReportScope.narrative` is rendered only when it is non-null, `complete` and
its text is not blank. This package only renders it; it never calls a
language model and never imports `local_llm`.

- **PDF** (history, pre-sale, lot summary): a boxed section, placed after
  the summary and before the records, titled "Drafted on this phone", with
  the line "By {modelVersion} — experimental. Not a record or a decision;
  check before sharing." Paragraphs are drawn in the report fonts and can
  continue onto the next page.
- **CSV**: header-block lines `narrative_model`, `narrative_experimental`
  (always `yes`) and `narrative_text`, placed after the disclaimers. Both
  values are guarded against formula injection.
- It is never part of record rows or findings. Sack labels ignore it.
- Without a narrative, or with an incomplete one, the output is unchanged.

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
