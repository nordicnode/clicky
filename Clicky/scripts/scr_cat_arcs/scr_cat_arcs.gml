/// @description cat story arcs: state, progress, bond and reward API.
///
/// This is the only owner of arc progress. It stores five small arrays under
/// global.G.arcs (step, branch, done, base) and reads the authored beats from
/// scr_cat_arc_content. Nothing here draws. The one gameplay-facing surface is
/// the small set of arc_* reward helpers called by the systems that already
/// own taps, sparkles, service, gardens, halls, nights and festivals.

#macro ARC_STEPS 5
#macro ARC_MAX 24

function arc_defaults() {
    var _n = album_count();
    return {
        step: array_create(_n, 0),
        branch: array_create(_n, -1),
        done: array_create(_n, 0),
        base: array_create(_n, 0)
    };
}

/// Additive on old saves: a save with no "arcs" keeps the default arrays, and
/// a save with partial or malformed arrays is resized without touching valid
/// values. There is no SAVE_VERSION migration.
function arc_normalize() {
    if (!variable_struct_exists(global.G, "arcs") || !is_struct(global.G.arcs)) {
        global.G.arcs = arc_defaults();
    }
    var _a = global.G.arcs;
    var _n = album_count();
    if (!is_array(_a.step)) _a.step = [];
    if (!is_array(_a.branch)) _a.branch = [];
    if (!is_array(_a.done)) _a.done = [];
    if (!is_array(_a.base)) _a.base = [];
    array_resize(_a.step, _n);
    array_resize(_a.branch, _n);
    array_resize(_a.done, _n);
    array_resize(_a.base, _n);
    for (var _i = 0; _i < _n; _i++) {
        _a.step[_i] = clamp(floor(is_numeric(_a.step[_i]) ? _a.step[_i] : 0), 0, ARC_STEPS);
        _a.branch[_i] = clamp(floor(is_numeric(_a.branch[_i]) ? _a.branch[_i] : -1), -1, 1);
        _a.done[_i] = is_numeric(_a.done[_i]) ? (_a.done[_i] > 0 ? 1 : 0) : 0;
        if (!is_struct(_a.base[_i])) _a.base[_i] = 0;
        if (_a.done[_i] == 1) {
            _a.step[_i] = ARC_STEPS;
            if (_a.branch[_i] < 0) _a.branch[_i] = 0;
        } else if (_a.step[_i] > 2 && _a.branch[_i] < 0) {
            // A save that lost its branch after step 3 still has a playable
            // route; show the first branch rather than an empty ask.
            _a.branch[_i] = 0;
        }
    }
}

function arc_count() { return min(album_count(), array_length(arc_content())); }

function arc_data(_cat) {
    if (_cat < 0 || _cat >= arc_count()) return undefined;
    return arc_content()[_cat];
}

function arc_steps(_cat) {
    var _d = arc_data(_cat);
    return is_struct(_d) ? _d.steps : [];
}

function arc_step_index(_cat) {
    if (!variable_struct_exists(global.G, "arcs") || !is_array(global.G.arcs.step)) return 0;
    if (_cat < 0 || _cat >= array_length(global.G.arcs.step)) return 0;
    return clamp(floor(global.G.arcs.step[_cat]), 0, ARC_STEPS);
}

/// The step currently presented. A finished arc returns the last beat so the
/// card can still show what was completed.
function arc_current_step(_cat) {
    var _steps = arc_steps(_cat);
    var _i = min(arc_step_index(_cat), array_length(_steps) - 1);
    if (_i < 0 || array_length(_steps) == 0) return undefined;
    return _steps[_i];
}

function arc_done(_cat) {
    if (!variable_struct_exists(global.G, "arcs") || !is_array(global.G.arcs.done)) return false;
    return _cat >= 0 && _cat < array_length(global.G.arcs.done) && global.G.arcs.done[_cat] == 1;
}

