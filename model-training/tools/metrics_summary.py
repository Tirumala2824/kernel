"""Compact summary of dist/<version>.metrics.json (for the model card and reports).

Usage:
    uv run python -I tools/metrics_summary.py dist/kernel-proxy-0.1.metrics.json
"""

from __future__ import annotations

import json
import sys


def pct(x) -> str:
    return "n/a" if x is None else f"{100 * x:.1f}%"


def show_split(name: str, s: dict) -> None:
    w, b, c = s["windows"], s["band"], s["clips"]
    pc = w["per_class"]
    print(f"[{name}] windows n={w['n']} (clean {w['n_clean']}, infested {w['n_infested']})")
    print(f"  acc {pct(w['accuracy'])} bal_acc {pct(w['balanced_accuracy'])} auc {w['roc_auc']:.3f}")
    for k in ("clean", "infested"):
        print(f"  {k}: precision {pct(pc[k]['precision'])} recall {pct(pc[k]['recall'])} f1 {pc[k]['f1']:.3f}")
    print(f"  confusion rows=true cols=pred [clean, infested]: {w['confusion_matrix']['values']}")
    print(f"  band <{b['uncertain_below']}: uncertain {pct(b['uncertain_rate'])} by class "
          f"{ {k: pct(v) for k, v in b['uncertain_rate_by_true_class'].items()} } "
          f"confident acc {pct(b['confident_accuracy'])} (n={b['confident_n']})")
    print(f"  3-way (rows true): {b['three_way_table_rows_true']}")
    print(f"  clip-level n={c['n']} acc {pct(c['accuracy'])} bal_acc {pct(c['balanced_accuracy'])} auc {c['roc_auc']:.3f}")
    print("  groups:", {g: f"{v['label'][0]} infested {pct(v['pred_infested_rate'])} unc {pct(v['uncertain_rate'])}"
                        for g, v in s["groups"].items()})


if __name__ == "__main__":
    m = json.load(open(sys.argv[1], encoding="utf-8"))
    print(f"{m['version']} validation={m['validation']} T={m['temperature']:.3f} bytes={m['tflite_bytes']} "
          f"int8={m['int8_bytes']} sha256={m['tflite_sha256']}")
    print("ops:", m["audit"]["float32"]["ops"])
    print("parity probe:", m["parity_probe"])
    print("keras vs tflite:", m["keras_vs_tflite"])
    print("training:", m["training"])
    for name, s in m["metrics_float32"].items():
        if name.startswith("challenge"):
            print(f"[{name}] {s['true_class']} windows={s['windows']} pred_infested {pct(s['pred_infested_rate'])} "
                  f"uncertain {pct(s['uncertain_rate'])} confident_infested {pct(s['confident_infested_rate'])} "
                  f"confident_clean {pct(s['confident_clean_rate'])}")
            print("  groups:", {g: pct(v["pred_infested_rate"]) for g, v in s["groups"].items()})
        else:
            show_split(name, s)
    for name, s in m["metrics_int8_dynamic"].items():
        w = s["windows"]
        print(f"[int8 {name}] acc {pct(w['accuracy'])} bal_acc {pct(w['balanced_accuracy'])} auc {w['roc_auc']:.3f}")
