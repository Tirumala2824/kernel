/* Per-device key and HMAC-SHA256 for the app-layer challenge-response
 * (docs/sensor-protocol.md section 7).
 *
 * CONFIG_KERNEL_KEY_EFUSE: the key is burned into an eFuse key block with
 * purpose HMAC_UP and used through the HMAC peripheral; software never reads it.
 * CONFIG_KERNEL_KEY_NVS: development fallback, key in the NVS blob "auth/key".
 *
 * Nonces come from HMAC(K, "KRNL-NONCE" | bootCount | counter | uptimeUs), a
 * keyed deterministic generator whose inputs never repeat. */
#include <string.h>

#include "esp_log.h"
#include "esp_mac.h"
#include "esp_timer.h"
#include "node.h"
#include "nvs.h"
#include "sdkconfig.h"

#if CONFIG_KERNEL_KEY_EFUSE
#include "esp_hmac.h"
#else
#include "mbedtls/md.h"
#endif

static const char *TAG = "auth";
static uint16_t s_boot_count;
static uint32_t s_nonce_counter;
static uint8_t s_addr6[6];
static bool s_has_key;
#if CONFIG_KERNEL_KEY_NVS
static uint8_t s_key[32];
#endif

esp_err_t na_init(void)
{
    nvs_handle_t h;
    esp_err_t err = nvs_open("kernel", NVS_READWRITE, &h);
    if (err != ESP_OK) {
        return err;
    }
    uint16_t boots = 0;
    nvs_get_u16(h, "boots", &boots);
    s_boot_count = (uint16_t)(boots + 1);
    nvs_set_u16(h, "boots", s_boot_count);
    nvs_commit(h);
    nvs_close(h);

    /* Public BT address, printed order (AA:BB:... -> AA first). */
    esp_read_mac(s_addr6, ESP_MAC_BT);

#if CONFIG_KERNEL_KEY_EFUSE
    /* Probe the key block with a fixed message; failure means not provisioned. */
    uint8_t probe[32];
    static const uint8_t msg[] = "KRNL-PROBE";
    s_has_key = esp_hmac_calculate((hmac_key_id_t)(HMAC_KEY0 + CONFIG_KERNEL_HMAC_KEY_ID), msg, sizeof(msg) - 1, probe) == ESP_OK;
#else
    if (nvs_open("auth", NVS_READONLY, &h) == ESP_OK) {
        size_t len = sizeof(s_key);
        s_has_key = nvs_get_blob(h, "key", s_key, &len) == ESP_OK && len == sizeof(s_key);
        nvs_close(h);
    }
#endif
    if (!s_has_key) {
        ESP_LOGW(TAG, "no per-device key provisioned: authentication will fail (see firmware/README.md)");
    }
    return ESP_OK;
}

bool na_has_key(void) { return s_has_key; }

uint16_t na_boot_count(void) { return s_boot_count; }

const uint8_t *na_addr6(void) { return s_addr6; }

esp_err_t na_hmac(const uint8_t *msg, size_t len, uint8_t out[32])
{
    if (!s_has_key) {
        return ESP_ERR_INVALID_STATE;
    }
#if CONFIG_KERNEL_KEY_EFUSE
    return esp_hmac_calculate((hmac_key_id_t)(HMAC_KEY0 + CONFIG_KERNEL_HMAC_KEY_ID), msg, len, out);
#else
    const mbedtls_md_info_t *md = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
    return mbedtls_md_hmac(md, s_key, sizeof(s_key), msg, len, out) == 0 ? ESP_OK : ESP_FAIL;
#endif
}

esp_err_t na_node_nonce(uint8_t out[16])
{
    uint8_t msg[KP_AUTH_MSG_MAX];
    size_t n = kp_node_nonce_msg(msg, s_boot_count, ++s_nonce_counter, (uint64_t)esp_timer_get_time());
    uint8_t mac[32];
    esp_err_t err = na_hmac(msg, n, mac);
    if (err == ESP_OK) {
        memcpy(out, mac, 16);
    }
    return err;
}
