package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.nio.ByteBuffer
import java.nio.ByteOrder

/** Encoded PCM16 stereo input for JVM regressions only; never shipped as app data. */
internal fun stereoPcm16Wav(left: ShortArray, right: ShortArray, rate: Int): ByteArray {
    require(left.size == right.size)
    val dataBytes = left.size * 4
    return ByteBuffer.allocate(44 + dataBytes).order(ByteOrder.LITTLE_ENDIAN).apply {
        put("RIFF".toByteArray(Charsets.US_ASCII)); putInt(36 + dataBytes)
        put("WAVE".toByteArray(Charsets.US_ASCII))
        put("fmt ".toByteArray(Charsets.US_ASCII)); putInt(16)
        putShort(1); putShort(2)
        putInt(rate); putInt(rate * 4); putShort(4); putShort(16)
        put("data".toByteArray(Charsets.US_ASCII)); putInt(dataBytes)
        for (i in left.indices) { putShort(left[i]); putShort(right[i]) }
    }.array()
}

class InsectWavTest {
    @Test fun pcmScalingAndMonoMixMatchUpstreamBeforeQualityGate() {
        for ((name, rate) in listOf("mono16" to 16000, "short16" to 16000, "long16" to 16000, "stereo44" to 44100, "mono48" to 48000)) {
            val bytes = javaClass.getResourceAsStream("/insect_parity/$name.wav")!!.readBytes()
            val expected = ByteBuffer.wrap(javaClass.getResourceAsStream("/insect_parity/$name.mono.f32")!!.readBytes()).order(ByteOrder.LITTLE_ENDIAN)
            val audio = InsectWav.decode(bytes)
            assertEquals(rate, audio.sampleRate)
            assertEquals(expected.capacity()/4, audio.samples.size)
            for (value in audio.samples) assertEquals(expected.float, value)
            assertTrue(audio.qualityReasons().isEmpty())
            assertEquals(audio.samples.size * 1000L / rate, audio.durationMs.toLong())
        }
        assertEquals(listOf("empty_audio"), InsectWav.decode(WavWriter.encode(shortArrayOf(),16000)).qualityReasons())
        assertEquals(listOf("low_level_or_silence"), InsectWav.decode(WavWriter.encode(ShortArray(1600),16000)).qualityReasons())
        assertEquals(listOf("possible_clipping"), InsectWav.decode(WavWriter.encode(ShortArray(1600) { 32767 },16000)).qualityReasons())
    }
    @Test fun clippingFromEitherSourceChannelSurvivesMonoAttenuation() {
        for (rate in listOf(16000, 44100, 48000)) {
            for (clippedChannel in 0..1) {
                val left = ShortArray(1600) { if (it % 2 == 0) 32767 else -32767 }
                val right = ShortArray(left.size)
                val bytes = if (clippedChannel == 0) stereoPcm16Wav(left, right, rate)
                    else stereoPcm16Wav(right, left, rate)
                val audio = InsectWav.decode(bytes)
                assertEquals(rate, audio.sampleRate)
                assertArrayEquals(FloatArray(left.size) { left[it] / 32768f / 2 }, audio.samples)
                assertEquals(listOf("possible_clipping"), audio.qualityReasons(),
                    "Clipping in source channel $clippedChannel at $rate Hz must survive downmixing")
            }
        }
    }

    @Test fun malformedAndUnsupportedWavAreRejectedInsteadOfInventingAudio() {
        fun reason(bytes: ByteArray) = assertThrows(InsectInputException::class.java) { InsectWav.decode(bytes) }.reason
        assertEquals("invalid_wav", reason(byteArrayOf(1,2,3)))
        val valid = WavWriter.encode(ShortArray(1600),16000)
        assertEquals("invalid_wav", reason(valid.copyOf(valid.size-2)))
        val unsupported = valid.copyOf().also { ByteBuffer.wrap(it).order(ByteOrder.LITTLE_ENDIAN).putInt(24, 8000) }
        assertEquals("unsupported_sample_rate", reason(unsupported))
        val encoding = valid.copyOf().also { it[20] = 3 }
        assertEquals("unsupported_wav_encoding", reason(encoding))
    }
}
