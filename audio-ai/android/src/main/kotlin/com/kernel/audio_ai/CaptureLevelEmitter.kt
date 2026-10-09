package com.kernel.audio_ai

import android.os.Handler
import android.os.Looper

/**
 * Pigeon event-channel handler for live capture levels
 * (`CaptureLevelEvents.captureLevels`).
 *
 * [emit] is called from the capture thread for each [LevelReading]. Flutter
 * event sinks must be used on the platform (main) thread, so each reading is
 * posted there. With no Dart listener, readings are dropped. Readings exist
 * only while a capture runs, so nothing is sent while idle.
 *
 * Only the four scalars of [NativeCaptureLevel] cross the bridge, never
 * samples.
 */
class CaptureLevelEmitter : CaptureLevelsStreamHandler() {
    private val main = Handler(Looper.getMainLooper())

    /** Set and cleared on the main thread by the event channel; read from the capture thread. */
    @Volatile
    private var sink: PigeonEventSink<NativeCaptureLevel>? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<NativeCaptureLevel>) {
        this.sink = sink
    }

    override fun onCancel(p0: Any?) {
        sink = null
    }

    /** Any thread. Never throws: a level reading must not affect the capture. */
    fun emit(reading: LevelReading) {
        if (sink == null) return
        val event = NativeCaptureLevel(
            elapsedMs = reading.elapsedMs.toLong(),
            targetMs = reading.targetMs.toLong(),
            rmsDbfs = reading.rmsDbfs,
            peakDbfs = reading.peakDbfs,
        )
        main.post {
            try {
                sink?.success(event)
            } catch (_: RuntimeException) {
                // Engine detached between post and delivery; nothing to do.
            }
        }
    }

    /** Drops queued readings and the sink (plugin detached). */
    fun detach() {
        main.removeCallbacksAndMessages(null)
        sink = null
    }
}
