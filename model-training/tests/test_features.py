"""Feature plumbing: batch log-mel, model input layout, resampling, windows."""

from __future__ import annotations

import numpy as np

from kernel_train.features import to_model_input
from kernel_train.logmel import PROVISIONAL, LogMel
from kernel_train.model import PROXY_MAX_HZ, bands_below
from kernel_train.prep import TARGET_SR, WINDOW_SAMPLES, to_16k_pcm16


def _signal(n: int, seed: int) -> np.ndarray:
    t = np.arange(n) / 16000
    k = np.arange(n) % 997
    return (0.2 * np.sin(2 * np.pi * 523 * t) + 0.3 * np.exp(-k / 30) * np.sin(2 * np.pi * 1800 * k / 16000)
            + 0.01 * np.cos(seed * t * 1000)).astype(np.float32)


def test_compute_batch_matches_compute():
    lm = LogMel(PROVISIONAL)
    wins = np.stack([_signal(WINDOW_SAMPLES, s) for s in range(3)])
    batch = lm.compute_batch(wins)
    for i in range(3):
        assert np.max(np.abs(batch[i].astype(np.float64) - lm.compute(wins[i]))) <= 2e-6


def test_model_input_is_mels_frames_like_model_runner():
    # ModelRunner MELS_FRAMES writes for m in mels, for t in frames: logMel[t, m].
    lm = LogMel(PROVISIONAL).compute(_signal(WINDOW_SAMPLES, 1))  # [198, 64]
    x = to_model_input(lm[None])
    assert x.shape == (1, 64, 198, 1) and x.dtype == np.float32
    flat = x.reshape(-1)
    expected = np.array([lm[t, m] for m in range(64) for t in range(198)], dtype=np.float32)
    assert np.array_equal(flat, expected)


def test_two_second_window_is_198_frames():
    assert LogMel(PROVISIONAL).frame_count(WINDOW_SAMPLES) == 198


def test_resample_8k_to_16k_keeps_frequency_and_level():
    n = 8000 * 2
    pcm8 = np.round(0.25 * 32768 * np.sin(2 * np.pi * 1000 * np.arange(n) / 8000)).astype(np.int16)
    y = to_16k_pcm16(pcm8, 8000)
    assert y.size == 2 * n
    spec = np.abs(np.fft.rfft(y[2000:-2000].astype(np.float64)))
    peak_hz = np.argmax(spec) * TARGET_SR / (y.size - 4000)
    assert abs(peak_hz - 1000) < 2
    rms = np.sqrt(np.mean((y[2000:-2000] / 32768.0) ** 2))
    assert abs(rms - 0.25 / np.sqrt(2)) < 0.005


def test_band_limit_is_below_source_nyquist():
    # 8 kHz TreeVibes: every kept band must end at or below 3.8 kHz (< 4 kHz Nyquist).
    from kernel_train.logmel import band_upper_edges_hz

    k = bands_below(PROXY_MAX_HZ)
    edges = band_upper_edges_hz(PROVISIONAL)
    assert k == 47
    assert edges[k - 1] <= 3800 + 1e-6 < edges[k]
