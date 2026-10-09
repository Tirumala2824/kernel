package com.kernel.audio_ai

import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.sqrt

/** Signal problems that make a recording unusable for analysis. */
enum class GateReason { SILENCE, CLIPPING, HIGH_NOISE, TOO_SHORT }

/**
 * Aggregate level statistics for one recording. These are scalar summaries,
 * not audio, and are the only thing the gate exposes about the signal.
 */
data class QualityMetrics(
    val durationMs: Int,
    /**
     * Whole-clip RMS after DC removal in dBFS, computed as 20*log10(rms) with
     * samples in [-1, 1). A full-scale sine reads -3 dBFS.
     */
    val rmsDbfs: Double,
    /** Low percentile of short-frame RMS: the stationary background level. */
    val noiseFloorDbfs: Double,
    /** High percentile of short-frame RMS: the level of the loudest events. */
    val peakFrameDbfs: Double,
    /** peakFrameDbfs - noiseFloorDbfs. Diagnostic only for now (see below). */
    val snrDb: Double,
    /** Fraction of samples at or near full scale. */
    val clipFraction: Double,
)

data class QualityResult(val reasons: List<GateReason>, val metrics: QualityMetrics) {
    val pass: Boolean get() = reasons.isEmpty()
}

/**
 * Pure-Kotlin quality gate run on the raw PCM16 the device delivered (before
 * resampling, so clipping is measured on the real samples). No Android
 * dependencies, so it is unit-tested on the JVM.
 *
 * Any reason means quality = RETRY and classification = NOT_EVALUATED.
 *
 * Level references. Capture uses AudioSource.VOICE_RECOGNITION, which the
 * Android CDD (section 5.4.1) requires to have AGC and noise suppression
 * disabled and a sensitivity such that a 90 dB SPL 1 kHz tone gives an RMS of
 * 2500 for 16-bit samples (about -22 dBFS). So, roughly,
 * dBFS = dB SPL - 112. The level thresholds below use that mapping. They are
 * PROVISIONAL: they come from the CDD reference and synthetic signals, not
 * from labelled grain recordings, and must be re-checked on the iQOO 15 with
 * real quiet-room, warehouse-noise and sack-contact captures
 * (docs/device-validation.md).
 */
class QualityGate {

    fun evaluate(pcm: ShortArray, sampleRate: Int): QualityResult {
        require(sampleRate > 0) { "sampleRate must be positive" }
        val durationMs = (pcm.size.toLong() * 1000L / sampleRate).toInt()
        val frameLen = sampleRate * FRAME_MS / 1000
        val frameCount = if (frameLen > 0) pcm.size / frameLen else 0

        if (frameCount == 0) {
            // Not even one analysis frame: nothing else can be measured.
            return QualityResult(
                reasons = listOf(GateReason.TOO_SHORT),
                metrics = QualityMetrics(durationMs, MIN_DBFS, MIN_DBFS, MIN_DBFS, 0.0, 0.0),
            )
        }

        // DC offset removal: some capture paths deliver a small constant
        // offset that would otherwise read as signal energy.
        var sum = 0.0
        var clipped = 0
        for (s in pcm) {
            sum += s
            if (abs(s.toInt()) >= CLIP_SAMPLE_ABS) clipped++
        }
        val mean = sum / pcm.size

        var totalSq = 0.0
        val frameDb = DoubleArray(frameCount)
        for (f in 0 until frameCount) {
            var frameSq = 0.0
            val start = f * frameLen
            for (i in start until start + frameLen) {
                val x = (pcm[i] - mean) / FULL_SCALE
                frameSq += x * x
            }
            totalSq += frameSq
            frameDb[f] = rmsToDbfs(sqrt(frameSq / frameLen))
        }
        // Trailing partial frame still counts towards the overall RMS.
        for (i in frameCount * frameLen until pcm.size) {
            val x = (pcm[i] - mean) / FULL_SCALE
            totalSq += x * x
        }
        val rmsDbfs = rmsToDbfs(sqrt(totalSq / pcm.size))

        frameDb.sort()
        val noiseFloor = percentile(frameDb, NOISE_FLOOR_PERCENTILE)
        val peakFrame = percentile(frameDb, PEAK_PERCENTILE)
        val clipFraction = clipped.toDouble() / pcm.size

        val reasons = mutableListOf<GateReason>()
        if (durationMs < MIN_DURATION_MS) reasons += GateReason.TOO_SHORT
        if (rmsDbfs < SILENCE_RMS_DBFS) reasons += GateReason.SILENCE
        if (clipFraction > MAX_CLIP_FRACTION) reasons += GateReason.CLIPPING
        if (noiseFloor > HIGH_NOISE_FLOOR_DBFS) reasons += GateReason.HIGH_NOISE

        return QualityResult(
            reasons = reasons,
            metrics = QualityMetrics(
                durationMs = durationMs,
                rmsDbfs = rmsDbfs,
                noiseFloorDbfs = noiseFloor,
                peakFrameDbfs = peakFrame,
                snrDb = peakFrame - noiseFloor,
                clipFraction = clipFraction,
            ),
        )
    }

