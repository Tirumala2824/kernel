/* Wire codec for docs/sensor-protocol.md v1. Mirrors kernel_ref/proto.py. */
#include "kernel_proto.h"

#include <math.h>
#include <string.h>

/* ------------------------------------------------------------ helpers */

static inline void put_u16(uint8_t *p, uint16_t v)
{
    p[0] = (uint8_t)v;
    p[1] = (uint8_t)(v >> 8);
}

static inline void put_u32(uint8_t *p, uint32_t v)
{
    for (int i = 0; i < 4; i++) {
        p[i] = (uint8_t)(v >> (8 * i));
    }
}

static inline void put_u64(uint8_t *p, uint64_t v)
{
    for (int i = 0; i < 8; i++) {
        p[i] = (uint8_t)(v >> (8 * i));
    }
}

static inline uint16_t get_u16(const uint8_t *p) { return (uint16_t)(p[0] | (p[1] << 8)); }

static inline uint32_t get_u32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static inline uint64_t get_u64(const uint8_t *p)
{
    uint64_t v = 0;
    for (int i = 7; i >= 0; i--) {
        v = (v << 8) | p[i];
    }
    return v;
}

static long clampl(long v, long lo, long hi) { return v < lo ? lo : (v > hi ? hi : v); }

/* --------------------------------------------------------- quantizers */

uint16_t kp_q_hz10(float hz) { return (uint16_t)clampl(kd_lround(hz / 10.0), 0, 0xFFFF); }
int16_t kp_q_slope(float v) { return (int16_t)clampl(kd_lround(v * 10.0), -32767, 32767); }
uint8_t kp_q_half_db(float db) { return (uint8_t)clampl(kd_lround(db * 2.0), 0, 255); }
int8_t kp_q_dbfs_i8(float db) { return (int8_t)clampl(kd_lround(db), -128, 127); }
int16_t kp_q_deci_db(float db) { return (int16_t)clampl(kd_lround(db * 10.0), -32768, 32767); }
uint16_t kp_q_rate(float hz) { return (uint16_t)clampl(kd_lround(hz * 100.0), 0, 0xFFFF); }
uint8_t kp_q_cv(float cv) { return cv < 0.0f ? 255 : (uint8_t)clampl(kd_lround(cv * 100.0), 0, 254); }

void kp_event_from_det(kp_event_t *w, const kd_event_t *ev, uint32_t seq, uint64_t clock_ms, bool time_valid,
                       uint8_t boot_low)
{
    memset(w, 0, sizeof(*w));
    w->seq = seq;
    w->t_start_s = (uint32_t)(clock_ms / 1000u);
    w->t_start_ms = (uint16_t)(clock_ms % 1000u);
    w->duration_ms = (uint16_t)clampl(kd_lround(ev->duration_ms), 0, 0xFFFF);
    w->event_class = ev->cls;
    w->flags = (uint8_t)((ev->flags & (KP_EF_REGULAR_TRAIN | KP_EF_TRUNCATED)) | (time_valid ? KP_EF_TIME_VALID : 0));
    w->peak_hz10 = kp_q_hz10(ev->peak_hz);
    w->min_hz10 = kp_q_hz10(ev->min_hz);
    w->max_hz10 = kp_q_hz10(ev->max_hz);
    w->slope_dhz_per_ms = kp_q_slope(ev->slope_hz_per_ms);
    w->snr_half_db = kp_q_half_db(ev->snr_db);
    w->peak_dbfs = kp_q_dbfs_i8(ev->peak_dbfs);
    w->impulses = (uint8_t)(ev->impulses > 255 ? 255 : ev->impulses);
    w->harmonics = (uint8_t)(ev->harmonics > 255 ? 255 : ev->harmonics);
    w->rep_rate_chz = kp_q_rate(ev->rep_rate_hz);
    w->ipi_cv_pct = kp_q_cv(ev->ipi_cv);
    w->boot_low = boot_low;
}

/* ------------------------------------------------------------ packers */

