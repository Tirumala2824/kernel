package com.kernel.sense_ai

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Session
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * Run-time distance capability. Nothing is assumed from the model name:
 * the global iQOO 15 (I2501) is not on the ARCore supported list, so ARCore
 * availability and depth support are always checked on the device.
 *
 * ArCoreApk.checkAvailabilityAsync may ask the Play Store (by IPC) about
 * the device when ARCore is not installed; this process makes no network
 * call and never requests an ARCore install.
 */
object DistanceProbe {
    const val REASON_ARCORE_NOT_INSTALLED = "arcore_not_installed"

    class ArDepth(val supported: Boolean, val automatic: Boolean, val reason: String?)

    suspend fun capability(context: Context): NativeDistanceCapability {
        val ar = arDepth(context)
        val focus = focusDistanceSupported(context)
        val reason = when {
            ar.supported -> null
            focus -> ar.reason
            else -> DistanceReason.ARCORE_UNSUPPORTED
        }
        return NativeDistanceCapability(arcoreDepth = ar.supported, focusDistance = focus, reason = reason)
    }

    suspend fun arDepth(context: Context): ArDepth {
        val availability = suspendCancellableCoroutine<ArCoreApk.Availability> { cont ->
            try {
                ArCoreApk.getInstance().checkAvailabilityAsync(context) { a -> if (cont.isActive) cont.resume(a) }
            } catch (_: Throwable) {
                if (cont.isActive) cont.resume(ArCoreApk.Availability.UNKNOWN_ERROR)
            }
        }
        when (availability) {
            ArCoreApk.Availability.SUPPORTED_INSTALLED -> Unit
            ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD,
            ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED,
            -> return ArDepth(false, false, REASON_ARCORE_NOT_INSTALLED)
            else -> return ArDepth(false, false, DistanceReason.ARCORE_UNSUPPORTED)
        }
        // Installed is not enough: depth needs a session on this device.
        var session: Session? = null
        return try {
            val s = Session(context)
            session = s
            val automatic = s.isDepthModeSupported(Config.DepthMode.AUTOMATIC)
            val raw = s.isDepthModeSupported(Config.DepthMode.RAW_DEPTH_ONLY)
            if (automatic || raw) ArDepth(true, automatic, null) else ArDepth(false, false, DistanceReason.ARCORE_UNSUPPORTED)
        } catch (_: Exception) {
            ArDepth(false, false, DistanceReason.ARCORE_UNSUPPORTED)
        } catch (_: LinkageError) {
            ArDepth(false, false, DistanceReason.ARCORE_UNSUPPORTED)
        } finally {
            try {
                session?.close()
            } catch (_: RuntimeException) {
                // Nothing to release.
            }
        }
    }

    /** First back-facing camera, the one CameraX's DEFAULT_BACK_CAMERA picks. */
    fun backCameraId(manager: CameraManager): String? = try {
        manager.cameraIdList.firstOrNull { id ->
            manager.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
        }
    } catch (_: Exception) {
        null
    }

    /**
     * Focus distance is usable only with an APPROXIMATE or CALIBRATED lens
     * and a focusing (not fixed-focus) camera that reaches 0.6 m or closer.
     */
    fun focusDistanceSupported(context: Context): Boolean {
        val manager = context.getSystemService(CameraManager::class.java) ?: return false
        val id = backCameraId(manager) ?: return false
        return try {
            val ch = manager.getCameraCharacteristics(id)
            val calibration = ch.get(CameraCharacteristics.LENS_INFO_FOCUS_DISTANCE_CALIBRATION)
            val minFocusDiopters = ch.get(CameraCharacteristics.LENS_INFO_MINIMUM_FOCUS_DISTANCE) ?: 0f
            FocusDistanceGate.calibrationUsable(calibration) && minFocusDiopters >= 1f / FocusDistanceGate.MAX_M.toFloat()
        } catch (_: Exception) {
            false
        }
    }
}
