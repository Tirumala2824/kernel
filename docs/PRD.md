# Kernel — MVP Implementation Plan (PRD reference copy)

> Transcribed from `Kernel_MVP_Local_AI_GCP_Revised_Architecture.docx.pdf`, Version 1.2, 9 October 2026 ("Local-AI-first + GCP services revision").
> The source has two overlapping halves with duplicate section numbers. Here they are **Part A** (product + engineering) and **Part B** (GCP + architecture correction).
> **Part B §12 supersedes any earlier wording that could be read as recommending cloud AI.**
> Focused extracts for day-to-day work: [scope-and-versions.md](scope-and-versions.md), [contracts.md](contracts.md), [guardrails.md](guardrails.md), [design-tokens.md](design-tokens.md), [device-validation.md](device-validation.md), [gcp-deferred.md](gcp-deferred.md).

Three-person delivery • Four audience modes • iQOO 15 Android prototype.
Purpose: a build-ready scope, hardware usage plan, UI design, task ownership, milestones, and measurable acceptance criteria.

## Executive decision
Build ONE offline-first Android application with a shared acoustic scanning engine and four role-specific journeys. The iQOO 15 is the primary integration device. Developers can build independently on emulators or other Android devices and test sequentially on the shared phone. Do not claim real pest detection until an appropriately trained and evaluated model is available.

---

# Part A — Product + engineering

## A1. Source baseline and proposed extensions
From the Kernel pitch deck:
- two-second phone-to-sack capture, with 16 kHz as the target recording rate
- log-mel spectrogram
- compact CNN
- Clean/Uncertain/Infested output
- batch risk ranking
- on-device offline operation

This document adds the MVP product workflows, Android integration, reports and UI screens. The deck does not demonstrate field-validated accuracy and does not specify a trained grain-pest model.

## A2. Versioned release scope
| Version | Goal | Included / exit condition |
|---|---|---|
| V0.1 clickable | Demonstrate all four journeys | Onboarding, role dashboards, item registration, mock scan and clearly simulated results. **(Overridden for this repo: no mocks. See decisions-log.md.)** |
| V0.2 device | Working phone hardware | Mic permission, actual audio capture, signal-quality gate, vibration, local persistence, camera QR/label capture where supported. |
| V0.3 AI | On-device model pipeline | Consistent spectrogram pipeline, model integration, explicit experimental mode and performance measurements. |
| V0.4 operations | End-to-end workflows | History, batch queue, inspection outcomes, lot records, reports, reminders. |
| V1.0 demo-ready | Integrated MVP | Four journeys pass on iQOO 15 offline; demo with known recordings; limitations clearly disclosed. |

## A3. Final MVP feature catalogue
| ID | Feature | Minimum behavior / acceptance |
|---|---|---|
| F01 | Role selection | Farmer, Household, Storage/FPO, Buyer. Switching role does not lose records. |
| F02 | Grain registry | Unique item ID, grain type, quantity, date, location; optional lot/supplier. |
| F03 | Guided scan | Positioning tutorial; record ~2 s; save item association. |
| F04 | Audio quality | Detect silence, clipping and high noise; offer a retry instead of forcing a verdict. |
| F05 | Offline inference | Log-mel preprocessing and compact CNN; record the model version; any simulated fallback is labeled. |
| F06 | Results | Clean / Uncertain / Infested once validated; next action and uncertainty. |
| F07 | Scan history | Timestamp, audio quality, item, result, model version, device details. |
| F08 | Batch prioritization | Sequential item scans; filter and rank the inspection queue; no multi-sack detection claim. |
| F09 | Inspection follow-up | Record observed pest evidence, inspector, notes, date and status. |
| F10 | Reports | Export a shareable PDF/CSV locally, built from actual stored records. |
| F11 | Reminders | On-device scheduled inspection reminders for households/farmers. |
| F12 | Offline/privacy | Core flows work without network; no default audio upload; local audio retention is optional. |

## A4. Audience-specific MVP workflows
| Audience | Workflow | Screens / differentiated functions |
|---|---|---|
| Small farmers | Create harvest → register sacks → scan → inspect flags → pre-sale summary | My Grain; Quick Scan; Results; History; Pre-sale Report; local language labels. |
| Households | Add container → storage date → scan → reminder → recheck | My Containers; Simple Scan; Reminder; History; plain-language guidance. |
| FPO / storage | Register warehouse/room/stack → add sacks → batch scan → rank → inspect | Warehouse Overview; Batch Scan; Inspection Queue; Task Status; Export. |
| Buyers / aggregators | Register supplier/lot → sample scans → physical checks → screening report | Incoming Lots; Lot Detail; Sample Scan; Inspection; Lot Summary. |

