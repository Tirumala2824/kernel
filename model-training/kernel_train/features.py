"""2 s windows -> log-mel model inputs, with light training augmentation.

Model input layout (manifest `input_layout=mels_frames`): float32
[batch, n_mels=64, frames=198, 1], values = raw ln(mel + log_offset) exactly
as the app's Kotlin LogMel produces them (any normalisation is in-graph).

Augmentation (training only, waveform domain, before the log-mel):
- time shift: a random window start anywhere inside the clip
- gain: uniform -12..+12 dB
- noise mixing (p = 0.5): add a 2 s window from a *clean field training* clip
  at a random SNR of 0..20 dB, which keeps the label. The noise comes only from
  the training split, so nothing leaks into val/test.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from kernel_train.logmel import PROVISIONAL, LogMel, LogMelConfig
from kernel_train.prep import WINDOW_SAMPLES, Clip, open_pcm, read_index

LABEL_INDEX = {"clean": 0, "infested": 1}

GAIN_DB = 12.0
NOISE_P = 0.5
NOISE_SNR_DB = (0.0, 20.0)


def to_model_input(logmel_frames_mels: np.ndarray) -> np.ndarray:
    """[B, frames, mels] (Kotlin/LogMel order) -> [B, mels, frames, 1] (mels_frames)."""
    return np.ascontiguousarray(np.transpose(logmel_frames_mels, (0, 2, 1))[..., None], dtype=np.float32)


@dataclass
class Split:
    name: str
    clips: list[Clip]
    pcm: np.ndarray  # int16 memmap

    @classmethod
    def load(cls, name: str, prep_dir=None) -> "Split":
        kw = {} if prep_dir is None else {"prep_dir": prep_dir}
        return cls(name, read_index(name, **kw), open_pcm(name, **kw))

    def window(self, clip: Clip, start: int) -> np.ndarray:
        a = clip.offset + start
        return np.asarray(self.pcm[a : a + WINDOW_SAMPLES], dtype=np.float32) / np.float32(32768.0)

    def eval_windows(self) -> list[tuple[int, int]]:
        """Non-overlapping 2 s windows from the start of each clip: (clip index, start)."""
        out = []
        for i, c in enumerate(self.clips):
            for s in range(0, c.length - WINDOW_SAMPLES + 1, WINDOW_SAMPLES):
                out.append((i, s))
        return out


def eval_batches(split: Split, batch: int = 128, cfg: LogMelConfig = PROVISIONAL):
    """Yields (x [B,64,198,1], y [B], clip_idx [B]) over every eval window."""
    lm = LogMel(cfg)
    wins = split.eval_windows()
    for i in range(0, len(wins), batch):
        chunk = wins[i : i + batch]
        raw = np.stack([split.window(split.clips[ci], s) for ci, s in chunk])
        y = np.array([LABEL_INDEX[split.clips[ci].label] for ci, _ in chunk], dtype=np.int64)
        yield to_model_input(lm.compute_batch(raw)), y, np.array([ci for ci, _ in chunk])


class TrainSampler:
    """Balanced, augmented batches: 50% clean / 50% infested, and within each
    label an equal share per domain present (TreeVibes: field / lab; lab is a
    few long recordings, so it must not dominate; own data: one domain),
    uniform over clips inside each (label, domain) bucket."""

    def __init__(self, split: Split, seed: int, cfg: LogMelConfig = PROVISIONAL, augment: bool = True):
        self.split = split
        self.rng = np.random.default_rng(seed)
        self.lm = LogMel(cfg)
        self.augment = augment
        self.domains = sorted({c.domain for c in split.clips})
        self.buckets: dict[tuple[str, str], np.ndarray] = {}
        for label in LABEL_INDEX:
            if not any(c.label == label for c in split.clips):
                raise ValueError(f"training split has no '{label}' clips")
            for domain in self.domains:
                idx = np.array([i for i, c in enumerate(split.clips) if c.label == label and c.domain == domain])
                if idx.size:
                    self.buckets[(label, domain)] = idx
        # Noise for mixing: clean clips from the target-like domain (field, or
        # own recordings), else any clean training clip.
        self.noise_clips = np.array(
            [i for i, c in enumerate(split.clips) if c.label == "clean" and c.domain in ("field", "own")]
        )
        if not self.noise_clips.size:
            self.noise_clips = np.array([i for i, c in enumerate(split.clips) if c.label == "clean"])

    def _random_window(self, clip_idx: int) -> np.ndarray:
        c = self.split.clips[clip_idx]
        start = int(self.rng.integers(0, c.length - WINDOW_SAMPLES + 1))
        return self.split.window(c, start).astype(np.float64)

    def _pick(self, label: str) -> int:
        domains = [d for d in self.domains if (label, d) in self.buckets]
        d = domains[int(self.rng.integers(0, len(domains)))]
        pool = self.buckets[(label, d)]
        return int(pool[int(self.rng.integers(0, pool.size))])

    def batch(self, size: int) -> tuple[np.ndarray, np.ndarray]:
        labels = np.array([i % 2 for i in range(size)])
        self.rng.shuffle(labels)
        raw = np.empty((size, WINDOW_SAMPLES), dtype=np.float32)
        for b, y in enumerate(labels):
            ci = self._pick("infested" if y else "clean")
            x = self._random_window(ci)
            if self.augment:
                x *= 10.0 ** (self.rng.uniform(-GAIN_DB, GAIN_DB) / 20.0)
                if self.rng.random() < NOISE_P:
                    ni = int(self.noise_clips[int(self.rng.integers(0, self.noise_clips.size))])
                    if ni != ci:
                        n = self._random_window(ni)
                        rx, rn = np.sqrt(np.mean(x * x)), np.sqrt(np.mean(n * n))
                        if rx > 0 and rn > 0:
                            snr = self.rng.uniform(*NOISE_SNR_DB)
                            x = x + n * (rx / rn) * 10.0 ** (-snr / 20.0)
                np.clip(x, -1.0, 32767.0 / 32768.0, out=x)
            raw[b] = x
        return to_model_input(self.lm.compute_batch(raw)), labels.astype(np.int64)
