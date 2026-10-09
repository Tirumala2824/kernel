"""Exact numpy port of the app's Kotlin log-mel front end.

Source of truth: audio-ai/android/src/main/kotlin/com/kernel/audio_ai/LogMel.kt.
Parity is proven by tests/test_logmel_parity.py against golden fixtures that
the Kotlin unit test LogMelGoldenFixtureTest writes to tests/fixtures/logmel/.

Conventions copied verbatim from the Kotlin code (change both or neither):
- periodic Hann window: 0.5 - 0.5 * cos(2*pi*n / winLength)
- each frame = winLength samples starting at f * hopLength, windowed, then
  zero-padded to nFft (no centre / reflect padding)
- frame count = 0 if n < winLength else 1 + (n - winLength) // hopLength
- magnitude spectrum |X[k]|, k = 0..nFft/2; power = 2 squares it
- HTK mel scale 1127 * ln(1 + f / 700); nMels + 2 edges equally spaced in mel
  between fMin and fMax; triangular weights max(0, min(up, down)) evaluated
  at each bin's mel value; DC bin weight forced to 0; no area normalisation
- out = ln(sum_k w[m, k] * spec[k] + logOffset), computed in float64 and
  stored as float32, frame-major [frames, nMels]
"""

from __future__ import annotations

from dataclasses import asdict, dataclass

import numpy as np


@dataclass(frozen=True)
class LogMelConfig:
    sample_rate: int
    n_fft: int
    win_length: int
    hop_length: int
    n_mels: int
    f_min: float
    f_max: float
    log_offset: float
    power: float  # 1.0 magnitude, 2.0 power

    def __post_init__(self) -> None:
        # Same validation as LogMelConfig.init in Kotlin.
        if self.sample_rate <= 0:
            raise ValueError("sampleRate must be positive")
        if self.n_fft < 2 or (self.n_fft & (self.n_fft - 1)) != 0:
            raise ValueError("nFft must be a power of two")
        if not 1 <= self.win_length <= self.n_fft:
            raise ValueError("winLength must be in 1..nFft")
        if self.hop_length <= 0:
            raise ValueError("hopLength must be positive")
        if self.n_mels <= 0:
            raise ValueError("nMels must be positive")
        if not (0.0 <= self.f_min < self.f_max <= self.sample_rate / 2.0):
            raise ValueError("need 0 <= fMin < fMax <= sampleRate / 2")
        if self.log_offset <= 0.0:
            raise ValueError("logOffset must be positive")
        if self.power not in (1.0, 2.0):
            raise ValueError("power must be 1.0 or 2.0")

    def as_dict(self) -> dict:
        return asdict(self)


# LogMelConfig.PROVISIONAL in Kotlin (docs/decisions-log.md #18).
PROVISIONAL = LogMelConfig(
    sample_rate=16_000,
    n_fft=512,
    win_length=400,
    hop_length=160,
    n_mels=64,
    f_min=125.0,
    f_max=7_500.0,
    log_offset=0.001,
    power=1.0,
)


def hz_to_mel(hz: np.ndarray | float) -> np.ndarray | float:
    return 1127.0 * np.log(1.0 + np.asarray(hz, dtype=np.float64) / 700.0)


def mel_to_hz(mel: np.ndarray | float) -> np.ndarray | float:
    return 700.0 * (np.exp(np.asarray(mel, dtype=np.float64) / 1127.0) - 1.0)


def periodic_hann(length: int) -> np.ndarray:
    n = np.arange(length, dtype=np.float64)
    return 0.5 - 0.5 * np.cos(2.0 * np.pi * n / length)


def band_edges_mel(cfg: LogMelConfig) -> np.ndarray:
    lo, hi = float(hz_to_mel(cfg.f_min)), float(hz_to_mel(cfg.f_max))
    i = np.arange(cfg.n_mels + 2, dtype=np.float64)
    return lo + (hi - lo) * i / (cfg.n_mels + 1)


def band_upper_edges_hz(cfg: LogMelConfig) -> np.ndarray:
    """Upper edge (Hz) of each band's triangle, used to band-limit a model."""
    return mel_to_hz(band_edges_mel(cfg)[2:])


def mel_weights(cfg: LogMelConfig) -> np.ndarray:
    """[nMels, nFft/2 + 1] triangular weights, exactly as LogMel.buildMelWeights."""
    num_bins = cfg.n_fft // 2 + 1
    edges = band_edges_mel(cfg)
    k = np.arange(num_bins, dtype=np.float64)
    bin_mel = hz_to_mel(k * cfg.sample_rate / cfg.n_fft)
    lower, center, upper = edges[:-2, None], edges[1:-1, None], edges[2:, None]
    up = (bin_mel[None, :] - lower) / (center - lower)
    down = (upper - bin_mel[None, :]) / (upper - center)
    w = np.maximum(0.0, np.minimum(up, down))
    w[:, 0] = 0.0  # DC bin carries no band energy (matches tf.signal and Kotlin).
    return w


def frame_count(num_samples: int, cfg: LogMelConfig) -> int:
    if num_samples < cfg.win_length:
        return 0
    return 1 + (num_samples - cfg.win_length) // cfg.hop_length


class LogMel:
    """Vectorised equivalent of the Kotlin LogMel. Thread-safe, stateless after init."""

    def __init__(self, cfg: LogMelConfig = PROVISIONAL) -> None:
        self.cfg = cfg
        self.window = periodic_hann(cfg.win_length)
        self.weights = mel_weights(cfg)  # [nMels, bins]

    def frame_count(self, num_samples: int) -> int:
        return frame_count(num_samples, self.cfg)

    def mel_spectrum(self, samples: np.ndarray, max_frames_per_chunk: int = 2048) -> np.ndarray:
        """Linear mel energies (before the log), float64 [frames, nMels]."""
        cfg = self.cfg
        x = np.asarray(samples)
        if x.ndim != 1:
            raise ValueError("samples must be mono 1-D")
        frames = self.frame_count(x.size)
        out = np.empty((frames, cfg.n_mels), dtype=np.float64)
        if frames == 0:
            return out
        # Kotlin multiplies the float sample by the double window in double.
        x64 = x.astype(np.float32).astype(np.float64)
        for start in range(0, frames, max_frames_per_chunk):
            stop = min(frames, start + max_frames_per_chunk)
            idx = (np.arange(start, stop)[:, None] * cfg.hop_length) + np.arange(cfg.win_length)[None, :]
            seg = x64[idx] * self.window[None, :]
            spec = np.abs(np.fft.rfft(seg, n=cfg.n_fft, axis=1))
            if cfg.power == 2.0:
                spec = spec * spec
            out[start:stop] = spec @ self.weights.T
        return out

    def log(self, mel: np.ndarray) -> np.ndarray:
        return np.log(mel + self.cfg.log_offset).astype(np.float32)

    def compute(self, samples: np.ndarray) -> np.ndarray:
        """float32 [frames, nMels], frame-major like LogMelResult.values."""
        return self.log(self.mel_spectrum(samples))


def pcm16_to_float(pcm: np.ndarray) -> np.ndarray:
    """Same conversion as ScanAnalyzer: pcm / 32768f, in float32."""
    return np.asarray(pcm, dtype=np.int16).astype(np.float32) / np.float32(32768.0)
