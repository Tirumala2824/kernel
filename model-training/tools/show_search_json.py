"""Print a compact view of saved Kaggle dataset-list or DataCite search JSON.

Usage:
    uv run python -I tools/show_search_json.py kaggle data/survey/k_rpw.json
    uv run python -I tools/show_search_json.py datacite data/survey/dc_is1000.json
"""

from __future__ import annotations

import json
import sys


def kaggle(d: object) -> None:
    items = d if isinstance(d, list) else d.get("datasets", d.get("datasetsNullable", []))
    for it in items:
        print(
            f"- {it.get('ref')} | {it.get('title')!r} | lic={it.get('licenseName')}"
            f" | {int(it.get('totalBytes') or 0) / 1e9:.2f} GB | {it.get('subtitle')!r}"
        )


def datacite(d: dict) -> None:
    for it in d.get("data", []):
        a = it.get("attributes", {})
        titles = "; ".join(t.get("title", "") for t in a.get("titles", []))
        rights = "; ".join(r.get("rights", "") or r.get("rightsUri", "") for r in a.get("rightsList", []))
        print(f"- {a.get('doi')} | {titles!r} | rights={rights} | sizes={a.get('sizes')} | {a.get('url')}")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    kind, path = sys.argv[1], sys.argv[2]
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    {"kaggle": kaggle, "datacite": datacite}[kind](data)
