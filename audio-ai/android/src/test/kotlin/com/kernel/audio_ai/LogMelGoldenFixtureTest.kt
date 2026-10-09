package com.kernel.audio_ai

import org.junit.jupiter.api.Test
import java.io.File
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.fail

/**
 * Writes golden log-mel fixtures for the off-device training pipeline
 * (model-training/tests/test_logmel_parity.py), so the Python front end that
 * prepares training data provably matches this Kotlin [LogMel].
 *
 * Fixtures: `tests/fixtures/logmel/<name>.json` at the repo root. Each holds a
 * deterministic PCM16 input (sine + linear chirp + click train + a silent gap +
 * LCG pseudo-noise from a fixed integer formula, no RNG), the exact
 * [LogMelConfig], and the frames x nMels output, frame-major.
 *
 * If a fixture is missing it is written. If it exists, the freshly computed
 * output must match it within [TOLERANCE] (else the Kotlin front end changed:
 * regenerate with KERNEL_REGEN_FIXTURES=1 and re-run the Python parity test).
 * A matching fixture is left untouched, so re-runs never churn the files.
 */
class LogMelGoldenFixtureTest {

    @Test
    fun provisionalTwoSecondCapture() {
        // The app's real case: ~2 s at 16 kHz with the provisional front end.
        val pcm = signal(LogMelConfig.PROVISIONAL.sampleRate, 32_000)
        checkOrWrite("provisional_2s", LogMelConfig.PROVISIONAL, pcm, expectedFrames = 198)
    }

    @Test
    fun alternateConfigPowerSpectrum() {
        // Exercises the other code paths: power = 2, f_max at Nyquist, larger FFT,
        // a window shorter than the FFT and a tiny log offset.
        val config = LogMelConfig(
            sampleRate = 16_000,
            nFft = 1024,
            winLength = 640,
            hopLength = 320,
            nMels = 40,
            fMin = 50.0,
            fMax = 8_000.0,
            logOffset = 1e-6,
            power = 2.0,
        )
        val pcm = signal(config.sampleRate, 12_345)
        checkOrWrite("alt_power2_nyquist", config, pcm, expectedFrames = 1 + (12_345 - 640) / 320)
    }

    @Test
    fun exportedModelManifestsParseAndUseAFixtureCoveredFrontEnd() {
        // Models exported by model-training/ must parse with the app's own
        // ModelManifest parser, and their log-mel front end must be one whose
        // Kotlin/Python parity this test's fixtures prove. Passes vacuously
        // until something is exported.
        val dist = File(repoRoot(), "model-training/dist")
        val manifests = dist.listFiles { f -> f.name.endsWith(".properties") }.orEmpty()
        for (file in manifests) {
            val manifest = ModelManifest.parse(file.readText(Charsets.UTF_8))
            assertEquals(LogMelConfig.PROVISIONAL, manifest.logMel, "${file.name}: front end not covered by a golden fixture")
            assertTrue(manifest.experimental, "${file.name}: exported models stay experimental until field-validated")
            assertTrue(File(dist, file.name.removeSuffix(".properties") + ".tflite").isFile, "${file.name}: missing .tflite")
        }
    }

    private fun checkOrWrite(name: String, config: LogMelConfig, pcm: ShortArray, expectedFrames: Int) {
        // Same int16 -> float conversion as ScanAnalyzer.
        val samples = FloatArray(pcm.size) { pcm[it] / QualityGate.FULL_SCALE.toFloat() }
        val result = LogMel(config).compute(samples)
        assertEquals(expectedFrames, result.frames)
        assertTrue(result.values.all { it.isFinite() })

        val file = File(fixtureDir(), "$name.json")
        val regen = System.getenv("KERNEL_REGEN_FIXTURES") == "1"
        if (file.exists() && !regen) {
            val stored = parseFloatArray(file.readText(), "logmel")
            assertEquals(result.values.size, stored.size, "$name: fixture size differs")
            var worst = 0.0
            for (i in stored.indices) worst = maxOf(worst, abs(stored[i].toDouble() - result.values[i].toDouble()))
            if (worst > TOLERANCE) {
                fail("$name: Kotlin LogMel output moved by $worst nats from the fixture. " +
                    "If intended, regenerate with KERNEL_REGEN_FIXTURES=1 and re-run model-training parity tests.")
            }
            return
        }
        file.absoluteFile.parentFile?.mkdirs()
        file.writeText(toJson(name, config, pcm, result))
    }

