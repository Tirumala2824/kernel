/* Spectral detector: STFT, running 5 % quantile floor, jammer detection,
 * tonal/FM blob tracking, harmonic search, chirp grouping and band frames.
 * Mirrors kernel_ref.detect.SpectralDetector; keep both in step. */
#include <float.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "kernel_detect.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define EPSF 1e-20f

static uint32_t u_ceil(double v) { return v <= 0.0 ? 0u : (uint32_t)ceil(v); }
static uint32_t u_floor(double v) { return v <= 0.0 ? 0u : (uint32_t)floor(v); }
static uint32_t u_round(double v) { return v <= 0.0 ? 0u : (uint32_t)kd_lround(v); }
static uint32_t u_max1(uint32_t v) { return v < 1u ? 1u : v; }

void kd_spec_default_cfg(kd_spec_cfg_t *c)
{
    memset(c, 0, sizeof(*c));
    c->smooth_frames = 3;
    c->detect_thresh_db = 14.0f;
    c->min_blob_ms = 5.0f;
    c->max_gap_ms = 4.0f;
    c->max_jump_hz = 1500.0f;
    c->max_blob_ms = 8000.0f;
    c->flat_min_ms = 300.0f;
    c->cont_min_ms = 1000.0f;
    c->fm_min_bw_hz = 3000.0f;
    c->harmonic_search = false;
    c->harmonic_rel_db = 3.0f;
    c->max_harmonics = 8;
    c->chirp_grouping = false;
    c->chirp_max_gap_ms = 120.0f;
    c->chirp_pulse_max_ms = 60.0f;
    c->chirp_freq_tol = 0.15f;
    c->chirp_max_cv = 0.30f;
    c->train_min_pulses = 3;
    c->jam_thresh_db = 6.0f;
    c->jam_hold_ms = 2000.0f;
    c->jam_miss_penalty = 10;
    c->jam_release_ms = 5000.0f;
    c->jam_occupancy = 0.9f;
    c->line_block_ms = 250.0f;
    c->line_neigh_lo = 3;
    c->line_neigh_hi = 10;
    c->band_frame_ms = 1000.0f;
    c->events_enabled = true;
    c->floor.quantile = 0.05f;
    c->floor.up_db_per_s = 0.5f;
    c->floor.warmup_ms = 1000.0f;
    c->floor.warmup_speedup = 20.0f;
}

