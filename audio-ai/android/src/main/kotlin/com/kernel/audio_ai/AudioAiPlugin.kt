package com.kernel.audio_ai

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Registers the pigeon ScanHostApi. No method channel, no network, and no
 * runtime permission requests: the app asks for RECORD_AUDIO itself.
 */
class AudioAiPlugin : FlutterPlugin {
    private var host: ScanEngineHost? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val engineHost = ScanEngineHost(binding.applicationContext)
        host = engineHost
        ScanHostApi.setUp(binding.binaryMessenger, engineHost)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ScanHostApi.setUp(binding.binaryMessenger, null)
        host?.close()
        host = null
    }
}
