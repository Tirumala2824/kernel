package com.kernel.local_llm

import java.io.File
import java.nio.file.Files
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test

class ModelStoreTest {
    private lateinit var dir: File
    private lateinit var store: ModelStore

    @BeforeEach
    fun setUp() {
        dir = Files.createTempDirectory("llm").toFile()
        store = ModelStore(dir)
    }

    @AfterEach
    fun tearDown() {
        dir.deleteRecursively()
    }

    private fun file(name: String, bytes: ByteArray = byteArrayOf(1, 2, 3)): File =
        File(dir, name).apply { writeBytes(bytes) }

    @Test
    fun `discovery returns null for a missing or empty directory`() {
        assertNull(ModelStore(null).findModel())
        assertNull(store.findModel())
    }

    @Test
    fun `discovery picks the first litertlm by name and ignores partial copies`() {
        file("zeta.litertlm")
        file("alpha.litertlm.part")
        file("notes.json")
        file("beta.litertlm")
        file("empty.litertlm", ByteArray(0))
        assertEquals("beta", store.findModel()!!.id)
    }

    @Test
    fun `sidecar is written once and versioned by id and sha256 prefix`() {
        val bytes = "hello".toByteArray()
        file("gemma-4-E2B-it.litertlm", bytes)
        val model = store.findModel()!!
        assertNull(store.readSidecar(model))

        val sidecar = store.ensureSidecar(model)
        // sha256("hello") = 2cf24dba5fb0a30e26e83b2ac5b9e29e...
        assertEquals("gemma-4-E2B-it", sidecar.id)
        assertEquals("gemma-4-E2B-it@2cf24dba5fb0", sidecar.version)
        assertEquals(5L, sidecar.sizeBytes)
        assertNotNull(Instant.parse(sidecar.importedAt))
        assertTrue(File(dir, "gemma-4-E2B-it.json").isFile)
        assertEquals(sidecar, store.readSidecar(model))
    }

    @Test
    fun `a sidecar that no longer matches the file size is ignored`() {
        file("m.litertlm", "hello".toByteArray())
        val model = store.findModel()!!
        store.ensureSidecar(model)
        file("m.litertlm", "hello world".toByteArray())
        assertNull(store.readSidecar(store.findModel()!!))
        assertEquals("m@b94d27b9934d", store.ensureSidecar(store.findModel()!!).version)
    }

    @Test
    fun `a corrupt sidecar is ignored`() {
        file("m.litertlm")
        file("m.json", "{not json".toByteArray())
        assertNull(store.readSidecar(store.findModel()!!))
    }

    @Test
    fun `deleteAll removes models, sidecars and partial copies only`() {
        file("m.litertlm")
        file("m.json")
        file("n.litertlm.part")
        file("keep.txt")
        assertEquals(3, store.deleteAll())
        assertEquals(listOf("keep.txt"), dir.list()!!.toList())
    }

    @Test
    fun `deleteOtherModels keeps the new model and its sidecar`() {
        file("old.litertlm")
        file("old.json")
        file("new.litertlm")
        file("new.json")
        store.deleteOtherModels("new.litertlm")
        assertEquals(setOf("new.litertlm", "new.json"), dir.list()!!.toSet())
    }

    @Test
    fun `file names are sanitized and must be litertlm`() {
        assertEquals("gemma-4-E2B-it.litertlm", ModelStore.sanitizeFileName("gemma-4-E2B-it.litertlm"))
        assertEquals("Model.litertlm", ModelStore.sanitizeFileName(" Model.LITERTLM "))
        assertEquals("evil.litertlm", ModelStore.sanitizeFileName("../../evil.litertlm"))
        assertEquals("a_b_c.litertlm", ModelStore.sanitizeFileName("a b/c.litertlm"))
        assertNull(ModelStore.sanitizeFileName("model.tflite"))
        assertNull(ModelStore.sanitizeFileName("recording.wav"))
        assertNull(ModelStore.sanitizeFileName(".litertlm"))
        assertNull(ModelStore.sanitizeFileName(null))
        val long = ModelStore.sanitizeFileName("x".repeat(500) + ".litertlm")!!
        assertFalse(long.contains('/'))
        assertTrue(long.length <= 120 + ".litertlm".length)
    }

    @Test
    fun `import needs the file size plus ten percent free`() {
        assertEquals(2_846_962_483L, ModelStore.requiredFreeBytes(2_588_147_712L))
        assertEquals(0L, ModelStore.requiredFreeBytes(0L))
    }

    @Test
    fun `version uses the first twelve hex characters`() {
        assertEquals("id@0123456789ab", ModelStore.versionOf("id", "0123456789abcdef"))
    }
}