int kd_spec_init(kd_spec_t *s, const kd_spec_cfg_t *cfg, const kd_sinks_t *sinks)
{
    uint16_t n = cfg->n_fft;
    if (n < 16 || n > KD_MAX_FFT || (n & (n - 1)) != 0 || cfg->hop == 0 || cfg->hop > n || cfg->fs == 0) {
        return -1;
    }
    if (cfg->n_bands < 1 || cfg->n_bands > KD_MAX_BANDS || cfg->smooth_frames < 1 ||
        cfg->smooth_frames > KD_MAX_SMOOTH || cfg->floor.quantile <= 0.0f || cfg->floor.quantile >= 1.0f) {
        return -1;
    }
    memset(s, 0, sizeof(*s));
    s->cfg = *cfg;
    if (sinks) {
        s->sinks = *sinks;
    }
    s->nb = (uint16_t)(n / 2 + 1);
    double wsum = 0.0;
    for (uint16_t i = 0; i < n; i++) {
        s->win[i] = (float)(0.5 - 0.5 * cos(2.0 * M_PI * i / n));
        wsum += s->win[i];
    }
    s->pscale = (float)((2.0 / wsum) * (2.0 / wsum));
    double bin_hz = (double)cfg->fs / n;
    double hop_ms = 1000.0 * cfg->hop / cfg->fs;
    double fps = (double)cfg->fs / cfg->hop;
    s->bin_hz = (float)bin_hz;
    s->hop_ms = (float)hop_ms;
    uint32_t k_lo = u_ceil(cfg->lo_hz / bin_hz);
    s->k_lo = (uint16_t)(k_lo < 1 ? 1 : k_lo);
    uint32_t k_hi = u_floor(cfg->hi_hz / bin_hz);
    s->k_hi = (uint16_t)(k_hi > (uint32_t)(s->nb - 2) ? (uint32_t)(s->nb - 2) : k_hi);
    if (s->k_hi <= s->k_lo + 2) {
        return -1;
    }
    for (uint8_t b = 0; b < cfg->n_bands; b++) {
        uint32_t k0 = u_ceil(cfg->band_edges_hz[b] / bin_hz);
        if (k0 < s->k_lo) {
            k0 = s->k_lo;
        }
        int64_t k1 = (int64_t)u_ceil(cfg->band_edges_hz[b + 1] / bin_hz) - 1;
        if (k1 > s->k_hi) {
            k1 = s->k_hi;
        }
        if (k1 < (int64_t)k0) {
            k1 = k0;
        }
        s->band_lo[b] = (uint16_t)k0;
        s->band_hi[b] = (uint16_t)k1;
    }
    s->eta = (float)(cfg->floor.up_db_per_s / (cfg->floor.quantile * fps));
    s->warmup_frames = u_ceil(cfg->floor.warmup_ms / hop_ms);
    s->min_blob_frames = u_max1(u_ceil(cfg->min_blob_ms / hop_ms - 1e-9));
    s->max_gap_frames = u_floor(cfg->max_gap_ms / hop_ms + 1e-9);
    s->max_jump_bins = u_max1(u_round(cfg->max_jump_hz / bin_hz));
    s->max_blob_frames = u_ceil(cfg->max_blob_ms / hop_ms);
    s->jam_hold_frames = u_ceil(cfg->jam_hold_ms / hop_ms);
    s->jam_release_frames = u_ceil(cfg->jam_release_ms / hop_ms);
    s->line_block_frames = u_max1(u_round(cfg->line_block_ms / hop_ms));
    uint32_t lb = u_max1(u_ceil((double)cfg->jam_hold_ms / cfg->line_block_ms));
    s->line_blocks = lb > KD_MAX_LINE_BLOCKS ? KD_MAX_LINE_BLOCKS : lb;
    s->band_frame_frames = u_max1(u_round(cfg->band_frame_ms / hop_ms));
    kd_fft_tables(n, s->tw_cos, s->tw_sin, s->bitrev);
    for (uint16_t k = 0; k < s->nb; k++) {
        s->blk_min[k] = INFINITY;
    }
    s->bf_peak_l = -INFINITY;
    return 0;
}

uint8_t kd_spec_health(const kd_spec_t *s)
{
    uint8_t h = 0;
    if (s->jammed) {
        h |= KD_H_JAMMED;
    }
    h |= (uint8_t)(s->ext_flags & (KD_H_CLIPPED | KD_H_SURVEY));
    if (s->frame < s->warmup_frames) {
        h |= KD_H_WARMING;
    }
    return h;
}

/* ------------------------------------------------------------ helpers */

static float interp_hz(const kd_spec_t *s, int k)
{
    float a = s->level[k - 1], b = s->level[k], c = s->level[k + 1];
    float den = a - 2.0f * b + c;
    float d = (den == 0.0f) ? 0.0f : 0.5f * (a - c) / den;
    if (d > 0.5f) {
        d = 0.5f;
    } else if (d < -0.5f) {
        d = -0.5f;
    }
    return ((float)k + d) * s->bin_hz;
}

static void sort_f(float *v, int n)
{
    for (int i = 1; i < n; i++) {
        float x = v[i];
        int j = i - 1;
        while (j >= 0 && v[j] > x) {
            v[j + 1] = v[j];
            j--;
        }
        v[j + 1] = x;
    }
}

static float median_f(float *v, int n)
{
    sort_f(v, n);
    return (n % 2) ? v[n / 2] : 0.5f * (v[n / 2 - 1] + v[n / 2]);
}

static void ipi_stats(const double *onsets, int n, float *rate, float *cv)
{
    *rate = 0.0f;
    *cv = -1.0f;
    if (n >= 2) {
        double span = (onsets[n - 1] - onsets[0]) / 1000.0;
        *rate = span > 0 ? (float)((n - 1) / span) : 0.0f;
    }
    if (n >= 3) {
        double m = 0.0;
        for (int i = 1; i < n; i++) {
            m += onsets[i] - onsets[i - 1];
        }
        m /= (n - 1);
        if (m > 0) {
            double v = 0.0;
            for (int i = 1; i < n; i++) {
                double d = (onsets[i] - onsets[i - 1]) - m;
                v += d * d;
            }
            v /= (n - 1);
            *cv = (float)(sqrt(v) / m);
        }
    }
}

