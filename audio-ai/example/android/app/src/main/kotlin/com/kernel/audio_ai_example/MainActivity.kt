package com.kernel.audio_ai_example

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

/**
 * Developer host for the audio_ai plugin. The plugin never requests runtime
 * permissions itself (the real app does that), so this dev activity asks for
 * RECORD_AUDIO once at launch.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_RECORD_AUDIO)
        }
    }

    private companion object {
        const val REQUEST_RECORD_AUDIO = 1
    }
}
