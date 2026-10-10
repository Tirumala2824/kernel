# Kernel sensor-node protocol, v1.0

Owner: `sensor-dev`. Implementations: `firmware/components/kernel_proto` (C, node), `firmware/reference/kernel_ref/proto.py` (Python reference, generates the fixtures), `sensor-link/android/.../protocol/SensorProtocol.kt` (Kotlin) and `sensor-link/lib/src/protocol.dart` (Dart). All four are tested against the same byte fixtures in `firmware/reference/vectors/protocol_v1.json`.

Guardrails §10 apply to everything here:
- Nodes send **features, not audio**.
- Every characteristic needs an **encrypted, bonded** link plus app-layer authentication.
- Events are **experimental signals**, never diagnoses.

## 1. Why the detection runs on the node
Raw ultrasound cannot be carried over BLE. LE Audio tops out at 48 kHz, and a 192 kSPS stream would need about 3 Mbit/s. So each node runs the FFT, the noise floor and the detectors itself and sends only:
- band-energy summaries (`BandFrame`)
- detection events (`Event`)
- health (`Status`)
- on explicit request only, a small u8 spectrogram tile set (`Snippet`)

There is no audio characteristic and no opcode that returns samples.

## 2. Conventions
- Every multi-byte field is **little-endian** and structures are **packed** (no padding).
- `uN`/`iN` are unsigned/signed integers of N bits. `u24` is 3 bytes LE.
- Reserved fields and bits are sent as 0 and ignored on receipt.
- **Length rule.** A receiver rejects a payload shorter than the v1.0 length and ignores trailing bytes beyond it. Trailing bytes are how minor versions extend a structure (§11).
- **Fixed-point units** (names carry the unit):

| Suffix | Unit | Example |
|---|---|---|
| `Hz10` | Hz / 10 (u16, so 0 to 655.35 kHz in 10 Hz steps) | `peakHz10 = 7012` is 70.12 kHz |
| `HalfDb` | 0.5 dB (u8) | `snrHalfDb = 57` is 28.5 dB |
| `DeciDb` | 0.1 dB (i16) | `-923` is -92.3 dB |
| `DHzPerMs` | 0.1 Hz/ms (i16) | `slope = 4210` is 421.0 Hz/ms |
| `CHz` | 0.01 Hz (u16) | `repRateCHz = 1500` is 15.00 Hz |
| `Pct` | percent (u8) | `ipiCvPct = 30` is CV 0.30; 255 means n/a |
| `Ds` | deciseconds (u8) | `jamHoldDs = 20` is 2.0 s |

- **Node time.** Nodes keep `epochMs` after a `SET_TIME`, on the RTC that survives deep sleep. Before the first `SET_TIME` of a boot, timestamps are uptime-based and flagged (`timeValid = 0`). The phone sends `SET_TIME` on every connection.

## 3. Advertising
The node advertises connectably (legacy advertising, 31 B):

| AD | Bytes | Content |
|---|---|---|
| Flags (0x01) | 3 | `0x06`: LE General Discoverable, BR/EDR not supported |
| Complete 128-bit Service UUIDs (0x07) | 18 | the Kernel sensor service UUID (§4) |
| Manufacturer Specific Data (0xFF) | 9 | `companyId u16`, `proto u8`, `sensorType u8`, `lastEventSeq u16`, `batt u8` |

Total: 30 B. The scan response carries the Complete Local Name `Kernel-XXXX`, where XXXX is the last 2 address bytes in hex.

Manufacturer data (7 B after the AD header):

| Off | Type | Field | Notes |
|---|---|---|---|
| 0 | u16 | companyId | `0xFFFF` = test/unregistered. **Production needs a Bluetooth SIG-registered company id.** |
| 2 | u8 | proto | protocol major, `1` |
| 3 | u8 | sensorType | 1 `US_AIR`, 2 `CONTACT_PIEZO`, 3 `CONTACT_ACCEL`, 4 `AUDIO_AIR` |
| 4 | u16 | lastEventSeq | low 16 bits of the newest event seq. The phone compares it with its stored seq to decide whether a sync is needed. |
| 6 | u8 | batt | 0..100 %, `0xFF` unknown |

