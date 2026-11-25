#!/usr/bin/env python3
"""Guard the one-canvas rule for player-facing UI.

The game draws 480x270 pixel-art rooms and a native 1920x1080 GUI. Text or a
control authored at room scale gets multiplied by four on screen, which is the
root cause of the huge-button / huge-label reports. This audit fails when that
class of code returns anywhere in the project, including screens nobody opened
during a screenshot pass.

Checks:
  * no text draw calls in any object's room Draw event (Draw_0);
  * no legacy 480-space UI helpers at all;
  * raw text drawing only inside the two native text primitives;
  * room-scale coordinates only in the explicit room/input files;
  * only the two documented player fonts are created;
  * control heights are scale tokens, never bare numbers.

Run it alone, or let tools/cafe_test.py run it before booting the game:

    python3 tools/ui_layout_audit.py
    python3 tools/ui_layout_audit.py --self-test
"""
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "Clicky"

# Generated CLI caches contain their own GML templates; they are not the game.
SKIP_PARTS = {".gmcache", "__pycache__", ".git"}

# Drawing text in a room event is always a bug. This is the exact regression
# that made floaters, tutorial pills and room labels enormous.
TEXT_CALLS = (
    "draw_text(",
    "draw_text_transformed(",
    "draw_text_ext(",
    "draw_text_colour(",
    "ui_text(",
    "dui_text(",
    "dui_vtext(",
)

# The only two places allowed to call the engine's text functions: the cafe
# dui_text primitive and the Hollow's dui_vtext primitive.
RAW_TEXT_PRIMITIVES = {
    "scripts/scr_ui/scr_ui.gml",
    "scripts/scr_veil_ui/scr_veil_ui.gml",
}

# Story cards are the one place where a single sentence can outgrow a narrow
# column. Every line must go through story_text_fit/story_text_wrap (or
# story_button for a control label); a raw primitive here is the regression
# that shipped the clipped "THE LAST BEAT KEPT IT FOR GOOD." footer.
STORY_DRAW = {
    "objects/obj_cat_arc/Draw_64.gml",
    "objects/obj_venue_arc/Draw_64.gml",
}

# 480-space UI helpers are gone. A call or a definition means a surface is
# about to be drawn through the room camera again. The lookbehind keeps
# dui_text/dui_nine from looking like the old ui_* family.
LEGACY_UI_RE = re.compile(
    r"(?<![A-Za-z0-9_])(ui_nine|ui_text|ui_button|ui_pill|ui_pill_w|ui_hover|ui_clicked)\s*\(")
LEGACY_DEF_RE = re.compile(
    r"function\s+(ui_nine|ui_text|ui_button|ui_pill|ui_pill_w|ui_hover|ui_clicked)\s*\(")

# UI_LEGACY_S is only a coordinate conversion for things that genuinely live
# in the room (cat, sparkles, pantry, floating numbers). It is never a layout
# unit for a control.
ROOM_COORD_FILES = {
    "scripts/scr_init/scr_init.gml",
    "scripts/scr_ui/scr_ui.gml",
    "scripts/scr_veil_test/scr_veil_test.gml",
    "objects/obj_cat_big/Step_0.gml",
    "objects/obj_sparkle/Step_0.gml",
    "objects/obj_veil_door/Step_0.gml",
    "objects/obj_floater/Draw_64.gml",
}

# The one intentional composition: the Hollow room is a 4x backdrop painted
# before the native shell. It must restore identity before any native plate.
BACKDROP_DRAW64 = "objects/obj_veil/Draw_64.gml"

# Control primitives whose fourth argument is the height. A bare number there
# is how a 52px or 72px button is born; the runtime audit catches a token that
# resolves to an off-table value, and this catches the literal before it runs.
CONTROL_CALLS = ("dui_button", "dui_pill", "dui_vbutton", "dui_vpill")


def rel(path: Path) -> str:
    return path.relative_to(PROJECT).as_posix()


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def source_files():
    for path in sorted(PROJECT.rglob("*.gml")):
        if any(part in SKIP_PARTS for part in path.parts):
            continue
        yield path


def matches(text: str, pattern: str):
    rx = re.compile(re.escape(pattern))
    for i, line in enumerate(text.splitlines(), 1):
        if rx.search(line):
            yield i, line.strip()


