/// @description native immediate-mode UI kit and its one layout scale
///
/// Player-facing text uses exactly two roles: a 32px display face and an 18px
/// reading face. Every control height and every gutter comes from this table;
/// a screen may not invent a third size. The primitives below reject an
/// off-table control at runtime, and tools/ui_layout_audit.py rejects a
/// literal height in a control call at build-check time.
#macro UI_TYPE_TITLE_PX 32
#macro UI_TYPE_BODY_PX  18
// Heights are all multiples of 4, so rows and baselines share one grid.
#macro UI_H_CONTROL     40    // square icon buttons, arrows, close
#macro UI_H_ROW         44    // tabs, selection pills, list rows
#macro UI_H_CTA         56    // the one primary action on a card
#macro UI_H_NAV         64    // persistent navigation bar, room nameplate
#macro UI_W_CONTROL     140
#macro UI_W_SQUARE      40
#macro UI_SPACE_XS      8
#macro UI_SPACE_S       16
#macro UI_SPACE_M       24
#macro UI_SPACE_L       40

// ------------------------------------------------------------ scale audit
// The harness reads these counters. A control whose height is not one of the
// four documented sizes is recorded here and fails the café suite; a screen
// that is never opened still fails the source audit if it hardcodes a height.
function ui_audit_reset() {
    global.ui_fail = [];
    global.ui_controls = 0;
    global.ui_h40 = 0;
    global.ui_h44 = 0;
    global.ui_h56 = 0;
    global.ui_h64 = 0;
    global.ui_texts = 0;
    global.ui_fits = 0;
}

function ui_audit_fail(_what) {
    if (!variable_global_exists("ui_fail") || !is_array(global.ui_fail)) {
        global.ui_fail = [];
    }
    if (array_length(global.ui_fail) < 40) array_push(global.ui_fail, _what);
}

function ui_audit_font(_font) {
    if (_font != global.fnt_big && _font != global.fnt_small) {
        ui_audit_fail("text font is not a type-scale role");
    }
}

function ui_audit_native() {
    var _m = matrix_get(matrix_world);
    var _id = matrix_build_identity();
    for (var _i = 0; _i < array_length(_m); _i++) {
        if (abs(_m[_i] - _id[_i]) > 0.0001) {
            ui_audit_fail("UI drawn through a non-native matrix");
            return;
        }
    }
}

function ui_audit_control(_kind, _x, _y, _w, _h) {
    global.ui_controls += 1;
    if (_h == UI_H_CONTROL) global.ui_h40 += 1;
    else if (_h == UI_H_ROW) global.ui_h44 += 1;
    else if (_h == UI_H_CTA) global.ui_h56 += 1;
    else if (_h == UI_H_NAV) global.ui_h64 += 1;
    else ui_audit_fail(_kind + " off-scale height " + string(_h));
    if (_w <= 0 || _x < 0 || _y < 0 || _x + _w > UI_W || _y + _h > UI_H) {
        ui_audit_fail(_kind + " outside the native canvas");
    }
    ui_audit_native();
}

function ui_audit_text(_x, _y) {
    global.ui_texts += 1;
    if (_x < 0 || _y < 0 || _x > UI_W || _y > UI_H) {
        ui_audit_fail("text outside the native canvas");
    }
    ui_audit_native();
}

/// Story cards pass the line they are about to draw and its column width. The
/// check runs after fitting, so a wrong width or a helper regression fails the
/// normal UI scale suite instead of shipping a clipped line.
function ui_audit_text_fit(_drawn, _font, _maxw, _src) {
    global.ui_fits += 1;
    draw_set_font(_font);
    var _w = string_width(_drawn) * UI_S;
    if (_w > _maxw + 1) {
        ui_audit_fail("story text overflow " + string(round(_w)) + ">"
                      + string(round(_maxw)) + ": " + string(_src));
    }
}

function ui_audit_clean() {
    return !variable_global_exists("ui_fail") || array_length(global.ui_fail) == 0;
}

function ui_audit_report() {
    return "controls=" + string(global.ui_controls)
         + " heights=" + string(global.ui_h40) + "/" + string(global.ui_h44)
         + "/" + string(global.ui_h56) + "/" + string(global.ui_h64)
         + " text=" + string(global.ui_texts)
         + " fit=" + string(global.ui_fits)
         + " fail=" + string(ui_audit_clean() ? 0 : array_length(global.ui_fail));
}

