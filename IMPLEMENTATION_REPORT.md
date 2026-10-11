# Kernel implementation handoff

## Delivered in this repository

The work extends the existing Kernel repository at `/home/ubuntu/kernel`; it does not recreate the whole project from an empty directory.

- **Chat-first startup:** after onboarding and role selection, production routing now opens `/chat`. The chat menu routes to saved-item grain scanning, pest tools, sensors, sightings map, model hub, inventory, reports, and settings.
- **Real scan context:** chat reads the role-scoped local inventory and passes the selected saved grain item ID to the acoustic scan engine. It no longer invents a default item ID; an audio request without a saved item is explicitly not evaluated.
- **Private local conversation history:** up to 200 text messages are stored in app-private support storage. The persisted format includes speaker, timestamp, text, and ID only. Media bytes/paths are not retained. Recovered structured agent results are shown as transcript text; the original cards and media are not reconstructed.
- **Evidence-honest agents:** acoustic proxy activity is no longer presented as insect species identification. Vision metrics are derived from decoded, bounded image pixels; fake species candidates and fixed bounding boxes were removed. Capture quality, model self-estimates, and independent-run agreement remain separate; no synthetic calibrated-confidence figure is produced.
- **Locally grounded advice:** chat questions and identification guidance use the bundled, reviewed local knowledge service. When there is no matching card, the app says so rather than filling the gap with invented pesticide instructions, thresholds, or statutory advice.
- **Regression coverage:** added tests for text-only bounded history, invalid images, audio proxy limits, unavailable guidance, provenance labels, missing inventory context, and the chat-first route. The shared connectivity indicator remains labeled at normal phone sizes and switches to its accessible tooltip presentation at enlarged text sizes.

## Validation performed

- `flutter analyze contracts app-ui audio-ai data-operations local-llm model-hub sense-ai sensor-link` — **no issues found**.
- `app-ui`: `flutter test` — **495 tests passed**.
- Flutter-aware package suites: `audio-ai` **46**, `data-operations` **212**, `local-llm` **259**, `model-hub` **45**, `sense-ai` **32**, `sensor-link` **109** — all passed.
- `contracts`: `dart test` — **18 tests passed**.
- `firmware/reference`: `uv run python -I -m pytest` — **64 tests passed**.
- `git diff --check` — passed.

## Not verified / not delivered

- An Android APK/device build was **not** run: this environment has Flutter 3.47.7 but no Android SDK (`flutter doctor` reports the Android toolchain unavailable).
- ESP-IDF compilation, flashing, Bluetooth/camera/microphone hardware integration, and physical-device validation were **not** run: `idf.py` is not installed here. The 64 passing firmware tests are host-side Python reference tests only.
- Therefore this handoff is **not a claim of a complete, production-certified Android + ESP-IDF release**. Device-specific execution, model-domain validation/calibration, and hardware acceptance remain unverified.
