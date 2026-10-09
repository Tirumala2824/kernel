package com.kernel.audio_ai

import org.junit.jupiter.api.Test
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.ln
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class LogMelTest {
    private val config = LogMelConfig.PROVISIONAL
    private val logMel = LogMel(config)
    private val numBins = config.nFft / 2 + 1

    @Test
    fun provisionalConfigValues() {
        // Guard against silent edits: these must change together with the model manifest.
        assertEquals(16_000, config.sampleRate)
        assertEquals(512, config.nFft)
        assertEquals(400, config.winLength)
        assertEquals(160, config.hopLength)
        assertEquals(64, config.nMels)
        assertEquals(125.0, config.fMin)
        assertEquals(7_500.0, config.fMax)
        assertEquals(0.001, config.logOffset)
        assertEquals(1.0, config.power)
    }

    @Test
    fun outputShapeForTwoSeconds() {
        val result = logMel.compute(FloatArray(32_000))
        // 1 + (32000 - 400) / 160 = 198 frames, no centre padding.
        assertEquals(198, result.frames)
        assertEquals(64, result.nMels)
        assertEquals(198 * 64, result.values.size)
    }

    @Test
    fun frameCountEdges() {
        assertEquals(0, logMel.frameCount(399))
        assertEquals(1, logMel.frameCount(400))
        assertEquals(1, logMel.frameCount(559))
        assertEquals(2, logMel.frameCount(560))
    }

    @Test
    fun silenceIsLogOffsetEverywhere() {
        val result = logMel.compute(FloatArray(16_000))
        val expected = ln(config.logOffset).toFloat()
        assertTrue(result.values.all { it == expected })
    }

    @Test
    fun fftMatchesNaiveDftReference() {
        // Multi-tone frame, off-bin frequencies, so leakage is exercised too.
        val samples = FloatArray(config.winLength) { n ->
            (0.3 * sin(2 * PI * 437.0 * n / 16_000) + 0.2 * cos(2 * PI * 2_911.3 * n / 16_000) +
                0.05 * sin(2 * PI * 6_120.0 * n / 16_000)).toFloat()
        }
        val fast = DoubleArray(numBins)
        logMel.magnitudeSpectrum(samples, 0, fast)
        val reference = naiveMagnitude(samples, 0)
        for (k in 0 until numBins) {
            assertTrue(abs(fast[k] - reference[k]) < 1e-9 * (1.0 + reference[k]), "bin $k: ${fast[k]} vs ${reference[k]}")
        }
    }

    @Test
    fun onBinSineHasAnalyticMagnitude() {
        // 1000 Hz = bin 32 exactly (16000 / 512 * 32). For a periodic Hann
        // window of length 400, sum(w) = 200, so |X[32]| = A * 200 / 2.
        val amplitude = 0.5
        val samples = Signals.floatSine(1000.0, 16_000, config.winLength, amplitude)
        val spectrum = DoubleArray(numBins)
        logMel.magnitudeSpectrum(samples, 0, spectrum)
        val expected = amplitude * 200.0 / 2.0
        assertTrue(abs(spectrum[32] - expected) / expected < 0.01, "|X[32]| = ${spectrum[32]}, expected $expected")
        val peak = spectrum.indices.maxByOrNull { spectrum[it] }
        assertEquals(32, peak)
    }

    @Test
    fun sinePeaksInTheBandCentredNearItsFrequency() {
        val samples = Signals.floatSine(1000.0, 16_000, 32_000, 0.5)
        val result = logMel.compute(samples)
        val centres = LogMel.bandCentersHz(config)
        val expectedBand = centres.indices.minByOrNull { abs(LogMel.hzToMel(centres[it]) - LogMel.hzToMel(1000.0)) }!!
        val frame = result.frames / 2
        val peakBand = (0 until result.nMels).maxByOrNull { result[frame, it] }
        assertEquals(expectedBand, peakBand)

        // Far bands hold only window leakage, many nats below the peak.
        val farBand = centres.indices.minByOrNull { abs(centres[it] - 5_000.0) }!!
        assertTrue(result[frame, peakBand!!] - result[frame, farBand] > 5f)
    }

    @Test
    fun logMelValueMatchesReferenceComputation() {
        val samples = Signals.floatSine(1000.0, 16_000, 32_000, 0.5)
        val result = logMel.compute(samples)
        val frame = 50
        val reference = naiveMagnitude(samples, frame * config.hopLength)
        for (m in 0 until config.nMels) {
            var acc = 0.0
            for (k in 0 until numBins) acc += logMel.melWeights[m][k] * reference[k]
            val expected = ln(acc + config.logOffset)
            assertTrue(abs(result[frame, m] - expected) < 1e-4, "band $m: ${result[frame, m]} vs $expected")
        }
    }

    @Test
    fun doublingAmplitudeAddsLnTwoAtThePeak() {
        val quiet = logMel.compute(Signals.floatSine(1000.0, 16_000, 16_000, 0.1))
        val loud = logMel.compute(Signals.floatSine(1000.0, 16_000, 16_000, 0.2))
        val frame = 20
        val band = (0 until quiet.nMels).maxByOrNull { quiet[frame, it] }!!
        assertTrue(abs((loud[frame, band] - quiet[frame, band]) - ln(2.0)) < 0.01)
    }

    @Test
    fun melFilterbankIsWellFormed() {
        val weights = logMel.melWeights
        assertEquals(config.nMels, weights.size)
        for ((m, row) in weights.withIndex()) {
            assertEquals(numBins, row.size)
            assertEquals(0.0, row[0], "DC bin must be zero in band $m")
            assertTrue(row.all { it in 0.0..1.0 }, "band $m weights out of [0, 1]")
            assertTrue(row.any { it > 0.0 }, "band $m has no bins")
        }
        // Nothing below fMin or above fMax contributes.
        val binHz = config.sampleRate.toDouble() / config.nFft
        for (k in 0 until numBins) {
            val hz = k * binHz
            if (hz <= config.fMin || hz >= config.fMax) {
                assertTrue(weights.all { it[k] == 0.0 }, "bin $k ($hz Hz) outside [fMin, fMax] has weight")
            }
        }
    }

    /** O(N^2) DFT magnitude of one Hann-windowed, zero-padded frame. Independent of Fft. */
    private fun naiveMagnitude(samples: FloatArray, offset: Int): DoubleArray {
        val n = config.nFft
        val window = DoubleArray(config.winLength) { 0.5 - 0.5 * cos(2 * PI * it / config.winLength) }
        return DoubleArray(numBins) { k ->
            var re = 0.0
            var im = 0.0
            for (t in 0 until config.winLength) {
                val x = samples[offset + t] * window[t]
                re += x * cos(2 * PI * k * t / n)
                im -= x * sin(2 * PI * k * t / n)
            }
            sqrt(re * re + im * im)
        }
    }
}