static void emit(kd_spec_t *s, const kd_event_t *ev)
{
    if (s->sinks.on_event) {
        s->sinks.on_event(s->sinks.ctx, ev);
    }
}

/* ------------------------------------------------------------- chirps */

static void flush_chirp(kd_spec_t *s)
{
    uint8_t n = s->chirp_n;
    s->chirp_n = 0;
    if (n == 0) {
        return;
    }
    if (n < s->cfg.train_min_pulses) {
        for (uint8_t i = 0; i < n; i++) {
            emit(s, &s->chirp[i]);
        }
        return;
    }
    double onsets[KD_MAX_CHIRP];
    double peak_sum = 0.0;
    kd_event_t ev;
    memset(&ev, 0, sizeof(ev));
    ev.min_hz = FLT_MAX;
    ev.max_hz = -FLT_MAX;
    ev.snr_db = -FLT_MAX;
    ev.peak_dbfs = -FLT_MAX;
    for (uint8_t i = 0; i < n; i++) {
        const kd_event_t *p = &s->chirp[i];
        onsets[i] = p->t_start_ms;
        peak_sum += p->peak_hz;
        ev.min_hz = fminf(ev.min_hz, p->min_hz);
        ev.max_hz = fmaxf(ev.max_hz, p->max_hz);
        ev.snr_db = fmaxf(ev.snr_db, p->snr_db);
        ev.peak_dbfs = fmaxf(ev.peak_dbfs, p->peak_dbfs);
    }
    ev.t_start_ms = s->chirp[0].t_start_ms;
    ev.duration_ms = (float)(s->chirp[n - 1].t_start_ms + s->chirp[n - 1].duration_ms - s->chirp[0].t_start_ms);
    ev.cls = KD_PULSED_CHIRP;
    ev.peak_hz = (float)(peak_sum / n);
    ev.impulses = n;
    ipi_stats(onsets, n, &ev.rep_rate_hz, &ev.ipi_cv);
    if (ev.ipi_cv >= 0.0f && ev.ipi_cv <= s->cfg.chirp_max_cv) {
        ev.flags |= KD_EF_REGULAR_TRAIN;
    }
    emit(s, &ev);
}

/* -------------------------------------------------------------- blobs */

static void close_blob(kd_spec_t *s, bool truncated)
{
    kd_blob_t b = s->blob;
    s->blob.open = false;
    s->gap = 0;
    if (!b.open || b.tainted) {
        return;
    }
    uint32_t span = b.last - b.first + 1;
    if (span < s->min_blob_frames) {
        return;
    }
    const kd_spec_cfg_t *c = &s->cfg;
    float dur = (float)(span * (double)s->hop_ms);
    float bw = b.fmax - b.fmin;
    float slope = 0.0f;
    double den = b.n * b.stt - b.st * b.st;
    if (b.n >= 2 && den > 0) {
        slope = (float)((b.n * b.stf - b.st * b.sf) / den);
    }
    uint32_t harmonics = b.n ? (uint32_t)kd_lround((double)b.harm_sum / b.n) : 0;
    uint8_t cls;
    if (c->harmonic_search && b.harm_frames * 2 >= b.n && harmonics >= 1) {
        cls = KD_HARMONIC;
    } else if (dur >= c->cont_min_ms) {
        cls = (bw >= c->fm_min_bw_hz) ? KD_CONTINUOUS_EMITTER : KD_FLAT_TONE;
    } else if (bw >= c->fm_min_bw_hz) {
        cls = KD_FM_SWEEP;
    } else if (dur >= c->flat_min_ms) {
        cls = KD_FLAT_TONE;
    } else {
        cls = KD_TONAL;
    }
    kd_event_t ev;
    memset(&ev, 0, sizeof(ev));
    ev.t_start_ms = b.first * (double)s->hop_ms;
    ev.duration_ms = dur;
    ev.cls = cls;
    ev.flags = truncated ? KD_EF_TRUNCATED : 0;
    ev.peak_hz = b.peak_hz;
    ev.min_hz = b.fmin;
    ev.max_hz = b.fmax;
    ev.slope_hz_per_ms = slope;
    ev.snr_db = b.max_excess;
    ev.peak_dbfs = b.peak_level;
    ev.harmonics = (uint16_t)(cls == KD_HARMONIC ? harmonics : 0);
    ev.ipi_cv = -1.0f;
    if (c->chirp_grouping && cls == KD_TONAL && dur <= c->chirp_pulse_max_ms) {
        if (s->chirp_n > 0) {
            const kd_event_t *last = &s->chirp[s->chirp_n - 1];
            const kd_event_t *first = &s->chirp[0];
            double gap = ev.t_start_ms - (last->t_start_ms + last->duration_ms);
            bool near = fabsf(ev.peak_hz - first->peak_hz) <= c->chirp_freq_tol * first->peak_hz;
            if (gap <= c->chirp_max_gap_ms && near && s->chirp_n < KD_MAX_CHIRP) {
                s->chirp[s->chirp_n++] = ev;
                return;
            }
        }
        flush_chirp(s);
        s->chirp[0] = ev;
        s->chirp_n = 1;
        return;
    }
    emit(s, &ev);
}