/// Full-screen illustrated backdrop for the activity screens. This is room
/// art, not interface: it deliberately contains no text, plate or control, so
/// nothing here can read as a giant button behind a native card.
function ui_activity_scene(_kind, _fade) {
    draw_set_alpha(1);
    draw_set_colour(P_CREAM);
    draw_rectangle(0, 0, GAME_W, GAME_H, false);
    draw_set_colour(_kind == 1 ? P_SKY : (_kind == 3 ? P_MINT : P_PINK));
    draw_rectangle(0, 0, GAME_W, 185, false);
    draw_set_colour(P_WOOD);
    draw_rectangle(0, 184, GAME_W, 190, false);
    draw_set_colour(P_BROWN);
    draw_rectangle(0, 190, GAME_W, GAME_H, false);
    for (var _i = 0; _i < 8; _i++) {
        draw_set_colour((_i mod 2) == 0 ? P_WOOD : P_BROWN);
        draw_rectangle(_i * 64, 192, _i * 64 + 63, GAME_H, false);
    }
    // Window, curtains and bunting give the activities their own place.
    draw_set_colour(P_WOOD);
    draw_roundrect_ext(301, 31, 461, 163, 9, 9, false);
    draw_set_colour(_kind == 1 ? P_SKY : P_CREAM);
    draw_roundrect_ext(306, 36, 456, 158, 6, 6, false);
    draw_set_colour(P_WHITE);
    draw_rectangle(379, 37, 383, 158, false);
    draw_rectangle(307, 93, 455, 97, false);
    draw_set_colour(P_CORAL);
    draw_rectangle(305, 32, 456, 37, false);
    for (var _i = 0; _i < 6; _i++) {
        draw_set_colour((_i mod 2) == 0 ? P_CORAL : P_GOLD);
        var _x = 310 + _i * 24;
        draw_triangle(_x, 38, _x + 18, 38, _x + 9, 50, false);
    }
    // Back shelf supports the section-specific ornament; the counter supports
    // the cats and food. Coordinates below use the visible pixel bounds.
    draw_set_colour(P_WOOD);
    draw_rectangle(419, 89, 453, 92, false);
    var _prop = spr_prop_mug, _left = 3, _top = 8, _right = 20, _bottom = 20;
    if (_kind == 1) { _prop = spr_prop_lantern; _top = 1; _right = 18; }
    else if (_kind == 2) { _prop = spr_prop_jars; _left = 1; _top = 6; _right = 19; }
    else if (_kind == 3) { _prop = spr_prop_yarnpit; _left = 2; _top = 5; }
    else if (_kind == 4) { _prop = spr_prop_aurora; _left = 1; _top = 2; _bottom = 18; }
    var _prop_w = _right - _left, _prop_h = _bottom - _top;
    draw_sprite_part_ext(_prop, 0, _left, _top, _prop_w, _prop_h,
                         436 - _prop_w * 0.5, 89 - _prop_h, 1, 1, c_white, 1);
    if (_kind == 1) draw_sprite_stretched(spr_fx_sparkle, 0, 345, 61, 16, 16);

    draw_set_colour(P_WOOD);
    draw_roundrect_ext(298, 181, 465, 194, 5, 5, false);
    draw_rectangle(310, 194, 318, 225, false);
    draw_rectangle(446, 194, 454, 225, false);

    var _cats = [spr_cat_tabby_idle, spr_cat_calico_idle, spr_cat_ginger_idle,
                 spr_cat_grey_idle, spr_cat_mint_idle, spr_cat_tuxedo_idle];
    var _cat = 0;
    if (_kind == 0) _cat = global.G.service.guest mod 6;
    else if (_kind == 1) _cat = 2;
    else if (_kind == 2) _cat = 1;
    else if (_kind == 3) _cat = 4;
    else _cat = 5;
    var _frame = global.G.settings.reduce_motion ? 0 : floor(global.time * 2) mod 4;
    var _cat_top = _frame == 2 ? 5 : (_frame == 3 ? 4 : 3);
    var _cat_bottom = _frame == 2 ? 20 : 19;
    var _cat_h = _cat_bottom - _cat_top;
    draw_sprite_part_ext(_cats[_cat], _frame, 3, _cat_top, 13, _cat_h,
                         344, 181 - _cat_h * 3, 3, 3, c_white, 1);
    draw_sprite_part_ext(_cats[(_cat + 1) mod 6], _frame, 3, _cat_top, 13, _cat_h,
                         425, 181 - _cat_h * 2, 2, 2, c_white, 1);
    draw_sprite_part_ext(spr_prop_teapot, 0, 1, 5, 19, 15, 311, 166, 1, 1, c_white, 1);
    draw_sprite_part_ext(spr_prop_cake, 0, 3, 2, 15, 18, 397, 163, 1, 1, c_white, 1);

    // A blank chalkboard is scenery. It has a rim, a chalk rail and two bits
    // of chalk, but no words: the native card above owns every label.
    draw_set_colour(P_WOOD);
    draw_roundrect_ext(296, 221, 466, 257, 6, 6, false);
    draw_set_colour(P_INK);
    draw_roundrect_ext(301, 226, 461, 252, 4, 4, false);
    draw_set_colour(P_BROWN);
    draw_rectangle(310, 247, 452, 249, false);
    draw_set_colour(P_CREAM);
    draw_rectangle(314, 241, 330, 243, false);
    draw_set_colour(P_PINK);
    draw_rectangle(424, 241, 444, 243, false);
    draw_set_alpha(_fade);
}

/// The largest whole-number scale that fits the display. Integer only, because
/// a 480px canvas shown at 2.6x is mush, and this game is nothing but pixels.
function window_best_scale() {
    var _dw = display_get_width();
    var _dh = display_get_height();
    var _s = min(floor(_dw / GAME_W), floor(_dh / GAME_H));
    return clamp(_s, 1, 6);
}

/// A sticker: a round badge with an icon scaled to fit inside it.
function sticker_badge(_x, _y, _size, _spr, _alpha) {
    if (_alpha == undefined) _alpha = 1;
    draw_set_alpha(_alpha);
    draw_set_colour(P_INK);
    draw_circle(_x + _size * 0.5, _y + _size * 0.5, _size * 0.5 + 1, false);
    draw_set_colour(P_CREAM);
    draw_circle(_x + _size * 0.5, _y + _size * 0.5, _size * 0.5, false);
    var _iw = sprite_get_width(_spr), _ih = sprite_get_height(_spr);
    var _k = min((_size - 4) / _iw, (_size - 4) / _ih);
    var _dw = _iw * _k, _dh = _ih * _k;
    draw_sprite_stretched(_spr, 0, _x + (_size - _dw) * 0.5, _y + (_size - _dh) * 0.5,
                          _dw, _dh);
    draw_set_alpha(1);
}

