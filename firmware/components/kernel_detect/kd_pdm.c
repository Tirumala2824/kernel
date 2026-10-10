/* PDM bitstream -> PCM: CIC (order 4, R = 8) then a 47-tap half-band FIR
 * decimating by 2. 3.072 MHz -> 384 kHz -> 192 kHz.
 * Mirrors kernel_ref.dsp.PdmDecimator (the CIC part is bit-exact). */
#include <string.h>

#include "kernel_detect.h"

void kd_pdm_init(kd_pdm_t *p) { memset(p, 0, sizeof(*p)); }

static inline int hb_push(kd_pdm_t *p, float x, float *y)
{
    p->hb_hist[p->hb_pos] = x;
    int emit = (p->hb_phase & 1u) != 0;
    if (emit) {
        float acc = 0.0f;
        uint32_t idx = p->hb_pos;
        for (uint32_t j = 0; j < KD_PDM_HB_TAPS; j++) {
            acc += kd_halfband_taps[j] * p->hb_hist[idx];
            idx = (idx == 0) ? (KD_PDM_HB_TAPS - 1) : (idx - 1);
        }
        *y = acc;
    }
    p->hb_pos = (p->hb_pos + 1) % KD_PDM_HB_TAPS;
    p->hb_phase ^= 1u;
    return emit;
}

size_t kd_pdm_run(kd_pdm_t *p, const uint32_t *words, size_t n_words, float *out, size_t out_cap)
{
    /* Unsigned arithmetic gives defined wrap-around; the true CIC output is
     * bounded by R^N = 4096, so the final cast to int32 is exact. */
    uint32_t i0 = (uint32_t)p->integ[0], i1 = (uint32_t)p->integ[1];
    uint32_t i2 = (uint32_t)p->integ[2], i3 = (uint32_t)p->integ[3];
    const float scale = 1.0f / 4096.0f; /* 1 / R^N */
    size_t n_out = 0;
    for (size_t w = 0; w < n_words; w++) {
        uint32_t word = words[w];
        for (int b = 31; b >= 0; b--) {
            uint32_t x = ((word >> b) & 1u) ? 1u : (uint32_t)-1;
            i0 += x;
            i1 += i0;
            i2 += i1;
            i3 += i2;
            if (++p->phase == KD_PDM_CIC_R) {
                p->phase = 0;
                uint32_t y = i3;
                for (int s = 0; s < KD_PDM_CIC_ORDER; s++) {
                    uint32_t t = y;
                    y = y - (uint32_t)p->comb[s];
                    p->comb[s] = (int32_t)t;
                }
                float pcm384 = (float)(int32_t)y * scale;
                float pcm192;
                if (hb_push(p, pcm384, &pcm192) && n_out < out_cap) {
                    out[n_out++] = pcm192;
                }
            }
        }
    }
    p->integ[0] = (int32_t)i0;
    p->integ[1] = (int32_t)i1;
    p->integ[2] = (int32_t)i2;
    p->integ[3] = (int32_t)i3;
    return n_out;
}
