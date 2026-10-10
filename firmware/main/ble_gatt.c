/* NimBLE GATT server for docs/sensor-protocol.md v1.
 *
 * Security: every characteristic (DIS, BAS and the Kernel service) needs an
 * encrypted link (LE Secure Connections, Just Works, bonded). Config,
 * BandTable, BandFrame, Event, Snippet and every ControlPoint opcode except
 * AUTH need the app-layer HMAC handshake on this connection. Only features
 * are ever sent; there is no audio characteristic. */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "freertos/task.h"
#include "host/ble_hs.h"
#include "host/util/util.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "node.h"
#include "sdkconfig.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"

void ble_store_config_init(void);

static const char *TAG = "gatt";

#define MAX_CONN CONFIG_BT_NIMBLE_MAX_CONNECTIONS
#define CP_QUEUE 3
#define CP_MAX 64
#define AUTH_MAX_FAILURES 3
#define AUTH_LOCKOUT_US (10 * 1000000LL)
#define SESSION_GRACE_US (60 * 1000000LL)

enum {
    CHR_DEVICE_INFO = 1,
    CHR_CONFIG,
    CHR_BAND_TABLE,
    CHR_BAND_FRAME,
    CHR_EVENT,
    CHR_STATUS,
    CHR_CONTROL,
    CHR_SNIPPET,
    CHR_DIS_MANUFACTURER,
    CHR_DIS_MODEL,
    CHR_DIS_HW,
    CHR_DIS_FW,
    CHR_BATTERY,
};

typedef struct {
    bool used;
    uint16_t handle;
    ble_addr_t peer;
    bool encrypted;
    bool authed;
    uint8_t failures;
    int64_t lockout_until_us;
    bool challenge_open;
    uint8_t app_nonce[16];
    uint8_t node_nonce[16];
    bool sub_event, sub_status, sub_cp, sub_band, sub_snippet, sub_batt;
    bool ind_busy;
    uint8_t cpq[CP_QUEUE][CP_MAX];
    uint8_t cpq_len[CP_QUEUE];
    uint8_t cpq_n;
    uint32_t next_seq;   /* next event to deliver (0 = none yet) */
    bool xfer;           /* GET_EVENTS_SINCE in progress */
    uint32_t xfer_end;
    uint16_t xfer_count;
    bool clear_bond;
    bool snip_pending;
    uint8_t snip_next_tile;
    uint8_t snip_tiles;
    uint8_t snip_cols_per_tile;
    sn_snippet_t snip;
} conn_t;

static conn_t s_conn[MAX_CONN];
static SemaphoreHandle_t s_mx;
static TaskHandle_t s_worker;
static uint8_t s_own_addr_type;
static int64_t s_fast_adv_until_us;
static uint16_t h_band_frame, h_event, h_status, h_cp, h_snippet, h_batt;
static char s_name[16];

#define W_EVENT (1u << 0)
#define W_BAND (1u << 1)
#define W_STATUS (1u << 2)
#define W_ADV (1u << 3)

static const ble_uuid128_t uuid_svc = BLE_UUID128_INIT(KP_UUID128_BYTES(KP_UUID_SERVICE));
static const ble_uuid128_t uuid_info = BLE_UUID128_INIT(KP_UUID128_BYTES(KP_UUID_DEVICE_INFO));
static const ble_uuid128_t uuid_config = BLE_UUID128_INIT(KP_UUID128_BYTES(KP_UUID_CONFIG));
static const ble_uuid128_t uuid_table = BLE_UUID128_INIT(KP_UUID128_BYTES(KP_UUID_BAND_TABLE));
static const ble_uuid128_t uuid_frame = BLE_UUID128_INIT(KP_UUID128_BYTES(KP_UUID_BAND_FRAME));
static const ble_uuid128_t uuid_event = BLE_UUID128_INIT(KP_UUID128_BYTES(KP_UUID_EVENT));
static const ble_uuid128_t uuid_status = BLE_UUID128_INIT(KP_UUID128_BYTES(KP_UUID_STATUS));
static const ble_uuid128_t uuid_cp = BLE_UUID128_INIT(KP_UUID128_BYTES(KP_UUID_CONTROL_POINT));
static const ble_uuid128_t uuid_snippet = BLE_UUID128_INIT(KP_UUID128_BYTES(KP_UUID_SNIPPET));

static void lock(void) { xSemaphoreTakeRecursive(s_mx, portMAX_DELAY); }
static void unlock(void) { xSemaphoreGiveRecursive(s_mx); }
static void kick(uint32_t bits)
{
    if (s_worker) {
        xTaskNotify(s_worker, bits, eSetBits);
    }
}