/// Visible-pixel bounds for the small prop icons. Their canvases are 20x20
/// with transparent padding and different anchors, so drawing from the top
/// left leaves each row's artwork at a different optical height.
function ui_icon_trim(_spr) {
    switch (_spr) {
        case spr_prop_box:     return [0, 5, 19, 20];
        case spr_prop_bed:     return [0, 6, 20, 20];
        case spr_prop_toys:    return [0, 9, 20, 20];
        case spr_prop_post:    return [1, 3, 20, 20];
        case spr_prop_jars:    return [1, 6, 19, 20];
        case spr_prop_fount:   return [1, 3, 20, 20];
        case spr_prop_sunbeam: return [0, 0, 20, 20];
        case spr_prop_yarnpit: return [2, 5, 20, 20];
        case spr_prop_mug:     return [3, 8, 20, 20];
        case spr_prop_cake:    return [3, 2, 18, 20];
        case spr_prop_teapot:  return [1, 5, 20, 20];
        case spr_prop_lantern: return [3, 1, 18, 20];
        case spr_prop_quilt:   return [2, 5, 18, 19];
        case spr_prop_aurora:  return [1, 2, 20, 18];
        case spr_ui_yarn_icon: return [0, 1, 16, 16];
        case spr_ui_fish_icon: return [1, 2, 16, 12];
        case spr_fx_sparkle:   return [0, 2, 15, 13];
        case spr_fx_heart:     return [2, 3, 14, 13];
        case spr_fx_puff:      return [6, 6, 11, 11];
        case spr_room_plant:   return [0, 0, 26, 42];
    }
    return [0, 0, sprite_get_width(_spr), sprite_get_height(_spr)];
}

/// Fit an icon's visible pixels inside a box, centred. One helper for every
/// row that shows a prop, so alignment cannot drift between screens.
function ui_icon_fit(_spr, _cx, _cy, _maxw, _maxh, _alpha) {
    var _b = ui_icon_trim(_spr);
    var _w = max(1, _b[2] - _b[0]);
    var _h = max(1, _b[3] - _b[1]);
    var _k = min(_maxw / _w, _maxh / _h);
    draw_sprite_part_ext(_spr, 0, _b[0], _b[1], _w, _h,
                         _cx - _w * _k * 0.5, _cy - _h * _k * 0.5,
                         _k, _k, c_white, _alpha);
}

/// Every row icon sits on the same cream lozenge, centred on the row's text
/// block. The plate is what makes a tall lantern and a flat fish read as one
/// column; the trim above is what keeps the artwork itself optically centred.
function ui_icon_plate(_cx, _cy, _alpha) {
    draw_set_alpha(0.55 * _alpha);
    draw_set_colour(P_WOOD);
    draw_roundrect_ext(_cx - 10, _cy - 10, _cx + 10, _cy + 10, 4, 4, false);
    draw_set_alpha(0.75 * _alpha);
    draw_set_colour(P_CREAM);
    draw_roundrect_ext(_cx - 9, _cy - 9, _cx + 9, _cy + 9, 3, 3, false);
    draw_set_alpha(_alpha);
}

// ---------------------------------------------------------------- guidance
// One line of advice, chosen from what the player has actually done. The
// guide card carries the full explanation; this is the nudge toward it.

