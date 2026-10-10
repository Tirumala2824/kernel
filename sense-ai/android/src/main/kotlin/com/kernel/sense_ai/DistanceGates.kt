package com.kernel.sense_ai

import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/** Reason keys the app localizes when no distance is shown. */
object DistanceReason {
    const val ARCORE_UNSUPPORTED = "arcore_unsupported"
    const val MOVE_PHONE_SLOWLY = "move_phone_slowly"
    const val TAP_TO_FOCUS = "tap_to_focus"
    const val OUT_OF_RANGE = "out_of_range"

    /** The user closed the Measure screen. */
    const val CANCELLED = "cancelled"

    /** CAMERA permission is not granted. */
    const val CAMERA_PERMISSION = "camera_permission"

    /** No visible activity to open the Measure screen from, or it failed. */
    const val MEASURE_FAILED = "measure_failed"
}

sealed interface DistanceDecision {
    class Available(val meters: Double, val low: Double, val high: Double, val confidence: Double) : DistanceDecision
    class Unavailable(val reason: String) : DistanceDecision
}

/**
 * Counts how often the depth image timestamp changed within the last
 * [windowMs]. A stalled depth stream must not produce a distance.
 */
class DepthFreshness(val windowMs: Long = 1000) {
    private var lastTimestamp: Long? = null
    private val changes = ArrayDeque<Long>()

    fun record(depthTimestampNs: Long, nowMs: Long) {
        if (depthTimestampNs != lastTimestamp) {
            lastTimestamp = depthTimestampNs
            changes.addLast(nowMs)
        }
        prune(nowMs)
    }

    fun changesInWindow(nowMs: Long): Int {
        prune(nowMs)
        return changes.size
    }

    fun reset() {
        lastTimestamp = null
        changes.clear()
    }

    private fun prune(nowMs: Long) {
        while (changes.isNotEmpty() && nowMs - changes.first() > windowMs) changes.removeFirst()
    }
}

/**
 * Tier 1 gate (ARCore depth). A range is shown only when the camera is
 * TRACKING, the depth stream is fresh (timestamp changed at least
 * [MIN_FRESH_CHANGES] times in the last second), and the raw-depth
 * confidence at the target is at least [MIN_CONFIDENCE] (or AUTOMATIC
 * depth is valid there). The range must be [MIN_M]..[MAX_M].
 */
object DepthGate {
    const val MIN_M = 0.3
    const val MAX_M = 5.0
    const val MIN_CONFIDENCE = 0.5
    const val MIN_FRESH_CHANGES = 3

    fun evaluate(
        tracking: Boolean,
        freshChanges: Int,
        rawConfidence: Double?,
        automaticDepthValid: Boolean,
        rangeMeters: Double?,
    ): DistanceDecision {
        if (!tracking || freshChanges < MIN_FRESH_CHANGES) return DistanceDecision.Unavailable(DistanceReason.MOVE_PHONE_SLOWLY)
        val confident = (rawConfidence != null && rawConfidence >= MIN_CONFIDENCE) || automaticDepthValid
        if (!confident || rangeMeters == null || rangeMeters.isNaN() || rangeMeters <= 0.0) {
            return DistanceDecision.Unavailable(DistanceReason.MOVE_PHONE_SLOWLY)
        }
        if (rangeMeters < MIN_M || rangeMeters > MAX_M) return DistanceDecision.Unavailable(DistanceReason.OUT_OF_RANGE)
        val c = (rawConfidence ?: MIN_CONFIDENCE).coerceIn(0.0, 1.0)
        // Error band: relative error grows as confidence falls, plus a
        // quadratic term for range (stereo-like depth). Needs calibration.
        val half = rangeMeters * (0.03 + 0.12 * (1.0 - c)) + 0.005 * rangeMeters * rangeMeters
        return DistanceDecision.Available(rangeMeters, max(0.0, rangeMeters - half), rangeMeters + half, c)
    }

    /** Euclidean distance between two pose translations (metres). */
    fun range(ax: Double, ay: Double, az: Double, bx: Double, by: Double, bz: Double): Double {
        val dx = ax - bx
        val dy = ay - by
        val dz = az - bz
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
}

/**
 * Collects passing tier-1 readings and reports a final value once enough
 * of them in the last [windowMs] agree within [maxSpread].
 */
class StableReading(val windowMs: Long = 1000, val minReadings: Int = 10, val maxSpread: Double = 0.06) {
    private class R(val at: Long, val d: DistanceDecision.Available)

