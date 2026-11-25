/// Verification harness for the Hollow. It only runs when CLICKY_VEILTEST is
/// set, so a player build never enters it. It writes plain results and a set
/// of screenshots into the save sandbox, where the isolated test copies them.

function veil_test_note(_ok, _name, _detail) {
    global.vt_pass += _ok ? 1 : 0;
    global.vt_fail += _ok ? 0 : 1;
    // Append per line: a killed runner must still leave the results on disk,
    // and a finished run must not append to a handle it no longer owns.
    if (variable_global_exists("vt_done") && global.vt_done) return;
    var _f = file_text_open_append(global.vt_name);
    file_text_write_string(_f,
        (_ok ? "PASS " : "FAIL ") + _name + " | " + _detail + "\n");
    file_text_close(_f);
}

/// A cat rung kind counts as live only when the same helper gameplay calls
/// returns a non-neutral value at max bond. A new kind with no consumer cannot
/// pass; this is the ladder-side guard against the dead-rung class.
function cat_bond_kind_live(_kind) {
    switch (_kind) {
        case "tap":      return cat_tap_mult() > 1;
        case "rate":     return cat_rate_mult() > 1;
        case "away":     return cat_away_add() > 0;
        case "offcap":   return cat_offcap_add() > 0;
        case "ember":    return cat_ember_mult() > 1;
        case "crit":     return cat_crit_add() > 0;
        case "critpay":  return cat_crit_pay() > 1;
        case "staff":    return cat_staff_add() > 0;
        case "match":    return cat_staff_match_add() > 0;
        case "frenzy":   return cat_frenzy_add() > 0;
        case "combo":    return cat_combo_add() > 0;
        case "grace":    return cat_combo_grace() > 0;
        case "nerve":    return cat_nerve_add() > 0;
        case "peek":     return cat_peek_discount() > 0;
        case "relic":    return cat_relic_add() > 0;
        case "growth":   return cat_growth_mult() > 1;
        case "harvest":  return cat_harvest_add() > 0;
        case "treat":    return cat_treat_every() > 0;
        case "endless":  return cat_endless_combo();
        case "critcombo": return cat_crit_combo();
        case "combo5":   return cat_combo5();
    }
    return false;
}

/// One runtime scale verdict for the Hollow. Called before the last frame
/// save, so a slow screenshot cannot leave the run without its result.
function veil_test_ui_scale() {
    if (variable_global_exists("vt_ui_checked") && global.vt_ui_checked) return;
    global.vt_ui_checked = true;
    var _ok = ui_audit_clean()
           && global.ui_h40 > 0 && global.ui_h44 > 0
           && global.ui_h56 > 0 && global.ui_h64 > 0
           && global.ui_controls > 20 && global.ui_texts > 40;
    var _detail = ui_audit_report();
    if (!ui_audit_clean()) {
        for (var _uf = 0; _uf < min(3, array_length(global.ui_fail)); _uf++) {
            _detail += " !" + global.ui_fail[_uf];
        }
    }
    veil_test_note(_ok, "ui.scale.hollow", _detail);
}

function veil_test_begin() {
    global.vt_pass = 0;
    global.vt_fail = 0;
    global.vt_ui_checked = false;
    global.vt_name = (environment_get_variable("CLICKY_VEILTEST") == "2"
        ? "veiltest2.txt"
        : (environment_get_variable("CLICKY_VEILTEST") == "3"
           ? "veiltest3.txt" : "veiltest.txt"));
    var _f = file_text_open_write(global.vt_name);
    file_text_close(_f);
    global.vt_stage = 0;
    global.vt_wait = 0;
    global.vt_shot = 0;
    global.vt_done = false;
    global.vt_shots = [
        [0, 0, "veil_1_map"], [1, 1, "veil_2_parlour"], [2, 2, "veil_3_garden"],
        [3, 3, "veil_4_hall", "hall"], [4, 4, "veil_5_cellar"],
        [6, 0, "veil_6_rites"], [7, 0, "veil_7_relics"],
        [8, 5, "veil_8_night", "night"], [8, 5, "veil_9_night_intro", "nightintro"],
        [0, 0, "veil_10_omen", "omen"], [0, 0, "veil_11_lesson", "lesson"],
        [2, 2, "veil_12_blight", "blight"]
    ];
}

/// Put each screenshot into the state that shows the screen at its most
/// demanding, without leaving a transient card on the next one.
function veil_test_prep(_kind) {
    var _o = global.G.occult;
    _o.omen.id = -1;
    _o.omen.t = 0;
    with (obj_guide) { shown = -1; }

    if (_kind == "hall") {
        veil_hall_start();
        veil_hall_peek(0);
        // THE QUIET opens with fewer than five doors; resolve the last real
        // door rather than assuming index 1 exists.
        veil_hall_resolve(veil_hall_door_count() - 1);
    } else if (_kind == "night") {
        if (!_o.night.active) veil_night_start();
        _o.night.active = true;
    } else if (_kind == "nightintro") {
        _o.night.active = false;
    } else if (_kind == "omen") {
        _o.omen.id = 2;
        _o.omen.t = 0;
    } else if (_kind == "lesson") {
        with (obj_guide) {
            shown = 1;
            def_id = "garden";
            page = 0;
            cooldown = 0;
        }
    } else if (_kind == "blight") {
        var _g = _o.garden;
        _g.choose = 0;
        _g.plots[0].seed = 2;
        _g.plots[0].blight = true;
        _g.plots[0].need = 60;
        _g.plots[0].planted = date_current_datetime() - 1;
    }
}

function veil_test_rect_in(_r) {
    return _r.x >= 0 && _r.y >= 0
        && _r.x + _r.w <= UI_W && _r.y + _r.h <= UI_H;
}

function veil_test_overlap(_a, _b) {
    return _a.x < _b.x + _b.w && _b.x < _a.x + _a.w
        && _a.y < _b.y + _b.h && _b.y < _a.y + _a.h;
}

/// Every Hollow card and control, measured on the native canvas. Draw and
/// input share these layout functions, so a pass here means the plates the
/// player sees are the plates they can actually click.
function veil_test_layout_native() {
    // map: five real door cards, a ledger, and the claim button inside it
    var _map = veil_map_ui();
    var _ok = (array_length(_map.doors) == 5 && veil_test_rect_in(_map.ledger)
               && veil_test_rect_in(_map.claim));
    var _minw = 9999;
    for (var _i = 0; _i < array_length(_map.doors); _i++) {
        var _d = _map.doors[_i];
        if (!veil_test_rect_in(_d) || _d.w < 300) _ok = false;
        _minw = min(_minw, _d.w);
        if (_i > 0 && veil_test_overlap(_d, _map.doors[_i - 1])) _ok = false;
    }
    if (_map.claim.x < _map.ledger.x || _map.claim.x + _map.claim.w > _map.ledger.x + _map.ledger.w
        || _map.claim.y < _map.ledger.y || _map.claim.y + _map.claim.h > _map.ledger.y + _map.ledger.h) _ok = false;
    veil_test_note(_ok, "layout.veil.map", "5 doors min=" + string(_minw) + " + ledger");

    // garden: twelve beds, no shared hit box, controls on the bottom band
    var _g = veil_garden_ui();
    _ok = (array_length(_g.plots) == VEIL_GARDEN_PLOTS);
    for (var _i = 0; _i < array_length(_g.plots); _i++) {
        var _p = _g.plots[_i];
        if (!veil_test_rect_in(_p) || _p.w < 380) _ok = false;
        for (var _j = 0; _j < _i; _j++) if (veil_test_overlap(_p, _g.plots[_j])) _ok = false;
    }
    var _gacts = [_g.patient, _g.fed, _g.plant, _g.feedback];
    for (var _i = 0; _i < 3; _i++) array_push(_gacts, _g.seeds[_i]);
    for (var _i = 0; _i < array_length(_gacts); _i++) {
        if (!veil_test_rect_in(_gacts[_i])) _ok = false;
    }
    if (!veil_test_rect_in(_g.choose_card) || !veil_test_rect_in(_g.cleanse)
        || !veil_test_rect_in(_g.take)) _ok = false;
    veil_test_note(_ok, "layout.veil.garden", "12 beds + seed bank + blight modal");

    // cellar: eight jars, three mortar slots, ten bottle rows
    var _b = veil_bench_ui();
    _ok = (array_length(_b.reagents) == VEIL_REAGENTS
           && array_length(_b.slots) == 3 && array_length(_b.bottles) == VEIL_TINCTURES);
    for (var _i = 0; _i < array_length(_b.reagents); _i++) {
        if (!veil_test_rect_in(_b.reagents[_i])) _ok = false;
        for (var _j = 0; _j < _i; _j++) if (veil_test_overlap(_b.reagents[_i], _b.reagents[_j])) _ok = false;
    }
    for (var _i = 0; _i < array_length(_b.bottles); _i++) {
        if (!veil_test_rect_in(_b.bottles[_i])) _ok = false;
        if (_i > 0 && veil_test_overlap(_b.bottles[_i], _b.bottles[_i - 1])) _ok = false;
    }
    for (var _i = 0; _i < array_length(_b.heat); _i++) if (!veil_test_rect_in(_b.heat[_i])) _ok = false;
    if (!veil_test_rect_in(_b.brew)) _ok = false;
    veil_test_note(_ok, "layout.veil.cellar", "8 jars + 3 slots + 10 bottles");

    // hall: the widest row must end before the run panel begins
    _ok = true;
    var _h = veil_hall_ui();
    for (var _n = 3; _n <= 5; _n++) {
        var _gap = (_n >= 5) ? 40 : 60;
        var _last = 0;
        for (var _i = 0; _i < _n; _i++) {
            var _x = veil_hall_door_x(_i, _n);
            if (_x < VUI_MX || _x + 180 > _h.run.x) _ok = false;
            _last = max(_last, _x + 180);
        }
        if (_last > _h.run.x) _ok = false;
    }
    for (var _i = 0; _i < array_length(_h.doors); _i++) {
        if (!veil_test_rect_in(_h.doors[_i]) || !veil_test_rect_in(_h.peeks[_i])) _ok = false;
    }
    if (!veil_test_rect_in(_h.run) || !veil_test_rect_in(_h.nerve)
        || !veil_test_rect_in(_h.abandon)) _ok = false;
    veil_test_note(_ok, "layout.veil.hall", "2-5 doors clear of run panel at " + string(_h.run.x));

    // parlour / night: seat cushions do not collide, action bar is its own row
    _ok = true;
    for (var _n = 4; _n <= 6; _n++) {
        var _s = veil_seance_ui(_n);
        if (!veil_test_rect_in(_s.roster) || !veil_test_rect_in(_s.table)
            || !veil_test_rect_in(_s.testimony)) _ok = false;
        for (var _i = 0; _i < _n; _i++) {
            var _seat = _s.seats[_i];
            var _box = { x: _seat.x - 44, y: _seat.y - 90, w: 88, h: 140 };
            if (!veil_test_rect_in(_box)) _ok = false;
            if (_box.x < _s.table.x || _box.x + _box.w > _s.table.x + _s.table.w
                || _box.y < _s.table.y || _box.y + _box.h > _s.table.y + _s.table.h) _ok = false;
            for (var _j = 0; _j < _i; _j++) {
                var _ob = { x: _s.seats[_j].x - 44, y: _s.seats[_j].y - 90, w: 88, h: 140 };
                if (veil_test_overlap(_box, _ob)) _ok = false;
            }
        }
        for (var _i = 0; _i < _n; _i++) if (!veil_test_rect_in(_s.rows[_i])) _ok = false;
        if (!veil_test_rect_in(_s.next) || !veil_test_rect_in(_s.reveal)
            || !veil_test_rect_in(_s.listen)) _ok = false;
    }
    veil_test_note(_ok, "layout.veil.parlour", "4/5/6 seats inside table; action bar clear");

    // rites: four columns of touch-sized charm cards
    var _u = veil_upgrades_ui();
    _ok = (array_length(_u) == array_length(global.VEIL_UP));
    for (var _i = 0; _i < array_length(_u); _i++) {
        var _r = _u[_i];
        if (!veil_test_rect_in(_r) || _r.w < 400 || _r.h < 96) _ok = false;
        for (var _j = 0; _j < _i; _j++) if (veil_test_overlap(_r, _u[_j])) _ok = false;
    }
    veil_test_note(_ok, "layout.veil.rites", string(array_length(_u)) + " charm cards, four columns");

    // relics: forty cells and five set readouts
    var _rel = veil_relics_ui();
    _ok = (array_length(_rel.cells) == VEIL_RELICS && array_length(_rel.sets) == 5);
    for (var _i = 0; _i < array_length(_rel.cells); _i++) {
        var _r = _rel.cells[_i];
        if (!veil_test_rect_in(_r) || _r.w < 200) _ok = false;
        for (var _j = 0; _j < _i; _j++) if (veil_test_overlap(_r, _rel.cells[_j])) _ok = false;
    }
    for (var _i = 0; _i < 5; _i++) if (!veil_test_rect_in(_rel.sets[_i])) _ok = false;
    veil_test_note(_ok, "layout.veil.relics", "40 cells + 5 sets inside 1920x1080");

    // night, omens and the native Hollow lesson card
    _ok = veil_test_rect_in(veil_night_ui().card) && veil_test_rect_in(veil_night_ui().begin)
          && veil_test_rect_in(veil_omen_ui().card)
          && veil_test_rect_in(veil_omen_ui().a) && veil_test_rect_in(veil_omen_ui().b);
    veil_test_note(_ok, "layout.veil.night", "night intro + omen card");

    var _gu = guide_dark_ui();
    _ok = veil_test_rect_in(_gu.card) && veil_test_rect_in(_gu.close);
    for (var _i = 0; _i < array_length(_gu.buttons); _i++) {
        if (!veil_test_rect_in(_gu.buttons[_i])) _ok = false;
        if (_gu.buttons[_i].y + _gu.buttons[_i].h > _gu.card.y + _gu.card.h) _ok = false;
    }
    veil_test_note(_ok, "layout.veil.lesson", "native Hollow lesson " + string(_gu.card.w) + "x" + string(_gu.card.h));

    // shell controls
    var _n = veil_nav_rects();
    var _acts = [veil_wake_rect(), _n.map, _n.rites, _n.relics, _n.night];
    _ok = true;
    for (var _i = 0; _i < array_length(_acts); _i++) if (!veil_test_rect_in(_acts[_i])) _ok = false;
    if (_n.map.x + _n.map.w > _n.rites.x || _n.rites.x + _n.rites.w > _n.relics.x
        || _n.relics.x + _n.relics.w > _n.night.x) _ok = false;
    veil_test_note(_ok, "layout.veil.shell", "wake + four nav controls inside canvas");

    // native reading widths: a label that cannot fit its plate is clipped text
    var _w1 = dui_vtext_w("THE TINCTURE CELLAR", global.fnt_big);
    var _w2 = dui_vtext_w("SOMETIMES THEY BITE.", global.fnt_small);
    var _w3 = dui_vtext_w("CLEANSE IT FOR 15 EMBERS AND TAKE HALF.", global.fnt_small);
    var _w4 = dui_vtext_w("THREE FLOORS. FIVE DOORS. NO MERCY.", global.fnt_small);
    _ok = (_w1 < 780 && _w2 < 360 && _w3 < 640 && _w4 < 528);
    veil_test_note(_ok, "layout.veil.text",
                   "title=" + string(_w1) + " note=" + string(_w2)
                   + " modal=" + string(_w3) + " hall=" + string(_w4));
}

