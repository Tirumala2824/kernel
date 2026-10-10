package com.kernel.local_llm

import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.ResponseFormat
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import org.junit.jupiter.api.Test

/**
 * Pest ID mode (guardrails §8 amendment): this engine, and only this one,
 * loads the vision and audio encoders. The advice engine stays text-only
 * (LlmConfigTest).
 */
class PestIdConfigTest {
    private val png = byteArrayOf(0x89.toByte(), 'P'.code.toByte(), 'N'.code.toByte(), 'G'.code.toByte(), 13, 10, 26, 10, 0)
    private val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xE0.toByte(), 0)
    private val wav = "RIFF\u0000\u0000\u0000\u0000WAVEfmt ".toByteArray(Charsets.US_ASCII)

    private fun request(
        images: List<ByteArray> = listOf(jpeg),
        audio: ByteArray? = null,
        format: NativeResponseFormat = NativeResponseFormat.JSON,
        spec: String? = "{\"type\":\"object\"}",
        temperature: Double = 0.7,
        topK: Long = 40,
        topP: Double = 0.95,
        seed: Long = 2,
        maxOutputTokens: Long = 400,
        prompt: String = "Identify the animal.",
    ) = NativePestRequest(
        modelPath = null,
        systemInstruction = "rules",
        prompt = prompt,
        images = images,
        audioWav = audio,
        format = format,
        formatSpec = spec,
        temperature = temperature,
        topK = topK,
        topP = topP,
        seed = seed,
        maxOutputTokens = maxOutputTokens,
        timeoutMs = 10_000,
    )

    @Test
    fun `pest engine sets the vision backend with the main one and audio on CPU`() {
        val gpu = PestIdConfig.engineConfig("/m.litertlm", TextBackend.GPU, "/cache")
        assertIs<Backend.GPU>(gpu.backend)
        assertIs<Backend.GPU>(gpu.visionBackend)
        assertIs<Backend.CPU>(gpu.audioBackend)
        assertEquals(2, gpu.maxNumImages)
        assertEquals("/m.litertlm", gpu.modelPath)
        assertEquals("/cache", gpu.cacheDir)

        val cpu = PestIdConfig.engineConfig("/m.litertlm", TextBackend.CPU, "/cache")
        assertIs<Backend.CPU>(cpu.backend)
        assertIs<Backend.CPU>(cpu.visionBackend, "vision falls back to CPU")
        assertIs<Backend.CPU>(cpu.audioBackend)
    }

    @Test
    fun `pest backends are tried GPU first, then CPU`() {
        assertEquals(listOf(TextBackend.GPU, TextBackend.CPU), PestIdConfig.BACKEND_ORDER)
    }

    @Test
    fun `visual token budget is 560, one of the supported values`() {
        assertEquals(560, PestIdConfig.VISUAL_TOKEN_BUDGET)
        assertTrue(PestIdConfig.VISUAL_TOKEN_BUDGET in PestIdConfig.ALLOWED_VISUAL_BUDGETS)
        assertEquals(setOf(70, 140, 280, 560, 1120), PestIdConfig.ALLOWED_VISUAL_BUDGETS)
        PestIdConfig.applyVisualBudget()
        assertEquals(560, PestIdConfig.currentVisualBudget())
        PestIdConfig.clearVisualBudget()
        assertNull(PestIdConfig.currentVisualBudget())
    }

    @Test
    fun `conversation config enables response format only when constrained`() {
        val json = PestIdConfig.conversationConfig(request(format = NativeResponseFormat.JSON))
        assertTrue(json.enableResponseFormat)
        val regex = PestIdConfig.conversationConfig(request(format = NativeResponseFormat.REGEX, spec = "(a|none)"))
        assertTrue(regex.enableResponseFormat)
        val free = PestIdConfig.conversationConfig(request(format = NativeResponseFormat.NONE, spec = null))
        assertFalse(free.enableResponseFormat)
        assertTrue(json.initialMessages.isEmpty(), "no history between runs")
        assertTrue(json.tools.isEmpty(), "no tools")
        assertEquals("rules", (json.systemInstruction!!.contents.single() as Content.Text).text)
    }

    @Test
    fun `sampler carries the requested values and clamps out-of-range ones`() {
        val s = PestIdConfig.conversationConfig(request(temperature = 0.7, topK = 40, topP = 0.95, seed = 3)).samplerConfig!!
        assertEquals(0.7, s.temperature)
        assertEquals(40, s.topK)
        assertEquals(0.95, s.topP)
        assertEquals(3, s.seed)
        val wild = PestIdConfig.conversationConfig(request(temperature = 9.0, topK = 0, topP = 7.0, maxOutputTokens = 100_000))
        assertEquals(1.5, wild.samplerConfig!!.temperature)
        assertEquals(1, wild.samplerConfig!!.topK)
        assertEquals(1.0, wild.samplerConfig!!.topP)
        assertEquals(PestIdConfig.MAX_OUTPUT_TOKENS, wild.maxOutputToken)
    }

    @Test
    fun `images come before the clip and the text`() {
        val contents = PestIdConfig.contents(listOf(jpeg, png), wav, "prompt").contents
        assertEquals(4, contents.size)
        assertContentEquals(jpeg, (contents[0] as Content.ImageBytes).bytes)
        assertContentEquals(png, (contents[1] as Content.ImageBytes).bytes)
        assertContentEquals(wav, (contents[2] as Content.AudioBytes).bytes)
        assertEquals("prompt", (contents[3] as Content.Text).text)

        val textOnly = PestIdConfig.contents(emptyList(), null, "only").contents
        assertEquals(1, textOnly.size)
        assertIs<Content.Text>(textOnly.single())
    }

    @Test
    fun `response format maps json and regex, none stays free`() {
        val json = PestIdConfig.responseFormat(NativeResponseFormat.JSON, "{\"type\":\"object\"}")
        assertNotNull(json)
        assertEquals("{\"type\":\"object\"}", json.schemaOrPattern)
        assertEquals(ResponseFormat.json("{}").type, json.type)
        val regex = PestIdConfig.responseFormat(NativeResponseFormat.REGEX, "(a|none)")
        assertEquals("(a|none)", regex!!.schemaOrPattern)
        assertEquals(ResponseFormat.regex("x").type, regex.type)
        assertNull(PestIdConfig.responseFormat(NativeResponseFormat.NONE, "ignored"))
        assertNull(PestIdConfig.responseFormat(NativeResponseFormat.JSON, null))
    }

    @Test
    fun `media is checked before anything reaches the engine`() {
        assertNull(PestIdConfig.validate(request()))
        assertNull(PestIdConfig.validate(request(images = listOf(png, jpeg))))
        assertNull(PestIdConfig.validate(request(images = emptyList(), audio = wav)))
        val unsupported = NativeGenerateStatus.UNSUPPORTED
        assertEquals(unsupported, PestIdConfig.validate(request(images = listOf(jpeg, jpeg, jpeg))))
        assertEquals(unsupported, PestIdConfig.validate(request(images = listOf("GIF89a".toByteArray()))))
        assertEquals(unsupported, PestIdConfig.validate(request(audio = "OggS0000".toByteArray())))
        assertEquals(unsupported, PestIdConfig.validate(request(audio = wav + ByteArray(PestIdConfig.MAX_AUDIO_BYTES))))
        assertEquals(unsupported, PestIdConfig.validate(request(format = NativeResponseFormat.JSON, spec = " ")))
        assertEquals(unsupported, PestIdConfig.validate(request(images = emptyList(), prompt = " ")))
    }

    @Test
    fun `audio cap is 30 s of 16 kHz mono 16-bit plus header room`() {
        assertEquals(30 * 16_000 * 2 + 4_096, PestIdConfig.MAX_AUDIO_BYTES)
        assertEquals(45_000L, PestIdConfig.TIMEOUT_MS)
    }

    @Test
    fun `magic numbers identify PNG, JPEG and RIFF WAVE`() {
        assertTrue(MediaCheck.isPng(png))
        assertTrue(MediaCheck.isJpeg(jpeg))
        assertTrue(MediaCheck.isRiffWave(wav))
        assertFalse(MediaCheck.isPngOrJpeg(wav))
        assertFalse(MediaCheck.isRiffWave(jpeg))
        assertFalse(MediaCheck.isPngOrJpeg(ByteArray(0)))
    }
}