function arc_branch(_cat) {
    if (!variable_struct_exists(global.G, "arcs") || !is_array(global.G.arcs.branch)) return -1;
    if (_cat < 0 || _cat >= array_length(global.G.arcs.branch)) return -1;
    return clamp(floor(global.G.arcs.branch[_cat]), -1, 1);
}

function arc_started(_cat) {
    return arc_step_index(_cat) > 0;
}

/// A step's branch goal lives on the choice at beat 3 (index 2), not on the
/// branch beat itself. Keeping that routing here means the content stays data.
function arc_goal(_cat) {
    var _steps = arc_steps(_cat);
    var _i = arc_step_index(_cat);
    if (_i < 0 || _i >= array_length(_steps)) return undefined;
    var _step = _steps[_i];
    if (is_struct(_step) && variable_struct_exists(_step, "goal") && is_struct(_step.goal)) {
        return _step.goal;
    }
    if (_i == 3 && array_length(_steps) > 2) {
        var _choice = _steps[2].choice;
        var _side = arc_branch(_cat);
        if (is_struct(_choice) && _side >= 0) {
            return _side == 0 ? _choice.a.goal : _choice.b.goal;
        }
    }
    return undefined;
}

function arc_choice(_cat) {
    var _steps = arc_steps(_cat);
    var _i = arc_step_index(_cat);
    if (_i < 0 || _i >= array_length(_steps)) return undefined;
    return (variable_struct_exists(_steps[_i], "choice") && is_struct(_steps[_i].choice))
           ? _steps[_i].choice : undefined;
}

function arc_choice_echo(_cat) {
    var _steps = arc_steps(_cat);
    if (array_length(_steps) < 3) return "";
    var _choice = _steps[2].choice;
    var _side = arc_branch(_cat);
    if (!is_struct(_choice) || _side < 0) return "";
    return _side == 0 ? _choice.a.echo : _choice.b.echo;
}

function arc_choice_label(_cat) {
    var _steps = arc_steps(_cat);
    if (array_length(_steps) < 3) return "";
    var _choice = _steps[2].choice;
    var _side = arc_branch(_cat);
    if (!is_struct(_choice) || _side < 0) return "";
    return _side == 0 ? _choice.a.label : _choice.b.label;
}

/// A stable snapshot per step, not per save. Old saves get their first
/// snapshot when the card is first opened, so no historical stat is invented.
function arc_snapshot(_cat) {
    return {
        taps: global.G.stats.clicks,
        buys: global.G.stats.purchases,
        sparkles: global.G.stats.sparkles,
        crits: global.G.stats.crits,
        service: service_total(),
        journal: global.G.journal.stamps,
        projects: arc_project_count(),
        prestige: global.G.stats.prestiges,
        fest: arc_festival_total(),
        hollow: arc_hollow_total(),
        room: global.G.rooms.mastery[cat_home_zone(_cat)]
    };
}

function arc_base(_cat) {
    if (!variable_struct_exists(global.G, "arcs") || !is_array(global.G.arcs.base)) {
        global.G.arcs = arc_defaults();
    }
    if (!is_struct(global.G.arcs.base[_cat])) {
        global.G.arcs.base[_cat] = arc_snapshot(_cat);
    }
    return global.G.arcs.base[_cat];
}

function arc_open(_cat) {
    if (_cat < 0 || _cat >= arc_count() || !album_unlocked(_cat)) return false;
    if (!arc_done(_cat)) arc_base(_cat);
    return true;
}

function arc_project_count() {
    var _n = 0;
    if (!variable_struct_exists(global.G, "journal") || !is_array(global.G.journal.projects)) return 0;
    for (var _i = 0; _i < array_length(global.G.journal.projects); _i++) {
        if (global.G.journal.projects[_i] > 0) _n += 1;
    }
    return _n;
}

