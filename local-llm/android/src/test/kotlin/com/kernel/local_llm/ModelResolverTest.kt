package com.kernel.local_llm

import java.io.File
import java.nio.file.Files
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test

class ModelResolverTest {
    private lateinit var root: File
    private lateinit var appFiles: File
    private lateinit var legacy: File
    private lateinit var hub: File
    private lateinit var outside: File
    private lateinit var versions: File

    @BeforeEach
    fun setUp() {
        root = Files.createTempDirectory("resolver").toFile()
        appFiles = File(root, "app").apply { mkdirs() }
        legacy = File(appFiles, "llm").apply { mkdirs() }
        hub = File(appFiles, "models/gemma").apply { mkdirs() }
        outside = File(root, "elsewhere").apply { mkdirs() }
        versions = File(root, "versions")
    }

    @AfterEach
    fun tearDown() {
        root.deleteRecursively()
    }

    private fun file(dir: File, name: String, text: String = "hello"): File =
        File(dir, name).apply { writeText(text) }

    private fun resolver(kinds: Map<String, ModelKind> = emptyMap()): ModelResolver {
        val classify: (File) -> ModelKind? = { kinds[it.name] }
        return ModelResolver(
            store = ModelStore(legacy, classify),
            roots = { listOf(appFiles) },
            versionDir = versions,
            kindOf = classify,
        )
    }

    @Test
    fun `paths outside the app's storage are refused`() {
        val inside = file(hub, "gemma-4-E2B-it.litertlm")
        val stranger = file(outside, "gemma.litertlm")
        assertNotNull(PathPolicy.check(inside.path, listOf(appFiles)))
        assertNull(PathPolicy.check(stranger.path, listOf(appFiles)))
        // ".." cannot climb out of an allowed root.
        val climbing = File(hub, "../../../elsewhere/gemma.litertlm").path
        assertNull(PathPolicy.check(climbing, listOf(appFiles)))
        // The root itself is not "inside".
        assertFalse(PathPolicy.isInside(appFiles.canonicalFile, appFiles))
    }

    @Test
    fun `only existing non-empty litertlm files with absolute paths pass`() {
        file(hub, "audio.wav")
        File(hub, "empty.litertlm").writeBytes(ByteArray(0))
        assertNull(PathPolicy.check(File(hub, "audio.wav").path, listOf(appFiles)))
        assertNull(PathPolicy.check(File(hub, "empty.litertlm").path, listOf(appFiles)))
        assertNull(PathPolicy.check(File(hub, "missing.litertlm").path, listOf(appFiles)))
        assertNull(PathPolicy.check("models/gemma/x.litertlm", listOf(appFiles)))
        assertNull(PathPolicy.check("", listOf(appFiles)))
        assertNull(PathPolicy.check("/a\u0000b.litertlm", listOf(appFiles)))
    }

    @Test
    fun `null path keeps the legacy llm directory discovery`() {
        file(legacy, "gemma-4-E2B-it.litertlm")
        val r = resolver().resolve(null, ModelKind.LLM)!!
        assertTrue(r.legacy)
        assertEquals("gemma-4-E2B-it", r.file.id)
        assertNull(resolver().resolve(null, ModelKind.EMBEDDING))
    }

    @Test
    fun `legacy discovery never hands an embedding model to the LLM paths`() {
        file(legacy, "a-embeddinggemma.litertlm")
        file(legacy, "b-gemma.litertlm")
        assertEquals("b-gemma", resolver().resolve(null, ModelKind.LLM)!!.file.id)
        assertEquals("a-embeddinggemma", resolver().resolve(null, ModelKind.EMBEDDING)!!.file.id)
    }

    @Test
    fun `an explicit path of the wrong kind is refused`() {
        val f = file(hub, "model.litertlm")
        val r = resolver(mapOf("model.litertlm" to ModelKind.EMBEDDING))
        assertNull(r.resolve(f.path, ModelKind.LLM))
        assertNotNull(r.resolve(f.path, ModelKind.EMBEDDING))
        // Unknown kind (header unreadable): the caller's choice stands.
        assertNotNull(resolver().resolve(f.path, ModelKind.LLM))
    }

    @Test
    fun `hub files are versioned by sha256 without writing next to them`() {
        val f = file(hub, "gemma-4-E2B-it.litertlm", "hello")
        val r = resolver()
        val model = r.resolve(f.path, ModelKind.LLM)!!
        assertFalse(model.legacy)
        val identity = r.identity(model)
        // sha256("hello") = 2cf24dba5fb0...
        assertEquals("gemma-4-E2B-it@2cf24dba5fb0", identity.version)
        assertEquals(5L, identity.sizeBytes)
        assertEquals(listOf("gemma-4-E2B-it.litertlm"), hub.list()!!.toList(), "no sidecar in the hub directory")
        assertEquals(1, versions.list()!!.size)
        assertEquals(identity, r.identity(model), "second call is served from the cache")
    }

    @Test
    fun `a changed file is hashed again`() {
        val f = file(hub, "m.litertlm", "hello")
        val r = resolver()
        assertEquals("m@2cf24dba5fb0", r.identity(r.resolve(f.path, ModelKind.LLM)!!).version)
        f.writeText("hello world")
        assertEquals("m@b94d27b9934d", r.identity(r.resolve(f.path, ModelKind.LLM)!!).version)
    }

    @Test
    fun `a legacy file named by path still uses its sidecar`() {
        val f = file(legacy, "gemma.litertlm", "hello")
        val r = resolver()
        val model = r.resolve(f.path, ModelKind.LLM)!!
        assertTrue(model.legacy)
        assertEquals("gemma@2cf24dba5fb0", r.identity(model).version)
        assertTrue(File(legacy, "gemma.json").isFile)
    }

    @Test
    fun `version cache entries must match path, size and time`() {
        val cache = File(versions, "x.json")
        ModelResolver.writeCached(cache, "/p", 5, 7, "m@abc")
        assertEquals("m@abc", ModelResolver.readCached(cache, "/p", 5, 7))
        assertNull(ModelResolver.readCached(cache, "/p", 6, 7))
        assertNull(ModelResolver.readCached(cache, "/q", 5, 7))
        assertNull(ModelResolver.readCached(cache, "/p", 5, 8))
        cache.writeText("{broken")
        assertNull(ModelResolver.readCached(cache, "/p", 5, 7))
        assertEquals(ModelResolver.cacheName("/p"), ModelResolver.cacheName("/p"))
        assertTrue(ModelResolver.cacheName("/p") != ModelResolver.cacheName("/q"))
    }
}
