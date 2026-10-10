# Kernel sensor nodes: reference firmware

ESP-IDF v5 (5.1 or later) firmware for the three dedicated frequency-detection nodes, using ESP32-S3 and NimBLE. The protocol is in [docs/sensor-protocol.md](../docs/sensor-protocol.md) and the guardrails in [docs/guardrails.md](../docs/guardrails.md) §10.

> **Status: reference design, not bench-validated.** `idf.py build` has **not** been run: ESP-IDF is not installed on the development PC.
> - The portable components (`components/kernel_detect`, `components/kernel_proto`) compile cleanly with `-Wall -Wextra -Werror -Wpedantic` under clang (NDK, `-fsyntax-only`).
> - `reference/` mirrors them in Python, and its tests pass.
> - Every detector threshold and every signature rule is literature-derived and **experimental**.

## What a node does (and does not do)
- It runs the FFT, a running 5 % quantile noise floor, jammer and clip detection and the detectors **on board**.
- It sends only:
  - band energies (`BandFrame`)
  - detection events (`Event`, 30 B)
  - health (`Status`)
  - on explicit request only, a small u8 *feature* spectrogram (`Snippet`) that is held in RAM.
- **No audio is ever stored or sent.** There is no audio characteristic and no opcode that returns samples.
- **US_AIR:** every PCM sample is high-passed at 20 kHz (6th-order Butterworth, in place) right after decimation, before anything is buffered. The raw PDM bits in the 3 x 4 ms DMA descriptors are overwritten continuously.
- **CONTACT:** samples are consumed in 0.5 ms blocks and FFT frames and are never kept.
- A jammed, clipped or surveying node emits **no events** and reports the reason in `Status`. The phone shows it as "not evaluated", never as "nothing there".

## Layout
| Path | What |
|---|---|
| `components/kernel_detect/` | Portable C11 detectors (no ESP dependencies): FFT, biquads, PDM CIC + half-band decimator, spectral detector (floor, jammer, tonal/FM blobs, harmonics, chirps), impulse/burst/pulse-train detector, clip detector |
| `components/kernel_proto/` | Portable wire codec (docs/sensor-protocol.md), auth message builders, CRC-16 |
| `main/` | Node app: capture front ends, pipeline, flash event ring, RAM snippets, auth key/HMAC, battery and clock, NimBLE GATT server, duty cycling |
| `reference/` | Python (numpy/scipy) mirror of `kernel_detect` + `kernel_proto`, synthetic scenarios, pytest, exported vectors used by the Dart and Kotlin tests |
| `tools/make_label.py` | Bench provisioning: per-device key, QR payload, eFuse/NVS burn commands |
| `partitions.csv` | Adds the 64 KiB `kevents` ring partition |
| `sdkconfig.defaults`, `sdkconfig.<node>` | Common defaults and per-node fragments |

## Bill of materials (approximate single-unit prices, 2026, USD)
Prices are indicative hobby/distributor prices; check before ordering. The shared core for every node:

| Part | Example | Approx. |
|---|---|---|
| MCU + BLE module | Espressif ESP32-S3-WROOM-1-N8 (devkit for prototypes: ESP32-S3-DevKitC-1) | $3.5 module / $12 devkit |
| 3.3 V LDO, low Iq | TI TPS7A02 or Microchip MCP1700 | $0.4 |
| Li-ion cell + holder | 18650, 3000 mAh | $6 |
| Charger | MCP73831 (or a TP4056 module) | $0.6–1 |
| Battery sense | 2 x 1 MΩ divider + 100 nF | $0.05 |
| Pairing button + LED | tactile switch, 0603 LED | $0.2 |
| Enclosure | IP54 box, label area for the QR code | $3–5 |

**US_AIR** (rodent USVs, repeller detection). Total about **$15–25** on a module PCB, or $30–40 on dev boards.

| Part | Example | Approx. |
|---|---|---|
| Ultrasonic PDM mic, 100 Hz–80 kHz | Knowles/Syntiant **SPH0641LU4H-1** (ultrasonic mode at 3.072–4.8 MHz). Do not use the SPU0410LR5H (obsolete). | $1.5–2.5 (breakout ~$10) |
| Acoustic port | open port with stainless mesh. Hydrophobic membranes attenuate ultrasound. | $0.5 |
| Decoupling, CLK series resistor | 100 nF, 33 Ω | $0.05 |

