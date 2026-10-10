/* Node pipeline: clip check on raw samples, US_AIR 20 kHz high-pass in place
 * (before anything is buffered), detectors, and the event/band-frame sinks.
 * Runs in the capture task; flash writes happen in the storage task. */
#include <string.h>

#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "node.h"
#include "nvs.h"
#include "sdkconfig.h"

static const char *TAG = "pipeline";

static kd_spec_t s_spec;
static kd_imp_t s_imp;
static kd_clip_t s_clip;
static kd_biquad_t s_us_hp;
static bool s_use_imp;
static bool s_snippets;
static uint32_t s_fs;
static uint64_t s_samples; /* detector time base: samples since detector init */
static portMUX_TYPE s_mux = portMUX_INITIALIZER_UNLOCKED;
static volatile bool s_cfg_pending;
static kp_config_t s_cfg_next;
static volatile int64_t s_survey_until_us;
static volatile uint16_t s_survey_total_s;
static bool s_survey_needed = true;
static volatile bool s_fault;
static QueueHandle_t s_event_q;
static kp_band_frame_t s_bf;
static volatile bool s_bf_pending;
static uint32_t s_bf_seq;
static uint16_t s_last_health;
static uint32_t s_dropped;

static uint64_t clock_at(double det_ms, bool *tv)
{
    uint64_t now = pw_clock_ms(tv);
    double det_now = (double)s_samples * 1000.0 / s_fs;
    double age = det_now - det_ms;
    if (age < 0) {
        age = 0;
    }
    uint64_t a = (uint64_t)age;
    return now > a ? now - a : 0;
}

static void on_event(void *ctx, const kd_event_t *ev)
{
    bool tv;
    uint64_t at = clock_at(ev->t_start_ms, &tv);
    kp_event_t w;
    kp_event_from_det(&w, ev, es_reserve_seq(), at, tv, (uint8_t)na_boot_count());
    if (s_snippets) {
        sn_capture(w.seq, ev->t_start_ms, ev->duration_ms, ev->min_hz, ev->max_hz);
        w.flags |= KP_EF_SNIPPET;
    }
    if (xQueueSend(s_event_q, &w, 0) != pdTRUE) {
        s_dropped++; /* storage task stalled; the seq stays unused */
    }
}

static void on_band(void *ctx, const kd_band_frame_t *bf)
{
    bool tv;
    uint64_t at = clock_at(bf->t_ms, &tv);
    kp_band_frame_t f;
    memset(&f, 0, sizeof(f));
    f.seq = ++s_bf_seq;
    f.t_start_s = (uint32_t)(at / 1000u);
    f.t_start_ms = (uint16_t)(at % 1000u);
    f.frame_ms = (uint16_t)kd_lround(bf->frame_ms);
    f.flags = (uint8_t)((tv ? KP_BF_TIME_VALID : 0) | ((bf->flags & KD_H_JAMMED) ? KP_BF_JAMMED : 0) |
                        ((bf->flags & KD_H_CLIPPED) ? KP_BF_CLIPPED : 0) | ((bf->flags & KD_H_SURVEY) ? KP_BF_SURVEY_ACTIVE : 0) |
                        ((bf->flags & KD_H_WARMING) ? KP_BF_WARMING_UP : 0));
    f.n_bands = bf->n_bands;
    f.noise_floor_ddbfs = kp_q_deci_db(bf->noise_floor_dbfs);
    f.peak_hz10 = kp_q_hz10(bf->peak_hz);
    f.peak_ddbfs = kp_q_deci_db(bf->peak_dbfs);
    f.jam_mask = bf->jam_mask & 0xFFFFFFu;
    for (uint8_t b = 0; b < bf->n_bands; b++) {
        f.bands_half_db[b] = kp_q_half_db(bf->bands_db[b]);
    }
    portENTER_CRITICAL(&s_mux);
    s_bf = f;
    s_bf_pending = true;
    portEXIT_CRITICAL(&s_mux);
    bg_on_band_frame();
}

static void on_column(void *ctx, uint32_t frame, const float *excess_db, uint16_t k_lo, uint16_t k_hi)
{
    if (s_snippets) {
        sn_column(frame, excess_db, k_lo, k_hi);
    }
}

static void storage_task(void *arg)
{
    kp_event_t w;
    for (;;) {
        if (xQueueReceive(s_event_q, &w, portMAX_DELAY) == pdTRUE) {
            if (es_write(&w) == ESP_OK) {
                bg_on_new_event();
            } else {
                ESP_LOGW(TAG, "event %u not stored", (unsigned)w.seq);
            }
        }
    }
}

static esp_err_t build(const kp_config_t *cfg)
{
    const node_profile_t *p = np_profile();
    kd_spec_cfg_t spec = p->spec;
    kd_imp_cfg_t imp = p->imp;
    np_apply_config(cfg, &spec, &imp);
    s_use_imp = (cfg->flags & KP_CF_IMPULSE_PATH) != 0 &&
                (p->sensor_type == KP_SENSOR_CONTACT_PIEZO || p->sensor_type == KP_SENSOR_CONTACT_ACCEL);
    s_snippets = (cfg->flags & KP_CF_SNIPPETS) != 0;
    kd_sinks_t sinks = {.on_event = on_event, .on_band_frame = on_band, .on_column = on_column, .ctx = NULL};
    if (!(cfg->flags & KP_CF_BAND_FRAMES)) {
        sinks.on_band_frame = NULL;
    }
    if (kd_spec_init(&s_spec, &spec, &sinks) != 0) {
        return ESP_ERR_INVALID_ARG;
    }
    if (s_use_imp) {
        kd_sinks_t isinks = {.on_event = on_event, .ctx = NULL};
        if (kd_imp_init(&s_imp, &imp, &isinks) != 0) {
            return ESP_ERR_INVALID_ARG;
        }
    }
    kd_clip_init(&s_clip, &p->clip, p->fs);
    memset(&s_us_hp, 0, sizeof(s_us_hp));
    if (p->sensor_type == KP_SENSOR_US_AIR) {
        /* Privacy filter: 6th-order Butterworth high-pass at 20 kHz. */
        kd_butter_highpass(&s_us_hp, (float)p->fs, 20000.0f, 6);
    }
    s_fs = p->fs;
    s_samples = 0;
    sn_init(s_spec.k_lo, s_spec.k_hi, s_spec.bin_hz, s_spec.hop_ms);
    return ESP_OK;
}

