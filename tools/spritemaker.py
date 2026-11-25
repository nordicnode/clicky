#!/usr/bin/env python3
"""Pixel-exact sprite generator for Clicky's Cat Cafe.

Every sprite is authored on an exact native pixel grid using the fixed
palette below — no supersample blur, no colour-snap artifacts, and crisp
1px dark ink outlines.

    python3 tools/spritemaker.py            # build every asset
    python3 tools/spritemaker.py font cats  # build selected groups
"""
import json
import os
import sys

import math
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art")

# ---------------------------------------------------------------- palette
P = {
    "ink":      (43, 27, 46),
    "brown_d":  (90, 58, 46),
    "brown":    (140, 90, 60),
    "wood":     (201, 138, 91),
    "cream":    (246, 230, 200),
    "white":    (255, 253, 247),
    "peach":    (244, 162, 107),
    "coral":    (232, 106, 90),
    "pink":     (245, 168, 200),
    "pink_d":   (214, 128, 165),
    "mint":     (143, 214, 192),
    "sky":      (158, 211, 240),
    "gold":     (255, 201, 77),
    "gold_d":   (224, 158, 40),
    "shadow":   (70, 45, 60),
    "glass":    (190, 226, 240),
}

COATS = {
    "tabby":  dict(fur=P["peach"], shade=P["coral"],   belly=P["cream"], ear=P["pink"]),
    "calico": dict(fur=P["cream"], shade=P["peach"],   belly=P["white"], ear=P["pink"]),
    "tuxedo": dict(fur=P["shadow"], shade=P["ink"],    belly=P["white"], ear=P["pink"]),
    "ginger": dict(fur=P["gold"],  shade=P["peach"],   belly=P["cream"], ear=P["pink"]),
    "grey":   dict(fur=P["sky"],   shade=P["glass"],   belly=P["cream"], ear=P["pink"]),
    "snow":   dict(fur=P["white"], shade=P["glass"],   belly=P["cream"], ear=P["pink"]),
    "mint":   dict(fur=P["mint"],  shade=P["glass"],   belly=P["white"], ear=P["pink"]),
    "rose":   dict(fur=P["pink"],  shade=P["pink_d"],  belly=P["white"], ear=P["coral"]),
}


def grid_to_image(grid, cmap, outline_col=P["ink"]):
    """Convert a 2D char grid to an RGBA image, optionally adding a 1px outline."""
    h = len(grid)
    w = len(grid[0])
    out = [list(row) for row in grid]
    if outline_col is not None:
        for y in range(h):
            for x in range(w):
                if grid[y][x] != ".":
                    continue
                if any(
                    0 <= x + dx < w and 0 <= y + dy < h and grid[y + dy][x + dx] != "."
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                ):
                    out[y][x] = "#"

    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y in range(h):
        for x in range(w):
            ch = out[y][x]
            if ch == ".":
                continue
            if ch == "#" and "#" not in cmap:
                px[x, y] = outline_col + (255,)
            else:
                col = cmap[ch]
                px[x, y] = col + (255,) if len(col) == 3 else col
    return im


def save(im, name):
    d = os.path.join(OUT, name)
    os.makedirs(d, exist_ok=True)
    p = os.path.join(d, f"{name}.png")
    im.save(p)
    return p


def frame_set(name, frames):
    d = os.path.join(OUT, name)
    os.makedirs(d, exist_ok=True)
    for f in os.listdir(d):
        if f.endswith(".png"):
            os.remove(os.path.join(d, f))
    paths = []
    for i, im in enumerate(frames):
        p = os.path.join(d, f"frame{i}.png")
        im.save(p)
        paths.append(p)
    return paths


# ---------------------------------------------------------------- font
F = {
    " ": "00000|00000|00000|00000|00000|00000|00000",
    "!": "00100|00100|00100|00100|00100|00000|00100",
    "?": "01110|10001|00001|00010|00100|00000|00100",
    ".": "00000|00000|00000|00000|00000|01100|01100",
    ",": "00000|00000|00000|00000|00110|00100|01000",
    ":": "00000|01100|01100|00000|01100|01100|00000",
    "'": "00100|00100|01000|00000|00000|00000|00000",
    "-": "00000|00000|00000|11111|00000|00000|00000",
    "+": "00000|00100|00100|11111|00100|00100|00000",
    "/": "00001|00010|00010|00100|01000|01000|10000",
    "%": "11001|11010|00010|00100|01000|01011|10011",
    "(": "00010|00100|01000|01000|01000|00100|00010",
    ")": "01000|00100|00010|00010|00010|00100|01000",
    "*": "00000|10101|01110|11111|01110|10101|00000",
    "=": "00000|00000|11111|00000|11111|00000|00000",
    "0": "01110|10001|10001|10001|10001|10001|01110",
    "1": "00100|01100|00100|00100|00100|00100|01110",
    "2": "01110|10001|00001|00010|00100|01000|11111",
    "3": "11111|00010|00100|00010|00001|10001|01110",
    "4": "00010|00110|01010|10010|11111|00010|00010",
    "5": "11111|10000|11110|00001|00001|10001|01110",
    "6": "00110|01000|10000|11110|10001|10001|01110",
    "7": "11111|00001|00010|00100|01000|01000|01000",
    "8": "01110|10001|10001|01110|10001|10001|01110",
    "9": "01110|10001|10001|01111|00001|00010|01100",
}
for _ch, _rows in [
    ("A", "01110|10001|10001|11111|10001|10001|10001"),
    ("B", "11110|10001|10001|11110|10001|10001|11110"),
    ("C", "01110|10001|10000|10000|10000|10001|01110"),
    ("D", "11110|10001|10001|10001|10001|10001|11110"),
    ("E", "11111|10000|10000|11110|10000|10000|11111"),
    ("F", "11111|10000|10000|11110|10000|10000|10000"),
    ("G", "01110|10001|10000|10111|10001|10001|01110"),
    ("H", "10001|10001|10001|11111|10001|10001|10001"),
    ("I", "11111|00100|00100|00100|00100|00100|11111"),
    ("J", "00111|00010|00010|00010|00010|10010|01100"),
    ("K", "10001|10010|10100|11000|10100|10010|10001"),
    ("L", "10000|10000|10000|10000|10000|10000|11111"),
    ("M", "10001|11011|10101|10101|10001|10001|10001"),
    ("N", "10001|11001|10101|10011|10001|10001|10001"),
    ("O", "01110|10001|10001|10001|10001|10001|01110"),
    ("P", "11110|10001|10001|11110|10000|10000|10000"),
    ("Q", "01110|10001|10001|10001|10101|10010|01101"),
    ("R", "11110|10001|10001|11110|10100|10010|10001"),
    ("S", "01111|10000|10000|01110|00001|00001|11110"),
    ("T", "11111|00100|00100|00100|00100|00100|00100"),
    ("U", "10001|10001|10001|10001|10001|10001|01110"),
    ("V", "10001|10001|10001|10001|10001|01010|00100"),
    ("W", "10001|10001|10001|10101|10101|10101|01010"),
    ("X", "10001|10001|01010|00100|01010|10001|10001"),
    ("Y", "10001|10001|01010|00100|00100|00100|00100"),
    ("Z", "11111|00001|00010|00100|01000|10000|11111"),
]:
    F[_ch] = _rows
