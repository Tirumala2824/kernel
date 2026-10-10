package com.kernel.local_llm

import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.SamplerConfig

/** Backends we ever try, in order. There is no audio or vision choice. */
enum class TextBackend(val wire: String) {
    GPU("gpu"),
    CPU("cpu"),
}

/**
 * Every LiteRT-LM configuration this plugin builds. Kept in one place so a
 * unit test can prove the isolation rule (docs/guardrails.md §8): the engine
 * is text-only, and the multimodal backends of EngineConfig are never set.
 */
object LlmConfig {
    /** GPU first, then CPU when the GPU backend fails to initialize. */
    val BACKEND_ORDER: List<TextBackend> = listOf(TextBackend.GPU, TextBackend.CPU)

    // Sampling for short, factual advice. Lower temperature and topK than
    // AI Edge Gallery's chat defaults (topK 64, topP 0.95, temperature 1.0):
    // the output should stay close to the facts in the prompt.
    const val TOP_K = 40
    const val TOP_P = 0.9
    const val TEMPERATURE = 0.3

    /** Hard cap on generated tokens; the prompt asks for at most 80 words. */
    const val MAX_OUTPUT_TOKENS = 220

    /** Whole request budget (load wait plus generation). Matches the Dart side. */
    const val GENERATION_TIMEOUT_MS = 25_000L

    /** Unload after this long without a generation. */
    const val IDLE_UNLOAD_MS = 3 * 60 * 1000L

    /**
     * Text-only engine config. [EngineConfig.visionBackend] and
     * [EngineConfig.audioBackend] are deliberately left at their null
     * defaults, so the model's audio and vision encoders are never loaded.
     */
    fun engineConfig(modelPath: String, backend: TextBackend, cacheDir: String): EngineConfig =
        EngineConfig(
            modelPath = modelPath,
            backend = when (backend) {
                TextBackend.GPU -> Backend.GPU()
                TextBackend.CPU -> Backend.CPU()
            },
            cacheDir = cacheDir,
        )

    /** One short-lived conversation per request: no history is carried over. */
    fun conversationConfig(systemInstruction: String): ConversationConfig =
        ConversationConfig(
            systemInstruction = Contents.of(systemInstruction),
            samplerConfig = SamplerConfig(
                topK = TOP_K,
                topP = TOP_P,
                temperature = TEMPERATURE,
            ),
            maxOutputToken = MAX_OUTPUT_TOKENS,
        )
}
