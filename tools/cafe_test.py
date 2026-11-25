#!/usr/bin/env python3
"""Run the cafe-systems checks in the isolated Wine prefix.

Covers the staff roster, the guide, room travel and the cafe-only entrance, then
captures one screenshot per affected screen. Uses the same private prefix as
tools/veil_test.py, so a player save is never read or written.

    python3 tools/cafe_test.py --fresh
"""
import glob
import os
import shutil
import signal
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "Clicky")
BUILD = os.path.join(PROJ, ".gmcache", "build-gms2-windows-VM", "output")
RUNNER = os.path.expanduser(
    "~/.cache/GameMakerCLI/runtimes-gms2/runtime-2026.1.0.28/windows/x64/Runner.exe"
)
TEST = os.path.join(ROOT, ".veil-test")
# Its own prefix: the player's manual test window may be live in .veil-test/wine,
# and two games must never share one save file.
PREFIX = os.path.join(TEST, "cafe-wine")
SAVE = os.path.join(PREFIX, "drive_c", "users", "mikey", "AppData", "Local", "Clicky")
SHOTS = os.path.join(ROOT, "tools", "shots", "ui")


def ensure_prefix():
    if os.path.isdir(PREFIX):
        return
    os.makedirs(TEST, exist_ok=True)
    subprocess.run(["wineboot", "-u"], env=dict(os.environ, WINEPREFIX=PREFIX,
                   WINEDEBUG="-all", WINEDLLOVERRIDES="mscoree,mshtml=",
                   DISPLAY=os.environ.get("DISPLAY", ":0")),
                   stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT, timeout=120)


def main():
    fresh = "--fresh" in sys.argv
    fullscreen = "--fullscreen" in sys.argv
    os.makedirs(SHOTS, exist_ok=True)

    # This check is part of the suite, not an optional lint: a UI surface that
    # drifts back onto the 4x room canvas fails the same run as the game checks.
    audit = subprocess.run(
        [sys.executable, os.path.join(ROOT, "tools", "ui_layout_audit.py")],
        capture_output=True, text=True)
    print(audit.stdout.strip())
    if audit.returncode != 0:
        print(audit.stderr.strip())
        return 1

    ensure_prefix()
    if fresh:
        for f in glob.glob(os.path.join(SAVE, "save.json")):
            os.remove(f)
        for pattern in ("ui_*.png", "cafetest.txt", "cafetrace.txt"):
            for f in glob.glob(os.path.join(SAVE, pattern)):
                os.remove(f)
        # The report folder is not an archive: a stale frame from a removed
        # stage must not be counted as one of this run's screenshots.
        for f in glob.glob(os.path.join(SHOTS, "ui_*.png")):
            os.remove(f)

    env = dict(os.environ,
               WINEPREFIX=PREFIX, WINEDEBUG="-all",
               DISPLAY=os.environ.get("DISPLAY", ":0"),
               CLICKY_CAFETEST="1")
    if fullscreen:
        # Boot the real window instead of pinning a size, so the mode under
        # test is the mode the player gets.
        env["CLICKY_FULLSCREEN"] = "1"
    else:
        env["CLICKY_WINSIZE"] = "960x540"
    log = os.path.join(TEST, "run_cafe.log")
    started = time.time()
    result = os.path.join(SAVE, "cafetest.txt")
    p = subprocess.Popen(["wine", RUNNER, "-game", "Clicky.win"], cwd=BUILD, env=env,
                         stdout=open(log, "w"), stderr=subprocess.STDOUT,
                         start_new_session=True)
    # The suite captures a full set of fullscreen frames; under Wine a frame
    # save can take several seconds, so the deadline must cover the last
    # lesson and room capture. The game writes DONE after its last check, so
    # stop it then rather than waiting out the whole timeout. A stale report
    # from an earlier run cannot satisfy this because its mtime predates us.
    deadline = started + 540
    while time.time() < deadline and p.poll() is None:
        if os.path.exists(result) and os.path.getmtime(result) >= started:
            try:
                if "DONE" in open(result, errors="replace").read().splitlines():
                    break
            except OSError:
                pass
        time.sleep(0.5)
    if p.poll() is None:
        os.killpg(os.getpgid(p.pid), signal.SIGTERM)
        try:
            p.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(os.getpgid(p.pid), signal.SIGKILL)

    text = open(log, errors="replace").read()
    for line in text.splitlines():
        if "ERROR in action" in line or "FATAL" in line:
            print("!!", line)
    for f in glob.glob(os.path.join(SAVE, "ui_*.png")):
        shutil.copy(f, SHOTS)
    if os.path.exists(result):
        report = open(result, errors="replace").read().strip()
        print(report)
        # A killed or crashed run can leave a partial report; only the explicit
        # end marker proves every check ran.
        if "DONE" not in report.splitlines():
            print("!! run ended before its DONE marker")
            return 1
    else:
        print("!! no cafetest.txt written")
        return 1
    print("shots:", len(glob.glob(os.path.join(SHOTS, "ui_*.png"))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
