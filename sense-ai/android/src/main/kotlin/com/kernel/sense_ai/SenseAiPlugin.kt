package com.kernel.sense_ai

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Pest ID sensing plugin: pigeon SenseHostApi, three event channels
 * (camera batches, sound events, listen status) and the camera preview
 * platform view. No network code, no runtime permission requests (the app
 * asks for CAMERA and RECORD_AUDIO itself) and no media logging.
 */
class SenseAiPlugin : FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener, SenseHostApi {
    private var context: Context? = null
    private var messenger: BinaryMessenger? = null
    private var stash: MediaStash? = null
    private var camera: CameraController? = null
    private val batches = CameraBatchEmitter()
    private val sounds = SoundEventEmitter()
    private val listenStatus = ListenStatusEmitter()

    private var activityBinding: ActivityPluginBinding? = null
    private var activityLifecycle: Lifecycle? = null
    private var activityStarted = false
    private var pendingMeasure: CompletableDeferred<NativeDistance>? = null

    private val activityObserver = LifecycleEventObserver { source, _ ->
        val state = source.lifecycle.currentState
        activityStarted = state.isAtLeast(Lifecycle.State.STARTED)
        camera?.setActivityResumed(state.isAtLeast(Lifecycle.State.RESUMED))
    }

    private val listenSink = object : ListenSink {
        override fun onEvent(event: NativeSoundEvent) = sounds.out.emit(event)
        override fun onStatus(status: NativeListenStatus) = listenStatus.out.emit(status)
    }

    // ---- FlutterPlugin ---------------------------------------------------------

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val ctx = binding.applicationContext
        context = ctx
        messenger = binding.binaryMessenger
        val s = MediaStash(ctx.filesDir)
        stash = s
        camera = CameraController(ctx, batches.out, s)
        ListenController.stash = s
        ListenController.sink = listenSink
        SenseHostApi.setUp(binding.binaryMessenger, this)
        CameraBatchesStreamHandler.register(binding.binaryMessenger, batches)
        SoundEventsStreamHandler.register(binding.binaryMessenger, sounds)
        ListenStatusStreamHandler.register(binding.binaryMessenger, listenStatus)
        binding.platformViewRegistry.registerViewFactory(SensePreviewFactory.VIEW_TYPE, SensePreviewFactory(camera!!))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SenseHostApi.setUp(binding.binaryMessenger, null)
        // The generated register() has no unregister; clear the same channels.
        for (name in EVENT_CHANNELS) {
            EventChannel(binding.binaryMessenger, "$EVENT_PREFIX.$name", SenseApiPigeonMethodCodec).setStreamHandler(null)
        }
        batches.out.detach()
        sounds.out.detach()
        listenStatus.out.detach()
        ListenController.stop(null)
        if (ListenController.sink === listenSink) ListenController.sink = null
        camera?.dispose()
        camera = null
        stash?.clear()
        stash = null
        context = null
        messenger = null
    }

    // ---- ActivityAware ---------------------------------------------------------

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
        val lifecycle = (binding.activity as? LifecycleOwner)?.lifecycle
        activityLifecycle = lifecycle
        if (lifecycle != null) {
            lifecycle.addObserver(activityObserver)
        } else {
            // Not a LifecycleOwner: treat the attached activity as visible.
            activityStarted = true
            camera?.setActivityResumed(true)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activityLifecycle?.removeObserver(activityObserver)
        activityLifecycle = null
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activityStarted = false
        camera?.setActivityResumed(false)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != MEASURE_REQUEST) return false
        val pending = pendingMeasure ?: return true
        pendingMeasure = null
        pending.complete(if (resultCode == Activity.RESULT_OK) MeasureActivity.parse(data) else MeasureActivity.unavailable(DistanceReason.CANCELLED))
        return true
    }

    // ---- SenseHostApi (main thread) ------------------------------------------------

    override suspend fun cameraCapabilities(): NativeCameraCapabilities =
        camera?.capabilities() ?: NativeCameraCapabilities(false, false, false, false, 1, false, false)

    override suspend fun captureStill(boxes: List<NativeBox>): NativeStill? = camera?.captureStill(boxes)

    override suspend fun setTorch(level: Double) {
        camera?.setTorch(level)
    }

    override suspend fun pulseTorch(durationMs: Long) {
        camera?.pulseTorch(durationMs)
    }

    override fun setLowLightBoost(enabled: Boolean) {
        camera?.setLowLightBoost(enabled)
    }

    override suspend fun startListening(mode: NativeListenMode, soundModelPath: String?): NativeListenStatus {
        val ctx = context ?: return NativeListenStatus(NativeListenState.FAILED, mode, ListenController.REASON_CAPTURE, false, false, null)
        val visible = activityStarted
        return withContext(Dispatchers.IO) { ListenController.start(ctx, mode, soundModelPath, visible) }
    }

    override fun stopListening() {
        ListenController.stop(null)
    }

    override fun clipFor(candidateId: String): ByteArray? = stash?.wav(candidateId)

    override fun soundLabelsFor(candidateId: String): List<NativeScoredLabel> = stash?.labels(candidateId).orEmpty()

    override suspend fun distanceCapability(): NativeDistanceCapability {
        val ctx = context ?: return NativeDistanceCapability(false, false, DistanceReason.ARCORE_UNSUPPORTED)
        return try {
            // ARCore sessions are normally created with an Activity context.
            DistanceProbe.capability(activityBinding?.activity ?: ctx)
        } catch (_: RuntimeException) {
            NativeDistanceCapability(false, false, DistanceReason.ARCORE_UNSUPPORTED)
        }
    }

    override suspend fun measure(target: NativeBox?): NativeDistance {
        val ctx = context ?: return MeasureActivity.unavailable(DistanceReason.MEASURE_FAILED)
        val activity = activityBinding?.activity ?: return MeasureActivity.unavailable(DistanceReason.MEASURE_FAILED)
        if (pendingMeasure != null) return MeasureActivity.unavailable(DistanceReason.MEASURE_FAILED)
        if (ctx.checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            return MeasureActivity.unavailable(DistanceReason.CAMERA_PERMISSION)
        }
        val cap = distanceCapability()
        if (!cap.arcoreDepth && !cap.focusDistance) return MeasureActivity.unavailable(DistanceReason.ARCORE_UNSUPPORTED)
        val deferred = CompletableDeferred<NativeDistance>()
        pendingMeasure = deferred
        // Free the camera for the Measure screen.
        camera?.setMeasuring(true)
        try {
            activity.startActivityForResult(MeasureActivity.intent(activity, target, cap.arcoreDepth, cap.focusDistance), MEASURE_REQUEST)
            return deferred.await()
        } catch (_: RuntimeException) {
            return MeasureActivity.unavailable(DistanceReason.MEASURE_FAILED)
        } finally {
            if (pendingMeasure === deferred) pendingMeasure = null
            camera?.setMeasuring(false)
        }
    }

    override fun discardMedia() {
        stash?.clear()
        ListenController.clearBuffers()
    }

    override suspend fun keepMedia(mediaId: String): String? {
        val s = stash ?: return null
        return withContext(Dispatchers.IO) { s.keep(mediaId) }
    }

    private companion object {
        const val MEASURE_REQUEST = 0x5E4D
        const val EVENT_PREFIX = "dev.flutter.pigeon.sense_ai.SenseEvents"
        val EVENT_CHANNELS = listOf("cameraBatches", "soundEvents", "listenStatus")
    }
}
