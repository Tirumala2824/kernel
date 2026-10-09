# Scope and versions

## Release ladder for this repo
The PRD's V0.1 "clickable mock" is **replaced** by a real-data foundation (see decisions-log.md).

| Version | Scope | Exit criteria |
|---|---|---|
| **V0.1 foundation** | Workspace scaffold, contracts, drift schema, role select, 4 dashboards with real empty states, item registration, real mic capture + quality gate, scan returning NOT_EVALUATED (no model), immutable history | Register item → scan → RETRY or NOT_EVALUATED → persisted → visible in history after restart, in airplane mode |
| V0.2 device | Haptics, permission-denied path, effective sample-rate logging, device benchmark notes, optional QR (mobile_scanner) | All device checks in device-validation.md pass on the iQOO 15 |
| V0.3 AI | Log-mel parity with the training pipeline, LiteRT model loaded from assets, experimental label, latency measurement | Only once a trained grain-pest model plus labelled audio exist |
| V0.4 operations | Batch queue + ranking, inspections, lots, reminders, CSV/PDF reports | Each audience completes its principal workflow from real records |
| V1.0 demo-ready | Polish, accessibility, localization, acceptance tests | Demo script in device-validation.md passes offline on the iQOO 15 |
| V3 (optional) | GCP metadata sync | See gcp-deferred.md |

## Feature catalogue → owner
| ID | Feature | Owner | First version |
|---|---|---|---|
| F01 | Role selection; switch without losing records | ui-dev (+ data-ops for activeRole) | V0.1 |
| F02 | Grain registry: id, grain type, quantity, date, location, optional lot/supplier | data-ops + ui-dev | V0.1 |
| F03 | Guided scan: positioning tutorial, ~2 s record, item association | ui-dev + audio-ai | V0.1 |
| F04 | Audio quality: silence / clipping / high noise → retry | audio-ai | V0.1 |
| F05 | Offline inference: log-mel + compact CNN, model version recorded | audio-ai | V0.3 |
| F06 | Results with next action and uncertainty | ui-dev | V0.1 (NOT_EVALUATED state) |
| F07 | Scan history: timestamp, quality, item, result, model version, device | data-ops + ui-dev | V0.1 |
| F08 | Batch prioritization: sequential scans, ranked queue, "needs scan" | data-ops + ui-dev | V0.4 |
| F09 | Inspection follow-up: evidence, inspector, notes, date, status | data-ops + ui-dev | V0.4 |
| F10 | Reports: local PDF/CSV from stored records | data-ops | V0.4 |
| F11 | Reminders: on-device scheduled notifications | data-ops | V0.4 |
| F12 | Offline/privacy: no network in core flows, audio retention opt-in, delete history | all | V0.1 |

## Audience journeys
| Role | Journey | Screens |
|---|---|---|
| Farmer | Create harvest → register sacks → scan → inspect flags → pre-sale summary | My Grain, Quick Scan, Results, History, Pre-sale Report |
| Household | Add container → storage date → scan → reminder → recheck | My Containers, Simple Scan, Reminder, History |
| Storage / FPO | Warehouse/room/stack → add sacks → batch scan → rank → inspect | Warehouse Overview, Batch Scan, Inspection Queue, Task Status, Export |
| Buyer | Supplier/lot → sample scans → physical checks → screening report | Incoming Lots, Lot Detail, Sample Scan, Inspection, Lot Summary |

## Out of scope for V1.0
Cloud sync (until V3), automated grading, pricing, IoT hardware, autonomous treatment, cloud AI of any kind, multi-sack detection claims.
