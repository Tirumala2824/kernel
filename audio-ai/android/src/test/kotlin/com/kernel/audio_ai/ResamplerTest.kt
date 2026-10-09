package com.kernel.audio_ai

import org.junit.jupiter.api.Test
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertNotSame
import kotlin.test.assertTrue

class ResamplerTest {
    /** Skip the kernel half-width at both ends, where the input is truncated. */
    private val edge = 64

    @Test
    fun sameRateReturnsACopy() {
        val input = floatArrayOf(0.1f, -0.2f, 0.3f)
        val out = Resampler.resample(input, 16_000, 16_000)
        assertContentEquals(input, out)
        assertNotSame(input, out)
    }

    @Test
    fun downsample48kPreservesAnInBandTone() {
        val input = Signals.floatSine(1000.0, 48_000, 96_000, 0.5)
        val out = Resampler.resample(input, 48_000, 16_000)
        assertEquals(32_000, out.size)
        var maxErr = 0.0
        for (j in edge until out.size - edge) {
            val ideal = 0.5 * sin(2 * PI * 1000.0 * j / 16_000)
            maxErr = maxOf(maxErr, abs(out[j] - ideal))
        }
        assertTrue(maxErr < 0.005, "max error $maxErr")
    }

    @Test
    fun downsample44k1PreservesAnInBandTone() {
        val input = Signals.floatSine(1000.0, 44_100, 88_200, 0.5)
        val out = Resampler.resample(input, 44_100, 16_000)
        assertEquals(32_000, out.size)
        var maxErr = 0.0
        for (j in edge until out.size - edge) {
            val ideal = 0.5 * sin(2 * PI * 1000.0 * j / 16_000)
            maxErr = maxOf(maxErr, abs(out[j] - ideal))
        }
        assertTrue(maxErr < 0.005, "max error $maxErr")
    }

    @Test
    fun downsampleRejectsContentAboveTheNewNyquist() {
        // 12 kHz would alias to 4 kHz at 16 kHz without the low-pass.
        val input = Signals.floatSine(12_000.0, 48_000, 96_000, 0.5)
        val out = Resampler.resample(input, 48_000, 16_000)
        val inRms = rms(input, 0, input.size)
        val outRms = rms(out, edge, out.size - edge)
        assertTrue(outRms / inRms < 0.01, "alias leak ratio ${outRms / inRms}")
    }

    @Test
    fun dcGainIsOne() {
        val out = Resampler.resample(FloatArray(4_800) { 0.25f }, 48_000, 16_000)
        assertTrue(out.all { abs(it - 0.25f) < 1e-5f })
    }

    private fun rms(x: FloatArray, from: Int, to: Int): Double {
        var s = 0.0
        for (i in from until to) s += x[i].toDouble() * x[i]
        return sqrt(s / (to - from))
    }
}
