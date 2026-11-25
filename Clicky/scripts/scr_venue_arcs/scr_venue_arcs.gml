/// @description room and festival story arcs: state, progress and keepsakes.
///
/// One owner for the authored venue layer. It stores four small arrays under
/// global.G.venue_arcs and reads beats from scr_venue_arc_content. Nothing
/// here draws, and the only gameplay hooks are the venue_perk_* queries used
/// by the same reward consumers that already spend arc keepsakes.

#macro VA_COUNT 15
#macro VA_STEPS_MAX 4

function venue_arc_defaults() {
    return {
        step: array_create(VA_COUNT, 0),
        branch: array_create(VA_COUNT, -1),
        done: array_create(VA_COUNT, 0),
        base: array_create(VA_COUNT, 0)
    };
}

/// Additive on old saves: a save with no venue_arcs keeps the defaults, and a
/// save with partial arrays is resized without touching valid values. No
/// SAVE_VERSION migration.
function venue_arc_normalize() {
    if (!variable_struct_exists(global.G, "venue_arcs") || !is_struct(global.G.venue_arcs)) {
        global.G.venue_arcs = venue_arc_defaults();
    }
    var _v = global.G.venue_arcs;
    if (!is_array(_v.step)) _v.step = [];
    if (!is_array(_v.branch)) _v.branch = [];
    if (!is_array(_v.done)) _v.done = [];
    if (!is_array(_v.base)) _v.base = [];
    array_resize(_v.step, VA_COUNT);
    array_resize(_v.branch, VA_COUNT);
    array_resize(_v.done, VA_COUNT);
    array_resize(_v.base, VA_COUNT);
    for (var _i = 0; _i < VA_COUNT; _i++) {
        var _len = array_length(venue_arc_steps(_i));
        if (!is_numeric(_v.done[_i])) _v.done[_i] = 0;
        _v.done[_i] = _v.done[_i] > 0 ? 1 : 0;
        if (!is_numeric(_v.step[_i])) _v.step[_i] = 0;
        _v.step[_i] = clamp(floor(_v.step[_i]), 0, _len);
        if (!is_numeric(_v.branch[_i])) _v.branch[_i] = -1;
        _v.branch[_i] = clamp(floor(_v.branch[_i]), -1, 1);
        if (!is_struct(_v.base[_i])) _v.base[_i] = 0;
        if (_v.done[_i] == 1) {
            _v.step[_i] = _len;
            if (_v.branch[_i] < 0) _v.branch[_i] = 0;
        } else if (_v.branch[_i] < 0 && _v.step[_i] > venue_arc_choice_at(_i)) {
            _v.branch[_i] = 0;
        }
    }
}

function venue_arc_count() {
    return min(VA_COUNT, array_length(venue_arc_content()));
}

function venue_arc_data(_i) {
    if (_i < 0 || _i >= venue_arc_count()) return undefined;
    return venue_arc_content()[_i];
}

function venue_arc_steps(_i) {
    var _d = venue_arc_data(_i);
    return is_struct(_d) ? _d.steps : [];
}

function venue_arc_title(_i) {
    var _d = venue_arc_data(_i);
    return is_struct(_d) ? _d.title : "";
}

function venue_arc_kind(_i) {
    var _d = venue_arc_data(_i);
    return is_struct(_d) ? _d.kind : 0;
}

function venue_arc_idx(_i) {
    var _d = venue_arc_data(_i);
    return is_struct(_d) ? _d.idx : 0;
}

/// The room whose palette and name the card uses. Festivals borrow the room
/// they are held in, so the same card can show a place for both kinds.
function venue_arc_room(_i) {
    var _k = venue_arc_kind(_i);
    var _idx = venue_arc_idx(_i);
    return _k == 0 ? _idx : (_idx mod ZONE_COUNT);
}

function venue_arc_name(_i) {
    if (venue_arc_kind(_i) == 0) return zone_name(venue_arc_idx(_i));
    var _v = festival_venues();
    var _idx = venue_arc_idx(_i);
    return (_idx >= 0 && _idx < array_length(_v)) ? _v[_idx].name : "FESTIVAL";
}

