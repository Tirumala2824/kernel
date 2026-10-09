## 0.2.0

* Contracts v2.
* `captureLevels()`: a pigeon `@EventChannelApi` stream of live RMS/peak dBFS readings, one per 50 ms of kept audio, computed in the capture loop. Levels only, and nothing while idle. The Dart side shares one broadcast stream per process.
* `captureAndAnalyze(..., haptics:)`: `false` plays no cue at all. `ScanOutcome.audioRetained` is true only when the WAV was written.
* `retainedAudioPath(scanId)`.
* `EngineInfo.modelNote` (from the manifest), `audioSource` (`VOICE_RECOGNITION`) and `deviceInputSampleRate` (HAL rate, known after the first capture).
* Model manifest:
  * New required key `validation=proxy|field`. `proxy` must be `experimental=true` and must have a `note`.
  * `note` is limited to 500 characters.
  * Optional `uncertain_below` confidence band.
  * Unknown keys are rejected, except `meta.*`.
  * The full format is in README.md.
* Per-stage benchmark (settle, capture, gate, resample, log-mel, inference, retain, latency, total) logged to `AudioAi` in debuggable builds.
* Capture reads in 50 ms blocks (was 100 ms). `LogMel` is unchanged.
* The example app shows live levels and has a haptics toggle.

## 0.1.0

* V0.1 foundation: `NativeScanEngine` (pigeon bridge), real AudioRecord capture, quality gate, provisional log-mel, LiteRT CPU path for a future bundled model (none bundled, so results are NOT_EVALUATED), haptic cues, opt-in app-private audio retention.
