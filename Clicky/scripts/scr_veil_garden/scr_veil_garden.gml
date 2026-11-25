/// THE ASH GARDEN: idle beds with one real decision - wait, or feed it.
/// Growth is stored as an absolute date, so a reload (or a week away) still
/// finds the bed exactly where the player left it. The Keeper familiar tends
/// ready beds at a reduced yield; it never makes the choice for the player.
///
/// Presentation lives on the native 1920 canvas. The grid, the seed bank and
/// the blight decision all read the same veil_garden_ui() rectangles that the
/// input path uses.

function veil_garden_seed_name(_s) {
    switch (_s) {
        case 0: return "WAX SEED";
        case 1: return "BONE SEED";
        case 2: return "VEIL SEED";
    }
    return "EMPTY BED";
}

function veil_garden_seed_need(_s) {
    switch (_s) {
        case 0: return 900;      // 15 minutes
        case 1: return 3600;     // 1 hour
        case 2: return 10800;    // 3 hours
    }
    return 0;
}

function veil_garden_seed_colour(_s) {
    switch (_s) {
        case 0: return V_WAX;
        case 1: return V_BONE;
        case 2: return vc(96, 78, 132);
    }
    return V_IRON;
}

function veil_plot_open(_i) {
    return _i >= 0 && _i < veil_plot_count();
}

function veil_garden_ready(_p) {
    if (!is_struct(_p) || _p.seed < 0 || _p.planted <= 0) return false;
    return date_second_span(_p.planted, date_current_datetime()) >= _p.need;
}

function veil_garden_left(_p) {
    if (!is_struct(_p) || _p.seed < 0) return 0;
    var _s = date_second_span(_p.planted, date_current_datetime());
    return max(0, _p.need - _s);
}

/// Plant the selected seed in the selected bed. Fed beds halve the wait but
/// can blight; the roll happens now and is saved, so reloading cannot reroll
/// a bad harvest.
function veil_garden_plant(_plot_i) {
    var _g = global.G.occult.garden;
    if (!veil_plot_open(_plot_i)) return false;
    var _p = _g.plots[_plot_i];
    if (_p.seed >= 0) return false;
    var _seed = clamp(veil_num(_g.seed, 0), 0, 2);
    var _fed = (veil_num(_g.mode, 0) == 1);
    var _need = veil_garden_seed_need(_seed) / veil_grow_mult();
    if (_fed) _need *= 0.5;
    _p.seed = _seed;
    _p.planted = date_current_datetime();
    _p.need = max(30, _need);
    _p.fed = _fed;
    _p.blight = (_fed && random(1) < 0.35);
    save_write();
    return true;
}

function veil_garden_reward(_seed, _mult, _cursed) {
    var _o = global.G.occult;
    var _m = veil_harvest_mult() * _mult;
    switch (_seed) {
        case 0:
            veil_gain_embers(16 * _m);
            break;
        case 1:
            for (var _i = 0; _i < 2; _i++) {
                var _r = irandom(VEIL_REAGENTS - 1);
                // A HUNGRY companion digs one extra of each reagent out of
                // every BONE bed; the rung is a rule, not a multiplier.
                _o.bench.reagents[_r] += max(1, floor(2 * _m)) + cat_harvest_add();
            }
            break;
        case 2:
            veil_gain_whispers(2.4 * _m);
            if (random(1) < veil_relic_chance() + 0.08) veil_relic_grant(-1);
            break;
    }
    if (_cursed) veil_curse_add(-1);
    _o.stats.harvests += 1;
    save_write();
}

/// Harvest a ripe bed. Blighted fed beds make the player choose: pay to clean
/// it, or take double and carry a curse.
function veil_garden_harvest(_plot_i, _take) {
    var _g = global.G.occult.garden;
    if (!veil_plot_open(_plot_i)) return false;
    var _p = _g.plots[_plot_i];
    if (!veil_garden_ready(_p)) return false;
    if (_p.blight && !_take) return false;

    var _seed = _p.seed;
    if (_p.blight && _take) {
        veil_garden_reward(_seed, (_p.fed ? 1.5 : 1) * 1.6, true);
        _g.feedback = "THE BED IS QUIET. SOMETHING FOLLOWED YOU OUT.";
    } else {
        veil_garden_reward(_seed, _p.fed ? 1.35 : 1, false);
        _g.feedback = "HARVESTED " + veil_garden_seed_name(_seed) + ".";
    }
    _p.seed = -1;
    _p.planted = 0;
    _p.need = 0;
    _p.fed = false;
    _p.blight = false;
    _g.choose = -1;
    save_write();
    return true;
}

