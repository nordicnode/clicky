#!/usr/bin/env python3
"""Check that a prestige wipes the run and keeps the account."""
import os, sys

p = os.path.expanduser("~/.wine/drive_c/users/mikey/AppData/Local/Clicky/prestige.txt")
if not os.path.exists(p):
    sys.exit(f"missing {p}; run: CLICKY_PTEST=1 tools/shoot.py")
d = dict(x.split("=", 1) for x in open(p).read().strip().rstrip(";").split(";"))

expect = {
    "yarn": 10,        # 60M run -> 10 yarn
    "fish": 0,
    "run": 0,
    "tiersum": 0,
    "paw": 0,
    "lifekept": 1,     # lifetime survives, it drives zones and the album
    "hats": 2,         # 10 yarn earns beanie (1) and crown (5)
}
bad = [f"  {k}: got {d[k]}, want {v}" for k, v in expect.items() if float(d[k]) != v]
if float(d["gain"]) != 10:
    bad.append(f"  gain: got {d['gain']}, want 10")
if abs(float(d["mult"]) - 2.0) > 0.001:
    bad.append(f"  mult: got {d['mult']}, want 2.0 (10 yarn = +100%)")
if d["equipped"] != "crown":
    bad.append(f"  equipped: got {d['equipped']!r}, want the newest hat, 'crown'")
if float(d["prestiges"]) != 1:
    bad.append(f"  prestiges: got {d['prestiges']}, want 1")

print(f"prestige: gain={d['gain']} yarn={d['yarn']} mult=x{d['mult']} "
      f"hats={d['hats']} lifetime kept={d['lifekept']}")
if bad:
    print("FAIL"); print("\n".join(bad)); sys.exit(1)
print("PASS: the run resets, the account keeps its yarn, lifetime and hats")
