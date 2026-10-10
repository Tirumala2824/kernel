package com.kernel.sense_ai

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CaptureRequest
import android.hardware.camera2.CaptureResult
import android.hardware.camera2.TotalCaptureResult
import android.media.Image
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.window.OnBackInvokedDispatcher
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import com.google.ar.core.Config
import com.google.ar.core.Coordinates2d
import com.google.ar.core.DepthPoint
import com.google.ar.core.Frame
import com.google.ar.core.Session
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.CameraNotAvailableException
import java.nio.ByteOrder
import java.util.Locale
import java.util.concurrent.Executor
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

/**
 * Full-screen Measure screen. Tier 1: ARCore depth (hit-test DepthPoint at
 * the target, shown only when TRACKING, fresh depth and confidence gates
 * pass). Tier 2: Camera2 AF lock on the target and LENS_FOCUS_DISTANCE,
 * only 0.1-0.6 m. Otherwise it returns unavailable with a reason key.
 * Monocular-depth or pinhole estimates are never computed or shown.
 *
 * Strings are Android resources (res/values/strings.xml); the app can
 * translate them by overriding the same names.
 */
class MeasureActivity : Activity(), LifecycleOwner {
    private enum class Tier { NONE, AR, FOCUS }

    private val registry = LifecycleRegistry(this)
    override val lifecycle: Lifecycle get() = registry

    private val main = Handler(Looper.getMainLooper())
    private val mainExecutor = Executor { main.post(it) }
    private lateinit var root: FrameLayout
    private lateinit var status: TextView
    private lateinit var reticle: Reticle
    private lateinit var closeUp: Button

    private var targetX = 0.5f
    private var targetY = 0.5f
    private var arAllowed = false
    private var focusAllowed = false
    @Volatile private var tier = Tier.NONE
    @Volatile private var finished = false
    private var lastReason: String? = null
    private var lastUiAt = 0L

    // Tier 1 (ARCore). The session is used on the GL thread between
    // GLSurfaceView.onResume and onPause only.
    private var session: Session? = null
    private var glView: GLSurfaceView? = null
    private var automaticDepth = false
    private val background = ArBackground()
    private val freshness = DepthFreshness()
    private val stable = StableReading()
    @Volatile private var viewW = 0
    @Volatile private var viewH = 0
    private var arStartedAt = 0L

