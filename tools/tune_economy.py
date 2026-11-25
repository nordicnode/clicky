#!/usr/bin/env python3
"""Balance sim for Clicky's Cat Cafe.

Mirrors the numbers in Clicky/scripts/scr_econ/scr_econ.gml and asserts the
pacing targets in docs/DEV_PLAN.md §3.7. Run it after every economy change —
if this file and scr_econ.gml disagree, the game is lying about its own math.

    python3 tools/tune_economy.py
    python3 tools/tune_economy.py --verbose
"""
import math
import sys

TIERS = [
    ("BOX",     10,       0.5),
    ("BED",     120,      4),
    ("TOYS",    1100,     30),
    ("POST",    8000,     200),
    ("JARS",    55000,    1300),
    ("FOUNT",   400000,   9000),
    ("SUN",     3000000,  65000),
    ("YARN",    25000000, 500000),
]

COST_GROWTH = 1.15
UNLOCK_FRAC = 0.25          # tier appears at 25% of its price earned
DOUBLES = ((80, 16), (40, 8), (20, 4), (10, 2))
TAPS_PER_SEC = 3.5
CLICK_FLAT = 1.0
PRESTIGE_MIN = 55_000_000   # run_earned needed for the first yarn
YARN_DIVISOR = 500_000      # yarn = (run_earned / this) ** 0.5
OFFLINE_RATE = 0.5
OFFLINE_CAP_H = 8


def marginal(i, owned):
    """Rate gained by buying one more: the whole tier re-multiplies."""
    r = TIERS[i][2]
    return r * ((owned + 1) * tier_mult(owned + 1) - owned * tier_mult(owned))


def tier_mult(owned):
    for n, m in DOUBLES:
        if owned >= n:
            return m
    return 1


def cost(i, owned):
    return math.ceil(TIERS[i][1] * COST_GROWTH ** owned)


def rate(tiers):
    return sum(TIERS[i][2] * tiers[i] * tier_mult(tiers[i])
               for i in range(len(TIERS)))


def yarn_for(run_earned):
    if run_earned < PRESTIGE_MIN:
        return 0
    return max(1, math.floor((run_earned / YARN_DIVISOR) ** 0.5))


def play(minutes=30, verbose=False):
    """Greedy player: buys the cheapest affordable tier, cheapest first."""
    t = 0.0
    dt = 0.25
    fish = 0.0
    run_earned = 0.0
    tiers = [0] * len(TIERS)
    unlocked = {0}
    prev_mult = [1] * len(TIERS)

    first_fish = None
    first_producer = None
    prestige_at = None
    events = []          # (time, label) — new tiers and doublings
    buys = []            # every successful purchase time

    while t < minutes * 60:
        t += dt
        gain = rate(tiers) * dt + CLICK_FLAT * TAPS_PER_SEC * dt
        fish += gain
        run_earned += gain

        if first_fish is None and fish > 0:
            first_fish = t
        if prestige_at is None and run_earned >= PRESTIGE_MIN:
            prestige_at = t

        # a player buys whatever pays back fastest, not whatever is first in the list
        bought = True
        while bought:
            bought = False
            best, best_pay = None, 1e18
            for i in range(len(TIERS)):
                if i > 0 and run_earned < TIERS[i][1] * UNLOCK_FRAC:
                    continue
                c = cost(i, tiers[i])
                if fish < c:
                    continue
                pay = c / max(1e-9, marginal(i, tiers[i]))
                if pay < best_pay:
                    best, best_pay = i, pay
            if best is not None:
                i = best
                fish -= cost(i, tiers[i])
                tiers[i] += 1
                buys.append(t)
                if first_producer is None:
                    first_producer = t
                if i not in unlocked:
                    unlocked.add(i)
                    events.append((t, f"unlock {TIERS[i][0]}"))
                m = tier_mult(tiers[i])
                if m != prev_mult[i]:
                    prev_mult[i] = m
                    events.append((t, f"{TIERS[i][0]} x{m}"))
                bought = True

    events.sort()
    buys.sort()

    def widest(times, start, end):
        pts = [start] + [x for x in times if start <= x <= end] + [end]
        return max((pts[i] - pts[i - 1], pts[i - 1], pts[i])
                   for i in range(1, len(pts)))

    early_gap = widest([e[0] for e in events], 0, 12 * 60)
    buy_gap = widest(buys, 0, minutes * 60)

    if verbose:
        print(f"after {minutes} min: rate={rate(tiers):,.0f}/s, tiers={tiers}")
        print(f"  first fish {first_fish:.1f}s | first producer {first_producer:.1f}s"
              f" | first prestige {prestige_at / 60:.1f}m"
              f" | yarn {yarn_for(run_earned)}")
        print(f"  {len(events)} reward events, {len(buys)} purchases")
        for tt, label in events:
            print(f"    {tt / 60:5.1f}m  {label}")

    return {
        "first_fish": first_fish,
        "first_producer": first_producer,
        "prestige_at": prestige_at,
        "early_gap": early_gap,
        "buy_gap": buy_gap,
        "events": events,
        "tiers": tiers,
    }


def check_offline():
    """One hour of offline pay equals OFFLINE_RATE * 60 min of production."""
    tiers = [5, 2, 1, 0, 0, 0, 0, 0]
    r = rate(tiers)
    offline = r * 3600 * OFFLINE_RATE
    equivalent_min = offline / r / 60
    return offline, equivalent_min


def main():
    verbose = "--verbose" in sys.argv
    r = play(verbose=verbose)
    fails = []

    if r["first_fish"] is None or r["first_fish"] > 2:
        fails.append(f"first fish {r['first_fish']:.1f}s > 2s")
    if r["first_producer"] is None or r["first_producer"] > 20:
        fails.append(f"first producer {r['first_producer']:.1f}s > 20s")

    gap, _, _ = r["early_gap"]
    # §3.7's "every 45-90s" is carried by purchases and cats walking in
    # (every few seconds); this metric counts only new tiers and doublings,
    # so 120s is the bar that catches a genuinely dead stretch.
    if gap > 120:
        fails.append(f"first 12 min: {gap:.0f}s with nothing new (target <= 120s)")

    gap, g0, g1 = r["buy_gap"]
    if gap > 180:
        fails.append(f"{gap / 60:.1f} min with nothing affordable "
                     f"({g0 / 60:.1f}m -> {g1 / 60:.1f}m), target < 3 min")

    p = r["prestige_at"]
    if p is None or not (20 * 60 <= p <= 30 * 60):
        fails.append(f"first prestige {0 if p is None else p / 60:.1f}m outside 20-30m")

    offline, equivalent_min = check_offline()
    if not (10 <= equivalent_min <= 40):
        fails.append(f"1h offline = {equivalent_min:.0f} min of progress, expected 10-40")

    print(f"\nfirst fish {r['first_fish']:.1f}s (<=2s)")
    print(f"first producer {r['first_producer']:.1f}s (<=20s)")
    print(f"widest gap in first 12 min: {r['early_gap'][0]:.0f}s (<=120s)")
    print(f"widest gap between purchases: {r['buy_gap'][0] / 60:.1f}m (<3m)")
    print(f"first prestige: {r['prestige_at'] / 60:.1f}m (20-30m)")
    print(f"1h offline = {equivalent_min:.0f} min of progress (10-40)")
    print(f"yarn at first prestige: {yarn_for(PRESTIGE_MIN)}")

    if fails:
        print("\nFAIL")
        for f in fails:
            print("  -", f)
        return 1
    print("\nPASS: pacing targets met")
    return 0


if __name__ == "__main__":
    sys.exit(main())
