package com.kernel.audio_ai

import android.content.Context
import android.util.Log
import org.tensorflow.lite.DataType
import org.tensorflow.lite.Interpreter
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Loads the bundled LiteRT model (if any) and runs it on the CPU.
 *
 * The model is a versioned asset: `src/main/assets/models/<name>.tflite`
 * plus `<name>.properties` (see [ModelManifest]). Nothing is downloaded and
 * nothing is learned on device. Today no model is bundled, so [status] is
 * [Status.Absent]. The engine then reports modelVersion "none" and
 * NOT_EVALUATED, and never produces a class.
 *
 * Delegate: CPU only. NNAPI/GPU will only be enabled after an on-device
 * benchmark shows them faster for the real model (PRD tech table).
 */
class ModelRunner(private val context: Context) {

    sealed interface Status {
        /** No .tflite asset bundled. */
        data object Absent : Status

        /** A model file exists but cannot be used safely (reason is technical, for logs). */
        data class Unusable(val reason: String) : Status

        class Ready internal constructor(
            val manifest: ModelManifest,
            internal val interpreter: Interpreter,
            internal val frames: Int,
        ) : Status
    }

    private var cached: Status? = null

    @Synchronized
    fun status(): Status = cached ?: load().also {
        cached = it
        when (it) {
            is Status.Absent -> Log.i(TAG, "no model bundled; scans are NOT_EVALUATED")
            is Status.Unusable -> Log.w(TAG, "bundled model unusable: ${it.reason}")
            is Status.Ready -> Log.i(TAG, "model ${it.manifest.version} loaded (CPU)")
        }
    }

    /** [NoModel] unless a real model is loaded and validated. */
    fun handle(): ModelHandle {
        val ready = status() as? Status.Ready ?: return NoModel
        return object : ModelHandle {
            override val version: String = ready.manifest.version
            override val experimental: Boolean = ready.manifest.experimental
            override val logMelConfig: LogMelConfig = ready.manifest.logMel
            override fun classify(logMel: LogMelResult): Prediction? = this@ModelRunner.classify(logMel)
        }
    }

    /**
     * Runs the model on [logMel] (computed with the manifest's config).
     * Returns null, never a guess, if the model is not ready or anything about
     * the input/output is off.
     */
    @Synchronized
    fun classify(logMel: LogMelResult): Prediction? {
        val ready = status() as? Status.Ready ?: return null
        val manifest = ready.manifest
        if (logMel.nMels != manifest.logMel.nMels || logMel.frames < ready.frames) {
            Log.w(TAG, "log-mel ${logMel.frames}x${logMel.nMels} does not fit model input ${ready.frames}x${manifest.logMel.nMels}")
            return null
        }
        return try {
            val input = ByteBuffer.allocateDirect(ready.frames * logMel.nMels * FLOAT_BYTES)
                .order(ByteOrder.nativeOrder())
            // Uses the first `frames` frames. The capture is sized for the model window.
            when (manifest.inputLayout) {
                InputLayout.FRAMES_MELS ->
                    for (t in 0 until ready.frames) for (m in 0 until logMel.nMels) input.putFloat(logMel[t, m])
                InputLayout.MELS_FRAMES ->
                    for (m in 0 until logMel.nMels) for (t in 0 until ready.frames) input.putFloat(logMel[t, m])
            }
            input.rewind()
            val output = arrayOf(FloatArray(manifest.labels.size))
            ready.interpreter.run(input, output)
            manifest.interpret(output[0])
        } catch (e: RuntimeException) {
            Log.w(TAG, "inference failed: ${e.javaClass.simpleName}: ${e.message}")
            null
        }
    }

    @Synchronized
    fun close() {
        (cached as? Status.Ready)?.interpreter?.close()
        cached = null
    }

