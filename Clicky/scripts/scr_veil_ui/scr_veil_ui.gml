/// The Hollow's native shell. Every player-facing screen below is laid out in
/// 1920x1080 pixels, on the same spacing and type scale as the cafe, but with
/// iron, bone and old blood instead of cream and coral. The 480x270 rooms stay
/// as the illustrated backdrop; no control or reading text is drawn through
/// the 4x room matrix any more.
///
/// Draw, input and the verification harness all read the same *_ui() functions,
/// so a hit box can never drift away from the plate the player sees.

#macro VUI_MX     96
#macro VUI_TOP    160
#macro VUI_BOT    936
#macro VUI_HEADER 128
#macro VUI_NAV_Y  952
#macro VUI_NAV_H  UI_H_NAV

// ---------------------------------------------------------------- dark kit

function dui_vtext(_x, _y, _txt, _font, _col, _align) {
    ui_audit_font(_font);
    ui_audit_text(_x, _y);
    draw_set_font(_font);
    draw_set_halign(_align);
    draw_set_valign(fa_top);
    draw_set_alpha(0.9);
    draw_set_colour(V_VOID);
    draw_text_transformed(_x + 2, _y + 2, _txt, UI_S, UI_S, 0);
    draw_set_alpha(1);
    draw_set_colour(_col);
    draw_text_transformed(_x, _y, _txt, UI_S, UI_S, 0);
    draw_set_halign(fa_left);
}

function dui_vtext_w(_txt, _font) {
    ui_audit_font(_font);
    draw_set_font(_font);
    return string_width(_txt) * UI_S;
}

function dui_vtext_h(_font) {
    draw_set_font(_font);
    return string_height("Ag") * UI_S;
}

/// A black iron card with rivets and one wax-red accent. This is the only
/// surface a Hollow control sits on, so the layer reads as one place.
function dui_vpanel(_x, _y, _w, _h, _accent) {
    draw_set_alpha(0.55);
    draw_set_colour(V_VOID);
    draw_roundrect_ext(_x + 8, _y + 10, _x + _w + 8, _y + _h + 10, 8, 8, false);
    draw_set_alpha(1);

    draw_set_colour(V_IRON);
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 6, 6, false);
    draw_set_colour(V_BLACK);
    draw_roundrect_ext(_x + 2, _y + 2, _x + _w - 2, _y + _h - 2, 4, 4, false);
    draw_set_colour(V_IRON_HI);
    draw_rectangle(_x + 4, _y + 3, _x + _w - 4, _y + 5, false);
    if (_accent) {
        draw_set_colour(V_BLOOD_HI);
        draw_rectangle(_x + 3, _y + 8, _x + 6, _y + _h - 8, false);
    }
    draw_set_colour(V_IRON_HI);
    draw_circle(_x + 13, _y + 13, 2, false);
    draw_circle(_x + _w - 13, _y + 13, 2, false);
    draw_circle(_x + 13, _y + _h - 13, 2, false);
    draw_circle(_x + _w - 13, _y + _h - 13, 2, false);
}

function dui_vbutton(_x, _y, _w, _h, _label, _hot, _on, _enabled) {
    ui_audit_control("dark button", _x, _y, _w, _h);
    var _fill = _on ? V_BLOOD : (_hot ? vc(52, 30, 33) : vc(26, 20, 23));
    var _edge = (_on || _hot) ? V_BLOOD_HI : V_IRON_HI;
    if (!_enabled) {
        _fill = vc(20, 16, 18);
        _edge = V_IRON;
    }
    draw_set_colour(_edge);
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 5, 5, false);
    draw_set_colour(_fill);
    draw_roundrect_ext(_x + 2, _y + 2, _x + _w - 2, _y + _h - 2, 3, 3, false);
    draw_set_colour(_enabled ? V_IRON_HI : V_IRON);
    draw_rectangle(_x + 10, _y + _h - 4, _x + _w - 10, _y + _h - 2, false);

    var _tw = dui_vtext_w(_label, global.fnt_small);
    var _th = dui_vtext_h(global.fnt_small);
    var _col = _enabled ? (_on ? V_BONE : V_BONE) : vc(86, 78, 74);
    dui_vtext(_x + floor((_w - _tw) * 0.5), _y + floor((_h - _th) * 0.5) - 1,
              _label, global.fnt_small, _col, fa_left);
}