**Advertising intervals:**
- 100 ms for 30 s after boot or a button press (pairing window).
- 1 s otherwise.
- 2 s when the battery is low.

The address is the ESP32 public MAC, which is also printed in the QR label.

## 4. GATT layout
Services:
- Device Information (0x180A): Manufacturer Name (0x2A29), Model Number (0x2A24), Hardware Revision (0x2A27), Firmware Revision (0x2A26).
- Battery (0x180F): Battery Level (0x2A19, read + notify).
- **Kernel sensor service** `c7780001-4139-44b2-877d-c537908d6290`.

Every characteristic in all three services, including DIS and BAS, requires an **encrypted link** (`READ_ENC`/`WRITE_ENC`). Unencrypted access fails with ATT error 0x0F (Insufficient Encryption). Before the app-layer handshake (§7), the characteristics marked "auth" fail with ATT 0x08 (Insufficient Authorization), and the node sends no notifications or indications on them.

| Char | UUID | Props | Auth | Length |
|---|---|---|---|---|
| DeviceInfo | `c7780002-4139-44b2-877d-c537908d6290` | read | no | 22 |
| Config | `c7780003-…` | read, write | **yes** | 32 |
| BandTable | `c7780004-…` | read | **yes** | 2 + 2(n+1) |
| BandFrame | `c7780005-…` | notify | **yes** | 23 + n (47 with 24 bands) |
| Event | `c7780006-…` | indicate | **yes** | 30 |
| Status | `c7780007-…` | read, notify | no | 21 |
| ControlPoint | `c7780008-…` | write (with response), indicate | AUTH ops: no; others: **yes** | var |
| Snippet | `c7780009-…` | notify | **yes** | 8 + rows x cols |

All UUIDs share the suffix `-4139-44b2-877d-c537908d6290` and differ only in the first group (`c778xxxx`). They were generated once (random v4) for this protocol. They are never reused for a different meaning.

**MTU.** The phone requests MTU 517; Android 14+ always negotiates 517 on the first request. The node prefers 247 (`CONFIG_BT_NIMBLE_ATT_PREFERRED_MTU`). The node sends BandFrame, Event, the AUTH_CHALLENGE response and Snippet tiles only when `MTU - 3` covers the payload, so the effective minimum is MTU 64. **PHY:** the phone asks for LE 2M when the adapter supports it, and the node accepts.

### 4.1 DeviceInfo (read, 22 B)
| Off | Type | Field |
|---|---|---|
| 0 | u8 | protoMajor (1) |
| 1 | u8 | protoMinor (0) |
| 2 | u8 | sensorType (as in §3) |
| 3 | u8 | hwRev |
| 4 | u8 | fwMajor |
| 5 | u8 | fwMinor |
| 6 | u8 | fwPatch |
| 7 | u8 | nBands (1..24) |
| 8 | u16 | capabilities: b0 bandFrames, b1 snippets, b2 survey, b3 rtc, b4 batteryAdc, b5 dutyCycle, b6 keyInEfuse |
| 10 | u32 | sampleRateHz |
| 14 | u16 | fftSize |
| 16 | u16 | hopSize |
| 18 | u16 | ringCapacity (events kept in flash) |
| 20 | u8 | cfgVersion (1) |
| 21 | u8 | reserved |

### 4.2 Config (read/write, auth, 32 B)
Writes must be exactly 32 B with `cfgVersion = 1`. Otherwise the node returns ATT 0x0D (Invalid Attribute Value Length) or 0x80 (application error: value out of range). The node persists the config in NVS and applies it at the next frame boundary.

