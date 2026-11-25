/// @description four zones, their unlocks and the swap logic

#macro ZONE_COUNT 6

function zones_init() {
    global.ZONE = [
        { name: "COZY CORNER", at: 0,         wall: $F0D9C4, floor: $B5793F },
        { name: "CAT GARDEN",  at: 25000,     wall: $D0F0E0, floor: $7FCB5C },
        { name: "ROOFTOP",     at: 500000,    wall: $6E4A7A, floor: $4A3358 },
        { name: "CLOUD CAFE",  at: 5000000,   wall: $F5C8E4, floor: $E8B7D8 },
        { name: "TEA HOUSE",   at: 250000000, wall: $D8C9A8, floor: $8A6A4A },
        { name: "STAR LIBRARY", at: 25000000000, wall: $4A3A6E, floor: $2A2240 }
    ];
}

/// Highest zone the player has earned, capped at the last one.
function zone_unlocked() {
    var _z = 0;
    for (var i = 0; i < ZONE_COUNT; i++) {
        if (global.G.lifetime_earned >= global.ZONE[i].at) _z = i;
    }
    return _z;
}

/// Returns a zone index if the player just earned one, else -1. A player who
/// has walked back to a lower room stays there: auto-advancing every frame
/// would make the ROOMS control useless.
function zone_check() {
    if (global.G.world.pinned) return -1;
    var _want = zone_unlocked();
    if (_want > global.G.world.zone) return _want;
    return -1;
}

function zone_name(_i) {
    return global.ZONE[clamp(_i, 0, ZONE_COUNT - 1)].name;
}

function zone_enter(_i) {
    global.G.world.zone = clamp(_i, 0, min(zone_unlocked(), ZONE_COUNT - 1));
    // Choosing the newest room releases the pin; choosing an older one holds it.
    global.G.world.pinned = (global.G.world.zone < zone_unlocked()) ? 1 : 0;
    global.zone_flash  = 1;
    global.zone_banner = 80;
    sfx(snd_zone, 1);
    save_touch();
}

/// Rooms are earned automatically, but they are not one-way. Once a second
/// room opens, a small ROOMS control lets the player walk back to the cafe --
/// which is also the only place the pantry wall exists.
function zone_travel_available() {
    return zone_unlocked() > 0;
}

// The room rail is native UI now: one fixed toggle, one panel, one row height.
// It uses the same 140x40 control and 44px row as the other native rails, so
// it cannot grow back into a room-scale button. Geometry is shared by draw and
// input.
function zone_rooms_toggle_rect() {
    return { x: 32, y: 112, w: UI_W_CONTROL, h: UI_H_CONTROL };
}

#macro ROOM_ROW_H 64

function zone_rooms_card_rect() {
    var _n = zone_unlocked() + 1;
    // Two text rows (room/level and next rung) plus the meter. The footer holds
    // the active companion, so the ladder is legible without a second panel.
    return { x: 32, y: 168, w: 424,
             h: 76 + _n * (ROOM_ROW_H + UI_SPACE_XS) + 52 + 56 };
}

/// One story action for whichever room the player is standing in. The panel
/// already owns room travel; this adds the authored layer without a second
/// hit box on each row.
function zone_room_story_rect() {
    var _c = zone_rooms_card_rect();
    return { x: _c.x + 12, y: _c.y + _c.h - 96, w: _c.w - 24, h: UI_H_ROW };
}

function zone_room_rect(_i) {
    return { x: 44, y: 224 + _i * (ROOM_ROW_H + UI_SPACE_XS), w: 400, h: ROOM_ROW_H };
}

/// -2 = the control was used and the list should toggle; -1 = nothing.
function zone_travel_click(_open) {
    if (!zone_travel_available()) return -1;
    var _t = zone_rooms_toggle_rect();
    if (dui_clicked(_t.x, _t.y, _t.w, _t.h)) return -2;
    if (!_open) return -1;
    var _story = zone_room_story_rect();
    if (venue_arc_open(global.G.world.zone)
        && dui_clicked(_story.x, _story.y, _story.w, _story.h)) return -3;
    var _rooms = zone_unlocked();
    for (var _i = 0; _i <= _rooms; _i++) {
        var _r = zone_room_rect(_i);
        if (dui_clicked(_r.x, _r.y, _r.w, _r.h)) return _i;
    }
    if (mouse_check_button_pressed(mb_left)) return -2;
    return -1;
}

