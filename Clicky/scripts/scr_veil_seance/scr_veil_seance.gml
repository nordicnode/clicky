/// THE COLD PARLOUR: a séance is a seating puzzle, not a menu.
/// Each case is generated from its seed, then checked by brute force so the
/// clues always describe exactly one arrangement. Nothing here draws outside
/// the activity's scene; the palette lives in scr_veil_art.

function veil_seat_gap(_a, _b, _n) {
    var _d = abs(_a - _b);
    return min(_d, _n - _d);
}

function veil_fact(_n) {
    var _f = 1;
    for (var _i = 2; _i <= _n; _i++) _f *= _i;
    return _f;
}

/// The index-th permutation of seats, in factorial order. Deterministic: two
/// runs with the same seed must produce the same case, reload included.
function veil_perm_at(_n, _index) {
    var _avail = [];
    for (var _i = 0; _i < _n; _i++) array_push(_avail, _i);
    var _out = [];
    var _idx = _index;
    for (var _pos = _n - 1; _pos >= 0; _pos--) {
        var _f = veil_fact(_pos);
        var _k = _idx div _f;
        _idx = _idx mod _f;
        array_push(_out, _avail[_k]);
        array_delete(_avail, _k, 1);
    }
    return _out;
}

function veil_rng(_seed) {
    return { s: ((_seed * 48271 + 12345) mod 2147483647) + 1 };
}

function veil_rand(_r) {
    _r.s = (_r.s * 48271) mod 2147483647;
    return _r.s;
}

function veil_rand_range(_r, _n) {
    if (_n <= 0) return 0;
    return veil_rand(_r) mod _n;
}

function veil_shuffle(_r, _a) {
    for (var _i = array_length(_a) - 1; _i > 0; _i--) {
        var _j = veil_rand_range(_r, _i + 1);
        var _t = _a[_i];
        _a[_i] = _a[_j];
        _a[_j] = _t;
    }
    return _a;
}

function veil_clue_ok(_c, _seat_of) {
    var _n = _c.n;
    switch (_c.k) {
        case "beside":      return veil_seat_gap(_seat_of[_c.a], _seat_of[_c.b], _n) == 1;
        case "not_beside":  return veil_seat_gap(_seat_of[_c.a], _seat_of[_c.b], _n) != 1;
        case "opposite":    return veil_seat_gap(_seat_of[_c.a], _seat_of[_c.b], _n) == _n div 2;
        case "not_opposite":return veil_seat_gap(_seat_of[_c.a], _seat_of[_c.b], _n) != _n div 2;
        case "not_end":     return _seat_of[_c.a] != 0 && _seat_of[_c.a] != _n - 1;
        case "end":         return _seat_of[_c.a] == 0 || _seat_of[_c.a] == _n - 1;
        case "seat_not":    return _seat_of[_c.a] != _c.s;
        case "seat_is":     return _seat_of[_c.a] == _c.s;
        case "neither":
            return veil_seat_gap(_seat_of[_c.a], _seat_of[_c.b], _n) != 1
                && veil_seat_gap(_seat_of[_c.a], _seat_of[_c.c], _n) != 1;
        case "distance":    return veil_seat_gap(_seat_of[_c.a], _seat_of[_c.b], _n) == _c.d;
    }
    return true;
}

function veil_clue_holds(_case, _seat_of) {
    for (var _i = 0; _i < array_length(_case.clues); _i++) {
        if (!veil_clue_ok(_case.clues[_i], _seat_of)) return false;
    }
    return true;
}

