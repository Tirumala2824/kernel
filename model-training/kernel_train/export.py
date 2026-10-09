"""Keras -> TFLite (LiteRT) export, op audit and Python-side verification.

The app runs LiteRT 1.4.2 on the CPU (docs/decisions-log.md #16). We emit
builtin ops only (no Flex/Select TF ops, no custom ops), float32 input and
output tensors (ModelRunner requires both), and a fixed [1, 64, 198, 1]
input. Optionally dynamic-range int8 weights (activations stay float).
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import tensorflow as tf

from kernel_train.model import FRAMES, N_MELS

# Builtin ops this model family is allowed to contain. All of them predate
# LiteRT 1.4.2 by years; anything else fails the export.
ALLOWED_OPS = {
    "CONV_2D", "MAX_POOL_2D", "MEAN", "SUB", "STRIDED_SLICE", "SLICE", "REDUCE_MAX", "CONCATENATION",
    "FULLY_CONNECTED", "MUL", "SOFTMAX", "RESHAPE", "ADD", "RELU", "QUANTIZE", "DEQUANTIZE",
}


def convert(model, quantize: bool = False) -> bytes:
    """Keras 3 model -> SavedModel (frozen by the converter) -> TFLite flatbuffer."""
    import tempfile

    spec = tf.TensorSpec([1, N_MELS, FRAMES, 1], tf.float32, name="logmel")
    with tempfile.TemporaryDirectory() as tmp:
        sm = Path(tmp) / "saved_model"
        model.export(str(sm), format="tf_saved_model", verbose=False, input_signature=[spec])
        converter = tf.lite.TFLiteConverter.from_saved_model(str(sm))
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
        if quantize:
            converter.optimizations = [tf.lite.Optimize.DEFAULT]  # dynamic-range int8 weights
        return converter.convert()


def op_versions(tflite: bytes) -> dict[str, int]:
    """{builtin op name: max version used}, read from the flatbuffer itself."""
    from tensorflow.lite.python import schema_py_generated as schema

    m = schema.Model.GetRootAsModel(tflite, 0)
    names = {v: k for k, v in schema.BuiltinOperator.__dict__.items() if not k.startswith("_")}
    out: dict[str, int] = {}
    for i in range(m.OperatorCodesLength()):
        oc = m.OperatorCodes(i)
        code = max(int(oc.BuiltinCode()), int(oc.DeprecatedBuiltinCode()))
        name = names.get(code, f"UNKNOWN_{code}")
        if code == schema.BuiltinOperator.CUSTOM:
            name = f"CUSTOM:{oc.CustomCode()}"
        out[name] = max(out.get(name, 0), int(oc.Version()))
    return out


def audit(tflite: bytes) -> dict:
    ops = op_versions(tflite)
    bad = sorted(o for o in ops if o not in ALLOWED_OPS)
    if bad:
        raise RuntimeError(f"model uses ops outside the allowed builtin set: {bad}")
    interp = tf.lite.Interpreter(model_content=tflite)
    inp, out = interp.get_input_details(), interp.get_output_details()
    if len(inp) != 1 or len(out) != 1:
        raise RuntimeError("model must have exactly one input and one output")
    if inp[0]["dtype"] != np.float32 or out[0]["dtype"] != np.float32:
        raise RuntimeError("input and output must be float32")
    return {
        "ops": ops,
        "input_shape": inp[0]["shape"].tolist(),
        "output_shape": out[0]["shape"].tolist(),
        "bytes": len(tflite),
    }


class TFLiteRunner:
    def __init__(self, tflite: bytes, threads: int = 4):
        self.interp = tf.lite.Interpreter(model_content=tflite, num_threads=threads)
        self.interp.allocate_tensors()
        self.inp = self.interp.get_input_details()[0]["index"]
        self.out = self.interp.get_output_details()[0]["index"]

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """x [B, 64, 198, 1] -> [B, n_labels], one invoke per example (batch is fixed at 1)."""
        res = []
        for i in range(x.shape[0]):
            self.interp.set_tensor(self.inp, x[i : i + 1].astype(np.float32))
            self.interp.invoke()
            res.append(self.interp.get_tensor(self.out)[0].copy())
        return np.stack(res)


def save(tflite: bytes, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(tflite)
