package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Random
import kotlin.math.PI
import kotlin.math.sin

class ListenTest {
    private val sr = 16_000

    private fun pipeline(): ListenPipeline {
        var n = 0
        return ListenPipeline(idFactory = { "e${n++}" })
    }

    /** Feeds [pcm] in 20 ms chunks, like AudioRecord reads. */
    private fun feed(p: ListenPipeline, pcm: ShortArray): List<SoundEventRecord> {
        val out = ArrayList<SoundEventRecord>()
        var i = 0
        val chunk = 320
        while (i < pcm.size) {
            val n = minOf(chunk, pcm.size - i)
            out += p.feed(pcm.copyOfRange(i, i + n), n)
            i += n
        }
        return out
    }

    private fun noise(seconds: Double, sigma: Double, seed: Long): DoubleArray {
        val rnd = Random(seed)
        return DoubleArray((seconds * sr).toInt()) { rnd.nextGaussian() * sigma }
    }

    private fun pcm(x: DoubleArray) = ShortArray(x.size) { (x[it] * 32767).coerceIn(-32768.0, 32767.0).toInt().toShort() }

    @Test
    fun impulseTrainIsDetected() {
        val x = noise(10.0, 0.003, 1)
        val rnd = Random(2)
        // Clicks every 1.5 s from 4 s on: 5 ms broadband bursts.
        val clickStarts = (0 until 4).map { ((4.0 + 1.5 * it) * sr).toInt() }
        for (s in clickStarts) for (j in 0 until 80) x[s + j] += rnd.nextGaussian() * 0.3
        val events = feed(pipeline(), pcm(x))
        assertEquals(clickStarts.size, events.size, "one event per click")
        for ((e, s) in events.zip(clickStarts)) {
            assertTrue(kotlin.math.abs(e.onsetSample - s) < 0.05 * sr, "onset near the click: ${e.onsetSample} vs $s")
            assertTrue(e.score in 0.0..1.0)
            assertEquals(ListenPipeline.WINDOW_SAMPLES, e.window.size)
            assertTrue(e.clip.size <= 6 * sr, "clip is pre + post roll")
            assertTrue(e.clip.size >= 4.5 * sr, "clip ${e.clip.size}")
        }
    }

    @Test
    fun rapidClicksMergeIntoOneEvent() {
        val x = noise(6.0, 0.003, 3)
        val rnd = Random(4)
        // Chewing-like: 5 clicks 150 ms apart.
        for (k in 0 until 5) {
            val s = ((3.0 + 0.15 * k) * sr).toInt()
            for (j in 0 until 60) x[s + j] += rnd.nextGaussian() * 0.2
        }
        val events = feed(pipeline(), pcm(x))
        assertEquals(1, events.size)
        assertTrue(events.single().onsetCount >= 3)
    }

    @Test
    fun stationaryNoiseIsNotDetected() {
        for (seed in 5L..9L) {
            assertEquals(0, feed(pipeline(), pcm(noise(15.0, 0.05, seed))).size, "white noise, seed $seed")
        }
        val quiet = feed(pipeline(), pcm(noise(15.0, 0.002, 6)))
        assertEquals(0, quiet.size, "very quiet room")
        // Mains hum plus fan-like noise.
        val hum = noise(15.0, 0.02, 7)
        for (i in hum.indices) hum[i] += 0.1 * sin(2 * PI * 100.0 * i / sr) + 0.05 * sin(2 * PI * 300.0 * i / sr)
        assertEquals(0, feed(pipeline(), pcm(hum)).size, "hum")
    }

    @Test
    fun slowSwellIsNotAnOnset() {
        // A sound fading in over 3 s has no flux peak.
        val x = noise(10.0, 0.003, 8)
        val rnd = Random(9)
        for (i in (3 * sr) until x.size) {
            val ramp = minOf(1.0, (i - 3.0 * sr) / (3.0 * sr))
            x[i] += ramp * 0.05 * rnd.nextGaussian()
        }
        assertEquals(0, feed(pipeline(), pcm(x)).size)
    }

