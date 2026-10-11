"""Frontend-only constant-crop regression fixtures; no recognition/accuracy claims.

Run with an inspected pinned upstream directory and NumPy/SciPy. No model is
loaded, no pickle is read, and output belongs only in native test resources.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

parser = argparse.ArgumentParser()
parser.add_argument("upstream", type=Path)
parser.add_argument("output", type=Path)
args = parser.parse_args()
revision = "001425d7fab4b44af5cc571174410f1c78552d0e"
checks = {
    "src/audio.py": "df78b3a6c79840569ac5c7fb073ac390c28de138cf493ba618073931f5975e85",
    "src/__init__.py": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
}
for path, digest in checks.items():
    actual = hashlib.sha256((args.upstream / path).read_bytes()).hexdigest()
    if actual != digest:
        raise ValueError(f"Unverified upstream source: {path}")
sys.path.insert(0, str(args.upstream.resolve()))
import numpy as np
import scipy
from scipy.io import wavfile
from src.audio import audio_quality, crop_offsets, logmel, read_audio, resample

args.output.mkdir(parents=True, exist_ok=True)
report = {
    "notice": "SYNTHETIC frontend-only fixtures; no model inference or species validation",
    "revision": revision,
    "source_sha256": checks,
    "versions": {"numpy": np.__version__, "scipy": scipy.__version__},
    "cases": {},
}
silent_first = np.zeros(64000, dtype=np.int16)
silent_first[32000:] = np.where(np.arange(32000) % 2 == 0, 4096, -4096)
for name, pcm in (("silence16", np.zeros(32000, dtype=np.int16)),
                  ("silent_first16", silent_first)):
    wav = args.output / f"{name}.wav"
    wavfile.write(wav, 16000, pcm)
    sr, mono = read_audio(wav)
    mono.astype("<f4").tofile(args.output / f"{name}.mono.f32")
    waveform = resample(mono, sr)
    offsets = crop_offsets(len(waveform), 5)
    features = np.stack([logmel(waveform, 16000, offset) for offset in offsets])
    features.astype("<f4").tofile(args.output / f"{name}.features.f32")
    ok, reasons = audio_quality(mono)
    entry = {"rate": sr, "samples": len(mono), "offsets": offsets,
             "quality_pass": bool(ok), "quality_reasons": reasons,
             "first_crop_unique": np.unique(features[0]).tolist()}
    report["cases"][name] = entry
    print(name, json.dumps(entry), flush=True)
(args.output / "normalization.json").write_text(json.dumps(report, indent=2) + "\n")
