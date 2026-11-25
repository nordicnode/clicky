/// The guidance layer: one persistent "next" goal chosen from live state, and
/// one first-visit lesson at a time. Lessons are pointers into guide_pages(),
/// not a second copy of the copy, so a page correction reaches both.
///
/// Everything here is read-only except guide_mark(). A lesson is marked seen
/// only when the player finishes it or opens its manual page; LATER snoozes it.

function guide_defaults() {
    return { seen: "", hidden: false };
}

/// Old saves simply arrive without this struct; a malformed one is repaired
/// rather than trusted. `seen` is a pipe-delimited set of lesson ids.
function guide_normalize() {
    if (!variable_struct_exists(global.G, "guide") || !is_struct(global.G.guide)) {
        global.G.guide = guide_defaults();
    }
    if (!variable_struct_exists(global.G.guide, "seen")
        || !is_string(global.G.guide.seen)) {
        global.G.guide.seen = "";
    }
    if (!variable_struct_exists(global.G.guide, "hidden")
        || !is_bool(global.G.guide.hidden)) {
        global.G.guide.hidden = false;
    }
}

function guide_seen(_id) {
    if (!variable_struct_exists(global.G, "guide") || !is_struct(global.G.guide)) return false;
    return string_pos("|" + _id + "|", "|" + global.G.guide.seen + "|") > 0;
}

/// Save-free so a test can mark a whole screenshot set without a write each.
function guide_mark_quiet(_id) {
    if (_id == "" || guide_seen(_id)) return;
    var _s = global.G.guide.seen;
    global.G.guide.seen = (_s == "") ? _id : _s + "|" + _id;
}

function guide_mark(_id) {
    if (_id == "" || guide_seen(_id)) return;
    guide_mark_quiet(_id);
    save_write();
}

/// Every first-visit explanation, in the order it should surface. Pages are
/// indexes into guide_pages(); a lesson never owns prose of its own.
function guide_lessons() {
    return [
        { id: "offline",  title: "WELCOME BACK",        pages: [20, 35], prio: 5 },
        { id: "door",     title: "THE HOLLOW",          pages: [9, 38],  prio: 10 },
        { id: "parlour",  title: "THE COLD PARLOUR",    pages: [10, 28], prio: 20 },
        { id: "hall",     title: "THE LONG HALL",       pages: [13, 30], prio: 30 },
        { id: "garden",   title: "THE ASH GARDEN",      pages: [11, 29], prio: 40 },
        { id: "cellar",   title: "THE TINCTURE CELLAR", pages: [12, 31], prio: 50 },
        { id: "relics",   title: "RELICS",              pages: [15, 32], prio: 60 },
        { id: "night",    title: "THE NINTH TABLE",     pages: [14, 33], prio: 70 },
        { id: "staff",    title: "STAFF",               pages: [26, 37], prio: 80 },
        { id: "bond",     title: "CAT BONDS",           pages: [41],      prio: 84 },
        { id: "nightfall",title: "HOLLOW NIGHTS",       pages: [42],      prio: 86 },
        { id: "festival", title: "THE FESTIVAL",        pages: [5, 27],  prio: 90 },
        { id: "era",      title: "CAFE ERAS",            pages: [39, 40], prio: 96 },
        { id: "layer0",   title: "YARN RESET",          pages: [21, 36], prio: 100 },
        { id: "layer1",   title: "STAR RESET",          pages: [22, 36], prio: 101 },
        { id: "layer2",   title: "BEAN RESET",          pages: [23, 36], prio: 102 },
        { id: "layer3",   title: "AURORA RESET",        pages: [24, 36], prio: 103 },
        { id: "layer4",   title: "MOON RESET",          pages: [25, 36], prio: 104 },
        { id: "counter",  title: "THE CAFE COUNTER",    pages: [4],      prio: 110 },
        { id: "journal",  title: "THE JOURNAL",         pages: [6],      prio: 120 },
        { id: "rooms",    title: "ROOMS AND LADDERS",   pages: [8, 40],  prio: 130 }
    ];
}

