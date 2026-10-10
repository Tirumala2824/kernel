/// Kernel's opt-in on-device LLM advice layer (Google AI Edge LiteRT-LM).
///
/// Text in, text out. [LocalAdviceEngine] implements `AdviceEngine` and
/// [LocalModelManager] implements `AdviceModelManager` from
/// kernel_contracts; [pickLitertlmUri] opens the system file picker for a
/// `.litertlm` model.
///
/// Isolation (docs/guardrails.md §8): this package never imports the audio-ai plugin,
/// never receives audio, paths or byte buffers, and never configures an
/// audio or vision backend. There is no network code.
library;

export 'src/local_advice_engine.dart' show LocalAdviceEngine, adviceTimeout;
export 'src/local_model_manager.dart' show LocalModelManager, pickLitertlmUri;
export 'src/output_guard.dart' show GuardCategory, GuardResult, checkOutput;
export 'src/prompts.dart' show promptVersion;