size_t kp_pack_adv_mfg(uint8_t out[KP_ADV_MFG_LEN], uint16_t company_id, uint8_t sensor_type, uint32_t last_seq,
                       uint8_t batt_pct)
{
    put_u16(out, company_id);
    out[2] = KP_PROTO_MAJOR;
    out[3] = sensor_type;
    put_u16(out + 4, (uint16_t)(last_seq & 0xFFFFu));
    out[6] = batt_pct;
    return KP_ADV_MFG_LEN;
}

size_t kp_pack_device_info(uint8_t out[KP_DEVICE_INFO_LEN], const kp_device_info_t *d)
{
    out[0] = KP_PROTO_MAJOR;
    out[1] = KP_PROTO_MINOR;
    out[2] = d->sensor_type;
    out[3] = d->hw_rev;
    out[4] = d->fw_major;
    out[5] = d->fw_minor;
    out[6] = d->fw_patch;
    out[7] = d->n_bands;
    put_u16(out + 8, d->capabilities);
    put_u32(out + 10, d->sample_rate_hz);
    put_u16(out + 14, d->fft_size);
    put_u16(out + 16, d->hop_size);
    put_u16(out + 18, d->ring_capacity);
    out[20] = KP_CFG_VERSION;
    out[21] = 0;
    return KP_DEVICE_INFO_LEN;
}

size_t kp_pack_config(uint8_t out[KP_CONFIG_LEN], const kp_config_t *c)
{
    out[0] = c->cfg_version;
    out[1] = c->flags;
    put_u16(out + 2, c->band_frame_ms);
    put_u16(out + 4, c->duty_on_s);
    put_u16(out + 6, c->duty_off_s);
    out[8] = c->detect_thresh_half_db;
    out[9] = c->jam_thresh_half_db;
    out[10] = c->jam_hold_ds;
    out[11] = c->impulse_thresh_half_db;
    out[12] = c->min_blob_ms;
    out[13] = c->max_gap_ms;
    put_u16(out + 14, c->flat_min_ms);
    put_u16(out + 16, c->cont_min_ms);
    put_u16(out + 18, c->fm_min_bw_hz10);
    out[20] = c->burst_min_impulses;
    out[21] = c->train_min_pulses;
    put_u16(out + 22, c->burst_max_gap_ms);
    out[24] = c->impulse_min_half_ms;
    out[25] = c->impulse_max_ms;
    out[26] = c->train_max_cv_pct;
    out[27] = c->low_batt_pct;
    put_u16(out + 28, c->chirp_max_gap_ms);
    put_u16(out + 30, 0);
    return KP_CONFIG_LEN;
}

#define IN_RANGE(v, lo, hi) ((v) >= (lo) && (v) <= (hi))

