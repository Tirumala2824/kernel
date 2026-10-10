/* Impulse path for CONTACT nodes: 200 Hz-10 kHz band-pass, 0.5 ms block
 * energy over a running 5 % quantile floor, impulse detection, burst
 * grouping and pulse-train regularity. Mirrors kernel_ref.detect.ImpulseDetector.
 *
 * Contact-vibration samples are consumed block by block and never stored. */
#include <float.h>
#include <math.h>
#include <string.h>

#include "kernel_detect.h"

#define EPSD 1e-20
#define SINE_DBFS_OFFSET 3.0102999566398120 /* 10*log10(2) */

static uint32_t u_ceil(double v) { return v <= 0.0 ? 0u : (uint32_t)ceil(v); }

void kd_imp_default_cfg(kd_imp_cfg_t *c)
{
    memset(c, 0, sizeof(*c));
    c->fs = 48000;
    c->block_ms = 0.5f;
    c->bp_lo_hz = 200.0f;
    c->bp_hi_hz = 10000.0f;
    c->thresh_db = 15.0f;
    c->min_ms = 1.0f;
    c->max_ms = 10.0f;
    c->burst_min_impulses = 3;
    c->burst_max_gap_ms = 200.0f;
    c->max_burst_impulses = KD_MAX_BURST;
    c->max_burst_ms = 10000.0f;
    c->train_min_pulses = 3;
    c->train_max_cv = 0.15f;
    c->jam_thresh_db = 6.0f;
    c->jam_hold_ms = 2000.0f;
    c->jam_miss_penalty = 10;
    c->jam_release_ms = 5000.0f;
    c->floor.quantile = 0.05f;
    c->floor.up_db_per_s = 0.5f;
    c->floor.warmup_ms = 1000.0f;
    c->floor.warmup_speedup = 20.0f;
}

int kd_imp_init(kd_imp_t *d, const kd_imp_cfg_t *cfg, const kd_sinks_t *sinks)
{
    if (cfg->fs == 0 || cfg->block_ms <= 0.0f || cfg->bp_hi_hz >= cfg->fs / 2.0f ||
        cfg->max_burst_impulses == 0 || cfg->max_burst_impulses > KD_MAX_BURST) {
        return -1;
    }
    memset(d, 0, sizeof(*d));
    d->cfg = *cfg;
    if (sinks) {
        d->sinks = *sinks;
    }
    long bn = kd_lround((double)cfg->block_ms * cfg->fs / 1000.0);
    d->block_n = (uint32_t)(bn < 1 ? 1 : bn);
    double block_ms = 1000.0 * d->block_n / cfg->fs;
    d->block_ms = (float)block_ms;
    double bps = (double)cfg->fs / d->block_n;
    if (kd_butter_highpass(&d->bp, (float)cfg->fs, cfg->bp_lo_hz, 2) != 0 ||
        kd_butter_lowpass(&d->bp, (float)cfg->fs, cfg->bp_hi_hz, 2) != 0) {
        return -1;
    }
    d->eta = (float)(cfg->floor.up_db_per_s / (cfg->floor.quantile * bps));
    d->warmup_blocks = u_ceil(cfg->floor.warmup_ms / block_ms);
    d->jam_hold_blocks = u_ceil(cfg->jam_hold_ms / block_ms);
    d->jam_release_blocks = u_ceil(cfg->jam_release_ms / block_ms);
    return 0;
}

uint8_t kd_imp_health(const kd_imp_t *d)
{
    uint8_t h = 0;
    if (d->jammed) {
        h |= KD_H_JAMMED;
    }
    h |= (uint8_t)(d->ext_flags & KD_H_CLIPPED);
    if (d->block < d->warmup_blocks) {
        h |= KD_H_WARMING;
    }
    return h;
}

static void close_burst(kd_imp_t *d, bool truncated)
{
    const kd_imp_cfg_t *c = &d->cfg;
    uint16_t n = d->burst_n;
    bool tainted = d->burst_tainted;
    d->burst_n = 0;
    d->burst_tainted = false;
    if (tainted || n < c->burst_min_impulses) {
        return;
    }
    kd_event_t ev;
    memset(&ev, 0, sizeof(ev));
    double fsum = 0.0;
    ev.min_hz = FLT_MAX;
    ev.max_hz = -FLT_MAX;
    ev.snr_db = -FLT_MAX;
    ev.peak_dbfs = -FLT_MAX;
    for (uint16_t i = 0; i < n; i++) {
        const kd_impulse_t *p = &d->burst[i];
        fsum += p->freq_hz;
        ev.min_hz = fminf(ev.min_hz, p->freq_hz);
        ev.max_hz = fmaxf(ev.max_hz, p->freq_hz);
        ev.snr_db = fmaxf(ev.snr_db, p->excess_db);
        ev.peak_dbfs = fmaxf(ev.peak_dbfs, p->peak_dbfs);
    }
    ev.t_start_ms = d->burst[0].t_start_ms;
    ev.duration_ms = (float)(d->burst[n - 1].t_end_ms - d->burst[0].t_start_ms);
    ev.cls = KD_IMPULSE_BURST;
    ev.peak_hz = (float)(fsum / n);
    ev.impulses = n;
    double span = (d->burst[n - 1].t_start_ms - d->burst[0].t_start_ms) / 1000.0;
    ev.rep_rate_hz = (n >= 2 && span > 0) ? (float)((n - 1) / span) : 0.0f;
    ev.ipi_cv = -1.0f;
    if (n >= 3) {
        double m = 0.0;
        for (uint16_t i = 1; i < n; i++) {
            m += (double)d->burst[i].t_start_ms - d->burst[i - 1].t_start_ms;
        }
        m /= (n - 1);
        if (m > 0) {
            double v = 0.0;
            for (uint16_t i = 1; i < n; i++) {
                double x = ((double)d->burst[i].t_start_ms - d->burst[i - 1].t_start_ms) - m;
                v += x * x;
            }
            v /= (n - 1);
            ev.ipi_cv = (float)(sqrt(v) / m);
        }
    }
    if (n >= c->train_min_pulses && ev.ipi_cv >= 0.0f && ev.ipi_cv <= c->train_max_cv) {
        ev.flags |= KD_EF_REGULAR_TRAIN;
    }
    if (truncated) {
        ev.flags |= KD_EF_TRUNCATED;
    }
    if (d->sinks.on_event) {
        d->sinks.on_event(d->sinks.ctx, &ev);
    }
}

