package com.kernel.sense_ai

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec

/** A serial background task queue prevents inference on Flutter's UI thread. */
internal class InsectSoundChannel(messenger: BinaryMessenger, readAsset: (String) -> ByteArray) {
    private val adapter = InsectSoundAdapter(readAsset)
    private val channel = MethodChannel(messenger, "com.kernel.sense_ai/insect_sound",
        StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue())
    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "classifyWavFile") {
                result.notImplemented()
            } else {
                val path = (call.arguments as? Map<*, *>)?.get("path") as? String
                result.success(if (path.isNullOrBlank()) InsectSoundAdapter.noMatch("unavailable", listOf("invalid_path"))
                    else adapter.classifyWavFile(path))
            }
        }
    }
    fun detach() = channel.setMethodCallHandler(null)
}
