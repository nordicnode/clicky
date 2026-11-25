# Clicky — Gameplay Inventory (2026-11-24)

Purpose: a factual snapshot of what exists in the build today, how much of it there
is, and how the player is (or is not) introduced to it. Written after reading the
scripts and objects and after running the Windows VM under Wine. This is the map
for later content and guidance passes; do not re-derive it from scratch.

Verified against:
- `Clicky/` (GameMaker 2026 project; **native 1920x1080 GUI canvas**, with the
  480x270 room art still drawn at 4x underneath it)
- `python3 tools/cafe_test.py --fresh --fullscreen` (106 in-game checks PASS,
  0 FAIL, 35 screenshots; the layout audit is also part of the run and PASSes;
  ends with a DONE marker so the runner stops instead of hanging, see §13.1)
- `python3 tools/strip_click_probe.py` (real X11 clicks in the built game; 5/5 checks)
- `python3 tools/veil_test.py 1 --fresh --fullscreen` (52 PASS / 0 FAIL, 12 native
  Hollow screenshots at 1920x1080; phase 2 adds 8 save checks)
- `python3 tools/tune_layers.py` and `tools/tune_economy.py` (pacing)
- `tools/shots/ui/*.png` from the isolated Wine save, not the player's save

---

## 1. Core loop

One currency (`fish`) is produced by a tap and by 14 passive producers. Buy rows to
raise production; reset to convert a run into a layer currency that permanently
multiplies production; spend that currency on permanent charms; unlock rooms,
cats, the counter, journals, festivals, and finally the hidden Hollow layer.

- Tap: flat value plus a share of `/s`, multipliers from layers, charms, journal,
  staff; combo raises a temporary multiplier; crits pay 10x (+2x per COMET level).
- Sparkles: gold pickup gives frenzy (x2 income, 8s + charms), plus materials.
  They drift in the room and are clicked or auto-collected by SPARKLE HANDS.
- Offline: on return, pays `rate * away_seconds * offline_rate` capped at 8h +
  CANOPY levels. Base 50%, raised by NIGHT SHIFT, MORNING DEW, MOONLIT, projects,
  skills, and the WINDOW staff station. A welcome-back card explains the payout.
- Save: one JSON file, `SAVE_VERSION 1`; defaults merge additively, dynamic
  upgrade keys are loaded explicitly. Prestige resets keep charms, cats,
  journal, staff, stickers, hats, Hollow state and settings; fish and shop tiers
  are cleared. The settings-card reset wipes the whole save.

## 2. Producers (14 tiers)

`scr_econ.gml` is the source of truth; `tools/tune_layers.py` mirrors it.

| # | Name | Base cost | Base /s | | # | Name | Base cost | Base /s |
|---|------|-----------|---------|---|----|------|-----------|---------|
| 0 | BOX | 10 | 0.5 | | 7 | BALL | 55M | 850K |
| 1 | BED | 130 | 5 | | 8 | MUG | 450M | 6.5M |
| 2 | TOYS | 1.4K | 45 | | 9 | CAKE | 3.8B | 50M |
| 3 | POST | 12K | 340 | | 10 | TEAPOT | 30B | 390M |
| 4 | JARS | 95K | 2.2K | | 11 | LANTERN | 240B | 3.1B |
| 5 | FOUNT | 800K | 15K | | 12 | QUILT | 2T | 24B |
| 6 | SUN | 6.5M | 110K | | 13 | AURORA | 16T | 190B |

- Cost growth 1.16 per owned; purchase discounts multiply (BARGAIN 2%/lvl,
  DEEP POCKETS 3%/lvl, CRATER 5%/lvl).
- Doubling rungs at 10/20/40/80/120 owned → x2/x4/x8/x16/x32. ROOTS pulls each
  rung down by one level (min 4).
- A tier appears at 25% of its price in lifetime earnings. Seven rows visible,
  scrollable; unlock auto-scrolls to the newest row.
- SELF-STOCK buys the best-payback affordable row every 30→5s once bought.
- KITTY CREW gives +2%/lvl per owned cat (capped at 400 cats); OPEN SKY adds
  +2 kittens per BOX per level to that count.

## 3. Reset layers (5)

Each layer pays a currency for giving up the layer below; the currency multiplier
uses **lifetime earned**, not held, so spending never slows the cafe.

| Layer | Currency | Needs (below) | Payout | Multiplier | Charms |
|-------|----------|---------------|--------|------------|--------|
| 0 | YARN | 600M run fish | `floor(sqrt(run/20M))` | +10% / yarn | 15 |
| 1 | STARS | 14 yarn paid since | `floor(sqrt(src/4))` | +25% / star | 9 |
| 2 | BEANS | 4 stars | `floor(sqrt(src/2))` | +50% / bean | 5 |
| 3 | AURORA | 3 beans | `floor(sqrt(src/2))` | +100% / aurora | 4 |
| 4 | MOON | 25 aurora | `floor(sqrt(src/8))` | +150% / moon | 4 |

- Reset of layer N clears fish, all shop tiers, click upgrades, and all layers
  below N; it counts its payout as progress toward layer N+1.
- Yarn ladder awards hats at 1/5/15 lifetime yarn (beanie/crown/wizard) and
  equips each new one.
- GIFT BOX starts every reset with 2 tiers of each producer per level; HEAD START
  adds boxes.
- There is no sixth layer. After MOON the only further progression is the Hollow.

## 4. Permanent charms (37, 295 total levels)

`scr_upgrades.gml`: 5 tabs, one per layer, bought with that layer's held currency.
All are flat/incremental multipliers or automation; none are mutually exclusive
and all can eventually be maxed.

- **YARN (15):** SOFT PAWS (+1 tap), FISH SHARE (+1% of /s per tap), BARGAIN,
  BIG COMBO, SHARP CLAWS (crit), KITTY CREW, NIGHT SHIFT, LONG PARTY, HEAD START,
  SPARKLE MAG, HELPING HANDS (autotap), GOOD YARN (+10% reset payout), SELF-STOCK,
  TIP JAR (+5% service tips), LONG GLOW.
- **STARS (9):** STARLIGHT (+15% all), SHORTCUT (yarn gate -10%), GIFT BOX,
  COMET (crit multiplier), DEEP POCKETS, MORNING DEW, HALO, WISH (+20% stars),
  SPARKLE HANDS (auto-collect).
- **BEANS (5):** SPROUT (+25% all), ROOTS, CANOPY (offline cap), BLOOM (frenzy
  chance), TALL STALK (+25% beans).
- **AURORA (4):** GLOW (x2 fish), OPEN SKY, DAWN (+25% every layer payout),
  COSMOS (+50% all).
- **MOON (4):** MOONBEAM (+50% all), MOONLIT (offline), ORBIT (+20% layer payout),
  CRATER (cheaper furniture).

