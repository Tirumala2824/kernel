package com.kernel.sense_ai

import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** Integer rectangle, [left, right) x [top, bottom). */
data class PixelRect(val left: Int, val top: Int, val right: Int, val bottom: Int) {
    val width: Int get() = right - left
    val height: Int get() = bottom - top
}

/** A planned crop: where to cut (upright pixels) and how big to encode it. */
class TilePlan(val candidateId: String, val region: PixelRect, val outputSide: Int)

/**
 * Tile geometry for captureStill, in upright full-resolution pixels.
 *
 * - Candidate tile: a square centred on the box, [contextScale] times its
 *   long side, at least [minRegionSide] px, clamped inside the image.
 * - No candidates: a grid of overlapping squares, [gridColumns] across the
 *   short edge.
 * - Output tiles are [MIN_TILE]..[MAX_TILE] px and never upscaled beyond the
 *   region.
 */
object TilePlanner {
    const val MIN_TILE = 512
    const val MAX_TILE = 768
    const val CONTEXT_LONG_EDGE = 1024

    fun forBox(
        candidateId: String,
        left: Double,
        top: Double,
        width: Double,
        height: Double,
        imageW: Int,
        imageH: Int,
        contextScale: Double = 2.5,
        minRegionSide: Int = MIN_TILE,
    ): TilePlan {
        val shortEdge = min(imageW, imageH)
        val boxSide = max(width * imageW, height * imageH)
        val side = (boxSide * contextScale).roundToInt().coerceIn(min(minRegionSide, shortEdge), shortEdge)
        val cx = (left + width / 2) * imageW
        val cy = (top + height / 2) * imageH
        val l = (cx - side / 2.0).roundToInt().coerceIn(0, imageW - side)
        val t = (cy - side / 2.0).roundToInt().coerceIn(0, imageH - side)
        val region = PixelRect(l, t, l + side, t + side)
        return TilePlan(candidateId, region, outputSide(side))
    }

    fun grid(imageW: Int, imageH: Int, gridColumns: Int = 2): List<TilePlan> {
        val shortEdge = min(imageW, imageH)
        val longEdge = max(imageW, imageH)
        val side = shortEdge / gridColumns
        val along = ceil(longEdge / side.toDouble()).toInt()
        val portrait = imageH >= imageW
        val plans = ArrayList<TilePlan>()
        for (r in 0 until along) {
            for (c in 0 until gridColumns) {
                val a = if (along == 1) 0 else ((longEdge - side) * r / (along - 1).toDouble()).roundToInt()
                val b = c * side
                val rect = if (portrait) PixelRect(b, a, b + side, a + side) else PixelRect(a, b, a + side, b + side)
                val row = if (portrait) r else c
                val col = if (portrait) c else r
                plans.add(TilePlan("grid-r${row}c$col", rect, outputSide(side)))
            }
        }
        return plans
    }

    fun outputSide(regionSide: Int): Int = if (regionSide < MIN_TILE) regionSide else regionSide.coerceAtMost(MAX_TILE)

    /** Largest power-of-two decode subsample that keeps at least [targetSide] px. */
    fun sampleSize(regionSide: Int, targetSide: Int): Int {
        var s = 1
        while (regionSide / (s * 2) >= targetSide) s *= 2
        return s
    }

    /** Upright size of a [w] x [h] encoded image that needs [rotationDegrees] clockwise. */
    fun uprightSize(w: Int, h: Int, rotationDegrees: Int): Pair<Int, Int> =
        if (normalize(rotationDegrees) % 180 == 0) w to h else h to w

    /**
     * Maps an upright rect back to the encoded (sensor-oriented) image of
     * size [encW] x [encH], which becomes upright after rotating clockwise
     * by [rotationDegrees].
     */
    fun uprightToEncoded(rect: PixelRect, rotationDegrees: Int, encW: Int, encH: Int): PixelRect =
        when (normalize(rotationDegrees)) {
            0 -> rect
            90 -> PixelRect(rect.top, encH - rect.right, rect.bottom, encH - rect.left)
            180 -> PixelRect(encW - rect.right, encH - rect.bottom, encW - rect.left, encH - rect.top)
            270 -> PixelRect(encW - rect.bottom, rect.left, encW - rect.top, rect.right)
            else -> throw IllegalArgumentException("rotation must be a multiple of 90")
        }

    private fun normalize(d: Int) = ((d % 360) + 360) % 360
}
