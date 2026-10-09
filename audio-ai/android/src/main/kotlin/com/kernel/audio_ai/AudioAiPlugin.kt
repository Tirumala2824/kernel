package com.kernel.audio_ai

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

/**
 * Registers the pigeon ScanHostApi and the CaptureLevelEvents event channel.
 * No method channel, no network, and no runtime permission requests: the app
 * asks for RECORD_AUDIO itself.
 */
class AudioAiPlugin : FlutterPlugin {
    private var host: ScanEngineHost? = null
    private var levels: CaptureLevelEmitter? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val emitter = CaptureLevelEmitter()
        levels = emitter
        CaptureLevelsStreamHandler.register(binding.binaryMessenger, emitter)

        val engineHost = ScanEngineHost(binding.applicationContext, emitter)
        host = engineHost
        ScanHostApi.setUp(binding.binaryMessenger, engineHost)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ScanHostApi.setUp(binding.binaryMessenger, null)
        // The generated register() has no unregister counterpart, so clear the
        // handler on the same channel name it uses.
        EventChannel(binding.binaryMessenger, LEVELS_CHANNEL, ScanApiPigeonMethodCodec).setStreamHandler(null)
        levels?.detach()
        levels = null
        host?.close()
        host = null
    }

    private companion object {
        /** Must match the name generated in ScanApi.g.kt for CaptureLevelEvents.captureLevels. */
        const val LEVELS_CHANNEL = "dev.flutter.pigeon.audio_ai.CaptureLevelEvents.captureLevels"
    }
}