Presentation: five tab pills; each row has an icon, name, effect line, next cost,
and a gold progress strip. The strip is `up_progress()` = level/max (see §15).

## 5. Rooms (6)

Cosmetic rooms plus the café-only secret. Unlock by lifetime fish; ROOMS control
appears once a second room exists and can walk back to any unlocked room.

| # | Room | Lifetime fish | Notes |
|---|------|---------------|-------|
| 0 | COZY CORNER | 0 | Pantry wall / Hollow entrance only here |
| 1 | CAT GARDEN | 25K | butterflies, picket fence |
| 2 | ROOFTOP | 500K | sunset, skyline, string lights |
| 3 | CLOUD CAFE | 5M | floating island, pink sky |
| 4 | TEA HOUSE | 250M | shoji, lanterns, tatami, table |
| 5 | STAR LIBRARY | 25B | shelves, ladder, round window |

Every room now has a **12-rung mastery ladder** earned by tapping in that room.
Rungs mix rules with small multipliers: combo size, crit chance, treat interval,
bond gain, combo grace, and automatic petting at ranks 6/11/12. Auto-pet is a
cosmetic reward (one treat every eighth automatic pet), not a tap, so it cannot advance
mastery or bond. Rank 12 is 326,450 taps in one room; all six is 1.96M taps. The café entrance remains
the only mechanical room gate. Each room has its own primitives, ambient
particles and rug. The shop's CAFE button opens the service counter when unlocked.

## 6. Cats and staff

- Album: 24 cats, unlocked at lifetime fish thresholds 0 → 55M (roughly every
  1.5-2x). Each has a name, a one-line quirk, a coat colour (one of 8 paper-doll
  sprites) and a card. Album completion is a journal goal.
- **Bonds:** every cat has its own 12-rung ladder (20 → 8,200 bond). Taps feed the
  active companion; a tap in the cat's home room counts double, and room BOND
  rungs add up to +50%. The CATS card is also the companion picker. Rungs are  trait-specific: SUNNY tempo, NIGHT Hollow, COZY away, BUSY production, DREAMY
  crits, HUNGRY garden. Each table mixes rule changes with small rate boosts;
  BUSY rungs improve the staff match bonus, not only raw output.
- **Stories:** each of the 24 cats has a five-beat authored story in CATS. Beats
  pay bond floors, the middle beat is a two-way choice, and the completed branch
  leaves a keepsake that changes an existing system. See §21 for the full count.
- Staff: 4 stations (COUNTER tap value, OVEN café output, WINDOW away rate,
  CELLAR Hollow embers), 3 slots each = 12 slots. Slot 0 open immediately, slot 1
  at 8 cats, slot 2 at 18. One cat cannot hold two slots.
- Each cat has one of 6 quirks, 4 of which map to a station; a cat in its natural
  station gives double. Bonus is 2% + 0.4% per 6 album index.
- Cats on the floor (`obj_cat_mini`) are cosmetic; staff is the mechanical use.

## 7. Journal, goals, projects, orders, skills

All of this survives every reset and is independent of prestige.

- **8 chapters** (COZY BEGINNINGS → MOONLIGHT CAFE), **4 goals each = 32 goals**.
  A chapter unlocks when the previous has 3 of 4 claimed. Claim = 1 stamp.
- **24 projects** (3 per chapter), bought with fish + one material, each gives
  +5% to output, tap, or away rate depending on the slot column.
- **3 skills** (output/tap/away), 10 levels each; cost 1,2,...10 stamps each.
- **3 concurrent orders**, targets scale per chapter, pay materials + a stamp.
- Materials: SCRAPS (purchases), TREATS, DUST; also from sparkles, service and
  festivals. There is no material-specific explanation in the UI beyond labels.

## 8. Café counter (service)

- Unlocks at 1.2K lifetime fish. 9 guests, each with 3 dishes = **27 recipes**.
- Guest 0 is open at the start; later guests require both an album threshold and
  a total-served threshold (2,4,7,9,11,13,16,20).
- Pick 1 of 3 bases + 1 of 3 toppings and try. A wrong guess costs nothing; a
  correct half is recorded permanently (`known_base` / `known_topping`). A full
  match pays either fish (8s of rate, tip bonus) or 3 of each material.
- The counter is reachable from the shop's CAFE button; it is not a separate
  dock button. A guide page and a contextual tip point at it once.

## 9. Festivals

- Unlocked by earning the first MOON. **9 venues × 3 ranks = 27 challenges**.
- Each venue is gated by the previous venue having at least one rank.
- Fill 3 menu slots with **known** dishes (each dish can only be used once); two
  authored rules are checked: an exact count on one dimension and a minimum on
  another (base, topping, guest variety). Rules are generated as readable labels.
- Entry costs 2+rank of that venue's material; win stores a pending reward, then
  choose materials, 2×rank stamps, or rank moon currency. Progress survives resets.
- The venue names, materials and challenge tables are in `scr_festival.gml`.

## 10. Stickers and hats

- **24 stickers** with plain-English conditions (taps, combos, crits, cats, fish,
  zones, resets, each layer currency, festival, service, journal, night depth,
  relics). Checked a few times a second; earned forever; 2 pages of 12.
- Hats: beanie/crown/wizard from the yarn ladder, equipped in settings; purely
  cosmetic on the big cat. There is no hat for any other milestone.

## 11. The Hollow Hour (hidden layer)

Entrance: only the Cozy Corner pantry. Requires `earned.moon > 0` **and** at
least one festival rank. Not a button: a tall cupboard whose right door never
latches; the guide says "knock three times". Three clicks on it discover the
layer. `veil_door_here()` gates both art and input on `world.zone == 0`.

Content:
- **5 locations:** Cold Parlour (séance), Ash Garden (growing), Long Hall (doors),
  Tincture Cellar (brewing), Ninth Table (night run).
- **13 closings** (ordered deeds) each +1 blood and +2 permanent café gift;
  claiming one unlocks the next location per the `veil_loc_need` table.
- **20 Hollow charms** in 4 branches (Rite/Reach/Residue/Altar), 72 levels.
  Bought with embers, or blood for the Altar branch.
- **40 relics** in 5 sets of 8; up to 8 copies of each (320 copies). Set bonuses
  apply when relics are enthroned (3 slots + RELIQUARY).
- **6 curses**, cleansed with embers (cost rises with the number held); omens can
  add them.
- **Séance:** 4-6 seats (4 + case tier); some seats auto-revealed by KEEN EAR;
  hints cost whispers; wrong placements break rules and lose tries/nerve.
- **Ash Garden:** 6 base + 2/level plots (max 12); 3 seed kinds; real-time growth;
  blight; harvest yields 8 reagents.
- **Tincture Cellar:** 3 reagent slots, heat 1-3, 10 tinctures learned by trying;
  each drink is a timed buff.