| Off | Type | Field | Default (US / CONTACT / AUDIO) | Range |
|---|---|---|---|---|
| 0 | u8 | cfgVersion | 1 | 1 |
| 1 | u8 | flags: b0 bandFrames, b1 dutyCycle, b2 snippets, b3 chirpGrouping, b4 harmonicSearch, b5 spectralEvents, b6 impulsePath | US 0x25, CONTACT 0x45, AUDIO 0x3D | |
| 2 | u16 | bandFrameMs | 1000 | 100..10000 |
| 4 | u16 | dutyOnS | 60 | 10..3600 |
| 6 | u16 | dutyOffS (0 = continuous) | 0 | 0..3600 |
| 8 | u8 | detectThreshHalfDb (blob threshold above the floor) | 28 / 28 / 40 | 12..80 |
| 9 | u8 | jamThreshHalfDb | 12 | 6..60 |
| 10 | u8 | jamHoldDs | 20 | 5..250 |
| 11 | u8 | impulseThreshHalfDb | 30 | 12..80 |
| 12 | u8 | minBlobMs | 5 / 5 / 8 | 1..100 |
| 13 | u8 | maxGapMs | 4 / 4 / 0 | 0..50 |
| 14 | u16 | flatMinMs | 300 | 50..5000 |
| 16 | u16 | contMinMs | 1000 | 200..10000 |
| 18 | u16 | fmMinBwHz10 | 300 / 300 / 150 | 10..5000 |
| 20 | u8 | burstMinImpulses | 3 | 2..50 |
| 21 | u8 | trainMinPulses | 3 | 3..50 |
| 22 | u16 | burstMaxGapMs | 200 | 10..2000 |
| 24 | u8 | impulseMinHalfMs | 2 (1 ms) | 1..40 |
| 25 | u8 | impulseMaxMs | 10 | 1..100 |
| 26 | u8 | trainMaxCvPct (regular-train CV limit) | 15 | 1..100 |
| 27 | u8 | lowBattPct | 15 | 5..50 |
| 28 | u16 | chirpMaxGapMs | 120 | 10..1000 |
| 30 | u16 | reserved | 0 | 0 |

The fixed analysis parameters, such as the FFT size, the band edges and the floor quantile, are Kconfig settings and are reported read-only in DeviceInfo and BandTable.

### 4.3 BandTable (read, auth)
| Off | Type | Field |
|---|---|---|
| 0 | u8 | nBands n (1..24) |
| 1 | u8 | reserved |
| 2 | u16[n+1] | edgesHz10, ascending |

Defaults:
- US_AIR: 18 bands of 4 kHz from 20 to 92 kHz.
- CONTACT: 17 third-octave-like bands from 200 Hz to 10 kHz.
- AUDIO_AIR: 20 bands from 100 Hz to 15 kHz.

### 4.4 BandFrame (notify, auth, 23 + n B; 47 B at n = 24)
One frame every `bandFrameMs` while a phone is subscribed and `flags.b0` is set. Each value is the **maximum** over the interval.

| Off | Type | Field |
|---|---|---|
| 0 | u32 | seq (frame counter, wraps) |
| 4 | u32 | tStartS (epoch s if timeValid, else uptime s) |
| 8 | u16 | tStartMs (0..999) |
| 10 | u16 | frameMs |
| 12 | u8 | flags: b0 timeValid, b1 jammed, b2 clipped, b3 surveyActive, b4 warmingUp |
| 13 | u8 | nBands n |
| 14 | i16 | noiseFloorDeciDbfs (median per-bin floor over the analysis range) |
| 16 | u16 | peakHz10 |
| 18 | i16 | peakDeciDbfs |
| 20 | u24 | jamBandMask (bit b: band b holds a stationary line) |
| 23 | u8[n] | bandsHalfDbAboveFloor |