function guide_lesson(_id) {
    var _all = guide_lessons();
    for (var _i = 0; _i < array_length(_all); _i++) {
        if (_all[_i].id == _id) return _all[_i];
    }
    return undefined;
}

/// The next reset only explains itself at the frontier: once the layer above
/// has paid out, this lesson has missed its moment and the manual carries it.
function guide_layer_frontier(_i) {
    if (_i < 0 || _i >= LAYER_COUNT) return false;
    if (!layer_can(_i)) return false;
    if (_i + 1 < LAYER_COUNT) {
        var _next = global.LAYER[_i + 1].key;
        if (global.G.earned[$ _next] > 0) return false;
    }
    return true;
}

function guide_relevant(_id) {
    var _g = global.G;
    var _o = _g.occult;
    switch (_id) {
        case "offline":
            return global.offline_s >= 60;
        case "door":
            return _o.found;
        case "parlour":
            return veil_loc_open(1);
        case "hall":
            return veil_loc_open(3);
        case "garden":
            return veil_loc_open(2);
        case "cellar":
            return veil_loc_open(4);
        case "relics":
            return _o.found && veil_relic_owned_total() > 0;
        case "night":
            return veil_loc_open(5);
        case "bond":
            return album_unlocked_count() >= 2 && room_companion() >= 0
                && cat_bond_rank(room_companion()) >= 1;
        case "nightfall":
            return _o.stats.halls >= 1;
        case "staff":
            return album_unlocked_count() >= 6;
        case "festival":
            return festival_unlocked();
        case "era":
            return era_unlocked();
        // A layer lesson fires at the frontier, and stays eligible after the
        // first payout so a player who reset without meeting the card still
        // gets the explanation once. guide_pending() filters the seen set.
        case "layer0": return guide_layer_frontier(0) || _g.earned.yarn > 0;
        case "layer1": return guide_layer_frontier(1) || _g.earned.stars > 0;
        case "layer2": return guide_layer_frontier(2) || _g.earned.beans > 0;
        case "layer3": return guide_layer_frontier(3) || _g.earned.aurora > 0;
        case "layer4": return guide_layer_frontier(4) || _g.earned.moon > 0;
        case "counter":
            // Also stays eligible after the first dish; the card is skipped
            // once seen, not disabled by the player having played the system.
            return service_unlocked();
        case "journal":
            return _g.stats.purchases >= 3;
        case "rooms":
            return zone_unlocked() >= 1;
    }
    return false;
}

/// First unseen, relevant lesson in priority order. `_skip` is the id the
/// player postponed; it stays queued but does not immediately return.
function guide_pending(_skip) {
    var _all = guide_lessons();
    for (var _i = 0; _i < array_length(_all); _i++) {
        var _id = _all[_i].id;
        if (_id == _skip) continue;
        if (guide_seen(_id)) continue;
        if (guide_relevant(_id)) return _id;
    }
    return "";
}

// ---------------------------------------------------------------- objective

function guide_goal(_short, _why, _page, _bar, _prog) {
    return { short: _short, why: _why, page: _page,
             bar: clamp(_bar, 0, 1), prog: _prog };
}

function guide_next_tier() {
    for (var _i = 0; _i < TIER_COUNT; _i++) {
        if (!econ_unlocked(_i)) return _i;
    }
    return -1;
}

/// The cheapest charm the player can actually afford right now. Cheapest, not
/// first, so a large bank does not always point at the same tab.
function guide_cheapest_upgrade() {
    var _best = -1;
    var _cost = 1000000000000;
    for (var _i = 0; _i < array_length(global.UP); _i++) {
        var _id = global.UP[_i].id;
        if (!up_affordable(_id)) continue;
        var _c = up_cost(_id);
        if (_c < _cost) { _cost = _c; _best = _i; }
    }
    return _best;
}

