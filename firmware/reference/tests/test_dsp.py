import math
import re
from pathlib import Path

import numpy as np
from scipy import signal as sps

from kernel_ref import dsp

ROOT = Path(__file__).resolve().parents[1]


def _gain_db(sos: np.ndarray, fs: float, f: float) -> float:
    _, h = sps.sosfreqz(sos, worN=[f], fs=fs)
    return 20 * math.log10(abs(h[0]))


def test_butterworth_cascade_matches_scipy():
    ours = dsp.sections_to_sos(dsp.butter_highpass_sections(192000, 20000, 6))
    ref = sps.butter(6, 20000, "highpass", fs=192000, output="sos")
    for f in (5000, 15000, 20000, 22000, 40000, 80000):
        assert abs(_gain_db(ours, 192000, f) - _gain_db(ref, 192000, f)) < 1e-6


def test_us_highpass_rejects_audible_band():
    sos = dsp.sections_to_sos(dsp.butter_highpass_sections(192000, dsp.US_HPF_HZ, dsp.US_HPF_ORDER))
    assert _gain_db(sos, 192000, 20000) == __import__("pytest").approx(-3.01, abs=0.05)
    assert _gain_db(sos, 192000, 10000) < -35.0
    assert _gain_db(sos, 192000, 4000) < -80.0
    assert _gain_db(sos, 192000, 30000) > -0.1


def test_contact_bandpass_edges():
    sos = dsp.sections_to_sos(dsp.butter_highpass_sections(48000, 200, 2) + dsp.butter_lowpass_sections(48000, 10000, 2))
    assert _gain_db(sos, 48000, 2000) > -0.1
    assert _gain_db(sos, 48000, 50) < -20.0
    assert _gain_db(sos, 48000, 20000) < -12.0


def test_halfband_taps_shape_and_c_table():
    h = dsp.halfband_taps()
    assert len(h) == 47
    assert abs(h.sum() - 1.0) < 1e-12
    assert np.allclose(h, h[::-1])
    c = len(h) // 2
    for i in range(len(h)):
        if i != c and (i - c) % 2 == 0:
            assert h[i] == 0.0
    w, resp = sps.freqz(h, worN=[60000, 80000, 112000, 150000], fs=384000)
    db = 20 * np.log10(np.abs(resp))
    assert abs(db[0]) < 0.01 and abs(db[1]) < 0.05  # passband to 80 kHz
    assert db[2] < -55 and db[3] < -55  # stopband from 112 kHz (aliases into 80 kHz)
    text = (ROOT.parent / "components" / "kernel_detect" / "kd_halfband.c").read_text(encoding="utf-8")
    vals = [float(v) for v in re.findall(r"(-?\d\.\d+e[+-]\d+)f", text)]
    assert len(vals) == 47
    assert np.allclose(vals, h, rtol=0, atol=1e-9)


def test_pdm_chain_recovers_ultrasound_and_rejects_audible():
    fs_pdm = 3072000
    n = int(0.08 * fs_pdm)
    t = np.arange(n) / fs_pdm
    x = 0.25 * np.sin(2 * math.pi * 40000 * t) + 0.25 * np.sin(2 * math.pi * 6000 * t)
    bits = dsp.sigma_delta_2(x)
    dec = dsp.PdmDecimator()
    # Feed in uneven chunks to exercise the carried state.
    out = np.concatenate([dec.process_bits(bits[i: i + 7777]) for i in range(0, len(bits), 7777)])
    assert len(out) == n // 16
    hp = dsp.BiquadCascade(dsp.butter_highpass_sections(192000, dsp.US_HPF_HZ, dsp.US_HPF_ORDER))
    y = hp.process(out)[4000:]
    spec = np.abs(np.fft.rfft(y * np.hanning(len(y))))
    f = np.fft.rfftfreq(len(y), 1 / 192000)

    def peak(f0):
        sel = (f > f0 - 500) & (f < f0 + 500)
        return 20 * np.log10(spec[sel].max())

    assert peak(40000) - peak(6000) > 60.0  # audible tone removed before any buffering
    raw = np.abs(np.fft.rfft(out[4000:] * np.hanning(len(out) - 4000)))
    fr = np.fft.rfftfreq(len(out) - 4000, 1 / 192000)
    k40 = np.argmin(np.abs(fr - 40000))
    amp = raw[k40 - 3: k40 + 4].max() * 2 / np.hanning(len(out) - 4000).sum()
    assert 0.2 < amp < 0.3  # CIC + half-band keep unity gain at 40 kHz


def test_cic_bit_exact_on_constant_input():
    dec = dsp.PdmDecimator()
    ones = np.ones(16 * 200, dtype=np.uint8)
    y = dec.process_bits(ones)
    assert np.allclose(y[-50:], 1.0, atol=1e-9)