### 4.5 Event (indicate, auth, 30 B)
| Off | Type | Field |
|---|---|---|
| 0 | u32 | seq (starts at 1, strictly increasing, never reused) |
| 4 | u32 | tStartS (epoch s if flags.timeValid, else uptime s of boot `bootLow`) |
| 8 | u16 | tStartMs (0..999) |
| 10 | u16 | durationMs (saturates at 65535) |
| 12 | u8 | eventClass: 0 tonal, 1 fmSweep, 2 flatTone, 3 impulseBurst, 4 harmonic, 5 pulsedChirp, 6 continuousEmitter |
| 13 | u8 | flags: b0 timeValid, b1 regularTrain, b2 truncated, b3 snippetAvailable |
| 14 | u16 | peakHz10 (fundamental for `harmonic`) |
| 16 | u16 | minHz10 |
| 18 | u16 | maxHz10 |
| 20 | i16 | slopeDHzPerMs (least-squares frequency slope) |
| 22 | u8 | snrHalfDb (peak excess over the noise floor) |
| 23 | i8 | peakDbfs |
| 24 | u8 | impulses (impulses in a burst, pulses in a chirp) |
| 25 | u8 | harmonics (overtones above the fundamental) |
| 26 | u16 | repRateCHz (impulse or pulse repetition rate) |
| 28 | u8 | ipiCvPct (inter-onset interval CV x 100; 255 = n/a) |
| 29 | u8 | bootLow (low 8 bits of the boot counter) |

Mapping to `contracts` `SensorEvent`: Hz fields are divided out, `snrDb = snrHalfDb / 2`, `repRateHz = repRateCHz / 100`, `slopeHzPerMs = slope / 10`.
- If `timeValid = 1`, `startedAt` is the epoch time.
- Otherwise, if `bootLow` equals the low byte of `Status.bootCount`, `startedAt = now - (Status.uptimeS - tStartS)`.
- Otherwise the event time is unknown. The phone skips the event and reports a gap (§12).

### 4.6 Status (read, notify, auth not required, 21 B)
| Off | Type | Field |
|---|---|---|
| 0 | u16 | health bits (below) |
| 2 | u8 | battPct (0xFF unknown) |
| 3 | u16 | battMv |
| 5 | u32 | lastSeq (newest event; 0 = none) |
| 9 | u32 | oldestSeq (oldest event still in flash) |
| 13 | u32 | uptimeS |
| 17 | u16 | bootCount |
| 19 | u16 | surveyRemainingS |

Health bits:

| Bit | Name | Meaning | App mapping (`SensorHealth`) |
|---|---|---|---|
| 0 | jammed | stationary line, sweeping emitter or sustained vibration | `jammed`: **not evaluated** |
| 1 | clipped | ADC clipping in the last 2 s | `clipped`: **not evaluated** |
| 2 | lowBattery | battery at or below lowBattPct | `lowBattery` |
| 3 | surveyNeeded | no completed site survey since config/placement change | `surveyNeeded`: **not evaluated** |
| 4 | surveyActive | survey running; events suppressed | `surveyNeeded`: **not evaluated** |
| 5 | sessionActive | a phone session holds continuous listening | (link state) |
| 6 | timeValid | node clock set this boot | (internal) |
| 7 | authenticated | this connection passed §7 | (link state) |
| 8 | warmingUp | floor still converging after start | (not shown) |
| 9 | sensorFault | capture errors (I2S/SPI) | no contract value; see §12 |
| 10 | eventsOverwritten | the ring dropped events newer than the last GET_EVENTS_SINCE | (gap note) |

The node notifies Status on every change of bits 0..4 and at most once a minute otherwise.

### 4.7 ControlPoint (write with response + indicate)
A request is `[opcode u8][params]`. Every request is answered by one indication `RESPONSE = [0x80][reqOpcode u8][status u8][payload]`.

**Status codes:**

