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
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Pigeon host: permission check -> start cue -> capture (own thread, live
 * levels) -> quality gate -> log-mel -> model (only if a real one is bundled)
 * -> finish/retry cue -> result. Audio and model problems become RETRY or
 * NOT_EVALUATED results and are never thrown to Dart.
 *
 * Privacy: audio is never logged or sent anywhere. Live levels are scalar
 * dBFS readings only. Buffers are zeroed after analysis. The only persistence
 * is the retain-audio opt-in, which writes to app-private storage.
 */
class ScanEngineHost(
    context: Context,
    private val levels: CaptureLevelEmitter,
) : ScanHostApi {
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

    /** HAL capture rate from the last capture that reported one (API 29+). */
    @Volatile
    private var lastDeviceInputRate: Int? = null

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

    override suspend fun captureAndAnalyze(scanId: String, retainAudio: Boolean, haptics: Boolean): NativeScanResult {
        val calledAt = System.currentTimeMillis()
        if (!capture.hasPermission()) return notRecorded(NativeQualityReason.PERMISSION_DENIED, calledAt)
        if (!busy.compareAndSet(false, true)) {
            Log.w(TAG, "scan requested while another scan is running")
            return notRecorded(NativeQualityReason.CAPTURE_ERROR, calledAt)
        }
        return try {
            withContext(captureDispatcher) { scan(scanId, retainAudio, haptics, calledAt) }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Throwable) {
            Log.e(TAG, "scan $scanId failed: ${e.javaClass.simpleName}")
            notRecorded(NativeQualityReason.CAPTURE_ERROR, calledAt)
        } finally {
            busy.set(false)
        }
    }

    override suspend fun analyzeFile(scanId: String, filePath: String, retainAudio: Boolean): NativeScanResult {
        val calledAt = System.currentTimeMillis()
        val file = java.io.File(filePath)
        if (!file.exists() || !file.canRead()) {
            Log.w(TAG, "file $filePath not found or unreadable")
            return notRecorded(NativeQualityReason.CAPTURE_ERROR, calledAt)
        }
        if (!busy.compareAndSet(false, true)) {
            Log.w(TAG, "analyzeFile requested while another scan is running")
            return notRecorded(NativeQualityReason.CAPTURE_ERROR, calledAt)
        }
        return try {
            withContext(captureDispatcher) {
                val decoded = WavReader.read(file)
                processPcm(
                    scanId = scanId,
                    pcm = decoded.pcm,
                    sampleRate = decoded.sampleRate,
                    deviceInputRate = null,
                    clientSilenced = false,
                    retainAudio = retainAudio,
                    calledAt = calledAt,
                    captureStartNanos = SystemClock.elapsedRealtimeNanos(),
                    endedAtElapsedNanos = SystemClock.elapsedRealtimeNanos(),
                    hapticsOn = false,
                )
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Throwable) {
            Log.e(TAG, "analyzeFile $scanId failed: ${e.javaClass.simpleName}")
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
            modelNote = if (present) handle.note else null,
            audioSource = AudioCapture.AUDIO_SOURCE_NAME,
            deviceInputSampleRate = lastDeviceInputRate?.toLong(),
        )
    }

    override suspend fun deleteRetainedAudio(): Long = withContext(Dispatchers.IO) {
        store.deleteAll().toLong()
    }

    override suspend fun retainedAudioPath(scanId: String): String? = withContext(Dispatchers.IO) {
        store.pathFor(scanId)
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
    private fun scan(scanId: String, retainAudio: Boolean, hapticsOn: Boolean, calledAt: Long): NativeScanResult {
        val scanStart = SystemClock.elapsedRealtimeNanos()
        // haptics=false (in-app setting off) means no cue at all, and no settle wait.
        if (hapticsOn && haptics.start()) Thread.sleep(Haptics.START_SETTLE_MS)

        val captureStart = SystemClock.elapsedRealtimeNanos()
        val recording = try {
            capture.record(TARGET_DURATION_MS, levels::emit)
        } catch (e: SecurityException) {
            return notRecorded(NativeQualityReason.PERMISSION_DENIED, calledAt)
        } catch (e: CaptureException) {
            Log.w(TAG, "capture failed: ${e.message}")
            if (hapticsOn) haptics.retry()
            return notRecorded(NativeQualityReason.CAPTURE_ERROR, calledAt)
        } catch (e: RuntimeException) {
            // AudioRecord state errors (IllegalStateException etc.).
            Log.w(TAG, "capture failed: ${e.javaClass.simpleName}")
            if (hapticsOn) haptics.retry()
            return notRecorded(NativeQualityReason.CAPTURE_ERROR, calledAt)
        }

        try {
            return processPcm(
                scanId = scanId,
                pcm = recording.pcm,
                sampleRate = recording.sampleRate,
                deviceInputRate = recording.deviceInputRate,
                clientSilenced = recording.clientSilenced,
                retainAudio = retainAudio,
                calledAt = recording.startedAtEpochMs,
                captureStartNanos = captureStart,
                endedAtElapsedNanos = recording.endedAtElapsedNanos,
                hapticsOn = hapticsOn,
                settleNanos = captureStart - scanStart,
            )
        } finally {
            recording.discard()
        }
    }

    private fun processPcm(
        scanId: String,
        pcm: ShortArray,
        sampleRate: Int,
        deviceInputRate: Int?,
        clientSilenced: Boolean,
        retainAudio: Boolean,
        calledAt: Long,
        captureStartNanos: Long,
        endedAtElapsedNanos: Long,
        hapticsOn: Boolean,
        settleNanos: Long = 0L,
    ): NativeScanResult {
        lastEffectiveRate = sampleRate
        deviceInputRate?.let { lastDeviceInputRate = it }
        val handle = model.handle()

        val reasons: List<NativeQualityReason>
        val prediction: Prediction?
        var analysis: Analysis? = null
        var asqiScore: Double? = null
        if (clientSilenced) {
            // Android handed the mic to another app and fed us zeros.
            Log.w(TAG, "capture was silenced by the system (mic in use elsewhere)")
            reasons = listOf(NativeQualityReason.CAPTURE_ERROR)
            prediction = null
        } else {
            val a = analyzer.analyze(pcm, sampleRate, handle)
            analysis = a
            reasons = a.reasons.map(::toNative)
            prediction = a.prediction
            if (debuggable) logMetrics(scanId, a)

            // Calculate on-device Audio Signal Quality Index (ASQI)
            val m = a.metrics
            val durSec = (m.durationMs / 1000.0).coerceIn(0.5, 1.0)
            val snrFraction = ((m.snrDb - 6.0) / 18.0).coerceIn(0.4, 1.0)
            val clipPenalty = (1.0 - m.clipFraction * 10.0).coerceIn(0.2, 1.0)
            val rateFraction = if (sampleRate >= 16000) 1.0 else 0.8
            asqiScore = ((snrFraction * clipPenalty) * durSec * rateFraction).coerceIn(0.1, 1.0)
        }

        val pass = reasons.isEmpty()
        if (hapticsOn) {
            if (pass) haptics.finish() else haptics.retry()
        }
        val retainStart = SystemClock.elapsedRealtimeNanos()
        val retained = retainAudio && retain(scanId, pcm, sampleRate, clientSilenced)

        val classified = if (pass) prediction else null
        val resultReady = SystemClock.elapsedRealtimeNanos()
        val latencyMs = (resultReady - endedAtElapsedNanos) / 1_000_000L
        if (debuggable) {
            logBenchmark(
                scanId = scanId,
                settleNanos = settleNanos,
                captureNanos = endedAtElapsedNanos - captureStartNanos,
                timings = analysis?.timings,
                retainNanos = resultReady - retainStart,
                latencyMs = latencyMs,
                totalNanos = resultReady - captureStartNanos,
            )
        }
        val durationMs = (pcm.size.toLong() * 1000L / sampleRate).toInt()
        return NativeScanResult(
            qualityPass = pass,
            qualityReasons = reasons,
            classification = classified?.let { toNative(it.label) } ?: NativeClassification.NOT_EVALUATED,
            confidence = classified?.confidence,
            experimental = handle.experimental,
            modelVersion = handle.version,
            capturedAtEpochMs = calledAt,
            latencyMs = latencyMs,
            durationMs = durationMs.toLong(),
            sampleRate = sampleRate.toLong(),
            deviceModel = DEVICE_MODEL,
            osVersion = OS_VERSION,
            audioRetained = retained,
            asqiScore = asqiScore,
        )
    }

    /** Returns true only if the WAV was actually written. */
    private fun retain(scanId: String, pcm: ShortArray, sampleRate: Int, clientSilenced: Boolean): Boolean {
        if (clientSilenced) {
            // The system replaced the audio with zeros; there is nothing real to keep.
            Log.w(TAG, "retain-audio skipped for scan $scanId (capture silenced by the system)")
            return false
        }
        return try {
            if (store.save(scanId, pcm, sampleRate) == null) {
                Log.w(TAG, "retain-audio skipped for scan $scanId (invalid id or storage unavailable)")
                false
            } else {
                true
            }
        } catch (e: IOException) {
            Log.w(TAG, "retain-audio failed for scan $scanId: ${e.javaClass.simpleName}")
            false
        }
    }

    /** Technical capture configuration only (no audio), logged when it changes. */
    private fun logCaptureConfigOnce(recording: Recording) {
        val config = "source=${AudioCapture.AUDIO_SOURCE_NAME} clientRate=${recording.sampleRate} " +
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
                .format(Locale.ROOT, m.rmsDbfs, m.noiseFloorDbfs, m.peakFrameDbfs, m.snrDb, m.clipFraction, analysis.reasons, analysis.logMelFrames),
        )
    }

    /**
     * Debuggable builds only: per-stage wall-clock timings in ms.
     * - settle: start haptic plus motor ring-down wait (0 with haptics off)
     * - capture: AudioRecord setup + 100 ms warm-up + the kept audio
     * - gate / resample / logMel / inference: [StageTimings]
     * - retain: WAV write under the opt-in (0 when off)
     * - latency: what ScanOutcome.latencyMs reports (capture end -> result ready)
     * - total: the whole native scan, from the start cue to the result
     */
    private fun logBenchmark(
        scanId: String,
        settleNanos: Long,
        captureNanos: Long,
        timings: StageTimings?,
        retainNanos: Long,
        latencyMs: Long,
        totalNanos: Long,
    ) {
        val t = timings ?: StageTimings(0, 0, 0, 0)
        Log.d(
            TAG,
            ("bench scan=$scanId settleMs=%.1f captureMs=%.1f gateMs=%.2f resampleMs=%.2f logMelMs=%.2f " +
                "inferenceMs=%.2f retainMs=%.2f latencyMs=%d totalMs=%.1f")
                .format(Locale.ROOT, ms(settleNanos), ms(captureNanos), ms(t.gateNanos), ms(t.resampleNanos),
                    ms(t.logMelNanos), ms(t.inferenceNanos), ms(retainNanos), latencyMs, ms(totalNanos)),
        )
    }

    private fun ms(nanos: Long): Double = nanos / 1_000_000.0

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
            audioRetained = false,
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
