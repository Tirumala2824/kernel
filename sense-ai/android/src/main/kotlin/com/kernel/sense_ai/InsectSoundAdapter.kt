package com.kernel.sense_ai

import org.json.JSONObject
import org.tensorflow.lite.DataType
import org.tensorflow.lite.Interpreter
import java.io.File
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.MessageDigest
import kotlin.math.exp

/** Offline adapter for one pinned CNN. Never shared with SoundClassifier/YAMNet. */
internal class InsectSoundAdapter(private val readAsset: (String) -> ByteArray) {
    fun classifyWavFile(path: String): Map<String, Any?> = try {
        classify(path)
    } catch (_: OutOfMemoryError) {
        noMatch("unavailable", listOf("memory_unavailable"))
    }

    private fun classify(path: String): Map<String, Any?> {
        val audio = try {
            val file = File(path)
            if (!file.isFile || !file.canRead()) return noMatch("unavailable", listOf("file_unreadable"))
            if (file.length() > InsectWav.MAX_BYTES) return noMatch("rejected", listOf("audio_too_large"))
            val bytes = file.inputStream().use { input ->
                val out = ByteArrayOutputStream()
                val chunk = ByteArray(8192)
                try {
                    while (true) {
                        val n = input.read(chunk, 0, minOf(chunk.size, InsectWav.MAX_BYTES + 1 - out.size()))
                        if (n <= 0) break
                        out.write(chunk,0,n)
                        if (out.size() > InsectWav.MAX_BYTES) throw InsectInputException("audio_too_large")
                    }
                    out.toByteArray()
                } finally { chunk.fill(0); out.reset() }
            }
            try { InsectWav.decode(bytes) } finally { bytes.fill(0) }
        } catch (e: InsectInputException) {
            return noMatch("rejected",listOf(e.reason))
        } catch (_: Exception) {
            return noMatch("unavailable",listOf("file_unreadable"))
        }
        var wave: FloatArray? = null
        try {
            val reasons = audio.qualityReasons()
            if (reasons.isNotEmpty()) return noMatch("rejected",reasons,audio)
            val resampled = InsectFrontend.resample(audio.samples, audio.sampleRate)
            wave = resampled
            val offsets = InsectFrontend.cropOffsets(resampled.size)
            if (!InsectFrontend.hasSignalInSelectedCrops(resampled, offsets)) {
                return noMatch("rejected", listOf("no_signal_in_selected_windows"), audio)
            }
            val labelsJson = JSONObject(String(verifiedAsset("labels.json", LABELS_SHA)))
            val labels = List(32) { labelsJson.getString(it.toString()) }
            val config = JSONObject(String(verifiedAsset("config.json", CONFIG_SHA)))
            val model = verifiedAsset("model.tflite", MODEL_SHA)
            val buffer = ByteBuffer.allocateDirect(model.size).order(ByteOrder.nativeOrder()).apply { put(model); rewind() }
            val scores = DoubleArray(32)
            Interpreter(buffer, Interpreter.Options().setNumThreads(2)).use { net ->
                require(net.inputTensorCount == 1 && net.outputTensorCount == 1)
                require(net.getInputTensor(0).dataType() == DataType.FLOAT32 && net.getInputTensor(0).shape().contentEquals(intArrayOf(1,1,64,201)))
                require(net.getOutputTensor(0).dataType() == DataType.FLOAT32 && net.getOutputTensor(0).shape().contentEquals(intArrayOf(1,32)))
                val input = ByteBuffer.allocateDirect(64*201*4).order(ByteOrder.nativeOrder())
                val output = ByteBuffer.allocateDirect(32*4).order(ByteOrder.nativeOrder())
                for (offset in offsets) {
                    val feature = InsectFrontend.logmel(resampled, offset)
                    input.rewind(); for (value in feature) input.putFloat(value); input.rewind()
                    feature.fill(0f)
                    output.rewind(); net.run(input, output); output.rewind()
                    val logits = DoubleArray(32) { output.float.toDouble() }
                    require(logits.all { it.isFinite() })
                    val max = logits.max()
                    val weights = DoubleArray(32) { exp(logits[it] - max) }
                    val sum = weights.sum()
                    for (i in scores.indices) scores[i] += weights[i] / sum / offsets.size
                }
                input.clear(); while (input.hasRemaining()) input.put(0.toByte())
            }
            val order = scores.indices.sortedByDescending { scores[it] }
            val identified = identify(labels, scores)
            return mapOf(
                "status" to "evaluated", "level" to identified.first, "label" to identified.second,
                "topLabels" to order.take(5).map { mapOf("label" to labels[it], "score" to scores[it]) },
                "reasons" to emptyList<String>(), "modelId" to MODEL_ID,
                "modelVersion" to config.getString("model_version"), "modelRevision" to REVISION,
                "sampleRate" to audio.sampleRate, "durationMs" to audio.durationMs, "experimental" to true,
            )
        } catch (_: AssetIntegrityException) {
            return noMatch("unavailable",listOf("asset_integrity"),audio)
        } catch (_: IOException) {
            return noMatch("unavailable",listOf("model_unavailable"),audio)
        } catch (_: LinkageError) {
            return noMatch("unavailable",listOf("runtime_unavailable"),audio)
        } catch (_: Exception) {
            return noMatch("unavailable",listOf("inference_failed"),audio)
        } finally { audio.samples.fill(0f); wave?.fill(0f) }
    }