## A5. iQOO 15 hardware and Android services
Confirm device-specific API behaviour on the actual iQOO 15 firmware. Use standard Android APIs. Do not assume direct access to a dedicated NPU or any special sensor without testing. The built-in microphone may not reliably capture all pest sounds, so an acoustic feasibility gate is essential.

| Capability | Prototype usage | Implementation / caution |
|---|---|---|
| Microphone | Two-second PCM recording | AudioRecord; runtime RECORD_AUDIO; sample-rate and mic response tests. |
| CPU / accelerators | Spectrogram and model inference | LiteRT/TFLite; CPU baseline first; NNAPI/GPU delegate only if supported and faster. |
| Camera | QR/barcode sack ID and inspection photos | CameraX + ML Kit or ZXing; optional for MVP; photos are inspection evidence, not acoustic proof. |
| Haptics | Start/finish/retry feedback | VibratorManager / Vibrator; respect user settings. |
| Speaker | Voice prompts / accessibility | Android TextToSpeech; local-language support depends on installed voices. |
| Local storage | Items, scans, tasks, exports | Room/SQLite; Android app-specific files and SAF share/export. |
| Notifications | Scheduled inspection reminders | NotificationManager + WorkManager; permissions and battery restrictions may affect timing. |
| Connectivity | Optional report share/sync | Not needed for scan; share through the Android Sharesheet when available. |
| Battery / thermal | Long batch-scan sessions | Monitor duration, power and throttling; avoid continuous background mic. |

## A6. Three-person ownership and interfaces
| Owner | Primary modules | Concrete deliverables |
|---|---|---|
| D1 — UI/UX + app shell | Flutter UI, navigation, accessibility, role-based screens | Design system, onboarding, four dashboards, scan/result UI, reusable components, screen tests. |
| D2 — audio/AI + phone services | Mic capture, preprocessing, model runtime, audio QA, haptics | AudioRecord module, 16 kHz normalized PCM, quality gate, inference adapter, device benchmark, AI evaluation report. |
| D3 — data + operations | SQLite, item registry, inspection queue, reports, reminders, integration | Schema/repositories, item/lot records, batch ranking, inspection tasks, PDF/CSV, reminders, offline tests. |

Shared integration rules:
- D1 owns the app navigation and the UI contract.
- D2 owns `ScanEngine.captureAndAnalyze(itemId) → ScanOutcome`.
- D3 owns the repositories and report services.
- Each developer keeps their own feature branch, with daily integration builds.
- One designated release integrator rotates weekly.
- All three review the end-to-end tests.

## A7. API contracts and data model
See [contracts.md](contracts.md).

## A8. UI/UX visual design
See [design-tokens.md](design-tokens.md).

## A9. UX behaviour and edge states
- No mic permission: show a permission explanation and still allow browsing existing inventory.
- Too much noise / silent recording: show retry and never present a confident classification.
- No trained model: show "Simulation / experimental result" on all relevant screens and exports. **(This repo: there is no simulation. Show "Not evaluated — no model installed".)**
- No network: scan, item entry, history and report export all work locally.
- Repeated scans: keep an immutable scan history; never silently overwrite earlier results.
- Unknown device support: fall back to CPU inference, log errors, and show "not evaluated" when processing fails.
- Buyer screening: never auto-accept or auto-reject lots from acoustic predictions alone.
- Treatment: never automatically recommend fumigation without confirmation and appropriate safety guidance.

## A10. Delivery plan — four sprints (indicative, not a guarantee)
| Sprint | D1 | D2 | D3 | Integrated demo |
|---|---|---|---|---|
| Week 1 | Design system, role selection, navigation | Mic POC, PCM capture, noise samples | Schema, item registry | Role selection + real recording + saved item |
| Week 2 | Four dashboards, scan/result screens | Quality checks, log-mel preprocessing | Scan history, inventory queries | Offline scan history + retry state |
| Week 3 | Queue, report and inspection UIs | CNN adapter, benchmark, experimental labels | Batch queue, lot flows, reminders | Four end-to-end audience journeys |
| Week 4 | Polish, accessibility, localization | Robustness tests, performance report | Reports, migrations, offline QA | iQOO 15 demo build + acceptance tests |

