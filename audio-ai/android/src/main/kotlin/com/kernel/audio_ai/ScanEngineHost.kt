package com.kernel.audio_ai

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Process
import android.os.SystemClock
import android.util.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.withContext
import java.io.IOException
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Pigeon host: permission check -> start cue -> capture (own thread) ->
 * quality gate -> log-mel -> model (only if a real one is bundled) ->
 * finish/retry cue -> result. Audio and model problems become RETRY or
 * NOT_EVALUATED results and are never thrown to Dart.
 *
 * Privacy: audio is never logged or sent anywhere. Buffers are zeroed after
 * analysis. The only persistence is the retain-audio opt-in, which writes to
 * app-private storage.
 */
class ScanEngineHost(context: Context) : ScanHostApi {
    private val appContext = context.applicationContext
    private val capture = AudioCapture(appContext)
    private val haptics = Haptics(appContext)
    private val model = ModelRunner(appContext)
    private val analyzer = ScanAnalyzer()
    private val store = RecordingStore(appContext.filesDir)
    private val debuggable = (appContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    private val executor = Executors.newSingleThreadExecutor { runnable ->
        Thread({
            Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)
            runnable.run()
        }, "audio-ai-capture")
    }
    private val captureDispatcher = executor.asCoroutineDispatcher()
    private val busy = AtomicBoolean(false)

    @Volatile
    private var lastEffectiveRate: Int? = null

    @Volatile
    private var loggedCaptureConfig: String? = null

    init {
        // Load (or confirm the absence of) the model off the main thread, so
        // the first scan's latency does not include model loading. Nothing
        // thrown here may reach the thread's uncaught handler (app crash).
        executor.execute {
            try {
                model.status()
            } catch (t: Throwable) {
                Log.e(TAG, "model preload failed: ${t.javaClass.simpleName}")
            }
        }
    }

    override suspend fun captureAndAnalyze(scanId: String, retainAudio: Boolean): NativeScanResult {
        val calledAt = System.currentTimeMillis()
        if (!capture.hasPermission()) return notRecorded(NativeQualityReason.PERMISSION_DENIED, calledAt)
        if (!busy.compareAndSet(false, true)) {
            Log.w(TAG, "scan requested while another scan is running")
            return notRecorded(NativeQualityReason.CAPTURE_ERROR, calledAt)
        }
        return try {
            withContext(captureDispatcher) { scan(scanId, retainAudio, calledAt) }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Throwable) {
            Log.e(TAG, "scan $scanId failed: ${e.javaClass.simpleName}")
            notRecorded(NativeQualityReason.CAPTURE_ERROR, calledAt)
        } finally {
            busy.set(false)
        }
    }

    override suspend fun info(): NativeEngineInfo = withContext(Dispatchers.IO) {
        val handle = model.handle()
        val present = handle.version != NO_MODEL_VERSION
        NativeEngineInfo(
            modelPresent = present,
            modelVersion = handle.version,
            experimental = handle.experimental,
            targetSampleRate = ModelManifest.PIPELINE_SAMPLE_RATE.toLong(),
            effectiveSampleRate = lastEffectiveRate?.toLong(),
            delegate = if (present) NativeDelegate.CPU else NativeDelegate.NONE,
            deviceModel = DEVICE_MODEL,
            osVersion = OS_VERSION,
        )
    }

    override suspend fun deleteRetainedAudio(): Long = withContext(Dispatchers.IO) {
        store.deleteAll().toLong()
    }

    fun close() {
        executor.execute {
            try {
                model.close()
            } catch (t: Throwable) {
                Log.w(TAG, "model close failed: ${t.javaClass.simpleName}")
            }
        }
        executor.shutdown()
    }