int kp_unpack_config(kp_config_t *c, const uint8_t *in, size_t len)
{
    if (len != KP_CONFIG_LEN) {
        return 0x0D; /* Invalid Attribute Value Length */
    }
    kp_config_t t;
    t.cfg_version = in[0];
    t.flags = in[1];
    t.band_frame_ms = get_u16(in + 2);
    t.duty_on_s = get_u16(in + 4);
    t.duty_off_s = get_u16(in + 6);
    t.detect_thresh_half_db = in[8];
    t.jam_thresh_half_db = in[9];
    t.jam_hold_ds = in[10];
    t.impulse_thresh_half_db = in[11];
    t.min_blob_ms = in[12];
    t.max_gap_ms = in[13];
    t.flat_min_ms = get_u16(in + 14);
    t.cont_min_ms = get_u16(in + 16);
    t.fm_min_bw_hz10 = get_u16(in + 18);
    t.burst_min_impulses = in[20];
    t.train_min_pulses = in[21];
    t.burst_max_gap_ms = get_u16(in + 22);
    t.impulse_min_half_ms = in[24];
    t.impulse_max_ms = in[25];
    t.train_max_cv_pct = in[26];
    t.low_batt_pct = in[27];
    t.chirp_max_gap_ms = get_u16(in + 28);
    bool ok = t.cfg_version == KP_CFG_VERSION && (t.flags & 0x80u) == 0 && IN_RANGE(t.band_frame_ms, 100, 10000) &&
              IN_RANGE(t.duty_on_s, 10, 3600) && t.duty_off_s <= 3600 && IN_RANGE(t.detect_thresh_half_db, 12, 80) &&
              IN_RANGE(t.jam_thresh_half_db, 6, 60) && IN_RANGE(t.jam_hold_ds, 5, 250) &&
              IN_RANGE(t.impulse_thresh_half_db, 12, 80) && IN_RANGE(t.min_blob_ms, 1, 100) && t.max_gap_ms <= 50 &&
              IN_RANGE(t.flat_min_ms, 50, 5000) && IN_RANGE(t.cont_min_ms, 200, 10000) &&
              IN_RANGE(t.fm_min_bw_hz10, 10, 5000) && IN_RANGE(t.burst_min_impulses, 2, 50) &&
              IN_RANGE(t.train_min_pulses, 3, 50) && IN_RANGE(t.burst_max_gap_ms, 10, 2000) &&
              IN_RANGE(t.impulse_min_half_ms, 1, 40) && IN_RANGE(t.impulse_max_ms, 1, 100) &&
              (uint32_t)t.impulse_min_half_ms <= 2u * t.impulse_max_ms && IN_RANGE(t.train_max_cv_pct, 1, 100) &&
              IN_RANGE(t.low_batt_pct, 5, 50) && IN_RANGE(t.chirp_max_gap_ms, 10, 1000) && get_u16(in + 30) == 0;
    if (!ok) {
        return 0x80; /* application error: value out of range */
    }
    *c = t;
    return 0;
}

size_t kp_pack_band_table(uint8_t *out, size_t cap, const uint16_t *edges_hz10, uint8_t n_bands)
{
    size_t need = 2u + 2u * (n_bands + 1u);
    if (n_bands < 1 || n_bands > KP_MAX_BANDS || cap < need) {
        return 0;
    }
    out[0] = n_bands;
    out[1] = 0;
    for (uint8_t i = 0; i <= n_bands; i++) {
        put_u16(out + 2 + 2 * i, edges_hz10[i]);
    }
    return need;
}

size_t kp_pack_band_frame(uint8_t *out, size_t cap, const kp_band_frame_t *f)
{
    size_t need = KP_BAND_FRAME_HDR_LEN + f->n_bands;
    if (f->n_bands < 1 || f->n_bands > KP_MAX_BANDS || cap < need) {
        return 0;
    }
    put_u32(out, f->seq);
    put_u32(out + 4, f->t_start_s);
    put_u16(out + 8, f->t_start_ms);
    put_u16(out + 10, f->frame_ms);
    out[12] = f->flags;
    out[13] = f->n_bands;
    put_u16(out + 14, (uint16_t)f->noise_floor_ddbfs);
    put_u16(out + 16, f->peak_hz10);
    put_u16(out + 18, (uint16_t)f->peak_ddbfs);
    out[20] = (uint8_t)f->jam_mask;
    out[21] = (uint8_t)(f->jam_mask >> 8);
    out[22] = (uint8_t)(f->jam_mask >> 16);
    memcpy(out + KP_BAND_FRAME_HDR_LEN, f->bands_half_db, f->n_bands);
    return need;
}

size_t kp_pack_event(uint8_t out[KP_EVENT_LEN], const kp_event_t *e)
{
    put_u32(out, e->seq);
    put_u32(out + 4, e->t_start_s);
    put_u16(out + 8, e->t_start_ms);
    put_u16(out + 10, e->duration_ms);
    out[12] = e->event_class;
    out[13] = e->flags;
    put_u16(out + 14, e->peak_hz10);
    put_u16(out + 16, e->min_hz10);
    put_u16(out + 18, e->max_hz10);
    put_u16(out + 20, (uint16_t)e->slope_dhz_per_ms);
    out[22] = e->snr_half_db;
    out[23] = (uint8_t)e->peak_dbfs;
    out[24] = e->impulses;
    out[25] = e->harmonics;
    put_u16(out + 26, e->rep_rate_chz);
    out[28] = e->ipi_cv_pct;
    out[29] = e->boot_low;
    return KP_EVENT_LEN;
}

