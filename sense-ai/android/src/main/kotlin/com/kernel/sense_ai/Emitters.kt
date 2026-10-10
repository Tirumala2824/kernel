package com.kernel.sense_ai

import android.os.Handler
import android.os.Looper

/**
 * Delivers events to one Dart listener on the platform thread. With no
 * listener, events are dropped. Never throws: an event must not break the
 * camera or audio thread that produced it.
 */
class MainThreadSink<T> {
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    var sink: PigeonEventSink<T>? = null

    fun emit(value: T) {
        if (sink == null) return
        main.post {
            try {
                sink?.success(value)
            } catch (_: RuntimeException) {
                // Engine detached between post and delivery.
            }
        }
    }

    fun detach() {
        main.removeCallbacksAndMessages(null)
        sink = null
    }
}

class CameraBatchEmitter : CameraBatchesStreamHandler() {
    val out = MainThreadSink<NativeCameraBatch>()

    override fun onListen(p0: Any?, sink: PigeonEventSink<NativeCameraBatch>) {
        out.sink = sink
    }

    override fun onCancel(p0: Any?) {
        out.sink = null
    }
}

class SoundEventEmitter : SoundEventsStreamHandler() {
    val out = MainThreadSink<NativeSoundEvent>()

    override fun onListen(p0: Any?, sink: PigeonEventSink<NativeSoundEvent>) {
        out.sink = sink
    }

    override fun onCancel(p0: Any?) {
        out.sink = null
    }
}

class ListenStatusEmitter : ListenStatusStreamHandler() {
    val out = MainThreadSink<NativeListenStatus>()

    override fun onListen(p0: Any?, sink: PigeonEventSink<NativeListenStatus>) {
        out.sink = sink
    }

    override fun onCancel(p0: Any?) {
        out.sink = null
    }
}
