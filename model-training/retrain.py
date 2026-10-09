"""Retrain on the team's own labelled grain recordings (the app's dataset ZIP).

Input: the ZIP written by the app's DatasetExportService.exportZip(), shared
off the phone by the user. It holds retained WAVs plus one CSV manifest with
the columns
    scan_id, item_id, label, inspection_id, grain_type, sack_material,
    environment, notes, wav_filename
`label` is clean / infested / unknown. The app only allows clean/infested
when a verified inspection agrees (LabeledSampleRepository).

What it does:
  1. extracts the ZIP into its own directory under data/own/ (untrusted
     input; path traversal is rejected) and reads the CSV
  2. drops `unknown` (and any other value), rows without a WAV, and
     duplicate scan_ids
  3. splits by item_id (sack), never by scan, so one sack is never in two
     splits: about 70/15/15 train/val/test, stratified by each sack's majority
     label, deterministic for a given --seed. It needs >= 3 sacks per label,
     else it stops: there would be nothing honest to evaluate on.
  4. resamples to 16 kHz mono PCM16; keeps only clips >= 2 s (shorter
     captures are never classified by the app either)
  5. fine-tunes from the proxy classifier (default) or trains from scratch.
     The default --bands full uses all 64 mels (125-7500 Hz), because own
     recordings are real 16 kHz phone audio; the proxy weights still transfer.
  6. exports dist/kernel-grain-<ver>.tflite + .properties with
     validation=field and experimental=true, plus .metrics.json and .keras

`experimental` is always true here. Set it to false only by hand, and only
after a documented field evaluation (docs/device-validation.md) supports it.

Usage:
    uv run python -I retrain.py path/to/kernel-dataset.zip --version 0.1
    uv run python -I retrain.py data.zip --version 0.2 --from scratch --epochs 40
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import sys
import zipfile
from collections import Counter, defaultdict
from pathlib import Path, PurePosixPath

import kernel_train  # noqa: F401  (MSVC runtime DLL dir before TF loads)
from kernel_train.treevibes import Item

ROOT = Path(__file__).resolve().parent
REQUIRED_COLUMNS = ("scan_id", "item_id", "label", "inspection_id", "grain_type", "sack_material",
                    "environment", "notes", "wav_filename")
KEEP_LABELS = ("clean", "infested")
MIN_ITEMS_PER_LABEL = 3
PROXY_KERAS = ROOT / "dist" / "kernel-proxy-0.1.keras"


class DatasetError(ValueError):
    pass


def safe_extract(zip_path: Path, dest: Path) -> list[str]:
    """Extract regular files only; reject absolute paths and '..' components."""
    names = []
    with zipfile.ZipFile(zip_path) as z:
        for info in z.infolist():
            if info.is_dir():
                continue
            p = PurePosixPath(info.filename.replace("\\", "/"))
            if p.is_absolute() or ".." in p.parts or (p.parts and ":" in p.parts[0]):
                raise DatasetError(f"unsafe path in zip: {info.filename!r}")
            target = dest.joinpath(*p.parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            with z.open(info) as src, open(target, "wb") as out:
                out.write(src.read())
            names.append(p.as_posix())
    return names


def read_manifest(raw_dir: Path, names: list[str]) -> list[dict]:
    csvs = [n for n in names if n.lower().endswith(".csv")]
    if len(csvs) != 1:
        raise DatasetError(f"expected exactly one CSV manifest in the zip, found {csvs}")
    text = (raw_dir / csvs[0]).read_text(encoding="utf-8-sig")
    reader = csv.DictReader(io.StringIO(text))
    missing = [c for c in REQUIRED_COLUMNS if c not in (reader.fieldnames or [])]
    if missing:
        raise DatasetError(f"CSV manifest is missing columns {missing}")
    return list(reader)


def resolve_wav(name: str, names: list[str]) -> str | None:
    name = name.strip().replace("\\", "/")
    if not name:
        return None
    if name in names:
        return name
    matches = [n for n in names if PurePosixPath(n).name == PurePosixPath(name).name]
    return matches[0] if len(matches) == 1 else None


def select_rows(rows: list[dict], names: list[str]) -> tuple[list[dict], Counter]:
    dropped: Counter = Counter()
    kept, seen = [], set()
    for r in rows:
        label = r["label"].strip().lower()
        if label not in KEEP_LABELS:
            dropped[f"label_{label or 'empty'}"] += 1
            continue
        if not r["item_id"].strip():
            dropped["no_item_id"] += 1
            continue
        sid = r["scan_id"].strip()
        if sid in seen:
            dropped["duplicate_scan_id"] += 1
            continue
        wav = resolve_wav(r["wav_filename"], names)
        if wav is None:
            dropped["wav_missing"] += 1
            continue
        seen.add(sid)
        kept.append({**r, "label": label, "wav": wav})
    return kept, dropped


def split_by_item(rows: list[dict], seed: int) -> dict[str, str]:
    """item_id -> split, stratified by the item's majority label, deterministic."""
    labels_of: dict[str, Counter] = defaultdict(Counter)
    for r in rows:
        labels_of[r["item_id"]][r["label"]] += 1
    by_major: dict[str, list[str]] = defaultdict(list)
    for item, c in labels_of.items():
        by_major[c.most_common(1)[0][0]].append(item)
    for label in KEEP_LABELS:
        n = len(by_major.get(label, []))
        if n < MIN_ITEMS_PER_LABEL:
            raise DatasetError(
                f"need >= {MIN_ITEMS_PER_LABEL} distinct sacks (item_id) labelled '{label}', found {n}. "
                "A held-out evaluation is impossible with fewer; collect more verified samples first."
            )
    assign: dict[str, str] = {}
    for label, items in by_major.items():
        items = sorted(items, key=lambda i: hashlib.sha256(f"{seed}:{i}".encode()).hexdigest())
        n = len(items)
        n_test = max(1, round(0.15 * n))
        n_val = max(1, round(0.15 * n))
        for k, item in enumerate(items):
            assign[item] = "test" if k < n_test else "val" if k < n_test + n_val else "train"
    return assign


