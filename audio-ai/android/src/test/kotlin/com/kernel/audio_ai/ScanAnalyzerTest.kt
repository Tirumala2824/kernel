package com.kernel.audio_ai

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ScanAnalyzerTest {
    private val analyzer = ScanAnalyzer()

    /** Test-only stand-in for a loaded model: returns a scripted prediction and counts calls. */
    private class ScriptedModel(private val answer: Prediction?) : ModelHandle {
        override val version = "test-model-1"
        override val experimental = true
        override val note: String? = "scripted test model"
        override val logMelConfig = LogMelConfig.PROVISIONAL
        var calls = 0
        var lastFrames = -1
        override fun classify(logMel: LogMelResult): Prediction? {
            calls++
            lastFrames = logMel.frames
            return answer
        }
    }

    @Test
    fun noModelNeverClassifiesAUsableRecording() {
        val a = analyzer.analyze(Signals.sine(1000.0, 16_000, 2000, -50.0), 16_000, NoModel)
        assertTrue(a.reasons.isEmpty(), "reasons ${a.reasons}")
        assertNull(a.prediction)
        assertEquals(NO_MODEL_VERSION, a.modelVersion)
        assertTrue(a.experimental)
        assertEquals(198, a.logMelFrames)
        assertNull(a.resampledFrom)
    }

    @Test
    fun retryRecordingNeverReachesTheModel() {
        val model = ScriptedModel(Prediction(ModelLabel.INFESTED, 0.9))
        val a = analyzer.analyze(ShortArray(32_000), 16_000, model)
        assertEquals(listOf(GateReason.SILENCE), a.reasons)
        assertNull(a.prediction)
        assertEquals(0, model.calls)
        assertEquals("test-model-1", a.modelVersion)
    }

    @Test
    fun passRecordingUsesOnlyTheModelsOwnAnswer() {
        val model = ScriptedModel(Prediction(ModelLabel.CLEAN, 0.8))
        val a = analyzer.analyze(Signals.sine(1000.0, 16_000, 2000, -50.0), 16_000, model)
        assertEquals(1, model.calls)
        assertEquals(Prediction(ModelLabel.CLEAN, 0.8), a.prediction)

        val unsure = ScriptedModel(null)
        assertNull(analyzer.analyze(Signals.sine(1000.0, 16_000, 2000, -50.0), 16_000, unsure).prediction)
    }

    /** Test clock: every reading advances by 1 ms, so each stage that runs takes exactly 1 ms. */
    private fun steppingClock(): () -> Long {
        var now = 0L
        return { now.also { now += 1_000_000L } }
    }

    @Test
    fun timingsCoverEveryStageThatRan() {
        val withModel = ScanAnalyzer(clock = steppingClock())
            .analyze(Signals.sine(1000.0, 16_000, 2000, -50.0), 16_000, ScriptedModel(null))
        assertEquals(StageTimings(1_000_000, 1_000_000, 1_000_000, 1_000_000), withModel.timings)
        assertEquals(4_000_000, withModel.timings.totalNanos)

        val noModel = ScanAnalyzer(clock = steppingClock())
            .analyze(Signals.sine(1000.0, 16_000, 2000, -50.0), 16_000, NoModel)
        assertEquals(0, noModel.timings.inferenceNanos, "no model, no inference time")
        assertEquals(1_000_000, noModel.timings.logMelNanos)
    }

    @Test
    fun retryTimingsHaveOnlyTheGate() {
        val a = ScanAnalyzer(clock = steppingClock()).analyze(ShortArray(32_000), 16_000, ScriptedModel(null))
        assertEquals(StageTimings(1_000_000, 0, 0, 0), a.timings)
    }

    @Test
    fun realClockTimingsAreNonNegative() {
        val t = analyzer.analyze(Signals.sine(1000.0, 48_000, 2000, -50.0), 48_000, ScriptedModel(null)).timings
        assertTrue(t.gateNanos >= 0 && t.resampleNanos >= 0 && t.logMelNanos >= 0 && t.inferenceNanos >= 0, "$t")
    }

    @Test
    fun nonNativeRateIsResampledBeforeLogMel() {
        val model = ScriptedModel(null)
        val a = analyzer.analyze(Signals.sine(1000.0, 48_000, 2000, -50.0), 48_000, model)
        assertTrue(a.reasons.isEmpty(), "reasons ${a.reasons}")
        assertEquals(48_000, a.resampledFrom)
        assertEquals(198, model.lastFrames)
    }
}