function guide_staff_count() {
    var _n = 0;
    var _s = global.G.staff.slots;
    for (var _i = 0; _i < array_length(_s); _i++) {
        if (_s[_i] >= 0) _n += 1;
    }
    return _n;
}

function guide_claimable() {
    for (var _c = 0; _c < JOURNAL_CHAPTERS; _c++) {
        if (!journal_unlocked(_c)) continue;
        for (var _s = 0; _s < 4; _s++) {
            var _goal = journal_goal(_c, _s);
            if (!global.G.journal.claims[_c * 4 + _s]
                && journal_value(_goal.kind) >= _goal.target) {
                return { chapter: _c, slot: _s };
            }
        }
    }
    return undefined;
}

/// One always-answerable goal, chosen from live state. The order is the order a
/// new player meets things; a deeper reset or the Hollow's closing chain can
/// always outrank a smaller optional purchase.
function objective_goal() {
    var _g = global.G;
    var _o = _g.occult;

    if (_g.stats.clicks < 25) {
        return guide_goal("TAP THE CAT",
            "Combo raises every tap. Gold sparkles start a frenzy.",
            0, _g.stats.clicks / 25, string(_g.stats.clicks) + "/25 taps");
    }
    if (_g.stats.purchases < 3) {
        var _c0 = econ_cost(0);
        return guide_goal("BUY A BOX",
            "Ten fish starts the first row and every box adds /s.",
            1, _g.fish / max(1, _c0),
            fmt_small(_g.fish) + "/" + fmt_small(_c0));
    }

    if (service_unlocked() && service_total() == 0) {
        return guide_goal("TRY THE COUNTER",
            "Pick a base and a topping. A wrong dish costs nothing.",
            4, 0, "0 served");
    }

    // The post-MOON chapter outranks the reset ladder: its deeds are the new
    // long path, and they already point at whatever the player must do next.
    if (era_unlocked() && !era_all_sealed()) {
        var _en = era_cur() + 1;
        if (global.G.eras.rule < 0) {
            return guide_goal("CHOOSE A HOUSE RULE",
                "Open CATS, then ERAS. One rule shapes era " + string(_en) + ".",
                40, 0, "era " + string(_en) + "/" + string(ERA_COUNT));
        }
        var _ed = era_deeds_done(era_cur());
        if (_ed >= 3) {
            return guide_goal("SEAL ERA " + string(_en),
                "All three deeds are done. Press SEAL in the ERAS tab.",
                39, 1, "3/3 deeds");
        }
        var _el = era_list()[era_cur()];
        for (var _ei = 0; _ei < 3; _ei++) {
            if (era_deed_done(era_cur(), _ei)) continue;
            var _ev = era_deed_value(era_cur(), _ei);
            var _et = _el.deeds[_ei].target;
            return guide_goal("ERA " + string(_en) + ": " + _el.deeds[_ei].label,
                "Deed " + string(_ei + 1) + " of 3. The ERAS tab tracks all three.",
                39, _ev / max(1, _et), fmt_number(min(_ev, _et)) + "/" + fmt_number(_et));
        }
    }

    for (var _li = LAYER_COUNT - 1; _li >= 0; _li--) {
        if (!layer_can(_li)) continue;
        var _src = layer_src(_li);
        var _need = global.LAYER[_li].need * up_need_mult(_li);
        var _from = (_li == 0) ? "run" : global.LAYER[_li - 1].name;
        return guide_goal("RESET FOR " + global.LAYER[_li].name,
            "Pays " + fmt_number(layer_gain(_li)) + " now. "
            + fmt_small(_src) + "/" + fmt_small(_need) + " " + _from + ".",
            21 + _li, layer_progress(_li),
            fmt_small(_src) + "/" + fmt_small(_need) + " " + _from);
    }

    if (album_unlocked_count() >= 6 && guide_staff_count() == 0) {
        return guide_goal("STAFF YOUR CAFE",
            "A cat in its matching station doubles that station's bonus.",
            26, 0, "0/12 posts");
    }

    if (_o.found && _o.closings < VEIL_CLOSINGS) {
        var _cd = global.VEIL_CLOSING[_o.closings];
        var _cv = veil_closing_value(_cd.key);
        if (veil_closing_ready()) {
            return guide_goal("CLAIM CLOSING " + string(_o.closings + 1),
                _cd.label + " is ready. Hear it at the altar.",
                16, 1, _cd.label);
        }
        return guide_goal("HOLLOW: CLOSING " + string(_o.closings + 1),
            _cd.label + " " + string(min(_cv, _cd.target)) + "/" + string(_cd.target)
            + ". The pantry is in the Cozy Corner.",
            16, _cv / max(1, _cd.target),
            string(min(_cv, _cd.target)) + "/" + string(_cd.target));
    }
    if (_o.found && _o.closings >= VEIL_CLOSINGS && _o.night_best < 13) {
        return guide_goal("DESCEND THE NINTH TABLE",
            "Depth 13 is the Hollow's ending. Your best is "
            + string(_o.night_best) + ".",
            14, _o.night_best / 13, "best " + string(_o.night_best));
    }

    if (festival_unlocked()) {
        var _ranks = _g.festival.ranks;
        var _total_ranks = 0;
        for (var _ri = 0; _ri < array_length(_ranks); _ri++) _total_ranks += _ranks[_ri];
        if (_total_ranks <= 0) {
            return guide_goal("ENTER THE FESTIVAL",
                "Your first moon opened nine venues. Three known dishes enter one.",
                5, 0, "0/27 ranks");
        }
        var _venues = festival_venues();
        for (var _vi = 0; _vi < array_length(_venues); _vi++) {
            if (_ranks[_vi] > 0) continue;
            if (_vi > 0 && _ranks[_vi - 1] <= 0) continue;
            return guide_goal("OPEN " + _venues[_vi].name,
                "Win rank 1 to unlock the next venue.",
                5, 0, "venue " + string(_vi + 1) + "/9");
        }
    }

    var _ui = guide_cheapest_upgrade();
    if (_ui >= 0) {
        var _up = global.UP[_ui];
        var _key = global.LAYER[_up.layer].key;
        return guide_goal("BUY " + _up.name,
            _up.desc + ". " + fmt_small(up_cost(_up.id)) + " " + _key + " ready.",
            2, up_progress(_up.id),
            "Lv " + string(up_level(_up.id)) + "/" + string(_up.max));
    }

    var _claim = guide_claimable();
    if (is_struct(_claim)) {
        return guide_goal("CLAIM A JOURNAL GOAL",
            "A finished goal pays 1 stamp. Stamps buy skills.",
            6, 0, "1 ready");
    }

    if (zone_unlocked() > _g.world.zone) {
        return guide_goal("VISIT " + zone_name(zone_unlocked()),
            "That room is open. ROOMS walks you there and back.",
            8, 0, "room " + string(zone_unlocked() + 1) + "/6");
    }

    var _nt = guide_next_tier();
    if (_nt >= 0) {
        var _at = global.TIER[_nt].cost * 0.25;
        return guide_goal("UNLOCK " + global.TIER[_nt].name,
            "Appears at " + fmt_small(_at) + " lifetime. Each adds "
            + fmt_rate(global.TIER[_nt].rate) + "/s.",
            1, _g.lifetime_earned / max(1, _at),
            fmt_small(_g.lifetime_earned) + "/" + fmt_small(_at));
    }

    var _maxed = 0;
    for (var _mi = 0; _mi < array_length(global.UP); _mi++) {
        if (up_level(global.UP[_mi].id) >= global.UP[_mi].max) _maxed += 1;
    }
    if (_maxed < array_length(global.UP)) {
        return guide_goal("MAX YOUR CHARMS",
            "Charms are permanent. Every level survives every reset.",
            2, _maxed / array_length(global.UP),
            string(_maxed) + "/" + string(array_length(global.UP)) + " maxed");
    }

    // The long ladders are the late-game's next mountaintop. They only take
    // the strip once the short-term unlocks are exhausted, so a new player is
    // never pointed at a 326k-tap room before learning the shop.
    if (album_unlocked_count() >= 6 && zone_unlocked() >= 2) {
        var _comp = room_companion();
        if (_comp >= 0 && cat_bond_rank(_comp) < CAT_BOND_MAX) {
            return guide_goal("BOND WITH " + string_upper(global.CAT[_comp].n),
                "Home-room taps count double. Next: " + cat_next_trick(_comp) + ".",
                41, cat_bond_progress(_comp),
                "Lv " + string(cat_bond_rank(_comp)) + "/" + string(CAT_BOND_MAX));
        }
        var _room = -1;
        for (var _ri = 0; _ri <= zone_unlocked(); _ri++) {
            if (room_mastery_level(_ri) < ROOM_MASTERY_MAX) { _room = _ri; break; }
        }
        if (_room >= 0) {
            return guide_goal("TRAIN " + zone_name(_room),
                "Next rung: " + room_next_rung(_room).name + ". Taps train the room you are in.",
                40, room_mastery_progress(_room),
                "Lv " + string(room_mastery_level(_room)) + "/" + string(ROOM_MASTERY_MAX));
        }
    }

    return guide_goal("CHASE THE ENDLESS NIGHT",
        "Depth 13 is the ending. The night keeps going past it.",
        14, _o.night_best / 13, "best " + string(_o.night_best));
}