| Code | Name |
|---|---|
| 0x00 | OK |
| 0x01 | UNKNOWN_OPCODE |
| 0x02 | INVALID_PARAM |
| 0x03 | NOT_AUTHENTICATED |
| 0x04 | AUTH_FAILED |
| 0x05 | BUSY |
| 0x06 | NOT_AVAILABLE |
| 0x07 | STORAGE_ERROR |

**Opcodes:**

| Op | Name | Params | Response payload | Auth |
|---|---|---|---|---|
| 0x01 | SET_TIME | `epochMs u64` | none | yes |
| 0x02 | GET_EVENTS_SINCE | `seq u32` (send events with seq > this), `maxCount u16` (0 = all) | `count u16`, `firstSeq u32`, `lastSeq u32`, `oldestSeq u32` | yes |
| 0x03 | START_SURVEY | `durationS u16` (30..3600) | none | yes |
| 0x04 | START_SESSION | `flags u8` (b0 liveBands) | none | yes |
| 0x05 | STOP_SESSION | none | none | yes |
| 0x06 | REQUEST_SNIPPET | `eventSeq u32` | `eventSeq u32`, `rows u8`, `cols u8`, `fLoHz10 u16`, `fHiHz10 u16`, `colDeciMs u16`, `tileCount u8`, `colsPerTile u8` (14 B) | yes |
| 0x07 | CLEAR_BOND | none | none; the node deletes this peer's bond after the disconnect | yes |
| 0x10 | AUTH_CHALLENGE | `appNonce[16]` | `nodeNonce[16]`, `nodeProof[32]` | no |
| 0x11 | AUTH_RESPONSE | `appProof[32]` | none (OK or AUTH_FAILED) | no |

GET_EVENTS_SINCE works in three steps:
1. The RESPONSE comes first.
2. Then come `count` Event indications in seq order.
3. Finally the node indicates `EVENTS_DONE = [0x81][count u16][lastSeq u32]`.

If `seq + 1 < oldestSeq`, events were overwritten. The response's `oldestSeq` tells the phone where the gap is.

Only one ControlPoint procedure runs at a time. A second request during a transfer gets BUSY.

### 4.8 Snippet (notify, auth)
Snippets are u8 spectrogram tiles of the **feature** spectrogram around one event: dB above the floor in 0.5 dB steps, cropped to the event's frequency range plus 20 %, at most 64 rows x 96 columns. They are never audio. The node keeps the last 8 event snippets in RAM only. They are never written to flash and are lost on reboot. A snippet is sent only after REQUEST_SNIPPET. The phone keeps it in memory, never persists it and never uploads it.

Each tile is `[eventSeq u32][tileIndex u8][tileCount u8][col0 u8][nCols u8]` followed by `rows x nCols` bytes, column-major (each column is `rows` bytes, lowest frequency first).

## 5. Signal chain and detectors (what the numbers mean)
Implemented in portable C (`kernel_detect`) and mirrored in Python (`kernel_ref.detect`).

**US_AIR** (SPH0641LU4H-1, ultrasonic mode):
- I2S clocks the mic at 3.072 MHz. The raw PDM bitstream goes through a CIC (order 4, R = 8) to 384 kSPS, then a 47-tap Kaiser half-band FIR (÷2) to **192 kSPS**.
- Every PCM sample then passes a **6th-order Butterworth high-pass at 20 kHz before anything is buffered**.
- The DMA descriptors hold 3 x 4 ms of raw PDM bits and are overwritten in place. Un-filtered PCM exists only in a 32-sample (0.17 ms) scratch that is filtered immediately.

**CONTACT** (piezo with a JFET buffer into a PCM1808 at 48 kSPS, or IIS3DWB at 26.7 kSPS):
- The impulse path band-passes 200 Hz–10 kHz (2nd-order HP + 2nd-order LP) and computes 0.5 ms block energies.
- Samples are never stored or sent.

**AUDIO_AIR**: a standard PDM mic at 32 kSPS.

