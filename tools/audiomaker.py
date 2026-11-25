#!/usr/bin/env python3
"""Procedural sound effects for the cat cafe.

Soft marimba-ish pops, a bright crit bell, a purr, and a buy clink. Small
mono 22 kHz WAVs, so the whole set is a few hundred KB.
"""
import math
import os
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art", "sounds")
SR = 44100


def env(t, dur, attack=0.004, decay=6.0):
    a = min(1.0, t / attack) if attack > 0 else 1.0
    return a * math.exp(-decay * t / dur)


def tone(freq, dur, amp=0.45, partials=((1, 1.0), (2, 0.28), (3, 0.12)),
         decay=5.5, bend=0.0):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        f = freq * (1 + bend * (t / dur))
        v = sum(a * math.sin(2 * math.pi * f * k * t) for k, a in partials)
        out.append(amp * v * env(t, dur, decay=decay))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    w = wave.open(path, "w")
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    frames = b"".join(
        struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
        for s in samples
    )
    w.writeframes(frames)
    w.close()
    return path


def marimba(freq, dur=1.2, amp=0.18):
    """A soft mallet note: fast decay, a couple of partials, no click."""
    return tone(freq, dur, amp,
                partials=((1, 1.0), (2, 0.22), (4, 0.07), (7, 0.03)),
                decay=4.2, bend=0.0)


def pad(freq, dur, amp=0.05):
    """A very quiet sustained tone, faded in and out so loops do not click."""
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        fade = min(1.0, t / 0.6) * min(1.0, (dur - t) / 0.8)
        v = (math.sin(2 * math.pi * freq * t)
             + 0.5 * math.sin(2 * math.pi * freq * 2 * t))
        out.append(amp * v * fade)
    return out


def music_cafe():
    """Sixteen bars of C-Am-F-G at a gentle 92 BPM, marimba over a pad."""
    beat = 60.0 / 92
    bar = beat * 4
    bars = 16
    total = bar * bars
    n = int(SR * total) + 1
    buf = [0.0] * n

    def add(samples, at):
        start = int(at * SR)
        for i, v in enumerate(samples):
            if start + i < n:
                buf[start + i] += v

    # I - vi - IV - V, one chord per bar, cycling
    chords = [
        (261.63, (261.63, 329.63, 392.00)),   # C
        (220.00, (220.00, 261.63, 329.63)),   # Am
        (174.61, (174.61, 220.00, 261.63)),   # F
        (196.00, (196.00, 246.94, 293.66)),   # G
    ]
    melody = [392.00, 440.00, 523.25, 440.00, 392.00, 329.63, 392.00, 523.25,
              587.33, 523.25, 440.00, 392.00, 349.23, 392.00, 440.00, 523.25]

    for b in range(bars):
        root, notes = chords[b % 4]
        t0 = b * bar
        # pad holds the whole bar
        for f in notes:
            add(pad(f, bar), t0)
        add(pad(root / 2, bar, 0.055), t0)
        # marimba: root on beats 1 and 3, a melody note on 2 and 4
        add(marimba(root, 1.4, 0.16), t0)
        add(marimba(notes[2], 1.2, 0.12), t0 + beat * 1.0)
        add(marimba(melody[b] if b < len(melody) else notes[1], 1.4, 0.15),
            t0 + beat * 2.0)
        add(marimba(notes[1], 1.1, 0.10), t0 + beat * 3.0)
        # a soft fifth on the offbeat keeps it moving
        add(marimba(root * 1.5, 0.8, 0.06), t0 + beat * 3.5)

    # normalise and round the ends so the loop joins cleanly
    peak = max(abs(v) for v in buf) or 1.0
    buf = [v / peak * 0.62 for v in buf]
    tail = int(0.25 * SR)
    for i in range(tail):
        k = i / tail
        buf[i] *= k
        buf[-1 - i] *= k
    return buf


def main():
    made = []
    # five ascending tap pops, pentatonic so combos sound musical
    for i, f in enumerate([523.25, 587.33, 659.25, 783.99, 880.00]):
        made.append(write(f"snd_pop{i + 1}", tone(f, 0.11, 0.40, decay=7.5)))

    # crit: bright bell + low thump
    made.append(write("snd_crit", mix(
        tone(1046.5, 0.22, 0.30, decay=6.0),
        tone(1568.0, 0.18, 0.18, decay=7.0),
        tone(196.0, 0.16, 0.22, partials=((1, 1.0),), decay=5.0),
    )))

    # buy clink
    made.append(write("snd_buy", mix(
        tone(880.0, 0.10, 0.25, decay=9.0),
        tone(1318.5, 0.14, 0.18, decay=8.0),
    )))

    # zone unlock: bright four-note chime
    made.append(write("snd_zone", mix(
        tone(523.25, 0.30, 0.26, decay=4.5),
        tone(659.25, 0.34, 0.22, decay=4.2),
        tone(783.99, 0.38, 0.20, decay=4.0),
        tone(1046.5, 0.46, 0.16, decay=3.4),
    )))

    # meow: a small pitch-bendy call
    made.append(write("snd_meow", tone(
        620.0, 0.24, 0.26,
        partials=((1, 1.0), (2, 0.5), (3, 0.25), (5, 0.1)),
        decay=3.2, bend=0.35)))

    # loud milestone: a short rising arpeggio for a doubling
    made.append(write("snd_milestone", mix(
        tone(659.25, 0.22, 0.22, decay=6.0),
        tone(880.00, 0.26, 0.20, decay=5.5),
        tone(1174.66, 0.34, 0.18, decay=4.6),
    )))

    # frenzy pickup shimmer
    made.append(write("snd_frenzy", mix(
        tone(1046.5, 0.30, 0.18, decay=5.0),
        tone(1318.5, 0.34, 0.15, decay=4.6),
        tone(1568.0, 0.40, 0.12, decay=4.2),
    )))

    made.append(("snd_music_cafe", write("snd_music_cafe", music_cafe())))
    print(f"wrote {len(made)} sounds to {OUT}")


if __name__ == "__main__":
    main()
