package com.kernel.audio_ai

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.SystemClock
import kotlin.math.max
import kotlin.math.min

/** Raw PCM16 mono exactly as AudioRecord delivered it. */
class Recording(
    val pcm: ShortArray,
    /** Rate AudioRecord really delivered to this app (the "effective" rate). */
    val sampleRate: Int,
    /** UTC epoch ms at the first kept sample. */
    val startedAtEpochMs: Long,
    /** elapsedRealtimeNanos when the last sample was read. */
    val endedAtElapsedNanos: Long,
    /** Rate the audio HAL captured at (API 29+), null if unknown. */
    val deviceInputRate: Int?,
    /** True if Android silenced this client (another app holds the mic); data is then zeros. */
    val clientSilenced: Boolean,
) {
    val durationMs: Int get() = (pcm.size.toLong() * 1000L / sampleRate).toInt()

    /** Overwrites the samples once analysis is done. */
    fun discard() = pcm.fill(0)
}

class CaptureException(message: String) : Exception(message)

/**
 * Blocking microphone capture via AudioRecord. Call off the main thread.
 * Never logs or returns anything but the buffer to its caller.
 */
class AudioCapture(private val context: Context) {

    fun hasPermission(): Boolean =
        context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED

    /**
     * Records [durationMs] of kept audio after a short warm-up. Tries 16 kHz
     * first, then common native rates if the device refuses 16 kHz (the
     * caller resamples). Throws [CaptureException] if no configuration works
     * or no audio could be read, and SecurityException if permission is gone.
     *
     * [onLevel], if given, receives a [LevelReading] every
     * [LevelMeter.WINDOW_MS] of kept audio, on this (capture) thread, computed
     * in the read loop. Only scalar levels are passed out, never samples.
     * Nothing is emitted during the warm-up discard or outside this call.
     */
    @SuppressLint("MissingPermission") // Checked by the caller via hasPermission().
    fun record(durationMs: Int, onLevel: ((LevelReading) -> Unit)? = null): Recording {
        // Pinned to the built-in mic (see MicRouting): a headset, USB or
        // Bluetooth input would change the calibration reference.
        val mic = builtInMic() ?: throw CaptureException("built-in microphone not listed")
        for (rate in CANDIDATE_RATES) {
            val minBuffer = AudioRecord.getMinBufferSize(rate, CHANNEL, ENCODING)
            if (minBuffer <= 0) continue
            val bufferBytes = max(minBuffer, rate * 2 * BUFFER_MS / 1000)
            val record = try {
                AudioRecord(AUDIO_SOURCE, rate, CHANNEL, ENCODING, bufferBytes)
            } catch (e: IllegalArgumentException) {
                continue
            }
            if (record.state != AudioRecord.STATE_INITIALIZED) {
                record.release()
                continue
            }
            if (!record.setPreferredDevice(mic)) {
                record.release()
                throw CaptureException("built-in microphone could not be selected")
            }
            return recordWith(record, durationMs, onLevel)
        }
        throw CaptureException("no supported AudioRecord configuration")
    }

    /** The built-in mic chosen by [MicRouting.pickBuiltInMic], or null. */
    private fun builtInMic(): AudioDeviceInfo? {
        val audio = context.getSystemService(AudioManager::class.java) ?: return null
        val inputs = audio.getDevices(AudioManager.GET_DEVICES_INPUTS)
        val pick = MicRouting.pickBuiltInMic(inputs.map(MicRouting::from)) ?: return null
        return inputs.firstOrNull { it.id == pick.id }
    }

