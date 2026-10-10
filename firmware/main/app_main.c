/* Kernel sensor node entry point (docs/sensor-protocol.md, firmware/README.md).
 * One image per node type, chosen in menuconfig (Kernel sensor node). */
#include "esp_log.h"
#include "esp_pm.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "node.h"
#include "nvs_flash.h"
#include "sdkconfig.h"

static const char *TAG = "kernel";

node_state_t g_node;

static void init_nvs(void)
{
    esp_err_t err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES || err == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        /* Erasing NVS drops bonds, config, the seq high-water mark and (NVS key
         * mode) the key: the node must be re-provisioned and re-paired. */
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }
    ESP_ERROR_CHECK(err);
}

static void init_pm(void)
{
#if CONFIG_PM_ENABLE
    /* Light sleep happens only when capture is paused (the I2S/SPI drivers
     * hold PM locks while running). */
    esp_pm_config_t pm = {.max_freq_mhz = 240, .min_freq_mhz = 80, .light_sleep_enable = true};
    if (esp_pm_configure(&pm) != ESP_OK) {
        ESP_LOGW(TAG, "power management not configured");
    }
#endif
}

void app_main(void)
{
    init_nvs();
    ESP_ERROR_CHECK(na_init());
    pw_init();
    if (es_init() != ESP_OK) {
        ESP_LOGE(TAG, "event store unavailable; check partitions.csv");
    }
    np_load_config(&g_node.cfg);
    ESP_ERROR_CHECK(pl_init(&g_node.cfg));
    ESP_ERROR_CHECK(bg_init());
    if (cap_start() != ESP_OK) {
        ESP_LOGE(TAG, "capture front end failed; node reports sensorFault");
    }
    init_pm();
    ESP_LOGI(TAG, "node type %u, fw %d.%d.%d, boot %u", np_profile()->sensor_type, FW_MAJOR, FW_MINOR, FW_PATCH,
             na_boot_count());

    /* Duty cycling: listen dutyOnS, pause dutyOffS, unless a session or a
     * survey needs continuous listening. */
    int64_t phase_start = esp_timer_get_time();
    bool listening = true;
    uint32_t last_minute = 0;
    for (;;) {
        vTaskDelay(pdMS_TO_TICKS(1000));
        const kp_config_t *c = &g_node.cfg;
        bool duty = (c->flags & KP_CF_DUTY_CYCLE) && c->duty_off_s > 0 && !bg_session_active() &&
                    pl_survey_left_s() == 0;
        int64_t now = esp_timer_get_time();
        if (!duty) {
            if (!listening) {
                cap_pause(false);
                listening = true;
            }
            phase_start = now;
        } else {
            int64_t elapsed_s = (now - phase_start) / 1000000;
            if (listening && elapsed_s >= c->duty_on_s) {
                cap_pause(true);
                listening = false;
                phase_start = now;
            } else if (!listening && elapsed_s >= c->duty_off_s) {
                cap_pause(false);
                listening = true;
                phase_start = now;
            }
        }
        if (g_node.session_until_us && now >= g_node.session_until_us) {
            g_node.session_until_us = 0;
            bg_on_status_change();
        }
        uint32_t minute = pw_uptime_s() / 60;
        if (minute != last_minute) {
            last_minute = minute;
            pw_tick();
            bg_on_status_change();
        }
    }
}