/// True while the lesson card is on screen. Other input owners use this so a
/// click on DONE cannot also pet the cat or buy a shop row underneath.
function guide_card_active() {
    return instance_exists(obj_guide) && obj_guide.shown >= 0;
}

/// The player can put the goal strip away; a tiny ? remains as the deliberate
/// way back. It lives in the save so a returning player is not forced to
/// re-open it.
function guide_strip_collapsed() {
    if (!variable_global_exists("G") || !variable_struct_exists(global.G, "guide")) return false;
    return global.G.guide.hidden == true;
}

/// The strip's whole click map, in native 1920 pixels. The panel body is
/// display-only: only the two explicit buttons and the collapsed ? react, so
/// clicking where the strip used to be can never pop a card over the game.
#macro GUIDE_STRIP_X 32
#macro GUIDE_STRIP_Y 900
#macro GUIDE_STRIP_W 760
#macro GUIDE_STRIP_H 148

function guide_strip_rect() {
    return { x: GUIDE_STRIP_X, y: GUIDE_STRIP_Y, w: GUIDE_STRIP_W, h: GUIDE_STRIP_H };
}

function guide_strip_rects() {
    var _p = guide_strip_rect();
    return {
        panel: _p,
        help:  { x: _p.x + _p.w - 112, y: _p.y + 16, w: UI_W_SQUARE, h: UI_H_CONTROL },
        hide:  { x: _p.x + _p.w - 64,  y: _p.y + 16, w: UI_W_SQUARE, h: UI_H_CONTROL },
        show:  { x: GUIDE_STRIP_X, y: GUIDE_STRIP_Y + 100, w: UI_W_SQUARE, h: UI_H_CONTROL }
    };
}

