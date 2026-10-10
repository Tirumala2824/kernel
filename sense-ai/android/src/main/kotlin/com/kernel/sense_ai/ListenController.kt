package com.kernel.sense_ai

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioRouting
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import java.util.UUID
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/** Where listen events and status changes go (the plugin's event channels). */
interface ListenSink {
    fun onEvent(event: NativeSoundEvent)
    fun onStatus(status: NativeListenStatus)
}

/**
 * Process-wide owner of the listen session, shared by the plugin and
 * [NightListenService]. Listen mode has its own AudioRecord pinned to
 * TYPE_BUILTIN_MIC and never touches the grain-scan capture in audio-ai.
 */
object ListenController {
    const val REASON_PERMISSION = "permission_denied"
    const val REASON_NO_BUILTIN_MIC = "builtin_mic_unavailable"
    const val REASON_REROUTED = "mic_rerouted"
    const val REASON_NOT_VISIBLE = "app_not_visible"
    const val REASON_CAPTURE = "capture_error"
    const val REASON_NOTIFICATION = "stopped_from_notification"

    @Volatile
    var sink: ListenSink? = null

    @Volatile
    var stash: MediaStash? = null

    private var session: ListenSession? = null

    @Synchronized
    fun start(context: Context, mode: NativeListenMode, modelPath: String?, appVisible: Boolean): NativeListenStatus {
        stopLocked(null, notify = false)
        val app = context.applicationContext
        if (mode == NativeListenMode.NIGHT && !appVisible) return failed(mode, REASON_NOT_VISIBLE)
        val classifier = SoundClassifier.open(modelPath)
        val s = ListenSession(app, mode, classifier, { stash }, { sink }) { reason -> onSessionEnded(reason) }
        val status = s.start()
        if (status.state != NativeListenState.LISTENING) {
            classifier?.close()
            return status
        }
        session = s
        if (mode == NativeListenMode.NIGHT) NightListenService.start(app)
        return status
    }

    @Synchronized
    fun stop(reason: String?) = stopLocked(reason, notify = true)

    @Synchronized
    fun clearBuffers() {
        session?.requestClear()
    }

    val isNight: Boolean
        @Synchronized get() = session?.mode == NativeListenMode.NIGHT

    private fun stopLocked(reason: String?, notify: Boolean) {
        val s = session ?: return
        session = null
        s.stop()
        if (s.mode == NativeListenMode.NIGHT) NightListenService.stop(s.context)
        if (notify) sink?.onStatus(s.status(NativeListenState.STOPPED, reason))
    }

    /** The audio thread ended on its own (error or rerouting). */
    private fun onSessionEnded(reason: String) {
        val s = synchronized(this) {
            val current = session ?: return
            session = null
            current
        }
        s.stop()
        if (s.mode == NativeListenMode.NIGHT) NightListenService.stop(s.context)
        sink?.onStatus(s.status(NativeListenState.FAILED, reason))
    }

    private fun failed(mode: NativeListenMode, reason: String) =
        NativeListenStatus(NativeListenState.FAILED, mode, reason, micVerified = false, soundModelLoaded = false, soundModelName = null)
}

/**
 * One AudioRecord session: 16 kHz mono PCM16 from the built-in mic,
 * fed to [ListenPipeline]; finished events are classified (when a model is
 * loaded) on a separate thread, held in [MediaStash] and reported.
 */
