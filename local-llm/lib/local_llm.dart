/// Kernel's opt-in on-device LLM advice layer (LiteRT-LM).
///
/// Text in, text out. Implements `AdviceEngine` and `AdviceModelManager`
/// from kernel_contracts. Never imports audio_ai and never receives audio;
/// see docs/guardrails.md §8. Implementation lands in W1 (audio-ai-dev).
library;