function guide_strip_action(_mx, _my, _pressed) {
    if (!_pressed) return "";
    var _r = guide_strip_rects();
    if (guide_strip_collapsed()) {
        // Closed really means closed: the one live control is the explicit ?
        // that brings the panel back. Nothing else in the old footprint wakes it.
        return point_in_rectangle(_mx, _my, _r.show.x, _r.show.y,
                                  _r.show.x + _r.show.w, _r.show.y + _r.show.h)
               ? "show" : "";
    }
    if (point_in_rectangle(_mx, _my, _r.help.x, _r.help.y,
                           _r.help.x + _r.help.w, _r.help.y + _r.help.h)) return "help";
    if (point_in_rectangle(_mx, _my, _r.hide.x, _r.hide.y,
                           _r.hide.x + _r.hide.w, _r.hide.y + _r.hide.h)) return "hide";
    return "";
}

/// The lesson card's frame and its four buttons, shared by Step and Draw.
function guide_card_rect() {
    return { x: 240, y: 220, w: 960, h: 460 };
}

function guide_card_button_rects() {
    var _c = guide_card_rect();
    var _bw = 190, _gap = 16;
    var _total = 4 * _bw + 3 * _gap;
    var _x = _c.x + floor((_c.w - _total) * 0.5);
    var _y = _c.y + _c.h - 88;
    var _out = [];
    for (var _i = 0; _i < 4; _i++) {
        array_push(_out, { x: _x + _i * (_bw + _gap), y: _y,
                           w: _bw, h: UI_H_CTA });
    }
    return _out;
}

