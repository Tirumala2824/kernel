package com.kernel.sense_ai

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.ln
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Streaming 64-band log-mel for listen-mode event detection: Hann window of
 * [nFft] samples every [hop] samples, power spectrum, HTK mel filterbank over
 * [fMin]..[fMax] Hz, then dB. Not the grain-scan log-mel (that one lives in
 * audio-ai and is never shared).
 */
class LogMel64(
    val sampleRate: Int = 16_000,
    val nFft: Int = 512,
    val hop: Int = 160,
    val nMels: Int = 64,
    val fMin: Double = 125.0,
    val fMax: Double = 7500.0,
) {
    private val window = FloatArray(nFft) { (0.5 - 0.5 * cos(2 * PI * it / nFft)).toFloat() }
    private val re = FloatArray(nFft)
    private val im = FloatArray(nFft)
    private val power = FloatArray(nFft / 2 + 1)
    private val filters: Array<FloatArray>
    private val filterStart: IntArray
    private val fft = Fft(nFft)

    init {
        require(Integer.bitCount(nFft) == 1) { "nFft must be a power of two" }
        val bins = nFft / 2 + 1
        val melMin = hzToMel(fMin)
        val melMax = hzToMel(fMax)
        val edges = DoubleArray(nMels + 2) { melToHz(melMin + (melMax - melMin) * it / (nMels + 1)) }
        val binHz = sampleRate.toDouble() / nFft
        filters = Array(nMels) { FloatArray(0) }
        filterStart = IntArray(nMels)
        for (m in 0 until nMels) {
            val lo = edges[m]
            val mid = edges[m + 1]
            val hi = edges[m + 2]
            val first = max(0, Math.ceil(lo / binHz).toInt())
            val last = min(bins - 1, Math.floor(hi / binHz).toInt())
            val weights = FloatArray(max(0, last - first + 1))
            for (k in first..last) {
                val f = k * binHz
                val wgt = if (f <= mid) (f - lo) / (mid - lo) else (hi - f) / (hi - mid)
                weights[k - first] = max(0.0, wgt).toFloat()
            }
            // Narrow low bands can fall between bins; give them the nearest bin.
            if (weights.isEmpty() || weights.all { it == 0f }) {
                val k = min(bins - 1, Math.round(mid / binHz).toInt())
                filterStart[m] = k
                filters[m] = floatArrayOf(1f)
            } else {
                filterStart[m] = first
                filters[m] = weights
            }
        }
    }

    /** [frame] holds [nFft] samples in [-1, 1]; writes [nMels] dB values into [out]. */
    fun compute(frame: FloatArray, offset: Int, out: FloatArray) {
        for (i in 0 until nFft) {
            re[i] = frame[offset + i] * window[i]
            im[i] = 0f
        }
        fft.transform(re, im)
        for (k in power.indices) power[k] = re[k] * re[k] + im[k] * im[k]
        for (m in 0 until nMels) {
            var e = 0.0
            val w = filters[m]
            val s = filterStart[m]
            for (j in w.indices) e += w[j] * power[s + j]
            out[m] = (10.0 * log10(max(e, 1e-10))).toFloat()
        }
    }

    companion object {
        fun hzToMel(hz: Double) = 1127.0 * ln(1.0 + hz / 700.0)
        fun melToHz(mel: Double) = 700.0 * (Math.exp(mel / 1127.0) - 1.0)
    }
}

/** In-place iterative radix-2 complex FFT. */
class Fft(val n: Int) {
    private val cosT = FloatArray(n / 2) { cos(2 * PI * it / n).toFloat() }
    private val sinT = FloatArray(n / 2) { sin(2 * PI * it / n).toFloat() }
    private val rev = IntArray(n).also { r ->
        val bits = Integer.numberOfTrailingZeros(n)
        for (i in 0 until n) r[i] = Integer.reverse(i) ushr (32 - bits)
    }

    fun transform(re: FloatArray, im: FloatArray) {
        for (i in 0 until n) {
            val j = rev[i]
            if (j > i) {
                var t = re[i]; re[i] = re[j]; re[j] = t
                t = im[i]; im[i] = im[j]; im[j] = t
            }
        }
        var size = 2
        while (size <= n) {
            val half = size / 2
            val step = n / size
            var start = 0
            while (start < n) {
                var k = 0
                for (j in start until start + half) {
                    val wr = cosT[k]
                    val wi = -sinT[k]
                    val l = j + half
                    val tr = re[l] * wr - im[l] * wi
                    val ti = re[l] * wi + im[l] * wr
                    re[l] = re[j] - tr
                    im[l] = im[j] - ti
                    re[j] += tr
                    im[j] += ti
                    k += step
                }
                start += size
            }
            size *= 2
        }
    }
}
