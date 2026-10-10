package com.kernel.local_llm

import com.google.gson.JsonObject
import com.google.gson.JsonParser
import java.io.File
import java.io.InputStream
import java.security.MessageDigest
import java.time.Instant

/** What a model file is for. */
enum class ModelKind {
    /** Gemma: grain advice (text-only engine) and Pest ID (multimodal engine). */
    LLM,

    /** EmbeddingGemma. */
    EMBEDDING,
}

/** An installed `.litertlm` file. */
class ModelFile(val file: File) {
    /** File name without the extension, e.g. "gemma-4-E2B-it". */
    val id: String = file.name.substring(0, file.name.length - ModelStore.EXTENSION.length)

    /** Changes when the file is replaced, so a failed load is not retried forever. */
    val key: String get() = "${file.absolutePath}|${file.length()}|${file.lastModified()}"
}

/** Provenance written next to the model as `<id>.json`. */
data class Sidecar(
    val id: String,
    val version: String,
    val sizeBytes: Long,
    val importedAt: String,
)

/**
 * Model files in app-specific storage (`getExternalFilesDir("llm")`, i.e.
 * `/sdcard/Android/data/<package>/files/llm/`). No permission is needed, no
 * other app can read it on Android 11+, and it is removed on uninstall.
 *
 * Pure java.io so it is unit-testable on the JVM. Never reads or logs model
 * content beyond hashing it.
 */
