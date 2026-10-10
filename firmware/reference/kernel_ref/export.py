"""Writes the shared test vectors.

    uv run python -I -m kernel_ref.export

Outputs (all deterministic):
  vectors/detect_<scenario>.json   detector outputs + wire events per scenario
  vectors/protocol_v1.json         byte fixtures for every structure in docs/sensor-protocol.md
  vectors/auth_v1.json             RFC 4231 HMAC-SHA256 cases + handshake vectors
  vectors/qr_v1.json               QR label parser cases
  ../components/kernel_detect/kd_halfband.c   generated half-band taps
"""

from __future__ import annotations

import base64
import json
import sys
from pathlib import Path

from . import config as C
from . import dsp, proto, scenarios

ROOT = Path(__file__).resolve().parent.parent
VECTORS = ROOT / "vectors"
HALFBAND_C = ROOT.parent / "components" / "kernel_detect" / "kd_halfband.c"

EPOCH_BASE_MS = 1767225600000  # 2026-01-01T00:00:00Z, fixed test clock
BOOT_COUNT = 7

SENSOR_TYPE_KEYS = {1: "usAir", 2: "contactPiezo", 3: "contactAccel", 4: "audioAir"}

EVENT_KEYS = (
    ("seq", "seq"), ("t_start_s", "tStartS"), ("t_start_ms", "tStartMs"), ("duration_ms", "durationMs"),
    ("event_class", "eventClass"), ("flags", "flags"), ("peak_hz10", "peakHz10"), ("min_hz10", "minHz10"),
    ("max_hz10", "maxHz10"), ("slope_dhz_per_ms", "slopeDHzPerMs"), ("snr_half_db", "snrHalfDb"),
    ("peak_dbfs", "peakDbfs"), ("impulses", "impulses"), ("harmonics", "harmonics"),
    ("rep_rate_chz", "repRateCHz"), ("ipi_cv_pct", "ipiCvPct"), ("boot_low", "bootLow"),
)

CONFIG_KEYS = {
    "cfg_version": "cfgVersion", "flags": "flags", "band_frame_ms": "bandFrameMs", "duty_on_s": "dutyOnS",
    "duty_off_s": "dutyOffS", "detect_thresh_half_db": "detectThreshHalfDb",
    "jam_thresh_half_db": "jamThreshHalfDb", "jam_hold_ds": "jamHoldDs",
    "impulse_thresh_half_db": "impulseThreshHalfDb", "min_blob_ms": "minBlobMs", "max_gap_ms": "maxGapMs",
    "flat_min_ms": "flatMinMs", "cont_min_ms": "contMinMs", "fm_min_bw_hz10": "fmMinBwHz10",
    "burst_min_impulses": "burstMinImpulses", "train_min_pulses": "trainMinPulses",
    "burst_max_gap_ms": "burstMaxGapMs", "impulse_min_half_ms": "impulseMinHalfMs",
    "impulse_max_ms": "impulseMaxMs", "train_max_cv_pct": "trainMaxCvPct", "low_batt_pct": "lowBattPct",
    "chirp_max_gap_ms": "chirpMaxGapMs", "reserved": "reserved",
}

# Defaults per node type, exactly as firmware/main/node_profile.c.
CONFIG_DEFAULTS = {
    "usAir": dict(cfg_version=1, flags=0x25, band_frame_ms=1000, duty_on_s=60, duty_off_s=0,
                  detect_thresh_half_db=28, jam_thresh_half_db=12, jam_hold_ds=20, impulse_thresh_half_db=30,
                  min_blob_ms=5, max_gap_ms=4, flat_min_ms=300, cont_min_ms=1000, fm_min_bw_hz10=300,
                  burst_min_impulses=3, train_min_pulses=3, burst_max_gap_ms=200, impulse_min_half_ms=2,
                  impulse_max_ms=10, train_max_cv_pct=15, low_batt_pct=15, chirp_max_gap_ms=120, reserved=0),
    "contactPiezo": dict(cfg_version=1, flags=0x45, band_frame_ms=1000, duty_on_s=60, duty_off_s=0,
                         detect_thresh_half_db=28, jam_thresh_half_db=12, jam_hold_ds=20, impulse_thresh_half_db=30,
                         min_blob_ms=5, max_gap_ms=4, flat_min_ms=300, cont_min_ms=1000, fm_min_bw_hz10=300,
                         burst_min_impulses=3, train_min_pulses=3, burst_max_gap_ms=200, impulse_min_half_ms=2,
                         impulse_max_ms=10, train_max_cv_pct=15, low_batt_pct=15, chirp_max_gap_ms=120, reserved=0),
    "audioAir": dict(cfg_version=1, flags=0x3D, band_frame_ms=1000, duty_on_s=60, duty_off_s=0,
                     detect_thresh_half_db=40, jam_thresh_half_db=12, jam_hold_ds=20, impulse_thresh_half_db=30,
                     min_blob_ms=8, max_gap_ms=0, flat_min_ms=300, cont_min_ms=1000, fm_min_bw_hz10=150,
                     burst_min_impulses=3, train_min_pulses=3, burst_max_gap_ms=200, impulse_min_half_ms=2,
                     impulse_max_ms=10, train_max_cv_pct=15, low_batt_pct=15, chirp_max_gap_ms=120, reserved=0),
}

