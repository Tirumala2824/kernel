package com.kernel.sense_ai

import java.io.File
import java.io.InputStream
import java.io.IOException
import java.util.UUID

internal data class ChatMediaLease(val token: String, val file: File, val fileName: String) {
    fun asMap(): Map<String, String> = mapOf("token" to token, "path" to file.path, "fileName" to fileName)
}

/** App-private, token-addressed media. Never takes a document path for deletion. */
internal class ChatMediaStore(cacheDir: File) {
    private val cachePath = cacheDir.absoluteFile
    private val cache = cacheDir.canonicalFile
    val directory = File(cache, "kernel_chat_media_v1")
    private val owned = mutableMapOf<String, File>()

    init {
        // Called once per process/cache root by shared(), before any imports.
        // Never sweep ImagePicker's cache or other app data.
        if (directory.isDirectory && directory.canonicalFile == directory.absoluteFile) {
            directory.listFiles().orEmpty().filter {
                OWNED_NAME.matches(it.name) && it.isFile && it.canonicalFile == it.absoluteFile
            }.forEach { it.delete() }
        }
    }

    companion object {
        private val UUID_NAME = Regex("[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}")
        private val OWNED_NAME = Regex("${UUID_NAME.pattern}\\.(wav|image)")
        private val instances = mutableMapOf<File, ChatMediaStore>()
        @Synchronized fun shared(cache: File): ChatMediaStore =
            instances.getOrPut(cache.canonicalFile) { ChatMediaStore(cache) }
    }

    private fun ensureDirectory() {
        if (directory.canonicalFile != directory.absoluteFile ||
            (!directory.isDirectory && !directory.mkdirs() && !directory.isDirectory)) throw IOException("media_storage_unavailable")
    }

    fun importWav(name: String, size: Long?, open: () -> InputStream): ChatMediaLease {
        if (!Regex("(?i).*\\.(wav|wave)$").matches(name)) throw IOException("unsupported_wav")
        if (size == 0L || (size != null && size > InsectWav.MAX_BYTES)) throw IOException("wav_size_limit")
        ensureDirectory()
        val token = UUID.randomUUID().toString()
        val file = File(directory, "$token.wav")
        try {
            open().use { input ->
                file.outputStream().use { output ->
                    val buffer = ByteArray(8192)
                    var total = 0
                    while (true) {
                        // Probe only one byte beyond the cap, never write it.
                        val count = input.read(buffer, 0, minOf(buffer.size, InsectWav.MAX_BYTES - total + 1))
                        if (count < 0) break
                        if (count == 0) throw IOException("unreadable_wav")
                        total += count
                        if (total > InsectWav.MAX_BYTES) throw IOException("wav_size_limit")
                        output.write(buffer, 0, count)
                    }
                    if (total == 0) throw IOException("empty_wav")
                }
            }
            synchronized(this) { owned[token] = file }
            return ChatMediaLease(token, file, name)
        } catch (error: Exception) {
            file.delete()
            throw error
        }
    }

    @Synchronized fun adoptImagePickerCopy(path: String): ChatMediaLease? {
        val selected = File(path).absoluteFile
        // Android may expose its trusted cache root through /data/user/0.
        // Resolve that root alias, but reject traversal/symlinks beneath it.
        val root = listOf(cachePath, cache).firstOrNull {
            selected.path.startsWith(it.path + File.separator)
        } ?: return null
        val relative = selected.path.substring(root.path.length + 1)
        if (relative.split(File.separatorChar).any { it == "." || it == ".." }) return null
        val source = File(cache, relative)
        if (selected.canonicalFile != source) return null
        // Both containment and the currently pinned ImagePicker layout must
        // match. An arbitrary selected path is NOT evidence of ownership.
        // ImagePicker may also leave unreturned resize intermediates; their
        // provenance is unavailable here, so never sweep its shared cache.
        if (!source.isFile || source.canonicalFile != source) return null
        val parent = source.parentFile ?: return null
        val inUuidDirectory = parent.parentFile == cache && UUID_NAME.matches(parent.name) &&
            parent.canonicalFile == parent
        val directPickerFile = parent == cache &&
            (source.name.startsWith("scaled_") || Regex("${UUID_NAME.pattern}[0-9]+\\.jpg").matches(source.name))
        if (!inUuidDirectory && !directPickerFile) return null
        ensureDirectory()
        val token = UUID.randomUUID().toString()
        val target = File(directory, "$token.image")
        if (!source.renameTo(target)) throw IOException("media_storage_unavailable")
        owned[token] = target
        if (inUuidDirectory) parent.delete() // Empty directory only, never recursive.
        return ChatMediaLease(token, target, source.name)
    }

    @Synchronized fun release(token: String) {
        val file = owned[token] ?: return
        if (directory.canonicalFile != directory.absoluteFile ||
            file.canonicalFile != file.absoluteFile || file.parentFile != directory) return
        if (file.exists() && !file.delete()) throw IOException("media_cleanup_failed")
        owned.remove(token)
    }
}
