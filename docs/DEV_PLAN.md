# Clicky's Cat Café — Development Plan

A sprite-based, semi-idle incremental game for 10-year-olds. GML / GameMaker,
built through the GameMaker `resourcetool` MCP server.

Project: `Clicky/Clicky.yyp` · Source of truth for this plan: this file.

---

## 1. Pitch

You run a one-table cat café. A giant sleepy cat sits on the counter. Every pet
earns **fish**. Fish buys cat furniture, furniture attracts cats, and cats keep
earning while you are at school. Come back and they have a mountain of fish
waiting for you.

**Why a 10-year-old cares**

| Hook | Where it lives |
| --- | --- |
| Petting a giant cat that squishes | `obj_cat_big` |
| Cats visibly filling a room | `obj_cat_idle` |
| Silly names + collectible cards | Cat Album (24 cats) |
| Big numbers that go BOOM | odometer + crits |
| "You were away — look what they made you" | welcome-back screen |
| Hats | prestige rewards |

**Design constraints (non-negotiable)**

- No ads, no purchases, no network calls, no accounts.
- No fail state, no punishment, no timers that expire progress.
- Labels of 1–3 words; every action has an icon.
- Every tap gives feedback within 1 frame. Every purchase within 6.
- Nothing is lost by closing the game at any moment.

---

## 2. Verified toolchain (what actually works here)

Everything below was executed against the real project before this plan was
written — not assumed.

**Installed:** `@gamemaker/gm-cli` 2.4.1, runtime `2026.1.0.28`,
Wine at `/usr/bin/wine`.

**MCP server:** registered in `~/.free-pi/agent/mcp.json` as `gamemaker`,
80 tools, project-locked to `Clicky/Clicky.yyp`. Requires `/reload` in the
session after any config change.

### The proven workflows

```
create sprite   → resource_create {TYPE:"sprite", NAME:"spr_x"}
                  sprite_addframe {NAME:"spr_x", PATH:"/abs/frame.png"}
create object   → resource_create {TYPE:"object", NAME:"obj_x"}
add event       → object_event_findorcreate {NAME:"obj_x", TYPE:"Create"}
                  → returns the .gml path; write GML to it directly
place instance  → room_instance_create {ROOM:"rm_cafe", OBJECT:"obj_x", X:..}
compile         → gm-cli compile   (run inside Clicky/, no login needed)
```

`object_event_findorcreate` prints `New GML file: .../Create_0.gml`. That file
is the event body — edit it with normal file writes.

Event subtype names are **not** the editor labels. Draw events need
`draw_normal`, `draw_begin`, `draw_end`, `draw_gui`, `gui_begin`, `gui_end`.
Bad names fail with an explicit list, so it is self-correcting.

### Running the game (two bugs to route around)

1. `gm-cli run` for **linux** dies in `linuxdeploy`/`unshare` (AppImage
   packaging). Do not use it.
2. `gm-cli run --target windows` **builds fine** but the launcher looks for
   `runtime/.../Windows/x64/Runner.exe` while the runtime ships
   `windows/x64/Runner.exe` (case). It never launches.

Working path:

```bash
# build (ignore the launch error afterwards)
cd Clicky && gm-cli run --target windows --no-verbose

# run
cd Clicky/.gmcache/build-gms2-windows-VM/output
wine ~/.cache/GameMakerCLI/runtimes-gms2/runtime-2026.1.0.28/windows/x64/Runner.exe \
     -game Clicky.win
```

### Screenshot harness (for visual QA)

The game sandbox refuses arbitrary absolute paths, so `screen_save` writes into
the save area:

```gml
screen_save("shot.png");   // → ~/.wine/drive_c/users/<user>/AppData/Local/Clicky/shot.png
```

Verified end to end: build → wine → `screen_save` → `look_at_image`. This is
how every visual milestone gets checked at 480×270 and at integer scale.

### Gotchas worth encoding in code

- **A sprite is not auto-drawn if a Draw event exists.** Call `draw_self()`.
- `gml_getgmlfilepath` only resolves *scripts*, not object events.
- Deleting a resource that a room instance references breaks project linking
  (`Cannot resolve link ... inst_...`). Delete instances first, or edit the
  room's `instanceCreationOrder` and layer `instances` array.
