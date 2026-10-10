package com.kernel.model_hub

import java.io.File

data class ModelFileInfo(val path: String, val sizeBytes: Long, val modifiedMs: Long)

/**
 * Lists and removes model files in Kernel's own storage (pure JVM):
 * - [modelsDir]: getExternalFilesDir(null)/models (downloads, nested by repo/revision)
 * - [legacyDir]: getExternalFilesDir("llm") (earlier imports and adb copies),
 *   scanned so a file copied from AI Edge Gallery is recognised by sha256.
 *
 * Partial downloads (*.part), sidecars and anything outside these two roots
 * are never listed or deleted.
 */
class ModelStorage(val modelsDir: File?, val legacyDir: File?) {
    fun list(): List<ModelFileInfo> {
        val out = ArrayList<ModelFileInfo>()
        modelsDir?.let { walk(it, MODELS_DEPTH, out) }
        legacyDir?.let { walk(it, LEGACY_DEPTH, out) }
        return out.distinctBy { it.path }.sortedBy { it.path }
    }

    fun isManaged(file: File): Boolean =
        (modelsDir != null && ModelPaths.isInside(modelsDir, file)) ||
            (legacyDir != null && ModelPaths.isInside(legacyDir, file))

    /** Deletes a model file (and its partial download). False when refused. */
    fun remove(path: String): Boolean {
        val f = File(path)
        if (!isManaged(f) || !isModelFile(f)) return false
        ResumableDownloader.partFile(f).delete()
        val ok = !f.exists() || f.delete()
        if (ok) pruneEmptyParents(f.parentFile)
        return ok
    }

    private fun pruneEmptyParents(start: File?) {
        val root = modelsDir?.canonicalFile ?: return
        var d = start?.canonicalFile
        while (d != null && d != root && ModelPaths.isInside(root, d)) {
            val children = d.list() ?: return
            if (children.isNotEmpty() || !d.delete()) return
            d = d.parentFile
        }
    }

    private fun walk(dir: File, depth: Int, out: MutableList<ModelFileInfo>) {
        if (depth < 0 || !dir.isDirectory) return
        val children = dir.listFiles() ?: return
        for (c in children) {
            if (c.isDirectory) {
                walk(c, depth - 1, out)
            } else if (c.isFile && isModelFile(c) && c.length() > 0) {
                out.add(ModelFileInfo(c.absolutePath, c.length(), c.lastModified()))
            }
        }
    }

    companion object {
        private const val MODELS_DEPTH = 4
        private const val LEGACY_DEPTH = 2

        fun isModelFile(f: File): Boolean {
            val name = f.name
            if (name.endsWith(ModelPaths.PART_SUFFIX) || name.startsWith(".")) return false
            return name.substringAfterLast('.', "").lowercase() in ModelPaths.MODEL_EXTENSIONS
        }
    }
}
