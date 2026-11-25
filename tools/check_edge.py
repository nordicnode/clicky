#!/usr/bin/env python3
"""Edge cases a 10-year-old will find: huge numbers, a maxed cafe, one yarn,
a save written mid-run, and a click worth something at zero fish."""
import os, sys

D = os.path.expanduser("~/.wine/drive_c/users/mikey/AppData/Local/Clicky")
p = os.path.join(D, "edge.txt")
if not os.path.exists(p):
    sys.exit("missing edge.txt; run: CLICKY_EDGE=1 tools/shoot.py")
v = dict(x.split("=", 1) for x in open(p).read().strip().rstrip(";").split(";"))

bad = []
def want(k, cond, msg):
    if not cond: bad.append(f"  {k}: {msg} (got {v.get(k)!r})")

want("big", v["big"] == "1.0aa", "1e15 is the fifth suffix: K M B T aa")
want("bigrate", v["bigrate"] == "987B/s", "a huge rate should read in billions")
want("maxcost_width", int(v["maxcost_width"]) <= 44, "a maxed cost must fit its 44px column")
want("maxrate", v["maxrate"].endswith("/s"), "maxed rate must format")
want("yarn_gain", int(v["yarn_gain"]) == 10, "one reset at the gate pays 10 yarn")
# the gate pays 10 yarn, so a first reset earns the beanie and the crown
want("hats", int(v["hats"]) == 2, "10 yarn earns beanie + crown, not the wizard")
want("hat", v["hat"] == "crown", "the newest hat is worn")
want("reload_fish", v["reload_fish"] == "4242", "the save round-trips")
want("click_at_zero", float(v["click_at_zero"]) >= 1.0, "a click is never worth zero")
want("sticker_name_width", int(v["sticker_name_width"]) <= 50, "a sticker name must fit its badge")
want("sticker_count", int(v["sticker_count"]) >= 12, "there is a sheet worth collecting")

print("edge:", " ".join(f"{k}={v[k]}" for k in v))
if bad:
    print("FAIL"); print("\n".join(bad)); sys.exit(1)
print("PASS: huge numbers, a maxed cafe, one yarn, a round-tripped save and a paid click")
