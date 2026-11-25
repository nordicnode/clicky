#!/usr/bin/env python3
"""Baseline progression model without upgrades, crits, combos, or offline play.

Mirrors the base producer and reset formulas, including lifetime multipliers.
The bot taps constantly, buys by marginal payback, and resets as soon as it
can. This is a scenario, not a prediction of human playtime.

The post-MOON Cafe Eras are measured separately below. Their gates are actions
(resets, service, festival, Hollow), not fish, because after the first moon the
bot's measured rate is exponential (x30 about every ten minutes). The action
budget is explicit so a change to a round's length is a one-line change here.
"""
import math
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------- producers
TIERS = [
    ("BOX",        10,           0.5),
    ("BED",        130,          5),
    ("TOYS",       1_400,        45),
    ("POST",       12_000,       340),
    ("JARS",       95_000,       2_200),
    ("FOUNT",      800_000,      15_000),
    ("SUN",        6_500_000,    110_000),
    ("BALL",       55_000_000,   850_000),
    ("MUG",        450_000_000,  6_500_000),
    ("CAKE",       3_800_000_000, 50_000_000),
    ("TEAPOT",     30_000_000_000, 390_000_000),
    ("LANTERN",    240_000_000_000, 3_100_000_000),
    ("QUILT",      2_000_000_000_000, 24_000_000_000),
    ("AURORA",     16_000_000_000_000, 190_000_000_000),
]
COST_GROWTH = 1.16
UNLOCK_FRAC = 0.25
DOUBLES = ((120, 32), (80, 16), (40, 8), (20, 4), (10, 2))
TAPS_PER_SEC = 3.5
CLICK_FLAT = 1.0

# ---------------------------------------------------------------- layers
# Each layer: the currency it makes, the run total it needs first, how that
# total turns into currency, and what one unit of currency multiplies.
LAYERS = [
    # key,      unlock_on,       need,        divisor, exp, per_unit, first
    ("yarn",    None,              6e8,         2e7,    0.5, 0.10,   1),
    ("stars",   "yarn_earned",     14.0,        4.0,    0.5, 0.25,   1),
    ("beans",   "stars_earned",     4.0,        2.0,    0.5, 0.50,   1),
    ("aurora",  "beans_earned",     3.0,        2.0,    0.5, 1.00,   1),
    ("moon",    "aurora_earned",   25.0,        8.0,    0.5, 1.50,   1),
]


def tier_mult(owned):
    for n, m in DOUBLES:
        if owned >= n:
            return m
    return 1


def cost(i, owned, cheap=0.0):
    base = TIERS[i][1] * (1.0 - cheap) ** owned
    return math.ceil(base * COST_GROWTH ** owned)


def marginal(i, owned, cheap=0.0):
    r = TIERS[i][2]
    return r * ((owned + 1) * tier_mult(owned + 1) - owned * tier_mult(owned))


def rate(tiers):
    return sum(TIERS[i][2] * tiers[i] * tier_mult(tiers[i])
               for i in range(len(TIERS)))


def layer_gain(idx, since):
    """How much currency layer `idx` would pay right now.

    `since` holds the progress made at the layer below since that layer was
    last reset, so a reset is worth something again only after new progress.
    """
    key, _unlock, need, divisor, exp, _per, first = LAYERS[idx]
    src = since[idx]
    if src < need:
        return 0
    return max(first if idx == 0 else 1, math.floor((src / divisor) ** exp))


def multiplier(held):
    m = 1.0
    for (key, _u, _n, _d, _e, per_unit, _f) in LAYERS:
        m *= 1.0 + held.get(key, 0) * per_unit
    return m


def play(minutes=1200, verbose=False, stop_at_moon=True):
    t = 0.0
    dt = 1.0
    tiers = [0] * len(TIERS)
    run = 0.0
    lifetime = 0.0
    fish = 0.0
    held = {k: 0 for (k, *_rest) in LAYERS}
    earned = dict(held)
    # progress at each layer since that layer last paid out
    since = [0.0] * len(LAYERS)
    first = {}
    resets = []
    peak_rate = 0.0

    while t < minutes * 60:
        t += dt
        r = (rate(tiers) + CLICK_FLAT * TAPS_PER_SEC) * multiplier(earned)
        peak_rate = max(peak_rate, r)
        gain = r * dt
        fish += gain
        run += gain
        lifetime += gain
        since[0] = run

        bought = True
        while bought:
            bought = False
            best, best_pay = None, 1e30
            for i in range(len(TIERS)):
                if i > 0 and lifetime < TIERS[i][1] * UNLOCK_FRAC:
                    continue
                c = cost(i, tiers[i])
                if fish < c:
                    continue
                pay = c / max(1e-9, marginal(i, tiers[i]))
                if pay < best_pay:
                    best, best_pay = i, pay
            if best is not None:
                fish -= cost(best, tiers[best])
                tiers[best] += 1
                bought = True

        # a reset clears that layer and everything under it
        for idx in range(len(LAYERS) - 1, -1, -1):
            g = layer_gain(idx, since)
            if g <= 0:
                continue
            key = LAYERS[idx][0]
            held[key] += g
            earned[key] += g
            if key not in first:
                first[key] = t
            resets.append((t, key, g))
            for j in range(idx + 1):
                held[LAYERS[j][0]] = 0 if j < idx else held[key]
                since[j] = 0.0
            run = 0.0
            fish = 0.0
            tiers = [0] * len(TIERS)
            # the payout counts as progress for the layer above
            if idx + 1 < len(LAYERS):
                since[idx + 1] += g
            break
        if "moon" in first:
            if not stop_at_moon:
                # keep the same run going; print a checkpoint every 10 min
                if int(t) % 600 == 0:
                    print(f"  {t/60:6.1f}m rate={r:.3g}/s x{multiplier(earned):.2f} "
                          f"moon={earned['moon']} resets={len(resets)}")
            else:
                break

    if verbose:
        print(f"after {t / 60:.1f}m: rate={rate(tiers):.3g}/s x{multiplier(earned):.2f}"
              f" peak={peak_rate:.3g}/s held={held} earned={earned}")
        print(f"  {len(resets)} resets")
        for tt, key, g in resets[-10:]:
            print(f"    {tt / 60:6.1f}m  {key} +{g}")
    return {"first": first, "resets": resets, "held": held,
            "rate": rate(tiers), "peak_rate": peak_rate}


