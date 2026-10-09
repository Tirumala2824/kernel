# GCP — deferred, optional, metadata-only

**Status: not part of V0.1–V1.0.** Enable only for a concrete multi-user feature (version V3). Owner when enabled: data-ops-dev (D3).

## Boundary
- GCP never performs pest classification and never receives raw audio or spectrograms.
- Local SQLite remains the source of truth for offline work. The cloud only holds a synced copy.
- The app must stay fully usable when Firebase, Cloud Run or Firestore is unavailable.

## Services
| Service | Status | Purpose / notes |
|---|---|---|
| Firebase Authentication | Optional (multi-user only) | Sign-in for shared records; skip for a one-device demo |
| Cloud Run (FastAPI) | Optional | Non-AI sync API. Never routes audio or inference |
| Cloud Firestore | Optional | Users, orgs, inventory, lots, tasks, inspections, sync state |
| Cloud Storage | Optional | Exported PDF reports only; private bucket; never audio |
| FCM | Optional | Online assignment push; offline reminders stay local |
| Crashlytics | Recommended for pilot | Exclude audio, tokens and sensitive data |
| Cloud Logging + Monitoring | If Cloud Run is deployed | Retention + alerts; never log audio or tokens |
| Secret Manager | Only if the backend has secrets | Never embed keys in the APK |
| Cloud Build + Artifact Registry | Optional | Backend container only |
| BigQuery | Later evaluation | Minimized metadata + verified outcomes only |
| Vertex AI / any cloud AI | **Excluded** | All classification is local |
| Cloud Scheduler + Pub/Sub | Defer | Only for a concrete scheduled workflow |

## Sync design (when enabled)
- Local outbox table → HTTPS Cloud Run → Firestore. Asynchronous; waits for connectivity.
- Every record has a stable UUID, `updatedAt` and `syncState`. Writes are idempotent; duplicate pushes create no duplicates.
- Conflicts are resolved explicitly; verified inspection outcomes are never silently overwritten.
- Payload allowlist: inventory metadata, scan timestamp, modelVersion, predicted class, quality flags, inspection outcome. **Nothing else.**

## Endpoints (keep small)
- `POST /v1/sync/push`: queued changes; idempotent
- `GET /v1/sync/pull?since=…`: authorized changes since a cursor
- `GET /v1/organizations/{id}/inventory`: only records the caller may access
- `POST /v1/inspections`: verified inspection observations and outcome
- `POST /v1/reports`: report metadata / temporary download link
- No endpoint accepts raw audio.

## Security
- Cloud Run validates the Firebase ID token and checks org membership and role on **every** protected call. Hiding a screen in the UI is not access control.
- Farmers and households see their own records; warehouse staff see authorized facilities; buyers see their own supplier/lot workflows.
- HTTPS only; never disable certificate validation. Least-privilege IAM, private buckets, retention policies.

## Setup checklist (when the time comes)
- Dedicated project with budget alerts. Budget alerts notify; they do not cap spend.
- Choose a region near the pilot users and check current pricing in the Pricing Calculator.
- Enable only the required APIs; separate dev/demo config; commit no credentials.
- Firestore rules, private storage, log exclusions.
- Airplane-mode test, then reconnect → verify duplicate-safe sync.