function arc_festival_total() {
    var _n = 0;
    if (!variable_struct_exists(global.G, "festival") || !is_array(global.G.festival.ranks)) return 0;
    for (var _i = 0; _i < array_length(global.G.festival.ranks); _i++) _n += global.G.festival.ranks[_i];
    return _n;
}

function arc_hollow_total() {
    if (!variable_struct_exists(global.G, "occult") || !is_struct(global.G.occult.stats)) return 0;
    var _s = global.G.occult.stats;
    return _s.solves + _s.harvests + _s.halls + _s.brews;
}

function arc_metric(_cat, _kind) {
    switch (_kind) {
        case "taps":     return global.G.stats.clicks;
        case "buys":     return global.G.stats.purchases;
        case "sparkles": return global.G.stats.sparkles;
        case "crits":    return global.G.stats.crits;
        case "service":  return service_total();
        case "journal":  return global.G.journal.stamps;
        case "projects": return arc_project_count();
        case "prestige": return global.G.stats.prestiges;
        case "fest":     return arc_festival_total();
        case "hollow":   return arc_hollow_total();
        case "night":    return global.G.occult.night_best;
        case "staff_self": return staff_assigned(_cat) >= 0 ? 1 : 0;
        case "room":     return global.G.rooms.mastery[cat_home_zone(_cat)];
    }
    return 0;
}

function arc_progress(_cat) {
    var _g = arc_goal(_cat);
    if (!is_struct(_g)) return 0;
    if (_g.k == "staff_self" || _g.k == "night") return arc_metric(_cat, _g.k);
    var _base = arc_base(_cat);
    var _from = variable_struct_exists(_base, _g.k) ? _base[$ _g.k] : 0;
    return max(0, arc_metric(_cat, _g.k) - _from);
}

function arc_goal_ready(_cat) {
    var _g = arc_goal(_cat);
    return is_struct(_g) && arc_progress(_cat) >= _g.n;
}

function arc_goal_label(_cat) {
    var _g = arc_goal(_cat);
    if (!is_struct(_g)) return "";
    var _n = string(_g.n);
    switch (_g.k) {
        case "taps":     return "TAP THE CAT " + _n + " TIMES";
        case "buys":     return "BUY " + _n + " SHOP ROWS";
        case "sparkles": return "CATCH " + _n + " GOLD SPARKLES";
        case "crits":    return "LAND " + _n + " CRITICAL TAPS";
        case "service":  return "SERVE " + _n + " COUNTER DISHES";
        case "journal":  return "CLAIM " + _n + " JOURNAL GOALS";
        case "projects": return "FINISH " + _n + " JOURNAL PROJECTS";
        case "prestige": return "RESET FOR YARN " + _n + " TIMES";
        case "fest":     return "WIN " + _n + " FESTIVAL RANKS";
        case "hollow":   return "FINISH " + _n + " HOLLOW DEEDS";
        case "night":    return "REACH NIGHT DEPTH " + _n;
        case "staff_self": return "GIVE " + global.CAT[_cat].n + " A STAFF POST";
        case "room":     return "EARN " + _n + " MASTERY IN " + cat_home_name(_cat);
    }
    return "KEEP GOING";
}

function arc_step_title(_cat) {
    var _s = arc_current_step(_cat);
    return is_struct(_s) ? _s.title : "THE END";
}

function arc_step_text(_cat) {
    var _s = arc_current_step(_cat);
    return is_struct(_s) ? _s.text : "";
}

/// The bond ladder is now fed by the arc. Each completed beat sets the cat to
/// at least the matching rung, so a finished story masters that cat even if
/// the player never tapped through the numeric bond track. Existing points
/// are never reduced, and older saves keep their earned rungs.
function arc_bond_award(_cat, _rank) {
    if (_cat < 0 || _cat >= album_count()) return false;
    var _steps = cat_bond_steps();
    var _at = clamp(_rank, 1, array_length(_steps));
    return bond_award_floor(_cat, _steps[_at - 1]);
}

