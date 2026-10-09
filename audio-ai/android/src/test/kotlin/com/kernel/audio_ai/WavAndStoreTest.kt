package com.kernel.audio_ai

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class WavAndStoreTest {
    @TempDir
    lateinit var dir: File

    @Test
    fun writesCanonicalPcm16MonoWav() {
        val pcm = shortArrayOf(0, 1, -1, 32767, -32768, 1234)
        val file = File(dir, "a.wav")
        WavWriter.write(file, pcm, 16_000)

        val bytes = file.readBytes()
        assertEquals(44 + pcm.size * 2, bytes.size)
        val b = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        assertEquals("RIFF", String(bytes, 0, 4, Charsets.US_ASCII))
        assertEquals(36 + pcm.size * 2, b.getInt(4))
        assertEquals("WAVE", String(bytes, 8, 4, Charsets.US_ASCII))
        assertEquals("fmt ", String(bytes, 12, 4, Charsets.US_ASCII))
        assertEquals(16, b.getInt(16))
        assertEquals(1.toShort(), b.getShort(20)) // PCM
        assertEquals(1.toShort(), b.getShort(22)) // mono
        assertEquals(16_000, b.getInt(24))
        assertEquals(32_000, b.getInt(28))
        assertEquals(2.toShort(), b.getShort(32))
        assertEquals(16.toShort(), b.getShort(34))
        assertEquals("data", String(bytes, 36, 4, Charsets.US_ASCII))
        assertEquals(pcm.size * 2, b.getInt(40))
        for (i in pcm.indices) assertEquals(pcm[i], b.getShort(44 + i * 2))
        assertFalse(File(dir, "a.wav.tmp").exists())
    }

    @Test
    fun storeSavesUnderRecordingsByScanIdAndDeletesAll() {
        val store = RecordingStore(dir)
        val id = "3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e"
        val saved = store.save(id, ShortArray(160), 16_000)!!
        assertEquals(File(File(dir, "recordings"), "$id.wav").canonicalPath, saved.canonicalPath)
        assertTrue(saved.exists())

        assertEquals(1, store.deleteAll())
        assertFalse(saved.exists())
        assertEquals(0, store.deleteAll())
    }

    @Test
    fun deleteAllIsSafeWhenTheFolderWasNeverCreated() {
        val store = RecordingStore(dir)
        assertFalse(store.directory.exists())
        assertEquals(0, store.deleteAll())
    }

    @Test
    fun pathForReturnsTheAbsolutePathOnlyWhenTheRecordingExists() {
        val store = RecordingStore(dir)
        val id = "3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e"
        assertNull(store.pathFor(id), "nothing retained yet")

        val saved = store.save(id, ShortArray(160), 16_000)!!
        val path = store.pathFor(id)!!
        assertTrue(File(path).isAbsolute)
        assertEquals(saved.canonicalPath, File(path).canonicalPath)
        assertTrue(path.endsWith("recordings${File.separator}$id.wav"), path)

        assertNull(store.pathFor("0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d"), "other scan was not retained")
        store.deleteAll()
        assertNull(store.pathFor(id), "deleted recordings have no path")
    }

    @Test
    fun pathForRefusesNonUuidIds() {
        val store = RecordingStore(dir)
        File(dir, "recordings").mkdirs()
        File(File(dir, "recordings"), "x.wav").writeBytes(ByteArray(44))
        assertNull(store.pathFor("x"))
        assertNull(store.pathFor("../recordings/x"))
        assertNull(store.pathFor(""))
    }

    @Test
    fun storeRefusesNonUuidIds() {
        val store = RecordingStore(dir)
        assertNull(store.save("../escape", ShortArray(160), 16_000))
        assertNull(store.save("", ShortArray(160), 16_000))
        assertFalse(File(dir, "escape.wav").exists())
        assertFalse(File(dir.parentFile, "escape.wav").exists())
    }
}