function veil_garden_cleanse_blight(_plot_i) {
    var _g = global.G.occult.garden;
    if (!veil_plot_open(_plot_i)) return false;
    var _p = _g.plots[_plot_i];
    if (!_p.blight) return false;
    var _cost = 15;
    if (global.G.occult.embers < _cost) {
        _g.feedback = "NEED " + string(_cost) + " EMBERS TO CLEANSE.";
        return false;
    }
    global.G.occult.embers -= _cost;
    _p.blight = false;
    veil_garden_reward(_p.seed, 0.5, false);
    _p.seed = -1;
    _p.planted = 0;
    _p.need = 0;
    _p.fed = false;
    _g.choose = -1;
    _g.feedback = "CLEANSED. THE SOIL IS COLD BUT HONEST.";
    save_write();
    return true;
}

/// The Keeper harvests ready, healthy beds at 60% and leaves blighted ones
/// for the player, because that is the only decision the bed contains.
function veil_familiar_tick(_dt) {
    var _o = global.G.occult;
    if (!variable_global_exists("veil_keeper_t")) global.veil_keeper_t = 0;
    if (!variable_global_exists("veil_listener_t")) global.veil_listener_t = 0;
    if (veil_lvl("keeper") > 0) {
        global.veil_keeper_t += _dt;
        if (global.veil_keeper_t >= 45) {
            global.veil_keeper_t = 0;
            for (var _i = 0; _i < veil_plot_count(); _i++) {
                var _p = _o.garden.plots[_i];
                if (veil_garden_ready(_p) && !_p.blight) {
                    var _seed = _p.seed;
                    _p.seed = -1;
                    _p.planted = 0;
                    _p.need = 0;
                    _p.fed = false;
                    veil_garden_reward(_seed, 0.6, false);
                    _o.garden.feedback = "THE KEEPER TOOK A HARVEST.";
                }
            }
        }
    }
    if (veil_lvl("listener") > 0) {
        global.veil_listener_t += _dt;
        if (global.veil_listener_t >= 90) {
            global.veil_listener_t = 0;
            veil_seance_auto(global.G.occult.seance.tier);
        }
    }
}

function veil_garden_tick(_dt) {
    // The beds themselves run on absolute dates; nothing to advance here.
    // This hook exists so the save can be normalized after a long absence.
    var _g = global.G.occult.garden;
    if (!is_array(_g.plots)) return;
    for (var _i = 0; _i < array_length(_g.plots); _i++) {
        var _p = _g.plots[_i];
        if (!is_struct(_p)) continue;
        if (_p.seed < 0 && _p.planted != 0) {
            _p.planted = 0;
            _p.need = 0;
            _p.fed = false;
            _p.blight = false;
        }
    }
}

// ---------------------------------------------------------------- layout

function veil_garden_plot_x(_i) {
    return 124 + (_i mod 4) * 424;
}

function veil_garden_plot_y(_i) {
    return 176 + (_i div 4) * 200;
}

function veil_garden_ui() {
    var _plots = [];
    for (var _i = 0; _i < VEIL_GARDEN_PLOTS; _i++) {
        array_push(_plots, { x: veil_garden_plot_x(_i), y: veil_garden_plot_y(_i),
                             w: 400, h: 180, id: _i, open: veil_plot_open(_i) });
    }
    var _seeds = [];
    for (var _s = 0; _s < 3; _s++) {
        array_push(_seeds, { x: 124 + _s * 212, y: 784, w: 200, h: 148, seed: _s });
    }
    var _choose = { x: 610, y: 350, w: 700, h: 380 };
    return {
        plots: _plots,
        seeds: _seeds,
        patient: { x: 780, y: 816, w: 170, h: UI_H_CONTROL },
        fed:     { x: 966, y: 816, w: 170, h: UI_H_CONTROL },
        plant:   { x: 1152, y: 804, w: 220, h: UI_H_CTA },
        feedback: { x: 1396, y: 784, w: 400, h: 148 },
        choose_card: _choose,
        cleanse: { x: _choose.x + 50,  y: _choose.y + 270, w: 280, h: UI_H_CTA },
        take:    { x: _choose.x + 370, y: _choose.y + 270, w: 280, h: UI_H_CTA }
    };
}

