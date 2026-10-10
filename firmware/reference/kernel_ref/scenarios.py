"""Synthetic scenarios behind firmware/reference/vectors/detect_*.json.

Each scenario builds a deterministic test signal (fixed seeds), runs the node
pipeline and states what the detector and the phone-side signature pack are
expected to conclude. `expect_signature` is the design intent of the synthetic
call, used by the Dart matcher tests. It is not a field measurement.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from functools import lru_cache
from typing import Callable

import numpy as np

from . import config as C
from . import detect, synth


@dataclass
class Scenario:
    name: str
    sensor_type: int
    description: str
    seconds: float
    build: Callable[[], np.ndarray]
    run: Callable[[np.ndarray], detect.NodeResult]
    expect_classes: list[str] = field(default_factory=list)
    expect_signature: str | None = None
    expect_jammed: bool = False
    expect_clipped: bool = False
    rate_window_s: float | None = None


def _us(x: np.ndarray) -> detect.NodeResult:
    return detect.run_spectral_node(x, C.US_AIR_SPEC, C.DEFAULT_CLIP, highpass=True)


def _audio(x: np.ndarray) -> detect.NodeResult:
    return detect.run_spectral_node(x, C.AUDIO_AIR_SPEC, C.DEFAULT_CLIP, highpass=False)


def _contact(x: np.ndarray) -> detect.NodeResult:
    return detect.run_contact_node(x, C.CONTACT_IMPULSE, C.DEFAULT_CLIP)


US_FS = C.US_AIR_SPEC.fs
AUDIO_FS = C.AUDIO_AIR_SPEC.fs
CONTACT_FS = C.CONTACT_IMPULSE.fs
US_AMP = synth.amp_for_bin_snr(25.0, C.US_AIR_SPEC.n_fft)
US_JAM_AMP = synth.amp_for_bin_snr(30.0, C.US_AIR_SPEC.n_fft)
AUDIO_AMP = synth.amp_for_bin_snr(30.0, C.AUDIO_AIR_SPEC.n_fft)
IMPULSE_AMP = 0.02  # about 30 dB above the band-passed noise floor


def _us_call(f0: float, f1: float, ms: float, seed: int) -> Callable[[], np.ndarray]:
    def build() -> np.ndarray:
        x = synth.white(US_FS, 2.6, seed=seed)
        synth.add_at(x, synth.sweep(US_FS, f0, f1, ms, US_AMP), US_FS, 1.5)
        return x

    return build


def _us_repeller(onset_s: float, seed: int) -> Callable[[], np.ndarray]:
    def build() -> np.ndarray:
        x = synth.white(US_FS, 6.0, seed=seed)
        i0 = int(round(onset_s * US_FS))
        t = np.arange(len(x) - i0) / US_FS
        x[i0:] += US_JAM_AMP * np.sin(2 * math.pi * 40000.0 * t)
        return x

    return build


def _us_clipped() -> np.ndarray:
    x = synth.white(US_FS, 3.0, seed=31)
    i0, i1 = int(1.5 * US_FS), int(2.5 * US_FS)
    t = np.arange(i1 - i0) / US_FS
    x[i0:i1] += 1.6 * np.sin(2 * math.pi * 50000.0 * t)
    return np.clip(x, -1.0, 1.0)


LARVA_BURSTS_S = (12.0, 41.0, 66.0, 97.0, 128.0, 161.0)


def _contact_larva() -> np.ndarray:
    gen = np.random.default_rng(41)
    x = synth.white(CONTACT_FS, 180.0, seed=42)
    for k, tb in enumerate(LARVA_BURSTS_S):
        t = tb
        for j in range(int(gen.integers(4, 8))):
            dur = float(gen.uniform(1.5, 6.0))
            freq = float(gen.uniform(1000.0, 6000.0))
            synth.add_at(x, synth.impulse(CONTACT_FS, dur, freq, IMPULSE_AMP, seed=1000 + 10 * k + j), CONTACT_FS, t)
            t += math.exp(float(gen.uniform(math.log(0.015), math.log(0.18))))
    return x


def _contact_termite() -> np.ndarray:
    gen = np.random.default_rng(51)
    x = synth.white(CONTACT_FS, 4.0, seed=52)
    for j in range(12):
        t = 1.5 + j / 15.0 + float(gen.uniform(-0.001, 0.001))
        synth.add_at(x, synth.impulse(CONTACT_FS, 2.0, 2500.0, IMPULSE_AMP, seed=2000 + j), CONTACT_FS, t)
    return x


def _audio_mosquito() -> np.ndarray:
    x = synth.white(AUDIO_FS, 3.5, seed=61)
    a = AUDIO_AMP
    synth.add_at(x, synth.harmonic_tone(AUDIO_FS, 450.0, 1500.0, [a, 0.7 * a, 0.5 * a, 0.3 * a]), AUDIO_FS, 1.5)
    return x


def _audio_cricket() -> np.ndarray:
    x = synth.white(AUDIO_FS, 3.5, seed=71)
    for c in range(3):
        for p in range(4):
            synth.add_at(x, synth.sweep(AUDIO_FS, 4600.0, 4600.0, 15.0, AUDIO_AMP), AUDIO_FS, 1.5 + 0.6 * c + 0.035 * p)
    return x


SCENARIOS: list[Scenario] = [
    Scenario("us_white_noise", C.SENSOR_US_AIR, "6 s of white noise at -60 dBFS", 6.0,
             lambda: synth.white(US_FS, 6.0, seed=21), _us),
    Scenario("us_rat_22k", C.SENSOR_US_AIR, "near-constant 23.0->21.8 kHz call, 600 ms, 25 dB bin SNR", 2.6,
             _us_call(23000.0, 21800.0, 600.0, 22), _us, ["flatTone"], "rat_22k"),
    Scenario("us_rat_50k", C.SENSOR_US_AIR, "45->58 kHz FM sweep, 40 ms", 2.6,
             _us_call(45000.0, 58000.0, 40.0, 23), _us, ["fmSweep"], "rat_50k"),
    Scenario("us_mouse_70k", C.SENSOR_US_AIR, "64->76 kHz FM sweep, 30 ms", 2.6,
             _us_call(64000.0, 76000.0, 30.0, 24), _us, ["fmSweep"], "mouse_usv"),
    Scenario("us_repeller_40k", C.SENSOR_US_AIR, "stationary 40 kHz repeller tone present from power-on", 6.0,
             _us_repeller(0.0, 25), _us, [], None, expect_jammed=True),
    Scenario("us_repeller_onset", C.SENSOR_US_AIR, "40 kHz repeller switched on at 1.5 s", 6.0,
             _us_repeller(1.5, 26), _us, [], None, expect_jammed=True),
    Scenario("us_clipping", C.SENSOR_US_AIR, "50 kHz tone at 1.6x full scale, 1.5-2.5 s", 3.0,
             _us_clipped, _us, [], None, expect_clipped=True),
    Scenario("contact_white_noise", C.SENSOR_CONTACT_PIEZO, "20 s of white noise", 20.0,
             lambda: synth.white(CONTACT_FS, 20.0, seed=43), _contact),
    Scenario("contact_larva_bursts", C.SENSOR_CONTACT_PIEZO,
             "Mankin-style larval impulses (1.5-6 ms, 1-6 kHz) in 6 bursts of 4-7 with irregular 15-180 ms gaps over 180 s", 180.0,
             _contact_larva, _contact, ["impulseBurst"] * 6, "grain_larva", rate_window_s=180.0),
    Scenario("contact_termite_15hz", C.SENSOR_CONTACT_PIEZO, "12 drumming pulses at 15 Hz (2 ms, 2.5 kHz)", 4.0,
             _contact_termite, _contact, ["impulseBurst"], "termite_drum"),
    Scenario("audio_white_noise", C.SENSOR_AUDIO_AIR, "10 s of white noise", 10.0,
             lambda: synth.white(AUDIO_FS, 10.0, seed=62), _audio),
    Scenario("audio_mosquito", C.SENSOR_AUDIO_AIR, "450 Hz flight tone with 3 overtones, 1.5 s", 3.5,
             _audio_mosquito, _audio, ["harmonic"], "mosquito_wingbeat"),
    Scenario("audio_cricket", C.SENSOR_AUDIO_AIR, "3 chirps of 4 x 15 ms pulses at 4.6 kHz", 3.5,
             _audio_cricket, _audio, ["pulsedChirp"] * 3, "cricket_chirp"),
]


def by_name(name: str) -> Scenario:
    for s in SCENARIOS:
        if s.name == name:
            return s
    raise KeyError(name)


@lru_cache(maxsize=None)
def result(name: str) -> detect.NodeResult:
    """Runs a scenario once per process (export and tests share the result)."""
    s = by_name(name)
    return s.run(s.build())
