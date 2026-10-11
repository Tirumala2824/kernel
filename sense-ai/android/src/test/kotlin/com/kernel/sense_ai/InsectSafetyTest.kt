package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.io.IOException

class InsectSafetyTest {
    @TempDir lateinit var dir: File
    private fun input(pcm: ShortArray): File = File(dir, "input.wav").apply { writeBytes(WavWriter.encode(pcm,16000)) }
    private fun assertEmpty(result: Map<String,Any?>, status: String, reason: String) {
        assertEquals(status, result["status"])
        assertEquals("unknown", result["level"])
        assertNull(result["label"])
        assertEquals(emptyList<Any>(), result["topLabels"])
        assertEquals(listOf(reason), result["reasons"])
        assertEquals("none", result["modelVersion"])
        assertEquals(true, result["experimental"])
    }
    @Test fun qualityFailureNeverLoadsModelAndHasNoLabels() {
        val adapter = InsectSoundAdapter { throw AssertionError("Model must not load on failed quality") }
        for ((pcm,reason) in listOf(shortArrayOf() to "empty_audio", ShortArray(1600) to "low_level_or_silence", ShortArray(1600) { 32767 } to "possible_clipping")) {
            val result = adapter.classifyWavFile(input(pcm).path)
            assertEmpty(result,"rejected",reason)
            assertEquals(16000,result["sampleRate"])
            assertEquals(pcm.size * 1000 / 16000,result["durationMs"])
        }
    }
    @Test fun clippedStereoSourceRejectsBeforeAnyAssetReadAndHasNoLabels() {
        val clipped = ShortArray(1600) { if (it % 2 == 0) 32767 else -32767 }
        val wav = File(dir, "clipped_stereo.wav").apply {
            writeBytes(stereoPcm16Wav(clipped, ShortArray(clipped.size), 16000))
        }
        // Averaging with the silent channel hides the source peak, leaving
        // otherwise usable mono audio. Exercise the actual encoded WAV path.
        val audio = InsectWav.decode(wav.readBytes())
        assertTrue(InsectAudio(audio.samples, audio.sampleRate).qualityReasons().isEmpty())
        var assetReads = 0
        val adapter = InsectSoundAdapter {
            assetReads++
            throw IOException("Clipped source channels must not reach the asset boundary")
        }
        val result = adapter.classifyWavFile(wav.path)
        assertEquals(0, assetReads, "Source-channel clipping must reject before any asset read")
        assertEmpty(result, "rejected", "possible_clipping")
        assertEquals(16000, result["sampleRate"])
        assertEquals(100, result["durationMs"])
        assertEquals(InsectSoundAdapter.REVISION, result["modelRevision"])
    }

    @Test fun signalOutsideEverySelectedWindowRejectsBeforeAnyAssetRead() {
        // Whole-file RMS passes, but the trained 0/7/14/21/28-second windows
        // miss this one-second burst completely. Do not invent a classification.
        val pcm = ShortArray(30 * 16000) { i ->
            if (i in 3 * 16000 until 4 * 16000) {
                if (i % 2 == 0) 4096 else -4096
            } else 0
        }
        val wav = input(pcm)
        val audio = InsectWav.decode(wav.readBytes())
        assertTrue(audio.qualityReasons().isEmpty())
        val wave = InsectFrontend.resample(audio.samples, audio.sampleRate)
        val offsets = InsectFrontend.cropOffsets(wave.size)
        assertArrayEquals(intArrayOf(0, 112000, 224000, 336000, 448000), offsets)
        assertTrue(offsets.all { start -> (start until start + 32000).all { wave[it] == 0f } })
        var assetReads = 0
        val adapter = InsectSoundAdapter {
            assetReads++
            throw IOException("Assets must not be read for unusable selected windows")
        }
        val result = adapter.classifyWavFile(wav.path)
        assertEquals(0, assetReads, "No asset may be read before the selected-window quality gate")
        assertEmpty(result, "rejected", "no_signal_in_selected_windows")
        assertEquals(16000, result["sampleRate"])
        assertEquals(30000, result["durationMs"])
        assertEquals(InsectSoundAdapter.REVISION, result["modelRevision"])
    }

