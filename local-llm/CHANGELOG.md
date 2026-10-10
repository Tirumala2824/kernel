## 0.2.0 (Phase 4)

* `RuntimeManager`: one native engine at a time, serialised requests, idle and memory-pressure unload.
* `LocalEmbedder` (EmbeddingGemma), `LiteRtModelProbe` (ModelInfo header), `LocalPestAnalyzer` (Gemma 4 E2B, Pest ID mode only).
* Injected `ModelPathResolver` for all engines; legacy `getExternalFilesDir("llm")` discovery kept.
* Output guard: rodenticides, poisons, doses; Pest ID certainty and safety claims (`checkPestOutput`).
* Manifest: optional `libcdsprpc.so`.

## 0.1.0 (Phase 3)

* Opt-in grain advice (`LocalAdviceEngine`), model import (`LocalModelManager`), output guard.