# ---------------------------------------------------------------- cafe eras
# Mirrors era_list() in Clicky/scripts/scr_layers/scr_layers.gml. Counts are
# the deeds the Era card asks for; kinds are the same singular verbs.
ERAS = [
    ("THE FIRST TABLE", 0, [("reset", 20), ("tap", 800), ("serve", 12)]),
    ("GARDEN PARTY",    1, [("reset", 25), ("tap", 1500), ("rank", 6)]),
    ("ROOFTOP HOUR",    2, [("reset", 25), ("found", 1), ("solves", 4)]),
    ("CLOUD SERVICE",   3, [("serve", 15), ("halls", 6), ("rank", 6)]),
    ("TEA CEREMONY",    4, [("solves", 6), ("halls", 6), ("reset", 30)]),
    ("STARRY NIGHT",    5, [("night", 6), ("rank", 8), ("reset", 40)]),
]

# A modeled interaction budget, not a playtest measurement. Each number is the
# wall-clock seconds one completed unit costs a deliberate player, including
# reading the card and clicking through it. Taps are the existing 3.5/s.
ERA_SECONDS = {
    "reset": 4.0,      # RESET card, confirm, spin, close
    "tap": 1.0 / TAPS_PER_SEC,
    "serve": 20.0,     # a few base/topping tries and the reward
    "rank": 45.0,      # pick three dishes, enter, read, claim
    "found": 60.0,     # discover the pantry and walk the Hollow's first room
    "solves": 150.0,   # one seance case, clues and seating
    "halls": 90.0,     # one Long Hall floor, peek and door
    "night": 240.0,    # a night run to the next deed
}

# The ladder thresholds live in the GML that actually runs. Read them here
# instead of keeping a second copy: a changed rung is immediately reflected in
# this model, and a moved function is a loud failure rather than silent drift.
ROOT = Path(__file__).resolve().parent.parent


def _macro(text, name):
    match = re.search(r"#macro\s+" + name + r"\s+(\d+)", text)
    if not match:
        raise RuntimeError(f"{name} not found in runtime GML")
    return int(match.group(1))


def _number_array_after(text, marker):
    """Return the integer array literal inside the function named by marker."""
    start = text.find(marker)
    if start < 0:
        raise RuntimeError(f"{marker} not found in runtime GML")
    open_at = text.find("[", start)
    close_at = text.find("];", open_at)
    if open_at < 0 or close_at < 0:
        raise RuntimeError(f"no array literal in {marker}")
    body = text[open_at + 1:close_at]
    # A comment inside the function is documentation, not a threshold.
    body = re.sub(r"/\*.*?\*/", "", body, flags=re.S)
    body = re.sub(r"//[^\n]*", "", body)
    return [int(value) for value in re.findall(r"\d+", body)]


_zones = (ROOT / "Clicky" / "scripts" / "scr_zones" / "scr_zones.gml").read_text(
    encoding="utf-8")
_album = (ROOT / "Clicky" / "scripts" / "scr_album" / "scr_album.gml").read_text(
    encoding="utf-8")
ROOM_STEPS = _number_array_after(_zones, "function room_mastery_steps()")
CAT_STEPS = _number_array_after(_album, "function cat_bond_steps()")
ROOM_MASTERY_MAX = _macro(_zones, "ROOM_MASTERY_MAX")
CAT_BOND_MAX = _macro(_album, "CAT_BOND_MAX")
ROOMS = _macro(_zones, "ZONE_COUNT")

_cat_block = re.search(r"function album_init\(\).*?global\.CAT\s*=\s*\[(.*?)\n\s*\];",
                       _album, re.S)
if not _cat_block:
    raise RuntimeError("album_init cat list not found in runtime GML")
CATS = len(re.findall(r"\{\s*n:", _cat_block.group(1)))

