# Model card: kernel-proxy-0.1

> **EXPERIMENTAL PROXY MODEL. Trained on non-grain insect recordings. Not validated on grain.**
> **Do not use it for sale, purchase, acceptance/rejection or treatment (fumigation) decisions.**
> A "clean" output is not a guarantee. Physical inspection is required for every decision.

| | |
|---|---|
| Files | `dist/kernel-proxy-0.1.tflite` (247,668 bytes, float32), `dist/kernel-proxy-0.1.properties` |
| SHA-256 (.tflite) | `4dea00ab7e88ff50ca2368e94373171b579c911b80911db6d18dcd6afee5edc5` |
| Manifest | `validation=proxy`, `experimental=true`, `labels=clean,infested`, `output=probabilities`, `input_layout=mels_frames`, `uncertain_below=0.7` |
| App note (`note`, shown with every result) | `Experimental — trained on TreeVibes (non-grain insect recordings); not validated on grain.` |
| Runtime | LiteRT 1.4.2, CPU. Builtin ops only, all at version 1 |
| Created | 2026-10-10. Reproduce with `README.md` § "Reproduce the proxy model" |

## Intended use

The app needs a real model to exercise its full path end to end: capture, quality gate, log-mel,
LiteRT, result screen with provenance, ranking queue. This model provides one while no labelled
grain-sack recordings exist. It replaces "no model" (`NOT_EVALUATED`) with an **experimental
acoustic-activity score**. At most, that score suggests which sacks to inspect physically first.

**Out of scope:**
- any claim of grain-pest detection or of accuracy on grain
- automatic accept/reject of lots
- any treatment recommendation
- multi-sack detection

The guardrails are in `docs/guardrails.md` §4–5.

## Data

- **Audio: TreeVibes.** Rigakis I., Potamitis I., Tatlas N.-A., Potirakis S. M., Ntalampiras S. (2021),
  *TreeVibes: Modern Tools for Global Monitoring of Trees for Borers*, Smart Cities 4(1), 271-285,
  doi:10.3390/smartcities4010017. Dataset: https://www.kaggle.com/datasets/potamitis/treevibes,
  **licence CC0 1.0**. CC0 needs no attribution; we credit the authors anyway.
- **Splits: TV-PAVC v1.** Ayoub A. (2026), *TreeVibes Provenance-Aware Validation Cohort (TV-PAVC v1):
  Manifests, Fixed Folds, and Reproducibility Artifacts*, Zenodo, doi:10.5281/zenodo.21993431,
  **licence CC BY 4.0** (attribution required, given here). We use its decoded-PCM de-duplication,
  its 23 provenance groups and its six fixed grouped folds.
- **What the recordings are:**
  - Field: a piezoelectric contact sensor coupled by a drill bit or waveguide into tree trunks, 8 kHz mono.
  - Labels are per tree/placement (AUDIO = 1 infested by wood-boring larvae, e.g. red palm weevil; 0 clean).
  - Lab clips were **not used** in 0.1 (see `DATASETS.md`).
- **Splits, by provenance group, never by clip or window:**

| Split | Clean groups | Infested groups | Clips (clean/infested) | 2 s windows (clean/infested) |
|---|---|---|---|---|
| train | folders 7, 10, 24 | 2, 5, 11, 16, 17, 19, 20, 21, 23 | 628 / 437 | sampled on the fly |
| val (epoch + temperature selection) | 8 | 6, 13, 14 | 238 / 109 | 2,379 / 1,090 |
| test (held out, touched once) | 9, 25 | 1, 3+4, 12, 18, 22 | 535 / 125 | 5,334 / 1,225 |
| challenge: hard negatives | 35 | none | 332 / 0 | 3,320 / 0 |
| challenge: positive only | none | 15, 26-34 | 0 / 1,689 | 0 / 16,782 |

- **Integrity:**
  - Every field file matched TV-PAVC's raw-file SHA-256.
  - Our PCM hashes matched TV-PAVC's `sha256_pcm` for all 4,093 clips.
  - No PCM duplicate crosses splits.

## Preprocessing (identical to the app)

