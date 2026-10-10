package com.kernel.local_llm

import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.EmbeddingEngineConfig
import com.google.ai.edge.litertlm.EmbeddingOptions
import com.google.ai.edge.litertlm.InputData

/**
 * EmbeddingGemma on LiteRT-LM. GPU first, CPU fallback. The vision and
 * audio encoders are configured only when the model header says the model
 * takes those inputs (Pest ID image/audio embeddings, guardrails §8
 * amendment); a text-only embedding model gets a text-only engine.
 */
object EmbedConfig {
    val BACKEND_ORDER: List<TextBackend> = listOf(TextBackend.GPU, TextBackend.CPU)

    /** Whole budget of one embedding, load included. Matches the Dart side. */
    const val TIMEOUT_MS = 15_000L

    /** Longest text passed in, in UTF-16 units (EmbeddingGemma takes 2048 tokens). */
    const val MAX_TEXT_CHARS = 8_000

    fun engineConfig(
        modelPath: String,
        backend: TextBackend,
        vision: Boolean,
        audio: Boolean,
        cacheDir: String,
    ): EmbeddingEngineConfig =
        EmbeddingEngineConfig(
            modelPath = modelPath,
            backend = PestIdConfig.backendOf(backend),
            visionBackend = if (vision) PestIdConfig.backendOf(backend) else null,
            audioBackend = if (audio) Backend.CPU() else null,
            cacheDir = cacheDir,
        )

    /**
     * Full-length, normalised output. Matryoshka truncation and the
     * re-normalisation after it happen on the Dart side.
     */
    fun options(): EmbeddingOptions = EmbeddingOptions(normalize = true, insertSpecialTokens = true)

    /** Null when [kind] has no usable payload. */
    fun input(kind: NativeEmbedKind, text: String?, bytes: ByteArray?): InputData? = when (kind) {
        NativeEmbedKind.TEXT -> text?.takeIf { it.isNotBlank() && it.length <= MAX_TEXT_CHARS }?.let { InputData.Text(it) }
        NativeEmbedKind.IMAGE -> bytes?.takeIf {
            it.size <= PestIdConfig.MAX_IMAGE_BYTES && MediaCheck.isPngOrJpeg(it)
        }?.let { InputData.Image(it) }
        NativeEmbedKind.AUDIO -> bytes?.takeIf {
            it.size <= PestIdConfig.MAX_AUDIO_BYTES && MediaCheck.isRiffWave(it)
        }?.let { InputData.Audio(it) }
    }
}
