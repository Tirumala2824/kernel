package com.kernel.audio_ai

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import kotlin.math.abs
import kotlin.math.exp
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ModelManifestTest {
    private val valid = """
        version=grain-cnn-test-1
        labels=clean,uncertain,infested
        output=probabilities
        input_layout=mels_frames
        sample_rate=16000
        n_fft=512
        win_length=400
        hop_length=160
        n_mels=64
        f_min=125
        f_max=7500
        log_offset=0.001
        power=1
    """.trimIndent()

    @Test
    fun parsesAValidManifest() {
        val m = ModelManifest.parse(valid)
        assertEquals("grain-cnn-test-1", m.version)
        assertEquals(listOf(ModelLabel.CLEAN, ModelLabel.UNCERTAIN, ModelLabel.INFESTED), m.labels)
        assertEquals(OutputType.PROBABILITIES, m.outputType)
        assertEquals(InputLayout.MELS_FRAMES, m.inputLayout)
        assertTrue(m.experimental, "experimental must default to true")
        assertEquals(LogMelConfig.PROVISIONAL, m.logMel)
    }

    @Test
    fun onlyExplicitFalseMarksValidated() {
        assertFalse(ModelManifest.parse("$valid\nexperimental=false").experimental)
        assertTrue(ModelManifest.parse("$valid\nexperimental=true").experimental)
        assertThrows<IllegalArgumentException> { ModelManifest.parse("$valid\nexperimental=maybe") }
    }

    @Test
    fun everyPreprocessingKeyIsRequired() {
        for (key in listOf("version", "labels", "output", "input_layout", "sample_rate", "n_fft",
            "win_length", "hop_length", "n_mels", "f_min", "f_max", "log_offset", "power")) {
            val without = valid.lines().filterNot { it.startsWith("$key=") }.joinToString("\n")
            assertThrows<IllegalArgumentException>("missing $key must be rejected") { ModelManifest.parse(without) }
        }
    }

    @Test
    fun rejectsReservedVersionUnknownLabelsAndOtherRates() {
        assertThrows<IllegalArgumentException> { ModelManifest.parse(valid.replace("version=grain-cnn-test-1", "version=none")) }
        assertThrows<IllegalArgumentException> { ModelManifest.parse(valid.replace("labels=clean,uncertain,infested", "labels=clean,weevil")) }
        assertThrows<IllegalArgumentException> { ModelManifest.parse(valid.replace("labels=clean,uncertain,infested", "labels=clean,clean")) }
        assertThrows<IllegalArgumentException> { ModelManifest.parse(valid.replace("sample_rate=16000", "sample_rate=22050")) }
        assertThrows<IllegalArgumentException> { ModelManifest.parse(valid.replace("n_fft=512", "n_fft=500")) }
    }

    @Test
    fun interpretsProbabilities() {
        val m = ModelManifest.parse(valid)
        val p = m.interpret(floatArrayOf(0.1f, 0.2f, 0.7f))
        assertEquals(ModelLabel.INFESTED, p.label)
        assertTrue(abs(p.confidence - 0.7) < 1e-6)
    }

    @Test
    fun interpretsLogitsWithSoftmax() {
        val m = ModelManifest.parse(valid.replace("output=probabilities", "output=logits"))
        val logits = floatArrayOf(2.0f, 0.5f, -1.0f)
        val p = m.interpret(logits)
        val expected = exp(2.0) / (exp(2.0) + exp(0.5) + exp(-1.0))
        assertEquals(ModelLabel.CLEAN, p.label)
        assertTrue(abs(p.confidence - expected) < 1e-6)
    }

    @Test
    fun refusesOutputNoValidModelWouldProduce() {
        val m = ModelManifest.parse(valid)
        assertThrows<IllegalStateException> { m.interpret(floatArrayOf(0.5f, 0.5f)) }
        assertThrows<IllegalStateException> { m.interpret(floatArrayOf(Float.NaN, 0.5f, 0.5f)) }
        assertThrows<IllegalStateException> { m.interpret(floatArrayOf(3f, 0f, 0f)) }
    }
}
