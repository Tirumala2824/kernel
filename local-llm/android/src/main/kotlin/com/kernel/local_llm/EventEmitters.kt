package com.kernel.local_llm

import android.os.Handler
import android.os.Looper

/**
 * One pigeon event sink, used from any thread. Flutter sinks must be called
 * on the main thread, so every event is posted there. With no Dart listener,
 * events are dropped. Never throws.
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

class EngineStatusEmitter : EngineStatusStreamHandler() {
    val out = MainThreadSink<NativeEngineStatus>()

    override fun onListen(p0: Any?, sink: PigeonEventSink<NativeEngineStatus>) {
        out.sink = sink
    }

    override fun onCancel(p0: Any?) {
        out.sink = null
    }
}

/** Generation progress carries sizes only, never generated text. */
class GenerationProgressEmitter : GenerationProgressStreamHandler() {
    val out = MainThreadSink<NativeGenerationProgress>()

    override fun onListen(p0: Any?, sink: PigeonEventSink<NativeGenerationProgress>) {
        out.sink = sink
    }

    override fun onCancel(p0: Any?) {
        out.sink = null
    }
}

class ImportProgressEmitter : ImportProgressStreamHandler() {
    val out = MainThreadSink<NativeImportProgress>()

    override fun onListen(p0: Any?, sink: PigeonEventSink<NativeImportProgress>) {
        out.sink = sink
    }

    override fun onCancel(p0: Any?) {
        out.sink = null
    }
}
