# Translation glossary

Used by the localisation pass (W5) for `app-ui/lib/l10n/app_<lang>.arb`. Target locales: hi (Hindi), bn (Bengali), te (Telugu), mr (Marathi), ta (Tamil), gu (Gujarati), kn (Kannada), ml (Malayalam), or (Odia), pa (Punjabi).

**Status: machine-drafted. Every locale needs native-speaker review before field use.** Record reviewers in `docs/decisions-log.md`.

## Rules
- Use plain, everyday rural vocabulary, not academic or Sanskritised terms. Farmers and households are the primary readers.
- Keep **Kernel** (brand) untranslated in Latin script.
- Keep the meaning of the safety wording exact:
  - "not a guarantee"
  - "not verified"
  - "inspect physically"
  - "experimental"

  Never soften these into reassurance.
- Never translate a status in a way that implies a decision ("approved", "rejected", "safe", "treated").
- Digits: use the locale's default (Western Arabic digits are fine across all target locales).
- Keep ARB placeholders (`{count}`, `{label}`) and ICU plural/select syntax intact.

## Core terms
| English | Meaning / guidance |
|---|---|
| Scan | A 2-second listening check with the phone pressed on the sack. Use the local word for "check/listen", not "X-ray" |
| Sack | Jute/plastic grain bag (e.g. hi: बोरी) |
| Container | Household storage drum/tin/bin |
| Lot | A delivery batch from one supplier |
| Harvest | One crop harvest season/batch |
| Grain | Generic for rice/wheat/pulses (e.g. hi: अनाज) |
| Pest / infestation | Stored-grain insects (weevils, borers) and their presence |
| Clean | The model found no sign. **Must not read as "safe" or "pest-free"** |
| Uncertain | The model can't tell, so inspect |
| Infested | Likely insects. Inspection needed |
| Not evaluated | No result was produced (no model or unusable recording) |
| Inspection | A human physically checking the grain |
| Verified finding | What the human inspector saw. Distinct from the AI result |
| Experimental | Not validated. Results may be wrong |
| Retry | Record again |
| Too quiet / too noisy | Recording quality hints |
| Reminder | A scheduled re-check notification |
| Pre-sale report | Summary a farmer shows a buyer before selling |
| Offline | No internet. The app still works |
| Research recording | An opt-in labelled audio sample kept on the phone for training |
