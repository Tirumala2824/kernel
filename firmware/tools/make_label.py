"""Provisioning helper for one Kernel sensor node (run on the bench PC, never in the app).

    python make_label.py --address C0:FF:EE:12:34:56 --type us_air --out node-0001

It writes:
  <out>/key.bin       32-byte per-device key (keep offline; burn it, then delete it)
  <out>/label.txt     QR payload kernel:sensor:v1:<address>:<base64url key>:<type>
  <out>/burn.txt      the espefuse / NVS commands to install the key

The key is generated with the OS CSPRNG (secrets). Print label.txt as a QR code
with any offline tool and stick it on the node enclosure. The QR label is the
only other copy of the key, so treat it like a password.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import re
import secrets
from pathlib import Path

TYPES = ("us_air", "contact_piezo", "contact_accel", "audio_air")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--address", required=True, help="public BT MAC printed by the node at boot (AA:BB:CC:DD:EE:FF)")
    ap.add_argument("--type", required=True, choices=TYPES)
    ap.add_argument("--out", required=True)
    ap.add_argument("--efuse-block", default="BLOCK_KEY4", help="eFuse key block matching CONFIG_KERNEL_HMAC_KEY_ID")
    a = ap.parse_args()
    if not re.fullmatch(r"([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}", a.address):
        raise SystemExit("address must look like AA:BB:CC:DD:EE:FF")
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=False)
    key = secrets.token_bytes(32)
    (out / "key.bin").write_bytes(key)
    k64 = base64.urlsafe_b64encode(key).decode().rstrip("=")
    label = f"kernel:sensor:v1:{a.address.upper()}:{k64}:{a.type}"
    (out / "label.txt").write_text(label + "\n", encoding="utf-8")
    fp = hashlib.sha256(key).hexdigest()[:8]
    (out / "burn.txt").write_text(
        "\n".join(
            [
                f"# key fingerprint {fp} (the app shows the same 8 hex chars after pairing)",
                "# Production (CONFIG_KERNEL_KEY_EFUSE): irreversible, the key becomes unreadable by software",
                f"espefuse.py --port PORT burn_key {a.efuse_block} key.bin HMAC_UP",
                "# Development (CONFIG_KERNEL_KEY_NVS): namespace 'auth', key 'key', 32-byte blob. nvs.csv:",
                "#   key,type,encoding,value",
                "#   auth,namespace,,",
                "#   key,file,binary,key.bin",
                "# then build it with nvs_partition_gen.py and flash it over the nvs partition (erases bonds).",
                "",
            ]
        ),
        encoding="utf-8",
    )
    print(f"wrote {out}/ (fingerprint {fp})")


if __name__ == "__main__":
    main()
