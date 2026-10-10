package com.kernel.audio_ai

import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder

/** Result of decoding a WAV audio file into 16-bit mono PCM. */
data class DecodedWav(val pcm: ShortArray, val sampleRate: Int)

/**
 * On-device WAV reader for analyzing audio files from file uploads or sensor dumps.
 * Handles canonical 44-byte RIFF/WAVE files, chunked metadata, mono and stereo 16-bit/8-bit PCM.
 * Pure JVM; no Android HAL or external dependency.
 */
object WavReader {
    @Throws(IOException::class)
    fun read(file: File): DecodedWav {
        if (!file.exists() || !file.canRead()) {
            throw IOException("File does not exist or is not readable: ${file.path}")
        }
        FileInputStream(file).use { input ->
            val header = ByteArray(12)
            if (input.read(header) < 12) throw IOException("WAV header truncated")
            val riff = String(header, 0, 4, Charsets.US_ASCII)
            val wave = String(header, 8, 4, Charsets.US_ASCII)
            if (riff != "RIFF" || wave != "WAVE") throw IOException("Not a valid RIFF/WAVE file")

            var sampleRate = 16000
            var channels = 1
            var bitsPerSample = 16
            var pcmData: ShortArray? = null

            val chunkHeader = ByteArray(8)
            while (input.read(chunkHeader) == 8) {
                val chunkId = String(chunkHeader, 0, 4, Charsets.US_ASCII)
                val chunkSize = ByteBuffer.wrap(chunkHeader, 4, 4).order(ByteOrder.LITTLE_ENDIAN).int
                if (chunkSize < 0) break

                if (chunkId == "fmt ") {
                    val fmtBytes = ByteArray(chunkSize)
                    if (input.read(fmtBytes) < chunkSize) throw IOException("fmt chunk truncated")
                    val fmtBuf = ByteBuffer.wrap(fmtBytes).order(ByteOrder.LITTLE_ENDIAN)
                    fmtBuf.short // audioFormat (1=PCM)
                    channels = fmtBuf.short.toInt()
                    sampleRate = fmtBuf.int
                    fmtBuf.int // byte rate
                    fmtBuf.short // block align
                    bitsPerSample = fmtBuf.short.toInt()
                } else if (chunkId == "data") {
                    val dataBytes = ByteArray(chunkSize)
                    var readTotal = 0
                    while (readTotal < chunkSize) {
                        val r = input.read(dataBytes, readTotal, chunkSize - readTotal)
                        if (r <= 0) break
                        readTotal += r
                    }
                    val dataBuf = ByteBuffer.wrap(dataBytes, 0, readTotal).order(ByteOrder.LITTLE_ENDIAN)
                    if (bitsPerSample == 16) {
                        val numSamples = readTotal / 2
                        if (channels <= 1) {
                            val pcm = ShortArray(numSamples)
                            for (i in 0 until numSamples) {
                                pcm[i] = dataBuf.short
                            }
                            pcmData = pcm
                        } else {
                            // Downmix multi-channel to mono
                            val numFrames = numSamples / channels
                            val pcm = ShortArray(numFrames)
                            for (i in 0 until numFrames) {
                                var sum = 0
                                for (c in 0 until channels) {
                                    sum += dataBuf.short.toInt()
                                }
                                pcm[i] = (sum / channels).toShort()
                            }
                            pcmData = pcm
                        }
                    } else if (bitsPerSample == 8) {
                        val numSamples = readTotal
                        if (channels <= 1) {
                            val pcm = ShortArray(numSamples)
                            for (i in 0 until numSamples) {
                                val u8 = dataBytes[i].toInt() and 0xFF
                                pcm[i] = ((u8 - 128) shl 8).toShort()
                            }
                            pcmData = pcm
                        } else {
                            val numFrames = numSamples / channels
                            val pcm = ShortArray(numFrames)
                            for (i in 0 until numFrames) {
                                var sum = 0
                                for (c in 0 until channels) {
                                    val u8 = dataBytes[i * channels + c].toInt() and 0xFF
                                    sum += ((u8 - 128) shl 8)
                                }
                                pcm[i] = (sum / channels).toShort()
                            }
                            pcmData = pcm
                        }
                    }
                    break
                } else {
                    var remaining = chunkSize.toLong()
                    while (remaining > 0) {
                        val skipped = input.skip(remaining)
                        if (skipped <= 0) break
                        remaining -= skipped
                    }
                }
            }

            val pcm = pcmData ?: throw IOException("No data chunk found in WAV")
            return DecodedWav(pcm, sampleRate)
        }
    }
}