    private fun load(): Status {
        val names = try {
            context.assets.list(MODELS_DIR)?.toList() ?: emptyList()
        } catch (e: IOException) {
            emptyList()
        }
        val models = names.filter { it.endsWith(MODEL_SUFFIX) }.sorted()
        if (models.isEmpty()) return Status.Absent
        if (models.size > 1) return Status.Unusable("more than one model bundled: $models")

        val modelName = models.single()
        val manifestName = modelName.removeSuffix(MODEL_SUFFIX) + MANIFEST_SUFFIX
        if (manifestName !in names) return Status.Unusable("missing $MODELS_DIR/$manifestName")

        val manifest = try {
            ModelManifest.parse(readAssetText("$MODELS_DIR/$manifestName"))
        } catch (e: IllegalArgumentException) {
            return Status.Unusable("invalid manifest: ${e.message}")
        } catch (e: IOException) {
            return Status.Unusable("cannot read manifest: ${e.message}")
        }

        val interpreter = try {
            Interpreter(readAssetDirect("$MODELS_DIR/$modelName"), Interpreter.Options().setNumThreads(CPU_THREADS))
        } catch (e: Throwable) {
            // Includes UnsatisfiedLinkError if the LiteRT native library is missing for this ABI.
            return Status.Unusable("cannot load model: ${e.javaClass.simpleName}: ${e.message}")
        }

        val frames = try {
            validateTensors(interpreter, manifest)
        } catch (e: IllegalStateException) {
            interpreter.close()
            return Status.Unusable(e.message ?: "tensor mismatch")
        }
        return Status.Ready(manifest, interpreter, frames)
    }

    /** Checks the model's tensors against the manifest. Returns the expected frame count. */
    private fun validateTensors(interpreter: Interpreter, manifest: ModelManifest): Int {
        check(interpreter.inputTensorCount == 1) { "model must have one input" }
        check(interpreter.outputTensorCount == 1) { "model must have one output" }
        val input = interpreter.getInputTensor(0)
        val output = interpreter.getOutputTensor(0)
        check(input.dataType() == DataType.FLOAT32) { "input must be float32 (quantised input is not supported yet)" }
        check(output.dataType() == DataType.FLOAT32) { "output must be float32" }

        val shape = input.shape()
        check(shape.size == 3 || (shape.size == 4 && shape[3] == 1)) { "input shape ${shape.contentToString()} not supported" }
        check(shape[0] == 1) { "input batch must be 1" }
        val nMels = manifest.logMel.nMels
        val frames = when (manifest.inputLayout) {
            InputLayout.MELS_FRAMES -> { check(shape[1] == nMels) { "input mel dim ${shape[1]} != n_mels $nMels" }; shape[2] }
            InputLayout.FRAMES_MELS -> { check(shape[2] == nMels) { "input mel dim ${shape[2]} != n_mels $nMels" }; shape[1] }
        }
        check(frames > 0) { "input frame dim must be positive" }

        val outShape = output.shape()
        check(outShape.contentEquals(intArrayOf(1, manifest.labels.size))) {
            "output shape ${outShape.contentToString()} != [1, ${manifest.labels.size}]"
        }
        return frames
    }

    private fun readAssetText(path: String): String =
        context.assets.open(path).use { it.readBytes().toString(Charsets.UTF_8) }

    /** Copies the asset into a direct buffer, so it works whether or not the APK compresses it. */
    private fun readAssetDirect(path: String): ByteBuffer {
        val bytes = context.assets.open(path).use { it.readBytes() }
        return ByteBuffer.allocateDirect(bytes.size).order(ByteOrder.nativeOrder()).apply {
            put(bytes)
            rewind()
        }
    }

    companion object {
        private const val TAG = "AudioAi"
        const val MODELS_DIR = "models"
        const val MODEL_SUFFIX = ".tflite"
        const val MANIFEST_SUFFIX = ".properties"
        private const val FLOAT_BYTES = 4

        /** CPU baseline. Re-tune from the iQOO 15 benchmark once a model exists. */
        const val CPU_THREADS = 4
    }
}
