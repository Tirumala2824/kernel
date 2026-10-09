"""Smoke tests for the exported TFLite model and the export path."""

from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np
import pytest

from kernel_train.export import ALLOWED_OPS, TFLiteRunner, audit, convert
from kernel_train.model import FRAMES, N_MELS, PROXY_MAX_HZ, bands_below, build_classifier, build_export, transfer_weights
from kernel_train.release import parity_input

ROOT = Path(__file__).resolve().parents[1]
VERSION = "kernel-proxy-0.1"
TFLITE = ROOT / "dist" / f"{VERSION}.tflite"
METRICS = ROOT / "dist" / f"{VERSION}.metrics.json"
KERAS = ROOT / "dist" / f"{VERSION}.keras"


@pytest.fixture(scope="module")
def model_bytes() -> bytes:
    return TFLITE.read_bytes()


def test_size_and_ops(model_bytes: bytes):
    assert len(model_bytes) < 5 * 1024 * 1024
    a = audit(model_bytes)
    assert set(a["ops"]) <= ALLOWED_OPS
    assert a["input_shape"] == [1, N_MELS, FRAMES, 1]
    assert a["output_shape"] == [1, 2]


def test_parity_input_reproduces_recorded_output(model_bytes: bytes):
    """Kotlin fixture log-mel -> TFLite: valid probabilities, identical to the release record."""
    p = TFLiteRunner(model_bytes)(parity_input())
    assert p.shape == (1, 2)
    assert np.all(np.isfinite(p)) and np.all(p >= 0) and abs(float(p.sum()) - 1.0) < 1e-5
    recorded = json.loads(METRICS.read_text(encoding="utf-8"))["parity_probe"]
    assert np.allclose(p[0], recorded["tflite_float32"], atol=1e-6)
    assert np.allclose(p[0], recorded["keras"], atol=1e-4)


@pytest.mark.parametrize("value", [math.log(0.001), 0.0, 12.0])
def test_constant_inputs_give_valid_probabilities(model_bytes: bytes, value: float):
    # Digital silence (ln 0.001 everywhere) and extreme levels must not produce NaN/inf.
    x = np.full((1, N_MELS, FRAMES, 1), value, dtype=np.float32)
    p = TFLiteRunner(model_bytes)(x)
    assert np.all(np.isfinite(p)) and abs(float(p.sum()) - 1.0) < 1e-5


def test_untrained_network_converts_with_builtin_ops_only():
    exp = build_export(build_classifier(bands_below(PROXY_MAX_HZ)), temperature=1.3)
    for q in (False, True):
        a = audit(convert(exp, quantize=q))
        assert set(a["ops"]) <= ALLOWED_OPS


def test_proxy_classifier_transfers_to_full_band():
    import keras

    src = keras.models.load_model(KERAS, compile=False)
    dst = build_classifier(N_MELS)
    copied = transfer_weights(src, dst)
    weighted = [l.name for l in dst.layers if l.get_weights()]
    assert sorted(copied) == sorted(weighted)
