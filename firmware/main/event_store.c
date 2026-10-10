/* Store-and-forward ring of 32 B event records in the "kevents" partition
 * (docs/sensor-protocol.md section 6). Records are features only. */
#include <string.h>

#include "esp_log.h"
#include "esp_partition.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "node.h"
#include "nvs.h"

#define SECTOR 4096u
#define REC KP_RING_RECORD_LEN
#define PER_SECTOR (SECTOR / REC)

static const char *TAG = "events";
static const esp_partition_t *s_part;
static SemaphoreHandle_t s_lock;
static uint32_t s_slots;      /* total record slots */
static uint32_t s_write_slot; /* next slot to write */
static uint32_t s_last_seq;   /* newest stored */
static uint32_t s_oldest_seq;
static uint32_t s_next_seq;   /* next seq to hand out */
static uint32_t s_requested_since;
static bool s_overwrote;

static bool slot_read(uint32_t slot, kp_event_t *e)
{
    uint8_t rec[REC];
    if (esp_partition_read(s_part, slot * REC, rec, REC) != ESP_OK) {
        return false;
    }
    bool erased = true;
    for (int i = 0; i < REC; i++) {
        if (rec[i] != 0xFF) {
            erased = false;
            break;
        }
    }
    if (erased) {
        return false;
    }
    uint16_t crc = (uint16_t)(rec[KP_EVENT_LEN] | (rec[KP_EVENT_LEN + 1] << 8));
    if (crc != kp_crc16(rec, KP_EVENT_LEN)) {
        return false;
    }
    return kp_unpack_event(e, rec, KP_EVENT_LEN) && e->seq != 0;
}

static uint32_t nvs_high_water(void)
{
    nvs_handle_t h;
    uint32_t v = 0;
    if (nvs_open("kernel", NVS_READONLY, &h) == ESP_OK) {
        nvs_get_u32(h, "seq_hw", &v);
        nvs_close(h);
    }
    return v;
}

static void nvs_set_high_water(uint32_t v)
{
    nvs_handle_t h;
    if (nvs_open("kernel", NVS_READWRITE, &h) == ESP_OK) {
        nvs_set_u32(h, "seq_hw", v);
        nvs_commit(h);
        nvs_close(h);
    }
}

esp_err_t es_init(void)
{
    s_lock = xSemaphoreCreateMutex();
    s_part = esp_partition_find_first(ESP_PARTITION_TYPE_DATA, ESP_PARTITION_SUBTYPE_ANY, "kevents");
    if (!s_part || s_part->size < 2 * SECTOR) {
        ESP_LOGE(TAG, "kevents partition missing");
        return ESP_ERR_NOT_FOUND;
    }
    s_slots = (s_part->size / SECTOR) * PER_SECTOR;
    uint32_t max_seq = 0, min_seq = UINT32_MAX, max_slot = 0;
    kp_event_t e;
    for (uint32_t slot = 0; slot < s_slots; slot++) {
        if (!slot_read(slot, &e)) {
            continue;
        }
        if (e.seq > max_seq) {
            max_seq = e.seq;
            max_slot = slot;
        }
        if (e.seq < min_seq) {
            min_seq = e.seq;
        }
    }
    s_last_seq = max_seq;
    s_oldest_seq = max_seq ? min_seq : 0;
    s_write_slot = max_seq ? (max_slot + 1) % s_slots : 0;
    uint32_t hw = nvs_high_water();
    s_next_seq = (max_seq > hw ? max_seq : hw) + 1;
    ESP_LOGI(TAG, "ring %u slots, seq %u..%u, next %u", (unsigned)s_slots, (unsigned)s_oldest_seq,
             (unsigned)s_last_seq, (unsigned)s_next_seq);
    return ESP_OK;
}

uint32_t es_reserve_seq(void)
{
    xSemaphoreTake(s_lock, portMAX_DELAY);
    uint32_t seq = s_next_seq++;
    xSemaphoreGive(s_lock);
    return seq;
}

esp_err_t es_write(const kp_event_t *e)
{
    uint8_t rec[REC];
    kp_pack_event(rec, e);
    uint16_t crc = kp_crc16(rec, KP_EVENT_LEN);
    rec[KP_EVENT_LEN] = (uint8_t)crc;
    rec[KP_EVENT_LEN + 1] = (uint8_t)(crc >> 8);
    xSemaphoreTake(s_lock, portMAX_DELAY);
    esp_err_t err = ESP_OK;
    if (s_write_slot % PER_SECTOR == 0) {
        /* Entering a sector: erase it (it holds the oldest records). */
        uint32_t sector_first = s_write_slot;
        kp_event_t old;
        uint32_t newest_dropped = 0;
        for (uint32_t i = 0; i < PER_SECTOR; i++) {
            if (slot_read(sector_first + i, &old) && old.seq > newest_dropped) {
                newest_dropped = old.seq;
            }
        }
        err = esp_partition_erase_range(s_part, (s_write_slot / PER_SECTOR) * SECTOR, SECTOR);
        if (newest_dropped) {
            s_oldest_seq = newest_dropped + 1;
            if (newest_dropped > s_requested_since) {
                s_overwrote = true; /* never read by GET_EVENTS_SINCE */
            }
        }
        nvs_set_high_water(e->seq);
    }
    if (err == ESP_OK) {
        err = esp_partition_write(s_part, s_write_slot * REC, rec, REC);
    }
    if (err == ESP_OK) {
        s_write_slot = (s_write_slot + 1) % s_slots;
        s_last_seq = e->seq;
        if (s_oldest_seq == 0) {
            s_oldest_seq = e->seq;
        }
    }
    xSemaphoreGive(s_lock);
    return err;
}

bool es_read(uint32_t seq, kp_event_t *out)
{
    xSemaphoreTake(s_lock, portMAX_DELAY);
    bool ok = false;
    if (seq >= s_oldest_seq && seq <= s_last_seq && s_last_seq != 0) {
        /* Seqs are written consecutively; skipped seqs (write errors) fall back to a scan. */
        uint32_t back = s_last_seq - seq;
        uint32_t slot = (s_write_slot + s_slots - 1 - (back % s_slots)) % s_slots;
        ok = slot_read(slot, out) && out->seq == seq;
        if (!ok) {
            for (uint32_t i = 0; i < s_slots && !ok; i++) {
                ok = slot_read(i, out) && out->seq == seq;
            }
        }
    }
    xSemaphoreGive(s_lock);
    return ok;
}

uint32_t es_last_seq(void) { return s_last_seq; }
uint32_t es_oldest_seq(void) { return s_oldest_seq; }
uint16_t es_capacity(void) { return (uint16_t)(s_slots - PER_SECTOR); }
bool es_overwrote_unsynced(void) { return s_overwrote; }

void es_mark_requested(uint32_t since_seq)
{
    s_requested_since = since_seq;
    s_overwrote = false;
}
