package com.kernel.audio_ai

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import kotlin.math.abs
import kotlin.math.log10
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class LevelMeterTest {
    private fun collect(rate: Int, targetMs: Int = 2000, windowMs: Int = LevelMeter.WINDOW_MS): Pair<LevelMeter, MutableList<LevelReading>> {
        val out = mutableListOf<LevelReading>()
        return LevelMeter(rate, targetMs, windowMs) { out += it } to out
    }

    private fun assertNear(expected: Double, actual: Double, tol: Double, what: String) =
        assertTrue(abs(expected - actual) <= tol, "$what: expected $expected +- $tol, got $actual")

    @Test
    fun sineRmsAndPeakMatchTheirDbfsLevels() {
        val (meter, out) = collect(16_000)
        // -20 dBFS RMS sine: peak is sqrt(2) higher, i.e. about -16.99 dBFS.
        val pcm = Signals.sine(1000.0, 16_000, 2000, rmsDbfs = -20.0)
        meter.add(pcm, 0, pcm.size)
        assertEquals(40, out.size)
        for (r in out) {
            assertNear(-20.0, r.rmsDbfs, 0.05, "rms")
            assertNear(-20.0 + 20 * log10(Math.sqrt(2.0)), r.peakDbfs, 0.05, "peak")
        }
    }

    @Test
    fun emitsOneReadingPer50msWithElapsedAndTarget() {
        val (meter, out) = collect(16_000, targetMs = 2000)
        val pcm = Signals.sine(440.0, 16_000, 2000, rmsDbfs = -40.0)
        meter.add(pcm, 0, pcm.size)
        assertEquals((1..40).map { it * 50 }, out.map { it.elapsedMs })
        assertTrue(out.all { it.targetMs == 2000 })
        assertEquals(800, meter.windowSamples)
    }

    @Test
    fun readingsDoNotDependOnReadSize() {
        val pcm = Signals.noise(16_000, 1000, rmsDbfs = -35.0)
        val (whole, a) = collect(16_000)
        whole.add(pcm, 0, pcm.size)
        val (chunked, b) = collect(16_000)
        var i = 0
        val sizes = intArrayOf(1, 333, 800, 17, 1200)
        var k = 0
        while (i < pcm.size) {
            val n = minOf(sizes[k++ % sizes.size], pcm.size - i)
            chunked.add(pcm, i, n)
            i += n
        }
        assertEquals(a, b)
        assertEquals(20, a.size)
    }

    @Test
    fun windowFollowsTheDeliveredRate() {
        for ((rate, window) in listOf(48_000 to 2400, 44_100 to 2205)) {
            val (meter, out) = collect(rate)
            assertEquals(window, meter.windowSamples)
            val pcm = Signals.sine(1000.0, rate, 2000, rmsDbfs = -30.0)
            meter.add(pcm, 0, pcm.size)
            assertEquals(40, out.size, "rate $rate")
            assertEquals(2000, out.last().elapsedMs)
            assertNear(-30.0, out[10].rmsDbfs, 0.05, "rms at $rate")
        }
    }

    @Test
    fun digitalSilenceReadsTheFloor() {
        val (meter, out) = collect(16_000)
        meter.add(ShortArray(1600), 0, 1600)
        assertEquals(2, out.size)
        assertTrue(out.all { it.rmsDbfs == QualityGate.MIN_DBFS && it.peakDbfs == QualityGate.MIN_DBFS })
    }

    @Test
    fun dcOffsetReadsAsSilenceButShowsInThePeak() {
        val (meter, out) = collect(16_000)
        val dc = ShortArray(800) { 1000 }
        meter.add(dc, 0, dc.size)
        assertEquals(QualityGate.MIN_DBFS, out.single().rmsDbfs)
        assertNear(20 * log10(1000 / 32768.0), out.single().peakDbfs, 1e-9, "peak")
    }

    @Test
    fun fullScaleReadsZeroDbfs() {
        val (meter, out) = collect(16_000)
        // Full-scale square wave: RMS and peak both 0 dBFS (-32768 is exactly full scale).
        val square = ShortArray(800) { if ((it / 8) % 2 == 0) Short.MIN_VALUE else Short.MAX_VALUE }
        meter.add(square, 0, square.size)
        assertNear(0.0, out.single().rmsDbfs, 0.01, "rms")
        assertEquals(0.0, out.single().peakDbfs)
    }

    @Test
    fun loudBurstShowsOnlyInItsWindow() {
        val (meter, out) = collect(16_000)
        val quiet = Signals.sine(1000.0, 16_000, 50, rmsDbfs = -60.0)
        val loud = Signals.sine(1000.0, 16_000, 50, rmsDbfs = -10.0)
        meter.add(quiet, 0, quiet.size)
        meter.add(loud, 0, loud.size)
        meter.add(quiet, 0, quiet.size)
        assertEquals(3, out.size)
        assertNear(-60.0, out[0].rmsDbfs, 0.1, "before")
        assertNear(-10.0, out[1].rmsDbfs, 0.05, "burst")
        assertNear(-60.0, out[2].rmsDbfs, 0.1, "after")
    }

    @Test
    fun flushEmitsTheTrailingPartialWindowOnlyOnce() {
        val (meter, out) = collect(16_000)
        val pcm = Signals.sine(1000.0, 16_000, 70, rmsDbfs = -25.0) // 1120 samples
        meter.add(pcm, 0, pcm.size)
        assertEquals(1, out.size)
        meter.flush()
        assertEquals(2, out.size)
        assertEquals(70, out.last().elapsedMs)
        meter.flush()
        assertEquals(2, out.size, "nothing pending, nothing emitted")
    }

    @Test
    fun nothingIsEmittedWithoutAudio() {
        val (meter, out) = collect(16_000)
        meter.flush()
        meter.add(ShortArray(10), 0, 0)
        meter.flush()
        assertTrue(out.isEmpty())
    }

    @Test
    fun rejectsBadArguments() {
        assertThrows<IllegalArgumentException> { LevelMeter(0, 2000) {} }
        assertThrows<IllegalArgumentException> { LevelMeter(16_000, -1) {} }
        assertThrows<IllegalArgumentException> { LevelMeter(16_000, 2000, windowMs = 0) {} }
        val (meter, _) = collect(16_000)
        assertThrows<IllegalArgumentException> { meter.add(ShortArray(10), 5, 10) }
    }

    @Test
    fun staticHelpersMatchTheMeter() {
        assertEquals(QualityGate.MIN_DBFS, LevelMeter.rmsDbfs(0, 0, 0))
        assertEquals(0.0, LevelMeter.peakDbfs(32768))
        assertEquals(QualityGate.MIN_DBFS, LevelMeter.peakDbfs(0))
        assertNear(-6.0206, LevelMeter.peakDbfs(16384), 1e-3, "half scale")
    }
}
