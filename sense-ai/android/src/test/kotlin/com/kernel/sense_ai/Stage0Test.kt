package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class Stage0Test {
    private fun run(
        p: Stage0Pipeline,
        frame: GrayFrame,
        t: Long,
        gyro: Double? = 0.0,
        torchOn: Boolean = false,
        torchAt: Long = 0,
    ) = p.process(frame, gyro, torchOn, torchAt, nowMs = t, wallMs = 1_000_000 + t)

    @Test
    fun movingBlobIsDetectedAsMotion() {
        val p = Stage0Pipeline()
        var t = 0L
        repeat(4) { run(p, Frames.flat(100, noise = 3, seed = it.toLong()), t); t += 66 }
        var last: Stage0Result? = null
        var x = 40
        repeat(8) { i ->
            val frame = Frames.withRect(Frames.flat(100, noise = 3, seed = 100L + i), x, 100, 10, 10, 30)
            last = run(p, frame, t)
            t += 66
            x += 3
        }
        val motion = last!!.candidates.filter { it.kind == Stage0Kind.MOTION }
        assertEquals(1, motion.size, "one moving blob")
        val c = motion.single()
        val cx = (c.left + c.width / 2) * Frames.W
        val cy = (c.top + c.height / 2) * Frames.H
        assertTrue(cx in (x - 3.0)..(x + 13.0), "box follows the blob: cx=$cx")
        assertTrue(cy in 100.0..110.0, "cy=$cy")
        assertTrue(c.score > 0.0 && c.score <= 1.0)
    }

    @Test
    fun blobNeedsThreeOfFiveFrames() {
        val p = Stage0Pipeline()
        var t = 0L
        repeat(4) { run(p, Frames.flat(100, noise = 2, seed = it.toLong()), t); t += 66 }
        val r1 = run(p, Frames.withRect(Frames.flat(100, 2, 50), 60, 60, 8, 8, 20), t); t += 66
        val r2 = run(p, Frames.withRect(Frames.flat(100, 2, 51), 63, 60, 8, 8, 20), t); t += 66
        val r3 = run(p, Frames.withRect(Frames.flat(100, 2, 52), 66, 60, 8, 8, 20), t)
        assertTrue(r1.candidates.isEmpty())
        assertTrue(r2.candidates.isEmpty())
        assertEquals(1, r3.candidates.count { it.kind == Stage0Kind.MOTION })
    }

    @Test
    fun globalChangeResetsAndIsIgnored() {
        val p = Stage0Pipeline()
        var t = 0L
        repeat(5) { run(p, Frames.flat(100, noise = 3, seed = it.toLong()), t); t += 66 }
        // Exposure jump: every pixel brighter by 40 DN.
        val jump = run(p, Frames.flat(140, noise = 3, seed = 9), t); t += 66
        assertTrue(jump.globalReset)
        assertTrue(jump.candidates.isEmpty())
        repeat(6) {
            val r = run(p, Frames.flat(140, noise = 3, seed = 20L + it), t); t += 66
            assertTrue(r.candidates.isEmpty(), "new level is the new background")
        }
    }

    @Test
    fun staticNoiseGivesNothing() {
        val p = Stage0Pipeline()
        var t = 0L
        repeat(30) {
            val r = run(p, Frames.flat(90, noise = 4, seed = it.toLong()), t); t += 66
            assertTrue(r.candidates.none { c -> c.kind == Stage0Kind.MOTION })
        }
    }

    @Test
    fun gyroMotionSkipsFrameAndResetsBackground() {
        val p = Stage0Pipeline()
        var t = 0L
        repeat(4) { run(p, Frames.flat(100, noise = 2, seed = it.toLong()), t); t += 66 }
        var x = 40
        repeat(5) { i ->
            run(p, Frames.withRect(Frames.flat(100, 2, 30L + i), x, 80, 10, 10, 20), t); t += 66; x += 3
        }
        val gated = run(p, Frames.withRect(Frames.flat(100, 2, 40), x, 80, 10, 10, 20), t, gyro = 0.2); t += 66
        assertTrue(gated.gyroGated)
        assertTrue(gated.candidates.isEmpty())
        // After the reset the next still frame only re-seeds the background.
        x += 3
        val after = run(p, Frames.withRect(Frames.flat(100, 2, 41), x, 80, 10, 10, 20), t, gyro = 0.01)
        assertFalse(after.gyroGated)
        assertTrue(after.candidates.isEmpty())
    }

    @Test
    fun gyroAtGateIsNotGated() {
        val p = Stage0Pipeline()
        val r = run(p, Frames.flat(100), 0, gyro = 0.05)
        assertFalse(r.gyroGated)
        val noGyro = run(p, Frames.flat(100), 66, gyro = null)
        assertFalse(noGyro.gyroGated)
    }

    @Test
    fun darkSpeckClusterIsReportedWithLowWeight() {
        val p = Stage0Pipeline(speckEveryNFrames = 1)
        var frame = Frames.flat(150, noise = 2, seed = 3)
        val spots = listOf(100 to 100, 106 to 103, 111 to 98, 104 to 110, 115 to 107, 98 to 106)
        for ((x, y) in spots) frame = Frames.withRect(frame, x, y, 2, 2, 60)
        run(p, frame, 0)
        val r = run(p, frame, 66)
        val specks = r.candidates.filter { it.kind == Stage0Kind.DARK_SPECKS }
        assertEquals(1, specks.size)
        assertTrue(specks.single().score <= 0.5)
        val box = specks.single()
        assertTrue(box.left * Frames.W <= 98 && (box.left + box.width) * Frames.W >= 117)
    }

    @Test
    fun crackLineIsNotASpeckCluster() {
        val d = DarkSpeckDetector()
        var frame = Frames.flat(150, noise = 2, seed = 4)
        frame = Frames.withRect(frame, 50, 120, 120, 2, 60) // long thin dark line
        assertTrue(d.detect(frame).isEmpty())
    }

    @Test
    fun eyeshineAppearsWithTorchPulse() {
        val p = Stage0Pipeline()
        val off = Frames.flat(40, noise = 2, seed = 5)
        run(p, off, 0, torchOn = false)
        run(p, off, 66, torchOn = false)
        // Torch on at t = 100; two tiny retroreflective spots on a dim scene.
        var on = Frames.flat(60, noise = 2, seed = 6)
        on = Frames.withRect(on, 150, 100, 2, 2, 255)
        on = Frames.withRect(on, 162, 101, 2, 2, 255)
        val early = run(p, on, 150, torchOn = true, torchAt = 100)
        assertTrue(early.candidates.none { it.kind == Stage0Kind.EYESHINE }, "exposure still settling")
        val r = run(p, on, 300, torchOn = true, torchAt = 100)
        val eyes = r.candidates.filter { it.kind == Stage0Kind.EYESHINE }
        assertEquals(2, eyes.size)
        assertTrue(eyes.all { it.score > 0.8 }, "a pair scores higher")
        // Held for a while after the pulse ends.
        val later = run(p, off, 1500, torchOn = false)
        assertEquals(2, later.candidates.count { it.kind == Stage0Kind.EYESHINE })
        val gone = run(p, off, 5000, torchOn = false)
        assertEquals(0, gone.candidates.count { it.kind == Stage0Kind.EYESHINE })
    }

    @Test
    fun brightPatchOrStaticLightIsNotEyeshine() {
        val d = EyeshineDetector()
        // A lamp that is bright with and without the torch.
        val off = Frames.withRect(Frames.flat(40), 100, 100, 3, 3, 250)
        val on = Frames.withRect(Frames.flat(60), 100, 100, 3, 3, 255)
        assertTrue(d.detect(on, off).isEmpty())
        // Glare: a large lit patch.
        val glare = Frames.withRect(Frames.flat(60), 50, 50, 30, 30, 255)
        assertTrue(d.detect(glare, Frames.flat(40)).isEmpty())
    }

    @Test
    fun throttleCapsAtFiveHertz() {
        val th = CandidateThrottle()
        fun c(x: Double) = listOf(Stage0Candidate("motion-1", Stage0Kind.MOTION, 0.5, x, 0.1, 0.1, 0.1, 0))
        assertTrue(th.offer(c(0.1), 0))
        assertFalse(th.offer(c(0.2), 50))
        assertFalse(th.offer(c(0.3), 150))
        assertTrue(th.offer(c(0.3), 210), "pending change goes out at the next slot")
        assertFalse(th.offer(c(0.3), 500), "unchanged list waits for the heartbeat")
        assertTrue(th.offer(c(0.3), 1300))
    }

    @Test
    fun downsampleAndRotate() {
        val src = ByteArray(8 * 4) { (it * 4).toByte() }
        val small = Luma.downsample(src, 8, 4, rowStride = 8, factor = 2)
        assertEquals(4, small.width)
        assertEquals(2, small.height)
        assertEquals(((0 + 4 + 32 + 36) / 4), small[0, 0])
        val r = Luma.rotate(GrayFrame(3, 2, byteArrayOf(1, 2, 3, 4, 5, 6)), 90)
        assertEquals(2, r.width)
        assertEquals(3, r.height)
        // Clockwise: the bottom-left source pixel becomes top-left.
        assertEquals(4, r[0, 0])
        assertEquals(1, r[1, 0])
        assertEquals(6, r[0, 2])
        val back = Luma.rotate(Luma.rotate(Luma.rotate(r, 90), 90), 90)
        assertEquals(listOf<Byte>(1, 2, 3, 4, 5, 6), back.data.toList())
        assertEquals(2, Luma.factorFor(640))
    }
}
