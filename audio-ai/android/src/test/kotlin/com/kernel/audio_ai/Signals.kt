package com.kernel.audio_ai

import java.util.Random
import kotlin.math.PI
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

/** Deterministic synthetic test signals (test fixtures only). */
object Signals {
    /** Linear RMS for a dBFS level (20*log10(rms) convention used by QualityGate). */
    fun rms(dbfs: Double): Double = 10.0.pow(dbfs / 20.0)

    fun samples(rate: Int, durationMs: Int): Int = rate * durationMs / 1000

    /** Sine whose RMS is [rmsDbfs]. */
    fun sine(freqHz: Double, rate: Int, durationMs: Int, rmsDbfs: Double): ShortArray {
        val amplitude = rms(rmsDbfs) * sqrt(2.0)
        return ShortArray(samples(rate, durationMs)) { n ->
            toPcm(amplitude * sin(2.0 * PI * freqHz * n / rate))
        }
    }

    /** Sine with a peak [amplitude] relative to full scale, hard-clipped to PCM16 range. */
    fun clippedSine(freqHz: Double, rate: Int, durationMs: Int, amplitude: Double): ShortArray =
        ShortArray(samples(rate, durationMs)) { n -> toPcm(amplitude * sin(2.0 * PI * freqHz * n / rate)) }

    /** Gaussian white noise with RMS [rmsDbfs], fixed seed for reproducibility. */
    fun noise(rate: Int, durationMs: Int, rmsDbfs: Double, seed: Long = 42L): ShortArray {
        val r = Random(seed)
        val sigma = rms(rmsDbfs)
        return ShortArray(samples(rate, durationMs)) { toPcm(r.nextGaussian() * sigma) }
    }

    fun floatSine(freqHz: Double, rate: Int, count: Int, amplitude: Double): FloatArray =
        FloatArray(count) { n -> (amplitude * sin(2.0 * PI * freqHz * n / rate)).toFloat() }

    fun toPcm(x: Double): Short = (x * 32768.0).roundToInt().coerceIn(-32768, 32767).toShort()
}