function guide_pages() {
    return [
        { title: "TAPPING", lines: [
            "Tap the big cat to earn fish.",
            "Keep tapping to raise combo.",
            "Gold sparkles double income.",
            "Frenzy time shows in the top bar."] },
        { title: "THE SHOP", lines: [
            "Rows appear near their price.",
            "Each buy walks in one cat.",
            "10, 20, 40, 80, 120 double it.",
            "Hover a row for its /s gain.",
            "BUY sets 1, 10, 100 or MAX."] },
        { title: "BOOSTS", lines: [
            "Yarn buys permanent charms.",
            "Charms survive every reset.",
            "The bar fills as you level it.",
            "Open BOOST under the shop."] },
        { title: "RESETS", lines: [
            "RESET under the shop peels a layer.",
            "Fish and furniture start over.",
            "Charms, cats, journal stay.",
            "The reset pays its currency."] },
        { title: "THE COUNTER", lines: [
            "Open CAFE under the shop.",
            "Pick one base and one topping.",
            "A perfect dish pays fish or goods.",
            "Nine guests, three dishes each."] },
        { title: "THE FESTIVAL", lines: [
            "Moon opens the festival.",
            "Find it in the CAFE card.",
            "Pick three known dishes.",
            "One rank opens the next venue."] },
        { title: "THE JOURNAL", lines: [
            "Open CATS, then GOALS.",
            "Claim goals for stamps.",
            "Stamps buy permanent boosts.",
            "Projects cost fish and materials."] },
        { title: "STAFF", lines: [
            "Give a met cat a station.",
            "Its quirk's station doubles it.",
            "Slots open as the album fills.",
            "Staff is the last CATS tab."] },
        { title: "ROOMS AND SECRETS", lines: [
            "ROOMS walks between rooms.",
            "Higher rooms need lifetime fish.",
            "The Cozy Corner hides a seam.",
            "Watch the wall. Knock three times."] },
        { title: "THE CELLAR DOOR", lines: [
            "Only the Cozy Corner has it.",
            "Moon and festival reveal it.",
            "Knock three times to open.",
            "Prestige never touches it."] },
        { title: "THE COLD PARLOUR", lines: [
            "Seat every guest so clues hold.",
            "A wrong seat breaks a rule.",
            "Close a case to earn embers.",
            "Closings unseal deeper rooms."] },
        { title: "THE ASH GARDEN", lines: [
            "Plant a seed in an empty bed.",
            "Beds ripen in real time.",
            "WAX pays embers. BONE pays reagents.",
            "VEIL pays whispers or relics."] },
        { title: "THE TINCTURE CELLAR", lines: [
            "Load three reagents, set heat.",
            "Recipes are learned by trying.",
            "Use one for a strong effect.",
            "Brewing spends what you loaded."] },
        { title: "THE LONG HALL", lines: [
            "Choose one door per floor.",
            "Doors pay embers or whispers.",
            "Some cost nerve. Zero nerve ends it.",
            "The last floor asks for 2 nerve."] },
        { title: "THE NINTH TABLE", lines: [
            "Open NIGHT on the map bar.",
            "A night run goes as deep as you dare.",
            "Every third case tests nerve.",
            "Depth 13 ends the night."] },
        { title: "RITES AND RELICS", lines: [
            "Open RITES or RELICS below.",
            "Embers and blood buy charms.",
            "Forty relics, five sets of eight.",
            "Enthrone one for its set bonus."] },
        { title: "CLOSINGS", lines: [
            "Thirteen deeds in order.",
            "Closings unseal deeper rooms.",
            "Claim them at the altar.",
            "Mastery adds a bonus."] },
        { title: "AUTOMATION", lines: [
            "SELF-STOCK buys a shop row.",
            "SPARKLE HANDS catches gold.",
            "Both ease the time you are here.",
            "Buy them in BOOST, yarn and stars."] },
        { title: "ROOMS BEYOND", lines: [
            "Tea House opens at 250M fish.",
            "Star Library opens at 25B fish.",
            "Every room has its own weather.",
            "ROOMS walks you back home."] },
        { title: "STICKERS AND HATS", lines: [
            "Stickers arrive as you play.",
            "Hats show on the big cat.",
            "Both live in the MORE card.",
            "Both survive layer resets."] },
        { title: "OFFLINE EARNINGS", lines: [
            "Away pay is 50% of /s.",
            "Base cap is 8 hours.",
            "Welcome shows the total.",
            "Combo and frenzy do not count."] },
        { title: "YARN RESET", lines: [
            "RESET: 600M run fish.",
            "Base pay: sqrt(run / 20M).",
            "Each yarn: +10% forever.",
            "Clears fish, rows and taps."] },
        { title: "STAR RESET", lines: [
            "RESET: 14 yarn since last star.",
            "Base pay: sqrt(source / 4).",
            "Each star: +25% forever.",
            "Clears yarn, fish and rows."] },
        { title: "BEAN RESET", lines: [
            "RESET: 4 stars since last bean.",
            "Base pay: sqrt(source / 2).",
            "Each bean: +50% forever.",
            "Clears stars, yarn, fish."] },
        { title: "AURORA RESET", lines: [
            "RESET: 3 beans since aurora.",
            "Base pay: sqrt(source / 2).",
            "Each aurora: +100% forever.",
            "Clears beans, stars and yarn."] },
        { title: "MOON RESET", lines: [
            "RESET: 25 aurora since moon.",
            "Base pay: sqrt(source / 8).",
            "Each moon: +150% forever.",
            "First moon opens festivals."] },
        { title: "STAFF POSTS", lines: [
            "Open CATS, then the STAFF tab.",
            "COUNTER taps. OVEN makes /s.",
            "WINDOW away. CELLAR embers.",
            "12 posts across 4 stations."] },
        { title: "FESTIVAL RULES", lines: [
            "Nine venues, three ranks each.",
            "3 known dishes, no repeats.",
            "An exact count plus a minimum.",
            "Entry: 2, 3, 4 material."] },
        { title: "PARLOUR RULES", lines: [
            "Seat spirits to fit every clue.",
            "A broken rule loses flawless.",
            "A hint costs 1 whisper.",
            "Seats: 4, 5, then 6."] },
        { title: "GARDEN RULES", lines: [
            "WAX 15m, BONE 1h, VEIL 3h.",
            "FED halves wait and pays 1.35x.",
            "Blight: cleanse 15 or risk curse.",
            "KEEPER takes healthy at 60%."] },
        { title: "HALL RULES", lines: [
            "SAFE, DARK, ???? tags.",
            "PEEK costs 2 whispers.",
            "A clean exit pays 1 blood.",
            "Failure keeps half the loot."] },
        { title: "CELLAR RULES", lines: [
            "Mix 3 reagents at heat 1-3.",
            "A wrong batch pays 4 embers.",
            "Matches are saved as known.",
            "Each bottle has one use."] },
        { title: "RELIC RULES", lines: [
            "Forty relics, five sets of 8.",
            "Complete 8: +5% cafe, +1 blood.",
            "ENTHRONE 3. RELIQUARY +1.",
            "Sets: embers, whispers, growth,",
            "nerve, finds. Duplicates stack."] },
        { title: "NIGHT RULES", lines: [
            "Endless. Depth 13 ends it.",
            "Every third depth costs nerve.",
            "A fail ends it. Loot is kept.",
            "Tier rises at depth 3 and 7."] },
        { title: "CLOSINGS IN DETAIL", lines: [
            "Claim the 13 deeds in order.",
            "Each: 1 blood, +2% cafe.",
            "Parlour open, then 1/3/6/12.",
            "Mastery: 1, 3, 6, 10, 16."] },
        { title: "OFFLINE RATE", lines: [
            "NIGHT SHIFT: +3% a level.",
            "DEW +15%. MOONLIT +25%.",
            "Journal, skills, WINDOW add.",
            "Combo and frenzy excluded."] },
        { title: "RESET MULTIPLIERS", lines: [
            "Counts all currency ever earned.",
            "Spending never lowers it.",
            "A reset clears layers below.",
            "All collections survive resets."] },
        { title: "STAFF SLOTS", lines: [
            "Slot 1 is open from the start.",
            "Slot 2 needs 8 cats.",
            "Slot 3 needs 18 cats.",
            "Matching quirk doubles it."] },
        { title: "HOLLOW CURRENCIES", lines: [
            "Embers buy most charms.",
            "Blood buys Altar charms.",
            "Whispers pay peeks and hints.",
            "Relics are found, not bought."] },
        { title: "CAFE ERAS", lines: [
            "The first moon opens ERAS.",
            "Open CATS, then the ERAS tab.",
            "Three deeds and one rule.",
            "Seal all six for six perks."] },
        { title: "HOUSE RULES", lines: [
            "Pick one at each era.",
            "HUSTLE: taps x2, /s -20%.",
            "STEADY: /s +25%, taps -25%.",
            "NIGHT: Hollow +25%, away +25%."] },
        { title: "ROOM MASTERY", lines: [
            "Taps train the room you are in.",
            "Twelve rungs: 150 taps to 115k.",
            "Each level also adds +1% output.",
            "Rank 6 auto-pets every 4s.",
            "Every 8th auto-pet: +1 treat."] },
        { title: "CAT BONDS", lines: [
            "Taps feed the cat beside you.",
            "Home-room taps count double bond.",
            "Twelve rungs per cat, in CATS.",
            "Rungs mix rules with small boosts."] },
        { title: "HOLLOW NIGHTS", lines: [
            "Every hall run draws a night.",
            "The first is always THE QUIET.",
            "2-5 doors, 3 or 5 floors.",
            "Each night changes how a run plays."] }
    ];
}