function dui_vpill(_x, _y, _w, _h, _label, _on, _hot) {
    ui_audit_control("dark pill", _x, _y, _w, _h);
    var _fill = _on ? V_BLOOD : (_hot ? vc(45, 28, 31) : V_BLACK);
    var _edge = _on ? V_BLOOD_HI : V_IRON;
    draw_set_colour(_edge);
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 6, 6, false);
    draw_set_colour(_fill);
    draw_roundrect_ext(_x + 2, _y + 2, _x + _w - 2, _y + _h - 2, 4, 4, false);
    var _tw = dui_vtext_w(_label, global.fnt_small);
    var _th = dui_vtext_h(global.fnt_small);
    dui_vtext(_x + floor((_w - _tw) * 0.5), _y + floor((_h - _th) * 0.5) - 1,
              _label, global.fnt_small, _on ? V_BONE : V_BONE_DIM, fa_left);
}

function dui_vbar(_x, _y, _w, _h, _frac, _col) {
    draw_set_colour(V_IRON);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_colour(V_VOID);
    draw_rectangle(_x + 2, _y + 2, _x + _w - 2, _y + _h - 2, false);
    var _fill = clamp(_frac, 0, 1) * (_w - 4);
    if (_fill > 0) {
        draw_set_colour(_col == undefined ? V_BLOOD_HI : _col);
        draw_rectangle(_x + 2, _y + 2, _x + 2 + _fill, _y + _h - 2, false);
    }
}

function dui_vglow(_cx, _cy, _r, _col, _a) {
    draw_set_alpha(_a);
    draw_set_colour(_col);
    draw_circle(_cx, _cy, _r, false);
    draw_set_alpha(_a * 0.55);
    draw_circle(_cx, _cy, _r * 1.8, false);
    draw_set_alpha(1);
}

/// The five map doors, drawn in a 20x20 local box then scaled by the matrix.
function veil_door_icon(_kind, _x, _y) {
    switch (_kind) {
        case 1: // candle
            draw_set_colour(V_WAX);
            draw_rectangle(_x + 8, _y + 8, _x + 11, _y + 20, false);
            draw_set_colour(V_EMBER);
            draw_circle(_x + 9, _y + 5, 3, false);
            veil_glow(_x + 9, _y + 5, 4, V_EMBER, 0.2);
            break;
        case 2: // bed
            draw_set_colour(vc(54, 40, 28));
            draw_rectangle(_x + 2, _y + 10, _x + 18, _y + 20, false);
            draw_set_colour(vc(44, 58, 40));
            draw_line(_x + 10, _y + 10, _x + 7, _y + 2);
            draw_line(_x + 10, _y + 10, _x + 14, _y + 3);
            break;
        case 3: // door
            draw_set_colour(vc(40, 28, 26));
            draw_rectangle(_x + 4, _y + 2, _x + 16, _y + 20, false);
            draw_set_colour(V_IRON);
            draw_rectangle(_x + 6, _y + 4, _x + 14, _y + 18, false);
            draw_set_colour(V_WAX);
            draw_circle(_x + 13, _y + 12, 1, false);
            break;
        case 4: // bottle
            draw_set_colour(V_WAX);
            draw_rectangle(_x + 8, _y + 2, _x + 11, _y + 7, false);
            draw_set_colour(vc(70, 96, 82));
            draw_roundrect_ext(_x + 4, _y + 7, _x + 15, _y + 20, 2, 2, false);
            break;
        case 5: // table
            draw_set_colour(vc(64, 30, 26));
            draw_rectangle(_x + 1, _y + 10, _x + 19, _y + 15, false);
            draw_set_colour(V_WAX);
            draw_rectangle(_x + 4, _y + 4, _x + 5, _y + 10, false);
            draw_rectangle(_x + 14, _y + 4, _x + 15, _y + 10, false);
            break;
    }
}

/// This runtime has no draw_set_transform, so native icon scaling goes through
/// the world matrix. Translation is applied after scale, exactly like a draw
/// transform; the identity is restored before any text or plate is drawn.
function dui_vicon(_kind, _cx, _cy, _s) {
    matrix_set(matrix_world, matrix_build(_cx - 7 * _s, _cy - 7 * _s, 0,
                                          0, 0, 0, _s, _s, 1));
    veil_icon(_kind, 0, 0);
    matrix_set(matrix_world, matrix_build_identity());
}

function dui_vdooricon(_kind, _cx, _cy, _s) {
    matrix_set(matrix_world, matrix_build(_cx - 10 * _s, _cy - 10 * _s, 0,
                                          0, 0, 0, _s, _s, 1));
    veil_door_icon(_kind, 0, 0);
    matrix_set(matrix_world, matrix_build_identity());
}

function dui_vcat(_x, _gy, _s, _coat, _frame, _eyes) {
    matrix_set(matrix_world, matrix_build(_x, _gy, 0, 0, 0, 0, _s, _s, 1));
    veil_cat(0, 0, 1.0, _coat, _frame, _eyes);
    matrix_set(matrix_world, matrix_build_identity());
}

