package com.kernel.audio_ai

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Every log-mel front-end parameter, in one object that ships with the model
 * version. A bundled model provides its own values through its manifest
 * (ModelManifest.logMel), so preprocessing always matches the model it feeds.
 *
 * [PROVISIONAL] is used only while no model is bundled. Its values are NOT
 * from the grain-pest training pipeline, which is still unknown
 * (docs/decisions-log.md open question). They follow the common 16 kHz
 * audio-classification front end used by YAMNet/VGGish-style models:
 * 25 ms periodic-Hann window, 10 ms hop, 512-point FFT, magnitude spectrum,
 * 64 HTK-mel bands from 125 to 7500 Hz, natural log with a 0.001 offset and
 * no centre padding.
 *
 * Fixed conventions (change the code, not the config, if training differs):
 * periodic Hann window, no centre/reflect padding, HTK mel scale
 * (1127 * ln(1 + f / 700)), triangular filters built in the mel domain with
 * the DC bin zeroed (as tf.signal.linear_to_mel_weight_matrix), no filter
 * area normalisation, natural log.
 */
data class LogMelConfig(
    val sampleRate: Int,
    val nFft: Int,
    val winLength: Int,
    val hopLength: Int,
    val nMels: Int,
    val fMin: Double,
    val fMax: Double,
    val logOffset: Double,
    /** 1.0 = magnitude spectrum, 2.0 = power spectrum. */
    val power: Double,
) {
    init {
        require(sampleRate > 0) { "sampleRate must be positive" }
        require(nFft >= 2 && (nFft and (nFft - 1)) == 0) { "nFft must be a power of two" }
        require(winLength in 1..nFft) { "winLength must be in 1..nFft" }
        require(hopLength > 0) { "hopLength must be positive" }
        require(nMels > 0) { "nMels must be positive" }
        require(fMin >= 0.0 && fMax > fMin && fMax <= sampleRate / 2.0) {
            "need 0 <= fMin < fMax <= sampleRate / 2"
        }
        require(logOffset > 0.0) { "logOffset must be positive" }
        require(power == 1.0 || power == 2.0) { "power must be 1.0 or 2.0" }
    }

    companion object {
        /** Provisional defaults until the training pipeline is known. See class doc. */
        val PROVISIONAL = LogMelConfig(
            sampleRate = 16_000,
            nFft = 512,
            winLength = 400,
            hopLength = 160,
            nMels = 64,
            fMin = 125.0,
            fMax = 7_500.0,
            logOffset = 0.001,
            power = 1.0,
        )
    }
}

/** Row-major log-mel matrix: [values] holds frames x nMels, frame-major. */
class LogMelResult(val frames: Int, val nMels: Int, val values: FloatArray) {
    operator fun get(frame: Int, mel: Int): Float = values[frame * nMels + mel]
}

/** Pure-Kotlin log-mel spectrogram. No Android dependencies. */
class LogMel(val config: LogMelConfig) {
    private val fft = Fft(config.nFft)
    private val window = periodicHann(config.winLength)
    private val numBins = config.nFft / 2 + 1

    /** [nMels][numBins] triangular filter weights. */
    internal val melWeights: Array<DoubleArray> = buildMelWeights(config)

    fun frameCount(numSamples: Int): Int =
        if (numSamples < config.winLength) 0
        else 1 + (numSamples - config.winLength) / config.hopLength

    /** [samples] are mono floats in [-1, 1) at [LogMelConfig.sampleRate]. */
    fun compute(samples: FloatArray): LogMelResult {
        val frames = frameCount(samples.size)
        val out = FloatArray(frames * config.nMels)
        val spectrum = DoubleArray(numBins)
        for (f in 0 until frames) {
            magnitudeSpectrum(samples, f * config.hopLength, spectrum)
            if (config.power == 2.0) {
                for (k in spectrum.indices) spectrum[k] = spectrum[k] * spectrum[k]
            }
            for (m in 0 until config.nMels) {
                val w = melWeights[m]
                var acc = 0.0
                for (k in 0 until numBins) acc += w[k] * spectrum[k]
                out[f * config.nMels + m] = ln(acc + config.logOffset).toFloat()
            }
        }
        return LogMelResult(frames, config.nMels, out)
    }

