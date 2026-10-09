"""Export, verify and evaluate a trained run, then write the dist/ artifacts.

Usage:
    uv run python -I -m kernel_train.release --run runs/proxy-0.1 --version kernel-proxy-0.1

Steps:
1. classifier + fitted temperature -> export model (softmax probabilities)
2. TFLite float32 and dynamic-range int8; op audit (builtin ops only, float32 IO)
3. parity probe: the Kotlin golden fixture's own log-mel values go through
   Keras, TFLite float32 and TFLite int8; the outputs are recorded
4. Keras vs TFLite agreement on every val window
5. metrics of the *TFLite artifacts* on val, test and the challenge sets
6. dist/<version>.tflite + .properties (strict manifest, round-trip checked)
   + .metrics.json + .keras (the classifier, for fine-tuning in retrain.py)

The float32 model ships unless int8 is needed for size. At about 250 KB it is
not, and float32 avoids hybrid-kernel differences between this Python
interpreter and LiteRT 1.4.2 on the phone.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import time
from datetime import date
from pathlib import Path

import numpy as np

import kernel_train  # noqa: F401  (MSVC runtime DLL dir before TF loads)
import keras

from kernel_train.evaluate import predict, summarise, summarise_one_class
from kernel_train.export import TFLiteRunner, audit, convert, save
from kernel_train.features import Split, to_model_input
from kernel_train.logmel import PROVISIONAL, LogMel, pcm16_to_float
from kernel_train.manifest import Manifest
from kernel_train.manifest import write as write_manifest
from kernel_train.model import FRAMES, LABELS, PROXY_MAX_HZ, build_export

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"
FIXTURE = ROOT.parent / "tests" / "fixtures" / "logmel" / "provisional_2s.json"

# Fixed before looking at test results: top-class probability below 0.70
# (i.e. p_infested in (0.30, 0.70)) is shown as UNCERTAIN.
UNCERTAIN_BELOW = 0.70
PROXY_NOTE = "Experimental — trained on TreeVibes (non-grain insect recordings); not validated on grain."
PROXY_META = {
    "meta.dataset": "TreeVibes (Rigakis, Potamitis et al. 2021, doi:10.3390/smartcities4010017), CC0 1.0, "
                    "kaggle.com/datasets/potamitis/treevibes",
    "meta.splits": "TV-PAVC v1 provenance-grouped folds (Ayoub 2026, doi:10.5281/zenodo.21993431), CC BY 4.0",
    "meta.domain": "wood-borer larvae vibrations via contact piezo, 8 kHz source audio; not grain, not a phone mic",
    "meta.band_limit_hz": str(int(PROXY_MAX_HZ)),
    "meta.model_card": "model-training/MODEL_CARD.md",
}


def parity_input() -> np.ndarray:
    """Model input built from the Kotlin fixture's own log-mel output."""
    d = json.loads(FIXTURE.read_text(encoding="utf-8"))
    kotlin = np.asarray(d["logmel"], dtype=np.float32).reshape(d["frames"], d["n_mels"])
    python = LogMel(PROVISIONAL).compute(pcm16_to_float(np.asarray(d["pcm16"], dtype=np.int16)))
    if not np.array_equal(kotlin, python):
        raise RuntimeError("Python log-mel no longer matches the Kotlin fixture; run tests/test_logmel_parity.py")
    if kotlin.shape[0] != FRAMES:
        raise RuntimeError(f"fixture has {kotlin.shape[0]} frames, model expects {FRAMES}")
    return to_model_input(kotlin[None])


