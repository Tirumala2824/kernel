"""Model manifest (`models/<name>.properties`): writer plus a strict validator.

The validator mirrors the app's ModelManifest.kt rules as specified by the
lead/audio-ai (2026-10-10), so an exported manifest that passes here is also
accepted by the app. Anything else makes the app treat the model as absent:

- UTF-8, Java properties syntax, `#` comments only at the start of a line.
- required: version, labels, output, input_layout, validation, sample_rate,
  n_fft, win_length, hop_length, n_mels, f_min, f_max, log_offset, power
- optional: experimental (default true), note (required, non-empty and at
  most 500 chars when validation=proxy), uncertain_below, meta.* (ignored)
- unknown keys are rejected
- labels: comma list over {clean, uncertain, infested}, unique, at least 2
- output: probabilities | logits; input_layout: mels_frames | frames_mels
- validation: proxy | field; a proxy model is always experimental=true
- sample_rate must be 16000; log-mel values must satisfy LogMelConfig
- version must not be "none" (the contract's no-model value)
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from kernel_train.logmel import LogMelConfig

REQUIRED = (
    "version", "labels", "output", "input_layout", "validation", "sample_rate",
    "n_fft", "win_length", "hop_length", "n_mels", "f_min", "f_max", "log_offset", "power",
)
OPTIONAL = ("experimental", "note", "uncertain_below")
META_PREFIX = "meta."
ALLOWED_LABELS = ("clean", "uncertain", "infested")
NOTE_MAX = 500
PIPELINE_SAMPLE_RATE = 16_000
NO_MODEL_VERSION = "none"


class ManifestError(ValueError):
    pass


@dataclass
class Manifest:
    version: str
    labels: list[str]
    output: str
    input_layout: str
    validation: str
    logmel: LogMelConfig
    experimental: bool = True
    note: str | None = None
    uncertain_below: float | None = None
    meta: dict[str, str] = field(default_factory=dict)


def _fmt_num(x: float) -> str:
    """Integers without a trailing .0 (f_min=125), other values via repr (0.001)."""
    return str(int(x)) if float(x).is_integer() else repr(float(x))


def _escape(value: str) -> str:
    """Java-properties-safe value: escape backslash and newlines; non-ASCII as \\uXXXX.

    The app reads the file as UTF-8, but \\u escapes are valid either way, so the
    file is pure ASCII and survives any reader.
    """
    out = []
    for ch in value:
        if ch == "\\":
            out.append("\\\\")
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ord(ch) > 0x7E or ord(ch) < 0x20:
            if ord(ch) > 0xFFFF:
                raise ManifestError("characters outside the BMP are not supported in manifests")
            out.append(f"\\u{ord(ch):04x}")
        else:
            out.append(ch)
    s = "".join(out)
    # A leading space would be stripped by Properties.load.
    return ("\\" + s) if s.startswith(" ") else s


def render(m: Manifest, header: list[str] | None = None) -> str:
    validate(m)
    lines = [f"# {h}" for h in (header or [])]
    c = m.logmel
    pairs = [
        ("version", m.version),
        ("labels", ",".join(m.labels)),
        ("output", m.output),
        ("input_layout", m.input_layout),
        ("validation", m.validation),
        ("experimental", "true" if m.experimental else "false"),
    ]
    if m.note is not None:
        pairs.append(("note", m.note))
    if m.uncertain_below is not None:
        pairs.append(("uncertain_below", _fmt_num(m.uncertain_below)))
    pairs += [
        ("sample_rate", str(c.sample_rate)),
        ("n_fft", str(c.n_fft)),
        ("win_length", str(c.win_length)),
        ("hop_length", str(c.hop_length)),
        ("n_mels", str(c.n_mels)),
        ("f_min", _fmt_num(c.f_min)),
        ("f_max", _fmt_num(c.f_max)),
        ("log_offset", _fmt_num(c.log_offset)),
        ("power", _fmt_num(c.power)),
    ]
    pairs += sorted(m.meta.items())
    lines += [f"{k}={_escape(v)}" for k, v in pairs]
    return "\n".join(lines) + "\n"


def write(m: Manifest, path: Path, header: list[str] | None = None) -> None:
    text = render(m, header)
    path.write_bytes(text.encode("utf-8"))
    # Round-trip guard: what we wrote must parse back to the same manifest.
    back = parse(path.read_text(encoding="utf-8"))
    if back != m:
        raise ManifestError(f"manifest round-trip mismatch: {back} != {m}")


# --- parsing (subset of java.util.Properties sufficient for our files, plus strict rules) ---

def _unescape(raw: str) -> str:
    out, i = [], 0
    while i < len(raw):
        ch = raw[i]
        if ch != "\\":
            out.append(ch)
            i += 1
            continue
        i += 1
        if i >= len(raw):
            raise ManifestError("dangling backslash (line continuation is not used in manifests)")
        e = raw[i]
        if e == "u":
            hexpart = raw[i + 1 : i + 5]
            if len(hexpart) != 4:
                raise ManifestError("bad \\u escape")
            out.append(chr(int(hexpart, 16)))
            i += 5
            continue
        out.append({"n": "\n", "r": "\r", "t": "\t", "f": "\f"}.get(e, e))
        i += 1
    return "".join(out)


def parse_properties(text: str) -> dict[str, str]:
    props: dict[str, str] = {}
    for n, line in enumerate(text.splitlines(), 1):
        stripped = line.lstrip(" \t\f")
        if not stripped or stripped[0] in "#!":
            continue
        if line[0] in " \t\f":
            raise ManifestError(f"line {n}: keys must start at column 0")
        # Separator: first unescaped '=' or ':' (our writer always uses '=').
        sep, i = -1, 0
        while i < len(line):
            if line[i] == "\\":
                i += 2
                continue
            if line[i] in "=:":
                sep = i
                break
            i += 1
        if sep < 0:
            raise ManifestError(f"line {n}: missing '='")
        key = _unescape(line[:sep].strip())
        value = _unescape(line[sep + 1 :].lstrip(" \t\f"))
        if key in props:
            raise ManifestError(f"duplicate key '{key}'")
        props[key] = value
    return props


def parse(text: str) -> Manifest:
    props = parse_properties(text)
    unknown = [k for k in props if k not in REQUIRED and k not in OPTIONAL and not k.startswith(META_PREFIX)]
    if unknown:
        raise ManifestError(f"unknown keys: {unknown}")

    def req(key: str) -> str:
        v = props.get(key, "").strip()
        if not v:
            raise ManifestError(f"manifest is missing '{key}'")
        return v

    def num(key: str, kind=float):
        v = req(key)
        try:
            return kind(v)
        except ValueError as e:
            raise ManifestError(f"'{key}' is not a {kind.__name__}") from e

    exp_raw = props.get("experimental", "").strip().lower()
    if exp_raw not in ("", "true", "false"):
        raise ManifestError("experimental must be true or false")
    ub = props.get("uncertain_below")
    try:
        cfg = LogMelConfig(
            sample_rate=num("sample_rate", int),
            n_fft=num("n_fft", int),
            win_length=num("win_length", int),
            hop_length=num("hop_length", int),
            n_mels=num("n_mels", int),
            f_min=num("f_min"),
            f_max=num("f_max"),
            log_offset=num("log_offset"),
            power=num("power"),
        )
    except ValueError as e:
        if isinstance(e, ManifestError):
            raise
        raise ManifestError(str(e)) from e
    m = Manifest(
        version=req("version"),
        labels=[x.strip().lower() for x in req("labels").split(",")],
        output=req("output").lower(),
        input_layout=req("input_layout").lower(),
        validation=req("validation").lower(),
        logmel=cfg,
        experimental=exp_raw != "false",
        note=props.get("note"),
        uncertain_below=float(ub) if ub is not None and ub.strip() else None,
        meta={k: v for k, v in props.items() if k.startswith(META_PREFIX)},
    )
    validate(m)
    return m


def validate(m: Manifest) -> None:
    if not m.version or m.version == NO_MODEL_VERSION:
        raise ManifestError(f"version must be set and not '{NO_MODEL_VERSION}'")
    if len(m.labels) < 2 or len(set(m.labels)) != len(m.labels):
        raise ManifestError("labels must be at least two unique values")
    bad = [x for x in m.labels if x not in ALLOWED_LABELS]
    if bad:
        raise ManifestError(f"unknown labels {bad}")
    if m.output not in ("probabilities", "logits"):
        raise ManifestError("output must be probabilities or logits")
    if m.input_layout not in ("mels_frames", "frames_mels"):
        raise ManifestError("input_layout must be mels_frames or frames_mels")
    if m.validation not in ("proxy", "field"):
        raise ManifestError("validation must be proxy or field")
    if m.validation == "proxy":
        if not m.experimental:
            raise ManifestError("a proxy model is always experimental=true")
        if not m.note or not m.note.strip():
            raise ManifestError("note is required when validation=proxy")
    if m.note is not None and len(m.note) > NOTE_MAX:
        raise ManifestError(f"note longer than {NOTE_MAX} chars")
    if m.uncertain_below is not None and not (0.0 < m.uncertain_below <= 1.0):
        raise ManifestError("uncertain_below must be in (0, 1]")
    if m.logmel.sample_rate != PIPELINE_SAMPLE_RATE:
        raise ManifestError(f"sample_rate must be {PIPELINE_SAMPLE_RATE}")
    for k in m.meta:
        if not k.startswith(META_PREFIX) or len(k) == len(META_PREFIX):
            raise ManifestError(f"bad meta key '{k}'")
