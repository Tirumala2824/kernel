package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.nio.file.Path

class ChatMediaStoreTest {
    @TempDir lateinit var temp: Path

    private class CountingStream(private val length: Int, private val failAt: Int? = null) : InputStream() {
        var readCount = 0
        var closed = false
        override fun read(): Int {
            if (failAt != null && readCount >= failAt) throw IOException("test read failure")
            return if (readCount >= length) -1 else { readCount++; 1 }
        }
        override fun close() { closed = true }
    }

    @Test fun rejectsKnownOversizeBeforeOpeningAndUnknownLengthAtTheCap() {
        val store = ChatMediaStore(File(temp.toFile(), "cache"))
        assertEquals(6_000_000, InsectWav.MAX_BYTES)
        var opened = false
        assertThrows(IOException::class.java) {
            store.importWav("large.wav", InsectWav.MAX_BYTES + 1L) { opened = true; CountingStream(1) }
        }
        assertFalse(opened)
        for (claimed in listOf(null, -1L, 1L)) {
            val stream = CountingStream(InsectWav.MAX_BYTES + 500_000)
            assertThrows(IOException::class.java) { store.importWav("large.WAVE", claimed) { stream } }
            assertEquals(InsectWav.MAX_BYTES + 1, stream.readCount)
            assertTrue(stream.closed)
            assertTrue(store.directory.listFiles().orEmpty().isEmpty())
        }
        val exact = CountingStream(InsectWav.MAX_BYTES)
        val lease = store.importWav("exact.wav", null) { exact }
        assertEquals(InsectWav.MAX_BYTES.toLong(), lease.file.length())
        store.release(lease.token)
    }

    @Test fun rejectsEmptyAndUnsupportedAndDeletesPartialOnReadError() {
        val store = ChatMediaStore(File(temp.toFile(), "cache"))
        for ((name, length) in listOf("empty.wav" to 0, "wrong.mp3" to 4)) {
            assertThrows(IOException::class.java) { store.importWav(name, null) { CountingStream(length) } }
            assertTrue(store.directory.listFiles().orEmpty().isEmpty())
        }
        val stream = CountingStream(50_000, 30_000)
        assertThrows(IOException::class.java) { store.importWav("broken.wav", null) { stream } }
        assertTrue(stream.closed)
        assertTrue(store.directory.listFiles().orEmpty().isEmpty())
    }

    @Test fun startupCleansOnlyDedicatedOrphansAndNeverAnotherLiveImport() {
        val cache = File(temp.toFile(), "cache")
        val store = ChatMediaStore(cache)
        val stale = store.importWav("stale.wav", 3) { byteArrayOf(1, 2, 3).inputStream() }
        val unrelated = File(store.directory, "not-owned.wav").apply { writeText("keep") }
        val original = File(cache, "original.wav").apply { writeText("keep") }
        val restarted = ChatMediaStore(cache)
        assertFalse(stale.file.exists())
        assertTrue(unrelated.exists())
        assertTrue(original.exists())
        val first = restarted.importWav("first.wav", 1) { byteArrayOf(1).inputStream() }
        val second = restarted.importWav("second.wav", 1) { byteArrayOf(2).inputStream() }
        assertTrue(first.file.exists())
        assertTrue(second.file.exists())
    }

    @Test fun adoptsOnlyReturnedPrivateImagePickerCopiesIntoTokenDirectory() {
        val cache = File(temp.toFile(), "cache").apply { mkdirs() }
        val original = File(temp.toFile(), "scaled_original.jpg").apply { writeBytes(byteArrayOf(1)) }
        val unrelated = File(cache, "original.jpg").apply { writeBytes(byteArrayOf(2)) }
        val store = ChatMediaStore(cache)
        assertNull(store.adoptImagePickerCopy(original.path))
        assertNull(store.adoptImagePickerCopy(unrelated.path))
        for (relative in listOf("scaled_photo.jpg", "6c329457-1790-492c-b967-cda25eb5a1f3/photo.jpg")) {
            val copy = File(cache, relative).apply { parentFile!!.mkdirs(); writeBytes(byteArrayOf(3)) }
            val lease = store.adoptImagePickerCopy(copy.path)!!
            assertFalse(copy.exists())
            assertEquals(store.directory.canonicalFile, lease.file.canonicalFile.parentFile)
            store.release(lease.token)
            assertFalse(lease.file.exists())
        }
        assertTrue(original.exists())
        assertTrue(unrelated.exists())
    }

    @Test fun sharedStartupDoesNotSweepAnotherSessionAndRejectsTraversal() {
        val cache = File(temp.toFile(), "cache").apply { mkdirs() }
        val store = ChatMediaStore.shared(cache)
        val lease = store.importWav("live.wav", 1) { byteArrayOf(1).inputStream() }
        assertSame(store, ChatMediaStore.shared(cache))
        assertTrue(lease.file.exists())
        val source = File(cache, "scaled_keep.jpg").apply { writeText("keep") }
        val child = File(cache, "child").apply { mkdirs() }
        assertNull(store.adoptImagePickerCopy(File(child, "../scaled_keep.jpg").path))
        store.release("../scaled_keep.jpg")
        store.release(lease.file.path)
        assertTrue(lease.file.exists())
        assertTrue(source.exists())
    }

    @Test fun canonicalContainmentNeverFollowsAnOwnedPathSymlink() {
        val cache = File(temp.toFile(), "cache")
        val store = ChatMediaStore(cache)
        val original = File(temp.toFile(), "source.wav").apply { writeText("preserve") }
        val lease = store.importWav("copy.wav", 1) { byteArrayOf(1).inputStream() }
        lease.file.delete()
        try {
            java.nio.file.Files.createSymbolicLink(lease.file.toPath(), original.toPath())
        } catch (_: java.nio.file.FileSystemException) {
            org.junit.jupiter.api.Assumptions.assumeTrue(false, "Host cannot create symlinks")
        }
        store.release(lease.token)
        assertEquals("preserve", original.readText())
        ChatMediaStore(cache)
        assertEquals("preserve", original.readText())
    }

    @Test fun trustedCacheAliasAllowsReturnedPhotosButNotChildTraversal() {
        File(temp.toFile(), "alias").mkdirs()
        val cacheAlias = File(temp.toFile(), "alias/../cache").apply { mkdirs() }
        val copy = File(cacheAlias, "scaled_photo.jpg").apply { writeText("photo") }
        val store = ChatMediaStore(cacheAlias)
        val lease = store.adoptImagePickerCopy(copy.path)
        assertNotNull(lease)
        assertFalse(copy.exists())
        store.release(lease!!.token)
        assertFalse(lease.file.exists())
    }

    @Test fun importsOneCopyAndReleasePreservesOriginal() {
        val original = File(temp.toFile(), "original.wav").apply { writeBytes(byteArrayOf(1, 2, 3)) }
        val store = ChatMediaStore(File(temp.toFile(), "cache"))
        val lease = store.importWav(original.name, original.length()) { original.inputStream() }
        assertArrayEquals(original.readBytes(), lease.file.readBytes())
        assertEquals(store.directory.canonicalFile, lease.file.canonicalFile.parentFile)
        store.release(original.path)
        assertTrue(original.exists())
        assertTrue(lease.file.exists())
        store.release(lease.token)
        store.release(lease.token)
        assertFalse(lease.file.exists())
        assertTrue(original.exists())
    }
}