function venue_arc_step_index(_i) {
    if (!variable_struct_exists(global.G, "venue_arcs")) return 0;
    if (!is_array(global.G.venue_arcs.step)) return 0;
    if (_i < 0 || _i >= array_length(global.G.venue_arcs.step)) return 0;
    return clamp(floor(global.G.venue_arcs.step[_i]), 0, array_length(venue_arc_steps(_i)));
}

function venue_arc_current_step(_i) {
    var _steps = venue_arc_steps(_i);
    var _at = venue_arc_step_index(_i);
    if (_at < 0 || _at >= array_length(_steps)) return undefined;
    return _steps[_at];
}

function venue_arc_done(_i) {
    if (!variable_struct_exists(global.G, "venue_arcs")) return false;
    if (!is_array(global.G.venue_arcs.done)) return false;
    return _i >= 0 && _i < array_length(global.G.venue_arcs.done)
        && global.G.venue_arcs.done[_i] == 1;
}

function venue_arc_branch(_i) {
    if (!variable_struct_exists(global.G, "venue_arcs")) return -1;
    if (!is_array(global.G.venue_arcs.branch)) return -1;
    if (_i < 0 || _i >= array_length(global.G.venue_arcs.branch)) return -1;
    return clamp(floor(global.G.venue_arcs.branch[_i]), -1, 1);
}

function venue_arc_started(_i) {
    return venue_arc_step_index(_i) > 0 || venue_arc_done(_i);
}

/// Rooms put the choice on the third beat and a finale after it. Festivals
/// are shorter: the choice is the middle beat and the finale closes it.
function venue_arc_choice_at(_i) {
    return venue_arc_kind(_i) == 0 ? 2 : 1;
}

/// The ask on the current beat. The step after a choice takes its goal from
/// the chosen branch, which keeps the content data-only.
function venue_arc_goal(_i) {
    var _steps = venue_arc_steps(_i);
    var _at = venue_arc_step_index(_i);
    if (_at < 0 || _at >= array_length(_steps)) return undefined;
    var _step = _steps[_at];
    if (is_struct(_step) && variable_struct_exists(_step, "goal") && is_struct(_step.goal)) {
        return _step.goal;
    }
    if (_at == venue_arc_choice_at(_i) + 1 && _at - 1 < array_length(_steps)) {
        var _choice = _steps[_at - 1].choice;
        var _side = venue_arc_branch(_i);
        if (is_struct(_choice) && _side >= 0) {
            return _side == 0 ? _choice.a.goal : _choice.b.goal;
        }
    }
    return undefined;
}

function venue_arc_choice(_i) {
    var _at = venue_arc_step_index(_i);
    var _steps = venue_arc_steps(_i);
    if (_at != venue_arc_choice_at(_i) || _at < 0 || _at >= array_length(_steps)) return undefined;
    return (variable_struct_exists(_steps[_at], "choice") && is_struct(_steps[_at].choice))
           ? _steps[_at].choice : undefined;
}

function venue_arc_choice_label(_i) {
    var _steps = venue_arc_steps(_i);
    var _at = venue_arc_choice_at(_i);
    if (!venue_arc_done(_i) || _at >= array_length(_steps)) return "";
    var _choice = _steps[_at].choice;
    var _side = venue_arc_branch(_i);
    if (!is_struct(_choice) || _side < 0) return "";
    return _side == 0 ? _choice.a.label : _choice.b.label;
}

function venue_arc_choice_echo(_i) {
    var _steps = venue_arc_steps(_i);
    var _at = venue_arc_choice_at(_i);
    if (!venue_arc_done(_i) || _at >= array_length(_steps)) return "";
    var _choice = _steps[_at].choice;
    var _side = venue_arc_branch(_i);
    if (!is_struct(_choice) || _side < 0) return "";
    return _side == 0 ? _choice.a.echo : _choice.b.echo;
}

/// Rooms open when the room is walkable. Festivals open with their venue, so
/// authored content never sits behind a threshold the player cannot see.
function venue_arc_open(_i) {
    if (_i < 0 || _i >= venue_arc_count()) return false;
    if (venue_arc_kind(_i) == 0) return venue_arc_idx(_i) <= zone_unlocked();
    return festival_venue_open(venue_arc_idx(_i));
}