    companion object {
        /** PCM16 full scale used to normalise samples to [-1, 1). */
        const val FULL_SCALE = 32768.0

        /** Lower bound reported for digital silence (log of zero). */
        const val MIN_DBFS = -120.0

        /**
         * Shortest usable recording. The target is 2000 ms. 1500 ms (75%)
         * still gives ~150 log-mel frames at a 10 ms hop. Anything shorter
         * means the capture was interrupted (read error, mic taken by another
         * app). Provisional until the model's input window is known.
         */
        const val MIN_DURATION_MS = 1500

        /**
         * Whole-clip RMS below this is "silence". -70 dBFS is about 42 dB SPL
         * at the VOICE_RECOGNITION reference above. That is below a phone
         * held against a sack (contact and handling energy), and well above
         * digital silence (all zeros, as delivered by the Android 12+ mic
         * privacy toggle or a silenced client) and a blocked or dead mic.
         * A quiet room with the phone lying untouched is expected to fall
         * below it. MUST be calibrated on the iQOO 15: if clean-grain sack
         * contact reads below -70 dBFS, this threshold rejects clean sacks
         * and must be lowered.
         */
        const val SILENCE_RMS_DBFS = -70.0

        /**
         * A sample counts as clipped at |s| >= 32440, i.e. 99% of full scale
         * (about -0.09 dBFS). Real converters often saturate slightly below
         * 32767, so an exact-full-scale test would miss clipping.
         */
        const val CLIP_SAMPLE_ABS = 32_440

        /**
         * More than 0.1% clipped samples (32 samples in 2 s at 16 kHz) is
         * RETRY. An undistorted signal peaking at -1 dBFS has none. A single
         * knock can clip a handful of samples. Sustained clipping (phone
         * rubbing or tapping the sack, mic overload) is well above this and
         * corrupts the spectrum.
         */
        const val MAX_CLIP_FRACTION = 0.001

        /**
         * "High noise" means a loud continuous background that masks faint
         * insect transients. It is measured as the noise floor, the
         * 10th-percentile 20 ms frame RMS: even the quietest 10% of the clip
         * is louder than this. -45 dBFS is about 67 dB SPL at the
         * VOICE_RECOGNITION reference (steady loud talking, traffic, fans or
         * machinery right next to the phone). Short loud events do not raise
         * the floor, so tapping alone does not trigger it. Clipping does.
         * The SNR (peak frame - floor) is reported but not gated on yet:
         * a sensible minimum SNR depends on what pest sounds look like,
         * which needs labelled recordings.
         */
        const val HIGH_NOISE_FLOOR_DBFS = -45.0

        /** Frame length for the floor/peak estimate (20 ms, 320 samples at 16 kHz). */
        const val FRAME_MS = 20

        /** Percentile of frame levels taken as the stationary noise floor. */
        const val NOISE_FLOOR_PERCENTILE = 0.10

        /** Percentile of frame levels taken as the event (signal) level. */
        const val PEAK_PERCENTILE = 0.95

        fun rmsToDbfs(rms: Double): Double {
            if (rms <= 0.0) return MIN_DBFS
            val db = 20.0 * log10(rms)
            return if (db < MIN_DBFS) MIN_DBFS else db
        }

        private fun percentile(sorted: DoubleArray, p: Double): Double {
            val index = (p * (sorted.size - 1)).toInt().coerceIn(0, sorted.size - 1)
            return sorted[index]
        }
    }
}
