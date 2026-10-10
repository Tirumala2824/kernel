package com.kernel.local_llm

import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.BackendType
import com.google.ai.edge.litertlm.InputData
import com.google.ai.edge.litertlm.NpuBrand
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import org.junit.jupiter.api.Test

class EmbedConfigTest {
    private val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xDB.toByte())
    private val wav = "RIFF\u0000\u0000\u0000\u0000WAVE".toByteArray(Charsets.US_ASCII)

    @Test
    fun `text-only embedding model gets no vision or audio encoder`() {
        val c = EmbedConfig.engineConfig("/e.litertlm", TextBackend.GPU, vision = false, audio = false, cacheDir = "/c")
        assertIs<Backend.GPU>(c.backend)
        assertNull(c.visionBackend)
        assertNull(c.audioBackend)
        assertEquals("/e.litertlm", c.modelPath)
        assertEquals("/c", c.cacheDir)
    }

    @Test
    fun `multimodal embedding model gets the encoders it supports`() {
        val gpu = EmbedConfig.engineConfig("/e.litertlm", TextBackend.GPU, vision = true, audio = true, cacheDir = "/c")
        assertIs<Backend.GPU>(gpu.visionBackend)
        assertIs<Backend.CPU>(gpu.audioBackend)
        val cpu = EmbedConfig.engineConfig("/e.litertlm", TextBackend.CPU, vision = true, audio = false, cacheDir = "/c")
        assertIs<Backend.CPU>(cpu.backend)
        assertIs<Backend.CPU>(cpu.visionBackend)
        assertNull(cpu.audioBackend)
    }

    @Test
    fun `GPU first, then CPU, and output is normalised`() {
        assertEquals(listOf(TextBackend.GPU, TextBackend.CPU), EmbedConfig.BACKEND_ORDER)
        assertEquals(true, EmbedConfig.options().normalize)
        assertNull(EmbedConfig.options().outputSize, "full length; Dart truncates and re-normalises")
    }

    @Test
    fun `inputs map by kind and reject unusable payloads`() {
        assertEquals("task: search result | query: weevil", (EmbedConfig.input(NativeEmbedKind.TEXT, "task: search result | query: weevil", null) as InputData.Text).text)
        assertIs<InputData.Image>(EmbedConfig.input(NativeEmbedKind.IMAGE, null, jpeg))
        assertIs<InputData.Audio>(EmbedConfig.input(NativeEmbedKind.AUDIO, null, wav))
        assertNull(EmbedConfig.input(NativeEmbedKind.TEXT, " ", null))
        assertNull(EmbedConfig.input(NativeEmbedKind.TEXT, "x".repeat(EmbedConfig.MAX_TEXT_CHARS + 1), null))
        assertNull(EmbedConfig.input(NativeEmbedKind.IMAGE, null, wav))
        assertNull(EmbedConfig.input(NativeEmbedKind.AUDIO, null, jpeg))
        assertNull(EmbedConfig.input(NativeEmbedKind.IMAGE, "text", null))
    }

    @Test
    fun `probe wire names`() {
        assertEquals("gpu", ModelProber.backendWire(BackendType.GPU))
        assertEquals("cpu", ModelProber.backendWire(BackendType.CPU))
        assertEquals("npu", ModelProber.backendWire(BackendType.NPU))
        assertEquals("qualcomm", ModelProber.npuWire(NpuBrand.QUALCOMM))
        assertNull(ModelProber.npuWire(NpuBrand.UNKNOWN))
        assertNull(ModelProber.npuWire(null))
        assertEquals(ModelKind.LLM, ModelProber.kindOf(NativeProbedKind.LLM))
        assertEquals(ModelKind.EMBEDDING, ModelProber.kindOf(NativeProbedKind.EMBEDDING))
        assertNull(ModelProber.kindOf(NativeProbedKind.UNKNOWN))
    }
}