function venue_arc_metric(_i, _k) {
    var _idx = venue_arc_idx(_i);
    switch (_k) {
        case "room":     return global.G.rooms.mastery[_idx];
        case "rank":     return global.G.festival.ranks[_idx];
        case "buys":     return global.G.stats.purchases;
        case "service":  return service_total();
        case "journal":  return global.G.journal.stamps;
        case "crits":    return global.G.stats.crits;
        case "sparkles": return global.G.stats.sparkles;
        case "fest":     return arc_festival_total();
        case "hollow":   return arc_hollow_total();
        case "night":    return global.G.occult.night_best;
        case "prestige": return global.G.stats.prestiges;
    }
    return 0;
}

/// Captured when the card opens and after each claim, so an ask counts work
/// done for that beat rather than the player's whole history.
function venue_arc_snapshot(_i) {
    var _idx = venue_arc_idx(_i);
    return {
        room: global.G.rooms.mastery[_idx],
        rank: global.G.festival.ranks[_idx],
        buys: global.G.stats.purchases,
        service: service_total(),
        journal: global.G.journal.stamps,
        crits: global.G.stats.crits,
        sparkles: global.G.stats.sparkles,
        fest: arc_festival_total(),
        hollow: arc_hollow_total(),
        prestige: global.G.stats.prestiges
    };
}

function venue_arc_base(_i) {
    if (!variable_struct_exists(global.G, "venue_arcs") || !is_array(global.G.venue_arcs.base)) {
        global.G.venue_arcs = venue_arc_defaults();
    }
    if (!is_struct(global.G.venue_arcs.base[_i])) {
        global.G.venue_arcs.base[_i] = venue_arc_snapshot(_i);
    }
    return global.G.venue_arcs.base[_i];
}

function venue_arc_progress(_i) {
    var _g = venue_arc_goal(_i);
    if (!is_struct(_g)) return 0;
    if (_g.k == "night") return global.G.occult.night_best;
    // A mastered festival has no ranks left to win. The branch reads as done
    // rather than dead-ending a completionist on an impossible ask.
    if (_g.k == "rank" && global.G.festival.ranks[venue_arc_idx(_i)] >= FESTIVAL_RANKS) {
        return _g.n;
    }
    var _base = venue_arc_base(_i);
    var _from = variable_struct_exists(_base, _g.k) ? _base[$ _g.k] : 0;
    return max(0, venue_arc_metric(_i, _g.k) - _from);
}

function venue_arc_goal_ready(_i) {
    var _g = venue_arc_goal(_i);
    return is_struct(_g) && venue_arc_progress(_i) >= _g.n;
}

function venue_arc_goal_label(_i) {
    var _g = venue_arc_goal(_i);
    if (!is_struct(_g)) return "";
    var _n = string(_g.n);
    switch (_g.k) {
        case "room":     return "TAP IN " + venue_arc_name(_i) + " " + _n + " TIMES";
        case "rank":     return "WIN RANK " + _n + " AT " + venue_arc_name(_i);
        case "buys":     return "BUY " + _n + " SHOP ROWS";
        case "service":  return "SERVE " + _n + " COUNTER DISHES";
        case "journal":  return "CLAIM " + _n + " JOURNAL GOALS";
        case "crits":    return "LAND " + _n + " CRITICAL TAPS";
        case "sparkles": return "CATCH " + _n + " GOLD SPARKLES";
        case "fest":     return "WIN " + _n + " FESTIVAL RANKS";
        case "hollow":   return "FINISH " + _n + " HOLLOW DEEDS";
        case "night":    return "REACH NIGHT DEPTH " + _n;
        case "prestige": return "RESET FOR YARN " + _n + " TIMES";
    }
    return "KEEP GOING";
}

function venue_arc_open_card(_i) {
    if (!venue_arc_open(_i) || venue_arc_done(_i)) return false;
    venue_arc_base(_i);
    return true;
}