/// The card's own close box, shared by Draw and Step.
function guide_card_close_rect() {
    var _c = guide_card_rect();
    return { x: _c.x + _c.w - 64, y: _c.y + 20, w: UI_W_SQUARE, h: UI_H_CONTROL };
}

function guide_strip_toggle() {
    if (!variable_global_exists("G") || !variable_struct_exists(global.G, "guide")) return false;
    global.G.guide.hidden = !guide_strip_collapsed();
    save_write();
    return global.G.guide.hidden;
}

/// True over the bottom-left objective strip. Input owners use this so a click
/// that opens the guide cannot also pet the cat or move rooms underneath it.
function guide_strip_hover() {
    if (veil_active()) return false;
    if (variable_global_exists("tutorial") && global.tutorial) return false;
    if (guide_strip_hidden()) return false;
    var _r = guide_strip_collapsed() ? guide_strip_rects().show : guide_strip_rect();
    return point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0),
                              _r.x, _r.y, _r.x + _r.w, _r.y + _r.h);
}

/// Shared guard for the strip: no strip while a real modal, lesson card or the
/// tutorial owns the corner. Kept separate so the strip's draw and its click
/// test can never disagree.
function guide_strip_hidden() {
    return guide_strip_collapsed() || ui_card_open() || guide_card_active()
        || instance_exists(obj_tutorial) || instance_exists(obj_welcome);
}

/// Wrap a free sentence for the narrow objective strip. Measured in pixels,
/// not characters, so the reason never has to be cut off with an ellipsis.
function guide_wrap(_txt, _maxw) {
    draw_set_font(global.fnt_small);
    var _words = string_split(_txt, " ");
    var _out = [];
    var _cur = "";
    for (var _i = 0; _i < array_length(_words); _i++) {
        var _try = (_cur == "") ? _words[_i] : _cur + " " + _words[_i];
        if (string_width(_try) > _maxw && _cur != "") {
            array_push(_out, _cur);
            _cur = _words[_i];
        } else {
            _cur = _try;
        }
    }
    if (_cur != "") array_push(_out, _cur);
    return _out;
}

/// Shrink a one-line label to fit a pixel width. The manual has its own
/// wrapper; this is only for the strip and card headers.
function guide_fit_text(_txt, _maxw) {
    draw_set_font(global.fnt_small);
    if (string_width(_txt) <= _maxw) return _txt;
    var _n = string_length(_txt);
    while (_n > 1 && string_width(string_copy(_txt, 1, _n)) > _maxw - 8) _n -= 1;
    return string_copy(_txt, 1, _n) + "..";
}

// --------------------------------------------------------------- text fit
// Every story card line goes through these helpers. The old bug was a raw
// dui_text() with a sentence longer than its 300px column; fitting and
// wrapping at the point of drawing makes that class of overflow impossible.

function text_width_px(_txt, _font) {
    draw_set_font(_font);
    return string_width(_txt) * UI_S;
}