    @Test
    fun clickOnTopOfASustainedSoundIsStillDetected() {
        // A fan starts at 2 s; a click at 9 s once the floor has absorbed it.
        val x = noise(12.0, 0.003, 10)
        val rnd = Random(11)
        for (i in (2 * sr) until x.size) x[i] += 0.03 * rnd.nextGaussian()
        val s = 9 * sr
        for (j in 0 until 80) x[s + j] += rnd.nextGaussian() * 0.5
        val events = feed(pipeline(), pcm(x))
        assertTrue(events.any { kotlin.math.abs(it.onsetSample - s) < 0.05 * sr }, "click found")
        assertTrue(events.size <= 2, "the fan start may count once, nothing else: ${events.size}")
    }

    @Test
    fun ringKeepsOnlyTheLastThirtySeconds() {
        val ring = PcmRing(sr * 30)
        val chunk = ShortArray(sr) { 1 }
        repeat(40) { ring.write(chunk, chunk.size) }
        assertEquals(40L * sr, ring.total)
        assertEquals(0, ring.copy(0, sr.toLong()).size, "older audio is gone")
        assertEquals(sr, ring.copy(39L * sr, 40L * sr).size)
        assertEquals(30 * sr, ring.copy(0, 40L * sr).size)
    }

    @Test
    fun wavWriterProducesRiffMono16k16bit() {
        val pcm = ShortArray(1600) { (it - 800).toShort() }
        val wav = WavWriter.encode(pcm, sr)
        assertEquals(44 + 3200, wav.size)
        val b = ByteBuffer.wrap(wav).order(ByteOrder.LITTLE_ENDIAN)
        assertEquals("RIFF", String(wav, 0, 4, Charsets.US_ASCII))
        assertEquals(36 + 3200, b.getInt(4))
        assertEquals("WAVE", String(wav, 8, 4, Charsets.US_ASCII))
        assertEquals("fmt ", String(wav, 12, 4, Charsets.US_ASCII))
        assertEquals(16, b.getInt(16))
        assertEquals(1, b.getShort(20).toInt(), "PCM")
        assertEquals(1, b.getShort(22).toInt(), "mono")
        assertEquals(sr, b.getInt(24))
        assertEquals(sr * 2, b.getInt(28))
        assertEquals(2, b.getShort(32).toInt())
        assertEquals(16, b.getShort(34).toInt())
        assertEquals("data", String(wav, 36, 4, Charsets.US_ASCII))
        assertEquals(3200, b.getInt(40))
        assertEquals(-800, b.getShort(44).toInt())
        assertEquals(799, b.getShort(44 + 2 * 1599).toInt())
    }

    @Test
    fun wavWriterCapsAtThirtySeconds() {
        val pcm = ShortArray(31 * sr) { if (it < sr) 7 else 3 }
        val wav = WavWriter.encode(pcm, sr)
        assertEquals(44 + 30 * sr * 2, wav.size)
        val b = ByteBuffer.wrap(wav).order(ByteOrder.LITTLE_ENDIAN)
        assertEquals(3, b.getShort(44).toInt(), "keeps the most recent 30 s")
    }

    @Test
    fun logMelPutsAToneInTheRightBand() {
        val mel = LogMel64()
        val frame = FloatArray(512) { (0.5 * sin(2 * PI * 1000.0 * it / sr)).toFloat() }
        val out = FloatArray(64)
        mel.compute(frame, 0, out)
        val peak = out.indices.maxByOrNull { out[it] }!!
        val melMin = LogMel64.hzToMel(125.0)
        val melMax = LogMel64.hzToMel(7500.0)
        val centre = LogMel64.melToHz(melMin + (melMax - melMin) * (peak + 1) / 65.0)
        assertTrue(centre in 900.0..1100.0, "peak band centre $centre Hz")
    }
}
