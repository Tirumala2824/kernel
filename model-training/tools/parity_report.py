"""Report the actual Python-vs-Kotlin log-mel error on every golden fixture.

Usage:
    uv run python -I tools/parity_report.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np

from kernel_train.logmel import LogMel, LogMelConfig, pcm16_to_float

FIXTURES = Path(__file__).resolve().parents[2] / "tests" / "fixtures" / "logmel"

if __name__ == "__main__":
    for path in sorted(FIXTURES.glob("*.json")):
        d = json.loads(path.read_text(encoding="utf-8"))
        cfg = LogMelConfig(**{k: (float(v) if k in ("f_min", "f_max", "log_offset", "power") else int(v)) for k, v in d["config"].items()})
        exp = np.asarray(d["logmel"], dtype=np.float32).reshape(d["frames"], d["n_mels"])
        got = LogMel(cfg).compute(pcm16_to_float(np.asarray(d["pcm16"], dtype=np.int16)))
        err = np.abs(got.astype(np.float64) - exp.astype(np.float64))
        ulp = np.spacing(np.abs(exp)).astype(np.float64)
        print(
            f"{path.stem}: shape {got.shape} max_abs {err.max():.3e} mean_abs {err.mean():.3e} "
            f"max_ulps {np.max(err / ulp):.1f} exact {np.mean(err == 0) * 100:.2f}% range [{exp.min():.3f}, {exp.max():.3f}]"
        )