    private class AssetIntegrityException : IllegalStateException()

    private fun verifiedAsset(name: String, sha: String): ByteArray {
        val bytes = readAsset("insect_sound/$name")
        val actual = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
        if (actual != sha) throw AssetIntegrityException()
        return bytes
    }

    companion object {
        internal fun noMatch(status: String, reasons: List<String>, audio: InsectAudio? = null): Map<String, Any?> = mapOf(
            "status" to status, "level" to "unknown", "label" to null,
            "topLabels" to emptyList<Any>(), "reasons" to reasons,
            "modelId" to MODEL_ID, "modelVersion" to "none", "modelRevision" to REVISION,
            "sampleRate" to audio?.sampleRate, "durationMs" to audio?.durationMs, "experimental" to true,
        )

        const val MODEL_ID = "ganesh333/kernel-insect-classifier"
        const val REVISION = "001425d7fab4b44af5cc571174410f1c78552d0e"
        const val MODEL_SHA = "55ad541b87d1ae0bae5a71c7ec9091fc40617051f479ac3f12996bacda6f597e"
        private const val LABELS_SHA = "c71894abb1c95dc877b59d48c7028cb3e9aa898d8352113ee280240b92b33748"
        private const val CONFIG_SHA = "52d8010c97b0d01a87f4f32a4e2294e6a03d1ff769352568a200e2404c618f6d"
        private val orthoptera = listOf("Pseudochorthippus", "Chorthippus", "Gryllus", "Nemobius", "Oecanthus", "Pholidoptera", "Roeseliana", "Tettigonia")
        private val cicadidae = listOf("Azanicada", "Brevisiana", "Kikihia", "Myopsalta", "Platypleura", "Pycna")
        private fun genus(species: String) = (orthoptera + cicadidae).firstOrNull { species.startsWith(it) } ?: species

        internal fun identify(labels: List<String>, scores: DoubleArray): Pair<String, String?> {
            val top = scores.indices.maxBy { scores[it] }
            if (scores[top] >= 0.6) return "species" to labels[top]
            for (level in listOf("genus", "group")) {
                val totals = linkedMapOf<String, Double>()
                for (i in scores.indices) {
                    val g = genus(labels[i])
                    val key = if (level == "genus") g else if (g in orthoptera) "Orthoptera (crickets/grasshoppers)" else "Cicadidae (cicadas)"
                    totals[key] = (totals[key] ?: 0.0) + scores[i]
                }
                val best = totals.maxBy { it.value }
                if (best.value >= 0.6) return level to best.key
            }
            return "unknown" to null
        }
    }
}
