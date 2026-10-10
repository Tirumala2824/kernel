package com.kernel.local_llm

import android.util.Log
import com.google.ai.edge.litertlm.BackendType
import com.google.ai.edge.litertlm.Modality
import com.google.ai.edge.litertlm.ModelInfo
import com.google.ai.edge.litertlm.NpuBrand
import java.io.File

/**
 * Reads LiteRT-LM model headers with [ModelInfo.from]. This never creates
 * an Engine and never loads weights. Results are cached per file version
 * (path, size, modification time), so the runtime can ask cheaply which
 * kind a file is and which inputs it takes.
 */
class ModelProber {
    private val cache = object : LinkedHashMap<String, Probe>(16, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Probe>?): Boolean = size > MAX_CACHED
    }

    /** One header read; [result] is null when the file is not a readable LiteRT-LM model. */
    private class Probe(val result: NativeProbeResult?)

    fun probe(file: File): NativeProbeResult? {
        val key = "${file.path}|${file.length()}|${file.lastModified()}"
        synchronized(cache) { cache[key]?.let { return it.result } }
        val result = try {
            ModelInfo.from(file.path).use(::describe)
        } catch (t: Throwable) {
            // UnsatisfiedLinkError on hosts without the runtime, or a file
            // that is not a LiteRT-LM container. Never logs paths or content.
            Log.w(TAG, "model header unreadable: ${t.javaClass.simpleName}")
            null
        }
        synchronized(cache) { cache[key] = Probe(result) }
        return result
    }

    /** LLM or EMBEDDING from the header; null when unknown or unreadable. */
    fun kindOf(file: File): ModelKind? = kindOf(probe(file)?.kind)

    companion object {
        private const val TAG = "LocalLlm"
        private const val MAX_CACHED = 16

        fun kindOf(kind: NativeProbedKind?): ModelKind? = when (kind) {
            NativeProbedKind.LLM -> ModelKind.LLM
            NativeProbedKind.EMBEDDING -> ModelKind.EMBEDDING
            NativeProbedKind.UNKNOWN, null -> null
        }

        fun backendWire(type: BackendType): String = type.name.lowercase()

        /** Null for an unknown brand, so "no NPU build" never reads as a brand. */
        fun npuWire(brand: NpuBrand?): String? =
            if (brand == null || brand == NpuBrand.UNKNOWN) null else brand.name.lowercase()

        private fun describe(info: ModelInfo): NativeProbeResult {
            val modalities = info.inputModalities()
            val kind = when (info) {
                is ModelInfo.Llm -> NativeProbedKind.LLM
                is ModelInfo.Embedding -> NativeProbedKind.EMBEDDING
                else -> NativeProbedKind.UNKNOWN
            }
            val backends = runCatching { info.supportedBackends(Modality.TEXT) }
                .getOrDefault(emptyList())
                .map(::backendWire)
                .distinct()
            val soc: String? = runCatching { info.socName(Modality.TEXT) }.getOrNull()
            val npu: NpuBrand? = runCatching { info.npuBrand(Modality.TEXT) }.getOrNull()
            val dim: Int? = (info as? ModelInfo.Embedding)?.let { runCatching { it.dimension() }.getOrNull() }
            return NativeProbeResult(
                kind = kind,
                text = modalities.text,
                vision = modalities.vision,
                audio = modalities.audio,
                video = modalities.video,
                backends = backends,
                maxContextTokens = runCatching { info.maxContextTokens() }.getOrNull()?.takeIf { it > 0 }?.toLong(),
                embeddingDim = dim?.takeIf { it > 0 }?.toLong(),
                socName = soc?.takeIf { it.isNotBlank() },
                npuBrand = npuWire(npu),
            )
        }
    }
}
