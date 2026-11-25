/// THE TINCTURE CELLAR: mix three reagents at a heat, discover the recipe,
/// then spend the bottle somewhere that matters. Experiments are real: a
/// failed batch eats the reagents, but never progress or a save.
///
/// The cellar is native 1920: reagent jars on the left, the mortar in the
/// middle, and a readable shelf of ten bottles on the right.

function veil_reagent_name(_i) {
    var _n = ["SALT", "ASH", "WAX", "BONE", "ROOT", "MOTH", "IRON", "TEAR"];
    if (_i < 0 || _i >= array_length(_n)) return "?";
    return _n[_i];
}

function veil_tinctures() {
    return [
        { name: "CLEAR SIGHT", desc: "REVEALS A SEAT",       r: [0, 7, 2], heat: 1 },
        { name: "SECOND KNOCK", desc: "A FRESH CASE",        r: [5, 1, 6], heat: 2 },
        { name: "GREEN HOUR", desc: "BEDS GROW 50% NOW",     r: [4, 2, 7], heat: 1 },
        { name: "SALT BATH", desc: "CLEANSES A CURSE",       r: [0, 1, 4], heat: 3 },
        { name: "DOORLIGHT", desc: "REVEALS EVERY DOOR",     r: [5, 6, 3], heat: 2 },
        { name: "EMBER DRAUGHT", desc: "+60 EMBERS",         r: [1, 2, 6], heat: 3 },
        { name: "WHISPER JAR", desc: "+6 WHISPERS",          r: [7, 5, 0], heat: 3 },
        { name: "PATIENCE", desc: "GARDEN 10 MIN BOOST",     r: [4, 3, 7], heat: 2 },
        { name: "BRIGHT FEAR", desc: "+2 HALL NERVE",        r: [3, 6, 5], heat: 1 },
        { name: "NINTH CUP", desc: "+1 BLOOD",               r: [7, 2, 3], heat: 3 }
    ];
}

function veil_tincture_name(_i) {
    var _t = veil_tinctures();
    if (_i < 0 || _i >= array_length(_t)) return "?";
    return _t[_i].name;
}

function veil_tincture_desc(_i) {
    var _t = veil_tinctures();
    if (_i < 0 || _i >= array_length(_t)) return "";
    return _t[_i].desc;
}

function veil_bench_add_reagent(_r) {
    var _b = global.G.occult.bench;
    for (var _i = 0; _i < 3; _i++) {
        if (_b.slots[_i] < 0) {
            _b.slots[_i] = _r;
            _b.feedback = "";
            return true;
        }
    }
    _b.feedback = "THE MORTAR IS FULL.";
    return false;
}

function veil_bench_clear_slot(_i) {
    var _b = global.G.occult.bench;
    if (_i < 0 || _i >= 3) return false;
    _b.slots[_i] = -1;
    _b.feedback = "";
    return true;
}

function veil_bench_recipe_match() {
    var _b = global.G.occult.bench;
    var _have = [];
    for (var _i = 0; _i < 3; _i++) {
        if (_b.slots[_i] < 0) return -1;
        array_push(_have, _b.slots[_i]);
    }
    var _all = veil_tinctures();
    for (var _t = 0; _t < array_length(_all); _t++) {
        var _r = _all[_t].r;
        if (_all[_t].heat != _b.heat) continue;
        var _left = _have;
        var _ok = true;
        for (var _k = 0; _k < 3; _k++) {
            var _at = -1;
            for (var _j = 0; _j < array_length(_left); _j++) {
                if (_left[_j] == _r[_k]) _at = _j;
            }
            if (_at < 0) { _ok = false; break; }
            array_delete(_left, _at, 1);
        }
        if (_ok && array_length(_left) == 0) return _t;
    }
    return -1;
}

function veil_bench_brew() {
    var _b = global.G.occult.bench;
    var _o = global.G.occult;
    for (var _i = 0; _i < 3; _i++) {
        if (_b.slots[_i] < 0) {
            _b.feedback = "THREE THINGS, NOT FEWER.";
            return false;
        }
        if (_b.reagents[_b.slots[_i]] <= 0) {
            _b.feedback = "NO " + veil_reagent_name(_b.slots[_i]) + " LEFT.";
            return false;
        }
    }
    var _match = veil_bench_recipe_match();
    for (var _i = 0; _i < 3; _i++) {
        _b.reagents[_b.slots[_i]] -= 1;
        _b.slots[_i] = -1;
    }
    _o.stats.brews += 1;
    if (_match >= 0) {
        _b.tinctures[_match] += 1;
        _b.known[_match] = true;
        _b.feedback = "BREWED " + veil_tincture_name(_match) + ".";
    } else {
        veil_gain_embers(4);
        _b.feedback = "SLUDGE. THE RECIPE WAS WRONG.";
    }
    save_write();
    return true;
}