bool kp_unpack_event(kp_event_t *e, const uint8_t *in, size_t len)
{
    if (len < KP_EVENT_LEN) {
        return false;
    }
    e->seq = get_u32(in);
    e->t_start_s = get_u32(in + 4);
    e->t_start_ms = get_u16(in + 8);
    e->duration_ms = get_u16(in + 10);
    e->event_class = in[12];
    e->flags = in[13];
    e->peak_hz10 = get_u16(in + 14);
    e->min_hz10 = get_u16(in + 16);
    e->max_hz10 = get_u16(in + 18);
    e->slope_dhz_per_ms = (int16_t)get_u16(in + 20);
    e->snr_half_db = in[22];
    e->peak_dbfs = (int8_t)in[23];
    e->impulses = in[24];
    e->harmonics = in[25];
    e->rep_rate_chz = get_u16(in + 26);
    e->ipi_cv_pct = in[28];
    e->boot_low = in[29];
    return true;
}

size_t kp_pack_status(uint8_t out[KP_STATUS_LEN], const kp_status_t *s)
{
    put_u16(out, s->health);
    out[2] = s->batt_pct;
    put_u16(out + 3, s->batt_mv);
    put_u32(out + 5, s->last_seq);
    put_u32(out + 9, s->oldest_seq);
    put_u32(out + 13, s->uptime_s);
    put_u16(out + 17, s->boot_count);
    put_u16(out + 19, s->survey_left_s);
    return KP_STATUS_LEN;
}

/* ------------------------------------------------------ control point */

uint8_t kp_parse_cp(kp_cp_req_t *r, const uint8_t *in, size_t len)
{
    memset(r, 0, sizeof(*r));
    if (len < 1) {
        return KP_ST_INVALID_PARAM;
    }
    r->opcode = in[0];
    switch (in[0]) {
    case KP_OP_SET_TIME:
        if (len < 9) {
            return KP_ST_INVALID_PARAM;
        }
        r->p.epoch_ms = get_u64(in + 1);
        return KP_ST_OK;
    case KP_OP_GET_EVENTS_SINCE:
        if (len < 7) {
            return KP_ST_INVALID_PARAM;
        }
        r->p.since.seq = get_u32(in + 1);
        r->p.since.max_count = get_u16(in + 5);
        return KP_ST_OK;
    case KP_OP_START_SURVEY:
        if (len < 3) {
            return KP_ST_INVALID_PARAM;
        }
        r->p.duration_s = get_u16(in + 1);
        return IN_RANGE(r->p.duration_s, 30, 3600) ? KP_ST_OK : KP_ST_INVALID_PARAM;
    case KP_OP_START_SESSION:
        r->p.session_flags = len >= 2 ? in[1] : 0;
        return KP_ST_OK;
    case KP_OP_STOP_SESSION:
    case KP_OP_CLEAR_BOND:
        return KP_ST_OK;
    case KP_OP_REQUEST_SNIPPET:
        if (len < 5) {
            return KP_ST_INVALID_PARAM;
        }
        r->p.snippet_seq = get_u32(in + 1);
        return KP_ST_OK;
    case KP_OP_AUTH_CHALLENGE:
        if (len < 17) {
            return KP_ST_INVALID_PARAM;
        }
        memcpy(r->p.nonce, in + 1, 16);
        return KP_ST_OK;
    case KP_OP_AUTH_RESPONSE:
        if (len < 33) {
            return KP_ST_INVALID_PARAM;
        }
        memcpy(r->p.proof, in + 1, 32);
        return KP_ST_OK;
    default:
        return KP_ST_UNKNOWN_OPCODE;
    }
}

size_t kp_pack_cp_response(uint8_t *out, size_t cap, uint8_t req_op, uint8_t status, const uint8_t *payload,
                           size_t payload_len)
{
    if (cap < 3 + payload_len) {
        return 0;
    }
    out[0] = KP_OP_RESPONSE;
    out[1] = req_op;
    out[2] = status;
    if (payload_len) {
        memcpy(out + 3, payload, payload_len);
    }
    return 3 + payload_len;
}