static void harmonics(const kd_spec_t *s, int kp, int *k0_out, uint32_t *hc_out)
{
    const kd_spec_cfg_t *c = &s->cfg;
    float thr = c->detect_thresh_db - c->harmonic_rel_db;
    int k0 = kp;
    static const int hs[3] = {4, 3, 2};
    for (int i = 0; i < 3; i++) {
        int kc = (int)kd_lround((double)kp / hs[i]);
        if (kc - 1 < s->k_lo || kc < 3) {
            continue;
        }
        int kk = kc - 1;
        for (int k = kc; k <= kc + 1; k++) {
            if (s->excess[k] > s->excess[kk]) {
                kk = k;
            }
        }
        bool local_peak = s->excess[kk] >= s->excess[kk - 1] && s->excess[kk] >= s->excess[kk + 1];
        if (s->excess[kk] >= thr && local_peak && kk <= kp - 3) {
            k0 = kk;
            break;
        }
    }
    float f0 = interp_hz(s, k0) / s->bin_hz;
    uint32_t hc = 0;
    for (int m = 2; m <= c->max_harmonics; m++) {
        int km = (int)kd_lround((double)m * f0);
        if (km + 1 > s->k_hi) {
            break;
        }
        float mx = s->excess[km - 1];
        if (s->excess[km] > mx) {
            mx = s->excess[km];
        }
        if (s->excess[km + 1] > mx) {
            mx = s->excess[km + 1];
        }
        if (mx >= thr) {
            hc++;
        }
    }
    *k0_out = k0;
    *hc_out = hc;
}

static void track(kd_spec_t *s, uint32_t i, bool evaluated, int kp, bool active)
{
    const kd_spec_cfg_t *c = &s->cfg;
    if (s->blob.open && !evaluated) {
        s->blob.tainted = true;
    }
    if (!active) {
        if (s->blob.open) {
            s->gap++;
            if (s->gap > s->max_gap_frames) {
                close_blob(s, false);
            }
        }
        return;
    }
    uint32_t hc = 0;
    int k_track = kp;
    if (c->harmonic_search) {
        harmonics(s, kp, &k_track, &hc);
    }
    if (s->blob.open && (uint32_t)abs(k_track - s->blob.last_k) > s->max_jump_bins) {
        close_blob(s, false);
    }
    if (s->blob.open && (i - s->blob.first + 1) > s->max_blob_frames) {
        close_blob(s, true);
    }
    kd_blob_t *b = &s->blob;
    if (!b->open) {
        memset(b, 0, sizeof(*b));
        b->open = true;
        b->first = i;
        b->last = i;
        b->last_k = k_track;
        b->fmin = INFINITY;
        b->fmax = -INFINITY;
        b->peak_level = -INFINITY;
        b->max_excess = 0.0f;
        b->tainted = !evaluated;
    }
    float f = interp_hz(s, k_track);
    double t_rel = (i - b->first) * (double)s->hop_ms;
    b->last = i;
    b->last_k = k_track;
    b->n++;
    b->fmin = fminf(b->fmin, f);
    b->fmax = fmaxf(b->fmax, f);
    if (s->level[k_track] > b->peak_level) {
        b->peak_level = s->level[k_track];
        b->peak_hz = f;
    }
    b->max_excess = fmaxf(b->max_excess, s->excess[k_track]);
    b->st += t_rel;
    b->sf += f;
    b->stt += t_rel * t_rel;
    b->stf += t_rel * f;
    if (hc >= 1) {
        b->harm_frames++;
    }
    b->harm_sum += hc;
    s->gap = 0;
}

