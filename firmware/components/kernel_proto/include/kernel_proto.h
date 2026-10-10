/*
 * kernel_proto: wire format of docs/sensor-protocol.md v1 (portable C11).
 * Mirrored by firmware/reference/kernel_ref/proto.py, SensorProtocol.kt and
 * protocol.dart; all four are checked against vectors/protocol_v1.json.
 *
 * Little-endian, packed. Functions write into caller buffers and return the
 * number of bytes written (0 on error).
 */
#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "kernel_detect.h"

#ifdef __cplusplus
extern "C" {
#endif

#define KP_PROTO_MAJOR 1
#define KP_PROTO_MINOR 0
#define KP_CFG_VERSION 1
#define KP_COMPANY_ID_TEST 0xFFFFu
#define KP_MAX_BANDS 24

/* 128-bit UUIDs, little-endian byte order as NimBLE's BLE_UUID128_INIT expects.
 * Service c7780001-4139-44b2-877d-c537908d6290; characteristics differ only
 * in the first 32-bit group (c778xxxx). */
#define KP_UUID128_BYTES(short16)                                                                     \
    0x90, 0x62, 0x8d, 0x90, 0x37, 0xc5, 0x7d, 0x87, 0xb2, 0x44, 0x39, 0x41, ((short16) & 0xFF),      \
        (((short16) >> 8) & 0xFF), 0x78, 0xc7
#define KP_UUID_SERVICE 0x0001
#define KP_UUID_DEVICE_INFO 0x0002
#define KP_UUID_CONFIG 0x0003
#define KP_UUID_BAND_TABLE 0x0004
#define KP_UUID_BAND_FRAME 0x0005
#define KP_UUID_EVENT 0x0006
#define KP_UUID_STATUS 0x0007
#define KP_UUID_CONTROL_POINT 0x0008
#define KP_UUID_SNIPPET 0x0009

/* Sensor types. */
#define KP_SENSOR_US_AIR 1
#define KP_SENSOR_CONTACT_PIEZO 2
#define KP_SENSOR_CONTACT_ACCEL 3
#define KP_SENSOR_AUDIO_AIR 4

/* Lengths. */
#define KP_ADV_MFG_LEN 7
#define KP_DEVICE_INFO_LEN 22
#define KP_CONFIG_LEN 32
#define KP_EVENT_LEN 30
#define KP_STATUS_LEN 21
#define KP_BAND_FRAME_HDR_LEN 23
#define KP_BAND_FRAME_MAX_LEN (KP_BAND_FRAME_HDR_LEN + KP_MAX_BANDS)
#define KP_BAND_TABLE_MAX_LEN (2 + 2 * (KP_MAX_BANDS + 1))
#define KP_SNIPPET_META_LEN 14
#define KP_SNIPPET_TILE_HDR_LEN 8
#define KP_RING_RECORD_LEN 32 /* event + CRC-16 */

/* Control point. */
#define KP_OP_SET_TIME 0x01
#define KP_OP_GET_EVENTS_SINCE 0x02
#define KP_OP_START_SURVEY 0x03
#define KP_OP_START_SESSION 0x04
#define KP_OP_STOP_SESSION 0x05
#define KP_OP_REQUEST_SNIPPET 0x06
#define KP_OP_CLEAR_BOND 0x07
#define KP_OP_AUTH_CHALLENGE 0x10
#define KP_OP_AUTH_RESPONSE 0x11
#define KP_OP_RESPONSE 0x80
#define KP_OP_EVENTS_DONE 0x81

#define KP_ST_OK 0x00
#define KP_ST_UNKNOWN_OPCODE 0x01
#define KP_ST_INVALID_PARAM 0x02
#define KP_ST_NOT_AUTHENTICATED 0x03
#define KP_ST_AUTH_FAILED 0x04
#define KP_ST_BUSY 0x05
#define KP_ST_NOT_AVAILABLE 0x06
#define KP_ST_STORAGE_ERROR 0x07

/* Status.health bits. */
#define KP_HB_JAMMED (1u << 0)
#define KP_HB_CLIPPED (1u << 1)
#define KP_HB_LOW_BATTERY (1u << 2)
#define KP_HB_SURVEY_NEEDED (1u << 3)
#define KP_HB_SURVEY_ACTIVE (1u << 4)
#define KP_HB_SESSION_ACTIVE (1u << 5)
#define KP_HB_TIME_VALID (1u << 6)
#define KP_HB_AUTHENTICATED (1u << 7)
#define KP_HB_WARMING_UP (1u << 8)
#define KP_HB_SENSOR_FAULT (1u << 9)
#define KP_HB_EVENTS_OVERWRITTEN (1u << 10)

/* Event flags (wire). */
#define KP_EF_TIME_VALID 0x01u
#define KP_EF_REGULAR_TRAIN 0x02u
#define KP_EF_TRUNCATED 0x04u
#define KP_EF_SNIPPET 0x08u

/* BandFrame flags. */
#define KP_BF_TIME_VALID 0x01u
#define KP_BF_JAMMED 0x02u
#define KP_BF_CLIPPED 0x04u
#define KP_BF_SURVEY_ACTIVE 0x08u
#define KP_BF_WARMING_UP 0x10u

/* Config flags. */
#define KP_CF_BAND_FRAMES 0x01u
#define KP_CF_DUTY_CYCLE 0x02u
#define KP_CF_SNIPPETS 0x04u
#define KP_CF_CHIRP_GROUPING 0x08u
#define KP_CF_HARMONIC_SEARCH 0x10u
#define KP_CF_SPECTRAL_EVENTS 0x20u
#define KP_CF_IMPULSE_PATH 0x40u

/* Capabilities. */
#define KP_CAP_BAND_FRAMES 0x0001u
#define KP_CAP_SNIPPETS 0x0002u
#define KP_CAP_SURVEY 0x0004u
#define KP_CAP_RTC 0x0008u
#define KP_CAP_BATTERY_ADC 0x0010u
#define KP_CAP_DUTY_CYCLE 0x0020u
#define KP_CAP_KEY_IN_EFUSE 0x0040u

typedef struct {
    uint32_t seq;
    uint32_t t_start_s;
    uint16_t t_start_ms;
    uint16_t duration_ms;
    uint8_t event_class;
    uint8_t flags;
    uint16_t peak_hz10;
    uint16_t min_hz10;
    uint16_t max_hz10;
    int16_t slope_dhz_per_ms;
    uint8_t snr_half_db;
    int8_t peak_dbfs;
    uint8_t impulses;
    uint8_t harmonics;
    uint16_t rep_rate_chz;
    uint8_t ipi_cv_pct;
    uint8_t boot_low;
} kp_event_t;

typedef struct {
    uint16_t health;
    uint8_t batt_pct;
    uint16_t batt_mv;
    uint32_t last_seq;
    uint32_t oldest_seq;
    uint32_t uptime_s;
    uint16_t boot_count;
    uint16_t survey_left_s;
} kp_status_t;

typedef struct {
    uint8_t sensor_type, hw_rev, fw_major, fw_minor, fw_patch, n_bands;
    uint16_t capabilities;
    uint32_t sample_rate_hz;
    uint16_t fft_size, hop_size, ring_capacity;
} kp_device_info_t;

typedef struct {
    uint8_t cfg_version;
    uint8_t flags;
    uint16_t band_frame_ms;
    uint16_t duty_on_s;
    uint16_t duty_off_s;
    uint8_t detect_thresh_half_db;
    uint8_t jam_thresh_half_db;
    uint8_t jam_hold_ds;
    uint8_t impulse_thresh_half_db;
    uint8_t min_blob_ms;
    uint8_t max_gap_ms;
    uint16_t flat_min_ms;
    uint16_t cont_min_ms;
    uint16_t fm_min_bw_hz10;
    uint8_t burst_min_impulses;
    uint8_t train_min_pulses;
    uint16_t burst_max_gap_ms;
    uint8_t impulse_min_half_ms;
    uint8_t impulse_max_ms;
    uint8_t train_max_cv_pct;
    uint8_t low_batt_pct;
    uint16_t chirp_max_gap_ms;
} kp_config_t;

typedef struct {
    uint32_t seq;
    uint32_t t_start_s;
    uint16_t t_start_ms;
    uint16_t frame_ms;
    uint8_t flags;
    uint8_t n_bands;
    int16_t noise_floor_ddbfs;
    uint16_t peak_hz10;
    int16_t peak_ddbfs;
    uint32_t jam_mask; /* 24 bits used */
    uint8_t bands_half_db[KP_MAX_BANDS];
} kp_band_frame_t;

typedef struct {
    uint8_t opcode;
    union {
        uint64_t epoch_ms;                              /* SET_TIME */
        struct { uint32_t seq; uint16_t max_count; } since; /* GET_EVENTS_SINCE */
        uint16_t duration_s;                            /* START_SURVEY */
        uint8_t session_flags;                          /* START_SESSION */
        uint32_t snippet_seq;                           /* REQUEST_SNIPPET */
        uint8_t nonce[16];                              /* AUTH_CHALLENGE */
        uint8_t proof[32];                              /* AUTH_RESPONSE */
    } p;
} kp_cp_req_t;

/* ---- fixed-point quantizers (half away from zero, saturating) ---- */
uint16_t kp_q_hz10(float hz);
int16_t kp_q_slope(float hz_per_ms);
uint8_t kp_q_half_db(float db);
int8_t kp_q_dbfs_i8(float db);
int16_t kp_q_deci_db(float db);
uint16_t kp_q_rate(float hz);
uint8_t kp_q_cv(float cv);

/* Detector event -> wire event. epoch_ms_or_uptime: node clock at the event
 * start; time_valid says which base it is. */
void kp_event_from_det(kp_event_t *w, const kd_event_t *ev, uint32_t seq, uint64_t clock_ms, bool time_valid,
                       uint8_t boot_low);

size_t kp_pack_adv_mfg(uint8_t out[KP_ADV_MFG_LEN], uint16_t company_id, uint8_t sensor_type, uint32_t last_seq,
                       uint8_t batt_pct);
size_t kp_pack_device_info(uint8_t out[KP_DEVICE_INFO_LEN], const kp_device_info_t *d);
size_t kp_pack_config(uint8_t out[KP_CONFIG_LEN], const kp_config_t *c);
/* Returns 0 on success, or an ATT error code (0x0D length, 0x80 range). */
int kp_unpack_config(kp_config_t *c, const uint8_t *in, size_t len);
size_t kp_pack_band_table(uint8_t *out, size_t cap, const uint16_t *edges_hz10, uint8_t n_bands);
size_t kp_pack_band_frame(uint8_t *out, size_t cap, const kp_band_frame_t *f);
size_t kp_pack_event(uint8_t out[KP_EVENT_LEN], const kp_event_t *e);
bool kp_unpack_event(kp_event_t *e, const uint8_t *in, size_t len);
size_t kp_pack_status(uint8_t out[KP_STATUS_LEN], const kp_status_t *s);

/* Control point. Returns KP_ST_OK or the status to answer with. */
uint8_t kp_parse_cp(kp_cp_req_t *r, const uint8_t *in, size_t len);
size_t kp_pack_cp_response(uint8_t *out, size_t cap, uint8_t req_op, uint8_t status, const uint8_t *payload,
                           size_t payload_len);
size_t kp_pack_events_since_payload(uint8_t out[14], uint16_t count, uint32_t first_seq, uint32_t last_seq,
                                    uint32_t oldest_seq);
size_t kp_pack_events_done(uint8_t out[7], uint16_t count, uint32_t last_seq);
size_t kp_pack_snippet_meta(uint8_t out[KP_SNIPPET_META_LEN], uint32_t seq, uint8_t rows, uint8_t cols,
                            uint16_t f_lo_hz10, uint16_t f_hi_hz10, uint16_t col_deci_ms, uint8_t tile_count,
                            uint8_t cols_per_tile);
size_t kp_pack_snippet_tile_hdr(uint8_t out[KP_SNIPPET_TILE_HDR_LEN], uint32_t seq, uint8_t index, uint8_t count,
                                uint8_t col0, uint8_t n_cols);

/* ---- auth (section 7). The HMAC itself is supplied by the app (eFuse HMAC
 * peripheral or mbedTLS), so this component stays crypto-free. ---- */
#define KP_LABEL_NODE "KRNL-AUTH-N1"
#define KP_LABEL_APP "KRNL-AUTH-A1"
#define KP_LABEL_NODE_NONCE "KRNL-NONCE"
#define KP_AUTH_MSG_MAX 64

size_t kp_auth_node_msg(uint8_t out[KP_AUTH_MSG_MAX], const uint8_t app_nonce[16], const uint8_t node_nonce[16],
                        const uint8_t addr6[6]);
size_t kp_auth_app_msg(uint8_t out[KP_AUTH_MSG_MAX], const uint8_t app_nonce[16], const uint8_t node_nonce[16],
                       const uint8_t addr6[6]);
size_t kp_node_nonce_msg(uint8_t out[KP_AUTH_MSG_MAX], uint32_t boot_count, uint32_t counter, uint64_t uptime_us);
bool kp_ct_equal(const uint8_t *a, const uint8_t *b, size_t n);

/* CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF) for flash ring records. */
uint16_t kp_crc16(const uint8_t *data, size_t len);

#ifdef __cplusplus
}
#endif
