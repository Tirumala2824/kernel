package com.kernel.model_hub

import java.io.File
import java.io.IOException

/**
 * Storage layout for downloaded models (pure JVM, unit tested):
 *
 *   getExternalFilesDir(null)/models/{repoId with '/' -> '__'}/{revision}/{file}
 *
 * Every segment is validated so a catalog value can never escape the models
 * directory.
 */
object ModelPaths {
    const val PART_SUFFIX = ".part"

    /** Model file extensions the registry lists. */
    val MODEL_EXTENSIONS = setOf("litertlm", "tflite", "task")

    private val SAFE_SEGMENT = Regex("^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")
    private val REVISION = Regex("^[0-9a-f]{40}$")
    val SHA256 = Regex("^[0-9a-f]{64}$")

    fun isSafeSegment(s: String): Boolean =
        SAFE_SEGMENT.matches(s) && s != "." && s != ".." && !s.contains("..")

    /** 'litert-community/gemma' -> 'litert-community__gemma'. Null if unsafe. */
    fun repoDirName(repoId: String): String? {
        val parts = repoId.split('/')
        if (parts.isEmpty() || parts.size > 4) return null
        if (!parts.all(::isSafeSegment)) return null
        return parts.joinToString("__")
    }

    fun isPinnedRevision(revision: String): Boolean = REVISION.matches(revision)

    fun isModelFileName(fileName: String): Boolean {
        if (!isSafeSegment(fileName)) return false
        return fileName.substringAfterLast('.', "").lowercase() in MODEL_EXTENSIONS
    }

    /** The canonical install path, or null when any segment is invalid. */
    fun targetFile(modelsDir: File, repoId: String, revision: String, fileName: String): File? {
        val repoDir = repoDirName(repoId) ?: return null
        if (!isPinnedRevision(revision)) return null
        if (!isModelFileName(fileName)) return null
        val f = File(File(File(modelsDir, repoDir), revision), fileName)
        return if (isInside(modelsDir, f)) f else null
    }

    /** True when [file] resolves to a path strictly inside [root]. */
    fun isInside(root: File, file: File): Boolean = try {
        val r = root.canonicalFile.path + File.separator
        file.canonicalFile.path.startsWith(r)
    } catch (_: IOException) {
        false
    }
}
