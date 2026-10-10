/* Battery (ADC through a 1:2 divider) and the node clock. */
#include <sys/time.h>

#include "esp_adc/adc_cali.h"
#include "esp_adc/adc_cali_scheme.h"
#include "esp_adc/adc_oneshot.h"
#include "esp_attr.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "node.h"
#include "sdkconfig.h"

static const char *TAG = "power";
static adc_oneshot_unit_handle_t s_adc;
static adc_cali_handle_t s_cali;
static adc_channel_t s_chan;
static bool s_adc_ok;
static uint16_t s_mv;
static uint8_t s_pct = 0xFF;

/* Survives deep sleep / soft reset; cleared on power loss. */
RTC_DATA_ATTR static bool s_time_valid;

/* Single-cell Li-ion, resting voltage -> percent (coarse; bench-calibrate). */
static uint8_t lipo_pct(uint16_t mv)
{
    static const uint16_t mv_tab[] = {3300, 3500, 3600, 3700, 3750, 3800, 3850, 3900, 4000, 4100, 4200};
    static const uint8_t pct_tab[] = {0, 5, 10, 20, 30, 40, 50, 60, 75, 90, 100};
    if (mv <= mv_tab[0]) {
        return 0;
    }
    for (int i = 1; i < 11; i++) {
        if (mv <= mv_tab[i]) {
            return (uint8_t)(pct_tab[i - 1] + (pct_tab[i] - pct_tab[i - 1]) * (mv - mv_tab[i - 1]) / (mv_tab[i] - mv_tab[i - 1]));
        }
    }
    return 100;
}

void pw_init(void)
{
#if CONFIG_KERNEL_PIN_BATT_ADC >= 0
    adc_unit_t unit;
    if (adc_oneshot_io_to_channel(CONFIG_KERNEL_PIN_BATT_ADC, &unit, &s_chan) != ESP_OK) {
        ESP_LOGW(TAG, "battery pin is not an ADC pin");
        return;
    }
    adc_oneshot_unit_init_cfg_t ucfg = {.unit_id = unit};
    if (adc_oneshot_new_unit(&ucfg, &s_adc) != ESP_OK) {
        return;
    }
    adc_oneshot_chan_cfg_t ccfg = {.atten = ADC_ATTEN_DB_12, .bitwidth = ADC_BITWIDTH_DEFAULT};
    adc_oneshot_config_channel(s_adc, s_chan, &ccfg);
    adc_cali_curve_fitting_config_t cal = {.unit_id = unit, .chan = s_chan, .atten = ADC_ATTEN_DB_12, .bitwidth = ADC_BITWIDTH_DEFAULT};
    s_adc_ok = adc_cali_create_scheme_curve_fitting(&cal, &s_cali) == ESP_OK;
    pw_tick();
#endif
}

void pw_tick(void)
{
    if (!s_adc_ok) {
        return;
    }
    int raw = 0, mv = 0;
    int64_t acc = 0;
    for (int i = 0; i < 8; i++) {
        if (adc_oneshot_read(s_adc, s_chan, &raw) != ESP_OK || adc_cali_raw_to_voltage(s_cali, raw, &mv) != ESP_OK) {
            return;
        }
        acc += mv;
    }
    s_mv = (uint16_t)(2 * acc / 8); /* 1:2 divider */
    s_pct = lipo_pct(s_mv);
}

uint8_t pw_batt_pct(void) { return s_pct; }
uint16_t pw_batt_mv(void) { return s_mv; }
bool pw_low_battery(uint8_t low_pct) { return s_pct != 0xFF && s_pct <= low_pct; }

uint64_t pw_clock_ms(bool *time_valid)
{
    if (s_time_valid) {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        if (time_valid) {
            *time_valid = true;
        }
        return (uint64_t)tv.tv_sec * 1000u + (uint64_t)tv.tv_usec / 1000u;
    }
    if (time_valid) {
        *time_valid = false;
    }
    return (uint64_t)(esp_timer_get_time() / 1000);
}

void pw_set_time(uint64_t epoch_ms)
{
    struct timeval tv = {.tv_sec = (time_t)(epoch_ms / 1000u), .tv_usec = (suseconds_t)((epoch_ms % 1000u) * 1000u)};
    settimeofday(&tv, NULL);
    s_time_valid = true;
}

uint32_t pw_uptime_s(void) { return (uint32_t)(esp_timer_get_time() / 1000000); }
