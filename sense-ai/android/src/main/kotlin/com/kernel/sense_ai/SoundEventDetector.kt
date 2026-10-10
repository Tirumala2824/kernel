package com.kernel.sense_ai

import kotlin.math.max
import kotlin.math.min

class SoundOnset(val frameIndex: Long, val flux: Double, val bandsAbove: Int)

/**
 * Listen-mode onset detector on 64-band log-mel frames.
 *
 * - Positive spectral flux: mean over bands of `max(0, L_t - L_{t-1})`,
 *   divided by [fluxScaleDb].
 * - Adaptive per-band floor: a running mean of each band that follows the
 *   background quickly ([floorRate], about 0.2 s) and slowly
 *   ([floorEventRate]) for [holdFrames] after an onset, so an event does
 *   not raise its own floor but a sustained new sound is absorbed.
 * - Onset: more than 6 bands ([minBandsAbove] = 7) above floor +
 *   [bandMarginDb] that were not above it [riseFrames] frames earlier (an
 *   impulsive rise, not a band that is already loud), and a flux peak: at
 *   least the previous [preMaxFrames] values and at least their
 *   [avgFrames] mean + [fluxDelta], with [waitFrames] between onsets.
 *
 * Thresholds need on-device calibration.
 */
class SoundEventDetector(
    val nBands: Int = 64,
    val bandMarginDb: Double = 9.0,
    val minBandsAbove: Int = 7,
    val fluxDelta: Double = 0.07,
    val fluxScaleDb: Double = 10.0,
    val preMaxFrames: Int = 3,
    val avgFrames: Int = 10,
    val waitFrames: Int = 3,
    val riseFrames: Int = 3,
    val floorRate: Float = 0.05f,
    val floorEventRate: Float = 0.005f,
    /** Frames after an onset during which the floor moves at [floorEventRate]. */
    val holdFrames: Int = 100,
    val warmupFrames: Int = 30,
) {
    private val floor = FloatArray(nBands)
    private val prev = FloatArray(nBands)

    /** The last [riseFrames] mel frames, oldest at [melPos]. */
    private val melHistory = Array(riseFrames) { FloatArray(nBands) }
    private var melPos = 0
    private val history = DoubleArray(max(preMaxFrames, avgFrames))
    private var historyCount = 0
    private var historyPos = 0
    private var frames = 0L
    private var lastOnset = Long.MIN_VALUE / 2

    fun reset() {
        frames = 0
        historyCount = 0
        historyPos = 0
        lastOnset = Long.MIN_VALUE / 2
    }

    /** Current floor for band [b] in dB (for diagnostics and tests). */
    fun floorDb(b: Int): Float = floor[b]

    fun process(mel: FloatArray): SoundOnset? {
        val index = frames++
        if (index == 0L) {
            System.arraycopy(mel, 0, floor, 0, nBands)
            System.arraycopy(mel, 0, prev, 0, nBands)
            for (h in melHistory) System.arraycopy(mel, 0, h, 0, nBands)
            return null
        }
        val then = melHistory[melPos]
        var rise = 0.0
        var above = 0
        for (b in 0 until nBands) {
            val d = mel[b] - prev[b]
            if (d > 0) rise += d
            val margin = floor[b] + bandMarginDb
            if (mel[b] > margin && then[b] <= margin) above++
        }
        val flux = rise / nBands / fluxScaleDb

        var onset: SoundOnset? = null
        if (index >= warmupFrames && historyCount >= avgFrames) {
            var recentMax = Double.NEGATIVE_INFINITY
            for (i in 1..preMaxFrames) recentMax = max(recentMax, historyAt(i))
            var mean = 0.0
            for (i in 1..avgFrames) mean += historyAt(i)
            mean /= avgFrames
            if (flux >= recentMax && flux >= mean + fluxDelta && above >= minBandsAbove &&
                index - lastOnset > waitFrames
            ) {
                onset = SoundOnset(index, flux, above)
                lastOnset = index
            }
        }

        val rate = when {
            index < warmupFrames -> 0.2f
            index - lastOnset <= holdFrames -> floorEventRate
            else -> floorRate
        }
        for (b in 0 until nBands) floor[b] += rate * (mel[b] - floor[b])
        System.arraycopy(mel, 0, prev, 0, nBands)
        System.arraycopy(mel, 0, then, 0, nBands)
        melPos = (melPos + 1) % riseFrames
        history[historyPos] = flux
        historyPos = (historyPos + 1) % history.size
        historyCount = min(historyCount + 1, history.size)
        return onset
    }

    /** Flux [ago] frames back (1 = previous frame). */
    private fun historyAt(ago: Int): Double {
        val i = ((historyPos - ago) % history.size + history.size) % history.size
        return history[i]
    }
}

