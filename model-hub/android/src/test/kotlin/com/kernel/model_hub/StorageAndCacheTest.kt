package com.kernel.model_hub

import java.io.File
import java.nio.file.Files
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class StorageAndCacheTest {
    private lateinit var root: File

    @BeforeTest
    fun setUp() {
        root = Files.createTempDirectory("mh-store").toFile()
    }

    @AfterTest
    fun tearDown() {
        root.deleteRecursively()
    }

    @Test
    fun targetPathReplacesSlashAndValidatesSegments() {
        val models = File(root, "models")
        val rev = "6e5c4f1e395deb959c494953478fa5cec4b8008f"
        val f = ModelPaths.targetFile(models, "litert-community/gemma-4-E2B-it-litert-lm", rev, "gemma-4-E2B-it.litertlm")
        assertNotNull(f)
        assertEquals(
            File(File(File(models, "litert-community__gemma-4-E2B-it-litert-lm"), rev), "gemma-4-E2B-it.litertlm").path,
            f.path,
        )
        assertNull(ModelPaths.targetFile(models, "../etc", rev, "a.litertlm"))
        assertNull(ModelPaths.targetFile(models, "a/b", "main", "a.litertlm"), "branch names are not pins")
        assertNull(ModelPaths.targetFile(models, "a/b", rev, "../x.litertlm"))
        assertNull(ModelPaths.targetFile(models, "a/b", rev, "notes.txt"), "only model extensions")
        assertNull(ModelPaths.targetFile(models, "a/..", rev, "a.tflite"))
    }

    @Test
    fun hashCacheIsKeyedByPathSizeAndMtime() {
        val f = File(root, "m.tflite")
        f.writeBytes(Random(1).nextBytes(10_000))
        val store = File(root, "cache/hashes.tsv")
        val cache = HashCache(store)
        val first = cache.sha256(f)
        assertEquals(LocalModelServer.sha256Hex(f.readBytes()), first)
        // A fresh instance reads the persisted value without re-hashing.
        assertEquals(first, HashCache(store).get(f))
        // Changing the content (size + mtime) invalidates the entry.
        f.writeBytes(Random(2).nextBytes(12_000))
        f.setLastModified(f.lastModified() + 5_000)
        assertNull(HashCache(store).get(f))
        assertEquals(LocalModelServer.sha256Hex(f.readBytes()), HashCache(store).sha256(f))
        cache.forget(f.path)
        assertNull(cache.get(f))
    }

    @Test
    fun storageListsModelFilesAndSkipsPartials() {
        val models = File(root, "models")
        val legacy = File(root, "llm")
        val a = File(models, "repo__x/${"a".repeat(40)}/x.litertlm").apply { parentFile.mkdirs(); writeText("x") }
        File(a.path + ".part").writeText("partial")
        File(models, "repo__y/${"b".repeat(40)}/notes.json").apply { parentFile.mkdirs(); writeText("{}") }
        val g = File(legacy, "gemma-4-E2B-it.litertlm").apply { parentFile.mkdirs(); writeText("gallery copy") }
        val t = File(models, "mediapipe__yamnet/${"c".repeat(40)}/yamnet.tflite").apply { parentFile.mkdirs(); writeText("t") }
        val list = ModelStorage(models, legacy).list().map { File(it.path).canonicalPath }.toSet()
        assertEquals(setOf(a.canonicalPath, g.canonicalPath, t.canonicalPath), list)
    }

    @Test
    fun removeRefusesPathsOutsideModelStorage() {
        val models = File(root, "models")
        val outside = File(root, "elsewhere/x.litertlm").apply { parentFile.mkdirs(); writeText("keep") }
        val storage = ModelStorage(models, null)
        assertFalse(storage.remove(outside.path))
        assertTrue(outside.exists())
        assertFalse(storage.remove(File(models, "../elsewhere/x.litertlm").path))
        assertTrue(outside.exists())

        val inside = File(models, "r__x/${"a".repeat(40)}/m.task").apply { parentFile.mkdirs(); writeText("m") }
        File(inside.path + ".part").writeText("p")
        assertTrue(storage.remove(inside.path))
        assertFalse(inside.exists())
        assertFalse(File(inside.path + ".part").exists())
        assertFalse(File(models, "r__x").exists(), "empty repo dirs are pruned")
        assertTrue(models.exists())
    }

    @Test
    fun runnerPublishesInstalledAndFailureStates() {
        val content = Random(3).nextBytes(50_000)
        LocalModelServer(content).use { server ->
            val target = File(root, "models/r__x/${"a".repeat(40)}/m.tflite")
            val d = ResumableDownloader(
                space = { Long.MAX_VALUE },
                hosts = HostPolicy(emptyList(), allowLoopbackHttp = true),
                sleeper = {},
            )
            val seen = ArrayList<ProvisionState>()
            val l: (ProvisionState) -> Unit = { if (it.entryId.startsWith("runner-")) seen.add(it) }
            ProvisionBus.addListener(l)
            try {
                val ok = DownloadJobSpec(
                    "runner-ok", "m", server.resolveUrl, LocalModelServer.sha256Hex(content),
                    content.size.toLong(), target.path, wifiOnly = true,
                )
                assertEquals(RunDecision.DONE, DownloadRunner(d).run(ok))
                assertEquals(ProvisionPhaseK.INSTALLED, seen.last().phase)
                assertEquals(target.absolutePath, seen.last().path)

                server.linkedEtag = null
                val bad = ok.copy(entryId = "runner-bad", sha256 = "1".repeat(64), targetPath = target.path + "2.tflite")
                assertEquals(RunDecision.STOP, DownloadRunner(d).run(bad))
                assertEquals(ProvisionPhaseK.FAILED, seen.last().phase)
                assertEquals("sha256_mismatch", seen.last().error)

                val noSpace = ResumableDownloader(
                    space = { 0 },
                    hosts = HostPolicy(emptyList(), allowLoopbackHttp = true),
                )
                val ns = ok.copy(entryId = "runner-space", targetPath = target.path + "3.tflite")
                assertEquals(RunDecision.STOP, DownloadRunner(noSpace).run(ns))
                assertEquals(ProvisionPhaseK.WAITING_FOR_SPACE, seen.last().phase)
                assertEquals("insufficient_space", seen.last().error)

                ProvisionBus.markCancelled("runner-cancel")
                val c = ok.copy(entryId = "runner-cancel", targetPath = target.path + "4.tflite")
                assertEquals(RunDecision.STOP, DownloadRunner(d).run(c))
                assertEquals(ProvisionPhaseK.PAUSED, seen.last().phase)
                assertEquals("cancelled", seen.last().error)

                val w = ok.copy(entryId = "runner-wifi", targetPath = target.path + "5.tflite")
                assertEquals(
                    RunDecision.RESCHEDULE,
                    DownloadRunner(d).run(w, stopReason = { DownloadRunner.STOP_WIFI_LOST }),
                )
                assertEquals(ProvisionPhaseK.WAITING_FOR_WIFI, seen.last().phase)
            } finally {
                ProvisionBus.removeListener(l)
                ProvisionBus.clearCancelled("runner-cancel")
            }
        }
    }
}
