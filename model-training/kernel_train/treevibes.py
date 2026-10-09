"""TreeVibes proxy dataset: file selection, verified download and split.

Source audio: TreeVibes (Rigakis, Potamitis et al. 2021), Kaggle
`potamitis/treevibes`, licence CC0 1.0 (public domain).
Split/provenance metadata: TV-PAVC v1 (Ayoub 2026), Zenodo
10.5281/zenodo.21993431, licence CC BY 4.0. We use its decoded-PCM
de-duplication, its 23 provenance groups (folders 3 and 4 linked) and its six
fixed grouped folds, so no tree/source appears on both sides of a split.

Splits (by provenance group, never by clip or window):
  train      primary folds 1, 2, 3   (+ laboratory clips, training only)
  val        primary fold 4
  test       primary folds 5, 6
  challenge  folder 35 hard negatives (clean audio from infested-tree context),
             folder 15 and folders 26-34 (positive-only, sensitivity only)

Laboratory clips are segments of a few long recordings whose lineage is not
recoverable (TV-PAVC usage atlas), so they are only ever used for training.

Usage:
    uv run python -I -m kernel_train.treevibes select   # writes data/treevibes/selection.csv
    uv run python -I -m kernel_train.treevibes download # verified, resumable
"""

from __future__ import annotations

import csv
import hashlib
import random
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
TV_DIR = DATA / "treevibes"
RAW_DIR = TV_DIR / "raw"
PAVC_DIR = DATA / "tv_pavc"
SELECTION = TV_DIR / "selection.csv"
LISTING = TV_DIR / "files.csv"

KAGGLE_FILE_URL = "https://www.kaggle.com/api/v1/datasets/download/potamitis/treevibes/{path}"

TRAIN_FOLDS = {1, 2, 3}
VAL_FOLDS = {4}
TEST_FOLDS = {5, 6}

# Laboratory infested clips are 53,676 ten-second segments of a few long
# recordings. A fixed-seed subset keeps the download under the budget and the
# classes roughly balanced against the 967 laboratory clean clips.
LAB_INFESTED_SUBSET = 1500
LAB_SEED = 20261010

LABELS = ("clean", "infested")


@dataclass(frozen=True)
class Item:
    relative_path: str
    label: str  # clean | infested
    group: str  # provenance group (TV-PAVC) or "lab"
    split: str  # train | val | test | challenge_hardneg | challenge_pos
    sha256_file: str  # "" when unknown (laboratory clips)
    sha256_pcm: str


def _label(audio_label: str) -> str:
    return "infested" if float(audio_label) >= 0.5 else "clean"