Spectral path (US_AIR, AUDIO_AIR):
1. Hann window, FFT (512 points). The power spectrum is scaled so a full-scale sine reads 0 dBFS, smoothed `[1 2 1]/4` across bins and averaged over `smooth_frames` frames (3 US, 1 AUDIO).
2. **Noise floor:** a running **5 % quantile** per bin and per band, using a stochastic quantile update in dB. The upward drift is limited to 0.5 dB/s, so the downward step is 19 times faster. During the first 1 s the step size anneals from 20x to 1x, and events are suppressed during warm-up.
3. **Blob detector:** each frame tracks the strongest bin whose excess over the floor is at least `detectThresh`. A blob continues while the tracked bin moves by at most `max_jump` (1.5 kHz US, 400 Hz AUDIO) and gaps stay within `maxGapMs`.
   - When a blob closes, it is checked against `minBlobMs` and the parabolic-interpolated min/max/peak frequencies, the least-squares slope, the peak excess and the peak dBFS are computed.
   - Class: `harmonic` if overtones are present in at least half of the frames (AUDIO). Otherwise:
     - a blob of at least `contMinMs` is `continuousEmitter` if its bandwidth is at least `fmMinBw`, else `flatTone`
     - otherwise a blob with bandwidth of at least `fmMinBw` is `fmSweep`
     - otherwise a blob of at least `flatMinMs` is `flatTone`
     - otherwise it is `tonal`
4. **Chirp grouping** (AUDIO): at least `trainMinPulses` short tonal pulses within ±15 % of the first frequency, with gaps of at most `chirpMaxGapMs`, become one `pulsedChirp`. It carries the pulse count, repetition rate and inter-onset CV.
5. **Jammer:** the node is JAMMED when any of these holds, and stays JAMMED for 5 s after the last one clears:
   - (a) a band stays at least `jamThresh` (6 dB) above its floor for more than `jamHold` (2 s). The run is leaky: each frame below the threshold costs 10 frames of credit, so high-variance narrow bands cannot fake a line
   - (b) a bin's 2 s minimum level sits at least 6 dB above the median floor of its neighbours at ±3..10 bins. This is a stationary line, including one that was present at power-on.
   - (c) the blob detector is active (some bin at least `detectThresh` above its floor) in at least 90 % of the frames of a 2 s window. This catches sweeping repellers.

Impulse path (CONTACT):
- Block energy relative to a running 5 % quantile floor.
- An impulse is a run of blocks at least `impulseThresh` (15 dB) above the floor, lasting `impulseMin`..`impulseMax` (1..10 ms, with ±1 block tolerance). Its frequency comes from zero crossings.
- A burst is at least `burstMinImpulses` impulses with gaps of at most `burstMaxGapMs`.
- A burst gets `regularTrain` when it has at least `trainMinPulses` and inter-onset CV of at most `trainMaxCv`.
- Sustained excess (6 dB for 2 s) is JAMMED.

**Clipping:** at least 3 raw samples at or above 98 % of full scale within a 100 ms window raise CLIPPED for 2 s.

**Gating:** frames that are warming up, jammed, clipped or surveying taint any open blob or burst, and tainted detections are dropped. A jammed or clipped node emits **no events**. The phone shows it as "not evaluated", never as "nothing there".

## 6. Store-and-forward
- Events go to a dedicated flash partition `kevents` (64 KiB = 16 sectors of 4 KiB). Each record is 32 B: the 30 B Event plus CRC-16/CCITT-FALSE, so a sector holds 128 records.
- When the write pointer enters a new sector, the oldest sector is erased. That leaves 15 x 128 = 1920 events retained.
- On boot, the node scans the sectors for the highest valid seq. NVS keeps a high-water mark, updated at each sector erase, so seq never goes backwards after a crash.
- **Reconnect sequence** (phone):
  1. connect
  2. bond (LE Secure Connections)
  3. MTU 517
  4. 2M PHY
  5. discover services
  6. subscribe to Status, ControlPoint, Event (and BandFrame/Snippet on demand)
  7. read DeviceInfo
  8. AUTH (§7)
  9. read BandTable
  10. `SET_TIME(now)`
  11. `GET_EVENTS_SINCE(lastSeq)`, where `lastSeq` is the latest seq the phone has **persisted** for this node
  12. live events
