package com.kernel.sense_ai

import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/**
 * Stage-0 dark specks (low weight; droppings-like clusters).
 *
 * - A pixel is a speck pixel when it is more than [darkerByDn] darker than
 *   the mean of its [window] x [window] neighbourhood.
 * - Speck blobs are 8-connected components of [minBlobArea]..[maxBlobArea]
 *   pixels that are not line-like (cracks, grout, wood grain).
 * - Specks whose centroids are within [linkRadiusFraction] of the long edge
 *   are clustered; a cluster of at least [minSpecks] is a candidate.
 * - A very busy frame (more than [maxSpecks] blobs) reports nothing.
 * - A cluster is reported only after it shows up in two consecutive runs.
 */
class DarkSpeckDetector(
    val darkerByDn: Int = 25,
    val window: Int = 31,
    val minBlobArea: Int = 2,
    val maxBlobArea: Int = 200,
    val maxElongation: Double = 4.0,
    val linkRadiusFraction: Double = 0.05,
    val minSpecks: Int = 3,
    val maxSpecks: Int = 300,
    val maxClusters: Int = 3,
    /** Score ceiling: dark specks are weak evidence. */
    val maxScore: Double = 0.5,
) {
    class Cluster(val id: Long, val box: PixelBox, val specks: Int, val score: Double)

    private var sat = IntArray(0)
    private var mask = ByteArray(0)
    private val labeller = ComponentLabeller()
    private var previous: List<Cluster> = emptyList()
    private var nextId = 1L

    fun reset() {
        previous = emptyList()
    }

    fun process(frame: GrayFrame): List<Cluster> {
        val raw = detect(frame)
        // Temporal confirmation: keep clusters that overlap one from the last run.
        val confirmed = ArrayList<Cluster>()
        val next = ArrayList<Cluster>()
        for (c in raw) {
            val match = previous.maxByOrNull { it.box.iou(c.box) }?.takeIf { it.box.iou(c.box) >= 0.3 }
            val kept = Cluster(match?.id ?: nextId++, c.box, c.specks, c.score)
            next.add(kept)
            if (match != null) confirmed.add(kept)
        }
        previous = next
        return confirmed
    }

    /** Single-frame detection without temporal confirmation. */
    fun detect(frame: GrayFrame): List<Cluster> {
        val w = frame.width
        val h = frame.height
        val n = frame.size
        sat = Luma.integral(frame, sat)
        if (mask.size < n) mask = ByteArray(n)
        val r = window / 2
        for (y in 0 until h) {
            val y0 = max(0, y - r)
            val y1 = min(h, y + r + 1)
            for (x in 0 until w) {
                val x0 = max(0, x - r)
                val x1 = min(w, x + r + 1)
                val mean = Luma.boxMean(sat, w, x0, y0, x1, y1)
                val v = frame.data[y * w + x].toInt() and 0xFF
                mask[y * w + x] = if (mean - v > darkerByDn) 1 else 0
            }
        }
        val blobs = labeller.label(mask, w, h, maxBlobs = maxSpecks * 4) ?: return emptyList()
        val specks = blobs.filter { b ->
            b.area in minBlobArea..maxBlobArea &&
                (b.area < 10 || max(b.box.width, b.box.height).toDouble() / min(b.box.width, b.box.height) <= maxElongation)
        }
        if (specks.size < minSpecks || specks.size > maxSpecks) return emptyList()

        // Single-link clustering on centroids (union-find).
        val parent = IntArray(specks.size) { it }
        fun find(i: Int): Int {
            var a = i
            while (parent[a] != a) {
                parent[a] = parent[parent[a]]
                a = parent[a]
            }
            return a
        }
        val link = linkRadiusFraction * max(w, h)
        for (i in specks.indices) for (j in i + 1 until specks.size) {
            if (hypot(specks[i].cx - specks[j].cx, specks[i].cy - specks[j].cy) <= link) {
                val a = find(i)
                val b = find(j)
                if (a != b) parent[a] = b
            }
        }
        val groups = specks.indices.groupBy { find(it) }.values
        return groups
            .filter { it.size >= minSpecks }
            .sortedByDescending { it.size }
            .take(maxClusters)
            .map { members ->
                val box = members.map { specks[it].box }.reduce { a, b -> a.union(b) }.expand(4, w, h)
                Cluster(0, box, members.size, maxScore * min(1.0, members.size / 12.0))
            }
    }
}
