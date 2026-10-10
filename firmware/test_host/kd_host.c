/* Host harness: runs kernel_detect on a float32 PCM file exactly like
 * kernel_ref.detect.run_spectral_node / run_contact_node and prints one JSON
 * object per line (events, then a summary). Used by
 * firmware/reference/tests/test_c_parity.py when a host C compiler exists.
 *
 *   kd_host us|audio|contact input.f32
 *
 * Test tool only: never part of the node firmware. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "kernel_detect.h"

static void on_event(void *ctx, const kd_event_t *e)
{
    (void)ctx;
    printf("{\"t\":%.3f,\"dur\":%.3f,\"cls\":%u,\"flags\":%u,\"peak\":%.2f,\"min\":%.2f,\"max\":%.2f,"
           "\"slope\":%.3f,\"snr\":%.3f,\"dbfs\":%.3f,\"imp\":%u,\"harm\":%u,\"rep\":%.4f,\"cv\":%.4f}\n",
           e->t_start_ms, e->duration_ms, e->cls, e->flags, e->peak_hz, e->min_hz, e->max_hz, e->slope_hz_per_ms,
           e->snr_db, e->peak_dbfs, e->impulses, e->harmonics, e->rep_rate_hz, e->ipi_cv);
}

static void linear(kd_spec_cfg_t *s, float lo, float hi, float step)
{
    s->n_bands = (uint8_t)kd_lround((hi - lo) / step);
    for (int i = 0; i <= s->n_bands; i++) {
        s->band_edges_hz[i] = lo + i * step;
    }
}

static void table(kd_spec_cfg_t *s, const float *e, int n)
{
    s->n_bands = (uint8_t)(n - 1);
    memcpy(s->band_edges_hz, e, sizeof(float) * n);
}

int main(int argc, char **argv)
{
    if (argc != 3) {
        fprintf(stderr, "usage: kd_host us|audio|contact input.f32\n");
        return 2;
    }
    FILE *f = fopen(argv[2], "rb");
    if (!f) {
        return 2;
    }
    fseek(f, 0, SEEK_END);
    long bytes = ftell(f);
    fseek(f, 0, SEEK_SET);
    size_t n = (size_t)bytes / sizeof(float);
    float *x = malloc(n * sizeof(float));
    if (!x || fread(x, sizeof(float), n, f) != n) {
        return 2;
    }
    fclose(f);

    static kd_spec_t spec;
    static kd_imp_t imp;
    kd_clip_t clip;
    kd_clip_cfg_t ccfg = {.level = 0.98f, .count = 3, .window_ms = 100.0f, .hold_ms = 2000.0f};
    kd_sinks_t sinks = {.on_event = on_event};
    kd_spec_cfg_t s;
    kd_spec_default_cfg(&s);
    bool contact = strcmp(argv[1], "contact") == 0;
    bool us = strcmp(argv[1], "us") == 0;
    kd_biquad_t hp;
    memset(&hp, 0, sizeof(hp));
    size_t chunk;
    if (us) {
        s.fs = 192000;
        s.n_fft = 512;
        s.hop = 256;
        s.lo_hz = 20000;
        s.hi_hz = 92000;
        linear(&s, 20000, 92000, 4000);
        kd_butter_highpass(&hp, 192000.0f, 20000.0f, 6);
        chunk = 256;
    } else if (!contact) {
        static const float e[] = {100, 160, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600,
                                  2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 15000};
        s.fs = 32000;
        s.n_fft = 512;
        s.hop = 128;
        s.lo_hz = 100;
        s.hi_hz = 15000;
        s.smooth_frames = 1;
        s.detect_thresh_db = 20;
        s.min_blob_ms = 8;
        s.max_gap_ms = 0;
        s.max_jump_hz = 400;
        s.fm_min_bw_hz = 1500;
        s.harmonic_search = true;
        s.chirp_grouping = true;
        table(&s, e, (int)(sizeof(e) / sizeof(e[0])));
        chunk = 128;
    } else {
        chunk = 480;
    }
    uint32_t fs = contact ? 48000 : s.fs;
    kd_clip_init(&clip, &ccfg, fs);
    if (contact) {
        kd_imp_cfg_t ic;
        kd_imp_default_cfg(&ic);
        if (kd_imp_init(&imp, &ic, &sinks) != 0) {
            return 3;
        }
    } else if (kd_spec_init(&spec, &s, &sinks) != 0) {
        return 3;
    }
    float buf[512];
    bool clipped_ever = false;
    for (size_t i = 0; i < n; i += chunk) {
        size_t m = n - i < chunk ? n - i : chunk;
        memcpy(buf, x + i, m * sizeof(float));
        kd_clip_push(&clip, buf, m);
        bool clipped = kd_clip_active(&clip);
        clipped_ever = clipped_ever || clip.ever;
        uint8_t ext = clipped ? KD_H_CLIPPED : 0;
        if (contact) {
            kd_imp_push(&imp, buf, m, ext);
        } else {
            if (hp.n) {
                kd_biquad_run(&hp, buf, m);
            }
            kd_spec_push(&spec, buf, m, ext);
        }
    }
    if (contact) {
        kd_imp_finish(&imp);
    } else {
        kd_spec_finish(&spec);
    }
    printf("{\"summary\":true,\"jammed\":%s,\"clipped\":%s}\n",
           (contact ? imp.jammed_ever : spec.jammed_ever) ? "true" : "false", clipped_ever ? "true" : "false");
    free(x);
    return 0;
}