def legacy_hits(text: str):
    for i, line in enumerate(text.splitlines(), 1):
        m = LEGACY_UI_RE.search(line)
        if m:
            yield i, m.group(1), line.strip()


def split_args(text: str, start: int):
    """Return the top-level arguments of a call whose '(' is just before start."""
    depth = 1
    args = []
    cur = []
    i = start
    in_str = False
    while i < len(text) and depth > 0:
        ch = text[i]
        if ch == '"':
            in_str = not in_str
        if not in_str:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    args.append("".join(cur).strip())
                    break
            elif ch == "," and depth == 1:
                args.append("".join(cur).strip())
                cur = []
                i += 1
                continue
        cur.append(ch)
        i += 1
    return args


def literal_control_heights(text: str):
    """Yield (line, call, height) for a control sized with a bare number."""
    for call in CONTROL_CALLS:
        needle = call + "("
        at = text.find(needle)
        while at >= 0:
            args = split_args(text, at + len(needle))
            if len(args) > 3 and re.fullmatch(r"-?\d+(?:\.\d+)?", args[3]):
                yield text.count("\n", 0, at) + 1, call, args[3]
            at = text.find(needle, at + len(needle))


def check_sources() -> list[str]:
    failures = []

    if not PROJECT.is_dir():
        return [f"project directory missing: {PROJECT}"]

    for path in source_files():
        name = rel(path)
        text = read(path)

        # 1. Room Draw events may draw art, never text.
        if path.name == "Draw_0.gml":
            for line, needle, src in (
                (i, n, s) for n in TEXT_CALLS for i, s in matches(text, n)
            ):
                failures.append(f"{name}:{line}: text draw in room event ({needle}) -> {src}")

        # 2. The old 480-space UI helpers must not exist anywhere.
        for line, helper, src in legacy_hits(text):
            failures.append(f"{name}:{line}: legacy room-space UI call ({helper}) -> {src}")
        if LEGACY_DEF_RE.search(text):
            failures.append(f"{name}: legacy room-space UI helper definition")

        # 3. Raw engine text is owned by the native primitives.
        if name not in RAW_TEXT_PRIMITIVES:
            for needle in ("draw_text(", "draw_text_transformed(",
                           "draw_text_ext(", "draw_text_colour("):
                for line, src in matches(text, needle):
                    failures.append(f"{name}:{line}: raw text outside native primitive -> {src}")

        # 4. Room coordinate conversion is not a layout system.
        if "UI_LEGACY_S" in text and name not in ROOM_COORD_FILES:
            for line, src in matches(text, "UI_LEGACY_S"):
                failures.append(f"{name}:{line}: room-scale coordinate outside room/input file -> {src}")

        # 5. Native Draw events must not inherit the 4x room matrix, except the
        #    one documented backdrop, which resets before drawing UI.
        if path.name == "Draw_64.gml":
            if "ui_legacy_begin()" in text and name != BACKDROP_DRAW64:
                failures.append(f"{name}: 4x room matrix in a native Draw GUI event")
            if name == BACKDROP_DRAW64 and "ui_canvas_reset()" not in text:
                failures.append(f"{name}: room backdrop does not restore the native matrix")

        # 6. Step events are input/update only, never drawing.
        if path.name.startswith("Step_") and "dui_text(" in text:
            failures.append(f"{name}: native text call in a Step event")

        # 7. No control may be sized with a bare number. This is what keeps a
        #    new screen from introducing the next 52px or 72px one-off.
        for line, call, h in literal_control_heights(text):
            failures.append(f"{name}:{line}: literal {h}px height in {call}()")

        # 8. The old 62px row token is gone; a surviving reference is a screen
        #    that will not compile, but name it here so the fix is obvious.
        if "UI_H_ROW_COMFY" in text:
            failures.append(f"{name}: retired UI_H_ROW_COMFY scale token")

        # 9. Story cards must fit or wrap each line to its own column. A raw
        #    dui_text/dui_button is exactly how the last overflow shipped.
        if name in STORY_DRAW:
            for needle in ("dui_text(", "dui_button("):
                for line, src in matches(text, needle):
                    failures.append(
                        f"{name}:{line}: story card bypasses fitted text helper -> {src}")
            if "story_text_fit(" not in text or "story_text_wrap(" not in text:
                failures.append(f"{name}: story card is not using fitted and wrapped text")

    # 9. One type scale: only the two documented pixel fonts may be created.
    init = PROJECT / "scripts/scr_init/scr_init.gml"
    if init.exists():
        if read(init).count("font_add_sprite_ext(") != 2:
            failures.append("scripts/scr_init/scr_init.gml: expected exactly two pixel fonts")
    for path in source_files():
        if path.resolve() == init.resolve():
            continue
        text = read(path)
        for line, src in matches(text, "font_add_sprite_ext("):
            failures.append(f"{rel(path)}:{line}: font created outside font_setup() -> {src}")

    return failures