    /** Deterministic test signal in PCM16, no RNG. */
    private fun signal(rate: Int, count: Int): ShortArray {
        val seconds = count.toDouble() / rate
        var lcg = 12_345L
        return ShortArray(count) { n ->
            val t = n.toDouble() / rate
            val sine = 0.25 * sin(2.0 * PI * 440.0 * t)
            // Linear chirp 100 Hz -> 7000 Hz over the whole signal.
            val chirp = 0.2 * sin(2.0 * PI * (100.0 * t + (7_000.0 - 100.0) / (2.0 * seconds) * t * t))
            // Decaying 2.5 kHz click every 1234 samples (insect-pulse-like transients).
            val k = n % 1_234
            val click = 0.3 * exp(-k / 40.0) * sin(2.0 * PI * 2_500.0 * k / rate)
            // 31-bit LCG (glibc constants) mapped to [-1, 1).
            lcg = (lcg * 1_103_515_245L + 12_345L) and 0x7FFF_FFFFL
            val noise = 0.05 * (2.0 * lcg / 2_147_483_648.0 - 1.0)
            // 100 ms digital silence in the middle exercises the log-offset floor.
            val gap = n in (count / 2) until (count / 2 + rate / 10)
            val x = if (gap) 0.0 else sine + chirp + click + noise
            (x * 32_768.0).roundToInt().coerceIn(-32_768, 32_767).toShort()
        }
    }

    private fun toJson(name: String, c: LogMelConfig, pcm: ShortArray, r: LogMelResult): String {
        val sb = StringBuilder(pcm.size * 7 + r.values.size * 14 + 1024)
        sb.append("{\n")
        sb.append("  \"name\": \"").append(name).append("\",\n")
        sb.append("  \"generator\": \"audio-ai/android/src/test/kotlin/com/kernel/audio_ai/LogMelGoldenFixtureTest.kt\",\n")
        sb.append("  \"signal\": \"0.25*sin(2pi*440t) + 0.2*chirp(100->7000 Hz) + 0.3*click(2.5 kHz, every 1234 samples, tau 40) ")
            .append("+ 0.05*LCG31(seed 12345, a 1103515245, c 12345) noise, 100 ms zero gap at count/2, PCM16 round(x*32768)\",\n")
        sb.append("  \"pcm_to_float\": \"pcm / 32768.0f\",\n")
        sb.append("  \"config\": {")
            .append("\"sample_rate\": ").append(c.sampleRate)
            .append(", \"n_fft\": ").append(c.nFft)
            .append(", \"win_length\": ").append(c.winLength)
            .append(", \"hop_length\": ").append(c.hopLength)
            .append(", \"n_mels\": ").append(c.nMels)
            .append(", \"f_min\": ").append(c.fMin)
            .append(", \"f_max\": ").append(c.fMax)
            .append(", \"log_offset\": ").append(c.logOffset)
            .append(", \"power\": ").append(c.power)
            .append("},\n")
        sb.append("  \"frames\": ").append(r.frames).append(",\n")
        sb.append("  \"n_mels\": ").append(r.nMels).append(",\n")
        sb.append("  \"layout\": \"frames_mels (frame-major)\",\n")
        sb.append("  \"pcm16\": [")
        pcm.forEachIndexed { i, s -> if (i > 0) sb.append(','); sb.append(s.toInt()) }
        sb.append("],\n")
        sb.append("  \"logmel\": [")
        r.values.forEachIndexed { i, v -> if (i > 0) sb.append(','); sb.append(v.toString()) }
        sb.append("]\n}\n")
        return sb.toString()
    }

    /** Minimal reader for the one numeric array this test writes (no JSON library in JVM unit tests). */
    private fun parseFloatArray(json: String, key: String): FloatArray {
        val start = json.indexOf("\"$key\": [")
        check(start >= 0) { "fixture has no '$key'" }
        val open = json.indexOf('[', start)
        val close = json.indexOf(']', open)
        val body = json.substring(open + 1, close).trim()
        if (body.isEmpty()) return FloatArray(0)
        return body.split(',').map { it.trim().toFloat() }.toFloatArray()
    }

    /** Repo root = first ancestor of the Gradle working dir holding both CLAUDE.md and audio-ai/. */
    private fun fixtureDir(): File = File(repoRoot(), "tests/fixtures/logmel")

    private fun repoRoot(): File {
        val workingDir = System.getProperty("user.dir") ?: error("user.dir is not set")
        var dir: File? = File(workingDir).absoluteFile
        while (dir != null) {
            if (File(dir, "CLAUDE.md").isFile && File(dir, "audio-ai").isDirectory) return dir
            dir = dir.parentFile
        }
        error("repo root not found above $workingDir")
    }

    companion object {
        /** Kotlin vs stored fixture (same code, so only JVM math differences): far below float32 noise at these magnitudes. */
        const val TOLERANCE = 1e-5
    }
}