/// Location mastery contract. Every door must count the activity its effect
/// reads, and the map's rank must come from that same value. This is the
/// runtime guard that would have failed the old Hall/Cellar/Ninth mapping.
function veil_test_mastery_live() {
    var _o = global.G.occult;
    var _s0 = json_parse(json_stringify(_o.stats));
    var _nb0 = _o.night_best;
    var _up0 = json_parse(json_stringify(_o.up));
    var _hall0 = json_parse(json_stringify(_o.hall));

    var _names = ["solves", "harvests", "halls", "brews", "night_best"];
    var _map_ok = true;
    var _detail = "";
    for (var _loc = 1; _loc <= VEIL_LOC_COUNT; _loc++) {
        _o.stats.solves = 0;
        _o.stats.harvests = 0;
        _o.stats.halls = 0;
        _o.stats.brews = 0;
        _o.night_best = 0;
        switch (_loc) {
            case 1: _o.stats.solves = 3; break;
            case 2: _o.stats.harvests = 3; break;
            case 3: _o.stats.halls = 3; break;
            case 4: _o.stats.brews = 3; break;
            case 5: _o.night_best = 3; break;
        }
        if (veil_mastery_value(_loc) != 3 || veil_mastery_rank(_loc) != 2) _map_ok = false;
        for (var _other = 1; _other <= VEIL_LOC_COUNT; _other++) {
            if (_other != _loc && veil_mastery_value(_other) != 0) _map_ok = false;
        }
        _detail += "L" + string(_loc) + "=" + _names[_loc - 1] + " ";
    }

    _o.stats.solves = 0;
    _o.stats.harvests = 0;
    _o.stats.halls = 0;
    _o.stats.brews = 0;
    _o.night_best = 3;
    var _best5 = (veil_mastery_best() == 2);
    veil_test_note(_map_ok && _best5, "veil.mastery.map",
                   _detail + "best includes Ninth Table=" + string(_best5));

    // The effects must move with the same activity the map counts. Rank 2 is
    // three of that activity: Hall nerve +2, Cellar find +2%, and Ninth Table
    // depth 10 raises the ember multiplier.
    _o.stats.solves = 0;
    _o.stats.harvests = 0;
    _o.stats.halls = 0;
    _o.stats.brews = 0;
    _o.night_best = 0;
    _o.hall.mood = 0;
    var _nerve0 = veil_hall_nerve();
    _o.stats.halls = 3;
    var _nerve1 = veil_hall_nerve();
    _o.stats.halls = 0;
    var _find0 = veil_relic_chance();
    _o.stats.brews = 3;
    var _find1 = veil_relic_chance();
    _o.stats.brews = 0;
    var _ember0 = veil_ember_mult();
    _o.night_best = 10;
    var _ember1 = veil_ember_mult();
    var _eff_ok = (_nerve1 - _nerve0 == 2)
               && (abs((_find1 - _find0) - 0.02) < 0.0001)
               && (_ember1 > _ember0 + 0.0001);
    veil_test_note(_eff_ok, "veil.mastery.effect",
                   "hall +" + string(_nerve1 - _nerve0)
                   + " cellar +" + string(_find1 - _find0)
                   + " night ember +" + string(_ember1 - _ember0));

    _o.stats = _s0;
    _o.night_best = _nb0;
    _o.up = _up0;
    _o.hall = _hall0;
}

/// Run 1: exercise the rules and visit every screen. Run 2: prove the save
/// survived, then wake into the cafe and show the door.
function veil_test_assert() {
    var _o = global.G.occult;

    if (environment_get_variable("CLICKY_VEILTEST") == "2") {
        veil_test_note(_o.found, "save.found", string(_o.found));
        veil_test_note(_o.in_hollow, "save.in_hollow", string(_o.in_hollow));
        veil_test_note(veil_relic_count(0) >= 1, "save.relic", string(veil_relic_count(0)));
        veil_test_note(veil_lvl("keen") >= 1, "save.upgrade", string(veil_lvl("keen")));
        veil_test_note(_o.stats.harvests >= 1, "save.harvest", string(_o.stats.harvests));
        veil_test_note(_o.stats.solves >= 1, "save.solve", string(_o.stats.solves));
        veil_test_note(_o.closings >= 1, "save.closing", string(_o.closings));
        veil_test_note(_o.night.depth >= 3, "save.night", string(_o.night.depth));
        veil_night_give_up();
        veil_wake();
        // idle earnings during phase 1 can cross a room threshold, so walk home
        // deliberately: this shot is meant to show the cafe wall and its door
        zone_enter(0);
        return;
    }

    // Run 3: a cafe save written before the Hollow existed. The layer must be
    // absent but findable, with default state only -- nothing invented.
    if (environment_get_variable("CLICKY_VEILTEST") == "3") {
        veil_test_note(!_o.found && !_o.in_hollow, "compat.woken", "not found");
        veil_test_note(veil_eligible(), "compat.eligible", "late cafe");
        veil_test_note(global.G.tiers[0] >= 15, "compat.cafe", "tiers=" + string(global.G.tiers[0]));
        veil_test_note(array_length(_o.garden.plots) == VEIL_GARDEN_PLOTS, "compat.defaults", "beds");
        veil_test_note(_o.embers == 0 && _o.closings == 0, "compat.clean", "no invented currency");
        return;
    }

    // Make the isolated fixture a lived-in late game, then prove the gate.
    if (global.G.stats.clicks < 60) global.G.stats.clicks = 60;
    global.G.tiers[0] = max(15, global.G.tiers[0]);
    global.G.tiers[1] = max(8, global.G.tiers[1]);
    global.G.tiers[2] = max(3, global.G.tiers[2]);
    global.G.fish = max(120000, global.G.fish);
    global.G.earned.moon = max(1, global.G.earned.moon);
    global.G.festival.ranks[0] = max(1, global.G.festival.ranks[0]);
    global.G.lifetime_earned = max(2000, global.G.lifetime_earned);
    veil_test_note(veil_eligible(), "gate.eligible", "moon+festival");
    veil_test_note(veil_discover(), "gate.discover", "knocks");
    veil_test_note(_o.found && _o.in_hollow, "gate.state", "found+inside");
    veil_test_note(instance_exists(obj_veil), "shell.created", "obj_veil");

    // The parlour earns the first closing, so it cannot be gated behind one:
    // a freshly opened Hollow has zero closings and must still have a way in.
    veil_test_note(veil_loc_open(1), "gate.parlour", "open at 0 closings");
    veil_test_note(!veil_loc_open(2) && !veil_loc_open(3) && !veil_loc_open(4)
                  && !veil_loc_open(5), "gate.later", "later doors sealed");

    // Every case at every tier must have one solution and truthful clues.
    var _bad_cases = 0;
    var _bad_truth = 0;
    var _min_clues = 99;
    for (var _tier = 0; _tier < 3; _tier++) {
        for (var _seed = 1; _seed <= 12; _seed++) {
            var _case = veil_case_build(_seed, _tier);
            if (_case.solutions != 1) _bad_cases += 1;
            if (!veil_clue_holds(_case, _case.truth)) _bad_truth += 1;
            _min_clues = min(_min_clues, array_length(_case.clues));
            for (var _c = 0; _c < array_length(_case.clues); _c++) {
                if (veil_clue_text(_case.clues[_c], _case.n) == "") _bad_truth += 1;
            }
        }
    }
    veil_test_note(_bad_cases == 0, "cases.unique", "bad=" + string(_bad_cases));
    veil_test_note(_bad_truth == 0, "cases.truthful", "bad=" + string(_bad_truth));
    veil_test_note(_min_clues >= 3, "cases.clues", "min=" + string(_min_clues));

    // A wrong arrangement must be rejected, the real one accepted.
    var _case = veil_case_build(7, 1);
    var _wrong = array_create(_case.n, -1);
    for (var _i = 0; _i < _case.n; _i++) _wrong[_i] = _case.truth[_i];
    var _tmp = _wrong[0]; _wrong[0] = _wrong[1]; _wrong[1] = _tmp;
    veil_test_note(veil_case_violation(_case, _wrong) >= 0, "case.rejects", "wrong seats");
    veil_test_note(veil_case_violation(_case, _case.truth) < 0, "case.accepts", "true seats");

    // Geometry: every shared hit test must stay on the native canvas.
    var _geo = true;
    for (var _n = 4; _n <= 6; _n++) {
        for (var _i = 0; _i < _n; _i++) {
            var _sx = veil_seat_x(_i, _n);
            var _sy = veil_seat_y(_i, _n);
            if (_sx < 460 || _sx > 1340 || _sy < 176 || _sy > 856) _geo = false;
        }
    }
    for (var _i = 0; _i < 5; _i++) {
        if (veil_map_door_x(_i) < 0 || veil_map_door_x(_i) + 326 > UI_W) _geo = false;
    }
    // The hall's run panel begins at 1236; a door must never slide under it.
    for (var _n = 2; _n <= 5; _n++) {
        for (var _i = 0; _i < _n; _i++) {
            var _hx = veil_hall_door_x(_i, _n);
            if (_hx < 0 || _hx + 180 > 1236) _geo = false;
        }
    }
    veil_test_note(_geo, "layout.bounds", "native seats+map+doors");
    veil_test_layout_native();

    // Hall outcomes must always be defined and tagged.
    var _bad_out = 0;
    for (var _seed = 1; _seed <= 40; _seed++) {
        for (var _floor = 0; _floor < 3; _floor++) {
            for (var _door = 0; _door < 5; _door++) {
                var _out = veil_hall_outcome(_seed, _floor, _door);
                if (_out.label == "" || _out.tag < 0 || _out.tag > 2) _bad_out += 1;
            }
        }
    }
    veil_test_note(_bad_out == 0, "hall.outcomes", "bad=" + string(_bad_out));

    // Pay a case and prove the reward and stats move.
    var _before_e = _o.embers;
    var _before_solves = _o.stats.solves;
    _o.seance.seed = _case.seed;
    _o.seance.tier = _case.tier;
    _o.seance.placed = array_create(6, -1);
    for (var _i = 0; _i < _case.n; _i++) _o.seance.placed[_i] = _case.truth[_i];
    veil_seance_pay(_o.seance, _case, true);
    veil_test_note(_o.embers > _before_e, "seance.pays", "embers=" + fmt_number(_o.embers));
    veil_test_note(_o.stats.solves == _before_solves + 1, "seance.stats", "solves");

    // Garden: plant, age the bed, harvest.
    veil_bench_starter();
    var _g = _o.garden;
    _g.seed = 0;
    _g.mode = 0;
    _g.sel = 0;
    veil_garden_plant(0);
    var _planted = _g.plots[0].seed;
    _g.plots[0].planted = date_current_datetime() - (_g.plots[0].need + 60) / 86400;
    var _h_before = _o.stats.harvests;
    veil_garden_harvest(0, false);
    veil_test_note(_planted == 0 && _g.plots[0].seed < 0, "garden.cycle", "planted+harvested");
    veil_test_note(_o.stats.harvests == _h_before + 1, "garden.stats", "harvests");

    // Bench: brew the first recipe from its own reagents.
    var _rec = veil_tinctures()[0];
    for (var _i = 0; _i < 3; _i++) {
        _g.plots[_i].seed = -1;
        _o.bench.slots[_i] = -1;
        _o.bench.reagents[_rec.r[_i]] += 2;
        _o.bench.slots[_i] = _rec.r[_i];
    }
    _o.bench.heat = _rec.heat;
    veil_bench_brew();
    veil_test_note(_o.bench.tinctures[0] == 1, "bench.brew", "clear sight");
    veil_test_note(veil_tincture_use(0), "bench.use", "reveal");
    veil_test_note(_o.bench.tinctures[0] == 0, "bench.spend", "used once");

    // Hall run: start, take a door, walk on.
    veil_hall_start();
    var _h = _o.hall;
    veil_hall_resolve(0);
    veil_test_note(_h.taken == 0 && _h.active, "hall.door", "resolved");
    veil_hall_continue();
    veil_test_note(_h.floor >= 1, "hall.floor", "floor=" + string(_h.floor));

    // Procedural nights: every run draws one of six modifiers, and the floor
    // count is the modifier's, not a hard-coded 3. The long corridor is played
    // to its end here so a fifth floor is a real run, not a label.
    var _hall_save = json_parse(json_stringify(_o.hall));
    var _blood0 = _o.blood;
    var _halls0 = _o.stats.halls;
    var _floors0 = _o.stats.floors;
    var _best0 = _o.stats.best_hall;
    var _mods = veil_hall_mods();
    veil_hall_start();
    _h = _o.hall;
    _h.mood = 0;
    var _quiet_doors = veil_hall_door_count();
    _h.mood = 1;
    var _hungry_doors = veil_hall_door_count();
    _h.mood = 5;
    var _unblinking_doors = veil_hall_door_count();
    var _unblinking_peek = veil_hall_mod().peek;
    _h.mood = 3;
    _h.floors = veil_hall_floors();
    _h.nerve = 40;
    veil_hall_reset_doors(_h);
    var _mod_ok = array_length(_mods) == 6
               && _quiet_doors == max(2, veil_hall_doors() - 1)
               && _hungry_doors == min(5, veil_hall_doors() + 1)
               && _unblinking_doors == min(5, veil_hall_doors() + 2)
               && _unblinking_peek == 0
               && _h.floors == 5 && veil_hall_door_count() == min(5, veil_hall_doors());
    veil_test_note(_mod_ok, "hall.night.mod",
                   "mods=6 quiet=" + string(_quiet_doors) + " hungry="
                   + string(_hungry_doors) + " unblinking="
                   + string(_unblinking_doors) + " floors=" + string(_h.floors));
    // The picker may not hand the player the same night twice in a row.
    var _repeat = 0;
    var _halls_before = _o.stats.halls;
    _o.stats.halls = 1;
    for (var _rp = 0; _rp < 200; _rp++) {
        _o.hall.last_mod = _rp mod 6;
        if (veil_hall_pick_mod() == _o.hall.last_mod) _repeat += 1;
    }
    _o.stats.halls = _halls_before;
    veil_test_note(_repeat == 0, "hall.night.repeat",
                   string(_repeat) + "/200 immediate repeats");
    for (var _hf = 0; _hf < 5; _hf++) {
        _h.nerve = 40;
        veil_hall_resolve(0);
        if (!_h.active) break;
        veil_hall_continue();
    }
    veil_test_note(!_h.active && _h.cleared == 1 && _h.floor == 5
                   && _o.stats.best_hall >= 5 && _o.blood == _blood0 + 1
                   && _o.stats.halls == _halls0 + 1,
                   "hall.night.five", "floor=" + string(_h.floor)
                   + " best=" + string(_o.stats.best_hall));
    _o.hall = json_parse(json_stringify(_hall_save));
    _o.blood = _blood0;
    _o.stats.halls = _halls0;
    _o.stats.floors = _floors0;
    _o.stats.best_hall = _best0;

    veil_test_mastery_live();

    // Upgrades and relics.
    _o.embers += 10000;
    veil_test_note(veil_up_buy("keen"), "rites.buy", "keen");
    veil_test_note(veil_lvl("keen") == 1, "rites.level", "1");
    veil_test_note(veil_relic_grant(0) == 0, "relic.grant", "wick");
    veil_test_note(veil_relic_count(0) == 1, "relic.count", "1");
    veil_test_note(veil_throne_toggle(0), "relic.throne", "enthroned");

    // Omen choice consumes the card.
    _o.omen.id = 0;
    var _e_before = _o.embers;
    veil_omen_apply(1);
    veil_test_note(_o.omen.id < 0 && _o.embers > _e_before, "omen.choice", "bolted");

    // Check each threshold and claim every closing in order. Activity totals are
    // supplied here; the activity actions above are tested separately.
    var _gate_ok = true;
    for (var _loc = 2; _loc <= VEIL_LOC_COUNT; _loc++) {
        var _need = veil_loc_need(_loc);
        _o.closings = _need - 1;
        if (veil_loc_open(_loc)) _gate_ok = false;
        _o.closings = _need;
        if (!veil_loc_open(_loc)) _gate_ok = false;
    }
    veil_test_note(_gate_ok, "gate.thresholds", "all later doors");
    _o.closings = 0;
    var _closing_ok = true;
    for (var _c = 0; _c < VEIL_CLOSINGS; _c++) {
        var _def = global.VEIL_CLOSING[_c];
        switch (_def.key) {
            case "solves": _closing_ok = _closing_ok && veil_loc_open(1); break;
            case "halls":
            case "cleansed": _closing_ok = _closing_ok && veil_loc_open(3); break;
            case "harvests": _closing_ok = _closing_ok && veil_loc_open(2); break;
            case "brews": _closing_ok = _closing_ok && veil_loc_open(4); break;
            case "night":
                _closing_ok = _closing_ok && veil_loc_open(5) && veil_night_start();
                for (var _d = 0; _d < 3; _d++) {
                    _o.night.solved = true;
                    if (!veil_night_advance()) _closing_ok = false;
                }
                break;
        }
        if (_def.key != "mastery" && _def.key != "night") _o.stats[$ _def.key] = _def.target;
        if (!veil_closing_claim() || _o.closings != _c + 1) _closing_ok = false;
    }
    veil_test_note(_closing_ok && _o.night_best >= 4, "closing.sequence",
                   "13 claims with available activities and night depth 4");

    // The screenshot pass shows the widest hall; five doors must still fit.
    _o.up[$ "doors"] = 2;
    veil_test_note(veil_loc_open(5), "descend.last", "ninth open");
    veil_night_start();
    veil_test_note(_o.night.active && _o.night.depth == 1, "night.start", "depth 1");
    _o.night.solved = true;
    veil_night_advance();
    veil_test_note(_o.night.depth == 2, "night.advance", "depth 2");
    _o.night.solved = true;
    veil_night_advance();
    veil_test_note(_o.night.depth == 3 && _o.blood > 0, "night.presence", "blood");        veil_test_note(_o.closings == 13 && veil_closing_current() < 0, "closing.state", "13/13");
        _o.in_hollow = true;
        _o.found = true;
        save_write();

    // Keep the sequence's own state readable by the screenshots.
    with (obj_veil) {
        intro = 0;
        t = 99;
    }
}

