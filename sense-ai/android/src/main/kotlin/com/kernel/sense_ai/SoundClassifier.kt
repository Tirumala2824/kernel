package com.kernel.sense_ai

import org.tensorflow.lite.DataType
import org.tensorflow.lite.Interpreter
import java.io.Closeable
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import java.util.zip.ZipFile

/**
 * YAMNet-class sound classifier on the LiteRT 1.4.2 interpreter (CPU).
 * Input: [ListenPipeline.WINDOW_SAMPLES] float32 samples in [-1, 1].
 * Output: [SoundPreFilter.YAMNET_CLASSES] scores (averaged over frames when
 * the model returns several).
 *
 * The model file is resolved by the app (model-hub) and passed in as a
 * path; nothing is bundled or downloaded here. Label names are read from
 * the label list embedded in the model's metadata when present.
 */
class SoundClassifier private constructor(
    private val interpreter: Interpreter,
    private val outputIndex: Int,
    val labels: List<String>?,
    val name: String,
) : Closeable {
    private val input = ByteBuffer.allocateDirect(ListenPipeline.WINDOW_SAMPLES * 4).order(ByteOrder.nativeOrder())

    /** Null when inference fails; the event is then reported without labels. */
    @Synchronized
    fun classify(window: FloatArray): FloatArray? = try {
        input.rewind()
        for (i in 0 until ListenPipeline.WINDOW_SAMPLES) input.putFloat(window.getOrElse(i) { 0f })
        input.rewind()
        val outTensor = interpreter.getOutputTensor(outputIndex)
        val count = outTensor.numElements()
        val out = ByteBuffer.allocateDirect(count * 4).order(ByteOrder.nativeOrder())
        interpreter.runForMultipleInputsOutputs(arrayOf<Any>(input), mapOf<Int, Any>(outputIndex to out))
        out.rewind()
        val classes = SoundPreFilter.YAMNET_CLASSES
        val frames = count / classes
        val scores = FloatArray(classes)
        for (f in 0 until frames) for (c in 0 until classes) scores[c] += out.getFloat() / frames
        scores
    } catch (_: RuntimeException) {
        null
    }

    @Synchronized
    override fun close() {
        try {
            interpreter.close()
        } catch (_: RuntimeException) {
            // Already closed.
        }
    }

    companion object {
        /** Null when the file is missing or is not a usable YAMNet-class model. */
        fun open(path: String?): SoundClassifier? {
            if (path.isNullOrBlank()) return null
            val file = File(path)
            if (!file.isFile || !file.canRead()) return null
            var interpreter: Interpreter? = null
            return try {
                val model = RandomAccessFile(file, "r").use { raf ->
                    raf.channel.map(FileChannel.MapMode.READ_ONLY, 0, raf.length())
                }
                val interp = Interpreter(model, Interpreter.Options().setNumThreads(2))
                interpreter = interp
                val inT = interp.getInputTensor(0)
                if (inT.dataType() != DataType.FLOAT32) return null.also { interp.close() }
                if (inT.numElements() != ListenPipeline.WINDOW_SAMPLES) {
                    val shape = inT.shape()
                    val resized = if (shape.size == 2) intArrayOf(1, ListenPipeline.WINDOW_SAMPLES) else intArrayOf(ListenPipeline.WINDOW_SAMPLES)
                    interp.resizeInput(0, resized)
                }
                interp.allocateTensors()
                var scoresIndex = -1
                for (i in 0 until interp.outputTensorCount) {
                    val t = interp.getOutputTensor(i)
                    val s = t.shape()
                    if (t.dataType() == DataType.FLOAT32 && s.isNotEmpty() && s.last() == SoundPreFilter.YAMNET_CLASSES) {
                        scoresIndex = i
                        break
                    }
                }
                if (scoresIndex < 0) return null.also { interp.close() }
                SoundClassifier(interp, scoresIndex, readLabels(file), file.name)
            } catch (_: Exception) {
                interpreter?.close()
                null
            } catch (_: LinkageError) {
                interpreter?.close()
                null
            }
        }

        /**
         * TFLite metadata packs associated files (the label list) as a zip
         * appended to the flatbuffer. Accepts a plain list or the YAMNet
         * class-map CSV (index,mid,display_name).
         */
        fun readLabels(file: File): List<String>? = try {
            ZipFile(file).use { zip ->
                val entry = zip.entries().asSequence().firstOrNull { e ->
                    !e.isDirectory && (e.name.endsWith(".txt") || e.name.endsWith(".csv"))
                } ?: return null
                val lines = zip.getInputStream(entry).bufferedReader().readLines().map { it.trim() }.filter { it.isNotEmpty() }
                val names = if (lines.firstOrNull()?.startsWith("index,") == true) {
                    lines.drop(1).map { csvLast(it) }
                } else {
                    lines
                }
                names.takeIf { it.size == SoundPreFilter.YAMNET_CLASSES }
            }
        } catch (_: Exception) {
            null
        }

        private fun csvLast(line: String): String {
            // display_name may be quoted and contain commas: 2 fields before it.
            var commas = 0
            for (i in line.indices) {
                if (line[i] == ',') {
                    commas++
                    if (commas == 2) return line.substring(i + 1).trim().removeSurrounding("\"")
                }
            }
            return line
        }
    }
}
