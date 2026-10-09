"""Summarise a dataset file listing (name,bytes CSV) by directory and extension.

Usage:
    uv run python -I tools/summarise_listing.py data/treevibes/files.csv [depth]
"""

from __future__ import annotations

import csv
import sys
from collections import defaultdict
from pathlib import PurePosixPath

if __name__ == "__main__":
    path = sys.argv[1]
    depth = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    stats: dict[tuple[str, str], list[int]] = defaultdict(lambda: [0, 0])
    with open(path, encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            p = PurePosixPath(row["name"])
            key = ("/".join(p.parts[:-1][:depth]), p.suffix.lower())
            stats[key][0] += 1
            stats[key][1] += int(row["bytes"])
    for (d, ext), (n, b) in sorted(stats.items()):
        print(f"{d:70s} {ext:6s} {n:6d} {b / 1e6:9.1f} MB")