function veil_test_shots() {
    if (variable_global_exists("vt_done") && global.vt_done) return;
    if (environment_get_variable("CLICKY_VEILTEST") == "3") {
        if (!variable_global_exists("vt_done")) {
            global.vt_done = true;
        }
        return;
    }
    if (environment_get_variable("CLICKY_VEILTEST") == "2") {
        // the offline card would cover the wall this shot exists to show
        with (obj_welcome) instance_destroy();
        global.vt_wait += 1;
        if (global.vt_wait >= 24 && !variable_global_exists("vt_done")) {
            screen_save("veil_13_cafe.png");
            global.vt_done = true;
        }
        return;
    }
    var _idx = global.vt_shot;
    if (_idx >= array_length(global.vt_shots)) {
        if (!variable_global_exists("vt_done")) {
            veil_test_ui_scale();
            global.vt_done = true;
            save_write();
        }
        return;
    }
    var _shot = global.vt_shots[_idx];
    // Every shot starts from a clean transient layer, then optionally sets up
    // the state it exists to show.
    with (obj_guide) { shown = -1; }
    global.G.occult.omen.id = -1;
    if (array_length(_shot) > 3) veil_test_prep(_shot[3]);
    with (obj_veil) {
        mode = _shot[0];
        loc = _shot[1];
        intro = 0;
    }
    global.vt_wait += 1;
    if (global.vt_wait < 14) return;
    // The last screen has now been drawn for 14 frames; record the runtime
    // scale verdict before its PNG write can dominate the runner's timeout.
    if (_idx == array_length(global.vt_shots) - 1) veil_test_ui_scale();
    screen_save(_shot[2] + ".png");
    global.vt_wait = 0;
    global.vt_shot += 1;
}

/// Called once per frame by obj_debug when the environment asks for a run.
function veil_test_tick() {
    if (!variable_global_exists("vt_stage")) veil_test_begin();
    if (global.vt_stage == 0) {
        veil_test_assert();
        global.vt_stage = 1;
        return;
    }
    if (global.vt_fail == 0) {
        veil_test_shots();
    } else {
        if (!variable_global_exists("vt_done")) {
            global.vt_done = true;
        }
    }
}

// ---------------------------------------------------------------- cafe systems
// The same isolated harness also covers the cafe-side additions: staff, the
// guide, room travel and the first-room-only entrance. Inert without
// CLICKY_CAFETEST, exactly like the Hollow run above.

function cafe_test_note(_ok, _name, _detail) {
    global.ct_pass += _ok ? 1 : 0;
    global.ct_fail += _ok ? 0 : 1;
    // One open/append/close per line. The suite is sometimes stopped by the
    // runner before its final frame; a long-lived handle can lose every line
    // and makes a killed run look like it never started. This also makes a
    // write after the run finishes harmless.
    if (variable_global_exists("ct_done") && global.ct_done) return;
    var _f = file_text_open_append("cafetest.txt");
    file_text_write_string(_f,
        (_ok ? "PASS " : "FAIL ") + _name + " | " + _detail + "\n");
    file_text_close(_f);
}

/// One shot, with the transient stickers out of the way: a screenshot should
/// show the screen being reviewed, not a badge that happens to be arriving.
function cafe_shot(_name) {
    // The harness switches sticker polling off, so the frame being saved is the
    // screen under review rather than a badge that happens to be arriving.
    with (obj_toast) instance_destroy();
    // Park the pointer below the shop and away from the cat so a stale hover
    // tooltip cannot leak into a screenshot; the pointer is not part of the UI.
    // hover_i is computed in the shop's Step, before this frame's Draw, so it
    // must be cleared here as well as moving the pointer for the next frame.
    window_mouse_set(270, 265);
    with (obj_shop) { hover_i = -1; hover_lock = -1; }
    screen_save(_name + ".png");
}

/// Fill the current beat's ask through the systems it names. This is test
/// harness code: it stands in for the player's taps and serves so the arc
/// state machine, bond award and keepsake can be checked in one boot.
function cafe_arc_satisfy(_cat) {
    var _g = arc_goal(_cat);
    if (!is_struct(_g)) return false;
    switch (_g.k) {
        case "taps":     global.G.stats.clicks += _g.n; break;
        case "buys":     global.G.stats.purchases += _g.n; break;
        case "sparkles": global.G.stats.sparkles += _g.n; break;
        case "crits":    global.G.stats.crits += _g.n; break;
        case "prestige": global.G.stats.prestiges += _g.n; break;
        case "service":  global.G.service.served[0] += _g.n; break;
        case "journal":  global.G.journal.stamps += _g.n; break;
        case "projects":
            var _need = _g.n;
            for (var _p = 0; _p < array_length(global.G.journal.projects) && _need > 0; _p++) {
                if (global.G.journal.projects[_p] == 0) {
                    global.G.journal.projects[_p] = 1;
                    _need -= 1;
                }
            }
            break;
        case "fest":
            if (array_length(global.G.festival.ranks) > 0)
                global.G.festival.ranks[0] += _g.n;
            break;
        case "hollow": global.G.occult.stats.solves += _g.n; break;
        case "night":  global.G.occult.night_best = max(global.G.occult.night_best, _g.n); break;
        case "room":   global.G.rooms.mastery[cat_home_zone(_cat)] += _g.n; break;
        case "staff_self":
            if (array_length(global.G.staff.slots) > 0) global.G.staff.slots[0] = _cat;
            break;
        default: return false;
    }
    return true;
}

function cafe_arc_finish(_cat, _side) {
    if (!arc_open(_cat)) return false;
    for (var _guard = 0; _guard < 12 && !arc_done(_cat); _guard++) {
        if (arc_step_index(_cat) == 2) {
            if (!arc_choose(_cat, _side)) return false;
        } else {
            if (!cafe_arc_satisfy(_cat)) return false;
            if (!arc_claim(_cat)) return false;
        }
    }
    return arc_done(_cat);
}

/// Fill a venue beat through the real metric the ask names. Test-harness code,
/// same contract as cafe_arc_satisfy: it stands in for a player's actions.
function cafe_venue_satisfy(_i) {
    var _g = venue_arc_goal(_i);
    if (!is_struct(_g)) return false;
    var _need = max(0, _g.n - venue_arc_progress(_i));
    var _idx = venue_arc_idx(_i);
    switch (_g.k) {
        case "room":     global.G.rooms.mastery[_idx] += _need; break;
        case "rank":     global.G.festival.ranks[_idx] = min(FESTIVAL_RANKS, global.G.festival.ranks[_idx] + _need); break;
        case "buys":     global.G.stats.purchases += _need; break;
        case "service":  global.G.service.served[0] += _need; break;
        case "journal":  global.G.journal.stamps += _need; break;
        case "crits":    global.G.stats.crits += _need; break;
        case "sparkles": global.G.stats.sparkles += _need; break;
        case "fest":     global.G.festival.ranks[0] += _need; break;
        case "hollow":   global.G.occult.stats.solves += _need; break;
        case "night":    global.G.occult.night_best = max(global.G.occult.night_best, _g.n); break;
        case "prestige": global.G.stats.prestiges += _need; break;
        default: return false;
    }
    return venue_arc_goal_ready(_i);
}

function cafe_venue_finish(_i, _side) {
    if (!venue_arc_open(_i)) return false;
    for (var _guard = 0; _guard < 10 && !venue_arc_done(_i); _guard++) {
        if (is_struct(venue_arc_choice(_i))) {
            if (!venue_arc_choose(_i, _side)) return false;
        } else {
            if (!cafe_venue_satisfy(_i)) return false;
            if (!venue_arc_claim(_i)) return false;
        }
    }
    return venue_arc_done(_i);
}

function cafe_test_begin() {
    var _f = file_text_open_write("cafetest.txt");
    file_text_close(_f);
    global.ct_stage = 0;
    global.ct_wait = 0;
    global.ct_pass = 0;
    global.ct_fail = 0;
    global.ct_done = false;
}

