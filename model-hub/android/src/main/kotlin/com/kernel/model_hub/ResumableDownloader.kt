package com.kernel.model_hub

import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.RandomAccessFile
import java.net.HttpURLConnection
import java.net.URL
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.StandardCopyOption

/** One pinned model file to install at [target]. */
data class DownloadSpec(
    val entryId: String,
    val url: String,
    val sha256: String,
    val sizeBytes: Long,
    val target: File,
)

sealed interface DownloadOutcome {
    data class Installed(val file: File, val sha256: String) : DownloadOutcome

    /** [retryable] failures keep the .part file so the next run resumes. */
    data class Failed(
        val reason: String,
        val retryable: Boolean,
        val retryAfterMs: Long? = null,
    ) : DownloadOutcome

    data class NoSpace(val requiredBytes: Long, val availableBytes: Long) : DownloadOutcome

    data object Cancelled : DownloadOutcome
}

enum class TransferPhase { DOWNLOADING, VERIFYING }

fun interface SpaceProbe {
    /** Bytes the system can allocate for [dir] (StorageManager on Android). */
    fun allocatableBytes(dir: File): Long
}

fun interface ConnectionOpener {
    fun open(url: URL): HttpURLConnection
}

fun interface Sleeper {
    fun sleep(ms: Long)
}

/**
 * Hosts a model file may come from (guardrails §7). https only; the HF
 * resolver redirects to its CDN under hf.co / huggingface.co.
 */
class HostPolicy(
    private val httpsSuffixes: List<String>,
    private val allowLoopbackHttp: Boolean = false,
) {
    fun allows(url: URL): Boolean {
        val host = url.host.lowercase()
        return when (url.protocol.lowercase()) {
            "https" -> httpsSuffixes.any { host == it || host.endsWith(".$it") }
            "http" -> allowLoopbackHttp && (host == "127.0.0.1" || host == "localhost")
            else -> false
        }
    }

    companion object {
        val MODEL_HOSTS = HostPolicy(listOf("huggingface.co", "hf.co", "storage.googleapis.com"))
    }
}

/**
 * Resumable, sha256-verified download of one file (pure JVM, unit tested
 * against a local HTTP server).
 *
 * - The resolve URL is re-requested on EVERY attempt: HF's CDN Location
 *   expires after about an hour, so it is never cached.
 * - The resolver's 302 carries X-Linked-Size / X-Linked-ETag (the LFS
 *   sha256); a mismatch with the pin fails before any byte is transferred.
 * - Resume with `Range: bytes=N-` and `Accept-Encoding: identity`. A 206 is
 *   accepted only when Content-Range starts at N; a 200 truncates and
 *   restarts from zero.
 * - Bytes go to `<target>.part`. After the last byte the WHOLE file is
 *   hashed; on a mismatch the part file is deleted ('sha256_mismatch'),
 *   otherwise it is renamed atomically onto the target.
 * - Before transferring, the volume must have remaining + 512 MB allocatable.
 */
