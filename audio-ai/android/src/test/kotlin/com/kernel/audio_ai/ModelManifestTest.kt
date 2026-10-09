package com.kernel.audio_ai

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import kotlin.math.abs
import kotlin.math.exp
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ModelManifestTest {
    private val valid = """
        version=grain-cnn-test-1
        labels=clean,uncertain,infested
        output=probabilities
        input_layout=mels_frames
        validation=field
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

    private val proxy = valid.replace("validation=field", "validation=proxy") +
        "\nnote=Trained on non-grain proxy insect recordings. Not validated on sacks."

    private fun parse(text: String) = ModelManifest.parse(text)

    @Test
    fun parsesAValidManifest() {
        val m = parse(valid)
        assertEquals("grain-cnn-test-1", m.version)
        assertEquals(listOf(ModelLabel.CLEAN, ModelLabel.UNCERTAIN, ModelLabel.INFESTED), m.labels)
        assertEquals(OutputType.PROBABILITIES, m.outputType)
        assertEquals(InputLayout.MELS_FRAMES, m.inputLayout)
        assertEquals(Validation.FIELD, m.validation)
        assertTrue(m.experimental, "experimental must default to true")
        assertNull(m.note)
        assertNull(m.uncertainBelow)
        assertEquals(LogMelConfig.PROVISIONAL, m.logMel)
    }

    @Test
    fun onlyExplicitFalseMarksValidated() {
        assertFalse(parse("$valid\nexperimental=false").experimental)
        assertTrue(parse("$valid\nexperimental=true").experimental)
        assertTrue(parse("$valid\nexperimental=").experimental, "blank means the default")
        assertThrows<IllegalArgumentException> { parse("$valid\nexperimental=maybe") }
    }

    @Test
    fun everyPreprocessingKeyIsRequired() {
        for (key in listOf("version", "labels", "output", "input_layout", "validation", "sample_rate", "n_fft",
            "win_length", "hop_length", "n_mels", "f_min", "f_max", "log_offset", "power")) {
            val without = valid.lines().filterNot { it.startsWith("$key=") }.joinToString("\n")
            assertThrows<IllegalArgumentException>("missing $key must be rejected") { parse(without) }
        }
    }

    @Test
    fun rejectsReservedVersionUnknownLabelsAndOtherRates() {
        assertThrows<IllegalArgumentException> { parse(valid.replace("version=grain-cnn-test-1", "version=none")) }
        assertThrows<IllegalArgumentException> { parse(valid.replace("labels=clean,uncertain,infested", "labels=clean,weevil")) }
        assertThrows<IllegalArgumentException> { parse(valid.replace("labels=clean,uncertain,infested", "labels=clean,clean")) }
        assertThrows<IllegalArgumentException> { parse(valid.replace("labels=clean,uncertain,infested", "labels=clean")) }
        assertThrows<IllegalArgumentException> { parse(valid.replace("sample_rate=16000", "sample_rate=22050")) }
        assertThrows<IllegalArgumentException> { parse(valid.replace("n_fft=512", "n_fft=500")) }
        assertThrows<IllegalArgumentException> { parse(valid.replace("f_min=125", "f_min=NaN")) }
    }

    // --- Contracts v2: validation and note ---

    @Test
    fun proxyManifestWithNoteIsExperimentalAndCarriesTheNote() {
        val m = parse(proxy)
        assertEquals(Validation.PROXY, m.validation)
        assertTrue(m.experimental)
        assertEquals("Trained on non-grain proxy insect recordings. Not validated on sacks.", m.note)
        assertTrue(parse("$proxy\nexperimental=true").experimental)
    }

    @Test
    fun proxyManifestClaimingValidatedIsInvalid() {
        val e = assertThrows<IllegalArgumentException> { parse("$proxy\nexperimental=false") }
        assertTrue("proxy" in e.message!!, e.message)
    }

    @Test
    fun proxyManifestNeedsANote() {
        val noNote = valid.replace("validation=field", "validation=proxy")
        assertThrows<IllegalArgumentException> { parse(noNote) }
        assertThrows<IllegalArgumentException> { parse("$noNote\nnote=   ") }
    }

    @Test
    fun fieldManifestMayBeValidatedAndHaveANote() {
        val m = parse("$valid\nexperimental=false\nnote=Field-tested on 120 sacks, Oct 2026.")
        assertFalse(m.experimental)
        assertEquals("Field-tested on 120 sacks, Oct 2026.", m.note)
    }

    @Test
    fun validationValueIsCheckedCaseInsensitively() {
        assertEquals(Validation.FIELD, parse(valid.replace("validation=field", "validation=FIELD")).validation)
        assertThrows<IllegalArgumentException> { parse(valid.replace("validation=field", "validation=lab")) }
    }

    @Test
    fun noteIsTrimmedUnicodeAndLengthLimited() {
        val m = parse("$valid\nnote=  प्रॉक्सी model  ")
        assertEquals("प्रॉक्सी model", m.note)
        assertNull(parse("$valid\nnote=").note)
        val long = "x".repeat(ModelManifest.MAX_NOTE_LENGTH + 1)
        assertThrows<IllegalArgumentException> { parse("$valid\nnote=$long") }
        assertEquals(ModelManifest.MAX_NOTE_LENGTH, parse("$valid\nnote=${long.drop(1)}").note!!.length)
    }

    @Test
    fun unknownKeysAreRejectedButMetaKeysAreIgnored() {
        assertThrows<IllegalArgumentException> { parse("$valid\nuncertian_below=0.7") }
        assertThrows<IllegalArgumentException> { parse("$valid\nlabels_order=clean") }
        val m = parse("$valid\nmeta.dataset=proxy-v3\nmeta.git_commit=abc123")
        assertEquals("grain-cnn-test-1", m.version)
    }

    // --- Interpretation ---

    @Test
    fun interpretsProbabilities() {
        val m = parse(valid)
        val p = m.interpret(floatArrayOf(0.1f, 0.2f, 0.7f))
        assertEquals(ModelLabel.INFESTED, p.label)
        assertTrue(abs(p.confidence - 0.7) < 1e-6)
    }

    @Test
    fun interpretsLogitsWithSoftmax() {
        val m = parse(valid.replace("output=probabilities", "output=logits"))
        val logits = floatArrayOf(2.0f, 0.5f, -1.0f)
        val p = m.interpret(logits)
        val expected = exp(2.0) / (exp(2.0) + exp(0.5) + exp(-1.0))
        assertEquals(ModelLabel.CLEAN, p.label)
        assertTrue(abs(p.confidence - expected) < 1e-6)
    }

    @Test
    fun refusesOutputNoValidModelWouldProduce() {
        val m = parse(valid)
        assertThrows<IllegalStateException> { m.interpret(floatArrayOf(0.5f, 0.5f)) }
        assertThrows<IllegalStateException> { m.interpret(floatArrayOf(Float.NaN, 0.5f, 0.5f)) }
        assertThrows<IllegalStateException> { m.interpret(floatArrayOf(3f, 0f, 0f)) }
    }

    @Test
    fun uncertainBandTurnsLowConfidenceIntoUncertain() {
        // 0.75 is exact in float32 and float64, so the boundary case is unambiguous.
        val binary = parse(valid.replace("labels=clean,uncertain,infested", "labels=clean,infested") + "\nuncertain_below=0.75")
        assertEquals(0.75, binary.uncertainBelow)

        val sure = binary.interpret(floatArrayOf(0.1f, 0.9f))
        assertEquals(ModelLabel.INFESTED, sure.label)
        assertTrue(abs(sure.confidence - 0.9) < 1e-6)

        val unsure = binary.interpret(floatArrayOf(0.4f, 0.6f))
        assertEquals(ModelLabel.UNCERTAIN, unsure.label)
        assertTrue(abs(unsure.confidence - 0.6) < 1e-6, "confidence stays the top-class probability")

        val cleanUnsure = binary.interpret(floatArrayOf(0.7f, 0.3f))
        assertEquals(ModelLabel.UNCERTAIN, cleanUnsure.label, "the band applies to every class, clean included")

        val atBand = binary.interpret(floatArrayOf(0.25f, 0.75f))
        assertEquals(ModelLabel.INFESTED, atBand.label, "the band is strictly below the threshold")
    }

    @Test
    fun uncertainBandMustBeAbleToTriggerAndNotSwallowEverything() {
        val binary = valid.replace("labels=clean,uncertain,infested", "labels=clean,infested")
        assertThrows<IllegalArgumentException> { parse("$binary\nuncertain_below=0.5") }
        assertThrows<IllegalArgumentException> { parse("$binary\nuncertain_below=1") }
        assertThrows<IllegalArgumentException> { parse("$binary\nuncertain_below=high") }
        assertEquals(0.4, parse("$valid\nuncertain_below=0.4").uncertainBelow, "three labels: 1/3 < 0.4")
        assertThrows<IllegalArgumentException> { parse("$valid\nuncertain_below=0.3") }
    }
}