TEST_KEY = bytes(range(0x00, 0x20))
TEST_ADDR = "C0:FF:EE:12:34:56"


def wire_event_dict(w: proto.WireEvent) -> dict:
    d = {camel: getattr(w, snake) for snake, camel in EVENT_KEYS}
    d["hex"] = w.pack().hex()
    return d


def scenario_vector(s: scenarios.Scenario) -> dict:
    r = scenarios.result(s.name)
    events = []
    for i, ev in enumerate(r.events):
        w = proto.event_from_detection(ev, seq=i + 1, epoch_ms=EPOCH_BASE_MS + proto.rnd(ev.t_start_ms), boot_low=BOOT_COUNT)
        d = wire_event_dict(w)
        d["className"] = C.CLASS_NAMES[ev.cls]
        events.append(d)
    out = {
        "schema": "kernel-sensor-detect-vector/1",
        "scenario": s.name,
        "description": s.description,
        "synthetic": True,
        "sensorType": s.sensor_type,
        "sensorTypeName": SENSOR_TYPE_KEYS[s.sensor_type],
        "seconds": s.seconds,
        "epochBaseMs": EPOCH_BASE_MS,
        "expect": {
            "classes": s.expect_classes,
            "signature": s.expect_signature,
            "jammed": s.expect_jammed,
            "clipped": s.expect_clipped,
        },
        "result": {
            "jammed": r.jammed_ever,
            "clipped": r.clipped_ever,
            "eventCount": len(r.events),
            "healthLog": [[round(t, 3), h] for t, h in r.health_log],
        },
        "events": events,
    }
    if s.rate_window_s:
        n = sum(1 for e in r.events if e.cls == C.IMPULSE_BURST)
        out["rate"] = {"windowS": s.rate_window_s, "bursts": n, "perS": round(n / s.rate_window_s, 6)}
    return out


def _case(kind: str, name: str, fields: dict, data: bytes) -> dict:
    return {"kind": kind, "name": name, "fields": fields, "hex": data.hex()}


