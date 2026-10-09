# Decisions log

Append new decisions at the bottom. Never rewrite past entries; supersede them with a new one.

| # | Date | Decision | Why |
|---|---|---|---|
| 1 | 2026-10-09 | **Flutter UI + native Kotlin Android plugin** for audio/AI | Team choice. The audio pipeline stays native (AudioRecord, DSP, LiteRT) and is reached via pigeon |
| 2 | 2026-10-09 | **No mocks in the first pass.** The PRD's V0.1 clickable mock is replaced by a real-data foundation. With no model, scans return NOT_EVALUATED | No fake data or simulated results anywhere in the app; test doubles only in test folders |
| 3 | 2026-10-09 | **GCP deferred** to V3, metadata-only | Single-device demo; PRD B-12.2 says GCP is not mandatory |
| 4 | 2026-10-09 | Repo layout `contracts/ app-ui/ audio-ai/ data-operations/ tests/ docs/` as a Dart pub workspace | PRD handoff boundaries plus one shared contracts package |
| 5 | 2026-10-09 | Stack: riverpod, go_router, drift, pigeon, flutter_local_notifications, pdf/csv/share_plus, permission_handler, connectivity_plus | Typed, testable, offline |
| 6 | 2026-10-09 | Three project subagents: ui-dev, audio-ai-dev, data-ops-dev. The lead (main session) owns `contracts/` and root files | Mirrors PRD D1/D2/D3 ownership |

## Open questions
- [ ] Does a trained grain-pest CNN exist? What were its training preprocessing parameters (n_mels, n_fft, hop, fmin/fmax, normalization)?
- [ ] Is labelled grain-pest audio available, and from which pests and grain types?
- [ ] Does the iQOO 15 mic deliver true 16 kHz, and which audio source (MIC / UNPROCESSED / VOICE_RECOGNITION)?
- [ ] Which local languages are needed for labels and TTS?
- [ ] Is multi-user sync needed for the hackathon at all?