// ---------------------------------------------------------------- input

function veil_garden_click() {
    var _g = global.G.occult.garden;
    var _u = veil_garden_ui();

    // A blighted bed owns the screen until the player has chosen. This is the
    // same rule as before: no planting behind the decision.
    if (_g.choose >= 0) {
        if (dui_clicked(_u.cleanse.x, _u.cleanse.y, _u.cleanse.w, _u.cleanse.h)) {
            veil_garden_cleanse_blight(_g.choose);
            return "cleanse";
        }
        if (dui_clicked(_u.take.x, _u.take.y, _u.take.w, _u.take.h)) {
            veil_garden_harvest(_g.choose, true);
            return "take";
        }
        return "";
    }

    for (var _i = 0; _i < array_length(_u.plots); _i++) {
        var _r = _u.plots[_i];
        if (!dui_clicked(_r.x, _r.y, _r.w, _r.h)) continue;
        if (!_r.open) {
            _g.feedback = "THAT BED IS STILL BURIED. BUY NEW BEDS.";
            return "";
        }
        var _p = _g.plots[_i];
        if (_p.seed < 0) {
            _g.sel = _i;
            _g.feedback = "BED " + string(_i + 1) + " CHOSEN.";
            return "select";
        }
        if (veil_garden_ready(_p)) {
            if (_p.blight) {
                _g.choose = _i;
                _g.feedback = "IT CAME UP WRONG. CLEANSE OR TAKE IT.";
                return "blight";
            }
            veil_garden_harvest(_i, false);
            return "harvest";
        }
        _g.feedback = "STILL GROWING - " + fmt_time(veil_garden_left(_p));
        return "wait";
    }

    for (var _s = 0; _s < array_length(_u.seeds); _s++) {
        var _sr = _u.seeds[_s];
        if (dui_clicked(_sr.x, _sr.y, _sr.w, _sr.h)) {
            _g.seed = _s;
            _g.feedback = veil_garden_seed_name(_s) + " READY TO PLANT.";
            save_write();
            return "seed";
        }
    }
    if (dui_clicked(_u.patient.x, _u.patient.y, _u.patient.w, _u.patient.h)) {
        _g.mode = 0;
        save_write();
        return "patient";
    }
    if (dui_clicked(_u.fed.x, _u.fed.y, _u.fed.w, _u.fed.h)) {
        _g.mode = 1;
        save_write();
        return "fed";
    }
    if (dui_clicked(_u.plant.x, _u.plant.y, _u.plant.w, _u.plant.h)) {
        if (_g.sel < 0) {
            _g.feedback = "CHOOSE AN EMPTY BED FIRST.";
        } else if (veil_garden_plant(_g.sel)) {
            _g.feedback = "PLANTED. " + (_g.mode == 1 ? "IT IS HUNGRY." : "PATIENCE.");
            _g.sel = -1;
            return "plant";
        }
        return "";
    }
    return "";
}

// ---------------------------------------------------------------- drawing

