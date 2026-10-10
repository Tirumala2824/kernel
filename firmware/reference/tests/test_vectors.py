"""The exported vectors on disk must equal what the reference produces now.

If one of these fails after an intended algorithm change, re-export with
`uv run python -I -m kernel_ref.export` and re-run the Dart/Kotlin tests.
"""

import json

import pytest

from kernel_ref import export, proto, scenarios


def _load(name):
    return json.loads((export.VECTORS / name).read_text(encoding="utf-8"))


@pytest.mark.parametrize("name", [s.name for s in scenarios.SCENARIOS])
def test_detect_vectors_are_current(name):
    on_disk = _load(f"detect_{name}.json")
    fresh = json.loads(json.dumps(export.scenario_vector(scenarios.by_name(name))))
    assert on_disk == fresh
    assert on_disk["synthetic"] is True
    exp = on_disk["expect"]
    assert on_disk["result"]["jammed"] == exp["jammed"]
    assert on_disk["result"]["clipped"] == exp["clipped"]
    assert [e["className"] for e in on_disk["events"]] == exp["classes"]


def test_detect_vector_events_decode_from_hex():
    for s in scenarios.SCENARIOS:
        for e in _load(f"detect_{s.name}.json")["events"]:
            w = proto.WireEvent.unpack(bytes.fromhex(e["hex"]))
            for snake, camel in export.EVENT_KEYS:
                assert getattr(w, snake) == e[camel]


def test_protocol_vectors_are_current():
    assert _load("protocol_v1.json") == json.loads(json.dumps(export.protocol_vectors()))


def test_auth_and_qr_vectors_are_current():
    assert _load("auth_v1.json") == json.loads(json.dumps(export.auth_vectors()))
    assert _load("qr_v1.json") == json.loads(json.dumps(export.qr_vectors()))


def test_halfband_c_is_current():
    assert export.HALFBAND_C.read_text(encoding="utf-8") == export.halfband_c()


def test_larva_vector_rate_is_possible():
    v = _load("detect_contact_larva_bursts.json")
    assert v["rate"]["bursts"] == 6
    assert v["rate"]["perS"] >= 0.02