def check_snippet(name: str, text: str) -> list[str]:
    """Small injectable version of the source checks, for --self-test."""
    out = []
    if name.endswith("Draw_0.gml"):
        for needle in TEXT_CALLS:
            for line, _src in matches(text, needle):
                out.append(f"{name}:{line}: text draw in room event ({needle})")
    for line, helper, _src in legacy_hits(text):
        out.append(f"{name}:{line}: legacy room-space UI call ({helper})")
    for line, call, h in literal_control_heights(text):
        out.append(f"{name}:{line}: literal {h}px height in {call}()")
    if name in STORY_DRAW:
        for needle in ("dui_text(", "dui_button("):
            for line, _src in matches(text, needle):
                out.append(f"{name}:{line}: story card bypasses fitted text helper")
        if "story_text_fit(" not in text or "story_text_wrap(" not in text:
            out.append(f"{name}: story card is not using fitted and wrapped text")
    return out


def self_test() -> int:
    bad = "draw_text(0, 0, 'HUGE');\n"
    good = "dui_text(0, 0, 'OK', global.fnt_small, P_INK, fa_left);\n"
    failures = []

    if not check_snippet("objects/obj_room/Draw_0.gml", bad):
        failures.append("self-test did not reject room-space text")
    if check_snippet("objects/obj_room/Draw_64.gml", good):
        failures.append("self-test rejected native text")
    if not check_snippet("scripts/bad/scr_bad.gml", "ui_text(1, 2, 'x');\n"):
        failures.append("self-test did not reject a legacy UI helper")
    if not check_snippet("objects/obj_room/Draw_64.gml",
                        'dui_button(0, 0, 100, 72, "BIG", false, false);\n'):
        failures.append("self-test did not reject a literal control height")
    if check_snippet("objects/obj_room/Draw_64.gml",
                     'dui_button(0, 0, 100, UI_H_CTA, "OK", false, false);\n'):
        failures.append("self-test rejected a token control height")
    if not check_snippet("objects/obj_cat_arc/Draw_64.gml",
                         'dui_text(0, 0, "LONG", global.fnt_small, P_INK, fa_left);\n'):
        failures.append("self-test did not reject raw text in a story card")
    if check_snippet("objects/obj_cat_arc/Draw_64.gml",
                     'story_text_fit(0, 0, "OK", global.fnt_small, P_INK, fa_left, 100);\n'
                     'story_text_wrap(0, 0, "OK", global.fnt_small, P_INK, fa_left, 100, 2, 26);\n'):
        failures.append("self-test rejected fitted story text")

    if failures:
        for f in failures:
            print("SELF-TEST FAIL", f)
        return 1
    print("PASS ui.layout.self | audit rejects room text and accepts native text")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        return self_test()

    failures = check_sources()
    if failures:
        print("FAIL ui.layout | player-facing UI escaped the native GUI canvas")
        for f in failures[:40]:
            print("  !!", f)
        if len(failures) > 40:
            print(f"  ... {len(failures) - 40} more")
        return 1

    native = sorted(PROJECT.glob("objects/*/Draw_64.gml"))
    room = sorted(PROJECT.glob("objects/*/Draw_0.gml"))
    if not args.quiet:
        print(f"PASS ui.layout | {len(native)} native GUI surfaces, {len(room)} room-art surfaces")
        print("  - no text in Draw_0; no legacy ui_* helpers; no room-scale layout")
        print("  - raw text only in scr_ui/scr_veil_ui; one two-role type scale")
    return 0


if __name__ == "__main__":
    sys.exit(main())
