"""Per-band log-mel statistics and clip levels of a prepared split.

Usage:
    uv run python -I tools/band_stats.py train
Checks that mel bands above the band limit carry no signal in the 8 kHz
TreeVibes audio (justifies the in-graph crop) and prints clip RMS levels.
"""

from __future__ import annotations

import math
import sys

import numpy as np

from kernel_train.features import Split, eval_batches
from kernel_train.logmel import PROVISIONAL, band_upper_edges_hz
from kernel_train.model import PROXY_MAX_HZ, bands_below

if __name__ == "__main__":
    split = Split.load(sys.argv[1] if len(sys.argv) > 1 else "train")
    acc, n = np.zeros(64), 0
    for i, (x, _, _) in enumerate(eval_batches(split, batch=128)):
        acc += x[..., 0].mean(axis=(0, 2)) * x.shape[0]
        n += x.shape[0]
        if i >= 7:
            break
    mean = acc / n
    edges = band_upper_edges_hz(PROVISIONAL)
    k = bands_below(PROXY_MAX_HZ)
    floor = math.log(PROVISIONAL.log_offset)
    for m in range(0, 64, 3):
        tag = "kept" if m < k else "cropped"
        print(f"band {m:2d} upper {edges[m]:7.0f} Hz mean {mean[m]:7.3f} ({mean[m] - floor:+.2f} over floor) {tag}")
    levels = np.array([c.rms_dbfs for c in split.clips])
    for lab in ("clean", "infested"):
        lv = np.array([c.rms_dbfs for c in split.clips if c.label == lab])
        if lv.size:
            print(f"{lab}: clip RMS dBFS p10 {np.percentile(lv, 10):.1f} median {np.median(lv):.1f} p90 {np.percentile(lv, 90):.1f}")
    print(f"windows used: {n}; all clips median {np.median(levels):.1f} dBFS")