static conn_t *find(uint16_t handle)
{
    for (int i = 0; i < MAX_CONN; i++) {
        if (s_conn[i].used && s_conn[i].handle == handle) {
            return &s_conn[i];
        }
    }
    return NULL;
}

static uint16_t payload_cap(uint16_t handle) { return (uint16_t)(ble_att_mtu(handle) - 3); }

bool bg_session_active(void)
{
    if (g_node.session) {
        return true;
    }
    return g_node.session_until_us != 0 && esp_timer_get_time() < g_node.session_until_us;
}

/* -------------------------------------------------------- packing helpers */

static uint16_t health_for(const conn_t *c)
{
    uint16_t h = pl_health_bits();
    bool tv;
    pw_clock_ms(&tv);
    if (pw_low_battery(g_node.cfg.low_batt_pct)) {
        h |= KP_HB_LOW_BATTERY;
    }
    if (bg_session_active()) {
        h |= KP_HB_SESSION_ACTIVE;
    }
    if (tv) {
        h |= KP_HB_TIME_VALID;
    }
    if (c && c->authed) {
        h |= KP_HB_AUTHENTICATED;
    }
    if (es_overwrote_unsynced()) {
        h |= KP_HB_EVENTS_OVERWRITTEN;
    }
    return h;
}

static size_t pack_status(uint8_t out[KP_STATUS_LEN], const conn_t *c)
{
    kp_status_t s = {
        .health = health_for(c),
        .batt_pct = pw_batt_pct(),
        .batt_mv = pw_batt_mv(),
        .last_seq = es_last_seq(),
        .oldest_seq = es_oldest_seq(),
        .uptime_s = pw_uptime_s(),
        .boot_count = na_boot_count(),
        .survey_left_s = pl_survey_left_s(),
    };
    return kp_pack_status(out, &s);
}

static size_t pack_device_info(uint8_t out[KP_DEVICE_INFO_LEN])
{
    const node_profile_t *p = np_profile();
    kp_device_info_t d = {
        .sensor_type = p->sensor_type,
        .hw_rev = CONFIG_KERNEL_HW_REV,
        .fw_major = FW_MAJOR,
        .fw_minor = FW_MINOR,
        .fw_patch = FW_PATCH,
        .n_bands = p->spec.n_bands,
        .capabilities = p->capabilities,
        .sample_rate_hz = p->fs,
        .fft_size = p->spec.n_fft,
        .hop_size = p->spec.hop,
        .ring_capacity = es_capacity(),
    };
    return kp_pack_device_info(out, &d);
}

static size_t pack_band_table(uint8_t *out, size_t cap)
{
    const node_profile_t *p = np_profile();
    uint16_t edges[KP_MAX_BANDS + 1];
    for (uint8_t i = 0; i <= p->spec.n_bands; i++) {
        edges[i] = kp_q_hz10(p->spec.band_edges_hz[i]);
    }
    return kp_pack_band_table(out, cap, edges, p->spec.n_bands);
}

/* ------------------------------------------------------------ indications */

static bool indicate(conn_t *c, uint16_t attr, const uint8_t *buf, size_t len)
{
    if (len > payload_cap(c->handle)) {
        return false;
    }
    struct os_mbuf *om = ble_hs_mbuf_from_flat(buf, (uint16_t)len);
    if (!om) {
        return false;
    }
    if (ble_gatts_indicate_custom(c->handle, attr, om) != 0) {
        return false;
    }
    c->ind_busy = true;
    return true;
}

static void cp_respond(conn_t *c, uint8_t req_op, uint8_t status, const uint8_t *payload, size_t n)
{
    if (c->cpq_n >= CP_QUEUE) {
        return;
    }
    size_t len = kp_pack_cp_response(c->cpq[c->cpq_n], CP_MAX, req_op, status, payload, n);
    if (len) {
        c->cpq_len[c->cpq_n++] = (uint8_t)len;
    }
}

