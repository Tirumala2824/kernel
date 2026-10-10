"""C (firmware/components/kernel_detect) vs Python reference on every scenario.

Runs only when a host C compiler is available: set KERNEL_CC (for example
"zig cc" or "gcc"), or have gcc/clang/cc on PATH. Otherwise the tests skip;
the C code is still syntax-checked separately (see firmware/README.md).
"""

import json
import os
import shlex
import shutil
import subprocess
import tempfile
from pathlib import Path

import numpy as np
import pytest

from kernel_ref import config as C
from kernel_ref import scenarios

FW = Path(__file__).resolve().parents[2]
KD = FW / "components" / "kernel_detect"
HARNESS = FW / "test_host" / "kd_host.c"


def _compiler():
    env = os.environ.get("KERNEL_CC")
    if env:
        return shlex.split(env)
    for cc in ("gcc", "clang", "cc"):
        if shutil.which(cc):
            return [cc]
    return None


@pytest.fixture(scope="module")
def kd_host():
    cc = _compiler()
    if cc is None:
        pytest.skip("no host C compiler (set KERNEL_CC)")
    out = Path(tempfile.mkdtemp(prefix="kd_host_")) / ("kd_host.exe" if os.name == "nt" else "kd_host")
    srcs = [str(HARNESS)] + [str(KD / f) for f in ("kd_dsp.c", "kd_pdm.c", "kd_halfband.c", "kd_spec.c", "kd_imp.c")]
    cmd = cc + ["-std=c11", "-O2", "-Wall", "-Wextra", "-Werror", f"-I{KD / 'include'}", "-o", str(out)] + srcs + ["-lm"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        pytest.fail("kernel_detect does not compile on the host:\n" + r.stderr)
    return out


def _mode(s):
    if s.sensor_type == C.SENSOR_US_AIR:
        return "us"
    if s.sensor_type == C.SENSOR_AUDIO_AIR:
        return "audio"
    return "contact"


@pytest.mark.parametrize("name", [s.name for s in scenarios.SCENARIOS])
def test_c_matches_python(kd_host, name, tmp_path):
    s = scenarios.by_name(name)
    x = s.build().astype("<f4")
    pcm = tmp_path / "in.f32"
    x.tofile(pcm)
    r = subprocess.run([str(kd_host), _mode(s), str(pcm)], capture_output=True, text=True, timeout=600)
    assert r.returncode == 0, r.stderr
    rows = [json.loads(line) for line in r.stdout.splitlines() if line.strip()]
    summary = rows[-1]
    c_events = rows[:-1]
    py = scenarios.result(name)
    assert summary["jammed"] == py.jammed_ever
    assert summary["clipped"] == py.clipped_ever
    assert [e["cls"] for e in c_events] == [e.cls for e in py.events]
    for ce, pe in zip(c_events, py.events):
        hop = 1000.0 * (C.US_AIR_SPEC.hop / C.US_AIR_SPEC.fs if s.sensor_type == C.SENSOR_US_AIR else 0.5)
        assert abs(ce["t"] - pe.t_start_ms) <= 2 * hop + 1
        assert abs(ce["dur"] - pe.duration_ms) <= 2 * hop + 1
        assert abs(ce["peak"] - pe.peak_hz) <= max(400.0, 0.02 * pe.peak_hz)
        assert abs(ce["snr"] - pe.snr_db) <= 1.5
        assert ce["imp"] == pe.impulses
        assert ce["harm"] == pe.harmonics
        assert ce["flags"] == pe.flags
        assert np.isclose(ce["rep"], pe.rep_rate_hz, rtol=0.05, atol=0.2)
