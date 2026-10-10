package com.kernel.model_hub

import java.io.File
import java.net.URL
import java.nio.file.Files
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

class ResumableDownloaderTest {
    private lateinit var dir: File
    private lateinit var server: LocalModelServer
    private val content = Random(7).nextBytes(300_000)
    private val sha = LocalModelServer.sha256Hex(content)
    private val sleeps = ArrayList<Long>()

    @BeforeTest
    fun setUp() {
        dir = Files.createTempDirectory("mh-dl").toFile()
        server = LocalModelServer(content)
    }

    @AfterTest
    fun tearDown() {
        server.close()
        dir.deleteRecursively()
    }

    private fun downloader(
        space: Long = Long.MAX_VALUE,
        cache: HashCache? = null,
        maxAttempts: Int = 6,
    ) = ResumableDownloader(
        space = { space },
        hosts = HostPolicy(emptyList(), allowLoopbackHttp = true),
        sleeper = { sleeps.add(it) },
        hashCache = cache,
        maxAttempts = maxAttempts,
        progressIntervalMs = 0,
    )

    private fun spec(sha256: String = sha, url: String = server.resolveUrl) =
        DownloadSpec("e1", url, sha256, content.size.toLong(), File(dir, "repo/rev/model.bin"))

    @Test
    fun freshDownloadFollowsRedirectVerifiesAndRenames() {
        val s = spec()
        val phases = ArrayList<TransferPhase>()
        val out = downloader().download(s) { p, _, _ -> phases.add(p) }
        assertIs<DownloadOutcome.Installed>(out)
        assertEquals(sha, out.sha256)
        assertTrue(s.target.readBytes().contentEquals(content))
        assertFalse(ResumableDownloader.partFile(s.target).exists(), "no .part left behind")
        assertEquals(1, server.resolveHits.get())
        assertEquals("identity", server.cdnRequests.single()["Accept-Encoding"])
        assertEquals(null, server.cdnRequests.single()["Range"], "no Range on a fresh start")
        assertEquals(TransferPhase.VERIFYING, phases.last())
    }

    @Test
    fun resumesFromPartWithRangeAndAccepts206AtN() {
        val s = spec()
        s.target.parentFile.mkdirs()
        ResumableDownloader.partFile(s.target).writeBytes(content.copyOfRange(0, 100_000))
        val out = downloader().download(s)
        assertIs<DownloadOutcome.Installed>(out)
        assertEquals("bytes=100000-", server.cdnRequests.single()["Range"])
        assertTrue(s.target.readBytes().contentEquals(content))
    }

    @Test
    fun serverIgnoringRangeTruncatesAndRestarts() {
        server.ignoreRange = true
        val s = spec()
        s.target.parentFile.mkdirs()
        // Garbage in the part file must not survive a 200 response.
        ResumableDownloader.partFile(s.target).writeBytes(ByteArray(50_000) { 1 })
        val out = downloader().download(s)
        assertIs<DownloadOutcome.Installed>(out)
        assertTrue(s.target.readBytes().contentEquals(content))
    }

    @Test
    fun wrongContentRangeStartRestartsFromZero() {
        server.wrongRangeStartOnce = true
        val s = spec()
        s.target.parentFile.mkdirs()
        ResumableDownloader.partFile(s.target).writeBytes(content.copyOfRange(0, 120_000))
        val out = downloader().download(s)
        assertIs<DownloadOutcome.Installed>(out)
        assertEquals(2, server.cdnHits.get())
        assertEquals(null, server.cdnRequests[1]["Range"], "restart is a full request")
        assertTrue(s.target.readBytes().contentEquals(content))
    }

    @Test
    fun reRequestsResolveUrlOnEveryAttemptAfterDrop() {
        server.dropAfterBytesOnce = 64_000
        val s = spec()
        val out = downloader().download(s)
        assertIs<DownloadOutcome.Installed>(out)
        assertEquals(2, server.resolveHits.get(), "resolve URL requested again, CDN URL not reused")
        val second = server.cdnRequests[1]["Range"]
        assertTrue(second != null && second.startsWith("bytes=") && second != "bytes=0-")
        assertTrue(s.target.readBytes().contentEquals(content))
    }

    @Test
    fun sha256MismatchDeletesPartAndFails() {
        server.linkedEtag = null
        val wrong = "0".repeat(64)
        val s = spec(sha256 = wrong)
        val out = downloader().download(s)
        assertEquals(DownloadOutcome.Failed("sha256_mismatch", retryable = false), out)
        assertFalse(ResumableDownloader.partFile(s.target).exists())
        assertFalse(s.target.exists())
    }

    @Test
    fun linkedEtagMismatchFailsBeforeAnyTransfer() {
        server.linkedEtag = "f".repeat(64)
        val out = downloader().download(spec())
        assertEquals(DownloadOutcome.Failed("sha256_mismatch", retryable = false), out)
        assertEquals(0, server.cdnHits.get())
    }

