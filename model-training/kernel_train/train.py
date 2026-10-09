"""Train the CNN on prepared windows (CPU, fixed seeds).

Usage:
    uv run python -I -m kernel_train.train --run runs/proxy-0.1 [--epochs 40]

Writes <run>/classifier.keras (best epoch by val balanced accuracy),
<run>/temperature.json (fitted on val logits) and <run>/history.json.
Only the training split is ever sampled; val chooses the epoch and the
temperature; test is never touched here.
"""

from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

import numpy as np

import kernel_train  # noqa: F401  (registers the MSVC runtime DLL dir before TF loads)
import keras
import tensorflow as tf
from scipy.optimize import minimize_scalar

from kernel_train.features import Split, TrainSampler, eval_batches
from kernel_train.model import PROXY_MAX_HZ, bands_below, build_classifier

SEED = 20261010


def softmax(z: np.ndarray) -> np.ndarray:
    z = z - z.max(axis=1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=1, keepdims=True)


def nll(logits: np.ndarray, y: np.ndarray, t: float = 1.0) -> float:
    p = softmax(logits / t)
    return float(-np.mean(np.log(np.clip(p[np.arange(y.size), y], 1e-12, 1.0))))


def balanced_accuracy(pred: np.ndarray, y: np.ndarray) -> float:
    recalls = [np.mean(pred[y == c] == c) for c in np.unique(y)]
    return float(np.mean(recalls))


def fit_temperature(logits: np.ndarray, y: np.ndarray) -> float:
    res = minimize_scalar(lambda t: nll(logits, y, t), bounds=(0.05, 20.0), method="bounded")
    return float(res.x)


def collect(split: Split) -> tuple[np.ndarray, np.ndarray]:
    xs, ys = [], []
    for x, y, _ in eval_batches(split, batch=128):
        xs.append(x.astype(np.float16))  # halves RAM; logs are |x| < 15, float16 is ample for selection
        ys.append(y)
    return np.concatenate(xs), np.concatenate(ys)


def train(run: Path, epochs: int, steps: int, batch: int, lr: float, patience: int, bands: int,
          train_split: Split, val_split: Split, init_from: Path | None = None, seed: int = SEED,
          log=print) -> dict:
    run.mkdir(parents=True, exist_ok=True)
    keras.utils.set_random_seed(seed)
    tf.config.experimental.enable_op_determinism()

    xv, yv = collect(val_split)
    log(f"val windows: {len(yv)} (clean {int(np.sum(yv == 0))}, infested {int(np.sum(yv == 1))})")
    sampler = TrainSampler(train_split, seed=seed)

    if init_from is not None:
        model = keras.models.load_model(init_from, compile=False)
    else:
        model = build_classifier(bands)
    opt = keras.optimizers.Adam(lr)
    model.compile(optimizer=opt, loss=keras.losses.SparseCategoricalCrossentropy(from_logits=True))

    best = {"bal_acc": -1.0, "loss": np.inf, "epoch": -1}
    history = []
    since_best, since_lr = 0, 0
    for epoch in range(epochs):
        t0 = time.time()
        losses = []
        for _ in range(steps):
            xb, yb = sampler.batch(batch)
            losses.append(float(model.train_on_batch(xb, yb)))
        logits = model.predict(xv.astype(np.float32), batch_size=256, verbose=0)
        vloss = nll(logits, yv)
        vbal = balanced_accuracy(logits.argmax(1), yv)
        rec = {"epoch": epoch, "train_loss": float(np.mean(losses)), "val_loss": vloss, "val_bal_acc": vbal,
               "lr": float(opt.learning_rate.numpy()), "sec": round(time.time() - t0, 1)}
        history.append(rec)
        log(json.dumps(rec))
        improved = vbal > best["bal_acc"] + 1e-4 or (abs(vbal - best["bal_acc"]) <= 1e-4 and vloss < best["loss"])
        if improved:
            best = {"bal_acc": vbal, "loss": vloss, "epoch": epoch}
            model.save(run / "classifier.keras", include_optimizer=False)
            since_best, since_lr = 0, 0
        else:
            since_best += 1
            since_lr += 1
            if since_lr >= 3:  # reduce-on-plateau
                opt.learning_rate.assign(float(opt.learning_rate.numpy()) * 0.5)
                since_lr = 0
            if since_best >= patience:
                log(f"early stop at epoch {epoch}; best epoch {best['epoch']}")
                break

    model = keras.models.load_model(run / "classifier.keras", compile=False)
    logits = model.predict(xv.astype(np.float32), batch_size=256, verbose=0)
    t = fit_temperature(logits, yv)
    summary = {"best": best, "temperature": t, "val_nll_raw": nll(logits, yv), "val_nll_calibrated": nll(logits, yv, t),
               "bands": bands, "seed": seed, "epochs_run": len(history), "steps": steps, "batch": batch, "lr": lr}
    (run / "temperature.json").write_text(json.dumps({"temperature": t}, indent=2), encoding="utf-8")
    (run / "history.json").write_text(json.dumps({"history": history, "summary": summary}, indent=2), encoding="utf-8")
    log(json.dumps(summary))
    return summary


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", type=Path, default=Path("runs/proxy-0.1"))
    ap.add_argument("--epochs", type=int, default=40)
    ap.add_argument("--steps", type=int, default=150)
    ap.add_argument("--batch", type=int, default=64)
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--patience", type=int, default=8)
    a = ap.parse_args()
    train(a.run, a.epochs, a.steps, a.batch, a.lr, a.patience, bands_below(PROXY_MAX_HZ),
          Split.load("train"), Split.load("val"), log=lambda s: print(s, flush=True))


if __name__ == "__main__":
    main()