/// Four chapters of the manual, each starting at one page. The card draws these
/// as jump pills so a player never has to arrow through twenty pages to find
/// the one system they are stuck on.
function guide_sections() {
    return [
        { name: "CAFE",   first: 0 },
        { name: "PEOPLE", first: 6 },
        { name: "HOLLOW", first: 9 },
        { name: "MORE",   first: 17 }
    ];
}

/// The chapter a page belongs to, for highlighting the jump pill.
function guide_section_of(_page) {
    var _s = guide_sections();
    var _at = 0;
    for (var _i = 0; _i < array_length(_s); _i++) {
        if (_page >= _s[_i].first) _at = _i;
    }
    return _at;
}

/// The next useful action, or undefined when the player is clearly on top of
/// things. Page numbers point at guide_pages().
function guide_tip() {
    var _g = global.G;
    if (_g.stats.clicks < 25) return { text: "TAP THE CAT", page: 0 };
    if (_g.stats.purchases < 3) return { text: "BUY A BOX IN THE SHOP", page: 1 };
    if (service_unlocked() && service_total() == 0)
        return { text: "TRY THE CAFE COUNTER", page: 4 };
    if (up_any_affordable() > 0) return { text: "SPEND YARN ON BOOSTS", page: 2 };
    if (global.G.lifetime_earned >= 250000000 && global.G.world.zone < 4)
        return { text: "A NEW ROOM IS OPEN: ROOMS", page: 18 };
    for (var _li = 0; _li < LAYER_COUNT; _li++) {
        if (layer_can(_li)) return { text: "RESET FOR " + global.LAYER[_li].name, page: 3 };
    }
    for (var _c = 0; _c < JOURNAL_CHAPTERS; _c++) {
        if (!journal_unlocked(_c)) continue;
        for (var _s = 0; _s < 4; _s++) {
            var _goal = journal_goal(_c, _s);
            if (!_g.journal.claims[_c * 4 + _s] && journal_value(_goal.kind) >= _goal.target)
                return { text: "CLAIM A JOURNAL GOAL", page: 6 };
        }
    }
    if (festival_unlocked() && _g.festival.ranks[0] == 0)
        return { text: "ENTER THE MOON FESTIVAL", page: 5 };
    var _empty = 0;
    for (var _si = 0; _si < array_length(_g.staff.slots); _si++) {
        if (_g.staff.slots[_si] < 0) _empty += 1;
    }
    if (album_unlocked_count() >= 6 && _empty == array_length(_g.staff.slots))
        return { text: "STAFF YOUR CAFE IN THE JOURNAL", page: 7 };
    if (_g.occult.found && _g.occult.in_hollow == false && _g.world.zone != 0)
        return { text: "THE CAFE WALL IS IN THE COZY CORNER", page: 8 };
    if (_g.occult.found && _g.occult.closings == 0)
        return { text: "SOLVE A CASE IN THE PARLOUR", page: 8 };
    return undefined;
}

/// Wrap one page's sentences to the card's inner width. The copy stays short,
/// but wrapping is what guarantees no line can ever leave the card.
function guide_lines(_page) {
    var _out = [];
    draw_set_font(global.fnt_small);
    for (var _i = 0; _i < array_length(_page.lines); _i++) {
        var _words = string_split(_page.lines[_i], " ");
        var _cur = "";
        for (var _w = 0; _w < array_length(_words); _w++) {
            var _try = (_cur == "") ? _words[_w] : _cur + " " + _words[_w];
            if (string_width(_try) > 208 && _cur != "") {
                array_push(_out, _cur);
                _cur = _words[_w];
            } else {
                _cur = _try;
            }
        }
        if (_cur != "") array_push(_out, _cur);
    }
    return _out;
}

// ------------------------------------------------------- native UI primitives
// These draw in the 1920x1080 GUI, at a 2x pixel scale. Layout numbers are real
// pixels; nothing here goes through the 480x270 room canvas.

function dui_begin() {
    matrix_set(matrix_world, matrix_build_identity());
}

function ui_legacy_begin() {
    // matrix_build takes rotation before scale: (x, y, z, rx, ry, rz, sx, sy, sz).
    matrix_set(matrix_world, matrix_build(0, 0, 0, 0, 0, 0, UI_LEGACY_S, UI_LEGACY_S, 1));
}

/// Convert a native GUI point back to room space when feedback (a heart or a
/// sparkle burst) has to live with the room art. This is the only conversion
/// direction UI code may use; it is not a layout helper.
function ui_room_x(_x) { return _x / UI_LEGACY_S; }
function ui_room_y(_y) { return _y / UI_LEGACY_S; }
/// The reverse, for a native pointer that must land on room art (the tutorial
/// arrow at the cat). Kept here so UI files never invent a scale constant.
function ui_room_to_gui(_v) { return _v * UI_LEGACY_S; }

