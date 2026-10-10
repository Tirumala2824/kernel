package com.kernel.sensor_link

import java.io.File
import org.json.JSONArray
import org.json.JSONObject

/** Loads the shared fixtures from firmware/reference/vectors (exported by kernel_ref). */
object Vectors {
    private val dir: File by lazy {
        val prop = System.getProperty("kernel.vectors")
        val candidates = listOfNotNull(prop, "../../firmware/reference/vectors", "../firmware/reference/vectors")
        candidates.map(::File).firstOrNull { File(it, "protocol_v1.json").isFile }
            ?: error("firmware/reference/vectors not found (tried $candidates)")
    }

    fun json(name: String): JSONObject = JSONObject(File(dir, name).readText(Charsets.UTF_8))

    fun detectFiles(): List<File> = dir.listFiles { f -> f.name.startsWith("detect_") && f.name.endsWith(".json") }
        ?.sortedBy { it.name } ?: emptyList()

    fun detect(file: File): JSONObject = JSONObject(file.readText(Charsets.UTF_8))
}

fun JSONArray.objects(): List<JSONObject> = (0 until length()).map { getJSONObject(it) }

fun JSONArray.ints(): List<Int> = (0 until length()).map { getInt(it) }
