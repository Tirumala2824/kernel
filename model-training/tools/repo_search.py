"""Search Dryad and figshare (incl. USDA Ag Data Commons) for candidate datasets.

Usage:
    uv run python -I tools/repo_search.py dryad "query" ["query" ...]
    uv run python -I tools/repo_search.py figshare "query" ["query" ...]

Read-only calls to the public search APIs. Prints title, licence (where the
search API returns it), size and URL.
"""

from __future__ import annotations

import json
import sys
import urllib.parse
import urllib.request

UA = {"User-Agent": "kernel-model-training-survey/0.1"}


def _get(url: str) -> object:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as resp:  # noqa: S310 (fixed https hosts)
        return json.load(resp)


def _post(url: str, body: dict) -> object:
    req = urllib.request.Request(
        url, data=json.dumps(body).encode(), headers={**UA, "Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=60) as resp:  # noqa: S310
        return json.load(resp)


def dryad(query: str) -> None:
    d = _get(f"https://datadryad.org/api/v2/search?{urllib.parse.urlencode({'q': query, 'per_page': 20})}")
    items = d.get("_embedded", {}).get("stash:datasets", [])
    print(f"=== dryad {query!r} total={d.get('total')}")
    for it in items:
        size = it.get("storageSize") or 0
        print(
            f"- {it.get('title')!r} | lic={it.get('license')} | {it.get('publicationDate')}"
            f" | {size / 1e9:.2f} GB | https://doi.org/{str(it.get('identifier', '')).removeprefix('doi:')}"
        )


def figshare(query: str) -> None:
    items = _post("https://api.figshare.com/v2/articles/search", {"search_for": query, "item_type": 3, "page_size": 20})
    print(f"=== figshare {query!r} n={len(items)}")
    for it in items:
        print(f"- [{it.get('id')}] {it.get('title')!r} | {it.get('published_date')} | {it.get('url_public_html')}")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    which, queries = sys.argv[1], sys.argv[2:]
    fn = {"dryad": dryad, "figshare": figshare}[which]
    for q in queries:
        try:
            fn(q)
        except Exception as e:  # survey helper: report and continue
            print(f"!!! {which} {q!r}: {type(e).__name__}: {e}")