def protocol_vectors() -> dict:
    cases = []
    cases.append(_case("adv", "adv_us_test_company", dict(companyId=0xFFFF, proto=1, sensorType=1, lastEventSeq16=0x1234, batt=87),
                       proto.pack_adv(0xFFFF, 1, 0x00011234, 87)))
    cases.append(_case("adv", "adv_contact_batt_unknown", dict(companyId=0xFFFF, proto=1, sensorType=2, lastEventSeq16=0, batt=255),
                       proto.pack_adv(0xFFFF, 2, 0, 255)))
    di = dict(proto_major=1, proto_minor=0, sensor_type=1, hw_rev=1, fw_major=0, fw_minor=1, fw_patch=0, n_bands=18,
              capabilities=0x005F, sample_rate_hz=192000, fft_size=512, hop_size=256, ring_capacity=1920, cfg_version=1)
    cases.append(_case("deviceInfo", "device_info_us_air", {
        "protoMajor": 1, "protoMinor": 0, "sensorType": 1, "hwRev": 1, "fwMajor": 0, "fwMinor": 1, "fwPatch": 0,
        "nBands": 18, "capabilities": 0x005F, "sampleRateHz": 192000, "fftSize": 512, "hopSize": 256,
        "ringCapacity": 1920, "cfgVersion": 1}, proto.pack_device_info(**di)))
    for node, cfg in CONFIG_DEFAULTS.items():
        cases.append(_case("config", f"config_default_{node}", {CONFIG_KEYS[k]: v for k, v in cfg.items()}, proto.pack_config(**cfg)))
    us_edges = [proto.q_hz10(e) for e in C.US_AIR_SPEC.band_edges_hz]
    cases.append(_case("bandTable", "band_table_us_air", {"nBands": len(us_edges) - 1, "edgesHz10": us_edges}, proto.pack_band_table(us_edges)))
    au_edges = [proto.q_hz10(e) for e in C.AUDIO_AIR_SPEC.band_edges_hz]
    cases.append(_case("bandTable", "band_table_audio_air", {"nBands": len(au_edges) - 1, "edgesHz10": au_edges}, proto.pack_band_table(au_edges)))

    # A real band frame from the 22 kHz scenario, plus a full 24-band frame.
    s = scenarios.by_name("us_rat_22k")
    r = scenarios.result(s.name)
    bf = r.band_frames[1]
    t = EPOCH_BASE_MS + proto.rnd(bf.t_ms)
    bands = [proto.q_half_db(v) for v in bf.bands_db]
    flags = proto.band_flags(bf.flags, time_valid=True)
    fields = dict(seq=2, tStartS=t // 1000, tStartMs=t % 1000, frameMs=proto.rnd(bf.frame_ms), flags=flags, nBands=len(bands),
                  noiseFloorDeciDbfs=proto.q_deci_db(bf.noise_floor_dbfs), peakHz10=proto.q_hz10(bf.peak_hz),
                  peakDeciDbfs=proto.q_deci_db(bf.peak_dbfs), jamBandMask=bf.jam_mask, bandsHalfDb=bands)
    cases.append(_case("bandFrame", "band_frame_us_rat_22k", fields, proto.pack_band_frame(
        fields["seq"], fields["tStartS"], fields["tStartMs"], fields["frameMs"], flags, fields["noiseFloorDeciDbfs"],
        fields["peakHz10"], fields["peakDeciDbfs"], bf.jam_mask, bands)))
    full = [min(255, 10 * i) for i in range(24)]
    fields = dict(seq=0xFFFFFFFE, tStartS=1767225600, tStartMs=999, frameMs=1000, flags=0x03, nBands=24,
                  noiseFloorDeciDbfs=-1234, peakHz10=4000, peakDeciDbfs=-321, jamBandMask=0x000020, bandsHalfDb=full)
    cases.append(_case("bandFrame", "band_frame_24_bands_jammed", fields, proto.pack_band_frame(
        0xFFFFFFFE, 1767225600, 999, 1000, 0x03, -1234, 4000, -321, 0x000020, full)))

    # Events: one per scenario class plus edge cases.
    seen = set()
    for sc in scenarios.SCENARIOS:
        if sc.name == "contact_larva_bursts":
            continue  # long; its events are in detect_contact_larva_bursts.json
        rr = scenarios.result(sc.name)
        for ev in rr.events[:1]:
            if ev.cls in seen:
                continue
            seen.add(ev.cls)
            w = proto.event_from_detection(ev, seq=100 + ev.cls, epoch_ms=EPOCH_BASE_MS + proto.rnd(ev.t_start_ms), boot_low=BOOT_COUNT)
            d = wire_event_dict(w)
            cases.append(_case("event", f"event_{C.CLASS_NAMES[ev.cls]}_{sc.name}", {k: v for k, v in d.items() if k != "hex"}, w.pack()))
    edge = proto.WireEvent(seq=0xFFFFFFFF, t_start_s=12345, t_start_ms=7, duration_ms=65535, event_class=6, flags=0x04,
                           peak_hz10=65535, min_hz10=0, max_hz10=65535, slope_dhz_per_ms=-32767, snr_half_db=255,
                           peak_dbfs=-128, impulses=255, harmonics=0, rep_rate_chz=0, ipi_cv_pct=255, boot_low=3)
    d = wire_event_dict(edge)
    cases.append(_case("event", "event_untimed_saturated", {k: v for k, v in d.items() if k != "hex"}, edge.pack()))

    st = [
        ("status_ok_session", dict(health=proto.HB_SESSION_ACTIVE | proto.HB_TIME_VALID | proto.HB_AUTHENTICATED, battPct=92, battMv=4010,
                                   lastSeq=4242, oldestSeq=2323, uptimeS=86400, bootCount=7, surveyRemainingS=0)),
        ("status_jammed_clipped", dict(health=proto.HB_JAMMED | proto.HB_CLIPPED | proto.HB_TIME_VALID, battPct=50, battMv=3700,
                                       lastSeq=10, oldestSeq=1, uptimeS=120, bootCount=1, surveyRemainingS=0)),
        ("status_survey_low_batt", dict(health=proto.HB_SURVEY_NEEDED | proto.HB_SURVEY_ACTIVE | proto.HB_LOW_BATTERY, battPct=9, battMv=3350,
                                        lastSeq=0, oldestSeq=0, uptimeS=30, bootCount=65535, surveyRemainingS=270)),
        ("status_fault_unknown_batt", dict(health=proto.HB_SENSOR_FAULT | proto.HB_EVENTS_OVERWRITTEN | proto.HB_WARMING_UP, battPct=255,
                                           battMv=0, lastSeq=0xFFFFFFFF, oldestSeq=0xFFFFF000, uptimeS=1, bootCount=2, surveyRemainingS=0)),
    ]
    for name, f in st:
        cases.append(_case("status", name, f, proto.pack_status(f["health"], f["battPct"], f["battMv"], f["lastSeq"], f["oldestSeq"],
                                                                 f["uptimeS"], f["bootCount"], f["surveyRemainingS"])))

    nonce = proto.app_nonce(TEST_KEY, 1, EPOCH_BASE_MS)
    reqs = [
        ("cp_set_time", dict(opcode=proto.OP_SET_TIME, epochMs=EPOCH_BASE_MS + 1234), proto.cp_set_time(EPOCH_BASE_MS + 1234)),
        ("cp_get_events_since", dict(opcode=proto.OP_GET_EVENTS_SINCE, seq=4242, maxCount=0), proto.cp_get_events_since(4242, 0)),
        ("cp_start_survey", dict(opcode=proto.OP_START_SURVEY, durationS=300), proto.cp_start_survey(300)),
        ("cp_start_session", dict(opcode=proto.OP_START_SESSION, flags=1), proto.cp_start_session(1)),
        ("cp_stop_session", dict(opcode=proto.OP_STOP_SESSION), proto.cp_stop_session()),
        ("cp_request_snippet", dict(opcode=proto.OP_REQUEST_SNIPPET, seq=101), proto.cp_request_snippet(101)),
        ("cp_clear_bond", dict(opcode=proto.OP_CLEAR_BOND), proto.cp_clear_bond()),
        ("cp_auth_challenge", dict(opcode=proto.OP_AUTH_CHALLENGE, nonceHex=nonce.hex()), proto.cp_auth_challenge(nonce)),
        ("cp_auth_response", dict(opcode=proto.OP_AUTH_RESPONSE, proofHex=(b"\xab" * 32).hex()), proto.cp_auth_response(b"\xab" * 32)),
    ]
    for name, f, b in reqs:
        cases.append(_case("cpRequest", name, f, b))

    ev_payload = proto.cp_events_since_payload(12, 4243, 4254, 2323)
    nn = proto.node_nonce(TEST_KEY, BOOT_COUNT, 1, 123456789)
    np_ = proto.node_proof(TEST_KEY, nonce, nn, TEST_ADDR)
    meta = proto.snippet_meta(101, 64, 96, 1800, 3000, 13, 32, 3)
    resps = [
        ("cp_resp_set_time_ok", dict(reqOpcode=proto.OP_SET_TIME, status=0, payloadHex=""), proto.cp_response(proto.OP_SET_TIME, 0)),
        ("cp_resp_events_since", dict(reqOpcode=proto.OP_GET_EVENTS_SINCE, status=0, payloadHex=ev_payload.hex(),
                                      count=12, firstSeq=4243, lastSeq=4254, oldestSeq=2323),
         proto.cp_response(proto.OP_GET_EVENTS_SINCE, 0, ev_payload)),
        ("cp_resp_auth_challenge", dict(reqOpcode=proto.OP_AUTH_CHALLENGE, status=0, payloadHex=(nn + np_).hex(),
                                        nodeNonceHex=nn.hex(), nodeProofHex=np_.hex()),
         proto.cp_response(proto.OP_AUTH_CHALLENGE, 0, nn + np_)),
        ("cp_resp_auth_failed", dict(reqOpcode=proto.OP_AUTH_RESPONSE, status=proto.ST_AUTH_FAILED, payloadHex=""),
         proto.cp_response(proto.OP_AUTH_RESPONSE, proto.ST_AUTH_FAILED)),
        ("cp_resp_not_authenticated", dict(reqOpcode=proto.OP_GET_EVENTS_SINCE, status=proto.ST_NOT_AUTHENTICATED, payloadHex=""),
         proto.cp_response(proto.OP_GET_EVENTS_SINCE, proto.ST_NOT_AUTHENTICATED)),
        ("cp_resp_snippet_meta", dict(reqOpcode=proto.OP_REQUEST_SNIPPET, status=0, payloadHex=meta.hex(), eventSeq=101, rows=64,
                                      cols=96, fLoHz10=1800, fHiHz10=3000, colDeciMs=13, tileCount=32, colsPerTile=3),
         proto.cp_response(proto.OP_REQUEST_SNIPPET, 0, meta)),
    ]
    for name, f, b in resps:
        cases.append(_case("cpResponse", name, f, b))
    cases.append(_case("eventsDone", "cp_events_done", dict(count=12, lastSeq=4254), proto.cp_events_done(12, 4254)))
    cols = [bytes((r * 3 + c) % 256 for r in range(4)) for c in range(2)]
    cases.append(_case("snippetTile", "snippet_tile_small", dict(eventSeq=101, tileIndex=5, tileCount=32, col0=15, nCols=2, rows=4,
                                                               dataHex=b"".join(cols).hex()), proto.snippet_tile(101, 5, 32, 15, cols)))
    return {
        "schema": "kernel-sensor-protocol-vectors/1",
        "protocol": {"major": proto.PROTO_MAJOR, "minor": proto.PROTO_MINOR},
        "serviceUuid": proto.SERVICE_UUID,
        "characteristics": {
            "deviceInfo": proto.UUID_DEVICE_INFO, "config": proto.UUID_CONFIG, "bandTable": proto.UUID_BAND_TABLE,
            "bandFrame": proto.UUID_BAND_FRAME, "event": proto.UUID_EVENT, "status": proto.UUID_STATUS,
            "controlPoint": proto.UUID_CONTROL_POINT, "snippet": proto.UUID_SNIPPET,
        },
        "lengths": {"adv": proto.ADV_LEN, "deviceInfo": proto.DEVICE_INFO_LEN, "config": proto.CONFIG_LEN,
                    "event": proto.EVENT_LEN, "status": proto.STATUS_LEN, "bandFrameHeader": proto.BAND_FRAME_HDR_LEN},
        "cases": cases,
    }


