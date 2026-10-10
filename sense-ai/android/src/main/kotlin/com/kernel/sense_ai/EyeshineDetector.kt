package com.kernel.sense_ai

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Stage-0 eyeshine: near-saturated 1-6 px spots that appear with a torch
 * pulse (retroreflection from eyes, e.g. spiders or rodents).
 *
 * Compares a torch-on frame with a torch-off reference taken just before
 * the pulse while the phone was still:
 * - spot pixel: on >= [saturatedDn] and on - off >= [minRiseDn];
 * - spot blob: 1..[maxSpotSide] px on each side and at most [maxSpotArea] px;
 * - isolated: the ring around it stays below [maxSurroundDn] (rejects glare
 *   on glossy surfaces);
 * - two spots at about the same height and close together score higher.
 */
class EyeshineDetector(
    val saturatedDn: Int = 235,
    val minRiseDn: Int = 60,
    val maxSpotSide: Int = 6,
    val maxSpotArea: Int = 30,
    val maxSurroundDn: Double = 160.0,
    val surroundRadius: Int = 4,
    val maxSpots: Int = 40,
    val pairMaxDistanceFraction: Double = 0.08,
) {
    class Spot(val box: PixelBox, val cx: Double, val cy: Double, val score: Double)

    private var mask = ByteArray(0)
    private val labeller = ComponentLabeller()

    fun detect(on: GrayFrame, off: GrayFrame): List<Spot> {
        if (on.width != off.width || on.height != off.height) return emptyList()
        val w = on.width
        val h = on.height
        val n = on.size
        if (mask.size < n) mask = ByteArray(n)
        for (i in 0 until n) {
            val a = on.data[i].toInt() and 0xFF
            val b = off.data[i].toInt() and 0xFF
            mask[i] = if (a >= saturatedDn && a - b >= minRiseDn) 1 else 0
        }
        // Too many bright new pixels is a lit surface, not eyes.
        val blobs = labeller.label(mask, w, h, maxBlobs = maxSpots * 2) ?: return emptyList()
        val spots = ArrayList<Spot>()
        for (b in blobs) {
            if (b.area > maxSpotArea || b.box.width > maxSpotSide || b.box.height > maxSpotSide) continue
            if (surroundMean(on, b.box) > maxSurroundDn) continue
            spots.add(Spot(b.box, b.cx, b.cy, 0.6))
        }
        if (spots.size > maxSpots) return emptyList()
        // Pairs (two eyes) score higher.
        val pairDist = pairMaxDistanceFraction * max(w, h)
        return spots.map { s ->
            val paired = spots.any { o ->
                o !== s && abs(o.cy - s.cy) <= max(2.0, 0.3 * abs(o.cx - s.cx)) &&
                    abs(o.cx - s.cx) in 2.0..pairDist
            }
            if (paired) Spot(s.box, s.cx, s.cy, 0.9) else s
        }
    }

    private fun surroundMean(frame: GrayFrame, box: PixelBox): Double {
        val r = surroundRadius
        val x0 = max(0, box.minX - r)
        val y0 = max(0, box.minY - r)
        val x1 = min(frame.width - 1, box.maxX + r)
        val y1 = min(frame.height - 1, box.maxY + r)
        var sum = 0L
        var count = 0
        for (y in y0..y1) for (x in x0..x1) {
            if (x in box.minX..box.maxX && y in box.minY..box.maxY) continue
            sum += frame[x, y]
            count++
        }
        return if (count == 0) 0.0 else sum.toDouble() / count
    }
}
