/* Per-node detector configuration. Mirrors kernel_ref/config.py and the
 * CONFIG_DEFAULTS in kernel_ref/export.py (vectors/protocol_v1.json). */
#include <string.h>

#include "esp_log.h"
#include "node.h"
#include "nvs.h"
#include "sdkconfig.h"

static const char *TAG = "profile";
static node_profile_t s_profile;
static bool s_ready;

static void common_defaults(kp_config_t *c)
{
    memset(c, 0, sizeof(*c));
    c->cfg_version = KP_CFG_VERSION;
    c->band_frame_ms = 1000;
    c->duty_on_s = 60;
    c->duty_off_s = 0;
    c->detect_thresh_half_db = 28;
    c->jam_thresh_half_db = 12;
    c->jam_hold_ds = 20;
    c->impulse_thresh_half_db = 30;
    c->min_blob_ms = 5;
    c->max_gap_ms = 4;
    c->flat_min_ms = 300;
    c->cont_min_ms = 1000;
    c->fm_min_bw_hz10 = 300;
    c->burst_min_impulses = 3;
    c->train_min_pulses = 3;
    c->burst_max_gap_ms = 200;
    c->impulse_min_half_ms = 2;
    c->impulse_max_ms = 10;
    c->train_max_cv_pct = 15;
    c->low_batt_pct = 15;
    c->chirp_max_gap_ms = 120;
}

__attribute__((unused)) static void linear_edges(kd_spec_cfg_t *s, float lo, float hi, float step)
{
    uint8_t n = (uint8_t)kd_lround((hi - lo) / step);
    s->n_bands = n;
    for (uint8_t i = 0; i <= n; i++) {
        s->band_edges_hz[i] = lo + i * step;
    }
}

__attribute__((unused)) static void table_edges(kd_spec_cfg_t *s, const float *edges, uint8_t n_edges)
{
    s->n_bands = (uint8_t)(n_edges - 1);
    memcpy(s->band_edges_hz, edges, sizeof(float) * n_edges);
}

static void build(void)
{
    node_profile_t *p = &s_profile;
    memset(p, 0, sizeof(*p));
    kd_spec_default_cfg(&p->spec);
    kd_imp_default_cfg(&p->imp);
    p->clip.level = 0.98f;
    p->clip.count = 3;
    p->clip.window_ms = 100.0f;
    p->clip.hold_ms = 2000.0f;
    common_defaults(&p->defaults);
    p->capabilities = KP_CAP_BAND_FRAMES | KP_CAP_SNIPPETS | KP_CAP_SURVEY | KP_CAP_RTC | KP_CAP_DUTY_CYCLE;
#if CONFIG_KERNEL_PIN_BATT_ADC >= 0
    p->capabilities |= KP_CAP_BATTERY_ADC;
#endif
#if CONFIG_KERNEL_KEY_EFUSE
    p->capabilities |= KP_CAP_KEY_IN_EFUSE;
#endif

#if CONFIG_KERNEL_NODE_US_AIR
    p->sensor_type = KP_SENSOR_US_AIR;
    p->fs = 192000;
    p->spec.fs = 192000;
    p->spec.n_fft = 512;
    p->spec.hop = 256;
    p->spec.lo_hz = 20000.0f;
    p->spec.hi_hz = 92000.0f;
    linear_edges(&p->spec, 20000.0f, 92000.0f, 4000.0f);
    p->defaults.flags = KP_CF_BAND_FRAMES | KP_CF_SNIPPETS | KP_CF_SPECTRAL_EVENTS; /* 0x25 */
#elif CONFIG_KERNEL_NODE_AUDIO_AIR
    static const float edges[] = {100, 160, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600,
                                  2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 15000};
    p->sensor_type = KP_SENSOR_AUDIO_AIR;
    p->fs = 32000;
    p->spec.fs = 32000;
    p->spec.n_fft = 512;
    p->spec.hop = 128;
    p->spec.lo_hz = 100.0f;
    p->spec.hi_hz = 15000.0f;
    p->spec.smooth_frames = 1;
    p->spec.max_jump_hz = 400.0f;
    table_edges(&p->spec, edges, sizeof(edges) / sizeof(edges[0]));
    p->defaults.flags = KP_CF_BAND_FRAMES | KP_CF_SNIPPETS | KP_CF_CHIRP_GROUPING | KP_CF_HARMONIC_SEARCH |
                        KP_CF_SPECTRAL_EVENTS; /* 0x3D */
    p->defaults.detect_thresh_half_db = 40;
    p->defaults.min_blob_ms = 8;
    p->defaults.max_gap_ms = 0;
    p->defaults.fm_min_bw_hz10 = 150;
#else /* CONTACT_PIEZO or CONTACT_ACCEL */
    static const float edges[] = {200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600,
                                  2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000};
#if CONFIG_KERNEL_NODE_CONTACT_ACCEL
    p->sensor_type = KP_SENSOR_CONTACT_ACCEL;
    p->fs = 26667;
#else
    p->sensor_type = KP_SENSOR_CONTACT_PIEZO;
    p->fs = 48000;
#endif
    p->spec.fs = p->fs;
    p->spec.n_fft = 512;
    p->spec.hop = 256;
    p->spec.lo_hz = 200.0f;
    p->spec.hi_hz = 10000.0f;
    p->spec.events_enabled = false; /* band frames + snippets only */
    table_edges(&p->spec, edges, sizeof(edges) / sizeof(edges[0]));
    p->imp.fs = p->fs;
    if (p->fs < 24000) {
        p->imp.bp_hi_hz = 0.4f * p->fs;
    }
    p->defaults.flags = KP_CF_BAND_FRAMES | KP_CF_SNIPPETS | KP_CF_IMPULSE_PATH; /* 0x45 */
#endif
    s_ready = true;
}