function ui_canvas_reset() {
    matrix_set(matrix_world, matrix_build_identity());
}

/// Scale a 6x9 pixel font by 2 without resampling it: the GUI canvas is native
/// 1920, so this is 18px tall on screen, not a magnified 4x glyph.
function dui_text(_x, _y, _txt, _font, _col, _align) {
    ui_audit_font(_font);
    ui_audit_text(_x, _y);
    draw_set_font(_font);
    draw_set_halign(_align);
    draw_set_valign(fa_top);
    if (_col == P_WHITE || _col == P_CREAM || _col == P_GOLD) {
        draw_set_colour(P_INK);
        draw_set_alpha(0.7);
        draw_text_transformed(_x, _y + 2, _txt, UI_S, UI_S, 0);
        draw_set_alpha(1);
    }
    draw_set_colour(_col);
    draw_text_transformed(_x, _y, _txt, UI_S, UI_S, 0);
    draw_set_halign(fa_left);
}

function dui_text_w(_txt, _font) {
    ui_audit_font(_font);
    draw_set_font(_font);
    return string_width(_txt) * UI_S;
}

/// A nine-slice panel at native scale. Source corners stay 6px; destination
/// corners are 12px, so the panel border is crisp instead of smeared.
function dui_nine(_spr, _x, _y, _w, _h, _c) {
    var _k = UI_S;
    var _sw = sprite_get_width(_spr);
    var _sh = sprite_get_height(_spr);
    var _mx = _sw - _c * 2;
    var _my = _sh - _c * 2;
    var _c2 = _c * _k;
    var _ew = max(0, _w - _c2 * 2);
    var _eh = max(0, _h - _c2 * 2);

    draw_sprite_part_ext(_spr, 0, 0, 0, _c, _c, _x, _y, _k, _k, c_white, 1);
    draw_sprite_part_ext(_spr, 0, _sw - _c, 0, _c, _c, _x + _w - _c2, _y, _k, _k, c_white, 1);
    draw_sprite_part_ext(_spr, 0, 0, _sh - _c, _c, _c, _x, _y + _h - _c2, _k, _k, c_white, 1);
    draw_sprite_part_ext(_spr, 0, _sw - _c, _sh - _c, _c, _c,
                         _x + _w - _c2, _y + _h - _c2, _k, _k, c_white, 1);

    if (_ew > 0 && _mx > 0) {
        draw_sprite_part_ext(_spr, 0, _c, 0, _mx, _c, _x + _c2, _y, _ew / _mx, _k, c_white, 1);
        draw_sprite_part_ext(_spr, 0, _c, _sh - _c, _mx, _c, _x + _c2, _y + _h - _c2,
                             _ew / _mx, _k, c_white, 1);
    }
    if (_eh > 0 && _my > 0) {
        draw_sprite_part_ext(_spr, 0, 0, _c, _c, _my, _x, _y + _c2, _k, _eh / _my, c_white, 1);
        draw_sprite_part_ext(_spr, 0, _sw - _c, _c, _c, _my, _x + _w - _c2, _y + _c2,
                             _k, _eh / _my, c_white, 1);
    }
    if (_ew > 0 && _eh > 0 && _mx > 0 && _my > 0) {
        draw_sprite_part_ext(_spr, 0, _c, _c, _mx, _my, _x + _c2, _y + _c2,
                             _ew / _mx, _eh / _my, c_white, 1);
    }
}

function dui_button(_x, _y, _w, _h, _label, _hot, _down) {
    ui_audit_control("button", _x, _y, _w, _h);
    var _spr = _down ? spr_ui_btn_press : (_hot ? spr_ui_btn_hover : spr_ui_btn_idle);
    dui_nine(_spr, _x, _y, _w, _h, 6);
    if (_label == "<" || _label == ">") {
        var _cx = floor(_x + _w * 0.5), _cy = floor(_y + _h * 0.5);
        var _dir = _label == "<" ? -1 : 1;
        draw_set_colour(P_INK);
        draw_triangle(_cx + _dir * 7, _cy, _cx - _dir * 5, _cy - 9,
                      _cx - _dir * 5, _cy + 9, false);
        return;
    }
    var _tw = dui_text_w(_label, global.fnt_small);
    var _th = string_height(_label) * UI_S;
    dui_text(_x + (_w - _tw) * 0.5, _y + (_h - _th) * 0.5 - 1, _label,
             global.fnt_small, P_INK, fa_left);
}

function dui_pill(_x, _y, _w, _h, _label, _on, _hot) {
    ui_audit_control("pill", _x, _y, _w, _h);
    var _fill = _on ? P_CORAL : (_hot ? P_PINK : P_CREAM);
    var _edge = _on ? P_CORAL : P_WOOD;
    draw_set_colour(_edge);
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 10, 10, false);
    draw_set_colour(_fill);
    draw_roundrect_ext(_x + 2, _y + 2, _x + _w - 2, _y + _h - 2, 8, 8, false);
    dui_text(_x + _w * 0.5, _y + (_h - 18) * 0.5 - 1, _label, global.fnt_small,
             _on ? P_WHITE : P_INK, fa_center);
}

function dui_pill_w(_label) {
    return dui_text_w(_label, global.fnt_small) + 40;
}

function dui_icon_plate(_cx, _cy, _alpha) {
    draw_set_alpha(0.55 * _alpha);
    draw_set_colour(P_WOOD);
    draw_roundrect_ext(_cx - 24, _cy - 24, _cx + 24, _cy + 24, 10, 10, false);
    draw_set_alpha(0.75 * _alpha);
    draw_set_colour(P_CREAM);
    draw_roundrect_ext(_cx - 21, _cy - 21, _cx + 21, _cy + 21, 8, 8, false);
    draw_set_alpha(_alpha);
}

