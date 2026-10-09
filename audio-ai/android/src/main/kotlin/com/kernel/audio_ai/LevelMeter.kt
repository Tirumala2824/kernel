package com.kernel.audio_ai

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.sqrt

/** One live input-level reading. Scalars only: never samples or spectra. */
data class LevelReading(
    /** Kept audio recorded so far (the warm-up discard is not counted). */
    val elapsedMs: Int,
    /** Kept audio the capture is aiming for. */
    val targetMs: Int,
    /** RMS of the window after removing the window mean, in dBFS (floor [QualityGate.MIN_DBFS]). */
    val rmsDbfs: Double,
    /** Largest |sample| of the window in dBFS. -32768 reads 0 dBFS. */
    val peakDbfs: Double,
)

/**
 * Live input levels, computed inside the capture loop as samples arrive.
 * It emits one [LevelReading] for every [windowMs] of kept audio, whatever the
 * read size, so the UI gets about 20 readings per second.
 *
 * Pure Kotlin with no Android dependencies, so it is unit-tested on the JVM.
 * The meter keeps only running sums (count, sum, sum of squares, peak), never
 * a copy of the samples.
 *
 * RMS uses the same dBFS convention as [QualityGate]: 20*log10(rms) with
 * samples scaled to [-1, 1), and a full-scale sine reads about -3 dBFS. The
 * window mean is removed first, so a constant DC offset from the capture path
 * reads as silence here too. That keeps the meter consistent with the gate's
 * silence check. Peak is taken on the raw samples, because clipping is a
 * raw-sample property.
 */
class LevelMeter(
    private val sampleRate: Int,
    private val targetMs: Int,
    windowMs: Int = WINDOW_MS,
    private val onLevel: (LevelReading) -> Unit,
) {
    init {
        require(sampleRate > 0) { "sampleRate must be positive" }
        require(targetMs >= 0) { "targetMs must not be negative" }
        require(windowMs > 0) { "windowMs must be positive" }
    }

    /** Samples per reading (800 at 16 kHz, 2400 at 48 kHz, 2205 at 44.1 kHz). */
    val windowSamples: Int = max(1, (sampleRate.toLong() * windowMs / 1000L).toInt())

    private var count = 0
    private var sum = 0L
    private var sumSq = 0L
    private var peakAbs = 0
    private var emittedSamples = 0L

    /** Feeds [length] freshly read samples starting at [offset]. */
    fun add(buffer: ShortArray, offset: Int, length: Int) {
        require(offset >= 0 && length >= 0 && offset + length <= buffer.size) { "range outside buffer" }
        for (i in offset until offset + length) {
            val s = buffer[i].toInt()
            sum += s
            sumSq += s.toLong() * s
            val a = abs(s)
            if (a > peakAbs) peakAbs = a
            count++
            if (count == windowSamples) emit()
        }
    }

    /** Emits the trailing partial window, if any (a capture that ended early). */
    fun flush() {
        if (count > 0) emit()
    }

    private fun emit() {
        emittedSamples += count
        val reading = LevelReading(
            elapsedMs = (emittedSamples * 1000L / sampleRate).toInt(),
            targetMs = targetMs,
            rmsDbfs = rmsDbfs(count, sum, sumSq),
            peakDbfs = peakDbfs(peakAbs),
        )
        count = 0
        sum = 0L
        sumSq = 0L
        peakAbs = 0
        onLevel(reading)
    }

    companion object {
        /** One reading per 50 ms of audio, i.e. about 20 Hz (contracts CaptureLevel). */
        const val WINDOW_MS = 50

        /** Mean-removed RMS in dBFS from running sums over [n] PCM16 samples. */
        fun rmsDbfs(n: Int, sum: Long, sumSq: Long): Double {
            if (n <= 0) return QualityGate.MIN_DBFS
            val mean = sum.toDouble() / n
            val variance = sumSq.toDouble() / n - mean * mean
            return QualityGate.rmsToDbfs(sqrt(max(0.0, variance)) / QualityGate.FULL_SCALE)
        }

        /** Peak absolute PCM16 value in dBFS (32768 is 0 dBFS). */
        fun peakDbfs(peakAbs: Int): Double = QualityGate.rmsToDbfs(peakAbs / QualityGate.FULL_SCALE)
    }
}