/// The Hollow has no light UI chrome, so its vignette is native too: a hollow
/// of darkness at the edges, never a tinted 480 frame.
function veil_native_vignette() {
    draw_set_alpha(0.42);
    draw_set_colour(V_VOID);
    draw_rectangle(0, 0, 40, UI_H, false);
    draw_rectangle(UI_W - 40, 0, UI_W, UI_H, false);
    draw_rectangle(0, VUI_HEADER, UI_W, VUI_HEADER + 18, false);
    draw_rectangle(0, UI_H - 128, UI_W, UI_H, false);
    draw_set_alpha(1);
}

// ---------------------------------------------------------------- shell frame

function veil_wake_rect() {
    return { x: 1728, y: 36, w: 160, h: UI_H_CTA };
}

function veil_nav_rects() {
    return {
        map:    { x: VUI_MX,          y: VUI_NAV_Y, w: 176, h: VUI_NAV_H, mode: 0 },
        rites:  { x: VUI_MX + 192,    y: VUI_NAV_Y, w: 176, h: VUI_NAV_H, mode: 6 },
        relics: { x: VUI_MX + 384,    y: VUI_NAV_Y, w: 176, h: VUI_NAV_H, mode: 7 },
        night:  { x: VUI_MX + 576,    y: VUI_NAV_Y, w: 176, h: VUI_NAV_H, mode: 8 }
    };
}

function veil_header_draw(_title, _sub) {
    draw_set_colour(V_VOID);
    draw_rectangle(0, 0, UI_W, VUI_HEADER, false);
    draw_set_colour(V_IRON);
    draw_rectangle(0, VUI_HEADER - 6, UI_W, VUI_HEADER, false);
    draw_set_colour(V_BLOOD);
    draw_rectangle(0, VUI_HEADER - 8, UI_W, VUI_HEADER - 6, false);

    dui_vtext(VUI_MX, 30, _title, global.fnt_big, V_BONE, fa_left);
    dui_vtext(VUI_MX, 80, _sub, global.fnt_small, V_BONE_DIM, fa_left);

    var _o = global.G.occult;
    var _chips = [
        { x: 1208, kind: 0, n: floor(_o.embers),    col: V_EMBER },
        { x: 1376, kind: 1, n: floor(_o.whispers),  col: V_BONE },
        { x: 1544, kind: 2, n: floor(_o.blood),     col: V_BLOOD_HI }
    ];
    for (var _i = 0; _i < array_length(_chips); _i++) {
        var _c = _chips[_i];
        dui_vpanel(_c.x, 36, 152, 56, 0);
        dui_vicon(_c.kind, _c.x + 28, 64, 2);
        dui_vtext(_c.x + 54, 50, fmt_number(_c.n), global.fnt_small, _c.col, fa_left);
    }

    var _w = veil_wake_rect();
    dui_vbutton(_w.x, _w.y, _w.w, _w.h, "WAKE", dui_hover(_w.x, _w.y, _w.w, _w.h), false, true);
}

function veil_nav_draw(_mode) {
    draw_set_colour(V_VOID);
    draw_rectangle(0, 944, UI_W, UI_H, false);
    draw_set_colour(V_IRON);
    draw_rectangle(0, 944, UI_W, 948, false);
    draw_set_colour(V_BLOOD);
    draw_rectangle(0, 948, UI_W, 950, false);

    var _n = veil_nav_rects();
    var _night_open = veil_loc_open(5);
    var _items = [_n.map, _n.rites, _n.relics, _n.night];
    var _labels = ["MAP", "RITES", "RELICS", "NIGHT"];
    for (var _i = 0; _i < 4; _i++) {
        var _r = _items[_i];
        var _enabled = (_i < 3) || _night_open;
        var _on = (_mode == _r.mode);
        dui_vbutton(_r.x, _r.y, _r.w, _r.h, _labels[_i],
                    _enabled && dui_hover(_r.x, _r.y, _r.w, _r.h), _on, _enabled);
    }
    if (!_night_open) {
        dui_vtext(_n.night.x + 88, 1020, "CLOSINGS " + string(global.G.occult.closings)
                  + "/" + string(veil_loc_need(5)), global.fnt_small, vc(110, 96, 88), fa_center);
    }

    dui_vtext(UI_W - VUI_MX, 968, "3:33", global.fnt_big, V_BLOOD_HI, fa_right);
    dui_vtext(UI_W - VUI_MX, 1012, "THE CAFE IS STILL OPEN. IT IS NOT FOR YOU.",
              global.fnt_small, vc(96, 84, 78), fa_right);
}