    @Test fun resamplingCannotTurnOutOfBandEnergyIntoUsableInferenceAudio() {
        val pcm = ShortArray(2 * 48000) { if (it % 2 == 0) 4096 else -4096 }
        val wav = File(dir, "out_of_band.wav").apply { writeBytes(WavWriter.encode(pcm, 48000)) }
        val audio = InsectWav.decode(wav.readBytes())
        assertTrue(audio.qualityReasons().isEmpty())
        val wave = InsectFrontend.resample(audio.samples, audio.sampleRate)
        assertTrue(InsectAudio(wave, 16000).qualityReasons().contains("low_level_or_silence"))
        val adapter = InsectSoundAdapter { throw AssertionError("Resampled low-level crops must not load assets") }
        val result = adapter.classifyWavFile(wav.path)
        assertEmpty(result, "rejected", "no_signal_in_selected_windows")
        assertEquals(48000, result["sampleRate"])
        assertEquals(2000, result["durationMs"])
    }

    @Test fun nonzeroButUnusableSelectedWindowsAlsoRejectBeforeAssetRead() {
        val pcm = ShortArray(30 * 16000) { i ->
            val magnitude = if (i in 3 * 16000 until 4 * 16000) 4096 else 1
            (if (i % 2 == 0) magnitude else -magnitude).toShort()
        }
        val wav = input(pcm)
        assertTrue(InsectWav.decode(wav.readBytes()).qualityReasons().isEmpty())
        val adapter = InsectSoundAdapter { throw AssertionError("Tiny nonzero crops must not load assets") }
        assertEmpty(adapter.classifyWavFile(wav.path), "rejected", "no_signal_in_selected_windows")
    }

    @Test fun anyUsableSelectedWindowStillReachesTheExistingAssetPath() {
        for (second in listOf(0, 7, 14, 21, 28)) {
            val pcm = ShortArray(30 * 16000) { i ->
                if (i in second * 16000 until (second + 1) * 16000) {
                    if (i % 2 == 0) 4096 else -4096
                } else 0
            }
            var assetReads = 0
            val adapter = InsectSoundAdapter {
                assetReads++
                throw IOException("Stop at the existing asset boundary; no JVM interpreter substitute")
            }
            val result = adapter.classifyWavFile(input(pcm).path)
            assertEquals(1, assetReads, "A usable crop at $second seconds must pass the new gate")
            assertEmpty(result, "unavailable", "model_unavailable")
        }
        // The upstream normalization regression includes a silent first crop
        // but must still pass quality as a whole, preserving all five crops.
        val wav = File(dir, "silent_first16.wav").apply {
            writeBytes(this@InsectSafetyTest.javaClass.getResourceAsStream("/insect_parity/silent_first16.wav")!!.use { it.readBytes() })
        }
        var assetReads = 0
        val adapter = InsectSoundAdapter { assetReads++; throw IOException("Stop at asset boundary") }
        assertEmpty(adapter.classifyWavFile(wav.path), "unavailable", "model_unavailable")
        assertEquals(1, assetReads)
    }

    @Test fun missingInvalidAndOversizedFilesCannotProduceResults() {
        val adapter = InsectSoundAdapter { throw AssertionError("No model for invalid input") }
        assertEmpty(adapter.classifyWavFile(File(dir,"missing.wav").path),"unavailable","file_unreadable")
        val invalid = File(dir,"invalid.wav").apply { writeBytes(byteArrayOf(1,2,3)) }
        assertEmpty(adapter.classifyWavFile(invalid.path),"rejected","invalid_wav")
        val large = File(dir,"large.wav").apply { java.io.RandomAccessFile(this,"rw").use { it.setLength(InsectWav.MAX_BYTES+1L) } }
        assertEmpty(adapter.classifyWavFile(large.path),"rejected","audio_too_large")
    }
    @Test fun memoryPressureIsUnavailableNotAClassificationOrCrash() {
        val wav = input(ShortArray(1600) { if (it % 2 == 0) 5000 else -5000 })
        val result = try {
            InsectSoundAdapter { throw OutOfMemoryError("test only") }.classifyWavFile(wav.path)
        } catch (_: OutOfMemoryError) {
            fail<Map<String,Any?>>("Memory failure escaped the adapter")
        }
        assertEmpty(result,"unavailable","memory_unavailable")
    }

    @Test fun absentTamperedAndUnusableRuntimeReturnUnavailable() {
        val wav = input(ShortArray(1600) { if (it % 2 == 0) 5000 else -5000 })
        assertEmpty(InsectSoundAdapter { throw IOException("missing") }.classifyWavFile(wav.path),"unavailable","model_unavailable")
        assertEmpty(InsectSoundAdapter { byteArrayOf(1,2,3) }.classifyWavFile(wav.path),"unavailable","asset_integrity")
        assertEmpty(InsectSoundAdapter { throw UnsatisfiedLinkError("unusable") }.classifyWavFile(wav.path),"unavailable","runtime_unavailable")
    }
}