class ModelStore(
    val dir: File?,
    /**
     * Kind of a model file (production: the LiteRT-LM ModelInfo header,
     * cached). Null when unknown; the file name decides then.
     */
    private val classify: (File) -> ModelKind? = { null },
) {
    /**
     * First `*.litertlm` of [kind] by name. Partial copies (`.part`) are
     * ignored. With only a Gemma file present this is the first file by name,
     * as before; an EmbeddingGemma file next to it is never picked for advice.
     */
    fun findModel(kind: ModelKind = ModelKind.LLM): ModelFile? {
        val files = dir?.listFiles() ?: return null
        return files
            .filter { it.isFile && it.name.endsWith(EXTENSION, ignoreCase = false) && it.length() > 0 }
            .sortedBy { it.name }
            .firstOrNull { kindOf(it) == kind }
            ?.let(::ModelFile)
    }

    private fun kindOf(file: File): ModelKind =
        runCatching { classify(file) }.getOrNull() ?: kindByName(file.name)

    fun sidecarFile(model: ModelFile): File = File(model.file.parentFile, "${model.id}$SIDECAR_EXTENSION")

    /** The sidecar if it exists, parses and still matches the file size. */
    fun readSidecar(model: ModelFile): Sidecar? {
        val f = sidecarFile(model)
        if (!f.isFile) return null
        return try {
            val json = JsonParser.parseString(f.readText(Charsets.UTF_8)).asJsonObject
            val sidecar = Sidecar(
                id = json.get("id").asString,
                version = json.get("version").asString,
                sizeBytes = json.get("sizeBytes").asLong,
                importedAt = json.get("importedAt").asString,
            )
            if (sidecar.id == model.id && sidecar.sizeBytes == model.file.length() &&
                sidecar.version.startsWith("${model.id}@")
            ) {
                sidecar
            } else {
                null
            }
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Sidecar for [model], writing one if it is missing or stale (e.g. the
     * file was copied in with adb). That costs one streamed sha256 pass.
     */
    @Synchronized
    fun ensureSidecar(model: ModelFile): Sidecar {
        readSidecar(model)?.let { return it }
        val sha = model.file.inputStream().use { sha256Hex(it) }
        return writeSidecar(model, sha, Instant.now())
    }

    fun writeSidecar(model: ModelFile, sha256Hex: String, importedAt: Instant): Sidecar {
        val sidecar = Sidecar(
            id = model.id,
            version = versionOf(model.id, sha256Hex),
            sizeBytes = model.file.length(),
            importedAt = importedAt.toString(),
        )
        val json = JsonObject().apply {
            addProperty("id", sidecar.id)
            addProperty("version", sidecar.version)
            addProperty("sizeBytes", sidecar.sizeBytes)
            addProperty("importedAt", sidecar.importedAt)
        }
        val target = sidecarFile(model)
        val tmp = File(target.parentFile, "${target.name}.tmp")
        tmp.writeText(json.toString(), Charsets.UTF_8)
        if (!tmp.renameTo(target)) {
            target.delete()
            if (!tmp.renameTo(target)) {
                tmp.delete()
                throw java.io.IOException("sidecar_write_failed")
            }
        }
        return sidecar
    }

    /**
     * Deletes every model, sidecar and partial copy in [dir]. Returns the
     * number of files deleted; throws if one could not be deleted.
     */
    fun deleteAll(): Int {
        val files = dir?.listFiles() ?: return 0
        var deleted = 0
        for (f in files) {
            if (!f.isFile || !isOwnedName(f.name)) continue
            if (!f.delete() && f.exists()) throw java.io.IOException("delete_failed")
            deleted++
        }
        return deleted
    }

    /** Deletes models (and their sidecars) other than [keepName]. */
    fun deleteOtherModels(keepName: String) {
        val files = dir?.listFiles() ?: return
        val keepSidecar = "${keepName.removeSuffix(EXTENSION)}$SIDECAR_EXTENSION"
        for (f in files) {
            if (!f.isFile || f.name == keepName || f.name == keepSidecar) continue
            if (f.name.endsWith(EXTENSION) || f.name.endsWith(SIDECAR_EXTENSION)) f.delete()
        }
    }

    /** Bytes available to this app in [dir]'s volume; 0 when unknown. */
    fun freeSpaceBytes(): Long {
        val d = dir ?: return 0
        if (!d.exists()) d.mkdirs()
        return d.usableSpace.coerceAtLeast(0)
    }

    companion object {
        const val EXTENSION = ".litertlm"
        const val SIDECAR_EXTENSION = ".json"
        const val PART_EXTENSION = ".part"

        /** Characters of the version that come from the sha256. */
        const val VERSION_HASH_CHARS = 12

        private const val MAX_NAME_CHARS = 120

        fun versionOf(id: String, sha256Hex: String): String = "$id@${sha256Hex.take(VERSION_HASH_CHARS)}"

        /** Fallback when the header cannot be read: "embed" in the name means EmbeddingGemma. */
        fun kindByName(name: String): ModelKind =
            if (name.lowercase().contains("embed")) ModelKind.EMBEDDING else ModelKind.LLM

        /** Space needed to import a file of [sizeBytes]: size plus 10 %. */
        fun requiredFreeBytes(sizeBytes: Long): Long = sizeBytes + sizeBytes / 10

        /**
         * Safe on-disk name for a picked document, or null when it is not a
         * `.litertlm` file. Keeps letters, digits, '.', '-' and '_' only, so
         * the name can never contain a path separator or "..".
         */
        fun sanitizeFileName(displayName: String?): String? {
            if (displayName == null) return null
            val trimmed = displayName.trim()
            if (!trimmed.lowercase().endsWith(EXTENSION)) return null
            val base = trimmed.substring(0, trimmed.length - EXTENSION.length)
            val safe = base
                .map { c -> if (c.isLetterOrDigit() && c.code < 128 || c == '-' || c == '_' || c == '.') c else '_' }
                .joinToString("")
                .replace(Regex("\\.{2,}"), ".")
                .trim('.', '_')
                .take(MAX_NAME_CHARS)
            if (safe.isEmpty()) return null
            return "$safe$EXTENSION"
        }

        private fun isOwnedName(name: String): Boolean =
            name.endsWith(EXTENSION) ||
                name.endsWith(SIDECAR_EXTENSION) ||
                name.endsWith(PART_EXTENSION) ||
                name.endsWith("$SIDECAR_EXTENSION.tmp")

        /** Streamed sha256 of [input], lowercase hex. */
        fun sha256Hex(input: InputStream, onBytes: ((Long) -> Unit)? = null): String {
            val digest = MessageDigest.getInstance("SHA-256")
            val buf = ByteArray(1 shl 20)
            var total = 0L
            while (true) {
                val n = input.read(buf)
                if (n < 0) break
                digest.update(buf, 0, n)
                total += n
                onBytes?.invoke(total)
            }
            return hex(digest.digest())
        }

        fun hex(bytes: ByteArray): String {
            val out = StringBuilder(bytes.size * 2)
            for (b in bytes) {
                val v = b.toInt() and 0xFF
                out.append(HEX[v ushr 4]).append(HEX[v and 0x0F])
            }
            return out.toString()
        }

        private val HEX = "0123456789abcdef".toCharArray()
    }
}