function zone_travel_draw(_open) {
    if (!zone_travel_available()) return;
    // The room-name card is the bigger moment; the control returns after it.
    if (global.zone_banner > 0) return;
    if (ui_modal_open()) return;

    // This is called from the GUI layer; native coordinates, no room scaling.
    dui_begin();

    var _t = zone_rooms_toggle_rect();
    dui_pill(_t.x, _t.y, _t.w, _t.h, "ROOMS", _open,
             dui_hover(_t.x, _t.y, _t.w, _t.h));
    if (!_open) return;

    var _c = zone_rooms_card_rect();
    draw_set_alpha(0.28);
    draw_set_colour(P_INK);
    draw_roundrect_ext(_c.x + 6, _c.y + 8, _c.x + _c.w + 6, _c.y + _c.h + 8, 12, 12, false);
    draw_set_alpha(1);
    dui_nine(spr_ui_panel, _c.x, _c.y, _c.w, _c.h, 6);
    dui_text(_c.x + UI_SPACE_M, _c.y + 12, "ROOMS", global.fnt_big, P_INK, fa_left);
    dui_text(_c.x + _c.w - UI_SPACE_M, _c.y + 20, "TAPS TRAIN",
             global.fnt_small, P_BROWN, fa_right);
    draw_set_colour(P_WOOD);
    draw_rectangle(_c.x + UI_SPACE_M, _c.y + 52,
                   _c.x + _c.w - UI_SPACE_M, _c.y + 54, false);

    // One row height, one text baseline, one meter baseline, for every room.
    var _rooms = zone_unlocked();
    for (var _i = 0; _i <= _rooms; _i++) {
        var _r = zone_room_rect(_i);
        var _on = (global.G.world.zone == _i);
        var _lv = room_mastery_level(_i);
        var _pr = room_mastery_progress(_i);

        dui_nine(spr_ui_row, _r.x, _r.y, _r.w, _r.h, 4);
        if (_on) {
            draw_set_alpha(0.14);
            draw_set_colour(P_GOLD);
            draw_roundrect_ext(_r.x + 2, _r.y + 2, _r.x + _r.w - 2,
                               _r.y + _r.h - 2, 6, 6, false);
            draw_set_alpha(1);
            draw_set_colour(P_CORAL);
            draw_rectangle(_r.x, _r.y + 5, _r.x + 4, _r.y + _r.h - 5, false);
        }

        if (era_unlocked() && era_featured_room() == _i) {
            draw_set_colour(P_GOLD);
            draw_circle(_r.x + 14, _r.y + 16, 3, false);
        }
        dui_text(_r.x + 26, _r.y + 2, zone_name(_i), global.fnt_small,
                 _on ? P_CORAL : P_INK, fa_left);
        dui_text(_r.x + _r.w - 16, _r.y + 2, "Lv " + string(_lv) + "/" + string(ROOM_MASTERY_MAX),
                 global.fnt_small, (_lv > 0) ? P_GOLD : P_BROWN, fa_right);
        var _nr = room_next_rung(_i);
        var _nr_name = (is_struct(_nr) && variable_struct_exists(_nr, "name"))
                     ? _nr.name : "NEXT RUNG";
        dui_text(_r.x + 26, _r.y + 28, "NEXT: " + _nr_name,
                 global.fnt_small, P_BROWN, fa_left);
        if (_lv >= ROOM_MASTERY_MAX) {
            dui_text(_r.x + _r.w - 16, _r.y + 28, "MASTERED",
                     global.fnt_small, P_GOLD, fa_right);
        }
        draw_set_colour(P_WOOD);
        draw_rectangle(_r.x + 26, _r.y + 50, _r.x + _r.w - 16, _r.y + 54, false);
        if (_pr > 0) {
            draw_set_colour(_lv >= ROOM_MASTERY_MAX ? P_GOLD : P_CORAL);
            draw_rectangle(_r.x + 26, _r.y + 50,
                           _r.x + 26 + (_r.w - 42) * _pr, _r.y + 54, false);
        }
    }

    // The current room's story is the one action the panel adds below the
    // ladder. It changes with the room, so walking is how the player browses
    // which story to continue.
    if (venue_arc_open(global.G.world.zone)) {
        var _s = zone_room_story_rect();
        var _si = global.G.world.zone;
        var _slabel = "START THIS ROOM'S STORY";
        if (venue_arc_done(_si)) {
            _slabel = "STORY KEPT - " + venue_arc_perk_name(_si);
        } else if (venue_arc_started(_si)) {
            _slabel = "CONTINUE STORY - " + venue_arc_title(_si);
        }
        dui_button(_s.x, _s.y, _s.w, _s.h,
                   guide_fit_text_px(_slabel, _s.w - 32),
                   dui_hover(_s.x, _s.y, _s.w, _s.h), false);
    }

    var _comp = room_companion();
    var _foot = "NO COMPANION - CHOOSE ONE IN CATS";
    if (_comp >= 0 && _comp < album_count() && is_struct(global.CAT[_comp])) {
        _foot = "WITH YOU: " + string_upper(global.CAT[_comp].n)
              + "   BOND " + string(cat_bond_rank(_comp)) + "/" + string(CAT_BOND_MAX);
    }
    dui_text(_c.x + UI_SPACE_M, _c.y + _c.h - 38, _foot,
             global.fnt_small, P_BROWN, fa_left);
}