def build_selection() -> list[Item]:
    items: list[Item] = []
    with open(PAVC_DIR / "TreeVibes_field_role_manifest_v1.csv", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            if r["keep_for_cohort_evaluation"] != "True":
                continue  # PCM duplicates, overlaps and unresolved lineage
            cohort = r["cohort"]
            if cohort == "primary_binary_cv":
                fold = int(float(r["fold"]))
                split = "train" if fold in TRAIN_FOLDS else "val" if fold in VAL_FOLDS else "test"
                group = r["provenance_group"]
            elif cohort == "folder35_hard_negative_challenge":
                split, group = "challenge_hardneg", "folder_35"
            elif cohort in ("official_positive_challenge", "folder15_source_test_challenge"):
                split, group = "challenge_pos", f"folder_{int(float(r['folder_num'])):02d}"
            else:
                continue
            items.append(
                Item(r["relative_path"], _label(r["audio_label"]), group, split, r["sha256_file"], r["sha256_pcm"])
            )

    lab_clean, lab_infested = [], []
    with open(LISTING, encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            name = r["name"]
            if name.startswith("lab/lab/clean/") and name.endswith(".wav"):
                lab_clean.append(name)
            elif name.startswith("lab/lab/infested/") and name.endswith(".wav"):
                lab_infested.append(name)
    lab_infested.sort()
    rng = random.Random(LAB_SEED)
    lab_infested = sorted(rng.sample(lab_infested, LAB_INFESTED_SUBSET))
    for name in sorted(lab_clean):
        items.append(Item(name, "clean", "lab", "train", "", ""))
    for name in lab_infested:
        items.append(Item(name, "infested", "lab", "train", "", ""))
    return items


def write_selection(items: list[Item]) -> None:
    SELECTION.parent.mkdir(parents=True, exist_ok=True)
    with open(SELECTION, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["relative_path", "label", "group", "split", "sha256_file", "sha256_pcm"])
        for it in items:
            w.writerow([it.relative_path, it.label, it.group, it.split, it.sha256_file, it.sha256_pcm])


def read_selection() -> list[Item]:
    with open(SELECTION, encoding="utf-8") as fh:
        return [Item(**r) for r in csv.DictReader(fh)]


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def _is_valid(path: Path, item: Item) -> bool:
    if not path.exists() or path.stat().st_size < 44:
        return False
    if item.sha256_file:
        return _sha256(path) == item.sha256_file
    with open(path, "rb") as fh:
        head = fh.read(12)
    return head[:4] == b"RIFF" and head[8:12] == b"WAVE"


def _download_one(item: Item, retries: int = 8) -> str:
    dest = RAW_DIR / item.relative_path
    if _is_valid(dest, item):
        return "cached"
    dest.parent.mkdir(parents=True, exist_ok=True)
    url = KAGGLE_FILE_URL.format(path=urllib.parse.quote(item.relative_path, safe=""))
    tmp = dest.with_suffix(dest.suffix + ".part")
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "kernel-model-training/0.1"})
            with urllib.request.urlopen(req, timeout=120) as resp, open(tmp, "wb") as out:  # noqa: S310
                while chunk := resp.read(1 << 16):
                    out.write(chunk)
            tmp.replace(dest)
            if _is_valid(dest, item):
                return "downloaded"
            dest.unlink(missing_ok=True)
            raise OSError("checksum or header mismatch")
        except Exception as e:  # network errors are retried, then reported
            tmp.unlink(missing_ok=True)
            if attempt == retries - 1:
                return f"FAILED {type(e).__name__}: {e}"
            wait = 2.0 * (attempt + 1)
            if isinstance(e, urllib.error.HTTPError) and e.code == 429:
                # Rate limited: honour Retry-After, else back off for a while.
                try:
                    wait = max(wait, float(e.headers.get("Retry-After", "")))
                except ValueError:
                    wait = max(wait, 30.0 * (attempt + 1))
            time.sleep(wait)
    return "FAILED"


def download(items: list[Item], workers: int = 8) -> int:
    failures = 0
    done = 0
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(_download_one, it): it for it in items}
        for fut in as_completed(futures):
            done += 1
            status = fut.result()
            if status.startswith("FAILED"):
                failures += 1
                print(f"{futures[fut].relative_path}: {status}", flush=True)
            if done % 250 == 0:
                print(f"{done}/{len(items)} files, {failures} failed", flush=True)
    print(f"done: {done}/{len(items)} files, {failures} failed", flush=True)
    return failures


def summarise(items: list[Item]) -> None:
    from collections import Counter

    c = Counter((it.split, it.label) for it in items)
    for k in sorted(c):
        print(k, c[k])
    groups: dict[tuple[str, str], set[str]] = {}
    for it in items:
        groups.setdefault((it.split, it.label), set()).add(it.group)
    for k in sorted(groups):
        print(k, sorted(groups[k]))


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "select"
    if cmd == "select":
        sel = build_selection()
        write_selection(sel)
        summarise(sel)
        print(f"{len(sel)} files -> {SELECTION}")
    elif cmd == "download":
        workers = int(sys.argv[2]) if len(sys.argv) > 2 else 8
        sys.exit(1 if download(read_selection(), workers=workers) else 0)
    else:
        raise SystemExit(f"unknown command {cmd}")
