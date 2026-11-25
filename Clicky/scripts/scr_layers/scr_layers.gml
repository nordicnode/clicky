/// @description the reset layers: yarn, stars, beans, aurora and moon.
/// Each one pays a currency for giving up the layer below, and each currency
/// both multiplies production (by how much has ever been earned) and buys a
/// permanent upgrade tree (from how much is still held). The numbers here are
/// the same ones tools/tune_layers.py simulates; change both together.

#macro LAYER_YARN   0
#macro LAYER_STARS  1
#macro LAYER_BEANS  2
#macro LAYER_AURORA 3
#macro LAYER_MOON   4
#macro LAYER_COUNT  5

function layer_init() {
    global.LAYER = [
        { key: "yarn",   name: "YARN",   title: "YARN TIME?",
          need: 600000000,  pay: 20000000,  per: 0.10,
          blurb: "+10% per yarn" },
        { key: "stars",  name: "STARS",  title: "STAR TIME?",
          need: 14,         pay: 4,         per: 0.25,
          blurb: "+25% per star" },
        { key: "beans",  name: "BEANS",  title: "BEAN TIME?",
          need: 4,          pay: 2,         per: 0.50,
          blurb: "+50% per bean" },
        { key: "aurora", name: "AURORA", title: "AURORA TIME?",
          need: 3,          pay: 2,         per: 1.00,
          blurb: "+100% per aurora" },
        { key: "moon",   name: "MOON",   title: "MOON TIME?",
          need: 25,         pay: 8,         per: 1.50,
          blurb: "+150% per moon" }
    ];
}

/// The progress that feeds a layer: the run for yarn, then the currency the
/// layer below has paid since this layer last reset.
function layer_src(_i) {
    if (_i == 0) return global.G.run_earned;
    return global.G.prog[_i];
}

/// What a reset would pay right now, or 0 if it is not worth one yet.
function layer_gain(_i) {
    if (_i < 0 || _i >= LAYER_COUNT) return 0;
    var _src = layer_src(_i);
    if (_src < global.LAYER[_i].need * up_need_mult(_i)) return 0;
    var _g = floor(power(_src / global.LAYER[_i].pay, 0.5) * up_gain_mult(_i));
    return max(1, _g);
}

function layer_can(_i) {
    return layer_gain(_i) > 0;
}

/// Lifetime earnings drive the multiplier, so spending currency on upgrades
/// never makes the cafe slower. That would feel like a punishment.
function layer_mult() {
    var _m = 1;
    for (var i = 0; i < LAYER_COUNT; i++) {
        _m *= 1 + global.G.earned[$ global.LAYER[i].key] * global.LAYER[i].per;
    }
    return _m;
}

/// One reset: pay the currency, forget the layers below, count the payout as
/// progress for the layer above so the next peel is closer.
function layer_reset(_i) {
    var _g = layer_gain(_i);
    if (_g <= 0) return 0;
    var _key = global.LAYER[_i].key;
    global.G.layers[$ _key] += _g;
    global.G.earned[$ _key] += _g;

    global.G.fish = 0;
    global.G.run_earned = 0;
    global.G.tiers = array_create(TIER_COUNT, up_level("gift") * 2);
    global.G.tiers[0] += up_level("head");
    with (obj_cat_mini) instance_destroy();
    global.G.click_upgrades = { paw: 0, share: 0 };
    global.G.stats.prestiges += 1;

    // everything below this layer starts again
    for (var j = 0; j < _i; j++) {
        global.G.layers[$ global.LAYER[j].key] = 0;
        global.G.prog[j] = 0;
    }
    global.G.prog[_i] = 0;
    if (_i + 1 < LAYER_COUNT) global.G.prog[_i + 1] += _g;

    // a first reset of any layer is a moment: hats mark the yarn ladder
    if (_i == 0) {
        var _ladder = [[1, "beanie"], [5, "crown"], [15, "wizard"]];
        for (var k = 0; k < array_length(_ladder); k++) {
            if (global.G.earned.yarn >= _ladder[k][0]) {
                var _h = _ladder[k][1];
                if (!array_contains(global.G.hats, _h)) {
                    array_push(global.G.hats, _h);
                    global.G.equipped_hat = _h;
                }
            }
        }
    }
    save_write();
    return _g;
}

