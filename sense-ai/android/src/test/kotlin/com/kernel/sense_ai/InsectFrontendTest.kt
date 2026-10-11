package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs

class InsectFrontendTest {
    private fun floats(name: String): FloatArray {
        val bytes = javaClass.getResourceAsStream("/insect_parity/$name")!!.readBytes()
        val buffer = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        return FloatArray(bytes.size / 4) { buffer.float }
    }
    @Test fun commonRatesAndFiveCropsMatchUpstream() {
        for ((name, rate) in listOf("short16" to 16000, "long16" to 16000, "stereo44" to 44100, "mono48" to 48000)) {
            val wave = InsectFrontend.resample(floats("$name.mono.f32"), rate)
            val expectedWave = floats("$name.resampled.f32")
            assertEquals(expectedWave.size, wave.size)
            val waveError = wave.indices.maxOf { abs(wave[it] - expectedWave[it]) }
            assertTrue(waveError < 2e-6f, "$name resample error $waveError")
            val expected = floats("$name.features.f32")
            val offsets = InsectFrontend.cropOffsets(wave.size)
            assertEquals(expected.size, offsets.size * 64 * 201)
            val actual = offsets.flatMap { InsectFrontend.logmel(wave, it).asIterable() }
            val error = expected.indices.maxOf { abs(expected[it] - actual[it]) }
            val fromReferenceWave = offsets.flatMap { InsectFrontend.logmel(expectedWave, it).asIterable() }
            val referenceError = expected.indices.maxOf { abs(expected[it] - fromReferenceWave[it]) }
            assertTrue(error < 3e-5f, "$name feature error $error, reference-wave frontend $referenceError, resample $waveError")
        }
        assertArrayEquals(intArrayOf(0, 9001, 18002, 27002, 36003), InsectFrontend.cropOffsets(68003))
    }

    @Test fun silentCropsMatchEveryUpstreamFloat32NormalizedFeature() {
        for (name in listOf("silence16", "silent_first16")) {
            val wave = floats("$name.mono.f32")
            val expected = floats("$name.features.f32")
            val offsets = InsectFrontend.cropOffsets(wave.size)
            val actual = offsets.flatMap { InsectFrontend.logmel(wave, it).asIterable() }
            assertEquals(expected.size, actual.size)
            // This nonzero constant is genuine float32 upstream normalization,
            // not a desired zero-mean reinterpretation of its silent first crop.
            assertEquals(0.160182476f, expected[0])
            val maxError = expected.indices.maxOf { abs(expected[it] - actual[it]) }
            assertTrue(maxError < 3e-5f,
                "$name feature error $maxError; first expected ${expected[0]}, actual ${actual[0]}")
            println("$name maximum normalized-feature error: $maxError")
        }
    }

    @Test fun selectedWindowGatePreservesCropInputsAndUsesPreGainPaddedRms() {
        val wave = floats("silent_first16.mono.f32")
        val original = wave.copyOf()
        val offsets = InsectFrontend.cropOffsets(wave.size)
        assertTrue(InsectFrontend.hasSignalInSelectedCrops(wave, offsets))
        assertArrayEquals(intArrayOf(0, 8000, 16000, 24000, 32000), offsets)
        assertArrayEquals(original, wave)
        // Below/above the existing RMS floor; a peak-normalized test would
        // incorrectly pass the first waveform. Padding belongs to the crop.
        assertFalse(InsectFrontend.hasSignalInSelectedCrops(FloatArray(32000) { 65 / 32768f }, intArrayOf(0)))
        assertTrue(InsectFrontend.hasSignalInSelectedCrops(FloatArray(32000) { 66 / 32768f }, intArrayOf(0)))
        assertFalse(InsectFrontend.hasSignalInSelectedCrops(FloatArray(1600) { 0.005f }, intArrayOf(0)))
        assertTrue(InsectFrontend.hasSignalInSelectedCrops(FloatArray(1600) { 0.02f }, intArrayOf(0)))
    }

    @Test fun mono16MatchesEveryUpstreamFeature() {
        val wave = floats("mono16.mono.f32")
        val expected = floats("mono16.features.f32")
        val actual = InsectFrontend.logmel(wave)
        assertEquals(64 * 201, actual.size)
        val maxError = actual.indices.maxOf { abs(actual[it] - expected[it]) }
        assertTrue(maxError < 3e-5f, "max feature error $maxError")
    }
}