**CONTACT_PIEZO** (larvae in grain, termite drumming). Total about **$20–35**.

| Part | Example | Approx. |
|---|---|---|
| Piezo disc | Murata 7BB-27-4 (27 mm) | $0.5–1 |
| High-impedance buffer (Zin ≥ 10 MΩ) | JFET source follower (MMBF5457/J201, 10 MΩ gate bias) + op-amp gain x10–x50 (MCP6002), or a charge amplifier | $0.5–1 |
| I2S audio ADC | TI **PCM1808** (24-bit, 48 kSPS, slave mode) module | $2–4 |
| Waveguide probe | 10–30 cm stainless rod, epoxied to the disc | $2–5 |

**CONTACT_ACCEL** (alternative contact front end). Total about **$30–45**.

| Part | Example | Approx. |
|---|---|---|
| Wideband accelerometer | ST **IIS3DWB** (26.7 kHz ODR, SPI), or eval board STEVAL-MKI208V1K | $8–12 chip / ~$15 board |

**AUDIO_AIR** (mosquito flight tone, cricket chirps). Total about **$15–25**.

| Part | Example | Approx. |
|---|---|---|
| Standard PDM mic | Infineon IM69D130 or ST MP34DT05 | $1.5–3 |

## Wiring (defaults, change in `menuconfig` → Kernel sensor node → Pins)
| Signal | GPIO | US_AIR (SPH0641) | CONTACT_PIEZO (PCM1808) | CONTACT_ACCEL (IIS3DWB) | AUDIO_AIR (PDM mic) |
|---|---|---|---|---|---|
| MIC_CLK | 4 | CLK (3.072 MHz) | BCK | n/a | CLK |
| MIC_DATA | 5 | DATA | DOUT | n/a | DATA |
| I2S_WS | 6 | n/a | LRCK | n/a | n/a |
| I2S_MCLK | 7 | n/a | SCKI (12.288 MHz) | n/a | n/a |
| SPI SCLK/MOSI/MISO/CS | 12/11/13/10 | n/a | n/a | SPC/SDI/SDO/CS | n/a |
| BATT_ADC | 1 | 1:2 divider from BAT+ | same | same | same |
| BUTTON | 0 | to GND (pairing window) | same | same | same |

- **SPH0641LU4H-1:** VDD 3.3 V with 100 nF at the pins. Tie SELECT to GND, keep CLK short (< 5 cm) with a 33 Ω series resistor. If the decoded stream looks like noise, tie SELECT to VDD or enable `KERNEL_PDM_BCLK_INVERT`.
- **PCM1808:** FMT = GND (I2S), MD0 = MD1 = GND (slave). Feed VINL from the buffered piezo signal through AC coupling, and AC-ground VINR. Use 5 V analog and 3.3 V digital as the module requires.
- **IIS3DWB:** SPI mode 3 at 8 MHz. Mount it rigidly on the probe, with the Z axis along the rod.

## Build, provision, flash
```bash
. $IDF_PATH/export.sh                      # ESP-IDF v5.1+
cd firmware
idf.py set-target esp32s3
# one build directory per node type:
idf.py -B build-us_air -D SDKCONFIG=build-us_air/sdkconfig \
       -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.us_air" build
idf.py -B build-us_air -p PORT flash monitor
```
For the other nodes, swap `us_air` for `contact_piezo`, `contact_accel` or `audio_air`.

**Provisioning** (once per node):
1. Flash the firmware, open the monitor and note the public BT address printed at boot.
2. Run `python tools/make_label.py --address AA:BB:CC:DD:EE:FF --type us_air --out node-0001`. It writes `key.bin`, `label.txt` and `burn.txt`.
3. Install the key:
   - **Production:** `espefuse.py --port PORT burn_key BLOCK_KEY4 key.bin HMAC_UP`. This is irreversible, and the key is then usable only through the HMAC peripheral, never readable by software.
   - **Dev boards:** choose `KERNEL_KEY_NVS` and write the blob as described in `burn.txt`.