    /** Runs on the capture thread. */
    private fun scan(scanId: String, retainAudio: Boolean, calledAt: Long): NativeScanResult {
        if (haptics.start()) Thread.sleep(Haptics.START_SETTLE_MS)

        val recording = try {
            capture.record(TARGET_DURATION_MS)
        } catch (e: SecurityException) {
            return notRecorded(NativeQualityReason.PERMISSION_DENIED, calledAt)
        } catch (e: CaptureException) {
            Log.w(TAG, "capture failed: ${e.message}")
            haptics.retry()
            return notRecorded(NativeQualityReason.CAPTURE_ERROR, calledAt)
        } catch (e: RuntimeException) {
            // AudioRecord state errors (IllegalStateException etc.).
            Log.w(TAG, "capture failed: ${e.javaClass.simpleName}")
            haptics.retry()
            return notRecorded(NativeQualityReason.CAPTURE_ERROR, calledAt)
        }

        try {
            lastEffectiveRate = recording.sampleRate
            logCaptureConfigOnce(recording)
            val handle = model.handle()

            val reasons: List<NativeQualityReason>
            val prediction: Prediction?
            if (recording.clientSilenced) {
                // Android handed the mic to another app and fed us zeros. That
                // is not "silence" in the room.
                Log.w(TAG, "capture was silenced by the system (mic in use elsewhere)")
                reasons = listOf(NativeQualityReason.CAPTURE_ERROR)
                prediction = null
            } else {
                val analysis = analyzer.analyze(recording.pcm, recording.sampleRate, handle)
                reasons = analysis.reasons.map(::toNative)
                prediction = analysis.prediction
                if (debuggable) logMetrics(scanId, analysis)
            }

            val pass = reasons.isEmpty()
            if (pass) haptics.finish() else haptics.retry()
            if (retainAudio) retain(scanId, recording)

            val classified = if (pass) prediction else null
            return NativeScanResult(
                qualityPass = pass,
                qualityReasons = reasons,
                classification = classified?.let { toNative(it.label) } ?: NativeClassification.NOT_EVALUATED,
                confidence = classified?.confidence,
                experimental = handle.experimental,
                modelVersion = handle.version,
                capturedAtEpochMs = recording.startedAtEpochMs,
                latencyMs = (SystemClock.elapsedRealtimeNanos() - recording.endedAtElapsedNanos) / 1_000_000L,
                durationMs = recording.durationMs.toLong(),
                sampleRate = recording.sampleRate.toLong(),
                deviceModel = DEVICE_MODEL,
                osVersion = OS_VERSION,
            )
        } finally {
            recording.discard()
        }
    }

    private fun retain(scanId: String, recording: Recording) {
        try {
            if (store.save(scanId, recording.pcm, recording.sampleRate) == null) {
                Log.w(TAG, "retain-audio skipped for scan $scanId (invalid id or storage unavailable)")
            }
        } catch (e: IOException) {
            Log.w(TAG, "retain-audio failed for scan $scanId: ${e.javaClass.simpleName}")
        }
    }

    /** Technical capture configuration only (no audio), logged when it changes. */
    private fun logCaptureConfigOnce(recording: Recording) {
        val config = "source=VOICE_RECOGNITION clientRate=${recording.sampleRate} " +
            "deviceRate=${recording.deviceInputRate ?: "unknown"} " +
            "resampled=${recording.sampleRate != ModelManifest.PIPELINE_SAMPLE_RATE}"
        if (config != loggedCaptureConfig) {
            loggedCaptureConfig = config
            Log.i(TAG, "capture config: $config")
        }
    }

    /** Debuggable builds only: aggregate gate levels for threshold calibration. Never samples. */
    private fun logMetrics(scanId: String, analysis: Analysis) {
        val m = analysis.metrics
        Log.d(
            TAG,
            "gate scan=$scanId durMs=${m.durationMs} rms=%.1f floor=%.1f peak=%.1f snr=%.1f clip=%.5f reasons=%s frames=%d"
                .format(m.rmsDbfs, m.noiseFloorDbfs, m.peakFrameDbfs, m.snrDb, m.clipFraction, analysis.reasons, analysis.logMelFrames),
        )
    }

    private fun notRecorded(reason: NativeQualityReason, calledAt: Long): NativeScanResult {
        val handle = try {
            model.handle()
        } catch (e: RuntimeException) {
            NoModel
        }
        return NativeScanResult(
            qualityPass = false,
            qualityReasons = listOf(reason),
            classification = NativeClassification.NOT_EVALUATED,
            confidence = null,
            experimental = handle.experimental,
            modelVersion = handle.version,
            capturedAtEpochMs = calledAt,
            latencyMs = 0L,
            durationMs = 0L,
            sampleRate = 0L,
            deviceModel = DEVICE_MODEL,
            osVersion = OS_VERSION,
        )
    }

    companion object {
        private const val TAG = "AudioAi"

        /** Contract: ~2 s per scan. */
        const val TARGET_DURATION_MS = 2_000

        val DEVICE_MODEL: String = Build.MODEL ?: "unknown"
        val OS_VERSION: String = "Android ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})"

        fun toNative(reason: GateReason): NativeQualityReason = when (reason) {
            GateReason.SILENCE -> NativeQualityReason.SILENCE
            GateReason.CLIPPING -> NativeQualityReason.CLIPPING
            GateReason.HIGH_NOISE -> NativeQualityReason.HIGH_NOISE
            GateReason.TOO_SHORT -> NativeQualityReason.TOO_SHORT
        }

        fun toNative(label: ModelLabel): NativeClassification = when (label) {
            ModelLabel.CLEAN -> NativeClassification.CLEAN
            ModelLabel.UNCERTAIN -> NativeClassification.UNCERTAIN
            ModelLabel.INFESTED -> NativeClassification.INFESTED
        }
    }
}