/* ------------------------------------------------------------- jammer */

static void lines(kd_spec_t *s, const float *minhold)
{
    const kd_spec_cfg_t *c = &s->cfg;
    float neigh[2 * 32];
    for (int k = 0; k < s->nb; k++) {
        s->line_bins[k] = 0;
    }
    int hi = c->line_neigh_hi > 32 ? 32 : c->line_neigh_hi;
    for (int k = s->k_lo; k <= s->k_hi; k++) {
        int nn = 0;
        for (int d = c->line_neigh_lo; d <= hi; d++) {
            if (k - d >= s->k_lo) {
                neigh[nn++] = s->floor_db[k - d];
            }
            if (k + d <= s->k_hi) {
                neigh[nn++] = s->floor_db[k + d];
            }
        }
        if (nn < 6) {
            continue;
        }
        if (minhold[k] - median_f(neigh, nn) >= c->jam_thresh_db) {
            s->line_bins[k] = 1;
        }
    }
}

static void jam_update(kd_spec_t *s, bool warming, bool active)
{
    const kd_spec_cfg_t *c = &s->cfg;
    bool stationary_any = false;
    bool stationary[KD_MAX_BANDS];
    /* (a) band held above floor + jam_thresh: leaky run credit. */
    for (uint8_t b = 0; b < c->n_bands; b++) {
        if (s->bexc[b] >= c->jam_thresh_db) {
            s->run[b]++;
        } else {
            s->run[b] = s->run[b] > c->jam_miss_penalty ? s->run[b] - c->jam_miss_penalty : 0u;
        }
        stationary[b] = s->run[b] >= s->jam_hold_frames;
        stationary_any = stationary_any || stationary[b];
    }
    /* (c) detector busy in >= jam_occupancy of the frames (sweepers). */
    s->occ_any += active ? 1u : 0u;
    s->occ_n++;
    if (s->occ_n >= s->jam_hold_frames) {
        s->occ_flag = (double)s->occ_any >= (double)c->jam_occupancy * s->occ_n;
        s->occ_any = 0;
        s->occ_n = 0;
    }
    for (uint16_t k = 0; k < s->nb; k++) {
        if (s->level[k] < s->blk_min[k]) {
            s->blk_min[k] = s->level[k];
        }
    }
    s->blk_n++;
    if (s->blk_n >= s->line_block_frames) {
        memcpy(s->blk_ring[s->blk_head], s->blk_min, sizeof(float) * s->nb);
        s->blk_head = (s->blk_head + 1) % s->line_blocks;
        if (s->blk_count < s->line_blocks) {
            s->blk_count++;
        }
        for (uint16_t k = 0; k < s->nb; k++) {
            s->blk_min[k] = INFINITY;
        }
        s->blk_n = 0;
        if (s->blk_count == s->line_blocks) {
            /* blk_min is free scratch until the next frame refills it. */
            float *minhold = s->blk_min;
            for (uint16_t k = 0; k < s->nb; k++) {
                float m = INFINITY;
                for (uint32_t r = 0; r < s->line_blocks; r++) {
                    if (s->blk_ring[r][k] < m) {
                        m = s->blk_ring[r][k];
                    }
                }
                minhold[k] = m;
            }
            lines(s, minhold);
            for (uint16_t k = 0; k < s->nb; k++) {
                s->blk_min[k] = INFINITY;
            }
        }
    }
    bool line_any = false;
    for (int k = s->k_lo; k <= s->k_hi; k++) {
        if (s->line_bins[k]) {
            line_any = true;
            break;
        }
    }
    bool cond = stationary_any || s->occ_flag || line_any;
    if (warming) {
        cond = false;
    }
    if (cond) {
        s->jam_left = s->jam_release_frames;
    } else if (s->jam_left > 0) {
        s->jam_left--;
    }
    s->jammed = cond || s->jam_left > 0;
    if (s->jammed) {
        s->jammed_ever = true;
    }
    uint32_t mask = 0;
    for (uint8_t b = 0; b < c->n_bands; b++) {
        bool hit = stationary[b];
        for (int k = s->band_lo[b]; !hit && k <= s->band_hi[b]; k++) {
            hit = s->line_bins[k] != 0;
        }
        if (hit) {
            mask |= 1u << b;
        }
    }
    s->jam_band_mask = mask;
}