/// The room-name flourish after a walk, on the native GUI layer. It uses the
/// same 64px plate as the persistent Hollow nav, so a room name is a banner,
/// not a giant button inherited from the old 4x canvas.
function zone_banner_draw_gui() {
    if (global.zone_banner <= 0) return;
    dui_begin();
    var _ln = zone_name(global.G.world.zone);
    var _w = dui_text_w(_ln, global.fnt_big) + 64;
    var _x = floor((1264 - _w) * 0.5);
    var _y = 160;

    dui_nine(spr_ui_panel, _x, _y, _w, UI_H_NAV, 6);
    dui_text(_x + _w * 0.5, _y + 16, _ln, global.fnt_big, P_INK, fa_center);
}

/// Gentle parallax, for things that are genuinely far away (hills, skyline,
/// clouds). The room's own walls never move: a window mounted a metre in front
/// of you does not slide when you look around, and in a 480px room an 8px
/// drift reads as the whole cafe wobbling.
function zone_parallax() {
    if (global.G.settings.reduce_motion) return 0;
    var _target = (device_mouse_x_to_gui(0) / UI_W - 0.5) * 6;
    global.par_x = lerp(global.par_x, clamp(_target, -3, 3), 0.05);
    return global.par_x;
}

// ---------------------------------------------------------------- room mastery
// Tapping is the one verb every room shares. A room remembers the taps made
// inside it, and every few hundred raises its mastery by one level. Levels are
// small (+1% output each) but permanent, so a late player has a reason to move
// the big cat around instead of only buying the newest row.
#macro ROOM_MASTERY_MAX 12

function room_defaults() {
    // Room mastery only. Cat bonds and the active companion belong to the
    // album, under global.G.bonds / global.G.companion.
    return { mastery: array_create(ZONE_COUNT, 0) };
}

function room_mastery_steps() {
    // Long on purpose: 326k taps takes a room from first visit to mastered,
    // and every six-room sweep is a meaningful chapter rather than a purchase.
    return [150, 500, 1200, 2600, 4800, 8200,
            13500, 21500, 33000, 50000, 76000, 115000];
}

function room_mastery_level(_z) {
    if (!variable_struct_exists(global.G, "rooms") || !is_struct(global.G.rooms)) return 0;
    if (!is_array(global.G.rooms.mastery)) return 0;
    if (_z < 0 || _z >= array_length(global.G.rooms.mastery)) return 0;
    var _pts = global.G.rooms.mastery[_z];
    var _steps = room_mastery_steps();
    var _lv = 0;
    for (var _i = 0; _i < array_length(_steps); _i++) {
        if (_pts >= _steps[_i]) _lv = _i + 1;
    }
    return _lv;
}

/// Progress toward the next level, 0..1. A maxed room shows a full bar.
function room_mastery_progress(_z) {
    var _lv = room_mastery_level(_z);
    if (_lv >= ROOM_MASTERY_MAX) return 1;
    var _steps = room_mastery_steps();
    var _pts = global.G.rooms.mastery[_z];
    var _from = (_lv == 0) ? 0 : _steps[_lv - 1];
    return clamp((_pts - _from) / max(1, _steps[_lv] - _from), 0, 1);
}

function room_mastery_total() {
    var _n = 0;
    for (var _i = 0; _i < ZONE_COUNT; _i++) _n += room_mastery_level(_i);
    return _n;
}

