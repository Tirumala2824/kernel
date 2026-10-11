---
license: cc-by-4.0
library_name: pytorch
pipeline_tag: audio-classification
datasets:
- InsectSet32
metrics:
- accuracy
- f1
tags:
- audio-classification
- insect
- bioacoustics
- experimental
- local-inference
- litert
- tflite
---

# Kernel Insect Sound Classifier (InsectCNN `full_model`, experimental 0.1.0)

A compact CNN (159k parameters) that classifies **32 sound-producing insect species** (9 Orthoptera, 23 Cicadidae) from audio. It was trained on [InsectSet32](https://zenodo.org/records/7072196).

> **This is not a grain-pest detector.** Do not use it to certify grain as clean or safe, to accept or reject lots, or to trigger treatment. It is a research baseline trained on a small dataset.

## Model details

| | |
|---|---|
| Architecture | `InsectCNN`: 3 conv blocks (16/32/64 ch, BatchNorm, ReLU) + dense head (128) with dropout 0.25 (`src/model.py`) |
| Input | Mono audio → resampled to 16 kHz → 2 s windows, peak-normalised → 64-bin log-mel (n_fft 512, hop 160), per-record standardised (`src/audio.py`) |
| Inference | Softmax averaged over 5 evenly spaced 2 s windows (`eval_crops: 5` in `config.json`) |
| Output | 32 species scores, plus a hierarchical species → genus → group answer |
| Base model | None. Trained from scratch (no pretrained weights, not a fine-tune) |
| Framework | PyTorch & Google LiteRT / TFLite |

### Files

- `model.tflite`: Google LiteRT / TensorFlow Lite on-device model for Android / edge mobile deployment.
- `model.pt`: PyTorch state dict weights. Load it with `torch.load(..., weights_only=True)`.
- `model.h5`: PyTorch state dict in a project-specific HDF5 layout (`kernel-pytorch-state-dict-hdf5-v1`). **It is not a Keras model.** `src.inference.load_model` reads it.
- `config.json`, `labels.json`: architecture, preprocessing settings and class-index → species mapping.
- `metrics.json`, `history.json`: test metrics (with per-class report) and the training curve.
- `src/`, `predict.py`, `export_litert.py`, `test_inference.py`: model definition, audio frontend, exporter and testing scripts.
- `train.py`, `evaluate.py`, `data/*.csv`: reproduction scripts and the official split annotations (the audio itself is not included).

## Usage

This is a custom PyTorch model. It does **not** load with `transformers`, and the hosted inference widget and Inference API don't support it. Run it locally:

```bash
pip install huggingface_hub
python -c "from huggingface_hub import snapshot_download; print(snapshot_download('ganesh333/kernel-insect-classifier', local_dir='kernel-insect-classifier'))"
cd kernel-insect-classifier
pip install -r requirements.txt
python predict.py path/to/recording.wav
```

WAV works out of the box. FLAC, OGG and MP3 need `soundfile`, which `requirements.txt` includes. Inference is fully local; no audio is sent anywhere.

Python API:

```python
from src.inference import predict_wav
r = predict_wav("recording.wav", model_dir=".")
print(r["identification"])                     # {'level': 'species'|'genus'|'group'|'unknown', 'name': ..., 'confidence': ...}
print(r["predicted_species"], r["confidence"])  # raw top-1
print(r["top_k"], r["quality_pass"], r["quality_reasons"])
```

**Hierarchical identification.** The model reports the most specific level whose summed probability is at least 0.6: species, then genus, then group (cicadas vs crickets/grasshoppers). Otherwise it reports `unknown`. The threshold was chosen on the validation split.

## Training

Data: InsectSet32. Using the dataset's official `train`/`validation`/`test` partitions, 331 recordings were loaded (206 / 51 / 74).

```bash
# place Cicadidae.csv, Orthoptera.csv, Cicadidae.zip, Orthoptera.zip in data/
python train.py --epochs 60 --random-crop --eval-crops 5 --output .
```

- AdamW (lr 1e-3, weight decay 1e-4), batch size 16, class-weighted cross entropy (weights from train only), seed 42.
- Each epoch trains on a fresh random 2 s window per file.
- The checkpoint is chosen by best validation macro-F1 (0.548). The test split was scored once, after selection.
- About 4 minutes on a CPU.

## Evaluation

Official test split (n = 74 recordings). 95% CIs from a file-level bootstrap:

| Metric | Value |
|---|---|
| Accuracy | 0.486 [0.38, 0.59] |
| Macro-F1 | 0.400 [0.29, 0.47] |
| Weighted-F1 | 0.474 |
| Session-clean accuracy / macro-F1 (n = 48) | 0.458 / 0.343 |

"Session-clean" counts only test files whose source recording session never appears in train or validation. See *Data leakage* below.

Accuracy among test files whose score at that level is at least 0.6:

| Level | Share of test files ≥ 0.6 | Accuracy on those (val / test) |
|---|---|---|
| Species | 43% | 77% / 72% |
| Genus | 77% | 90% / 95% |
| Group | 96% | 98% / 99% |

For comparison, the earlier center-crop baseline of the same architecture scored 0.392 accuracy and 0.329 macro-F1 on the same split. The CIs overlap, so with only 74 test files these differences are not conclusive.

## Limitations

- **Small, imbalanced data.** Species have 4–22 recordings each, and `Roeselianaroeselii` has no test files. All scores are uncertain.
- **Data leakage.** The official split groups by file, not by source recording: 26 of the 74 test files share a source session with train or validation. Official-split scores are therefore optimistic; the session-clean numbers are the more honest estimate.
- **Label noise.** Five `MHV 318 P.capensis` source files are labelled `Platypleuracfcatenata`. They were kept as published.
- **Closed set.** Every input is mapped onto the 32 trained species. Silence, pure tones and white noise can receive high-confidence species predictions. Use `quality_reasons` and treat `genus`/`unknown` answers as exactly that.
- **Noise sensitivity.** Added background noise (SNR 0–20 dB) often changes the prediction.
- **Not calibrated.** The scores are not probabilities of grain infestation. Recording conditions differ from grain sacks and warehouses.
- **Not mobile-ready.** This is not a validated Android LiteRT/TFLite model. See `docs/deployment.md` before any on-device port.
- `model.pt` is a pickle-based file and may be flagged by the Hub's pickle scanner. It contains only tensors. Prefer `model.h5`, or load with `weights_only=True`.

## Dataset attribution and citation

Trained on **InsectSet32** by Marius Faiß, Baudewijn Odé and Ed Baker (CC BY 4.0, [Zenodo 7072196](https://zenodo.org/records/7072196)). Orthoptera recordings: Baudewijn Odé. Cicadidae recordings: the Global Cicada Sound Collection on Bioacoustica ([doi.org/10.1093/database/bav054](https://doi.org/10.1093/database/bav054)). Copyright in individual recordings belongs to the recordists. See `data/README.txt`.

For academic use, please cite the dataset paper: Faiß, M. & Stowell, D. *Adaptive representations of sound for automatic insect recognition*, PLOS Computational Biology (2023), [doi.org/10.1371/journal.pcbi.1011541](https://doi.org/10.1371/journal.pcbi.1011541).

## License

- Model weights and this card: **CC BY 4.0**, matching the training data's license. Keep the attribution above when you redistribute.
- Code (`src/`, `*.py`): **MIT**. See `LICENSE`.
