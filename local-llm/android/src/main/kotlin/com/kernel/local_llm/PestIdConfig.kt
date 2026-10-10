@file:OptIn(ExperimentalApi::class)

package com.kernel.local_llm

import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.ExperimentalApi
import com.google.ai.edge.litertlm.ExperimentalFlags
import com.google.ai.edge.litertlm.ResponseFormat
import com.google.ai.edge.litertlm.SamplerConfig

/**
 * Pest ID mode only (docs/guardrails.md §8 amendment, §9).
 *
 * This file and EmbedConfig are the only places in local-llm that configure
 * a vision or audio encoder or build image/audio content. The grain advice
 * engine (LlmConfig) stays text-only; LlmConfigTest and PestIdConfigTest
 * prove both sides.
 *
 * Inputs are the user-validated crop (plus an optional context frame) and
 * a clip of at most 30 s, held in memory for one request and never written
 * or logged.
 */
object PestIdConfig {
    /** Main and vision backend tried together: GPU first, then CPU. Audio always runs on CPU. */
    val BACKEND_ORDER: List<TextBackend> = listOf(TextBackend.GPU, TextBackend.CPU)

    /** Gemma 4 visual token budget per image; one of 70, 140, 280, 560, 1120. */
    const val VISUAL_TOKEN_BUDGET = 560
    val ALLOWED_VISUAL_BUDGETS: Set<Int> = setOf(70, 140, 280, 560, 1120)

    /** The crop plus an optional downscaled context frame. */
    const val MAX_IMAGES = 2

    /** Encoded image cap (a 768 px JPEG crop is far smaller). */
    const val MAX_IMAGE_BYTES = 8 * 1024 * 1024

    /** 30 s of 16 kHz mono 16-bit PCM plus room for the RIFF header and metadata chunks. */
    const val MAX_AUDIO_SECONDS = 30
    const val MAX_AUDIO_BYTES = MAX_AUDIO_SECONDS * 16_000 * 2 + 4_096

    /** Hard cap on generated tokens for the structured JSON analysis. */
    const val MAX_OUTPUT_TOKENS = 640

    /** Whole Pest ID budget (all runs of one analysis); matches the Dart side. */
    const val TIMEOUT_MS = 45_000L

    /**
     * Multimodal engine: the vision encoder on the same backend as the main
     * model (GPU, CPU fallback), the audio encoder on CPU.
     */
    fun engineConfig(modelPath: String, backend: TextBackend, cacheDir: String): EngineConfig =
        EngineConfig(
            modelPath = modelPath,
            backend = backendOf(backend),
            visionBackend = backendOf(backend),
            audioBackend = Backend.CPU(),
            maxNumImages = MAX_IMAGES,
            cacheDir = cacheDir,
        )

    /** Must run before the Pest ID Engine is created (LiteRT-LM reads it at creation). */
    fun applyVisualBudget() {
        ExperimentalFlags.visualTokenBudget = VISUAL_TOKEN_BUDGET
    }

    /** Restores the runtime default before the text-only advice engine is created. */
    fun clearVisualBudget() {
        ExperimentalFlags.visualTokenBudget = null
    }

    fun currentVisualBudget(): Int? = ExperimentalFlags.visualTokenBudget

    /** One fresh conversation per run: no history, sampling chosen by the Dart side. */
    fun conversationConfig(request: NativePestRequest): ConversationConfig =
        ConversationConfig(
            systemInstruction = Contents.of(request.systemInstruction),
            samplerConfig = SamplerConfig(
                topK = request.topK.toInt().coerceIn(1, 64),
                topP = request.topP.coerceIn(0.05, 1.0),
                temperature = request.temperature.coerceIn(0.0, 1.5),
                seed = request.seed.toInt(),
            ),
            maxOutputToken = request.maxOutputTokens.toInt().coerceIn(1, MAX_OUTPUT_TOKENS),
            enableResponseFormat = request.format != NativeResponseFormat.NONE,
        )

    /** Constrained decoding; null for free text. */
    fun responseFormat(format: NativeResponseFormat, spec: String?): ResponseFormat? = when (format) {
        NativeResponseFormat.NONE -> null
        NativeResponseFormat.JSON -> spec?.let { ResponseFormat.json(it) }
        NativeResponseFormat.REGEX -> spec?.let { ResponseFormat.regex(it) }
    }

    /** Images first (Gemma 4 model card), then the clip, then the text. */
    fun contents(images: List<ByteArray>, audioWav: ByteArray?, prompt: String): Contents {
        val parts = ArrayList<Content>(images.size + 2)
        images.forEach { parts.add(Content.ImageBytes(it)) }
        audioWav?.let { parts.add(Content.AudioBytes(it)) }
        parts.add(Content.Text(prompt))
        return Contents.of(parts)
    }

    /**
     * Null when the request may run; UNSUPPORTED when its media is not what
     * the engine accepts (too many or oversized images, not PNG/JPEG, a clip
     * that is not RIFF WAV or longer than 30 s, or a format without a spec).
     */
    fun validate(request: NativePestRequest): NativeGenerateStatus? {
        if (request.images.size > MAX_IMAGES) return NativeGenerateStatus.UNSUPPORTED
        if (request.images.any { it.size > MAX_IMAGE_BYTES || !MediaCheck.isPngOrJpeg(it) }) {
            return NativeGenerateStatus.UNSUPPORTED
        }
        request.audioWav?.let { wav ->
            if (wav.size > MAX_AUDIO_BYTES || !MediaCheck.isRiffWave(wav)) return NativeGenerateStatus.UNSUPPORTED
        }
        if (request.format != NativeResponseFormat.NONE && request.formatSpec.isNullOrBlank()) {
            return NativeGenerateStatus.UNSUPPORTED
        }
        if (request.images.isEmpty() && request.audioWav == null && request.prompt.isBlank()) {
            return NativeGenerateStatus.UNSUPPORTED
        }
        return null
    }

    internal fun backendOf(choice: TextBackend): Backend = when (choice) {
        TextBackend.GPU -> Backend.GPU()
        TextBackend.CPU -> Backend.CPU()
    }
}

/** Magic-number checks on in-memory media. Never reads beyond the header. */
object MediaCheck {
    fun isPngOrJpeg(bytes: ByteArray): Boolean = isPng(bytes) || isJpeg(bytes)

    fun isPng(b: ByteArray): Boolean =
        b.size >= 8 && b[0] == 0x89.toByte() && b[1] == 'P'.code.toByte() &&
            b[2] == 'N'.code.toByte() && b[3] == 'G'.code.toByte()

    fun isJpeg(b: ByteArray): Boolean =
        b.size >= 3 && b[0] == 0xFF.toByte() && b[1] == 0xD8.toByte() && b[2] == 0xFF.toByte()

    fun isRiffWave(b: ByteArray): Boolean =
        b.size >= 12 && String(b, 0, 4, Charsets.US_ASCII) == "RIFF" && String(b, 8, 4, Charsets.US_ASCII) == "WAVE"
}
