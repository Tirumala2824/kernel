package com.kernel.sense_ai

/**
 * 8-bit luma image, row-major and tightly packed. Stage 0 works only on
 * this (the Y plane of ImageAnalysis frames), never on colour.
 */
class GrayFrame(val width: Int, val height: Int, val data: ByteArray) {
    init {
        require(width > 0 && height > 0) { "empty frame" }
        require(data.size >= width * height) { "buffer too small" }
    }

    val size: Int get() = width * height

    operator fun get(x: Int, y: Int): Int = data[y * width + x].toInt() and 0xFF

    fun copy(): GrayFrame = GrayFrame(width, height, data.copyOf(width * height))
}

object Luma {
    /** Stage 0 works on about 320x240; this is the long edge it aims for. */
    const val TARGET_LONG_EDGE = 320

    /** Integer box-filter factor that brings [longEdge] close to [TARGET_LONG_EDGE]. */
    fun factorFor(longEdge: Int): Int = maxOf(1, Math.round(longEdge / TARGET_LONG_EDGE.toFloat()))

    /**
     * Box-downsamples a strided Y plane by [factor] (pixel stride 1, as for
     * YUV_420_888 luma). Rows may be padded to [rowStride]; the last row may
     * be shorter than [rowStride], so reads stay within `width` per row.
     */
    fun downsample(
        src: ByteArray,
        srcWidth: Int,
        srcHeight: Int,
        rowStride: Int,
        factor: Int,
        out: ByteArray? = null,
    ): GrayFrame {
        require(factor >= 1)
        val w = srcWidth / factor
        val h = srcHeight / factor
        val dst = if (out != null && out.size >= w * h) out else ByteArray(w * h)
        if (factor == 1) {
            for (y in 0 until h) System.arraycopy(src, y * rowStride, dst, y * w, w)
            return GrayFrame(w, h, dst)
        }
        val area = factor * factor
        for (y in 0 until h) {
            val sy = y * factor
            for (x in 0 until w) {
                val sx = x * factor
                var sum = 0
                for (dy in 0 until factor) {
                    val row = (sy + dy) * rowStride + sx
                    for (dx in 0 until factor) sum += src[row + dx].toInt() and 0xFF
                }
                dst[y * w + x] = (sum / area).toByte()
            }
        }
        return GrayFrame(w, h, dst)
    }

    /**
     * Rotates clockwise by [degrees] (0, 90, 180 or 270), the
     * ImageInfo.rotationDegrees that makes the frame upright.
     */
    fun rotate(frame: GrayFrame, degrees: Int): GrayFrame {
        val d = ((degrees % 360) + 360) % 360
        if (d == 0) return frame
        val w = frame.width
        val h = frame.height
        val src = frame.data
        return when (d) {
            90 -> {
                val dst = ByteArray(w * h)
                // Upright is h x w; (x, y) in source goes to (h - 1 - y, x).
                for (y in 0 until h) for (x in 0 until w) dst[x * h + (h - 1 - y)] = src[y * w + x]
                GrayFrame(h, w, dst)
            }
            180 -> {
                val dst = ByteArray(w * h)
                val n = w * h
                for (i in 0 until n) dst[n - 1 - i] = src[i]
                GrayFrame(w, h, dst)
            }
            270 -> {
                val dst = ByteArray(w * h)
                // (x, y) goes to (y, w - 1 - x).
                for (y in 0 until h) for (x in 0 until w) dst[(w - 1 - x) * h + y] = src[y * w + x]
                GrayFrame(h, w, dst)
            }
            else -> throw IllegalArgumentException("rotation must be a multiple of 90")
        }
    }

    /** Summed-area table with a zero first row and column ((w+1) x (h+1)). */
    fun integral(frame: GrayFrame, out: IntArray? = null): IntArray {
        val w = frame.width
        val h = frame.height
        val stride = w + 1
        val sat = if (out != null && out.size >= stride * (h + 1)) out else IntArray(stride * (h + 1))
        java.util.Arrays.fill(sat, 0, stride, 0)
        for (y in 0 until h) {
            var rowSum = 0
            sat[(y + 1) * stride] = 0
            for (x in 0 until w) {
                rowSum += frame.data[y * w + x].toInt() and 0xFF
                sat[(y + 1) * stride + x + 1] = sat[y * stride + x + 1] + rowSum
            }
        }
        return sat
    }