function dui_icon_fit(_spr, _cx, _cy, _maxw, _maxh, _alpha) {
    var _b = ui_icon_trim(_spr);
    var _w = max(1, _b[2] - _b[0]);
    var _h = max(1, _b[3] - _b[1]);
    var _k = clamp(floor(min(_maxw / _w, _maxh / _h)), 1, 6);
    draw_sprite_part_ext(_spr, 0, _b[0], _b[1], _w, _h,
                         _cx - _w * _k * 0.5, _cy - _h * _k * 0.5,
                         _k, _k, c_white, _alpha);
}

/// The 480x270 illustrated backdrops stay pixel art, blown up 4x behind the
/// native card. Drawing them through their own matrix keeps the room art and
/// the interface independent.
function dui_pixel_scene(_kind, _fade) {
    matrix_set(matrix_world, matrix_build(0, 0, 0, 0, 0, 0, UI_LEGACY_S, UI_LEGACY_S, 1));
    ui_activity_scene(_kind, _fade);
    matrix_set(matrix_world, matrix_build_identity());
}

function dui_hover(_x, _y, _w, _h) {
    return point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0),
                              _x, _y, _x + _w, _y + _h);
}

function dui_clicked(_x, _y, _w, _h) {
    return dui_hover(_x, _y, _w, _h) && mouse_check_button_pressed(mb_left);
}

// GameMaker hex literals are $BBGGRR, so these are R and B swapped on purpose.
#macro P_INK   $2E1B2B  // 2B1B2E
#macro P_CREAM $C8E6F6  // F6E6C8
#macro P_WHITE $F7FDFF  // FFFDF7
#macro P_GOLD  $4DC9FF  // FFC94D
#macro P_CORAL $5A6AE8  // E86A5A
#macro P_PINK  $C8A8F5  // F5A8C8
#macro P_MINT  $C0D68F  // 8FD6C0
#macro P_SKY   $F0D39E  // 9ED3F0
#macro P_WOOD  $5B8AC9  // C98A5B
#macro P_BROWN $3C5A8C  // 8C5A3C

/// A hat by name. A switch, not a struct: asset_get_index on a built name
/// is a known trap and a string-keyed lookup is not worth the risk.
function hat_sprite(_h) {
    switch (_h) {
        case "beanie": return spr_hat_beanie;
        case "crown":  return spr_hat_crown;
        case "wizard": return spr_hat_wizard;
    }
    return -1;
}

// ------------------------------------------------------ native menu layouts
// The last 4x cards. Every menu below now uses the same 1920 canvas as the
// journal, shop and BOOST: a real pixel card, a 18px reading size, and one
// layout function shared by Step and Draw so a hit box cannot drift.

function dui_dim(_a) {
    draw_set_alpha(_a);
    draw_set_colour(P_INK);
    draw_rectangle(0, 0, UI_W, UI_H, false);
    draw_set_alpha(1);
}

function dui_square(_r, _label) {
    ui_audit_control("square", _r.x, _r.y, _r.w, _r.h);
    dui_nine(spr_ui_btn_idle, _r.x, _r.y, _r.w, _r.h, 4);
    dui_text(_r.x + _r.w * 0.5, _r.y + (_r.h - 18) * 0.5 - 1, _label,
             global.fnt_small, P_INK, fa_center);
}

function settings_card_rect() {
    return { x: 580, y: 160, w: 760, h: 700 };
}

function settings_ui() {
    var _c = settings_card_rect();
    var _x = _c.x + UI_SPACE_L, _w = _c.w - UI_SPACE_L * 2;
    var _bw = floor((_w - UI_SPACE_M) * 0.5);
    return {
        card: _c,
        close: { x: _c.x + _c.w - 72, y: _c.y + UI_SPACE_M, w: UI_W_SQUARE, h: UI_H_CONTROL },
        help:  { x: _c.x + _c.w - 128, y: _c.y + UI_SPACE_M, w: UI_W_SQUARE, h: UI_H_CONTROL },
        music: { x: _x, y: _c.y + 96, w: _bw, h: UI_H_CTA },
        sfx:   { x: _x + _bw + UI_SPACE_M, y: _c.y + 96, w: _bw, h: UI_H_CTA },
        motion: { x: _x, y: _c.y + 168, w: _bw, h: UI_H_CTA },
        hat:   { x: _x + _bw + UI_SPACE_M, y: _c.y + 168, w: _bw, h: UI_H_CTA },
        stickers: { x: _x, y: _c.y + 272, w: _w, h: UI_H_CTA },
        guide: { x: _x, y: _c.y + 344, w: _w, h: UI_H_CTA },
        reset: { x: _x, y: _c.y + 416, w: _w, h: UI_H_CTA }
    };
}

function manual_card_rect() {
    return { x: 320, y: 160, w: 1280, h: 760 };
}

function manual_ui() {
    var _c = manual_card_rect();
    var _x = _c.x + 48, _w = _c.w - 96;
    var _secs = guide_sections();
    var _gap = UI_SPACE_S;
    var _pills = [];
    var _sx = _x;
    for (var _i = 0; _i < array_length(_secs); _i++) {
        var _pw = dui_pill_w(_secs[_i].name) + UI_SPACE_S;
        array_push(_pills, { x: _sx, y: _c.y + 104, w: _pw, h: UI_H_ROW,
                             index: _i, name: _secs[_i].name, first: _secs[_i].first });
        _sx += _pw + _gap;
    }
    return {
        card: _c,
        close: { x: _c.x + _c.w - 72, y: _c.y + UI_SPACE_M, w: UI_W_SQUARE, h: UI_H_CONTROL },
        pills: _pills,
        prev: { x: _x, y: _c.y + 560, w: UI_W_CONTROL, h: UI_H_CTA },
        next: { x: _c.x + _c.w - 48 - UI_W_CONTROL, y: _c.y + 560,
                w: UI_W_CONTROL, h: UI_H_CTA },
        back: { x: _c.x + _c.w * 0.5 - UI_W_CONTROL, y: _c.y + 560,
                w: UI_W_CONTROL * 2, h: UI_H_CTA },
        lines_x: _x,
        lines_w: _w
    };
}

