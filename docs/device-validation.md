# Device validation, acceptance and demo

Target: **iQOO 15**, shared by three developers. Record every session in the device log at the bottom of this file.

## Device validation checklist (PRD A11)
- [ ] Record clean and infested grain samples only with explicit labelling and appropriate inspection confirmation.
- [ ] Test the actual 16 kHz capture path and any resampling; record the effective device input configuration (rate, source, format).
- [ ] Compare a quiet room with realistic warehouse noise, and different sack materials.
- [ ] Measure end-to-end latency, CPU/GPU delegate behaviour, battery use and thermal changes.
- [ ] Verify airplane-mode functionality for all core flows.
- [ ] Verify camera/QR, vibration, voice prompts, notifications and report sharing.
- [ ] Test permissions, background/foreground behaviour, rotation, font scaling and storage exhaustion.
- [ ] Document false positives, missed infestations and the "uncertain" rate before any accuracy claim.

## Acceptance criteria (PRD A12 + B-10.9 + B-12.6)
- [ ] Each of the four roles can finish its main workflow without a network.
- [ ] A real mic recording is captured and quality-checked; unusable recordings are rejected (RETRY, no class stored).
- [ ] Every scan output shows model provenance and experimental status; every scan stores modelVersion + experimental.
- [ ] Inventory, inspections, lots, reminders and reports persist after an app restart.
- [ ] FPO can rank sequentially scanned sacks and record inspection outcomes; unscanned items show "needs scan".
- [ ] Buyer can register a lot, attach screenings and export an evidence-based report.
- [ ] Farmer can generate a pre-sale summary; household can set a reminder.
- [ ] Reports distinguish AI predictions from human-verified findings.
- [ ] No audio or spectrogram is sent anywhere (network inspection shows zero calls in core flows).
- [ ] Local history can be deleted; logs contain no audio or tokens.
- [ ] No seeded or fake data exists outside test folders (`grep` check in CLAUDE.md).

## First-pass smoke test (V0.1 foundation)
1. Install the debug APK and enable airplane mode.
2. Select Farmer → empty state shown → register a sack.
3. Deny mic permission → explanation shown, inventory still browsable → grant.
4. Scan in silence → RETRY with reason "silence", nothing classified.
5. Scan against a sack → PASS → "Not evaluated — no model installed".
6. Switch to Household and back → records intact.
7. Force-stop and relaunch → sack and both scans still in history.

## Five-minute demo script (V1.0)
1. Choose Farmer and register a sack.
2. Record 2 seconds.
3. Show the quality check and the model-status label (experimental / not evaluated).
4. Switch to FPO, scan a batch and show the prioritized inspection queue.
5. Switch to Buyer and attach a screening to a lot.
6. Show the Household reminder and an offline report.
7. Enable airplane mode and repeat a core scan.

If no trained model exists, the demo shows NOT_EVALUATED honestly and does not claim pest detection.

## Device log
| Date | Who | Build | Test | Result / notes |
|---|---|---|---|---|
| | | | | |