/// Every true statement about the secret seating, in a stable order. Greedy
/// filtering then keeps only statements that still fit every remaining
/// arrangement, which is how a case becomes solvable and unique.
function veil_clue_pool(_n, _truth) {
    var _p = [];
    for (var _a = 0; _a < _n; _a++) {
        var _sa = _truth[_a];
        // A round table has no end seats: every seat already has two
        // neighbours, so an "end" clue would be a lie dressed as a rule.
        for (var _s = 0; _s < _n; _s++) {
            if (_s != _sa) array_push(_p, { k: "seat_not", a: _a, s: _s, n: _n });
        }
        for (var _b = _a + 1; _b < _n; _b++) {
            var _sb = _truth[_b];
            var _gap = veil_seat_gap(_sa, _sb, _n);
            if (_gap == 1) {
                array_push(_p, { k: "beside", a: _a, b: _b, n: _n });
            } else {
                array_push(_p, { k: "not_beside", a: _a, b: _b, n: _n });
                if (_n mod 2 == 0 && _gap == _n div 2) {
                    array_push(_p, { k: "opposite", a: _a, b: _b, n: _n });
                } else if (_n mod 2 == 0) {
                    array_push(_p, { k: "not_opposite", a: _a, b: _b, n: _n });
                }
            }
            if (_gap > 1 && _gap <= _n div 2) {
                array_push(_p, { k: "distance", a: _a, b: _b, d: _gap, n: _n });
            }
            if (_n >= 5) {
                for (var _c = _b + 1; _c < _n; _c++) {
                    if (veil_seat_gap(_sa, _truth[_c], _n) != 1) {
                        array_push(_p, { k: "neither", a: _a, b: _b, c: _c, n: _n });
                    }
                }
            }
        }
    }
    return _p;
}

/// Build (and cache) the case for a seed and tier. The cache key includes the
/// number of seats, so advancing a tier cannot silently reuse a smaller case.
function veil_case_build(_seed, _tier) {
    if (!variable_global_exists("veil_case_cache")) {
        global.veil_case_cache = { key: "", data: -1 };
    }
    var _n = veil_case_seats(_tier);
    var _key = string(_seed) + ":" + string(_n);
    if (global.veil_case_cache.key == _key && is_struct(global.veil_case_cache.data)) {
        return global.veil_case_cache.data;
    }

    var _perms = [];
    var _total = veil_fact(_n);
    for (var _i = 0; _i < _total; _i++) array_push(_perms, veil_perm_at(_n, _i));
    var _r = veil_rng(_seed * 31 + _n * 7 + 1);
    var _truth = _perms[veil_rand_range(_r, _total)];

    var _pool = veil_clue_pool(_n, _truth);
    // Strong statements first, seat exclusions last. A case that can be told
    // in three good sentences should not need nine weak ones.
    var _strong = [];
    var _weak = [];
    for (var _i = 0; _i < array_length(_pool); _i++) {
        if (_pool[_i].k == "seat_not") array_push(_weak, _pool[_i]);
        else array_push(_strong, _pool[_i]);
    }
    _pool = veil_shuffle(_r, _strong);
    _weak = veil_shuffle(_r, _weak);
    for (var _i = 0; _i < array_length(_weak); _i++) array_push(_pool, _weak[_i]);
    var _cands = [];
    for (var _i = 0; _i < _total; _i++) array_push(_cands, _perms[_i]);

    // A round table makes every relational clue rotation-invariant: without an
    // absolute anchor, the true seating can be turned and still fit. One
    // marked seat breaks that symmetry and is the first thing a medium says.
    var _clues = [];
    var _anchor = veil_rand_range(_r, _n);
    var _anchor_clue = { k: "seat_is", a: _anchor, s: _truth[_anchor], n: _n };
    array_push(_clues, _anchor_clue);
    var _anchored = [];
    for (var _j = 0; _j < array_length(_cands); _j++) {
        if (veil_clue_ok(_anchor_clue, _cands[_j])) array_push(_anchored, _cands[_j]);
    }
    _cands = _anchored;

    // Each testimony must eliminate as many wrong seatings as it can. Greedy
    // selection turns a six-spirit case from fifteen weak sentences into four
    // strong ones, which is the difference between a puzzle and a wall of text.
    var _want = 3 + (_tier >= 2 ? 1 : 0);
    var _limit = min(array_length(_pool), 70);
    while (array_length(_clues) < 5
           && (array_length(_cands) > 1 || array_length(_clues) < _want)) {
        var _pick = -1;
        var _best = array_length(_cands) + 1;
        for (var _i = 0; _i < min(_limit, array_length(_pool)); _i++) {
            var _test = _pool[_i];
            if (!veil_clue_ok(_test, _truth)) continue;
            var _left = 0;
            for (var _j = 0; _j < array_length(_cands); _j++) {
                if (veil_clue_ok(_test, _cands[_j])) _left += 1;
            }
            if (_left > 0 && _left < _best) { _best = _left; _pick = _i; }
        }
        if (_pick < 0) break;
        var _clue = _pool[_pick];
        var _next = [];
        for (var _j = 0; _j < array_length(_cands); _j++) {
            if (veil_clue_ok(_clue, _cands[_j])) array_push(_next, _cands[_j]);
        }
        array_push(_clues, _clue);
        array_delete(_pool, _pick, 1);
        _cands = _next;
    }
    // Fallback: name seats outright. This always narrows to one arrangement.
    if (array_length(_cands) != 1) {
        for (var _a = 0; _a < _n && array_length(_cands) > 1; _a++) {
            var _direct = { k: "seat_is", a: _a, s: _truth[_a], n: _n };
            array_push(_clues, _direct);
            var _next = [];
            for (var _j = 0; _j < array_length(_cands); _j++) {
                if (veil_clue_ok(_direct, _cands[_j])) array_push(_next, _cands[_j]);
            }
            _cands = _next;
        }
    }

    // Last resort for a pathological pool: state every seat. This is dull,
    // but it is always valid and always has exactly one solution.
    if (array_length(_cands) != 1) {
        _clues = [];
        _cands = [];
        for (var _i = 0; _i < _total; _i++) array_push(_cands, _perms[_i]);
        for (var _a = 0; _a < _n; _a++) {
            var _direct = { k: "seat_is", a: _a, s: _truth[_a], n: _n };
            array_push(_clues, _direct);
            var _next = [];
            for (var _j = 0; _j < array_length(_cands); _j++) {
                if (veil_clue_ok(_direct, _cands[_j])) array_push(_next, _cands[_j]);
            }
            _cands = _next;
        }
    }

    var _case = {
        n: _n, tier: clamp(_tier, 0, 2), seed: _seed,
        truth: _truth, clues: _clues, solutions: array_length(_cands)
    };
    global.veil_case_cache.key = _key;
    global.veil_case_cache.data = _case;
    return _case;
}