for _ch, _rows in [
    ("a", "00000|00000|01110|00001|01111|10001|01111"),
    ("b", "10000|10000|11110|10001|10001|10001|11110"),
    ("c", "00000|00000|01110|10000|10000|10001|01110"),
    ("d", "00001|00001|01111|10001|10001|10001|01111"),
    ("e", "00000|00000|01110|10001|11111|10000|01110"),
    ("f", "00110|01001|01000|11100|01000|01000|01000"),
    ("g", "00000|01111|10001|10001|01111|00001|01110"),
    ("h", "10000|10000|11110|10001|10001|10001|10001"),
    ("i", "00100|00000|01100|00100|00100|00100|01110"),
    ("j", "00010|00000|00110|00010|00010|10010|01100"),
    ("k", "10000|10000|10010|10100|11000|10100|10010"),
    ("l", "01100|00100|00100|00100|00100|00100|01110"),
    ("m", "00000|00000|11010|10101|10101|10001|10001"),
    ("n", "00000|00000|11110|10001|10001|10001|10001"),
    ("o", "00000|00000|01110|10001|10001|10001|01110"),
    ("p", "00000|11110|10001|10001|11110|10000|10000"),
    ("q", "00000|01111|10001|10001|01111|00001|00001"),
    ("r", "00000|00000|10110|11001|10000|10000|10000"),
    ("s", "00000|00000|01111|10000|01110|00001|11110"),
    ("t", "01000|01000|11100|01000|01000|01001|00110"),
    ("u", "00000|00000|10001|10001|10001|10011|01101"),
    ("v", "00000|00000|10001|10001|10001|01010|00100"),
    ("w", "00000|00000|10001|10001|10101|10101|01010"),
    ("x", "00000|00000|10001|01010|00100|01010|10001"),
    ("y", "00000|10001|10001|10001|01111|00001|01110"),
    ("z", "00000|00000|11111|00010|00100|01000|11111"),
]:
    F[_ch] = _rows

GLYPH_ORDER = [chr(c) for c in range(32, 127)]


def glyph_rows(ch):
    return F.get(ch, F["?"]).split("|")


def build_font(colour=(255, 253, 247), scale=2, name="spr_font"):
    """One PNG per glyph: font_add_sprite_ext maps frames, not an atlas."""
    d = os.path.join(OUT, name)
    os.makedirs(d, exist_ok=True)
    for f in os.listdir(d):
        if f.endswith(".png"):
            os.remove(os.path.join(d, f))

    cw = 5 * scale + (2 if scale > 1 else 1)
    ch = 7 * scale + (2 if scale > 1 else 2)

    for i, g in enumerate(GLYPH_ORDER):
        im = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        dr = ImageDraw.Draw(im)
        for y, row in enumerate(glyph_rows(g)):
            for x, bit in enumerate(row):
                if bit == "1":
                    dr.rectangle([x * scale, y * scale,
                                  x * scale + scale - 1, y * scale + scale - 1],
                                 fill=colour)
        im.save(os.path.join(d, f"frame{i:03d}.png"))
    return cw, ch


