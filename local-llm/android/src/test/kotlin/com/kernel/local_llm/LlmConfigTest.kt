package com.kernel.local_llm

import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Content
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import org.junit.jupiter.api.Test

/**
 * Isolation (docs/guardrails.md §8): the engine is configured text-only.
 * This is the one place in local-llm allowed to name the multimodal
 * backends, to assert that they are absent.
 */
class LlmConfigTest {
    @Test
    fun `engine config never sets an audio or vision backend`() {
        for (choice in TextBackend.entries) {
            val config = LlmConfig.engineConfig("/data/model.litertlm", choice, "/cache")
            assertNull(config.audioBackend, "audioBackend must stay null for $choice")
            assertNull(config.visionBackend, "visionBackend must stay null for $choice")
            assertNull(config.maxNumImages, "no image budget for $choice")
        }
    }

    @Test
    fun `engine config carries path, cache dir and the chosen text backend`() {
        val gpu = LlmConfig.engineConfig("/m.litertlm", TextBackend.GPU, "/cache")
        assertEquals("/m.litertlm", gpu.modelPath)
        assertEquals("/cache", gpu.cacheDir)
        assertIs<Backend.GPU>(gpu.backend)

        val cpu = LlmConfig.engineConfig("/m.litertlm", TextBackend.CPU, "/cache")
        assertIs<Backend.CPU>(cpu.backend)
    }

    @Test
    fun `backends are tried GPU first, then CPU, and nothing else`() {
        assertEquals(listOf(TextBackend.GPU, TextBackend.CPU), LlmConfig.BACKEND_ORDER)
    }

    @Test
    fun `conversation config uses the advice sampler and token cap`() {
        val config = LlmConfig.conversationConfig("rules")
        val sampler = config.samplerConfig!!
        assertEquals(40, sampler.topK)
        assertEquals(0.9, sampler.topP)
        assertEquals(0.3, sampler.temperature)
        assertEquals(220, config.maxOutputToken)
        val system = config.systemInstruction!!.contents
        assertEquals(1, system.size)
        assertEquals("rules", (system.single() as Content.Text).text)
        assertEquals(true, config.initialMessages.isEmpty(), "no history is carried between requests")
        assertEquals(true, config.tools.isEmpty(), "no tools")
    }

    @Test
    fun `timeouts match the guardrails`() {
        assertEquals(25_000L, LlmConfig.GENERATION_TIMEOUT_MS)
        assertEquals(180_000L, LlmConfig.IDLE_UNLOAD_MS)
    }
}