/* -------------------------------------------------------- band frames */

static void band_frame(kd_spec_t *s, double t_ms)
{
    const kd_spec_cfg_t *c = &s->cfg;
    if (s->bf_n == 0) {
        s->bf_start = t_ms;
        for (uint8_t b = 0; b < c->n_bands; b++) {
            s->bf_max[b] = 0.0f;
        }
        s->bf_peak_l = -INFINITY;
        s->bf_flags = 0;
    }
    for (uint8_t b = 0; b < c->n_bands; b++) {
        float v = s->bexc[b] > 0.0f ? s->bexc[b] : 0.0f;
        if (v > s->bf_max[b]) {
            s->bf_max[b] = v;
        }
    }
    int k = s->k_lo;
    for (int j = s->k_lo + 1; j <= s->k_hi; j++) {
        if (s->level[j] > s->level[k]) {
            k = j;
        }
    }
    if (s->level[k] > s->bf_peak_l) {
        s->bf_peak_l = s->level[k];
        s->bf_peak_hz = (float)k * s->bin_hz;
    }
    s->bf_flags |= kd_spec_health(s);
    s->bf_n++;
    if (s->bf_n >= s->band_frame_frames) {
        kd_band_frame_t bf;
        memset(&bf, 0, sizeof(bf));
        bf.t_ms = s->bf_start;
        bf.frame_ms = (float)(s->bf_n * (double)s->hop_ms);
        bf.flags = s->bf_flags;
        bf.n_bands = c->n_bands;
        /* excess[] is free scratch at this point of the frame. */
        int nn = 0;
        for (int j = s->k_lo; j <= s->k_hi; j++) {
            s->excess[nn++] = s->floor_db[j];
        }
        bf.noise_floor_dbfs = median_f(s->excess, nn);
        bf.peak_hz = s->bf_peak_hz;
        bf.peak_dbfs = s->bf_peak_l;
        bf.jam_mask = s->jam_band_mask;
        memcpy(bf.bands_db, s->bf_max, sizeof(float) * c->n_bands);
        if (s->sinks.on_band_frame) {
            s->sinks.on_band_frame(s->sinks.ctx, &bf);
        }
        s->bf_n = 0;
    }
}

/* -------------------------------------------------------------- frame */

static void floor_update(float *f, const float *x, int n, float eta, float q)
{
    for (int k = 0; k < n; k++) {
        if (x[k] < f[k]) {
            f[k] -= eta * (1.0f - q);
        } else {
            f[k] += eta * q;
        }
    }
}