    @Test
    fun linkedSizeMismatchFails() {
        server.linkedSize = 5
        val out = downloader().download(spec())
        assertEquals(DownloadOutcome.Failed("size_mismatch", retryable = false), out)
        assertEquals(0, server.cdnHits.get())
    }

    @Test
    fun rateLimitedRetriesAfterRetryAfter() {
        server.rateLimitTimes = 2
        val out = downloader().download(spec())
        assertIs<DownloadOutcome.Installed>(out)
        assertEquals(3, server.resolveHits.get())
        assertEquals(listOf(1000L, 1000L), sleeps)
    }

    @Test
    fun givesUpAsRetryableAfterMaxAttempts() {
        server.rateLimitTimes = 100
        val out = downloader(maxAttempts = 3).download(spec())
        assertEquals(DownloadOutcome.Failed("rate_limited", retryable = true), out)
    }

    @Test
    fun insufficientSpaceNeedsRemainingPlus512Mb() {
        val s = spec()
        s.target.parentFile.mkdirs()
        ResumableDownloader.partFile(s.target).writeBytes(content.copyOfRange(0, 100_000))
        val remaining = content.size - 100_000L
        val required = remaining + ResumableDownloader.RESERVE_BYTES
        val out = downloader(space = required - 1).download(s)
        assertEquals(DownloadOutcome.NoSpace(required, required - 1), out)
        assertEquals(0, server.resolveHits.get(), "no network when space is short")
        assertIs<DownloadOutcome.Installed>(downloader(space = required).download(s))
    }

    @Test
    fun cancelKeepsPartForResume() {
        var stop = false
        val s = spec()
        val out = ResumableDownloader(
            space = { Long.MAX_VALUE },
            hosts = HostPolicy(emptyList(), allowLoopbackHttp = true),
            progressIntervalMs = 0,
        ).download(s, cancelled = { stop }) { _, done, _ -> if (done > 0) stop = true }
        assertEquals(DownloadOutcome.Cancelled, out)
        assertFalse(s.target.exists())
        val part = ResumableDownloader.partFile(s.target)
        assertTrue(part.exists() && part.length() in 1 until content.size)
        assertIs<DownloadOutcome.Installed>(downloader().download(s))
        assertTrue(s.target.readBytes().contentEquals(content))
    }

    @Test
    fun alreadyInstalledFileNeedsNoNetwork() {
        val s = spec()
        s.target.parentFile.mkdirs()
        s.target.writeBytes(content)
        val cache = HashCache(File(dir, "hashes.tsv"))
        val out = downloader(cache = cache).download(s)
        assertIs<DownloadOutcome.Installed>(out)
        assertEquals(0, server.resolveHits.get())
        assertEquals(sha, cache.get(s.target))
    }

    @Test
    fun corruptFileAtTargetIsReplaced() {
        val s = spec()
        s.target.parentFile.mkdirs()
        s.target.writeBytes(ByteArray(content.size) { 9 })
        assertIs<DownloadOutcome.Installed>(downloader().download(s))
        assertTrue(s.target.readBytes().contentEquals(content))
    }

    @Test
    fun rejectsUnknownShaAndDisallowedHosts() {
        assertEquals(
            DownloadOutcome.Failed("sha256_unknown", retryable = false),
            downloader().download(spec(sha256 = "abc")),
        )
        val prod = ResumableDownloader(space = { Long.MAX_VALUE }, sleeper = {})
        assertEquals(
            DownloadOutcome.Failed("host_not_allowed", retryable = false),
            prod.download(spec()),
        )
        assertEquals(0, server.resolveHits.get())
    }

    @Test
    fun redirectToDisallowedHostIsRefused() {
        server.redirectLocation = "https://example.com/model.bin"
        val out = downloader().download(spec())
        assertEquals(DownloadOutcome.Failed("host_not_allowed", retryable = false), out)
    }

    @Test
    fun hostPolicyAllowsOnlyModelHostsOverHttps() {
        val p = HostPolicy.MODEL_HOSTS
        assertTrue(p.allows(URL("https://huggingface.co/a/resolve/b/c")))
        assertTrue(p.allows(URL("https://cas-bridge.xethub.hf.co/x")))
        assertTrue(p.allows(URL("https://us.aws.cdn.hf.co/x")))
        assertTrue(p.allows(URL("https://storage.googleapis.com/mediapipe-models/x")))
        assertFalse(p.allows(URL("http://huggingface.co/a")))
        assertFalse(p.allows(URL("https://evilhuggingface.co/a")))
        assertFalse(p.allows(URL("https://example.com/a")))
        assertFalse(p.allows(URL("http://127.0.0.1/a")))
    }

    @Test
    fun parsesContentRangeAndEtags() {
        assertEquals(100L to 200L, ResumableDownloader.parseContentRange("bytes 100-199/200"))
        assertEquals(5L to null, ResumableDownloader.parseContentRange("bytes 5-9/*"))
        assertEquals(null, ResumableDownloader.parseContentRange("bytes */200"))
        assertEquals("abc", ResumableDownloader.normalizeEtag("W/\"ABC\""))
    }
}