/// How much of the way to the next reset, for the progress bars.
function layer_progress(_i) {
    return clamp(layer_src(_i) / (global.LAYER[_i].need * up_need_mult(_i)), 0, 1);
}

/// The deepest layer the player has ever opened, for the dock and the cards.
function layer_unlocked(_i) {
    if (_i == 0) return global.G.earned.yarn > 0 || global.G.run_earned >= 100000;
    return global.G.earned[$ global.LAYER[_i - 1].key] > 0;
}

// ================================================================ CAFÉ ERAS
// The chapter after the first MOON. Each era names a featured room, asks for
// three concrete deeds that reuse the systems already in the game, and lets
// the player pick one House Rule that changes how that era's runs play. A seal
// is permanent: it pays a small Legacy Perk and opens the next era.
//
// Renown is a progress score, not a currency. It is never spent.
#macro ERA_COUNT 6
#macro ERA_RULE_COUNT 3

function era_defaults() {
    return {
        index: 0, sealed: 0, renown: 0, rule: -1,
        // Every deed is measured from the moment its era opened. A late save
        // that had no Eras starts from its current totals, not from zero.
        base: { resets: 0, taps: 0, served: 0, ranks: 0, found: 0,
                solves: 0, halls: 0, brews: 0, night: 0 }
    };
}

function era_list() {
    return [
        { name: "THE FIRST TABLE", room: 0,
          deeds: [ { kind: "reset", target: 20, label: "RESETS" },
                   { kind: "tap",   target: 800, label: "TAPS" },
                   { kind: "serve", target: 12, label: "DISHES SERVED" } ] },
        { name: "GARDEN PARTY", room: 1,
          deeds: [ { kind: "reset", target: 25, label: "RESETS" },
                   { kind: "tap",   target: 1500, label: "TAPS" },
                   { kind: "rank",  target: 6, label: "FESTIVAL RANKS" } ] },
        { name: "ROOFTOP HOUR", room: 2,
          deeds: [ { kind: "reset",  target: 25, label: "RESETS" },
                   { kind: "found",  target: 1, label: "FIND THE HOLLOW" },
                   { kind: "solves", target: 4, label: "SEANCE SOLVES" } ] },
        { name: "CLOUD SERVICE", room: 3,
          deeds: [ { kind: "serve", target: 15, label: "DISHES SERVED" },
                   { kind: "halls", target: 6, label: "HALL FLOORS" },
                   { kind: "rank",  target: 6, label: "FESTIVAL RANKS" } ] },
        { name: "TEA CEREMONY", room: 4,
          deeds: [ { kind: "solves", target: 6, label: "SEANCE SOLVES" },
                   { kind: "halls",  target: 6, label: "HALL FLOORS" },
                   { kind: "reset",  target: 30, label: "RESETS" } ] },
        { name: "STARRY NIGHT", room: 5,
          deeds: [ { kind: "night", target: 6, label: "NIGHT RUNS" },
                   { kind: "rank",  target: 8, label: "FESTIVAL RANKS" },
                   { kind: "reset", target: 40, label: "RESETS" } ] }
    ];
}

function era_rules() {
    return [
        { name: "HUSTLE", blurb: "Taps x2. Passive -20%." },
        { name: "STEADY", blurb: "Passive +25%. Taps -25%." },
        { name: "NIGHT",  blurb: "Hollow +25%, away +25%, /s -10%." }
    ];
}

/// The first moon is the gate. A save that has never reset that deep simply
/// has no Era tab, which keeps the first two hours uncluttered.
function era_unlocked() {
    return global.G.earned.moon > 0;
}