static void pump(conn_t *c)
{
    if (!c->used || c->ind_busy || !c->encrypted) {
        return;
    }
    if (c->cpq_n > 0) {
        if (c->sub_cp && indicate(c, h_cp, c->cpq[0], c->cpq_len[0])) {
            /* sent */
        }
        memmove(c->cpq[0], c->cpq[1], sizeof(c->cpq[0]) * (CP_QUEUE - 1));
        memmove(c->cpq_len, c->cpq_len + 1, CP_QUEUE - 1);
        c->cpq_n--;
        if (c->ind_busy) {
            return;
        }
    }
    if (!c->authed || !c->sub_event || c->next_seq == 0) {
        return;
    }
    uint32_t last = es_last_seq();
    if (c->xfer && c->next_seq > c->xfer_end) {
        uint8_t done[7];
        kp_pack_events_done(done, c->xfer_count, c->xfer_end);
        c->xfer = false;
        if (c->sub_cp) {
            indicate(c, h_cp, done, sizeof(done));
        }
        return;
    }
    while (c->next_seq <= last && !c->ind_busy) {
        kp_event_t e;
        uint32_t seq = c->next_seq++;
        if (!es_read(seq, &e)) {
            continue; /* overwritten or never stored */
        }
        uint8_t buf[KP_EVENT_LEN];
        kp_pack_event(buf, &e);
        if (indicate(c, h_event, buf, sizeof(buf))) {
            if (c->xfer) {
                c->xfer_count++;
            }
        } else {
            c->next_seq = seq; /* retry when the link allows */
            break;
        }
        if (c->xfer && c->next_seq > c->xfer_end) {
            break;
        }
    }
}

/* ----------------------------------------------------------- control point */

static void cp_handle(conn_t *c, const uint8_t *in, size_t len)
{
    kp_cp_req_t r;
    uint8_t st = kp_parse_cp(&r, in, len);
    if (st != KP_ST_OK) {
        cp_respond(c, r.opcode, st, NULL, 0);
        return;
    }
    bool auth_op = r.opcode == KP_OP_AUTH_CHALLENGE || r.opcode == KP_OP_AUTH_RESPONSE;
    if (!auth_op && !c->authed) {
        cp_respond(c, r.opcode, KP_ST_NOT_AUTHENTICATED, NULL, 0);
        return;
    }
    switch (r.opcode) {
    case KP_OP_AUTH_CHALLENGE: {
        if (esp_timer_get_time() < c->lockout_until_us || !na_has_key() || na_node_nonce(c->node_nonce) != ESP_OK) {
            cp_respond(c, r.opcode, KP_ST_AUTH_FAILED, NULL, 0);
            return;
        }
        memcpy(c->app_nonce, r.p.nonce, 16);
        uint8_t msg[KP_AUTH_MSG_MAX], payload[48];
        size_t n = kp_auth_node_msg(msg, c->app_nonce, c->node_nonce, na_addr6());
        memcpy(payload, c->node_nonce, 16);
        if (na_hmac(msg, n, payload + 16) != ESP_OK) {
            cp_respond(c, r.opcode, KP_ST_AUTH_FAILED, NULL, 0);
            return;
        }
        c->challenge_open = true;
        cp_respond(c, r.opcode, KP_ST_OK, payload, sizeof(payload));
        return;
    }
    case KP_OP_AUTH_RESPONSE: {
        bool ok = false;
        if (c->challenge_open) {
            uint8_t msg[KP_AUTH_MSG_MAX], expect[32];
            size_t n = kp_auth_app_msg(msg, c->app_nonce, c->node_nonce, na_addr6());
            ok = na_hmac(msg, n, expect) == ESP_OK && kp_ct_equal(expect, r.p.proof, 32);
        }
        c->challenge_open = false;
        if (ok) {
            c->authed = true;
            c->failures = 0;
            c->next_seq = es_last_seq() + 1; /* live events from now; history via GET_EVENTS_SINCE */
            cp_respond(c, r.opcode, KP_ST_OK, NULL, 0);
            kick(W_STATUS);
        } else {
            cp_respond(c, r.opcode, KP_ST_AUTH_FAILED, NULL, 0);
            if (++c->failures >= AUTH_MAX_FAILURES) {
                c->lockout_until_us = esp_timer_get_time() + AUTH_LOCKOUT_US;
                ble_gap_terminate(c->handle, BLE_ERR_REM_USER_CONN_TERM);
            }
        }
        return;
    }
    case KP_OP_SET_TIME:
        pw_set_time(r.p.epoch_ms);
        cp_respond(c, r.opcode, KP_ST_OK, NULL, 0);
        kick(W_STATUS);
        return;
    case KP_OP_GET_EVENTS_SINCE: {
        if (c->xfer) {
            cp_respond(c, r.opcode, KP_ST_BUSY, NULL, 0);
            return;
        }
        es_mark_requested(r.p.since.seq);
        uint32_t last = es_last_seq(), oldest = es_oldest_seq();
        uint32_t first = r.p.since.seq + 1;
        if (oldest && first < oldest) {
            first = oldest;
        }
        uint32_t count = (last >= first && last) ? last - first + 1 : 0;
        if (r.p.since.max_count && count > r.p.since.max_count) {
            count = r.p.since.max_count;
        }
        if (count > 0xFFFF) {
            count = 0xFFFF;
        }
        c->xfer = true;
        c->xfer_end = first + count - 1; /* < first when count == 0: done at once */
        c->xfer_count = 0;
        c->next_seq = first;
        uint8_t payload[14];
        kp_pack_events_since_payload(payload, (uint16_t)count, first, count ? c->xfer_end : last, oldest);
        cp_respond(c, r.opcode, KP_ST_OK, payload, sizeof(payload));
        return;
    }
    case KP_OP_START_SURVEY:
        pl_start_survey(r.p.duration_s);
        cap_pause(false);
        cp_respond(c, r.opcode, KP_ST_OK, NULL, 0);
        kick(W_STATUS);
        return;
    case KP_OP_START_SESSION:
        g_node.session = true;
        g_node.session_until_us = 0;
        cap_pause(false);
        cp_respond(c, r.opcode, KP_ST_OK, NULL, 0);
        kick(W_STATUS);
        return;
    case KP_OP_STOP_SESSION:
        g_node.session = false;
        g_node.session_until_us = 0;
        cp_respond(c, r.opcode, KP_ST_OK, NULL, 0);
        kick(W_STATUS);
        return;
    case KP_OP_REQUEST_SNIPPET: {
        if (!(g_node.cfg.flags & KP_CF_SNIPPETS) || !sn_get(r.p.snippet_seq, &c->snip) || c->snip.rows == 0) {
            cp_respond(c, r.opcode, KP_ST_NOT_AVAILABLE, NULL, 0);
            return;
        }
        uint16_t cap = payload_cap(c->handle);
        uint16_t per = (uint16_t)((cap - KP_SNIPPET_TILE_HDR_LEN) / c->snip.rows);
        if (per == 0) {
            cp_respond(c, r.opcode, KP_ST_INVALID_PARAM, NULL, 0); /* MTU too small */
            return;
        }
        if (per > c->snip.cols) {
            per = c->snip.cols;
        }
        c->snip_cols_per_tile = (uint8_t)per;
        c->snip_tiles = (uint8_t)((c->snip.cols + per - 1) / per);
        c->snip_next_tile = 0;
        c->snip_pending = true;
        uint8_t meta[KP_SNIPPET_META_LEN];
        kp_pack_snippet_meta(meta, c->snip.seq, c->snip.rows, c->snip.cols, c->snip.f_lo_hz10, c->snip.f_hi_hz10,
                             c->snip.col_deci_ms, c->snip_tiles, c->snip_cols_per_tile);
        cp_respond(c, r.opcode, KP_ST_OK, meta, sizeof(meta));
        return;
    }
    case KP_OP_CLEAR_BOND:
        c->clear_bond = true;
        cp_respond(c, r.opcode, KP_ST_OK, NULL, 0);
        return;
    default:
        cp_respond(c, r.opcode, KP_ST_UNKNOWN_OPCODE, NULL, 0);
        return;
    }
}