- **Long Hall:** every run draws one of **six night modifiers** (THE QUIET, THE
  HUNGRY DARK, THE TILTED HOUR, THE LONG CORRIDOR, THE WAX MOON, THE UNBLINKING).
  Modifiers change door count (2-5), floor count (3 or 5), nerve, ember/whisper
  payout, relic chance and free peeks. The first run is always THE QUIET; later
  runs avoid immediately repeating the last modifier. Nerve 5+, peek costs
  whispers; correct doors pay embers/whispers (and sometimes relics), wrong doors
  cost nerve.
- **Ninth Table:** endless night; each solve advances depth, every 3rd depth costs
  nerve, depth 13 sets `ending` and grants relic 39, then continues scaling.
- **10 omens** with two-choice trade-offs on a 4-7 minute timer while inside.
- **Closings** are the only gate on location access; the layer never resets its
  collection. Mastery ranks per location from 1/3/6/10/16 deeds.
- Hollow time pays 10% of café rate into fish, so the café is never frozen.
- Entering the Hollow crossfades from the café loop to `snd_music_hollow`, a
  24-second dark ambient track (low drone, wind, distant bells, slow heartbeat);
  waking crossfades back. Muting still applies to both.

## 12. Presentation surfaces

- **Two canvases.** Room art is still authored at 480x270 and multiplied by 4 on
  screen. The interface is a separate native **1920x1080 GUI** (windowed at
  960x540 it is a clean 0.5 scale). Every player-facing surface uses real pixel
  numbers, the 32/18 two-role pixel type scale and the shared `dui_*`
  primitives in `scr_ui.gml` / `scr_veil_ui.gml`; nothing in them inherits the
  room canvas.
- Top bar: fish odometer, `/s`, combo pill, yarn count, total multiplier pill,
  frenzy badge. Native.
- Shop panel: 7 rows + scroll, affordability pulse, hover "next +/s" tooltip,
  doubling hairline, lock wash + padlock, CAFE button, dock
  (CATS/RESET/BOOST/MORE). Native, `x=1264..1888`, ten visible rows.
- Bottom-left goal strip: 760x148 at `(32,900)`, a persistent NEXT action, a
  two-line reason, a gold progress hairline, 48x48 `?` and X buttons. The panel
  body is display-only; only `?` (opens the matching guide page), X (hides) and
  the collapsed 56x56 `?` at `(32,992)` (restores) react. A 14-step grace after
  hiding stops the closing press from bouncing it open. It hides under a modal,
  tutorial or lesson card. Hidden state is saved.
- **Converted to the native canvas:** café HUD, shop rail, BOOST, journal/album
  (all tabs), goal strip, café lesson card, MORE/settings, 44-page manual,
  sticker sheets (2), reset card, counter, festival card, welcome-back card,
  the tutorial pill, the ROOMS rail and the room banner. The Hollow shell
  (header, stat plates, nav, footer) and all twelve of its player-facing
  surfaces are native too: map, Cold Parlour, Ash Garden, Long Hall, Tincture
  Cellar, Wall of Charms/rites, Cabinet/relics, Long Night, night intro, omen,
  blight and the Hollow lesson card.
- **Intentionally room-space, not UI:** the Hollow's 4x pixel-art backdrop is
  painted before `ui_canvas_reset()` restores the native matrix; it carries no
  text, plate or control. Café room art, floaters and particles are the same
  class. No player-facing interface remains on the 480-space canvas.
- Cards: album (6 tabs: CATS/GOALS/BUILD/ORDERS/STAFF/ERAS), prestige (5 layer cards),
  boost (5 tabs, 37 rows), service, festivals inside service, stickers (2 pages),
  settings (manual, mute, reduce motion, hat, stickers, reset).
- Feedback: floaters, screen shake (toggle), pop particles, toasts on stickers,
  zone banner, room flash, welcome-back card, milestone chime.
- All art is primitives except props/font/UI sprites; no external atlas.

## 13. What the player is actually told

### The guidance layer (built this pass)

- **Persistent goal strip.** Bottom-left, always available outside modals, drawn
  by `obj_guide` from `objective_goal()`. The goal is chosen from live state in
  this order: first taps, first purchases, the unplayed counter, the deepest
  reset currently affordable (pays/needs shown), staffing, the next Hollow
  closing or night depth, the festival circuit, the cheapest affordable charm, a
  claimable journal goal, an unvisited room, the next producer tier, maxing
  charms, then the endless night. It advances as the player acts; it is not a
  timer or a static checklist. The strip's small `?` opens the manual page that
  explains the chosen goal; the body itself is inert. The X collapses it to a
  56x56 `?` at `(32,992)`; that state is saved, and clicking that explicit `?`
  is the only way back. A click in the panel's old footprint, including the old
  X spot, does nothing while it is closed. This is native 1920 input, not a
  480-space hit box.
- **First-visit lesson cards.** One card at a time, queued by live gates, never a
  wall of popups. `offline` (60s+ away), `door` (Hollow discovered), each of the
  five Hollow locations when it opens, `relics`, `night`, `staff` (6 cats met),
  `festival` (first moon), each of the five reset layers at its frontier, plus
  one-page pointers for `counter`, `journal` and `rooms`. The first moon also
  adds the `era` card. A first bond rung adds `bond`; a first completed hall run
  adds `nightfall`. A layer that was reset before the card was met still gets
  one catch-up card later. 21 definitions in all.
- **Paged and dismissable.** 16 of the 21 cards hold two manual pages; the card
  shows `1/2`, BACK/NEXT, GUIDE, LATER and X. DONE/X marks it seen; LATER merely
  snoozes it for 30 seconds and never marks it seen; GUIDE opens the exact
  manual page and marks it seen. The card never pauses the simulation: the
  harness keeps the staff card open for 12 frames and confirms café income rose
  (`guide.card.nonblocking`, +28K in the run).
- **Re-readable.** The manual now has **44 pages** in four chapters
  (CAFE/PEOPLE/HOLLOW/MORE) with jump pills, page arrows and a native 1280x760
  card. Every lesson points into that one copy, so a correction lands in both
  the card and the manual.
- **Honest copy.** The eight wrong manual lines from the previous pass remain
  fixed. This pass removed semicolons from visible copy: the pixel font renders
  `;` as `?`, which made lessons look uncertain. The harness now fails on any
  semicolon in a guide page (`guide.punctuation`) and checks every state-shaped
  goal fits the strip in two un-clipped lines (`guide.objective.fit`).

### Tutorialised (shown at the moment it matters)

