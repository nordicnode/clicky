#!/usr/bin/env python3
"""Real-input probe for the three reported cafe bugs.

Boots the built game in the isolated Wine prefix with a save whose pantry is
open, then drives real X11 clicks and reads the game's own save back:

  * click the cat while the pantry is open -> stats.clicks rises, in_hollow
    stays false (the door did not steal the pet);
  * click the strip body, the X, the old X spot and the old body -> the guide
    never opens, and the collapsed strip stays collapsed;
  * click the explicit ? -> the strip comes back;
  * click the pantry above the cat -> the Hollow opens (the door still works).

The window is 960x540 while the GUI is 1920x1080, so every probe point below
is half the real native layout coordinate.

    python3 tools/strip_click_probe.py
"""
import json
import os
import signal
import subprocess
import sys
import time

from PIL import Image
from Xlib import X, display
from Xlib.ext import xtest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "Clicky")
BUILD = os.path.join(PROJ, ".gmcache", "build-gms2-windows-VM", "output")
RUNNER = os.path.expanduser(
    "~/.cache/GameMakerCLI/runtimes-gms2/runtime-2026.1.0.28/windows/x64/Runner.exe"
)
PREFIX = os.path.join(ROOT, ".veil-test", "probe-wine")
SAVE = os.path.join(PREFIX, "drive_c", "users", "mikey", "AppData", "Local", "Clicky")
SHOTS = os.path.join(ROOT, "tools", "shots", "probe")
TITLE = "Clicky's Cat Cafe"
ALL_LESSONS = "|".join([
    "offline", "door", "parlour", "hall", "garden", "cellar", "relics", "night",
    "staff", "festival", "era", "layer0", "layer1", "layer2", "layer3",
    "layer4", "counter", "journal", "rooms",
])


def write_fixture():
    """A cafe save whose pantry is already found, in the first room."""
    os.makedirs(SAVE, exist_ok=True)
    fixture = {
        "v": 3,
        "fish": 1200000.0,
        "run_earned": 900000.0,
        "lifetime_earned": 8000000.0,
        "layers": {"yarn": 12.0},
        "earned": {"yarn": 12.0, "moon": 1.0},
        "occult": {"found": True, "in_hollow": False, "closings": 0, "knocks": 3},
        "world": {"zone": 0, "pinned": 1},
        "stats": {"clicks": 100, "purchases": 10},
        "guide": {"seen": ALL_LESSONS, "hidden": False},
        "settings": {"mute_music": False, "mute_sfx": False, "reduce_motion": False},
        "last_seen": 0,
    }
    with open(os.path.join(SAVE, "save.json"), "w") as f:
        json.dump(fixture, f)


def read_save():
    try:
        with open(os.path.join(SAVE, "save.json")) as f:
            return json.load(f)
    except Exception:
        return {}