/* Sends pending snippet tiles (notifications); called from the worker. */
static bool send_snippet_tiles(conn_t *c)
{
    if (!c->snip_pending || c->ind_busy || c->cpq_n || !c->sub_snippet) {
        return c->snip_pending;
    }
    static uint8_t buf[KP_SNIPPET_TILE_HDR_LEN + 512];
    while (c->snip_next_tile < c->snip_tiles) {
        uint8_t col0 = (uint8_t)(c->snip_next_tile * c->snip_cols_per_tile);
        uint8_t n = c->snip_cols_per_tile;
        if (col0 + n > c->snip.cols) {
            n = (uint8_t)(c->snip.cols - col0);
        }
        size_t data = (size_t)n * c->snip.rows;
        if (KP_SNIPPET_TILE_HDR_LEN + data > sizeof(buf)) {
            c->snip_pending = false;
            return false;
        }
        kp_pack_snippet_tile_hdr(buf, c->snip.seq, c->snip_next_tile, c->snip_tiles, col0, n);
        memcpy(buf + KP_SNIPPET_TILE_HDR_LEN, &c->snip.cells[(size_t)col0 * c->snip.rows], data);
        struct os_mbuf *om = ble_hs_mbuf_from_flat(buf, (uint16_t)(KP_SNIPPET_TILE_HDR_LEN + data));
        if (!om || ble_gatts_notify_custom(c->handle, h_snippet, om) != 0) {
            return true; /* out of buffers: retry shortly */
        }
        c->snip_next_tile++;
    }
    c->snip_pending = false;
    memset(&c->snip, 0, sizeof(c->snip)); /* memory only, dropped once sent */
    return false;
}

/* ------------------------------------------------------------ GATT access */

static int append(struct ble_gatt_access_ctxt *ctxt, const void *data, size_t len)
{
    return os_mbuf_append(ctxt->om, data, (uint16_t)len) == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
}

