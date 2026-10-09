package com.kernel.audio_ai

import java.io.StringReader
import java.util.Properties
import kotlin.math.exp

/** Model output classes. These map 1:1 onto the contract Classification values. */
enum class ModelLabel { CLEAN, UNCERTAIN, INFESTED }

/** Tensor layout of the log-mel input, ignoring the batch and optional channel dims. */
enum class InputLayout {
    /** [1, nMels, frames] or [1, nMels, frames, 1]. */
    MELS_FRAMES,

    /** [1, frames, nMels] or [1, frames, nMels, 1]. */
    FRAMES_MELS,
}

enum class OutputType { PROBABILITIES, LOGITS }

/** One real model prediction. Only ever built from a bundled model's output tensor. */
data class Prediction(val label: ModelLabel, val confidence: Double)

/**
 * Manifest that ships next to the model as `models/<name>.properties`, for
 * `models/<name>.tflite`. It ties the model version to the exact
 * preprocessing it was trained with. Every key is required except
 * `experimental`: nothing about preprocessing is silently defaulted, because
 * a mismatch would make the model's output meaningless.
 *
 * ```
 * version=grain-cnn-2026-11-01
 * labels=clean,uncertain,infested      # output tensor index order
 * output=probabilities                 # or logits (softmax applied here)
 * input_layout=mels_frames             # or frames_mels
 * experimental=true                    # only an explicit false marks it validated
 * sample_rate=16000
 * n_fft=512
 * win_length=400
 * hop_length=160
 * n_mels=64
 * f_min=125
 * f_max=7500
 * log_offset=0.001
 * power=1
 * ```
 */
data class ModelManifest(
    val version: String,
    val labels: List<ModelLabel>,
    val outputType: OutputType,
    val inputLayout: InputLayout,
    val experimental: Boolean,
    val logMel: LogMelConfig,
) {
    /**
     * Turns raw output scores into a prediction. Throws IllegalStateException
     * for output that no valid model would produce. The caller then reports
     * NOT_EVALUATED instead of guessing.
     */
    fun interpret(scores: FloatArray): Prediction {
        check(scores.size == labels.size) {
            "model produced ${scores.size} scores for ${labels.size} labels"
        }
        check(scores.all { it.isFinite() }) { "model produced non-finite scores" }
        val probs = when (outputType) {
            OutputType.PROBABILITIES -> {
                check(scores.all { it >= -PROB_TOLERANCE && it <= 1.0 + PROB_TOLERANCE }) {
                    "probabilities outside [0, 1]"
                }
                DoubleArray(scores.size) { scores[it].toDouble().coerceIn(0.0, 1.0) }
            }
            OutputType.LOGITS -> softmax(scores)
        }
        var best = 0
        for (i in 1 until probs.size) if (probs[i] > probs[best]) best = i
        return Prediction(labels[best], probs[best])
    }

    companion object {
        const val PIPELINE_SAMPLE_RATE = 16_000
        private const val PROB_TOLERANCE = 1e-3

        fun parse(text: String): ModelManifest {
            val props = Properties()
            props.load(StringReader(text))
            return parse(props)
        }

        fun parse(props: Properties): ModelManifest {
            fun required(key: String): String {
                val value = props.getProperty(key)?.trim()
                require(!value.isNullOrEmpty()) { "manifest is missing '$key'" }
                return value
            }
            fun int(key: String): Int =
                required(key).toIntOrNull() ?: throw IllegalArgumentException("'$key' is not an integer")
            fun double(key: String): Double =
                required(key).toDoubleOrNull() ?: throw IllegalArgumentException("'$key' is not a number")

            val version = required("version")
            require(version != NO_MODEL_VERSION) { "version must not be '$NO_MODEL_VERSION'" }

            val labels = required("labels").split(',').map { raw ->
                when (raw.trim().lowercase()) {
                    "clean" -> ModelLabel.CLEAN
                    "uncertain" -> ModelLabel.UNCERTAIN
                    "infested" -> ModelLabel.INFESTED
                    else -> throw IllegalArgumentException("unknown label '${raw.trim()}'")
                }
            }
            require(labels.size >= 2) { "need at least two labels" }
            require(labels.toSet().size == labels.size) { "labels must be unique" }

            val outputType = when (required("output").lowercase()) {
                "probabilities" -> OutputType.PROBABILITIES
                "logits" -> OutputType.LOGITS
                else -> throw IllegalArgumentException("output must be probabilities or logits")
            }
            val layout = when (required("input_layout").lowercase()) {
                "mels_frames" -> InputLayout.MELS_FRAMES
                "frames_mels" -> InputLayout.FRAMES_MELS
                else -> throw IllegalArgumentException("input_layout must be mels_frames or frames_mels")
            }
            val experimental = when (props.getProperty("experimental")?.trim()?.lowercase()) {
                null, "", "true" -> true
                "false" -> false
                else -> throw IllegalArgumentException("experimental must be true or false")
            }

            val sampleRate = int("sample_rate")
            require(sampleRate == PIPELINE_SAMPLE_RATE) {
                "model expects $sampleRate Hz but the capture pipeline produces $PIPELINE_SAMPLE_RATE Hz"
            }
            val logMel = LogMelConfig(
                sampleRate = sampleRate,
                nFft = int("n_fft"),
                winLength = int("win_length"),
                hopLength = int("hop_length"),
                nMels = int("n_mels"),
                fMin = double("f_min"),
                fMax = double("f_max"),
                logOffset = double("log_offset"),
                power = double("power"),
            )
            return ModelManifest(version, labels, outputType, layout, experimental, logMel)
        }

        private fun softmax(logits: FloatArray): DoubleArray {
            val maxLogit = logits.maxOrNull()!!.toDouble()
            val exps = DoubleArray(logits.size) { exp(logits[it] - maxLogit) }
            val sum = exps.sum()
            return DoubleArray(exps.size) { exps[it] / sum }
        }
    }
}

/** Contract value for "no model bundled" (contracts noModelVersion). */
const val NO_MODEL_VERSION = "none"
