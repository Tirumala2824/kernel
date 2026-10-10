"""Synthetic test signals for the reference detectors.

These are test inputs only (fixed seeds, documented parameters). They are not
recordings and are never shipped or shown as data.
"""

from __future__ import annotations

import math

import numpy as np

NOISE_RMS = 1e-3  # -60 dBFS broadband white noise


def white(fs: int, seconds: float, rms: float = NOISE_RMS, seed: int = 1) -> np.ndarray:
    gen = np.random.default_rng(seed)
    return gen.normal(0.0, rms, int(round(fs * seconds)))


def tukey(n: int, alpha: float = 0.3) -> np.ndarray:
    if n <= 1:
        return np.ones(n)
    w = np.ones(n)
    k = int(alpha * (n - 1) / 2.0)
    if k > 0:
        r = np.arange(k)
        ramp = 0.5 * (1.0 - np.cos(math.pi * r / k))
        w[:k] = ramp
        w[-k:] = ramp[::-1]
    return w


def sweep(fs: int, f0: float, f1: float, ms: float, amp: float) -> np.ndarray:
    """Linear FM call with a Tukey envelope."""
    n = int(round(fs * ms / 1000.0))
    t = np.arange(n) / fs
    dur = n / fs
    phase = 2.0 * math.pi * (f0 * t + 0.5 * (f1 - f0) / dur * t * t)
    return amp * np.sin(phase) * tukey(n, 0.2)


def add_at(x: np.ndarray, sig: np.ndarray, fs: int, t_s: float) -> None:
    i = int(round(t_s * fs))
    j = min(len(x), i + len(sig))
    x[i:j] += sig[: j - i]


def amp_for_bin_snr(snr_db: float, n_fft: int, rms: float = NOISE_RMS) -> float:
    """Sine amplitude whose Hann-window peak bin is `snr_db` above the mean noise bin."""
    noise_bin = 6.0 * rms * rms / n_fft
    return math.sqrt(noise_bin * 10.0 ** (snr_db / 10.0))


def impulse(fs: int, ms: float, freq: float, amp: float, seed: int) -> np.ndarray:
    """Short damped tone burst, the shape of a larval feeding click."""
    n = max(2, int(round(fs * ms / 1000.0)))
    t = np.arange(n) / fs
    gen = np.random.default_rng(seed)
    ph = gen.uniform(0, 2 * math.pi)
    return amp * np.sin(2 * math.pi * freq * t + ph) * tukey(n, 0.3)


def harmonic_tone(fs: int, f0: float, ms: float, amps: list[float], vib_hz: float = 3.0,
                  vib_depth: float = 0.01) -> np.ndarray:
    n = int(round(fs * ms / 1000.0))
    t = np.arange(n) / fs
    inst = f0 * (1.0 + vib_depth * np.sin(2 * math.pi * vib_hz * t))
    phase = 2 * math.pi * np.cumsum(inst) / fs
    y = np.zeros(n)
    for h, a in enumerate(amps, start=1):
        y += a * np.sin(h * phase)
    return y * tukey(n, 0.1)