    private val readings = ArrayDeque<R>()

    fun add(reading: DistanceDecision.Available, nowMs: Long) {
        readings.addLast(R(nowMs, reading))
        while (readings.isNotEmpty() && nowMs - readings.first().at > windowMs) readings.removeFirst()
    }

    fun clear() = readings.clear()

    fun stable(): DistanceDecision.Available? {
        if (readings.size < minReadings) return null
        val sorted = readings.map { it.d }.sortedBy { it.meters }
        val median = sorted[sorted.size / 2]
        val spread = (sorted.last().meters - sorted.first().meters) / median.meters
        if (spread > maxSpread) return null
        return DistanceDecision.Available(
            median.meters,
            min(median.low, sorted.first().meters),
            max(median.high, sorted.last().meters),
            sorted.map { it.confidence }.average(),
        )
    }
}

/**
 * Tier 2 gate (Camera2 focus distance). Used only with AF FOCUSED_LOCKED
 * on the target and a lens calibration of APPROXIMATE or CALIBRATED;
 * LENS_FOCUS_DISTANCE is in diopters (metres = 1 / D) and only 0.1-0.6 m
 * is shown. Low/high come from the depth-of-field band around the focus
 * distance.
 */
object FocusDistanceGate {
    const val MIN_M = 0.1
    const val MAX_M = 0.6

    /** CameraMetadata.LENS_INFO_FOCUS_DISTANCE_CALIBRATION_* values. */
    const val CALIBRATION_UNCALIBRATED = 0
    const val CALIBRATION_APPROXIMATE = 1
    const val CALIBRATION_CALIBRATED = 2

    /** Extra relative band for APPROXIMATE calibration. Needs calibration. */
    const val APPROXIMATE_EXTRA = 0.10

    fun calibrationUsable(calibration: Int?): Boolean =
        calibration == CALIBRATION_APPROXIMATE || calibration == CALIBRATION_CALIBRATED

    class Optics(val focalLengthMm: Double, val aperture: Double, val circleOfConfusionMm: Double)

    fun evaluate(afLocked: Boolean, diopters: Double?, calibration: Int?, optics: Optics?): DistanceDecision {
        if (!calibrationUsable(calibration)) return DistanceDecision.Unavailable(DistanceReason.ARCORE_UNSUPPORTED)
        if (!afLocked) return DistanceDecision.Unavailable(DistanceReason.TAP_TO_FOCUS)
        if (diopters == null || diopters.isNaN() || diopters <= 0.0) return DistanceDecision.Unavailable(DistanceReason.OUT_OF_RANGE)
        val meters = 1.0 / diopters
        // 1/D round-off must not push the inclusive limits out of range.
        if (meters < MIN_M - 1e-9 || meters > MAX_M + 1e-9) return DistanceDecision.Unavailable(DistanceReason.OUT_OF_RANGE)
        var (near, far) = if (optics != null) depthOfField(meters, optics) else (meters * 0.85 to meters * 1.15)
        val calibrated = calibration == CALIBRATION_CALIBRATED
        if (!calibrated) {
            near *= 1.0 - APPROXIMATE_EXTRA
            far *= 1.0 + APPROXIMATE_EXTRA
        }
        val relBand = (far - near) / meters
        val confidence = (if (calibrated) 0.8 else 0.5) * (1.0 - relBand / 2.0).coerceIn(0.2, 1.0)
        return DistanceDecision.Available(meters, near, far, confidence)
    }

    /**
     * Near and far limits of acceptable sharpness for focus distance [s]
     * metres, via the hyperfocal distance H = f^2 / (N c) + f.
     */
    fun depthOfField(s: Double, optics: Optics): Pair<Double, Double> {
        val f = optics.focalLengthMm / 1000.0
        val c = optics.circleOfConfusionMm / 1000.0
        val n = optics.aperture
        if (f <= 0 || c <= 0 || n <= 0) return s * 0.85 to s * 1.15
        val h = f * f / (n * c) + f
        val near = s * (h - f) / (h + s - 2 * f)
        val far = if (s < h) s * (h - f) / (h - s) else Double.POSITIVE_INFINITY
        return near to far
    }

    /** Circle of confusion from the sensor diagonal (d / 1500, the usual rule). */
    fun circleOfConfusionMm(sensorWidthMm: Double, sensorHeightMm: Double): Double =
        sqrt(sensorWidthMm * sensorWidthMm + sensorHeightMm * sensorHeightMm) / 1500.0
}