def sha256(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def evaluate_artifact(runner: TFLiteRunner, splits: dict[str, Split], log) -> dict:
    out = {}
    for name, split in splits.items():
        t0 = time.time()
        probs, y, clip = predict(runner, split)
        if name.startswith("challenge"):
            out[name] = summarise_one_class(probs, y, split, clip, UNCERTAIN_BELOW)
        else:
            out[name] = summarise(probs, y, clip, split, UNCERTAIN_BELOW)
        out[name]["seconds"] = round(time.time() - t0, 1)
        log(f"  {name}: {len(y)} windows in {out[name]['seconds']} s")
    return out


def release(run: Path, version: str, validation: str, note: str, meta: dict[str, str], splits: dict[str, Split],
            dist: Path = DIST, extra: dict | None = None, log=print) -> dict:
    clf = keras.models.load_model(run / "classifier.keras", compile=False)
    temperature = json.loads((run / "temperature.json").read_text(encoding="utf-8"))["temperature"]
    export_model = build_export(clf, temperature)

    f32, i8 = convert(export_model, quantize=False), convert(export_model, quantize=True)
    audits = {"float32": audit(f32), "int8_dynamic": audit(i8)}
    log(f"audit: {json.dumps(audits)}")

    x0 = parity_input()
    r32, r8 = TFLiteRunner(f32), TFLiteRunner(i8)
    probe = {"keras": np.asarray(export_model(x0, training=False))[0].tolist(),
             "tflite_float32": r32(x0)[0].tolist(), "tflite_int8": r8(x0)[0].tolist()}
    t0 = time.perf_counter()
    for _ in range(50):
        r32(x0)
    probe["tflite_float32_ms_per_inference_this_pc"] = round((time.perf_counter() - t0) / 50 * 1000, 2)
    log(f"parity probe: {json.dumps(probe)}")

    # Keras vs TFLite float32 agreement on all val windows.
    val = splits["val"]
    pk, _, _ = predict(lambda x: np.asarray(export_model.predict(x, batch_size=128, verbose=0)), val)
    pt, _, _ = predict(r32, val)
    agreement = {"val_windows": int(pk.shape[0]), "max_abs_prob_diff": float(np.abs(pk - pt).max()),
                 "argmax_agreement": float(np.mean(pk.argmax(1) == pt.argmax(1)))}
    log(f"keras vs tflite: {json.dumps(agreement)}")

    log("evaluating float32 artifact")
    m32 = evaluate_artifact(r32, splits, log)
    log("evaluating int8 artifact")
    m8 = evaluate_artifact(r8, {k: v for k, v in splits.items() if k in ("val", "test")}, log)

    dist.mkdir(parents=True, exist_ok=True)
    tfl_path = dist / f"{version}.tflite"
    save(f32, tfl_path)
    manifest = Manifest(
        version=version, labels=list(LABELS), output="probabilities", input_layout="mels_frames",
        validation=validation, logmel=PROVISIONAL, experimental=True, note=note,
        uncertain_below=UNCERTAIN_BELOW,
        meta={**meta, "meta.created": date.today().isoformat(), "meta.tflite_sha256": sha256(f32)},
    )
    header = [
        f"Kernel model manifest for {version}.tflite (format: model-training/kernel_train/manifest.py).",
        "EXPERIMENTAL. Proxy-domain metrics only; not validated on grain. Physical inspection decides.",
    ] if validation == "proxy" else [
        f"Kernel model manifest for {version}.tflite. Experimental until a documented field evaluation exists.",
    ]
    write_manifest(manifest, dist / f"{version}.properties", header=header)
    shutil.copyfile(run / "classifier.keras", dist / f"{version}.keras")

    history = json.loads((run / "history.json").read_text(encoding="utf-8"))
    metrics = {
        "version": version, "validation": validation, "experimental": True, "uncertain_below": UNCERTAIN_BELOW,
        "shipped_variant": "float32", "temperature": temperature,
        "tflite_bytes": len(f32), "tflite_sha256": sha256(f32), "int8_bytes": len(i8),
        "audit": audits, "parity_probe": probe, "keras_vs_tflite": agreement,
        "training": history["summary"], "history": history["history"],
        "metrics_float32": m32, "metrics_int8_dynamic": m8,
        "split_sizes": {k: {"clips": len(s.clips), "windows": len(s.eval_windows())} for k, s in splits.items()},
        **(extra or {}),
    }
    (dist / f"{version}.metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    log(f"wrote {tfl_path} ({len(f32)} bytes) and manifest")
    return metrics


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", type=Path, default=Path("runs/proxy-0.1"))
    ap.add_argument("--version", default="kernel-proxy-0.1")
    a = ap.parse_args()
    names = ("val", "test", "challenge_hardneg", "challenge_pos")
    splits = {n: Split.load(n) for n in names}
    release(a.run, a.version, "proxy", PROXY_NOTE, PROXY_META, splits, log=lambda s: print(s, flush=True))


if __name__ == "__main__":
    main()