| System | How |
|--------|-----|
| Tapping | `obj_tutorial`: TAP THE CAT → KEEP TAPPING (3/8 clicks) |
| Shop | tutorial BUY A BOX; guide p.1; hover tooltip; affordable pulse; goal strip |
| Combo / frenzy / sparkles | guide p.0 and the frenzy badge; crit only through SHARP CLAWS and the LUCKY sticker |
| Boost | guide p.2; BOOST glows; progress strip; goal strip at the cheapest charm |
| Reset | RESET glows; prestige card lists need/payout; guide p.3; per-layer first-visit card; goal strip with live need |
| Counter | shop CAFE button; guide p.4; first-visit pointer; goal strip until first dish |
| Journal | guide p.6; goal strip when a goal is claimable |
| Staff | guide p.7; first-visit card at 6 cats; goal strip while no one is assigned |
| Festival | guide p.5; first-visit card after first moon; goal strip for the next venue |
| Rooms | ROOMS control, room banner; guide p.8/18; goal strip points at an unvisited room |
| Stickers/hats | guide p.19; toast on earn; hats cycle in settings |
| Offline | welcome-back card, then the `offline` first-visit card; guide p.20/35 has 50% base, 8h cap and boosts |
| Hollow entrance | guide p.8/9 ("knock three-times" instruction); first-visit `door` card; goal strip sends you back to the café wall |
| Hollow locations | one card per location when it first opens, plus the manual's rules page; goal strip tracks the next closing |

### Still silently assumed (honest gaps)

- The producer unlock rule (25% of price in lifetime fish). The doubling ladder
  is named on guide p.1, but the unlock rule is only inferred from the shop.
- Material sources, and which project column needs which material. The journal
  page names the columns but not where each material comes from.
- Guest unlock thresholds, and that a wrong counter dish costs nothing. The
  counter card says a try narrows the recipe, not the exact guest gates.
- Festival rank-reward choices (materials vs stamps vs moon). Entry cost and
  venue chaining are now on p.27 and the festival card.
- Hat thresholds (1/5/15 lifetime yarn).
- Hollow curse cleansing cost; relic-set bonuses are on p.15/32 but the exact
  cleanse price is not stated anywhere the player can reread.
- Auto-stock's 4x affordability rule and autoglean's range.
- Save behaviour and version; there is no export or cloud save.

### Guidance mechanics that exist (for future edits)

- `objective_goal()` and `guide_lessons()` in `scr_guide.gml`; the strip/card
  drawing and input in `obj_guide`.
- `guide_tip()` remains in `scr_ui.gml` as a legacy single-line helper and is
  exercised by the harness, but the visible UI now uses the persistent strip.
- Tutorial is strictly the first four actions and self-dismisses for returning
  players (clicks > 40 with no purchase).
- Lesson seen state is a pipe-delimited set in `global.G.guide.seen`, saved with
  the normal save and normalised for old saves.

### 13.1 Guidance verification (this machine)

`python3 tools/cafe_test.py --fresh --fullscreen` runs the real Windows build
under Wine in an isolated prefix and prints **99 PASS / 0 FAIL** (98 in-game
checks plus the one-line pre-boot source audit; the report ends with `DONE`).
Relevant checks:

- `guide.lessons`, `guide.paged`, `guide.later` — 21 definitions, 16 two-page
  cards, LATER leaves the lesson unseen and it resumes.
- `guide.goal.tap|buy|reset|hollow`, `guide.objective.fit` — the chooser follows
  real state and every sampled reason fits two 600px lines with no ellipsis.
- `layout.menus` — settings, manual, stickers, reset, counter and welcome cards
  and every interactive rect inside the 1920x1080 canvas.
- `guide.reset.trigger`, `guide.reset.caughtup` — the frontier is suppressed
  once a higher layer pays, but a reset that happened before its card was met
  still explains itself once; marking it seen removes it from the queue.
- `guide.triggers`, `guide.locations` — staff/moon/offline and the five Hollow
  location gates.
- `guide.punctuation`, `guide.wrap`, `guide.copy` — no semicolons, no page wider
  than its column, layer needs and staff slot numbers present.
- `guide.lesson.live`, `guide.lesson.reset.live`, `guide.lesson.festival.live`,
  `guide.lesson.hollow.live` — the real card controller picks the expected id
  from a realistic save state.
- `guide.card.nonblocking` — card stays open while fish rises.
- `guide.strip.toggle`, `guide.strip.collapsed` — closing the goal strip really
  removes it from the corner, leaves only the small `?`, and the state is
  saved; the collapsed `?` is shown in `ui_objective_hidden`.
- `guide.strip.clicks`, `guide.strip.closed` — the strip body and the space
  where it used to be are inert; only `?`/X react while open and only the
  explicit `?` reacts while closed. This is the regression the player hit:
  clicking the panel after closing it could reopen the guide card.
- `guide.objective.live` — the live strip is unobstructed and its chosen goal
  names a valid manual page/index; the failure detail includes the hidden,
  collapsed, modal, card, tutorial and welcome flags so a fixture race is
  diagnosable rather than guessed at.
- `ui.scale` — 3,912 native controls across the café surfaces, exercising all
  four heights (1,572 / 924 / 552 / 864), 16,259 texts, 0 off-scale or
  out-of-canvas calls.
- `layout.canvas`, `layout.type`, `layout.roomrail`, `layout.shop`,
  `layout.strip`, `layout.lessoncard`, `layout.journal`, `layout.boost` and
  `layout.menus` — the café's native regions and the 32/18 type roles.
- `tools/strip_click_probe.py` is the real-input counterpart: X11 clicks in the
  built game, with the save read back. It confirms `stats.clicks` rising when
  the open pantry overlaps the cat, `in_hollow` staying false, `guide.hidden`
  staying true through clicks on the old X/body, and the explicit `?` restoring
  the strip.
- `door.petpriority` — the cat's 56px petting circle owns clicks over the pantry,
  while the cupboard above the cat remains clickable.
- `music.hollow`, `music.cafe` — the playing instance's own length is read
  while inside the Hollow (24s, dark track) and after waking (42s, café track),
  so this proves which track is actually running, not merely which file exists.
- `ui.layout` (run before boot, plus `--self-test`) rejects text in a room
  `Draw_0`, legacy `ui_*` helpers, raw engine text outside the two native
  primitives, room-scale layout and any control sized with a literal height.
  The self-test feeds it a room-space `draw_text` and a 72px button and requires
  a failure, so a green audit is evidence rather than a vacuous pass.
- Screenshots `ui_objective`, `ui_objective_hidden`, `ui_lesson_staff`,
  `ui_lesson_reset`, `ui_lesson_festival`, `ui_lesson_hollow`, `ui_guide`,
  `ui_cats`, `ui_more`, `ui_stickers`, `ui_stickers2`, `ui_prestige`,
  `ui_counter`, `ui_festival` and `ui_staff` document the real rendered café
  surfaces; `cafetrace.txt` is the stage breadcrumb if the VM stalls.
- `ui_cats` is the new CATS capture: eight coat sprites, per-cat bond meters and
  the companion selection highlight.
