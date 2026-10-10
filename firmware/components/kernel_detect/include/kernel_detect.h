/*
 * kernel_detect: portable C detectors for Kernel sensor nodes.
 *
 * No ESP-IDF dependency (C11 + libm only). Mirrored line by line by
 * firmware/reference/kernel_ref/detect.py, which owns the test vectors.
 *
 * Privacy (guardrails section 10): the detectors keep at most one analysis
 * frame (n_fft samples) or one energy block of input. They emit features only.
 * Nothing in this component stores or returns samples.
 */
#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define KD_MAX_FFT 512
#define KD_MAX_BINS (KD_MAX_FFT / 2 + 1)
#define KD_MAX_BANDS 24
#define KD_MAX_LINE_BLOCKS 16
#define KD_MAX_SMOOTH 4
#define KD_MAX_CHIRP 32
#define KD_MAX_BURST 255
#define KD_MAX_BIQUADS 4

/* Event classes (wire codes, docs/sensor-protocol.md 4.5). */
typedef enum {
    KD_TONAL = 0,
    KD_FM_SWEEP = 1,
    KD_FLAT_TONE = 2,
    KD_IMPULSE_BURST = 3,
    KD_HARMONIC = 4,
    KD_PULSED_CHIRP = 5,
    KD_CONTINUOUS_EMITTER = 6,
} kd_class_t;

/* Event flags (detector-owned bits; timeValid/snippet are set by the app). */
#define KD_EF_REGULAR_TRAIN 0x02u
#define KD_EF_TRUNCATED 0x04u

/* Health bits. */
#define KD_H_JAMMED 0x01u
#define KD_H_CLIPPED 0x02u
#define KD_H_WARMING 0x04u
#define KD_H_SURVEY 0x08u

typedef struct {
    double t_start_ms; /* detector time since init */
    float duration_ms;
    uint8_t cls;
    uint8_t flags;
    float peak_hz;
    float min_hz;
    float max_hz;
    float slope_hz_per_ms;
    float snr_db;
    float peak_dbfs;
    uint16_t impulses;
    uint16_t harmonics;
    float rep_rate_hz;
    float ipi_cv; /* < 0 when not applicable */
} kd_event_t;

typedef struct {
    double t_ms;
    float frame_ms;
    uint8_t flags; /* KD_H_* OR-ed over the interval */
    uint8_t n_bands;
    float noise_floor_dbfs;
    float peak_hz;
    float peak_dbfs;
    uint32_t jam_mask;
    float bands_db[KD_MAX_BANDS];
} kd_band_frame_t;

typedef void (*kd_event_cb_t)(void *ctx, const kd_event_t *ev);
typedef void (*kd_band_cb_t)(void *ctx, const kd_band_frame_t *bf);
/* One feature column per frame: excess over the floor in dB for bins
 * [k_lo, k_hi]. Used by the app for in-RAM snippet tiles only. */
typedef void (*kd_column_cb_t)(void *ctx, uint32_t frame, const float *excess_db, uint16_t k_lo, uint16_t k_hi);

typedef struct {
    kd_event_cb_t on_event;
    kd_band_cb_t on_band_frame;
    kd_column_cb_t on_column;
    void *ctx;
} kd_sinks_t;

/* ------------------------------------------------------------------ DSP */

typedef struct {
    float b0, b1, b2, a1, a2;
} kd_biquad_coef_t;

typedef struct {
    uint8_t n;
    kd_biquad_coef_t c[KD_MAX_BIQUADS];
    float z1[KD_MAX_BIQUADS];
    float z2[KD_MAX_BIQUADS];
} kd_biquad_t;

kd_biquad_coef_t kd_biquad_highpass(float fs, float fc, float q);
kd_biquad_coef_t kd_biquad_lowpass(float fs, float fc, float q);
/* Even-order Butterworth high-/low-pass appended to `bq` (order/2 sections). */
int kd_butter_highpass(kd_biquad_t *bq, float fs, float fc, int order);
int kd_butter_lowpass(kd_biquad_t *bq, float fs, float fc, int order);
void kd_biquad_reset(kd_biquad_t *bq);
/* In place, Direct Form II transposed. */
void kd_biquad_run(kd_biquad_t *bq, float *x, size_t n);

/* ---------------------------------------------------------------- floor */

typedef struct {
    float quantile;      /* 0.05 */
    float up_db_per_s;   /* 0.5 */
    float warmup_ms;     /* 1000 */
    float warmup_speedup;/* 20 */
} kd_floor_cfg_t;

