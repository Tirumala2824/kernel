package com.kernel.sense_ai

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Size
import android.view.Surface
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.LowLightBoostState
import androidx.camera.core.Preview
import androidx.camera.core.TorchState
import androidx.camera.core.UseCase
import androidx.camera.core.resolutionselector.AspectRatioStrategy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.Observer
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.util.UUID
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import kotlin.coroutines.resume
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * CameraX pipeline for Pest ID: Preview (into the SenseCameraPreview
 * platform view), ImageAnalysis (YUV_420_888 about 640x480,
 * KEEP_ONLY_LATEST, Y plane only, Stage 0) and ImageCapture (maximum
 * resolution, in-memory stills).
 *
 * The camera runs only while a preview is mounted, the activity is
 * resumed, the Measure screen is closed and the thermal level is below
 * PAUSED. Night extension is not used: it cannot be bound together with
 * ImageAnalysis. Low Light Boost (API 35+, per device) is used when the
 * app asks for it and the camera supports it.
 *
 * All public methods run on the main thread.
 */
class CameraController(
    private val context: Context,
    private val batches: MainThreadSink<NativeCameraBatch>,
    private val stash: MediaStash,
) : LifecycleOwner {
    private val registry = LifecycleRegistry(this).apply { currentState = Lifecycle.State.CREATED }
    override val lifecycle: Lifecycle get() = registry

    private val main = Handler(Looper.getMainLooper())
    private val mainExecutor = Executor { main.post(it) }
    private val analysisExecutor = Executors.newSingleThreadExecutor()
    private val captureExecutor = Executors.newSingleThreadExecutor()

    private var provider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var capture: ImageCapture? = null
    private var useCases: Array<UseCase> = emptyArray()
    private var view: PreviewView? = null
    private var activityResumed = false
    private var measuring = false
    private var lowLightBoostWanted = false
    private var torchLevel = 0.0

    @Volatile private var thermalLevel = ThermalLevel.NORMAL
    @Volatile private var targetFps = ThermalPolicy.analysisFps(ThermalLevel.NORMAL)
    @Volatile private var torchOn = false
    @Volatile private var torchChangedAt = 0L
    @Volatile private var lowLightBoostActive = false
    @Volatile private var resetRequested = false

    // Analyzer-thread state.
    private val pipeline = Stage0Pipeline()
    private val throttle = CandidateThrottle()
    private var yBytes = ByteArray(0)
    private var small = ByteArray(0)
    private var lastProcessedAt = Long.MIN_VALUE / 2
    private val processedTimes = ArrayDeque<Long>()

    private val gyro = GyroMonitor(context)
    private val thermal = ThermalMonitor(context) { onThermal(it) }

    private val torchObserver = Observer<Int> { state ->
        val on = state == TorchState.ON
        if (on != torchOn) {
            torchOn = on
            torchChangedAt = SystemClock.elapsedRealtime()
        }
    }
    private val lowLightObserver = Observer<Int> { lowLightBoostActive = it == LowLightBoostState.ACTIVE }

    val thermalStage1Allowed: Boolean get() = thermalLevel < ThermalLevel.NO_STAGE1

    fun attach(previewView: PreviewView, lowLightBoost: Boolean) {
        if (registry.currentState == Lifecycle.State.DESTROYED) return
        view = previewView
        lowLightBoostWanted = lowLightBoost
        thermal.start()
        gyro.start()
        ensureProvider { if (view === previewView) bind(previewView) }
    }

    fun detach(previewView: PreviewView) {
        if (view !== previewView) return
        view = null
        unbindUseCases()
        thermal.stop()
        gyro.stop()
        updateLifecycle()
    }

    fun setActivityResumed(resumed: Boolean) {
        activityResumed = resumed
        updateLifecycle()
    }

    /** Releases the camera while the Measure screen owns it. */
    fun setMeasuring(active: Boolean) {
        measuring = active
        updateLifecycle()
    }

    fun setLowLightBoost(enabled: Boolean) {
        lowLightBoostWanted = enabled
        applyLowLightBoost()
    }

    fun setTorch(level: Double) {
        torchLevel = level.coerceIn(0.0, 1.0)
        applyTorch()
    }

    /** Torch on for [durationMs], then back to the previous level (eyeshine check). */
    suspend fun pulseTorch(durationMs: Long) {
        if (camera == null) return
        val previous = torchLevel
        torchLevel = 1.0
        applyTorch()
        delay(durationMs.coerceIn(200L, 3000L))
        torchLevel = previous
        applyTorch()
    }

    fun capabilities(): NativeCameraCapabilities {
        val pm = context.packageManager
        val cam = camera
        val info = cam?.cameraInfo
        val strength = if (info != null && info.isTorchStrengthSupported) info.maxTorchStrengthLevel.toLong() else 1L
        return NativeCameraCapabilities(
            cameraPermission = context.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED,
            hasBackCamera = pm.hasSystemFeature(PackageManager.FEATURE_CAMERA),
            cameraBound = cam != null && registry.currentState.isAtLeast(Lifecycle.State.STARTED),
            torchAvailable = info?.hasFlashUnit() ?: pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH),
            maxTorchStrength = strength,
            lowLightBoostSupported = info?.isLowLightBoostSupported ?: false,
            gyroAvailable = gyro.available,
        )
    }

    /**
     * Full-resolution still kept in [stash] (memory only), plus the upright
     * context image and tiles. Null when no camera is running or the capture
     * failed.
     */
    suspend fun captureStill(boxes: List<NativeBox>): NativeStill? {
        val still = capture ?: return null
        if (!registry.currentState.isAtLeast(Lifecycle.State.STARTED)) return null
        val shot = suspendCancellableCoroutine<Pair<ByteArray, Int>?> { cont ->
            still.takePicture(
                captureExecutor,
                object : ImageCapture.OnImageCapturedCallback() {
                    override fun onCaptureSuccess(image: ImageProxy) {
                        val result = try {
                            jpegBytes(image)?.let { it to image.imageInfo.rotationDegrees }
                        } finally {
                            image.close()
                        }
                        if (cont.isActive) cont.resume(result)
                    }

                    override fun onError(exception: ImageCaptureException) {
                        if (cont.isActive) cont.resume(null)
                    }
                },
            )
        } ?: return null
        val (jpeg, rotation) = shot
        val out = withContext(Dispatchers.Default) {
            try {
                StillProcessor.process(jpeg, rotation, boxes)
            } catch (_: OutOfMemoryError) {
                null
            }
        }
        if (out == null) {
            jpeg.fill(0)
            return null
        }
        val id = UUID.randomUUID().toString()
        stash.putStill(id, jpeg)
        val w = out.uprightWidth.toDouble()
        val h = out.uprightHeight.toDouble()
        return NativeStill(
            stillId = id,
            contextJpeg = out.context,
            tiles = out.tiles.map {
                val r = it.plan.region
                NativeTile(it.plan.candidateId, r.left / w, r.top / h, r.width / w, r.height / h, it.jpeg)
            },
            fullWidth = out.uprightWidth.toLong(),
            fullHeight = out.uprightHeight.toLong(),
            capturedAtEpochMs = System.currentTimeMillis(),
        )
    }

    fun dispose() {
        view = null
        unbindUseCases()
        thermal.stop()
        gyro.stop()
        registry.currentState = Lifecycle.State.DESTROYED
        analysisExecutor.shutdown()
        captureExecutor.shutdown()
    }

    private fun ensureProvider(then: () -> Unit) {
        provider?.let {
            then()
            return
        }
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener(
            {
                try {
                    provider = future.get()
                    then()
                } catch (_: Exception) {
                    // No camera service; capabilities() reports cameraBound = false.
                }
            },
            mainExecutor,
        )
    }

    private fun bind(previewView: PreviewView) {
        val p = provider ?: return
        unbindUseCases()
        val rotation = previewView.display?.rotation ?: Surface.ROTATION_0
        val ratio = AspectRatioStrategy.RATIO_4_3_FALLBACK_AUTO_STRATEGY
        val preview = Preview.Builder()
            .setResolutionSelector(ResolutionSelector.Builder().setAspectRatioStrategy(ratio).build())
            .setTargetRotation(rotation)
            .build()
        preview.surfaceProvider = previewView.surfaceProvider
        val analysis = ImageAnalysis.Builder()
            .setResolutionSelector(
                ResolutionSelector.Builder()
                    .setAspectRatioStrategy(ratio)
                    .setResolutionStrategy(
                        ResolutionStrategy(Size(640, 480), ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER),
                    )
                    .build(),
            )
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
            .setTargetRotation(rotation)
            .build()
        analysis.setAnalyzer(analysisExecutor) { image -> analyze(image) }
        val still = ImageCapture.Builder()
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
            .setResolutionSelector(
                ResolutionSelector.Builder()
                    .setAspectRatioStrategy(ratio)
                    .setResolutionStrategy(ResolutionStrategy.HIGHEST_AVAILABLE_STRATEGY)
                    .build(),
            )
            .setTargetRotation(rotation)
            .build()
        val cases = arrayOf<UseCase>(preview, analysis, still)
        val cam = try {
            p.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA, *cases)
        } catch (_: IllegalArgumentException) {
            null
        } catch (_: IllegalStateException) {
            null
        } ?: return
        camera = cam
        capture = still
        useCases = cases
        resetRequested = true
        cam.cameraInfo.torchState.observeForever(torchObserver)
        cam.cameraInfo.lowLightBoostState.observeForever(lowLightObserver)
        applyTorch()
        applyLowLightBoost()
        updateLifecycle()
    }

    private fun unbindUseCases() {
        camera?.cameraInfo?.let {
            it.torchState.removeObserver(torchObserver)
            it.lowLightBoostState.removeObserver(lowLightObserver)
        }
        // Only our own use cases: other plugins may share ProcessCameraProvider.
        if (useCases.isNotEmpty()) provider?.unbind(*useCases)
        useCases = emptyArray()
        camera = null
        capture = null
        torchOn = false
        lowLightBoostActive = false
    }

    private fun updateLifecycle() {
        if (registry.currentState == Lifecycle.State.DESTROYED) return
        val run = view != null && camera != null && activityResumed && !measuring && thermalLevel != ThermalLevel.PAUSED
        val want = if (run) Lifecycle.State.RESUMED else Lifecycle.State.CREATED
        if (registry.currentState != want) {
            if (run) resetRequested = true
            registry.currentState = want
        }
        if (!run) emitIdle()
    }

    private fun onThermal(headroom: Double?) {
        val next = ThermalPolicy.next(headroom, thermalLevel)
        if (next == thermalLevel) return
        thermalLevel = next
        targetFps = ThermalPolicy.analysisFps(next)
        updateLifecycle()
    }

    private fun applyTorch() {
        val cam = camera ?: return
        if (!cam.cameraInfo.hasFlashUnit()) return
        val on = torchLevel > 0.0
        try {
            cam.cameraControl.enableTorch(on)
            if (on && cam.cameraInfo.isTorchStrengthSupported) {
                val max = cam.cameraInfo.maxTorchStrengthLevel
                if (max >= 1) cam.cameraControl.setTorchStrengthLevel((torchLevel * max).roundToInt().coerceIn(1, max))
            }
        } catch (_: RuntimeException) {
            // Camera closing; the torch state observer reports what happened.
        }
    }

    private fun applyLowLightBoost() {
        val cam = camera ?: return
        if (Build.VERSION.SDK_INT < 35 || !cam.cameraInfo.isLowLightBoostSupported) return
        try {
            cam.cameraControl.enableLowLightBoostAsync(lowLightBoostWanted)
        } catch (_: RuntimeException) {
            // Unsupported in the current configuration.
        }
    }

    private fun analyze(image: ImageProxy) {
        try {
            if (resetRequested) {
                resetRequested = false
                pipeline.reset()
                throttle.reset()
            }
            val now = SystemClock.elapsedRealtime()
            val fps = targetFps
            if (fps <= 0.0 || now - lastProcessedAt < (1000.0 / fps).toLong() - 5) return
            lastProcessedAt = now
            val plane = image.planes[0]
            val buf = plane.buffer
            buf.rewind()
            val len = buf.remaining()
            if (yBytes.size < len) yBytes = ByteArray(len)
            buf.get(yBytes, 0, len)
            val factor = Luma.factorFor(max(image.width, image.height))
            val need = (image.width / factor) * (image.height / factor)
            if (small.size < need) small = ByteArray(need)
            val down = Luma.downsample(yBytes, image.width, image.height, plane.rowStride, factor, small)
            val upright = Luma.rotate(down, image.imageInfo.rotationDegrees)
            val result = pipeline.process(upright, gyro.takePeak(), torchOn, torchChangedAt, now, System.currentTimeMillis())
            processedTimes.addLast(now)
            while (processedTimes.isNotEmpty() && now - processedTimes.first() > 1000) processedTimes.removeFirst()
            if (throttle.offer(result.candidates, now)) {
                batches.emit(batch(result.candidates, result.gyroGated, true, processedTimes.size.toDouble()))
            }
        } catch (_: RuntimeException) {
            // A bad frame must not stop the analyzer.
        } finally {
            image.close()
        }
    }

    private fun emitIdle() = batches.emit(batch(emptyList(), gyroGated = false, active = false, fps = 0.0))

    private fun batch(c: List<Stage0Candidate>, gyroGated: Boolean, active: Boolean, fps: Double) = NativeCameraBatch(
        candidates = c.map {
            NativeCandidate(it.id, kindOf(it.kind), it.score, it.detectedAtEpochMs, it.left, it.top, it.width, it.height)
        },
        emittedAtEpochMs = System.currentTimeMillis(),
        thermalLevel = when (thermalLevel) {
            ThermalLevel.NORMAL -> NativeThermalLevel.NORMAL
            ThermalLevel.REDUCED_FPS -> NativeThermalLevel.REDUCED_FPS
            ThermalLevel.NO_STAGE1 -> NativeThermalLevel.NO_STAGE1
            ThermalLevel.PAUSED -> NativeThermalLevel.PAUSED
        },
        thermalHeadroom = thermal.lastHeadroom,
        cameraActive = active,
        gyroGated = gyroGated,
        torchOn = active && torchOn,
        lowLightBoostActive = active && lowLightBoostActive,
        analysisFps = fps,
    )

    private fun kindOf(k: Stage0Kind) = when (k) {
        Stage0Kind.MOTION -> NativeSignalKind.MOTION
        Stage0Kind.DARK_SPECKS -> NativeSignalKind.DARK_SPECKS
        Stage0Kind.EYESHINE -> NativeSignalKind.EYESHINE
    }

    private fun jpegBytes(image: ImageProxy): ByteArray? {
        if (image.format != ImageFormat.JPEG) return null
        val buf = image.planes.firstOrNull()?.buffer ?: return null
        buf.rewind()
        val out = ByteArray(buf.remaining())
        buf.get(out)
        return out
    }
}
