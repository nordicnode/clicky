#!/usr/bin/env python3
"""Build the Windows VM, run it under Wine, and collect screenshots.

The GameMaker CLI cannot launch on this box (two upstream path bugs), so this
script does the build, ignores the launch failure, and then starts the runtime
itself. CLICKY_DEMO=1 makes the game play a fixed scripted sequence and save
comparable screenshots.

    python3 tools/shoot.py            # build + demo shots
    python3 tools/shoot.py --no-build # just re-run the last build
"""
import glob
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "Clicky")
BUILD = os.path.join(PROJ, ".gmcache", "build-gms2-windows-VM", "output")
RUNNER = os.path.expanduser(
    "~/.cache/GameMakerCLI/runtimes-gms2/runtime-2026.1.0.28/windows/x64/Runner.exe"
)
GMC = os.path.expanduser(
    "~/.npm/_npx/166e0ec5f4c2d768/node_modules/@gamemaker/gm-cli/dist/cli.js"
)
NODE = shutil.which("node") or "node"
SAVE = os.path.expanduser("~/.wine/drive_c/users/mikey/AppData/Local/Clicky")
SHOTS = os.path.join(ROOT, "tools", "shots")


def sh(cmd, cwd=None, env=None, timeout=600):
    return subprocess.run(cmd, cwd=cwd, env=env, timeout=timeout,
                          capture_output=True, text=True)


def main():
    if "--no-build" not in sys.argv:
        print("building...")
        r = sh([NODE, GMC, "run", "--target", "windows", "--no-verbose"], cwd=PROJ)
        # the launcher is expected to fail; the build itself is what matters
        if not os.path.exists(os.path.join(BUILD, "Clicky.win")):
            print(r.stdout[-3000:])
            print("BUILD FAILED")
            return 1

    os.makedirs(SHOTS, exist_ok=True)
    for f in glob.glob(os.path.join(SHOTS, "*.png")):
        os.remove(f)
    for f in glob.glob(os.path.join(SAVE, "shot_*.png")):
        os.remove(f)

    env = dict(os.environ, DISPLAY=":0", CLICKY_DEMO="1")
    print("running under wine...")
    r = sh(["wine", RUNNER, "-game", "Clicky.win"], cwd=BUILD, env=env, timeout=120)
    with open(os.path.join(SHOTS, "run.log"), "w") as f:
        f.write(r.stdout + r.stderr)
    bad = [l for l in (r.stdout + r.stderr).splitlines() if "ERROR in action" in l]
    for l in bad[:5]:
        print("  !!", l)

    got = sorted(glob.glob(os.path.join(SAVE, "shot_*.png")))
    for p in got:
        shutil.copy(p, SHOTS)
    for p in sorted(glob.glob(os.path.join(SHOTS, "*.png"))):
        print(" ", p)
    return 0 if got else 1


if __name__ == "__main__":
    sys.exit(main())