def main():
    os.makedirs(SHOTS, exist_ok=True)
    write_fixture()
    d = display.Display(os.environ.get("DISPLAY", ":0"))
    root = d.screen().root
    before = set(c.id for c in root.query_tree().children)

    env = dict(os.environ, WINEPREFIX=PREFIX, WINEDEBUG="-all",
               DISPLAY=os.environ.get("DISPLAY", ":0"),
               CLICKY_WINSIZE="960x540")
    log = open("/tmp/strip_probe.log", "w")
    p = subprocess.Popen(["wine", RUNNER, "-game", "Clicky.win"], cwd=BUILD, env=env,
                         stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    failures = []
    try:
        win = None
        for _ in range(100):
            time.sleep(0.25)
            for c in root.query_tree().children:
                if c.id in before:
                    continue
                try:
                    if c.get_wm_name() == TITLE:
                        win = c
                        break
                except Exception:
                    pass
            if win is not None:
                break
        if win is None:
            print("!! no game window")
            return 1
        time.sleep(4.5)                      # boot, save load, tutorial self-clear
        g = win.get_geometry()
        t = win.translate_coords(root, 0, 0)
        origin_x, origin_y = -t.x, -t.y
        print("window", g.width, g.height, "at", origin_x, origin_y)
        if (g.width, g.height) != (960, 540):
            print("!! unexpected window size")
            return 1

        def shot(name):
            img = win.get_image(0, 0, g.width, g.height, X.ZPixmap, 0xffffffff)
            path = os.path.join(SHOTS, name)
            Image.frombytes("RGB", (g.width, g.height), img.data,
                            "raw", "BGRX").save(path)
            print("shot", name)

        def click(cx, cy, label):
            # Move and press in one request batch: waiting after the warp lets a
            # physical mouse (or the user) drag the press off the target.
            ax, ay = origin_x + cx, origin_y + cy
            xtest.fake_input(d, X.MotionNotify, x=ax, y=ay)
            d.sync()
            time.sleep(0.03)
            xtest.fake_input(d, X.ButtonPress, 1)
            d.sync()
            time.sleep(0.06)
            xtest.fake_input(d, X.ButtonRelease, 1)
            d.sync()
            time.sleep(0.8)
            print("click", label, (cx, cy))

        def check(name, ok, detail):
            print(("PASS " if ok else "FAIL ") + name + " | " + detail)
            if not ok:
                failures.append(name)

        start = read_save()
        print("save before: clicks", start.get("stats", {}).get("clicks"),
              "in_hollow", start.get("occult", {}).get("in_hollow"))
        shot("1_cafe_door_open.png")
        # The cat's generous 56px circle overlaps the open pantry. This is the
        # reported click-through: it must pet, not open the Hollow. Two taps a
        # second apart also get past save_touch's one-second write throttle.
        click(300, 372, "cat center over the open pantry")
        time.sleep(1.2)
        click(300, 372, "cat center again")
        time.sleep(1.0)
        after = read_save()
        clicks0 = start.get("stats", {}).get("clicks", 0)
        clicks1 = after.get("stats", {}).get("clicks", 0)
        check("cat.pet.vs.door",
              clicks1 > clicks0 and after.get("occult", {}).get("in_hollow") is False,
              "clicks " + str(clicks0) + " -> " + str(clicks1)
              + ", in_hollow " + str(after.get("occult", {}).get("in_hollow")))
        shot("2_cat_petted_cafe.png")

        # Strip body is display-only: no guide card may open. The X is the
        # native 728..776 x 916..964 box, i.e. 364..388 / 458..482 here.
        click(140, 475, "strip body (must not open the guide)")
        shot("3_body_no_guide.png")
        click(376, 470, "strip X (hide)")
        time.sleep(0.2)
        hidden1 = read_save().get("guide", {}).get("hidden")
        shot("4_hidden.png")
        click(376, 470, "old X spot while hidden")
        click(140, 475, "old body while hidden")
        time.sleep(0.2)
        hidden2 = read_save().get("guide", {}).get("hidden")
        shot("5_still_hidden.png")
        check("strip.stays.closed", hidden1 is True and hidden2 is True,
              "hidden after X and after old-area clicks")
        click(30, 510, "explicit ? (restore)")
        time.sleep(0.2)
        reopened = read_save().get("guide", {}).get("hidden")
        check("strip.only.question.opens", reopened is False,
              "hidden " + str(reopened) + " after the explicit ?")
        shot("7_restored.png")

        # The door above the cat's circle must still work.
        click(320, 220, "pantry above the cat")
        time.sleep(1.0)
        hollow = read_save()
        check("door.still.opens", hollow.get("occult", {}).get("in_hollow") is True,
              "in_hollow " + str(hollow.get("occult", {}).get("in_hollow")))
        shot("8_hollow.png")
        # Dismiss the title card, then wake back to the cafe. Native WAKE is
        # 1728..1888 x 36..92 at 1920, i.e. 864..944 x 18..46 at 960.
        click(900, 36, "hollow title card / WAKE")
        click(900, 36, "WAKE")
        time.sleep(1.0)
        wake = read_save()
        check("hollow.wake", wake.get("occult", {}).get("in_hollow") is False,
              "in_hollow " + str(wake.get("occult", {}).get("in_hollow")))
        shot("9_back_in_cafe.png")

        print("RESULT", "PASS" if not failures else "FAIL " + ",".join(failures))
        return 0 if not failures else 1
    finally:
        try:
            os.killpg(os.getpgid(p.pid), signal.SIGTERM)
            p.wait(timeout=5)
        except Exception:
            pass
        log.close()


if __name__ == "__main__":
    sys.exit(main())
