"""Counts per cohort / fold / label in the TV-PAVC manifests (survey helper).

Usage:
    uv run python -I tools/manifest_stats.py data/tv_pavc/TreeVibes_field_role_manifest_v1.csv
"""

from __future__ import annotations

import csv
import sys
from collections import Counter

if __name__ == "__main__":
    path = sys.argv[1]
    with open(path, encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh))
    print("columns:", list(rows[0].keys()))
    c = Counter(
        (r["cohort"], r.get("fold", ""), r.get("audio_label", ""), r.get("keep_for_cohort_evaluation", ""))
        for r in rows
    )
    for k, n in sorted(c.items()):
        print(k, n)
    reasons = Counter(r.get("exclusion_reason", "") for r in rows)
    print("exclusion reasons:", dict(reasons))
    durs = [float(r["duration_s"]) for r in rows if r.get("duration_s")]
    print(f"duration: n={len(durs)} min={min(durs):.2f} max={max(durs):.2f} total_h={sum(durs) / 3600:.2f}")