static int chr_access(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    int id = (int)(intptr_t)arg;
    int rc = 0;
    lock();
    conn_t *c = find(conn_handle);
    bool authed = c && c->authed;
    bool read = ctxt->op == BLE_GATT_ACCESS_OP_READ_CHR;
    bool write = ctxt->op == BLE_GATT_ACCESS_OP_WRITE_CHR;
    switch (id) {
    case CHR_DEVICE_INFO: {
        uint8_t b[KP_DEVICE_INFO_LEN];
        rc = read ? append(ctxt, b, pack_device_info(b)) : BLE_ATT_ERR_WRITE_NOT_PERMITTED;
        break;
    }
    case CHR_STATUS: {
        uint8_t b[KP_STATUS_LEN];
        rc = read ? append(ctxt, b, pack_status(b, c)) : BLE_ATT_ERR_WRITE_NOT_PERMITTED;
        break;
    }
    case CHR_CONFIG:
        if (!authed) {
            rc = BLE_ATT_ERR_INSUFFICIENT_AUTHOR;
        } else if (read) {
            uint8_t b[KP_CONFIG_LEN];
            rc = append(ctxt, b, kp_pack_config(b, &g_node.cfg));
        } else if (write) {
            uint8_t b[KP_CONFIG_LEN + 1];
            uint16_t n = 0;
            if (ble_hs_mbuf_to_flat(ctxt->om, b, sizeof(b), &n) != 0) {
                rc = BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
                break;
            }
            kp_config_t cfg;
            int e = kp_unpack_config(&cfg, b, n);
            if (e) {
                rc = e;
                break;
            }
            g_node.cfg = cfg;
            np_save_config(&cfg);
            pl_request_config(&cfg);
            kick(W_STATUS);
        }
        break;
    case CHR_BAND_TABLE:
        if (!authed) {
            rc = BLE_ATT_ERR_INSUFFICIENT_AUTHOR;
        } else {
            uint8_t b[KP_BAND_TABLE_MAX_LEN];
            rc = read ? append(ctxt, b, pack_band_table(b, sizeof(b))) : BLE_ATT_ERR_WRITE_NOT_PERMITTED;
        }
        break;
    case CHR_CONTROL:
        if (write && c) {
            uint8_t b[CP_MAX];
            uint16_t n = 0;
            if (ble_hs_mbuf_to_flat(ctxt->om, b, sizeof(b), &n) != 0) {
                rc = BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
                break;
            }
            cp_handle(c, b, n);
            kick(W_EVENT); /* the worker sends the RESPONSE indication */
        } else {
            rc = BLE_ATT_ERR_READ_NOT_PERMITTED;
        }
        break;
    case CHR_BAND_FRAME:
    case CHR_EVENT:
    case CHR_SNIPPET:
        rc = authed ? BLE_ATT_ERR_READ_NOT_PERMITTED : BLE_ATT_ERR_INSUFFICIENT_AUTHOR;
        break;
    case CHR_DIS_MANUFACTURER:
        rc = append(ctxt, "Kernel", 6);
        break;
    case CHR_DIS_MODEL: {
        static const char *models[] = {"", "Kernel US_AIR", "Kernel CONTACT", "Kernel CONTACT_ACCEL", "Kernel AUDIO_AIR"};
        uint8_t t = np_profile()->sensor_type;
        const char *m = t < 5 ? models[t] : "Kernel";
        rc = append(ctxt, m, strlen(m));
        break;
    }
    case CHR_DIS_HW: {
        char hw[8];
        int n = snprintf(hw, sizeof(hw), "%d", CONFIG_KERNEL_HW_REV);
        rc = append(ctxt, hw, (size_t)n);
        break;
    }
    case CHR_DIS_FW: {
        char fw[16];
        int n = snprintf(fw, sizeof(fw), "%d.%d.%d", FW_MAJOR, FW_MINOR, FW_PATCH);
        rc = append(ctxt, fw, (size_t)n);
        break;
    }
    case CHR_BATTERY: {
        uint8_t b = pw_batt_pct();
        b = b > 100 ? 0 : b;
        rc = append(ctxt, &b, 1);
        break;
    }
    default:
        rc = BLE_ATT_ERR_UNLIKELY;
    }
    unlock();
    return rc;
}

#define ARG(x) ((void *)(intptr_t)(x))
#define ENC_R (BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_READ_ENC)
#define ENC_W (BLE_GATT_CHR_F_WRITE | BLE_GATT_CHR_F_WRITE_ENC)