function veil_spirit_name(_i) {
    var _names = ["MOTH", "WICK", "SABLE", "IVY", "CINDER", "PALE"];
    if (_i < 0 || _i >= array_length(_names)) return "?";
    return _names[_i];
}

function veil_clue_text(_c, _n) {
    var _a = veil_spirit_name(_c.a);
    switch (_c.k) {
        case "beside":      return _a + " SAT BESIDE " + veil_spirit_name(_c.b) + ".";
        case "not_beside":  return _a + " AVOIDED " + veil_spirit_name(_c.b) + ".";
        case "opposite":    return _a + " FACED " + veil_spirit_name(_c.b) + ".";
        case "not_opposite":return _a + " AVOIDED " + veil_spirit_name(_c.b) + ".";
        case "not_end":     return _a + " REFUSED BOTH ENDS.";
        case "end":         return _a + " TOOK AN END SEAT.";
        case "seat_not":    return _a + " REFUSED SEAT " + string(_c.s + 1) + ".";
        case "seat_is":     return _a + " TOOK SEAT " + string(_c.s + 1) + ".";
        case "neither":     return _a + " AVOIDED " + veil_spirit_name(_c.b) + " AND "
                               + veil_spirit_name(_c.c) + ".";
        case "distance":    return _a + " SAT " + string(_c.d) + " SEATS FROM "
                               + veil_spirit_name(_c.b) + ".";
    }
    return "";
}

/// -1 means the arrangement satisfies every testimony.
function veil_case_violation(_case, _seat_of) {
    for (var _i = 0; _i < array_length(_case.clues); _i++) {
        if (!veil_clue_ok(_case.clues[_i], _seat_of)) return _i;
    }
    return -1;
}

