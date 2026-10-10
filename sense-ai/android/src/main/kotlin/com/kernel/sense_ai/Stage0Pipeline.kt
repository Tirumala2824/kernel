package com.kernel.sense_ai

import kotlin.math.min

enum class Stage0Kind { MOTION, DARK_SPECKS, EYESHINE }

/** Box normalised to the upright analysis frame (0..1, origin top-left). */
class Stage0Candidate(
    val id: String,
    val kind: Stage0Kind,
    val score: Double,
    val left: Double,
    val top: Double,
    val width: Double,
    val height: Double,
    val detectedAtEpochMs: Long,
)

class Stage0Result(
    val candidates: List<Stage0Candidate>,
    val gyroGated: Boolean,
    val globalReset: Boolean,
)

/**
 * Stage 0 on the downsampled upright Y plane (about 320x240): gyro gating,
 * then motion, dark specks and torch-pulse eyeshine. Pure JVM; the camera
 * analyzer feeds it one frame at a time on a single thread.
 */
class Stage0Pipeline(
    /** Frames are skipped and the background reset above this rotation rate. */
    val gyroGateRadPerSec: Double = 0.05,
    val speckEveryNFrames: Int = 3,
    /** Eyeshine is looked for this long after the torch turns on. */
    val eyeshineFromMs: Long = 150,
    val eyeshineUntilMs: Long = 2000,
    /** An eyeshine candidate stays listed this long after it was seen. */
    val eyeshineHoldMs: Long = 3000,
    /** The torch-off reference must be at most this old when the pulse starts. */
    val referenceMaxAgeMs: Long = 3000,
    private val motion: MotionDetector = MotionDetector(),
    private val specks: DarkSpeckDetector = DarkSpeckDetector(),
    private val eyeshine: EyeshineDetector = EyeshineDetector(),
) {
    private class HeldSpot(val id: String, var box: PixelBox, var score: Double, var until: Long, val seenAt: Long)

    private var frameCount = 0L
    private var speckClusters: List<DarkSpeckDetector.Cluster> = emptyList()
    private var offReference: GrayFrame? = null
    private var offReferenceAt = 0L
    private val held = ArrayList<HeldSpot>()
    private var nextEyeshine = 1L
    private val firstSeen = HashMap<String, Long>()

    fun reset() {
        motion.reset()
        specks.reset()
        speckClusters = emptyList()
        offReference = null
        held.clear()
        firstSeen.clear()
    }

    /**
     * [gyroRadPerSec] is the peak rotation rate since the last frame, or
     * null when the device has no gyroscope. [torchChangedAtMs] and [nowMs]
     * are on the same monotonic clock; [wallMs] stamps candidates.
     */
    fun process(
        frame: GrayFrame,
        gyroRadPerSec: Double?,
        torchOn: Boolean,
        torchChangedAtMs: Long,
        nowMs: Long,
        wallMs: Long,
    ): Stage0Result {
        if (gyroRadPerSec != null && gyroRadPerSec > gyroGateRadPerSec) {
            // The phone is rotating: every pixel moves, so start over.
            reset()
            return Stage0Result(emptyList(), gyroGated = true, globalReset = false)
        }
        frameCount++

        if (!torchOn) {
            offReference = frame.copy()
            offReferenceAt = nowMs
        } else {
            val sinceOn = nowMs - torchChangedAtMs
            val ref = offReference
            if (ref != null && sinceOn in eyeshineFromMs..eyeshineUntilMs &&
                offReferenceAt <= torchChangedAtMs && torchChangedAtMs - offReferenceAt <= referenceMaxAgeMs
            ) {
                for (spot in eyeshine.detect(frame, ref)) holdSpot(spot, nowMs)
            }
        }
        held.removeAll { it.until < nowMs }

        val m = motion.process(frame)
        if (frameCount % speckEveryNFrames == 0L || m.globalReset) {
            speckClusters = if (m.globalReset) {
                specks.reset()
                emptyList()
            } else {
                specks.process(frame)
            }
        }

        val w = frame.width.toDouble()
        val h = frame.height.toDouble()
        val out = ArrayList<Stage0Candidate>()
        for (t in m.tracks) {
            val id = "motion-${t.id}"
            val score = (t.hits.toDouble() / motion.persistWindow) * min(1.0, t.contrast / 3.0)
            out.add(candidate(id, Stage0Kind.MOTION, score, t.box, w, h, wallMs))
        }
        for (c in speckClusters) {
            out.add(candidate("specks-${c.id}", Stage0Kind.DARK_SPECKS, c.score, c.box, w, h, wallMs))
        }
        for (s in held) {
            out.add(candidate(s.id, Stage0Kind.EYESHINE, s.score, s.box.expand(2, frame.width, frame.height), w, h, wallMs))
        }
        val live = out.mapTo(HashSet()) { it.id }
        firstSeen.keys.retainAll(live)
        return Stage0Result(out, gyroGated = false, globalReset = m.globalReset)
    }

    private fun holdSpot(spot: EyeshineDetector.Spot, nowMs: Long) {
        val existing = held.firstOrNull { it.box.expand(2, Int.MAX_VALUE, Int.MAX_VALUE).iou(spot.box) > 0.0 }
        if (existing != null) {
            existing.box = spot.box
            existing.score = maxOf(existing.score, spot.score)
            existing.until = nowMs + eyeshineHoldMs
        } else {
            held.add(HeldSpot("eyeshine-${nextEyeshine++}", spot.box, spot.score, nowMs + eyeshineHoldMs, nowMs))
        }
    }

    private fun candidate(
        id: String,
        kind: Stage0Kind,
        score: Double,
        box: PixelBox,
        w: Double,
        h: Double,
        wallMs: Long,
    ): Stage0Candidate {
        val seen = firstSeen.getOrPut(id) { wallMs }
        return Stage0Candidate(
            id = id,
            kind = kind,
            score = score.coerceIn(0.0, 1.0),
            left = box.minX / w,
            top = box.minY / h,
            width = box.width / w,
            height = box.height / h,
            detectedAtEpochMs = seen,
        )
    }
}

/**
 * Throttles candidate lists to at most one per [minIntervalMs] (5 Hz). A
 * changed list is sent at the next allowed time; an unchanged one is resent
 * every [heartbeatMs] so listeners know the pipeline is alive.
 */
class CandidateThrottle(val minIntervalMs: Long = 200, val heartbeatMs: Long = 1000) {
    private var lastEmitAt = Long.MIN_VALUE / 2
    private var lastSignature: String? = null
    private var pending = false

    fun offer(candidates: List<Stage0Candidate>, nowMs: Long, force: Boolean = false): Boolean {
        val signature = candidates.joinToString("|") {
            "${it.id}:${(it.left * 100).toInt()},${(it.top * 100).toInt()},${(it.width * 100).toInt()},${(it.height * 100).toInt()}"
        }
        if (signature != lastSignature) pending = true
        lastSignature = signature
        val since = nowMs - lastEmitAt
        if (since < minIntervalMs) return false
        if (pending || force || since >= heartbeatMs) {
            pending = false
            lastEmitAt = nowMs
            return true
        }
        return false
    }

    fun reset() {
        lastEmitAt = Long.MIN_VALUE / 2
        lastSignature = null
        pending = false
    }
}
