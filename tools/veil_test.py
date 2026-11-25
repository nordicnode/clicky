#!/usr/bin/env python3
"""Run the Hollow's isolated verification pass under its own Wine prefix.

The game writes saves into a sandbox inside the prefix, so this never reads or
writes the player's real save. Phase 1 exercises the rules and every screen;
phase 2 reloads that save, then wakes into the cafe for the door shot.

    python3 tools/veil_test.py 1 --fresh --fullscreen
    python3 tools/veil_test.py 2 --fullscreen
"""
import glob
import json
import os
import shutil
import signal
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "Clicky")
BUILD = os.path.join(PROJ, ".gmcache", "build-gms2-windows-VM", "output")
RUNNER = os.path.expanduser(
    "~/.cache/GameMakerCLI/runtimes-gms2/runtime-2026.1.0.28/windows/x64/Runner.exe"
)
TEST = os.path.join(ROOT, ".veil-test")
PREFIX = os.path.join(TEST, "wine")
SAVE = os.path.join(PREFIX, "drive_c", "users", "mikey", "AppData", "Local", "Clicky")
SHOTS = os.path.join(ROOT, "tools", "shots", "veil")


def main():
    phase = sys.argv[1] if len(sys.argv) > 1 else "1"
    fresh = "--fresh" in sys.argv
    fullscreen = "--fullscreen" in sys.argv
    os.makedirs(SHOTS, exist_ok=True)
    if fresh:
        for f in glob.glob(os.path.join(SAVE, "save.json")):
            os.remove(f)
        for pattern in ("veil_*.png", "veiltest*.txt"):
            for f in glob.glob(os.path.join(SAVE, pattern)):
                os.remove(f)
        # The shots folder is a report, not an archive: a stale image from an
        # older run must not be counted as one of this run's twelve screens.
        for f in glob.glob(os.path.join(SHOTS, "veil_*.png")):
            os.remove(f)
    if phase == "3":
        # Strip the new key to reproduce a save written before the Hollow.
        path = os.path.join(SAVE, "save.json")
        data = json.load(open(path))
        data.pop("occult", None)
        json.dump(data, open(path, "w"))

    env = dict(os.environ,
               WINEPREFIX=PREFIX, WINEDEBUG="-all", DISPLAY=os.environ.get("DISPLAY", ":0"),
               CLICKY_VEILTEST=phase)
    if fullscreen:
        env["CLICKY_FULLSCREEN"] = "1"
    else:
        env["CLICKY_WINSIZE"] = "960x540"
    log = os.path.join(TEST, "run%s.log" % phase)
    p = subprocess.Popen(["wine", RUNNER, "-game", "Clicky.win"], cwd=BUILD, env=env,
                         stdout=open(log, "w"), stderr=subprocess.STDOUT,
                         start_new_session=True)
    # Twelve native Hollow screens are captured at 1920x1080; a Wine frame
    # save can take several seconds, so the old 75s stopped before the last
    # screen (and before its scale check).
    try:
        p.wait(timeout=220)
    except subprocess.TimeoutExpired:
        os.killpg(os.getpgid(p.pid), signal.SIGTERM)
        try:
            p.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(os.getpgid(p.pid), signal.SIGKILL)

    text = open(log, errors="replace").read()
    for line in text.splitlines():
        if "ERROR in action" in line or "FATAL" in line:
            print("!!", line)
    for f in glob.glob(os.path.join(SAVE, "veil_*.png")):
        shutil.copy(f, SHOTS)
    for name in ("veiltest.txt", "veiltest2.txt", "veiltest3.txt"):
        path = os.path.join(SAVE, name)
        if os.path.exists(path):
            print("----", name)
            print(open(path, errors="replace").read().strip())
    print("shots:", len(glob.glob(os.path.join(SHOTS, "veil_*.png"))))


if __name__ == "__main__":
    main()