static const struct ble_gatt_svc_def s_svcs[] = {
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = BLE_UUID16_DECLARE(0x180A),
        .characteristics = (struct ble_gatt_chr_def[]){
            {.uuid = BLE_UUID16_DECLARE(0x2A29), .access_cb = chr_access, .arg = ARG(CHR_DIS_MANUFACTURER), .flags = ENC_R},
            {.uuid = BLE_UUID16_DECLARE(0x2A24), .access_cb = chr_access, .arg = ARG(CHR_DIS_MODEL), .flags = ENC_R},
            {.uuid = BLE_UUID16_DECLARE(0x2A27), .access_cb = chr_access, .arg = ARG(CHR_DIS_HW), .flags = ENC_R},
            {.uuid = BLE_UUID16_DECLARE(0x2A26), .access_cb = chr_access, .arg = ARG(CHR_DIS_FW), .flags = ENC_R},
            {0},
        },
    },
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = BLE_UUID16_DECLARE(0x180F),
        .characteristics = (struct ble_gatt_chr_def[]){
            {.uuid = BLE_UUID16_DECLARE(0x2A19), .access_cb = chr_access, .arg = ARG(CHR_BATTERY),
             .flags = ENC_R | BLE_GATT_CHR_F_NOTIFY, .val_handle = &h_batt},
            {0},
        },
    },
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &uuid_svc.u,
        .characteristics = (struct ble_gatt_chr_def[]){
            {.uuid = &uuid_info.u, .access_cb = chr_access, .arg = ARG(CHR_DEVICE_INFO), .flags = ENC_R},
            {.uuid = &uuid_config.u, .access_cb = chr_access, .arg = ARG(CHR_CONFIG), .flags = ENC_R | ENC_W},
            {.uuid = &uuid_table.u, .access_cb = chr_access, .arg = ARG(CHR_BAND_TABLE), .flags = ENC_R},
            {.uuid = &uuid_frame.u, .access_cb = chr_access, .arg = ARG(CHR_BAND_FRAME),
             .flags = BLE_GATT_CHR_F_NOTIFY | BLE_GATT_CHR_F_READ_ENC, .val_handle = &h_band_frame},
            {.uuid = &uuid_event.u, .access_cb = chr_access, .arg = ARG(CHR_EVENT),
             .flags = BLE_GATT_CHR_F_INDICATE | BLE_GATT_CHR_F_READ_ENC, .val_handle = &h_event},
            {.uuid = &uuid_status.u, .access_cb = chr_access, .arg = ARG(CHR_STATUS),
             .flags = ENC_R | BLE_GATT_CHR_F_NOTIFY, .val_handle = &h_status},
            {.uuid = &uuid_cp.u, .access_cb = chr_access, .arg = ARG(CHR_CONTROL),
             .flags = ENC_W | BLE_GATT_CHR_F_INDICATE, .val_handle = &h_cp},
            {.uuid = &uuid_snippet.u, .access_cb = chr_access, .arg = ARG(CHR_SNIPPET),
             .flags = BLE_GATT_CHR_F_NOTIFY | BLE_GATT_CHR_F_READ_ENC, .val_handle = &h_snippet},
            {0},
        },
    },
    {0},
};

/* ------------------------------------------------------------ advertising */

static int gap_event(struct ble_gap_event *event, void *arg);

static void advertise(void)
{
    if (ble_gap_adv_active()) {
        ble_gap_adv_stop();
    }
    int used = 0;
    for (int i = 0; i < MAX_CONN; i++) {
        used += s_conn[i].used ? 1 : 0;
    }
    if (used >= MAX_CONN) {
        return;
    }
    static uint8_t mfg[2 + KP_ADV_MFG_LEN];
    kp_pack_adv_mfg(mfg, CONFIG_KERNEL_COMPANY_ID, np_profile()->sensor_type, es_last_seq(), pw_batt_pct());
    struct ble_hs_adv_fields f;
    memset(&f, 0, sizeof(f));
    f.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
    f.uuids128 = &uuid_svc;
    f.num_uuids128 = 1;
    f.uuids128_is_complete = 1;
    f.mfg_data = mfg;
    f.mfg_data_len = KP_ADV_MFG_LEN;
    if (ble_gap_adv_set_fields(&f) != 0) {
        ESP_LOGW(TAG, "adv fields rejected");
        return;
    }
    struct ble_hs_adv_fields rsp;
    memset(&rsp, 0, sizeof(rsp));
    rsp.name = (const uint8_t *)s_name;
    rsp.name_len = (uint8_t)strlen(s_name);
    rsp.name_is_complete = 1;
    ble_gap_adv_rsp_set_fields(&rsp);
    struct ble_gap_adv_params p;
    memset(&p, 0, sizeof(p));
    p.conn_mode = BLE_GAP_CONN_MODE_UND;
    p.disc_mode = BLE_GAP_DISC_MODE_GEN;
    uint32_t ms = esp_timer_get_time() < s_fast_adv_until_us ? 100 : (pw_low_battery(g_node.cfg.low_batt_pct) ? 2000 : 1000);
    p.itvl_min = (uint16_t)BLE_GAP_ADV_ITVL_MS(ms);
    p.itvl_max = (uint16_t)BLE_GAP_ADV_ITVL_MS(ms + ms / 10);
    int rc = ble_gap_adv_start(s_own_addr_type, NULL, BLE_HS_FOREVER, &p, gap_event, NULL);
    if (rc != 0) {
        ESP_LOGW(TAG, "adv start rc=%d", rc);
    }
}