1. 8 kHz PCM16 is resampled to 16 kHz with a polyphase FIR (`scipy.signal.resample_poly`) and re-quantised to PCM16.
2. Clips are cut into non-overlapping 2 s windows (32,000 samples), matching one app capture (`TARGET_DURATION_MS = 2000`).
3. Samples are scaled as `pcm / 32768f`, as in `ScanAnalyzer`.
4. Log-mel uses the app's `LogMelConfig.PROVISIONAL`:
   - 512-pt FFT, 400-sample periodic Hann window, 160-sample hop, no centre padding, magnitude spectrum
   - 64 HTK-mel bands, 125-7500 Hz, DC bin zeroed
   - `ln(mel + 0.001)`
   - result: 198 frames × 64 mels
5. **Parity:**
   - `kernel_train/logmel.py` is checked against golden fixtures written by the Kotlin
     `LogMelGoldenFixtureTest` (`tests/fixtures/logmel/`).
   - Tolerance is 2e-6 nats. The observed difference is **0 (bit-exact)** on both fixtures.
6. The model input is the raw log-mel, `[1, 64, 198, 1]`, mels-major (`mels_frames`). All normalisation happens inside the graph.

## Architecture

The model is a compact CNN with 61,010 parameters. BatchNorm and the temperature are folded at export.

1. **Band limit (in-graph crop):** keep mel bands 0-46, whose upper edges are ≤ 3.8 kHz.
   - TreeVibes is 8 kHz audio. Measured on train, the kept bands sit about 5.2 nats above the
     log floor, while bands above 4.1 kHz are at or near the floor.
   - So the phone's real high-band content cannot drive the prediction.
2. **Per-band time-mean subtraction:** removes per-band gain, i.e. sensor and coupling frequency
   response and absolute level, and keeps transients (feeding pulses).
3. Four blocks of conv 3×3 (16, 32, 64, 64 channels) → BN → ReLU, with 2×2 max-pool after the first three.
4. Global max and global average pooling, concatenated.
5. Dropout 0.3, then dense to 2 logits.
6. Export: logits / T (T = 1.436, fitted on val NLL), then softmax.

TFLite ops: STRIDED_SLICE, MEAN, SUB, CONV_2D, MAX_POOL_2D, REDUCE_MAX, CONCATENATION,
FULLY_CONNECTED, SOFTMAX. All are builtin, version 1.

## Training

- CPU, TensorFlow 2.19.1 / Keras 3.15.1, seeds fixed (20261010) with TF op determinism.
- Adam at 1e-3, halved after 3 epochs without val improvement. 150 steps of 64 per epoch; early stop
  with patience 8. The best epoch was **13 of 22**, by val balanced accuracy.
- Batches are balanced 50/50 clean/infested, uniform over clips within each class.
- Augmentation is light, waveform domain:
  - random time shift (window start)
  - gain ±12 dB
  - with p = 0.5, mixing in a 2 s window from a *clean training* clip at 0-20 dB SNR

## Metrics (proxy domain only: TreeVibes wood-borer vibrations, unseen trees)

These numbers say how well the model separates **larval vibrations in wood recorded with a contact
piezo** on trees it never saw. **They say nothing about grain sacks recorded with a phone microphone.**
They are measured on the exported float32 `.tflite` through `tf.lite.Interpreter`. Keras and TFLite
agree within 5e-6 on every val window.

**Test (folds 5+6), per 2 s window** (n = 6,559: clean 5,334, infested 1,225)

| | value |
|---|---|
| Accuracy | 70.4% |
| Balanced accuracy | 67.3% |
| ROC AUC | 0.715 |
| Clean: precision / recall | 89.3% / 72.3% |
| Infested: precision / recall | 34.0% / 62.3% |

Confusion matrix (rows are true, columns predicted):

| true \ predicted | clean | infested |
|---|---|---|
| clean | 3,855 | 1,479 |
| infested | 462 | 763 |

**Uncertain band** (`uncertain_below = 0.7`, fixed before testing; a top-class probability below 0.7 shows as UNCERTAIN):

| true \ shown | clean | uncertain | infested |
|---|---|---|---|
| clean | 2,076 | 2,704 | 554 |
| infested | 210 | 558 | 457 |