static void frame(kd_spec_t *s)
{
    const kd_spec_cfg_t *c = &s->cfg;
    const uint16_t n = c->n_fft;
    const uint32_t i = s->frame;
    const double t_ms = i * (double)s->hop_ms;
    /* ring_pos is the oldest sample once the ring is full. */
    for (uint16_t j = 0; j < n; j++) {
        uint32_t idx = (s->ring_pos + j) % n;
        s->re[j] = s->ring[idx] * s->win[j];
        s->im[j] = 0.0f;
    }
    kd_fft(n, s->re, s->im, s->tw_cos, s->tw_sin, s->bitrev);
    float *p = s->excess; /* scratch: raw power */
    for (uint16_t k = 0; k < s->nb; k++) {
        p[k] = (s->re[k] * s->re[k] + s->im[k] * s->im[k]) * s->pscale;
    }
    float *row = s->hist[i % c->smooth_frames];
    row[0] = p[0];
    row[s->nb - 1] = p[s->nb - 1];
    for (uint16_t k = 1; k + 1 < s->nb; k++) {
        row[k] = 0.25f * p[k - 1] + 0.5f * p[k] + 0.25f * p[k + 1];
    }
    uint32_t cnt = (i + 1 < c->smooth_frames) ? i + 1 : c->smooth_frames;
    float *sm = s->excess; /* scratch: smoothed power (p no longer needed) */
    for (uint16_t k = 0; k < s->nb; k++) {
        float acc = 0.0f;
        for (uint32_t r = 0; r < cnt; r++) {
            acc += s->hist[r][k];
        }
        sm[k] = acc / (float)cnt;
        s->level[k] = 10.0f * log10f(sm[k] + EPSF);
    }
    for (uint8_t b = 0; b < c->n_bands; b++) {
        float acc = 0.0f;
        for (int k = s->band_lo[b]; k <= s->band_hi[b]; k++) {
            acc += sm[k];
        }
        s->blevel[b] = 10.0f * log10f(acc + EPSF);
    }
    bool warming = i < s->warmup_frames;
    if (!s->floor_init) {
        memcpy(s->floor_db, s->level, sizeof(float) * s->nb);
        memcpy(s->bfloor, s->blevel, sizeof(float) * c->n_bands);
        s->floor_init = true;
    }
    for (uint16_t k = 0; k < s->nb; k++) {
        s->excess[k] = s->level[k] - s->floor_db[k];
    }
    for (uint8_t b = 0; b < c->n_bands; b++) {
        s->bexc[b] = s->blevel[b] - s->bfloor[b];
    }

    int kp = s->k_lo;
    for (int k = s->k_lo + 1; k <= s->k_hi; k++) {
        if (s->excess[k] > s->excess[kp]) {
            kp = k;
        }
    }
    bool active = s->excess[kp] >= c->detect_thresh_db;
    jam_update(s, warming, active);
    bool evaluated = !(warming || s->jammed || (s->ext_flags & (KD_H_CLIPPED | KD_H_SURVEY)));

    if (c->events_enabled) {
        track(s, i, evaluated, kp, active);
        if (s->chirp_n > 0) {
            const kd_event_t *last = &s->chirp[s->chirp_n - 1];
            if (t_ms - (last->t_start_ms + last->duration_ms) > c->chirp_max_gap_ms) {
                flush_chirp(s);
            }
        }
    }
    if (s->sinks.on_column) {
        s->sinks.on_column(s->sinks.ctx, i, s->excess, s->k_lo, s->k_hi);
    }
    band_frame(s, t_ms);

    /* Warm-up: step size anneals linearly from warmup_speedup x to 1 x. */
    float warm_left = warming ? (float)(1.0 - (double)i / s->warmup_frames) : 0.0f;
    float eta = s->eta * (1.0f + (c->floor.warmup_speedup - 1.0f) * warm_left);
    floor_update(s->floor_db, s->level, s->nb, eta, c->floor.quantile);
    floor_update(s->bfloor, s->blevel, c->n_bands, eta, c->floor.quantile);
    s->frame++;
}

void kd_spec_push(kd_spec_t *s, const float *x, size_t n, uint8_t ext_flags)
{
    s->ext_flags = ext_flags;
    const uint16_t nf = s->cfg.n_fft;
    for (size_t j = 0; j < n; j++) {
        s->ring[s->ring_pos] = x[j];
        s->ring_pos = (s->ring_pos + 1) % nf;
        if (s->ring_fill < nf) {
            s->ring_fill++;
            if (s->ring_fill == nf) {
                frame(s);
            }
            continue;
        }
        if (++s->since_hop >= s->cfg.hop) {
            s->since_hop = 0;
            frame(s);
        }
    }
}

void kd_spec_finish(kd_spec_t *s)
{
    if (s->blob.open) {
        close_blob(s, false);
    }
    flush_chirp(s);
}