- The Hollow's twelve native captures are `tools/shots/veil/veil_1_map`,
  `veil_2_parlour`, `veil_3_garden`, `veil_4_hall`, `veil_5_cellar`,
  `veil_6_rites`, `veil_7_relics`, `veil_8_night`, `veil_9_night_intro`,
  `veil_10_omen`, `veil_11_lesson` and `veil_12_blight`, all 1920x1080.
- `python3 tools/strip_click_probe.py` passes 5/5 with real X11 input: cat pet
  vs open pantry, strip stays collapsed through old-area clicks, explicit `?`
  restores it, the pantry still opens the Hollow, and WAKE returns to the café.

## 14. Content depth — measured

`tools/tune_layers.py` (constant tapping, optimal buying, no charms, no offline,
resets as soon as possible):

- first YARN 29.8 min
- first STARS 63.2 min
- first BEANS 99.4 min
- first AURORA 105.2 min
- first MOON 115.0 min (all five layers inside ~2 hours)
- 407 resets in that window; final multiplier ~6.6e8

`tools/tune_economy.py` (first-session pacing): first producer 3.0s, widest
purchase gap 94s, first prestige 20.3 min, 1h offline ≈ 30 min progress — PASS.

What that means:
- The authored critical path is short. The numbers above are a bot, but a human
  following the same loop reaches MOON in a long evening, not hundreds of hours.
- After MOON the only content is the festival circuit (27 challenges), the Hollow
  (13 closings, 5 minigames, 320 relic copies, endless night), and maxing 295
  charm levels. The Hollow is still hidden and repetitive, but the Long Hall now
  draws six night modifiers and the room/cat ladders give the late game a long
  measured climb; see §18 for the corrected 155.5h tap model and 217.3m Era seal
  time.
- The 24 five-beat cat stories are the first authored quest layer (§21). There
  is still no second production line, no NG+/season and no seasonal arc. A reason
  to reset a layer after its charms max is still missing.
- Rooms now change play through their 12-rung ladders; they are no longer only
  thresholds with new paint.

## 15. Known visual/presentation issues (this pass)

Fixed and verified this pass:
1. **Café entrance** — was a floating door with a stray pale seam and blob. Now a
   floor-standing pantry built from the room's timber palette, two doors, brass
   knobs, preserves shelf; the only tell is a dark unlatched seam and a cold
   thread that is nearly invisible at rest and surfaces on hover. No cracks, no
   pale blob, no glow.
2. **Boost icons** — each sprite was placed from its own origin, so art with
   different padding drifted row to row. Every icon now goes through
   `ui_icon_fit()` into the same 20x20 plate / 14x14 art box on one centre line.
3. **Boost progress strip** — the fill was computed separately from the level/max
   the row displays. It now comes from one function, `up_progress()` (level/max),
   and the bar uses that. All five tabs show a proportional gold fill; maxed rows
   show a full mint bar and "MAXED".
4. **Café-only wall** — the pantry is painted by `zone_cozy()` only; no other zone
   painter calls it, and `veil_door_here()` gates the object's draw and input on
   room 0. Tested in all 6 rooms, closed and open.
5. **Guide copy** — the manual contained eight factual errors: it said six guests
   (nine exist), that three festival ranks are needed to open the next venue (one
   is), that automation runs offline (the offline payout is a flat calculation),
   that the Hollow has its own save (it shares the one save), that the séance
   always seats six (4-6 by tier), that longer garden seeds need deeper rooms (all
   three are selectable from the start), that the night is three doors deep (it is
   endless), and that only embers buy Hollow charms (the Altar branch costs
   blood). All eight lines now match the code.
6. **Guidance visuals** — the café goal strip (760x148 at `(32,900)`) and both
   lesson cards are native 1920 surfaces (café 960x460, Hollow 900x520). The
   strip is two lines at most, ends at x=792 and never runs under the shop at
   x=1264. Captured in the `ui_lesson_*`/`ui_objective`/`ui_guide` and
   `veil_11_lesson` screenshots, not inferred from source.
7. **Goal strip obstruction** — the strip can now be closed with its X. Only a
   56x56 `?` at `(32,992)` remains in the lower-left; that explicit control is
   the only way back and the hidden flag is saved. The panel body is inert, so
   clicking the old strip rectangle or the old X spot cannot reopen anything.
   The collapsed frame is captured in `ui_objective_hidden`;
   `tools/strip_click_probe.py` repeats the click sequence with real X11 input
   and reads `guide.hidden` back.
8. **Door stealing cat clicks** — the pantry and cat overlap on screen. The
   cat's 56px petting circle now owns every click inside it; the cupboard only
   receives clicks around that circle. `door.petpriority` asserts both halves of
   that rule. The cat's old compensating no-pet rectangle was removed.
9. **Hollow score** — the Hollow no longer reuses `snd_music_cafe`. A new
   24-second dark ambient track (`snd_music_hollow`) uses a low D-minor drone,
   wind, distant bells and a slow heartbeat, and crossfades with the café track
   over about half a second. `music.hollow`/`music.cafe` assert the switch both
   ways and read the live instance's length (24s versus the café's 42s), so the
   check proves playback of a different track, not just that a WAV exists.
10. **Native menu pass** — MORE/settings, the 44-page manual, both sticker
   sheets, the reset card, counter/festival, and welcome-back are now native
   1920 layouts. `layout.menus` asserts every card and interactive rect is
   inside the canvas; `ui_more`, `ui_guide`, `ui_cats`, `ui_stickers`,
   `ui_stickers2`, `ui_prestige`, `ui_counter` and `ui_festival` are the real
   fullscreen captures.
11. **Hollow native pass** — the Hollow shell and all twelve player-facing
   surfaces now use the same native 1920 `dui_*` kit, spacing scale and 32/18
   type roles as the café, while keeping the dark palette, room art and audio.
   `layout.veil.map|garden|cellar|hall|parlour|rites|relics|night|lesson|shell|text`
   assert the cards and interactive rects inside the canvas; `ui.scale.hollow`
   reports 1,280 controls and 8,779 texts with 0 off-scale or out-of-canvas
   calls. The twelve `veil_*` captures at 1920x1080 are the visual evidence.

Still weak (for the next visual pass):
- The Hollow's room backdrop is still 4x pixel art by design; it contains no
  text or controls and sits behind the native shell. That is the only
  intentionally room-scale layer left.
- Activity backdrops can peek around a native card (the BOOST sign, the counter
  sign). They are decorative, not UI, but the contrast is visible at the
  card's edges.
- The manual page has a large calm area below four lines; it is intentional
  reading space, but a shorter card or a marginal illustration would tighten it.
- Hats only show on the big cat; staff cats and album cards do not reflect them.
- The room set is strong; the shop/HUD are consistent. The door was the outlier.

## 16. File map (where to change what)

