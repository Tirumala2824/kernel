import base64
import struct

import pytest

from kernel_ref import proto
from kernel_ref.export import TEST_ADDR, TEST_KEY

# Published RFC 4231 HMAC-SHA256 values (sections 4.2-4.8; 4.6 is truncated and omitted).
RFC4231_EXPECTED = {
    "tc1": "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7",
    "tc2": "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843",
    "tc3": "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe",
    "tc4": "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b",
    "tc6": "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54",
    "tc7": "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2",
}


def test_struct_lengths_match_the_spec():
    assert proto.ADV_LEN == 7
    assert proto.DEVICE_INFO_LEN == 22
    assert proto.CONFIG_LEN == 32
    assert proto.EVENT_LEN == 30
    assert proto.STATUS_LEN == 21
    assert proto.BAND_FRAME_HDR_LEN == 23
    assert proto.BAND_FRAME_HDR_LEN + 24 == 47
    assert struct.calcsize(proto.SNIPPET_META_FMT) == 14
    assert struct.calcsize(proto.SNIPPET_TILE_HDR_FMT) == 8


def test_event_round_trip_and_trailing_bytes():
    w = proto.WireEvent(5, 1767225601, 501, 39, 1, 1, 5410, 4587, 5715, -3164, 52, -58, 0, 0, 0, 255, 7)
    b = w.pack()
    assert len(b) == 30
    assert proto.WireEvent.unpack(b) == w
    assert proto.WireEvent.unpack(b + b"\x00\x01") == w  # minor versions append fields
    with pytest.raises(ValueError):
        proto.WireEvent.unpack(b[:29])


def test_fixed_point_rounding_is_half_away_from_zero():
    assert proto.q_hz10(25.0) == 3  # 2.5 -> 3, not banker's 2
    assert proto.q_slope(-0.25) == -3
    assert proto.q_half_db(1.25) == 3
    assert proto.q_cv(-1.0) == 255
    assert proto.q_cv(9.0) == 254
    assert proto.q_rate(1000.0) == 0xFFFF


def test_band_frame_layout():
    b = proto.pack_band_frame(1, 2, 3, 1000, 0x03, -1234, 4000, -321, 0xABCDEF, [1, 2, 3])
    assert len(b) == 26
    assert b[20:23] == bytes([0xEF, 0xCD, 0xAB])
    assert b[13] == 3


def test_rfc4231_vectors():
    from kernel_ref.export import RFC4231

    for name, key, data in RFC4231:
        assert proto.hmac256(key, data).hex() == RFC4231_EXPECTED[name]


def test_handshake_is_mutual_and_bound_to_address():
    an = proto.app_nonce(TEST_KEY, 1, 1767225600000)
    nn = proto.node_nonce(TEST_KEY, 7, 1, 123)
    assert len(an) == 16 and len(nn) == 16
    np_ = proto.node_proof(TEST_KEY, an, nn, TEST_ADDR)
    ap = proto.app_proof(TEST_KEY, an, nn, TEST_ADDR)
    assert np_ != ap  # domain-separated labels
    assert proto.node_proof(TEST_KEY, an, nn, "C0:FF:EE:12:34:57") != np_
    assert proto.node_proof(bytes(32), an, nn, TEST_ADDR) != np_
    assert proto.node_nonce(TEST_KEY, 7, 2, 123) != nn  # counter changes every challenge


def test_qr_payload_format():
    q = proto.qr_payload(TEST_ADDR, TEST_KEY, 1)
    parts = q.split(":")
    assert len(parts) == 11
    assert parts[:3] == ["kernel", "sensor", "v1"]
    assert ":".join(parts[3:9]) == TEST_ADDR
    assert len(parts[9]) == 43 and "=" not in parts[9]
    assert base64.urlsafe_b64decode(parts[9] + "=") == TEST_KEY
    assert parts[10] == "us_air"
    assert proto.key_fingerprint(TEST_KEY) == __import__("hashlib").sha256(TEST_KEY).hexdigest()[:8]


def test_uuids_share_one_base():
    for u in (proto.UUID_DEVICE_INFO, proto.UUID_CONFIG, proto.UUID_BAND_TABLE, proto.UUID_BAND_FRAME,
              proto.UUID_EVENT, proto.UUID_STATUS, proto.UUID_CONTROL_POINT, proto.UUID_SNIPPET):
        assert u.endswith(proto.SERVICE_UUID[8:])
    assert proto.SERVICE_UUID == "c7780001-4139-44b2-877d-c537908d6290"
