"""Smoke-check the export path on an untrained network (no data needed).

Usage:
    uv run python -I tools/probe_export.py
Prints band count, parameter count, TFLite op versions and size for float32
and dynamic-range int8. The untrained weights are discarded.
"""

from __future__ import annotations

import numpy as np

from kernel_train.export import audit, convert
from kernel_train.model import PROXY_MAX_HZ, bands_below, build_classifier, build_export

if __name__ == "__main__":
    k = bands_below(PROXY_MAX_HZ)
    clf = build_classifier(k)
    print("bands", k, "params", clf.count_params())
    exp = build_export(clf, 1.0)
    for q in (False, True):
        tfl = convert(exp, quantize=q)
        a = audit(tfl)
        print("int8" if q else "float32", a)
    x = np.zeros((1, 64, 198, 1), np.float32)
    print("keras out", np.asarray(exp(x)))
