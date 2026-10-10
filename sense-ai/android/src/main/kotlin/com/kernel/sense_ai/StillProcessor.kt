package com.kernel.sense_ai

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapRegionDecoder
import android.graphics.Matrix
import android.graphics.Rect
import android.os.Build
import java.io.ByteArrayOutputStream
import kotlin.math.max

/**
 * Turns a full-resolution JPEG into an upright 1024 px context image and
 * 512-768 px tiles. Decodes by region and subsample, so a 50 MP still
 * never becomes one full-size bitmap. Memory only.
 */
object StillProcessor {
    private const val JPEG_QUALITY = 90
    private const val MAX_TILES = 12

    class Tile(val plan: TilePlan, val jpeg: ByteArray)

    class Output(val context: ByteArray, val tiles: List<Tile>, val uprightWidth: Int, val uprightHeight: Int)

    fun process(jpeg: ByteArray, rotationDegrees: Int, boxes: List<NativeBox>): Output? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size, bounds)
        val encW = bounds.outWidth
        val encH = bounds.outHeight
        if (encW <= 0 || encH <= 0) return null
        val (uW, uH) = TilePlanner.uprightSize(encW, encH, rotationDegrees)

        val context = contextImage(jpeg, encW, encH, rotationDegrees) ?: return null
        val plans = if (boxes.isEmpty()) {
            TilePlanner.grid(uW, uH)
        } else {
            boxes.take(MAX_TILES).map { TilePlanner.forBox(it.candidateId, it.left, it.top, it.width, it.height, uW, uH) }
        }
        val decoder = newDecoder(jpeg) ?: return Output(context, emptyList(), uW, uH)
        val tiles = ArrayList<Tile>(plans.size)
        try {
            for (plan in plans) {
                val enc = TilePlanner.uprightToEncoded(plan.region, rotationDegrees, encW, encH)
                val side = plan.region.width
                val opts = BitmapFactory.Options().apply { inSampleSize = TilePlanner.sampleSize(side, plan.outputSide) }
                val region = try {
                    decoder.decodeRegion(Rect(enc.left, enc.top, enc.right, enc.bottom), opts)
                } catch (_: IllegalArgumentException) {
                    null
                } ?: continue
                val upright = scaleAndRotate(region, plan.outputSide.toFloat() / max(region.width, region.height), rotationDegrees)
                tiles.add(Tile(plan, encode(upright)))
                if (upright !== region) upright.recycle()
                region.recycle()
            }
        } finally {
            decoder.recycle()
        }
        return Output(context, tiles, uW, uH)
    }

    private fun contextImage(jpeg: ByteArray, encW: Int, encH: Int, rotation: Int): ByteArray? {
        val long = max(encW, encH)
        val opts = BitmapFactory.Options().apply { inSampleSize = TilePlanner.sampleSize(long, TilePlanner.CONTEXT_LONG_EDGE) }
        val bmp = BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size, opts) ?: return null
        val scale = TilePlanner.CONTEXT_LONG_EDGE.toFloat() / max(bmp.width, bmp.height)
        val upright = scaleAndRotate(bmp, minOf(1f, scale), rotation)
        val out = encode(upright)
        if (upright !== bmp) upright.recycle()
        bmp.recycle()
        return out
    }

    private fun scaleAndRotate(src: Bitmap, scale: Float, rotation: Int): Bitmap {
        if (scale == 1f && rotation % 360 == 0) return src
        val m = Matrix().apply {
            postScale(scale, scale)
            postRotate(rotation.toFloat())
        }
        return Bitmap.createBitmap(src, 0, 0, src.width, src.height, m, true)
    }

    private fun encode(bmp: Bitmap): ByteArray {
        val out = ByteArrayOutputStream(bmp.width * bmp.height / 4)
        bmp.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, out)
        return out.toByteArray()
    }

    @Suppress("DEPRECATION")
    private fun newDecoder(jpeg: ByteArray): BitmapRegionDecoder? = try {
        if (Build.VERSION.SDK_INT >= 31) {
            BitmapRegionDecoder.newInstance(jpeg, 0, jpeg.size)
        } else {
            BitmapRegionDecoder.newInstance(jpeg, 0, jpeg.size, false)
        }
    } catch (_: java.io.IOException) {
        null
    }
}