/// Seat coordinates are shared by the drawing and the hit tests, so a cushion
/// can never drift away from where it is clicked. Native 1920 geometry: the
/// table sits in the middle card and the seats are large enough to read.
function veil_seat_x(_i, _n) {
    return 900 + cos(-pi / 2 + _i * 2 * pi / _n) * 280;
}

function veil_seat_y(_i, _n) {
    return 500 + sin(-pi / 2 + _i * 2 * pi / _n) * 190;
}

function veil_seat_at_mouse(_n, _x, _y) {
    for (var _i = 0; _i < _n; _i++) {
        if (point_distance(_x, _y, veil_seat_x(_i, _n), veil_seat_y(_i, _n)) < 52) return _i;
    }
    return -1;
}

/// The parlour grows harder as the closings accumulate: four seats at the
/// start, five in the middle, six for the deepest cases.
function veil_seance_tier() {
    var _c = global.G.occult.closings;
    if (_c >= 9) return 2;
    if (_c >= 4) return 1;
    return 0;
}

function veil_seance_reset(_state, _tier) {
    _state.seed += 1 + irandom(3);
    _state.tier = clamp(_tier, 0, 2);
    _state.solved = false;
    _state.tries = 0;
    _state.sel = -1;
    _state.clue_top = 0;
    _state.free = veil_lvl("keen");
    _state.feedback = "";
    for (var _i = 0; _i < 6; _i++) {
        _state.placed[_i] = -1;
        _state.reveal[_i] = -1;
    }
}

/// A free reveal, used by the Clear Sight tincture. Always picks the first
/// spirit whose seat is still unknown.
function veil_seance_force_reveal(_state) {
    var _case = veil_case_build(_state.seed, _state.tier);
    if (!is_array(_state.reveal)) _state.reveal = array_create(6, -1);
    for (var _i = 0; _i < _case.n; _i++) {
        if (_state.reveal[_i] < 0) {
            _state.reveal[_i] = _case.truth[_i];
            return true;
        }
    }
    return false;
}

function veil_seance_reveal(_state, _case) {
    if (_state.solved) return false;
    var _cost = 1;
    if (veil_num(_state.free, 0) > 0) {
        _cost = 0;
    } else if (global.G.occult.whispers < _cost) {
        _state.feedback = "NOT ENOUGH WHISPERS.";
        return false;
    }
    for (var _i = 0; _i < 6; _i++) {
        if (!is_array(_state.reveal)) _state.reveal = array_create(6, -1);
    }
    var _pick = -1;
    for (var _i = 0; _i < _case.n; _i++) {
        if (_state.reveal[_i] < 0) _pick = _i;
    }
    if (_pick < 0) {
        _state.feedback = "NOTHING LEFT TO REVEAL.";
        return false;
    }
    if (_cost == 0) _state.free = max(0, veil_num(_state.free, 0) - 1);
    else global.G.occult.whispers -= _cost;
    _state.reveal[_pick] = _case.truth[_pick];
    _state.feedback = veil_spirit_name(_pick) + " SITS AT SEAT " + string(_case.truth[_pick] + 1) + ".";
    save_write();
    return true;
}

/// Seat the selected spirit. Clicking an occupied seat lifts that spirit back
/// up instead, so a wrong placement is always free to undo.
function veil_seance_seat(_state, _seat) {
    var _spirit = (_state.sel == undefined) ? -1 : _state.sel;
    for (var _i = 0; _i < 6; _i++) {
        if (_state.placed[_i] == _seat) {
            _state.placed[_i] = -1;
            _state.sel = _i;
            _state.feedback = "";
            return true;
        }
    }
    if (_spirit < 0) {
        _state.feedback = "CHOOSE A SPIRIT FIRST.";
        return false;
    }
    for (var _i = 0; _i < 6; _i++) {
        if (_state.placed[_i] == _spirit) _state.placed[_i] = -1;
    }
    _state.placed[_spirit] = _seat;
    _state.sel = -1;
    _state.feedback = "";
    return true;
}