/* ------------------------------------------------------------ clipping */

typedef struct {
    float level;     /* fraction of full scale, 0.98 */
    uint16_t count;  /* clipped samples per window, 3 */
    float window_ms; /* 100 */
    float hold_ms;   /* 2000 */
} kd_clip_cfg_t;

typedef struct {
    kd_clip_cfg_t cfg;
    uint64_t n_total;
    uint64_t win;
    uint64_t hold;
    int64_t cur_win;
    uint32_t win_count;
    int64_t hold_until;
    bool ever;
} kd_clip_t;

void kd_clip_init(kd_clip_t *c, const kd_clip_cfg_t *cfg, uint32_t fs);
void kd_clip_push(kd_clip_t *c, const float *x, size_t n);
bool kd_clip_active(const kd_clip_t *c);

/* ------------------------------------------------------- PDM decimator */

#define KD_PDM_CIC_ORDER 4
#define KD_PDM_CIC_R 8
#define KD_PDM_HB_TAPS 47

typedef struct {
    int32_t integ[KD_PDM_CIC_ORDER];
    int32_t comb[KD_PDM_CIC_ORDER];
    uint32_t phase;
    float hb_hist[KD_PDM_HB_TAPS];
    uint32_t hb_pos;
    uint32_t hb_phase;
} kd_pdm_t;

void kd_pdm_init(kd_pdm_t *p);
/* words: raw PDM bits, first bit in the MSB of each 32-bit word.
 * Writes at most out_cap PCM samples (fs_pdm / 16), returns the count. */
size_t kd_pdm_run(kd_pdm_t *p, const uint32_t *words, size_t n_words, float *out, size_t out_cap);
extern const float kd_halfband_taps[KD_PDM_HB_TAPS];

/* --------------------------------------------------------- spectral */

typedef struct {
    uint32_t fs;
    uint16_t n_fft;
    uint16_t hop;
    uint8_t n_bands;
    float band_edges_hz[KD_MAX_BANDS + 1];
    float lo_hz;
    float hi_hz;
    uint8_t smooth_frames;
    float detect_thresh_db;
    float min_blob_ms;
    float max_gap_ms;
    float max_jump_hz;
    float max_blob_ms;
    float flat_min_ms;
    float cont_min_ms;
    float fm_min_bw_hz;
    bool harmonic_search;
    float harmonic_rel_db;
    uint8_t max_harmonics;
    bool chirp_grouping;
    float chirp_max_gap_ms;
    float chirp_pulse_max_ms;
    float chirp_freq_tol;
    float chirp_max_cv;
    uint8_t train_min_pulses;
    float jam_thresh_db;
    float jam_hold_ms;
    uint8_t jam_miss_penalty; /* a frame below costs this many frames of run credit */
    float jam_release_ms;
    float jam_occupancy;
    float line_block_ms;
    uint8_t line_neigh_lo;
    uint8_t line_neigh_hi;
    float band_frame_ms;
    bool events_enabled;
    kd_floor_cfg_t floor;
} kd_spec_cfg_t;

typedef struct {
    bool open;
    uint32_t first, last;
    int last_k;
    uint32_t n;
    float fmin, fmax, peak_level, peak_hz, max_excess;
    double st, sf, stt, stf;
    uint32_t harm_frames, harm_sum;
    bool tainted;
} kd_blob_t;