    // Tier 2 (CameraX + Camera2 interop).
    private var provider: ProcessCameraProvider? = null
    private var preview: Preview? = null
    private var previewView: PreviewView? = null
    private var camera: Camera? = null
    @Volatile private var calibration: Int? = null
    @Volatile private var optics: FocusDistanceGate.Optics? = null
    @Volatile private var afPending = false
    @Volatile private var afLockAwaitedSince = 0L
    private var focusToken = 0
    private var pendingFocus: DistanceDecision.Available? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registry.currentState = Lifecycle.State.CREATED
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        targetX = intent.getFloatExtra(EXTRA_TARGET_X, 0.5f).coerceIn(0.05f, 0.95f)
        targetY = intent.getFloatExtra(EXTRA_TARGET_Y, 0.5f).coerceIn(0.05f, 0.95f)
        arAllowed = intent.getBooleanExtra(EXTRA_ARCORE, false)
        focusAllowed = intent.getBooleanExtra(EXTRA_FOCUS, false)
        buildUi()
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT) {
                finishUnavailable(DistanceReason.CANCELLED)
            }
        }
        when {
            arAllowed -> startAr()
            focusAllowed -> startFocus()
            else -> finishUnavailable(DistanceReason.ARCORE_UNSUPPORTED)
        }
    }

    override fun onStart() {
        super.onStart()
        registry.currentState = Lifecycle.State.STARTED
    }

    override fun onResume() {
        super.onResume()
        registry.currentState = Lifecycle.State.RESUMED
        if (tier == Tier.AR) resumeAr(0)
    }

    override fun onPause() {
        if (tier == Tier.AR) {
            glView?.onPause()
            session?.pause()
        }
        registry.currentState = Lifecycle.State.STARTED
        super.onPause()
    }

    override fun onStop() {
        registry.currentState = Lifecycle.State.CREATED
        super.onStop()
    }

    override fun onDestroy() {
        closeAr()
        preview?.let { provider?.unbind(it) }
        main.removeCallbacksAndMessages(null)
        registry.currentState = Lifecycle.State.DESTROYED
        super.onDestroy()
    }

    @Deprecated("Back on API < 33; API 33+ uses OnBackInvokedCallback")
    override fun onBackPressed() {
        finishUnavailable(DistanceReason.CANCELLED)
    }

    // ---- UI ----------------------------------------------------------------

    private fun buildUi() {
        val d = resources.displayMetrics.density
        root = FrameLayout(this).apply { setBackgroundColor(Color.BLACK) }
        reticle = Reticle(this)
        root.addView(reticle, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        status = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 18f
            gravity = Gravity.CENTER
            setBackgroundColor(Color.argb(160, 0, 0, 0))
            val p = (16 * d).toInt()
            setPadding(p, p, p, p)
            fitsSystemWindows = true
        }
        root.addView(status, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.TOP))
        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.argb(160, 0, 0, 0))
            val p = (12 * d).toInt()
            setPadding(p, p, p, p)
            fitsSystemWindows = true
        }
        val cancel = Button(this).apply {
            setText(R.string.sense_measure_cancel)
            setOnClickListener { finishUnavailable(DistanceReason.CANCELLED) }
        }
        closeUp = Button(this).apply {
            setText(R.string.sense_measure_close_up)
            visibility = View.GONE
            setOnClickListener {
                closeAr()
                startFocus()
            }
        }
        bar.addView(cancel)
        bar.addView(closeUp)
        root.addView(bar, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM))
        setContentView(root)
        reticle.set(targetX, targetY)
    }

    private fun showStatus(text: String, force: Boolean = false) {
        val now = SystemClock.elapsedRealtime()
        if (!force && now - lastUiAt < 200) return
        lastUiAt = now
        main.post { if (!finished) status.text = text }
    }

    private fun reasonText(reason: String): String = getString(
        when (reason) {
            DistanceReason.MOVE_PHONE_SLOWLY -> R.string.sense_measure_move_slowly
            DistanceReason.TAP_TO_FOCUS -> R.string.sense_measure_tap_to_focus
            DistanceReason.OUT_OF_RANGE -> R.string.sense_measure_out_of_range
            else -> R.string.sense_measure_unsupported
        },
    )

    private fun readingText(d: DistanceDecision.Available): String =
        getString(R.string.sense_measure_result, metres(d.meters), metres(d.low), metres(d.high))

    private fun metres(m: Double): String =
        if (m < 1.0) String.format(Locale.getDefault(), "%d cm", Math.round(m * 100)) else String.format(Locale.getDefault(), "%.2f m", m)

    // ---- Results -------------------------------------------------------------

    private fun finishAvailable(method: NativeDistanceMethod, d: DistanceDecision.Available) {
        if (finished) return
        finished = true
        setResult(
            RESULT_OK,
            Intent()
                .putExtra(EXTRA_METHOD, method.raw)
                .putExtra(EXTRA_METERS, d.meters)
                .putExtra(EXTRA_LOW, d.low)
                .putExtra(EXTRA_HIGH, d.high)
                .putExtra(EXTRA_CONFIDENCE, d.confidence),
        )
        finish()
    }

    private fun finishUnavailable(reason: String) {
        if (finished) return
        finished = true
        setResult(RESULT_OK, unavailableIntent(reason))
        finish()
    }

    // ---- Tier 1: ARCore depth -------------------------------------------------

    private fun startAr() {
        val s = try {
            Session(this)
        } catch (_: Exception) {
            null
        }
        if (s == null) {
            fallbackFromAr(DistanceReason.ARCORE_UNSUPPORTED)
            return
        }
        automaticDepth = s.isDepthModeSupported(Config.DepthMode.AUTOMATIC)
        val config = Config(s)
        config.setDepthMode(if (automaticDepth) Config.DepthMode.AUTOMATIC else Config.DepthMode.RAW_DEPTH_ONLY)
        config.setFocusMode(Config.FocusMode.AUTO)
        config.setUpdateMode(Config.UpdateMode.LATEST_CAMERA_IMAGE)
        try {
            s.configure(config)
        } catch (_: Exception) {
            s.close()
            fallbackFromAr(DistanceReason.ARCORE_UNSUPPORTED)
            return
        }
        session = s
        val gl = GLSurfaceView(this).apply {
            preserveEGLContextOnPause = true
            setEGLContextClientVersion(2)
            setEGLConfigChooser(8, 8, 8, 8, 16, 0)
            setRenderer(renderer)
            renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
        }
        glView = gl
        root.addView(gl, 0, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        freshness.reset()
        stable.clear()
        arStartedAt = SystemClock.elapsedRealtime()
        tier = Tier.AR
        closeUp.visibility = if (focusAllowed) View.VISIBLE else View.GONE
        showStatus(reasonText(DistanceReason.MOVE_PHONE_SLOWLY), force = true)
        if (registry.currentState.isAtLeast(Lifecycle.State.RESUMED)) resumeAr(0)
    }

    private fun resumeAr(attempt: Int) {
        val s = session ?: return
        try {
            s.resume()
            glView?.onResume()
        } catch (_: CameraNotAvailableException) {
            // The preview camera may still be closing; retry briefly.
            if (attempt < 6) {
                main.postDelayed({ if (tier == Tier.AR && registry.currentState.isAtLeast(Lifecycle.State.RESUMED)) resumeAr(attempt + 1) }, 300)
            } else {
                fallbackFromAr(DistanceReason.MOVE_PHONE_SLOWLY)
            }
        } catch (_: SecurityException) {
            finishUnavailable(DistanceReason.CAMERA_PERMISSION)
        } catch (_: RuntimeException) {
            fallbackFromAr(DistanceReason.ARCORE_UNSUPPORTED)
        }
    }

    private fun closeAr() {
        if (tier == Tier.AR) tier = Tier.NONE
        glView?.let {
            it.onPause()
            root.removeView(it)
        }
        glView = null
        session?.let {
            try {
                it.pause()
                it.close()
            } catch (_: RuntimeException) {
                // Already closed.
            }
        }
        session = null
        closeUp.visibility = View.GONE
    }

    private fun fallbackFromAr(reason: String) {
        if (finished) return
        closeAr()
        if (focusAllowed) startFocus() else finishUnavailable(reason)
    }

    private fun displayRotation(): Int =
        if (Build.VERSION.SDK_INT >= 30) display?.rotation ?: 0 else @Suppress("DEPRECATION") windowManager.defaultDisplay.rotation

    private val renderer = object : GLSurfaceView.Renderer {
        override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
            GLES20.glClearColor(0f, 0f, 0f, 1f)
            background.create()
            session?.setCameraTextureName(background.textureId)
        }

        override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
            GLES20.glViewport(0, 0, width, height)
            viewW = width
            viewH = height
            session?.setDisplayGeometry(displayRotation(), width, height)
        }

        override fun onDrawFrame(gl: GL10?) {
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)
            val s = session ?: return
            if (tier != Tier.AR || finished) return
            val frame = try {
                s.update()
            } catch (_: Exception) {
                return
            }
            background.draw(frame)
            evaluateDepth(frame)
        }
    }

    /** GL thread. */
    private fun evaluateDepth(frame: Frame) {
        val now = SystemClock.elapsedRealtime()
        val cam = frame.camera
        val tracking = cam.trackingState == TrackingState.TRACKING
        val tx = targetX * viewW
        val ty = targetY * viewH
        val norm = floatArrayOf(0.5f, 0.5f)
        try {
            frame.transformCoordinates2d(Coordinates2d.VIEW, floatArrayOf(tx, ty), Coordinates2d.IMAGE_NORMALIZED, norm)
        } catch (_: RuntimeException) {
            // Keep the centre.
        }
        acquire { frame.acquireRawDepthImage16Bits() }?.let { img ->
            try {
                freshness.record(img.timestamp, now)
            } finally {
                img.close()
            }
        }
        val rawConfidence = acquire { frame.acquireRawDepthConfidenceImage() }?.let { img ->
            try {
                y8Median(img, norm[0], norm[1])
            } finally {
                img.close()
            }
        }
        val automaticValid = automaticDepth && (
            acquire { frame.acquireDepthImage16Bits() }?.let { img ->
                try {
                    depth16At(img, norm[0], norm[1]) > 0
                } finally {
                    img.close()
                }
            } ?: false
            )
        val range = if (!tracking) {
            null
        } else {
            try {
                frame.hitTest(tx, ty).firstOrNull { it.trackable is DepthPoint }?.let { hit ->
                    val a = hit.hitPose
                    val b = cam.pose
                    DepthGate.range(a.tx().toDouble(), a.ty().toDouble(), a.tz().toDouble(), b.tx().toDouble(), b.ty().toDouble(), b.tz().toDouble())
                }
            } catch (_: RuntimeException) {
                null
            }
        }
        when (val d = DepthGate.evaluate(tracking, freshness.changesInWindow(now), rawConfidence, automaticValid, range)) {
            is DistanceDecision.Available -> {
                stable.add(d, now)
                val done = stable.stable()
                if (done != null) {
                    main.post { finishAvailable(NativeDistanceMethod.ARCORE_DEPTH, done) }
                    return
                }
                showStatus(readingText(d))
            }
            is DistanceDecision.Unavailable -> {
                lastReason = d.reason
                showStatus(reasonText(d.reason))
            }
        }
        if (now - arStartedAt > AR_TIMEOUT_MS) {
            val reason = lastReason ?: DistanceReason.MOVE_PHONE_SLOWLY
            main.post { if (tier == Tier.AR) fallbackFromAr(reason) }
        }
    }

    private inline fun acquire(block: () -> Image): Image? = try {
        block()
    } catch (_: Exception) {
        null
    }

    private fun y8Median(img: Image, nx: Float, ny: Float): Double {
        val plane = img.planes[0]
        val buf = plane.buffer
        val cx = (nx * img.width).toInt().coerceIn(0, img.width - 1)
        val cy = (ny * img.height).toInt().coerceIn(0, img.height - 1)
        val values = IntArray(25)
        var k = 0
        for (dy in -2..2) for (dx in -2..2) {
            val x = (cx + dx).coerceIn(0, img.width - 1)
            val y = (cy + dy).coerceIn(0, img.height - 1)
            values[k++] = buf.get(y * plane.rowStride + x * plane.pixelStride).toInt() and 0xFF
        }
        values.sort()
        return values[12] / 255.0
    }

    private fun depth16At(img: Image, nx: Float, ny: Float): Int {
        val plane = img.planes[0]
        val buf = plane.buffer.order(ByteOrder.LITTLE_ENDIAN)
        val x = (nx * img.width).toInt().coerceIn(0, img.width - 1)
        val y = (ny * img.height).toInt().coerceIn(0, img.height - 1)
        return buf.getShort(y * plane.rowStride + x * plane.pixelStride).toInt() and 0xFFFF
    }

    // ---- Tier 2: focus distance -------------------------------------------------

    @SuppressLint("ClickableViewAccessibility")
    @androidx.annotation.OptIn(markerClass = [ExperimentalCamera2Interop::class])
    private fun startFocus() {
        if (finished) return
        tier = Tier.FOCUS
        closeUp.visibility = View.GONE
        val pv = PreviewView(this).apply {
            implementationMode = PreviewView.ImplementationMode.COMPATIBLE
            scaleType = PreviewView.ScaleType.FILL_CENTER
        }
        previewView = pv
        root.addView(pv, 0, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        pv.setOnTouchListener { v, e ->
            if (e.action == MotionEvent.ACTION_UP && v.width > 0 && v.height > 0) {
                targetX = (e.x / v.width).coerceIn(0.05f, 0.95f)
                targetY = (e.y / v.height).coerceIn(0.05f, 0.95f)
                reticle.set(targetX, targetY)
                focusAt(e.x, e.y)
            }
            true
        }
        showStatus(reasonText(DistanceReason.TAP_TO_FOCUS), force = true)
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener(
            {
                if (finished) return@addListener
                val p = try {
                    future.get()
                } catch (_: Exception) {
                    finishUnavailable(DistanceReason.MEASURE_FAILED)
                    return@addListener
                }
                provider = p
                val builder = Preview.Builder()
                Camera2Interop.Extender(builder).setSessionCaptureCallback(captureCallback)
                val pr = builder.build()
                pr.surfaceProvider = pv.surfaceProvider
                val cam = try {
                    p.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA, pr)
                } catch (_: Exception) {
                    finishUnavailable(DistanceReason.MEASURE_FAILED)
                    return@addListener
                }
                preview = pr
                camera = cam
                val info = Camera2CameraInfo.from(cam.cameraInfo)
                calibration = info.getCameraCharacteristic(CameraCharacteristics.LENS_INFO_FOCUS_DISTANCE_CALIBRATION)
                val focal = info.getCameraCharacteristic(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)?.firstOrNull()
                val aperture = info.getCameraCharacteristic(CameraCharacteristics.LENS_INFO_AVAILABLE_APERTURES)?.firstOrNull()
                val sensor = info.getCameraCharacteristic(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)
                optics = if (focal != null && aperture != null && sensor != null) {
                    FocusDistanceGate.Optics(
                        focal.toDouble(),
                        aperture.toDouble(),
                        FocusDistanceGate.circleOfConfusionMm(sensor.width.toDouble(), sensor.height.toDouble()),
                    )
                } else {
                    null
                }
                // First AF at the target once the preview is streaming.
                main.postDelayed({ if (tier == Tier.FOCUS) focusAt(targetX * pv.width, targetY * pv.height) }, 600)
            },
            mainExecutor,
        )
    }

    private fun focusAt(x: Float, y: Float) {
        val cam = camera ?: return
        val pv = previewView ?: return
        afPending = false
        pendingFocus = null
        val token = ++focusToken
        showStatus(getString(R.string.sense_measure_focusing), force = true)
        val point = pv.meteringPointFactory.createPoint(x, y)
        val action = FocusMeteringAction.Builder(point, FocusMeteringAction.FLAG_AF).disableAutoCancel().build()
        val future = cam.cameraControl.startFocusAndMetering(action)
        future.addListener(
            {
                if (token != focusToken || finished) return@addListener
                val ok = try {
                    future.get().isFocusSuccessful
                } catch (_: Exception) {
                    false
                }
                if (ok) {
                    afLockAwaitedSince = SystemClock.elapsedRealtime()
                    afPending = true
                } else {
                    onFocusDecision(token, DistanceDecision.Unavailable(DistanceReason.TAP_TO_FOCUS))
                }
            },
            mainExecutor,
        )
    }

    /** Camera thread: read the AF state and focus distance after the trigger completed. */
    private val captureCallback = object : CameraCaptureSession.CaptureCallback() {
        override fun onCaptureCompleted(session: CameraCaptureSession, request: CaptureRequest, result: TotalCaptureResult) {
            if (!afPending || finished) return
            val token = focusToken
            val state = result.get(CaptureResult.CONTROL_AF_STATE) ?: return
            val decision = when (state) {
                CaptureResult.CONTROL_AF_STATE_FOCUSED_LOCKED -> {
                    val base = optics
                    val o = base?.let {
                        FocusDistanceGate.Optics(
                            result.get(CaptureResult.LENS_FOCAL_LENGTH)?.toDouble() ?: it.focalLengthMm,
                            result.get(CaptureResult.LENS_APERTURE)?.toDouble() ?: it.aperture,
                            it.circleOfConfusionMm,
                        )
                    }
                    FocusDistanceGate.evaluate(true, result.get(CaptureResult.LENS_FOCUS_DISTANCE)?.toDouble(), calibration, o)
                }
                CaptureResult.CONTROL_AF_STATE_NOT_FOCUSED_LOCKED -> DistanceDecision.Unavailable(DistanceReason.TAP_TO_FOCUS)
                else -> if (SystemClock.elapsedRealtime() - afLockAwaitedSince > AF_LOCK_TIMEOUT_MS) {
                    DistanceDecision.Unavailable(DistanceReason.TAP_TO_FOCUS)
                } else {
                    return
                }
            }
            afPending = false
            main.post { onFocusDecision(token, decision) }
        }
    }

    private fun onFocusDecision(token: Int, d: DistanceDecision) {
        if (finished || token != focusToken) return
        when (d) {
            is DistanceDecision.Available -> {
                pendingFocus = d
                showStatus(readingText(d), force = true)
                // Short pause so the user sees the value; a new tap cancels it.
                main.postDelayed({ if (pendingFocus === d && token == focusToken) finishAvailable(NativeDistanceMethod.FOCUS_DISTANCE, d) }, 1200)
            }
            is DistanceDecision.Unavailable -> {
                lastReason = d.reason
                showStatus(reasonText(d.reason), force = true)
            }
        }
    }

    companion object {
        private const val EXTRA_TARGET_X = "sense.targetX"
        private const val EXTRA_TARGET_Y = "sense.targetY"
        private const val EXTRA_ARCORE = "sense.arcore"
        private const val EXTRA_FOCUS = "sense.focus"
        private const val EXTRA_METHOD = "sense.method"
        private const val EXTRA_METERS = "sense.meters"
        private const val EXTRA_LOW = "sense.low"
        private const val EXTRA_HIGH = "sense.high"
        private const val EXTRA_CONFIDENCE = "sense.confidence"
        private const val EXTRA_REASON = "sense.reason"

        /** Tier 1 gives up (then tier 2, if available) after this long. */
        const val AR_TIMEOUT_MS = 20_000L
        const val AF_LOCK_TIMEOUT_MS = 1_500L

        fun intent(context: Context, target: NativeBox?, arcore: Boolean, focus: Boolean): Intent =
            Intent(context, MeasureActivity::class.java)
                .putExtra(EXTRA_TARGET_X, target?.let { (it.left + it.width / 2).toFloat() } ?: 0.5f)
                .putExtra(EXTRA_TARGET_Y, target?.let { (it.top + it.height / 2).toFloat() } ?: 0.5f)
                .putExtra(EXTRA_ARCORE, arcore)
                .putExtra(EXTRA_FOCUS, focus)

        private fun unavailableIntent(reason: String) =
            Intent().putExtra(EXTRA_METHOD, NativeDistanceMethod.UNAVAILABLE.raw).putExtra(EXTRA_REASON, reason)

        fun unavailable(reason: String) = NativeDistance(NativeDistanceMethod.UNAVAILABLE, null, null, null, null, reason)

        /** Maps the activity result to the bridge type. */
        fun parse(data: Intent?): NativeDistance {
            if (data == null) return unavailable(DistanceReason.CANCELLED)
            val method = NativeDistanceMethod.ofRaw(data.getIntExtra(EXTRA_METHOD, NativeDistanceMethod.UNAVAILABLE.raw))
                ?: NativeDistanceMethod.UNAVAILABLE
            if (method == NativeDistanceMethod.UNAVAILABLE || !data.hasExtra(EXTRA_METERS)) {
                return unavailable(data.getStringExtra(EXTRA_REASON) ?: DistanceReason.CANCELLED)
            }
            return NativeDistance(
                method = method,
                meters = data.getDoubleExtra(EXTRA_METERS, 0.0),
                lowMeters = data.getDoubleExtra(EXTRA_LOW, 0.0),
                highMeters = data.getDoubleExtra(EXTRA_HIGH, 0.0),
                confidence = data.getDoubleExtra(EXTRA_CONFIDENCE, 0.0),
                reason = null,
            )
        }
    }
}

/** Target ring drawn over the camera image. */
private class Reticle(context: Context) : View(context) {
    private var nx = 0.5f
    private var ny = 0.5f
    private val density = context.resources.displayMetrics.density
    private val outer = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 5 * density
        color = Color.argb(160, 0, 0, 0)
    }
    private val inner = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 2.5f * density
        color = Color.WHITE
    }

    init {
        // Draw above the camera views added at index 0.
        translationZ = 1f
    }

    fun set(x: Float, y: Float) {
        nx = x
        ny = y
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        val cx = nx * width
        val cy = ny * height
        val r = 28 * density
        canvas.drawCircle(cx, cy, r, outer)
        canvas.drawCircle(cx, cy, r, inner)
        canvas.drawLine(cx - r / 3, cy, cx + r / 3, cy, inner)
        canvas.drawLine(cx, cy - r / 3, cx, cy + r / 3, inner)
    }
}