class ListenSession(
    val context: Context,
    val mode: NativeListenMode,
    private val classifier: SoundClassifier?,
    private val stash: () -> MediaStash?,
    private val sink: () -> ListenSink?,
    private val onEnded: (String) -> Unit,
) {
    private val running = AtomicBoolean(false)
    private val clear = AtomicBoolean(false)
    private var record: AudioRecord? = null
    private var thread: Thread? = null
    private var micVerified = false
    private var startedAtWallMs = 0L
    private val main = Handler(Looper.getMainLooper())
    private val classify = ThreadPoolExecutor(1, 1, 0, TimeUnit.MILLISECONDS, ArrayBlockingQueue(16), ThreadPoolExecutor.DiscardPolicy())
    private val pipeline = ListenPipeline(sampleRate = SAMPLE_RATE, idFactory = { UUID.randomUUID().toString() })
    private val routing = AudioRouting.OnRoutingChangedListener { r ->
        val routed = (r as? AudioRecord)?.routedDevice
        if (routed != null && routed.type != AudioDeviceInfo.TYPE_BUILTIN_MIC) end(ListenController.REASON_REROUTED)
    }

    fun status(state: NativeListenState, reason: String?) = NativeListenStatus(
        state = state,
        mode = mode,
        reason = reason,
        micVerified = micVerified,
        soundModelLoaded = classifier != null,
        soundModelName = classifier?.name,
    )

    fun start(): NativeListenStatus {
        if (context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return status(NativeListenState.FAILED, ListenController.REASON_PERMISSION)
        }
        val audio = context.getSystemService(AudioManager::class.java)
        val builtin = audio?.getDevices(AudioManager.GET_DEVICES_INPUTS)?.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_MIC }
            ?: return status(NativeListenState.FAILED, ListenController.REASON_NO_BUILTIN_MIC)
        val unprocessed = audio.getProperty(AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED) == "true"
        val source = if (unprocessed) MediaRecorder.AudioSource.UNPROCESSED else MediaRecorder.AudioSource.VOICE_RECOGNITION
        val minBuf = AudioRecord.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        if (minBuf <= 0) return status(NativeListenState.FAILED, ListenController.REASON_CAPTURE)
        val rec = try {
            AudioRecord(source, SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, maxOf(minBuf, SAMPLE_RATE))
        } catch (_: RuntimeException) {
            return status(NativeListenState.FAILED, ListenController.REASON_CAPTURE)
        }
        if (rec.state != AudioRecord.STATE_INITIALIZED) {
            rec.release()
            return status(NativeListenState.FAILED, ListenController.REASON_CAPTURE)
        }
        rec.setPreferredDevice(builtin)
        try {
            rec.startRecording()
        } catch (_: IllegalStateException) {
            rec.release()
            return status(NativeListenState.FAILED, ListenController.REASON_CAPTURE)
        }
        if (rec.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
            rec.release()
            return status(NativeListenState.FAILED, ListenController.REASON_CAPTURE)
        }
        // Verify the pin: the route is known once audio flows.
        val warm = ShortArray(SAMPLE_RATE / 10)
        rec.read(warm, 0, warm.size)
        warm.fill(0)
        val routed = rec.routedDevice
        if (routed != null && routed.type != AudioDeviceInfo.TYPE_BUILTIN_MIC) {
            rec.stop()
            rec.release()
            return status(NativeListenState.FAILED, ListenController.REASON_NO_BUILTIN_MIC)
        }
        micVerified = routed != null
        rec.addOnRoutingChangedListener(routing, main)
        record = rec
        startedAtWallMs = System.currentTimeMillis()
        running.set(true)
        thread = Thread({ loop(rec) }, "sense-listen").also { it.start() }
        return status(NativeListenState.LISTENING, null)
    }

    fun requestClear() = clear.set(true)

    fun stop() {
        if (!running.getAndSet(false)) return
        val rec = record
        record = null
        rec?.removeOnRoutingChangedListener(routing)
        try {
            rec?.stop()
        } catch (_: IllegalStateException) {
            // Already stopped.
        }
        if (thread !== Thread.currentThread()) thread?.join(500)
        rec?.release()
        classify.shutdownNow()
        classifier?.close()
        pipeline.clear()
    }

    private fun end(reason: String) {
        if (running.get()) main.post { onEnded(reason) }
    }

    private fun loop(rec: AudioRecord) {
        val buf = ShortArray(SAMPLE_RATE / 50) // 20 ms
        while (running.get()) {
            val n = rec.read(buf, 0, buf.size)
            if (n < 0) {
                end(ListenController.REASON_CAPTURE)
                break
            }
            if (clear.getAndSet(false)) pipeline.clear()
            if (n == 0) continue
            val events = pipeline.feed(buf, n)
            for (e in events) classify.execute { report(e) }
        }
        buf.fill(0)
    }

    private fun report(e: SoundEventRecord) {
        if (!running.get()) return
        val scores = classifier?.classify(e.window)
        e.window.fill(0f)
        val filter = scores?.let { SoundPreFilter.evaluate(it, classifier.labels) }
        if (filter?.rejected == true) {
            e.clip.fill(0)
            return
        }
        val labels = filter?.labels.orEmpty().map { NativeScoredLabel(it.label, it.score.toDouble(), it.index.toLong()) }
        stash()?.putClip(e.id, e.clip, SAMPLE_RATE, labels)
        val at = startedAtWallMs + e.onsetSample * 1000 / SAMPLE_RATE
        sink()?.onEvent(
            NativeSoundEvent(
                id = e.id,
                score = e.score,
                detectedAtEpochMs = at,
                hint = filter?.hint,
                labelled = scores != null,
                onsetCount = e.onsetCount.toLong(),
            ),
        )
    }

    companion object {
        const val SAMPLE_RATE = 16_000
    }
}
