package com.kernel.audio_ai

/**
 * What the analysis needs from the model layer. Production code has exactly
 * two sources: [NoModel] (nothing bundled) and the handle of a real loaded
 * LiteRT model ([ModelRunner.handle]).
 */
interface ModelHandle {
    /** Model version, or [NO_MODEL_VERSION]. */
    val version: String
    val experimental: Boolean

    /** Preprocessing the model was trained with. It ships with the model version. */
    val logMelConfig: LogMelConfig

    /** Real model output, or null if the model could not evaluate this input. */
    fun classify(logMel: LogMelResult): Prediction?
}

/** No model bundled: nothing is ever classified. */
object NoModel : ModelHandle {
    override val version: String = NO_MODEL_VERSION
    override val experimental: Boolean = true
    override val logMelConfig: LogMelConfig = LogMelConfig.PROVISIONAL
    override fun classify(logMel: LogMelResult): Prediction? = null
}

class Analysis(
    /** Empty means quality PASS. */
    val reasons: List<GateReason>,
    val metrics: QualityMetrics,
    /** Only ever set from a real model's output on a PASS recording. */
    val prediction: Prediction?,
    val modelVersion: String,
    val experimental: Boolean,
    /** Device rate the audio was resampled from, or null if it was already at the model rate. */
    val resampledFrom: Int?,
    /** Log-mel frames computed (0 if the gate failed). */
    val logMelFrames: Int,
)

/**
 * Pure pipeline after capture: quality gate on the raw device PCM, then (only
 * on PASS) resampling to the model rate, log-mel, and the model. No Android
 * dependencies. Intermediate float buffers are zeroed before returning.
 */
class ScanAnalyzer(private val gate: QualityGate = QualityGate()) {
    private var logMel: LogMel? = null

    fun analyze(pcm: ShortArray, sampleRate: Int, model: ModelHandle): Analysis {
        val quality = gate.evaluate(pcm, sampleRate)
        if (!quality.pass) {
            return Analysis(quality.reasons, quality.metrics, null, model.version, model.experimental, null, 0)
        }

        val config = model.logMelConfig
        val raw = FloatArray(pcm.size) { pcm[it] / QualityGate.FULL_SCALE.toFloat() }
        val samples = if (sampleRate == config.sampleRate) raw
            else Resampler.resample(raw, sampleRate, config.sampleRate)
        val frontEnd = logMel?.takeIf { it.config == config } ?: LogMel(config).also { logMel = it }

        // Log-mel is computed even with no model, so latency on the device
        // reflects the real pipeline. With no model the matrix is discarded
        // unused: no class is ever derived from it.
        val features = frontEnd.compute(samples)
        val prediction = if (model.version == NO_MODEL_VERSION) null else model.classify(features)

        raw.fill(0f)
        if (samples !== raw) samples.fill(0f)
        features.values.fill(0f)

        return Analysis(
            reasons = emptyList(),
            metrics = quality.metrics,
            prediction = prediction,
            modelVersion = model.version,
            experimental = model.experimental,
            resampledFrom = if (sampleRate == config.sampleRate) null else sampleRate,
            logMelFrames = features.frames,
        )
    }
}
