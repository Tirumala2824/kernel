# Kernel MVP

An offline-first Android app (Flutter UI + native Kotlin audio/AI plugin) for acoustic grain-pest screening. There are four roles (Farmer, Household, Storage/FPO, Buyer) and the target device is the iQOO 15.

**Read first:** [docs/guardrails.md](docs/guardrails.md) (non-negotiable) and [docs/contracts.md](docs/contracts.md). Full PRD: [docs/PRD.md](docs/PRD.md).

## Hard rules (summary of guardrails.md)
- **No fake data, no simulated results.** No seeds or sample records in the app. With no model bundled, a scan returns `NOT_EVALUATED` with `modelVersion: "none"`. Test doubles only under `test/`, `integration_test/`, `/tests`.
- **AI stays on the device.** No cloud AI. Raw audio is never uploaded or logged.
- RETRY ⇒ no pest class persisted. Scan history is append-only. The AI prediction is kept separate from the verified inspection finding.
- Never auto-accept/reject lots and never auto-recommend fumigation.
- Core flows make zero network calls. GCP is deferred ([docs/gcp-deferred.md](docs/gcp-deferred.md)).

## Layout and ownership
| Path | What | Owner (subagent) |
|---|---|---|
| `contracts/` | Pure Dart: ScanOutcome, enums, repository interfaces | **lead only** (agents propose changes) |
| `app-ui/` | Flutter app: theme, navigation, role screens, riverpod wiring | `ui-dev` |
| `audio-ai/` | Flutter plugin: Dart ScanEngine + Kotlin (AudioRecord, quality gate, log-mel, LiteRT), pigeon | `audio-ai-dev` |
| `data-operations/` | Dart package: drift DB, repositories, ranking, inspections, reminders, CSV/PDF | `data-ops-dev` |
| `tests/` | Cross-module integration tests + recorded audio fixtures | shared |
| `docs/` | PRD split, decisions log, device log | lead (agents may append to device-validation.md log and propose decisions) |
| root (`pubspec.yaml`, `CLAUDE.md`, `.claude/`) | Workspace config | **lead only** |

Dependency direction: `app-ui → audio-ai, data-operations → contracts`. `audio-ai` and `data-operations` never import each other or `app-ui`.

## Working with subagents
- Delegate module work to `ui-dev`, `audio-ai-dev` and `data-ops-dev`. They can run in parallel because their directories don't overlap.
- Contract changes go in this order: the lead edits `contracts/` + `docs/contracts.md`, then the agents adapt.
- Each agent finishes with analyze + tests green for its package and reports any contract gaps instead of working around them.
- Record new decisions in `docs/decisions-log.md`.

## Toolchain (this machine)
Flutter 3.47.7 / Dart 3.13.5 at `C:\Users\venka\dev\flutter` (not on PATH by default). The JDK is Android Studio's bundled JBR. In each Git Bash shell:
```bash
export PATH="/c/Users/venka/dev/flutter/bin:$PATH"
export JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"
```
Android SDK: `C:\Users\venka\AppData\Local\Android\Sdk`.

## Commands (run from repo root unless noted)
```bash
flutter pub get                         # resolves the whole pub workspace (single root pubspec.lock)
flutter analyze                         # all packages
(cd contracts && dart test)
(cd data-operations && flutter test)    # Flutter package (drift/notifications need flutter)
(cd app-ui && flutter test)
(cd audio-ai/example/android && ./gradlew :audio_ai:testDebugUnitTest)   # Kotlin unit tests (quality gate, log-mel)
(cd app-ui && flutter build apk --debug)
(cd app-ui && flutter run -d <iqoo-device-id>)
dart run build_runner build -d          # in data-operations (drift) after schema changes
dart run pigeon --input pigeons/scan_api.dart   # in audio-ai after bridge changes
```
No-fake check (must return nothing):
```bash
grep -rniE "mock|fake|dummy|sample(Data|Sack|Lot)|random\(" --include=*.dart --include=*.kt app-ui/lib audio-ai/lib audio-ai/android/src/main data-operations/lib contracts/lib
```

New dependencies: the owning agent adds them to its own package pubspec, then runs `flutter pub get` at the root. Every member keeps `resolution: workspace`.

## Status
- Done: docs, agents, git init, workspace scaffold, `contracts/` (tests green).
- Next: the parallel V0.1 foundation slices (ui-dev / audio-ai-dev / data-ops-dev), then lead integration. See [docs/scope-and-versions.md](docs/scope-and-versions.md).
