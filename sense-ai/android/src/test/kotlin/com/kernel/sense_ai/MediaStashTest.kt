package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.assertArrayEquals
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.io.File

class MediaStashTest {
    @TempDir
    lateinit var dir: File

    private val label = NativeScoredLabel("Mouse", 0.4, 119)

    @Test
    fun clipsAreHeldInMemoryAsWav() {
        val stash = MediaStash(dir)
        stash.putClip("e1", ShortArray(1600) { 5 }, 16_000, listOf(label))
        val wav = stash.wav("e1")!!
        assertEquals("RIFF", String(wav, 0, 4, Charsets.US_ASCII))
        assertEquals(44 + 3200, wav.size)
        assertEquals(listOf(label), stash.labels("e1"))
        assertTrue(stash.labels("missing").isEmpty())
        assertTrue(dir.listFiles().isNullOrEmpty(), "nothing written without keep()")
    }

    @Test
    fun clearDropsAndZeroesEverything() {
        val stash = MediaStash(dir)
        val jpeg = byteArrayOf(1, 2, 3)
        val pcm = ShortArray(10) { 9 }
        stash.putStill("s1", jpeg)
        stash.putClip("e1", pcm, 16_000, emptyList())
        stash.clear()
        assertNull(stash.wav("e1"))
        assertNull(stash.keep("s1"))
        assertArrayEquals(byteArrayOf(0, 0, 0), jpeg, "buffers are zeroed")
        assertTrue(pcm.all { it.toInt() == 0 })
    }

    @Test
    fun keepWritesOnlyWhenAskedAndOnlySafeIds() {
        val stash = MediaStash(dir)
        stash.putStill("3f1c2a9e-0000-4000-8000-000000000001", byteArrayOf(9, 8, 7))
        stash.putClip("e-1", ShortArray(16) { 1 }, 16_000, emptyList())
        val still = stash.keep("3f1c2a9e-0000-4000-8000-000000000001")
        assertNotNull(still)
        assertTrue(still!!.endsWith(".jpg"))
        assertArrayEquals(byteArrayOf(9, 8, 7), File(still).readBytes())
        val clip = stash.keep("e-1")!!
        assertTrue(clip.endsWith(".wav"))
        assertEquals(File(dir, MediaStash.DIR).absolutePath, File(clip).parent)
        assertNull(stash.keep("../escape"))
        assertNull(stash.keep("unknown"))
        assertFalse(File(dir, MediaStash.DIR).listFiles()!!.any { it.name.endsWith(".part") })
    }

    @Test
    fun oldStillsAreEvicted() {
        val stash = MediaStash(dir)
        val first = byteArrayOf(4, 4)
        stash.putStill("a", first)
        repeat(MediaStash.MAX_STILLS) { stash.putStill("n$it", byteArrayOf(1)) }
        assertNull(stash.keep("a"))
        assertArrayEquals(byteArrayOf(0, 0), first)
    }
}