/** Rolling PCM16 buffer with absolute sample positions. Memory only. */
class PcmRing(val capacity: Int) {
    private val buf = ShortArray(capacity)
    var total: Long = 0
        private set

    fun write(src: ShortArray, count: Int) {
        var off = 0
        var left = count
        if (left > capacity) {
            off = left - capacity
            left = capacity
        }
        var pos = (total % capacity).toInt()
        while (left > 0) {
            val n = min(left, capacity - pos)
            System.arraycopy(src, off, buf, pos, n)
            off += n
            left -= n
            pos = (pos + n) % capacity
        }
        total += count
    }

    /** Samples [from, to) clamped to what is still held. */
    fun copy(from: Long, to: Long): ShortArray {
        val lo = max(from, max(0L, total - capacity))
        val hi = min(to, total)
        if (hi <= lo) return ShortArray(0)
        val out = ShortArray((hi - lo).toInt())
        var pos = (lo % capacity).toInt()
        var off = 0
        while (off < out.size) {
            val n = min(out.size - off, capacity - pos)
            System.arraycopy(buf, pos, out, off, n)
            off += n
            pos = (pos + n) % capacity
        }
        return out
    }

    fun clear() {
        java.util.Arrays.fill(buf, 0)
        total = 0
    }
}

/** A finished sound event: detector stats plus its in-memory audio. */
class SoundEventRecord(
    val id: String,
    val onsetSample: Long,
    val score: Double,
    val onsetCount: Int,
    val peakFlux: Double,
    val maxBands: Int,
    /** Clip for the user and the on-device analyser (PCM16, [ListenPipeline.sampleRate]). */
    val clip: ShortArray,
    /** Classifier window (floats in [-1, 1], [ListenPipeline.WINDOW_SAMPLES] long). */
    val window: FloatArray,
)

/**
 * Listen-mode signal path without Android: PCM16 in, finished
 * [SoundEventRecord]s out. Onsets within [mergeMs] of an event's first
 * onset are merged into it; the event is finished [mergeMs] after the
 * onset with a clip from [clipPreMs] before to [mergeMs] after it.
 */