static int gap_event(struct ble_gap_event *event, void *arg)
{
    struct ble_gap_conn_desc desc;
    lock();
    switch (event->type) {
    case BLE_GAP_EVENT_CONNECT:
        if (event->connect.status == 0) {
            for (int i = 0; i < MAX_CONN; i++) {
                if (!s_conn[i].used) {
                    memset(&s_conn[i], 0, sizeof(s_conn[i]));
                    s_conn[i].used = true;
                    s_conn[i].handle = event->connect.conn_handle;
                    if (ble_gap_conn_find(event->connect.conn_handle, &desc) == 0) {
                        s_conn[i].peer = desc.peer_id_addr;
                    }
                    break;
                }
            }
            /* Ask the phone to encrypt now (bonded: LTK; new: SC Just Works pairing). */
            ble_gap_security_initiate(event->connect.conn_handle);
        }
        advertise();
        break;
    case BLE_GAP_EVENT_DISCONNECT: {
        conn_t *c = find(event->disconnect.conn.conn_handle);
        if (c) {
            if (c->clear_bond) {
                ble_gap_unpair(&c->peer);
            }
            memset(c, 0, sizeof(*c));
        }
        bool any = false;
        for (int i = 0; i < MAX_CONN; i++) {
            any = any || s_conn[i].used;
        }
        if (!any && g_node.session) {
            g_node.session = false;
            g_node.session_until_us = esp_timer_get_time() + SESSION_GRACE_US;
        }
        advertise();
        break;
    }
    case BLE_GAP_EVENT_ENC_CHANGE: {
        conn_t *c = find(event->enc_change.conn_handle);
        if (c && event->enc_change.status == 0 && ble_gap_conn_find(c->handle, &desc) == 0) {
            c->encrypted = desc.sec_state.encrypted && desc.sec_state.key_size >= 16;
            c->peer = desc.peer_id_addr;
        }
        break;
    }
    case BLE_GAP_EVENT_REPEAT_PAIRING:
        /* The phone lost its bond: forget ours and pair again. */
        if (ble_gap_conn_find(event->repeat_pairing.conn_handle, &desc) == 0) {
            ble_store_util_delete_peer(&desc.peer_id_addr);
        }
        unlock();
        return BLE_GAP_REPEAT_PAIRING_RETRY;
    case BLE_GAP_EVENT_SUBSCRIBE: {
        conn_t *c = find(event->subscribe.conn_handle);
        if (c) {
            uint16_t a = event->subscribe.attr_handle;
            bool on = event->subscribe.cur_notify || event->subscribe.cur_indicate;
            if (a == h_event) {
                c->sub_event = on;
            } else if (a == h_status) {
                c->sub_status = on;
            } else if (a == h_cp) {
                c->sub_cp = on;
            } else if (a == h_band_frame) {
                c->sub_band = on;
            } else if (a == h_snippet) {
                c->sub_snippet = on;
            } else if (a == h_batt) {
                c->sub_batt = on;
            }
        }
        kick(W_EVENT);
        break;
    }
    case BLE_GAP_EVENT_NOTIFY_TX: {
        conn_t *c = find(event->notify_tx.conn_handle);
        if (c && event->notify_tx.indication && event->notify_tx.status != 0) {
            /* BLE_HS_EDONE = acknowledged; any other non-zero = failed/timeout. */
            c->ind_busy = false;
            kick(W_EVENT);
        }
        break;
    }
    case BLE_GAP_EVENT_ADV_COMPLETE:
        advertise();
        break;
    default:
        break;
    }
    unlock();
    return 0;
}

/* ------------------------------------------------------------------ worker */

