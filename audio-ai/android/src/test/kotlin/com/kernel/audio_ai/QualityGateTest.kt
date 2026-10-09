package com.kernel.audio_ai

import org.junit.jupiter.api.Test
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.sin
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class QualityGateTest {
    private val gate = QualityGate()
    private val rate = 16_000

    @Test
    fun digitalSilenceIsSilence() {
        val result = gate.evaluate(ShortArray(Signals.samples(rate, 2000)), rate)
        assertEquals(listOf(GateReason.SILENCE), result.reasons)
        assertEquals(QualityGate.MIN_DBFS, result.metrics.rmsDbfs)
        assertEquals(2000, result.metrics.durationMs)
    }

    @Test
    fun veryQuietNoiseIsSilence() {
        val result = gate.evaluate(Signals.noise(rate, 2000, rmsDbfs = -85.0), rate)
        assertEquals(listOf(GateReason.SILENCE), result.reasons)
        assertTrue(abs(result.metrics.rmsDbfs - -85.0) < 1.0, "rms ${result.metrics.rmsDbfs}")
    }

    @Test
    fun dcOffsetAloneIsSilence() {
        val result = gate.evaluate(ShortArray(Signals.samples(rate, 2000)) { 1000 }, rate)
        assertEquals(listOf(GateReason.SILENCE), result.reasons)
    }

    @Test
    fun clippedSineIsClipping() {
        // Peak at twice full scale: about two thirds of the samples are pinned at full scale.
        val result = gate.evaluate(Signals.clippedSine(440.0, rate, 2000, amplitude = 2.0), rate)
        assertTrue(GateReason.CLIPPING in result.reasons, "reasons ${result.reasons}")
        assertFalse(GateReason.SILENCE in result.reasons)
        assertTrue(result.metrics.clipFraction > 0.5, "clip ${result.metrics.clipFraction}")
    }

    @Test
    fun loudButUnclippedSineDoesNotClip() {
        // Peak at -1 dBFS (0.89 FS) stays below the 99% clip level.
        val result = gate.evaluate(Signals.clippedSine(440.0, rate, 2000, amplitude = 0.89), rate)
        assertFalse(GateReason.CLIPPING in result.reasons)
        assertEquals(0.0, result.metrics.clipFraction)
    }

    @Test
    fun normalLevelSinePasses() {
        val result = gate.evaluate(Signals.sine(1000.0, rate, 2000, rmsDbfs = -50.0), rate)
        assertTrue(result.pass, "reasons ${result.reasons}")
        assertTrue(abs(result.metrics.rmsDbfs - -50.0) < 0.1, "rms ${result.metrics.rmsDbfs}")
        assertTrue(abs(result.metrics.noiseFloorDbfs - -50.0) < 0.5, "floor ${result.metrics.noiseFloorDbfs}")
    }

    @Test
    fun normalLevelSineAt48kHzPasses() {
        val result = gate.evaluate(Signals.sine(1000.0, 48_000, 2000, rmsDbfs = -50.0), 48_000)
        assertTrue(result.pass, "reasons ${result.reasons}")
        assertEquals(2000, result.metrics.durationMs)
    }

    @Test
    fun loudContinuousNoiseIsHighNoise() {
        val result = gate.evaluate(Signals.noise(rate, 2000, rmsDbfs = -30.0), rate)
        assertEquals(listOf(GateReason.HIGH_NOISE), result.reasons)
        assertTrue(result.metrics.noiseFloorDbfs > QualityGate.HIGH_NOISE_FLOOR_DBFS)
    }

    @Test
    fun moderateNoiseBelowFloorThresholdPasses() {
        val result = gate.evaluate(Signals.noise(rate, 2000, rmsDbfs = -55.0), rate)
        assertTrue(result.pass, "reasons ${result.reasons}")
    }

    @Test
    fun loudTransientsOverQuietFloorAreNotHighNoise() {
        // Quiet background (-75 dBFS) with twenty 5 ms, 2 kHz bursts peaking at
        // -20 dBFS: impulsive events like contact sounds, not a loud background.
        val pcm = Signals.noise(rate, 2000, rmsDbfs = -75.0)
        val burstLen = rate * 5 / 1000
        for (b in 0 until 20) {
            val start = b * (pcm.size / 20) + 100
            for (i in 0 until burstLen) {
                val x = pcm[start + i] / 32768.0 + 0.1 * sin(2.0 * PI * 2000.0 * i / rate)
                pcm[start + i] = Signals.toPcm(x)
            }
        }
        val result = gate.evaluate(pcm, rate)
        assertTrue(result.pass, "reasons ${result.reasons}")
        assertTrue(result.metrics.snrDb > 30.0, "snr ${result.metrics.snrDb}")
    }

    @Test
    fun shortBufferIsTooShortOnly() {
        val result = gate.evaluate(Signals.sine(1000.0, rate, 500, rmsDbfs = -50.0), rate)
        assertEquals(listOf(GateReason.TOO_SHORT), result.reasons)
        assertEquals(500, result.metrics.durationMs)
    }

    @Test
    fun durationBoundaryIsInclusiveAtMinimum() {
        val atMin = gate.evaluate(Signals.sine(1000.0, rate, QualityGate.MIN_DURATION_MS, -50.0), rate)
        assertTrue(atMin.pass, "reasons ${atMin.reasons}")
        val justUnder = Signals.sine(1000.0, rate, QualityGate.MIN_DURATION_MS, -50.0).copyOf(
            Signals.samples(rate, QualityGate.MIN_DURATION_MS) - 16,
        )
        assertEquals(listOf(GateReason.TOO_SHORT), gate.evaluate(justUnder, rate).reasons)
    }

    @Test
    fun emptyBufferIsTooShort() {
        assertEquals(listOf(GateReason.TOO_SHORT), gate.evaluate(ShortArray(0), rate).reasons)
    }
}
