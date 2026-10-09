package com.kernel.audio_ai

import java.io.File
import java.io.IOException

/**
 * The only place audio is ever persisted, and only under the user's explicit
 * retain-audio opt-in: app-private `files/recordings/<scanId>.wav`. Nothing
 * here touches shared storage or the network.
 */
class RecordingStore(filesDir: File) {
    val directory = File(filesDir, DIR_NAME)

    /** Saves [pcm] as `<scanId>.wav`. Returns the file, or null if [scanId] is not a UUID. */
    fun save(scanId: String, pcm: ShortArray, sampleRate: Int): File? {
        if (!UUID_PATTERN.matches(scanId)) return null // never build paths from arbitrary input
        if (!directory.isDirectory && !directory.mkdirs()) return null
        val file = File(directory, "$scanId.wav")
        WavWriter.write(file, pcm, sampleRate)
        return file
    }

    /**
     * Absolute path of the retained `<scanId>.wav`, or null if [scanId] is not
     * a UUID or no such recording exists. Writes are atomic (temp file plus
     * rename), so an existing file is always a complete WAV.
     */
    fun pathFor(scanId: String): String? {
        if (!UUID_PATTERN.matches(scanId)) return null
        val file = File(directory, "$scanId.wav")
        return if (file.isFile) file.absolutePath else null
    }

    /**
     * Deletes every retained recording. Returns the number of files removed.
     * Throws IOException if any file is left behind, so a failed privacy
     * delete is never reported as success.
     */
    @Throws(IOException::class)
    fun deleteAll(): Int {
        val files = directory.listFiles() ?: return 0
        var deleted = 0
        var failed = 0
        for (f in files) {
            if (!f.isFile) continue
            if (f.delete()) deleted++ else failed++
        }
        if (failed > 0) throw IOException("$failed retained recording(s) could not be deleted")
        return deleted
    }

    companion object {
        const val DIR_NAME = "recordings"
        private val UUID_PATTERN =
            Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
    }
}