if len(ROOM_STEPS) != ROOM_MASTERY_MAX:
    raise RuntimeError(f"room ladder has {len(ROOM_STEPS)} rungs, expected {ROOM_MASTERY_MAX}")
if len(CAT_STEPS) != CAT_BOND_MAX:
    raise RuntimeError(f"cat ladder has {len(CAT_STEPS)} rungs, expected {CAT_BOND_MAX}")
if CATS <= 0:
    raise RuntimeError("no cats found in album_init")


def room_level(points):
    return sum(1 for step in ROOM_STEPS if points >= step)


def ladder_pacing():
    """Modeled hours of continuous tapping to finish both ladders.

    One manual tap advances the room the player is in and the active cat's
    bond at the same time, so these are not additive ladders. The conservative
    figure gives every cat its double home-room bond; the 321k home points fit
    inside the 1.96M taps the six rooms already require. The room stream is
    therefore the floor, and the Era's temporary featured-room double is not
    banked here.
    """
    room_taps = sum(ROOM_STEPS) * ROOMS
    cat_taps = sum(CAT_STEPS) * CATS
    cat_home_taps = cat_taps / 2
    rate_per_hour = TAPS_PER_SEC * 3600
    # A tap is counted once. Both ladders fill from that same stream.
    total_taps = max(room_taps, cat_home_taps)
    return {
        "room_taps": room_taps,
        "cat_taps": cat_taps,
        "cat_home_taps": cat_home_taps,
        "total_taps": int(total_taps),
        "hours": total_taps / rate_per_hour,
        "raw_taps": max(room_taps, cat_taps),
        "raw_hours": max(room_taps, cat_taps) / rate_per_hour,
    }


def era_seconds(deeds):
    """Time an era takes when taps fill the gaps between card actions.

    Taps run in parallel with waiting, but not with the counter/festival/Hollow
    cards, so the tap deed and the card deeds overlap rather than add.
    """
    tap_s = sum(n * ERA_SECONDS["tap"] for kind, n in deeds if kind == "tap")
    card_s = sum(n * ERA_SECONDS[kind] for kind, n in deeds if kind != "tap")
    return max(tap_s, card_s)


def era_pacing(moon_min):
    t = moon_min * 60.0
    mastery = [0] * 6
    rows = []
    for name, room, deeds in ERAS:
        sec = era_seconds(deeds)
        taps = sum(n for kind, n in deeds if kind == "tap")
        mastery[room] += taps * 2          # featured room counts double
        t += sec
        levels = sum(room_level(p) for p in mastery)
        rows.append((name, t / 60.0, sec / 60.0, levels))
    return rows


def main():
    after = "--after" in sys.argv
    r = play(verbose="--verbose" in sys.argv,
             minutes=300 if after else 1200, stop_at_moon=not after)
    print("Baseline bot: constant taps, no upgrades or offline earnings")
    missing = []
    last = 0
    for key, *_ in LAYERS:
        t = r["first"].get(key)
        print(f"first {key:7s}: {t / 60:.1f} min" if t is not None
              else f"first {key:7s}: not reached in 1200 min")
        if t is None or t < last:
            missing.append(key)
        if t is not None:
            last = t
    if missing:
        print("FAIL: layers not reached in order:", ", ".join(missing))
        return 1
    moon = r["first"].get("moon")
    if moon is None:
        print("FAIL: eras have no starting moon")
        return 1
    print("\nCafe Eras (modeled interaction budget, not a playtest):")
    print("  reset 4s, tap 1/3.5s, dish 20s, rank 45s,")
    print("  find 60s, seance 150s, hall 90s, night 240s")
    rows = era_pacing(moon / 60.0)
    for name, at, took, levels in rows:
        print(f"  {name:16s} sealed {at:6.1f}m  (+{took:5.1f}m)  room levels {levels}")
    first_era = rows[0][1]
    last_era = rows[-1][1]
    if not (first_era > moon / 60.0 and last_era > first_era):
        print("FAIL: era milestones are not in order after the first moon")
        return 1
    print(f"  all six sealed at {last_era:.1f}m "
          f"({last_era - moon / 60.0:.1f}m after the first moon)")

    lp = ladder_pacing()
    print("\nLong-tail ladders (modeled continuous tapping at 3.5/s):")
    print(f"  rooms: {lp['room_taps']:,} taps across {ROOMS} rooms")
    print(f"  cats:  {lp['cat_taps']:,} bond across {CATS} cats "
          f"({lp['cat_taps'] // 2:,} with every cat at home)")
    print(f"  total: one {lp['total_taps']:,}-tap stream = {lp['hours']:.1f}h "
          f"(cat home points alone: {int(lp['cat_home_taps']):,}; "
          f"room points: {lp['room_taps']:,})")
    print(f"  no-home-bond floor: {lp['raw_taps']:,} taps = {lp['raw_hours']:.1f}h")
    print("  a tap advances both ladders; the room stream dominates, not 1.96M + 321k")
    print("  this is a tap model, not a playtest; Hollow night replays are not counted")
    print("PASS: all layers reachable and all six eras measure beyond the first moon")
    return 0


if __name__ == "__main__":
    sys.exit(main())
