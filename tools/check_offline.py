#!/usr/bin/env python3
"""Check the offline payout using the numbers the game itself computed."""
import os, sys

SAVE = os.path.expanduser("~/.wine/drive_c/users/mikey/AppData/Local/Clicky/offline.txt")
path = os.path.join(SAVE)
if not os.path.exists(path):
    sys.exit(f"missing {path}; run: CLICKY_OFFTEST=1 tools/shoot.py")
d = dict(p.split("=", 1) for p in open(path).read().strip().rstrip(";").split(";"))

fails = []
def near(k, want, tol):
    got = float(d[k])
    if abs(got - want) > tol:
        fails.append(f"  {k}: got {got:g}, want {want:g} (+/-{tol:g})")

near("tenmin", 600, 3)        # 10 minutes away pays for 10 minutes
near("sixdays", 28800, 1)     # capped at 8 hours, no matter how long
near("fresh", 0, 0)           # a brand-new save gets nothing
near("ratio", 1, 0.001)       # exactly half the rate, as designed
near("frenzy", 2, 0.001)      # a frenzy doubles the live rate
near("base", 1, 0.001)        # ... and the shown rate excludes it

print(f"offline: 10min={d['tenmin']}s  6days={d['sixdays']}s  fresh={d['fresh']}s  "
      f"paid={float(d['paid']):.0f} of {float(d['expect']):.0f}")
if fails:
    print("FAIL"); print("\n".join(fails)); sys.exit(1)
print("PASS: offline time is clamped, pays half rate, skips fresh saves, "
      "and frenzy doubles only the live rate")