const node_profile_t *np_profile(void)
{
    if (!s_ready) {
        build();
    }
    return &s_profile;
}

void np_apply_config(const kp_config_t *c, kd_spec_cfg_t *s, kd_imp_cfg_t *m)
{
    s->detect_thresh_db = c->detect_thresh_half_db / 2.0f;
    s->jam_thresh_db = c->jam_thresh_half_db / 2.0f;
    s->jam_hold_ms = c->jam_hold_ds * 100.0f;
    s->min_blob_ms = c->min_blob_ms;
    s->max_gap_ms = c->max_gap_ms;
    s->flat_min_ms = c->flat_min_ms;
    s->cont_min_ms = c->cont_min_ms;
    s->fm_min_bw_hz = c->fm_min_bw_hz10 * 10.0f;
    s->train_min_pulses = c->train_min_pulses;
    s->chirp_max_gap_ms = c->chirp_max_gap_ms;
    s->band_frame_ms = c->band_frame_ms;
    s->chirp_grouping = (c->flags & KP_CF_CHIRP_GROUPING) != 0;
    s->harmonic_search = (c->flags & KP_CF_HARMONIC_SEARCH) != 0;
    s->events_enabled = (c->flags & KP_CF_SPECTRAL_EVENTS) != 0;
    m->thresh_db = c->impulse_thresh_half_db / 2.0f;
    m->jam_thresh_db = c->jam_thresh_half_db / 2.0f;
    m->jam_hold_ms = c->jam_hold_ds * 100.0f;
    m->min_ms = c->impulse_min_half_ms / 2.0f;
    m->max_ms = c->impulse_max_ms;
    m->burst_min_impulses = c->burst_min_impulses;
    m->burst_max_gap_ms = c->burst_max_gap_ms;
    m->train_min_pulses = c->train_min_pulses;
    m->train_max_cv = c->train_max_cv_pct / 100.0f;
}

esp_err_t np_load_config(kp_config_t *out)
{
    *out = np_profile()->defaults;
    nvs_handle_t h;
    if (nvs_open("kernel", NVS_READONLY, &h) != ESP_OK) {
        return ESP_OK;
    }
    uint8_t buf[KP_CONFIG_LEN];
    size_t len = sizeof(buf);
    esp_err_t err = nvs_get_blob(h, "config", buf, &len);
    nvs_close(h);
    if (err == ESP_OK && kp_unpack_config(out, buf, len) != 0) {
        ESP_LOGW(TAG, "stored config invalid, using defaults");
        *out = np_profile()->defaults;
    }
    return ESP_OK;
}

esp_err_t np_save_config(const kp_config_t *c)
{
    uint8_t buf[KP_CONFIG_LEN];
    kp_pack_config(buf, c);
    nvs_handle_t h;
    esp_err_t err = nvs_open("kernel", NVS_READWRITE, &h);
    if (err != ESP_OK) {
        return err;
    }
    err = nvs_set_blob(h, "config", buf, sizeof(buf));
    if (err == ESP_OK) {
        err = nvs_commit(h);
    }
    nvs_close(h);
    return err;
}