    /**
     * |FFT| of one windowed frame starting at [offset], zero-padded to nFft.
     * Writes nFft / 2 + 1 bins into [out].
     */
    internal fun magnitudeSpectrum(samples: FloatArray, offset: Int, out: DoubleArray) {
        val re = DoubleArray(config.nFft)
        val im = DoubleArray(config.nFft)
        for (i in 0 until config.winLength) re[i] = samples[offset + i] * window[i]
        fft.transform(re, im)
        for (k in 0 until numBins) out[k] = sqrt(re[k] * re[k] + im[k] * im[k])
    }

    companion object {
        fun hzToMel(hz: Double): Double = 1127.0 * ln(1.0 + hz / 700.0)

        fun periodicHann(length: Int): DoubleArray =
            DoubleArray(length) { n -> 0.5 - 0.5 * cos(2.0 * PI * n / length) }

        /** Centre frequency (Hz) of each mel band, for tests and diagnostics. */
        fun bandCentersHz(config: LogMelConfig): DoubleArray {
            val edges = bandEdgesMel(config)
            return DoubleArray(config.nMels) { m -> 700.0 * (Math.E.pow(edges[m + 1] / 1127.0) - 1.0) }
        }

        private fun bandEdgesMel(config: LogMelConfig): DoubleArray {
            val lo = hzToMel(config.fMin)
            val hi = hzToMel(config.fMax)
            return DoubleArray(config.nMels + 2) { i -> lo + (hi - lo) * i / (config.nMels + 1) }
        }

        private fun buildMelWeights(config: LogMelConfig): Array<DoubleArray> {
            val numBins = config.nFft / 2 + 1
            val edges = bandEdgesMel(config)
            val binMel = DoubleArray(numBins) { k -> hzToMel(k.toDouble() * config.sampleRate / config.nFft) }
            return Array(config.nMels) { m ->
                val lower = edges[m]
                val center = edges[m + 1]
                val upper = edges[m + 2]
                DoubleArray(numBins) { k ->
                    if (k == 0) {
                        0.0 // DC bin carries no band energy (matches tf.signal).
                    } else {
                        val up = (binMel[k] - lower) / (center - lower)
                        val down = (upper - binMel[k]) / (upper - center)
                        max(0.0, min(up, down))
                    }
                }
            }
        }
    }
}

/** In-place iterative radix-2 complex FFT of a fixed power-of-two size. */
internal class Fft(private val n: Int) {
    private val levels = Integer.numberOfTrailingZeros(n)
    private val cosTable = DoubleArray(n / 2) { i -> cos(2.0 * PI * i / n) }
    private val sinTable = DoubleArray(n / 2) { i -> sin(2.0 * PI * i / n) }

    init {
        require(n >= 2 && (n and (n - 1)) == 0) { "FFT size must be a power of two" }
    }

    fun transform(re: DoubleArray, im: DoubleArray) {
        require(re.size == n && im.size == n)
        // Bit-reversal permutation.
        for (i in 0 until n) {
            val j = Integer.reverse(i) ushr (32 - levels)
            if (j > i) {
                var t = re[i]; re[i] = re[j]; re[j] = t
                t = im[i]; im[i] = im[j]; im[j] = t
            }
        }
        var size = 2
        while (size <= n) {
            val half = size / 2
            val step = n / size
            var start = 0
            while (start < n) {
                var k = 0
                for (j in start until start + half) {
                    val l = j + half
                    // Forward transform: twiddle = exp(-2*pi*i*k/n).
                    val tRe = re[l] * cosTable[k] + im[l] * sinTable[k]
                    val tIm = -re[l] * sinTable[k] + im[l] * cosTable[k]
                    re[l] = re[j] - tRe
                    im[l] = im[j] - tIm
                    re[j] += tRe
                    im[j] += tIm
                    k += step
                }
                start += size
            }
            size *= 2
        }
    }
}