function veil_nav_click() {
    var _n = veil_nav_rects();
    if (dui_clicked(_n.map.x, _n.map.y, _n.map.w, _n.map.h)) return 0;
    if (dui_clicked(_n.rites.x, _n.rites.y, _n.rites.w, _n.rites.h)) return 6;
    if (dui_clicked(_n.relics.x, _n.relics.y, _n.relics.w, _n.relics.h)) return 7;
    if (veil_loc_open(5) && dui_clicked(_n.night.x, _n.night.y, _n.night.w, _n.night.h)) return 8;
    return -1;
}

function veil_title_card_native(_a) {
    if (_a <= 0) return;
    draw_set_alpha(0.88 * _a);
    draw_set_colour(V_VOID);
    draw_rectangle(0, 0, UI_W, UI_H, false);
    draw_set_alpha(_a);
    draw_set_colour(V_BLOOD);
    draw_rectangle(0, 494, UI_W, 500, false);
    draw_rectangle(0, 604, UI_W, 610, false);
    dui_vtext(UI_W * 0.5, 430, "THE HOLLOW HOUR", global.fnt_big, V_BONE, fa_center);
    dui_vtext(UI_W * 0.5, 522, "THE CAFE IS STILL OPEN. IT IS NOT FOR YOU.",
              global.fnt_small, V_BONE_DIM, fa_center);
    dui_vtext(UI_W * 0.5, 650, "CLICK TO DESCEND", global.fnt_small,
              vc(120, 104, 92), fa_center);
    draw_set_alpha(1);
}

// ---------------------------------------------------------------- map

function veil_map_door_x(_i) {
    return 97 + _i * 350;
}

function veil_map_ui() {
    var _doors = [];
    for (var _i = 0; _i < VEIL_LOC_COUNT; _i++) {
        array_push(_doors, { x: veil_map_door_x(_i), y: 184, w: 326, h: 436,
                             loc: _i + 1, open: veil_loc_open(_i + 1),
                             mastery: veil_mastery_label(_i + 1) });
    }
    var _ledger = { x: VUI_MX, y: 640, w: 1728, h: 264 };
    return {
        doors: _doors,
        ledger: _ledger,
        claim: { x: _ledger.x + 1400, y: _ledger.y + 78, w: 280, h: UI_H_CTA }
    };
}

