# Kernel MVP

An offline-first Android app (Flutter UI + native Kotlin plugins) for acoustic grain-pest screening. Phase 4 adds a **Pest & Animal ID** mode (camera, mic, BLE frequency sensors, maps). There are four roles (Farmer, Household, Storage/FPO, Buyer) and the target device is the iQOO 15.

**Read first:** [docs/guardrails.md](docs/guardrails.md) (non-negotiable) and [docs/contracts.md](docs/contracts.md). Full PRD: [docs/PRD.md](docs/PRD.md).

## Hard rules (summary of guardrails.md)
- **No fake data, no simulated results.** No seeds or sample records in the app. With no model bundled, a scan returns `NOT_EVALUATED` with `modelVersion: "none"`. Test doubles only under `test/`, `integration_test/`, `/tests`.
- **AI stays on the device.** No cloud AI. Raw audio, images and sensor data are never uploaded or logged.
- **Network** is used only to fetch model catalogs/files (`model-hub/`) and for Google Maps/Routes after consent (§7). Everything else works in airplane mode.
- RETRY means no pest class is persisted. Scan history is append-only. The AI prediction, the user's validation and the verified finding are kept separate (§6, §9).
- Never auto-accept/reject lots, never auto-recommend fumigation, and never recommend poisons or pesticide doses (§9).
- Sensor nodes send features, not audio. Their events are experimental signals, not diagnoses (§10).

## Layout and ownership
| Path | What | Owner (subagent) |
|---|---|---|
| `contracts/` | Pure Dart: ScanOutcome, enums, repository and engine interfaces | **lead only** (agents propose changes) |
| `app-ui/` | Flutter app: theme, navigation, role screens, riverpod wiring | `ui-dev` |
| `audio-ai/` | Flutter plugin: grain-scan ScanEngine + Kotlin (AudioRecord, quality gate, log-mel, LiteRT), pigeon | `audio-ai-dev` |
| `local-llm/` | Flutter plugin: on-device LiteRT-LM. Text advice (grain), embeddings, model probe, multimodal Pest ID analyzer | `audio-ai-dev` |
| `model-training/` | Off-device Python: dataset prep, log-mel parity, CNN training, TFLite export, model cards. Never shipped in the APK except the released `.tflite` + `.properties` | `audio-ai-dev` |
| `data-operations/` | Dart package: drift DB, repositories, ranking, inspections, reminders, sightings, sensor events, knowledge store, CSV/PDF | `data-ops-dev` |
| `model-hub/` | Flutter plugin: Gallery/Kernel/HF model catalog, auto-provisioning (UIDT downloads, sha256), registry and semantic model search. The only package with model-download network code (§7) | `data-ops-dev` |
| `sense-ai/` | Flutter plugin: Pest ID camera Stage 0 (CameraX), stills/tiles, listen mode + sound classifier, ARCore/focus distance measurement | `sense-dev` |
| `sensor-link/` | Flutter plugin: BLE link to frequency-detection sensor nodes (CDM, GATT protocol, signature pack) | `sensor-dev` |
| `firmware/` | ESP-IDF reference firmware for sensor nodes (US_AIR, CONTACT, AUDIO_AIR) + Python reference detectors | `sensor-dev` |
| `tests/` | Cross-module integration tests + recorded fixtures | shared |
| `docs/` | PRD split, guardrails, contracts, decisions log, device log, knowledge-card and sensor-protocol specs | lead (agents may append to the device-validation log; sensor-dev owns `docs/sensor-protocol.md`) |
| root (`pubspec.yaml`, `CLAUDE.md`, `.claude/`) | Workspace config | **lead only** |

Dependency direction: `app-ui → audio-ai, local-llm, data-operations, model-hub, sense-ai, sensor-link → contracts`. No plugin package imports another plugin or `app-ui`; the lead wires them together in `app-ui/lib/bootstrap.dart`. The grain pest path (`audio-ai`) and the LLM path (`local-llm`) stay separate (§8).

## Working with subagents
- Delegate module work to the owners above. Their directories don't overlap, so they can run in parallel in worktrees.
- Contract changes go in this order: the lead edits `contracts/` + `docs/contracts.md`, then the agents adapt.
- Each agent finishes with analyze + tests green for its package and reports any contract gaps instead of working around them.
- Record new decisions in `docs/decisions-log.md`.

## Toolchain (this machine)
Flutter 3.47.7 / Dart 3.13.5 at `C:\Users\venka\dev\flutter` (not on PATH by default). The JDK is Android Studio's bundled JBR. `uv` (Python) is in `C:\Users\venka\.local\bin`. In each Git Bash shell:
```bash
export PATH="/c/Users/venka/dev/flutter/bin:$PATH"
export JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"
export MSYS_NO_PATHCONV=1   # when passing device paths to adb
```
Android SDK: `C:\Users\venka\AppData\Local\Android\Sdk`.

## Commands (run from repo root unless noted)
```bash
flutter pub get                         # resolves the whole pub workspace (single root pubspec.lock)
flutter analyze                         # all packages
(cd contracts && dart test)
(cd data-operations && flutter test)    # Flutter package (drift/notifications need flutter)
(cd app-ui && flutter test)
(cd <plugin> && flutter test)           # audio-ai, local-llm, model-hub, sense-ai, sensor-link
(cd <plugin>/example/android && ./gradlew :<plugin_name>:testDebugUnitTest)   # Kotlin unit tests
(cd app-ui && flutter build apk --release --split-per-abi)
(cd app-ui && flutter run -d <iqoo-device-id>)
dart run build_runner build -d          # in data-operations (drift) after schema changes
(cd firmware/reference && uv run python -I -m pytest)   # sensor detector reference
```
No-fake check (must return nothing):
```bash
grep -rniE "mock|fake|dummy|sample(Data|Sack|Lot)|random\(" --include=*.dart --include=*.kt --include=*.c --include=*.h \
  app-ui/lib contracts/lib data-operations/lib audio-ai/lib audio-ai/android/src/main local-llm/lib local-llm/android/src/main \
  model-hub/lib model-hub/android/src/main sense-ai/lib sense-ai/android/src/main sensor-link/lib sensor-link/android/src/main firmware/main firmware/components
```

New dependencies: the owning agent adds them to its own package pubspec, then runs `flutter pub get` at the root. Every member keeps `resolution: workspace`.

## Status
- Phase 2 on `main`: brand, real-time scan, all role flows, contracts v2, schema v2, reports, dataset export, the experimental proxy model and 11 locales.
- Phase 3 on `main`: next-action homes, Insights, queue filters, suggested reminders, and the opt-in on-phone AI assistant (`local-llm/`, LiteRT-LM 0.18.0).
- Phase 4 (in progress): contracts v4 (model hub, embeddings, Pest ID, sensors). Scaffolds for `model-hub/`, `sense-ai/`, `sensor-link/` and `firmware/` exist. Plan: `C:\Users\venka\.claude\plans\create-plan-for-starting-eventual-snowflake.md`.
- Device: iQOO 15 (I2501, Android 16, adb serial 10BFAT1SQT000XP). AI Edge Gallery holds Gemma 4 E2B and EmbeddingGemma 2, but Kernel can't read them (Android scoped storage). Dev path: `adb shell cp` into `/sdcard/Android/data/com.kernel.kernel_app/files/models/...`.