static void end_impulse(kd_imp_t *d)
{
    const kd_imp_cfg_t *c = &d->cfg;
    float dur = d->imp_n * d->block_ms;
    if (d->imp_tainted) {
        return;
    }
    if (dur < c->min_ms - d->block_ms || dur > c->max_ms + d->block_ms) {
        return;
    }
    float f = (float)(d->imp_zc / (2.0 * dur / 1000.0));
    f = fmaxf(c->bp_lo_hz, fminf(c->bp_hi_hz, f));
    kd_impulse_t imp = {
        .t_start_ms = d->imp_start * (double)d->block_ms,
        .t_end_ms = (d->imp_start + d->imp_n) * (double)d->block_ms,
        .freq_hz = f,
        .peak_dbfs = d->imp_peak_l,
        .excess_db = d->imp_peak_e,
    };
    if (d->burst_n > 0) {
        const kd_impulse_t *last = &d->burst[d->burst_n - 1];
        double span = imp.t_end_ms - d->burst[0].t_start_ms;
        if (imp.t_start_ms - last->t_end_ms > c->burst_max_gap_ms) {
            close_burst(d, false);
        } else if (d->burst_n >= c->max_burst_impulses || span > c->max_burst_ms) {
            close_burst(d, true);
        }
    }
    d->burst[d->burst_n++] = imp;
}

static void block(kd_imp_t *d)
{
    const kd_imp_cfg_t *c = &d->cfg;
    const uint32_t i = d->block;
    const double t_ms = i * (double)d->block_ms;
    double e = d->acc / d->block_n;
    float level = (float)(10.0 * log10(e + EPSD) + SINE_DBFS_OFFSET);
    bool warming = i < d->warmup_blocks;
    float warm_left = warming ? (float)(1.0 - (double)i / d->warmup_blocks) : 0.0f;
    if (!d->floor_init) {
        d->floor_db = level;
        d->floor_init = true;
    }
    float exc = level - d->floor_db;

    if (exc >= c->jam_thresh_db) {
        d->run++;
    } else {
        d->run = d->run > c->jam_miss_penalty ? d->run - c->jam_miss_penalty : 0u;
    }
    bool cond = (d->run >= d->jam_hold_blocks) && !warming;
    if (cond) {
        d->jam_left = d->jam_release_blocks;
    } else if (d->jam_left > 0) {
        d->jam_left--;
    }
    d->jammed = cond || d->jam_left > 0;
    if (d->jammed) {
        d->jammed_ever = true;
    }
    bool evaluated = !(warming || d->jammed || (d->ext_flags & KD_H_CLIPPED));
    if (!evaluated && d->burst_n > 0) {
        d->burst_tainted = true;
    }

    if (exc >= c->thresh_db) {
        if (!d->in_imp) {
            d->in_imp = true;
            d->imp_start = i;
            d->imp_n = 0;
            d->imp_zc = 0;
            d->imp_peak_l = -INFINITY;
            d->imp_peak_e = 0.0f;
            d->imp_tainted = false;
        }
        d->imp_n++;
        d->imp_zc += d->acc_zc;
        d->imp_peak_l = fmaxf(d->imp_peak_l, level);
        d->imp_peak_e = fmaxf(d->imp_peak_e, exc);
        if (!evaluated) {
            d->imp_tainted = true;
        }
    } else if (d->in_imp) {
        d->in_imp = false;
        end_impulse(d);
    }

    if (d->burst_n > 0 && !d->in_imp && (t_ms - d->burst[d->burst_n - 1].t_end_ms) > c->burst_max_gap_ms) {
        close_burst(d, false);
    }

    float eta = d->eta * (1.0f + (c->floor.warmup_speedup - 1.0f) * warm_left);
    if (level < d->floor_db) {
        d->floor_db -= eta * (1.0f - c->floor.quantile);
    } else {
        d->floor_db += eta * c->floor.quantile;
    }
    d->block++;
}

void kd_imp_push(kd_imp_t *d, const float *x, size_t n, uint8_t ext_flags)
{
    d->ext_flags = ext_flags;
    float tmp[64];
    size_t done = 0;
    while (done < n) {
        size_t m = n - done;
        if (m > 64) {
            m = 64;
        }
        memcpy(tmp, x + done, m * sizeof(float));
        kd_biquad_run(&d->bp, tmp, m);
        for (size_t j = 0; j < m; j++) {
            float y = tmp[j];
            if ((signbit(y) != 0) != (signbit(d->prev_sample) != 0)) {
                d->acc_zc++;
            }
            d->prev_sample = y;
            d->acc += y * y;
            if (++d->acc_n == d->block_n) {
                block(d);
                d->acc = 0.0f;
                d->acc_n = 0;
                d->acc_zc = 0;
            }
        }
        done += m;
    }
}

void kd_imp_finish(kd_imp_t *d) { close_burst(d, false); }