function stickers_card_rect() {
    return { x: 460, y: 90, w: 1000, h: 900 };
}

function stickers_ui() {
    var _c = stickers_card_rect();
    return {
        card: _c,
        close: { x: _c.x + _c.w - 72, y: _c.y + UI_SPACE_M, w: UI_W_SQUARE, h: UI_H_CONTROL },
        grid_x: _c.x + 40, grid_y: _c.y + 120,
        cell_w: 215, cell_h: 200, gap: 20,
        prev: { x: _c.x + 40, y: _c.y + 804, w: UI_W_CONTROL, h: UI_H_CTA },
        next: { x: _c.x + _c.w - 40 - UI_W_CONTROL, y: _c.y + 804,
                w: UI_W_CONTROL, h: UI_H_CTA }
    };
}

function prestige_card_rect() {
    return { x: 360, y: 100, w: 1200, h: 880 };
}

function prestige_ui() {
    var _c = prestige_card_rect();
    var _do = 300, _nah = 180, _gap = UI_SPACE_M;
    var _bx = _c.x + floor((_c.w - (_do + _nah + _gap)) * 0.5);
    return {
        card: _c,
        help: { x: _c.x + 32, y: _c.y + UI_SPACE_M, w: UI_W_SQUARE, h: UI_H_CONTROL },
        close: { x: _c.x + _c.w - 72, y: _c.y + UI_SPACE_M, w: UI_W_SQUARE, h: UI_H_CONTROL },
        tabs_y: _c.y + 104,
        bar: { x: _c.x + 96, y: _c.y + 326, w: _c.w - 192, h: 16 },
        do_btn: { x: _bx, y: _c.y + 728, w: _do, h: UI_H_CTA },
        nah_btn: { x: _bx + _do + _gap, y: _c.y + 728, w: _nah, h: UI_H_CTA }
    };
}

function service_card_rect() {
    // 820 is the measured content height: header, two choice rows, the serve
    // action and the next-guest line, with one 40px breathing margin.
    return { x: 360, y: 90, w: 1200, h: 820 };
}

function service_ui() {
    var _c = service_card_rect();
    var _x = _c.x + 48, _w = _c.w - 96;
    var _cell = floor((_w - 40) / 3);
    var _base = [];
    var _topping = [];
    for (var _i = 0; _i < 3; _i++) {
        array_push(_base, { x: _x + _i * (_cell + 20), y: _c.y + 310,
                            w: _cell, h: UI_H_CTA });
        array_push(_topping, { x: _x + _i * (_cell + 20), y: _c.y + 432,
                               w: _cell, h: UI_H_CTA });
    }
    var _tipw = 420, _tipg = UI_SPACE_M;
    var _tipx = _c.x + floor((_c.w - (_tipw * 2 + _tipg)) * 0.5);
    var _dish_prev = [], _dish_next = [];
    for (var _i = 0; _i < 3; _i++) {
        var _y = _c.y + 350 + _i * 86;
        array_push(_dish_prev, { x: _x, y: _y, w: UI_W_SQUARE, h: UI_H_CONTROL });
        array_push(_dish_next, { x: _c.x + _c.w - 48 - UI_W_SQUARE, y: _y,
                                 w: UI_W_SQUARE, h: UI_H_CONTROL });
    }
    var _rewards = [];
    for (var _i = 0; _i < 3; _i++) {
        array_push(_rewards, { x: _x, y: _c.y + 260 + _i * 88, w: _w, h: UI_H_CTA });
    }
    return {
        card: _c,
        close: { x: _c.x + _c.w - 72, y: _c.y + UI_SPACE_M, w: UI_W_SQUARE, h: UI_H_CONTROL },
        help: { x: _c.x + _c.w - 128, y: _c.y + UI_SPACE_M, w: UI_W_SQUARE, h: UI_H_CONTROL },
        toggle: { x: _c.x + 360, y: _c.y + UI_SPACE_M, w: 240, h: UI_H_ROW },
        guest_prev: { x: _x, y: _c.y + 124, w: UI_W_SQUARE, h: UI_H_CONTROL },
        guest_next: { x: _c.x + _c.w - 48 - UI_W_SQUARE, y: _c.y + 124,
                      w: UI_W_SQUARE, h: UI_H_CONTROL },
        base: _base, topping: _topping,
        serve: { x: _c.x + _c.w * 0.5 - 180, y: _c.y + 630, w: 360, h: UI_H_CTA },
        tip: [ { x: _tipx, y: _c.y + 630, w: _tipw, h: UI_H_CTA },
               { x: _tipx + _tipw + _tipg, y: _c.y + 630, w: _tipw, h: UI_H_CTA } ],
        venue_prev: { x: _x, y: _c.y + 124, w: UI_W_SQUARE, h: UI_H_CONTROL },
        venue_next: { x: _c.x + _c.w - 48 - UI_W_SQUARE, y: _c.y + 124,
                      w: UI_W_SQUARE, h: UI_H_CONTROL },
        dish_prev: _dish_prev, dish_next: _dish_next,
        entry: { x: _c.x + _c.w * 0.5 - 180, y: _c.y + 700, w: 360, h: UI_H_CTA },
        // The venue story sits beside the venue name, not on the entry row:
        // the entry stays the one primary action in the festival card.
        story: { x: _c.x + 120, y: _c.y + 112, w: 240, h: UI_H_ROW },
        rewards: _rewards
    };
}

function welcome_card_rect() {
    return { x: 580, y: 330, w: 760, h: 420 };
}
