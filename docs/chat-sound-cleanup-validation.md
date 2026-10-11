# Chat sound classification and record-UI cleanup — validation

## Scope

Continued the existing chat-first/Hugging Face integration without replacing the application or discarding the pre-existing working-tree changes. The model and chat integration were already present when this continuation began; they were reverified rather than recreated.

This continuation fixes false record-state presentations:

- Buyer physical-check summaries no longer interpret pending/failed inspection history as “No physical check yet”.
- Buyer sample-scan and harvest-sack summaries no longer interpret pending/failed scan history as “Not scanned yet”.
- Batch eligibility/counts require current queue data and, when “skip scanned today” is enabled, current today-history data. Loading, error, and retained values during refresh cannot start a stale walk. The start handler rechecks the providers, including callbacks captured before a refresh. Disabling the optional today filter permits a walk only if queue data remains current.
- Scans Today no longer substitutes “Archived” for an unresolved item label. Real scan timestamps/results and navigation remain available; the label returns when current item data arrives.

The shared `CurrentDataView` is used only for these compact record summaries. It uses existing localized loading/error text and never substitutes fabricated records or counts. Curated knowledge, real empty states, real capture flows, and persisted records remain intact.

## New regression evidence

`app-ui/test/record_data_honesty_test.dart` and `app-ui/test/batch_data_honesty_test.dart` contain five executed widget tests (including the lot/harvest parameterized cases).

Observed behavioral RED failures before production edits:

1. Pending inspections displayed “No physical check yet” when no such observation existed.
2. Pending lot and harvest scan histories displayed “Not scanned yet”.
3. Batch Start had a non-null callback while today's scan history was unavailable.
4. An active item's scan received `itemLabel == 'Archived'` before the item list arrived.

Observed GREEN covers initial pending, initial failure, real empty observations, nonempty observations, retained-data refresh, failure after data, recovery, and preserved real controls. Batch tests also invoke stale callbacks before a rebuild and verify that no walk/capture begins.

## Executed checks

All commands were serialized through the existing local Flutter test wrapper.

| Check | Observed result |
|---|---|
| App-wide `flutter test --no-pub --reporter expanded` | **771 passed** |
| Named-file Flutter analysis for the five changed UI files and two new test files | **No issues found** |
| `contracts`: `dart test --reporter expanded` | **23 passed** |
| `sense-ai`: `flutter test --no-pub --reporter expanded` | **46 passed** |
| `local-llm`: `flutter test --no-pub --reporter expanded` | **264 passed** |
| `model-hub`: `flutter test --no-pub --reporter expanded` | **46 passed** |
| `sense-ai` JVM test XML | **70 total, 0 failures, 0 errors, 1 skipped** |
| `sense-ai` connected Android tests on I2501 / Android 16 | **2 passed** |
| `app-ui/integration_test/chat_sound_test.dart` on device `10BFAT1SQT000XP` | **Passed** |
| Scoped `git diff --check` for this continuation's UI files | **Clean** |

The JVM skip is the existing Windows symlink test. Existing Gradle/JDK and `flutter_tts` Kotlin-plugin migration warnings remain. The bootstrap unit test intentionally exercises unavailable local storage and emits its expected MissingPluginException diagnostic. A whole-tree diff check also reports a pre-existing extra EOF blank line in `contracts/lib/src/agents/agent_models.dart`; that unrelated change was preserved.

## Model and runtime verification

Source: <https://huggingface.co/ganesh333/kernel-insect-classifier>

- Pinned revision: `001425d7fab4b44af5cc571174410f1c78552d0e`.
- The source `model.tflite`, `labels.json`, and `config.json` SHA-256 values matched their existing pins.
- The connected native tests execute the real interpreter and numerical parity checks. The app integration test exercises production bootstrap, native classification, and actual chat rendering; silent audio returns rejection with no labels.
- Numerical input signals exist only in tests. These checks establish runtime/numerical integration, **not insect-recognition accuracy on field recordings**.
- No new remote inference, audio upload, model download, setup dialog, or fabricated model score was introduced.

## Normal app artifact and device readback

After the integration runner finished, rebuilt explicitly from the normal entry point:

```bash
flutter build apk --debug --no-pub --target lib/main.dart
```

Artifact: `app-ui/build/app/outputs/flutter-apk/app-debug.apk`.

APK SHA-256: `4980684c9a49717885cdaecb9ba1d0cc8f638eee84b5655a3955f298400e4f4e`.

The APK contains the pinned production model with SHA-256 `55ad541b87d1ae0bae5a71c7ec9091fc40617051f479ac3f12996bacda6f597e`; archive inspection found no `insect_parity` fixture directory. The model license/card/attribution assets remain bundled.

Installed with `adb install -r` (no data wipe), then launched `com.kernel.kernel_app/.MainActivity`. Readback of the installed `base.apk` SHA-256 exactly matched the normal artifact. Launch reported `Status: ok`; the running app's accessibility hierarchy exposed Kernel, Menu, the notebook empty state, Attach, and Send message—not the test runner.

A device screenshot was captured, but the vision-analysis service failed with a gateway error. Pixel-level screenshot review is therefore **not claimed**. UI hierarchy readback, widget overflow/accessibility tests, the real-device integration test, and normal-app launch were executed.

## Limits that must remain visible

This is an experimental closed-set classifier for 32 audible insect species. It cannot establish hidden grain infestation, grain safety, pest absence, ultrasound detection, or presence of an insect merely from a match. Noise and non-insect audio can receive high model scores. No new labeled field-audio evaluation, unknown-species validation, cross-device benchmark, or thermal/battery study was performed.

No commits, pushes, stashes, resets, or destructive database changes were made in this continuation.
