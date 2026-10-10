package com.kernel.sense_ai

import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/**
 * Stage-0 motion: MAD-adaptive absolute difference against a running
 * background.
 *
 * - `d = |frame - background|`, threshold `max(minThresholdDn, k * 1.4826 * MAD)`
 *   where MAD is the median absolute deviation of the signed differences.
 * - More than [globalResetFraction] of pixels above threshold means a global
 *   change (exposure, torch, the phone moved): the background is reset and
 *   nothing is reported.
 * - Connected components with an area fraction in
 *   [[minAreaFraction], [maxAreaFraction]] are tracked; a track seen in at
 *   least [persistHits] of the last [persistWindow] frames is a candidate.
 *
 * Every threshold needs on-device calibration (docs/device-validation.md).
 */
class MotionDetector(
    val minThresholdDn: Double = 12.0,
    val madK: Double = 3.0,
    val globalResetFraction: Double = 0.05,
    val minAreaFraction: Double = 0.0002,
    val maxAreaFraction: Double = 0.02,
    val persistHits: Int = 3,
    val persistWindow: Int = 5,
    val backgroundRate: Float = 0.05f,
    val foregroundRate: Float = 0.02f,
    val warmupFrames: Int = 2,
    /** Track match radius as a fraction of the frame's long edge. */
    val matchRadiusFraction: Double = 0.08,
) {
    class Track(val id: Long) {
        var history = 0 // bit i = seen i frames ago
        var box = PixelBox(0, 0, 0, 0)
        var cx = 0.0
        var cy = 0.0
        var contrast = 0.0

        val hits: Int get() = Integer.bitCount(history)
    }

    class Result(
        val tracks: List<Track>,
        val globalReset: Boolean,
        val threshold: Double,
        val foregroundFraction: Double,
    )

    private var background: FloatArray? = null
    private var bgWidth = 0
    private var bgHeight = 0
    private var warmup = 0
    private var nextId = 1L
    private val tracks = ArrayList<Track>()
    private val histogram = IntArray(256)
    private val signedHistogram = IntArray(511)
    private var diff = FloatArray(0)
    private var mask = ByteArray(0)
    private val labeller = ComponentLabeller()

    /** Drops the background and all tracks (gyro motion, rebind, discard). */
    fun reset() {
        background = null
        tracks.clear()
        warmup = 0
    }

    fun process(frame: GrayFrame): Result {
        val n = frame.size
        val bg = background
        if (bg == null || bgWidth != frame.width || bgHeight != frame.height) {
            seed(frame)
            return Result(emptyList(), globalReset = false, threshold = minThresholdDn, foregroundFraction = 0.0)
        }
        if (diff.size < n) {
            diff = FloatArray(n)
            mask = ByteArray(n)
        }
        // Signed differences: median m, then MAD = median(|d - m|). A uniform
        // exposure shift has a large m but a small MAD, so it shows up as a
        // global change below instead of inflating the threshold.
        java.util.Arrays.fill(signedHistogram, 0)
        val px = frame.data
        for (i in 0 until n) {
            val d = (px[i].toInt() and 0xFF) - bg[i]
            diff[i] = d
            signedHistogram[(d.toInt() + 255).coerceIn(0, 510)]++
        }
        val m = histogramMedian(signedHistogram, n) - 255
        java.util.Arrays.fill(histogram, 0)
        for (i in 0 until n) histogram[min(255, abs(diff[i] - m.toFloat()).toInt())]++
        val mad = histogramMedian(histogram, n)
        val threshold = max(minThresholdDn, madK * 1.4826 * mad)
        for (i in 0 until n) diff[i] = abs(diff[i])
        var fg = 0
        for (i in 0 until n) {
            if (diff[i] > threshold) {
                mask[i] = 1
                fg++
            } else {
                mask[i] = 0
            }
        }
        val fgFraction = fg.toDouble() / n
        if (fgFraction > globalResetFraction) {
            seed(frame)
            return Result(emptyList(), globalReset = true, threshold = threshold, foregroundFraction = fgFraction)
        }
        // Selective running average: foreground pixels learn more slowly so a
        // small moving animal is not absorbed into the background at once.
        for (i in 0 until n) {
            val v = (px[i].toInt() and 0xFF).toFloat()
            val rate = if (mask[i].toInt() != 0) foregroundRate else backgroundRate
            bg[i] += rate * (v - bg[i])
        }
        if (warmup < warmupFrames) {
            warmup++
            return Result(emptyList(), globalReset = false, threshold = threshold, foregroundFraction = fgFraction)
        }
        val minArea = max(1, Math.ceil(minAreaFraction * n).toInt())
        val maxArea = (maxAreaFraction * n).toInt()
        val blobs = labeller.label(mask, frame.width, frame.height, diff, maxBlobArea = Int.MAX_VALUE)
            ?.filter { it.area in minArea..maxArea }
            .orEmpty()
        associate(blobs, frame, threshold)
        val persisted = tracks.filter { it.hits >= persistHits }
        return Result(persisted, globalReset = false, threshold = threshold, foregroundFraction = fgFraction)
    }

    private fun associate(blobs: List<Blob>, frame: GrayFrame, threshold: Double) {
        val radius = matchRadiusFraction * max(frame.width, frame.height)
        val windowMask = (1 shl persistWindow) - 1
        for (t in tracks) t.history = (t.history shl 1) and windowMask
        val matched = HashSet<Track>()
        // Largest blobs first so a big mover keeps its track.
        for (b in blobs.sortedByDescending { it.area }) {
            var best: Track? = null
            var bestDist = radius
            for (t in tracks) {
                if (t in matched) continue
                val d = hypot(t.cx - b.cx, t.cy - b.cy)
                if (d <= bestDist) {
                    bestDist = d
                    best = t
                }
            }
            val track = best ?: Track(nextId++).also { tracks.add(it) }
            matched.add(track)
            track.history = track.history or 1
            track.box = b.box
            track.cx = b.cx
            track.cy = b.cy
            track.contrast = b.meanStrength / threshold
        }
        tracks.removeAll { it.history == 0 }
    }

    private fun seed(frame: GrayFrame) {
        val n = frame.size
        val bg = background?.takeIf { it.size == n } ?: FloatArray(n)
        for (i in 0 until n) bg[i] = (frame.data[i].toInt() and 0xFF).toFloat()
        background = bg
        bgWidth = frame.width
        bgHeight = frame.height
        tracks.clear()
        warmup = 0
    }

    companion object {
        fun histogramMedian(histogram: IntArray, count: Int): Double {
            val half = (count + 1) / 2
            var acc = 0
            for (v in histogram.indices) {
                acc += histogram[v]
                if (acc >= half) return v.toDouble()
            }
            return 255.0
        }
    }
}
