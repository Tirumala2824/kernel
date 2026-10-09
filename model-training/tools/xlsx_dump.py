"""Dump the cell text of every sheet in an .xlsx file using only the stdlib.

Usage:
    uv run python -I tools/xlsx_dump.py data/survey/TreeVibes.xlsx
"""

from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
import zipfile

NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}


def dump(path: str) -> None:
    with zipfile.ZipFile(path) as z:
        shared: list[str] = []
        if "xl/sharedStrings.xml" in z.namelist():
            root = ET.fromstring(z.read("xl/sharedStrings.xml"))
            for si in root.findall("m:si", NS):
                shared.append("".join(t.text or "" for t in si.iter(f"{{{NS['m']}}}t")))
        sheets = sorted(n for n in z.namelist() if re.match(r"xl/worksheets/sheet\d+\.xml", n))
        for name in sheets:
            print(f"### {name}")
            root = ET.fromstring(z.read(name))
            for row in root.iter(f"{{{NS['m']}}}row"):
                cells = []
                for c in row.findall("m:c", NS):
                    v = c.find("m:v", NS)
                    text = v.text if v is not None else ""
                    if c.get("t") == "s" and text:
                        text = shared[int(text)]
                    elif c.get("t") == "inlineStr":
                        text = "".join(t.text or "" for t in c.iter(f"{{{NS['m']}}}t"))
                    cells.append(f"{c.get('r')}={text}")
                print(" | ".join(cells))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    dump(sys.argv[1])
