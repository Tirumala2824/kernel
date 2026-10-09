"""Prepare downloaded recordings: 16 kHz mono PCM16, packed per split.

For every selected clip:
  1. read the WAV (PCM16), take channel 0 if multi-channel
  2. hash the raw PCM frames (same method as TV-PAVC `sha256_pcm`), and check
     the hash against the TV-PAVC manifest for field clips
  3. resample to 16 kHz with a polyphase FIR (scipy resample_poly, Kaiser
     window) and re-quantise to PCM16, the format the app's analyzer receives
  4. append to data/prepared/<split>.pcm16 (raw little-endian int16) and
     record offset/length in data/prepared/<split>.csv

Leakage guard: a PCM hash may appear in one split only. Splits are processed
in the order test, val, challenge_hardneg, challenge_pos, train, so a
duplicate is always dropped from the later split, which means train loses it
and the evaluation sets are never changed.

Clips shorter than one 2 s window are dropped (the app always analyses one
2 s capture).

Usage:
    uv run python -I -m kernel_train.prep
"""

from __future__ import annotations

import csv
import hashlib
import json
import math
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import resample_poly

from kernel_train.treevibes import DATA, RAW_DIR, Item, read_selection

PREP_DIR = DATA / "prepared"
TARGET_SR = 16_000
# One app capture: ScanEngineHost.TARGET_DURATION_MS = 2000 ms at 16 kHz.
WINDOW_SAMPLES = 32_000
SPLIT_ORDER = ("test", "val", "challenge_hardneg", "challenge_pos", "train")


@dataclass
class Clip:
    split: str
    relative_path: str
    label: str
    group: str
    domain: str  # field | lab | own
    offset: int
    length: int
    source_rate: int
    rms_dbfs: float
    pcm_sha256: str


def to_16k_pcm16(pcm: np.ndarray, rate: int) -> np.ndarray:
    """int16 mono at `rate` -> int16 mono at 16 kHz (identity if already 16 kHz)."""
    if rate == TARGET_SR:
        return pcm.astype(np.int16, copy=True)
    g = math.gcd(rate, TARGET_SR)
    y = resample_poly(pcm.astype(np.float64) / 32768.0, TARGET_SR // g, rate // g)
    return np.clip(np.floor(y * 32768.0 + 0.5), -32768, 32767).astype(np.int16)


def read_pcm16(path: Path) -> tuple[np.ndarray, int]:
    x, rate = sf.read(str(path), dtype="int16", always_2d=True)
    return np.ascontiguousarray(x[:, 0]), int(rate)


def rms_dbfs(pcm: np.ndarray) -> float:
    x = pcm.astype(np.float64) / 32768.0
    r = math.sqrt(float(np.mean(x * x))) if x.size else 0.0
    return 20.0 * math.log10(r) if r > 0 else -200.0


def write_index(path: Path, clips: list[Clip]) -> None:
    with open(path, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(list(Clip.__dataclass_fields__))
        for c in clips:
            w.writerow([getattr(c, f) for f in Clip.__dataclass_fields__])


def read_index(split: str, prep_dir: Path = PREP_DIR) -> list[Clip]:
    with open(prep_dir / f"{split}.csv", encoding="utf-8") as fh:
        out = []
        for r in csv.DictReader(fh):
            out.append(
                Clip(
                    r["split"], r["relative_path"], r["label"], r["group"], r["domain"], int(r["offset"]),
                    int(r["length"]), int(r["source_rate"]), float(r["rms_dbfs"]), r["pcm_sha256"],
                )
            )
        return out


def open_pcm(split: str, prep_dir: Path = PREP_DIR) -> np.ndarray:
    path = prep_dir / f"{split}.pcm16"
    return np.memmap(path, dtype="<i2", mode="r")


def _treevibes_domain(it: Item) -> str:
    return "lab" if it.group == "lab" else "field"


def prepare(items: list[Item], raw_dir: Path = RAW_DIR, prep_dir: Path = PREP_DIR,
            split_order: tuple[str, ...] = SPLIT_ORDER, domain_of=_treevibes_domain) -> dict:
    prep_dir.mkdir(parents=True, exist_ok=True)
    seen: dict[str, str] = {}  # pcm hash -> split
    report: dict = {"dropped": Counter(), "kept": Counter(), "hash_mismatch": 0, "source_rates": Counter()}
    by_split: dict[str, list[Item]] = {s: [] for s in split_order}
    for it in items:
        by_split[it.split].append(it)

    for split in split_order:
        clips: list[Clip] = []
        offset = 0
        with open(prep_dir / f"{split}.pcm16", "wb") as out:
            for it in by_split[split]:
                path = raw_dir / it.relative_path
                if not path.exists():
                    report["dropped"][f"{split}:missing"] += 1
                    continue
                pcm, rate = read_pcm16(path)
                h = hashlib.sha256(pcm.astype("<i2").tobytes()).hexdigest()
                if it.sha256_pcm and h != it.sha256_pcm:
                    report["hash_mismatch"] += 1
                if h in seen:
                    report["dropped"][f"{split}:duplicate_of_{seen[h]}"] += 1
                    continue
                seen[h] = split
                y = to_16k_pcm16(pcm, rate)
                if y.size < WINDOW_SAMPLES:
                    report["dropped"][f"{split}:shorter_than_2s"] += 1
                    continue
                out.write(y.astype("<i2").tobytes())
                domain = domain_of(it)
                clips.append(Clip(split, it.relative_path, it.label, it.group, domain, offset, int(y.size), rate,
                                  round(rms_dbfs(y), 2), h))
                offset += int(y.size)
                report["kept"][f"{split}:{it.label}"] += 1
                report["source_rates"][str(rate)] += 1
        write_index(prep_dir / f"{split}.csv", clips)
        print(f"{split}: {len(clips)} clips, {offset / TARGET_SR / 3600:.2f} h", flush=True)

    summary = {k: dict(v) if isinstance(v, Counter) else v for k, v in report.items()}
    (prep_dir / "prep_report.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return summary


if __name__ == "__main__":
    import argparse

    ap = argparse.ArgumentParser()
    ap.add_argument("--domains", default="field,lab",
                    help="comma list of TreeVibes domains to include (kernel-proxy-0.1 used 'field')")
    a = ap.parse_args()
    keep = set(a.domains.split(","))
    selected = [it for it in read_selection() if _treevibes_domain(it) in keep]
    print(json.dumps(prepare(selected), indent=2))
