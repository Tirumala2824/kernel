package com.kernel.local_llm

import com.google.gson.JsonObject
import com.google.gson.JsonParser
import java.io.File
import java.io.IOException
import java.security.MessageDigest

/**
 * Model paths handed over from Dart (the model-hub resolver) are accepted
 * only when they name an existing, non-empty `.litertlm` file inside the
 * app's own storage, after symlinks and ".." are resolved. Pure java.io.
 */
object PathPolicy {
    private const val MAX_PATH_CHARS = 4096

    /** The canonical file, or null when [path] is not acceptable. */
    fun check(path: String, roots: List<File>): File? {
        if (path.isEmpty() || path.length > MAX_PATH_CHARS || path.indexOf('\u0000') >= 0) return null
        val raw = File(path)
        if (!raw.isAbsolute) return null
        val file = runCatching { raw.canonicalFile }.getOrNull() ?: return null
        if (!file.name.endsWith(ModelStore.EXTENSION) || !file.isFile || file.length() <= 0) return null
        return if (roots.any { isInside(file, it) }) file else null
    }

    /** True when [file] (canonical) lies strictly below [root]. */
    fun isInside(file: File, root: File): Boolean {
        val r = runCatching { root.canonicalFile }.getOrNull() ?: return false
        return file.path.startsWith(r.path + File.separator)
    }
}

/** Provenance of a model file: `<id>@<first 12 hex chars of its sha256>`. */
data class ModelIdentity(val id: String, val version: String, val sizeBytes: Long)

/** A model file chosen for one request. [legacy] = found in getExternalFilesDir("llm"). */
class ResolvedModel(val file: ModelFile, val legacy: Boolean)

/**
 * Turns a Dart-side model path (or null) into a model file.
 *
 * - null: legacy discovery, the first model of the requested kind in
 *   getExternalFilesDir("llm") (ModelStore), exactly as before Phase 4.
 * - a path: must pass [PathPolicy] against [roots], and must not be known to
 *   be the wrong kind of model (e.g. an EmbeddingGemma file for advice).
 *
 * Versions of legacy files come from their sidecar (ModelStore). Files
 * elsewhere are hashed once; the result is cached in [versionDir] by
 * path, size and modification time. Nothing is ever written next to a
 * model that local-llm does not own.
 */
class ModelResolver(
    private val store: ModelStore,
    private val roots: () -> List<File>,
    private val versionDir: File?,
    private val kindOf: (File) -> ModelKind?,
) {
    fun resolve(modelPath: String?, kind: ModelKind): ResolvedModel? {
        if (modelPath == null) return store.findModel(kind)?.let { ResolvedModel(it, legacy = true) }
        val file = PathPolicy.check(modelPath, roots()) ?: return null
        val known = runCatching { kindOf(file) }.getOrNull()
        if (known != null && known != kind) return null
        val inStore = store.dir?.let { file.parentFile?.canonicalPath == runCatching { it.canonicalPath }.getOrNull() } ?: false
        return ResolvedModel(ModelFile(file), legacy = inStore)
    }

    @Synchronized
    fun identity(model: ResolvedModel): ModelIdentity {
        if (model.legacy) {
            val s = store.ensureSidecar(model.file)
            return ModelIdentity(s.id, s.version, s.sizeBytes)
        }
        val file = model.file.file
        val size = file.length()
        val modified = file.lastModified()
        val cache = versionDir?.let { File(it, cacheName(file.path)) }
        cache?.let { readCached(it, file.path, size, modified) }?.let { return ModelIdentity(model.file.id, it, size) }
        val sha = file.inputStream().use { ModelStore.sha256Hex(it) }
        val version = ModelStore.versionOf(model.file.id, sha)
        cache?.let { runCatching { writeCached(it, file.path, size, modified, version) } }
        return ModelIdentity(model.file.id, version, size)
    }

    companion object {
        fun cacheName(path: String): String {
            val digest = MessageDigest.getInstance("SHA-256").digest(path.toByteArray(Charsets.UTF_8))
            return ModelStore.hex(digest).take(24) + ".json"
        }

        fun readCached(cache: File, path: String, size: Long, modified: Long): String? {
            if (!cache.isFile) return null
            return try {
                val json = JsonParser.parseString(cache.readText(Charsets.UTF_8)).asJsonObject
                val ok = json.get("path").asString == path &&
                    json.get("sizeBytes").asLong == size &&
                    json.get("modified").asLong == modified
                if (ok) json.get("version").asString else null
            } catch (_: Exception) {
                null
            }
        }

        fun writeCached(cache: File, path: String, size: Long, modified: Long, version: String) {
            cache.parentFile?.mkdirs()
            val json = JsonObject().apply {
                addProperty("path", path)
                addProperty("sizeBytes", size)
                addProperty("modified", modified)
                addProperty("version", version)
            }
            val tmp = File(cache.parentFile, "${cache.name}.tmp")
            tmp.writeText(json.toString(), Charsets.UTF_8)
            if (!tmp.renameTo(cache)) {
                cache.delete()
                if (!tmp.renameTo(cache)) {
                    tmp.delete()
                    throw IOException("version_cache_write_failed")
                }
            }
        }
    }
}