| Concern | File |
|---------|------|
| Producers, costs, multipliers | `Clicky/scripts/scr_econ/scr_econ.gml` |
| Layers, reset rules, hats | `Clicky/scripts/scr_layers/scr_layers.gml` |
| Charms and all `up_*` effects | `Clicky/scripts/scr_upgrades/scr_upgrades.gml` |
| Album, journal, projects, orders, staff | `Clicky/scripts/scr_album/scr_album.gml` |
| Service recipes/guests | `Clicky/scripts/scr_service/scr_service.gml` + `obj_service` |
| Festivals | `Clicky/scripts/scr_festival/scr_festival.gml` |
| Stickers | `Clicky/scripts/scr_achieve/scr_achieve.gml` |
| Rooms and travel | `Clicky/scripts/scr_zones/scr_zones.gml` + `scr_zone_art` |
| Hollow state/rules | `Clicky/scripts/scr_veil_core/scr_veil_core.gml` |
| Hollow screens | `scr_veil_ui`, `scr_veil_seance`, `scr_veil_garden`, `scr_veil_hall`, `scr_veil_bench` |
| Guide pages/UI widgets | `Clicky/scripts/scr_ui/scr_ui.gml` |
| Music, sfx, crossfade | `Clicky/scripts/scr_audio/scr_audio.gml`; `sounds/snd_music_*` |
| Goal chooser, lesson queue, first-visit copy | `Clicky/scripts/scr_guide/scr_guide.gml` |
| Goal strip and lesson card drawing/input | `Clicky/objects/obj_guide/` |
| Save/load/migration | `Clicky/scripts/scr_save/scr_save.gml` |
| Tests and screenshots | `tools/cafe_test.py`, `tools/veil_test.py`, `tools/shoot.py` |

## 17. Highest-value next steps (from the gaps above)

1. **Guidance:** the persistent goal strip and the 21 first-visit lessons are
   built and verified. Remaining guidance work is small copy, not architecture:
   explain material sources/project columns, guest unlock gates, hat thresholds,
   festival rank-reward choices, curse cleanse cost, and auto-stock's 4x buffer.
2. **Depth:** the room and cat ladders are now the long-tail sinks; the next
   lever is a repeatable Hollow depth/relic ladder (or a seasonal prestige) so
   the 155.5h tap ladder is not the only post-MOON mountaintop. A reason to
   re-enter lower layers after their charms max is still missing.
3. **Content variety:** cat-specific requests/quests, more room-specific
   decisions, festival modifiers, and Hollow room events. These reuse existing
   systems instead of adding another currency.
4. **Presentation:** every café and Hollow player-facing surface is now native
   1920 and verified by `layout.menus` / `layout.veil.*` / `ui.scale*`. The
   remaining visual work is smaller: show equipped hats on staff/album cards,
   and review the decorative activity-backdrop seams around native cards. There
   is no remaining large-type screen.

Do not add new currencies before fixing how the existing five are explained.
Do not call the visual pass complete until every café screen and every Hollow
room has been reviewed in the running build, not just the six guidance shots.

## 18. Long-tail pass (2026-11-24)

Two repeatable systems were added this pass. Both are fully wired into save,
guidance, input and the tuning model; neither adds a currency.

### 18.1 Per-room mastery (12 rungs, 6 rooms)

- Points: one per tap in that room; the Era's featured room still counts double.
- Thresholds: 150, 500, 1.2K, 2.6K, 4.8K, 8.2K, 13.5K, 21.5K, 33K, 50K,
  76K, 115K. Total 326,450 taps per room, 1.96M for all six.
- Rungs mix rules and small multipliers: COMBO +1/+2, CRIT +1%, TREAT EVERY
  12/8, BOND +25%, GRACE +100MS, AUTO-PET every 4s/3s/2s. Auto-pet is cosmetic
  and leaves one treat every eighth automatic pet; it does not call `tap()`, so
  it cannot advance room mastery or cat bond. Every level also adds +1%
  permanent output.
- Live effects (2026-11-24): CRIT rungs add +1% each to the real tap crit
  roll (still capped at 75%); TREAT rungs add a separate treat payline every 12
  (rank 3) or 8 (rank 10) taps, on top of the universal tenth-tap treat; COMBO
  adds the next tap's combo, BOND stretches every bond point, and GRACE widens
  the combo window. The harness now drives `tap()`, `cat_bond_add()` and
  `auto_pet()` for `room.combo.effect`, `room.crit.effect`, `room.treat.effect`,
  `room.bond.effect`, `room.grace.effect` and `room.autopet.noprogress`, then
  `room.rung.contract` fails if any kind in `room_rung()` has no passing probe.
- UI: the ROOMS panel row is 64px, shows `Lv n/12`, `NEXT: <rung>` and a gold
  meter; the footer names the active companion and its bond. No second panel.

### 18.2 Per-cat bonds (12 rungs, 24 cats)

- Points: every tap feeds the active companion; a tap in the cat's home room
  (cat index mod 6) counts double; room BOND rungs add up to +50% more.
- Thresholds: 20, 60, 140, 280, 500, 850, 1.35K, 2.05K, 3K, 4.3K, 6K, 8.2K.
  Total 26,750 bond per cat, 642K across the album (321K if every cat is trained
  at home).
- Each trait has its own table: SUNNY tempo, NIGHT Hollow nerve/embers/peeks,
  COZY away/cap, BUSY staff/match, DREAMY crits/frenzy, HUNGRY treats/growth/
  harvest. Each table mixes rule changes with percentage filler; only one
  companion's rungs are live. The BUSY match rungs raise the natural-station
  multiplier from 2x toward 3.25x, so they are not only raw staff/output.
- UI: the CATS card shows `BOND n/12`, a gold bar and `WITH YOU`; clicking an
  unlocked cat makes it the companion and saves immediately. Hover names the
  next rung. The ROOMS footer repeats the active bond.

### 18.3 Procedural Hollow nights

- Six modifiers, drawn at `veil_hall_start`: THE QUIET (one fewer door, +1
  nerve), THE HUNGRY DARK (one more door, embers +25%), THE TILTED HOUR (nerve
  -1, whispers +30%), THE LONG CORRIDOR (5 floors, relic chance +4%), THE WAX
  MOON (embers +50%, nerve -1), THE UNBLINKING (5 doors, no free peek).
- Floors are 3 or 5; doors are 2-5 (base `3 + THREE KEYS` plus the modifier,
  clamped). The first run is always THE QUIET; later runs pick from the other
  five nights, never the one just played. Start screen and run panel name the
  night and show its actual floor/door count.
- Harness: `hall.night.mod` asserts all six modifiers, including THE
  UNBLINKING's five doors and no free peek; `hall.night.repeat` draws 200 times
  and proves the picker never repeats the night just played; `hall.night.five`
  plays THE LONG CORRIDOR to floor 5, checks blood and stats, then restores the
  save state. The 12 Hollow screenshots include the run panel with `NIGHT:` and
  the dynamic floor counter.

### 18.4 Guidance additions

- New lessons: `bond` (first cat rung) and `nightfall` (first completed hall
  run). The existing `rooms` lesson is now two pages and includes the rung copy.
