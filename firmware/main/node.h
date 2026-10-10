/*
 * Kernel sensor node: module interfaces (firmware/main).
 *
 * Data path (guardrails section 10): capture -> [US_AIR: >= 20 kHz high-pass
 * on every sample, before any buffering] -> kernel_detect (one FFT frame at a
 * time) -> features (events, band frames, in-RAM snippet tiles) -> flash ring
 * / GATT. No module stores or transmits samples.
 */
#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "esp_err.h"
#include "kernel_detect.h"
#include "kernel_proto.h"

#define FW_MAJOR 0
#define FW_MINOR 1
#define FW_PATCH 0

/* ------------------------------------------------------------ profile */

typedef struct {
    uint8_t sensor_type;      /* KP_SENSOR_* */
    uint32_t fs;              /* detector sample rate */
    uint16_t capabilities;    /* KP_CAP_* */
    kd_spec_cfg_t spec;       /* spectral path (events or band frames only) */
    kd_imp_cfg_t imp;         /* impulse path (CONTACT) */
    kd_clip_cfg_t clip;
    kp_config_t defaults;     /* Config characteristic defaults */
} node_profile_t;

const node_profile_t *np_profile(void);
/* Applies the runtime-tunable Config fields to detector configs. */
void np_apply_config(const kp_config_t *c, kd_spec_cfg_t *spec, kd_imp_cfg_t *imp);
esp_err_t np_load_config(kp_config_t *out);  /* NVS or defaults */
esp_err_t np_save_config(const kp_config_t *c);

/* --------------------------------------------------------------- power */

void pw_init(void);
void pw_tick(void);              /* once a minute: battery */
uint8_t pw_batt_pct(void);       /* 0xFF when unknown */
uint16_t pw_batt_mv(void);
bool pw_low_battery(uint8_t low_pct);
/* Node clock in ms: epoch after SET_TIME (time_valid = true), else uptime. */
uint64_t pw_clock_ms(bool *time_valid);
void pw_set_time(uint64_t epoch_ms);
uint32_t pw_uptime_s(void);

/* ---------------------------------------------------------------- auth */

esp_err_t na_init(void);
bool na_has_key(void);
uint16_t na_boot_count(void);
esp_err_t na_hmac(const uint8_t *msg, size_t len, uint8_t out[32]);
esp_err_t na_node_nonce(uint8_t out[16]);
const uint8_t *na_addr6(void);   /* public BT address, printed order */

/* --------------------------------------------------------- event store */

esp_err_t es_init(void);
uint32_t es_reserve_seq(void);                 /* thread-safe, never reused */
esp_err_t es_write(const kp_event_t *e);       /* storage task only */
bool es_read(uint32_t seq, kp_event_t *out);
uint32_t es_last_seq(void);                    /* newest stored, 0 = none */
uint32_t es_oldest_seq(void);
uint16_t es_capacity(void);
bool es_overwrote_unsynced(void);
void es_mark_requested(uint32_t since_seq);

/* ------------------------------------------------------------- snippets */

void sn_init(uint16_t k_lo, uint16_t k_hi, float bin_hz, float hop_ms);
void sn_column(uint32_t frame, const float *excess_db, uint16_t k_lo, uint16_t k_hi);
void sn_capture(uint32_t seq, double t_start_ms, float duration_ms, float min_hz, float max_hz);
typedef struct {
    uint32_t seq;
    uint8_t rows, cols;
    uint16_t f_lo_hz10, f_hi_hz10, col_deci_ms;
    uint8_t cells[64 * 96]; /* column-major, rows per column */
} sn_snippet_t;
/* Copies the snippet for seq into out; false if no longer held. */
bool sn_get(uint32_t seq, sn_snippet_t *out);

/* ------------------------------------------------------------- pipeline */

esp_err_t pl_init(const kp_config_t *cfg);
void pl_request_config(const kp_config_t *cfg); /* applied at the next chunk boundary */
void pl_start_survey(uint16_t seconds);
uint16_t pl_survey_left_s(void);
bool pl_survey_needed(void);
uint16_t pl_health_bits(void);                  /* KP_HB_* owned by the pipeline */
void pl_set_sensor_fault(bool fault);
/* US_AIR: decimated PCM, not yet high-passed (the pipeline filters in place
 * first). Other nodes: raw PCM. Values in [-1, 1]. */
void pl_feed(float *pcm, size_t n);
bool pl_band_frame_pending(kp_band_frame_t *out); /* takes the latest frame */

/* -------------------------------------------------------------- capture */

esp_err_t cap_start(void);
void cap_pause(bool paused);  /* duty cycling */

/* ------------------------------------------------------------------ BLE */

esp_err_t bg_init(void);
void bg_on_new_event(void);      /* storage task: an event was stored */
void bg_on_band_frame(void);     /* a band frame is pending */
void bg_on_status_change(void);
bool bg_session_active(void);

/* Shared node state */
typedef struct {
    kp_config_t cfg;
    volatile bool session;        /* START_SESSION from a phone */
    volatile int64_t session_until_us; /* grace after disconnect */
} node_state_t;

extern node_state_t g_node;
