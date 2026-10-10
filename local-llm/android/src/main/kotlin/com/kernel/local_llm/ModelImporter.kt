package com.kernel.local_llm

import android.content.ContentResolver
import android.net.Uri
import android.os.SystemClock
import android.provider.OpenableColumns
import java.io.File
import java.io.IOException
import java.security.DigestOutputStream
import java.security.MessageDigest
import java.time.Instant

/**
 * Copies a user-picked `.litertlm` (SAF content:// URI) into the
 * [ModelStore] directory. No network: the user already has the file, e.g.
 * from AI Edge Gallery.
 *
 * Steps: check the name and free space (size + 10 %), stream-copy to
 * `<name>.part` while hashing, re-read the copy and compare size and sha256,
 * then replace any previous model, rename and write the sidecar.
 *
 * Blocking; call from an IO thread. Failures come back as a `failed` result
 * with a short technical reason, never as an exception.
 */
class ModelImporter(
    private val resolver: ContentResolver,
    private val store: ModelStore,
    private val emit: (NativeImportProgress) -> Unit,
    /** Called right before the old model is replaced (unloads the engine). */
    private val beforeInstall: () -> Unit,
) {
    fun import(importId: String, contentUri: String): NativeImportProgress {
        var copied = 0L
        var total: Long? = null
        var part: File? = null
        fun failed(reason: String) = progress(importId, NativeImportPhase.FAILED, copied, total, reason)

        try {
            val uri = Uri.parse(contentUri)
            if (uri.scheme != ContentResolver.SCHEME_CONTENT) return failed("not_a_content_uri")
            val (displayName, size) = queryNameAndSize(uri)
            total = size
            val name = ModelStore.sanitizeFileName(displayName) ?: return failed("not_a_litertlm_file")
            val dir = store.dir ?: return failed("storage_unavailable")
            if (!dir.exists() && !dir.mkdirs()) return failed("storage_unavailable")

            if (size != null) {
                val need = ModelStore.requiredFreeBytes(size)
                val free = store.freeSpaceBytes()
                if (free < need) return failed("insufficient_space: need $need bytes, free $free bytes")
            }

            val partFile = File(dir, "$name${ModelStore.PART_EXTENSION}")
            part = partFile
            partFile.delete()

            val digest = MessageDigest.getInstance("SHA-256")
            val input = resolver.openInputStream(uri) ?: return failed("cannot_open_source")
            var lastEmit = 0L
            input.use { src ->
                DigestOutputStream(partFile.outputStream(), digest).use { dst ->
                    val buf = ByteArray(COPY_BUFFER_BYTES)
                    while (true) {
                        val n = src.read(buf)
                        if (n < 0) break
                        dst.write(buf, 0, n)
                        copied += n
                        val now = SystemClock.elapsedRealtime()
                        if (now - lastEmit >= PROGRESS_INTERVAL_MS) {
                            lastEmit = now
                            emit(progress(importId, NativeImportPhase.COPYING, copied, total, null))
                            // Unknown size: stop before the volume fills up.
                            if (size == null && store.freeSpaceBytes() < MIN_FREE_BYTES_WHILE_COPYING) {
                                throw IOException("insufficient_space")
                            }
                        }
                    }
                }
            }
            val copySha = ModelStore.hex(digest.digest())
            emit(progress(importId, NativeImportPhase.COPYING, copied, total, null))

            if (size != null && copied != size) return cleanup(partFile, failed("size_mismatch"))
            if (copied == 0L) return cleanup(partFile, failed("empty_file"))

            // Verify what actually landed on disk.
            emit(progress(importId, NativeImportPhase.VERIFYING, copied, total, null))
            if (partFile.length() != copied) return cleanup(partFile, failed("size_mismatch"))
            val diskSha = partFile.inputStream().use { ModelStore.sha256Hex(it) }
            if (diskSha != copySha) return cleanup(partFile, failed("checksum_mismatch"))

            beforeInstall()
            store.deleteOtherModels(name)
            val target = File(dir, name)
            if (target.exists() && !target.delete()) return cleanup(partFile, failed("replace_failed"))
            if (!partFile.renameTo(target)) return cleanup(partFile, failed("rename_failed"))
            part = null
            store.writeSidecar(ModelFile(target), copySha, Instant.now())
            return progress(importId, NativeImportPhase.DONE, copied, total, null)
        } catch (e: SecurityException) {
            part?.delete()
            return failed("permission_denied")
        } catch (e: IOException) {
            part?.delete()
            return failed(if (e.message == "insufficient_space") "insufficient_space" else "io_error")
        } catch (e: Exception) {
            part?.delete()
            return failed("error_${e.javaClass.simpleName}")
        }
    }

    private fun cleanup(part: File, result: NativeImportProgress): NativeImportProgress {
        part.delete()
        return result
    }

    private fun queryNameAndSize(uri: Uri): Pair<String?, Long?> {
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
            ?.use { c ->
                if (c.moveToFirst()) {
                    val nameIdx = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeIdx = c.getColumnIndex(OpenableColumns.SIZE)
                    val name = if (nameIdx >= 0 && !c.isNull(nameIdx)) c.getString(nameIdx) else null
                    val size = if (sizeIdx >= 0 && !c.isNull(sizeIdx)) c.getLong(sizeIdx).takeIf { it > 0 } else null
                    return name to size
                }
            }
        return null to null
    }

    private fun progress(
        importId: String,
        phase: NativeImportPhase,
        copied: Long,
        total: Long?,
        error: String?,
    ) = NativeImportProgress(
        importId = importId,
        phase = phase,
        bytesCopied = copied,
        totalBytes = total,
        error = error,
    )

    companion object {
        private const val COPY_BUFFER_BYTES = 1 shl 20
        private const val PROGRESS_INTERVAL_MS = 250L

        /** With an unknown source size, abort the copy below this much free space. */
        private const val MIN_FREE_BYTES_WHILE_COPYING = 256L * 1024 * 1024

        /** Display name of a content URI (used by the picker filter). */
        fun displayName(resolver: ContentResolver, uri: Uri): String? = try {
            resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst() && !c.isNull(0)) c.getString(0) else null
            }
        } catch (_: Exception) {
            null
        }
    }
}