- Manual pages 41 (`CAT BONDS`) and 42 (`HOLLOW NIGHTS`); page 40 states the
  twelve thresholds and the cosmetic auto-pet/treat rule. Page 13 no longer
  claims the hall is always three doors; it says the last floor asks for 2 nerve.
- Late-game objective: once the short-term unlocks are exhausted (6+ cats, 2+
  rooms), the strip points at the active cat's next bond rung, then at an
  unfinished room's next rung. The reason states that home-room taps count double.

### 18.5 Measured pacing (actual output of `tools/tune_layers.py`)

- `tune_layers.py` now parses `room_mastery_steps()` and `cat_bond_steps()`
  from the runtime GML, plus the cat count from `album_init()`; there is no
  second hardcoded ladder table to drift.
- First MOON: 115.0m (unchanged; ladders are post-MOON by design).
- All six Era chapters sealed: 217.3m (`+102.3m` after the first moon).
- Room ladders: 1,958,700 taps = 155.5h at 3.5 taps/s.
- Cat bonds: 642,000 raw, 321,000 with every cat at home. Those points accrue on
  the same taps as room mastery; they do not add a second 25.5h.
- Combined ladder: **1,958,700 taps = 155.5h** continuous tapping. The 321,000
  home-bond points fit inside the six-room stream, so the room ladder is the
  floor, not `1.96M + 321k`; the no-home-bond floor is the same 155.5h here.
- This is a material increase from the previous 115-minute critical path, but it
  is still not “hundreds of hours” in the strict plural sense. It is a tap model,
  not a playtest. The next lever is a repeatable Hollow depth/relic ladder or a
  seasonal prestige; the procedural nights add replay variety but have no fixed
  completion counter to model.

### 18.6 What is verified and what is not

Verified on this machine (final build, 2026-11-24 18:33):
- GML compile (VM) and Windows target build are clean.
- `cafe_test.py --fresh --fullscreen`: 106 in-game PASS / 0 FAIL, 35 fullscreen
  captures, DONE marker, layout audit PASS. New room checks:
  `room.combo.effect` (base 1, rank 1 -> 2), `room.bond.effect` (base 2.0,
  rank 4 -> 2.5), `room.grace.effect` (930ms tap: rank 0 resets, rank 6 keeps
  combo), plus the existing crit/treat and auto-pet checks. New contracts:
  `room.rung.contract` (6/6 kinds probed) and `cat.rung.contract` (21 kinds).
- `ui_layout_audit.py`: PASS - 15 native GUI surfaces, 9 room-art surfaces.
- `veil_test.py 1 --fresh --fullscreen`: 52 PASS / 0 FAIL, 12 captures at
  1920x1080. New `veil.mastery.map` (L1=solves L2=harvests L3=halls L4=brews
  L5=night_best, best includes the Ninth Table) and `veil.mastery.effect`
  (Hall nerve +2, Cellar find +0.02, Night ember +0.05). Phase 2 adds 8 save
  checks, all PASS.
- `strip_click_probe.py`: 5/5 PASS on the final binary: cat pet vs open door,
  strip body inert, X hides, old area inert while hidden, explicit `?` restores,
  pantry still opens, WAKE returns to the café.
- `tune_layers.py` output quoted above is unchanged; this pass changed no
  economy or ladder thresholds.

Hollow location mastery (fixed 2026-11-24):
- One source: `veil_mastery_value()` counts Parlour `solves`, Garden `harvests`,
  Long Hall `halls`, Cellar `brews`, Ninth Table `night_best`. `veil_mastery_rank()`
  turns that value into the map pips and every consumer calls the same rank/value;
  `veil_mastery_best()` now includes the Ninth Table, and `veil_ember_mult()` reads
  `veil_mastery_value(5)` instead of duplicating `night_best`.
- Old saves need no count migration: location progress is derived from the existing
  activity stats, never stored per door. Every solve/harvest/hall/brew/night depth
  is preserved and the corrected rank appears immediately. The old
  `occult.mastery` array is legacy and unread.
- The harness proves both directions: the map check sets each stat alone and
  expects rank 2 at value 3; the effect check sets three halls/brews (Hall nerve
  +2, Cellar find +0.02) and night depth 10 (ember factor +0.05).

Relic copy (fixed 2026-11-24):
- Manual page 32 now reads: `Forty relics, five sets of 8.` / `Complete 8:
  +5% cafe, +1 blood.` / `ENTHRONE 3. RELIQUARY +1.` / `Sets: embers, whispers,
  growth,` / `nerve, finds. Duplicates stack.` The old `A full set` line
  conflated the completion gift with the enthroned-set effects. The sweep was
  imprecise that no set bonus pays +5% cafe +1 blood: `veil_relic_grant()` does
  pay exactly that when a set reaches 8 copies. The page now states both facts
  separately, and `guide.wrap` still passes at 5 lines / 204px.

Reward-consumer guard (new this pass):
- `room.rung.contract` compares every kind advertised by `room_rung()` with the
  effect probes that actually moved `tap()`/`cat_bond_add()`; a new kind without
  a passing probe fails by name.
- `cat.rung.contract` sets each of the six traits to max bond and asks the same
  helpers gameplay asks; every advertised kind (21) must return a non-neutral
  value, so a table-only kind fails.
- `veil.mastery.map` / `veil.mastery.effect` are the location-side guard: the
  displayed rank and the consumer must both come from the same activity.

Not verified / deliberately not added:
- No human playtest of 155.5h; the number is a constant-tap model, not a
  playtest.
- Procedural nights vary the Hall only; the other four Hollow locations still
  have fixed rules and no run modifier.
- Cat stories now supply per-cat authored goals; room rungs are still ladders,
  not quests.
- No alternate production line, NG+, seasons or seasonal narrative arc yet.

## 19. Playtest fixes (2026-11-24)

Driven as a user through the built 960x540 window under Wine, with X11 clicks.

1. **STICKERS opened underneath MORE.** The settings card created the sticker
   sheet at the same GUI depth it occupied, so the sheet was drawn behind the
   live settings card and both screens competed for the pointer. The sheet is
   now a child screen at `-10002`, and `obj_settings` yields input while
   `obj_stickers` exists. Real path verified: MORE -> STICKERS -> X returns to
   MORE (`tools/shots/playtest/71_more.png`, `72_stickers_above.png`,
   `73_back_to_more.png`).
2. **The tutorial bubble drew through modals.** `TAP THE CAT` / `BUY A BOX`
   remained visible beside the welcome card, MORE and the lesson card. `obj_hud`
   now gates the hint on `!ui_modal_open()`. The same captures show the hint
   gone while MORE is open.

Probed without further fixes: fresh start, rapid petting, one-row and bulk
purchases, album tabs, BOOST, manual paging, motion/music/sound toggles, START
OVER (reset lands, settings survive) and a buy followed by Alt+F4 and relaunch
(the purchase survived). No new game logic or content was added.

