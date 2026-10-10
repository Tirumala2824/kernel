package com.kernel.sense_ai

import java.util.Random

/** Synthetic luma frames for Stage-0 tests (test sources only). */
object Frames {
    const val W = 320
    const val H = 240

    fun flat(level: Int, noise: Int = 0, seed: Long = 1, w: Int = W, h: Int = H): GrayFrame {
        val rnd = Random(seed)
        val data = ByteArray(w * h) { clamp(level + if (noise > 0) rnd.nextInt(2 * noise + 1) - noise else 0) }
        return GrayFrame(w, h, data)
    }

    fun withRect(base: GrayFrame, x: Int, y: Int, rw: Int, rh: Int, level: Int): GrayFrame {
        val f = base.copy()
        for (yy in y until y + rh) for (xx in x until x + rw) {
            if (xx in 0 until f.width && yy in 0 until f.height) f.data[yy * f.width + xx] = clamp(level)
        }
        return f
    }

    fun clamp(v: Int): Byte = v.coerceIn(0, 255).toByte()
}