    /** Mean of the box [x0, x1) x [y0, y1) from an [integral] table. */
    fun boxMean(sat: IntArray, width: Int, x0: Int, y0: Int, x1: Int, y1: Int): Float {
        val stride = width + 1
        val sum = sat[y1 * stride + x1] - sat[y0 * stride + x1] - sat[y1 * stride + x0] + sat[y0 * stride + x0]
        return sum.toFloat() / ((x1 - x0) * (y1 - y0))
    }
}

/** Pixel bounding box, inclusive on both ends. */
data class PixelBox(val minX: Int, val minY: Int, val maxX: Int, val maxY: Int) {
    val width: Int get() = maxX - minX + 1
    val height: Int get() = maxY - minY + 1

    fun union(o: PixelBox) = PixelBox(minOf(minX, o.minX), minOf(minY, o.minY), maxOf(maxX, o.maxX), maxOf(maxY, o.maxY))

    fun expand(px: Int, w: Int, h: Int) =
        PixelBox(maxOf(0, minX - px), maxOf(0, minY - px), minOf(w - 1, maxX + px), minOf(h - 1, maxY + px))

    fun iou(o: PixelBox): Double {
        val ix = minOf(maxX, o.maxX) - maxOf(minX, o.minX) + 1
        val iy = minOf(maxY, o.maxY) - maxOf(minY, o.minY) + 1
        if (ix <= 0 || iy <= 0) return 0.0
        val inter = ix.toDouble() * iy
        return inter / (width.toDouble() * height + o.width.toDouble() * o.height - inter)
    }
}

/** One 8-connected foreground component. */
class Blob(
    val area: Int,
    val box: PixelBox,
    val cx: Double,
    val cy: Double,
    /** Mean of the per-pixel strength values passed to the labeller. */
    val meanStrength: Double,
)

/**
 * 8-connected component labelling on a mask, with reusable buffers. A pixel
 * is foreground when `mask[i] != 0`; `strength[i]` (optional) is averaged
 * per blob.
 */
class ComponentLabeller {
    private var labels = IntArray(0)
    private var stack = IntArray(0)

    /**
     * Returns at most [maxBlobs] blobs; returns null when there are more
     * (the frame is too busy to be meaningful).
     */
    fun label(
        mask: ByteArray,
        width: Int,
        height: Int,
        strength: FloatArray? = null,
        maxBlobs: Int = Int.MAX_VALUE,
        maxBlobArea: Int = Int.MAX_VALUE,
    ): List<Blob>? {
        val n = width * height
        if (labels.size < n) {
            labels = IntArray(n)
            stack = IntArray(n)
        } else {
            java.util.Arrays.fill(labels, 0, n, 0)
        }
        val blobs = ArrayList<Blob>()
        var next = 1
        for (start in 0 until n) {
            if (mask[start].toInt() == 0 || labels[start] != 0) continue
            if (blobs.size >= maxBlobs) return null
            var sp = 0
            stack[sp++] = start
            labels[start] = next
            var area = 0
            var minX = Int.MAX_VALUE
            var minY = Int.MAX_VALUE
            var maxX = -1
            var maxY = -1
            var sx = 0.0
            var sy = 0.0
            var ss = 0.0
            while (sp > 0) {
                val p = stack[--sp]
                val x = p % width
                val y = p / width
                area++
                if (x < minX) minX = x
                if (x > maxX) maxX = x
                if (y < minY) minY = y
                if (y > maxY) maxY = y
                sx += x
                sy += y
                if (strength != null) ss += strength[p]
                val y0 = if (y > 0) y - 1 else y
                val y1 = if (y < height - 1) y + 1 else y
                val x0 = if (x > 0) x - 1 else x
                val x1 = if (x < width - 1) x + 1 else x
                for (ny in y0..y1) {
                    val row = ny * width
                    for (nx in x0..x1) {
                        val q = row + nx
                        if (mask[q].toInt() != 0 && labels[q] == 0) {
                            labels[q] = next
                            stack[sp++] = q
                        }
                    }
                }
            }
            next++
            if (area <= maxBlobArea) {
                blobs.add(Blob(area, PixelBox(minX, minY, maxX, maxY), sx / area, sy / area, if (strength != null) ss / area else 0.0))
            }
        }
        return blobs
    }
}
