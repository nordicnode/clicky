#!/usr/bin/env python3
"""Play 30 minutes of cafe time without a human: taps, buys, resets, logs.

Uses CLICKY_SOAK=1, which runs the economic clock at 6x so half an hour of
game time takes about five minutes of wall clock.
"""
import glob
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD = os.path.join(ROOT, "Clicky", ".gmcache", "build-gms2-windows-VM", "output")
RUNNER = os.path.expanduser(
    "~/.cache/GameMakerCLI/runtimes-gms2/runtime-2026.1.0.28/windows/x64/Runner.exe")
SAVE = os.path.expanduser("~/.wine/drive_c/users/mikey/AppData/Local/Clicky")

for f in ("soak.txt", "save.json"):
    p = os.path.join(SAVE, f)
    if os.path.exists(p):
        os.remove(p)

env = dict(os.environ, DISPLAY=":0", CLICKY_SOAK="1", CLICKY_DEMO="",
           CLICKY_SOAK_END=os.environ.get("CLICKY_SOAK_END", "1800"))
print("soaking (about five minutes)...")
r = subprocess.run(["wine", RUNNER, "-game", "Clicky.win"], cwd=BUILD, env=env,
                   capture_output=True, text=True, timeout=900)
log = r.stdout + r.stderr
bad = [l for l in log.splitlines() if "ERROR in action" in l or "FATAL" in l]
for l in bad[:6]:
    print("  !!", l)
if bad:
    # the whole stack, because the line above is never the interesting one
    i = log.find("ERROR in action")
    print(log[max(0, i - 200):i + 900])
sys.exit(1 if bad else 0)
