# data_operations

Kernel's local data and operations layer. It implements every repository and
service interface from `package:kernel_contracts` on an on-device SQLite
database (drift). It works fully offline and makes no network calls.

## Usage

```dart
import 'package:data_operations/data_operations.dart';

final data = await DataOperations.open(
  deleteRetainedAudio: () async { /* clear audio-ai's retained recordings */ },
);
// data.items, data.locations, data.lots, data.scans, data.inspections,
// data.reminders, data.settings, data.ranking, data.reports, data.privacy
await data.close();
```

Tests construct `DataOperations(executor: NativeDatabase.memory(), ...)` with a
test scheduler and a temporary report directory (see `test/support/`).

## Rules enforced here

- A fresh database is empty. Migrations never insert rows.
- Scans are append-only: there is no update and no single delete, and a
  database trigger rejects edits to recorded fields.
  `ScanRepository.record` throws `ArgumentError` when
  `ScanOutcome.invariantViolations()` is non-empty.
- Verified inspection findings are immutable (trigger-guarded). Only the
  follow-up status changes.
- Ranking follows the rule in `docs/contracts.md`. Items without a comparable
  valid scan go to `needsScan`.
- Reports are built only from stored records. They carry model provenance on
  every scan row, keep AI and human columns separate, and include the
  "Clean is not a guarantee" disclaimer.

## Schema changes

1. Edit `lib/src/db/tables.dart` and bump `schemaVersion`.
2. Run `dart run build_runner build` and then `dart run drift_dev make-migrations`.
3. Add the `stepByStep` migration and an upgrade test in
   `test/drift/kernel_database/migration_test.dart`.

## Android app requirements (reminders)

The app's `AndroidManifest.xml` must declare `RECEIVE_BOOT_COMPLETED` and the
`ScheduledNotificationReceiver` / `ScheduledNotificationBootReceiver`
receivers from flutter_local_notifications. The app module must also enable
core library desugaring. Reminders use inexact scheduling, so no exact-alarm
permission is needed. On Android 13+, call
`DataOperations.requestNotificationPermission()` from a user action.
