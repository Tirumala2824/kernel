package com.kernel.audio_ai

import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.min
import kotlin.math.sin

/**
 * Band-limited sample-rate conversion (Hann-windowed sinc), used only when
 * the device does not deliver the 16 kHz the pipeline asks for. Pure Kotlin.
 *
 * Linear interpolation would fold content above the new Nyquist back into
 * the band and change the spectrogram, so a proper low-pass is applied.
 */
object Resampler {
    /** Sinc zero crossings on each side of the kernel centre. */
    const val ZERO_CROSSINGS = 16

    /** Low-pass cutoff as a fraction of the lower of the two Nyquist rates. */
    const val CUTOFF_FRACTION = 0.95

    fun resample(input: FloatArray, inRate: Int, outRate: Int): FloatArray {
        require(inRate > 0 && outRate > 0) { "rates must be positive" }
        if (inRate == outRate) return input.copyOf()
        val ratio = outRate.toDouble() / inRate
        val outLen = floor(input.size * ratio).toInt()
        // Cutoff in cycles per input sample.
        val fc = 0.5 * min(1.0, ratio) * CUTOFF_FRACTION
        val halfWidth = ZERO_CROSSINGS / (2.0 * fc)
        val out = FloatArray(outLen)
        for (j in 0 until outLen) {
            val t = j / ratio
            val first = maxOf(0, ceil(t - halfWidth).toInt())
            val last = minOf(input.size - 1, floor(t + halfWidth).toInt())
            var acc = 0.0
            var weightSum = 0.0
            for (n in first..last) {
                val d = t - n
                val w = kernel(d, fc, halfWidth)
                acc += input[n] * w
                weightSum += w
            }
            // Normalising by the kernel sum keeps DC gain exactly 1 at every
            // fractional phase (and near the edges where the kernel is cut).
            out[j] = if (weightSum != 0.0) (acc / weightSum).toFloat() else 0f
        }
        return out
    }

    private fun kernel(d: Double, fc: Double, halfWidth: Double): Double {
        if (d <= -halfWidth || d >= halfWidth) return 0.0
        val x = 2.0 * fc * d
        val sinc = if (x == 0.0) 1.0 else sin(PI * x) / (PI * x)
        val window = 0.5 * (1.0 + cos(PI * d / halfWidth))
        return 2.0 * fc * sinc * window
    }
}