function veil_garden_draw() {
    var _g = global.G.occult.garden;
    var _u = veil_garden_ui();
    var _now = date_current_datetime();

    dui_vtext(VUI_MX, VUI_TOP - 6, "BEDS  -  PLANT, WAIT, OR FEED THE SOIL",
              global.fnt_small, V_BONE_DIM, fa_left);

    for (var _i = 0; _i < array_length(_u.plots); _i++) {
        var _r = _u.plots[_i];
        var _open = _r.open;
        var _p = _g.plots[_i];
        var _sel = (_g.sel == _i);
        var _hot = dui_hover(_r.x, _r.y, _r.w, _r.h);

        draw_set_colour(_open ? vc(30, 24, 20) : vc(18, 15, 17));
        draw_rectangle(_r.x, _r.y, _r.x + _r.w, _r.y + _r.h, false);
        draw_set_colour(_open ? V_IRON_HI : V_IRON);
        draw_rectangle(_r.x, _r.y, _r.x + _r.w, _r.y + _r.h, true);
        draw_set_colour(_open ? vc(54, 40, 30) : vc(28, 24, 26));
        draw_rectangle(_r.x + 6, _r.y + 48, _r.x + _r.w - 6, _r.y + _r.h - 6, false);

        // soil furrows
        draw_set_colour(_open ? vc(40, 29, 22) : V_VOID);
        for (var _f = 0; _f < 4; _f++) {
            draw_rectangle(_r.x + 16, _r.y + 80 + _f * 18,
                           _r.x + _r.w - 16, _r.y + 84 + _f * 18, false);
        }

        if (_sel) {
            draw_set_alpha(0.55 + 0.2 * sin(global.time * 4));
            draw_set_colour(V_EMBER);
            draw_rectangle(_r.x - 2, _r.y - 2, _r.x + _r.w + 2, _r.y + _r.h + 2, true);
            draw_set_alpha(1);
        } else if (_hot) {
            draw_set_colour(V_IRON_HI);
            draw_rectangle(_r.x, _r.y, _r.x + _r.w, _r.y + _r.h, true);
        }

        dui_vtext(_r.x + 18, _r.y + 12, "BED " + string(_i + 1),
                  global.fnt_small, _open ? V_BONE_DIM : vc(82, 74, 70), fa_left);

        if (!_open) {
            dui_vtext(_r.x + _r.w * 0.5, _r.y + 84, "SEALED",
                      global.fnt_small, V_BONE_DIM, fa_center);
            dui_vtext(_r.x + _r.w * 0.5, _r.y + 116,
                      "BUY NEW BEDS IN RITES", global.fnt_small,
                      vc(92, 82, 76), fa_center);
            continue;
        }

        if (_p.seed < 0) {
            dui_vtext(_r.x + _r.w * 0.5, _r.y + 84, "EMPTY",
                      global.fnt_small, vc(100, 90, 80), fa_center);
            if (_sel) {
                dui_vtext(_r.x + _r.w * 0.5, _r.y + 116, "READY FOR A SEED",
                          global.fnt_small, V_EMBER, fa_center);
            }
            continue;
        }

        var _col = veil_garden_seed_colour(_p.seed);
        var _ready = veil_garden_ready(_p);
        var _left = veil_garden_left(_p);
        var _frac = clamp(1 - _left / max(1, _p.need), 0, 1);
        var _h = 18 + floor(_frac * 58);
        var _px = _r.x + _r.w * 0.5;

        // the plant: a small stalk that grows with the timer
        draw_set_colour(_col);
        draw_rectangle(_px - 3, _r.y + 148 - _h, _px + 3, _r.y + 150, false);
        draw_circle(_px, _r.y + 148 - _h, _ready ? 10 : 7, false);
        draw_set_colour(V_VOID);
        draw_circle(_px - 3, _r.y + 146 - _h, 2, false);
        draw_circle(_px + 4, _r.y + 146 - _h, 2, false);

        if (_p.blight) {
            draw_set_alpha(0.40 + 0.12 * sin(global.time * 5));
            draw_set_colour(V_BLOOD_HI);
            draw_circle(_px, _r.y + 118, 20, true);
            draw_set_alpha(1);
        }

        if (_ready) {
            draw_set_alpha(0.4 + 0.16 * sin(global.time * 5));
            draw_set_colour(_p.blight ? V_BLOOD_HI : V_EMBER);
            draw_rectangle(_r.x + 4, _r.y + 4, _r.x + _r.w - 4, _r.y + _r.h - 4, true);
            draw_set_alpha(1);
            dui_vtext(_px, _r.y + 18, _p.blight ? "WRONG" : "RIPE",
                      global.fnt_small, _p.blight ? V_BLOOD_HI : V_BONE, fa_center);
        } else {
            dui_vtext(_px, _r.y + 18, fmt_time(_left),
                      global.fnt_small, V_BONE_DIM, fa_center);
        }

        dui_vtext(_r.x + 18, _r.y + 158, veil_garden_seed_name(_p.seed),
                  global.fnt_small, _col, fa_left);
        if (_p.fed) {
            dui_vtext(_r.x + _r.w - 18, _r.y + 158, "FED",
                      global.fnt_small, V_BLOOD_HI, fa_right);
        }
        dui_vbar(_r.x + 18, _r.y + 172, _r.w - 36, 6, _frac, _col);
    }

    // Seed bank, mode and the one button that commits the bed.
    for (var _s = 0; _s < array_length(_u.seeds); _s++) {
        var _sr = _u.seeds[_s];
        var _on = (veil_num(_g.seed, 0) == _s);
        dui_vpanel(_sr.x, _sr.y, _sr.w, _sr.h, _on);
        draw_set_colour(veil_garden_seed_colour(_s));
        draw_circle(_sr.x + 28, _sr.y + 34, 9, false);
        dui_vtext(_sr.x + 48, _sr.y + 20, ["WAX", "BONE", "VEIL"][_s],
                  global.fnt_small, _on ? V_EMBER : V_BONE, fa_left);
        dui_vtext(_sr.x + 48, _sr.y + 52, fmt_time(veil_garden_seed_need(_s)),
                  global.fnt_small, V_BONE_DIM, fa_left);
        dui_vtext(_sr.x + 20, _sr.y + 108,
                  ["EMBERS", "REAGENTS", "WHISPERS"][_s],
                  global.fnt_small, vc(112, 100, 90), fa_left);
    }

    dui_vbutton(_u.patient.x, _u.patient.y, _u.patient.w, _u.patient.h, "PATIENT",
                dui_hover(_u.patient.x, _u.patient.y, _u.patient.w, _u.patient.h),
                _g.mode == 0, true);
    dui_vbutton(_u.fed.x, _u.fed.y, _u.fed.w, _u.fed.h, "FED",
                dui_hover(_u.fed.x, _u.fed.y, _u.fed.w, _u.fed.h),
                _g.mode == 1, true);
    dui_vbutton(_u.plant.x, _u.plant.y, _u.plant.w, _u.plant.h, "PLANT",
                dui_hover(_u.plant.x, _u.plant.y, _u.plant.w, _u.plant.h), false, true);

    var _fb = _u.feedback;
    dui_vpanel(_fb.x, _fb.y, _fb.w, _fb.h, 0);
    if (_g.feedback != "") {
        var _lines = guide_wrap_px(_g.feedback, _fb.w - 40);
        for (var _l = 0; _l < min(3, array_length(_lines)); _l++) {
            dui_vtext(_fb.x + 20, _fb.y + 18 + _l * 28, _lines[_l],
                      global.fnt_small, V_BONE, fa_left);
        }
    } else {
        dui_vtext(_fb.x + 20, _fb.y + 18, "CHOOSE A BED, THEN A SEED.",
                  global.fnt_small, V_BONE_DIM, fa_left);
    }
    dui_vtext(_fb.x + 20, _fb.y + 100, "FED BEDS WAIT LESS.",
              global.fnt_small, V_BLOOD_HI, fa_left);
    dui_vtext(_fb.x + 20, _fb.y + 124, "SOMETIMES THEY BITE.",
              global.fnt_small, V_BLOOD_HI, fa_left);

}

