"""End-to-end dry run of prep -> train -> release on whatever is downloaded.

Usage:
    uv run python -I tools/dryrun.py
Writes only under data/dryrun/ (gitignored). Tiny training budget; the
resulting model is meaningless and is never released.
"""

from __future__ import annotations

from kernel_train.features import Split
from kernel_train.model import PROXY_MAX_HZ, bands_below
from kernel_train.prep import prepare
from kernel_train.release import PROXY_META, PROXY_NOTE, release
from kernel_train.train import train
from kernel_train.treevibes import DATA, read_selection

if __name__ == "__main__":
    root = DATA / "dryrun"
    prep_dir = root / "prepared"
    print(prepare(read_selection(), prep_dir=prep_dir), flush=True)
    splits = {s: Split.load(s, prep_dir=prep_dir) for s in ("train", "val", "test", "challenge_hardneg", "challenge_pos")}
    splits = {k: v for k, v in splits.items() if v.clips}
    train(root / "run", 2, 5, 32, 1e-3, 2, bands_below(PROXY_MAX_HZ), splits["train"], splits["val"],
          log=lambda s: print(s, flush=True))
    ev = {k: v for k, v in splits.items() if k != "train"}
    release(root / "run", "kernel-dryrun-0.0", "proxy", PROXY_NOTE, PROXY_META, ev, dist=root / "dist",
            log=lambda s: print(s, flush=True))
    print("DRYRUN OK", flush=True)
