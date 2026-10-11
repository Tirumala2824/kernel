package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

class ChatMediaSessionTest {
    @TempDir lateinit var temp: Path

    @Test fun allowsOneRequestRejectsMultipleDocumentsAndCancellationDoesNotImport() {
        val store = ChatMediaStore(temp.toFile())
        val session = ChatMediaSession(store)
        val replies = mutableListOf<Pair<ChatMediaLease?, String?>>()
        val request = session.begin { media, error -> replies.add(media to error) }!!
        var busy: String? = null
        assertNull(session.begin { _, error -> busy = error })
        assertEquals("picker_busy", busy)
        session.complete(request, 2, "field.wav", 1) { fail("Must not open multiple documents") }
        assertEquals("select_one_wav", replies.single().second)
        session.begin { media, error -> replies.add(media to error) }
        session.cancel()
        assertEquals(null to null, replies.last())
        assertTrue(store.directory.listFiles().orEmpty().isEmpty())
    }

    @Test fun closeReleasesDeliveredCopyAndLateImportAndPreservesOriginal() {
        val store = ChatMediaStore(temp.toFile())
        val original = File(temp.toFile(), "source.wav").apply { writeBytes(byteArrayOf(1, 2, 3)) }
        val session = ChatMediaSession(store)
        var delivered: ChatMediaLease? = null
        val first = session.begin { media, _ -> delivered = media }!!
        session.complete(first, 1, original.name, original.length()) { original.inputStream() }
        assertNotNull(delivered)
        assertTrue(delivered!!.file.exists())
        val opened = CountDownLatch(1)
        val resume = CountDownLatch(1)
        val replies = mutableListOf<Pair<ChatMediaLease?, String?>>()
        val second = session.begin { media, error -> replies.add(media to error) }!!
        val worker = thread {
            session.complete(second, 1, original.name, null) {
                opened.countDown()
                check(resume.await(5, TimeUnit.SECONDS))
                original.inputStream()
            }
        }
        assertTrue(opened.await(5, TimeUnit.SECONDS))
        session.close()
        resume.countDown()
        worker.join(5000)
        assertFalse(worker.isAlive)
        assertFalse(delivered!!.file.exists())
        assertEquals(1, replies.size)
        assertTrue(store.directory.listFiles().orEmpty().isEmpty())
        assertTrue(original.exists())
    }
}