/// Drawn after the shell so the blight decision owns the whole screen: map,
/// header and nav all sit under one scrim until the player answers.
function veil_garden_modal_draw() {
    var _g = global.G.occult.garden;
    if (_g.choose < 0) return;
    var _u = veil_garden_ui();
    var _c = _u.choose_card;

    draw_set_alpha(0.80);
    draw_set_colour(V_VOID);
    draw_rectangle(0, 0, UI_W, UI_H, false);
    draw_set_alpha(1);

    dui_vpanel(_c.x, _c.y, _c.w, _c.h, 1);
    dui_vtext(_c.x + _c.w * 0.5, _c.y + 40, "THE BED CAME UP WRONG",
              global.fnt_big, V_BONE, fa_center);
    dui_vtext(_c.x + _c.w * 0.5, _c.y + 104,
              "CLEANSE IT FOR 15 EMBERS AND TAKE HALF.",
              global.fnt_small, V_BONE_DIM, fa_center);
    dui_vtext(_c.x + _c.w * 0.5, _c.y + 142,
              "OR TAKE IT ALL AND CARRY A CURSE.",
              global.fnt_small, V_BLOOD_HI, fa_center);
    dui_vtext(_c.x + _c.w * 0.5, _c.y + 200,
              "BED " + string(_g.choose + 1) + "  -  "
              + veil_garden_seed_name(_g.plots[_g.choose].seed),
              global.fnt_small, V_EMBER, fa_center);
    dui_vbutton(_u.cleanse.x, _u.cleanse.y, _u.cleanse.w, _u.cleanse.h, "CLEANSE 15",
                dui_hover(_u.cleanse.x, _u.cleanse.y, _u.cleanse.w, _u.cleanse.h),
                false, global.G.occult.embers >= 15);
    dui_vbutton(_u.take.x, _u.take.y, _u.take.w, _u.take.h, "TAKE IT",
                dui_hover(_u.take.x, _u.take.y, _u.take.w, _u.take.h), false, true);
}