/// Each finished beat pays one journal stamp, so the arc feeds an existing
/// long-term goal between its keepsake and its next ask.
function venue_arc_claim(_i) {
    if (_i < 0 || _i >= venue_arc_count() || venue_arc_done(_i)) return false;
    if (!venue_arc_goal_ready(_i)) return false;
    var _at = venue_arc_step_index(_i);
    var _len = array_length(venue_arc_steps(_i));
    global.G.journal.stamps += 1;
    if (_at >= _len - 1) {
        global.G.venue_arcs.step[_i] = _len;
        global.G.venue_arcs.done[_i] = 1;
        if (global.G.venue_arcs.branch[_i] < 0) global.G.venue_arcs.branch[_i] = 0;
    } else {
        global.G.venue_arcs.step[_i] = _at + 1;
        global.G.venue_arcs.base[_i] = venue_arc_snapshot(_i);
    }
    save_write();
    return true;
}

function venue_arc_choose(_i, _side) {
    if (_i < 0 || _i >= venue_arc_count() || venue_arc_done(_i)) return false;
    if (_side != 0 && _side != 1) return false;
    if (venue_arc_step_index(_i) != venue_arc_choice_at(_i) || !is_struct(venue_arc_choice(_i))) {
        return false;
    }
    global.G.venue_arcs.branch[_i] = _side;
    global.G.venue_arcs.step[_i] = venue_arc_choice_at(_i) + 1;
    global.G.venue_arcs.base[_i] = venue_arc_snapshot(_i);
    save_write();
    return true;
}

function venue_arc_reward(_i) {
    var _d = venue_arc_data(_i);
    return is_struct(_d) ? _d.reward : undefined;
}

function venue_arc_perk(_i) {
    var _r = venue_arc_reward(_i);
    if (!is_struct(_r) || !venue_arc_done(_i)) return undefined;
    return venue_arc_branch(_i) == 1 ? _r.b : _r.a;
}

function venue_arc_perk_name(_i) {
    var _r = venue_arc_reward(_i);
    return is_struct(_r) ? _r.name : "";
}

function venue_arc_perk_text(_i) {
    var _p = venue_arc_perk(_i);
    return is_struct(_p) ? _p.text : "";
}

// --------------------------------------------------- reward consumers
// These are called at existing action points, once per action, not per frame.
// They only report counts; the callers own the actual treat/material payout.

function venue_perk_treats(_kind, _zone) {
    var _n = 0;
    for (var _i = 0; _i < venue_arc_count(); _i++) {
        var _p = venue_arc_perk(_i);
        if (!is_struct(_p) || _p.k != _kind) continue;
        if (_zone >= 0 && _p.zone >= 0 && _p.zone != _zone) continue;
        _n += 1;
    }
    return _n;
}

function venue_perk_sum(_kind) {
    var _n = 0;
    for (var _i = 0; _i < venue_arc_count(); _i++) {
        var _p = venue_arc_perk(_i);
        if (is_struct(_p) && _p.k == _kind) _n += _p.n;
    }
    return _n;
}

function venue_perk_materials() {
    var _out = { treats: 0, scraps: 0, dust: 0 };
    for (var _i = 0; _i < venue_arc_count(); _i++) {
        var _p = venue_arc_perk(_i);
        if (!is_struct(_p) || _p.k != "service_treat") continue;
        if (_p.m == 1) _out.scraps += 1;
        else if (_p.m == 2) _out.dust += 1;
        else _out.treats += 1;
    }
    return _out;
}

// ------------------------------------------------------------- album-style
/// The label shared by the ROOMS panel and the festival card. The hit box and
/// the label use this one string, so the player only clicks what they read.
function venue_arc_label(_i) {
    if (!venue_arc_open(_i)) return "";
    if (venue_arc_done(_i)) return "KEPT";
    if (!venue_arc_started(_i)) return "STORY";
    return string(venue_arc_step_index(_i) + 1) + "/" + string(array_length(venue_arc_steps(_i)));
}

function venue_arc_ui() {
    // Same card, columns and control heights as the cat story. The venue card
    // is the same object in the same place, not a second visual language.
    return arc_ui();
}