def main(argv: list[str] | None = None) -> dict:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("zip", type=Path)
    ap.add_argument("--version", required=True, help="e.g. 0.1 -> kernel-grain-0.1")
    ap.add_argument("--from", dest="init", choices=("proxy", "scratch"), default="proxy")
    ap.add_argument("--proxy-keras", type=Path, default=PROXY_KERAS)
    ap.add_argument("--bands", choices=("full", "proxy"), default="full")
    ap.add_argument("--epochs", type=int, default=30)
    ap.add_argument("--steps", type=int, default=100)
    ap.add_argument("--batch", type=int, default=64)
    ap.add_argument("--lr", type=float, default=None, help="default 3e-4 fine-tune, 1e-3 scratch")
    ap.add_argument("--patience", type=int, default=8)
    ap.add_argument("--seed", type=int, default=20261010)
    ap.add_argument("--dist", type=Path, default=ROOT / "dist")
    ap.add_argument("--work", type=Path, default=None, help="default data/own/kernel-grain-<ver>")
    a = ap.parse_args(argv)

    # Heavy imports after argument parsing so --help is instant.
    import keras

    from kernel_train.features import Split
    from kernel_train.logmel import PROVISIONAL
    from kernel_train.model import N_MELS, PROXY_MAX_HZ, bands_below, build_classifier, transfer_weights
    from kernel_train.prep import prepare
    from kernel_train.release import release
    from kernel_train.train import train

    version = f"kernel-grain-{a.version}"
    work = a.work or (ROOT / "data" / "own" / version)
    raw_dir, prep_dir, run_dir = work / "raw", work / "prepared", work / "run"
    raw_dir.mkdir(parents=True, exist_ok=True)

    names = safe_extract(a.zip, raw_dir)
    rows, dropped = select_rows(read_manifest(raw_dir, names), names)
    assign = split_by_item(rows, a.seed)
    items = [Item(r["wav"], r["label"], r["item_id"], assign[r["item_id"]], "", "") for r in rows]
    report = prepare(items, raw_dir=raw_dir, prep_dir=prep_dir, split_order=("test", "val", "train"),
                     domain_of=lambda it: "own")
    splits = {s: Split.load(s, prep_dir=prep_dir) for s in ("train", "val", "test")}
    for s, sp in splits.items():
        for lab in KEEP_LABELS:
            if not any(c.label == lab for c in sp.clips):
                raise DatasetError(f"split '{s}' has no usable '{lab}' clips after preparation")

    bands = N_MELS if a.bands == "full" else bands_below(PROXY_MAX_HZ, PROVISIONAL)
    init_path = None
    if a.init == "proxy":
        if not a.proxy_keras.exists():
            raise DatasetError(f"proxy classifier not found: {a.proxy_keras}")
        src = keras.models.load_model(a.proxy_keras, compile=False)
        dst = build_classifier(bands)
        copied = transfer_weights(src, dst)
        run_dir.mkdir(parents=True, exist_ok=True)
        init_path = run_dir / "init.keras"
        dst.save(init_path, include_optimizer=False)
        print(f"initialised from proxy: {len(copied)} layers copied", flush=True)
    lr = a.lr if a.lr is not None else (3e-4 if a.init == "proxy" else 1e-3)

    summary = train(run_dir, a.epochs, a.steps, a.batch, lr, a.patience, bands, splits["train"], splits["val"],
                    init_from=init_path, seed=a.seed, log=lambda s: print(s, flush=True))

    sacks = len({r["item_id"] for r in rows})
    grains = sorted({r["grain_type"].strip() for r in rows if r["grain_type"].strip()})
    note = (f"Experimental — trained on {len(rows)} labelled grain-sack recordings from {sacks} sacks "
            f"({', '.join(grains) or 'grain type not recorded'}); field evaluation pending.")[:500]
    zip_sha = hashlib.sha256(a.zip.read_bytes()).hexdigest()
    meta = {
        "meta.dataset": f"own labelled recordings, dataset zip sha256 {zip_sha}",
        "meta.samples": str(len(rows)),
        "meta.sacks": str(sacks),
        "meta.base_model": "kernel-proxy-0.1" if a.init == "proxy" else "none (from scratch)",
        "meta.band_limit_hz": "7500" if bands == N_MELS else str(int(PROXY_MAX_HZ)),
        "meta.model_card": "model-training/MODEL_CARD.md (write a grain section before release)",
    }
    extra = {"own_dataset": {
        "zip_sha256": zip_sha, "rows_kept": len(rows), "rows_dropped": dict(dropped), "sacks": sacks,
        "grain_types": grains, "split_items": dict(Counter(assign.values())), "prep": report,
        "labels_by_split": {s: dict(Counter(c.label for c in sp.clips)) for s, sp in splits.items()},
    }, "train_summary": summary}
    metrics = release(run_dir, version, "field", note, meta, {"val": splits["val"], "test": splits["test"]},
                      dist=a.dist, extra=extra, log=lambda s: print(s, flush=True))
    out = {"version": version, "test": metrics["metrics_float32"]["test"]["windows"], "dist": str(a.dist)}
    print(json.dumps(out, indent=2))
    return metrics


if __name__ == "__main__":
    try:
        main()
    except DatasetError as e:
        print(f"retrain: {e}", file=sys.stderr)
        sys.exit(2)
