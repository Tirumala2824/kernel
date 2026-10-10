"""Detector configuration and per-node defaults.

Mirrors kd_spec_cfg_t / kd_imp_cfg_t / kd_clip_cfg_t in
firmware/components/kernel_detect/include/kernel_detect.h and the per-node
defaults in firmware/main/node_profile.c. The runtime-tunable subset is the
Config characteristic (docs/sensor-protocol.md section 5.3).
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field, replace

# Event classes (wire codes, docs/sensor-protocol.md section 5.5).
TONAL = 0
FM_SWEEP = 1
FLAT_TONE = 2
IMPULSE_BURST = 3
HARMONIC = 4
PULSED_CHIRP = 5
CONTINUOUS_EMITTER = 6

CLASS_NAMES = {
    TONAL: "tonal",
    FM_SWEEP: "fmSweep",
    FLAT_TONE: "flatTone",
    IMPULSE_BURST: "impulseBurst",
    HARMONIC: "harmonic",
    PULSED_CHIRP: "pulsedChirp",
    CONTINUOUS_EMITTER: "continuousEmitter",
}

# Event flags.
EF_TIME_VALID = 0x01
EF_REGULAR_TRAIN = 0x02
EF_TRUNCATED = 0x04
EF_SNIPPET = 0x08

# Sensor types (wire codes).
SENSOR_US_AIR = 1
SENSOR_CONTACT_PIEZO = 2
SENSOR_CONTACT_ACCEL = 3
SENSOR_AUDIO_AIR = 4


@dataclass(frozen=True)
class ClipConfig:
    level: float = 0.98  # |x| >= level of full scale counts as a clipped sample
    count: int = 3  # clipped samples within one window to raise CLIPPED
    window_ms: float = 100.0
    hold_ms: float = 2000.0


@dataclass(frozen=True)
class FloorConfig:
    quantile: float = 0.05  # running 5 % quantile
    up_db_per_s: float = 0.5  # upward drift limit; downward is (1-q)/q faster
    warmup_ms: float = 1000.0
    warmup_speedup: float = 20.0


@dataclass(frozen=True)
class SpecConfig:
    fs: int
    n_fft: int
    hop: int
    band_edges_hz: tuple[float, ...]
    lo_hz: float
    hi_hz: float
    smooth_frames: int = 3
    detect_thresh_db: float = 14.0
    min_blob_ms: float = 5.0
    max_gap_ms: float = 4.0
    max_jump_hz: float = 1500.0
    max_blob_ms: float = 8000.0
    flat_min_ms: float = 300.0
    cont_min_ms: float = 1000.0
    fm_min_bw_hz: float = 3000.0
    harmonic_search: bool = False
    harmonic_rel_db: float = 3.0  # harmonic bins need detect_thresh - this
    max_harmonics: int = 8
    chirp_grouping: bool = False
    chirp_max_gap_ms: float = 120.0
    chirp_pulse_max_ms: float = 60.0
    chirp_freq_tol: float = 0.15
    chirp_max_cv: float = 0.30
    train_min_pulses: int = 3
    jam_thresh_db: float = 6.0
    jam_hold_ms: float = 2000.0
    jam_miss_penalty: int = 10  # a frame below costs this many frames of credit
    jam_release_ms: float = 5000.0
    jam_occupancy: float = 0.9
    line_block_ms: float = 250.0
    line_neigh_lo: int = 3
    line_neigh_hi: int = 10
    band_frame_ms: float = 1000.0
    floor: FloorConfig = field(default_factory=FloorConfig)


@dataclass(frozen=True)
class ImpulseConfig:
    fs: int = 48000
    block_ms: float = 0.5
    bp_lo_hz: float = 200.0
    bp_hi_hz: float = 10000.0
    thresh_db: float = 15.0
    min_ms: float = 1.0
    max_ms: float = 10.0
    burst_min_impulses: int = 3
    burst_max_gap_ms: float = 200.0
    max_burst_impulses: int = 255
    max_burst_ms: float = 10000.0
    train_min_pulses: int = 3
    train_max_cv: float = 0.15
    jam_thresh_db: float = 6.0
    jam_hold_ms: float = 2000.0
    jam_miss_penalty: int = 10  # a frame below costs this many frames of credit
    jam_release_ms: float = 5000.0
    floor: FloorConfig = field(default_factory=FloorConfig)


def _linear_edges(lo: float, hi: float, step: float) -> tuple[float, ...]:
    n = int(math.floor((hi - lo) / step + 0.5))
    return tuple(lo + i * step for i in range(n + 1))


# US_AIR: SPH0641LU4H-1 at 3.072 MHz -> 192 kSPS, analysis 20-92 kHz.
US_AIR_SPEC = SpecConfig(
    fs=192000,
    n_fft=512,
    hop=256,
    band_edges_hz=_linear_edges(20000.0, 92000.0, 4000.0),
    lo_hz=20000.0,
    hi_hz=92000.0,
)

# AUDIO_AIR: standard PDM mic at 32 kSPS, analysis 100 Hz - 15 kHz.
AUDIO_AIR_SPEC = SpecConfig(
    fs=32000,
    n_fft=512,
    hop=128,
    band_edges_hz=(100.0, 160.0, 250.0, 315.0, 400.0, 500.0, 630.0, 800.0, 1000.0, 1250.0,
                   1600.0, 2000.0, 2500.0, 3150.0, 4000.0, 5000.0, 6300.0, 8000.0, 10000.0,
                   12500.0, 15000.0),
    lo_hz=100.0,
    hi_hz=15000.0,
    smooth_frames=1,
    detect_thresh_db=20.0,
    min_blob_ms=8.0,
    max_gap_ms=0.0,
    max_jump_hz=400.0,
    fm_min_bw_hz=1500.0,
    harmonic_search=True,
    chirp_grouping=True,
)

# CONTACT spectral bands (live view only; the detector is the impulse path).
CONTACT_SPEC = SpecConfig(
    fs=48000,
    n_fft=512,
    hop=256,
    band_edges_hz=(200.0, 250.0, 315.0, 400.0, 500.0, 630.0, 800.0, 1000.0, 1250.0, 1600.0,
                   2000.0, 2500.0, 3150.0, 4000.0, 5000.0, 6300.0, 8000.0, 10000.0),
    lo_hz=200.0,
    hi_hz=10000.0,
    smooth_frames=3,
)

CONTACT_IMPULSE = ImpulseConfig()

DEFAULT_CLIP = ClipConfig()


def with_overrides(cfg, **kw):
    return replace(cfg, **kw)