/// Effects are deliberately cross-system: a bottle is a plan, not a number.
function veil_tincture_use(_t) {
    var _o = global.G.occult;
    var _b = _o.bench;
    if (_t < 0 || _t >= VEIL_TINCTURES || _b.tinctures[_t] <= 0) return false;
    switch (_t) {
        case 0:
            veil_seance_force_reveal(_o.seance);
            break;
        case 1:
            veil_seance_reset(_o.seance, _o.seance.tier);
            break;
        case 2:
            for (var _i = 0; _i < veil_plot_count(); _i++) {
                var _p = _o.garden.plots[_i];
                if (_p.seed >= 0 && !veil_garden_ready(_p)) {
                    _p.need -= veil_garden_left(_p) * 0.5;
                }
            }
            _o.garden.feedback = "THE BEDS JERK FORWARD.";
            break;
        case 3:
            if (array_length(_o.curses) > 0) {
                array_delete(_o.curses, 0, 1);
                _o.stats.cleansed += 1;
            }
            break;
        case 4:
            if (_o.hall.active) {
                for (var _i = 0; _i < veil_hall_door_count(); _i++) _o.hall.peeked[_i] = 1;
                _o.hall.feedback = "EVERY DOOR IS BRIEFLY HONEST.";
            }
            break;
        case 5:
            veil_gain_embers(60);
            break;
        case 6:
            veil_gain_whispers(6);
            break;
        case 7:
            _o.buff.kind = 1;
            _o.buff.t = max(_o.buff.t, 600);
            break;
        case 8:
            if (_o.hall.active) _o.hall.nerve += 2;
            break;
        case 9:
            _o.blood += 1;
            break;
    }
    _b.tinctures[_t] -= 1;
    _b.feedback = "USED " + veil_tincture_name(_t) + ".";
    save_write();
    return true;
}

/// The cellar gives a starter set once it opens, so the first recipe is a
/// discovery rather than a shopping trip. It is saved, so it never repeats.
function veil_bench_starter() {
    var _b = global.G.occult.bench;
    if (variable_struct_exists(_b, "starter") && _b.starter) return;
    for (var _i = 0; _i < VEIL_REAGENTS; _i++) _b.reagents[_i] += 2;
    _b.starter = true;
    _b.feedback = "A STARTER SET. THE REST IS YOUR PROBLEM.";
    save_write();
}

function veil_reagent_colour(_i) {
    var _c = [vc(214, 202, 182), vc(88, 78, 72), vc(198, 178, 138), vc(226, 218, 200),
              vc(96, 112, 74), vc(120, 104, 132), vc(84, 92, 100), vc(122, 160, 168)];
    if (_i < 0 || _i >= array_length(_c)) return V_BONE_DIM;
    return _c[_i];
}

// ---------------------------------------------------------------- layout

function veil_bench_ui() {
    var _jars = [];
    for (var _i = 0; _i < VEIL_REAGENTS; _i++) {
        array_push(_jars, {
            x: 124 + (_i mod 4) * 144, y: 236 + (_i div 4) * 130,
            w: 132, h: 110, reagent: _i
        });
    }
    var _slots = [];
    for (var _i = 0; _i < 3; _i++) {
        array_push(_slots, { x: 190 + _i * 180, y: 680, r: 62, slot: _i });
    }
    var _heat = [];
    for (var _i = 0; _i < 3; _i++) {
        array_push(_heat, { x: 124 + _i * 160, y: 776, w: 140, h: UI_H_CONTROL, heat: _i + 1 });
    }
    var _bottles = [];
    for (var _t = 0; _t < VEIL_TINCTURES; _t++) {
        array_push(_bottles, { x: 772, y: 240 + _t * 66, w: 1028, h: 60, tincture: _t });
    }
    return {
        reagents: _jars,
        slots: _slots,
        heat: _heat,
        brew: { x: 124, y: 848, w: 300, h: UI_H_CTA },
        bottles: _bottles,
        mortar: { x: 96, y: 536, w: 620, h: 400 },
        shelf: { x: 748, y: 176, w: 1076, h: 748 }
    };
}

// ---------------------------------------------------------------- input

