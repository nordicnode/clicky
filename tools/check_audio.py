#!/usr/bin/env python3
"""Check the music loop starts and that both mutes actually silence it."""
import os, sys

D = os.path.expanduser("~/.wine/drive_c/users/mikey/AppData/Local/Clicky")

def read(name):
    p = os.path.join(D, name)
    if not os.path.exists(p):
        sys.exit(f"missing {name}; run: CLICKY_ATEST=1 tools/shoot.py")
    return dict(x.split("=", 1) for x in open(p).read().strip().rstrip(";").split(";"))

base, muted, on = read("audio.txt"), read("audio_muted.txt"), read("audio_on.txt")
bad = []
if int(base["id"]) < 0 or base["playing"] != "1":
    bad.append("  the cafe loop never started")
if float(muted["gain"]) > 0.02:
    bad.append(f"  muted gain is {float(muted['gain']):.3f}, want ~0")
if float(on["gain"]) < 0.2:
    bad.append(f"  unmuted gain is {float(on['gain']):.3f}, want the loop back up")

print(f"audio: playing={base['playing']} muted gain={float(muted['gain']):.3f} "
      f"unmuted gain={float(on['gain']):.3f}")
if bad:
    print("FAIL"); print("\n".join(bad)); sys.exit(1)
print("PASS: music starts, mute silences it, unmute brings it back")