class ListenPipeline(
    val sampleRate: Int = 16_000,
    ringSeconds: Int = 30,
    val clipPreMs: Int = 5000,
    val mergeMs: Int = 1000,
    val windowPreMs: Int = 500,
    private val idFactory: () -> String,
    val detector: SoundEventDetector = SoundEventDetector(),
    private val logMel: LogMel64 = LogMel64(sampleRate = sampleRate),
) {
    private class Pending(val onsetSample: Long, var onsets: Int, var peakFlux: Double, var maxBands: Int)

    private val ring = PcmRing(sampleRate * ringSeconds)
    private val frame = FloatArray(logMel.nFft)
    private val circ = FloatArray(logMel.nFft)
    private var circPos = 0
    private val mel = FloatArray(logMel.nMels)
    private var filled = 0
    private var sinceHop = 0
    private var pending: Pending? = null

    fun feed(pcm: ShortArray, count: Int): List<SoundEventRecord> {
        ring.write(pcm, count)
        val out = ArrayList<SoundEventRecord>(0)
        val nFft = logMel.nFft
        val startTotal = ring.total - count
        for (i in 0 until count) {
            // Circular buffer of the last nFft samples, unrolled once per hop.
            circ[circPos] = pcm[i] / 32768f
            circPos = (circPos + 1) % nFft
            if (filled < nFft) filled++
            sinceHop++
            if (filled == nFft && sinceHop >= logMel.hop) {
                sinceHop = 0
                val tail = nFft - circPos
                System.arraycopy(circ, circPos, frame, 0, tail)
                System.arraycopy(circ, 0, frame, tail, circPos)
                logMel.compute(frame, 0, mel)
                val onset = detector.process(mel)
                if (onset != null) {
                    // Centre of the analysis window.
                    val at = startTotal + i + 1 - nFft / 2
                    val p = pending
                    if (p == null) {
                        pending = Pending(at, 1, onset.flux, onset.bandsAbove)
                    } else {
                        p.onsets++
                        p.peakFlux = max(p.peakFlux, onset.flux)
                        p.maxBands = max(p.maxBands, onset.bandsAbove)
                    }
                }
            }
            val p = pending
            if (p != null && startTotal + i + 1 >= p.onsetSample + samples(mergeMs)) {
                out.add(finish(p))
                pending = null
            }
        }
        return out
    }

    fun clear() {
        ring.clear()
        java.util.Arrays.fill(circ, 0f)
        circPos = 0
        filled = 0
        sinceHop = 0
        pending = null
        detector.reset()
    }

    private fun finish(p: Pending): SoundEventRecord {
        val clip = ring.copy(p.onsetSample - samples(clipPreMs), p.onsetSample + samples(mergeMs))
        val winStart = p.onsetSample - samples(windowPreMs)
        val raw = ring.copy(winStart, winStart + WINDOW_SAMPLES)
        val window = FloatArray(WINDOW_SAMPLES)
        // Left-pad with silence if the event came right after the start.
        val pad = WINDOW_SAMPLES - raw.size
        for (j in raw.indices) window[pad + j] = raw[j] / 32768f
        val score = (0.6 * min(1.0, p.peakFlux / 0.5) + 0.4 * (p.maxBands / detector.nBands.toDouble())).coerceIn(0.0, 1.0)
        return SoundEventRecord(idFactory(), p.onsetSample, score, p.onsets, p.peakFlux, p.maxBands, clip, window)
    }

    private fun samples(ms: Int): Long = ms.toLong() * sampleRate / 1000

    companion object {
        /** YAMNet input: 0.975 s at 16 kHz. */
        const val WINDOW_SAMPLES = 15_600
    }
}

/** RIFF WAV, mono, 16-bit PCM. Longer input keeps only the last [maxSeconds]. */
object WavWriter {
    fun encode(pcm: ShortArray, sampleRate: Int, maxSeconds: Int = 30): ByteArray {
        val maxSamples = sampleRate * maxSeconds
        val start = max(0, pcm.size - maxSamples)
        val n = pcm.size - start
        val dataBytes = n * 2
        val out = java.nio.ByteBuffer.allocate(44 + dataBytes).order(java.nio.ByteOrder.LITTLE_ENDIAN)
        out.put("RIFF".toByteArray(Charsets.US_ASCII))
        out.putInt(36 + dataBytes)
        out.put("WAVE".toByteArray(Charsets.US_ASCII))
        out.put("fmt ".toByteArray(Charsets.US_ASCII))
        out.putInt(16) // PCM fmt chunk size
        out.putShort(1) // PCM
        out.putShort(1) // mono
        out.putInt(sampleRate)
        out.putInt(sampleRate * 2) // byte rate
        out.putShort(2) // block align
        out.putShort(16) // bits per sample
        out.put("data".toByteArray(Charsets.US_ASCII))
        out.putInt(dataBytes)
        for (i in start until pcm.size) out.putShort(pcm[i])
        return out.array()
    }
}