# ---------------------------------------------------------------- big cat (39x35)
def big_cat(coat="tabby", pose="idle", frame=0, outline=True):
    """Cute chibi sitting cat on an exact 39x35 pixel grid."""
    W, H = 39, 35
    c = COATS[coat]
    cmap = {
        "o": c["fur"],
        "O": c["shade"],
        "c": c["belly"],
        "p": c["ear"],
        "w": P["white"],
        "#": P["ink"],
    }
    g = [["." for _ in range(W)] for _ in range(H)]

    def put(x, y, ch):
        if 0 <= x < W and 0 <= y < H:
            g[y][x] = ch

    def ell(cx, cy, rx, ry, ch):
        for y in range(H):
            for x in range(W):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    g[y][x] = ch

    def rect(x0, y0, x1, y1, ch):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                put(x, y, ch)

    cx = 20  # center x; tail occupies left x=3..12
    hy = 0
    if pose == "idle":
        hy = [0, 0, 1, 1, 0, 0][frame % 6]
    elif pose == "pet":
        hy = [1, 2, 1, 0][frame % 4]

    # 1. Fluffy curled tail (kept left of cheek so it never fuses with the head)
    tdy = [0, -1, -2, -1, 0, 1][frame % 6] if pose == "idle" else [-1, -2, -1, 0][frame % 4]
    tail_pts = [
        (13, 29, 1.8), (10, 29, 1.8), (8, 28, 1.8),
        (6, 26 + tdy // 2, 1.8), (5, 23 + tdy, 1.8), (6, 20 + tdy, 1.7),
    ]
    for px, py, r in tail_pts:
        ell(px, py, r, r, "o")
    ell(6, 20 + tdy, 1.3, 1.1, "O")
    ell(5, 24 + tdy // 2, 1.2, 0.9, "O")

    # 2. Plump sitting body + soft neck (no pinch)
    ell(cx, 25, 7.6, 5.8, "o")
    rect(cx - 5, 18, cx + 5, 22, "o")
    for sy in (24, 27):
        put(cx - 6, sy, "O"); put(cx - 5, sy, "O")
        put(cx + 5, sy, "O"); put(cx + 6, sy, "O")
    ell(cx, 26, 3.8, 4.0, "c")

    # 3. Bottom haunches & tucked front paws
    ell(cx - 5, 30, 2.4, 1.6, "o")
    ell(cx + 5, 30, 2.4, 1.6, "o")
    ell(cx - 2.5, 30.5, 2.0, 1.5, "c")
    ell(cx + 2.5, 30.5, 2.0, 1.5, "c")
    put(cx - 3, 31, "w"); put(cx - 2, 31, "w")
    put(cx + 2, 31, "w"); put(cx + 3, 31, "w")

    # 4. Big round head
    ell(cx, 13.5 + hy, 9.0, 6.6, "o")

    # 5. Pointed ears tucked cleanly onto the head dome (no overhang notch)
    ear_drop = 1 if pose == "pet" else 0
    ear_spans = [1, 2, 3, 4, 4, 4]
    for i, sp in enumerate(ear_spans):
        y = 2 + i + hy + ear_drop
        for dx in range(sp):
            put(13 + dx, y, "o")
            put(27 - dx, y, "o")
    # Smooth temple join between ear base and cheek
    rect(13, 8 + hy + ear_drop, 16, 10 + hy, "o")
    rect(24, 8 + hy + ear_drop, 27, 10 + hy, "o")
    for i, sp in [(2, 1), (3, 2), (4, 2), (5, 2)]:
        y = 2 + i + hy + ear_drop
        for dx in range(sp):
            put(14 + dx, y, "p")
            put(26 - dx, y, "p")

    # 6. Forehead tabby 'M' & cheek stripes
    for ys in (8 + hy, 9 + hy, 10 + hy):
        put(cx, ys, "O")
    for sx in (cx - 2, cx + 2):
        put(sx, 8 + hy, "O"); put(sx, 9 + hy, "O")
    put(cx - 8, 13 + hy, "O"); put(cx - 7, 13 + hy, "O")
    put(cx + 7, 13 + hy, "O"); put(cx + 8, 13 + hy, "O")

    # 7. Cream muzzle
    ell(cx, 15.5 + hy, 3.6, 2.2, "c")

    # 8. Eyes
    blink = (pose == "blink" and frame == 1) or (pose == "idle" and frame == 5)
    if pose == "pet":
        for ex in (cx - 5, cx + 5):
            put(ex - 1, 13 + hy, "#")
            put(ex,     12 + hy, "#")
            put(ex + 1, 13 + hy, "#")
    elif blink:
        for ex in (cx - 5, cx + 5):
            put(ex - 1, 13 + hy, "#")
            put(ex,     13 + hy, "#")
            put(ex + 1, 13 + hy, "#")
    else:
        for ex in (cx - 5, cx + 5):
            rect(ex - 1, 11 + hy, ex + 1, 13 + hy, "#")
            put(ex - 1, 11 + hy, "w")  # sparkle

    # 9. Rosy blush cheeks
    bw = 3 if pose == "pet" else 2
    for dx in range(bw):
        put(cx - 7 + dx, 15 + hy, "p")
        put(cx + 7 - dx, 15 + hy, "p")

    # 10. Pink nose + :3 smile
    put(cx, 14 + hy, "p")
    put(cx - 2, 15 + hy, "#"); put(cx, 15 + hy, "#"); put(cx + 2, 15 + hy, "#")
    put(cx - 1, 16 + hy, "#"); put(cx + 1, 16 + hy, "#")

    im = grid_to_image(g, cmap, P["ink"] if outline else None)
    # crisp paw-divider pixel between the two front paws
    im.putpixel((cx, 31), P["ink"] + (255,))
    im.putpixel((cx, 32), P["ink"] + (255,))
    return im


# ---------------------------------------------------------------- mini cat (22x20)
def outline_image(im, col=None):
    """Add a 1px ink outline around a sprite's silhouette.

    Downscaling a big cat by half keeps the fur but eats the 1px outline, and
    an unoutlined kitty on a busy wallpaper disappears. So the outline is put
    back on the pixels that ended up on the edge.
    """
    col = col or (P["ink"] + (255,))
    w, h = im.size
    src = im.copy().load()
    out = im.copy()
    px = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] != 0:
                    px[x, y] = col
                    break
    return out


def soften_rim(im, rim_col=None):
    """Replace dark rim pixels that touch empty space with a neighbour colour.

    The big cat's art carries ink along its silhouette. Half size, that ink
    becomes the whole outline of the kitten, which is exactly the heavy black
    frame we do not want. So any dark pixel on the outer edge takes the colour
    of a neighbouring fur pixel instead.
    """
    w, h = im.size
    src = im.copy().load()
    out = im.copy()
    px = out.load()

    def dark(c):
        return c[3] > 0 and c[0] < 110 and c[1] < 90 and c[2] < 100

    def empty(x, y):
        return not (0 <= x < w and 0 <= y < h) or src[x, y][3] == 0

    for y in range(h):
        for x in range(w):
            c = src[x, y]
            if not dark(c):
                continue
            touches_edge = any(empty(x + dx, y + dy)
                               for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if not touches_edge:
                continue
            if rim_col is not None:
                # a soft rim in the coat's own shade: the shape stays readable
                # and the tail stays attached, with no black line anywhere
                px[x, y] = rim_col
                continue
            # otherwise borrow the colour of a solid neighbour
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    n = src[nx, ny]
                    if n[3] > 0 and not dark(n):
                        px[x, y] = n
                        break
    return out


def mini_from_big(coat, pose, frame):
    """A kitten that is literally the cafe cat, half size, in another pelt.

    Keeping one source drawing is what stops the small cats drifting off-model,
    which is exactly what happened when they were drawn by hand.
    """
    big_pose = "pet" if pose == "happy" else "idle"
    # No outline on the kittens at all. A 1px ring around a 20px cat reads as
    # a heavy black frame next to the big cat's own outline, so the small cats
    # are grounded with a soft shadow under them instead (see obj_cat_mini).
    # downscale the outlined drawing (so the silhouette is solid at half size),
    # then strip the ink off its rim: no black frame on the kittens
    src = big_cat(coat, big_pose, frame, True)
    small = soften_rim(src.resize((20, 18), Image.NEAREST),
                       COATS[coat]["shade"] + (255,))

    # a hop or a walk bob, always a whole pixel so the art stays crisp
    dy = 0
    if pose == "walk":
        dy = [0, -1, 0, 1][frame % 4]
    elif pose == "happy":
        dy = [0, -1, -2][frame % 3]
    elif pose == "idle":
        dy = [0, 0, 1, 0][frame % 4]

    out = Image.new("RGBA", (22, 20), (0, 0, 0, 0))
    out.paste(small, (1, 2 + dy), small)
    return out

def mini_cat(coat="tabby", pose="idle", frame=0):
    """Cute 22x20 pixel kitty for the cafe floor (idle / walk / happy)."""
    W, H = 22, 20
    c = COATS[coat]
    cmap = {
        "o": c["fur"],
        "O": c["shade"],
        "c": c["belly"],
        "p": c["ear"],
        "w": P["white"],
        "#": P["ink"],
    }
    g = [["." for _ in range(W)] for _ in range(H)]

    def put(x, y, ch):
        if 0 <= x < W and 0 <= y < H:
            g[y][x] = ch

    def ell(cx, cy, rx, ry, ch):
        for y in range(H):
            for x in range(W):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    g[y][x] = ch

    bob = 0
    tdy = 0
    if pose == "walk":
        bob = [0, -1, 0, 1][frame % 4]
        tdy = [-1, 0, 1, 0][frame % 4]
    elif pose == "happy":
        bob = [0, -1, -2][frame % 3]
        tdy = -1
    elif pose == "idle":
        bob = [0, 0, 1, 0][frame % 4]
        tdy = [0, -1, 0, 1][frame % 4]

    cx = 12
    hy = max(-1, min(1, bob))

    # tail (kept clear of head outline)
    for px, py in [(7, 15), (4, 15), (2, 13 + tdy), (3, 11 + tdy)]:
        ell(px, py, 1.0, 1.0, "o")
    put(3, 11 + tdy, "O")

    # body
    ell(cx, 14, 4.4, 3.4, "o")
    ell(cx, 15, 2.2, 2.2, "c")
    # paws
    l_off = [-1, 0, 1, 0][frame % 4] if pose == "walk" else 0
    r_off = -l_off
    ell(cx - 2 + l_off * 0.5, 17, 1.3, 1.0, "c")
    ell(cx + 2 + r_off * 0.5, 17, 1.3, 1.0, "c")

    # head
    ell(cx, 8 + hy, 5.2, 3.8, "o")
    # ears
    for dy, sp in [(0, 1), (1, 2), (2, 3)]:
        for dx in range(sp):
            put(8 + dx, 2 + dy + hy, "o")
            put(16 - dx, 2 + dy + hy, "o")
    put(9, 4 + hy, "p"); put(15, 4 + hy, "p")

    # stripes
    put(cx, 5 + hy, "O")
    put(cx - 4, 13, "O"); put(cx + 4, 13, "O")

    # muzzle + eyes
    ell(cx, 9.5 + hy, 2.2, 1.3, "c")
    if pose == "happy":
        for ex in (cx - 3, cx + 3):
            put(ex - 1, 8 + hy, "#"); put(ex, 7 + hy, "#"); put(ex + 1, 8 + hy, "#")
    else:
        for ex in (cx - 3, cx + 3):
            put(ex, 7 + hy, "#"); put(ex, 8 + hy, "#")
            put(ex, 7 + hy, "w") if False else None
    put(cx, 9 + hy, "p")
    put(cx - 1, 10 + hy, "#"); put(cx + 1, 10 + hy, "#")

    return grid_to_image(g, cmap)


def build_cats():
    made = []
    made.append(("spr_cat_big_idle",  [big_cat("tabby", "idle", i)  for i in range(6)]))
    made.append(("spr_cat_big_pet",   [big_cat("tabby", "pet", i)   for i in range(4)]))
    made.append(("spr_cat_big_blink", [big_cat("tabby", "blink", i) for i in range(2)]))
    # the kittens are the big cat, half size, in eight pelts
    for coat in ("tabby", "calico", "tuxedo", "ginger", "grey", "snow", "mint", "rose"):
        made.append((f"spr_cat_{coat}_idle",  [mini_from_big(coat, "idle", i) for i in range(4)]))
        made.append((f"spr_cat_{coat}_walk",  [mini_from_big(coat, "walk", i) for i in range(4)]))
        made.append((f"spr_cat_{coat}_happy", [mini_from_big(coat, "happy", i) for i in range(3)]))
    for name, frames in made:
        frame_set(name, frames)
    return [m[0] for m in made]


# ---------------------------------------------------------------- fx (16x16 pixel-exact)
def build_fx():
    out = []
    cmap = {
        "s": P["sky"], "l": P["glass"], "w": P["white"],
        "r": P["coral"], "p": P["pink"],
        "g": P["gold"], "G": P["gold_d"],
        "c": P["cream"], "#": P["ink"],
    }

    # fish (4 gentle spin frames)
    fish_wide = [
        "................",
        "......gg........",
        "....ss##ss......",
        "...sllsssss...s.",
        "..slw#ssssss.ss.",
        "..ss##sssssssss.",
        "..sssssssssssss.",
        "...sspssssss.ss.",
        "....sssssss...s.",
        "......ssss......",
        "................",
    ]
    fish_mid = [
        "................",
        ".......g........",
        ".....ssss.......",
        "....sllsss...s..",
        "...slw#ssss.ss..",
        "...ss##sssssss..",
        "...sssssssssss..",
        "....sspssss.ss..",
        ".....sssss...s..",
        "......sss.......",
        "................",
    ]
    fish_narrow = [
        "................",
        "................",
        "......sss.......",
        ".....sllss..s...",
        "....slw#sssss...",
        "....sssssssss...",
        ".....sspsssss...",
        "......ssss..s...",
        ".......ss.......",
        "................",
        "................",
    ]
    def pad16(rows):
        top = (16 - len(rows)) // 2
        bot = 16 - len(rows) - top
        return ["." * 16] * top + rows + ["." * 16] * bot

    fish_frames = [grid_to_image(pad16(g), cmap) for g in (fish_wide, fish_mid, fish_narrow, fish_mid)]
    out.append(("spr_fx_fish", fish_frames))

    # true heart with crisp top notch (3 pulse sizes)
    heart_s = [
        "................",
        "................",
        "....rrr..rrr....",
        "...rwwrrrrrrr...",
        "...rwrrrrrrrr...",
        "...rrrrrrrrrr...",
        "....rrrrrrrr....",
        ".....rrrrrr.....",
        "......rrrr......",
        ".......rr.......",
        "................",
    ]
    heart_m = [
        "................",
        "...rrrr..rrrr...",
        "..rwwrrrrrrrrr..",
        "..rwrrrrrrrrrr..",
        "..rrrrrrrrrrrr..",
        "...rrrrrrrrrr...",
        "....rrrrrrrr....",
        ".....rrrrrr.....",
        "......rrrr......",
        ".......rr.......",
        "................",
    ]
    heart_l = [
        "..rrrr....rrrr..",
        ".rwwrrrrrrrrrrr.",
        ".rwrrrrrrrrrrrr.",
        ".rrrrrrrrrrrrrr.",
        "..rrrrrrrrrrrr..",
        "...rrrrrrrrrr...",
        "....rrrrrrrr....",
        ".....rrrrrr.....",
        "......rrrr......",
        ".......rr.......",
        "................",
    ]
    out.append(("spr_fx_heart", [grid_to_image(pad16(g), cmap) for g in (heart_s, heart_m, heart_l)]))

    # puff / dust (4 clean pixel circles, no outline)
    puff_frames = []
    for r in (2, 3, 4, 4):
        g = [["." for _ in range(16)] for _ in range(16)]
        for y in range(16):
            for x in range(16):
                if (x - 8) ** 2 + (y - 8) ** 2 <= r * r:
                    g[y][x] = "c"
        puff_frames.append(grid_to_image(g, cmap, outline_col=None))
    out.append(("spr_fx_puff", puff_frames))

    # crisp 4-point star sparkle
    sp_l = [
        ".......g........",
        ".......g........",
        "......gwg.......",
        ".....gwwwg......",
        "..gggwwwwwggg...",
        "ggggwwwwwwwgggg.",
        "..gggwwwwwggg...",
        ".....gwwwg......",
        "......gwg.......",
        ".......g........",
        ".......g........",
    ]
    sp_m = [
        "................",
        ".......g........",
        "......gwg.......",
        ".....gwwwg......",
        "...ggwwwwwgg....",
        ".....gwwwg......",
        "......gwg.......",
        ".......g........",
        "................",
    ]
    sp_s = [
        "................",
        "................",
        ".......g........",
        "......gwg.......",
        ".....gwwwg......",
        "......gwg.......",
        ".......g........",
        "................",
    ]
    out.append(("spr_fx_sparkle", [
        grid_to_image(pad16(g), cmap, outline_col=None)
        for g in (sp_l, sp_m, sp_s, sp_m)
    ]))

    for name, frames in out:
        frame_set(name, frames)
    return [o[0] for o in out]


# ---------------------------------------------------------------- ui (pixel-exact)
def make_panel_9slice(fill, border_outer, border_inner, top_hi=None, bottom_lip=None):
    """24x24 pixel-exact 9-slice panel with unbroken 2px rounded corners."""
    im = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    px = im.load()
    for y in range(24):
        for x in range(24):
            # 2px chamfered rounded corners: skip (0,0),(1,0),(0,1) and symmetric
            dx = min(x, 23 - x)
            dy = min(y, 23 - y)
            if dx + dy < 2:
                continue
            if dx == 0 or dy == 0 or (dx == 1 and dy == 1):
                px[x, y] = border_outer + (255,)
            elif bottom_lip is not None and y >= 21:
                px[x, y] = bottom_lip + (255,)
            elif dx == 1 or dy == 1 or (dx == 2 and dy == 2):
                px[x, y] = border_inner + (255,)
            else:
                px[x, y] = fill + (255,)
    if top_hi is not None:
        for x in range(4, 20):
            px[x, 2] = top_hi + (255,)
    return im


def build_ui():
    out = []

    save(make_panel_9slice(P["cream"], P["brown_d"], P["wood"], top_hi=P["white"]),
         "spr_ui_panel")
    out.append("spr_ui_panel")

    states = {
        "idle":  (P["peach"], P["brown_d"], P["coral"],  P["white"], P["brown_d"]),
        "hover": (P["gold"],  P["brown_d"], P["gold_d"], P["white"], P["brown_d"]),
        "press": (P["coral"], P["ink"],     P["brown_d"], None,      P["ink"]),
    }
    for name, args in states.items():
        save(make_panel_9slice(*args), f"spr_ui_btn_{name}")
        out.append(f"spr_ui_btn_{name}")

    save(make_panel_9slice(P["cream"], P["wood"], P["white"]), "spr_ui_row")
    out.append("spr_ui_row")

    # Crisp 16x16 fish icon (sky fish with eye, tail, fin, shine)
    fish_icon_grid = [
        "................",
        "................",
        "................",
        "......sss.......",
        "....ssllsss...s.",
        "...slw#sssss.ss.",
        "..slss#ssssssss.",
        "..sssssssssssss.",
        "..sspsssssss.ss.",
        "...sssssssss..s.",
        "....sssssss.....",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]
    cmap_ui = {
        "s": P["sky"], "l": P["glass"], "w": P["white"],
        "p": P["pink"], "P": P["pink_d"], "#": P["ink"],
        "c": P["coral"],
    }
    save(grid_to_image(fish_icon_grid, cmap_ui), "spr_ui_fish_icon")
    out.append("spr_ui_fish_icon")

    # Crisp 16x16 ball of yarn icon (crossed yarn wraps + dangling thread)
    yarn_icon_grid = [
        "................",
        "................",
        ".....pppppp.....",
        "...ppwppppPpp...",
        "..ppwPpppPpppP..",
        "..pPPpppPpppPp..",
        ".ppppppPpppPppp.",
        ".pppPPppppPpppp.",
        ".ppPppPPPppPppp.",
        "..pPppppPPPppp..",
        "..pppppppppppp..",
        "...pppppppppp...",
        ".....pppppp..p..",
        "............ppp.",
        ".............p..",
        "................",
    ]
    save(grid_to_image(yarn_icon_grid, cmap_ui), "spr_ui_yarn_icon")
    out.append("spr_ui_yarn_icon")

    return out


# ---------------------------------------------------------------- shop props (16x16)
def teapot_grid():
    g = [list("." * 16) for _ in range(11)]

    def put(x, y, ch):
        if 0 <= x < 16 and 0 <= y < len(g):
            g[y][x] = ch

    # body: a fat rounded pot, x 4..12
    for y in range(4, 10):
        for x in range(4, 13):
            put(x, y, "w")
    for x in range(5, 12):
        put(x, 3, "w")
    for x in range(6, 11):
        put(x, 2, "w")
    # lid
    for x in range(6, 11):
        put(x, 2, "g")
    for x in range(5, 12):
        put(x, 3, "g")
    put(8, 1, "g")
    # spout, out to the left
    for i, y in enumerate((6, 7, 8)):
        for x in range(0 + i, 4):
            put(x, y, "w")
    # handle: a separate block on the right, one empty column away from the
    # body so the outline pass draws the gap and the handle reads as a loop
    for y in range(4, 9):
        put(14, y, "w")
        put(15, y, "w")
    put(15, 4, "w")
    return ["".join(r) for r in g]


PROP_GRIDS = {
    # cardboard box, open flaps
    "spr_prop_box": [
        "................",
        "................",
        "..ww......ww....",
        ".wwww....wwww...",
        "..wwww..wwww....",
        "...WwwwwwwW.....",
        "...WwwwwwwW.....",
        "...WwccccwW.....",
        "...WwccccwW.....",
        "...WwccccwW.....",
        "...WwwwwwwW.....",
        "....DDDDDD......",
        "................",
    ],
    # round cat bed
    "spr_prop_bed": [
        "................",
        "................",
        "....RRRRRRRR....",
        "..RRccccccccRR..",
        ".RcccwwwwwwcccR.",
        ".RccwwwwwwwwccR.",
        ".RcccwwwwwwcccR.",
        "..RRccccccccRR..",
        "...RRRRRRRRRR...",
        "....DDDDDDDD....",
        "................",
    ],
    # toy basket with a ball
    "spr_prop_toys": [
        "................",
        "........gg......",
        ".......gGGg.....",
        "........gg......",
        "..W.........W...",
        "..WWWWWWWWWWW...",
        "..WcccccccccW...",
        "..WcpcccccccW...",
        "..WcppcccccpW...",
        "...WccccccccW...",
        "....WWWWWWWW....",
        "................",
    ],
    # scratching post
    "spr_prop_post": [
        "................",
        "..cccccc........",
        "..cWWWWc........",
        "..ccWWcc........",
        "...ccWWcc.......",
        "...ccWWcc.......",
        "...ccWWcc.......",
        "...ccWWcc.......",
        "...ccWWcc.......",
        "..WWWWWWWW......",
        "..WwwwwwwW......",
        "..WWWWWWWW......",
        "................",
    ],
    # treat jar
    "spr_prop_jars": [
        "................",
        "....DDDDDD......",
        "...DwwwwwwD.....",
        "....DDDDDD......",
        "...WccccccW.....",
        "...WcgccccW.....",
        "...WcggcccW.....",
        "...WcgccccW.....",
        "...WccccccW.....",
        "...WccccccW.....",
        "....WWWWWW......",
        "................",
    ],
    # water fountain
    "spr_prop_fount": [
        "................",
        "......ss........",
        ".....slls.......",
        "......ss........",
        "....DDDDDD......",
        "...DssssssD.....",
        "..DDDDDDDDDD....",
        "..DssssssssD....",
        "..DssssssssD....",
        "..DDDDDDDDDD....",
        "................",
    ],
    # warm sunbeam
    "spr_prop_sunbeam": [
        "................",
        "..g...gg...g....",
        "...g.gggg.g.....",
        "....gggggg......",
        "..gggwwwwggg....",
        "..gwwwwwwwwg....",
        "..gggwwwwggg....",
        "....gggggg......",
        "...g.gggg.g.....",
        "..g...gg...g....",
        "................",
    ],
    # yarn pit
    "spr_prop_yarnpit": [
        "................",
        "..pppp..pppp....",
        ".ppPPpppppPPpp..",
        ".pPpppppPppppPp.",
        ".pppPPpppppPPpp.",
        "..pppppppppppp..",
        "..PPPPPPPPPPPP..",
        "...pppppppppp...",
        "................",
    ],
    # mug of tea
    "spr_prop_mug": [
        "................",
        "................",
        "....######......",
        "...#wwwwww#.....",
        "...#wwccww#..##.",
        "...#wwwwww#..#g#",
        "...#wwwwww#..#g#",
        "...#wwwwww#..##.",
        "...#wwwwww#.....",
        "....######......",
        "................",
    ],
    # cupcake
    "spr_prop_cake": [
        "................",
        "......cc........",
        ".....cWWc.......",
        "....cWccWcc.....",
        "...cWWccccWc....",
        "...cWccccccW....",
        "....######......",
        "....#RRRR#......",
        "....#RPPR#......",
        "....#RRRR#......",
        "....######......",
        "................",
    ],
    # teapot: built from shapes, because a spout and a handle are loops and
    # a hand-typed grid of loops always ends up lopsided
    "spr_prop_teapot": teapot_grid(),
    # lantern: cap, ring, and vertical ribs so it is not a blob
    "spr_prop_lantern": [
        "................",
        ".......#........",
        "......###.......",
        ".....#####......",
        "....#ggggg#.....",
        "...#gGcGcGg#....",
        "...#gGcGcGg#....",
        "...#gGcGcGg#....",
        "....#ggggg#.....",
        ".....#####......",
        ".......#........",
    ],
    # patchwork quilt
    "spr_prop_quilt": [
        "................",
        "..##pPpPpP##....",
        "..#pPpPpPp#.....",
        "..#PpPpPpP#.....",
        "..#pPpPpPp#.....",
        "..#PpPpPpP#.....",
        "..#pPpPpPp#.....",
        "..##pPpPpP##....",
        "................",
    ],
    # aurora gem: wide table, bright crown, point at the bottom
    "spr_prop_aurora": [
        "................",
        "......####......",
        ".....#llll#.....",
        "....#lggggl#....",
        "....#gGgGGg#....",
        ".....#gGGg#.....",
        "......#GG#......",
        ".......##.......",
        "................",
    ],
    # padlock for locked rows
    "spr_ui_lock": [
        "................",
        ".....####.......",
        "....#....#......",
        "....#....#......",
        "...##....##.....",
        "..#WWWWWWWW#....",
        "..#WWwwwwWW#....",
        "..#WWw##wWW#....",
        "..#WWw##wWW#....",
        "..#WWwwwwWW#....",
        "..#WWWWWWWW#....",
        "...########.....",
        "................",
    ],
}


class Prop:
    """A 16x16 canvas with just enough drawing words to describe an object.

    Every shop icon is built from these, so each one is a deliberate shape
    (a bowl, a handle, a flame) instead of a scatter of pixels, and the ink
    outline is added once at the end by grid_to_image(). Sixteen is the size
    the shop row is built around: a 20px icon in a 25px row swamped the label.
    """

    def __init__(self, w=16, h=16):
        self.w, self.h = w, h
        self.g = [["." for _ in range(w)] for _ in range(h)]

    def px(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.px(x, y, c)

    def frame(self, x0, y0, x1, y1, c):
        self.rect(x0, y0, x1, y0, c)
        self.rect(x0, y1, x1, y1, c)
        self.rect(x0, y0, x0, y1, c)
        self.rect(x1, y0, x1, y1, c)

    def oval(self, cx, cy, rx, ry, c):
        for y in range(self.h):
            for x in range(self.w):
                if ((x - cx) / max(0.001, rx)) ** 2 + ((y - cy) / max(0.001, ry)) ** 2 <= 1.0:
                    self.px(x, y, c)

    def ring(self, cx, cy, rx, ry, thick, c):
        for y in range(self.h):
            for x in range(self.w):
                d = ((x - cx) / max(0.001, rx)) ** 2 + ((y - cy) / max(0.001, ry)) ** 2
                inner = ((x - cx) / max(0.001, rx - thick)) ** 2 + \
                        ((y - cy) / max(0.001, ry - thick)) ** 2
                if d <= 1.0 and inner > 1.0:
                    self.px(x, y, c)

    def poly(self, pts, c):
        for y in range(self.h):
            for x in range(self.w):
                inside = False
                n = len(pts)
                for i in range(n):
                    x0, y0 = pts[i]
                    x1, y1 = pts[(i + 1) % n]
                    if (y0 > y) != (y1 > y):
                        xt = x0 + (y - y0) * (x1 - x0) / (y1 - y0)
                        if x < xt:
                            inside = not inside
                if inside:
                    self.px(x, y, c)

    def line(self, x0, y0, x1, y1, c, thick=1):
        steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(steps + 1):
            t = i / steps
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            for dy in range(thick):
                for dx in range(thick):
                    self.px(x + dx, y + dy, c)

    def rows(self):
        return ["".join(r) for r in self.g]


PROP_COLS = {
    "w": P["cream"], "W": P["wood"], "c": P["coral"], "R": P["pink_d"],
    "D": P["brown_d"], "g": P["gold"], "G": P["gold_d"], "s": P["sky"],
    "l": P["glass"], "p": P["pink"], "m": P["mint"], "k": P["brown"],
    "i": P["ink"], "y": (206, 168, 96), "t": (206, 120, 84),
    "T": (162, 88, 62), "v": (126, 96, 196),
}


def prop_box():
    p = Prop()
    # an open box with the flaps out and tape down the middle
    p.rect(4, 7, 11, 14, "W")                 # body
    p.rect(4, 7, 11, 8, "y")                  # lit front edge
    p.poly([(4, 7), (1, 4), (6, 6)], "y")     # left flap
    p.poly([(11, 7), (14, 4), (9, 6)], "y")   # right flap
    p.rect(6, 6, 9, 7, "D")                   # what is inside
    p.rect(7, 7, 8, 14, "w")                  # tape
    return p


def prop_bed():
    p = Prop()
    # a pet bed: oval rim, a square cushion inside, a pillow at one end
    p.oval(8, 10, 7, 4, "R")
    p.oval(8, 10, 6, 3, "p")
    p.rect(3, 8, 12, 12, "w")                 # cushion
    p.oval(5, 9, 1, 1, "p")                   # pillow
    p.rect(3, 13, 12, 14, "R")                # rim in front
    return p


def prop_toys():
    p = Prop()
    # a ball of yarn and a toy mouse
    p.oval(4, 11, 3, 3, "p")
    p.line(2, 9, 6, 13, "R")
    p.line(2, 13, 6, 9, "R")
    p.oval(10, 12, 3, 2, "W")                 # mouse body
    p.px(9, 10, "W")                          # ears
    p.px(12, 10, "W")
    p.px(8, 11, "i")                          # eye
    p.line(13, 12, 15, 10, "R")               # tail
    return p


def prop_post():
    p = Prop()
    # a scratching post: base, rope pole, a pom-pom on a string
    p.oval(7, 14, 5, 1, "W")
    p.rect(5, 4, 8, 13, "w")
    for y in range(5, 13, 2):
        p.rect(5, y, 8, y, "y")               # rope wraps
    p.line(9, 5, 11, 6, "D")                  # string
    p.oval(12, 7, 1, 1, "p")                  # pom-pom
    return p


def prop_jars():
    p = Prop()
    # two treat jars with lids
    for (x0, y0) in ((1, 5), (9, 7)):
        p.rect(x0, y0 + 2, x0 + 5, 14, "l")
        p.rect(x0, y0 + 2, x0 + 5, y0 + 3, "w")
        p.rect(x0, y0, x0 + 5, y0 + 1, "g")   # lid
        p.oval(x0 + 2, 12, 1, 1, "y")         # treats
    return p


def prop_fount():
    p = Prop()
    # a water bowl with drops falling into it; at 16px one shape beats a
    # tiered fountain, which reads as a trophy
    p.oval(8, 11, 6, 4, "w")
    p.rect(3, 9, 12, 9, "w")                  # its rim
    p.oval(8, 11, 4, 2, "s")                  # water
    p.px(8, 2, "s")                           # a falling drop
    p.px(8, 3, "s")
    p.px(5, 5, "s")
    p.px(11, 4, "s")
    return p


def prop_sun():
    p = Prop()
    # a sun with real rays
    for a in range(0, 360, 45):
        rad = math.radians(a)
        p.line(8 + math.cos(rad) * 4.5, 8 + math.sin(rad) * 4.5,
               8 + math.cos(rad) * 7.5, 8 + math.sin(rad) * 7.5, "g")
    p.oval(8, 8, 3.5, 3.5, "g")
    p.oval(7, 7, 1, 1, "w")
    return p


def prop_ball():
    p = Prop()
    # a ball of yarn with a loose end curling away
    p.oval(7, 9, 5, 5, "p")
    p.line(3, 6, 11, 12, "R")
    p.line(3, 12, 11, 6, "R")
    p.line(7, 4, 7, 14, "R")
    p.line(12, 11, 14, 14, "R")
    p.px(14, 13, "R")
    return p


def prop_mug():
    p = Prop()
    # a mug with a fish on it and a handle that joins the body
    p.rect(3, 6, 9, 13, "w")
    p.rect(3, 6, 9, 7, "c")                   # the rim
    p.ring(11, 10, 3, 3, 1.5, "w")            # handle
    p.rect(11, 9, 11, 11, ".")                # the hole through it
    p.px(5, 10, "s")                          # a little fish print
    p.px(6, 9, "s")
    p.px(6, 11, "s")
    return p


def prop_cake():
    p = Prop()
    # a cupcake: paper case, frosting, cherry
    p.poly([(3, 9), (12, 9), (10, 15), (5, 15)], "p")
    for x in range(5, 11, 2):
        p.line(x, 9, x - 1, 15, "R")
    p.oval(8, 7, 4.5, 3, "c")                 # frosting
    p.oval(6, 6, 1, 1, "w")                   # highlight
    p.oval(8, 3, 1, 1, "R")                   # cherry
    return p


def prop_teapot():
    p = Prop()
    # a teapot: round body, lid knob, a straight spout up and to the left,
    # and a D-shaped handle on the right. Both appendages are two pixels
    # thick so the ink outline cannot swallow them at this size.
    p.oval(7, 10, 4.5, 4, "w")               # body
    p.oval(7, 7, 3, 1.5, "g")                # lid
    p.px(7, 4, "g")                          # knob
    p.px(7, 5, "g")
    p.line(5, 8, 1, 5, "w", 2)               # spout
    p.rect(11, 6, 14, 12, "w")                # handle: a solid D
    p.rect(12, 8, 13, 10, ".")                # with a hole through it
    return p


def prop_lantern():
    p = Prop()
    # a paper lantern: cap, ring, ribbed body, tassel
    p.px(7, 1, "i")                           # hanging ring
    p.rect(6, 2, 9, 2, "g")                   # cap
    p.oval(8, 8, 4.5, 4.5, "c")
    for x in range(5, 11, 2):
        p.line(x, 4, x, 12, "y")              # ribs
    p.rect(7, 13, 8, 14, "G")                 # tassel
    return p


def prop_quilt():
    p = Prop()
    # a folded quilt: a patchwork grid with stitching, and a turned corner
    cols = ["p", "w", "R", "m"]
    p.rect(2, 4, 13, 13, "p")
    for row in range(3):
        for col in range(3):
            x0 = 2 + col * 4
            y0 = 4 + row * 4
            p.rect(x0, y0, x0 + 3, y0 + 3, cols[(row * 3 + col) % 4])
    for x in range(2, 15, 4):
        p.rect(x, 4, x, 13, "i")              # stitching
    for y in range(4, 14, 4):
        p.rect(2, y, 13, y, "i")
    p.poly([(13, 13), (13, 10), (10, 13)], "w")   # the folded-back corner
    return p


def prop_aurora():
    p = Prop()
    # northern lights: a ribbon of colour with stars behind it
    for x in range(1, 15):
        y = 8 + round(2 * math.sin(x / 2.6))
        p.px(x, y, "m")
        p.px(x, y + 1, "m")
        p.px(x, y - 1, "s")
    for (sx, sy) in ((3, 2), (9, 2), (13, 3), (5, 13), (11, 13)):
        p.px(sx, sy, "w")
    return p


PROP_FACTORY = {
    "spr_prop_box": prop_box,
    "spr_prop_bed": prop_bed,
    "spr_prop_toys": prop_toys,
    "spr_prop_post": prop_post,
    "spr_prop_jars": prop_jars,
    "spr_prop_fount": prop_fount,
    "spr_prop_sunbeam": prop_sun,
    "spr_prop_yarnpit": prop_ball,
    "spr_prop_mug": prop_mug,
    "spr_prop_cake": prop_cake,
    "spr_prop_teapot": prop_teapot,
    "spr_prop_lantern": prop_lantern,
    "spr_prop_quilt": prop_quilt,
    "spr_prop_aurora": prop_aurora,
}


def build_props():
    """Every shop icon, drawn from shapes at 20x20 and outlined once."""
    made = []
    for name, fn in PROP_FACTORY.items():
        g = fn().rows()
        save(grid_to_image(g, PROP_COLS, P["ink"]), name)
        made.append(name)
    return made


# ---------------------------------------------------------------- room plant
def build_room_plant():
    """A potted plant for the Cozy Corner: a real pot, a stem, and leaves with
    points on them. Drawn as a sprite rather than primitives, because triangles
    and circles laid out by hand read as exactly that and nothing else."""
    W, H = 26, 42
    g = [["." for _ in range(W)] for _ in range(H)]

    def put(x, y, ch):
        if 0 <= x < W and 0 <= y < H:
            g[y][x] = ch

    def ell(cx, cy, rx, ry, ch):
        for y in range(H):
            for x in range(W):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    g[y][x] = ch

    def tri(p0, p1, p2, ch):
        (x0, y0), (x1, y1), (x2, y2) = p0, p1, p2
        for y in range(H):
            for x in range(W):
                d = ((y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2))
                if d == 0:
                    continue
                a = ((y1 - y2) * (x - x2) + (x2 - x1) * (y - y2)) / d
                b = ((y2 - y0) * (x - x2) + (x0 - x2) * (y - y2)) / d
                c = 1 - a - b
                if a >= 0 and b >= 0 and c >= 0:
                    g[y][x] = ch

    # stem, up the middle of the pot
    for y in range(18, 34):
        put(12, y, "b")
        put(13, y, "b")
    # a second, shorter stem leaning right
    for i, y in enumerate(range(24, 32)):
        put(15 + (i // 2), y, "b")

    def leaf(cx, cy, rx, ry, tip, vein_col):
        """One leaf: a body, a pointed tip pulled out of it, and a vein."""
        ell(cx, cy, rx, ry, "G")
        ell(cx - 1, cy - 1, rx - 1, ry - 1, "g")
        tri(tip, (cx - rx // 2, cy - ry // 2), (cx + rx // 2, cy - ry // 2), "g")
        # vein from the stem side out towards the tip
        for i in range(max(2, rx)):
            put(cx + (tip[0] - cx) * i // max(1, rx),
                cy + (tip[1] - cy) * i // max(1, rx), vein_col)

    # five leaves, tips pointing outwards, so it reads as a plant and not a bush
    leaf(12, 11, 6, 4, (12, 1), "l")     # top
    leaf(6, 19, 4, 3, (1, 15), "g")      # upper left
    leaf(19, 16, 4, 3, (25, 12), "g")    # upper right
    leaf(9, 25, 3, 2, (4, 27), "g")      # lower left
    leaf(17, 24, 3, 2, (23, 25), "g")    # lower right
    ell(10, 9, 3, 2, "l")

    # pot: rim, then a tapering body
    for x in range(5, 21):
        put(x, 32, "T")
        put(x, 33, "t")
        put(x, 34, "T")
    for y in range(35, 42):
        inset = (y - 35) // 2
        for x in range(7 + inset, 19 - inset):
            put(x, y, "t")
        put(7 + inset, y, "T")
        put(18 - inset, y, "T")
    # soil
    for x in range(6, 20):
        put(x, 32, "S")

    cmap = {
        "g": (110, 186, 96), "G": (78, 146, 74), "l": (163, 224, 138),
        "b": (110, 74, 52), "t": (206, 120, 84), "T": (162, 88, 62),
        "S": (92, 62, 52), "#": P["ink"],
    }
    save(grid_to_image(g, cmap, P["ink"]), "spr_room_plant")
    return ["spr_room_plant"]


# ---------------------------------------------------------------- hats
HAT_CMAP = {
    "p": P["pink"], "P": P["pink_d"], "w": P["cream"], "W": P["white"],
    "g": P["gold"], "G": P["gold_d"], "c": P["coral"],
    "v": (126, 96, 196), "V": (92, 66, 156),
}

HAT_GRIDS = {
    "spr_hat_beanie": [
        "........pppp........",
        ".......pPPppp.......",
        "......pPpppppP......",
        ".....pPpppppppP.....",
        "....pPpppppppppP....",
        "...wwwwwwwwwwwwww...",
        "...wwwwwwwwwwwwww...",
        "....wwwwwwwwwwww....",
    ],
    "spr_hat_crown": [
        "..g....g....g....g",
        "..gg..ggg..ggg..gg",
        "..gggggggggggggggg",
        "..gGcgGgGcgGgGcgGg",
        "..GGGGGGGGGGGGGGGG",
        "..GGGGGGGGGGGGGGGG",
    ],
    "spr_hat_wizard": [
        "..........g.........",
        ".........ggg........",
        ".........gvg........",
        "........gvVvg.......",
        "........gvVvg.......",
        ".......gvVgVvg......",
        ".......gvVvVvg......",
        "......gvVvVvVvg.....",
        "......gvVvVvVvg.....",
        ".....gvVvVgvVvg.....",
        ".....gvVvVvVvVvg....",
        "....gvVvVvVvVvVvg...",
        "....gvVvVvVvVvVvg...",
        "...ggggggggggggggg..",
        "...GGGGGGGGGGGGGGG..",
    ],
}


# the crown sits on ginger fur, so its gold is deepened to stay readable
CROWN_CMAP = dict(HAT_CMAP, g=(206, 142, 26), G=(158, 100, 14), c=(226, 74, 66))


def build_hats():
    made = []
    for name, rows in HAT_GRIDS.items():
        w = max(len(r) for r in rows)
        g = [list(r.ljust(w, ".")) for r in rows]
        cmap = CROWN_CMAP if name == "spr_hat_crown" else HAT_CMAP
        save(grid_to_image(g, cmap), name)
        made.append(name)
    return made


# ---------------------------------------------------------------- main
def main(sel):
    groups = {
        "font": lambda: (build_font(),
                         build_font(scale=1, name="spr_font_small"),
                         ["spr_font", "spr_font_small"])[2],
        "cats": build_cats,
        "plant": build_room_plant,
        "fx": build_fx,
        "ui": build_ui,
        "props": build_props,
        "hats": build_hats,
    }
    made = []
    for k, fn in groups.items():
        if sel and k not in sel:
            continue
        made += fn()
    print(json.dumps({"made": made, "out": OUT}, indent=1))


if __name__ == "__main__":
    main(set(sys.argv[1:]))
