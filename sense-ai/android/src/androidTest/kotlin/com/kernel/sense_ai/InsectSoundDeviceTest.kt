package com.kernel.sense_ai

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.json.JSONObject
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.DataType
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.MessageDigest
import kotlin.math.abs

/** Synthetic numerical inputs, never claimed as real insect identifications. */
@RunWith(AndroidJUnit4::class)
class InsectSoundDeviceTest {
    private val context = InstrumentationRegistry.getInstrumentation().context
    private fun asset(path: String) = context.assets.open(path).use { it.readBytes() }
    private fun direct(bytes: ByteArray) = ByteBuffer.allocateDirect(bytes.size).order(ByteOrder.nativeOrder()).apply { put(bytes); rewind() }

    @Test fun bundledModelHasExactShapeAndMatchesSafeH5LogitsOnPhone() {
        val model = asset("insect_sound/model.tflite")
        assertEquals(646352, model.size)
        assertEquals("55ad541b87d1ae0bae5a71c7ec9091fc40617051f479ac3f12996bacda6f597e",
            MessageDigest.getInstance("SHA-256").digest(model).joinToString("") { "%02x".format(it) })
        Interpreter(direct(model), Interpreter.Options().setNumThreads(2)).use { net ->
            assertArrayEquals(intArrayOf(1,1,64,201), net.getInputTensor(0).shape())
            assertArrayEquals(intArrayOf(1,32), net.getOutputTensor(0).shape())
            assertEquals(DataType.FLOAT32, net.getInputTensor(0).dataType())
            assertEquals(DataType.FLOAT32, net.getOutputTensor(0).dataType())
            for (name in listOf("mono16","short16","long16","stereo44","mono48")) {
                val features = asset("insect_parity/$name.features.f32")
                val expected = ByteBuffer.wrap(asset("insect_parity/$name.logits.f32")).order(ByteOrder.LITTLE_ENDIAN)
                val size = 64*201*4
                for (offset in features.indices step size) {
                    val output = ByteBuffer.allocateDirect(32*4).order(ByteOrder.nativeOrder())
                    net.run(direct(features.copyOfRange(offset,offset+size)),output)
                    output.rewind()
                    repeat(32) { assertEquals(expected.float, output.float, 1e-4f) }
                }
            }
        }
    }

    @Test fun localWavToRealInferenceMatchesUpstreamProbabilitiesAndHierarchy() {
        val report = JSONObject(String(asset("insect_parity/parity.json")))
        val adapter = InsectSoundAdapter(::asset)
        for (name in listOf("mono16","short16","long16","stereo44","mono48")) {
            val file = File(context.cacheDir,"insect-parity-$name.wav")
            file.writeBytes(asset("insect_parity/$name.wav"))
            try {
                val started = System.nanoTime()
                val result = adapter.classifyWavFile(file.path)
                val case = report.getJSONObject("cases").getJSONObject(name)
                val upstream = case.getJSONObject("upstream")
                assertEquals("evaluated", result["status"])
                assertEquals(upstream.getJSONObject("identification").getString("level"), result["level"])
                assertEquals(upstream.getJSONObject("identification").getString("name"), result["label"])
                assertEquals("0.1.0-experimental", result["modelVersion"])
                assertEquals("001425d7fab4b44af5cc571174410f1c78552d0e", result["modelRevision"])
                assertEquals(case.getInt("rate"),result["sampleRate"])
                assertEquals(case.getInt("samples") * 1000L / case.getInt("rate"), (result["durationMs"] as Number).toLong())
                val top = result["topLabels"] as List<*>
                assertEquals(5,top.size)
                for (i in 0 until 5) {
                    val expected = upstream.getJSONArray("top_k").getJSONObject(i)
                    val actual = top[i] as Map<*,*>
                    assertEquals(expected.getString("species"), actual["label"])
                    assertEquals(expected.getDouble("score"), (actual["score"] as Number).toDouble(), 2e-5)
                }
                println("synthetic parity $name latencyMs=${(System.nanoTime()-started)/1_000_000}")
            } finally { file.delete() }
        }
    }
}
