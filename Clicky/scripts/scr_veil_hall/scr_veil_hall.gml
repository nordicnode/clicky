/// THE LONG HALL: pick a door, live with it. Every door advances the run, so
/// there is no way to stall or farm a safe corridor. The only permanent thing
/// a run can cost is a curse, and curses are always cleansable with embers.
///
/// The hall is native 1920. Doors are 180x440 cards with their risk tag above
/// and their peek control below; the run panel sits to their right and never
/// shares a hit box with a door.

/// Each night draws one modifier. The first run is always THE QUIET so the
/// player learns the door/peek loop before the hall starts changing shape.
function veil_hall_mods() {
    return [
        { name: "THE QUIET",        desc: "One fewer door. One extra nerve.",
          doors: -1, nerve: 1,  floors: 3, loot: 1.00, whisper: 1.00, relic: 0.00, peek: 1 },
        { name: "THE HUNGRY DARK",  desc: "More doors. Embers +25%.",
          doors: 1,  nerve: 0,  floors: 3, loot: 1.25, whisper: 1.00, relic: 0.00, peek: 1 },
        { name: "THE TILTED HOUR",  desc: "Nerve -1. Whispers +30%.",
          doors: 0,  nerve: -1, floors: 3, loot: 1.00, whisper: 1.30, relic: 0.00, peek: 1 },
        { name: "THE LONG CORRIDOR",desc: "5 floors. Relic chance +4%.",
          doors: 0,  nerve: 0,  floors: 5, loot: 1.00, whisper: 1.00, relic: 0.04, peek: 1 },
        { name: "THE WAX MOON",     desc: "Embers +50%. Nerve -1.",
          doors: 0,  nerve: -1, floors: 3, loot: 1.50, whisper: 1.00, relic: 0.00, peek: 1 },
        { name: "THE UNBLINKING",   desc: "5 doors. No free peek.",
          doors: 2,  nerve: 0,  floors: 3, loot: 1.00, whisper: 1.00, relic: 0.00, peek: 0 }
    ];
}

function veil_hall_mod() {
    var _mods = veil_hall_mods();
    var _i = 0;
    if (variable_struct_exists(global.G, "occult") && is_struct(global.G.occult)
        && variable_struct_exists(global.G.occult, "hall")
        && is_struct(global.G.occult.hall)
        && variable_struct_exists(global.G.occult.hall, "mood")) {
        _i = global.G.occult.hall.mood;
    }
    return _mods[clamp(is_numeric(_i) ? floor(_i) : 0, 0, array_length(_mods) - 1)];
}

function veil_hall_pick_mod() {
    var _mods = veil_hall_mods();
    if (global.G.occult.stats.halls <= 0) return 0;
    var _last = variable_struct_exists(global.G.occult.hall, "last_mod")
              ? global.G.occult.hall.last_mod : -1;
    var _n = array_length(_mods);
    var _i = irandom(_n - 1);
    // Pick from the other n-1 nights, never the one just played. The old
    // fallback could wrap back to _last and repeat it.
    if (_i == _last) _i = (_last + 1 + irandom(_n - 2)) mod _n;
    return _i;
}

function veil_hall_door_count() {
    return clamp(veil_hall_doors() + veil_hall_mod().doors, 2, 5);
}

function veil_hall_floors() {
    return veil_hall_mod().floors;
}

function veil_hall_outcome(_seed, _floor, _i) {
    var _h = abs((_seed * 928371 + (_floor + 1) * 7919 + (_i + 1) * 104729) mod 1000003);
    var _kind = _h mod 10;
    var _val = (_h div 10) mod 14;
    var _tag = 0;
    var _label = "";
    switch (_kind) {
        case 0: _label = "A WARM POCKET"; break;
        case 1: _label = "A HELD BREATH"; break;
        case 2: _label = "SOMETHING WITHDRAWS"; break;
        case 3: _label = "A MARK ON THE FRAME"; break;
        case 4: _label = "SOMETHING SHINES"; break;
        case 5: _label = "A JAR, STILL WARM"; break;
        case 6: _label = "A BOTTLE, UNCORKED"; break;
        case 7: _label = "A DEAD END"; break;
        case 8: _label = "A ROOM FULL OF COINS"; break;
        case 9: _label = "THE FLOOR TILTS"; break;
    }
    if (_kind == 3 || _kind == 7 || _kind == 9 || _kind == 2) _tag = 1;
    if (_kind == 4 || _kind == 6) _tag = 2;
    return { kind: _kind, val: _val, tag: _tag, label: _label };
}

