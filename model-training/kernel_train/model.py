"""Compact CNN on the app's log-mel input, with the normalisation in-graph.

Input:  float32 [1, 64, 198, 1] (input_layout=mels_frames), raw
        ln(mel + 0.001) exactly as the app's Kotlin LogMel computes it.
Graph:
  1. band limit: keep the first `bands` mel bands. TreeVibes is 8 kHz audio,
     so bands above ~3.8 kHz hold no signal in training. Cropping them means
     the phone's real high-band content cannot drive the prediction.
  2. per-band time-mean subtraction (per example): removes fixed per-band
     gain, i.e. sensor/coupling frequency response and absolute level, and
     keeps transients (feeding pulses) relative to the background.
  3. 4 x [conv3x3 -> BN -> ReLU] with 2x2 max-pooling after the first three
  4. global max + global average pooling (pulses are sparse in time), dropout
  5. dense -> 2 logits [clean, infested]
Export adds `logits / T` (temperature fitted on val) and softmax, so the
TFLite output is calibrated probabilities (manifest output=probabilities).

TFLite builtin ops only: STRIDED_SLICE, MEAN, SUB, CONV_2D, MAX_POOL_2D,
REDUCE_MAX, CONCATENATION, FULLY_CONNECTED, MUL, SOFTMAX (+ RESHAPE).
"""

from __future__ import annotations

import keras
import numpy as np
from keras import layers, ops

from kernel_train.logmel import PROVISIONAL, LogMelConfig, band_upper_edges_hz

N_MELS = PROVISIONAL.n_mels
FRAMES = 198  # 2 s at 16 kHz: 1 + (32000 - 400) // 160
LABELS = ("clean", "infested")

# Highest mel-band upper edge the proxy model may look at. TreeVibes is 8 kHz
# (Nyquist 4 kHz) and its recorder's anti-alias filter rolls off just below
# that, so 3.8 kHz keeps every band that carries real training signal.
PROXY_MAX_HZ = 3_800.0


def bands_below(max_hz: float, cfg: LogMelConfig = PROVISIONAL) -> int:
    """Number of leading mel bands whose whole triangle lies at or below max_hz."""
    return int(np.sum(band_upper_edges_hz(cfg) <= max_hz + 1e-6))


@keras.saving.register_keras_serializable(package="kernel")
class PerBandTimeNorm(layers.Layer):
    """x - mean_over_time(x), per example and per mel band ([B, mels, frames, C])."""

    def call(self, x):
        return x - ops.mean(x, axis=2, keepdims=True)


def build_classifier(bands: int, n_mels: int = N_MELS, frames: int = FRAMES, dropout: float = 0.3,
                     widths: tuple[int, ...] = (16, 32, 64, 64)) -> keras.Model:
    if not 1 <= bands <= n_mels:
        raise ValueError("bands must be in 1..n_mels")
    inp = keras.Input((n_mels, frames, 1), name="logmel")
    x = layers.Cropping2D(((0, n_mels - bands), (0, 0)), name="band_limit")(inp) if bands < n_mels else inp
    x = PerBandTimeNorm(name="per_band_time_norm")(x)
    for i, w in enumerate(widths):
        x = layers.Conv2D(w, 3, padding="same", use_bias=False, name=f"conv{i}")(x)
        x = layers.BatchNormalization(name=f"bn{i}")(x)
        x = layers.ReLU(name=f"relu{i}")(x)
        if i < len(widths) - 1:
            x = layers.MaxPooling2D(2, name=f"pool{i}")(x)
    x = layers.Concatenate(name="pool_concat")(
        [layers.GlobalMaxPooling2D(name="gmax")(x), layers.GlobalAveragePooling2D(name="gavg")(x)]
    )
    x = layers.Dropout(dropout, name="dropout")(x)
    logits = layers.Dense(len(LABELS), name="logits")(x)
    return keras.Model(inp, logits, name="kernel_cnn")


def transfer_weights(src: keras.Model, dst: keras.Model) -> list[str]:
    """Copy weights layer-by-layer by name where shapes match. Conv kernels do
    not depend on the input height, so a proxy (band-limited) classifier can
    initialise a full-band one. Returns the names of the copied layers."""
    copied = []
    by_name = {l.name: l for l in src.layers}
    for layer in dst.layers:
        w = layer.get_weights()
        if not w or layer.name not in by_name:
            continue
        sw = by_name[layer.name].get_weights()
        if len(sw) == len(w) and all(a.shape == b.shape for a, b in zip(sw, w)):
            layer.set_weights(sw)
            copied.append(layer.name)
    return copied


def build_export(classifier: keras.Model, temperature: float) -> keras.Model:
    """Classifier + temperature + softmax: outputs probabilities [1, 2]."""
    if temperature <= 0:
        raise ValueError("temperature must be positive")
    inp = keras.Input(classifier.input_shape[1:], batch_size=1, name="logmel")
    logits = classifier(inp, training=False)
    scaled = layers.Rescaling(1.0 / temperature, name="temperature")(logits)
    probs = layers.Softmax(name="probabilities")(scaled)
    return keras.Model(inp, probs, name="kernel_cnn_export")