size_t kp_pack_events_since_payload(uint8_t out[14], uint16_t count, uint32_t first_seq, uint32_t last_seq,
                                    uint32_t oldest_seq)
{
    put_u16(out, count);
    put_u32(out + 2, first_seq);
    put_u32(out + 6, last_seq);
    put_u32(out + 10, oldest_seq);
    return 14;
}

size_t kp_pack_events_done(uint8_t out[7], uint16_t count, uint32_t last_seq)
{
    out[0] = KP_OP_EVENTS_DONE;
    put_u16(out + 1, count);
    put_u32(out + 3, last_seq);
    return 7;
}

size_t kp_pack_snippet_meta(uint8_t out[KP_SNIPPET_META_LEN], uint32_t seq, uint8_t rows, uint8_t cols,
                            uint16_t f_lo_hz10, uint16_t f_hi_hz10, uint16_t col_deci_ms, uint8_t tile_count,
                            uint8_t cols_per_tile)
{
    put_u32(out, seq);
    out[4] = rows;
    out[5] = cols;
    put_u16(out + 6, f_lo_hz10);
    put_u16(out + 8, f_hi_hz10);
    put_u16(out + 10, col_deci_ms);
    out[12] = tile_count;
    out[13] = cols_per_tile;
    return KP_SNIPPET_META_LEN;
}

size_t kp_pack_snippet_tile_hdr(uint8_t out[KP_SNIPPET_TILE_HDR_LEN], uint32_t seq, uint8_t index, uint8_t count,
                                uint8_t col0, uint8_t n_cols)
{
    put_u32(out, seq);
    out[4] = index;
    out[5] = count;
    out[6] = col0;
    out[7] = n_cols;
    return KP_SNIPPET_TILE_HDR_LEN;
}

/* --------------------------------------------------------------- auth */

static size_t auth_msg(uint8_t *out, const char *label, const uint8_t a[16], const uint8_t b[16], const uint8_t addr6[6])
{
    size_t n = strlen(label);
    memcpy(out, label, n);
    memcpy(out + n, a, 16);
    memcpy(out + n + 16, b, 16);
    memcpy(out + n + 32, addr6, 6);
    return n + 38;
}

size_t kp_auth_node_msg(uint8_t out[KP_AUTH_MSG_MAX], const uint8_t app_nonce[16], const uint8_t node_nonce[16],
                        const uint8_t addr6[6])
{
    return auth_msg(out, KP_LABEL_NODE, app_nonce, node_nonce, addr6);
}

size_t kp_auth_app_msg(uint8_t out[KP_AUTH_MSG_MAX], const uint8_t app_nonce[16], const uint8_t node_nonce[16],
                       const uint8_t addr6[6])
{
    return auth_msg(out, KP_LABEL_APP, node_nonce, app_nonce, addr6);
}

size_t kp_node_nonce_msg(uint8_t out[KP_AUTH_MSG_MAX], uint32_t boot_count, uint32_t counter, uint64_t uptime_us)
{
    size_t n = strlen(KP_LABEL_NODE_NONCE);
    memcpy(out, KP_LABEL_NODE_NONCE, n);
    put_u32(out + n, boot_count);
    put_u32(out + n + 4, counter);
    put_u64(out + n + 8, uptime_us);
    return n + 16;
}

bool kp_ct_equal(const uint8_t *a, const uint8_t *b, size_t n)
{
    uint8_t d = 0;
    for (size_t i = 0; i < n; i++) {
        d |= (uint8_t)(a[i] ^ b[i]);
    }
    return d == 0;
}

uint16_t kp_crc16(const uint8_t *data, size_t len)
{
    uint16_t crc = 0xFFFF;
    for (size_t i = 0; i < len; i++) {
        crc ^= (uint16_t)(data[i] << 8);
        for (int b = 0; b < 8; b++) {
            crc = (crc & 0x8000u) ? (uint16_t)((crc << 1) ^ 0x1021u) : (uint16_t)(crc << 1);
        }
    }
    return crc;
}