RFC4231 = [
    ("tc1", bytes([0x0B] * 20), b"Hi There"),
    ("tc2", b"Jefe", b"what do ya want for nothing?"),
    ("tc3", bytes([0xAA] * 20), bytes([0xDD] * 50)),
    ("tc4", bytes(range(1, 26)), bytes([0xCD] * 50)),
    ("tc6", bytes([0xAA] * 131), b"Test Using Larger Than Block-Size Key - Hash Key First"),
    ("tc7", bytes([0xAA] * 131),
     b"This is a test using a larger than block-size key and a larger than block-size data. "
     b"The key needs to be hashed before being used by the HMAC algorithm."),
]


def auth_vectors() -> dict:
    rfc = [{"name": n, "keyHex": k.hex(), "dataHex": d.hex(), "hmacHex": proto.hmac256(k, d).hex()} for n, k, d in RFC4231]
    hs = []
    for i, (key, addr, boot, ctr, up, actr, aep) in enumerate([
        (TEST_KEY, TEST_ADDR, BOOT_COUNT, 1, 123456789, 1, EPOCH_BASE_MS),
        (bytes([0xA5] * 32), "AA:BB:CC:DD:EE:FF", 65535, 0xFFFFFFFF, 2**63, 2**40, EPOCH_BASE_MS + 86_400_000),
    ]):
        an = proto.app_nonce(key, actr, aep)
        nn = proto.node_nonce(key, boot, ctr, up)
        hs.append({
            "name": f"handshake_{i + 1}",
            "keyHex": key.hex(),
            "address": addr,
            "bootCount": boot,
            "nodeCounter": ctr,
            "uptimeUs": up,
            "appCounter": actr,
            "appEpochMs": aep,
            "appNonceHex": an.hex(),
            "nodeNonceHex": nn.hex(),
            "nodeProofHex": proto.node_proof(key, an, nn, addr).hex(),
            "appProofHex": proto.app_proof(key, an, nn, addr).hex(),
            "fingerprint": proto.key_fingerprint(key),
        })
    return {
        "schema": "kernel-sensor-auth-vectors/1",
        "labels": {"node": proto.LABEL_NODE.decode(), "app": proto.LABEL_APP.decode(),
                   "nodeNonce": proto.LABEL_NODE_NONCE.decode(), "appNonce": proto.LABEL_APP_NONCE.decode()},
        "rfc4231": rfc,
        "handshakes": hs,
    }