function veil_hall_tag_name(_tag) {
    if (_tag == 1) return "DARK";
    if (_tag == 2) return "????";
    return "SAFE";
}

function veil_hall_tag_colour(_tag) {
    if (_tag == 1) return V_BLOOD_HI;
    if (_tag == 2) return vc(146, 120, 190);
    return V_BONE_DIM;
}

function veil_hall_reset_doors(_hall) {
    var _n = veil_hall_door_count();
    if (!is_array(_hall.doors)) _hall.doors = [];
    if (!is_array(_hall.peeked)) _hall.peeked = [];
    array_resize(_hall.doors, 5);
    array_resize(_hall.peeked, 5);
    for (var _i = 0; _i < 5; _i++) {
        _hall.doors[_i] = (_i < _n) ? 1 : 0;
        _hall.peeked[_i] = 0;
    }
}

function veil_hall_start() {
    var _h = global.G.occult.hall;
    _h.mood = veil_hall_pick_mod();
    _h.last_mod = _h.mood;
    _h.floors = veil_hall_floors();
    _h.active = true;
    _h.floor = 0;
    _h.nerve = veil_hall_nerve() + arc_hall_nerve();
    _h.seed = irandom(999999) + 1;
    _h.taken = -1;
    _h.loot_e = 0;
    _h.loot_w = 0;
    _h.cleared = 0;
    _h.free = veil_lvl("peek") * veil_hall_mod().peek;
    _h.feedback = "THE HALL IS LONGER THAN THE CAFE.";
    veil_hall_reset_doors(_h);
    save_write();
}

function veil_hall_peek(_i) {
    var _h = global.G.occult.hall;
    var _n = veil_hall_door_count();
    if (!_h.active || _i < 0 || _i >= _n || _h.taken >= 0) return false;
    if (_h.peeked[_i] == 1) return false;
    var _cost = 0;
    if (_h.free > 0) _h.free -= 1;
    else _cost = veil_peek_cost();
    if (global.G.occult.whispers < _cost) {
        _h.feedback = "NOT ENOUGH WHISPERS TO SEE THROUGH IT.";
        return false;
    }
    global.G.occult.whispers -= _cost;
    _h.peeked[_i] = 1;
    _h.feedback = "SEEN: " + veil_hall_outcome(_h.seed, _h.floor, _i).label;
    save_write();
    return true;
}

