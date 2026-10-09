"""Print the metadata of figshare / Ag Data Commons articles (survey helper).

Usage:
    uv run python -I tools/figshare_record.py <article-id> [<article-id> ...]

Read-only call to the public figshare API.
"""

from __future__ import annotations

import html
import json
import re
import sys
import urllib.request


def fetch(article_id: str) -> dict:
    req = urllib.request.Request(
        f"https://api.figshare.com/v2/articles/{int(article_id)}",
        headers={"User-Agent": "kernel-model-training-survey/0.1"},
    )
    with urllib.request.urlopen(req, timeout=60) as resp:  # noqa: S310 (fixed https host)
        return json.load(resp)


def show(a: dict, max_desc: int) -> None:
    print(f"# [{a.get('id')}] {a.get('title')}")
    lic = a.get("license") or {}
    print(f"licence: {lic.get('name')} {lic.get('url')} | doi: {a.get('doi')} | published: {a.get('published_date')}")
    print("authors:", "; ".join(x.get("full_name", "") for x in a.get("authors", [])))
    desc = html.unescape(re.sub(r"<[^>]+>", " ", a.get("description", "")))
    print("description:", re.sub(r"\s+", " ", desc).strip()[:max_desc])
    for r in a.get("references", []) or []:
        print("reference:", r)
    for cf in a.get("custom_fields", []) or []:
        val = cf.get("value")
        if val:
            print(f"field {cf.get('name')}: {str(val)[:400]}")
    total = 0
    for f in a.get("files", []):
        total += f.get("size", 0)
        print(f"file: {f.get('name')} {f.get('size', 0) / 1e6:.1f} MB md5={f.get('computed_md5')} {f.get('download_url')}")
    print(f"total files: {len(a.get('files', []))} {total / 1e9:.3f} GB\n")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    args = sys.argv[1:]
    max_desc = 4000
    if args and args[0].startswith("--desc="):
        max_desc = int(args[0].split("=", 1)[1])
        args = args[1:]
    for aid in args:
        show(fetch(aid), max_desc)
