"""Reference detectors, mirrored line by line by firmware/components/kernel_detect.

* SpectralDetector  (kd_spec.c): STFT, 5 % running-quantile noise floor per bin
  and per band, stationary-line / jammer detection, single-track tonal/FM blob
  detector with duration and FM gates, harmonic search and chirp grouping.
* ImpulseDetector   (kd_imp.c): band-passed block energy, impulse detector,
  burst grouping and pulse-train regularity.
* ClipDetector      (kd_clip.c): ADC clipping on raw samples.

The detectors only ever see features of the current frame or block; nothing
here keeps audio beyond one analysis frame.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

import numpy as np

from . import dsp
from .config import (
    CLASS_NAMES,
    CONTINUOUS_EMITTER,
    EF_REGULAR_TRAIN,
    EF_TRUNCATED,
    FLAT_TONE,
    FM_SWEEP,
    HARMONIC,
    IMPULSE_BURST,
    PULSED_CHIRP,
    TONAL,
    ClipConfig,
    FloorConfig,
    ImpulseConfig,
    SpecConfig,
)

H_JAMMED = 0x01
H_CLIPPED = 0x02
H_WARMING = 0x04
H_SURVEY = 0x08

EPS = 1e-20


def rnd(v: float) -> int:
    """Half away from zero, like kd_lround in C (Python's round() is banker's)."""
    return int(math.floor(v + 0.5)) if v >= 0 else -int(math.floor(-v + 0.5))
SINE_DBFS_OFFSET = 10.0 * math.log10(2.0)  # mean(sin^2) = 1/2


@dataclass
class DetEvent:
    t_start_ms: float
    duration_ms: float
    cls: int
    flags: int
    peak_hz: float
    min_hz: float
    max_hz: float
    slope_hz_per_ms: float
    snr_db: float
    peak_dbfs: float
    impulses: int
    harmonics: int
    rep_rate_hz: float
    ipi_cv: float  # -1 when not applicable

    @property
    def class_name(self) -> str:
        return CLASS_NAMES[self.cls]

    @property
    def end_ms(self) -> float:
        return self.t_start_ms + self.duration_ms


@dataclass
class BandFrameOut:
    t_ms: float
    frame_ms: float
    flags: int
    noise_floor_dbfs: float
    peak_hz: float
    peak_dbfs: float
    jam_mask: int
    bands_db: list[float]


def _ipi_cv(onsets_ms: list[float]) -> float:
    if len(onsets_ms) < 3:
        return -1.0
    d = np.diff(np.asarray(onsets_ms, dtype=float))
    m = float(d.mean())
    if m <= 0:
        return -1.0
    return float(d.std() / m)


def _rep_rate(onsets_ms: list[float]) -> float:
    if len(onsets_ms) < 2:
        return 0.0
    span = (onsets_ms[-1] - onsets_ms[0]) / 1000.0
    return (len(onsets_ms) - 1) / span if span > 0 else 0.0


class RunningQuantile:
    """Stochastic 5 % quantile tracker in dB (kd_floor_update).

    q <- q - eta (1 - p)  when x < q
    q <- q + eta p        otherwise
    The equilibrium is P(x < q) = p. eta is chosen so that the upward drift is
    `up_db_per_s`; the downward step is (1-p)/p = 19 times larger, so the
    floor follows quiet periods quickly and rises slowly under long signals.
    During warm-up eta is multiplied by a factor that falls linearly from
    `warmup_speedup` to 1, so the estimate converges fast and then settles.
    """

    def __init__(self, cfg: FloorConfig, rate_hz: float) -> None:
        self.p = cfg.quantile
        self.eta = cfg.up_db_per_s / (cfg.quantile * rate_hz)
        self.speedup = cfg.warmup_speedup
        self.value: np.ndarray | None = None

    def update(self, x: np.ndarray, warm_left: float) -> None:
        """warm_left: 1.0 at the first frame of warm-up, 0.0 once it is over."""
        if self.value is None:
            self.value = np.array(x, dtype=float, copy=True)
            return
        eta = self.eta * (1.0 + (self.speedup - 1.0) * warm_left)
        below = x < self.value
        self.value = np.where(below, self.value - eta * (1.0 - self.p), self.value + eta * self.p)


@dataclass
class _Blob:
    first: int
    last: int
    last_k: int
    n: int = 0
    fmin: float = math.inf
    fmax: float = -math.inf
    peak_level: float = -math.inf
    peak_hz: float = 0.0
    max_excess: float = 0.0
    st: float = 0.0
    sf: float = 0.0
    stt: float = 0.0
    stf: float = 0.0
    harm_frames: int = 0
    harm_sum: int = 0
    tainted: bool = False


class ClipDetector:
    """kd_clip: clipped-sample counter in windows aligned to the absolute sample index."""

    def __init__(self, cfg: ClipConfig, fs: int) -> None:
        self.cfg = cfg
        self.win = max(1, rnd((cfg.window_ms * fs / 1000.0)))
        self.hold = rnd((cfg.hold_ms * fs / 1000.0))
        self.n_total = 0
        self.cur_win = -1
        self.win_count = 0
        self.hold_until = -1
        self.ever = False

    def push(self, x: np.ndarray) -> None:
        x = np.asarray(x, dtype=float)
        base = self.n_total
        for i in np.nonzero(np.abs(x) >= self.cfg.level)[0]:
            n = base + int(i)
            w = n // self.win
            if w != self.cur_win:
                self.cur_win = w
                self.win_count = 0
            self.win_count += 1
            if self.win_count >= self.cfg.count:
                self.hold_until = n + self.hold
                self.ever = True
        self.n_total = base + len(x)

    @property
    def active(self) -> bool:
        return self.n_total <= self.hold_until


class SpectralDetector:
    def __init__(self, cfg: SpecConfig, events_enabled: bool = True) -> None:
        self.cfg = cfg
        self.events_enabled = events_enabled
        n = cfg.n_fft
        self.nb = n // 2 + 1
        self.win = dsp.hann_periodic(n)
        self.pscale = (2.0 / self.win.sum()) ** 2
        self.bin_hz = cfg.fs / n
        self.hop_ms = 1000.0 * cfg.hop / cfg.fs
        fps = cfg.fs / cfg.hop
        self.k_lo = max(1, int(math.ceil(cfg.lo_hz / self.bin_hz)))
        self.k_hi = min(self.nb - 2, int(math.floor(cfg.hi_hz / self.bin_hz)))
        edges = cfg.band_edges_hz
        self.n_bands = len(edges) - 1
        self.band_lo = []
        self.band_hi = []
        for b in range(self.n_bands):
            k0 = max(self.k_lo, int(math.ceil(edges[b] / self.bin_hz)))
            k1 = min(self.k_hi, int(math.ceil(edges[b + 1] / self.bin_hz)) - 1)
            if k1 < k0:
                k1 = k0
            self.band_lo.append(k0)
            self.band_hi.append(k1)
        self.floor = RunningQuantile(cfg.floor, fps)
        self.bfloor = RunningQuantile(cfg.floor, fps)
        self.warmup_frames = int(math.ceil(cfg.floor.warmup_ms / self.hop_ms))
        self.min_blob_frames = max(1, int(math.ceil(cfg.min_blob_ms / self.hop_ms - 1e-9)))
        self.max_gap_frames = int(math.floor(cfg.max_gap_ms / self.hop_ms + 1e-9))
        self.max_jump_bins = max(1, rnd((cfg.max_jump_hz / self.bin_hz)))
        self.max_blob_frames = int(math.ceil(cfg.max_blob_ms / self.hop_ms))
        self.jam_hold_frames = int(math.ceil(cfg.jam_hold_ms / self.hop_ms))
        self.jam_release_frames = int(math.ceil(cfg.jam_release_ms / self.hop_ms))
        self.line_block_frames = max(1, rnd((cfg.line_block_ms / self.hop_ms)))
        self.line_blocks = min(16, max(1, int(math.ceil(cfg.jam_hold_ms / cfg.line_block_ms))))
        self.band_frame_frames = max(1, rnd((cfg.band_frame_ms / self.hop_ms)))

        self.pending = np.zeros(0)
        self.hist = np.zeros((cfg.smooth_frames, self.nb))
        self.frame = 0
        # Jammer state.
        self.run = np.zeros(self.n_bands, dtype=int)
        self.occ_any = 0
        self.occ_n = 0
        self.occ_flag = False
        self.blk_min = np.full(self.nb, math.inf)
        self.blk_n = 0
        self.blk_ring: list[np.ndarray] = []
        self.line_mask_bins = np.zeros(self.nb, dtype=bool)
        self.jam_left = 0
        self.jammed = False
        self.jam_band_mask = 0
        self.jammed_ever = False
        self.clipped = False
        self.survey = False
        # Blob / chirp state.
        self.blob: _Blob | None = None
        self.gap = 0
        self.chirp: list[DetEvent] = []
        self.events: list[DetEvent] = []
        # Band-frame aggregation.
        self.bf_max = np.zeros(self.n_bands)
        self.bf_peak_l = -math.inf
        self.bf_peak_hz = 0.0
        self.bf_n = 0
        self.bf_start = 0
        self.bf_flags = 0
        self.band_frames: list[BandFrameOut] = []
        self.health_log: list[tuple[float, int]] = []
        self._last_health = -1

    # ----------------------------------------------------------------- input
    def push(self, x: np.ndarray, clipped: bool = False, survey: bool = False) -> None:
        self.clipped = clipped
        self.survey = survey
        self.pending = np.concatenate((self.pending, np.asarray(x, dtype=float)))
        n, hop = self.cfg.n_fft, self.cfg.hop
        while len(self.pending) >= n:
            self._frame(self.pending[:n])
            self.pending = self.pending[hop:]

    def finish(self) -> None:
        if self.blob is not None:
            self._close_blob(truncated=False)
        self._flush_chirp()

    @property
    def health(self) -> int:
        h = 0
        if self.jammed:
            h |= H_JAMMED
        if self.clipped:
            h |= H_CLIPPED
        if self.frame < self.warmup_frames:
            h |= H_WARMING
        if self.survey:
            h |= H_SURVEY
        return h

    # ------------------------------------------------------------- per frame
    def _interp(self, l: np.ndarray, k: int) -> float:
        a, b, c = l[k - 1], l[k], l[k + 1]
        den = a - 2.0 * b + c
        d = 0.0 if den == 0 else 0.5 * (a - c) / den
        d = max(-0.5, min(0.5, d))
        return (k + d) * self.bin_hz

    def _frame(self, x: np.ndarray) -> None:
        cfg = self.cfg
        i = self.frame
        t_ms = i * self.hop_ms
        spec = np.fft.rfft(x * self.win)
        p = (spec.real**2 + spec.imag**2) * self.pscale
        pf = p.copy()
        pf[1:-1] = 0.25 * p[:-2] + 0.5 * p[1:-1] + 0.25 * p[2:]
        self.hist[i % cfg.smooth_frames] = pf
        cnt = min(i + 1, cfg.smooth_frames)
        s = self.hist[:cnt].mean(axis=0) if cnt < cfg.smooth_frames else self.hist.mean(axis=0)
        level = 10.0 * np.log10(s + EPS)
        bsum = np.array([s[self.band_lo[b]: self.band_hi[b] + 1].sum() for b in range(self.n_bands)])
        blevel = 10.0 * np.log10(bsum + EPS)

        warming = i < self.warmup_frames
        warm_left = (1.0 - i / self.warmup_frames) if warming else 0.0
        if self.floor.value is None:
            self.floor.update(level, 1.0)
            self.bfloor.update(blevel, 1.0)
        floor = self.floor.value
        bfloor = self.bfloor.value
        exc = level - floor
        self.last_level = level
        self.last_exc = exc
        bexc = blevel - bfloor

        seg = exc[self.k_lo: self.k_hi + 1]
        kp = self.k_lo + int(np.argmax(seg))
        active = bool(exc[kp] >= cfg.detect_thresh_db)
        self._jam_update(level, floor, bexc, warming, active)
        evaluated = not (warming or self.jammed or self.clipped or self.survey)

        # ---- blob tracking on the strongest excess bin
        if self.events_enabled:
            self._track(i, t_ms, level, exc, evaluated, kp, active)
            if self.chirp and (t_ms - self.chirp[-1].end_ms) > cfg.chirp_max_gap_ms:
                self._flush_chirp()

        # ---- band frames
        self._band_frame(i, t_ms, level, floor, bexc)

        # ---- floors (after detection, so detection uses the previous floor)
        self.floor.update(level, warm_left)
        self.bfloor.update(blevel, warm_left)

        h = self.health
        if h != self._last_health:
            self.health_log.append((t_ms, h))
            self._last_health = h
        self.frame += 1

    def _jam_update(self, level, floor, bexc, warming, active) -> None:
        cfg = self.cfg
        # (a) band held above floor + jam_thresh: leaky run, a missed frame
        # costs jam_miss_penalty frames of credit.
        above = bexc >= cfg.jam_thresh_db
        self.run = np.where(above, self.run + 1, np.maximum(0, self.run - cfg.jam_miss_penalty))
        stationary = self.run >= self.jam_hold_frames

        # (c) detector busy in >= jam_occupancy of the frames (sweepers).
        self.occ_any += int(active)
        self.occ_n += 1
        if self.occ_n >= self.jam_hold_frames:
            self.occ_flag = self.occ_any >= cfg.jam_occupancy * self.occ_n
            self.occ_any = 0
            self.occ_n = 0

        self.blk_min = np.minimum(self.blk_min, level)
        self.blk_n += 1
        if self.blk_n >= self.line_block_frames:
            self.blk_ring.append(self.blk_min)
            if len(self.blk_ring) > self.line_blocks:
                self.blk_ring.pop(0)
            self.blk_min = np.full(self.nb, math.inf)
            self.blk_n = 0
            if len(self.blk_ring) == self.line_blocks:
                self.line_mask_bins = self._lines(np.min(np.array(self.blk_ring), axis=0), floor)

        line_any = bool(self.line_mask_bins.any())
        cond = bool(stationary.any()) or self.occ_flag or line_any
        if warming:
            cond = False
        if cond:
            self.jam_left = self.jam_release_frames
        elif self.jam_left > 0:
            self.jam_left -= 1
        self.jammed = cond or self.jam_left > 0
        if self.jammed:
            self.jammed_ever = True
        mask = 0
        for b in range(self.n_bands):
            if stationary[b] or self.line_mask_bins[self.band_lo[b]: self.band_hi[b] + 1].any():
                mask |= 1 << b
        self.jam_band_mask = mask

    def _lines(self, minhold: np.ndarray, floor: np.ndarray) -> np.ndarray:
        cfg = self.cfg
        out = np.zeros(self.nb, dtype=bool)
        lo, hi = cfg.line_neigh_lo, cfg.line_neigh_hi
        for k in range(self.k_lo, self.k_hi + 1):
            neigh = []
            for d in range(lo, hi + 1):
                if k - d >= self.k_lo:
                    neigh.append(floor[k - d])
                if k + d <= self.k_hi:
                    neigh.append(floor[k + d])
            if len(neigh) < 6:
                continue
            if minhold[k] - float(np.median(neigh)) >= cfg.jam_thresh_db:
                out[k] = True
        return out

    def _harmonics(self, exc: np.ndarray, level: np.ndarray, kp: int) -> tuple[int, int]:
        cfg = self.cfg
        thr = cfg.detect_thresh_db - cfg.harmonic_rel_db
        k0 = kp
        for h in (4, 3, 2):
            kc = rnd((kp / h))
            if kc - 1 < self.k_lo or kc < 3:
                continue
            seg = exc[kc - 1: kc + 2]
            kk = kc - 1 + int(np.argmax(seg))
            local_peak = exc[kk] >= exc[kk - 1] and exc[kk] >= exc[kk + 1]
            if exc[kk] >= thr and local_peak and kk <= kp - 3:
                k0 = kk
                break
        f0 = self._interp(level, k0) / self.bin_hz
        hc = 0
        for m in range(2, cfg.max_harmonics + 1):
            km = rnd((m * f0))
            if km + 1 > self.k_hi:
                break
            if exc[km - 1: km + 2].max() >= thr:
                hc += 1
        return k0, hc

    def _track(self, i: int, t_ms: float, level, exc, evaluated: bool, kp: int, active: bool) -> None:
        cfg = self.cfg
        if self.blob is not None and not evaluated:
            self.blob.tainted = True
        if not active:
            if self.blob is not None:
                self.gap += 1
                if self.gap > self.max_gap_frames:
                    self._close_blob(truncated=False)
            return
        hc = 0
        k_track = kp
        if cfg.harmonic_search:
            k_track, hc = self._harmonics(exc, level, kp)
        if self.blob is not None and abs(k_track - self.blob.last_k) > self.max_jump_bins:
            self._close_blob(truncated=False)
        if self.blob is not None and (i - self.blob.first + 1) > self.max_blob_frames:
            self._close_blob(truncated=True)
        if self.blob is None:
            self.blob = _Blob(first=i, last=i, last_k=k_track, tainted=not evaluated)
        b = self.blob
        f = self._interp(level, k_track)
        t_rel = (i - b.first) * self.hop_ms
        b.last = i
        b.last_k = k_track
        b.n += 1
        b.fmin = min(b.fmin, f)
        b.fmax = max(b.fmax, f)
        if level[k_track] > b.peak_level:
            b.peak_level = float(level[k_track])
            b.peak_hz = f
        b.max_excess = max(b.max_excess, float(exc[k_track]))
        b.st += t_rel
        b.sf += f
        b.stt += t_rel * t_rel
        b.stf += t_rel * f
        if hc >= 1:
            b.harm_frames += 1
        b.harm_sum += hc
        self.gap = 0

    def _close_blob(self, truncated: bool) -> None:
        cfg = self.cfg
        b = self.blob
        self.blob = None
        self.gap = 0
        if b is None or b.tainted:
            return
        span = b.last - b.first + 1
        if span < self.min_blob_frames:
            return
        dur = span * self.hop_ms
        bw = b.fmax - b.fmin
        slope = 0.0
        den = b.n * b.stt - b.st * b.st
        if b.n >= 2 and den > 0:
            slope = (b.n * b.stf - b.st * b.sf) / den
        harmonics = rnd((b.harm_sum / b.n)) if b.n else 0
        if cfg.harmonic_search and b.harm_frames * 2 >= b.n and harmonics >= 1:
            cls = HARMONIC
        elif dur >= cfg.cont_min_ms:
            cls = CONTINUOUS_EMITTER if bw >= cfg.fm_min_bw_hz else FLAT_TONE
        elif bw >= cfg.fm_min_bw_hz:
            cls = FM_SWEEP
        elif dur >= cfg.flat_min_ms:
            cls = FLAT_TONE
        else:
            cls = TONAL
        ev = DetEvent(
            t_start_ms=b.first * self.hop_ms,
            duration_ms=dur,
            cls=cls,
            flags=EF_TRUNCATED if truncated else 0,
            peak_hz=b.peak_hz,
            min_hz=b.fmin,
            max_hz=b.fmax,
            slope_hz_per_ms=slope,
            snr_db=b.max_excess,
            peak_dbfs=b.peak_level,
            impulses=0,
            harmonics=harmonics if cls == HARMONIC else 0,
            rep_rate_hz=0.0,
            ipi_cv=-1.0,
        )
        if cfg.chirp_grouping and cls == TONAL and dur <= cfg.chirp_pulse_max_ms:
            c = self.chirp
            if c and (ev.t_start_ms - c[-1].end_ms) <= cfg.chirp_max_gap_ms and abs(
                ev.peak_hz - c[0].peak_hz
            ) <= cfg.chirp_freq_tol * c[0].peak_hz:
                c.append(ev)
            else:
                self._flush_chirp()
                self.chirp = [ev]
            return
        self.events.append(ev)

    def _flush_chirp(self) -> None:
        c = self.chirp
        self.chirp = []
        if not c:
            return
        if len(c) < self.cfg.train_min_pulses:
            self.events.extend(c)
            return
        onsets = [e.t_start_ms for e in c]
        cv = _ipi_cv(onsets)
        flags = EF_REGULAR_TRAIN if 0 <= cv <= self.cfg.chirp_max_cv else 0
        self.events.append(
            DetEvent(
                t_start_ms=c[0].t_start_ms,
                duration_ms=c[-1].end_ms - c[0].t_start_ms,
                cls=PULSED_CHIRP,
                flags=flags,
                peak_hz=float(np.mean([e.peak_hz for e in c])),
                min_hz=min(e.min_hz for e in c),
                max_hz=max(e.max_hz for e in c),
                slope_hz_per_ms=0.0,
                snr_db=max(e.snr_db for e in c),
                peak_dbfs=max(e.peak_dbfs for e in c),
                impulses=len(c),
                harmonics=0,
                rep_rate_hz=_rep_rate(onsets),
                ipi_cv=cv,
            )
        )

    def _band_frame(self, i: int, t_ms: float, level, floor, bexc) -> None:
        if self.bf_n == 0:
            self.bf_start = t_ms
            self.bf_max[:] = 0.0
            self.bf_peak_l = -math.inf
            self.bf_flags = 0
        self.bf_max = np.maximum(self.bf_max, np.maximum(bexc, 0.0))
        seg = level[self.k_lo: self.k_hi + 1]
        k = self.k_lo + int(np.argmax(seg))
        if level[k] > self.bf_peak_l:
            self.bf_peak_l = float(level[k])
            self.bf_peak_hz = k * self.bin_hz
        self.bf_flags |= self.health
        self.bf_n += 1
        if self.bf_n >= self.band_frame_frames:
            self.band_frames.append(
                BandFrameOut(
                    t_ms=self.bf_start,
                    frame_ms=self.bf_n * self.hop_ms,
                    flags=self.bf_flags,
                    noise_floor_dbfs=float(np.median(floor[self.k_lo: self.k_hi + 1])),
                    peak_hz=self.bf_peak_hz,
                    peak_dbfs=self.bf_peak_l,
                    jam_mask=self.jam_band_mask,
                    bands_db=[float(v) for v in self.bf_max],
                )
            )
            self.bf_n = 0


@dataclass
class _Impulse:
    t_start_ms: float
    t_end_ms: float
    freq_hz: float
    peak_dbfs: float
    excess_db: float


class ImpulseDetector:
    def __init__(self, cfg: ImpulseConfig) -> None:
        self.cfg = cfg
        self.block_n = max(1, rnd((cfg.block_ms * cfg.fs / 1000.0)))
        self.block_ms = 1000.0 * self.block_n / cfg.fs
        bps = cfg.fs / self.block_n
        self.bp = dsp.BiquadCascade(
            dsp.butter_highpass_sections(cfg.fs, cfg.bp_lo_hz, 2)
            + dsp.butter_lowpass_sections(cfg.fs, cfg.bp_hi_hz, 2)
        )
        self.eta = cfg.floor.up_db_per_s / (cfg.floor.quantile * bps)
        self.floor_db: float | None = None
        self.warmup_blocks = int(math.ceil(cfg.floor.warmup_ms / self.block_ms))
        self.jam_hold_blocks = int(math.ceil(cfg.jam_hold_ms / self.block_ms))
        self.jam_release_blocks = int(math.ceil(cfg.jam_release_ms / self.block_ms))
        self.pending = np.zeros(0)
        self.prev_sample = 0.0
        self.block = 0
        self.run = 0
        self.jam_left = 0
        self.jammed = False
        self.jammed_ever = False
        self.clipped = False
        self.in_imp = False
        self.imp_start = 0
        self.imp_n = 0
        self.imp_zc = 0
        self.imp_peak_l = -math.inf
        self.imp_peak_e = 0.0
        self.imp_tainted = False
        self.burst: list[_Impulse] = []
        self.burst_tainted = False
        self.events: list[DetEvent] = []
        self.health_log: list[tuple[float, int]] = []
        self._last_health = -1

    @property
    def health(self) -> int:
        h = 0
        if self.jammed:
            h |= H_JAMMED
        if self.clipped:
            h |= H_CLIPPED
        if self.block < self.warmup_blocks:
            h |= H_WARMING
        return h

    def push(self, x: np.ndarray, clipped: bool = False) -> None:
        self.clipped = clipped
        buf = np.concatenate((self.pending, self.bp.process(x)))
        n = self.block_n
        nblk = len(buf) // n
        if nblk:
            used = buf[: nblk * n]
            blocks = used.reshape(nblk, n)
            levels = 10.0 * np.log10(np.mean(blocks * blocks, axis=1) + EPS) + SINE_DBFS_OFFSET
            signs = np.signbit(np.concatenate(([self.prev_sample], used)))
            zcs = (signs[1:] != signs[:-1]).reshape(nblk, n).sum(axis=1)
            self.prev_sample = float(used[-1])
            for level, zc in zip(levels.tolist(), zcs.tolist()):
                self._block(level, int(zc))
        self.pending = buf[nblk * n:]

    def finish(self) -> None:
        self._close_burst(truncated=False)

    def _block(self, level: float, zc: int) -> None:
        """One 0.5 ms block: level in dBFS, zc = zero crossings within the block."""
        cfg = self.cfg
        i = self.block
        t_ms = i * self.block_ms
        warming = i < self.warmup_blocks
        warm_left = (1.0 - i / self.warmup_blocks) if warming else 0.0
        if self.floor_db is None:
            self.floor_db = level
        floor = self.floor_db
        exc = level - floor
        self.last_level = level
        self.last_exc = exc

        # Stationary vibration (motor, pump): excess held for jam_hold.
        if exc >= cfg.jam_thresh_db:
            self.run += 1
        else:
            self.run = max(0, self.run - cfg.jam_miss_penalty)
        cond = (self.run >= self.jam_hold_blocks) and not warming
        if cond:
            self.jam_left = self.jam_release_blocks
        elif self.jam_left > 0:
            self.jam_left -= 1
        self.jammed = cond or self.jam_left > 0
        if self.jammed:
            self.jammed_ever = True
        evaluated = not (warming or self.jammed or self.clipped)
        if not evaluated and self.burst:
            self.burst_tainted = True


        if exc >= cfg.thresh_db:
            if not self.in_imp:
                self.in_imp = True
                self.imp_start = i
                self.imp_n = 0
                self.imp_zc = 0
                self.imp_peak_l = -math.inf
                self.imp_peak_e = 0.0
                self.imp_tainted = False
            self.imp_n += 1
            self.imp_zc += zc
            self.imp_peak_l = max(self.imp_peak_l, level)
            self.imp_peak_e = max(self.imp_peak_e, exc)
            if not evaluated:
                self.imp_tainted = True
        elif self.in_imp:
            self.in_imp = False
            self._end_impulse()

        if self.burst and (t_ms - self.burst[-1].t_end_ms) > cfg.burst_max_gap_ms and not self.in_imp:
            self._close_burst(truncated=False)

        # Scalar form of RunningQuantile.update.
        eta = self.eta * (1.0 + (cfg.floor.warmup_speedup - 1.0) * warm_left)
        q = cfg.floor.quantile
        self.floor_db = self.floor_db - eta * (1.0 - q) if level < self.floor_db else self.floor_db + eta * q
        h = self.health
        if h != self._last_health:
            self.health_log.append((t_ms, h))
            self._last_health = h
        self.block += 1

    def _end_impulse(self) -> None:
        cfg = self.cfg
        dur = self.imp_n * self.block_ms
        if self.imp_tainted:
            return
        if dur < cfg.min_ms - self.block_ms or dur > cfg.max_ms + self.block_ms:
            return
        f = self.imp_zc / (2.0 * dur / 1000.0)
        f = max(cfg.bp_lo_hz, min(cfg.bp_hi_hz, f))
        imp = _Impulse(
            t_start_ms=self.imp_start * self.block_ms,
            t_end_ms=(self.imp_start + self.imp_n) * self.block_ms,
            freq_hz=f,
            peak_dbfs=self.imp_peak_l,
            excess_db=self.imp_peak_e,
        )
        if self.burst:
            last = self.burst[-1]
            span = imp.t_end_ms - self.burst[0].t_start_ms
            if imp.t_start_ms - last.t_end_ms > cfg.burst_max_gap_ms:
                self._close_burst(truncated=False)
            elif len(self.burst) >= cfg.max_burst_impulses or span > cfg.max_burst_ms:
                self._close_burst(truncated=True)
        self.burst.append(imp)

    def _close_burst(self, truncated: bool) -> None:
        cfg = self.cfg
        b = self.burst
        tainted = self.burst_tainted
        self.burst = []
        self.burst_tainted = False
        if tainted or len(b) < cfg.burst_min_impulses:
            return
        onsets = [p.t_start_ms for p in b]
        cv = _ipi_cv(onsets)
        flags = 0
        if len(b) >= cfg.train_min_pulses and 0 <= cv <= cfg.train_max_cv:
            flags |= EF_REGULAR_TRAIN
        if truncated:
            flags |= EF_TRUNCATED
        fr = [p.freq_hz for p in b]
        self.events.append(
            DetEvent(
                t_start_ms=b[0].t_start_ms,
                duration_ms=b[-1].t_end_ms - b[0].t_start_ms,
                cls=IMPULSE_BURST,
                flags=flags,
                peak_hz=float(np.mean(fr)),
                min_hz=min(fr),
                max_hz=max(fr),
                slope_hz_per_ms=0.0,
                snr_db=max(p.excess_db for p in b),
                peak_dbfs=max(p.peak_dbfs for p in b),
                impulses=len(b),
                harmonics=0,
                rep_rate_hz=_rep_rate(onsets),
                ipi_cv=cv,
            )
        )


# ------------------------------------------------------------------ runners


@dataclass
class NodeResult:
    events: list[DetEvent]
    band_frames: list[BandFrameOut]
    health_log: list[tuple[float, int]]
    jammed_ever: bool
    clipped_ever: bool
    final_health: int
    extra: dict = field(default_factory=dict)


def _chunks(x: np.ndarray, n: int):
    for i in range(0, len(x), n):
        yield x[i: i + n]


def run_spectral_node(
    pcm: np.ndarray,
    cfg: SpecConfig,
    clip_cfg: ClipConfig,
    highpass: bool,
) -> NodeResult:
    """US_AIR (highpass=True) or AUDIO_AIR pipeline: clip on raw -> HPF -> STFT."""
    hp = dsp.BiquadCascade(dsp.butter_highpass_sections(cfg.fs, dsp.US_HPF_HZ, dsp.US_HPF_ORDER)) if highpass else None
    clip = ClipDetector(clip_cfg, cfg.fs)
    det = SpectralDetector(cfg)
    for c in _chunks(np.asarray(pcm, dtype=float), cfg.hop):
        clip.push(c)
        y = hp.process(c) if hp is not None else c
        det.push(y, clipped=clip.active)
    det.finish()
    return NodeResult(
        events=det.events,
        band_frames=det.band_frames,
        health_log=det.health_log,
        jammed_ever=det.jammed_ever,
        clipped_ever=clip.ever,
        final_health=det.health,
    )


def run_contact_node(
    pcm: np.ndarray,
    cfg: ImpulseConfig,
    clip_cfg: ClipConfig,
    chunk: int = 480,
) -> NodeResult:
    clip = ClipDetector(clip_cfg, cfg.fs)
    det = ImpulseDetector(cfg)
    for c in _chunks(np.asarray(pcm, dtype=float), chunk):
        clip.push(c)
        det.push(c, clipped=clip.active)
    det.finish()
    return NodeResult(
        events=det.events,
        band_frames=[],
        health_log=det.health_log,
        jammed_ever=det.jammed_ever,
        clipped_ever=clip.ever,
        final_health=det.health,
    )


def burst_rate_per_s(events: list[DetEvent], window_s: float) -> float:
    n = sum(1 for e in events if e.cls == IMPULSE_BURST)
    return n / window_s if window_s > 0 else 0.0
