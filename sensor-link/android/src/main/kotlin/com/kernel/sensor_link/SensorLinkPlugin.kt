package com.kernel.sensor_link

import android.app.Activity
import android.app.Application
import android.os.Bundle
import com.kernel.sensor_link.cdm.CompanionPairing
import com.kernel.sensor_link.link.LinkManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry

/**
 * Registers the pigeon SensorHostApi/SensorFlutterApi. Tracks whether the
 * host activity is resumed, because the connectedDevice foreground service
 * may only be started while the app is visible. No network code.
 */
class SensorLinkPlugin : FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {
    private var pairing: CompanionPairing? = null
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null
    private var lifecycle: Application.ActivityLifecycleCallbacks? = null

    override fun onAttachedToEngine(b: FlutterPlugin.FlutterPluginBinding) {
        val p = CompanionPairing(b.applicationContext)
        pairing = p
        SensorHostApi.setUp(b.binaryMessenger, SensorHostApiImpl(b.applicationContext, p) { activity })
        LinkManager.flutterApi = SensorFlutterApi(b.binaryMessenger)
    }

    override fun onDetachedFromEngine(b: FlutterPlugin.FlutterPluginBinding) {
        SensorHostApi.setUp(b.binaryMessenger, null)
        LinkManager.flutterApi = null
        pairing = null
    }

    override fun onAttachedToActivity(b: ActivityPluginBinding) = attach(b)

    override fun onReattachedToActivityForConfigChanges(b: ActivityPluginBinding) = attach(b)

    override fun onDetachedFromActivityForConfigChanges() = detach()

    override fun onDetachedFromActivity() = detach()

    private fun attach(b: ActivityPluginBinding) {
        binding = b
        activity = b.activity
        b.addActivityResultListener(this)
        val target = b.activity
        val cb = object : Application.ActivityLifecycleCallbacks {
            override fun onActivityResumed(a: Activity) {
                if (a === target) LinkManager.appVisible = true
            }

            override fun onActivityPaused(a: Activity) {
                if (a === target) LinkManager.appVisible = false
            }

            override fun onActivityCreated(a: Activity, s: Bundle?) = Unit
            override fun onActivityStarted(a: Activity) = Unit
            override fun onActivityStopped(a: Activity) = Unit
            override fun onActivitySaveInstanceState(a: Activity, s: Bundle) = Unit
            override fun onActivityDestroyed(a: Activity) = Unit
        }
        lifecycle = cb
        target.application.registerActivityLifecycleCallbacks(cb)
        // Attached while already in the foreground (e.g. hot restart).
        LinkManager.appVisible = target.hasWindowFocus() || LinkManager.appVisible
    }

    private fun detach() {
        binding?.removeActivityResultListener(this)
        lifecycle?.let { activity?.application?.unregisterActivityLifecycleCallbacks(it) }
        lifecycle = null
        binding = null
        activity = null
        LinkManager.appVisible = false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?): Boolean =
        pairing?.onActivityResult(requestCode, resultCode, data) ?: false
}