function arc_claim(_cat) {
    if (_cat < 0 || _cat >= arc_count() || arc_done(_cat)) return false;
    if (!arc_goal_ready(_cat)) return false;
    var _i = arc_step_index(_cat);
    var _rank = [2, 4, 6, 8, 12][_i];
    if (_i >= ARC_STEPS - 1) {
        global.G.arcs.step[_cat] = ARC_STEPS;
        global.G.arcs.done[_cat] = 1;
        if (global.G.arcs.branch[_cat] < 0) global.G.arcs.branch[_cat] = 0;
        arc_bond_award(_cat, 12);
    } else {
        global.G.arcs.step[_cat] = _i + 1;
        global.G.arcs.base[_cat] = arc_snapshot(_cat);
        arc_bond_award(_cat, _rank);
    }
    save_write();
    return true;
}

function arc_choose(_cat, _side) {
    if (_cat < 0 || _cat >= arc_count() || arc_done(_cat)) return false;
    if (_side != 0 && _side != 1) return false;
    if (arc_step_index(_cat) != 2 || !is_struct(arc_choice(_cat))) return false;
    global.G.arcs.branch[_cat] = _side;
    global.G.arcs.step[_cat] = 3;
    global.G.arcs.base[_cat] = arc_snapshot(_cat);
    arc_bond_award(_cat, 6);
    save_write();
    return true;
}

function arc_reward_data(_cat) {
    var _d = arc_data(_cat);
    return is_struct(_d) ? _d.reward : undefined;
}

/// The completed branch's keepsake effect. Returns undefined before the arc is
/// finished, so no reward can leak from an unplayed story.
function arc_perk(_cat) {
    var _r = arc_reward_data(_cat);
    if (!is_struct(_r) || !arc_done(_cat)) return undefined;
    return arc_branch(_cat) == 1 ? _r.b : _r.a;
}

function arc_perk_name(_cat) {
    var _r = arc_reward_data(_cat);
    return is_struct(_r) ? _r.name : "";
}

function arc_perk_text(_cat) {
    var _p = arc_perk(_cat);
    return is_struct(_p) ? _p.text : "";
}

// ------------------------------------------------------- reward consumers
// Each query loops the twenty-four cats. These are called at existing action
// points, once per action, not per frame.

function arc_tap_treats(_zone) {
    var _n = 0;
    for (var _c = 0; _c < arc_count(); _c++) {
        var _p = arc_perk(_c);
        if (!is_struct(_p) || _p.k != "tap_treat") continue;
        if (_p.zone >= 0 && _p.zone != _zone) continue;
        if (global.G.stats.clicks mod max(1, _p.n) == 0) _n += 1;
    }
    // Room and festival keepsakes feed the same payout points.
    return _n + venue_perk_treats("tap_treat", _zone);
}

function arc_crit_treats(_was_crit) {
    if (!_was_crit) return 0;
    var _n = 0;
    for (var _c = 0; _c < arc_count(); _c++) {
        var _p = arc_perk(_c);
        if (is_struct(_p) && _p.k == "crit_treat") _n += 1;
    }
    return _n + venue_perk_treats("crit_treat", -1);
}

function arc_spark_treats() {
    var _n = 0;
    for (var _c = 0; _c < arc_count(); _c++) {
        var _p = arc_perk(_c);
        if (is_struct(_p) && _p.k == "spark_treat") _n += 1;
    }
    return _n + venue_perk_treats("spark_treat", -1);
}

function arc_service_materials() {
    var _out = { treats: 0, scraps: 0, dust: 0 };
    for (var _c = 0; _c < arc_count(); _c++) {
        var _p = arc_perk(_c);
        if (!is_struct(_p) || _p.k != "service_treat") continue;
        if (_p.m == 1) _out.scraps += 1;
        else if (_p.m == 2) _out.dust += 1;
        else _out.treats += 1;
    }
    var _venue = venue_perk_materials();
    _out.treats += _venue.treats;
    _out.scraps += _venue.scraps;
    _out.dust += _venue.dust;
    return _out;
}

