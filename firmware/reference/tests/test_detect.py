"""Detector behaviour on the synthetic scenarios (kernel_ref.scenarios)."""

import numpy as np
import pytest

from kernel_ref import config as C
from kernel_ref import detect, scenarios, synth


def classes(name):
    return [e.class_name for e in scenarios.result(name).events]


@pytest.mark.parametrize("name", ["us_rat_22k", "us_rat_50k", "us_mouse_70k"])
def test_usv_sweeps_detected_at_192k(name):
    s = scenarios.by_name(name)
    r = scenarios.result(name)
    assert classes(name) == s.expect_classes
    assert not r.jammed_ever and not r.clipped_ever
    ev = r.events[0]
    assert 1490 < ev.t_start_ms < 1540  # Tukey fade-in delays the 600 ms call
    assert ev.snr_db > 20


def test_usv_features_match_the_synthetic_calls():
    rat22 = scenarios.result("us_rat_22k").events[0]
    assert 21500 < rat22.min_hz and rat22.max_hz < 23300
    assert rat22.duration_ms >= 500
    assert rat22.max_hz - rat22.min_hz < 3000  # near-constant: below the FM gate
    rat50 = scenarios.result("us_rat_50k").events[0]
    assert 45000 < rat50.min_hz < 47500 and 56000 < rat50.max_hz < 58500
    assert 250 < rat50.slope_hz_per_ms < 400  # 13 kHz over 40 ms = 325 Hz/ms
    mouse = scenarios.result("us_mouse_70k").events[0]
    assert 64000 < mouse.min_hz and mouse.max_hz < 76500
    assert 25 <= mouse.duration_ms <= 40


def test_mankin_bursts_detected_and_rate_computed():
    s = scenarios.by_name("contact_larva_bursts")
    r = scenarios.result("contact_larva_bursts")
    assert classes(s.name) == ["impulseBurst"] * len(scenarios.LARVA_BURSTS_S)
    for ev, tb in zip(r.events, scenarios.LARVA_BURSTS_S):
        assert abs(ev.t_start_ms - tb * 1000) < 2
        assert ev.impulses >= 3
        assert not ev.flags & C.EF_REGULAR_TRAIN  # irregular feeding clicks
        assert 200 <= ev.min_hz <= ev.max_hz <= 10000
    rate = detect.burst_rate_per_s(r.events, s.rate_window_s)
    assert rate == pytest.approx(6 / 180)
    assert rate >= 0.02  # the literature "possible" threshold


def test_termite_15hz_pulse_train():
    r = scenarios.result("contact_termite_15hz")
    assert classes("contact_termite_15hz") == ["impulseBurst"]
    ev = r.events[0]
    assert ev.impulses == 12
    assert ev.rep_rate_hz == pytest.approx(15.0, abs=0.5)
    assert ev.flags & C.EF_REGULAR_TRAIN
    assert 0 <= ev.ipi_cv < 0.05


@pytest.mark.parametrize("name", ["us_repeller_40k", "us_repeller_onset"])
def test_stationary_40k_repeller_is_jammed_not_an_event(name):
    r = scenarios.result(name)
    assert r.jammed_ever
    assert r.events == []
    assert r.final_health & detect.H_JAMMED


def test_repeller_onset_flags_after_jam_hold():
    log = scenarios.result("us_repeller_onset").health_log
    t_jam = next(t for t, h in log if h & detect.H_JAMMED)
    assert 1500 + 2000 - 20 <= t_jam <= 1500 + 2000 + 100


def test_jam_band_mask_points_at_40k():
    r = scenarios.result("us_repeller_40k")
    bf = r.band_frames[-1]
    assert bf.flags & detect.H_JAMMED
    edges = C.US_AIR_SPEC.band_edges_hz
    hit = [b for b in range(len(edges) - 1) if bf.jam_mask >> b & 1]
    assert hit
    # 40 kHz sits on the edge between band 4 (36-40 kHz) and band 5 (40-44 kHz).
    assert set(hit) <= {4, 5}


@pytest.mark.parametrize("name", ["us_white_noise", "contact_white_noise", "audio_white_noise"])
def test_white_noise_gives_no_events(name):
    r = scenarios.result(name)
    assert r.events == []
    assert not r.jammed_ever and not r.clipped_ever


def test_clipping_reports_clipped_and_no_events():
    r = scenarios.result("us_clipping")
    assert r.clipped_ever
    assert r.events == []
    t_clip = next(t for t, h in r.health_log if h & detect.H_CLIPPED)
    assert 1490 <= t_clip <= 1510


def test_audio_mosquito_and_cricket():
    mos = scenarios.result("audio_mosquito").events
    assert [e.class_name for e in mos] == ["harmonic"]
    assert 430 < mos[0].peak_hz < 470 and mos[0].harmonics >= 2
    cr = scenarios.result("audio_cricket").events
    assert [e.class_name for e in cr] == ["pulsedChirp"] * 3
    for e in cr:
        assert e.impulses == 4 and 4400 < e.peak_hz < 4800
        assert e.rep_rate_hz == pytest.approx(1000 / 35, abs=1.5)


def test_events_suppressed_during_warmup():
    fs = C.US_AIR_SPEC.fs
    x = synth.white(fs, 2.0, seed=91)
    synth.add_at(x, synth.sweep(fs, 45000, 58000, 40, scenarios.US_AMP), fs, 0.5)
    r = detect.run_spectral_node(x, C.US_AIR_SPEC, C.DEFAULT_CLIP, highpass=True)
    assert r.events == []


def test_survey_gating_suppresses_events():
    cfg = C.US_AIR_SPEC
    x = scenarios.by_name("us_rat_50k").build()
    det = detect.SpectralDetector(cfg)
    for i in range(0, len(x), cfg.hop):
        det.push(x[i: i + cfg.hop], survey=True)
    det.finish()
    assert det.events == []


def test_running_quantile_converges_to_5_percent():
    gen = np.random.default_rng(5)
    q = detect.RunningQuantile(C.FloorConfig(), rate_hz=750.0)
    xs = gen.normal(0.0, 1.0, 40000)
    for i, v in enumerate(xs):
        q.update(np.array([v]), max(0.0, 1 - i / 750))
    assert float(q.value[0]) == pytest.approx(-1.645, abs=0.15)


def test_clip_detector_hold():
    c = detect.ClipDetector(C.ClipConfig(), 1000)
    c.push(np.array([0.0, 0.99, 0.99, 0.99]))
    assert c.active
    c.push(np.zeros(2100))
    assert not c.active
    c2 = detect.ClipDetector(C.ClipConfig(), 1000)
    c2.push(np.array([0.99, 0.0, 0.99] + [0.0] * 200 + [0.99]))  # 3 hits but split across windows
    assert not c2.ever
