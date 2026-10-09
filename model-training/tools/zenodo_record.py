"""Print the metadata of one Zenodo record (dataset survey helper).

Usage:
    uv run python -I tools/zenodo_record.py <record-id> [<record-id> ...]

Shows title, licence, DOI, creators, description (HTML stripped), related
identifiers and the file list with sizes and checksums. Read-only.
"""

from __future__ import annotations

import html
import json
import re
import sys
import urllib.request


def fetch(record_id: str) -> dict:
    url = f"https://zenodo.org/api/records/{int(record_id)}"
    with urllib.request.urlopen(url, timeout=60) as resp:  # noqa: S310 (fixed https host)
        return json.load(resp)


def show(rec: dict, max_desc: int) -> None:
    m = rec.get("metadata", {})
    print(f"# [{rec.get('id')}] {m.get('title')}")
    print(f"licence: {(m.get('license') or {}).get('id')} | doi: {rec.get('doi')} | date: {m.get('publication_date')}")
    print("creators:", "; ".join(c.get("name", "") for c in m.get("creators", [])))
    desc = html.unescape(re.sub(r"<[^>]+>", " ", m.get("description", "")))
    desc = re.sub(r"\s+", " ", desc).strip()
    print("description:", desc[:max_desc])
    for r in m.get("related_identifiers", []) or []:
        print(f"related: {r.get('relation')} {r.get('identifier')}")
    for f in rec.get("files", []):
        print(f"file: {f.get('key')} {f.get('size', 0) / 1e6:.1f} MB {f.get('checksum')} {f.get('links', {}).get('self')}")
    print()


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    args = sys.argv[1:]
    max_desc = 2500
    if args and args[0].startswith("--desc="):
        max_desc = int(args[0].split("=", 1)[1])
        args = args[1:]
    for rid in args:
        show(fetch(rid), max_desc)