- The node never deletes an event because it was indicated. Only ring overwrite removes events.

## 7. Security
**Pairing and encryption:**
- Pairing uses LE Secure Connections, Just Works (the node has no IO), with bonding. NimBLE settings: `sm_sc = 1`, `sm_bonding = 1`, `sm_mitm = 0`, `CONFIG_BT_NIMBLE_SM_SC_ONLY = 1` so legacy pairing is refused, and a 16-byte key size.
- Every characteristic needs encryption (§4).

**App-layer authentication (HMAC-SHA256):** this proves that the phone holds the 32-byte per-device key printed on the node's QR label. It also closes the Just Works MITM gap at pairing time, because a relay or impersonator does not know the key.

`addr6` below is the 6 address bytes in printed order.
1. Phone → `AUTH_CHALLENGE(appNonce)`.
2. Node → `nodeNonce`, `nodeProof = HMAC(K, "KRNL-AUTH-N1" ‖ appNonce ‖ nodeNonce ‖ addr6)`.
3. The phone verifies nodeProof in constant time and disconnects on a mismatch (health `authFailed`).
4. Phone → `AUTH_RESPONSE(appProof = HMAC(K, "KRNL-AUTH-A1" ‖ nodeNonce ‖ appNonce ‖ addr6))`.
5. Node → OK, and the connection becomes authenticated. Otherwise AUTH_FAILED. After 3 failures the node disconnects and ignores AUTH for 10 s.

**Nonces** come from an HMAC-based deterministic generator keyed with K, with no RNG dependency. Both inputs never repeat:
- `nodeNonce = HMAC(K, "KRNL-NONCE" ‖ bootCount u32 ‖ counter u32 ‖ uptimeUs u64)[0:16]`. bootCount is in NVS.
- `appNonce = HMAC(K, "KRNL-APPNONCE" ‖ counter u64 ‖ epochMs u64)[0:16]`. The counter is persisted on the phone.

**Gating:** auth state is per connection and is cleared on disconnect. Config, BandTable, BandFrame, Event and Snippet, and every ControlPoint opcode except AUTH, are denied until the connection is authenticated.

**Keys:**
- *Node:* the key is in an eFuse key block with purpose HMAC_UP, used through the ESP32-S3 HMAC peripheral, so software cannot read it (`CONFIG_KERNEL_KEY_EFUSE`). Dev boards can keep it in encrypted NVS instead (`CONFIG_KERNEL_KEY_NVS`).
- *Phone:* the key is imported into **Android Keystore** as a non-exportable `HmacSHA256` key (`KeyProtection`, PURPOSE_SIGN). Only the alias and `fingerprint = hex(sha256(K))[0:8]` are stored in app preferences, and the raw key bytes are zeroed after import.

**QR label:** `kernel:sensor:v1:<address>:<base64url key>:<type>`.
- `<address>` is `AA:BB:CC:DD:EE:FF` in uppercase hex.
- `<base64url key>` is 32 bytes, unpadded (43 chars; padding is accepted).
- `<type>` is one of `us_air`, `contact_piezo`, `contact_accel`, `audio_air`.

Parsers split on `:` and require exactly 11 fields.