    /**
     * Device type Android actually routed this recording to: the active
     * recording configuration (API 29+), else the routed device; null when
     * neither is known yet.
     */
    private fun activeInputType(record: AudioRecord): Int? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            record.activeRecordingConfiguration?.audioDevice?.let { return it.type }
        }
        return record.routedDevice?.type
    }

    private fun recordWith(record: AudioRecord, durationMs: Int, onLevel: ((LevelReading) -> Unit)?): Recording {
        val rate = record.sampleRate
        val meter = onLevel?.let { LevelMeter(rate, durationMs, onLevel = it) }
        val warmupSamples = rate * WARMUP_DISCARD_MS / 1000
        val keepSamples = rate * durationMs / 1000
        val chunkSamples = rate * READ_CHUNK_MS / 1000
        val scratch = ShortArray(chunkSamples)
        val out = ShortArray(keepSamples)
        var filled = 0
        var readError = 0
        var startedAtEpochMs = System.currentTimeMillis()
        var endedAt = 0L
        var deviceRate: Int? = null
        var silenced = false
        try {
            record.startRecording()
            if (record.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                throw CaptureException("AudioRecord did not start (mic busy or unavailable)")
            }
            val deadline = SystemClock.elapsedRealtime() + WARMUP_DISCARD_MS + durationMs + READ_TIMEOUT_SLACK_MS

            var discarded = 0
            while (discarded < warmupSamples && SystemClock.elapsedRealtime() < deadline) {
                val n = record.read(scratch, 0, min(scratch.size, warmupSamples - discarded))
                if (n < 0) {
                    readError = n
                    break
                }
                discarded += n
            }

            // Checked once audio is flowing (after the warm-up), before any
            // sample is kept: the route must really be the built-in mic.
            if (readError == 0 && !MicRouting.isVerifiedBuiltIn(activeInputType(record))) {
                throw CaptureException("capture not routed to the built-in microphone")
            }

            startedAtEpochMs = System.currentTimeMillis()
            while (readError == 0 && filled < keepSamples && SystemClock.elapsedRealtime() < deadline) {
                val n = record.read(out, filled, min(chunkSamples, keepSamples - filled))
                if (n < 0) {
                    readError = n
                    break
                }
                meter?.add(out, filled, n)
                filled += n
            }
            endedAt = SystemClock.elapsedRealtimeNanos()
            meter?.flush()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val config = record.activeRecordingConfiguration
                deviceRate = config?.format?.sampleRate?.takeIf { it > 0 }
                silenced = config?.isClientSilenced ?: false
            }
        } finally {
            try {
                record.stop()
            } catch (_: IllegalStateException) {
                // Not started; nothing to stop.
            }
            record.release()
            scratch.fill(0)
        }

        if (filled == 0) {
            out.fill(0)
            throw CaptureException(
                if (readError != 0) "AudioRecord read error $readError" else "no audio read before timeout",
            )
        }
        val pcm = if (filled == keepSamples) out else out.copyOf(filled).also { out.fill(0) }
        return Recording(pcm, rate, startedAtEpochMs, endedAt, deviceRate, silenced)
    }

    companion object {
        /**
         * VOICE_RECOGNITION: the Android CDD requires AGC and noise
         * suppression to be off for this source, with a defined sensitivity.
         * The quality-gate levels are referenced to it. MIC usually has AGC and
         * noise suppression, which would erase faint insect sounds.
         * UNPROCESSED has about 18 dB less gain by spec, which pushes quiet
         * contact sounds towards 16-bit quantisation. Compare both on the
         * iQOO 15 before changing this (decisions-log open question).
         */
        const val AUDIO_SOURCE = MediaRecorder.AudioSource.VOICE_RECOGNITION

        /** Name of [AUDIO_SOURCE], reported in EngineInfo.audioSource and logcat. */
        const val AUDIO_SOURCE_NAME = "VOICE_RECOGNITION"

        /** 16 kHz first (pipeline rate); then common native rates to resample from. */
        val CANDIDATE_RATES = intArrayOf(16_000, 48_000, 44_100)

        const val CHANNEL = AudioFormat.CHANNEL_IN_MONO
        const val ENCODING = AudioFormat.ENCODING_PCM_16BIT

        /**
         * Audio read and dropped right after startRecording(). The first
         * ~100 ms of a capture often holds the converter/HAL start-up
         * transient and any residual vibration from the start haptic.
         */
        const val WARMUP_DISCARD_MS = 100

        /** AudioRecord internal buffer: at least 200 ms so reads never overrun. */
        const val BUFFER_MS = 200

        /**
         * Blocking read size. 50 ms matches [LevelMeter.WINDOW_MS], so each
         * read yields one live level reading (about 20 Hz) and the deadline is
         * checked regularly. The 200 ms internal buffer leaves 150 ms of slack
         * for scheduling jitter on the capture thread.
         */
        const val READ_CHUNK_MS = 50

        /** Give up if the device has not delivered the audio this long after it should have. */
        const val READ_TIMEOUT_SLACK_MS = 3_000
    }
}