- Hand-editing `.yy` JSON is fragile (GameMaker tolerates trailing commas,
  Python's `json` does not). Prefer MCP tools; repair by hand only when needed.
- `font_setfile` + `font_addrange` did **not** produce a usable font (glyphs
  empty, `includeTTF:false`, nothing rendered). Plan uses a **sprite font**
  instead — see §4.2.

---

## 3. Game design

### 3.1 The loop

```
        ┌──────────────── tap the big cat ────────────────┐
        │                                                  │
        ▼                                                  │
   + fish ──► buy furniture ──► cats appear ──► + fish/s ──┘
        │                            │
        └──► milestones / new zone ──┴──► prestige (yarn) ──► hats + ×mult
```

Three rhythms running at once:

- **Second to second:** tap, crit, combo, floating numbers.
- **Minute to minute:** next tier, next milestone badge, next cat adopts you.
- **Session to session:** offline fish, new zone, prestige.

### 3.2 Economy

- **Fish 🐟** — soft currency. Tapped and produced.
- **Yarn 🧶** — prestige currency. Permanent, never spent.
- **Sparkle ✨** — 8-second frenzy pickup, no inventory.

Core numbers:

```gml
combo         = taps within 0.75s, capped at 40  → up to ×1.8
crit          = 10% chance, ×10, tiny screen shake + "POW!"

producer_cost = ceil(base_cost * power(1.15, owned))
producer_rate = base_rate * owned * tier_mult(owned) * yarn_mult * frenzy

click_flat    = 1 + upgrades.paw            // +1 fish per Soft Paws
click_share   = upgrades.share * 0.01       // % of current fish/s per tap
click_value   = (click_flat + econ_rate() * click_share)
                * combo_mult * crit * yarn_mult
```

`tier_mult` **doubles** at 10 / 20 / 40 / 80 owned — ×2, ×4, ×8, ×16. These
are the "badge" moments that break the exponential wall and reward staying on a
cheap tier.

The rungs started at 10/25/50/100. `tools/tune_economy.py` showed a 2.7-minute
stretch with nothing new around minute 8, so they were pulled in — same shape,
roughly twice the reward events in the first half hour.

```gml
function econ_tier_mult(_owned) {
    if (_owned >= 80) return 16;
    if (_owned >= 40) return 8;
    if (_owned >= 20) return 4;
    if (_owned >= 10) return 2;
    return 1;
}
```

**Tapping must never become pointless.** A flat click is meaningless next to
Tier 8. So a mid-game upgrade (`Helping Paw`, unlocked at Tier 3) makes each tap
add **1% of current fish/s** — at 5 taps/s that is a permanent 5% top-up, and it
scales with the whole economy. Target: tapping at a normal pace stays worth
**5–15% of total income** right through the first prestige. The flat `paw`
upgrade carries the first two minutes; `share` carries everything after.

### 3.3 Producer tiers

| # | Furniture | Base cost | Fish/s each | Payback |
| --- | --- | --- | --- | --- |
| 1 | Cardboard Box | 10 | 0.5 | 20s |
| 2 | Cat Bed | 120 | 4 | 30s |
| 3 | Toy Basket | 1,100 | 30 | 37s |
| 4 | Scratching Post | 8,000 | 200 | 40s |
| 5 | Treat Jar | 55,000 | 1,300 | 42s |
| 6 | Fish Fountain | 400,000 | 9,000 | 44s |
| 7 | Sunbeam Window | 3,000,000 | 65,000 | 46s |
| 8 | Yarn Ball Pit | 25,000,000 | 500,000 | 50s |

Payback drifts 20s → 50s on purpose: early buys feel instant, late buys are
carried by milestone doubles and yarn multipliers.

### 3.4 Prestige — Yarn

Two separate totals, because one number cannot do two jobs:

| Field | Resets on prestige | Used for |
| --- | --- | --- |
| `run_earned` | yes | yarn payout |
| `lifetime_earned` | **no** | zone unlocks, achievements |

```gml
yarn_gain = max(1, floor(power(global.G.run_earned / 500000, 0.5)))
// eligibility: run_earned >= 55,000,000
```

- First prestige lands at **~20 minutes** (measured: 20.3 min), worth
  **~10 yarn** — a visible +100% instead of the original 1–2 yarn, which the
  plan fixed in errata #5 but never re-measured against the payout curve.
- Each yarn: **+10%** to all production forever.
- **First hat at 1 yarn**, then 5 / 15 / 40. A reset that gives nothing visible
  is a reset a kid will never do twice; the starter hat is the reason to press
  the button the first time.
- Reset keeps: yarn, hats, equipped hat, album, achievements, settings,
  `lifetime_earned`.
- Reset clears: fish, `run_earned`, tiers, click upgrades, combo.

### 3.5 Zones (visual phases)

| Zone | Unlock (`lifetime_earned`) | Look |
| --- | --- | --- |
| Cozy Counter | start | warm wood, window, plants |
| Cat Garden | 25,000 | grass, sunflowers, butterflies |
| Rooftop | 500,000 | dusk city, string lights |
| Cloud Café | 5,000,000 | pink clouds, floating islands |

Each zone swaps the background, palette tint and ambient particles. Props and
cats are shared, so the cost is art-only, not systems.

### 3.6 Cat Album (24 cats)

Each cat = portrait + name + one silly line ("Mochi: sleeps in the sink").
Unlock sources:

- 16 by milestone (tiers bought, fish earned, zones entered).
- 8 "visitors": at most one every ~4 minutes, wanders in, tap to adopt.

Album screen is a 4×6 grid of cards; locked cards show a silhouette. This is
the collection loop that survives prestige.

### 3.7 Pacing targets (assert these in a sim)

| Event | Target |
| --- | --- |
| First fish | < 2 s |
| First producer affordable | < 20 s |
| Every 45–90 s for the first 12 min | something new (a purchase or a cat walking in; new tiers and doublings never more than 2 min apart) |
| First prestige | 20–30 min (measured 20.3) |
| Longest stretch with nothing affordable | < 3 min |
| 1 hour offline | ≈ 30 min of progress (50% rate, as §3.6 specifies) |
| Full album | 3–5 sessions |

Offline: `rate * seconds * 0.5`, capped at 8 hours, paid out on a
welcome-back modal with one big **Collect** button.

---

## 4. Visual design

### 4.1 Canvas and palette

- Logical resolution **480×270**, integer scale ×2–×4 (960×540 up to 1920×1080).
- Point filtering everywhere; no sub-pixel positions; camera snapped to ints.
- 12-colour warm palette, plus one "magic" accent for pickups:

```
ink        #2B1B2E
brown dark #5A3A2E   brown #8C5A3C   wood  #C98A5B
cream      #F6E6C8   white #FFFDF7
peach      #F4A26B   coral #E86A5A   pink  #F5A8C8
mint       #8FD6C0   sky   #9ED3F0   gold  #FFC94D
```

Cats get 2–3 recolours from a 6-swatch coat set (tabby, calico, tuxedo, ginger,
grey, black) so 24 cats feel distinct without 24 drawings.

### 4.2 Sprite inventory (~60 assets)

| Group | Count | Detail |
| --- | --- | --- |
| Bitmap font `spr_font` | 1 | 10×16 cells (5×7 glyph at 2×), uses `font_add_sprite_ext` |
| Small font `spr_font_small` | 1 | 6×9 cells (5×7 glyph at 1×) for shop rows and dense labels |
| Big cat | 5 anims | idle 6f, blink 2f, pet 4f, happy 6f, sleep 4f |
| Idle cats | 8 breeds × 3 anims | idle 4f, walk 6f, happy 3f |
| Hats | 6 | top hat, beanie, crown, flower, wizard, fish |
| Furniture | 8 × 2–3f | box, bed, toy basket, post, jar, fountain, sunbeam, yarn pit |
| Props | 10 | plant, lamp, cup, sign, rug, window, cushion, bowl, mouse toy, yarn |
| Pickups/fx | 8 | fish 4f, sparkle 4f, heart 3f, star 3f, puff 4f, ring 4f, crit 3f, confetti 4f |
| Backgrounds | 4 zones × 3 layers | far / mid / near parallax |
| UI | 6 | panel 9-slice, button 3 states, meter, badge, card, arrow |
| Portraits | 24 | 32×32 album faces |

Naming: `spr_<domain>_<thing>_<anim>`, e.g. `spr_cat_tabby_walk`, `spr_ui_btn`.

Animation speed is set per sprite (cats ~8fps, UI 12fps, fx 20fps) so nothing
looks uniformly floaty.

### 4.3 Juice checklist

| Moment | Effect | Timing |
| --- | --- | --- |
| Tap cat | squash 0.86×/1.14×, eyes shut, release | 120 ms |
| Tap | floating `+1` arcs up, fades, drifts ±8px | 600 ms |
| Combo ≥ 5 | cat glows, hearts spawn, pitch climbs | continuous |
| Crit | `POW!` burst, 2px shake, gold flash | 250 ms |
| Purchase | button squash → row collapses → cat walks in | 400 ms |
| Milestone | banner slides, confetti, chime, badge pops | 1.2 s |
| Affordable | button pulses 4% scale at 2 Hz | loop |
| Frenzy | background tints, fish rain, timer ring | 8 s |
| Prestige | screen whites out, yarn ball grows, hats fall | 2.5 s |
| Idle 30s | cat yawns, music fades to purr | loop |

Rules: max 2 shakes per second, effects never cover the fish counter, all
particles pooled (no runtime allocation spikes).

### 4.4 Screen layout (480×270)

```
┌────────────────────────────────────────────────┐
│ 🐟 1,234        +12/s            🧶 3   ⚙ 🔇    │  HUD (24px)
├──────────────────────────────────┬─────────────┤
│                                  │ BOX    10   │
│        big cat + room            │  ×0   🐟    │
│        cats wander here          │ BED   120   │
│                                  │  ×2   🐟    │
│                                  │ TOY  1100   │
│                                  │  🔒         │
├──────────────────────────────────┴─────────────┤
│  [ALBUM]      [ZONES]      [PRESTIGE]          │  dock (36px)
└────────────────────────────────────────────────┘
```

Shop rows: **26px** tall (8 rows = 208px, fits the 210px panel with no
scrolling), icon + short name + cost + count, whole row is the hit target
(≈104 screen px at ×4). Names are abbreviated to fit a 148px column in the
6×9 font: `BOX`, `BED`, `TOYS`, `POST`, `JARS`, `FOUNT`, `SUN`, `YARN`.
Locked rows show a padlock **and** a dimmed cost, never colour alone.

---

## 5. Audio

Generated procedurally (Python + `wave`) into `sounds/`, imported with
`sound_setfile`.

| Sound | Use |
| --- | --- |
| `snd_pop1..5` | taps, ascending pentatonic with combo |
| `snd_meow_a..d` | random cat chatter, pitch-shifted per cat |
| `snd_crit` | bright bell + thump |
| `snd_buy` | soft "clink + purr" |
| `snd_milestone` | 4-note arpeggio |
| `snd_frenzy` | shimmer loop, 8s |
| `snd_music_cafe` | 60s loop, marimba + soft pad |

Two audio groups (`audiogroup_music`, `audiogroup_sfx`) so the mute buttons and
future web builds behave. Music ducks to 30% while a modal is open.

---

## 6. Technical architecture

### 6.1 Project layout

```
Clicky/
  Clicky.yyp
  objects/    obj_boot obj_game obj_cat_big obj_cat_idle obj_shop obj_hud
              obj_floater obj_pop obj_golden obj_album obj_welcome obj_settings
  scripts/    scr_init scr_economy scr_save scr_fmt scr_juice scr_ui
              scr_cats scr_audio scr_achieve scr_debug
  rooms/      rm_boot rm_cafe
  sprites/    spr_*   fonts/ (none — sprite font)   sounds/ snd_*
  options/    windows/linux settings
tools/        gmmcp.py spritemaker.py import_assets.py tune_economy.py shoot.py
art/          generated PNGs (source for import)
docs/         DEV_PLAN.md
```

### 6.2 Object responsibilities

| Object | Does |
| --- | --- |
| `obj_boot` | one-time setup: filter, GUI size, load save, hand off to `rm_cafe` |
| `obj_game` | persistent controller: economy tick, autosave, achievements, offline calc, zone state |
| `obj_cat_big` | tap target, squash animation, crit/combo, spawns floaters |
| `obj_cat_idle` | pooled wandering cats, one per ~2 owned cats (cap 24), walk/sit/sleep |
| `obj_shop` | tier rows, affordability state, purchase, milestone badges |
| `obj_hud` | fish counter (odometer), rate, yarn, mute, nav dock |
| `obj_floater` | pooled `+N` text with arc + fade |
| `obj_pop` | pooled particle bursts |
| `obj_golden` | sparkle spawner + frenzy timer |
| `obj_album` | card grid, locked silhouettes, page scroll |
| `obj_welcome` | offline payout modal |
| `obj_settings` | mute, reset (double-confirm), credits |

### 6.3 State and save

Single global struct, so save/load is one `json_stringify`:

```gml
global.G = {
    v: 1,
    fish: 0.0,
    run_earned: 0.0,        // resets on prestige (yarn payout)
    lifetime_earned: 0.0,   // never resets (zones, achievements)
    yarn: 0.0,
    tiers: [0,0,0,0,0,0,0,0],
    click_upgrades: { paw: 0, share: 0 },
    cats: [],               // album ids owned
    hats: [],               // hat ids owned
    equipped_hat: "",
    achievements: [],       // ids
    world: { zone: 0 },
    stats: { clicks: 0, playtime: 0, prestiges: 0, best_rate: 0 },
    settings: { mute_music: false, mute_sfx: false, reduce_motion: false },
    last_seen: 0
};
```

Save rules:

- `save.json` in the sandbox save dir, written to `save.tmp` then renamed.
- Autosave every 15 s, on focus loss, on modals closing, on `game_end`.
- `v` gates migrations; unknown fields are preserved, missing fields defaulted.
- **First launch:** `last_seen` is 0, so skip the offline calculation entirely —
  a new player must never see a "welcome back" modal for time they did not play.
- Offline is computed from `last_seen`; negative or > 8 h is clamped; the result
  uses producer rate only (no frenzy, no combo).

### 6.4 Economy module (single source of truth)

```gml
function econ_tier_mult(_owned) {
    if (_owned >= 100) return 16;
    if (_owned >= 50)  return 8;
    if (_owned >= 25)  return 4;
    if (_owned >= 10)  return 2;
    return 1;
}

function econ_cost(_tier) {
    return ceil(TIER[_tier].cost * power(1.15, global.G.tiers[_tier]));
}

function econ_rate() {
    var _r = 0;
    for (var i = 0; i < array_length(TIER); i++) {
        var _owned = global.G.tiers[i];
        _r += TIER[i].rate * _owned * econ_tier_mult(_owned);
    }
    return _r * (1 + global.G.yarn * 0.10);
}

// frenzy is applied at the tick, never inside econ_rate(), so offline
// earnings and the rate readout can never be boosted by a live pickup.
function econ_tick(_dt) {
    var _gain = econ_rate() * global.frenzy * _dt;
    global.G.fish += _gain;
    global.G.run_earned += _gain;
    global.G.lifetime_earned += _gain;
}
```

`TIER` is a struct array defined in `scr_economy`, and `tools/tune_economy.py`
reads the same table (exported as JSON) so the balance sim and the game can
never drift apart.

Everything numeric that the player sees goes through `fmt_number()`:
`0–999` plain, then `1.2K`, `3.4M`, `5.6B`, `7.8T`, then `aa/ab/…`. Never show
raw floats, never show `1e+06`.

### 6.5 Rendering and scaling

```gml
// obj_boot
gpu_set_tex_filter(false);
display_set_gui_size(480, 270);
window_set_size(480 * SCALE, 270 * SCALE);
surface_resize(application_surface, 480, 270);
```

All UI in Draw GUI at logical pixels. Room layers scroll one pixel at a time.
On window resize, recompute `SCALE` and re-centre. Text is drawn with the
sprite font so it stays crisp at every scale.

### 6.6 Targets

Primary: **Windows** (builds and runs here under Wine, matches what a kid
would install). Secondary: **web / GX.games** once the loop is fun — that is
the easiest way to send a link to a friend. Both are VM builds; no YYC needed.

---

## 7. Asset pipeline

Three small Python tools, all deterministic and re-runnable. No AI image
generation in the main pipeline — pixel art needs to be *consistent*, and a
generator with a shared palette guarantees that. (`generate_image` is still
useful for mood boards and zone backdrops, but never for the animation frames.)

```
art/palette.json      the 12 colours + coat swatches
tools/spritemaker.py  shape DSL → PNG frames → art/<sprite>/<anim>_<n>.png
tools/import_assets.py  creates sprites via MCP, adds frames, sets origin + speed
tools/tune_economy.py   headless economy sim → pacing report
tools/shoot.py          build + wine + screen_save + collect screenshots
```

The sprite maker works in a tiny declarative language so cats stay on-model:

```python
cat(
    coat="tabby", pose="walk", frame=2,
    ears="up", eyes="open", tail="curl", accessory=None
)
```

Body proportions, outline width, shadow offset and dither pattern are constants,
so every cat automatically sits in the same visual family. Frames are drawn at
1× and exported at 1× (the game scales integer).

`import_assets.py` is idempotent: it creates the sprite if missing, replaces
frames if the PNG digest changed, and always sets origin 9 (bottom-centre) for
cats/props and 4 (centre) for fx/UI.

Cost check: ~60 assets, roughly 220 frames, generated in seconds, and any
single sprite can be regenerated and reimported in one command without touching
the editor.

---

## 8. Build, run and verify loop

Every change goes through the same five gates. Nothing is called "done" until
gate 5 passes.

```bash
# 1. compile — catches GML syntax and link errors in ~30s
cd Clicky && gm-cli compile

# 2. build windows
cd Clicky && gm-cli run --target windows --no-verbose   # ignore launch error

# 3. run under wine
cd Clicky/.gmcache/build-gms2-windows-VM/output
wine ~/.cache/GameMakerCLI/runtimes-gms2/runtime-2026.1.0.28/windows/x64/Runner.exe \
     -game Clicky.win

# 4. capture (scripted by scr_debug, no manual clicking)
#    obj_debug calls screen_save("shot_<name>.png") after a scripted sequence
cp ~/.wine/drive_c/users/mikey/AppData/Local/Clicky/shot_*.png tools/shots/

# 5. look at it
#    look_at_image on each shot: "is the cat centred, is text readable,
#    does the layout match the 480x270 spec?"
```

**Headless checks that do not need a window**

- `tools/tune_economy.py` — replays the economy for 60 simulated minutes and
  asserts every pacing target in §3.7. Runs in under a second, so it runs on
  every balance change.
- A `scr_debug` "sim" mode: fast-forward N minutes of economy and dump a CSV,
  used to confirm GML and Python agree to the fish.

**Debug keys (debug builds only)**

| Key | Action |
| --- | --- |
| F1 | toggle hitbox/row bounds overlay |
| F2 | +10,000 fish |
| F3 | skip 5 minutes |
| F4 | force sparkle frenzy |
| F5 | unlock all album cats |
| F6 | screenshot sequence |
| F9 | wipe save and restart |

Screenshot sequences are defined once per milestone so visual regressions are
comparable frame to frame.

---

## 9. Milestones

Each milestone ends with: compile green, sim green, screenshots reviewed, and
a playable build. Estimates assume one focused developer-agent day ≈ 4 hours of
real work.

### M0 — Skeleton (½ day) **DONE**
Project options, `obj_boot`, `obj_game`, `scr_init`, `scr_fmt`, `scr_save`,
`rm_boot` → `rm_cafe`, debug keys, screenshot harness, palette + sprite font.
**Accept: game boots to an empty café, fish counter shows 0, save survives a
restart, screenshot of a known scene renders identically twice.**

Shipped: 480×270 room, `obj_bg` painted room, sprite fonts, save/load/autosave
(15 s, on tap, on game end), debug keys F2/F3/F5/F6/F9, `tools/shoot.py`
build → wine → screenshot loop. Verified: `save.json` persists fish and clicks
across two runs (9.72 → 19.44, 18 clicks).

### M1 — The tap (1 day) **IN PROGRESS (tap loop done)**
Big cat with 5 animations, squash, combo, crits, floaters, particle bursts,
fish counter odometer, first sound effects.
**Accept: 30 seconds of tapping is genuinely satisfying; combo reaches ×1.8;
each tap is audible and visible; 60fps with 200 floaters live.**

Shipped: big cat at 1.95× scale with idle/pet animations, squash-and-stretch,
combo (cap 40) with badge in the HUD, 10 % crits at ×10, staggered floaters
(hard cap 6 live, ink-on-white-halo so they read on any wall), heart/sparkle
bursts, screen shake, pentatonic tap pops that climb with the combo.
Remaining for M1: odometer roll on the fish counter, 200-floater stress test,
and the "pet me" first-run prompt.

### M2 — Cats and shop (1½ days) **DONE**
8 tiers, shop rows with affordability/lock states, purchase animation, idle
cats spawning/wandering, milestone doubles at 10/20/40/80, rate readout.
**Accept: buying a box makes a cat walk in; every tier is affordable within
its pacing window; the shop never shows an unaffordable-only screen.**

Shipped: 200px shop panel (`obj_shop`) with eight 26px rows — prop icon, name,
owned count on the name baseline, right-aligned cost, gold breathing pulse when
affordable, dim wash + padlock when locked, doubling hairline along the row
bottom. `obj_cat_mini` wanders the floor with four coats, sits and cheers at
random, depth-sorted by y. One cat walks in per purchase, cap 20. Purchases and
doublings save immediately.

Verified: purchases persist across runs (`tiers [2,2,2]` in `save.json`);
`tools/tune_economy.py` PASSes every §3.7 target (first prestige 20.3 min,
worst purchase gap 0.1 min, 1h offline = 30 min); 20 extra cats run at 58 fps
with `fps_real` 2267, i.e. ~0.44 ms per frame, measured under Wine with
`CLICKY_STRESS=1`.

### M3 — World and polish (2 days) **DONE**
Four zones with parallax backgrounds, zone unlock transitions, ambient
particles, UI panels/cards/dock, odometer rolling, affordable-row pulse,
day→dusk tint.
**Accept: each zone looks distinctly different in a screenshot; the café reads
as "cute" to someone who has not seen the plan; no element overlaps at ×2.**

Shipped: `scr_zones` holds the four rooms and their unlock math; `scr_zone_art`
draws them from primitives, so the whole world costs no memory and recolours
per zone. Parallax is a mouse offset plus a slow breath, capped at ±8px. Each
room has its own ambient life — dust motes, butterflies, fireflies, drifting
sparkles. A new room lands with a cream flash, a chime (`snd_zone`) and a name
card over the play area, then the room stays put across saves.

Unlock timing, measured with the same bot as the economy sim: **3.9 min** (Cat
Garden), **8.3 min** (Rooftop), **13.3 min** (Cloud Café) — one new room every
four or five minutes, with the last one landing well before the 20-minute first
prestige.

Verified: all four rooms photographed (`tools/shots/shot_4..6`, `shot_zone_card`)
and reviewed for clarity; zones reached through the real `zone_check()` path, not
by calling `zone_enter` from the demo; the HUD audit passes on the combo, idle
and rooftop shots. The dock from the original list moved to M5 — its three
buttons have nothing to open until the album and options exist, and shipping
dead buttons to a ten-year-old is worse than shipping no buttons.

### M4 — Idle systems (1 day) **DONE**
Offline earnings with clamped time, welcome-back modal, sparkle spawner and
frenzy, autosave, focus-loss save, 8h cap.
**Accept: quit for 10 minutes → return gives a believable amount; frenzy
doubles income for exactly 8s; save file is valid after a hard kill.**

Shipped: `obj_welcome` explains the offline fish in words ("You were away 14m /
The cats kept fishing! +8.4K") with one YAY button and no way to get stuck.
`obj_sparkle` drifts in every 45–75s once there is income, waits 12s, fades out
rather than vanishing, and pays 8 seconds of double income with a banner that
grows in on pickup. Autosave every 15s, save on every tap and purchase, and a
save the moment the window loses focus.

Verified against the shipped code, not a Python copy:
`tools/check_offline.py` reads what the game itself computed — 10 minutes away
pays 600s of half rate, 6 days clamps to the 8h cap, a fresh save pays nothing,
and frenzy doubles the live rate while the displayed rate excludes it.
Hard kill: `pkill -9` mid-run leaves valid JSON (`fish 2401, clicks 4`), and the
next launch loads it.

### M5 — Collection and meta (1½ days) **DONE, except achievements**
Cat album (24 cards, silhouettes, page scroll), achievements/stickers, prestige
with yarn ball animation, hats, permanent multiplier display.
**Accept: album fills as expected; prestige wipes the right things and keeps
the right things; a second run is measurably faster.**

Shipped: `scr_album` holds 24 cats with a name, a silly line and a lifetime
threshold; the album is a 4×3 card grid over two pages, silhouettes and a
padlock on what is not found yet, and the hovered card says its line (or where
to find it) along the bottom. Prestige runs from a card that spells out the
trade ("Every yarn makes cats +10% faster, forever"), spins a yarn ball in, then
resets. Hats: beanie at 1 yarn, crown at 5, wizard at 15, seated on the cat by
measuring the head (17px wide, crown 10 rows down) rather than guessing. The
permanent ×N multiplier is a pill in the top bar. The dock under the shop opens
ALBUM and YARN; a golden halo pulses on the yarn button when a reset is worth
doing.

Verified: `tools/check_prestige.py` reads the game's own numbers — 60M run pays
10 yarn, fish/run/tiers/upgrades cleared, lifetime kept, hats granted, multiplier
x2. All three hats photographed and checked for seating (`shot_hat*.png`).

Deferred: achievements/stickers move to M6 — they are the one part of this
milestone that does not gate any other system.

### M6 — Audio and onboarding (1 day) **DONE**

Music loop, ducking, all sfx hooked, mute persistence, first-run tutorial
(4 steps, 3 words each), "what's this?" tooltips.
**Accept: a first-time player reaches their first purchase in under 20s with no
explanation outside the game; every sound has a mute path.**

Built:
- `snd_music_cafe` — a 16-bar C-Am-F-G marimba-and-pad loop at 92 BPM, ~42 s,
  generated by `tools/audiomaker.py` (`music_cafe()`), faded at both ends so the
  loop joins without a click.
- `scr_audio` now owns the music too: `music_init/start/refresh` and
  `music_apply_gain()`, one instance, gain eased — muted by the setting, ducked
  to 30% while any card is open (`album`, `prestige`, `welcome`, `settings`).
- `snd_milestone` on a doubling, `snd_frenzy` on the sparkle, `snd_meow` on
  roughly one tap in ten with a randomised pitch.
- `obj_settings` as a real card: MUSIC and SOUND switches (a muted switch draws
  at 62% alpha as well as saying OFF), START OVER which only wipes on a second
  press and forgets that press after four seconds, close X / Esc / click-outside.
  Reached from the third dock button, so nothing is hidden behind a key.
- `obj_tutorial`: four steps — TAP THE CAT, KEEP TAPPING, BUY A BOX, NEW CAT! —
  advancing on what the player actually did (`stats.clicks`, then owned tiers),
  never on a timer, with the pill hugging its words and centred on its arrow.
- Shop rows explain themselves on hover (`BOX +0.5/s each`), which needed
  `fmt_small()` — `fmt_number(0.5)` reads "0", and "BOX +0/s" is a lie.

Verified: `tools/check_audio.py` reads the running game — loop is playing at
boot, muted gain 0.020, unmuted gain 0.470. `shot_tutorial.png`,
`shot_settings.png` and `shot_tooltip.png` reviewed by eye, then the settings
card's vertical rhythm measured in pixels (bands at 48/74/106/126/154/178/190
with 19px below) rather than eyeballed.

### M7 — Balance and bug bash (1 day)
Sim tuning, 3-resolution screenshot pass (960×540, 1440×810, 1920×1080), 30-min
scripted playtest, edge cases (0 fish, max tiers, 1 yarn, offline 3 days,
window resize, alt-tab).
**Accept: every §3.7 target met in the sim and confirmed in one real session;
no visual defects in the screenshot set.**

Total: **~9 days**. A playable vertical slice (M0–M2) exists after **3 days**,
which is the right point to let a 10-year-old try it and react.

### What to cut if time is short

1. Zones 3–4 (keep two).
2. Hats (keep the yarn multiplier).
3. Music (keep sfx — they carry more feel per hour of work).

Do not cut: the squash, the floaters, the offline modal, the album.

---

## 10. Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| `gm-cli run` broken on this box | Can't see the game | Wine path proven; wrap it in `tools/shoot.py` |
| MCP holds a project lock | Writes fail mid-run | One client at a time; always `close()`; retry once |
| Hand-editing `.yy` corrupts project | Hours lost | Only MCP tools; `gm-cli compile` after every batch; keep project in git |
| Deleting referenced resources | Link failure | Delete room instances first, compile immediately |
| TTF fonts don't render | Ugly UI | Sprite font from §4.2 — already decided |
| Pixel art drifts off-model | Looks amateurish | Generator with fixed proportions + palette, never freehand |
| Exponential walls feel bad | Kid quits | Milestone doubles + yarn multiplier + sim assertions |
| Idle game becomes a spreadsheet | Boring | Juice budget: every purchase and milestone gets animation + sound |
| Scope creep into online/social | Never ships | Hard constraint: no network |

---

## 11. Product safety (for a 10-year-old)

- No monetisation of any kind, no external links, no analytics.
- No chat, no names from the internet, no user-generated content.
- No streak loss, no energy timers, no "come back in 4 hours" gates.
- Optional read-aloud: every modal has a 6-word maximum headline; icons carry
  the meaning.
- Settings include a one-tap **Reset** behind a double confirm, and a
  **Reduce motion** toggle that disables shake and heavy particles.
- Colour is never the only signal: locked = padlock + dim, affordable = pulse +
  brighter cost, disco colors avoided in favour of one warm palette.

---

## 12. Open decisions (defaults chosen, changeable)

| Decision | Default now | Alternative |
| --- | --- | --- |
| Window size | 1440×810 (×3) | 1920×1080 (×4) |
| Big cat personality | sleepy loaf | bouncy kitten |
| Prestige name | Yarn | Star Paws |
| Zone order | Counter → Garden → Rooftop → Cloud | Garden before Counter |
| Distribution | Windows + itch-style zip | GX.games link |

## 13. Immediate next step

Build **M0 + M1 in one pass** — boot, save, sprite font, big cat, tap loop —
then capture three screenshots (idle, mid-combo, crit) and judge the feel
before any economy work. That is the cheapest possible test of whether this
game is actually charming.

---

## 14. Errata log (review fixes, applied before coding)

| # | Issue | Fix |
| --- | --- | --- |
| 1 | `tier_mult` said ×2/×4/×8/×16 at 10/25/50/100 but code did `1 + owned/25` | `econ_tier_mult()` returns 1/2/4/8/16 at 0/10/25/50/100 |
| 2 | `total_earned` was used for both yarn and zones — double-claimable or self-locking | split into `run_earned` (resets, yarn) and `lifetime_earned` (persists, zones) |
| 3 | `achievements`, `equipped_hat`, `world` missing from the save struct | added; `last_seen == 0` skips the offline modal |
| 4 | tapping became worthless once Tier 8 ran | `click_share` upgrade: 1% of fish/s per tap, target 5–15% of income |
| 5 | first prestige gave 1–2 yarn and no hat | `max(1, …)` payout and a starter hat at 1 yarn |
| 6 | 10×14 font could not fit shop names; 36px rows overflowed | added `spr_font_small` (6×9) and 26px shop rows (8 fit in 208px) |
| 7 | `frenzy` was inside `econ_rate()`, so offline and the rate readout could be boosted by a live pickup | frenzy applied only in `econ_tick()` |
| 8 | the cat never appeared: background sat at a lower depth than the cat and painted over it, and the room's own background layer covered it at depth 1000 | `obj_bg` at depth **150** (behind instances, in front of the room background layer at 200); floaters/pops at −80/−70 in front of the cat at 0 |
| 9 | every lowercase letter rendered as `?` (`+0/s` printed `+0/?`) | glyph table extended with a–z, still 95 frames for ASCII 32–126 |
| 10 | `audio_play_sound(asset_get_index("snd_pop" + n))` threw *Index did not map to an existing audio asset*, and 22 kHz WAVs left `duration: 0.0` | sounds re-cut at 44.1 kHz and looked up through a literal array, so no string→asset lookup at runtime |
| 11 | quitting in the first 15 s lost everything (autosave only) | save on Game End (`Other_3`), a throttled `save_touch()` on every tap and purchase, plus the 15 s timer |
| 12 | floaters stacked into an illegible smudge during fast tapping | golden-fan spawn offsets, 26-frame life, hard cap of 6 live floaters, ink fill with a white halo |
| 13 | the cat read as "a nightmare, not a cat" and everything looked blurry | `spritemaker.py` now authors every sprite on an exact native pixel grid (no 8× supersample + palette snap); big cat redesigned at 39×35 with pointed ears seated on the dome, big glossy eyes, blush, `:3` mouth, tucked paws |
| 14 | HUD icons were vague blobs and the bar was unaligned | fish and yarn redrawn as recognisable 16×16 icons; every element centred on the bar midline and verified by `tools/audit_hud.py`, which measures the rendered pixels |
| 15 | lampshade hung beside its own wire | every lamp part now derives from one centre `_lx = 72` (cord, canopy, shade, bulb); measured identical centre x = 71.8 |
| 16 | the doubling ladder 10/25/50/100 left a 2.7-minute dead stretch | pulled in to 10/20/40/80; sim now asserts the gap |
| 17 | first prestige arrived at 6.5 min, not 20–30 | threshold 100k → 55M `run_earned`, yarn divisor 100k → 500k (first reset ≈ 10 yarn) |
| 18 | §3.7 claimed "1 hour offline ≈ 10 min of progress" while §3.6 pays 50% | impossible with a 50% rate (that is 30 min); target corrected to ≈ 30 min |
| 19 | `tools/tune_economy.py` did not exist, so economy claims were unverified | written; mirrors `scr_econ.gml`, plays a payback-maximising bot, and asserts every §3.7 target |

Any change to the economy table must be mirrored in `tools/tune_economy.py` and
re-asserted against §3.7 before it is merged.
| 20 | the rooftop sunset rendered icy blue | GameMaker's `$RRGGBB` literals are **BGR**, so `$FFA35C` is a cyan; every zone colour now goes through `zc(r, g, b)` |
| 21 | the zone name card was cut in half by the shop panel | it was centred on the full 480px canvas; now centred in the 280px play area and clamped to 272px wide |
| 22 | `Variable obj_bg.last_zone not set` | `obj_bg` had a Step and a Draw but no Create event; the Create event was created and now seeds `last_zone` |
| 23 | the garden sun was invisible and the cloud island looked like a mushroom | the sun sat at x=352, behind the shop panel; the island's cone was hidden under the gold floor band |
| 24 | `audit_hud.py` flagged the decimal point in "2.4M" as misaligned | punctuation sits on the baseline by design; elements under 6px tall are now skipped |
| 25 | a sparkle's frenzy never reached the live rate before the banner drew | `frenzy_kick` was set by the pickup, but `obj_hud` had no Create event; the variable was created only on pickup, so the first frame read an unset variable |
| 26 | every number on screen was one unit too big (8420 read "8.4M") | `fmt_number` divided then indexed `_suf[_i]`; it must index `_suf[_i - 1]` |
| 27 | a big fish count printed as "0" late in a run | GML promotes integers past 2^31 to int64, and `is_real()` says false for int64; the formatter now casts with `real()` first |
| 28 | the welcome card's payout number touched the YAY button | card is 110px tall with the button at +84, verified by measurement and by eye |
| 29 | GameMaker dates count **days**, not seconds | the offline test that subtracted `600` was really subtracting 600 days; every offline gap is `seconds / 86400` |
| 30 | offline/frenzy claims were untested | `tools/check_offline.py` + `tools/check_fmt.py` read values the running game wrote out, so the checks cannot drift from the code |
| 31 | hats floated above the cat's head | the seat was a guess; the head is 17px wide with its crown 10 rows down, so the brim now rests on row 10 and the hat covers only what is above it |
| 32 | album portraits overlapped their own names | mini cat sprites have a top-left origin, so `draw_sprite_ext` at the centre pushed them right; portraits are placed by box with `draw_sprite_stretched` |
| 33 | `global.HATS["beanie"]` threw "unable to convert string to int64" | string-keyed struct lookup was read as an array index; hats are looked up by a `switch` in `hat_sprite()` |
| 34 | the frenzy banner covered the album header | album and prestige draw at depth 690, in front of the HUD at 800 but behind the shop at 200, and their dim only covers the play area |
| 35 | clicking a card also punched the cat behind it | the cat and the shop ignore the mouse while a modal exists |
| 36 | the wizard hat leaned left of the cat's head | its art was not centred on its own brim; the cone was rebuilt around column 10 so the tip rises from the middle |
| 37 | regenerated art silently kept the old sprite frames | the importer only added frames to empty sprites; it now refreshes any sprite whose PNG is newer than its `.yy`, and deleting a sprite folder by hand is what broke the project |
| 38 | the settings card was a mess: close X off the card, every label flush to the left border, three different left edges | the card now has one padding constant that every element hangs off, an 18px X tucked inside the top-right, and two equal toggle buttons |
| 39 | the settings card had a dead band at the bottom | the card is 176px tall and its sections were measured in pixels (48/74/106/126/154/178/190), not nudged by eye |
| 40 | the hint pill and its arrow were not aligned | the arrow sits on the cat's centre line and the pill is centred on the arrow, with its width measured from `string_width()` instead of a fixed 108 |
| 41 | the room's window slid side to side | `zone_parallax()` was pushing every wall fixture, and its sine "breathing" moved the room even with a still mouse. Wall-mounted things are now anchored, distant scenery keeps a ±3px eased offset |
| 43 | a "strange floating circle" sat in the Cloud Cafe | the floating island had a two-lobed bush and a parasol that read as a face on a propeller at 480px; it is now one grass cap, one tree and a faceted rock, with no extra blobs |
| 42 | reading `global.par_x` before it was set crashed the draw event | GML raises on an unset global instead of returning undefined, so `undefined` guards do not work; it is declared in `scr_init` |
| 44 | Hollow closing objectives required activities whose doors were still locked, including the final Night objective | the parlour opens at 0 closings, hall at 1, garden at 3, cellar at 6, and Night at 12; every required activity opens before its objective |
| 45 | at four and five doors the hall drew a door and its candle underneath the run panel | the row tightens to a 63px pitch and slides left so every door ends by x=326; `veil_test` asserts the bounds for 3–5 doors |
| 46 | the garden familiar sat in front of a sealed bed and hid its label | moved to the free corner beneath the reading plate, clear of beds, seed pouches and the nav bar |

### The Hollow's ownership

- `scr_veil_core` owns the persistent `global.G.occult` state: defaults, save
  normalization, the café discovery gate, closings, omens, relics, charms and the
  long night. It never draws.
- `scr_veil_seance`, `scr_veil_hall`, `scr_veil_garden` and `scr_veil_bench` each own
  one activity's rules and its own click/draw pair; `scr_veil_ui` owns map, nav, rites
  and relic layout shared by the shell.
- `scr_veil_art` owns the dark palette and the drawing primitives (cats, panels,
  seals, plates) so every screen looks like the same place.
- `obj_veil` is the single input and draw shell for the layer; `obj_veil_door` is the
  café-side discovery and entry. `obj_boot` only decides whether to spawn the shell.
- `scr_veil_test` runs only under `CLICKY_VEILTEST`; `tools/veil_test.py` drives it in
  its own Wine prefix (`phase 1` play, `phase 2` reload, `phase 3` a pre-Hollow save).

### Service and prestige ownership

- `scr_service` owns the persistent `global.G.service` state, guest and recipe rules,
  unlock, rewards, and service-specific save normalization. The generic save
  loader merges the save and then calls that normalization; the save schema is unchanged.
- `obj_service` owns transient card animation, input and presentation. Input calls
  service actions; drawing reads service state and rules. The shop asks the service
  whether its entry is unlocked rather than duplicating that policy.
- `scr_layers` owns reset rules and persistent layer state. `obj_prestige` owns
  selection, animation and card layout; its input and draw events share tab geometry.

