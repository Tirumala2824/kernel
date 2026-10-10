/* Biquads (RBJ cookbook), Butterworth cascades, FFT and clipping.
 * Mirrors firmware/reference/kernel_ref/dsp.py and detect.ClipDetector. */
#include <math.h>
#include <string.h>

#include "kernel_detect.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

kd_biquad_coef_t kd_biquad_highpass(float fs, float fc, float q)
{
    double w0 = 2.0 * M_PI * fc / fs;
    double cw = cos(w0), sw = sin(w0);
    double alpha = sw / (2.0 * q);
    double a0 = 1.0 + alpha;
    kd_biquad_coef_t c;
    c.b0 = (float)((1.0 + cw) / 2.0 / a0);
    c.b1 = (float)(-(1.0 + cw) / a0);
    c.b2 = (float)((1.0 + cw) / 2.0 / a0);
    c.a1 = (float)(-2.0 * cw / a0);
    c.a2 = (float)((1.0 - alpha) / a0);
    return c;
}

kd_biquad_coef_t kd_biquad_lowpass(float fs, float fc, float q)
{
    double w0 = 2.0 * M_PI * fc / fs;
    double cw = cos(w0), sw = sin(w0);
    double alpha = sw / (2.0 * q);
    double a0 = 1.0 + alpha;
    kd_biquad_coef_t c;
    c.b0 = (float)((1.0 - cw) / 2.0 / a0);
    c.b1 = (float)((1.0 - cw) / a0);
    c.b2 = (float)((1.0 - cw) / 2.0 / a0);
    c.a1 = (float)(-2.0 * cw / a0);
    c.a2 = (float)((1.0 - alpha) / a0);
    return c;
}

static int butter(kd_biquad_t *bq, float fs, float fc, int order, int high)
{
    if (order <= 0 || (order % 2) != 0) {
        return -1;
    }
    int sections = order / 2;
    if (bq->n + sections > KD_MAX_BIQUADS) {
        return -1;
    }
    for (int k = 0; k < sections; k++) {
        double q = 1.0 / (2.0 * cos((2.0 * k + 1.0) * M_PI / (2.0 * order)));
        bq->c[bq->n] = high ? kd_biquad_highpass(fs, fc, (float)q) : kd_biquad_lowpass(fs, fc, (float)q);
        bq->z1[bq->n] = 0.0f;
        bq->z2[bq->n] = 0.0f;
        bq->n++;
    }
    return 0;
}

int kd_butter_highpass(kd_biquad_t *bq, float fs, float fc, int order) { return butter(bq, fs, fc, order, 1); }

int kd_butter_lowpass(kd_biquad_t *bq, float fs, float fc, int order) { return butter(bq, fs, fc, order, 0); }

void kd_biquad_reset(kd_biquad_t *bq)
{
    memset(bq->z1, 0, sizeof(bq->z1));
    memset(bq->z2, 0, sizeof(bq->z2));
}

void kd_biquad_run(kd_biquad_t *bq, float *x, size_t n)
{
    for (uint8_t s = 0; s < bq->n; s++) {
        const kd_biquad_coef_t c = bq->c[s];
        float z1 = bq->z1[s], z2 = bq->z2[s];
        for (size_t i = 0; i < n; i++) {
            float in = x[i];
            float out = c.b0 * in + z1;
            z1 = c.b1 * in - c.a1 * out + z2;
            z2 = c.b2 * in - c.a2 * out;
            x[i] = out;
        }
        bq->z1[s] = z1;
        bq->z2[s] = z2;
    }
}

/* ------------------------------------------------------------------ FFT */

void kd_fft_tables(uint16_t n, float *tw_cos, float *tw_sin, uint16_t *bitrev)
{
    unsigned bits = 0;
    while ((1u << bits) < n) {
        bits++;
    }
    for (uint16_t i = 0; i < n / 2; i++) {
        double a = -2.0 * M_PI * i / n;
        tw_cos[i] = (float)cos(a);
        tw_sin[i] = (float)sin(a);
    }
    for (uint16_t i = 0; i < n; i++) {
        uint16_t r = 0;
        for (unsigned b = 0; b < bits; b++) {
            if (i & (1u << b)) {
                r |= (uint16_t)(1u << (bits - 1 - b));
            }
        }
        bitrev[i] = r;
    }
}

void kd_fft(uint16_t n, float *re, float *im, const float *tw_cos, const float *tw_sin, const uint16_t *bitrev)
{
    for (uint16_t i = 0; i < n; i++) {
        uint16_t j = bitrev[i];
        if (j > i) {
            float t = re[i];
            re[i] = re[j];
            re[j] = t;
            t = im[i];
            im[i] = im[j];
            im[j] = t;
        }
    }
    for (uint16_t len = 2; len <= n; len <<= 1) {
        uint16_t half = len >> 1;
        uint16_t step = n / len;
        for (uint16_t base = 0; base < n; base += len) {
            for (uint16_t k = 0; k < half; k++) {
                float wr = tw_cos[k * step], wi = tw_sin[k * step];
                uint16_t a = base + k, b = a + half;
                float xr = re[b] * wr - im[b] * wi;
                float xi = re[b] * wi + im[b] * wr;
                re[b] = re[a] - xr;
                im[b] = im[a] - xi;
                re[a] += xr;
                im[a] += xi;
            }
        }
    }
}

/* ------------------------------------------------------------- clipping */

void kd_clip_init(kd_clip_t *c, const kd_clip_cfg_t *cfg, uint32_t fs)
{
    memset(c, 0, sizeof(*c));
    c->cfg = *cfg;
    long w = kd_lround((double)cfg->window_ms * fs / 1000.0);
    c->win = (uint64_t)(w < 1 ? 1 : w);
    c->hold = (uint64_t)kd_lround((double)cfg->hold_ms * fs / 1000.0);
    c->cur_win = -1;
    c->hold_until = -1;
}

void kd_clip_push(kd_clip_t *c, const float *x, size_t n)
{
    for (size_t i = 0; i < n; i++) {
        if (fabsf(x[i]) >= c->cfg.level) {
            uint64_t idx = c->n_total + i;
            int64_t w = (int64_t)(idx / c->win);
            if (w != c->cur_win) {
                c->cur_win = w;
                c->win_count = 0;
            }
            c->win_count++;
            if (c->win_count >= c->cfg.count) {
                c->hold_until = (int64_t)(idx + c->hold);
                c->ever = true;
            }
        }
    }
    c->n_total += n;
}

bool kd_clip_active(const kd_clip_t *c) { return (int64_t)c->n_total <= c->hold_until; }
