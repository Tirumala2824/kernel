package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class TilesAndLabelsTest {
    @Test
    fun candidateTileIsASquareAroundTheBoxInsideTheImage() {
        // 3000 x 4000 upright still, a 40 px insect near the centre.
        val p = TilePlanner.forBox("motion-1", 0.5, 0.5, 40 / 3000.0, 40 / 4000.0, 3000, 4000)
        assertEquals(p.region.width, p.region.height)
        assertEquals(512, p.region.width, "small boxes get the 512 px minimum")
        assertEquals(512, p.outputSide)
        val cx = (p.region.left + p.region.right) / 2.0
        assertEquals(1520.0, cx, 1.0)

        // Large box near the corner: clamped inside, output capped at 768.
        val big = TilePlanner.forBox("motion-2", 0.0, 0.0, 0.3, 0.2, 3000, 4000)
        assertTrue(big.region.left == 0 && big.region.top == 0)
        assertTrue(big.region.right <= 3000 && big.region.bottom <= 4000)
        assertEquals(768, big.outputSide)
    }

    @Test
    fun tileNeverExceedsTheShortEdge() {
        val p = TilePlanner.forBox("x", 0.0, 0.0, 1.0, 1.0, 800, 600)
        assertEquals(600, p.region.width)
        assertEquals(600, p.outputSide)
        val tiny = TilePlanner.forBox("y", 0.4, 0.4, 0.01, 0.01, 400, 300)
        assertEquals(300, tiny.region.width, "image smaller than the minimum tile")
        assertEquals(300, tiny.outputSide, "never upscaled")
    }

    @Test
    fun gridCoversTheWholeStill() {
        val tiles = TilePlanner.grid(3000, 4000)
        assertEquals(6, tiles.size)
        assertTrue(tiles.all { it.region.width == 1500 && it.region.height == 1500 })
        assertEquals(0, tiles.minOf { it.region.top })
        assertEquals(4000, tiles.maxOf { it.region.bottom })
        assertEquals(3000, tiles.maxOf { it.region.right })
        assertEquals(tiles.size, tiles.map { it.candidateId }.toSet().size)
        assertTrue(tiles.all { it.outputSide in 512..768 })
        val landscape = TilePlanner.grid(4000, 3000)
        assertEquals(4000, landscape.maxOf { it.region.right })
    }

    @Test
    fun uprightRectMapsBackToTheEncodedImage() {
        // Encoded 400 x 300 (landscape sensor), upright 300 x 400 after 90 deg.
        val upright = PixelRect(10, 20, 60, 100)
        val enc90 = TilePlanner.uprightToEncoded(upright, 90, 400, 300)
        assertEquals(PixelRect(20, 240, 100, 290), enc90)
        assertEquals(upright.width, enc90.height)
        assertEquals(upright.height, enc90.width)
        val enc270 = TilePlanner.uprightToEncoded(upright, 270, 400, 300)
        assertEquals(PixelRect(300, 10, 380, 60), enc270)
        val enc180 = TilePlanner.uprightToEncoded(PixelRect(10, 20, 60, 100), 180, 400, 300)
        assertEquals(PixelRect(340, 200, 390, 280), enc180)
        assertEquals(upright, TilePlanner.uprightToEncoded(upright, 0, 400, 300))
        assertEquals(300 to 400, TilePlanner.uprightSize(400, 300, 90))
        assertEquals(4, TilePlanner.sampleSize(3000, 700))
        assertEquals(1, TilePlanner.sampleSize(600, 512))
    }

    private fun scores(vararg pairs: Pair<Int, Float>): FloatArray {
        val s = FloatArray(SoundPreFilter.YAMNET_CLASSES) { 0.001f }
        for ((i, v) in pairs) s[i] = v
        return s
    }

    @Test
    fun speechMusicAndTvAreRejected() {
        assertTrue(SoundPreFilter.evaluate(scores(0 to 0.8f, 119 to 0.1f), null).rejected, "speech")
        assertTrue(SoundPreFilter.evaluate(scores(132 to 0.6f), null).rejected, "music")
        val labels = List(SoundPreFilter.YAMNET_CLASSES) { "c$it" }.toMutableList()
        labels[518] = "Television"
        assertTrue(SoundPreFilter.evaluate(scores(518 to 0.5f), labels).rejected, "TV by name")
    }

    @Test
    fun pestClassesGiveAHintAndSortedLabels() {
        val r = SoundPreFilter.evaluate(scores(119 to 0.4f, 468 to 0.2f, 500 to 0.3f), null)
        assertFalse(r.rejected)
        assertEquals("Mouse", r.hint)
        assertEquals(listOf(0.4f, 0.3f, 0.2f), r.labels.take(3).map { it.score })
        assertEquals("class_500", r.labels[1].label)
        assertEquals("Scratch", r.labels[2].label)
        val weak = SoundPreFilter.evaluate(scores(500 to 0.5f, 121 to 0.03f), null)
        assertNull(weak.hint, "allow-listed score below the hint minimum")
        assertTrue(weak.labels.any { it.index == 121 }, "still listed")
    }

    @Test
    fun embeddedLabelsOverrideIndices() {
        // A model whose label order differs: allow-list resolved by name.
        val labels = List(SoundPreFilter.YAMNET_CLASSES) { "c$it" }.toMutableList()
        labels[7] = "Mouse"
        val r = SoundPreFilter.evaluate(scores(7 to 0.4f, 119 to 0.5f), labels)
        assertEquals("Mouse", r.hint)
        assertFalse(r.rejected)
    }
}