function veil_hall_resolve(_i) {
    var _o = global.G.occult;
    var _h = _o.hall;
    var _n = veil_hall_door_count();
    if (!_h.active || _h.taken >= 0 || _i < 0 || _i >= _n) return false;
    var _out = veil_hall_outcome(_h.seed, _h.floor, _i);
    _h.taken = _i;
    switch (_out.kind) {
        case 0:
            _h.loot_e += 12 + _out.val;
            _h.feedback = "A WARM POCKET: " + string(12 + _out.val) + " EMBERS.";
            break;
        case 1:
            _h.loot_w += 1 + (_out.val mod 3);
            _h.feedback = "A HELD BREATH: WHISPERS FOLLOW YOU.";
            break;
        case 2:
            _h.nerve -= 1;
            _h.feedback = "SOMETHING WITHDRAWS. NERVE -1.";
            break;
        case 3: {
            var _ci = veil_curse_add(-1);
            _h.feedback = "MARKED: " + veil_curses()[_ci].name + ".";
            break;
        }
        case 4:
            if (random(1) < 0.5) veil_relic_grant(-1);
            else _h.loot_e += 30;
            _h.feedback = "SOMETHING SHINES IN THE DUST.";
            break;
        case 5:
            for (var _r = 0; _r < 2; _r++) {
                _o.bench.reagents[irandom(VEIL_REAGENTS - 1)] += 2;
            }
            _h.feedback = "TWO JARS, STILL WARM.";
            break;
        case 6: {
            var _t = irandom(VEIL_TINCTURES - 1);
            _o.bench.tinctures[_t] += 1;
            _o.bench.known[_t] = true;
            _h.feedback = "A BOTTLE: " + veil_tincture_name(_t) + ".";
            break;
        }
        case 7:
            _h.feedback = "A DEAD END. YOU LOSE YOUR BEARINGS.";
            _h.nerve -= 1;
            break;
        case 8:
            _h.loot_e += 26 + _out.val;
            _h.nerve -= 1;
            _h.feedback = "COINS, AND SOMETHING UNDER THEM. NERVE -1.";
            break;
        case 9:
            _h.nerve -= 2;
            _h.feedback = "THE FLOOR TILTS. NERVE -2.";
            break;
    }
    if (_h.nerve <= 0) {
        _h.nerve = 0;
        veil_hall_end(false);
        return true;
    }
    save_write();
    return true;
}

/// Move on after reading the outcome. The presence waits after three doors.
function veil_hall_continue() {
    var _o = global.G.occult;
    var _h = _o.hall;
    if (!_h.active || _h.taken < 0) return false;
    _h.taken = -1;
    _h.floor += 1;
    if (_h.floor >= _h.floors) {
        // The presence asks for nerve before it lets the run end.
        if (_h.nerve >= 2) {
            _h.nerve -= 2;
            veil_hall_end(true);
        } else {
            veil_hall_end(false);
        }
        return true;
    }
    _h.free = veil_lvl("peek") * veil_hall_mod().peek;
    veil_hall_reset_doors(_h);
    _h.feedback = "THE HALL TURNS. FLOOR " + string(_h.floor + 1)
                + " OF " + string(_h.floors) + ".";
    save_write();
    return true;
}

/// Loot is never lost entirely: a failed presence still pays half. The run
/// itself is where the choices were, not the payout.
function veil_hall_end(_cleared) {
    var _o = global.G.occult;
    var _h = _o.hall;
    var _m = veil_hall_mod();
    var _mult = (_cleared ? 1 : 0.5) * _m.loot;
    if (_h.loot_e > 0) veil_gain_embers(_h.loot_e * _mult);
    if (_h.loot_w > 0) veil_gain_whispers(_h.loot_w * _mult * _m.whisper);
    _o.stats.halls += 1;
    _o.stats.floors += _h.floor;
    if (_h.floor > _o.stats.best_hall) _o.stats.best_hall = _h.floor;
    if (_cleared) {
        _h.cleared = 1;
        _o.blood += 1;
        if (random(1) < veil_relic_chance() + 0.12 + _m.relic) veil_relic_grant(-1);
        _h.feedback = "THE HALL LETS YOU OUT. IT WILL REMEMBER YOU.";
    } else {
        _h.cleared = 0;
        _h.feedback = "YOU CRAWL OUT. HALF THE LOOT, ALL THE LESSON.";
    }
    _h.active = false;
    _h.taken = -1;
    _h.loot_e = 0;
    _h.loot_w = 0;
    save_write();
}

function veil_hall_abandon() {
    var _h = global.G.occult.hall;
    if (!_h.active) return false;
    veil_hall_end(false);
    return true;
}

// ---------------------------------------------------------------- layout

/// Four and five doors tighten and slide left rather than drawing under the
/// run panel. The panel begins at 1236, so the widest row still ends by 1186.
function veil_hall_door_x(_i, _n) {
    var _gap = (_n >= 5) ? 40 : 60;
    var _w = 180;
    var _total = _n * _w + (_n - 1) * _gap;
    return VUI_MX + floor((1100 - _total) * 0.5) + _i * (_w + _gap);
}

