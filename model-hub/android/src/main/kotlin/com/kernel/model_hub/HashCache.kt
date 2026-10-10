package com.kernel.model_hub

import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.security.MessageDigest

/**
 * sha256 of large model files, computed once and cached by
 * (path, size, mtime). A file that changes size or mtime is hashed again.
 *
 * Persisted as a small tab-separated file in app-private storage:
 *   sha256 \t size \t mtime \t path
 * (pure JVM, unit tested; no JSON dependency).
 */
class HashCache(private val store: File) {
    private data class Entry(val size: Long, val mtime: Long, val sha256: String)

    private val entries = HashMap<String, Entry>()
    private var loaded = false

    @Synchronized
    fun get(file: File): String? {
        load()
        val e = entries[file.path] ?: return null
        return if (file.isFile && e.size == file.length() && e.mtime == file.lastModified()) e.sha256 else null
    }

    @Synchronized
    fun put(file: File, sha256: String) {
        load()
        entries[file.path] = Entry(file.length(), file.lastModified(), sha256.lowercase())
        save()
    }

    @Synchronized
    fun forget(path: String) {
        load()
        if (entries.remove(path) != null) save()
    }

    /**
     * Cached sha256, or computes it now (call from a background thread).
     * Null when cancelled or the file is unreadable.
     */
    fun sha256(file: File, cancelled: () -> Boolean = { false }): String? {
        get(file)?.let { return it }
        val sha = sha256Of(file, cancelled) ?: return null
        put(file, sha)
        return sha
    }

    private fun load() {
        if (loaded) return
        loaded = true
        if (!store.isFile) return
        try {
            store.forEachLine { line ->
                val p = line.split('\t', limit = 4)
                if (p.size == 4 && ModelPaths.SHA256.matches(p[0])) {
                    val size = p[1].toLongOrNull()
                    val mtime = p[2].toLongOrNull()
                    if (size != null && mtime != null) entries[p[3]] = Entry(size, mtime, p[0])
                }
            }
        } catch (_: IOException) {
            entries.clear()
        }
    }

    private fun save() {
        try {
            store.parentFile?.mkdirs()
            val tmp = File(store.path + ".tmp")
            tmp.bufferedWriter().use { w ->
                for ((path, e) in entries) {
                    if (path.contains('\n')) continue
                    w.write("${e.sha256}\t${e.size}\t${e.mtime}\t$path\n")
                }
            }
            if (!tmp.renameTo(store)) {
                store.delete()
                tmp.renameTo(store)
            }
        } catch (_: IOException) {
            // A lost cache only costs a re-hash.
        }
    }

    companion object {
        private const val BUFFER = 1 shl 20

        /** Streams the whole file through SHA-256. Null when cancelled/unreadable. */
        fun sha256Of(file: File, cancelled: () -> Boolean = { false }): String? = try {
            val md = MessageDigest.getInstance("SHA-256")
            FileInputStream(file).use { input ->
                val buf = ByteArray(BUFFER)
                while (true) {
                    if (cancelled()) return null
                    val n = input.read(buf)
                    if (n < 0) break
                    md.update(buf, 0, n)
                }
            }
            md.digest().joinToString("") { "%02x".format(it) }
        } catch (_: IOException) {
            null
        }
    }
}
