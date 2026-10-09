"""The exported manifest follows the app's ModelManifest spec exactly.

Spec (lead / audio-ai, 2026-10-10): UTF-8 Java properties, '#' comments only
at line start; required keys version, labels, output, input_layout,
validation, sample_rate=16000, n_fft, win_length, hop_length, n_mels, f_min,
f_max, log_offset, power; optional experimental (default true), note
(required, non-empty, <= 500 chars when validation=proxy), uncertain_below,
meta.*; unknown keys rejected. Input float32 [1, n_mels, F(, 1)] with
F <= 198 for mels_frames; output [1, len(labels)].
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

import numpy as np
import pytest
import tensorflow as tf

from kernel_train.logmel import PROVISIONAL, LogMelConfig
from kernel_train.manifest import (
    OPTIONAL, REQUIRED, Manifest, ManifestError, parse, parse_properties, render,
)

ROOT = Path(__file__).resolve().parents[1]
VERSION = "kernel-proxy-0.1"
PROPS = ROOT / "dist" / f"{VERSION}.properties"
TFLITE = ROOT / "dist" / f"{VERSION}.tflite"
FIXTURE = ROOT.parent / "tests" / "fixtures" / "logmel" / "provisional_2s.json"
MAX_FRAMES = 198  # 2 s capture


@pytest.fixture(scope="module")
def text() -> str:
    return PROPS.read_text(encoding="utf-8")


def _without(text: str, key: str) -> str:
    return "\n".join(l for l in text.splitlines() if not l.startswith(f"{key}=")) + "\n"


def _replace(text: str, key: str, value: str) -> str:
    return re.sub(rf"(?m)^{re.escape(key)}=.*$", f"{key}={value}", text)


def test_proxy_manifest_values(text: str):
    m = parse(text)
    assert m.version == VERSION
    assert m.labels == ["clean", "infested"]
    assert m.output == "probabilities"
    assert m.input_layout == "mels_frames"
    assert m.validation == "proxy"
    assert m.experimental is True
    assert m.uncertain_below == pytest.approx(0.70)
    assert m.logmel == PROVISIONAL
    assert m.note is not None and 0 < len(m.note) <= 500
    assert m.note.startswith("Experimental — trained on TreeVibes (non-grain insect recordings)")
    assert "not validated on grain" in m.note


def test_file_syntax(text: str):
    raw = PROPS.read_bytes()
    raw.decode("ascii")  # non-ASCII is \u-escaped, so UTF-8 and ISO-8859-1 readers agree
    for line in text.splitlines():
        if not line:
            continue
        if line.startswith("#"):
            continue
        assert re.match(r"^[a-z_][a-z0-9_.]*=", line), f"bad line: {line!r}"
        assert " #" not in line.split("=", 1)[1] or line.startswith("note="), "no inline comments"


def test_keys_are_exactly_the_allowed_set(text: str):
    keys = set(parse_properties(text))
    assert set(REQUIRED) <= keys
    extra = keys - set(REQUIRED) - set(OPTIONAL)
    assert all(k.startswith("meta.") for k in extra), extra
    assert {"experimental", "note", "uncertain_below"} <= keys


def test_unknown_key_is_rejected(text: str):
    with pytest.raises(ManifestError, match="unknown keys"):
        parse(text + "threshold=0.5\n")
    with pytest.raises(ManifestError, match="unknown keys"):
        parse(text + "metadata=x\n")  # only the 'meta.' prefix is free-form
    parse(text + "meta.anything=ok\n")


@pytest.mark.parametrize("key", REQUIRED)
def test_every_required_key_is_required(text: str, key: str):
    with pytest.raises(ManifestError):
        parse(_without(text, key))


@pytest.mark.parametrize(
    "key,value",
    [
        ("version", "none"),
        ("labels", "clean,weevil"),
        ("labels", "clean,clean"),
        ("labels", "clean"),
        ("output", "scores"),
        ("input_layout", "mels"),
        ("validation", "lab"),
        ("experimental", "maybe"),
        ("sample_rate", "22050"),
        ("n_fft", "500"),
        ("win_length", "1024"),
        ("f_max", "9000"),
        ("log_offset", "0"),
        ("power", "3"),
        ("uncertain_below", "1.5"),
    ],
)
def test_invalid_values_are_rejected(text: str, key: str, value: str):
    with pytest.raises(ManifestError):
        parse(_replace(text, key, value))


def test_proxy_rules(text: str):
    with pytest.raises(ManifestError, match="experimental"):
        parse(_replace(text, "experimental", "false"))
    with pytest.raises(ManifestError, match="note"):
        parse(_without(text, "note"))
    with pytest.raises(ManifestError, match="note"):
        parse(_replace(text, "note", ""))
    with pytest.raises(ManifestError, match="500"):
        parse(_replace(text, "note", "x" * 501))
    # validation=field may drop the note, and experimental defaults to true.
    m = parse(_without(_without(_replace(text, "validation", "field"), "note"), "experimental"))
    assert m.experimental is True and m.note is None


def test_render_round_trip():
    m = Manifest(version="kernel-test-1", labels=["clean", "uncertain", "infested"], output="logits",
                 input_layout="frames_mels", validation="proxy", logmel=PROVISIONAL, note="Experimental — ü\\x",
                 uncertain_below=0.6, meta={"meta.a": "b"})
    assert parse(render(m)) == m


def test_manifest_matches_the_tflite_tensors(text: str):
    m = parse(text)
    interp = tf.lite.Interpreter(model_path=str(TFLITE))
    (inp,), (out,) = interp.get_input_details(), interp.get_output_details()
    assert inp["dtype"] == np.float32 and out["dtype"] == np.float32
    shape = inp["shape"].tolist()
    assert m.input_layout == "mels_frames"
    assert shape[0] == 1 and shape[1] == m.logmel.n_mels and (len(shape) == 3 or (len(shape) == 4 and shape[3] == 1))
    assert 0 < shape[2] <= MAX_FRAMES
    assert out["shape"].tolist() == [1, len(m.labels)]


def test_manifest_logmel_is_covered_by_the_golden_fixture(text: str):
    """The shipped front end is exactly the config the Kotlin/Python parity fixture proves."""
    c = json.loads(FIXTURE.read_text(encoding="utf-8"))["config"]
    fixture_cfg = LogMelConfig(**{k: (float(v) if isinstance(v, float) else int(v)) for k, v in c.items()})
    assert parse(text).logmel == fixture_cfg


def test_meta_records_provenance_and_artifact_hash(text: str):
    m = parse(text)
    assert m.meta["meta.tflite_sha256"] == hashlib.sha256(TFLITE.read_bytes()).hexdigest()
    assert "CC0" in m.meta["meta.dataset"] and "TreeVibes" in m.meta["meta.dataset"]
    assert "CC BY 4.0" in m.meta["meta.splits"]
