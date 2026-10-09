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

/** What the model was evaluated on. */
enum class Validation {
    /** Trained/evaluated on non-grain proxy recordings. Always experimental. */
    PROXY,

    /** Evaluated on labelled field recordings of real grain sacks. */
    FIELD,
}

/** One real model prediction. Only ever built from a bundled model's output tensor. */
data class Prediction(val label: ModelLabel, val confidence: Double)

/**
 * Manifest that ships next to the model as `models/<name>.properties`, for
 * `models/<name>.tflite`. It ties the model version to the exact
 * preprocessing it was trained with and to its provenance. The full format
 * (every key, type and rule) is specified in `audio-ai/README.md`, section
 * "Model manifest". Nothing about preprocessing is silently defaulted: a
 * mismatch would make the model's output meaningless. Unknown keys are
 * rejected (a typo must not silently disable a rule) except free-form
 * `meta.*` keys, which the engine ignores.
 *
 * Java properties syntax: `#` starts a comment only at the start of a line.
 * A `#` after a value is part of the value.
 *
 * ```
 * version=grain-cnn-2026-11-01
 * # Output tensor index order.
 * labels=clean,infested
 * output=probabilities
 * input_layout=mels_frames
 * validation=proxy
 * # A proxy model must say true. Only validation=field may say false.
 * experimental=true
 * note=Trained on non-grain proxy insect recordings. Not validated on sacks.
 * uncertain_below=0.7
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
    val validation: Validation,
    /** Human-readable provenance, shown with every result (EngineInfo.modelNote). */
    val note: String?,
    /** Top-class probability below this is reported as UNCERTAIN. Null = no band. */
    val uncertainBelow: Double?,
) {
    /**
     * Turns raw output scores into a prediction. Throws IllegalStateException
     * for output that no valid model would produce. The caller then reports
     * NOT_EVALUATED instead of guessing.
     *
     * The confidence is always the probability of the model's top output
     * class. With [uncertainBelow] set and that probability below it, the
     * label becomes UNCERTAIN and the confidence stays the top-class
     * probability (so it is below the band).
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
        val top = probs[best]
        val band = uncertainBelow
        return if (band != null && top < band) Prediction(ModelLabel.UNCERTAIN, top)
        else Prediction(labels[best], top)
    }

    companion object {
        const val PIPELINE_SAMPLE_RATE = 16_000
        private const val PROB_TOLERANCE = 1e-3

        /** Longest accepted `note`. It is shown on every result and in PDF headers. */
        const val MAX_NOTE_LENGTH = 500

        /** Every key the engine understands. Anything else (except `meta.*`) is rejected. */
        val KNOWN_KEYS: Set<String> = setOf(
            "version", "labels", "output", "input_layout", "validation", "experimental", "note",
            "uncertain_below", "sample_rate", "n_fft", "win_length", "hop_length", "n_mels",
            "f_min", "f_max", "log_offset", "power",
        )

        /** Prefix for free-form metadata keys (dataset id, commit, date). Ignored by the engine. */
        const val META_PREFIX = "meta."

        fun parse(text: String): ModelManifest {
            val props = Properties()
            props.load(StringReader(text))
            return parse(props)
        }

        fun parse(props: Properties): ModelManifest {
            for (key in props.stringPropertyNames()) {
                require(key in KNOWN_KEYS || key.startsWith(META_PREFIX)) { "unknown manifest key '$key'" }
            }
            fun optional(key: String): String? = props.getProperty(key)?.trim()?.takeIf { it.isNotEmpty() }
            fun required(key: String): String =
                optional(key) ?: throw IllegalArgumentException("manifest is missing '$key'")
            fun int(key: String): Int =
                required(key).toIntOrNull() ?: throw IllegalArgumentException("'$key' is not an integer")
            fun double(key: String): Double =
                required(key).toDoubleOrNull()?.takeIf { it.isFinite() }
                    ?: throw IllegalArgumentException("'$key' is not a number")

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
            val validation = when (required("validation").lowercase()) {
                "proxy" -> Validation.PROXY
                "field" -> Validation.FIELD
                else -> throw IllegalArgumentException("validation must be proxy or field")
            }
            val experimental = when (optional("experimental")?.lowercase()) {
                null, "true" -> true
                "false" -> false
                else -> throw IllegalArgumentException("experimental must be true or false")
            }
            // Contracts v2: a proxy model is always experimental. A manifest
            // that claims otherwise is invalid, so the model is not used.
            require(validation != Validation.PROXY || experimental) {
                "validation=proxy requires experimental=true"
            }

            val note = optional("note")
            require(validation != Validation.PROXY || note != null) {
                "validation=proxy requires a note describing the proxy data"
            }
            require(note == null || note.length <= MAX_NOTE_LENGTH) {
                "note is longer than $MAX_NOTE_LENGTH characters"
            }

            val uncertainBelow = optional("uncertain_below")?.let {
                val t = it.toDoubleOrNull()?.takeIf { v -> v.isFinite() }
                    ?: throw IllegalArgumentException("'uncertain_below' is not a number")
                // At or below 1/labels it could never trigger (the top class is
                // always at least that likely); at 1 or above every result
                // would be UNCERTAIN.
                require(t > 1.0 / labels.size && t < 1.0) {
                    "uncertain_below must be in (1/${labels.size}, 1)"
                }
                t
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
            return ModelManifest(
                version = version,
                labels = labels,
                outputType = outputType,
                inputLayout = layout,
                experimental = experimental,
                logMel = logMel,
                validation = validation,
                note = note,
                uncertainBelow = uncertainBelow,
            )
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