4. Print `label.txt` as a QR code, stick it on the enclosure, and delete `key.bin`.
5. In the app, scan the QR. CompanionDeviceManager offers the node, Android asks to pair (Just Works), the app runs the HMAC handshake, and it shows the same 8-hex fingerprint as `burn.txt`.

**Forget/re-pair:** "Forget" in the app sends CLEAR_BOND, so the node drops that phone's bond. Erasing NVS also drops bonds, config and the seq high-water mark, and in NVS-key mode the key as well.

## Power notes (estimates to be measured)
| Mode | Estimate |
|---|---|
| Continuous listening, US_AIR (240 MHz, I2S, FFT 750/s) | ~60–90 mA, so about 1.5–2 days on 3000 mAh |
| Continuous, CONTACT / AUDIO | ~40–60 mA |
| Duty cycle 60 s on / 540 s off (`dutyCycle` flag, `dutyOffS = 540`) | ~8–15 mA average, so about 1–2 weeks |
| Advertising only (1 s interval, light sleep) | well under 1 mA |

- Sessions (START_SESSION) force continuous listening. Surveys do too.
- Low battery (≤ `lowBattPct`) slows advertising to 2 s and is reported in `Status`.
- The ESP32-S3 has no APLL, so the I2S clock is a fractional divider of the 160 MHz PLL. PDM mics tolerate the jitter, but measure the US_AIR noise floor.

## Bench validation checklist
1. **Boot:**
   - The log shows node type, boot count and ring range, and Status has no `sensorFault`.
   - DeviceInfo (22 B) matches `reference/vectors/protocol_v1.json` layouts.
2. **Security:**
   - Unencrypted reads fail with ATT 0x0F.
   - Before AUTH, Config/BandTable reads fail with 0x08 and GET_EVENTS_SINCE answers NOT_AUTHENTICATED.
   - A wrong key fails AUTH, and 3 failures lock AUTH out for 10 s.
   - Legacy pairing is refused.
3. **US_AIR privacy filter:** play a 1–10 kHz tone or speech at 90 dB SPL next to the node. Band frames stay within a few dB of the floor and no events appear.
4. **US_AIR detection:**
   - Replay published mouse/rat USV recordings through an ultrasonic speaker (≥ 192 kSPS DAC) and compare event peak, min/max and slope with a spectrogram.
   - Then repeat at increasing distance to find the practical range.
5. **Repellers:** run a commercial ultrasonic repeller.
   - A stationary tone gives JAMMED within about 2 s and no events.
   - A sweeping repeller gives JAMMED by the occupancy rule.
   - JAMMED clears about 5 s after switch-off.
6. **Contact:**
   - Pencil-lead breaks and 1–5 ms tap impulses on the probe count as impulses.
   - Infested-grain recordings (*Sitophilus*, *Rhyzopertha*) played through a shaker give bursts, and the bursts-per-minute rate is computed.
   - A running motor or pump on the bin gives JAMMED and no events.
7. **Clipping:** overdrive the input (clap at the AUDIO node, strike the probe). CLIPPED is raised for 2 s and no events are emitted.
8. **Store-and-forward:**
   - Go out of range for an hour with periodic stimuli, then reconnect. GET_EVENTS_SINCE returns every seq with no gaps.
   - Power-cycle: seq continues.
   - Fill the ring (> 1920 events): `oldestSeq` advances and `eventsOverwritten` is set.
9. **Time:**
   - Events recorded before SET_TIME after a reboot carry uptime and `bootLow`, and the phone places them in time only within the same boot.
10. **Power:** measure current per mode with a power profiler, and calibrate the battery % table in `main/power.c`.
11. **Field false-positive survey:** run each node type for 24 h in an empty store room and record the event rates (the site survey baseline) before reading anything into rates.

## Detector reference and vectors
```bash
cd firmware/reference
uv run python -I -m pytest            # detector + codec tests
uv run python -I -m kernel_ref.export # regenerate vectors/*.json and components/kernel_detect/kd_halfband.c
```
After any algorithm change:
1. Change C and Python together.
2. Re-export the vectors.
3. Run `flutter test` in `sensor-link/` and the Kotlin unit tests, which decode the same vectors.
