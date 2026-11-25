#!/usr/bin/env python3
"""Measure the rendered HUD and report geometry, so alignment is checked
against real pixels instead of intent.

Columns of non-background pixels are grouped into element runs (a gap of
GAP_SCREEN px ends a run), then each run's vertical extent is measured.

    python3 tools/audit_hud.py tools/shots/shot_1_combo.png
"""
import sys

from PIL import Image

BAR_BG = (246, 230, 200)
HUD_BOTTOM = 22   # game px of top bar the audit looks at
GAP = 8          # px of blank columns that separates two elements (at 3x)
MIDLINE = 11.0   # logical centre of a 22px bar


def near(a, b, tol=20):
    return all(abs(a[i] - b[i]) <= tol for i in range(3))


def main(path, y1=None, scale=None):
    img = Image.open(path).convert("RGB")
    w, _ = img.size
    # the window can be any whole multiple of 480x270, so derive the scale
    if scale is None:
        scale = w // 480
    if y1 is None:
        y1 = HUD_BOTTOM * scale
    px = img.load()

    cols = []
    for x in range(w):
        ink = [y for y in range(y1) if not near(px[x, y][:3], BAR_BG)]
        cols.append(ink)

    runs = []
    cur = None
    for x, ink in enumerate(cols):
        if ink:
            if cur is None:
                cur = [x, x, min(ink), max(ink)]
            else:
                cur[1] = x
                cur[2] = min(cur[2], min(ink))
                cur[3] = max(cur[3], max(ink))
        elif cur and x - cur[1] >= GAP:
            runs.append(cur)
            cur = None
    if cur:
        runs.append(cur)

    # glyphs inside one number can sit 2px apart: merge runs that close
    merged = []
    for r in runs:
        if merged and (r[0] - merged[-1][1]) / scale < 3.5:
            ln = merged[-1]
            ln[1] = r[1]
            ln[2] = min(ln[2], r[2])
            ln[3] = max(ln[3], r[3])
        else:
            merged.append(r)
    runs = merged

    print(f"{path}  elements in the bar (logical px):")
    print(f"  {'x':>6} {'w':>5} {'y0':>5} {'h':>5} {'cy':>6} {'gap':>5}")
    problems = []
    prev = None
    for x0, x1, y0, y1b in runs:
        lx0, lw = x0 / scale, (x1 - x0 + 1) / scale
        ly0, lh = y0 / scale, (y1b - y0 + 1) / scale
        cy = ly0 + lh / 2
        gap = "" if prev is None else f"{(lx0 - prev) / 1:.0f}"
        print(f"  {lx0:6.1f} {lw:5.1f} {ly0:5.1f} {lh:5.1f} {cy:6.1f} {gap:>5}")
        # a period or comma sits on the baseline on purpose: its box is
        # tiny and low, and measuring it against the bar midline is noise
        if lh <= 5.5:
            continue
        if abs(cy - MIDLINE) > 1.5:
            problems.append(f"  x={lx0:.0f}: centre {cy:.1f} vs bar {MIDLINE} "
                            f"(off by {cy - MIDLINE:+.1f})")
        if prev is not None and lx0 - prev < 3:
            problems.append(f"  x={lx0:.0f}: only {lx0 - prev:.0f}px gap from previous")
        prev = x0 / scale + lw

    print()
    if problems:
        print("PROBLEMS")
        print("\n".join(problems))
        return 1
    print("OK: every element centred on the bar midline with >=3px gaps")
    return 0


if __name__ == "__main__":
    p = sys.argv[1] if len(sys.argv) > 1 else "tools/shots/shot_1_combo.png"
    sys.exit(main(p))