/// Every level in every room adds one percent to the cafe, permanently.
function room_mastery_mult() {
    return 1 + room_mastery_total() * 0.01;
}

/// What the next rung changes. These are rules and tempo, not a single
/// multiplier, so a room keeps giving the player new verbs after its level
/// number stops being the headline.
function room_rung(_rank) {
    switch (clamp(_rank, 1, ROOM_MASTERY_MAX)) {
        case 1:  return { name: "COMBO +1",       kind: "combo", val: 1 };
        case 2:  return { name: "CRIT +1%",       kind: "crit",  val: 0.01 };
        case 3:  return { name: "TREAT EVERY 12", kind: "treat", val: 12 };
        case 4:  return { name: "BOND +25%",      kind: "bond",  val: 0.25 };
        case 5:  return { name: "GRACE +100MS",   kind: "grace", val: 100 };
        case 6:  return { name: "AUTO-PET 4S",    kind: "auto",  val: 240 };
        case 7:  return { name: "CRIT +1%",       kind: "crit",  val: 0.01 };
        case 8:  return { name: "COMBO +2",       kind: "combo", val: 2 };
        case 9:  return { name: "BOND +25%",      kind: "bond",  val: 0.25 };
        case 10: return { name: "TREAT EVERY 8",  kind: "treat", val: 8 };
        case 11: return { name: "AUTO-PET 3S",    kind: "auto",  val: 180 };
        default: return { name: "AUTO-PET 2S",    kind: "auto",  val: 120 };
    }
}

function room_next_rung(_z) {
    var _lv = room_mastery_level(_z);
    if (_lv >= ROOM_MASTERY_MAX) return { name: "ALL RUNGS EARNED", kind: "max", val: 0 };
    return room_rung(_lv + 1);
}

function room_rung_sum(_z, _kind) {
    var _sum = 0;
    var _lv = room_mastery_level(_z);
    for (var _i = 1; _i <= _lv; _i++) {
        var _g = room_rung(_i);
        if (is_struct(_g) && _g.kind == _kind) _sum += _g.val;
    }
    return _sum;
}

function room_combo_bonus(_z)  { return room_rung_sum(_z, "combo"); }
function room_crit_bonus(_z)   { return room_rung_sum(_z, "crit"); }
function room_combo_window(_z){ return 900 + room_rung_sum(_z, "grace"); }
function room_bond_mult(_z)    { return 1 + room_rung_sum(_z, "bond"); }

/// The best treat interval unlocked in this room, or 0 before rank 3.
function room_treat_every(_z) {
    var _lv = room_mastery_level(_z);
    if (_lv >= 10) return 8;
    if (_lv >= 3) return 12;
    return 0;
}

/// Frames between automatic pets. 0 means the room has not earned one yet.
function room_auto_pet_frames(_z) {
    var _lv = room_mastery_level(_z);
    if (_lv >= 12) return 120;
    if (_lv >= 11) return 180;
    if (_lv >= 6) return 240;
    return 0;
}

/// One manual tap in a room. The era's featured room earns double, which is
/// the gentle nudge that makes the Era card and the ROOMS list one system.
/// The same tap feeds the active cat's bond, doubled in its home room.
function room_tap_add(_z) {
    if (!variable_struct_exists(global.G, "rooms") || !is_struct(global.G.rooms)) return;
    if (!is_array(global.G.rooms.mastery)) global.G.rooms.mastery = array_create(ZONE_COUNT, 0);
    if (_z < 0 || _z >= array_length(global.G.rooms.mastery)) return;
    var _add = 1;
    if (era_unlocked() && era_featured_room() == _z) _add = 2;
    global.G.rooms.mastery[_z] += _add;
    cat_bond_add(room_companion(), _z);
}

function room_normalize() {
    if (!variable_struct_exists(global.G, "rooms") || !is_struct(global.G.rooms)) {
        global.G.rooms = room_defaults();
    }
    if (!variable_struct_exists(global.G.rooms, "mastery")
        || !is_array(global.G.rooms.mastery)) {
        global.G.rooms.mastery = array_create(ZONE_COUNT, 0);
    }
    array_resize(global.G.rooms.mastery, ZONE_COUNT);
    for (var _i = 0; _i < ZONE_COUNT; _i++) {
        if (!is_numeric(global.G.rooms.mastery[_i])) global.G.rooms.mastery[_i] = 0;
        global.G.rooms.mastery[_i] = max(0, global.G.rooms.mastery[_i]);
    }
}
