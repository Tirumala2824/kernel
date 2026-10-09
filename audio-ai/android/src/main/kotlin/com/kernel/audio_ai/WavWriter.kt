package com.kernel.audio_ai

import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder

/** Writes mono 16-bit PCM as a canonical 44-byte-header WAV file. Pure JVM. */
object WavWriter {
    private const val HEADER_BYTES = 44

    /**
     * Writes atomically: the data goes to a temporary sibling first and is
     * renamed into place, so a crash never leaves a half-written recording.
     */
    @Throws(IOException::class)
    fun write(target: File, pcm: ShortArray, sampleRate: Int) {
        require(sampleRate > 0) { "sampleRate must be positive" }
        val dataBytes = pcm.size * 2
        val buffer = ByteBuffer.allocate(HEADER_BYTES + dataBytes).order(ByteOrder.LITTLE_ENDIAN)
        buffer.put("RIFF".toByteArray(Charsets.US_ASCII))
        buffer.putInt(36 + dataBytes)
        buffer.put("WAVE".toByteArray(Charsets.US_ASCII))
        buffer.put("fmt ".toByteArray(Charsets.US_ASCII))
        buffer.putInt(16) // PCM fmt chunk size
        buffer.putShort(1) // audio format: PCM
        buffer.putShort(1) // channels: mono
        buffer.putInt(sampleRate)
        buffer.putInt(sampleRate * 2) // byte rate
        buffer.putShort(2) // block align
        buffer.putShort(16) // bits per sample
        buffer.put("data".toByteArray(Charsets.US_ASCII))
        buffer.putInt(dataBytes)
        for (s in pcm) buffer.putShort(s)

        val tmp = File(target.parentFile, target.name + ".tmp")
        try {
            FileOutputStream(tmp).use { out ->
                out.write(buffer.array())
                out.fd.sync()
            }
            if (!tmp.renameTo(target)) throw IOException("rename failed for ${target.name}")
        } finally {
            buffer.array().fill(0)
            if (tmp.exists()) tmp.delete()
        }
    }
}
