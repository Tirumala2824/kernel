package com.kernel.sense_ai

/** Ordered from cool to hot. */
enum class ThermalLevel { NORMAL, REDUCED_FPS, NO_STAGE1, PAUSED }

/**
 * Maps PowerManager.getThermalHeadroom readings to a step-down level:
 * 0.85 lowers the Stage-0 rate, 0.95 stops Stage 1, 1.0 pauses the camera.
 * Stepping back down needs the headroom to fall [hysteresis] below the
 * threshold that raised it, so the level does not flap.
 */
object ThermalPolicy {
    const val REDUCED_FPS_AT = 0.85
    const val NO_STAGE1_AT = 0.95
    const val PAUSE_AT = 1.0
    const val HYSTERESIS = 0.03

    /** At most one headroom poll per this interval (platform guidance). */
    const val POLL_INTERVAL_MS = 10_000L

    fun raw(headroom: Double): ThermalLevel = when {
        headroom >= PAUSE_AT -> ThermalLevel.PAUSED
        headroom >= NO_STAGE1_AT -> ThermalLevel.NO_STAGE1
        headroom >= REDUCED_FPS_AT -> ThermalLevel.REDUCED_FPS
        else -> ThermalLevel.NORMAL
    }

    /** A null or NaN [headroom] (unsupported, or polled too often) keeps [previous]. */
    fun next(headroom: Double?, previous: ThermalLevel): ThermalLevel {
        if (headroom == null || headroom.isNaN()) return previous
        val up = raw(headroom)
        if (up >= previous) return up
        // Cooling: only step down once clearly below the threshold.
        return raw(headroom + HYSTERESIS).coerceAtMost(previous)
    }

    /** Stage-0 frames per second at [level]; 0 = camera paused. */
    fun analysisFps(level: ThermalLevel): Double = when (level) {
        ThermalLevel.NORMAL -> 15.0
        ThermalLevel.REDUCED_FPS, ThermalLevel.NO_STAGE1 -> 5.0
        ThermalLevel.PAUSED -> 0.0
    }
}