- Uncertain rate: **49.7%** (clean 50.7%, infested 45.6%).
- Accuracy on the confident remainder: **76.8%** (n = 3,297).

**Clip level** (mean of a clip's ~10 window probabilities, n = 660): balanced accuracy 78.9%, AUC 0.830.
This is secondary, because the app classifies one 2 s window.

**Per test group** (fraction of windows predicted infested):

| Group | Label | Predicted infested |
|---|---|---|
| folder 25 | clean (forest) | 16.3% |
| folder 9 | clean (apricot, wind) | 28.3% |
| folder 1 | infested | 53.6% |
| folders 3+4 | infested | 72.9% |
| folder 18 | infested | 66.0% |
| folder 12 | infested | 92.0% |
| folder 22 | infested | 95.0% |

**Val (fold 4):** balanced accuracy 71.6%, AUC 0.790. It was used for epoch and temperature selection, so it is optimistic.

**Challenge sets (rates only):**
- **Hard negatives, folder 35** (AUDIO = 0 clips from infested trees): **67.9% predicted infested**,
  44.8% uncertain, 11.2% confident clean. The model fires on infested-tree context even when the
  annotators heard nothing. This is a known false-alarm mode.
- **Positive only, folders 15 and 26-34:** 38.1% predicted infested overall, ranging from 20.4% (folder 28) to 97.1% (folder 15).
  Sensitivity varies strongly by tree.

**Dynamic-range int8** (69,768 bytes): test balanced accuracy 67.1% (float32: 67.3%), AUC 0.715.
Accuracy holds, but **float32 ships**. At 248 KB size does not matter, and float32 avoids
hybrid-kernel numeric differences between this interpreter and LiteRT on the phone.

Full numbers, the training history, per-group rates and the op audit are in `dist/kernel-proxy-0.1.metrics.json`.

## Proxy caveat and known limits

1. **Domain gap.** The model saw wood, not grain, through a contact piezo, not a phone microphone
   on a jute or poly sack. It saw tree-borer larvae (e.g. red palm weevil), not *Sitophilus*,
   *Rhyzopertha*, *Tribolium* or *Trogoderma* in grain. Expect proxy metrics **not** to transfer.
2. **Bandwidth.** Only content below 3.8 kHz is used. Grain-insect feeding clicks have energy above that.
   A model trained on our own 16 kHz recordings (`retrain.py --bands full`) can use it.
3. **Label noise.** Labels are per tree, so 2 s windows from infested trees can be silent and still be
   labelled infested, and folder 35 shows the reverse.
4. **Few clean sources.** There are only 6 clean trees: 3 in train, 1 in val, 2 in test. Model
   selection rests on a single clean val tree (a fig tree recorded in rain), and val balanced
   accuracy swung between 0.50 and 0.72 across epochs.
5. **Weak operating point.** About half of all windows are UNCERTAIN, and confident results are about 77% correct on unseen trees.
6. **Not calibrated for grain.** The temperature was fitted on TreeVibes val. Confidence values are not probabilities of infestation in a sack.
7. **The app's quality gate was not applied** to the training data. TreeVibes clips (median about -38 dBFS RMS)
   would partly fail the provisional high-noise gate, and phone captures that pass the gate are a different distribution.

## Must be verified on the iQOO 15 (not done here)

- The model loads in LiteRT 1.4.2: `ModelRunner` status Ready, tensor validation passes, and the app's manifest parser accepts the `.properties`.
- On-device inference latency (0.8 ms per inference on the build PC, Python TFLite with 4 threads) and end-to-end scan latency.
- Output on a real silent and a real noisy capture is valid, and result screens show the `note`, `experimental` and UNCERTAIN.
- Record a device-log row in `docs/device-validation.md`.

## Replacing this model

Collect verified, labelled recordings in the app: research mode, with a clean or infested label only
when a physical inspection agrees. Export the dataset ZIP, then run
`uv run python -I retrain.py <zip> --version <v>`. That produces `kernel-grain-<v>` with
`validation=field`, still `experimental=true`, until a documented field evaluation exists.