function era_cur() {
    if (!variable_struct_exists(global.G, "eras")) return 0;
    return clamp(global.G.eras.index, 0, ERA_COUNT - 1);
}

function era_all_sealed() {
    if (!variable_struct_exists(global.G, "eras")) return false;
    return global.G.eras.sealed >= ERA_COUNT;
}

function era_featured_room() {
    if (!era_unlocked()) return -1;
    if (era_all_sealed()) return era_list()[ERA_COUNT - 1].room;
    return era_list()[era_cur()].room;
}

/// Current totals, in the same shape as the base snapshot. Every one of these
/// only goes up, so a deed's progress can never become negative.
function era_snapshot() {
    var _o = global.G.occult;
    var _ranks = 0;
    for (var _i = 0; _i < array_length(global.G.festival.ranks); _i++) {
        _ranks += global.G.festival.ranks[_i];
    }
    return {
        resets: global.G.stats.prestiges,
        taps: global.G.stats.clicks,
        served: service_total(),
        ranks: _ranks,
        found: _o.found ? 1 : 0,
        solves: _o.stats.solves,
        halls: _o.stats.floors,
        brews: _o.stats.brews,
        night: _o.stats.nights
    };
}

function era_stat_total(_kind) {
    var _s = era_snapshot();
    if (variable_struct_exists(_s, _kind)) return _s[$ _kind];
    return 0;
}

/// Deed kinds are singular verbs; the snapshot uses the counters that already
/// exist. Keep the translation in one place so a new deed cannot silently read
/// a missing key and report zero progress.
function era_stat_key(_kind) {
    switch (_kind) {
        case "reset": return "resets";
        case "tap":   return "taps";
        case "serve": return "served";
        case "rank":  return "ranks";
    }
    return _kind;
}

function era_deed_value(_era, _slot) {
    var _list = era_list();
    if (_era < 0 || _era >= ERA_COUNT) return 0;
    if (_slot < 0 || _slot >= 3) return 0;
    var _key = era_stat_key(_list[_era].deeds[_slot].kind);
    var _base = 0;
    if (variable_struct_exists(global.G.eras.base, _key)) {
        _base = global.G.eras.base[$ _key];
    }
    return max(0, era_stat_total(_key) - _base);
}

function era_deed_done(_era, _slot) {
    var _list = era_list();
    if (_era < 0 || _era >= ERA_COUNT) return false;
    return era_deed_value(_era, _slot) >= _list[_era].deeds[_slot].target;
}

function era_deeds_done(_era) {
    var _n = 0;
    for (var _i = 0; _i < 3; _i++) {
        if (era_deed_done(_era, _i)) _n += 1;
    }
    return _n;
}

function era_ready() {
    return era_unlocked() && !era_all_sealed() && global.G.eras.rule >= 0
        && era_deeds_done(era_cur()) == 3;
}

function era_choose_rule(_i) {
    if (_i < 0 || _i >= ERA_RULE_COUNT) return false;
    if (!era_unlocked() || era_all_sealed()) return false;
    global.G.eras.rule = _i;
    save_write();
    return true;
}

/// One seal: pay a permanent Legacy Perk, reset the deed baseline and move to
/// the next era. Nothing in the cafe is wiped; this is a chapter, not a reset.
function era_seal() {
    if (!era_ready()) return false;
    var _e = era_cur();
    global.G.eras.sealed += 1;
    global.G.eras.renown += 1;
    global.G.eras.index = min(ERA_COUNT, global.G.eras.index + 1);
    global.G.eras.rule = -1;
    global.G.eras.base = era_snapshot();
    save_write();
    return true;
}

/// The perk the next seal will pay, and the one already paid. Kept small and
/// permanent so an Era never competes with the layer multiplier.
function era_perk_name(_n) {
    switch (_n) {
        case 0: return "+5% PASSIVE";
        case 1: return "+5% TAPS";
        case 2: return "+10% HOLLOW";
        case 3: return "+5% PASSIVE";
        case 4: return "+5% PASSIVE";
        case 5: return "+10% ALL";
    }
    return "";
}