function veil_bench_click(_x, _y) {
    var _b = global.G.occult.bench;
    var _u = veil_bench_ui();

    for (var _i = 0; _i < array_length(_u.reagents); _i++) {
        var _r = _u.reagents[_i];
        if (dui_clicked(_r.x, _r.y, _r.w, _r.h)) {
            if (_b.reagents[_r.reagent] <= 0) {
                _b.feedback = "NO " + veil_reagent_name(_r.reagent) + " LEFT.";
            } else {
                veil_bench_add_reagent(_r.reagent);
            }
            return "jar";
        }
    }
    for (var _i = 0; _i < array_length(_u.slots); _i++) {
        var _s = _u.slots[_i];
        if (point_distance(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0),
                           _s.x, _s.y) < _s.r
            && mouse_check_button_pressed(mb_left)) {
            veil_bench_clear_slot(_s.slot);
            return "slot";
        }
    }
    for (var _i = 0; _i < array_length(_u.heat); _i++) {
        var _h = _u.heat[_i];
        if (dui_clicked(_h.x, _h.y, _h.w, _h.h)) {
            _b.heat = _h.heat;
            _b.feedback = "";
            save_write();
            return "heat";
        }
    }
    if (dui_clicked(_u.brew.x, _u.brew.y, _u.brew.w, _u.brew.h)) {
        veil_bench_brew();
        return "brew";
    }
    for (var _i = 0; _i < array_length(_u.bottles); _i++) {
        var _r = _u.bottles[_i];
        if (dui_clicked(_r.x, _r.y, _r.w, _r.h)) {
            if (_b.tinctures[_r.tincture] <= 0) {
                _b.feedback = "NONE BREWED YET.";
                return "";
            }
            veil_tincture_use(_r.tincture);
            return "use";
        }
    }
    return "";
}

// ---------------------------------------------------------------- drawing