esp_err_t pl_init(const kp_config_t *cfg)
{
    nvs_handle_t h;
    if (nvs_open("kernel", NVS_READONLY, &h) == ESP_OK) {
        uint8_t ok = 0;
        nvs_get_u8(h, "survey_ok", &ok);
        s_survey_needed = ok == 0;
        nvs_close(h);
    }
    s_event_q = xQueueCreate(16, sizeof(kp_event_t));
    esp_err_t err = build(cfg);
    if (err != ESP_OK) {
        return err;
    }
    xTaskCreatePinnedToCore(storage_task, "kstore", 4096, NULL, 4, NULL, 0);
    return ESP_OK;
}

void pl_request_config(const kp_config_t *cfg)
{
    portENTER_CRITICAL(&s_mux);
    s_cfg_next = *cfg;
    s_cfg_pending = true;
    portEXIT_CRITICAL(&s_mux);
}

static void set_survey_ok(bool ok)
{
    s_survey_needed = !ok;
    nvs_handle_t h;
    if (nvs_open("kernel", NVS_READWRITE, &h) == ESP_OK) {
        nvs_set_u8(h, "survey_ok", ok ? 1 : 0);
        nvs_commit(h);
        nvs_close(h);
    }
}

void pl_start_survey(uint16_t seconds)
{
    s_survey_total_s = seconds;
    s_survey_until_us = esp_timer_get_time() + (int64_t)seconds * 1000000;
}

uint16_t pl_survey_left_s(void)
{
    int64_t until = s_survey_until_us;
    if (until == 0) {
        return 0;
    }
    int64_t left = (until - esp_timer_get_time()) / 1000000;
    return (uint16_t)(left > 0 ? left : 0);
}

bool pl_survey_needed(void) { return s_survey_needed; }

void pl_set_sensor_fault(bool fault) { s_fault = fault; }

uint16_t pl_health_bits(void)
{
    uint16_t h = 0;
    bool jammed = s_use_imp ? s_imp.jammed : s_spec.jammed;
    if (jammed) {
        h |= KP_HB_JAMMED;
    }
    if (kd_clip_active(&s_clip)) {
        h |= KP_HB_CLIPPED;
    }
    if (kd_spec_health(&s_spec) & KD_H_WARMING) {
        h |= KP_HB_WARMING_UP;
    }
    if (s_survey_until_us != 0) {
        h |= KP_HB_SURVEY_ACTIVE;
    }
    if (s_survey_needed) {
        h |= KP_HB_SURVEY_NEEDED;
    }
    if (s_fault) {
        h |= KP_HB_SENSOR_FAULT;
    }
    return h;
}

void pl_feed(float *pcm, size_t n)
{
    if (s_cfg_pending) {
        kp_config_t c;
        portENTER_CRITICAL(&s_mux);
        c = s_cfg_next;
        s_cfg_pending = false;
        portEXIT_CRITICAL(&s_mux);
        if (build(&c) != ESP_OK) {
            ESP_LOGE(TAG, "config rejected by detector init");
        }
        set_survey_ok(false); /* new thresholds: the site needs a new survey */
    }
    /* Clipping is judged on the raw samples (ADC / modulator saturation). */
    kd_clip_push(&s_clip, pcm, n);
    if (s_us_hp.n) {
        /* US_AIR: high-pass in place before the detector stores any sample. */
        kd_biquad_run(&s_us_hp, pcm, n);
    }
    uint8_t ext = (uint8_t)((kd_clip_active(&s_clip) ? KD_H_CLIPPED : 0) | (s_survey_until_us ? KD_H_SURVEY : 0));
    kd_spec_push(&s_spec, pcm, n, ext);
    if (s_use_imp) {
        kd_imp_push(&s_imp, pcm, n, ext);
    }
    s_samples += n;

    if (s_survey_until_us && esp_timer_get_time() >= s_survey_until_us) {
        s_survey_until_us = 0;
        set_survey_ok(true);
        ESP_LOGI(TAG, "survey of %u s complete%s", s_survey_total_s, (pl_health_bits() & KP_HB_JAMMED) ? " (jammed)" : "");
    }
    uint16_t h = pl_health_bits() & (KP_HB_JAMMED | KP_HB_CLIPPED | KP_HB_SURVEY_ACTIVE | KP_HB_SURVEY_NEEDED | KP_HB_SENSOR_FAULT);
    if (h != s_last_health) {
        s_last_health = h;
        bg_on_status_change();
    }
}

bool pl_band_frame_pending(kp_band_frame_t *out)
{
    bool got = false;
    portENTER_CRITICAL(&s_mux);
    if (s_bf_pending) {
        *out = s_bf;
        s_bf_pending = false;
        got = true;
    }
    portEXIT_CRITICAL(&s_mux);
    return got;
}
