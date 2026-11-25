#!/usr/bin/env python3
"""Import generated PNGs from art/ into the GameMaker project.

Two passes, because the MCP server only writes frames reliably for sprites
that already exist on disk when the session starts:

  1. create any missing sprite resources (fresh session)
  2. add frames to every sprite that has none (fresh session, verified,
     one retry in another fresh session)

Run after tools/spritemaker.py.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gmmcp import Client

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "art")
SPRITES = os.path.join(ROOT, "Clicky", "sprites")

FOLDER = [
    ("spr_cat_", "Sprites/Cats"),
    ("spr_fx_", "Sprites/FX"),
    ("spr_ui_", "Sprites/UI"),
    ("spr_font", "Sprites/UI"),
]


def folder_for(name):
    for pre, f in FOLDER:
        if name.startswith(pre):
            return f
    return "Sprites"


def art_dirs():
    return sorted(
        d for d in os.listdir(ART)
        if d.startswith("spr_") and os.path.isdir(os.path.join(ART, d))
    )


def frames_of(name):
    return sorted(
        f for f in os.listdir(os.path.join(ART, name)) if f.endswith(".png")
    )


def frame_count(name):
    yy = os.path.join(SPRITES, name, name + ".yy")
    if not os.path.exists(yy):
        return -1
    s = open(yy).read()
    m = re.search(r'"frames":\[(.*?)\]', s, re.S)
    if not m:
        return 0
    return m.group(1).count("$GMSpriteFrame")


def create_missing():
    created = []
    c = Client()
    try:
        existing = c.call("resource_list", {"TYPE": "sprites"})
        for name in art_dirs():
            if name in existing:
                continue
            c.call("resource_create",
                   {"TYPE": "sprite", "NAME": name, "FOLDER": folder_for(name)})
            created.append(name)
    finally:
        c.close()
    return created


def add_frames(names):
    """One session for the whole batch; sprites already exist on disk."""
    done = []
    c = Client()
    try:
        for name in names:
            for i, f in enumerate(frames_of(name)):
                # never pass FRAME: it silently fails on a sprite with no frames
                c.call("sprite_addframe",
                       {"NAME": name, "PATH": os.path.join(ART, name, f)})
            done.append(name)
    finally:
        c.close()
    return done


def force_reimport(names):
    c = Client()
    try:
        for name in names:
            c.call("resource_delete", {"NAME": name, "TYPE": "sprite"})
    finally:
        c.close()
    c = Client()
    try:
        for name in names:
            c.call("resource_create",
                   {"TYPE": "sprite", "NAME": name, "FOLDER": folder_for(name)})
    finally:
        c.close()
    add_frames(names)


def stale(project_root):
    """Sprites whose PNG is newer than the imported .yy: art changed but the
    resource still holds the old frames. Deleting the folder by hand instead
    breaks the project, so this is the safe way to refresh a sprite."""
    out = []
    for name in art_dirs():
        yy = os.path.join(project_root, "Clicky", "sprites", name, name + ".yy")
        if not os.path.exists(yy):
            continue
        yy_t = os.path.getmtime(yy)
        pngs = [os.path.join(name, f) for f in os.listdir(os.path.join(ART, name))
                if f.endswith(".png")]
        if not pngs:
            continue
        if max(os.path.getmtime(os.path.join(ART, p)) for p in pngs) > yy_t:
            out.append(name)
    return out


def main():
    forced = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not forced:
        forced = stale(ROOT)
        if forced:
            print(f"refreshing {len(forced)} sprite(s) whose art changed")
                
    if forced:
        force_reimport(forced)
        for n in forced:
            print(f"  {n}: {frame_count(n)} frames")

    created = create_missing()
    print(f"created {len(created)} sprite resources")

    todo = [n for n in art_dirs() if frame_count(n) <= 0]
    if not todo:
        print("all sprites already have frames")
        return

    print(f"adding frames to {len(todo)} sprites")
    add_frames(todo)

    missing = [n for n in todo if frame_count(n) <= 0]
    if missing:
        print(f"retrying {len(missing)} in a fresh session")
        add_frames(missing)
        missing = [n for n in todo if frame_count(n) <= 0]

    total = sum(frame_count(n) for n in art_dirs())
    print(f"sprites ok: {len(art_dirs()) - len(missing)}/{len(art_dirs())}, "
          f"frames: {total}")
    for n in missing:
        print(f"  STILL EMPTY: {n}")


if __name__ == "__main__":
    main()