function cafe_test_tick() {
    if (!variable_global_exists("ct_stage")) cafe_test_begin();
    if (global.ct_done) return;

    if (global.ct_stage == 0) {
        var _g = global.G;
        var _o = _g.occult;

        // The real 1920x1080 path, not a configured number: this run boots
        // without a pinned window and asks the window manager.
        if (environment_get_variable("CLICKY_FULLSCREEN") == "1") {
            cafe_test_note(window_get_fullscreen()
                           && display_get_width() == 1920
                           && display_get_height() == 1080,
                           "display.fullscreen",
                           "fullscreen=" + string(window_get_fullscreen())
                           + " display=" + string(display_get_width()) + "x"
                           + string(display_get_height()) + " window="
                           + string(window_get_width()) + "x"
                           + string(window_get_height()));
        }

        // --- guide content
        var _pages = guide_pages();
        var _shape = array_length(_pages) >= 8;
        for (var _i = 0; _i < array_length(_pages); _i++) {
            if (_pages[_i].title == "" || array_length(_pages[_i].lines) < 1
                || array_length(_pages[_i].lines) > 5) _shape = false;
        }
        cafe_test_note(_shape, "guide.pages", string(array_length(_pages)) + " pages");

        var _clicks = _g.stats.clicks;
        _g.stats.clicks = 0;
        var _tip = guide_tip();
        cafe_test_note(is_struct(_tip) && _tip.page == 0, "guide.first", _tip.text);
        _g.stats.clicks = _clicks;

        // every manual page is reachable, and each section starts at a page
        var _secs = guide_sections();
        var _sec_ok = array_length(_secs) == 4;
        for (var _i = 0; _i < array_length(_secs); _i++) {
            if (_secs[_i].first < 0 || _secs[_i].first >= array_length(_pages)) _sec_ok = false;
            if (guide_section_of(_secs[_i].first) != _i) _sec_ok = false;
        }
        cafe_test_note(_sec_ok, "guide.sections", string(array_length(_pages)) + " pages");

        // no page may be wider than its column, or taller than its five lines
        draw_set_font(global.fnt_small);
        var _wide = 0;
        var _tallest = 0;
        var _tall_page = "";
        for (var _i = 0; _i < array_length(_pages); _i++) {
            var _ls = guide_lines(_pages[_i]);
            if (array_length(_ls) > _tallest) _tall_page = _pages[_i].title;
            _tallest = max(_tallest, array_length(_ls));
            for (var _l2 = 0; _l2 < array_length(_ls); _l2++) {
                _wide = max(_wide, string_width(_ls[_l2]));
            }
        }
        cafe_test_note(_wide <= 216 && _tallest <= 5, "guide.wrap",
                       "widest=" + string(_wide) + " lines=" + string(_tallest)
                       + " at " + _tall_page);

        // The pixel font renders a semicolon as a question mark. The copy must
        // use full stops so a lesson never reads like it is unsure of itself.
        var _punct_ok = true;
        var _punct_at = "";
        for (var _pi = 0; _pi < array_length(_pages); _pi++) {
            for (var _pl = 0; _pl < array_length(_pages[_pi].lines); _pl++) {
                if (string_pos(";", _pages[_pi].lines[_pl]) > 0) {
                    _punct_ok = false;
                    _punct_at = _pages[_pi].title;
                }
            }
        }
        cafe_test_note(_punct_ok, "guide.punctuation", "no semicolons at " + _punct_at);

        // --- guidance layer: a state-driven goal and one lesson per system
        var _defs = guide_lessons();
        var _page_count = array_length(_pages);
        var _defs_ok = array_length(_defs) >= 18;
        var _ids = [];
        for (var _di = 0; _di < array_length(_defs); _di++) {
            var _d = _defs[_di];
            if (_d.id == "" || array_contains(_ids, _d.id)) _defs_ok = false;
            array_push(_ids, _d.id);
            if (_d.title == "" || array_length(_d.pages) < 1
                || array_length(_d.pages) > 2) _defs_ok = false;
            for (var _dp = 0; _dp < array_length(_d.pages); _dp++) {
                if (_d.pages[_dp] < 0 || _d.pages[_dp] >= _page_count) _defs_ok = false;
            }
        }
        cafe_test_note(_defs_ok, "guide.lessons", string(array_length(_defs)) + " definitions");

        // Major systems get a two-page card; the one-page pointers are only
        // for systems whose whole rule fits on the manual page they open.
        var _paged_ok = true;
        var _want_pages = ["offline", "door", "parlour", "hall", "garden", "cellar",
                           "relics", "night", "staff", "festival", "layer0", "layer1",
                           "layer2", "layer3", "layer4", "era"];
        for (var _wp = 0; _wp < array_length(_want_pages); _wp++) {
            var _wd = guide_lesson(_want_pages[_wp]);
            if (!is_struct(_wd) || array_length(_wd.pages) != 2) _paged_ok = false;
        }
        cafe_test_note(_paged_ok, "guide.paged", string(array_length(_want_pages)) + " two-page cards");

        // LATER postpones, it does not mark a system seen: the same lesson is
        // still queued when the snooze expires and the manual remains readable.
        var _seen_before = _g.guide.seen;
        _g.guide.seen = "";
        var _allq = guide_lessons();
        for (var _qq = 0; _qq < array_length(_allq); _qq++) {
            if (_allq[_qq].id != "staff") guide_mark_quiet(_allq[_qq].id);
        }
        _g.lifetime_earned = global.CAT[5].at;
        var _skipped = guide_pending("staff");
        var _resumed = guide_pending("");
        cafe_test_note(_skipped != "staff" && _resumed == "staff"
                       && !guide_seen("staff"), "guide.later",
                       "skip=" + _skipped + " resume=" + _resumed);
        _g.guide.seen = _seen_before;

        // The goal must change with real state, not with a timer or a page.
        var _clicks0 = _g.stats.clicks;
        var _purch0 = _g.stats.purchases;
        var _fish0 = _g.fish;
        var _life0 = _g.lifetime_earned;
        var _run0 = _g.run_earned;
        var _found0 = _o.found;
        var _close0 = _o.closings;
        var _moon0 = _g.earned.moon;
        var _eras0 = _g.eras;
        var _bonds0 = _g.bonds;
        var _comp0 = _g.companion;
        // The goal chooser tests below describe the pre-MOON path. Hide the
        // Era chapter so its (correct) priority cannot mask those goals.
        _g.eras = era_defaults();
        _g.eras.sealed = ERA_COUNT;
        var _served0 = _g.service.served[0];
        var _off0 = global.offline_s;
        var _lay0 = [];
        var _earn0 = [];
        var _prog0 = [];
        for (var _lj = 0; _lj < LAYER_COUNT; _lj++) {
            array_push(_lay0, _g.layers[$ global.LAYER[_lj].key]);
            array_push(_earn0, _g.earned[$ global.LAYER[_lj].key]);
            array_push(_prog0, _g.prog[_lj]);
        }
        for (var _li2 = 0; _li2 < LAYER_COUNT; _li2++) {
            _g.layers[$ global.LAYER[_li2].key] = 0;
            _g.earned[$ global.LAYER[_li2].key] = 0;
            _g.prog[_li2] = 0;
        }
        _g.stats.clicks = 0;
        _g.stats.purchases = 0;
        _g.fish = 0;
        _g.lifetime_earned = 0;
        _g.run_earned = 0;
        _g.service.served[0] = 0;
        _o.found = false;
        _o.closings = 0;
        var _goal_tap = objective_goal();
        cafe_test_note(_goal_tap.short == "TAP THE CAT", "guide.goal.tap", _goal_tap.short);

        _g.stats.clicks = 30;
        _g.fish = 5;
        var _goal_buy = objective_goal();
        cafe_test_note(string_copy(_goal_buy.short, 1, 3) == "BUY",
                       "guide.goal.buy", _goal_buy.short);

        _g.stats.purchases = 10;
        _g.run_earned = global.LAYER[0].need * up_need_mult(0) + 1000000;
        var _goal_reset = objective_goal();
        cafe_test_note(string_pos("RESET FOR YARN", _goal_reset.short) > 0,
                       "guide.goal.reset", _goal_reset.short);

        _g.run_earned = 0;
        _o.found = true;
        _o.closings = 0;
        var _goal_hollow = objective_goal();
        cafe_test_note(string_pos("CLOSING 1", _goal_hollow.short) > 0,
                       "guide.goal.hollow", _goal_hollow.short);
        cafe_test_note(_goal_hollow.page >= 0 && _goal_hollow.page < _page_count
                       && _goal_hollow.bar >= 0 && _goal_hollow.bar <= 1
                       && _goal_hollow.why != "" && _goal_hollow.short != "",
                       "guide.goal.shape", "page=" + string(_goal_hollow.page));

        // The strip has two lines of room and a help target on its right. Every
        // state-shaped goal must fit there without an ellipsis.
        draw_set_font(global.fnt_small);
        var _fits_ok = true;
        var _fit_at = "";
        var _goals_fit = [_goal_tap, _goal_buy, _goal_reset, _goal_hollow];
        for (var _gf = 0; _gf < array_length(_goals_fit); _gf++) {
            var _gg = _goals_fit[_gf];
            var _gl = guide_wrap_px(_gg.why, 600);
            if (dui_text_w(_gg.short, global.fnt_small) > 480 || array_length(_gl) > 2) {
                _fits_ok = false;
                _fit_at = _gg.short;
            }
            for (var _gln = 0; _gln < array_length(_gl); _gln++) {
                if (string_width(_gl[_gln]) * UI_S > 600) {
                    _fits_ok = false;
                    _fit_at = _gg.short;
                }
            }
        }
        cafe_test_note(_fits_ok, "guide.objective.fit", "two native lines, no clip at " + _fit_at);

        // ---- Cafe Eras: a post-MOON chapter with three real gates.
        _g.eras = era_defaults();
        _g.earned.moon = 1;
        var _era_goal0 = objective_goal();
        cafe_test_note(_era_goal0.short == "CHOOSE A HOUSE RULE",
                       "era.goal.rule", _era_goal0.short);
        cafe_test_note(era_choose_rule(0), "era.rule.choose", "HUSTLE");
        cafe_test_note(abs(era_rate_mult() - 0.80) < 0.001
                       && abs(era_tap_mult() - 2.00) < 0.001,
                       "era.rule.effect", "rate 0.80, tap 2.00");

        // Mark the three deeds done by moving the era baseline, not by
        // inventing a second progress store. This is the same path the game
        // uses after a real reset or service.
        var _snap = era_snapshot();
        _g.eras.base.resets = _snap.resets - 20;
        _g.eras.base.taps = _snap.taps - 800;
        _g.eras.base.served = _snap.served - 12;
        cafe_test_note(era_deeds_done(0) == 3 && era_ready(),
                       "era.deeds", string(era_deed_value(0, 0)) + "/20 "
                       + string(era_deed_value(0, 1)) + "/800 "
                       + string(era_deed_value(0, 2)) + "/12");
        var _era_goal1 = objective_goal();
        cafe_test_note(_era_goal1.short == "SEAL ERA 1", "era.goal.seal", _era_goal1.short);
        var _era_perk_before = era_perk_rate();
        var _sealed_ok = era_seal();
        cafe_test_note(_sealed_ok && _g.eras.sealed == 1 && _g.eras.index == 1
                       && _g.eras.rule == -1 && era_featured_room() == 1
                       && era_perk_rate() > _era_perk_before,
                       "era.seal", "sealed=1, next room=Cat Garden, perk live");
        cafe_test_note(array_length(album_nav_labels()) == 6
                       && album_nav_labels()[5] == "ERAS",
                       "era.tab", "six journal tabs");
        cafe_test_note(!era_ready(), "era.seal.gate", "deeds reset for era 2");

        // ---- Room mastery: taps in the featured room count double and one
        // level is exactly one percent of permanent output.
        var _rooms0 = _g.rooms;
        _g.rooms = room_defaults();
        _g.eras = era_defaults();
        _g.earned.moon = 1;
        _g.world.zone = 0;
        room_tap_add(0);
        room_tap_add(0);
        var _double_ok = _g.rooms.mastery[0] == 4;
        _g.rooms.mastery[0] = 150;
        var _base_mult = room_mastery_mult();
        _g.rooms.mastery[0] = 500;
        cafe_test_note(_double_ok && room_mastery_level(0) == 2
                       && room_mastery_mult() > _base_mult,
                       "room.mastery", "featured x2, level 2 at 500");

        // The room ladder is rules, not one multiplier: rank 1 is a combo,
        // rank 3 a treat interval, rank 6 auto-pets, rank 12 the fastest pet.
        _g.rooms = room_defaults();
        _g.rooms.mastery[0] = 150;
        var _rung1 = room_mastery_level(0) == 1 && room_combo_bonus(0) == 1
                   && room_next_rung(0).name == "CRIT +1%";
        _g.rooms.mastery[0] = 1200;
        var _rung3 = room_treat_every(0) == 12 && room_crit_bonus(0) > 0;
        _g.rooms.mastery[0] = 8200;
        var _rung6 = room_auto_pet_frames(0) == 240 && room_combo_window(0) > 900;
        _g.rooms.mastery[0] = 115000;
        var _rung12 = room_mastery_level(0) == ROOM_MASTERY_MAX
                   && room_auto_pet_frames(0) == 120
                   && room_mastery_progress(0) == 1;
        cafe_test_note(_rung1 && _rung3 && _rung6 && _rung12,
                       "room.ladder", "rules at ranks 1/3/6/12");

        // The getters above only say the table is shaped correctly. These
        // checks drive the real tap() loop: each advertised rung kind must
        // change play, not merely return a number from a getter.
        var _room_probed = [];
        if (instance_exists(obj_cat_big)) {
            var _cat_fx = instance_find(obj_cat_big, 0);
            var _fx_clicks = _g.stats.clicks;
            var _fx_crits = _g.stats.crits;
            var _fx_best = _g.stats.best_combo;
            var _fx_fish = _g.fish;
            var _fx_run = _g.run_earned;
            var _fx_life = _g.lifetime_earned;
            var _fx_treats = _g.journal.materials.treats;
            var _fx_zone = _g.world.zone;
            var _fx_up = _g.up;
            var _fx_bonds = _g.bonds;
            var _fx_comp = _g.companion;
            var _fx_mastery = _g.rooms.mastery[0];
            _g.up = {};
            _g.bonds = bond_defaults();
            _g.companion = 0;
            _g.world.zone = 0;

            // tap()'s first random(1) is its crit roll. Find a seed whose
            // first roll sits between the base 10% and the rank-7 12%, so the
            // same input is a miss at rank 0 and a crit at rank 7.
            var _crit_seed = -1;
            for (var _sd = 1; _sd <= 10000; _sd++) {
                random_set_seed(_sd);
                var _sr = random(1);
                if (_sr > 0.105 && _sr < 0.115) { _crit_seed = _sd; break; }
            }
            var _crit_ok = false;
            var _crit_detail = "no seed/cat";
            if (_crit_seed > 0) {
                _g.rooms.mastery[0] = 0;
                random_set_seed(_crit_seed);
                var _c0 = _g.stats.crits;
                _cat_fx.tap();
                var _base_crit = _g.stats.crits - _c0;
                _g.rooms.mastery[0] = 13500; // rank 7: both CRIT rungs live
                random_set_seed(_crit_seed);
                var _c1 = _g.stats.crits;
                _cat_fx.tap();
                var _rung_crit = _g.stats.crits - _c1;
                _crit_ok = _base_crit == 0 && _rung_crit == 1;
                _crit_detail = "base=" + string(_base_crit)
                             + " rank7=" + string(_rung_crit)
                             + " seed=" + string(_crit_seed);
            }
            cafe_test_note(_crit_ok, "room.crit.effect", _crit_detail);
            if (_crit_ok) array_push(_room_probed, "crit");

            // Rank 3 pays a treat on tap 12; rank 10 pays one on tap 8. The
            // universal tenth-tap treat is still there, so rank 3 has two
            // treats by tap 12 and rank 10 has one by tap 8.
            _g.stats.clicks = 0;
            _g.journal.materials.treats = 0;
            _g.rooms.mastery[0] = 1200;
            for (var _tt = 0; _tt < 12; _tt++) _cat_fx.tap();
            var _rank3_treats = _g.journal.materials.treats;
            _g.stats.clicks = 0;
            _g.journal.materials.treats = 0;
            _g.rooms.mastery[0] = 50000; // rank 10: TREAT EVERY 8
            for (var _tt2 = 0; _tt2 < 8; _tt2++) _cat_fx.tap();
            var _rank10_treats = _g.journal.materials.treats;
            cafe_test_note(_rank3_treats == 2 && _rank10_treats == 1,
                           "room.treat.effect",
                           "rank3@12=" + string(_rank3_treats)
                           + " rank10@8=" + string(_rank10_treats));
            if (_rank3_treats == 2 && _rank10_treats == 1) array_push(_room_probed, "treat");

            // Rank 1 adds a combo, rank 4 stretches every bond point, and rank
            // 5 widens the window a combo survives. Drive the real tap loop
            // and the real bond add, not their getters.
            _g.rooms.mastery[0] = 0;
            _cat_fx.combo = 0;
            _cat_fx.last_tap = -9999;
            _cat_fx.tap();
            _cat_fx.tap();
            var _combo0 = _cat_fx.combo;
            _g.rooms.mastery[0] = 150;
            _cat_fx.combo = 0;
            _cat_fx.last_tap = -9999;
            _cat_fx.tap();
            _cat_fx.tap();
            var _combo1 = _cat_fx.combo;
            var _combo_ok = (_combo0 == 1 && _combo1 == 2);
            cafe_test_note(_combo_ok, "room.combo.effect",
                           "base=" + string(_combo0) + " rank1=" + string(_combo1));
            if (_combo_ok) array_push(_room_probed, "combo");

            _g.rooms.mastery[0] = 0;
            _g.bonds = bond_defaults();
            cat_bond_add(0, 0);
            var _bond0 = _g.bonds[0];
            _g.bonds = bond_defaults();
            _g.rooms.mastery[0] = 2600;
            cat_bond_add(0, 0);
            var _bond4 = _g.bonds[0];
            var _bond_ok = (abs(_bond0 - 2) < 0.0001 && abs(_bond4 - 2.5) < 0.0001);
            cafe_test_note(_bond_ok, "room.bond.effect",
                           "base=" + string(_bond0) + " rank4=" + string(_bond4));
            if (_bond_ok) array_push(_room_probed, "bond");

            _g.rooms.mastery[0] = 0;
            _cat_fx.combo = 5;
            _cat_fx.last_tap = current_time - 930;
            _cat_fx.tap();
            var _grace0 = _cat_fx.combo;
            _g.rooms.mastery[0] = 8200;
            _cat_fx.combo = 5;
            _cat_fx.last_tap = current_time - 930;
            _cat_fx.tap();
            var _grace6 = _cat_fx.combo;
            var _grace_ok = (_grace0 == 0 && _grace6 > 5);
            cafe_test_note(_grace_ok, "room.grace.effect",
                           "base=" + string(_grace0) + " rank6=" + string(_grace6));
            if (_grace_ok) array_push(_room_probed, "grace");

            _g.stats.clicks = _fx_clicks;
            _g.stats.crits = _fx_crits;
            _g.stats.best_combo = _fx_best;
            _g.fish = _fx_fish;
            _g.run_earned = _fx_run;
            _g.lifetime_earned = _fx_life;
            _g.journal.materials.treats = _fx_treats;
            _g.world.zone = _fx_zone;
            _g.up = _fx_up;
            _g.bonds = _fx_bonds;
            _g.companion = _fx_comp;
            _g.rooms.mastery[0] = _fx_mastery;
            _cat_fx.combo = 0;
            _cat_fx.last_tap = -9999;
            _cat_fx.pet_t = 0;
            _cat_fx.squash = 1;
            _cat_fx.auto_t = 0;
            global.combo = 0;
            global.shake = 0;
            with (obj_floater) instance_destroy();
            with (obj_pop) instance_destroy();
            global.floaters = [];
        } else {
            cafe_test_note(false, "room.crit.effect", "no cat instance");
            cafe_test_note(false, "room.treat.effect", "no cat instance");
            cafe_test_note(false, "room.combo.effect", "no cat instance");
            cafe_test_note(false, "room.bond.effect", "no cat instance");
            cafe_test_note(false, "room.grace.effect", "no cat instance");
        }

        var _nr0 = room_next_rung(0);
        cafe_test_note(is_struct(_nr0) && variable_struct_exists(_nr0, "name")
                       && _nr0.name != "NEXT RUNG", "room.rung.shape",
                       is_struct(_nr0) ? _nr0.name : "undefined");

        // Every trait must mix real rules with percentage filler. This is the
        // structural guard behind the manual's "rules and small boosts" copy.
        var _rule_kinds = ["combo", "combo5", "grace", "endless", "critcombo",
                           "nerve", "peek", "offcap", "match", "frenzy",
                           "treat", "harvest"];
        var _mix_ok = true;
        var _mix_at = "each table has 4+ rule rungs";
        for (var _tr = 0; _tr < 6; _tr++) {
            var _tab = cat_bond_table(_tr);
            var _rules = 0;
            for (var _rk = 0; _rk < array_length(_tab); _rk++) {
                if (array_contains(_rule_kinds, _tab[_rk].k)) _rules += 1;
            }
            if (_rules < 4) {
                _mix_ok = false;
                _mix_at = "trait " + string(_tr) + " has " + string(_rules);
            }
        }
        cafe_test_note(_mix_ok, "cat.rung.mix", _mix_at);

        // Every advertised cat-rung kind must have a live consumer. Put each
        // trait at max bond and ask the same helper gameplay asks; a kind that
        // only exists in the table (the dead-rung class) cannot answer.
        var _cat_bonds0 = _g.bonds;
        var _cat_comp0 = _g.companion;
        var _cat_life0 = _g.lifetime_earned;
        _g.lifetime_earned = max(_g.lifetime_earned, global.CAT[album_count() - 1].at + 1);
        _g.bonds = bond_defaults();
        var _cat_kinds = [];
        var _cat_missing = "";
        for (var _ci = 0; _ci < 6; _ci++) {
            _g.companion = _ci;
            _g.bonds[_ci] = 999999;
            var _ct = cat_bond_table(staff_trait(_ci));
            for (var _cr = 0; _cr < array_length(_ct); _cr++) {
                var _ck = _ct[_cr].k;
                if (!array_contains(_cat_kinds, _ck)) array_push(_cat_kinds, _ck);
                if (!cat_bond_kind_live(_ck)) _cat_missing += _ck + " ";
            }
            _g.bonds[_ci] = 0;
        }
        cafe_test_note(_cat_missing == "", "cat.rung.contract",
                       string(array_length(_cat_kinds)) + " kinds"
                       + (_cat_missing == "" ? "" : " missing=" + _cat_missing));
        _g.bonds = _cat_bonds0;
        _g.companion = _cat_comp0;
        _g.lifetime_earned = _cat_life0;

        // Auto-pet is a room reward, not a tap: no mastery, no bond. Eight
        // pets still pay one treat, so the rung is not purely cosmetic.
        var _auto_ok = false;
        var _auto_detail = "no cat instance";
        if (instance_exists(obj_cat_big)) {
            var _cat_inst = instance_find(obj_cat_big, 0);
            _g.rooms.mastery[0] = 8200;
            _g.bonds[0] = 100;
            var _am = _g.rooms.mastery[0];
            var _ab = _g.bonds[0];
            var _at = _g.journal.materials.treats;
            _cat_inst.auto_gift = 0;
            for (var _ap = 0; _ap < 8; _ap++) _cat_inst.auto_pet();
            _auto_ok = _g.rooms.mastery[0] == _am && _g.bonds[0] == _ab
                    && _g.journal.materials.treats == _at + 1
                    && _cat_inst.pet_t > 0;
            _auto_detail = "mastery=" + string(_g.rooms.mastery[0])
                         + " bond=" + string(_g.bonds[0])
                         + " treats=" + string(_g.journal.materials.treats - _at);
        }
        cafe_test_note(_auto_ok, "room.autopet.noprogress", _auto_detail);
        if (_auto_ok) array_push(_room_probed, "auto");

        // The room ladder's contract: every kind room_rung() advertises has a
        // probe above that actually moved a real tap/bond/auto-pet. Add a new
        // kind without its effect test and this check names it.
        var _room_kinds = [];
        for (var _rr = 1; _rr <= ROOM_MASTERY_MAX; _rr++) {
            var _rk2 = room_rung(_rr);
            if (!array_contains(_room_kinds, _rk2.kind)) array_push(_room_kinds, _rk2.kind);
        }
        var _room_missing = "";
        for (var _ki = 0; _ki < array_length(_room_kinds); _ki++) {
            if (!array_contains(_room_probed, _room_kinds[_ki])) {
                _room_missing += _room_kinds[_ki] + " ";
            }
        }
        cafe_test_note(_room_missing == "", "room.rung.contract",
                       "probed=" + string(array_length(_room_probed)) + "/"
                       + string(array_length(_room_kinds))
                       + (_room_missing == "" ? "" : " missing=" + _room_missing));

        // Bond points feed the active cat, home-room taps double, and a rung
        // changes a real tap rule (SUNNY rank 2 is +1% tap, not a UI number).
        _g.rooms = room_defaults();
        _g.companion = 0;
        _g.bonds = bond_defaults();
        for (var _bt = 0; _bt < 10; _bt++) cat_bond_add(0, cat_home_zone(0));
        var _bond1 = cat_bond_rank(0) == 1 && cat_bond_active_sum("combo") == 1
                   && cat_bond_progress(0) >= 0 && cat_bond_progress(0) < 1;
        _g.bonds[0] = 60;
        var _bond2 = cat_bond_rank(0) == 2 && cat_tap_mult() > 1
                   && cat_next_trick(0) == "PET 5: +1 COMBO";
        cafe_test_note(_bond1 && _bond2, "cat.bond",
                       "home x2, rank1 combo, rank2 tap+1%");
        cafe_test_note(room_companion_set(0) && room_companion() == 0,
                       "cat.companion", "Mochi walks with you");
        _g.rooms = _rooms0;

        // Eras and room mastery survive a real save/load. A save written
        // before the chapter simply starts its first era from today.
        _g.eras = era_defaults();
        _g.eras.rule = 1;
        _g.eras.sealed = 2;
        _g.eras.index = 2;
        _g.eras.base.resets = 7;
        _g.rooms = room_defaults();
        _g.rooms.mastery[3] = 400;
        _g.bonds[0] = 321;
        _g.companion = 0;
        save_write();
        state_load();
        var _era_saved = _g.eras.rule == 1 && _g.eras.sealed == 2
                      && _g.eras.index == 2 && _g.eras.base.resets == 7
                      && _g.rooms.mastery[3] == 400
                      && _g.bonds[0] == 321 && _g.companion == 0;
        // Old saves kept bonds under rooms; the one-time move must preserve it.
        _g.bonds[0] = 0;
        bond_normalize({ rooms: { bonds: [7], companion: 0 } });
        var _bond_migrated = _g.bonds[0] == 7;
        variable_struct_remove(_g, "eras");
        era_normalize({});
        var _era_migrated = variable_struct_exists(_g, "eras")
                          && _g.eras.base.resets == era_snapshot().resets;
        cafe_test_note(_era_saved && _era_migrated && _bond_migrated, "era.save",
                       "sealed/index/rule/base + rooms/bonds persist, old save migrates");

        _g.eras = _eras0;
        _g.rooms = _rooms0;
        _g.earned.moon = _moon0;

        // every first-visit trigger uses the same live gates as the systems
        var _rel = true;
        _o.found = true;
        _o.closings = 0; _rel = _rel && guide_relevant("parlour") && !guide_relevant("hall");
        _o.closings = 1; _rel = _rel && guide_relevant("hall") && !guide_relevant("garden");
        _o.closings = 3; _rel = _rel && guide_relevant("garden") && !guide_relevant("cellar");
        _o.closings = 6; _rel = _rel && guide_relevant("cellar") && !guide_relevant("night");
        _o.closings = 12; _rel = _rel && guide_relevant("night");
        cafe_test_note(_rel, "guide.locations", "0/1/3/6/12 closings");

        _g.lifetime_earned = 0;
        _rel = !guide_relevant("staff");
        _g.lifetime_earned = global.CAT[5].at;
        _rel = _rel && guide_relevant("staff");
        _g.earned.moon = 0;
        _rel = _rel && !guide_relevant("festival") && !guide_relevant("era");
        _g.earned.moon = 1;
        _rel = _rel && guide_relevant("festival") && guide_relevant("era");

        // The two new long-tail systems explain themselves at their first real
        // moment: a first bond rung, and the first completed hall run.
        var _rooms_rel = _g.rooms;
        var _halls_rel = _o.stats.halls;
        _g.rooms = room_defaults();
        _g.bonds = bond_defaults();
        _g.bonds[0] = 0;
        _rel = _rel && !guide_relevant("bond");
        _g.bonds[0] = 20;
        _rel = _rel && guide_relevant("bond");
        _o.stats.halls = 0;
        _rel = _rel && !guide_relevant("nightfall");
        _o.stats.halls = 1;
        _rel = _rel && guide_relevant("nightfall");
        _g.rooms = _rooms_rel;
        _g.bonds = _bonds0;
        _g.companion = _comp0;
        _o.stats.halls = _halls_rel;
        cafe_test_note(_rel, "guide.ladders", "first bond + first night");

        global.offline_s = 0;
        _rel = _rel && !guide_relevant("offline");
        global.offline_s = 90;
        _rel = _rel && guide_relevant("offline");
        cafe_test_note(_rel, "guide.triggers", "staff/moon/offline");

        _g.run_earned = global.LAYER[0].need * up_need_mult(0) + 1000000;
        _g.earned.yarn = 0;
        _g.earned.stars = 0;
        _rel = guide_relevant("layer0") && !guide_relevant("layer1");
        _g.earned.stars = 1;
        _rel = _rel && !guide_relevant("layer0");   // old layer is not a frontier
        _g.prog[1] = global.LAYER[1].need * up_need_mult(1) + 1000;
        _g.earned.beans = 0;
        _rel = _rel && guide_relevant("layer1");
        cafe_test_note(_rel, "guide.reset.trigger", "frontier + catch-up");

        // A reset that happened before the card was met must still explain
        // itself once, then stop being queued when marked seen.
        var _seen_reset = _g.guide.seen;
        var _yarn_reset = _g.earned.yarn;
        _g.guide.seen = "";
        var _all_lessons = guide_lessons();
        for (var _lrq = 0; _lrq < array_length(_all_lessons); _lrq++) {
            if (_all_lessons[_lrq].id != "layer0") guide_mark_quiet(_all_lessons[_lrq].id);
        }
        _g.earned.yarn = 1;
        _g.earned.stars = 0;
        _g.run_earned = 0;
        var _caught = guide_relevant("layer0") && guide_pending("") == "layer0";
        guide_mark_quiet("layer0");
        _caught = _caught && guide_pending("") == "";
        cafe_test_note(_caught, "guide.reset.caughtup", "late reset explains once");
        _g.earned.yarn = _yarn_reset;
        _g.guide.seen = _seen_reset;

        // The manual copy that the cards point at must use the same gates.
        var _copy_ok = true;
        for (var _ci = 0; _ci < LAYER_COUNT; _ci++) {
            var _copy_page = _pages[21 + _ci];
            var _has_need = false;
            for (var _cl = 0; _cl < array_length(_copy_page.lines); _cl++) {
                if (string_pos(fmt_number(global.LAYER[_ci].need), _copy_page.lines[_cl]) > 0) {
                    _has_need = true;
                }
            }
            if (!_has_need) _copy_ok = false;
        }
        var _staff_1 = false;
        var _staff_2 = false;
        for (var _sl = 0; _sl < array_length(_pages[37].lines); _sl++) {
            if (string_pos(string(staff_slot_open_need(1)), _pages[37].lines[_sl]) > 0) {
                _staff_1 = true;
            }
            if (string_pos(string(staff_slot_open_need(2)), _pages[37].lines[_sl]) > 0) {
                _staff_2 = true;
            }
        }
        var _staff_copy = _staff_1 && _staff_2;
        cafe_test_note(_copy_ok && _staff_copy, "guide.copy", "layer needs + staff slots");

        // Put every test mutation back before the round trip, so the rest of
        // the suite is still testing a lived-in cafe, not this fixture.
        _g.stats.clicks = _clicks0;
        _g.stats.purchases = _purch0;
        _g.fish = _fish0;
        _g.lifetime_earned = _life0;
        _g.run_earned = _run0;
        _o.found = _found0;
        _o.closings = _close0;
        _g.service.served[0] = _served0;
        global.offline_s = _off0;
        for (var _lr = 0; _lr < LAYER_COUNT; _lr++) {
            _g.layers[$ global.LAYER[_lr].key] = _lay0[_lr];
            _g.earned[$ global.LAYER[_lr].key] = _earn0[_lr];
            _g.prog[_lr] = _prog0[_lr];
        }

        // Seen state survives a reload, which is what stops a card returning.
        guide_mark_quiet("offline");
        save_write();
        state_load();
        cafe_test_note(guide_seen("offline"), "guide.save", "seen persists");

        // every charm in a tab has its own icon: the old mapping fell back to
        // one yarn ball for every row, which read as an alignment bug
        var _icons_ok = true;
        for (var _li = 0; _li < LAYER_COUNT; _li++) {
            var _list = up_of_layer(_li);
            var _seen = [];
            for (var _ui = 0; _ui < array_length(_list); _ui++) {
                var _spr = up_icon(_list[_ui].id);
                if (!sprite_exists(_spr)) _icons_ok = false;
                if (array_contains(_seen, _spr)) _icons_ok = false;
                array_push(_seen, _spr);
            }
        }
        cafe_test_note(_icons_ok, "boost.icons", "distinct in every tab");

        // The yellow strip is a ratio of the item's own max, not its price or
        // a raw level. 7/20 must read 0.35, and a maxed charm must read 1.
        var _old_paw = up_level("paw");
        var _old_combo = up_level("combo");
        _g.up[$ "paw"] = 7;
        _g.up[$ "combo"] = up_max("combo");
        cafe_test_note(abs(up_progress("paw") - 0.35) < 0.0001
                       && abs(up_progress("combo") - 1) < 0.0001,
                       "boost.progress",
                       string(up_progress("paw")) + "/" + string(up_progress("combo")));
        _g.up[$ "paw"] = _old_paw;
        _g.up[$ "combo"] = _old_combo;

        // the two automation charms have real effects, not just a price
        _g.up[$ "stock"] = 1;
        _g.up[$ "glean"] = 1;
        _g.up[$ "tipjar"] = 2;
        cafe_test_note(up_autostock_sec() == 25, "auto.stock", string(up_autostock_sec()) + "s");
        cafe_test_note(up_autoglean() == 1, "auto.glean", "enabled");
        cafe_test_note(abs(up_tip_bonus() - 1.10) < 0.001, "auto.tips", string(up_tip_bonus()));

        // the self-stocker really buys, and never without its buffer
        var _fish_before = _g.fish;
        _g.fish = 1000000000;
        var _bought = up_autostock_try();
        var _bought_ok = _bought >= 0 && _g.fish < 1000000000;
        if (_bought_ok) _g.tiers[_bought] -= 1;
        _g.fish = 1000000000;
        _g.up[$ "stock"] = 0;
        cafe_test_note(up_autostock_try() < 0, "auto.nostock", "no charm, no purchase");
        _g.fish = _fish_before;
        cafe_test_note(_bought_ok, "auto.stockbuy", "tier=" + string(_bought));

        _g.up[$ "stock"] = 0;
        _g.up[$ "glean"] = 0;
        _g.up[$ "tipjar"] = 0;

        // --- staff: a rich album so all slots are open
        _g.lifetime_earned = max(_g.lifetime_earned, 8000000);
        cafe_test_note(staff_slot_open(2), "staff.slots", "album=" + string(album_unlocked_count()));

        var _base_click = econ_click_value();
        var _base_off = up_offline_rate();
        var _base_ember = veil_ember_mult();
        cafe_test_note(staff_set(0, 0, 0), "staff.assign", "sunny counter");
        cafe_test_note(staff_bonus(0) > 0, "staff.bonus", string(staff_bonus(0)));
        cafe_test_note(econ_click_value() > _base_click, "staff.tap", "tap pays more");

        cafe_test_note(staff_set(3, 0, 1), "staff.assign2", "night cellar");
        cafe_test_note(veil_ember_mult() > _base_ember, "staff.ember", "hollow pays more");

        cafe_test_note(staff_set(2, 0, 2), "staff.assign3", "cozy window");
        cafe_test_note(up_offline_rate() > _base_off, "staff.away", "away pays more");

        // One cat cannot hold two stations; moving it clears the old slot.
        cafe_test_note(staff_set(1, 0, 1), "staff.move", "night to oven");
        cafe_test_note(staff_assigned(1) == 3, "staff.unique", "cellar cleared");
        cafe_test_note(veil_ember_mult() <= _base_ember + 0.0001, "staff.move.effect", "ember back");

        // Slot two needs a bigger album; prove the gate with a small one.
        var _life = _g.lifetime_earned;
        _g.lifetime_earned = 0;
        cafe_test_note(!staff_set(0, 2, 2), "staff.locked", "needs 18 cats");
        _g.lifetime_earned = _life;

        // --- save round trip
        save_write();
        state_load();
        cafe_test_note(global.G.staff.slots[0] == 0, "staff.save", "counter cat kept");
        cafe_test_note(global.G.staff.slots[3] == 1, "staff.save2", "oven cat kept");

        // --- rooms and the cafe-only entrance
        cafe_test_note(zone_travel_available(), "rooms.available", "more than one room");
        cafe_test_note(zone_unlocked() >= 2, "rooms.unlocked", "zone=" + string(zone_unlocked()));

        _g.stats.clicks = max(60, _g.stats.clicks);
        _g.earned.moon = max(1, _g.earned.moon);
        _g.festival.ranks[0] = max(1, _g.festival.ranks[0]);
        _g.tiers[0] = max(15, _g.tiers[0]);
        _o.found = false;
        _o.knocks = 0;
        _o.in_hollow = false;

        // the entrance exists in the first room and in no other room at all
        var _only_cafe = true;
        for (var _z = 1; _z < ZONE_COUNT; _z++) {
            zone_enter(_z);
            if (veil_door_here()) _only_cafe = false;
        }
        cafe_test_note(_only_cafe, "door.hidden", "absent in 5 other rooms");

        // A discovered Hollow must not widen the gate either: the open
        // cupboard still exists in room 0 and in no other room.
        _o.found = true;
        var _only_cafe_open = true;
        for (var _z2 = 1; _z2 < ZONE_COUNT; _z2++) {
            zone_enter(_z2);
            if (veil_door_here()) _only_cafe_open = false;
        }
        cafe_test_note(_only_cafe_open, "door.open.hidden", "absent in 5 other rooms");
        _o.found = false;
        zone_enter(0);
        cafe_test_note(veil_door_here(), "door.here", "cozy corner");
        // The cat is in front of the pantry. Its 56px circle must win over the
        // cupboard's target, while the cupboard above it still receives clicks.
        cafe_test_note(veil_door_cat_claimed(150, 190)
                       && !veil_door_cat_claimed(150, 105),
                       "door.petpriority", "cat circle beats door rect");

        // six rooms, in order, with the last two far beyond the cloud cafe
        cafe_test_note(ZONE_COUNT == 6 && zone_name(4) == "TEA HOUSE"
                       && zone_name(5) == "STAR LIBRARY", "rooms.count", "six rooms");
        var _life_before = _g.lifetime_earned;
        _g.lifetime_earned = 30000000000;
        cafe_test_note(zone_unlocked() == 5, "rooms.unlock", "library at 25B");
        _g.lifetime_earned = _life_before;

        // nine guests, nine venues, and every venue rank must be solvable
        cafe_test_note(SERVICE_GUESTS == 9 && FESTIVAL_VENUES == 9,
                       "content.counts", "9 guests, 9 venues");
        var _gsl = service_guests();
        var _gates_ok = true;
        for (var _gi2 = 1; _gi2 < SERVICE_GUESTS; _gi2++) {
            if (_gsl[_gi2].album < _gsl[_gi2 - 1].album) _gates_ok = false;
            if (_gsl[_gi2].serves <= _gsl[_gi2 - 1].serves) _gates_ok = false;
        }
        cafe_test_note(_gates_ok, "guests.gates", "album and served rise in order");

        // every dish known, then search for a winning menu for each challenge
        for (var _gi3 = 0; _gi3 < SERVICE_GUESTS; _gi3++) {
            for (var _di2 = 0; _di2 < SERVICE_RECIPES; _di2++) {
                var _sl3 = _gi3 * SERVICE_RECIPES + _di2;
                global.G.service.known_base[_sl3] = (_gsl[_gi3].base + _di2) mod 3;
                global.G.service.known_topping[_sl3] = (_gsl[_gi3].topping + _di2 * 2) mod 3;
            }
        }
        var _unsolved = 0;
        var _unsolved_at = "";
        var _ranks_before = global.G.festival.ranks;
        for (var _vi = 0; _vi < FESTIVAL_VENUES; _vi++) {
            for (var _rk = 0; _rk < FESTIVAL_RANKS; _rk++) {
                global.G.festival.ranks[_vi] = _rk;
                var _found = false;
                for (var _a2 = 0; _a2 < SERVICE_GUESTS * SERVICE_RECIPES && !_found; _a2++) {
                    for (var _b2 = _a2 + 1; _b2 < SERVICE_GUESTS * SERVICE_RECIPES && !_found; _b2++) {
                        for (var _c2 = _b2 + 1; _c2 < SERVICE_GUESTS * SERVICE_RECIPES && !_found; _c2++) {
                            global.G.festival.menu = [_a2, _b2, _c2];
                            if (festival_evaluate(_vi).valid) _found = true;
                        }
                    }
                }
                if (!_found) {
                    _unsolved += 1;
                    _unsolved_at = festival_venues()[_vi].name + " R" + string(_rk + 1);
                }
            }
        }
        global.G.festival.ranks = _ranks_before;
        global.G.festival.menu = [-1, -1, -1];
        cafe_test_note(_unsolved == 0, "festival.solvable",
                       "unsolved=" + string(_unsolved) + " " + _unsolved_at);

        // the sticker sheet now needs pages, and every sticker has a real test
        cafe_test_note(ach_count() == 24, "stickers.count", string(ach_count()));
        // every sticker's condition is evaluated once, so a broken one is a
        // failure here rather than a silent crash on a player's machine
        var _ach_ok = true;
        for (var _ai = 0; _ai < ach_count(); _ai++) {
            var _met = ach_met(global.ACH[_ai].id);
            if (!is_bool(_met)) _ach_ok = false;
        }
        cafe_test_note(_ach_ok, "stickers.rules", "all conditions evaluate");
        var _paged = ceil(ach_count() / 12) > 1;
        cafe_test_note(_paged, "stickers.pages", string(ceil(ach_count() / 12)) + " sheets");

        // Screenshot set starts from a clean cafe: no tutorial pill, no toast,
        // and no new sticker arriving over the screen being photographed.
        global.tutorial = false;
        with (obj_tutorial) instance_destroy();
        with (obj_toast) instance_destroy();
        with (obj_welcome) instance_destroy();
        with (obj_game) ach_t = 999999;
        // Keep the screenshot set free of cards; the lesson stages below clear
        // this on purpose to photograph the real controller.
        var _quiet = guide_lessons();
        for (var _qi = 0; _qi < array_length(_quiet); _qi++) guide_mark_quiet(_quiet[_qi].id);
        with (obj_guide) { shown = -1; cooldown = 999; }
        _g.fish = max(_g.fish, 500000);
        global.ct_stage = 1;
        global.ct_wait = 0;
        return;
    }

    global.ct_wait += 1;
    if (global.ct_wait < 12) return;
    global.ct_wait = 0;
    var _stage = global.ct_stage;
    // Breadcrumb for the run: a stage that never writes its next marker is
    // where the screenshot pass stopped.
    if (!variable_global_exists("ct_trace_stage") || global.ct_trace_stage != _stage) {
        global.ct_trace_stage = _stage;
        var _ctf = file_text_open_append("cafetrace.txt");
        file_text_write_string(_ctf, string(_stage) + ";");
        file_text_close(_ctf);
    }

    // One stage sets a screen up, the next one photographs it. Saving on the
    // same frame as the setup captures the previous frame instead.
    if (_stage == 1) {
        // A small enough cafe to actually stay in the first room, and a
        // deterministic live goal for the strip: no reset and no Hollow yet.
        var _g1 = global.G;
        _g1.lifetime_earned = 0;
        _g1.run_earned = 0;
        _g1.fish = 0;
        _g1.stats.clicks = 60;
        _g1.stats.purchases = 10;
        _g1.service.served = array_create(SERVICE_GUESTS, 0);
        _g1.earned.moon = 0;
        _g1.occult.found = false;
        _g1.occult.in_hollow = false;
        for (var _l1 = 0; _l1 < LAYER_COUNT; _l1++) {
            _g1.layers[$ global.LAYER[_l1].key] = 0;
            _g1.earned[$ global.LAYER[_l1].key] = 0;
            _g1.prog[_l1] = 0;
        }
        global.offline_s = 0;
        with (obj_bg) travel_open = false;
        zone_enter(0);
        // A deterministic unobstructed cafe for the screenshot set: the
        // tutorial and welcome card own the strip by design, so they must not
        // be left over from boot, and a lesson may not queue itself mid-set.
        with (obj_tutorial) instance_destroy();
        with (obj_welcome) instance_destroy();
        with (obj_guide) { shown = -1; cooldown = 999; }
        global.ct_stage = 50;
    } else if (_stage == 50) {
        var _obj = objective_goal();
        // Name the gate that hid the strip, not just the goal it chose: a
        // transient tutorial or card in the fixture must be diagnosable from
        // the report instead of only from a screenshot.
        var _hid = guide_strip_hidden();
        var _why = " hidden=" + string(_hid)
                 + " collapsed=" + string(guide_strip_collapsed())
                 + " modal=" + string(ui_card_open())
                 + " card=" + string(guide_card_active())
                 + " tutorial=" + string(instance_exists(obj_tutorial))
                 + " welcome=" + string(instance_exists(obj_welcome));
        cafe_test_note(!_hid && _obj.short != ""
                       && _obj.page >= 0 && _obj.page < array_length(guide_pages()) 
                       && _obj.bar >= 0 && _obj.bar <= 1,
                       "guide.objective.live",
                       _obj.short + " @ page " + string(_obj.page) + _why);
        // The panel is display-only; only ? and X are live. This is the exact
        // regression the player reported: a click on the strip body used to
        // open the manual, which felt like the closed panel reopening.
        var _sr = guide_strip_rects();
        var _body_inert = (guide_strip_action(_sr.panel.x + 320, _sr.panel.y + 70, true) == "");
        var _help_ok    = (guide_strip_action(_sr.help.x + 24, _sr.help.y + 24, true) == "help");
        var _hide_ok    = (guide_strip_action(_sr.hide.x + 24, _sr.hide.y + 24, true) == "hide");
        var _nopress    = (guide_strip_action(_sr.help.x + 24, _sr.help.y + 24, false) == "");
        cafe_test_note(_body_inert && _help_ok && _hide_ok && _nopress,
                       "guide.strip.clicks",
                       "native body inert, ? help, X hide, no action without a press");

        // The interface now has a native canvas. Prove the canvas size, the
        // room-space mapping, and that the high-traffic panels are budgeted
        // inside the screen rather than inherited from the 480 canvas.
        var _layout_ok = (display_get_gui_width() == UI_W
                          && display_get_gui_height() == UI_H
                          && UI_W == 1920 && UI_H == 1080
                          && UI_LEGACY_S == 4);
        cafe_test_note(_layout_ok, "layout.canvas",
                       "gui=" + string(display_get_gui_width()) + "x"
                       + string(display_get_gui_height()));

        // One type scale: the two pixel fonts must measure exactly the two
        // documented roles on the native canvas.
        draw_set_font(global.fnt_big);
        var _type_title = string_height("Ag") * UI_S;
        draw_set_font(global.fnt_small);
        var _type_body = string_height("Ag") * UI_S;
        cafe_test_note(_type_title == UI_TYPE_TITLE_PX && _type_body == UI_TYPE_BODY_PX,
                       "layout.type",
                       "title=" + string(_type_title) + " body=" + string(_type_body));

        // The room rail was the reported huge control. It must use the native
        // 140x40 control height and 44px rows, and sit entirely on the canvas.
        var _rt = zone_rooms_toggle_rect();
        var _rc = zone_rooms_card_rect();
        var _rr = zone_room_rect(0);
        var _room_ok = (_rt.w == UI_W_CONTROL && _rt.h == UI_H_CONTROL
                       && _rr.h == ROOM_ROW_H
                       && _rt.x >= 0 && _rt.y >= 96
                       && _rt.x + _rt.w <= UI_W
                       && _rc.y + _rc.h <= UI_H - 24
                       && _rr.x + _rr.w <= _rc.x + _rc.w - 12);
        cafe_test_note(_room_ok, "layout.roomrail",
                       "toggle=" + string(_rt.w) + "x" + string(_rt.h)
                       + " row=" + string(_rr.w) + "x" + string(_rr.h));

        var _shop_ok = obj_shop.PANEL_X + obj_shop.PANEL_W <= UI_W - 24
                    && obj_shop.PANEL_Y >= 104
                    && obj_shop.PANEL_Y + obj_shop.PANEL_H <= UI_H - 24
                    && obj_shop.SHOP_ROWS >= 9
                    && obj_shop.PANEL_Y > 96;
        cafe_test_note(_shop_ok, "layout.shop",
                       "rail=" + string(obj_shop.PANEL_X) + "," + string(obj_shop.PANEL_Y)
                       + " " + string(obj_shop.PANEL_W) + "x" + string(obj_shop.PANEL_H)
                       + " rows=" + string(obj_shop.SHOP_ROWS));

        var _strip_ok = _sr.panel.x + _sr.panel.w < obj_shop.PANEL_X
                     && _sr.panel.y + _sr.panel.h <= UI_H - 24
                     && _sr.help.x + _sr.help.w <= _sr.panel.x + _sr.panel.w
                     && _sr.hide.x + _sr.hide.w <= _sr.panel.x + _sr.panel.w;
        cafe_test_note(_strip_ok, "layout.strip",
                       "strip=" + string(_sr.panel.x) + "," + string(_sr.panel.y)
                       + " " + string(_sr.panel.w) + "x" + string(_sr.panel.h));

        var _card = guide_card_rect();
        var _btns = guide_card_button_rects();
        var _card_ok = _card.x >= 0 && _card.y >= 0
                    && _card.x + _card.w <= UI_W
                    && _card.y + _card.h <= UI_H
                    && _btns[3].x + _btns[3].w <= _card.x + _card.w
                    && _btns[3].y + _btns[3].h <= _card.y + _card.h;
        cafe_test_note(_card_ok, "layout.lessoncard",
                       "card=" + string(_card.w) + "x" + string(_card.h));

        var _album_ok = ALBUM_X + ALBUM_W <= UI_W - 24
                     && ALBUM_Y + ALBUM_H <= UI_H - 24;
        var _tabs_native = album_nav_rects();
        for (var _lt = 0; _lt < array_length(_tabs_native); _lt++) {
            if (_tabs_native[_lt].left < ALBUM_X + 24
                || _tabs_native[_lt].left + _tabs_native[_lt].width > ALBUM_X + ALBUM_W - 24)
                _album_ok = false;
        }
        cafe_test_note(_album_ok, "layout.journal",
                       "card=" + string(ALBUM_W) + "x" + string(ALBUM_H)
                       + " tabs=" + string(array_length(_tabs_native)));

        var _boost_ok = BOOST_X >= 0 && BOOST_Y >= 0
                     && BOOST_X + BOOST_W <= UI_W - 24
                     && BOOST_Y + BOOST_H <= UI_H - 24;
        cafe_test_note(_boost_ok, "layout.boost",
                       "card=" + string(BOOST_W) + "x" + string(BOOST_H));

        // The converted menus: every card and every interactive rect has to
        // sit inside the native canvas, or a fullscreen player cannot reach it.
        var _menu_ok = true;
        var _ms = settings_ui();
        var _mcard = _ms.card;
        if (_mcard.x < 0 || _mcard.y < 0
            || _mcard.x + _mcard.w > UI_W || _mcard.y + _mcard.h > UI_H) _menu_ok = false;
        var _acts = [_ms.music, _ms.sfx, _ms.motion, _ms.hat,
                     _ms.stickers, _ms.guide, _ms.reset, _ms.close, _ms.help];
        for (var _ai = 0; _ai < array_length(_acts); _ai++) {
            var _ar = _acts[_ai];
            if (_ar.x < _mcard.x || _ar.y < _mcard.y
                || _ar.x + _ar.w > _mcard.x + _mcard.w
                || _ar.y + _ar.h > _mcard.y + _mcard.h) _menu_ok = false;
        }
        var _mm = manual_ui();
        if (_mm.card.x < 0 || _mm.card.x + _mm.card.w > UI_W
            || _mm.card.y < 0 || _mm.card.y + _mm.card.h > UI_H) _menu_ok = false;
        for (var _pi = 0; _pi < array_length(_mm.pills); _pi++) {
            var _pp = _mm.pills[_pi];
            if (_pp.x < _mm.card.x || _pp.x + _pp.w > _mm.card.x + _mm.card.w) _menu_ok = false;
        }
        if (_mm.prev.y + _mm.prev.h > _mm.card.y + _mm.card.h
            || _mm.next.x + _mm.next.w > _mm.card.x + _mm.card.w
            || _mm.back.y + _mm.back.h > _mm.card.y + _mm.card.h) _menu_ok = false;
        var _mt = stickers_ui();
        if (_mt.grid_x + 3 * (_mt.cell_w + _mt.gap) + _mt.cell_w
            > _mt.card.x + _mt.card.w - 40) _menu_ok = false;
        if (_mt.grid_y + 2 * (_mt.cell_h + _mt.gap) + _mt.cell_h
            > _mt.card.y + _mt.card.h - 100) _menu_ok = false;
        var _mp = prestige_ui();
        if (_mp.do_btn.x + _mp.do_btn.w > _mp.nah_btn.x
            || _mp.nah_btn.x + _mp.nah_btn.w > _mp.card.x + _mp.card.w
            || _mp.do_btn.y + _mp.do_btn.h > _mp.card.y + _mp.card.h) _menu_ok = false;
        var _mv = service_ui();
        if (_mv.toggle.x + _mv.toggle.w > _mv.card.x + _mv.card.w
            || _mv.serve.y + _mv.serve.h > _mv.card.y + _mv.card.h
            || _mv.entry.y + _mv.entry.h > _mv.card.y + _mv.card.h) _menu_ok = false;
        for (var _bi = 0; _bi < 3; _bi++) {
            if (_mv.base[_bi].x + _mv.base[_bi].w > _mv.card.x + _mv.card.w
                || _mv.topping[_bi].y + _mv.topping[_bi].h > _mv.card.y + _mv.card.h) _menu_ok = false;
        }
        var _mwc = welcome_card_rect();
        if (_mwc.x < 0 || _mwc.y < 0
            || _mwc.x + _mwc.w > UI_W || _mwc.y + _mwc.h > UI_H) _menu_ok = false;
        cafe_test_note(_menu_ok, "layout.menus",
                       "settings/manual/stickers/reset/counter/welcome native");

        // Text columns are measured in the same 2x pixels they are drawn in.
        var _text_ok = true;
        for (var _tt = 0; _tt < TIER_COUNT; _tt++) {
            if (dui_text_w(global.TIER[_tt].name, global.fnt_small) > 280) _text_ok = false;
        }
        var _manual = guide_pages();
        for (var _ll = 0; _ll < array_length(_manual); _ll++) {
            if (array_length(guide_lines_px(_manual[_ll], 872)) > 5) _text_ok = false;
        }
        cafe_test_note(_text_ok, "layout.textfit", "shop names + five-line lessons");

        // Bulk buying: a fixed batch is all-or-nothing and charges the exact
        // ladder; MAX keeps going while the fish last. The same control drives
        // the charm rows, so prove that path too, then restore the fixture.
        var _bf = global.G.fish;
        var _bt = global.G.tiers[0];
        var _bb = global.G.settings.buy;
        var _bp = global.G.stats.purchases;
        var _bs = global.G.journal.materials.scraps;
        global.G.tiers[0] = 0;
        var _c10 = econ_bulk_cost(0, 10);
        global.G.fish = _c10;
        global.G.settings.buy = 10;
        var _b10 = econ_buy_bulk(0, 10);
        var _fixed_ok = false;
        if (_b10 == 10) {
            if (global.G.tiers[0] == 10) {
                if (global.G.fish <= 0.001) _fixed_ok = true;
            }
        }
        var _c100 = econ_bulk_cost(0, 100);
        global.G.fish = max(0, _c100 - 1);
        var _b100 = econ_buy_bulk(0, 100);
        var _bulk_gate = false;
        if (_b100 == 0) {
            if (global.G.tiers[0] == 10) {
                _bulk_gate = true;
            }
        }
        global.G.fish = 1000000000000000;
        global.G.settings.buy = 0;
        var _bmax = econ_buy_bulk(0, 0);
        var _max_ok = false;
        if (_bmax > 0) {
            if (global.G.tiers[0] == 10 + _bmax) _max_ok = true;
        }
        global.G.settings.buy = 10;
        var _level_before = up_level("paw");
        global.G.layers.yarn = 1000000000000;
        var _ub = up_buy_bulk("paw", 10);
        var _up_ok = false;
        if (_ub == 10) {
            if (up_level("paw") == _level_before + 10) _up_ok = true;
        }
        global.G.layers.yarn = 0;
        var _unone = up_buy_bulk("paw", 10);
        var _upgate_ok = false;
        if (_unone == 0) {
            if (up_level("paw") == _level_before + 10) _upgate_ok = true;
        }
        global.G.settings.buy = 1;
        var _cyc1 = buy_count();
        buy_cycle();
        var _cyc2 = buy_count();
        buy_cycle();
        var _cyc3 = buy_count();
        buy_cycle();
        var _cyc4 = buy_count();
        var _cycle_ok = false;
        if (_cyc1 == 1) {
            if (_cyc2 == 10) {
                if (_cyc3 == 100) {
                    if (_cyc4 == 0) _cycle_ok = true;
                }
            }
        }
        global.G.fish = _bf; global.G.tiers[0] = _bt; global.G.settings.buy = _bb;
        global.G.stats.purchases = _bp; global.G.journal.materials.scraps = _bs;
        global.G.up[$ "paw"] = _level_before;
        cafe_test_note(_fixed_ok && _bulk_gate && _max_ok && _cycle_ok,
                       "shop.bulk",
                       "10x exact, 100x all-or-nothing, MAX takes what fits, 1-10-100-MAX cycle");
        cafe_test_note(_up_ok && _upgate_ok, "boost.bulk",
                       "charm 10x and its all-or-nothing gate");
        cafe_shot("ui_objective");
        global.G.guide.hidden = true;
        global.ct_stage = 58;
    } else if (_stage == 58) {
        cafe_test_note(guide_strip_collapsed() && !guide_strip_hover(),
                       "guide.strip.collapsed", "mini tab only");
        // Closed means closed. Neither the old body nor the old X spot may
        // resurrect the strip; only the deliberate ? does.
        var _sr2 = guide_strip_rects();
        var _closed_inert = (guide_strip_action(_sr2.panel.x + 320, _sr2.panel.y + 70, true) == ""
                          && guide_strip_action(_sr2.hide.x + 24, _sr2.hide.y + 24, true) == ""
                          && guide_strip_action(_sr2.help.x + 24, _sr2.help.y + 24, true) == ""
                          && guide_strip_action(_sr2.panel.x + 200, _sr2.panel.y + 60, true) == "");
        var _tab_live = (guide_strip_action(_sr2.show.x + 28, _sr2.show.y + 28, true) == "show");
        cafe_test_note(_closed_inert && _tab_live, "guide.strip.closed",
                       "old panel and old tab area inert, explicit ? is the only way back");
        cafe_shot("ui_objective_hidden");
        global.G.guide.hidden = false;
        global.G.lifetime_earned = 0;
        with (obj_bg) travel_open = false;
        zone_enter(0);
        global.ct_stage = 62;
    } else if (_stage == 62) {
        // One kitten, held still, photographed facing each way. This is the
        // visual half of the pivot regression: the two shots must mirror
        // around the same x, not jump by the sprite width. The goal strip is
        // hidden so it cannot cover the feet and shadow being judged.
        global.G.guide.hidden = true;
        with (obj_guide) { shown = -1; }
        with (obj_cat_mini) instance_destroy();
        var _kc = instance_create_depth(230, 244, 10, obj_cat_mini);
        _kc.set_coat("ginger");
        _kc.state = "sit";
        _kc.sit_t = 90;
        _kc.dir = 1;
        _kc.image_xscale = 1;
        global.ct_stage = 63;
    } else if (_stage == 63) {
        cafe_shot("ui_kitten_right");
        with (obj_cat_mini) {
            dir = -1;
            image_xscale = -1;
            state = "sit";
            sit_t = 90;
        }
        global.ct_stage = 64;
    } else if (_stage == 64) {
        cafe_shot("ui_kitten_left");
        // Every kitten sprite must pivot on the body centre and ground line,
        // and the spinning yarn must pivot on its middle, not a corner.
        var _kitten_spr = [];
        var _coats = ["tabby", "calico", "tuxedo", "ginger",
                      "grey", "snow", "mint", "rose"];
        for (var _qc = 0; _qc < array_length(_coats); _qc++) {
            array_push(_kitten_spr, asset_get_index("spr_cat_" + _coats[_qc] + "_idle"));
            array_push(_kitten_spr, asset_get_index("spr_cat_" + _coats[_qc] + "_walk"));
            array_push(_kitten_spr, asset_get_index("spr_cat_" + _coats[_qc] + "_happy"));
        }
        var _pivot_ok = true;
        var _pivot_bad = "";
        for (var _qs = 0; _qs < array_length(_kitten_spr); _qs++) {
            var _ks = _kitten_spr[_qs];
            if (sprite_get_xoffset(_ks) != sprite_get_width(_ks) * 0.5
                || sprite_get_yoffset(_ks) != sprite_get_height(_ks)) {
                _pivot_ok = false;
                _pivot_bad += sprite_get_name(_ks) + " ";
            }
        }
        var _yarn_ok = sprite_get_xoffset(spr_ui_yarn_icon) * 2 == sprite_get_width(spr_ui_yarn_icon)
                    && sprite_get_yoffset(spr_ui_yarn_icon) * 2 == sprite_get_height(spr_ui_yarn_icon);
        cafe_test_note(_pivot_ok && _yarn_ok, "sprite.pivots",
                       "24 kitten sprites bottom-centre, yarn middle-centre"
                       + (_pivot_bad == "" ? "" : " bad=" + _pivot_bad));
        with (obj_cat_mini) instance_destroy();
        global.G.guide.hidden = false;
        global.ct_stage = 2;
    } else if (_stage == 2) {
        cafe_shot("ui_cafe_wall");
        var _g2 = global.G;
        _g2.fish = 2000000;
        _g2.lifetime_earned = 9000000;
        _g2.tiers = [12, 7, 4, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        zone_enter(0);          // pin the cafe so the shot is the cafe
        global.zone_banner = 0;
        global.ct_stage = 3;
    } else if (_stage == 3) {
        cafe_shot("ui_shop");
        // real charms at real levels, so the progress bars have something to say
        global.G.fish = 2000000000;
        global.G.layers.yarn = 300;
        global.G.earned.yarn = 120;
        global.G.earned.stars = 8;
        global.G.earned.beans = 1;
        global.G.up[$ "paw"] = 7;
        global.G.up[$ "share"] = 5;
        global.G.up[$ "cheap"] = 3;
        global.G.up[$ "combo"] = 10;
        global.G.up[$ "stock"] = 2;
        // later trees, so every tab has real levels and real bars to inspect
        global.G.earned.aurora = max(1, global.G.earned.aurora);
        global.G.earned.moon = max(1, global.G.earned.moon);
        global.G.up[$ "shine"] = 4;
        global.G.up[$ "quick"] = 2;
        global.G.up[$ "gift"] = 1;
        global.G.up[$ "comet"] = 3;
        global.G.up[$ "pockets"] = 2;
        global.G.up[$ "sprout"] = 3;
        global.G.up[$ "roots"] = 2;
        global.G.up[$ "canopy"] = 1;
        global.G.up[$ "bloom"] = 2;
        global.G.up[$ "glow"] = 2;
        global.G.up[$ "sky"] = 1;
        global.G.up[$ "dawn"] = 1;
        global.G.up[$ "moonbeam"] = 3;
        global.G.up[$ "moonlit"] = 2;
        var _up = ui_card_spawn(obj_upgrades);
        _up.tab = 0;
        global.ct_stage = 4;
    } else if (_stage == 4) {
        cafe_shot("ui_boost");
        with (obj_upgrades) tab = 1;
        global.ct_stage = 40;
    } else if (_stage == 40) {
        cafe_shot("ui_boost_stars");
        with (obj_upgrades) tab = 2;
        global.ct_stage = 41;
    } else if (_stage == 41) {
        cafe_shot("ui_boost_beans");
        with (obj_upgrades) tab = 3;
        global.ct_stage = 42;
    } else if (_stage == 42) {
        cafe_shot("ui_boost_aurora");
        with (obj_upgrades) tab = 4;
        global.ct_stage = 43;
    } else if (_stage == 43) {
        cafe_shot("ui_boost_moon");
        with (obj_upgrades) instance_destroy();
        with (obj_shop) { shop_top = 0; }
        // CATS carries the cat-bond choice and its rung meter; photograph it
        // with real bonds so an empty bar is not what gets reviewed.
        var _gcat = global.G;
        _gcat.companion = 0;
        _gcat.bonds[0] = 60;
        _gcat.bonds[1] = 20;
        _gcat.bonds[2] = 140;
        _gcat.bonds[3] = 300;
        var _al = ui_card_spawn(obj_album);
        _al.mode = 0;
        _al.page = 0;
        global.ct_stage = 44;
    } else if (_stage == 44) {
        cafe_shot("ui_cats");
        staff_set(1, 0, 3);
        staff_set(1, 1, 0);
        with (obj_album) { mode = 4; staff_station = 1; }
        global.ct_stage = 5;
    } else if (_stage == 5) {
        cafe_shot("ui_staff");
        with (obj_album) instance_destroy();
        var _st = ui_card_spawn(obj_settings);
        _st.guide = 1;
        _st.guide_page = 0;
        global.ct_stage = 6;
    } else if (_stage == 6) {
        cafe_shot("ui_guide");
        with (obj_settings) instance_destroy();
        with (obj_welcome) instance_destroy();
        // Let the real queue surface the staff lesson: six cats, no one
        // assigned, and every higher-priority card marked seen.
        var _g6 = global.G;
        _g6.guide.seen = "";
        _g6.lifetime_earned = 8000000;
        _g6.run_earned = 0;
        _g6.fish = 0;
        _g6.stats.clicks = 60;
        _g6.stats.purchases = 10;
        _g6.service.served = array_create(SERVICE_GUESTS, 0);
        _g6.service.served[0] = 1;
        _g6.earned.moon = 0;
        _g6.occult.found = false;
        _g6.occult.in_hollow = false;
        for (var _s6 = 0; _s6 < array_length(_g6.staff.slots); _s6++) _g6.staff.slots[_s6] = -1;
        for (var _l6 = 0; _l6 < LAYER_COUNT; _l6++) {
            _g6.layers[$ global.LAYER[_l6].key] = 0;
            _g6.earned[$ global.LAYER[_l6].key] = 0;
            _g6.prog[_l6] = 0;
        }
        global.offline_s = 0;
        zone_enter(0);
        global.zone_banner = 0;
        with (obj_guide) { shown = -1; cooldown = 0; snooze_id = ""; snooze_t = 0; }
        global.ct_stage = 51;
    } else if (_stage == 51) {
        var _lesson_ok = guide_card_active() && obj_guide.def_id == "staff";
        cafe_test_note(_lesson_ok, "guide.lesson.live",
                       "staff card, page " + string(obj_guide.page + 1));

        // The strip has a real dismiss/reopen state, saved with the cafe.
        var _strip_was = guide_strip_collapsed();
        var _strip_closed = guide_strip_toggle();
        var _strip_open = guide_strip_toggle();
        cafe_test_note(!_strip_was && _strip_closed && !_strip_open
                       && !guide_strip_collapsed(), "guide.strip.toggle",
                       "closed then reopened");
        cafe_shot("ui_lesson_staff");
        // Stay on the card for another beat so the next stage can prove the
        // cafe kept producing while it was open.
        global.ct_card_fish = global.G.fish;
        global.ct_card_ok = _lesson_ok;
        global.ct_stage = 57;
    } else if (_stage == 57) {
        var _still = guide_card_active() && obj_guide.def_id == "staff";
        var _ticked = global.G.fish > global.ct_card_fish + 0.001;
        cafe_test_note(global.ct_card_ok && _still && _ticked,
                       "guide.card.nonblocking",
                       "card kept open, fish +" + fmt_small(global.G.fish - global.ct_card_fish));
        guide_mark("staff");
        with (obj_guide) { shown = -1; cooldown = 999; }

        // The reset card, on layer 0's real frontier. Only this lesson is
        // unseen, so the card on screen is the one the state chose.
        var _gR = global.G;
        _gR.guide.seen = "";
        var _allR = guide_lessons();
        for (var _qR = 0; _qR < array_length(_allR); _qR++) {
            if (_allR[_qR].id != "layer0") guide_mark_quiet(_allR[_qR].id);
        }
        _gR.earned.moon = 0;
        _gR.earned.yarn = 0;
        _gR.earned.stars = 0;
        _gR.layers.yarn = 0;
        _gR.run_earned = global.LAYER[0].need * up_need_mult(0) + 1000000;
        _gR.occult.found = false;
        _gR.occult.in_hollow = false;
        _gR.stats.clicks = max(60, _gR.stats.clicks);
        _gR.stats.purchases = max(10, _gR.stats.purchases);
        global.offline_s = 0;
        zone_enter(0);
        global.zone_banner = 0;
        with (obj_guide) { shown = -1; cooldown = 0; snooze_id = ""; snooze_t = 0; }
        global.ct_stage = 55;
    } else if (_stage == 55) {
        var _reset_ok = guide_card_active() && obj_guide.def_id == "layer0";
        cafe_test_note(_reset_ok, "guide.lesson.reset.live",
                       "layer0 card, page " + string(obj_guide.page + 1));
        cafe_shot("ui_lesson_reset");
        guide_mark("layer0");
        with (obj_guide) { shown = -1; cooldown = 999; }

        // The festival card, one moon earned and no rank entered.
        var _gF = global.G;
        _gF.guide.seen = "";
        var _allF = guide_lessons();
        for (var _qF = 0; _qF < array_length(_allF); _qF++) {
            if (_allF[_qF].id != "festival") guide_mark_quiet(_allF[_qF].id);
        }
        _gF.earned.moon = 1;
        _gF.festival.ranks = array_create(FESTIVAL_VENUES, 0);
        _gF.occult.found = false;
        _gF.run_earned = 0;
        _gF.lifetime_earned = 0;
        _gF.stats.clicks = max(60, _gF.stats.clicks);
        _gF.stats.purchases = max(10, _gF.stats.purchases);
        _gF.service.served[0] = max(1, _gF.service.served[0]);
        global.offline_s = 0;
        zone_enter(0);
        global.zone_banner = 0;
        with (obj_guide) { shown = -1; cooldown = 0; snooze_id = ""; snooze_t = 0; }
        global.ct_stage = 56;
    } else if (_stage == 56) {
        var _fest_ok = guide_card_active() && obj_guide.def_id == "festival";
        cafe_test_note(_fest_ok, "guide.lesson.festival.live",
                       "festival card, page " + string(obj_guide.page + 1));
        cafe_shot("ui_lesson_festival");
        guide_mark("festival");
        with (obj_guide) { shown = -1; cooldown = 999; }

        // The Era card is the one that appears the first time MOON is earned.
        var _gE = global.G;
        _gE.guide.seen = "";
        var _allE = guide_lessons();
        for (var _qE = 0; _qE < array_length(_allE); _qE++) {
            if (_allE[_qE].id != "era") guide_mark_quiet(_allE[_qE].id);
        }
        _gE.earned.moon = 1;
        _gE.occult.found = false;
        _gE.occult.in_hollow = false;
        _gE.run_earned = 0;
        _gE.stats.clicks = max(60, _gE.stats.clicks);
        _gE.stats.purchases = max(10, _gE.stats.purchases);
        _gE.service.served[0] = max(1, _gE.service.served[0]);
        global.offline_s = 0;
        zone_enter(0);
        global.zone_banner = 0;
        with (obj_guide) { shown = -1; cooldown = 0; snooze_id = ""; snooze_t = 0; }
        global.ct_stage = 59;
    } else if (_stage == 59) {
        var _era_card = guide_card_active() && obj_guide.def_id == "era";
        cafe_test_note(_era_card, "guide.lesson.era.live",
                       "era card, page " + string(obj_guide.page + 1));
        cafe_shot("ui_lesson_era");
        guide_mark("era");
        with (obj_guide) { shown = -1; cooldown = 999; }
        var _set2 = ui_card_spawn(obj_settings);
        _set2.guide = 1;
        _set2.guide_page = 21;
        global.ct_stage = 52;
    } else if (_stage == 52) {
        // The manual was already photographed on page 1 (ui_guide). Page 21
        // is the same card; a second full-screen save here was the one frame
        // Wine could stall on, and it proved nothing the first shot did not.
        with (obj_settings) instance_destroy();
        global.G.lifetime_earned = 1500000;
        zone_enter(1);
        global.zone_banner = 0;
        with (obj_bg) travel_open = true;
        global.ct_stage = 66;
    } else if (_stage == 7) {
        cafe_shot("ui_rooms");
        with (obj_bg) travel_open = false;
        global.G.lifetime_earned = 300000000;
        zone_enter(4);
        global.zone_banner = 0;
        global.ct_stage = 8;
    } else if (_stage == 8) {
        cafe_shot("ui_tea_house");
        global.G.lifetime_earned = 30000000000;
        zone_enter(5);
        global.zone_banner = 0;
        global.ct_stage = 9;
    } else if (_stage == 9) {
        cafe_shot("ui_library");
        var _al2 = ui_card_spawn(obj_album);
        _al2.mode = 1;
        _al2.chapter = 0;
        global.ct_stage = 10;
    } else if (_stage == 10) {
        cafe_shot("ui_journal_goals");
        with (obj_album) mode = 3;
        global.ct_stage = 11;
    } else if (_stage == 11) {
        cafe_shot("ui_journal_orders");
        with (obj_album) mode = 2;
        global.ct_stage = 12;
    } else if (_stage == 12) {
        cafe_shot("ui_journal_projects");
        global.G.earned.moon = 1;
        with (obj_album) { mode = 5; }
        global.ct_stage = 120;
    } else if (_stage == 120) {
        cafe_shot("ui_eras");
        with (obj_album) instance_destroy();
        global.G.rooms.mastery = [400, 120, 0, 0, 0, 1200];
        zone_enter(0);
        global.zone_banner = 0;
        with (obj_bg) travel_open = true;
        global.ct_stage = 121;
    } else if (_stage == 121) {
        cafe_shot("ui_rooms_mastery");
        with (obj_bg) travel_open = false;
        var _sv = ui_card_spawn(obj_service);
        _sv.t = 20;
        global.ct_stage = 13;
    } else if (_stage == 13) {
        cafe_shot("ui_counter");
        // every dish known, so the festival menu has real choices to show
        var _gs = service_guests();
        for (var _gi = 0; _gi < SERVICE_GUESTS; _gi++) {
            for (var _di = 0; _di < SERVICE_RECIPES; _di++) {
                var _slot = _gi * SERVICE_RECIPES + _di;
                global.G.service.known_base[_slot] = (_gs[_gi].base + _di) mod 3;
                global.G.service.known_topping[_slot] = (_gs[_gi].topping + _di * 2) mod 3;
            }
        }
        global.G.journal.materials.scraps = 99;
        global.G.journal.materials.treats = 99;
        global.G.journal.materials.dust = 99;
        global.G.festival.menu = [0, 1, 2];
        global.G.festival.ranks[0] = 0;
        with (obj_service) {
            festival_mode = true;
            festival_venue = 0;
            festival_feedback = "";
        }
        global.ct_stage = 14;
    } else if (_stage == 14) {
        cafe_shot("ui_festival");
        with (obj_service) instance_destroy();
        global.G.run_earned = 900000000;
        global.G.layers.yarn = 40;
        global.G.earned.yarn = 40;
        var _pr = ui_card_spawn(obj_prestige);
        _pr.t = 20;
        global.ct_stage = 15;
    } else if (_stage == 15) {
        cafe_shot("ui_prestige");
        // Start the ball low enough that the 12-frame stage wait lands it in
        // the middle of the spin, after the payout label appears, and before
        // the reset flash. Starting at 14 ran it into the flash, which washed
        // out both the pivot and the label placement this shot exists to prove.
        with (obj_prestige) { yarn_ball = 7; flash = 0; closing = -1; }
        global.ct_stage = 65;
    } else if (_stage == 65) {
        cafe_shot("ui_prestige_spin");
        with (obj_prestige) instance_destroy();
        var _set = ui_card_spawn(obj_settings);
        _set.t = 20;
        global.ct_stage = 16;
    } else if (_stage == 16) {
        cafe_shot("ui_more");
        with (obj_settings) instance_destroy();
        // the hidden seam, revealed only because this fixture has stopped to look
        global.G.lifetime_earned = 8000000;
        global.G.earned.moon = 1;
        global.G.festival.ranks[0] = 1;
        global.G.occult.found = false;
        global.G.occult.in_hollow = false;
        global.G.occult.knocks = 0;
        zone_enter(0);
        global.zone_banner = 0;
        with (obj_veil_door) hover_t = 60;
        global.ct_stage = 17;
    } else if (_stage == 17) {
        cafe_shot("ui_seam");
        global.G.occult.found = true;
        with (obj_veil_door) { hover_t = 0; }
        global.ct_stage = 18;
    } else if (_stage == 18) {
        cafe_shot("ui_hatch");
        // With the Hollow discovered, the cupboard is still cafe furniture.
        // A garden and a library shot prove it is absent from both later rooms.
        global.G.occult.found = true;
        zone_enter(1);
        global.zone_banner = 0;
        global.zone_flash = 0;
        with (obj_veil_door) hover_t = 60;
        global.ct_stage = 30;
    } else if (_stage == 30) {
        cafe_shot("ui_door_garden");
        global.G.lifetime_earned = max(global.G.lifetime_earned, 30000000000);
        zone_enter(5);
        global.zone_banner = 0;
        global.zone_flash = 0;
        global.ct_stage = 31;
    } else if (_stage == 31) {
        cafe_shot("ui_door_library");
        global.G.occult.found = false;
        global.G.occult.knocks = 0;
        zone_enter(0);
        global.zone_banner = 0;
        global.zone_flash = 0;
        with (obj_veil_door) hover_t = 0;
        global.G.achievements = ["tap1", "tap200", "combo40", "cat10", "fish1k",
                                "garden", "cloud", "reset1", "star1", "bean1",
                                "aurora1", "moon1", "tea", "library"];
        var _stk = ui_card_spawn(obj_stickers);
        _stk.t = 20;
        global.ct_stage = 19;
    } else if (_stage == 19) {
        cafe_shot("ui_stickers");
        with (obj_stickers) page = 1;
        global.ct_stage = 20;
    } else if (_stage == 20) {
        cafe_shot("ui_stickers2");
        // Every cafe screen has now been drawn at least once. The primitives
        // recorded each control's real height and each text font; this is the
        // runtime half of the one-scale rule. The source half is
        // tools/ui_layout_audit.py, which rejects a literal height before boot.
        var _heights_used = (global.ui_h40 > 0 && global.ui_h44 > 0
                          && global.ui_h56 > 0 && global.ui_h64 > 0);
        var _detail = ui_audit_report();
        if (!ui_audit_clean()) {
            for (var _uf = 0; _uf < min(3, array_length(global.ui_fail)); _uf++) {
                _detail += " !" + global.ui_fail[_uf];
            }
        }
        cafe_test_note(ui_audit_clean() && _heights_used
                       && global.ui_controls > 100 && global.ui_texts > 100
                       && global.ui_fits > 0,
                       "ui.scale", _detail);
        with (obj_stickers) instance_destroy();
        with (obj_welcome) instance_destroy();
        // A Hollow location lesson is dark and lives on the map, not over an
        // activity. Clear the seen set except the door so the queue is real.
        var _g20 = global.G;
        _g20.guide.seen = "";
        var _all20 = guide_lessons();
        for (var _q20 = 0; _q20 < array_length(_all20); _q20++) {
            if (_all20[_q20].id != "door") guide_mark_quiet(_all20[_q20].id);
        }
        _g20.occult.found = true;
        _g20.occult.in_hollow = true;
        _g20.occult.closings = 0;
        _g20.occult.omen.id = -1;
        _g20.occult.night_best = 0;
        global.offline_s = 0;
        if (!instance_exists(obj_veil)) {
            instance_create_depth(0, 0, -10000, obj_veil);
        }
        with (obj_veil) { mode = 0; intro = 0; loc = 1; }
        with (obj_guide) { shown = -1; cooldown = 0; snooze_id = ""; snooze_t = 0; }
        // The score follows the room; make sure the test is not muted first.
        global.G.settings.mute_music = false;
        if (global.music_id < 0) music_start();
        music_apply_gain(0);
        var _hollow_len = audio_sound_length(global.music_id);
        var _cafe_len = audio_sound_length(snd_music_cafe);
        cafe_test_note(global.music_track == "hollow"
                       && global.music_id >= 0
                       && audio_is_playing(global.music_id)
                       && _hollow_len > 0
                       && abs(_hollow_len - _cafe_len) > 1,
                       "music.hollow",
                       "hollow instance playing, " + string_format(_hollow_len, 1, 0)
                       + "s vs cafe " + string_format(_cafe_len, 1, 0) + "s");
        global.ct_stage = 53;
    } else if (_stage == 66) {
        // The cat stories need every cat unlocked; the album gates by lifetime.
        global.G.lifetime_earned = 60000000;
        // An old save has no arcs key at all. The additive default must restore
        // the four arrays without a save-version migration.
        variable_struct_remove(global.G, "arcs");
        arc_normalize();
        cafe_test_note(is_struct(global.G.arcs)
                       && array_length(global.G.arcs.step) == arc_count()
                       && array_length(global.G.arcs.branch) == arc_count()
                       && array_length(global.G.arcs.done) == arc_count()
                       && array_length(global.G.arcs.base) == arc_count(),
                       "story.merge", "old save without arcs gets defaults");
        // The venue layer is additive in exactly the same way.
        variable_struct_remove(global.G, "venue_arcs");
        venue_arc_normalize();
        cafe_test_note(is_struct(global.G.venue_arcs)
                       && array_length(global.G.venue_arcs.step) == VA_COUNT
                       && array_length(global.G.venue_arcs.branch) == VA_COUNT
                       && array_length(global.G.venue_arcs.done) == VA_COUNT,
                       "venue.merge", "old save without venue_arcs gets defaults");
        if (!is_array(global.G.arcs.step)) global.G.arcs = arc_defaults();
        var _cats = [0, 1, 3, 8];
        for (var _ac = 0; _ac < array_length(_cats); _ac++) {
            var _ci = _cats[_ac];
            global.G.arcs.step[_ci] = 0;
            global.G.arcs.branch[_ci] = -1;
            global.G.arcs.done[_ci] = 0;
            global.G.arcs.base[_ci] = 0;
            global.G.bonds[_ci] = 0;
        }
        zone_enter(0);
        global.zone_banner = 0;
        with (obj_album) instance_destroy();
        with (obj_settings) instance_destroy();
        with (obj_cat_arc) instance_destroy();
        var _story = ui_card_spawn(obj_cat_arc);
        _story.cat = 0;
        arc_open(0);
        global.ct_stage = 67;
    } else if (_stage == 67) {
        cafe_shot("ui_cat_arc");
        cafe_test_note(arc_count() == 24 && array_length(arc_steps(0)) == 5,
                       "story.count", string(arc_count()) + " cats, five beats each");
        cafe_test_note(arc_goal(0).k == "taps" && arc_step_title(0) == "THE DRIP",
                       "story.first", arc_step_title(0));
        cafe_arc_satisfy(0);
        arc_claim(0);
        cafe_arc_satisfy(0);
        arc_claim(0);
        cafe_test_note(arc_step_index(0) == 2 && is_struct(arc_choice(0)),
                       "story.choice", "branch at step 3");
        global.ct_stage = 68;
    } else if (_stage == 68) {
        cafe_shot("ui_cat_arc_choice");
        cafe_test_note(!arc_goal_ready(0), "story.choice.gate", "choice is not claimable");
        arc_choose(0, 0);
        cafe_test_note(arc_branch(0) == 0 && arc_step_index(0) == 3,
                       "story.branch.a", "Mochi kept the drip");
        // Finish the first story through its remaining beats, then play a
        // second cat to the other branch so the two outcomes differ in data.
        for (var _a1 = 0; _a1 < 4 && !arc_done(0); _a1++) {
            cafe_arc_satisfy(0);
            if (!arc_claim(0)) break;
        }
        var _second = cafe_arc_finish(1, 1);
        var _third = cafe_arc_finish(3, 0);
        var _fourth = cafe_arc_finish(8, 0);
        cafe_test_note(arc_done(0) && arc_branch(0) == 0,
                       "story.finish.a", arc_perk_name(0));
        cafe_test_note(_second && arc_done(1) && arc_branch(1) == 1,
                       "story.finish.b", arc_perk_name(1));
        cafe_test_note(_third && _fourth && arc_done(3) && arc_done(8),
                       "story.finish.more", "four arcs completed in one boot");
        cafe_test_note(cat_bond_rank(0) == 12 && cat_bond_rank(1) == 12
                       && cat_bond_rank(3) == 12 && cat_bond_rank(8) == 12,
                       "story.bond", "four stories award the full bond");
        global.G.stats.clicks = 60;
        var _tap_a = arc_tap_treats(0);
        var _tap_b = arc_tap_treats(1);
        cafe_test_note(_tap_a >= 1 && _tap_b >= 1,
                       "story.keepsake.treats", string(_tap_a) + "/" + string(_tap_b));
        cafe_test_note(arc_service_materials().treats >= 1
                       && arc_garden_plots() >= 1
                       && veil_plot_count() >= VEIL_PLOT_BASE + 1,
                       "story.keepsake.wired",
                       "service materials, garden beds and tap treats");
        global.ct_stage = 69;
    } else if (_stage == 69) {
        cafe_shot("ui_cat_arc_done");
        var _shape_ok = true;
        var _shape_bad = "";
        for (var _ac2 = 0; _ac2 < arc_count(); _ac2++) {
            var _d2 = arc_data(_ac2);
            var _s2 = arc_steps(_ac2);
            if (!is_struct(_d2) || array_length(_s2) != 5
                || !is_struct(_s2[2].choice)
                || !is_struct(_s2[2].choice.a.goal) || !is_struct(_s2[2].choice.b.goal)
                || !is_struct(_d2.reward) || _d2.reward.name == "") {
                _shape_ok = false;
                _shape_bad = "cat " + string(_ac2);
            }
        }
        cafe_test_note(_shape_ok, "story.shape", _shape_ok ? "24 arcs x 5 beats x 2 branches" : _shape_bad);
        with (obj_cat_arc) instance_destroy();

        // ---- Room story: capture the ask, the branch and the keepsake as
        // three separate frames so each layout state is reviewed.
        global.G.earned.moon = max(1, global.G.earned.moon);
        global.G.rooms.mastery[0] = 0;
        with (obj_venue_arc) instance_destroy();
        var _rv = ui_card_spawn(obj_venue_arc);
        _rv.idx = 0;
        venue_arc_open_card(0);
        global.ct_stage = 70;
    } else if (_stage == 70) {
        cafe_shot("ui_room_story_ask");
        cafe_venue_satisfy(0);
        venue_arc_claim(0);
        cafe_venue_satisfy(0);
        venue_arc_claim(0);
        cafe_test_note(array_length(venue_arc_steps(0)) == 4
                       && is_struct(venue_arc_choice(0))
                       && venue_arc_step_index(0) == 2,
                       "venue.room.choice", "room story branches on beat 3");
        global.ct_stage = 71;
    } else if (_stage == 71) {
        cafe_shot("ui_room_story_choice");
        cafe_test_note(!venue_arc_claim(0), "venue.choice.gate", "choice is not a claim");
        venue_arc_choose(0, 0);
        var _room_done = cafe_venue_finish(0, 0);
        cafe_test_note(_room_done && venue_arc_branch(0) == 0,
                       "venue.room.finish", venue_arc_perk_name(0));
        global.G.stats.clicks = 8;
        cafe_test_note(arc_tap_treats(0) >= 1,
                       "venue.room.keepsake", "room keepsake feeds the tap payout");
        with (obj_venue_arc) instance_destroy();
        var _room_card = ui_card_spawn(obj_venue_arc);
        _room_card.idx = 0;
        global.ct_stage = 72;
    } else if (_stage == 72) {
        cafe_shot("ui_room_story_done");
        with (obj_venue_arc) instance_destroy();

        // A festival story pays a different keepsake. Venue 0 is open with
        // MOON; capture its ask before claiming the first beat, then its
        // branch, then the keepsake.
        var _fv = ui_card_spawn(obj_venue_arc);
        _fv.idx = VA_ROOMS + 0;
        venue_arc_open_card(VA_ROOMS + 0);
        global.ct_stage = 73;
    } else if (_stage == 73) {
        cafe_shot("ui_festival_story_ask");
        cafe_venue_satisfy(VA_ROOMS + 0);
        venue_arc_claim(VA_ROOMS + 0);
        cafe_test_note(is_struct(venue_arc_choice(VA_ROOMS + 0)),
                       "venue.fest.choice", "festival story branches on beat 2");
        global.ct_stage = 74;
    } else if (_stage == 74) {
        cafe_shot("ui_festival_story_choice");
        var _mat0 = arc_service_materials();
        var _fest_done = cafe_venue_finish(VA_ROOMS + 0, 1);
        var _mat1 = arc_service_materials();
        cafe_test_note(_fest_done && venue_arc_done(VA_ROOMS + 0),
                       "venue.fest.finish", venue_arc_perk_name(VA_ROOMS + 0));
        cafe_test_note(_mat1.treats > _mat0.treats,
                       "venue.fest.keepsake", "festival keepsake feeds service materials");
        with (obj_venue_arc) instance_destroy();
        var _fest_card = ui_card_spawn(obj_venue_arc);
        _fest_card.idx = VA_ROOMS + 0;
        global.ct_stage = 75;
    } else if (_stage == 75) {
        cafe_shot("ui_festival_story_done");
        with (obj_venue_arc) instance_destroy();

        // Longest column text: Star Library's 180-tap ask, drawn as a stress
        // case even when the room is still locked in this save.
        var _long = ui_card_spawn(obj_venue_arc);
        _long.idx = 5;
        global.ct_stage = 76;
    } else if (_stage == 76) {
        cafe_shot("ui_room_story_long");
        with (obj_venue_arc) instance_destroy();
        cafe_test_note(ui_audit_clean() && global.ui_fits > 0,
                       "story.text.fit", ui_audit_report());
        cafe_test_note(venue_arc_count() == VA_COUNT
                       && array_length(venue_arc_steps(0)) == 4
                       && array_length(venue_arc_steps(VA_ROOMS)) == 3,
                       "venue.count", "6 rooms x 4 beats + 9 festivals x 3 beats");
        var _vshape = true;
        var _vbad = "";
        for (var _vi = 0; _vi < venue_arc_count(); _vi++) {
            var _vs = venue_arc_steps(_vi);
            var _ca = venue_arc_choice_at(_vi);
            if (!is_struct(venue_arc_data(_vi)) || array_length(_vs) < 3
                || _ca < 0 || _ca >= array_length(_vs)
                || !is_struct(_vs[_ca].choice)
                || !is_struct(_vs[_ca].choice.a.goal) || !is_struct(_vs[_ca].choice.b.goal)
                || venue_arc_perk_name(_vi) == "") {
                _vshape = false;
                _vbad = "venue " + string(_vi);
            }
        }
        cafe_test_note(_vshape, "venue.shape",
                       _vshape ? "15 stories, a choice and a keepsake each" : _vbad);
        with (obj_bg) travel_open = true;
        global.ct_stage = 7;
    } else if (_stage == 53) {
        var _dark_ok = guide_card_active() && obj_guide.def_id == "door";
        cafe_test_note(_dark_ok, "guide.lesson.hollow.live",
                       "door card, page " + string(obj_guide.page + 1));
        cafe_shot("ui_lesson_hollow");
        guide_mark("door");
        with (obj_guide) { shown = -1; cooldown = 999; }
        veil_wake();
        music_apply_gain(0);
        var _back_len = audio_sound_length(global.music_id);
        cafe_test_note(global.music_track == "cafe"
                       && global.music_id >= 0
                       && audio_is_playing(global.music_id)
                       && _back_len > 0
                       && abs(_back_len - audio_sound_length(snd_music_hollow)) > 1,
                       "music.cafe",
                       "cafe instance back, " + string_format(_back_len, 1, 0) + "s");
        // A machine-readable end marker: the runner stops the game here instead
        // of waiting out its full timeout after every check has already passed.
        var _donef = file_text_open_append("cafetest.txt");
        file_text_write_string(_donef, "DONE\n");
        file_text_close(_donef);
        global.ct_done = true;
    } else {
        global.ct_done = true;
    }
}
