package com.kernel.sense_ai

import kotlin.math.*

/** Port of pinned src/audio.py (MIT). Distinct from the YAMNet/event frontend. */
internal object InsectFrontend {
    private const val FFT = 512
    private const val HOP = 160
    private const val SAMPLES = 32000
    private const val FRAMES = 201
    private val window = FloatArray(FFT) { (0.5 - 0.5 * cos(2 * PI * it / FFT)).toFloat() }
    private val filters = Array(64) { FloatArray(257) }.also { bank ->
        val topMel = 2595.0 * log10(1.0 + 8000.0 / 700.0)
        val bins = IntArray(66) { floor(513 * 700 * (10.0.pow(topMel * it / 65 / 2595) - 1) / 16000).toInt() }
        for (m in 0 until 64) {
            val left = bins[m]; val center = bins[m + 1]; val right = bins[m + 2]
            for (k in left until center) bank[m][k] = (k-left).toFloat() / (center-left)
            for (k in center until right) bank[m][k] = (right-k).toFloat() / (right-center)
        }
    }

    /** scipy.signal.resample_poly default Kaiser(beta=5), zero extension. */
    fun resample(wave: FloatArray, sampleRate: Int): FloatArray {
        require(sampleRate in 8000..96000)
        if (sampleRate == 16000) return wave.copyOf()
        fun gcd(a: Int, b: Int): Int = if (b == 0) a else gcd(b, a % b)
        val divisor = gcd(16000, sampleRate)
        val up = 16000 / divisor; val down = sampleRate / divisor
        val maxRate = maxOf(up, down); val half = 10 * maxRate
        fun i0(x: Double): Double {
            var term = 1.0; var sum = 1.0
            for (k in 1..40) { term *= x*x / (4*k*k); sum += term }
            return sum
        }
        val taps = DoubleArray(2 * half + 1) { k ->
            val x = (k-half).toDouble() / maxRate
            val sinc = if (x == 0.0) 1.0 else sin(PI*x) / (PI*x)
            sinc / maxRate * i0(5 * sqrt(maxOf(0.0, 1 - ((k-half).toDouble()/half).pow(2)))) / i0(5.0)
        }
        val scale = taps.sum()
        val h = FloatArray(taps.size) { (taps[it]/scale).toFloat() * up }
        val prePad = down - half % down
        val remove = (half + prePad) / down
        val result = FloatArray(((wave.size.toLong()*up + down-1)/down).toInt())
        for (out in result.indices) {
            val center = (out.toLong()+remove)*down - prePad
            val first = maxOf(0L, (center-h.lastIndex + up-1)/up).toInt()
            val last = minOf(wave.lastIndex.toLong(), center/up).toInt()
            var sum = 0f
            for (j in first..last) sum += wave[j] * h[(center-j.toLong()*up).toInt()]
            result[out] = sum
        }
        return result
    }

    fun cropOffsets(sampleCount: Int): IntArray = if (sampleCount <= SAMPLES) intArrayOf(0)
        else IntArray(5) { Math.rint((sampleCount-SAMPLES) * it / 4.0).toInt() }

    /** Same low-level floor as whole-file quality, on actual resampled/padded
     * crops BEFORE peak normalization. This is an all-windows safety veto, not
     * an instruction to drop quiet crops or change trained crop averaging.
     */
    fun hasSignalInSelectedCrops(wave: FloatArray, offsets: IntArray): Boolean = offsets.any { offset ->
        val start = offset.coerceIn(0, maxOf(0, wave.size - SAMPLES))
        var energy = 0.0
        for (i in start until minOf(start + SAMPLES, wave.size)) energy += (wave[i] * wave[i]).toDouble()
        sqrt(energy / SAMPLES) >= 0.002
    }

    // Double intermediates avoid accumulated roundoff in low-energy FFT bins.
    private fun transform(re: DoubleArray, im: DoubleArray) {
        for (i in 0 until FFT) {
            val j = Integer.reverse(i) ushr 23
            if (j > i) {
                val r = re[i]; re[i] = re[j]; re[j] = r
                val v = im[i]; im[i] = im[j]; im[j] = v
            }
        }
        var size = 2
        while (size <= FFT) {
            for (start in 0 until FFT step size) for (j in 0 until size / 2) {
                val a = start + j; val b = a + size / 2
                val wr = cos(2 * PI * j / size); val wi = -sin(2 * PI * j / size)
                val r = re[b] * wr - im[b] * wi; val v = re[b] * wi + im[b] * wr
                re[b] = re[a] - r; im[b] = im[a] - v
                re[a] += r; im[a] += v
            }
            size *= 2
        }
    }

    /** NumPy's contiguous float32 pairwise reduction (128-value, eight-lane blocks).
     * A double or sequential float sum changes normalization of constant crops.
     */
    private fun float32Sum(values: FloatArray, start: Int = 0, count: Int = values.size): Float {
        if (count < 8) {
            var sum = -0f
            for (i in start until start + count) sum += values[i]
            return sum
        }
        if (count <= 128) {
            val lanes = FloatArray(8) { values[start + it] }
            val aligned = count - count % 8
            for (i in 8 until aligned step 8) {
                for (lane in lanes.indices) lanes[lane] += values[start + i + lane]
            }
            var sum = ((lanes[0] + lanes[1]) + (lanes[2] + lanes[3])) +
                ((lanes[4] + lanes[5]) + (lanes[6] + lanes[7]))
            for (i in aligned until count) sum += values[start + i]
            return sum
        }
        val half = (count / 2).let { it - it % 8 }
        return float32Sum(values, start, half) + float32Sum(values, start + half, count - half)
    }

    fun logmel(wave: FloatArray, offset: Int = 0): FloatArray {
        val start = offset.coerceIn(0, maxOf(0, wave.size - SAMPLES))
        val y = FloatArray(SAMPLES) { wave.getOrElse(start + it) { 0f } }
        val peak = y.maxOf { abs(it) }
        if (peak > 1e-8f) for (i in y.indices) y[i] /= peak
        val re = DoubleArray(FFT); val im = DoubleArray(FFT); val power = FloatArray(257)
        val features = FloatArray(64 * FRAMES)
        for (frame in 0 until FRAMES) {
            for (i in 0 until FFT) {
                // scipy STFT boundary=zeros centers frame 0 at input sample 0.
                re[i] = (y.getOrElse(frame * HOP + i - FFT / 2) { 0f } * window[i]).toDouble()
                im[i] = 0.0
            }
            transform(re, im)
            for (k in power.indices) {
                val r = (re[k] / 256).toFloat(); val j = (im[k] / 256).toFloat()
                power[k] = r*r + j*j // scipy scaling='spectrum': divide by sum(Hann).
            }
            for (m in 0 until 64) {
                var energy = 0f
                for (k in power.indices) energy += filters[m][k] * power[k]
                features[m * FRAMES + frame] = ln(maxOf(energy, 1e-8f))
            }
        }
        // Upstream mean/std, centering and epsilon arithmetic all remain float32.
        // In particular, a silent crop must not be special-cased to all zeroes.
        val mean = float32Sum(features) / features.size
        val squared = FloatArray(features.size) { (features[it] - mean).let { value -> value * value } }
        val std = sqrt(float32Sum(squared) / features.size)
        squared.fill(0f)
        for (i in features.indices) features[i] = (features[i] - mean) / (std + 1e-5f)
        y.fill(0f)
        return features
    }
}
