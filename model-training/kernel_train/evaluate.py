"""Window-level evaluation, matching how the app classifies one 2 s capture.

The app maps the top-class probability to a classification. With
`uncertain_below=u`, a window whose top probability is below u is shown as
UNCERTAIN; otherwise it is the argmax class. Confidence is always the
top-class probability. We report:
  - binary metrics on argmax (accuracy, balanced accuracy, per-class
    precision/recall/F1, confusion matrix, ROC AUC)
  - the uncertain rate within the band, accuracy on the confident remainder,
    and the 3-way table (true x {clean, uncertain, infested})
  - clip-level metrics (mean window probability per clip), secondary
  - per provenance group: fraction predicted infested / uncertain
Metrics are for the proxy domain only (TreeVibes wood-borer vibrations).
"""

from __future__ import annotations

from collections import defaultdict

import numpy as np
from sklearn.metrics import confusion_matrix, precision_recall_fscore_support, roc_auc_score

from kernel_train.features import Split, eval_batches

LABELS = ("clean", "infested")


def predict(fn, split: Split, batch: int = 128) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    ps, ys, cs = [], [], []
    for x, y, c in eval_batches(split, batch=batch):
        ps.append(np.asarray(fn(x), dtype=np.float64))
        ys.append(y)
        cs.append(c)
    return np.concatenate(ps), np.concatenate(ys), np.concatenate(cs)


def _binary(p_inf: np.ndarray, y: np.ndarray) -> dict:
    pred = (p_inf >= 0.5).astype(int)
    out: dict = {"n": int(y.size), "n_clean": int(np.sum(y == 0)), "n_infested": int(np.sum(y == 1))}
    out["accuracy"] = float(np.mean(pred == y))
    present = np.unique(y)
    out["balanced_accuracy"] = float(np.mean([np.mean(pred[y == c] == c) for c in present]))
    prec, rec, f1, sup = precision_recall_fscore_support(y, pred, labels=[0, 1], zero_division=0)
    out["per_class"] = {
        LABELS[i]: {"precision": float(prec[i]), "recall": float(rec[i]), "f1": float(f1[i]), "support": int(sup[i])}
        for i in range(2)
    }
    out["confusion_matrix"] = {"rows_true": list(LABELS), "cols_pred": list(LABELS),
                               "values": confusion_matrix(y, pred, labels=[0, 1]).tolist()}
    out["roc_auc"] = float(roc_auc_score(y, p_inf)) if present.size == 2 else None
    return out


def _band(probs: np.ndarray, y: np.ndarray, uncertain_below: float) -> dict:
    top = probs.max(axis=1)
    pred = probs.argmax(axis=1)
    unc = top < uncertain_below
    conf = ~unc
    table = {LABELS[t]: {"clean": int(np.sum((y == t) & conf & (pred == 0))),
                         "uncertain": int(np.sum((y == t) & unc)),
                         "infested": int(np.sum((y == t) & conf & (pred == 1)))}
             for t in (0, 1) if np.any(y == t)}
    return {
        "uncertain_below": uncertain_below,
        "uncertain_rate": float(np.mean(unc)),
        "uncertain_rate_by_true_class": {LABELS[t]: float(np.mean(unc[y == t])) for t in (0, 1) if np.any(y == t)},
        "confident_accuracy": float(np.mean(pred[conf] == y[conf])) if np.any(conf) else None,
        "confident_n": int(np.sum(conf)),
        "three_way_table_rows_true": table,
    }


def summarise(probs: np.ndarray, y: np.ndarray, clip: np.ndarray, split: Split, uncertain_below: float) -> dict:
    p_inf = probs[:, 1]
    out = {"windows": _binary(p_inf, y), "band": _band(probs, y, uncertain_below)}
    # Clip level: mean of the clip's window probabilities.
    clips = np.unique(clip)
    cp = np.array([p_inf[clip == c].mean() for c in clips])
    cy = np.array([y[clip == c][0] for c in clips])
    out["clips"] = _binary(cp, cy)
    groups: dict[str, list[int]] = defaultdict(list)
    for i, c in enumerate(clip):
        groups[split.clips[int(c)].group].append(i)
    top = probs.max(axis=1)
    out["groups"] = {
        g: {"label": split.clips[int(clip[idx[0]])].label, "windows": len(idx),
            "pred_infested_rate": float(np.mean(p_inf[idx] >= 0.5)),
            "uncertain_rate": float(np.mean(top[idx] < uncertain_below))}
        for g, idx in sorted(groups.items())
    }
    return out


def summarise_one_class(probs: np.ndarray, y: np.ndarray, split: Split, clip: np.ndarray, uncertain_below: float) -> dict:
    """Challenge sets with a single true class: only rates make sense."""
    top, pred = probs.max(axis=1), probs.argmax(axis=1)
    label = LABELS[int(y[0])]
    out = {"true_class": label, "windows": int(y.size),
           "pred_infested_rate": float(np.mean(pred == 1)),
           "uncertain_rate": float(np.mean(top < uncertain_below)),
           "confident_infested_rate": float(np.mean((pred == 1) & (top >= uncertain_below))),
           "confident_clean_rate": float(np.mean((pred == 0) & (top >= uncertain_below)))}
    groups: dict[str, list[int]] = defaultdict(list)
    for i, c in enumerate(clip):
        groups[split.clips[int(c)].group].append(i)
    out["groups"] = {g: {"windows": len(idx), "pred_infested_rate": float(np.mean(pred[idx] == 1))}
                     for g, idx in sorted(groups.items())}
    return out