/// Wrapping for the native canvas. Widths are pixels on the 1920 canvas, and
/// text is measured at the same 2x scale it is drawn at.
function text_wrap_px(_txt, _font, _maxw) {
    draw_set_font(_font);
    var _words = string_split(_txt, " ");
    var _out = [];
    var _cur = "";
    for (var _i = 0; _i < array_length(_words); _i++) {
        var _try = (_cur == "") ? _words[_i] : _cur + " " + _words[_i];
        if (string_width(_try) * UI_S > _maxw && _cur != "") {
            array_push(_out, _cur);
            _cur = _words[_i];
        } else {
            _cur = _try;
        }
    }
    if (_cur != "") array_push(_out, _cur);
    return _out;
}

function text_fit_px(_txt, _font, _maxw) {
    draw_set_font(_font);
    if (string_width(_txt) * UI_S <= _maxw) return _txt;
    var _n = string_length(_txt);
    while (_n > 1 && string_width(string_copy(_txt, 1, _n)) * UI_S > _maxw - 24) _n -= 1;
    return string_copy(_txt, 1, _n) + "..";
}

/// Draw one line fitted to its column. The fitted result is audited too: a
/// wrong column width or a helper bug fails the normal layout suite.
function story_text_fit(_x, _y, _txt, _font, _col, _align, _maxw) {
    var _fit = text_fit_px(_txt, _font, _maxw);
    ui_audit_text_fit(_fit, _font, _maxw, _txt);
    dui_text(_x, _y, _fit, _font, _col, _align);
}

/// Draw up to _maxlines wrapped lines. A line that still exceeds the column,
/// or copy that needs more lines than the card reserves, is a layout failure.
function story_text_wrap(_x, _y, _txt, _font, _col, _align, _maxw, _maxlines, _lineh) {
    var _lines = text_wrap_px(_txt, _font, _maxw);
    var _n = min(_maxlines, array_length(_lines));
    for (var _i = 0; _i < _n; _i++) {
        ui_audit_text_fit(_lines[_i], _font, _maxw, _txt);
        dui_text(_x, _y + _i * _lineh, _lines[_i], _font, _col, _align);
    }
    if (array_length(_lines) > _maxlines) {
        ui_audit_fail("story text needs " + string(array_length(_lines))
                      + " lines, max " + string(_maxlines) + ": " + _txt);
    }
}

function story_button(_x, _y, _w, _h, _label, _hot, _down) {
    var _fit = text_fit_px(_label, global.fnt_small, _w - 16);
    ui_audit_text_fit(_fit, global.fnt_small, _w - 16, _label);
    dui_button(_x, _y, _w, _h, _fit, _hot, _down);
}

function guide_wrap_px(_txt, _maxw) {
    return text_wrap_px(_txt, global.fnt_small, _maxw);
}

function guide_fit_text_px(_txt, _maxw) {
    return text_fit_px(_txt, global.fnt_small, _maxw);
}

/// A lesson page wrapped for the native card, using the same five-line budget
/// as the manual so a page can never outgrow the space it is given.
function guide_lines_px(_page, _maxw) {
    var _out = [];
    for (var _i = 0; _i < array_length(_page.lines); _i++) {
        var _wrapped = guide_wrap_px(_page.lines[_i], _maxw);
        for (var _j = 0; _j < array_length(_wrapped); _j++) {
            array_push(_out, _wrapped[_j]);
        }
    }
    return _out;
}

/// The Hollow's lesson card, on the same native canvas as the cafe card but
/// in the dark palette. Draw and input share this one geometry.
function guide_dark_ui() {
    var _c = { x: 510, y: 250, w: 900, h: 520 };
    var _bw = 180, _gap = 18;
    var _total = 4 * _bw + 3 * _gap;
    var _bx = _c.x + floor((_c.w - _total) * 0.5);
    var _by = _c.y + _c.h - 88;
    var _btns = [];
    for (var _i = 0; _i < 4; _i++) {
        array_push(_btns, { x: _bx + _i * (_bw + _gap), y: _by,
                            w: _bw, h: UI_H_CTA });
    }
    return {
        card: _c,
        close: { x: _c.x + _c.w - 64, y: _c.y + UI_SPACE_M,
                 w: UI_W_SQUARE, h: UI_H_CONTROL },
        buttons: _btns
    };
}