function veil_map_draw() {
    var _o = global.G.occult;
    var _u = veil_map_ui();

    dui_vtext(VUI_MX, VUI_TOP - 6, "FIVE DOORS. ONE CAFE.", global.fnt_small,
              V_BONE_DIM, fa_left);

    for (var _i = 0; _i < array_length(_u.doors); _i++) {
        var _d = _u.doors[_i];
        var _hot = dui_hover(_d.x, _d.y, _d.w, _d.h);
        var _name = veil_loc_name(_d.loc);
        var _lines = guide_wrap_px(_name, _d.w - 44);

        dui_vpanel(_d.x, _d.y, _d.w, _d.h, _hot);

        // The arch is the room; its shape is what says "door", not an icon.
        var _ax = _d.x + 34, _ay = _d.y + 30, _aw = _d.w - 68, _ah = 242;
        draw_set_colour(_d.open ? V_IRON : vc(26, 21, 23));
        draw_rectangle(_ax - 3, _ay + 20, _ax + _aw + 3, _ay + _ah, false);
        draw_triangle(_ax - 3, _ay + 20, _ax + _aw * 0.5, _ay - 10, _ax + _aw + 3, _ay + 20, false);
        draw_set_colour(_d.open ? vc(34, 22, 24) : vc(15, 12, 14));
        draw_rectangle(_ax, _ay + 20, _ax + _aw, _ay + _ah, false);
        draw_triangle(_ax, _ay + 20, _ax + _aw * 0.5, _ay - 4, _ax + _aw, _ay + 20, false);

        if (_d.open) {
            draw_set_alpha(0.16 + 0.05 * sin(global.time * 2 + _i));
            draw_set_colour(V_EMBER);
            draw_rectangle(_ax + 4, _ay + 24, _ax + _aw - 4, _ay + _ah - 4, false);
            draw_set_alpha(1);
            dui_vglow(_d.x + _d.w * 0.5, _ay + 118, 72, V_EMBER, 0.10);
            dui_vdooricon(_d.loc, _d.x + _d.w * 0.5, _ay + 118, 4);

            var _rank = veil_mastery_rank(_d.loc);
            for (var _p = 0; _p < 5; _p++) {
                draw_set_colour(_p < _rank ? V_BLOOD_HI : V_IRON);
                draw_circle(_d.x + _d.w * 0.5 - 40 + _p * 20, _d.y + 386, 5, false);
            }
            dui_vtext(_d.x + _d.w * 0.5, _d.y + 400, _d.mastery,
                      global.fnt_small, V_BONE_DIM, fa_center);
        } else {
            draw_set_alpha(0.55);
            draw_set_colour(V_BLOOD_HI);
            draw_ellipse(_d.x + _d.w * 0.5 - 30, _ay + 106,
                         _d.x + _d.w * 0.5 - 16, _ay + 116, false);
            draw_ellipse(_d.x + _d.w * 0.5 + 16, _ay + 106,
                         _d.x + _d.w * 0.5 + 30, _ay + 116, false);
            draw_set_alpha(1);
            dui_vtext(_d.x + _d.w * 0.5, _d.y + 356,
                      "CLOSING " + string(veil_loc_need(_d.loc)),
                      global.fnt_small, vc(110, 98, 90), fa_center);
        }

        var _ty = _d.y + 292;
        for (var _l = 0; _l < min(2, array_length(_lines)); _l++) {
            dui_vtext(_d.x + _d.w * 0.5, _ty + _l * 28, _lines[_l],
                      global.fnt_small, _d.open ? V_BONE : V_BONE_DIM, fa_center);
        }
        if (_d.open) {
            dui_vtext(_d.x + _d.w * 0.5, _d.y + 352, "ENTER",
                      global.fnt_small, _hot ? V_EMBER : V_BONE_DIM, fa_center);
        }
    }

    // The ledger is the only always-visible statement of what moves the layer.
    var _lg = _u.ledger;
    dui_vpanel(_lg.x, _lg.y, _lg.w, _lg.h, 1);
    dui_vtext(_lg.x + 32, _lg.y + 22, "THE CLOSING LEDGER", global.fnt_small,
              V_BLOOD_HI, fa_left);

    var _cur = veil_closing_current();
    if (_cur < 0) {
        dui_vtext(_lg.x + 32, _lg.y + 66, "ALL THIRTEEN HEARD.", global.fnt_big,
                  V_BONE, fa_left);
        dui_vtext(_lg.x + 32, _lg.y + 118, "THE NINTH TABLE IS OPEN. DEPTH 13 ENDS THE NIGHT.",
                  global.fnt_small, V_BONE_DIM, fa_left);
    } else {
        var _def = global.VEIL_CLOSING[_cur];
        var _val = veil_closing_value(_def.key);
        var _p = clamp(_val / _def.target, 0, 1);
        dui_vtext(_lg.x + 32, _lg.y + 62,
                  "CLOSING " + string(_cur + 1) + "/13  -  " + _def.label,
                  global.fnt_small, V_BONE, fa_left);
        dui_vbar(_lg.x + 32, _lg.y + 108, 1240, 20, _p, V_BLOOD_HI);
        dui_vtext(_lg.x + 32, _lg.y + 140,
                  string(min(_val, _def.target)) + "/" + string(_def.target),
                  global.fnt_small, V_BONE_DIM, fa_left);
        dui_vtext(_lg.x + 32, _lg.y + 186,
                  "EVERY CLOSING PAYS 1 BLOOD AND 2% CAFE OUTPUT.",
                  global.fnt_small, vc(112, 100, 92), fa_left);

        if (veil_closing_ready()) {
            var _c = _u.claim;
            dui_vbutton(_c.x, _c.y, _c.w, _c.h, "HEAR IT",
                        dui_hover(_c.x, _c.y, _c.w, _c.h), true, true);
        } else {
            dui_vtext(_lg.x + 1438, _lg.y + 108, "KEEP WORKING",
                      global.fnt_small, V_BONE_DIM, fa_left);
        }
    }

    if (array_length(_o.curses) > 0) {
        dui_vtext(_lg.x + 1438, _lg.y + 186,
                  "CURSES " + string(array_length(_o.curses)),
                  global.fnt_small, V_BLOOD_HI, fa_left);
    }
}

function veil_map_click() {
    var _u = veil_map_ui();
    for (var _i = 0; _i < array_length(_u.doors); _i++) {
        var _d = _u.doors[_i];
        if (dui_clicked(_d.x, _d.y, _d.w, _d.h)) {
            if (!veil_loc_open(_d.loc)) return "locked";
            return "loc:" + string(_d.loc);
        }
    }
    var _c = _u.claim;
    if (veil_closing_ready() && dui_clicked(_c.x, _c.y, _c.w, _c.h)) {
        if (veil_closing_claim()) return "closing";
    }
    return "";
}

// ---------------------------------------------------------------- rites

function veil_up_col_x(_branch) {
    return VUI_MX + _branch * 429;
}

function veil_up_row_y(_row) {
    return 208 + _row * 110;
}