function veil_bench_draw() {
    var _b = global.G.occult.bench;
    var _u = veil_bench_ui();

    // jars, within reach above the mortar
    for (var _i = 0; _i < array_length(_u.reagents); _i++) {
        var _r = _u.reagents[_i];
        var _n = _b.reagents[_r.reagent];
        var _hot = dui_hover(_r.x, _r.y, _r.w, _r.h);
        dui_vpanel(_r.x, _r.y, _r.w, _r.h, _hot && _n > 0);
        draw_set_colour(veil_reagent_colour(_r.reagent));
        draw_rectangle(_r.x + 16, _r.y + 18, _r.x + 40, _r.y + 62, false);
        draw_set_colour(V_VOID);
        draw_rectangle(_r.x + 22, _r.y + 16, _r.x + 34, _r.y + 22, false);
        dui_vtext(_r.x + 52, _r.y + 18, veil_reagent_name(_r.reagent),
                  global.fnt_small, _n > 0 ? V_BONE : vc(96, 86, 80), fa_left);
        dui_vtext(_r.x + 52, _r.y + 52, "x" + string(_n),
                  global.fnt_small, _n > 0 ? V_EMBER : V_BONE_DIM, fa_left);
        if (_n <= 0) {
            dui_vtext(_r.x + 16, _r.y + 82, "EMPTY",
                      global.fnt_small, vc(82, 74, 70), fa_left);
        }
    }

    // the mortar and its three slots
    var _m = _u.mortar;
    dui_vpanel(_m.x, _m.y, _m.w, _m.h, 1);
    dui_vtext(_m.x + 28, _m.y + 20, "THE MORTAR", global.fnt_small, V_BLOOD_HI, fa_left);
    var _mix = veil_bench_recipe_match();
    dui_vtext(_m.x + 28, _m.y + 54,
              _mix >= 0 ? veil_tincture_desc(_mix) : "THREE THINGS AND A HEAT",
              global.fnt_small, _mix >= 0 ? V_EMBER : V_BONE_DIM, fa_left);

    for (var _i = 0; _i < array_length(_u.slots); _i++) {
        var _s = _u.slots[_i];
        draw_set_colour(V_IRON);
        draw_circle(_s.x, _s.y, _s.r, false);
        draw_set_colour(vc(12, 9, 11));
        draw_circle(_s.x, _s.y, _s.r - 6, false);
        draw_set_colour(V_IRON_HI);
        draw_circle(_s.x, _s.y, _s.r - 2, true);
        if (_b.slots[_i] >= 0) {
            draw_set_colour(veil_reagent_colour(_b.slots[_i]));
            draw_circle(_s.x, _s.y, 18, false);
            dui_vtext(_s.x, _s.y + 34, veil_reagent_name(_b.slots[_i]),
                      global.fnt_small, V_BONE, fa_center);
        } else {
            dui_vtext(_s.x, _s.y - 9, "DROP", global.fnt_small,
                      vc(86, 76, 72), fa_center);
        }
    }

    // heat: three candles, the lit one is the brew temperature
    for (var _i = 0; _i < array_length(_u.heat); _i++) {
        var _h = _u.heat[_i];
        var _lit = (_b.heat >= _h.heat);
        dui_vbutton(_h.x, _h.y, _h.w, _h.h, "HEAT " + string(_h.heat),
                    dui_hover(_h.x, _h.y, _h.w, _h.h), _b.heat == _h.heat, true);
        if (_lit) {
            dui_vglow(_h.x + _h.w * 0.5, _h.y - 4, 5 + _h.heat * 2, V_EMBER, 0.20);
        }
    }
    dui_vbutton(_u.brew.x, _u.brew.y, _u.brew.w, _u.brew.h, "BREW",
                dui_hover(_u.brew.x, _u.brew.y, _u.brew.w, _u.brew.h), false, true);

    if (_b.feedback != "") {
        var _fl = guide_wrap_px(_b.feedback, 250);
        for (var _l = 0; _l < min(3, array_length(_fl)); _l++) {
            dui_vtext(_m.x + 344, _m.y + 344 + _l * 26, _fl[_l],
                      global.fnt_small, V_EMBER, fa_left);
        }
    } else {
        dui_vtext(_m.x + 344, _m.y + 344,
                  "A WRONG BATCH PAYS 4 EMBERS.", global.fnt_small,
                  V_BONE_DIM, fa_left);
    }

    // the shelf of outcomes
    var _sh = _u.shelf;
    dui_vpanel(_sh.x, _sh.y, _sh.w, _sh.h, 0);
    dui_vtext(_sh.x + 24, _sh.y + 20, "BOTTLES", global.fnt_small, V_BLOOD_HI, fa_left);
    dui_vtext(_sh.x + _sh.w - 24, _sh.y + 20, "CLICK A BOTTLE TO USE IT",
              global.fnt_small, vc(112, 100, 90), fa_right);

    for (var _i = 0; _i < array_length(_u.bottles); _i++) {
        var _r = _u.bottles[_i];
        var _known = _b.known[_r.tincture];
        var _have = _b.tinctures[_r.tincture];
        var _hot = dui_hover(_r.x, _r.y, _r.w, _r.h);

        draw_set_alpha(_have > 0 ? 1 : 0.62);
        draw_set_colour(_hot && _have > 0 ? vc(40, 27, 30) : vc(24, 19, 22));
        draw_rectangle(_r.x, _r.y, _r.x + _r.w, _r.y + _r.h, false);
        draw_set_colour(_have > 0 ? V_BLOOD : V_IRON);
        draw_rectangle(_r.x, _r.y, _r.x + 6, _r.y + _r.h, false);

        // a small bottle icon, drawn from primitives like everything else
        draw_set_colour(_have > 0 ? V_WAX : V_IRON_HI);
        draw_rectangle(_r.x + 22, _r.y + 16, _r.x + 30, _r.y + 24, false);
        draw_set_colour(_have > 0 ? vc(70, 96, 82) : vc(40, 36, 34));
        draw_roundrect_ext(_r.x + 18, _r.y + 24, _r.x + 34, _r.y + 48, 4, 4, false);

        dui_vtext(_r.x + 50, _r.y + 8,
                  _known ? veil_tincture_name(_r.tincture) : "UNKNOWN",
                  global.fnt_small, _have > 0 ? V_BONE : V_BONE_DIM, fa_left);
        dui_vtext(_r.x + 330, _r.y + 8,
                  _known ? veil_tincture_desc(_r.tincture) : "BREW TO LEARN",
                  global.fnt_small, _have > 0 ? V_BONE_DIM : vc(96, 86, 80), fa_left);
        dui_vtext(_r.x + _r.w - 120, _r.y + 8, "x" + string(_have),
                  global.fnt_small, _have > 0 ? V_EMBER : V_BONE_DIM, fa_right);
        if (_have > 0) {
            dui_vtext(_r.x + _r.w - 24, _r.y + 8, "USE",
                      global.fnt_small, _hot ? V_EMBER : V_BONE, fa_right);
        }
        draw_set_alpha(1);
    }
}
