# model-training

The off-device Python pipeline for Kernel's acoustic screening model. It covers dataset prep,
log-mel parity with the app, CNN training, TFLite export and model cards.

**Nothing here ships in the APK** except a released `dist/<name>.tflite` and `dist/<name>.properties`,
which the lead copies into `audio-ai/android/src/main/assets/models/`. There is no network code in the
app; the downloads below run on a developer machine only.

- `DATASETS.md`: the dataset survey and the chosen proxy data
- `MODEL_CARD.md`: what `kernel-proxy-0.1` is, what it is not, and its metrics (proxy domain only)

## Setup

```bash
# uv: see https://docs.astral.sh/uv/ (Windows installs to %USERPROFILE%\.local\bin)
uv python install 3.12
cd model-training
uv sync                     # TensorFlow 2.19 (CPU), numpy, scipy, soundfile, scikit-learn, pytest
```

On Windows, TensorFlow needs the MSVC C++ runtime. The `msvc-runtime` dependency puts it inside the
venv, and `kernel_train/__init__.py` registers that directory, so no system-wide install is needed.

Run every Python that reads downloaded data with `-I` (isolated mode). `kernel_train` is installed
editable, so `python -I -m kernel_train.<module>` works.

## Log-mel parity (Kotlin is the source of truth)

`kernel_train/logmel.py` is an exact numpy port of
`audio-ai/android/src/main/kotlin/com/kernel/audio_ai/LogMel.kt`.

```bash
# 1. Kotlin writes golden fixtures to ../tests/fixtures/logmel/ (or verifies them if present)
cd audio-ai/example/android && ./gradlew :audio_ai:testDebugUnitTest
#    regenerate after an intended LogMel change: KERNEL_REGEN_FIXTURES=1 ./gradlew ...
# 2. Python must match them
cd model-training && uv run python -I -m pytest tests/test_logmel_parity.py
uv run python -I tools/parity_report.py        # prints the actual error (bit-exact as of 2026-10-10)
```

The tolerance is 2e-6 nats, about 2 float32 ulps. The observed difference is 0 on both fixtures.

## Reproduce the proxy model (kernel-proxy-0.1)

```bash
uv run python -I -m kernel_train.treevibes select      # data/treevibes/selection.csv (needs data/tv_pavc + files.csv, see below)
uv run python -I -m kernel_train.treevibes download 4  # verified against TV-PAVC SHA-256; resumable; Kaggle may rate-limit (429)
uv run python -I -m kernel_train.prep --domains field  # 16 kHz PCM16 per split -> data/prepared/
uv run python -I -m kernel_train.train --run runs/proxy-0.1
uv run python -I -m kernel_train.release --run runs/proxy-0.1 --version kernel-proxy-0.1
```

Inputs the `select` step needs, downloaded once:
- `data/tv_pavc/` is the extracted `TreeVibes_TV-PAVC_v1_Resource.zip` from
  https://zenodo.org/records/21993431 (CC BY 4.0).
- `data/treevibes/files.csv` is the TreeVibes file listing:
  `uv run python -I tools/kaggle_files.py potamitis/treevibes data/treevibes/files.csv`.

`release` writes to `dist/`:
- `kernel-proxy-0.1.tflite`: float32, builtin ops only, input `[1, 64, 198, 1]`, output `[1, 2]` probabilities
- `kernel-proxy-0.1.properties`: the strict app manifest (see below)
- `kernel-proxy-0.1.metrics.json`: every metric, the op audit, the parity probe and the training history
- `kernel-proxy-0.1.keras`: the classifier, used as the starting point for `retrain.py`

Seeds are fixed (`SEED = 20261010`, plus TF op determinism).

## Retrain on our own grain recordings

The app's `DatasetExportService.exportZip()` writes retained WAVs plus one CSV with the columns
`scan_id,item_id,label,inspection_id,grain_type,sack_material,environment,notes,wav_filename`.
The user shares that ZIP from the phone; the app never uploads it.

```bash
uv run python -I retrain.py path/to/kernel-dataset.zip --version 0.1
#   --from proxy|scratch   (default proxy: fine-tune from dist/kernel-proxy-0.1.keras)
#   --bands full|proxy     (default full: all 64 mels, 125-7500 Hz, because own audio is real 16 kHz)
#   --epochs 30 --steps 100 --lr 3e-4 --dist dist --work data/own/kernel-grain-0.1
```

What `retrain.py` does:
- drops `unknown` labels, rows without a WAV and duplicate `scan_id`s
- splits **by `item_id` (sack)** about 70/15/15 (no sack is in two splits), and refuses to run with fewer than 3 sacks per label
- resamples to 16 kHz and keeps captures of at least 2 s
- trains, then exports `dist/kernel-grain-<ver>.tflite` + `.properties` with `validation=field` and **`experimental=true`**

`experimental` only becomes `false` by hand, after a documented field evaluation (`docs/device-validation.md`).
Before shipping a grain model, add a section to `MODEL_CARD.md`.

## Manifest format (`<name>.properties`)

`kernel_train/manifest.py` writes and strictly validates the format the app's `ModelManifest.kt` accepts.
Unknown keys make the app treat the model as absent.

- **Encoding:** UTF-8, Java properties syntax, `#` comments only at the start of a line.
  Our writer emits pure ASCII (`\uXXXX` escapes).
- **Required keys:** `version`, `labels` (over clean/uncertain/infested), `output` (probabilities|logits),
  `input_layout` (mels_frames|frames_mels), `validation` (proxy|field), `sample_rate=16000`, `n_fft`,
  `win_length`, `hop_length`, `n_mels`, `f_min`, `f_max`, `log_offset`, `power`.
- **Optional keys:**
  - `experimental` (default true; a proxy model is always true)
  - `note` (required and at most 500 chars when validation=proxy)
  - `uncertain_below` (a top-class probability below it shows as UNCERTAIN)
  - `meta.*` (ignored by the app; we store dataset attribution and the tflite SHA-256)

## Tests

```bash
uv run python -I -m pytest            # parity, features, manifest format, export smoke, retrain
```

`tests/test_retrain.py` builds a small synthetic ZIP in pytest's `tmp_path`. It only checks plumbing:
nothing it produces is kept, and it never writes to `dist/`.

## Layout

| Path | What |
|---|---|
| `kernel_train/logmel.py` | numpy port of the Kotlin LogMel |
| `kernel_train/treevibes.py` | TreeVibes selection (TV-PAVC folds) + verified downloader |
| `kernel_train/prep.py` | 16 kHz PCM16 packing per split, PCM-hash leakage guard |
| `kernel_train/features.py` | 2 s windows -> model input, training sampler and augmentation |
| `kernel_train/model.py` | CNN (in-graph band limit and per-band normalisation) |
| `kernel_train/train.py` | training loop, model selection on val, temperature fit |
| `kernel_train/export.py` | TFLite conversion, op audit, interpreter runner |
| `kernel_train/evaluate.py` | window/clip/group metrics, uncertain band |
| `kernel_train/release.py` | export + verify + evaluate + write `dist/` |
| `kernel_train/manifest.py` | manifest writer and strict validator |
| `retrain.py` | own-data retraining from the app's dataset ZIP |
| `tools/` | survey, parity report, band statistics, dry run |
| `data/`, `runs/`, `.venv/` | gitignored |