function veil_upgrades_ui() {
    var _out = [];
    for (var _b = 0; _b < 4; _b++) {
        var _row = 0;
        for (var _i = 0; _i < array_length(global.VEIL_UP); _i++) {
            var _u = global.VEIL_UP[_i];
            if (_u.branch != _b) continue;
            array_push(_out, {
                x: veil_up_col_x(_b), y: veil_up_row_y(_row),
                w: 405, h: 100, id: _u.id, branch: _b, row: _row
            });
            _row += 1;
        }
    }
    return _out;
}

function veil_upgrades_draw() {
    var _branches = ["RITE", "REACH", "RESIDUE", "ALTAR"];
    var _all = veil_upgrades_ui();

    for (var _b = 0; _b < 4; _b++) {
        dui_vtext(veil_up_col_x(_b), VUI_TOP - 2, _branches[_b], global.fnt_small,
                  _b == 3 ? V_BLOOD_HI : V_BONE_DIM, fa_left);
    }

    for (var _i = 0; _i < array_length(_all); _i++) {
        var _r = _all[_i];
        var _u = global.VEIL_UP[veil_up_find(_r.id)];
        var _lvl = veil_lvl(_u.id);
        var _maxed = veil_up_maxed(_u.id);
        var _can = veil_up_affordable(_u.id);
        var _hot = dui_hover(_r.x, _r.y, _r.w, _r.h);

        dui_vpanel(_r.x, _r.y, _r.w, _r.h, _can || _hot);
        dui_vtext(_r.x + 20, _r.y + 12, _u.name, global.fnt_small,
                  _lvl > 0 ? V_BONE : V_BONE_DIM, fa_left);
        dui_vtext(_r.x + _r.w - 20, _r.y + 12, string(_lvl) + "/" + string(_u.max),
                  global.fnt_small, _can ? V_EMBER : V_BONE_DIM, fa_right);
        dui_vtext(_r.x + 20, _r.y + 38, _u.desc, global.fnt_small,
                  _can ? vc(198, 176, 160) : vc(112, 102, 94), fa_left);

        dui_vicon(_u.cur == "b" ? 2 : 0, _r.x + 30, _r.y + 76, 2);
        dui_vtext(_r.x + 52, _r.y + 67, _maxed ? "MAX" : fmt_number(veil_up_cost(_u.id)),
                  global.fnt_small, _can ? V_EMBER : V_BONE_DIM, fa_left);
        dui_vbar(_r.x + 170, _r.y + 74, _r.w - 194, 10, _lvl / max(1, _u.max),
                 _maxed ? V_EMBER : V_BLOOD_HI);
    }
}

function veil_upgrades_click() {
    var _all = veil_upgrades_ui();
    for (var _i = 0; _i < array_length(_all); _i++) {
        var _r = _all[_i];
        if (dui_clicked(_r.x, _r.y, _r.w, _r.h)) {
            return veil_up_buy(_r.id) ? "bought" : "poor";
        }
    }
    return "";
}

// ---------------------------------------------------------------- relics

function veil_relic_cell_x(_i) {
    return 99 + (_i mod 8) * 217;
}

function veil_relic_cell_y(_i) {
    return 208 + (_i div 8) * 124;
}

function veil_relic_set_colour(_set) {
    switch (_set) {
        case 0: return V_WAX;
        case 1: return V_BONE;
        case 2: return vc(128, 92, 76);
        case 3: return V_MOSS;
        case 4: return vc(120, 98, 148);
    }
    return V_BONE_DIM;
}

function veil_relics_ui() {
    var _cells = [];
    for (var _i = 0; _i < VEIL_RELICS; _i++) {
        array_push(_cells, { x: veil_relic_cell_x(_i), y: veil_relic_cell_y(_i),
                             w: 203, h: 110, id: _i });
    }
    var _sets = [];
    for (var _s = 0; _s < 5; _s++) {
        array_push(_sets, { x: VUI_MX + _s * 348, y: 862, w: 330, h: 60, set: _s });
    }
    return { cells: _cells, sets: _sets };
}

