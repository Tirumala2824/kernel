"""Wire codec for docs/sensor-protocol.md v1, mirrored by kernel_proto (C),
SensorProtocol.kt (Kotlin) and protocol.dart (Dart).

All multi-byte fields are little-endian and packed (no padding).
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import struct
from dataclasses import dataclass

from .detect import rnd

PROTO_MAJOR = 1
PROTO_MINOR = 0

SERVICE_UUID = "c7780001-4139-44b2-877d-c537908d6290"


def char_uuid(short: int) -> str:
    return f"c778{short:04x}-4139-44b2-877d-c537908d6290"


UUID_DEVICE_INFO = char_uuid(0x0002)
UUID_CONFIG = char_uuid(0x0003)
UUID_BAND_TABLE = char_uuid(0x0004)
UUID_BAND_FRAME = char_uuid(0x0005)
UUID_EVENT = char_uuid(0x0006)
UUID_STATUS = char_uuid(0x0007)
UUID_CONTROL_POINT = char_uuid(0x0008)
UUID_SNIPPET = char_uuid(0x0009)

COMPANY_ID_TEST = 0xFFFF

# Control point opcodes.
OP_SET_TIME = 0x01
OP_GET_EVENTS_SINCE = 0x02
OP_START_SURVEY = 0x03
OP_START_SESSION = 0x04
OP_STOP_SESSION = 0x05
OP_REQUEST_SNIPPET = 0x06
OP_CLEAR_BOND = 0x07
OP_AUTH_CHALLENGE = 0x10
OP_AUTH_RESPONSE = 0x11
OP_RESPONSE = 0x80
OP_EVENTS_DONE = 0x81

ST_OK = 0x00
ST_UNKNOWN_OPCODE = 0x01
ST_INVALID_PARAM = 0x02
ST_NOT_AUTHENTICATED = 0x03
ST_AUTH_FAILED = 0x04
ST_BUSY = 0x05
ST_NOT_AVAILABLE = 0x06
ST_STORAGE_ERROR = 0x07

# Status.health bits.
HB_JAMMED = 1 << 0
HB_CLIPPED = 1 << 1
HB_LOW_BATTERY = 1 << 2
HB_SURVEY_NEEDED = 1 << 3
HB_SURVEY_ACTIVE = 1 << 4
HB_SESSION_ACTIVE = 1 << 5
HB_TIME_VALID = 1 << 6
HB_AUTHENTICATED = 1 << 7
HB_WARMING_UP = 1 << 8
HB_SENSOR_FAULT = 1 << 9
HB_EVENTS_OVERWRITTEN = 1 << 10

# BandFrame flags.
BF_TIME_VALID = 0x01
BF_JAMMED = 0x02
BF_CLIPPED = 0x04
BF_SURVEY_ACTIVE = 0x08
BF_WARMING_UP = 0x10

MAX_BANDS = 24


def band_flags(detector_health: int, time_valid: bool) -> int:
    """Detector health bits (H_JAMMED 1, H_CLIPPED 2, H_WARMING 4, H_SURVEY 8) -> BandFrame flags."""
    f = BF_TIME_VALID if time_valid else 0
    if detector_health & 0x01:
        f |= BF_JAMMED
    if detector_health & 0x02:
        f |= BF_CLIPPED
    if detector_health & 0x08:
        f |= BF_SURVEY_ACTIVE
    if detector_health & 0x04:
        f |= BF_WARMING_UP
    return f

ADV_FMT = "<HBBHB"
DEVICE_INFO_FMT = "<BBBBBBBBHIHHHBB"
CONFIG_FMT = "<BBHHHBBBBBBHHHBBHBBBBHH"
EVENT_FMT = "<IIHHBBHHHhBbBBHBB"
STATUS_FMT = "<HBHIIIHH"
BAND_FRAME_HDR_FMT = "<IIHHBBhHh"
SNIPPET_META_FMT = "<IBBHHHBB"
SNIPPET_TILE_HDR_FMT = "<IBBBB"

ADV_LEN = struct.calcsize(ADV_FMT)  # 7
DEVICE_INFO_LEN = struct.calcsize(DEVICE_INFO_FMT)  # 22
CONFIG_LEN = struct.calcsize(CONFIG_FMT)  # 32
EVENT_LEN = struct.calcsize(EVENT_FMT)  # 30
STATUS_LEN = struct.calcsize(STATUS_FMT)  # 21
BAND_FRAME_HDR_LEN = struct.calcsize(BAND_FRAME_HDR_FMT) + 3  # 23


def _clamp(v: int, lo: int, hi: int) -> int:
    return lo if v < lo else hi if v > hi else v


def q_hz10(hz: float) -> int:
    return _clamp(rnd(hz / 10.0), 0, 0xFFFF)


def q_slope(hz_per_ms: float) -> int:
    return _clamp(rnd(hz_per_ms * 10.0), -32767, 32767)


def q_half_db(db: float) -> int:
    return _clamp(rnd(db * 2.0), 0, 255)


def q_dbfs_i8(db: float) -> int:
    return _clamp(rnd(db), -128, 127)


def q_deci_db(db: float) -> int:
    return _clamp(rnd(db * 10.0), -32768, 32767)


def q_rate(hz: float) -> int:
    return _clamp(rnd(hz * 100.0), 0, 0xFFFF)


def q_cv(cv: float) -> int:
    return 255 if cv < 0 else _clamp(rnd(cv * 100.0), 0, 254)


@dataclass
class WireEvent:
    seq: int
    t_start_s: int
    t_start_ms: int
    duration_ms: int
    event_class: int
    flags: int
    peak_hz10: int
    min_hz10: int
    max_hz10: int
    slope_dhz_per_ms: int
    snr_half_db: int
    peak_dbfs: int
    impulses: int
    harmonics: int
    rep_rate_chz: int
    ipi_cv_pct: int
    boot_low: int

    def pack(self) -> bytes:
        return struct.pack(
            EVENT_FMT,
            self.seq, self.t_start_s, self.t_start_ms, self.duration_ms, self.event_class, self.flags,
            self.peak_hz10, self.min_hz10, self.max_hz10, self.slope_dhz_per_ms, self.snr_half_db,
            self.peak_dbfs, self.impulses, self.harmonics, self.rep_rate_chz, self.ipi_cv_pct,
            self.boot_low,
        )

    @classmethod
    def unpack(cls, b: bytes) -> "WireEvent":
        if len(b) < EVENT_LEN:
            raise ValueError("event too short")
        return cls(*struct.unpack_from(EVENT_FMT, b))

    def as_dict(self) -> dict:
        return dict(self.__dict__)


def event_from_detection(ev, seq: int, epoch_ms: int | None, boot_low: int = 0) -> WireEvent:
    """Packs a DetEvent. epoch_ms is the node clock at the event start (None if unset)."""
    flags = ev.flags
    if epoch_ms is not None:
        t = int(epoch_ms)
        flags |= 0x01
    else:
        t = rnd(ev.t_start_ms)
    return WireEvent(
        seq=seq,
        t_start_s=t // 1000,
        t_start_ms=t % 1000,
        duration_ms=_clamp(rnd(ev.duration_ms), 0, 0xFFFF),
        event_class=ev.cls,
        flags=flags,
        peak_hz10=q_hz10(ev.peak_hz),
        min_hz10=q_hz10(ev.min_hz),
        max_hz10=q_hz10(ev.max_hz),
        slope_dhz_per_ms=q_slope(ev.slope_hz_per_ms),
        snr_half_db=q_half_db(ev.snr_db),
        peak_dbfs=q_dbfs_i8(ev.peak_dbfs),
        impulses=_clamp(ev.impulses, 0, 255),
        harmonics=_clamp(ev.harmonics, 0, 255),
        rep_rate_chz=q_rate(ev.rep_rate_hz),
        ipi_cv_pct=q_cv(ev.ipi_cv),
        boot_low=boot_low & 0xFF,
    )


def pack_adv(company_id: int, sensor_type: int, last_seq: int, batt: int) -> bytes:
    return struct.pack(ADV_FMT, company_id, PROTO_MAJOR, sensor_type, last_seq & 0xFFFF, batt)


def pack_device_info(**f) -> bytes:
    return struct.pack(
        DEVICE_INFO_FMT,
        f["proto_major"], f["proto_minor"], f["sensor_type"], f["hw_rev"], f["fw_major"],
        f["fw_minor"], f["fw_patch"], f["n_bands"], f["capabilities"], f["sample_rate_hz"],
        f["fft_size"], f["hop_size"], f["ring_capacity"], f["cfg_version"], 0,
    )


CONFIG_FIELDS = (
    "cfg_version", "flags", "band_frame_ms", "duty_on_s", "duty_off_s", "detect_thresh_half_db",
    "jam_thresh_half_db", "jam_hold_ds", "impulse_thresh_half_db", "min_blob_ms", "max_gap_ms",
    "flat_min_ms", "cont_min_ms", "fm_min_bw_hz10", "burst_min_impulses", "train_min_pulses",
    "burst_max_gap_ms", "impulse_min_half_ms", "impulse_max_ms", "train_max_cv_pct",
    "low_batt_pct", "chirp_max_gap_ms", "reserved",
)


def pack_config(**f) -> bytes:
    return struct.pack(CONFIG_FMT, *[f.get(k, 0) for k in CONFIG_FIELDS])


def unpack_config(b: bytes) -> dict:
    return dict(zip(CONFIG_FIELDS, struct.unpack_from(CONFIG_FMT, b)))


def pack_band_table(edges_hz10: list[int]) -> bytes:
    n = len(edges_hz10) - 1
    if not 1 <= n <= MAX_BANDS:
        raise ValueError("bad band count")
    return struct.pack("<BB", n, 0) + struct.pack(f"<{n + 1}H", *edges_hz10)


def pack_band_frame(seq, t_s, t_ms, frame_ms, flags, floor_ddb, peak_hz10, peak_ddb, jam_mask, bands_half_db) -> bytes:
    n = len(bands_half_db)
    if not 1 <= n <= MAX_BANDS:
        raise ValueError("bad band count")
    hdr = struct.pack(BAND_FRAME_HDR_FMT, seq, t_s, t_ms, frame_ms, flags, n, floor_ddb, peak_hz10, peak_ddb)
    return hdr + (jam_mask & 0xFFFFFF).to_bytes(3, "little") + bytes(bands_half_db)


def pack_status(health, batt_pct, batt_mv, last_seq, oldest_seq, uptime_s, boot_count, survey_left_s) -> bytes:
    return struct.pack(STATUS_FMT, health, batt_pct, batt_mv, last_seq, oldest_seq, uptime_s, boot_count, survey_left_s)


# ---- control point -------------------------------------------------------


def cp_set_time(epoch_ms: int) -> bytes:
    return struct.pack("<BQ", OP_SET_TIME, epoch_ms)


def cp_get_events_since(seq: int, max_count: int = 0) -> bytes:
    return struct.pack("<BIH", OP_GET_EVENTS_SINCE, seq, max_count)


def cp_start_survey(duration_s: int) -> bytes:
    return struct.pack("<BH", OP_START_SURVEY, duration_s)


def cp_start_session(flags: int) -> bytes:
    return struct.pack("<BB", OP_START_SESSION, flags)


def cp_stop_session() -> bytes:
    return struct.pack("<B", OP_STOP_SESSION)


def cp_request_snippet(seq: int) -> bytes:
    return struct.pack("<BI", OP_REQUEST_SNIPPET, seq)


def cp_clear_bond() -> bytes:
    return struct.pack("<B", OP_CLEAR_BOND)


def cp_auth_challenge(app_nonce: bytes) -> bytes:
    assert len(app_nonce) == 16
    return bytes([OP_AUTH_CHALLENGE]) + app_nonce


def cp_auth_response(app_proof: bytes) -> bytes:
    assert len(app_proof) == 32
    return bytes([OP_AUTH_RESPONSE]) + app_proof


def cp_response(req_op: int, status: int, payload: bytes = b"") -> bytes:
    return bytes([OP_RESPONSE, req_op, status]) + payload


def cp_events_since_payload(count: int, first_seq: int, last_seq: int, oldest_seq: int) -> bytes:
    return struct.pack("<HIII", count, first_seq, last_seq, oldest_seq)


def cp_events_done(count: int, last_seq: int) -> bytes:
    return struct.pack("<BHI", OP_EVENTS_DONE, count, last_seq)


def snippet_meta(seq, rows, cols, f_lo_hz10, f_hi_hz10, col_deci_ms, tile_count, cols_per_tile) -> bytes:
    return struct.pack(SNIPPET_META_FMT, seq, rows, cols, f_lo_hz10, f_hi_hz10, col_deci_ms, tile_count, cols_per_tile)


def snippet_tile(seq, index, count, col0, data_cols: list[bytes]) -> bytes:
    return struct.pack(SNIPPET_TILE_HDR_FMT, seq, index, count, col0, len(data_cols)) + b"".join(data_cols)


# ---- auth ----------------------------------------------------------------

LABEL_NODE = b"KRNL-AUTH-N1"
LABEL_APP = b"KRNL-AUTH-A1"
LABEL_NODE_NONCE = b"KRNL-NONCE"
LABEL_APP_NONCE = b"KRNL-APPNONCE"


def addr_bytes(addr: str) -> bytes:
    parts = addr.split(":")
    if len(parts) != 6:
        raise ValueError("address must be AA:BB:CC:DD:EE:FF")
    return bytes(int(p, 16) for p in parts)


def hmac256(key: bytes, msg: bytes) -> bytes:
    return hmac.new(key, msg, hashlib.sha256).digest()


def node_nonce(key: bytes, boot_count: int, counter: int, uptime_us: int) -> bytes:
    return hmac256(key, LABEL_NODE_NONCE + struct.pack("<IIQ", boot_count, counter, uptime_us))[:16]


def app_nonce(key: bytes, counter: int, epoch_ms: int) -> bytes:
    return hmac256(key, LABEL_APP_NONCE + struct.pack("<QQ", counter, epoch_ms))[:16]


def node_proof(key: bytes, app_n: bytes, node_n: bytes, addr: str) -> bytes:
    return hmac256(key, LABEL_NODE + app_n + node_n + addr_bytes(addr))


def app_proof(key: bytes, app_n: bytes, node_n: bytes, addr: str) -> bytes:
    return hmac256(key, LABEL_APP + node_n + app_n + addr_bytes(addr))


def key_fingerprint(key: bytes) -> str:
    return hashlib.sha256(key).hexdigest()[:8]


SENSOR_TYPE_NAMES = {1: "us_air", 2: "contact_piezo", 3: "contact_accel", 4: "audio_air"}


def qr_payload(addr: str, key: bytes, sensor_type: int) -> str:
    k = base64.urlsafe_b64encode(key).decode().rstrip("=")
    return f"kernel:sensor:v1:{addr.upper()}:{k}:{SENSOR_TYPE_NAMES[sensor_type]}"
