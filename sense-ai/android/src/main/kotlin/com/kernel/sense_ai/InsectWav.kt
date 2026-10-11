package com.kernel.sense_ai

import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.sqrt

internal class InsectInputException(val reason: String) : IllegalArgumentException(reason)
internal data class InsectAudio(
    val samples: FloatArray,
    val sampleRate: Int,
    private val sourceChannelPeak: Float = 0f,
) {
    val durationMs: Int get() = (samples.size.toLong() * 1000 / sampleRate).toInt()
    fun qualityReasons(): List<String> {
        if (samples.isEmpty()) return listOf("empty_audio")
        val rms = sqrt(samples.sumOf { (it * it).toDouble() } / samples.size)
        val peak = maxOf(sourceChannelPeak, samples.maxOf { abs(it) })
        return buildList {
            if (rms < 0.002) add("low_level_or_silence")
            if (peak > 0.999) add("possible_clipping")
        }
    }
}

/** Strict RIFF PCM16 reader. Unsupported formats are not silently reinterpreted. */
internal object InsectWav {
    const val MAX_BYTES = 6_000_000
    fun decode(bytes: ByteArray): InsectAudio {
        fun invalid(): Nothing = throw InsectInputException("invalid_wav")
        if (bytes.size < 12 || bytes.size > MAX_BYTES) invalid()
        fun tag(p: Int) = String(bytes, p, 4, Charsets.US_ASCII)
        val b = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        fun u32(p: Int) = b.getInt(p).toLong() and 0xffffffffL
        if (tag(0) != "RIFF" || tag(8) != "WAVE" || u32(4) + 8 != bytes.size.toLong()) invalid()
        var fmt = -1; var data = -1; var dataSize = -1; var pos = 12
        while (pos + 8 <= bytes.size) {
            val size = u32(pos + 4)
            val end = pos + 8L + size
            if (end > bytes.size) invalid()
            when (tag(pos)) {
                "fmt " -> { if (fmt >= 0 || size < 16) invalid(); fmt = pos + 8 }
                "data" -> { if (data >= 0) invalid(); data = pos + 8; dataSize = size.toInt() }
            }
            pos = (end + size % 2).toInt()
        }
        if (fmt < 0 || data < 0 || pos != bytes.size) invalid()
        val encoding = b.getShort(fmt).toInt() and 0xffff
        val channels = b.getShort(fmt + 2).toInt() and 0xffff
        val rate = b.getInt(fmt + 4)
        val align = b.getShort(fmt + 12).toInt() and 0xffff
        val bits = b.getShort(fmt + 14).toInt() and 0xffff
        if (encoding != 1 || bits != 16 || channels !in 1..2) throw InsectInputException("unsupported_wav_encoding")
        if (rate !in listOf(16000, 44100, 48000)) throw InsectInputException("unsupported_sample_rate")
        if (align != channels * 2 || b.getInt(fmt + 8) != rate * align || dataSize % align != 0) invalid()
        val count = dataSize / align
        if (count.toLong() > rate * 30L) throw InsectInputException("audio_too_long")
        // Keep the peak across source channels; averaging can hide clipping.
        var sourceChannelPeak = 0f
        val mono = FloatArray(count) { i ->
            var sum = 0f
            for (c in 0 until channels) {
                val value = b.getShort(data + i * align + c * 2) / 32768f
                sourceChannelPeak = maxOf(sourceChannelPeak, abs(value))
                sum += value
            }
            sum / channels
        }
        return InsectAudio(mono, rate, sourceChannelPeak)
    }
}