function veil_relics_draw() {
    var _o = global.G.occult;
    var _u = veil_relics_ui();

    dui_vtext(VUI_MX, VUI_TOP - 2,
              "ENTHRONED " + string(array_length(_o.throne)) + "/"
              + string(veil_throne_slots()) + "  -  CLICK A RELIC TO SET OR LIFT IT",
              global.fnt_small, V_BONE_DIM, fa_left);
    dui_vtext(UI_W - VUI_MX, VUI_TOP - 2,
              "FOUND " + string(veil_relic_owned_total()) + "/40",
              global.fnt_small, V_EMBER, fa_right);

    for (var _i = 0; _i < array_length(_u.cells); _i++) {
        var _r = _u.cells[_i];
        var _n = veil_relic_count(_r.id);
        var _on = veil_enthroned(_r.id);
        var _rel = global.VEIL_RELIC[_r.id];
        var _hot = dui_hover(_r.x, _r.y, _r.w, _r.h);

        draw_set_colour(_n > 0 ? vc(26, 20, 24) : vc(16, 13, 15));
        draw_rectangle(_r.x, _r.y, _r.x + _r.w, _r.y + _r.h, false);
        draw_set_colour(_n > 0 ? veil_relic_set_colour(_rel.set) : V_IRON);
        draw_rectangle(_r.x, _r.y, _r.x + _r.w, _r.y + 4, false);
        if (_on) {
            draw_set_alpha(0.18);
            draw_set_colour(V_BLOOD_HI);
            draw_rectangle(_r.x + 1, _r.y + 4, _r.x + _r.w - 1, _r.y + _r.h - 1, false);
            draw_set_alpha(1);
            draw_set_colour(V_EMBER);
            draw_rectangle(_r.x, _r.y, _r.x + _r.w, _r.y + _r.h, true);
        } else if (_hot && _n > 0) {
            draw_set_colour(V_IRON_HI);
            draw_rectangle(_r.x, _r.y, _r.x + _r.w, _r.y + _r.h, true);
        }

        dui_vtext(_r.x + _r.w * 0.5, _r.y + 24, _n > 0 ? _rel.name : "? ? ?",
                  global.fnt_small, _n > 0 ? V_BONE : vc(86, 76, 72), fa_center);
        dui_vtext(_r.x + _r.w * 0.5, _r.y + 54,
                  _n > 0 ? ("x" + string(_n)) : "-",
                  global.fnt_small, _n > 0 ? V_BONE_DIM : vc(64, 58, 58), fa_center);
        if (_on) {
            dui_vtext(_r.x + _r.w * 0.5, _r.y + 82, "ENTHRONED",
                      global.fnt_small, V_EMBER, fa_center);
        }
    }

    for (var _s = 0; _s < array_length(_u.sets); _s++) {
        var _sr = _u.sets[_s];
        var _count = veil_relic_set_count(_sr.set);
        dui_vpanel(_sr.x, _sr.y, _sr.w, _sr.h, _count >= 8);
        dui_vtext(_sr.x + 20, _sr.y + 9,
                  ["WAX", "BONE", "ASH", "ROOT", "VEIL"][_sr.set],
                  global.fnt_small, _count >= 8 ? V_EMBER : V_BONE_DIM, fa_left);
        dui_vtext(_sr.x + _sr.w - 20, _sr.y + 9,
                  string(_count) + "/8", global.fnt_small,
                  _count >= 8 ? V_EMBER : V_BONE_DIM, fa_right);
        dui_vbar(_sr.x + 20, _sr.y + 38, _sr.w - 40, 10, _count / 8,
                 _count >= 8 ? V_EMBER : V_BLOOD_HI);
    }
}

function veil_relics_click() {
    var _u = veil_relics_ui();
    for (var _i = 0; _i < array_length(_u.cells); _i++) {
        var _r = _u.cells[_i];
        if (dui_clicked(_r.x, _r.y, _r.w, _r.h)) {
            if (veil_relic_count(_r.id) <= 0) return "empty";
            return veil_throne_toggle(_r.id) ? "throne" : "full";
        }
    }
    return "";
}

// ---------------------------------------------------------------- long night

function veil_night_ui() {
    var _card = { x: 510, y: 260, w: 900, h: 420 };
    return {
        card: _card,
        begin: { x: _card.x + _card.w * 0.5 - 150, y: _card.y + 330, w: 300, h: UI_H_CTA }
    };
}

