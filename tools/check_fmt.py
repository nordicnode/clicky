#!/usr/bin/env python3
"""Read the numbers the game's own formatter produced and check them.

obj_debug writes fmt.txt under CLICKY_DEMO=1, so this tests shipped GML
rather than a Python copy of it.
"""
import os, subprocess, sys

SAVE_DIR = os.path.expanduser("~/.wine/drive_c/users/mikey/AppData/Local/Clicky")
EXPECT = {
    "0": "0", "7": "7", "999": "999", "1000": "1.0K", "1500": "1.5K",
    "8420": "8.4K", "125000": "125K", "1500000": "1.5M", "3200000000": "3.2B",
    "t840": "14m", "t5400": "1h",
    "half": "0.5", "quarter": "4.2",
}

path = os.path.join(SAVE_DIR, "fmt.txt")
if not os.path.exists(path):
    sys.exit(f"missing {path}; run tools/shoot.py first")
raw = open(path).read().strip().rstrip(";")
bad = []
for part in raw.split(";"):
    k, _, got = part.partition("=")
    want = EXPECT.get(k)
    if want is None:
        continue
    if got != want:
        bad.append(f"  {k}: got {got!r}, want {want!r}")
print(f"checked {len(EXPECT)} formatter cases from the running game")
if bad:
    print("FAIL")
    print("\n".join(bad))
    sys.exit(1)
print("PASS: every number on screen reads at the right scale")
