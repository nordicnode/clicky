/// @description save / load / merge. One struct in, one struct out.

function save_write() {
    global.G.last_seen = date_current_datetime();
    var _s = json_stringify(global.G);
    var _f = file_text_open_write(SAVE_FILE);
    file_text_write_string(_f, _s);
    file_text_close(_f);
}

/// Cheap autosave: at most once a second, for taps and purchases.
function save_touch() {
    var _now = current_time;
    if (!variable_global_exists("save_touch_t")) global.save_touch_t = 0;
    if (_now - global.save_touch_t < 1000) return;
    global.save_touch_t = _now;
    save_write();
}

/// Recursively copy known keys only, so old saves migrate and junk is ignored.
function state_merge(_target, _source) {
    if (!is_struct(_source)) return;
    var _keys = variable_struct_get_names(_source);
    for (var i = 0; i < array_length(_keys); i++) {
        var _k = _keys[i];
        if (!variable_struct_exists(_target, _k)) continue;
        var _dst = _target[$ _k];
        var _src = _source[$ _k];
        if (is_struct(_dst) && is_struct(_src)) {
            state_merge(_dst, _src);
        } else if (!is_struct(_src)) {
            _target[$ _k] = _src;
        }
    }
}

function state_load() {
    if (!file_exists(SAVE_FILE)) return false;
    var _f = file_text_open_read(SAVE_FILE);
    if (_f < 0) return false;
    var _s = "";
    while (!file_text_eof(_f)) {
        _s += file_text_read_string(_f);
        file_text_readln(_f);
    }
    file_text_close(_f);

    var _p = undefined;
    try { _p = json_parse(_s); } catch (_e) { return false; }
    if (!is_struct(_p)) return false;

    state_merge(global.G, _p);

    // Upgrade IDs are dynamic keys, so the defaults-based merge cannot copy them.
    global.G.up = {};
    if (variable_struct_exists(_p, "up") && is_struct(_p.up)) {
        for (var _i = 0; _i < array_length(global.UP); _i++) {
            var _id = global.UP[_i].id;
            if (variable_struct_exists(_p.up, _id) && is_numeric(_p.up[$ _id])) {
                global.G.up[$ _id] = clamp(floor(_p.up[$ _id]), 0, global.UP[_i].max);
            }
        }
    }
    // Migrate the original single-currency saves once, without overwriting
    // a newer save's held and lifetime totals.
    if (!variable_struct_exists(_p, "layers") && variable_struct_exists(_p, "yarn")
        && is_numeric(_p.yarn)) {
        global.G.layers.yarn = max(0, _p.yarn);
        global.G.earned.yarn = max(0, _p.yarn);
    }

    // an older save has eight producers and the table now has fourteen, so
    // grow the list rather than read past the end of it. A save from before
    // the layers existed can also hold a struct where an array belongs.
    if (!is_array(global.G.tiers)) global.G.tiers = [];
    if (!is_array(global.G.prog)) global.G.prog = [];
    var _old_layers = array_length(global.G.prog);
    array_resize(global.G.tiers, TIER_COUNT);
    array_resize(global.G.prog, LAYER_COUNT);
    // Aurora earned before Moon existed still counts toward its first unlock.
    if (_old_layers <= LAYER_MOON) global.G.prog[LAYER_MOON] = global.G.earned.aurora;

    // Each system owns its save-field migration after the generic merge.
    service_normalize();
    festival_normalize();
    staff_normalize();
    veil_normalize();
    veil_load_up(_p);
    guide_normalize();
    buy_normalize();
    era_normalize(_p);
    room_normalize();
    bond_normalize(_p);
    arc_normalize();
    venue_arc_normalize();

    if (!is_array(global.G.journal.claims)) global.G.journal.claims = [];
    if (!is_array(global.G.journal.projects)) global.G.journal.projects = [];
    if (!is_array(global.G.journal.skills)) global.G.journal.skills = [];
    if (!is_array(global.G.journal.order_active)) global.G.journal.order_active = [];
    if (!is_array(global.G.journal.order_chapter)) global.G.journal.order_chapter = [];
    if (!is_array(global.G.journal.order_start)) global.G.journal.order_start = [];
    array_resize(global.G.journal.order_active, 3);
    array_resize(global.G.journal.order_chapter, 3);
    array_resize(global.G.journal.order_start, 3);
    array_resize(global.G.journal.claims, JOURNAL_CHAPTERS * 4);
    array_resize(global.G.journal.projects, JOURNAL_CHAPTERS * 3);
    array_resize(global.G.journal.skills, 3);
    // Existing saves did not count lifetime purchases. Preserve a conservative
    // minimum based on currently owned furniture; never invent past sparkles.
    if (!variable_struct_exists(_p, "stats") || !is_struct(_p.stats)
        || !variable_struct_exists(_p.stats, "purchases")) {
        global.G.stats.purchases = 0;
        for (var _i = 0; _i < TIER_COUNT; _i++) global.G.stats.purchases += global.G.tiers[_i];
    }
    return true;
}

function state_reset() {
    if (file_exists(SAVE_FILE)) file_delete(SAVE_FILE);
    state_defaults();
}

/// Seconds since last save, clamped. Returns 0 on a brand-new save.
function offline_seconds() {
    if (global.G.last_seen <= 0) return 0;
    var _sec = date_second_span(global.G.last_seen, date_current_datetime());
    if (_sec < 60) return 0;
    return min(_sec, up_offline_cap_h() * 3600);
}

/// Offline pays half rate. Uses producer rate only (no frenzy, no combo).
function offline_apply() {
    global.offline_s = offline_seconds();
    global.offline_gain = 0;
    if (global.offline_s <= 0) return 0;
    var _gain = econ_rate() * global.offline_s * up_offline_rate();
    global.offline_gain = _gain;
    global.G.fish += _gain;
    global.G.run_earned += _gain;
    global.G.lifetime_earned += _gain;
    return _gain;
}