function arc_auto_treats() {
    var _n = 0;
    for (var _c = 0; _c < arc_count(); _c++) {
        var _p = arc_perk(_c);
        if (is_struct(_p) && _p.k == "auto_treat") _n += 1;
    }
    return _n + venue_perk_treats("auto_treat", -1);
}

function arc_garden_plots() {
    var _n = 0;
    for (var _c = 0; _c < arc_count(); _c++) {
        var _p = arc_perk(_c);
        if (is_struct(_p) && _p.k == "garden_plot") _n += _p.n;
    }
    return _n + venue_perk_sum("garden_plot");
}

function arc_hall_nerve() {
    var _n = 0;
    for (var _c = 0; _c < arc_count(); _c++) {
        var _p = arc_perk(_c);
        if (is_struct(_p) && _p.k == "hall_nerve") _n += _p.n;
    }
    return _n + venue_perk_sum("hall_nerve");
}

function arc_night_nerve() {
    var _n = 0;
    for (var _c = 0; _c < arc_count(); _c++) {
        var _p = arc_perk(_c);
        if (is_struct(_p) && _p.k == "night_nerve") _n += _p.n;
    }
    return _n + venue_perk_sum("night_nerve");
}

function arc_festival_discount() {
    var _n = 0;
    for (var _c = 0; _c < arc_count(); _c++) {
        var _p = arc_perk(_c);
        if (is_struct(_p) && _p.k == "festival_entry") _n += _p.n;
    }
    return _n + venue_perk_sum("festival_entry");
}

// ------------------------------------------------------------- album hook
/// The album label is the whole card modification: STORY, a step count, or
/// KEPT. The hit box and the label share this one rect.
function arc_album_rect(_r) {
    // Top-right, opposite the companion's "WITH YOU" label. The two states
    // share one card without either text landing on the other.
    return { x: _r.x + _r.w - 82, y: _r.y + 4, w: 76, h: UI_H_CONTROL };
}

function arc_album_label(_cat) {
    if (arc_done(_cat)) return "KEPT";
    if (!arc_started(_cat)) return "STORY";
    return string(arc_step_index(_cat) + 1) + "/" + string(ARC_STEPS);
}

// ---------------------------------------------------------------- card UI
function arc_ui() {
    var _c = { x: 360, y: 74, w: 1200, h: 932 };
    var _left = { x: _c.x + 48, y: _c.y + 112, w: 300, h: 760 };
    var _body = { x: _c.x + 376, y: _c.y + 112, w: 776, h: 760 };
    return {
        card: _c,
        close: { x: _c.x + _c.w - 72, y: _c.y + 24, w: UI_W_SQUARE, h: UI_H_CONTROL },
        left: _left,
        body: _body,
        portrait: { x: _left.x + 84, y: _left.y + 12, w: 132, h: 120 },
        // The keepsake copy can reach five lines. The walk control sits at the
        // bottom of the left column so it cannot cover that last line.
        companion: { x: _left.x, y: _left.y + 590,
                     w: _left.w, h: UI_H_CTA },
        claim: { x: _body.x + _body.w - 360, y: _c.y + _c.h - 104,
                 w: 360, h: UI_H_CTA },
        choice_a: { x: _body.x, y: _c.y + 496, w: _body.w, h: UI_H_CTA },
        choice_b: { x: _body.x, y: _c.y + 650, w: _body.w, h: UI_H_CTA }
    };
}

function arc_cat_sprite(_cat) {
    var _n = ["tabby", "calico", "tuxedo", "ginger",
              "grey", "snow", "mint", "rose"][album_coat(_cat)];
    return asset_get_index("spr_cat_" + _n + "_idle");
}