function era_perk_rate() {
    if (!variable_struct_exists(global.G, "eras")) return 1;
    var _n = global.G.eras.sealed;
    var _m = 1;
    if (_n >= 1) _m *= 1.05;
    if (_n >= 4) _m *= 1.05;
    if (_n >= 5) _m *= 1.05;
    if (_n >= 6) _m *= 1.10;
    return _m;
}

function era_perk_tap() {
    if (!variable_struct_exists(global.G, "eras")) return 1;
    return global.G.eras.sealed >= 2 ? 1.05 : 1;
}

function era_perk_ember() {
    if (!variable_struct_exists(global.G, "eras")) return 1;
    return global.G.eras.sealed >= 3 ? 1.10 : 1;
}

/// House Rules only apply while their era is open. Sealing clears the rule,
/// so the next era starts from a clean choice. The Legacy Perk stays.
function era_rate_mult() {
    if (!era_unlocked() || era_all_sealed()) return 1;
    var _r = global.G.eras.rule;
    if (_r == 0) return 0.80;
    if (_r == 1) return 1.25;
    if (_r == 2) return 0.90;
    return 1;
}

function era_tap_mult() {
    if (!era_unlocked() || era_all_sealed()) return 1;
    var _r = global.G.eras.rule;
    if (_r == 0) return 2.00;
    if (_r == 1) return 0.75;
    if (_r == 2) return 1.00;
    return 1;
}

function era_offline_mult() {
    if (!era_unlocked() || era_all_sealed()) return 1;
    return global.G.eras.rule == 2 ? 1.25 : 1;
}

function era_ember_mult() {
    if (!era_unlocked() || era_all_sealed()) return 1;
    return global.G.eras.rule == 2 ? 1.25 : 1;
}

/// Old saves arrive without an eras struct. If the save predates Eras, the
/// first era starts from today, so a late player is not handed a checklist
/// they finished years ago.
function era_normalize(_source) {
    if (!variable_struct_exists(global.G, "eras") || !is_struct(global.G.eras)) {
        global.G.eras = era_defaults();
        global.G.eras.base = era_snapshot();
        return;
    }
    var _e = global.G.eras;
    if (!variable_struct_exists(_e, "index") || !is_numeric(_e.index)) _e.index = 0;
    if (!variable_struct_exists(_e, "sealed") || !is_numeric(_e.sealed)) _e.sealed = 0;
    if (!variable_struct_exists(_e, "renown") || !is_numeric(_e.renown)) _e.renown = 0;
    if (!variable_struct_exists(_e, "rule") || !is_numeric(_e.rule)) _e.rule = -1;
    _e.index = clamp(floor(_e.index), 0, ERA_COUNT);
    _e.sealed = clamp(floor(_e.sealed), 0, ERA_COUNT);
    _e.renown = max(0, floor(_e.renown));
    _e.rule = clamp(floor(_e.rule), -1, ERA_RULE_COUNT - 1);
    if (!variable_struct_exists(_e, "base") || !is_struct(_e.base)) _e.base = era_defaults().base;
    var _keys = variable_struct_get_names(era_defaults().base);
    for (var _i = 0; _i < array_length(_keys); _i++) {
        var _k = _keys[_i];
        if (!variable_struct_exists(_e.base, _k) || !is_numeric(_e.base[$ _k])) {
            _e.base[$ _k] = 0;
        } else {
            _e.base[$ _k] = max(0, _e.base[$ _k]);
        }
    }
    // An old save had no eras key at all; state_merge already installed the
    // defaults above, so only a source that claims eras but has no base needs
    // the catch-up snapshot.
    if (is_struct(_source) && !variable_struct_exists(_source, "eras")) {
        _e.base = era_snapshot();
    }
}