function veil_seance_all_seated(_state, _case) {
    for (var _i = 0; _i < _case.n; _i++) {
        if (_state.placed[_i] < 0) return false;
    }
    return true;
}

/// Pay a solved case once. The save marks it solved, so a reload cannot pay
/// twice; NEXT CASE is the only way to earn from the same table again.
function veil_seance_pay(_state, _case, _flawless) {
    var _e = (10 + 6 * _case.tier) * veil_seance_mult();
    if (_flawless) _e *= 1.5 + 0.25 * veil_lvl("candle");
    veil_gain_embers(_e);
    var _w = 1 + _case.tier + veil_lvl("ear");
    veil_gain_whispers(_w * 0.6);
    global.G.occult.stats.seances += 1;
    global.G.occult.stats.solves += 1;
    if (random(1) < 0.35) {
        global.G.occult.bench.reagents[irandom(VEIL_REAGENTS - 1)] += 1;
    }
    if (random(1) < veil_relic_chance() + _case.tier * 0.01) veil_relic_grant(-1);
    save_write();
    return _e;
}

// ---------------------------------------------------------------- layout

/// One layout for the table, roster, testimony and action bar. Both screens
/// (the parlour and the Long Night) share it, so the two cannot drift apart.
function veil_seance_ui(_n) {
    var _rows = [];
    for (var _i = 0; _i < _n; _i++) {
        array_push(_rows, { x: 116, y: 236 + _i * 72, w: 300, h: UI_H_NAV, spirit: _i });
    }
    var _seats = [];
    for (var _i = 0; _i < _n; _i++) {
        array_push(_seats, { x: veil_seat_x(_i, _n), y: veil_seat_y(_i, _n),
                             r: 52, seat: _i });
    }
    return {
        roster:    { x: VUI_MX, y: 176, w: 340, h: 680 },
        table:     { x: 460, y: 176, w: 880, h: 680 },
        testimony: { x: 1364, y: 176, w: 460, h: 680 },
        rows: _rows,
        seats: _seats,
        next:   { x: 96,   y: 864, w: 340, h: UI_H_CTA },
        reveal: { x: 470,  y: 864, w: 300, h: UI_H_CTA },
        listen: { x: 1484, y: 864, w: 340, h: UI_H_CTA }
    };
}

/// The real click handler: rules first, then whatever the shell needs to
/// animate. Returns a short action name for obj_veil to react to.
function veil_seance_click(_state, _tier, _is_night) {
    var _case = veil_case_build(_state.seed, _tier);
    var _u = veil_seance_ui(_case.n);
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    if (dui_clicked(_u.next.x, _u.next.y, _u.next.w, _u.next.h)) {
        if (_is_night) return "abandon";
        veil_seance_reset(_state, _tier);
        return "next";
    }
    if (dui_clicked(_u.listen.x, _u.listen.y, _u.listen.w, _u.listen.h)) {
        if (_state.solved) {
            _state.feedback = "THE TABLE IS QUIET. TAKE ANOTHER CASE.";
            return "already";
        }
        if (!veil_seance_all_seated(_state, _case)) {
            _state.feedback = "SEAT ALL " + string(_case.n) + " SPIRITS.";
            return "wait";
        }
        var _seat_of = array_create(_case.n, -1);
        for (var _i = 0; _i < _case.n; _i++) _seat_of[_i] = _state.placed[_i];
        var _bad = veil_case_violation(_case, _seat_of);
        if (_bad >= 0) {
            _state.tries += 1;
            _state.feedback = "BROKEN: " + veil_clue_text(_case.clues[_bad], _case.n);
            return "fail";
        }
        _state.solved = true;
        var _flawless = (_state.tries == 0);
        var _paid = veil_seance_pay(_state, _case, _flawless);
        _state.feedback = "THE TABLE IS QUIET. +" + fmt_number(_paid) + " EMBERS";
        return "solved";
    }
    if (dui_clicked(_u.reveal.x, _u.reveal.y, _u.reveal.w, _u.reveal.h)) {
        veil_seance_reveal(_state, _case);
        return "reveal";
    }

    // Long cases can overflow the testimony card; the wheel pages it.
    var _t = _u.testimony;
    if (dui_hover(_t.x, _t.y, _t.w, _t.h)) {
        var _top = clamp(veil_num(_state.clue_top, 0), 0, max(0, array_length(_case.clues) - 1));
        if (mouse_wheel_up()) _state.clue_top = max(0, _top - 1);
        if (mouse_wheel_down()) _state.clue_top = min(max(0, array_length(_case.clues) - 1), _top + 1);
    }

    // roster
    for (var _i = 0; _i < array_length(_u.rows); _i++) {
        var _r = _u.rows[_i];
        if (dui_clicked(_r.x, _r.y, _r.w, _r.h)) {
            if (_state.placed[_r.spirit] >= 0) {
                _state.placed[_r.spirit] = -1;
                _state.sel = _r.spirit;
            } else if (_state.sel == _r.spirit) {
                _state.sel = -1;
            } else {
                _state.sel = _r.spirit;
            }
            _state.feedback = "";
            return "select";
        }
    }
    var _seat = veil_seat_at_mouse(_case.n, _mx, _my);
    if (_seat >= 0 && mouse_check_button_pressed(mb_left)) {
        if (veil_seance_seat(_state, _seat)) return "seat";
    }
    return "";
}