function veil_night_draw() {
    var _o = global.G.occult;
    var _n = _o.night;
    if (!veil_loc_open(5)) {
        var _card = { x: 510, y: 300, w: 900, h: 400 };
        dui_vpanel(_card.x, _card.y, _card.w, _card.h, 1);
        dui_vtext(_card.x + _card.w * 0.5, _card.y + 64, "THE NINTH TABLE",
                  global.fnt_big, V_BONE, fa_center);
        dui_vtext(_card.x + _card.w * 0.5, _card.y + 128, "HEAR TWELVE CLOSINGS FIRST.",
                  global.fnt_small, V_BONE_DIM, fa_center);
        dui_vtext(_card.x + _card.w * 0.5, _card.y + 176,
                  "THE TABLE IS NOT SET FOR YOU YET.", global.fnt_small,
                  V_BLOOD_HI, fa_center);
        dui_vtext(_card.x + _card.w * 0.5, _card.y + 228,
                  "CLOSINGS " + string(_o.closings) + "/" + string(veil_loc_need(5)),
                  global.fnt_small, V_BONE_DIM, fa_center);
        dui_vbar(_card.x + 190, _card.y + 286, _card.w - 380, 16,
                 _o.closings / veil_loc_need(5), V_BLOOD_HI);
        return;
    }
    if (!_n.active) {
        var _u = veil_night_ui();
        var _c = _u.card;
        dui_vpanel(_c.x, _c.y, _c.w, _c.h, 1);
        dui_vtext(_c.x + _c.w * 0.5, _c.y + 52, "THE LONG NIGHT",
                  global.fnt_big, V_BONE, fa_center);
        dui_vtext(_c.x + _c.w * 0.5, _c.y + 112,
                  "ONE TABLE. ENDLESS DEPTH. NO MERCY, ONLY CHOICES.",
                  global.fnt_small, V_BONE_DIM, fa_center);
        dui_vtext(_c.x + _c.w * 0.5, _c.y + 170,
                  "BEST DEPTH " + string(_o.night_best),
                  global.fnt_small, V_EMBER, fa_center);
        dui_vtext(_c.x + _c.w * 0.5, _c.y + 210,
                  "EVERY THIRD DEPTH ASKS FOR NERVE. DEPTH 13 OPENS THE ENDING.",
                  global.fnt_small, V_BONE_DIM, fa_center);
        dui_vbutton(_u.begin.x, _u.begin.y, _u.begin.w, _u.begin.h, "BEGIN",
                    dui_hover(_u.begin.x, _u.begin.y, _u.begin.w, _u.begin.h), true, true);
        if (_o.ending) {
            dui_vtext(_c.x + _c.w * 0.5, _c.y + 262,
                      "YOU HAVE SEEN THE END OF THE NIGHT.",
                      global.fnt_small, V_BLOOD_HI, fa_center);
        }
        return;
    }
    veil_seance_draw(_n, _n.tier, true);
}

function veil_night_click() {
    var _o = global.G.occult;
    var _n = _o.night;
    if (!veil_loc_open(5)) return "";
    if (!_n.active) {
        var _u = veil_night_ui();
        var _b = _u.begin;
        if (dui_clicked(_b.x, _b.y, _b.w, _b.h)) {
            return veil_night_start() ? "start" : "";
        }
        return "";
    }
    var _action = veil_seance_click(_n, _n.tier, true);
    if (_action == "solved") {
        veil_night_advance();
    } else if (_action == "abandon") {
        veil_night_give_up();
        return "abandon";
    }
    return _action;
}

// ---------------------------------------------------------------- omens

function veil_omen_ui() {
    var _card = { x: 510, y: 330, w: 900, h: 410 };
    return {
        card: _card,
        a: { x: _card.x + 70,  y: _card.y + 300, w: 370, h: UI_H_CTA },
        b: { x: _card.x + 460, y: _card.y + 300, w: 370, h: UI_H_CTA }
    };
}

function veil_omen_draw() {
    var _o = global.G.occult;
    if (_o.omen.id < 0) return;
    var _card = veil_omens()[_o.omen.id];
    var _u = veil_omen_ui();

    draw_set_alpha(0.82);
    draw_set_colour(V_VOID);
    draw_rectangle(0, 0, UI_W, UI_H, false);
    draw_set_alpha(1);

    dui_vpanel(_u.card.x, _u.card.y, _u.card.w, _u.card.h, 1);
    dui_vtext(_u.card.x + _u.card.w * 0.5, _u.card.y + 44, _card.title,
              global.fnt_big, V_BONE, fa_center);
    var _lines = guide_wrap_px(_card.text, 620);
    for (var _l = 0; _l < array_length(_lines); _l++) {
        dui_vtext(_u.card.x + _u.card.w * 0.5, _u.card.y + 118 + _l * 30,
                  _lines[_l], global.fnt_small, V_BONE_DIM, fa_center);
    }
    dui_vtext(_u.card.x + _u.card.w * 0.5, _u.card.y + 242,
              "EITHER WAY, SOMETHING IS PAID.", global.fnt_small,
              vc(112, 98, 90), fa_center);
    dui_vbutton(_u.a.x, _u.a.y, _u.a.w, _u.a.h, _card.a,
                dui_hover(_u.a.x, _u.a.y, _u.a.w, _u.a.h), false, true);
    dui_vbutton(_u.b.x, _u.b.y, _u.b.w, _u.b.h, _card.b,
                dui_hover(_u.b.x, _u.b.y, _u.b.w, _u.b.h), false, true);
}

function veil_omen_click() {
    var _o = global.G.occult;
    if (_o.omen.id < 0) return false;
    var _u = veil_omen_ui();
    if (dui_clicked(_u.a.x, _u.a.y, _u.a.w, _u.a.h)) return veil_omen_apply(0);
    if (dui_clicked(_u.b.x, _u.b.y, _u.b.w, _u.b.h)) return veil_omen_apply(1);
    return false;
}