function veil_hall_ui() {
    var _n = veil_hall_door_count();
    var _doors = [];
    var _peeks = [];
    for (var _i = 0; _i < _n; _i++) {
        var _x = veil_hall_door_x(_i, _n);
        array_push(_doors, { x: _x, y: 196, w: 180, h: 440, index: _i });
        array_push(_peeks, { x: _x, y: 652, w: 180, h: UI_H_ROW, index: _i });
    }
    var _run = { x: 1236, y: 176, w: 588, h: 620 };
    return {
        doors: _doors,
        peeks: _peeks,
        run: _run,
        start:   { x: _run.x + 34, y: _run.y + 514, w: _run.w - 68, h: UI_H_CTA },
        cleanse: { x: _run.x + 34, y: _run.y + 430, w: _run.w - 68, h: UI_H_CTA },
        continue: { x: _run.x + 34, y: _run.y + 514, w: _run.w - 68, h: UI_H_CTA },
        nerve: { x: VUI_MX, y: 784, w: 720, h: 140 },
        abandon: { x: 876, y: 826, w: 280, h: UI_H_CTA }
    };
}

// ---------------------------------------------------------------- input

function veil_hall_click(_x, _y) {
    var _h = global.G.occult.hall;
    var _u = veil_hall_ui();

    if (!_h.active) {
        if (dui_clicked(_u.start.x, _u.start.y, _u.start.w, _u.start.h)) {
            veil_hall_start();
            return "start";
        }
        if (array_length(global.G.occult.curses) > 0
            && dui_clicked(_u.cleanse.x, _u.cleanse.y, _u.cleanse.w, _u.cleanse.h)) {
            if (veil_curse_cleanse()) return "cleanse";
        }
        return "";
    }

    if (_h.taken >= 0) {
        if (dui_clicked(_u.continue.x, _u.continue.y, _u.continue.w, _u.continue.h)) {
            veil_hall_continue();
            return "continue";
        }
        return "";
    }

    for (var _i = 0; _i < array_length(_u.doors); _i++) {
        var _d = _u.doors[_i];
        if (dui_clicked(_d.x, _d.y, _d.w, _d.h)) {
            veil_hall_resolve(_d.index);
            return "door";
        }
        var _p = _u.peeks[_i];
        if (dui_clicked(_p.x, _p.y, _p.w, _p.h)) {
            veil_hall_peek(_p.index);
            return "peek";
        }
    }
    var _a = _u.abandon;
    if (dui_clicked(_a.x, _a.y, _a.w, _a.h)) {
        veil_hall_abandon();
        return "abandon";
    }
    return "";
}

// ---------------------------------------------------------------- drawing