The primary risk to delivering real classification is whether representative labeled pest audio is available.

## A11. Device validation checklist / A12. Acceptance criteria and demo script
See [device-validation.md](device-validation.md).

## A13. Risks, decisions and out of scope
| Risk / decision | Mitigation |
|---|---|
| Acoustic detectability with a phone | Test early on iQOO 15 with labeled physical samples; do not assume published sensor thresholds transfer. |
| No labeled training data | Ship a fully functional hardware/app prototype. **(This repo: the result reads NOT_EVALUATED, never a simulated output.)** |
| Single shared device | Separate development environments; reserve daily device test slots; keep a shared device test log. |
| Cross-device inference variation | Benchmark the CPU baseline and log device/OS/model versions. |
| False sense of grain safety | Always show uncertainty and require physical verification for decisions. |
| Overly broad MVP | No cloud sync, automated grading, pricing, IoT hardware or autonomous treatment in V1.0. |

## A14. Handoff package
- Android installable build (APK) and reproducible build instructions.
- Source repository with /app-ui, /audio-ai, /data-operations, /tests, /docs boundaries.
- Screen designs, design tokens and a navigation map.
- Local schema, sample records, API contract and test fixtures. ("Sample records" means real recorded fixtures under `tests/`, never seeded into the app.)
- Device test log, model card or simulation disclosure, benchmark report.
- Short demo video/script and a known limitations list.

---

# Part B — GCP integration and final architecture

**All AI inference runs locally on the iQOO 15.** Do not call Gemini, Vertex AI, Cloud Vision, Speech-to-Text or any other cloud AI service for a scan. GCP is used only for optional non-AI services: accounts, shared inventory metadata, sync, notifications and monitoring. Local scanning and local records must keep working when the network or GCP is unavailable. Do not upload raw microphone audio by default.

Full GCP detail (services table, architecture, security, endpoints, setup checklist, cost) is in [gcp-deferred.md](gcp-deferred.md).

## B-12.1 AI services: what to use and what to replace
| AI function | Use in Kernel | Do not use for MVP | Reason |
|---|---|---|---|
| Audio capture | Android mic API; PCM at the model's expected rate (target 16 kHz) | Cloud audio recording APIs | Audio stays on the device and works offline. |
| Signal processing | Local DSP + log-mel tested against training preprocessing | Cloud preprocessing endpoints | Preprocessing must match the model and must not transmit audio. |
| Inference runtime | LiteRT/TFLite CNN on the phone CPU; NNAPI/acceleration only after testing | Vertex AI Prediction, Gemini API, Cloud Vision, Speech-to-Text, hosted inference | Avoids network dependency, latency, per-request cost and audio disclosure. |
| Model training | Off-device on a dev machine; package a versioned model file into the app | Training on the phone | Inference is local; training is not needed during a scan. |
| Model updates | Versioned app/model release after offline evaluation | Automatic unreviewed updates from user scans | Prevents silent behaviour changes. |
| Evaluation | Local test set + documented field validation; optional export of minimized labels/metrics | Uploading all raw recordings by default | Research collection stays separate, purposeful and opt-in. |

## B-12.4 Data flow
- **Required local path:** iQOO 15 microphone → audio quality checks → local log-mel preprocessing → local CNN inference → result UI → SQLite record. This path makes no network request.
- **Optional sync path:** SQLite outbox → HTTPS Cloud Run API → Firestore metadata. It is asynchronous and never carries raw audio or an inference request. If sync is not needed, omit it entirely.

## B-11. Decisions required before implementation
Status of each decision is tracked in [decisions-log.md](decisions-log.md).
- Flutter vs native Kotlin.
- Whether the hackathon needs multi-user cloud sync. If not, defer Firebase Auth, Cloud Run and Firestore.
- The acoustic dataset, and whether a grain-pest CNN already exists. An industrial defect CNN is not evidence of grain-pest performance.
- Whether any research audio collection is necessary. Default: no raw audio upload.
- Expected number of users, scans, reports and the retention period, before estimating GCP cost.

Source reference: user-supplied "Kernel Pitch Deck (1).pptx", hackathon build 2026. The hardware integrations and workflows in this plan are implementation proposals. Neither the pitch deck nor device testing has verified them.
