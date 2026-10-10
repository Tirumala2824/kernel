package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class DistanceGatesTest {
    private val optics = FocusDistanceGate.Optics(focalLengthMm = 6.5, aperture = 1.88, circleOfConfusionMm = 0.008)

    private fun reason(d: DistanceDecision) = (d as DistanceDecision.Unavailable).reason

    @Test
    fun focusDistanceInsideRangeIsShownWithDofBand() {
        val d = FocusDistanceGate.evaluate(true, 2.5, FocusDistanceGate.CALIBRATION_CALIBRATED, optics)
        val a = d as DistanceDecision.Available
        assertEquals(0.4, a.meters, 1e-9)
        assertTrue(a.low < 0.4 && a.high > 0.4)
        assertTrue(a.low > 0.3 && a.high < 0.55, "band ${a.low}..${a.high}")
        assertTrue(a.confidence in 0.0..1.0)
    }

    @Test
    fun approximateCalibrationWidensTheBand() {
        val cal = FocusDistanceGate.evaluate(true, 2.5, FocusDistanceGate.CALIBRATION_CALIBRATED, optics) as DistanceDecision.Available
        val approx = FocusDistanceGate.evaluate(true, 2.5, FocusDistanceGate.CALIBRATION_APPROXIMATE, optics) as DistanceDecision.Available
        assertTrue(approx.low < cal.low && approx.high > cal.high)
        assertTrue(approx.confidence < cal.confidence)
    }

    @Test
    fun focusRangeFilter() {
        val cal = FocusDistanceGate.CALIBRATION_CALIBRATED
        // 0.1 m and 0.6 m are the inclusive limits.
        assertTrue(FocusDistanceGate.evaluate(true, 10.0, cal, optics) is DistanceDecision.Available)
        assertTrue(FocusDistanceGate.evaluate(true, 1.0 / 0.6, cal, optics) is DistanceDecision.Available)
        assertEquals(DistanceReason.OUT_OF_RANGE, reason(FocusDistanceGate.evaluate(true, 1.0, cal, optics)), "1 m")
        assertEquals(DistanceReason.OUT_OF_RANGE, reason(FocusDistanceGate.evaluate(true, 12.0, cal, optics)), "8 cm")
        assertEquals(DistanceReason.OUT_OF_RANGE, reason(FocusDistanceGate.evaluate(true, 0.0, cal, optics)), "infinity")
        assertEquals(DistanceReason.OUT_OF_RANGE, reason(FocusDistanceGate.evaluate(true, null, cal, optics)))
    }

    @Test
    fun focusNeedsAfLockAndCalibration() {
        assertEquals(
            DistanceReason.TAP_TO_FOCUS,
            reason(FocusDistanceGate.evaluate(false, 2.5, FocusDistanceGate.CALIBRATION_CALIBRATED, optics)),
        )
        assertEquals(
            DistanceReason.ARCORE_UNSUPPORTED,
            reason(FocusDistanceGate.evaluate(true, 2.5, FocusDistanceGate.CALIBRATION_UNCALIBRATED, optics)),
        )
        assertTrue(!FocusDistanceGate.calibrationUsable(null))
    }

    @Test
    fun depthOfFieldMatchesHyperfocalFormula() {
        val (near, far) = FocusDistanceGate.depthOfField(0.3, optics)
        // H = 6.5^2 / (1.88 * 0.008) + 6.5 mm = 2815.7 mm
        val h = 2.81568
        val f = 0.0065
        assertEquals(0.3 * (h - f) / (h + 0.3 - 2 * f), near, 1e-3)
        assertEquals(0.3 * (h - f) / (h - 0.3), far, 1e-3)
        assertEquals(43.27 / 1500.0, FocusDistanceGate.circleOfConfusionMm(36.0, 24.0), 1e-3)
    }

    @Test
    fun arcoreGateNeedsTrackingFreshnessAndConfidence() {
        assertEquals(DistanceReason.MOVE_PHONE_SLOWLY, reason(DepthGate.evaluate(false, 10, 0.9, false, 1.0)), "not tracking")
        assertEquals(DistanceReason.MOVE_PHONE_SLOWLY, reason(DepthGate.evaluate(true, 2, 0.9, false, 1.0)), "stale depth")
        assertEquals(DistanceReason.MOVE_PHONE_SLOWLY, reason(DepthGate.evaluate(true, 3, 0.49, false, 1.0)), "low confidence")
        assertEquals(DistanceReason.MOVE_PHONE_SLOWLY, reason(DepthGate.evaluate(true, 3, null, false, 1.0)), "no confidence")
        assertEquals(DistanceReason.MOVE_PHONE_SLOWLY, reason(DepthGate.evaluate(true, 3, 0.9, false, null)), "no hit")
        val ok = DepthGate.evaluate(true, 3, 0.5, false, 1.2) as DistanceDecision.Available
        assertEquals(1.2, ok.meters, 1e-9)
        assertTrue(ok.low < 1.2 && ok.high > 1.2)
        assertTrue(DepthGate.evaluate(true, 3, 0.2, true, 1.2) is DistanceDecision.Available, "AUTOMATIC depth valid")
    }

    @Test
    fun arcoreRangeLimits() {
        assertEquals(DistanceReason.OUT_OF_RANGE, reason(DepthGate.evaluate(true, 5, 0.9, false, 0.25)))
        assertEquals(DistanceReason.OUT_OF_RANGE, reason(DepthGate.evaluate(true, 5, 0.9, false, 5.5)))
        assertTrue(DepthGate.evaluate(true, 5, 0.9, false, 0.3) is DistanceDecision.Available)
        assertTrue(DepthGate.evaluate(true, 5, 0.9, false, 5.0) is DistanceDecision.Available)
        val hi = DepthGate.evaluate(true, 5, 1.0, false, 2.0) as DistanceDecision.Available
        val lo = DepthGate.evaluate(true, 5, 0.5, false, 2.0) as DistanceDecision.Available
        assertTrue(lo.high - lo.low > hi.high - hi.low, "lower confidence, wider band")
        assertEquals(5.0, DepthGate.range(1.0, 2.0, 3.0, 4.0, 6.0, 3.0), 1e-9)
    }

    @Test
    fun freshnessCountsTimestampChangesInTheLastSecond() {
        val f = DepthFreshness()
        f.record(100, 0)
        f.record(100, 30) // same depth image again
        f.record(100, 60)
        assertEquals(1, f.changesInWindow(60))
        f.record(200, 300)
        f.record(300, 600)
        assertEquals(3, f.changesInWindow(600))
        // The first change ages out after a second.
        assertEquals(2, f.changesInWindow(1100))
        f.record(300, 1500)
        assertEquals(1, f.changesInWindow(1500), "a stalled stream goes stale")
    }

    @Test
    fun stableReadingNeedsAgreement() {
        val s = StableReading(minReadings = 5)
        repeat(4) { s.add(DistanceDecision.Available(1.0, 0.95, 1.05, 0.8), it * 50L) }
        assertEquals(null, s.stable())
        s.add(DistanceDecision.Available(1.02, 0.97, 1.07, 0.8), 250)
        assertEquals(1.0, s.stable()!!.meters, 1e-9)
        s.add(DistanceDecision.Available(1.5, 1.4, 1.6, 0.8), 300)
        assertEquals(null, s.stable(), "an outlier breaks agreement")
    }

    @Test
    fun thermalStepDownWithHysteresis() {
        var level = ThermalLevel.NORMAL
        level = ThermalPolicy.next(0.5, level); assertEquals(ThermalLevel.NORMAL, level)
        level = ThermalPolicy.next(0.86, level); assertEquals(ThermalLevel.REDUCED_FPS, level)
        level = ThermalPolicy.next(0.95, level); assertEquals(ThermalLevel.NO_STAGE1, level)
        level = ThermalPolicy.next(1.0, level); assertEquals(ThermalLevel.PAUSED, level)
        level = ThermalPolicy.next(0.98, level); assertEquals(ThermalLevel.PAUSED, level, "hysteresis")
        level = ThermalPolicy.next(Double.NaN, level); assertEquals(ThermalLevel.PAUSED, level, "NaN keeps the level")
        level = ThermalPolicy.next(0.9, level); assertEquals(ThermalLevel.REDUCED_FPS, level)
        level = ThermalPolicy.next(0.83, level); assertEquals(ThermalLevel.REDUCED_FPS, level)
        level = ThermalPolicy.next(0.8, level); assertEquals(ThermalLevel.NORMAL, level)
        level = ThermalPolicy.next(null, level); assertEquals(ThermalLevel.NORMAL, level)
        assertEquals(0.0, ThermalPolicy.analysisFps(ThermalLevel.PAUSED))
        assertTrue(ThermalPolicy.analysisFps(ThermalLevel.REDUCED_FPS) < ThermalPolicy.analysisFps(ThermalLevel.NORMAL))
    }
}