typedef struct {
    kd_spec_cfg_t cfg;
    kd_sinks_t sinks;
    /* derived */
    uint16_t nb, k_lo, k_hi;
    uint16_t band_lo[KD_MAX_BANDS], band_hi[KD_MAX_BANDS];
    float bin_hz, hop_ms, pscale, eta;
    uint32_t warmup_frames, min_blob_frames, max_gap_frames, max_jump_bins, max_blob_frames;
    uint32_t jam_hold_frames, jam_release_frames;
    uint32_t line_block_frames, line_blocks, band_frame_frames;
    /* buffers (one frame of post-filter input at most) */
    float win[KD_MAX_FFT];
    float ring[KD_MAX_FFT];
    uint32_t ring_pos, ring_fill, since_hop;
    float re[KD_MAX_FFT], im[KD_MAX_FFT];
    float tw_cos[KD_MAX_FFT / 2], tw_sin[KD_MAX_FFT / 2];
    uint16_t bitrev[KD_MAX_FFT];
    float hist[KD_MAX_SMOOTH][KD_MAX_BINS];
    float level[KD_MAX_BINS];
    float floor_db[KD_MAX_BINS];
    float excess[KD_MAX_BINS];
    float blevel[KD_MAX_BANDS], bfloor[KD_MAX_BANDS], bexc[KD_MAX_BANDS];
    bool floor_init;
    uint32_t frame;
    /* jammer */
    uint32_t run[KD_MAX_BANDS];
    uint32_t occ_any, occ_n;
    bool occ_flag;
    float blk_min[KD_MAX_BINS];
    float blk_ring[KD_MAX_LINE_BLOCKS][KD_MAX_BINS];
    uint32_t blk_n, blk_count, blk_head;
    uint8_t line_bins[KD_MAX_BINS];
    uint32_t jam_left;
    bool jammed, jammed_ever;
    uint32_t jam_band_mask;
    uint8_t ext_flags;
    /* blobs + chirps */
    kd_blob_t blob;
    uint32_t gap;
    kd_event_t chirp[KD_MAX_CHIRP];
    uint8_t chirp_n;
    /* band frames */
    float bf_max[KD_MAX_BANDS];
    float bf_peak_l, bf_peak_hz;
    uint32_t bf_n;
    double bf_start;
    uint8_t bf_flags;
} kd_spec_t;

void kd_spec_default_cfg(kd_spec_cfg_t *cfg);
int kd_spec_init(kd_spec_t *s, const kd_spec_cfg_t *cfg, const kd_sinks_t *sinks);
/* x: post-filter samples in [-1, 1]. ext_flags: KD_H_CLIPPED | KD_H_SURVEY. */
void kd_spec_push(kd_spec_t *s, const float *x, size_t n, uint8_t ext_flags);
void kd_spec_finish(kd_spec_t *s);
uint8_t kd_spec_health(const kd_spec_t *s);

/* ---------------------------------------------------------- impulses */

typedef struct {
    uint32_t fs;
    float block_ms;
    float bp_lo_hz;
    float bp_hi_hz;
    float thresh_db;
    float min_ms;
    float max_ms;
    uint8_t burst_min_impulses;
    float burst_max_gap_ms;
    uint16_t max_burst_impulses;
    float max_burst_ms;
    uint8_t train_min_pulses;
    float train_max_cv;
    float jam_thresh_db;
    float jam_hold_ms;
    uint8_t jam_miss_penalty; /* a frame below costs this many frames of run credit */
    float jam_release_ms;
    kd_floor_cfg_t floor;
} kd_imp_cfg_t;

typedef struct {
    double t_start_ms, t_end_ms;
    float freq_hz, peak_dbfs, excess_db;
} kd_impulse_t;

typedef struct {
    kd_imp_cfg_t cfg;
    kd_sinks_t sinks;
    kd_biquad_t bp;
    uint32_t block_n;
    float block_ms, eta;
    uint32_t warmup_blocks, jam_hold_blocks, jam_release_blocks;
    float acc;
    uint32_t acc_n;
    uint32_t acc_zc;
    float prev_sample;
    uint32_t block;
    float floor_db;
    bool floor_init;
    uint32_t run, jam_left;
    bool jammed, jammed_ever;
    uint8_t ext_flags;
    bool in_imp, imp_tainted;
    uint32_t imp_start, imp_n, imp_zc;
    float imp_peak_l, imp_peak_e;
    kd_impulse_t burst[KD_MAX_BURST];
    uint16_t burst_n;
    bool burst_tainted;
} kd_imp_t;

void kd_imp_default_cfg(kd_imp_cfg_t *cfg);
int kd_imp_init(kd_imp_t *d, const kd_imp_cfg_t *cfg, const kd_sinks_t *sinks);
void kd_imp_push(kd_imp_t *d, const float *x, size_t n, uint8_t ext_flags);
void kd_imp_finish(kd_imp_t *d);
uint8_t kd_imp_health(const kd_imp_t *d);

/* ----------------------------------------------------------- FFT */

/* In-place radix-2 complex FFT; tables from kd_fft_tables. n is a power of 2. */
void kd_fft_tables(uint16_t n, float *tw_cos, float *tw_sin, uint16_t *bitrev);
void kd_fft(uint16_t n, float *re, float *im, const float *tw_cos, const float *tw_sin, const uint16_t *bitrev);

/* Rounding identical to the Python reference: half away from zero. */
static inline long kd_lround(double v) { return v >= 0 ? (long)(v + 0.5) : -(long)(-v + 0.5); }

#ifdef __cplusplus
}
#endif
