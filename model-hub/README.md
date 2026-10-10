# model_hub

Kernel's model hub: catalog (AI Edge Gallery allowlist + Kernel catalog +
anonymous Hugging Face search), automatic provisioning, an installed-model
registry and semantic model search. It implements the contracts
`ModelCatalog`, `ModelRegistry`, `ModelProvisioner` and `ModelSearch`.

This is the only package allowed network, and only for model catalogs and
model files (docs/guardrails.md §7). Every model runs on the phone.

## Use (app-ui wiring)

```dart
final hub = ModelHub.create(probe: modelProbe, embedder: embedder);
await hub.provisioner.setConsent(const DownloadConsent(granted: true)); // Wi-Fi only by default
hub.provisioner.ensure({ModelCapability.embedText}).listen(onProgress);
final path = await hub.pathFor(ModelCapability.embedText);
```

`probe` (contracts `ModelProbe`) and `embedder` (contracts `Embedder`) are
injected; model_hub never imports another plugin.

## Rules enforced here
- Network only with consent, on an unmetered network when the consent is
  Wi-Fi only. Catalog hosts: raw.githubusercontent.com, huggingface.co.
  Model file hosts: huggingface.co (+ its hf.co CDN), storage.googleapis.com.
- Downloads only for ungated entries with licence apache-2.0, mit or
  bsd-3-clause, a 40-character pinned revision and a known sha256.
- Catalog fetched at most once a day (ETag); HF revision facts cached per
  pinned revision; 429 backs off (Retry-After / RateLimit `t=`).
- Downloads (Kotlin): user-initiated data-transfer job on API 34+, dataSync
  WorkManager worker below; free space must be remaining + 512 MB; `.part`
  file, Range resume, whole-file sha256, atomic rename.
- Storage: `getExternalFilesDir(null)/models/{repo with / -> __}/{revision}/{file}`;
  the legacy `getExternalFilesDir("llm")` is scanned too.

## Tests
```bash
flutter test                                                    # Dart (from model-hub/)
cd example/android && ./gradlew :model_hub:testDebugUnitTest    # Kotlin
```
Regenerate the bridge after editing `pigeons/hub_api.dart`:
`dart run pigeon --input pigeons/hub_api.dart`.