## 20. Sprite pivots: kittens and the prestige yarn (2026-11-24)

The turn artifact was a sprite-origin bug, not the walk art. A flipped sprite
pivots on its origin, so a 22px kitten with xorigin 0 swings its whole body
sideways when `image_xscale` changes to -1.

- All **24 kitten sprites** (8 coats x idle/walk/happy) now use
  `xorigin 11, yorigin 20` on a 22x20 canvas: horizontal body centre and the
ground line. The cat stays on the same floor spot when it turns; only the tail
and face swap. The big-cat sprites stay top-left because `obj_cat_big/Draw_0`
computes its own centred draw box from width/height; changing their origin too
would double-offset the pet.
- **`spr_ui_yarn_icon`** is 16x16 and now uses xorigin/yorigin 8. The prestige
  animation rotates the ball around its middle instead of orbiting its corner.
  The HUD icon was re-anchored to the same visual edge, and the prestige payout
  icon is offset by half its scaled width so its left edge does not move.
- The harness now asserts both invariants in `sprite.pivots`: all 24 kitten
  sprites must be bottom-centre, and the yarn icon must be exactly half its
  width/height. A later art or import pass that resets an origin fails the same
  suite as a gameplay error.

Evidence from the final Windows build:
- `tools/shots/ui/ui_kitten_right.png` and `ui_kitten_left.png`: same room, same
  body position, flipped face/tail. `tools/shots/audit/kitten_turn_pair.png`
  crops both around the body centre line.
- `tools/shots/audit/yarn_spin.png` (full card) and `yarn_spin_crop.png`
  (close-up): a mid-spin frame at 30 degrees; the ball is centred inside the
  coral halo rather than swinging around it.
- `cafe_test.py --fresh --fullscreen`: **107 PASS / 0 FAIL**, including
  `sprite.pivots`; 38 fullscreen captures. `veil_test.py 1`: 52 PASS / 0 FAIL.

## 21. Cat story arcs (2026-11-24)

The first authored, non-numeric long tail. Every cat now has a story made of
real actions in systems that already exist, not a second currency or a ladder.

### 21.1 What exists

- **24 arcs**, one per album cat, **five beats each = 120 authored beats**.
- **24 two-way choices**, one per arc, at the middle beat: **48 branch
  outcomes**. Each branch has its own next ask, closing line and keepsake.
- **120 asks**, all fulfilled through existing play: taps, shop rows, gold
  sparkles, critical taps, counter dishes, journal goals/projects, resets,
  festival ranks, Hollow deeds, night depth, staff assignment and room mastery.
- **48 keepsakes** across 9 effect families: extra treats on taps/crits/
  sparkles/automatic pets, extra counter materials, an extra Ash Garden bed,
  extra Long Hall nerve, extra Ninth Table nerve, and a festival-entry
  discount. Effects are additive rules, not percentage bumps.
- Examples: Mochi's dripping sink (leave it dripping -> tap treats; fix it ->
  sparkle treats), Biscuit's warm laptop (share the warmth vs close the lid),
  Pepper's red dot (keep chasing vs show her the hand), Bean's garden bell,
  Star's night lamp, Big Boss's ledger (sign for the cafe vs yourself).

### 21.2 State and ownership

- `scr_cat_arc_content` is content only: 24 data records, helper constructors,
  no state and no drawing.
- `scr_cat_arcs` owns `global.G.arcs` (four 24-slot arrays: step, branch, done,
  base), all progress/claim/branch/reward queries, and the nine reward
  consumers. `arc_defaults()` is the only new save default;
  `arc_normalize()` is additive and has no `SAVE_VERSION` migration. An old
  save with no `arcs` key keeps every existing field and receives the default
  arrays; a malformed partial array is resized and clamped.
- Bond awards go through `bond_award_floor()`, owned by the album, so a story
  cannot lower a player's existing bond. Every completed beat sets a floor:
  +2/+4/+6/+8/+12 rungs, ending at master. Tap-fed bond still works.
- UI: `obj_cat_arc` is one card spawned from the CATS album; the album's only
  additions are a small top-right `STORY`/`n/5`/`KEPT` label and its hit box.
  It shows the portrait, bond meter, five pips, the current ask with live
  progress, a two-button choice, or the completed keepsake and branch echo.

### 21.3 What the player does

1. Open CATS and click the `STORY` corner of an unlocked cat.
2. Complete the current ask through its named system (tap the cat, buy a shop
   row, serve a dish, catch a sparkle, etc.). Progress is measured from the
   moment that beat opened, so it never asks for lifetime totals.
3. Claim the beat. Bond rises to that rung; the next beat opens.
4. On the middle beat, choose one of two paths. The next ask, the closing text
   and the keepsake change.
5. Finish the fifth beat to earn the keepsake and master that cat's bond. The
   keepsake's effect is live immediately in the named system.

### 21.4 Verification (this build)

- GML compile and Windows target build clean.
- `cafe_test.py --fresh`: **all checks PASS**, including `story.merge` (a save
  with no `arcs` key gets defaults), `story.count` (24 arcs x five beats),
  `story.choice`, `story.choice.gate` (choice cannot be claimed as a normal
  beat), `story.branch.a`, `story.finish.a/b/more` (four arcs completed in one
  boot through the real state machine), `story.bond` (four cats reach rank 12),
  `story.keepsake.treats` (tap treats), `story.keepsake.wired` (service
  materials + garden bed + `veil_plot_count()`), and `story.shape` (all 24 arcs
  have five beats, both branch goals, and a reward).
- `tools/shots/ui/ui_cat_arc.png`, `ui_cat_arc_choice.png` and
  `ui_cat_arc_done.png` are captures of the actual card at step 1, the branch
  beat, and the completed keepsake. `ui_cats.png` shows the story label on the
  album cards without covering `WITH YOU`.
- `veil_test.py 1 --fresh`: 52 PASS / 0 FAIL; phase 2 save checks PASS.
- **Real-input check (X11, 960x540, final build):** a separate probe started the
  Windows build with an old-shaped save (no `arcs` key), clicked CATS -> the
  story label -> the card, tapped the cat, claimed beats, chose `FIX THE DRIP`,
  bought rows, and finished the final beat. The game's save afterwards reads
  `arc[0].step=5, branch=1, done=1, bond[0]=8200`, and `05_done.png` shows the
  B-branch keepsake. The same probe needed `bond` in its pre-seen lessons,
  because the first arc beat can legitimately trigger the existing CAT BONDS
  lesson; that is the existing guidance system, not a story error.
- Remaining: no human has read all 120 beats in order; the branch rewards are
  verified as data and through the real claim API and one real branch, not every
  one through a played tap. The next content pass should extend arcs into
  room/festival stories and add a second choice where the effect changes a run,
  not only a treat/material payline.