function veil_seance_draw(_state, _tier, _is_night) {
    var _case = veil_case_build(_state.seed, _tier);
    var _n = _case.n;
    var _u = veil_seance_ui(_n);

    // ---- roster card
    var _rc = _u.roster;
    dui_vpanel(_rc.x, _rc.y, _rc.w, _rc.h, 0);
    dui_vtext(_rc.x + 24, _rc.y + 22, "SPIRITS", global.fnt_small, V_BLOOD_HI, fa_left);
    var _seated = 0;
    for (var _sc = 0; _sc < _n; _sc++) {
        if (_state.placed[_sc] >= 0) _seated += 1;
    }
    dui_vtext(_rc.x + _rc.w - 24, _rc.y + 22,
              string(_seated) + " SEATED / " + string(_n),
              global.fnt_small, V_BONE_DIM, fa_right);
    for (var _i = 0; _i < array_length(_u.rows); _i++) {
        var _row = _u.rows[_i];
        var _on = (_state.sel == _row.spirit);
        var _seat = _state.placed[_row.spirit];
        dui_vpanel(_row.x, _row.y, _row.w, _row.h, _on);
        if (_on) {
            draw_set_colour(V_EMBER);
            draw_rectangle(_row.x, _row.y, _row.x + _row.w, _row.y + _row.h, true);
        }
        dui_vcat(_row.x + 36, _row.y + 52, 0.8, _row.spirit mod 3,
                 floor(global.time * 1.4 + _row.spirit) mod 4, 1);
        dui_vtext(_row.x + 70, _row.y + 12, veil_spirit_name(_row.spirit),
                  global.fnt_small, _on ? V_EMBER : V_BONE, fa_left);
        dui_vtext(_row.x + 70, _row.y + 38,
                  _seat >= 0 ? ("SEAT " + string(_seat + 1)) : "UNSEATED",
                  global.fnt_small, _seat >= 0 ? V_BONE_DIM : vc(96, 86, 80), fa_left);
        if (_seat < 0 && is_array(_state.reveal) && _state.reveal[_row.spirit] >= 0) {
            dui_vtext(_row.x + _row.w - 16, _row.y + 38,
                      "SEAT " + string(_state.reveal[_row.spirit] + 1),
                      global.fnt_small, V_EMBER, fa_right);
        }
    }

    // ---- table card
    var _tc = _u.table;
    dui_vpanel(_tc.x, _tc.y, _tc.w, _tc.h, 1);
    var _cx = 900, _cy = 500;
    draw_set_alpha(0.55);
    draw_set_colour(V_VOID);
    draw_ellipse(_cx - 270, _cy + 60, _cx + 270, _cy + 210, false);
    draw_set_alpha(1);
    draw_set_colour(V_IRON);
    draw_ellipse(_cx - 258, _cy - 150, _cx + 258, _cy + 158, false);
    draw_set_colour(vc(46, 30, 34));
    draw_ellipse(_cx - 246, _cy - 142, _cx + 246, _cy + 150, false);
    draw_set_colour(vc(72, 20, 24));
    draw_ellipse(_cx - 226, _cy - 128, _cx + 226, _cy + 136, false);
    draw_set_colour(vc(96, 28, 30));
    draw_ellipse(_cx - 204, _cy - 114, _cx + 204, _cy + 122, false);
    draw_set_colour(vc(86, 24, 26));
    for (var _g = 0; _g < 5; _g++) {
        draw_ellipse(_cx - 190 + _g * 10, _cy - 96 + _g * 8,
                     _cx + 190 - _g * 10, _cy + 104 - _g * 8, true);
    }
    draw_set_colour(V_WAX);
    draw_circle(_cx, _cy, 9, false);
    draw_set_colour(V_EMBER);
    draw_circle(_cx, _cy - 6, 6, false);
    dui_vglow(_cx, _cy - 6, 18, V_EMBER, 0.16);

    // candles around the rim
    for (var _c = 0; _c < 6; _c++) {
        var _a = -pi / 2 + _c * pi / 3 + 0.26;
        var _kx = _cx + cos(_a) * 220;
        var _ky = _cy + sin(_a) * 128;
        draw_set_colour(V_WAX);
        draw_rectangle(_kx - 3, _ky - 20, _kx + 3, _ky, false);
        draw_set_colour(V_EMBER);
        draw_circle(_kx, _ky - 24, 4, false);
        dui_vglow(_kx, _ky - 24, 10, V_EMBER, 0.12 + 0.03 * sin(global.time * 3 + _c));
    }

    // seats, numbered, with a cushion and the seated ghost
    for (var _i = 0; _i < _n; _i++) {
        var _s = _u.seats[_i];
        var _spirit = -1;
        for (var _j = 0; _j < _n; _j++) {
            if (_state.placed[_j] == _i) _spirit = _j;
        }
        draw_set_alpha(0.5);
        draw_set_colour(V_VOID);
        draw_ellipse(_s.x - 40, _s.y + 22, _s.x + 40, _s.y + 46, false);
        draw_set_alpha(1);
        draw_set_colour((_spirit >= 0) ? vc(52, 24, 30) : vc(38, 30, 34));
        draw_ellipse(_s.x - 34, _s.y + 14, _s.x + 34, _s.y + 38, false);
        draw_set_colour(V_IRON_HI);
        draw_ellipse(_s.x - 34, _s.y + 14, _s.x + 34, _s.y + 38, true);
        dui_vtext(_s.x, _s.y + 34, string(_i + 1), global.fnt_small,
                  V_BONE_DIM, fa_center);

        if (_spirit >= 0) {
            dui_vcat(_s.x, _s.y + 28, 1.6, _spirit mod 3,
                     floor(global.time * 1.7 + _spirit) mod 4, 1);
            dui_vtext(_s.x, _s.y - 90, veil_spirit_name(_spirit),
                      global.fnt_small, V_BONE, fa_center);
            draw_set_colour(V_BLOOD_HI);
            draw_ellipse(_s.x - 44, _s.y + 20, _s.x + 44, _s.y + 46, true);
        } else if (_state.sel >= 0) {
            draw_set_alpha(0.28 + 0.08 * sin(global.time * 4));
            draw_set_colour(V_EMBER);
            draw_circle(_s.x, _s.y, 26, true);
            draw_set_alpha(1);
            dui_vtext(_s.x, _s.y - 40, "CLICK TO SEAT",
                      global.fnt_small, V_EMBER, fa_center);
        }
    }

    // ---- testimony card
    var _tp = _u.testimony;
    dui_vpanel(_tp.x, _tp.y, _tp.w, _tp.h, 0);
    dui_vtext(_tp.x + 24, _tp.y + 22, "TESTIMONY", global.fnt_small, V_BLOOD_HI, fa_left);
    var _top = clamp(veil_num(_state.clue_top, 0), 0, max(0, array_length(_case.clues) - 1));
    dui_vtext(_tp.x + _tp.w - 24, _tp.y + 22,
              string(min(array_length(_case.clues), _top + 1)) + "/"
              + string(array_length(_case.clues)),
              global.fnt_small, V_BONE_DIM, fa_right);

    var _viol = -1;
    if (veil_seance_all_seated(_state, _case) && !_state.solved) {
        var _seat_of = array_create(_n, -1);
        for (var _i = 0; _i < _n; _i++) _seat_of[_i] = _state.placed[_i];
        _viol = veil_case_violation(_case, _seat_of);
    }

    var _y = _tp.y + 66;
    var _last = _top - 1;
    for (var _i = _top; _i < array_length(_case.clues); _i++) {
        var _col = (_i == _viol) ? V_BLOOD_HI : V_BONE_DIM;
        var _lines = guide_wrap_px(veil_clue_text(_case.clues[_i], _n), _tp.w - 56);
        if (_y + array_length(_lines) * 28 > _tp.y + _tp.h - 66) break;
        for (var _l = 0; _l < array_length(_lines); _l++) {
            dui_vtext(_tp.x + 24, _y, _lines[_l], global.fnt_small, _col, fa_left);
            _y += 28;
        }
        _y += 14;
        _last = _i;
    }
    if (_last < array_length(_case.clues) - 1 || _top > 0) {
        dui_vtext(_tp.x + _tp.w - 24, _tp.y + _tp.h - 40, "SCROLL",
                  global.fnt_small, vc(112, 100, 90), fa_right);
    }

    // ---- action bar: all controls outside the three cards
    dui_vbutton(_u.next.x, _u.next.y, _u.next.w, _u.next.h,
                _is_night ? "ABANDON" : "NEXT CASE",
                dui_hover(_u.next.x, _u.next.y, _u.next.w, _u.next.h), false, true);
    var _reveal_label = (veil_num(_state.free, 0) > 0) ? "REVEAL FREE" : "REVEAL 1 WHISPER";
    dui_vbutton(_u.reveal.x, _u.reveal.y, _u.reveal.w, _u.reveal.h,
                _reveal_label,
                dui_hover(_u.reveal.x, _u.reveal.y, _u.reveal.w, _u.reveal.h),
                false, !_state.solved);
    dui_vbutton(_u.listen.x, _u.listen.y, _u.listen.w, _u.listen.h,
                _state.solved ? "READ AGAIN" : "LISTEN",
                dui_hover(_u.listen.x, _u.listen.y, _u.listen.w, _u.listen.h),
                !_state.solved && _state.sel >= 0, true);

    // Feedback sits inside the table card so the action bar stays a clean row.
    var _fb = _state.feedback;
    if (_fb == "" && !_is_night) _fb = "SEAT THEM, THEN LISTEN.";
    if (_fb != "") {
        var _fl = guide_wrap_px(_fb, 520);
        for (var _l = 0; _l < min(2, array_length(_fl)); _l++) {
            dui_vtext(1020, 790 + _l * 26, _fl[_l], global.fnt_small,
                      _state.solved ? V_BONE : V_BLOOD_HI, fa_center);
        }
    }
}

/// Shared by the tincture and the Listener familiar: solve without playing.
function veil_seance_auto(_tier) {
    var _s = global.G.occult.seance;
    _s.seed += 1 + irandom(2);
    _s.solved = false;
    _s.tries = 0;
    for (var _i = 0; _i < 6; _i++) _s.placed[_i] = -1;
    var _case = veil_case_build(_s.seed, _tier);
    veil_gain_embers(4 + 2 * _case.tier);
    veil_gain_whispers(0.4);
    global.G.occult.stats.seances += 1;
    global.G.occult.stats.solves += 1;
    save_write();
}
