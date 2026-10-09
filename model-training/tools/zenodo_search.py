"""Summarise Zenodo records-API search results (dataset survey helper).

Usage:
    uv run python -I tools/zenodo_search.py "query one" "query two" ...

Prints id, title, licence, publication date, file count, total size and URL
for each hit. Read-only: it only calls the public Zenodo search API.
"""

from __future__ import annotations

import json
import sys
import urllib.parse
import urllib.request

API = "https://zenodo.org/api/records"


def search(query: str, size: int = 15) -> dict:
    params = {"q": query, "size": size}
    if DATASETS_ONLY:
        params["type"] = "dataset"
    url = f"{API}?{urllib.parse.urlencode(params)}"
    with urllib.request.urlopen(url, timeout=60) as resp:  # noqa: S310 (fixed https host)
        return json.load(resp)


def summarise(query: str, result: dict) -> None:
    hits = result.get("hits", {})
    print(f"=== {query!r} total={hits.get('total')}")
    for h in hits.get("hits", []):
        m = h.get("metadata", {})
        lic = (m.get("license") or {}).get("id")
        files = h.get("files", [])
        size = sum(f.get("size", 0) for f in files)
        print(
            f"- [{h.get('id')}] {m.get('title')!r} | lic={lic} | {m.get('publication_date')}"
            f" | files={len(files)} {size / 1e9:.2f} GB | {h.get('links', {}).get('self_html')}"
        )


DATASETS_ONLY = False

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")  # titles contain non-cp1252 characters
    args = sys.argv[1:]
    if args and args[0] == "--datasets":
        DATASETS_ONLY = True
        args = args[1:]
    for q in args:
        summarise(q, search(q))