function veil_hall_draw() {
    var _h = global.G.occult.hall;
    var _u = veil_hall_ui();
    var _n = array_length(_u.doors);

    for (var _i = 0; _i < _n; _i++) {
        var _d = _u.doors[_i];
        var _out = veil_hall_outcome(_h.seed, _h.floor, _i);
        var _chosen = (_h.taken == _i);
        var _open = (_h.taken < 0);
        var _hot = dui_hover(_d.x, _d.y, _d.w, _d.h);

        // risk tag
        draw_set_colour(vc(14, 10, 12));
        draw_rectangle(_d.x, 160, _d.x + _d.w, 188, false);
        dui_vtext(_d.x + _d.w * 0.5, 164, veil_hall_tag_name(_out.tag),
                  global.fnt_small, veil_hall_tag_colour(_out.tag), fa_center);

        // frame and the dark behind it
        draw_set_colour(_chosen ? V_BLOOD : V_IRON);
        draw_rectangle(_d.x - 4, _d.y - 4, _d.x + _d.w + 4, _d.y + _d.h + 4, false);
        draw_set_colour(_chosen ? V_BLOOD : vc(20, 14, 17));
        draw_rectangle(_d.x, _d.y, _d.x + _d.w, _d.y + _d.h, false);

        // A flat lintel, not a 34px roof: the risk tag above every door needs
        // its whole row, and a peak was sitting right through the text.
        draw_set_colour(V_IRON_HI);
        draw_rectangle(_d.x - 4, _d.y - 8, _d.x + _d.w + 4, _d.y - 2, false);
        draw_set_colour(_chosen ? V_BLOOD : V_IRON);
        draw_circle(_d.x + _d.w * 0.5, _d.y - 5, 4, false);

        if (_chosen) {
            draw_set_alpha(0.35 + 0.1 * sin(global.time * 4));
            draw_set_colour(V_EMBER);
            draw_rectangle(_d.x + 10, _d.y + 14, _d.x + _d.w - 10, _d.y + _d.h - 10, true);
            draw_set_alpha(1);
        } else if (_hot && _open) {
            draw_set_colour(V_EMBER);
            draw_rectangle(_d.x + 2, _d.y + 2, _d.x + _d.w - 2, _d.y + _d.h - 2, true);
        }

        // a numbered brass plate: the only readable thing on a closed door
        draw_set_colour(V_WAX);
        draw_circle(_d.x + _d.w * 0.5, _d.y + 82, 18, false);
        draw_set_colour(V_VOID);
        draw_circle(_d.x + _d.w * 0.5, _d.y + 82, 14, false);
        dui_vtext(_d.x + _d.w * 0.5, _d.y + 68, string(_i + 1),
                  global.fnt_big, V_BONE, fa_center);

        if (!_open) {
            draw_set_alpha(0.58);
            draw_set_colour(V_VOID);
            draw_rectangle(_d.x, _d.y, _d.x + _d.w, _d.y + _d.h, false);
            draw_set_alpha(1);
        }

        if (_h.peeked[_i] == 1) {
            var _lines = guide_wrap_px(_out.label, _d.w - 24);
            for (var _l = 0; _l < min(4, array_length(_lines)); _l++) {
                dui_vtext(_d.x + _d.w * 0.5, _d.y + 300 + _l * 26, _lines[_l],
                          global.fnt_small, V_EMBER, fa_center);
            }
        } else if (_open) {
            dui_vtext(_d.x + _d.w * 0.5, _d.y + 382, "CHOOSE",
                      global.fnt_small, _hot ? V_EMBER : V_BONE_DIM, fa_center);
        }

        // peek control sits outside the door card, so the two hit boxes never
        // overlap even at five doors.
        var _p = _u.peeks[_i];
        dui_vbutton(_p.x, _p.y, _p.w, _p.h,
                    _h.peeked[_i] == 1 ? "SEEN" : "PEEK",
                    _open && dui_hover(_p.x, _p.y, _p.w, _p.h), false, _open);
    }

    // nerve, as candles: one goes out per point lost
    var _nc = _u.nerve;
    dui_vpanel(_nc.x, _nc.y, _nc.w, _nc.h, 0);
    var _max_n = veil_hall_nerve();
    dui_vtext(_nc.x + 24, _nc.y + 16, "NERVE " + string(_h.nerve) + "/" + string(_max_n),
              global.fnt_small, V_BLOOD_HI, fa_left);
    for (var _i = 0; _i < _max_n; _i++) {
        var _cx = _nc.x + 28 + (_i mod 10) * 48;
        var _cy = _nc.y + 66 + (_i div 10) * 38;
        draw_set_colour(V_WAX);
        draw_rectangle(_cx, _cy, _cx + 5, _cy + 22, false);
        if (_i < _h.nerve) {
            draw_set_colour(V_EMBER);
            draw_circle(_cx + 2, _cy - 6, 5, false);
            dui_vglow(_cx + 2, _cy - 6, 4, V_EMBER, 0.22);
        } else {
            draw_set_colour(V_IRON_HI);
            draw_line(_cx - 3, _cy - 8, _cx + 9, _cy + 2);
        }
    }

    // status card
    var _rp = _u.run;
    dui_vpanel(_rp.x, _rp.y, _rp.w, _rp.h, 0);
    dui_vtext(_rp.x + 30, _rp.y + 22, "THE RUN", global.fnt_small, V_BLOOD_HI, fa_left);
    dui_vtext(_rp.x + _rp.w - 30, _rp.y + 22,
              "FLOOR " + string(min(_h.floors, _h.floor + 1))
              + " OF " + string(_h.floors),
              global.fnt_small, V_BONE_DIM, fa_right);
    dui_vtext(_rp.x + 30, _rp.y + 188, "NIGHT: " + veil_hall_mod().name,
              global.fnt_small, V_EMBER, fa_left);
    dui_vtext(_rp.x + 30, _rp.y + 62,
              "NERVE " + string(_h.nerve) + "/" + string(_max_n),
              global.fnt_small, V_BONE, fa_left);
    dui_vtext(_rp.x + 30, _rp.y + 94, "EMBERS " + fmt_number(_h.loot_e),
              global.fnt_small, V_BONE_DIM, fa_left);
    dui_vtext(_rp.x + 30, _rp.y + 126, "WHISPERS " + fmt_number(_h.loot_w),
              global.fnt_small, V_BONE_DIM, fa_left);
    dui_vtext(_rp.x + 30, _rp.y + 158,
              "CURSES " + string(array_length(global.G.occult.curses)),
              global.fnt_small,
              array_length(global.G.occult.curses) > 0 ? V_BLOOD_HI : V_BONE_DIM, fa_left);

    var _fb = guide_wrap_px(_h.feedback, _rp.w - 60);
    for (var _l = 0; _l < min(5, array_length(_fb)); _l++) {
        dui_vtext(_rp.x + 30, _rp.y + 208 + _l * 28, _fb[_l],
                  global.fnt_small, V_BONE, fa_left);
    }

    if (!_h.active) {
        var _mn = veil_hall_mod();
        dui_vtext(_rp.x + 30, _rp.y + 350, "TONIGHT: " + _mn.name,
                  global.fnt_small, V_EMBER, fa_left);
        var _md = guide_wrap_px(_mn.desc, _rp.w - 60);
        for (var _ml = 0; _ml < min(2, array_length(_md)); _ml++) {
            dui_vtext(_rp.x + 30, _rp.y + 378 + _ml * 26, _md[_ml],
                      global.fnt_small, V_BONE_DIM, fa_left);
        }
        dui_vtext(_rp.x + 30, _rp.y + 440,
                  string(_mn.floors) + " FLOORS. " + string(veil_hall_door_count())
                  + " DOORS. NO MERCY.",
                  global.fnt_small, vc(112, 100, 92), fa_left);
        dui_vbutton(_u.start.x, _u.start.y, _u.start.w, _u.start.h, "ENTER THE HALL",
                    dui_hover(_u.start.x, _u.start.y, _u.start.w, _u.start.h), false, true);
        if (array_length(global.G.occult.curses) > 0) {
            dui_vbutton(_u.cleanse.x, _u.cleanse.y, _u.cleanse.w, _u.cleanse.h,
                        "CLEANSE " + string(veil_curse_cleanse_cost()),
                        dui_hover(_u.cleanse.x, _u.cleanse.y, _u.cleanse.w, _u.cleanse.h),
                        false, global.G.occult.embers >= veil_curse_cleanse_cost());
        }
    } else if (_h.taken >= 0) {
        dui_vbutton(_u.continue.x, _u.continue.y, _u.continue.w, _u.continue.h,
                    "KEEP WALKING",
                    dui_hover(_u.continue.x, _u.continue.y, _u.continue.w, _u.continue.h),
                    false, true);
    } else {
        dui_vtext(_rp.x + 30, _rp.y + 514, "CHOOSE A DOOR.",
                  global.fnt_small, V_EMBER, fa_left);
        var _a = _u.abandon;
        dui_vbutton(_a.x, _a.y, _a.w, _a.h, "TURN BACK",
                    dui_hover(_a.x, _a.y, _a.w, _a.h), false, true);
    }
}
