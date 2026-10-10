# kernel-sensor-ref

Python mirror of the sensor-node detectors in `firmware/components/kernel_detect` and of the wire codec in `firmware/components/kernel_proto`. It runs off-device only. It holds the reference algorithms, the synthetic test signals and the exported test vectors that the Dart and Kotlin codecs and the Dart signature matcher are tested against.

```bash
cd firmware/reference
uv run python -I -m pytest            # detector + codec tests
uv run python -I -m kernel_ref.export # rewrite vectors/*.json
```

Only numpy and scipy are used. The synthetic signals are test inputs (fixed seeds), never shipped data. See `firmware/README.md` and `docs/sensor-protocol.md`.
