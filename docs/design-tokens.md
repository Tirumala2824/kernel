# Design tokens and screens

## Colour
| Token | Hex | Use |
|---|---|---|
| `forest` | #234C38 | Primary: hero action cards, headings, primary buttons |
| `sage` | #E6EFE4 | Secondary cards / surfaces |
| `ivory` | #F6F3E9 | App background, tertiary cards |
| `amber` | #D9A441 | Attention: "Inspection needed", "Review due", warnings |
| `onForest` | #FFFFFF | Text on forest |
| `ink` | #1B2A22 (suggested) | Body text on light surfaces. Check ≥4.5:1 contrast |

Status colours always come **with a text label** (never colour alone).

## Rules
- Touch targets ≥ 48dp. Plain-language instructions. Support font scaling and do not clip at 200%.
- A persistent **Offline** indicator in the app bar, driven by connectivity_plus. It is informational only, because nothing in the core flows needs the network.
- Bottom navigation: **Home · Scan · Inventory · Reports**. Labels may change per role (e.g. Inventory → "My Grain" / "My Containers" / "Warehouse" / "Lots").
- Every result screen shows model provenance: `Model: none — Not evaluated` or `Model vX — Experimental`.

## Screen skeletons (from PRD wireframes)
The wireframe numbers are illustrations. **Bind every count to the real DB and show an empty state at zero.**

| Screen | Title / subtitle | Hero card (forest) | Cards |
|---|---|---|---|
| Role selection | "Select your role" / "One app. Four workflows." | — | Farmer (Harvest and pre-sale checks) · Household (Containers and reminders) · Storage/FPO (Warehouse and batch inspections) · Buyer (Supplier and lot screening) |
| Farmer home | "Farmer dashboard" / harvest name • Offline | Scan grain: "Start a guided 2-second recording" | `{n} registered sacks` / `{k} require follow-up inspection` · My grain · Pre-sale report |
| Household home | "Household storage" / "Home grain tracker" • Offline | Scan a container: "Record grain condition" | One card per container: `{grain} / {place}` · `Stored {d} days` · review status · Inspection reminders |
| FPO home | "Warehouse overview" / room • stack | Batch scan: "Scan sacks one at a time" | `{n} registered sacks` / `{m} scanned this session` · Inspection queue `{k} flagged` · Assigned inspections |
| Buyer home | "Incoming lots" / "Procurement screening" | Register delivery: "Supplier, lot, grain, quantity" | One card per lot: `{lot} / {grain}` · `{s} of {n} sacks screened` · Pending physical check · Inspection report |
| Guided scan | "Guided acoustic scan" / grain • item label | Ready to listen: "Press phone against sack" | Recording quality (noise / clipping / silence) · Capture duration (2 s at 16 kHz) · On-device inference ("No upload required") |
| Result | "Screening result" / model status line | State headline (see below) | Item card · Record inspection · Scan another |

Result headline states:
- RETRY: "Recording not usable — try again", plus the reasons.
- NOT_EVALUATED: "Not evaluated — no model installed. Inspect physically."
- INFESTED / UNCERTAIN (V0.3+): "Inspection needed — model result is not verified".
- CLEAN (V0.3+): "No signal detected — not a guarantee; inspect before sale/storage decisions".

Empty states use plain language and a single next action, e.g. "No sacks yet — Register your first sack".
