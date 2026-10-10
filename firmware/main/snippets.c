/* In-RAM snippet tiles (docs/sensor-protocol.md 4.8).
 *
 * A rolling ring keeps the last 256 *feature* columns (dB above the noise
 * floor, 0.5 dB steps, 64 frequency rows). When an event is stored, the
 * columns around it are copied into one of 8 slots. Nothing here is audio,
 * nothing is written to flash, and everything is lost on reboot. */
#include <math.h>
#include <string.h>

#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "node.h"

#define ROWS 64
#define RING_COLS 256
#define MAX_COLS 96
#define SLOTS 8
#define MARGIN_COLS 12

static uint8_t s_ring[RING_COLS][ROWS];
static uint32_t s_ring_frame[RING_COLS];
static uint32_t s_newest = UINT32_MAX;
static sn_snippet_t s_slots[SLOTS];
static uint8_t s_next_slot;
static SemaphoreHandle_t s_lock;
static uint16_t s_k_lo, s_k_hi;
static float s_bin_hz, s_hop_ms;

void sn_init(uint16_t k_lo, uint16_t k_hi, float bin_hz, float hop_ms)
{
    if (!s_lock) {
        s_lock = xSemaphoreCreateMutex();
    }
    xSemaphoreTake(s_lock, portMAX_DELAY);
    s_k_lo = k_lo;
    s_k_hi = k_hi;
    s_bin_hz = bin_hz;
    s_hop_ms = hop_ms;
    s_newest = UINT32_MAX;
    memset(s_slots, 0, sizeof(s_slots));
    xSemaphoreGive(s_lock);
}

static inline uint16_t row_lo_bin(int r)
{
    return (uint16_t)(s_k_lo + (uint32_t)(s_k_hi - s_k_lo + 1) * r / ROWS);
}

void sn_column(uint32_t frame, const float *excess_db, uint16_t k_lo, uint16_t k_hi)
{
    uint32_t c = frame % RING_COLS;
    for (int r = 0; r < ROWS; r++) {
        uint16_t a = row_lo_bin(r), b = row_lo_bin(r + 1);
        if (b <= a) {
            b = (uint16_t)(a + 1);
        }
        float m = 0.0f;
        for (uint16_t k = a; k < b && k <= k_hi; k++) {
            if (excess_db[k] > m) {
                m = excess_db[k];
            }
        }
        long q = kd_lround(m * 2.0f);
        s_ring[c][r] = (uint8_t)(q > 255 ? 255 : (q < 0 ? 0 : q));
    }
    s_ring_frame[c] = frame;
    s_newest = frame;
}

void sn_capture(uint32_t seq, double t_start_ms, float duration_ms, float min_hz, float max_hz)
{
    if (s_newest == UINT32_MAX || s_hop_ms <= 0.0f) {
        return;
    }
    xSemaphoreTake(s_lock, portMAX_DELAY);
    int64_t f0 = (int64_t)floor(t_start_ms / s_hop_ms) - MARGIN_COLS;
    int64_t f1 = (int64_t)ceil((t_start_ms + duration_ms) / s_hop_ms) + MARGIN_COLS;
    int64_t oldest = (int64_t)s_newest - RING_COLS + 1;
    if (f0 < oldest) {
        f0 = oldest; /* long events keep their most recent part */
    }
    if (f0 < 0) {
        f0 = 0;
    }
    if (f1 > (int64_t)s_newest) {
        f1 = s_newest;
    }
    if (f1 < f0) {
        xSemaphoreGive(s_lock);
        return;
    }
    uint32_t span = (uint32_t)(f1 - f0 + 1);
    uint32_t dec = (span + MAX_COLS - 1) / MAX_COLS;
    uint32_t cols = (span + dec - 1) / dec;
    /* Rows cropped to the event's frequency range +/- 20 %. */
    float lo_hz = 0.8f * min_hz, hi_hz = 1.2f * max_hz;
    int r0 = 0, r1 = ROWS - 1;
    for (int r = 0; r < ROWS; r++) {
        float f_lo = row_lo_bin(r) * s_bin_hz;
        float f_hi = row_lo_bin(r + 1) * s_bin_hz;
        if (f_hi < lo_hz) {
            r0 = r + 1;
        }
        if (f_lo <= hi_hz) {
            r1 = r;
        }
    }
    if (r0 > r1) {
        r0 = 0;
        r1 = ROWS - 1;
    }
    sn_snippet_t *s = &s_slots[s_next_slot];
    s_next_slot = (uint8_t)((s_next_slot + 1) % SLOTS);
    memset(s, 0, sizeof(*s));
    s->seq = seq;
    s->rows = (uint8_t)(r1 - r0 + 1);
    s->cols = (uint8_t)cols;
    s->f_lo_hz10 = kp_q_hz10(row_lo_bin(r0) * s_bin_hz);
    s->f_hi_hz10 = kp_q_hz10(row_lo_bin(r1 + 1) * s_bin_hz);
    s->col_deci_ms = (uint16_t)kd_lround(s_hop_ms * dec * 10.0f);
    for (uint32_t c = 0; c < cols; c++) {
        for (int r = r0; r <= r1; r++) {
            uint8_t m = 0;
            for (uint32_t d = 0; d < dec; d++) {
                int64_t f = f0 + (int64_t)(c * dec + d);
                if (f > f1) {
                    break;
                }
                uint32_t rc = (uint32_t)(f % RING_COLS);
                if (s_ring_frame[rc] == (uint32_t)f && s_ring[rc][r] > m) {
                    m = s_ring[rc][r];
                }
            }
            s->cells[c * s->rows + (r - r0)] = m;
        }
    }
    xSemaphoreGive(s_lock);
}

bool sn_get(uint32_t seq, sn_snippet_t *out)
{
    bool ok = false;
    xSemaphoreTake(s_lock, portMAX_DELAY);
    for (int i = 0; i < SLOTS; i++) {
        if (s_slots[i].seq == seq && seq != 0) {
            *out = s_slots[i];
            ok = true;
            break;
        }
    }
    xSemaphoreGive(s_lock);
    return ok;
}
