"""List every file of a public Kaggle dataset (no credentials needed for listing).

Usage:
    uv run python -I tools/kaggle_files.py potamitis/treevibes data/treevibes/files.csv

Writes `name,bytes` rows. Read-only call to the public Kaggle API.
"""

from __future__ import annotations

import csv
import json
import sys
import urllib.parse
import urllib.request

API = "https://www.kaggle.com/api/v1/datasets/list/{ref}"


def list_files(ref: str) -> list[tuple[str, int]]:
    out: list[tuple[str, int]] = []
    token = None
    while True:
        params = {"pageSize": 200}
        if token:
            params["pageToken"] = token
        url = API.format(ref=ref) + "?" + urllib.parse.urlencode(params)
        req = urllib.request.Request(url, headers={"User-Agent": "kernel-model-training/0.1"})
        with urllib.request.urlopen(req, timeout=120) as resp:  # noqa: S310 (fixed https host)
            page = json.load(resp)
        for f in page.get("datasetFiles", []):
            out.append((f["name"], int(f.get("totalBytes", 0))))
        token = page.get("nextPageTokenNullable") or page.get("nextPageToken")
        if not token:
            return out


if __name__ == "__main__":
    ref, dest = sys.argv[1], sys.argv[2]
    files = list_files(ref)
    with open(dest, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["name", "bytes"])
        w.writerows(files)
    print(f"{len(files)} files, {sum(b for _, b in files) / 1e9:.2f} GB -> {dest}")