static void worker(void *arg)
{
    uint32_t last_minute = 0;
    for (;;) {
        uint32_t bits = 0;
        bool snippets = false;
        for (int i = 0; i < MAX_CONN; i++) {
            snippets = snippets || s_conn[i].snip_pending;
        }
        xTaskNotifyWait(0, UINT32_MAX, &bits, pdMS_TO_TICKS(snippets ? 15 : 1000));
        lock();
        if (bits & W_STATUS) {
            for (int i = 0; i < MAX_CONN; i++) {
                conn_t *c = &s_conn[i];
                if (c->used && c->encrypted && c->sub_status) {
                    uint8_t b[KP_STATUS_LEN];
                    size_t n = pack_status(b, c);
                    struct os_mbuf *om = ble_hs_mbuf_from_flat(b, (uint16_t)n);
                    if (om) {
                        ble_gatts_notify_custom(c->handle, h_status, om);
                    }
                }
                if (c->used && c->encrypted && c->sub_batt) {
                    uint8_t level = pw_batt_pct();
                    level = level > 100 ? 0 : level;
                    struct os_mbuf *om = ble_hs_mbuf_from_flat(&level, 1);
                    if (om) {
                        ble_gatts_notify_custom(c->handle, h_batt, om);
                    }
                }
            }
        }
        if (bits & W_BAND) {
            kp_band_frame_t f;
            if (pl_band_frame_pending(&f)) {
                uint8_t b[KP_BAND_FRAME_MAX_LEN];
                size_t n = kp_pack_band_frame(b, sizeof(b), &f);
                for (int i = 0; i < MAX_CONN && n; i++) {
                    conn_t *c = &s_conn[i];
                    if (c->used && c->authed && c->sub_band && n <= payload_cap(c->handle)) {
                        struct os_mbuf *om = ble_hs_mbuf_from_flat(b, (uint16_t)n);
                        if (om) {
                            ble_gatts_notify_custom(c->handle, h_band_frame, om);
                        }
                    }
                }
            }
        }
        for (int i = 0; i < MAX_CONN; i++) {
            pump(&s_conn[i]);
            send_snippet_tiles(&s_conn[i]);
        }
        uint32_t minute = pw_uptime_s() / 60;
        if ((bits & W_ADV) || minute != last_minute) {
            last_minute = minute;
            advertise(); /* refresh lastEventSeq and battery in the advertising data */
        }
        unlock();
    }
}

void bg_on_new_event(void) { kick(W_EVENT); }
void bg_on_band_frame(void) { kick(W_BAND); }
void bg_on_status_change(void) { kick(W_STATUS); }

/* -------------------------------------------------------------- host setup */

static void on_sync(void)
{
    ble_hs_util_ensure_addr(0);
    /* Public address: the one printed on the QR label. */
    s_own_addr_type = BLE_OWN_ADDR_PUBLIC;
    const uint8_t *a = na_addr6();
    snprintf(s_name, sizeof(s_name), "Kernel-%02X%02X", a[4], a[5]);
    ble_svc_gap_device_name_set(s_name);
    s_fast_adv_until_us = esp_timer_get_time() + 30 * 1000000LL;
    lock();
    advertise();
    unlock();
}

static void on_reset(int reason) { ESP_LOGW(TAG, "host reset, reason %d", reason); }

static void host_task(void *param)
{
    nimble_port_run();
    nimble_port_freertos_deinit();
}

esp_err_t bg_init(void)
{
    s_mx = xSemaphoreCreateRecursiveMutex();
    esp_err_t err = nimble_port_init();
    if (err != ESP_OK) {
        return err;
    }
    ble_hs_cfg.sync_cb = on_sync;
    ble_hs_cfg.reset_cb = on_reset;
    ble_hs_cfg.store_status_cb = ble_store_util_status_rr;
    ble_hs_cfg.sm_io_cap = BLE_SM_IO_CAP_NO_IO; /* Just Works */
    ble_hs_cfg.sm_bonding = 1;
    ble_hs_cfg.sm_mitm = 0;
    ble_hs_cfg.sm_sc = 1; /* LE Secure Connections */
    ble_hs_cfg.sm_our_key_dist = BLE_SM_PAIR_KEY_DIST_ENC | BLE_SM_PAIR_KEY_DIST_ID;
    ble_hs_cfg.sm_their_key_dist = BLE_SM_PAIR_KEY_DIST_ENC | BLE_SM_PAIR_KEY_DIST_ID;
    ble_svc_gap_init();
    ble_svc_gatt_init();
    int rc = ble_gatts_count_cfg(s_svcs);
    if (rc == 0) {
        rc = ble_gatts_add_svcs(s_svcs);
    }
    if (rc != 0) {
        ESP_LOGE(TAG, "GATT table rejected rc=%d", rc);
        return ESP_FAIL;
    }
    ble_store_config_init();
    xTaskCreatePinnedToCore(worker, "kble", 6144, NULL, 5, &s_worker, 0);
    nimble_port_freertos_init(host_task);
    return ESP_OK;
}
