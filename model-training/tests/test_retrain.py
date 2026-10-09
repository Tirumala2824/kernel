"""retrain.py: dataset ZIP ingestion, item-level split, and a tiny end-to-end run.

The ZIP here is synthetic and built in pytest's tmp_path (test-only). It only
exercises the plumbing; the model it trains is written to tmp_path and is
never released.
"""

from __future__ import annotations

import csv
import io
import zipfile
from pathlib import Path

import numpy as np
import pytest
import soundfile as sf

import retrain
from kernel_train.manifest import parse

COLUMNS = list(retrain.REQUIRED_COLUMNS)


def _wav_bytes(seed: int, infested: bool, rate: int = 16000, seconds: float = 2.2) -> bytes:
    n = int(rate * seconds)
    t = np.arange(n) / rate
    # Deterministic, formula-based test signals (no RNG): a hum plus, for the
    # "infested" class, a decaying click train.
    x = 0.01 * np.sin(2 * np.pi * (180 + 7 * seed) * t)
    if infested:
        k = np.arange(n) % (rate // 7)
        x = x + 0.2 * np.exp(-k / (rate / 400)) * np.sin(2 * np.pi * 2200 * k / rate)
    buf = io.BytesIO()
    sf.write(buf, (x * 32767).astype(np.int16), rate, format="WAV", subtype="PCM_16")
    return buf.getvalue()


def _make_zip(path: Path, sacks_per_label: int = 4, scans_per_sack: int = 3) -> None:
    rows = []
    with zipfile.ZipFile(path, "w") as z:
        sid = 0
        for label in ("clean", "infested"):
            for s in range(sacks_per_label):
                item = f"{label}-sack-{s}"
                for k in range(scans_per_sack):
                    sid += 1
                    name = f"recordings/scan-{sid}.wav"
                    rate = 48000 if k == 0 else 16000  # exercise resampling
                    z.writestr(name, _wav_bytes(sid, label == "infested", rate=rate))
                    rows.append({"scan_id": f"scan-{sid}", "item_id": item, "label": label,
                                 "inspection_id": f"insp-{sid}", "grain_type": "wheat", "sack_material": "jute",
                                 "environment": "store", "notes": "", "wav_filename": name})
        # Rows that must be dropped.
        z.writestr("recordings/unknown.wav", _wav_bytes(999, False))
        rows.append({**rows[0], "scan_id": "scan-unknown", "label": "unknown", "wav_filename": "recordings/unknown.wav"})
        rows.append({**rows[0], "scan_id": "scan-missing", "wav_filename": "recordings/nope.wav"})
        rows.append({**rows[0]})  # duplicate scan_id
        out = io.StringIO()
        w = csv.DictWriter(out, fieldnames=COLUMNS)
        w.writeheader()
        w.writerows(rows)
        z.writestr("manifest.csv", out.getvalue())


def test_select_and_split_by_item(tmp_path: Path):
    zp = tmp_path / "ds.zip"
    _make_zip(zp)
    names = retrain.safe_extract(zp, tmp_path / "raw")
    rows, dropped = retrain.select_rows(retrain.read_manifest(tmp_path / "raw", names), names)
    assert dropped == {"label_unknown": 1, "wav_missing": 1, "duplicate_scan_id": 1}
    assert {r["label"] for r in rows} == {"clean", "infested"}
    assign = retrain.split_by_item(rows, seed=1)
    # Every scan of a sack lands in the same split; each split has both labels.
    for item in {r["item_id"] for r in rows}:
        assert len({assign[r["item_id"]] for r in rows if r["item_id"] == item}) == 1
    for split in ("train", "val", "test"):
        assert {r["label"] for r in rows if assign[r["item_id"]] == split} == {"clean", "infested"}
    assert retrain.split_by_item(rows, seed=1) == assign  # deterministic


def test_too_few_sacks_is_refused(tmp_path: Path):
    zp = tmp_path / "ds.zip"
    _make_zip(zp, sacks_per_label=2)
    names = retrain.safe_extract(zp, tmp_path / "raw")
    rows, _ = retrain.select_rows(retrain.read_manifest(tmp_path / "raw", names), names)
    with pytest.raises(retrain.DatasetError, match="distinct sacks"):
        retrain.split_by_item(rows, seed=1)


def test_zip_path_traversal_is_rejected(tmp_path: Path):
    zp = tmp_path / "evil.zip"
    with zipfile.ZipFile(zp, "w") as z:
        z.writestr("../outside.wav", b"x")
    with pytest.raises(retrain.DatasetError, match="unsafe path"):
        retrain.safe_extract(zp, tmp_path / "raw")
    assert not (tmp_path / "outside.wav").exists()


def test_end_to_end_tiny_run(tmp_path: Path):
    zp = tmp_path / "ds.zip"
    _make_zip(zp)
    dist = tmp_path / "dist"
    retrain.main([str(zp), "--version", "0.0-test", "--epochs", "1", "--steps", "2", "--batch", "8",
                  "--dist", str(dist), "--work", str(tmp_path / "work")])
    m = parse((dist / "kernel-grain-0.0-test.properties").read_text(encoding="utf-8"))
    assert m.validation == "field" and m.experimental is True
    assert m.labels == ["clean", "infested"]
    assert m.note and m.note.startswith("Experimental")
    assert m.meta["meta.base_model"] == "kernel-proxy-0.1"
    assert m.meta["meta.band_limit_hz"] == "7500"
    assert (dist / "kernel-grain-0.0-test.tflite").stat().st_size < 5 * 1024 * 1024
