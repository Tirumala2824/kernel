"""DSP primitives mirrored by firmware/components/kernel_detect (kd_dsp.c, kd_pdm.c).

Everything here is deterministic and uses the same formulas as the C code, so
coefficients can be compared one-to-one (tests/test_dsp.py).
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

import numpy as np
from scipy import signal as sps

# --------------------------------------------------------------------------
# Biquads (RBJ audio-EQ cookbook). One section = (b0, b1, b2, a1, a2), a0 = 1.
# --------------------------------------------------------------------------


def biquad_highpass(fs: float, fc: float, q: float) -> tuple[float, float, float, float, float]:
    w0 = 2.0 * math.pi * fc / fs
    cw, sw = math.cos(w0), math.sin(w0)
    alpha = sw / (2.0 * q)
    a0 = 1.0 + alpha
    b0 = (1.0 + cw) / 2.0 / a0
    b1 = -(1.0 + cw) / a0
    b2 = (1.0 + cw) / 2.0 / a0
    a1 = -2.0 * cw / a0
    a2 = (1.0 - alpha) / a0
    return (b0, b1, b2, a1, a2)


def biquad_lowpass(fs: float, fc: float, q: float) -> tuple[float, float, float, float, float]:
    w0 = 2.0 * math.pi * fc / fs
    cw, sw = math.cos(w0), math.sin(w0)
    alpha = sw / (2.0 * q)
    a0 = 1.0 + alpha
    b0 = (1.0 - cw) / 2.0 / a0
    b1 = (1.0 - cw) / a0
    b2 = (1.0 - cw) / 2.0 / a0
    a1 = -2.0 * cw / a0
    a2 = (1.0 - alpha) / a0
    return (b0, b1, b2, a1, a2)


def butterworth_qs(order: int) -> list[float]:
    """Q of each biquad in an even-order Butterworth cascade."""
    if order % 2:
        raise ValueError("even order only")
    return [1.0 / (2.0 * math.cos((2 * k + 1) * math.pi / (2 * order))) for k in range(order // 2)]


def butter_highpass_sections(fs: float, fc: float, order: int):
    return [biquad_highpass(fs, fc, q) for q in butterworth_qs(order)]


def butter_lowpass_sections(fs: float, fc: float, order: int):
    return [biquad_lowpass(fs, fc, q) for q in butterworth_qs(order)]


def sections_to_sos(sections) -> np.ndarray:
    return np.array([[b0, b1, b2, 1.0, a1, a2] for (b0, b1, b2, a1, a2) in sections], dtype=float)


@dataclass
class BiquadCascade:
    """Streaming Direct Form II transposed cascade (same as kd_biquad_run)."""

    sections: list
    _sos: np.ndarray = field(init=False)
    _zi: np.ndarray = field(init=False)

    def __post_init__(self) -> None:
        self._sos = sections_to_sos(self.sections)
        self._zi = np.zeros((len(self.sections), 2))

    def process(self, x: np.ndarray) -> np.ndarray:
        y, self._zi = sps.sosfilt(self._sos, np.asarray(x, dtype=float), zi=self._zi)
        return y


# US_AIR privacy high-pass: 6th-order Butterworth at 20 kHz, applied to every
# PCM sample before anything is buffered (guardrails section 10).
US_HPF_HZ = 20000.0
US_HPF_ORDER = 6

# CONTACT impulse band: 200 Hz .. 10 kHz (2nd-order HP + 2nd-order LP).
CONTACT_BP_LO_HZ = 200.0
CONTACT_BP_HI_HZ = 10000.0


def hann_periodic(n: int) -> np.ndarray:
    i = np.arange(n)
    return 0.5 - 0.5 * np.cos(2.0 * math.pi * i / n)


# --------------------------------------------------------------------------
# PDM decimation (kd_pdm.c): CIC order 4, R = 8, then a 47-tap Kaiser
# half-band FIR decimating by 2. 3.072 MHz PDM -> 384 kHz -> 192 kHz PCM.
# --------------------------------------------------------------------------

CIC_ORDER = 4
CIC_R = 8
HALFBAND_TAPS = 47
HALFBAND_BETA = 5.65


def halfband_taps(n: int = HALFBAND_TAPS, beta: float = HALFBAND_BETA) -> np.ndarray:
    if n % 4 != 3:
        raise ValueError("half-band length must be 4k+3")
    m = np.arange(n) - (n - 1) / 2.0
    h = 0.5 * np.sinc(m / 2.0) * np.kaiser(n, beta)
    h[np.abs(m) % 2 == 0] = 0.0
    h[(n - 1) // 2] = 0.5
    return h / h.sum()


class PdmDecimator:
    """Bit-exact mirror of kd_pdm_run for the CIC, float FIR afterwards."""

    def __init__(self) -> None:
        self.integ = np.zeros(CIC_ORDER, dtype=np.int64)
        self.comb = np.zeros(CIC_ORDER, dtype=np.int64)
        self.phase = 0
        self.h = halfband_taps()
        self.fir_zi = np.zeros(len(self.h) - 1)
        self.fir_phase = 0
        self.scale = 1.0 / (CIC_R**CIC_ORDER)

    def process_bits(self, bits: np.ndarray) -> np.ndarray:
        """bits: uint8 0/1 at the PDM clock rate. Returns float PCM at clock/16."""
        x = 2 * bits.astype(np.int64) - 1
        # Integrators with carried state.
        y = x
        for s in range(CIC_ORDER):
            y = np.cumsum(y) + self.integ[s]
            self.integ[s] = y[-1]
        # Decimate: keep every R-th sample, phase continuous across chunks.
        start = (CIC_R - 1 - self.phase) % CIC_R
        dec = y[start::CIC_R]
        self.phase = (self.phase + len(x)) % CIC_R
        # Combs with carried state.
        out = dec
        for s in range(CIC_ORDER):
            prev = np.concatenate(([self.comb[s]], out[:-1]))
            self.comb[s] = out[-1] if len(out) else self.comb[s]
            out = out - prev
        pcm384 = out.astype(float) * self.scale
        # Half-band FIR, keep every second output.
        f, self.fir_zi = sps.lfilter(self.h, 1.0, pcm384, zi=self.fir_zi)
        first = (1 - self.fir_phase) % 2
        res = f[first::2]
        self.fir_phase = (self.fir_phase + len(pcm384)) % 2
        return res


def sigma_delta_2(x: np.ndarray) -> np.ndarray:
    """Second-order sigma-delta modulator (test-signal helper, not firmware)."""
    bits = np.empty(len(x), dtype=np.uint8)
    i1 = i2 = 0.0
    fb = 0.0
    for n, v in enumerate(x):
        i1 += v - fb
        i2 += i1 - fb
        b = 1 if i2 >= 0 else 0
        fb = 1.0 if b else -1.0
        bits[n] = b
    return bits
