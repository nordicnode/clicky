# UI structure

The interface has two canvases, and one owner per concern.

## Canvases

- **Room art** is the 480x270 pixel canvas. `obj_bg/Draw_0` and the room-space
  actors draw there. Room Draw events contain no text and no controls.
- **Interface** is the native 1920x1080 GUI. Every player-facing card, label,
  control and overlay draws there through `dui_*`. `tools/ui_layout_audit.py`
  enforces this.

## Ownership

| Piece | Owner |
|---|---|
| Type and spacing tokens, `dui_*` primitives, screen layout definitions | `scripts/scr_ui` |
| Card registry, modal predicate, card stacking depth, card creation | `scripts/scr_screens` |
| Persistent café furniture: top bar, room rail, room nameplate | `objects/obj_hud` |
| First-run tutorial hint (state **and** native draw) | `objects/obj_tutorial` |
| Sticker toast (state **and** native draw) | `objects/obj_toast` |
| Floating gains (state **and** native draw) | `objects/obj_floater` |
| Settings, manual and reset card | `objects/obj_settings` |
| Individual card contents and commands | the card's own object |
| Goal strip, lesson cards, guide copy and progression | `scripts/scr_guide` |

`obj_hud` no longer draws another object's state. If an object owns state, it
owns its native draw event too.

## Card screens

A **card** is a screen that dims the room, owns the pointer and pauses ambient
overlays. The Hollow is a destination, not a card.

- The one registry is `ui_cards()` in `scr_screens`. Adding a card screen means
  adding its object there once.
- Open cards only through `ui_card_spawn(obj)`. It assigns the next depth above
  the current stack; callers never pass `-10000`-style values.
- `ui_card_open()` means "a café card is open". `ui_modal_open()` also includes
  the Hollow and is the predicate for room/world input and HUD suppression.
- `guide_strip_hidden()` and `obj_guide` use `ui_card_open()`, not their own
  list. The old `guide_ui_modal()` wrapper is gone.

The live instances are the stack: `ui_card_depth()` counts them when the next
card opens. A parent card yields input while its child exists (settings while
stickers is open; any activity card while its help settings card is open).

Back-to-front at rest:

```
welcome 940       (the one card that stays behind the HUD; drawn first)
HUD 800
toast 40
floating gains -80
tutorial -5000
cards     UI_CARD_Z - open card count
Hollow    -10000
guide     -11000   (always-on goal strip / lessons; drawn last)
```

Lower depth draws later. Normal cards draw above the HUD and below the guide;
the offline welcome card is deliberately behind the HUD so the top bar stays
readable while the gain is explained.

## Rules for later passes

1. A new card gets one registry entry and is spawned through `ui_card_spawn`.
2. A new overlay's state object also owns its `Draw_64`; do not add another
   `with (obj_x)` block to `obj_hud`.
3. World input uses `ui_card_open()`/`ui_modal_open()` plus the specific guide
   guard; do not copy the card object list.
4. Native UI text uses the two type roles and named control heights from
   `scr_ui`; no room-scale coordinates except the documented world actors.