def qr_vectors() -> dict:
    k1 = TEST_KEY
    k2 = bytes([0xFB] * 32)  # base64url uses '-' and '_' here
    valid = []
    for addr, key, st in [(TEST_ADDR, k1, 1), ("AA:BB:CC:DD:EE:FF", k2, 2), ("01:23:45:67:89:AB", k1, 3), ("01:23:45:67:89:AB", k2, 4)]:
        valid.append({"payload": proto.qr_payload(addr, key, st), "address": addr, "keyHex": key.hex(),
                      "sensorType": SENSOR_TYPE_KEYS[st], "fingerprint": proto.key_fingerprint(key)})
    padded = base64.urlsafe_b64encode(k1).decode()
    valid.append({"payload": f"kernel:sensor:v1:{TEST_ADDR}:{padded}:audio_air", "address": TEST_ADDR, "keyHex": k1.hex(),
                  "sensorType": "audioAir", "fingerprint": proto.key_fingerprint(k1)})
    valid.append({"payload": f"kernel:sensor:v1:{TEST_ADDR.lower()}:{padded.rstrip('=')}:us_air", "address": TEST_ADDR,
                  "keyHex": k1.hex(), "sensorType": "usAir", "fingerprint": proto.key_fingerprint(k1)})
    good_key = base64.urlsafe_b64encode(k1).decode().rstrip("=")
    short_key = base64.urlsafe_b64encode(bytes(16)).decode().rstrip("=")
    invalid = [
        {"payload": "", "reason": "empty"},
        {"payload": f"kernel:sensor:v2:{TEST_ADDR}:{good_key}:us_air", "reason": "version"},
        {"payload": f"kernel:sensr:v1:{TEST_ADDR}:{good_key}:us_air", "reason": "prefix"},
        {"payload": f"kernel:sensor:v1:C0:FF:EE:12:34:{good_key}:us_air", "reason": "fields"},
        {"payload": f"kernel:sensor:v1:C0:FF:EE:12:34:5G:{good_key}:us_air", "reason": "address"},
        {"payload": f"kernel:sensor:v1:{TEST_ADDR}:{short_key}:us_air", "reason": "keyLength"},
        {"payload": f"kernel:sensor:v1:{TEST_ADDR}:{good_key[:-1]}*:us_air", "reason": "keyEncoding"},
        {"payload": f"kernel:sensor:v1:{TEST_ADDR}:{good_key}:ultrasonic", "reason": "type"},
        {"payload": f"kernel:sensor:v1:{TEST_ADDR}:{good_key}:us_air:extra", "reason": "fields"},
        {"payload": f" kernel:sensor:v1:{TEST_ADDR}:{good_key}:us_air", "reason": "prefix"},
    ]
    return {"schema": "kernel-sensor-qr-vectors/1", "valid": valid, "invalid": invalid}


