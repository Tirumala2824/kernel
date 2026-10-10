/// Kernel's on-device LiteRT-LM layer (Google AI Edge).
///
/// - [LocalAdviceEngine] implements `AdviceEngine` (grain advice, opt-in,
///   text in, text out) and [LocalModelManager] `AdviceModelManager`;
///   [pickLitertlmUri] opens the system file picker for a `.litertlm`.
/// - [LocalEmbedder] implements `Embedder` (EmbeddingGemma).
/// - [LiteRtModelProbe] implements `ModelProbe` (model header, no weights).
/// - [LocalPestAnalyzer] implements `PestAnalyzer` (Gemma 4, Pest ID mode).
/// - [RuntimeManager] owns the native engines for all of them: one engine
///   in memory at a time, serialised requests, idle unload. Share one.
///
/// Isolation (docs/guardrails.md §8 and its amendment): this package never
/// imports the audio-ai plugin. The grain advice path never receives audio,
/// images, paths or byte buffers and never configures an audio or vision
/// backend. Only the Pest ID path passes a user-validated crop or clip to
/// the on-device engine. There is no network code.
library;

export 'src/local_advice_engine.dart' show LocalAdviceEngine, adviceTimeout;
export 'src/local_embedder.dart'
    show LocalEmbedder, embedTimeout, embeddingDims, embeddingPrompt;
export 'src/local_model_manager.dart' show LocalModelManager, pickLitertlmUri;
export 'src/local_pest_analyzer.dart'
    show
        LocalPestAnalyzer,
        pestAnalysisBudget,
        pestGuideTimeout,
        selfConsistencySamples;
export 'src/model_probe.dart' show LiteRtModelProbe;
export 'src/output_guard.dart'
    show GuardCategory, GuardResult, checkOutput, checkPestOutput;
export 'src/pest_prompts.dart' show pestPromptVersion;
export 'src/prompts.dart' show promptVersion;
export 'src/runtime_manager.dart'
    show ModelPathResolver, RuntimeManager, RuntimeSlot, runtimeIdleUnload;