class ResumableDownloader(
    private val space: SpaceProbe,
    private val hosts: HostPolicy = HostPolicy.MODEL_HOSTS,
    private val opener: ConnectionOpener = ConnectionOpener { it.openConnection() as HttpURLConnection },
    private val sleeper: Sleeper = Sleeper { Thread.sleep(it) },
    private val hashCache: HashCache? = null,
    private val maxAttempts: Int = 6,
    private val reserveBytes: Long = RESERVE_BYTES,
    private val progressIntervalMs: Long = 250,
    private val clock: () -> Long = System::currentTimeMillis,
) {
    private sealed interface Step {
        data object Done : Step
        data object Restart : Step
        data object Cancelled : Step
        data class Retry(val reason: String, val waitMs: Long?, val progressed: Boolean) : Step
        data class Fatal(val reason: String, val deletePart: Boolean = false) : Step
    }

    fun download(
        spec: DownloadSpec,
        cancelled: () -> Boolean = { false },
        onProgress: (TransferPhase, Long, Long) -> Unit = { _, _, _ -> },
    ): DownloadOutcome {
        if (!ModelPaths.SHA256.matches(spec.sha256.lowercase())) {
            return DownloadOutcome.Failed("sha256_unknown", retryable = false)
        }
        if (spec.sizeBytes <= 0) return DownloadOutcome.Failed("size_unknown", retryable = false)
        val target = spec.target
        val dir = target.parentFile ?: return DownloadOutcome.Failed("invalid_target", false)
        if (!dir.isDirectory && !dir.mkdirs()) return DownloadOutcome.Failed("invalid_target", false)
        val part = partFile(target)

        // Already installed (e.g. a previous job finished after the UI left).
        if (target.isFile && target.length() == spec.sizeBytes) {
            onProgress(TransferPhase.VERIFYING, spec.sizeBytes, spec.sizeBytes)
            val sha = hashCache?.sha256(target, cancelled)
                ?: HashCache.sha256Of(target, cancelled)
                ?: return DownloadOutcome.Cancelled
            if (sha.equals(spec.sha256, ignoreCase = true)) {
                part.delete()
                return DownloadOutcome.Installed(target, sha)
            }
            target.delete()
        }
        if (part.length() > spec.sizeBytes) truncate(part)

        val remaining = spec.sizeBytes - part.length()
        val required = remaining + reserveBytes
        val available = space.allocatableBytes(dir)
        if (available < required) return DownloadOutcome.NoSpace(required, available)

        var attempts = 0
        var lastReason = "network"
        while (part.length() < spec.sizeBytes) {
            if (cancelled()) return DownloadOutcome.Cancelled
            attempts++
            if (attempts > maxAttempts) return DownloadOutcome.Failed(lastReason, retryable = true)
            when (val step = transferOnce(spec, part, cancelled, onProgress)) {
                Step.Done -> Unit
                Step.Restart -> truncate(part)
                Step.Cancelled -> return DownloadOutcome.Cancelled
                is Step.Fatal -> {
                    if (step.deletePart) part.delete()
                    return DownloadOutcome.Failed(step.reason, retryable = false)
                }
                is Step.Retry -> {
                    lastReason = step.reason
                    if (step.progressed) attempts = 0
                    val wait = step.waitMs ?: backoffMs(attempts)
                    if (wait > MAX_INLINE_WAIT_MS) {
                        return DownloadOutcome.Failed(step.reason, retryable = true, retryAfterMs = wait)
                    }
                    if (wait > 0) sleeper.sleep(wait)
                }
            }
        }
        if (part.length() != spec.sizeBytes) {
            part.delete()
            return DownloadOutcome.Failed("size_mismatch", retryable = false)
        }

        onProgress(TransferPhase.VERIFYING, spec.sizeBytes, spec.sizeBytes)
        val sha = HashCache.sha256Of(part, cancelled) ?: return DownloadOutcome.Cancelled
        if (!sha.equals(spec.sha256, ignoreCase = true)) {
            part.delete()
            return DownloadOutcome.Failed("sha256_mismatch", retryable = false)
        }
        try {
            try {
                Files.move(
                    part.toPath(), target.toPath(),
                    StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING,
                )
            } catch (_: AtomicMoveNotSupportedException) {
                Files.move(part.toPath(), target.toPath(), StandardCopyOption.REPLACE_EXISTING)
            }
        } catch (_: IOException) {
            return DownloadOutcome.Failed("rename_failed", retryable = true)
        }
        hashCache?.put(target, sha)
        return DownloadOutcome.Installed(target, sha)
    }

    private fun transferOnce(
        spec: DownloadSpec,
        part: File,
        cancelled: () -> Boolean,
        onProgress: (TransferPhase, Long, Long) -> Unit,
    ): Step {
        val have = part.length()
        var url = try {
            URL(spec.url)
        } catch (_: IOException) {
            return Step.Fatal("invalid_url")
        }
        var hops = 0
        var conn: HttpURLConnection
        var code: Int
        while (true) {
            if (!hosts.allows(url)) return Step.Fatal("host_not_allowed")
            conn = try {
                open(url, have)
            } catch (_: IOException) {
                return Step.Retry("network", null, false)
            }
            code = try {
                conn.responseCode
            } catch (_: IOException) {
                conn.disconnect()
                return Step.Retry("network", null, false)
            }
            if (code !in REDIRECTS) break
            val linkedEtag = conn.getHeaderField("X-Linked-ETag")?.let(::normalizeEtag)
            val linkedSize = conn.getHeaderField("X-Linked-Size")?.trim()?.toLongOrNull()
            val location = conn.getHeaderField("Location")
            conn.disconnect()
            if (linkedEtag != null && ModelPaths.SHA256.matches(linkedEtag) &&
                !linkedEtag.equals(spec.sha256, ignoreCase = true)
            ) {
                return Step.Fatal("sha256_mismatch", deletePart = true)
            }
            if (linkedSize != null && linkedSize != spec.sizeBytes) {
                return Step.Fatal("size_mismatch", deletePart = true)
            }
            if (location.isNullOrBlank()) return Step.Retry("bad_redirect", null, false)
            url = try {
                URL(url, location)
            } catch (_: IOException) {
                return Step.Fatal("invalid_url")
            }
            if (++hops > MAX_REDIRECTS) return Step.Fatal("too_many_redirects")
        }
        try {
            return when {
                code == HttpURLConnection.HTTP_PARTIAL -> {
                    val range = parseContentRange(conn.getHeaderField("Content-Range"))
                    if (range == null || range.first != have) {
                        Step.Restart
                    } else if (range.second != null && range.second != spec.sizeBytes) {
                        Step.Fatal("size_mismatch", deletePart = true)
                    } else {
                        stream(conn, part, have, append = true, spec, cancelled, onProgress)
                    }
                }
                code == HttpURLConnection.HTTP_OK -> {
                    val len = conn.contentLengthLong
                    if (len >= 0 && len != spec.sizeBytes) {
                        Step.Fatal("size_mismatch", deletePart = true)
                    } else {
                        // Fresh start, or the server ignored Range: truncate.
                        stream(conn, part, 0, append = false, spec, cancelled, onProgress)
                    }
                }
                code == 416 -> if (have == spec.sizeBytes) Step.Done else Step.Restart
                code == 429 -> Step.Retry("rate_limited", retryAfterMs(conn) ?: RATE_LIMIT_WAIT_MS, false)
                code in 500..599 -> Step.Retry("http_$code", retryAfterMs(conn), false)
                code == 401 || code == 403 -> Step.Fatal("forbidden")
                code == 404 || code == 410 -> Step.Fatal("not_found")
                else -> Step.Fatal("http_$code")
            }
        } finally {
            conn.disconnect()
        }
    }

    private fun stream(
        conn: HttpURLConnection,
        part: File,
        start: Long,
        append: Boolean,
        spec: DownloadSpec,
        cancelled: () -> Boolean,
        onProgress: (TransferPhase, Long, Long) -> Unit,
    ): Step {
        var done = start
        var lastEmit = 0L
        val out = try {
            FileOutputStream(part, append)
        } catch (_: IOException) {
            return Step.Fatal("write_failed")
        }
        out.use { sink ->
            val input = try {
                conn.inputStream
            } catch (_: IOException) {
                return Step.Retry("network", null, false)
            }
            input.use { src ->
                val buf = ByteArray(BUFFER)
                while (true) {
                    if (cancelled()) return Step.Cancelled
                    val n = try {
                        src.read(buf)
                    } catch (_: IOException) {
                        return Step.Retry("network", null, done > start)
                    }
                    if (n < 0) break
                    if (done + n > spec.sizeBytes) return Step.Fatal("size_mismatch", deletePart = true)
                    try {
                        sink.write(buf, 0, n)
                    } catch (_: IOException) {
                        return Step.Fatal("write_failed")
                    }
                    done += n
                    val now = clock()
                    if (now - lastEmit >= progressIntervalMs) {
                        lastEmit = now
                        onProgress(TransferPhase.DOWNLOADING, done, spec.sizeBytes)
                    }
                }
            }
        }
        onProgress(TransferPhase.DOWNLOADING, done, spec.sizeBytes)
        return if (done == spec.sizeBytes) Step.Done else Step.Retry("network", null, done > start)
    }

    private fun open(url: URL, have: Long): HttpURLConnection {
        val c = opener.open(url)
        c.instanceFollowRedirects = false
        c.connectTimeout = CONNECT_TIMEOUT_MS
        c.readTimeout = READ_TIMEOUT_MS
        c.useCaches = false
        c.setRequestProperty("Accept-Encoding", "identity")
        c.setRequestProperty("User-Agent", USER_AGENT)
        if (have > 0) c.setRequestProperty("Range", "bytes=$have-")
        return c
    }

    private fun retryAfterMs(conn: HttpURLConnection): Long? =
        conn.getHeaderField("Retry-After")?.trim()?.toLongOrNull()?.let { it.coerceIn(0, 3600) * 1000 }

    private fun backoffMs(attempt: Int): Long =
        (1000L shl (attempt - 1).coerceIn(0, 5)).coerceAtMost(30_000)

    companion object {
        const val RESERVE_BYTES = 512L * 1024 * 1024
        const val USER_AGENT = "kernel-model-hub/0.1"
        private const val BUFFER = 256 * 1024
        private const val MAX_REDIRECTS = 5
        private const val CONNECT_TIMEOUT_MS = 20_000
        private const val READ_TIMEOUT_MS = 60_000
        private const val MAX_INLINE_WAIT_MS = 60_000L
        private const val RATE_LIMIT_WAIT_MS = 60_000L
        private val REDIRECTS = setOf(301, 302, 303, 307, 308)

        fun partFile(target: File) = File(target.path + ModelPaths.PART_SUFFIX)

        /** `"abc"` or `W/"abc"` -> `abc` (lowercase). */
        fun normalizeEtag(raw: String): String =
            raw.trim().removePrefix("W/").trim().trim('"').lowercase()

        /** `bytes 100-199/200` -> (100, 200); total null when `*`. */
        fun parseContentRange(raw: String?): Pair<Long, Long?>? {
            if (raw == null) return null
            val m = Regex("""^\s*bytes\s+(\d+)-(\d+)/(\d+|\*)\s*$""").find(raw) ?: return null
            val start = m.groupValues[1].toLongOrNull() ?: return null
            val total = m.groupValues[3].toLongOrNull()
            return start to total
        }

        private fun truncate(f: File) {
            if (!f.exists()) return
            try {
                RandomAccessFile(f, "rw").use { it.setLength(0) }
            } catch (_: IOException) {
                f.delete()
            }
        }
    }
}