def halfband_c() -> str:
    taps = dsp.halfband_taps()
    lines = [
        "/* GENERATED by firmware/reference (python -m kernel_ref.export). Do not edit.",
        f" * {dsp.HALFBAND_TAPS}-tap Kaiser (beta {dsp.HALFBAND_BETA}) half-band low-pass, cutoff fs/4, unity DC gain. */",
        '#include "kernel_detect.h"',
        "",
        "const float kd_halfband_taps[KD_PDM_HB_TAPS] = {",
    ]
    for i in range(0, len(taps), 4):
        lines.append("    " + " ".join(f"{t:.9e}f," for t in taps[i: i + 4]))
    lines.append("};")
    return "\n".join(lines) + "\n"


def write_all(only: list[str] | None = None) -> list[Path]:
    VECTORS.mkdir(exist_ok=True)
    written = []

    def dump(path: Path, obj) -> None:
        path.write_text(json.dumps(obj, indent=1, sort_keys=False) + "\n", encoding="utf-8", newline="\n")
        written.append(path)

    for s in scenarios.SCENARIOS:
        if only and s.name not in only:
            continue
        dump(VECTORS / f"detect_{s.name}.json", scenario_vector(s))
    if not only:
        dump(VECTORS / "protocol_v1.json", protocol_vectors())
        dump(VECTORS / "auth_v1.json", auth_vectors())
        dump(VECTORS / "qr_v1.json", qr_vectors())
        HALFBAND_C.write_text(halfband_c(), encoding="utf-8", newline="\n")
        written.append(HALFBAND_C)
    return written


if __name__ == "__main__":
    for p in write_all(sys.argv[1:] or None):
        print(p.relative_to(ROOT.parent))
