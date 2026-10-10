package com.kernel.sense_ai

import java.io.File
import java.io.IOException

/**
 * In-memory holder for captured stills and sound clips (guardrails §3, §8
 * amendment). Nothing is written to disk unless [keep] is called for a
 * sighting the user saves with "keep media" on. [clear] zeroes and drops
 * everything. Media is never logged.
 */
class MediaStash(private val filesDir: File) {
    private class Still(val jpeg: ByteArray)
    private class Clip(val pcm: ShortArray, val sampleRate: Int, val labels: List<NativeScoredLabel>)

    private val stills = LinkedHashMap<String, Still>()
    private val clips = LinkedHashMap<String, Clip>()

    @Synchronized
    fun putStill(id: String, jpeg: ByteArray) {
        stills[id] = Still(jpeg)
        while (stills.size > MAX_STILLS) {
            val eldest = stills.keys.first()
            stills.remove(eldest)?.jpeg?.fill(0)
        }
    }

    @Synchronized
    fun putClip(id: String, pcm: ShortArray, sampleRate: Int, labels: List<NativeScoredLabel>) {
        clips[id] = Clip(pcm, sampleRate, labels)
        while (clips.size > MAX_CLIPS) {
            val eldest = clips.keys.first()
            clips.remove(eldest)?.pcm?.fill(0)
        }
    }

    @Synchronized
    fun wav(id: String): ByteArray? = clips[id]?.let { WavWriter.encode(it.pcm, it.sampleRate) }

    @Synchronized
    fun labels(id: String): List<NativeScoredLabel> = clips[id]?.labels.orEmpty()

    @Synchronized
    fun clear() {
        for (s in stills.values) s.jpeg.fill(0)
        for (c in clips.values) c.pcm.fill(0)
        stills.clear()
        clips.clear()
    }

    /**
     * Writes the held full-resolution still (JPEG) or clip (WAV) for [id] to
     * app-private `files/sense_media/` and returns the absolute path; null
     * when nothing is held for [id].
     */
    fun keep(id: String): String? {
        if (!SAFE_ID.matches(id)) return null
        val (bytes, ext) = synchronized(this) {
            stills[id]?.let { it.jpeg.copyOf() to "jpg" }
                ?: clips[id]?.let { WavWriter.encode(it.pcm, it.sampleRate) to "wav" }
                ?: return null
        }
        val dir = File(filesDir, DIR)
        if (!dir.isDirectory && !dir.mkdirs()) return null
        val file = File(dir, "$id.$ext")
        return try {
            val tmp = File(dir, "$id.$ext.part")
            tmp.writeBytes(bytes)
            if (!tmp.renameTo(file)) {
                tmp.delete()
                return null
            }
            file.absolutePath
        } catch (_: IOException) {
            null
        } finally {
            bytes.fill(0)
        }
    }

    companion object {
        const val DIR = "sense_media"
        const val MAX_STILLS = 3
        const val MAX_CLIPS = 30
        private val SAFE_ID = Regex("^[A-Za-z0-9-]{1,64}$")
    }
}