## 8. Android link (sensor-link)
- **Permissions:** `BLUETOOTH_SCAN` (`usesPermissionFlags="neverForLocation"`) and `BLUETOOTH_CONNECT`. Legacy `BLUETOOTH`/`BLUETOOTH_ADMIN` have `maxSdkVersion="30"`. Also `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_CONNECTED_DEVICE` and `REQUEST_OBSERVE_COMPANION_DEVICE_PRESENCE`. There is **no location permission**.
- **Pairing:** CompanionDeviceManager `associate()` with an `AssociationRequest` (single device) and a `BluetoothLeDeviceFilter` on the service UUID and the QR address.
- **Presence:** on API 36, `startObservingDevicePresence(ObservingDevicePresenceRequest)` plus a `CompanionDeviceService`; API 31–35 use the address-based variant. A PendingIntent scan filter on the service UUID is the fallback while a session waits for its node.
- **Sessions:** a `connectedDevice` foreground service that is started **only while the app is visible** and stopped by STOP_SESSION or the notification action.
- The link uses native Kotlin and Pigeon. `flutter_blue_plus` is not used.

## 9. Signature pack (phone side)
`sensor-link/assets/signature_pack_v0_1.properties` is versioned (`pack.version`), lists its signatures, sets `pack.experimental=true` (the parser refuses anything else) and **rejects unknown keys**.

Rule fields:

| Field | Meaning |
|---|---|
| `classes` | event classes the rule accepts |
| `sensors` | sensor types the rule accepts |
| `minHz`/`maxHz` | the event's min and max frequency must lie in this range |
| `minDurMs`/`maxDurMs` | duration range |
| `maxBwHz` | maximum bandwidth |
| `minImpulses` | minimum impulse or pulse count |
| `minRepHz`/`maxRepHz` | repetition-rate range |
| `regular` | `any`, `required` or `forbidden` |
| `minHarmonics` | minimum overtone count |
| `possibleRatePerS` + `minWindowS` | the window rate rule |
| `source` | literature reference |

**Score:** an event that passes every gate of a rule gets a score in 0..1. The score is the mean of "centredness" terms (1.0 at the centre of each range, 0.5 at its edges). **It is not a probability.** The highest score wins, and ties go to pack order. No passing rule means no match. "No match" is never presented as absence.

**Rates:** results are reported as "N events in M minutes". A rate rule (grain larva: 0.02 bursts/s over at least 180 s) yields `possible` or `belowThreshold`. A shorter window, or a window that overlaps jammed, clipped or survey time, yields `notEvaluated`.

## 10. Duty cycling and power
- With `dutyCycle` set, the node listens for `dutyOnS` and then sleeps (light sleep, radio advertising at 2 s) for `dutyOffS`. Events from the listen windows are stored as usual.
- A session forces continuous listening until STOP_SESSION or disconnect + 60 s.
- Battery is sampled with the ADC (1:2 divider) once a minute. `lowBattery` is set at or below `lowBattPct`.

## 11. Versioning rules
- `proto` (major) appears in the advertising data and in DeviceInfo. The phone refuses to authenticate with a different major and shows "update needed".
- A **minor** version may only append fields at the end of a structure, add opcodes, add characteristics or define reserved bits. Old parsers ignore all of these.
- A **major** bump is required to change, reorder or remove any field, change a unit, or change the auth construction.
- Config has its own `cfgVersion`. A node rejects config writes with an unknown version.
- The signature pack is versioned independently (`pack.version`), and every `SignatureMatch` carries it. Pack keys are closed: a new key needs a new pack version and a parser update.

## 12. Known gaps (reported to the lead)
- `SensorHealth` has no value for `sensorFault` or for "events overwritten". The Dart link exposes the raw bits, and `sensorFault` should be shown as not evaluated.
- `SensorLink` has no snippet API. `BleSensorLink.requestSnippet` is an extra method.
- `SensorLink` has no rate or summary type. `SignaturePack.rate` is an extra helper.
- `SensorEvent.startedAt` is required, so events that cannot be timed are skipped and counted.
- There is no explicit connect or disconnect. The link connects on demand (watchStatus, liveBands, syncEvents, startSurvey, startSession).
