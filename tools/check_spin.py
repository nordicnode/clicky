#!/usr/bin/env python3
"""The prestige card must finish: spin, reset, close. It used to spin forever.

Run with: CLICKY_SPINTEST=1 tools/shoot.py
"""
import os
import sys

D = os.path.expanduser("~/.wine/drive_c/users/mikey/AppData/Local/Clicky")
p = os.path.join(D, "spin.txt")
if not os.path.exists(p):
    sys.exit("missing spin.txt; run: CLICKY_SPINTEST=1 tools/shoot.py")

rows = [dict(kv.split("=") for kv in r.split())
        for r in open(p).read().strip().rstrip(";").split(";") if r.strip()]

bad = []
closed_at = next((int(r["frame"]) for r in rows if r["live"] == "0"), None)
if closed_at is None:
    bad.append("  the card never closed: a yarn ball spun for the whole run")
last = rows[-1]
if int(last["prestiges"]) < 1:
    bad.append("  prestige never applied")
if int(last["yarn"]) < 1:
    bad.append("  no yarn was paid")

print(f"spin: closed at frame {closed_at}, prestiges={last['prestiges']}, yarn={last['yarn']}")
if bad:
    print("FAIL")
    print("\n".join(bad))
    sys.exit(1)
print("PASS: the ball spins, the reset lands, the card closes")
