/// @description the whole economy. This file is the single source of truth;
/// tools/tune_layers.py mirrors this table and asserts the pacing targets.
///
/// Fourteen producers, each about ten times the last, so the shop keeps
/// opening a new row for hours instead of running out at eight.

#macro TIER_COUNT 14

function econ_init() {
    global.TIER = [
        { name: "BOX",     cost: 10,             rate: 0.5            },
        { name: "BED",     cost: 130,            rate: 5              },
        { name: "TOYS",    cost: 1400,           rate: 45             },
        { name: "POST",    cost: 12000,          rate: 340            },
        { name: "JARS",    cost: 95000,          rate: 2200           },
        { name: "FOUNT",   cost: 800000,         rate: 15000          },
        { name: "SUN",     cost: 6500000,        rate: 110000         },
        { name: "BALL",    cost: 55000000,       rate: 850000         },
        { name: "MUG",     cost: 450000000,      rate: 6500000        },
        { name: "CAKE",    cost: 3800000000,     rate: 50000000       },
        { name: "TEAPOT",  cost: 30000000000,    rate: 390000000      },
        { name: "LANTERN", cost: 240000000000,   rate: 3100000000     },
        { name: "QUILT",   cost: 2000000000000,  rate: 24000000000    },
        { name: "AURORA",  cost: 16000000000000, rate: 190000000000   }
    ];
}

/// Doubles at 10 / 20 / 40 / 80 / 120 owned: x2, x4, x8, x16, x32.
/// Roots pulls every rung in by one, because a bean buys a faster ladder.
function econ_tier_mult(_owned) {
    if (_owned >= up_double_step(120)) return 32;
    if (_owned >= up_double_step(80))  return 16;
    if (_owned >= up_double_step(40))  return 8;
    if (_owned >= up_double_step(20))  return 4;
    if (_owned >= up_double_step(10))  return 2;
    return 1;
}

/// The price of one level, at an arbitrary owned count. Kept separate so a
/// bulk purchase can add the exact ladder the player is about to climb.
function econ_cost_at(_tier, _owned) {
    return ceil(global.TIER[_tier].cost * power(1.16, _owned) * up_cost_mult());
}

function econ_cost(_tier) {
    return econ_cost_at(_tier, global.G.tiers[_tier]);
}

/// 1, 10, 100 or 0 (= buy until the fish run out). The setting lives in the
/// save so a returning player keeps the pace they chose.
function buy_count() {
    if (!variable_global_exists("G") || !variable_struct_exists(global.G, "settings")) return 1;
    var _b = global.G.settings.buy;
    return (_b == 10 || _b == 100 || _b == 0) ? _b : 1;
}

function buy_label() {
    var _b = buy_count();
    return (_b == 0) ? "MAX" : string(_b) + "x";
}

function buy_cycle() {
    var _b = buy_count();
    global.G.settings.buy = (_b == 1) ? 10 : ((_b == 10) ? 100 : ((_b == 100) ? 0 : 1));
    save_touch();
    return global.G.settings.buy;
}

function buy_normalize() {
    if (!variable_struct_exists(global.G, "settings") || !is_struct(global.G.settings)) return;
    if (!variable_struct_exists(global.G.settings, "buy")) global.G.settings.buy = 1;
    if (!variable_struct_exists(global.G.settings, "fullscreen")
        || !is_bool(global.G.settings.fullscreen)) {
        global.G.settings.fullscreen = true;
    }
    var _b = global.G.settings.buy;
    if (!is_numeric(_b) || (_b != 0 && _b != 1 && _b != 10 && _b != 100)) {
        global.G.settings.buy = 1;
    }
}

/// What a fixed batch costs. MAX has no fixed batch, so the caller shows the
/// next level's price instead.
function econ_bulk_cost(_tier, _count) {
    var _n = (_count <= 0) ? 1 : _count;
    var _total = 0;
    var _own = global.G.tiers[_tier];
    for (var _k = 0; _k < _n; _k++) _total += econ_cost_at(_tier, _own + _k);
    return _total;
}

/// Buy exactly a fixed batch (all-or-nothing, like every shop of this kind),
/// or as many as the fish can cover for MAX. Returns the number bought.
function econ_buy_bulk(_tier, _count) {
    if (_tier < 0 || _tier >= TIER_COUNT || !econ_unlocked(_tier)) return 0;
    var _bought = 0;
    if (_count > 0) {
        if (global.G.fish < econ_bulk_cost(_tier, _count)) return 0;
        for (var _k = 0; _k < _count; _k++) {
            global.G.fish -= econ_cost_at(_tier, global.G.tiers[_tier]);
            global.G.tiers[_tier] += 1;
            global.G.stats.purchases += 1;
            global.G.journal.materials.scraps += 1;
            _bought += 1;
        }
        return _bought;
    }
    // MAX: a guarded loop. The cap is only a freeze guard; by the time a
    // player can afford thousands of one row, the room is already full.
    var _guard = 0;
    while (_guard < 5000) {
        var _c = econ_cost_at(_tier, global.G.tiers[_tier]);
        if (global.G.fish < _c) break;
        global.G.fish -= _c;
        global.G.tiers[_tier] += 1;
        global.G.stats.purchases += 1;
        global.G.journal.materials.scraps += 1;
        _bought += 1;
        _guard += 1;
    }
    return _bought;
}

/// The extra base rate a batch would add, before the shared multipliers. Used
/// by the shop's hover tooltip so "10x" can state its real gain.
function econ_bulk_base_gain(_tier, _count) {
    var _n = (_count <= 0) ? 1 : _count;
    var _own = global.G.tiers[_tier];
    var _add = 0;
    for (var _k = 0; _k < _n; _k++) {
        var _o = _own + _k;
        _add += global.TIER[_tier].rate
              * ((_o + 1) * econ_tier_mult(_o + 1) - _o * econ_tier_mult(_o));
    }
    return _add;
}

/// Production before multipliers.
function econ_base_rate() {
    var _r = 0;
    for (var i = 0; i < TIER_COUNT; i++) {
        var _o = global.G.tiers[i];
        _r += global.TIER[i].rate * _o * econ_tier_mult(_o);
    }
    return _r;
}

/// Every reset layer, every tree, and the crew of kittens add their bit.
function econ_mult() {
    return layer_mult() * up_rate_mult() * kitten_mult()
         * (1 + journal_project_count(0) * 0.05 + global.G.journal.skills[0] * 0.10)
         * (1 + staff_bonus(1))
         * veil_cafe_mult()
         * room_mastery_mult()
         * cat_rate_mult();
}

/// The kittens are not just for show: with KITTY CREW bought, every one of
/// them adds a little to the whole cafe.
function kitten_mult() {
    var _lvl = up_level("crew");
    if (_lvl <= 0) return 1;
    var _cats = 0;
    for (var i = 0; i < TIER_COUNT; i++) _cats += global.G.tiers[i];
    _cats += global.G.tiers[0] * up_level("sky") * 2;
    return 1 + min(CAT_CAP, _cats) * _lvl * 0.02;
}

/// What the player sees as "+X/s". Never includes frenzy.
function econ_rate() {
    // The Era's House Rule and Legacy Perk are passive-only, so they belong
    // here and not in econ_mult(), which the tap value also reads.
    return econ_base_rate() * econ_mult() * era_rate_mult() * era_perk_rate();
}

function econ_live_rate() {
    return econ_rate() * global.frenzy;
}

function econ_tick(_dt) {
    var _gain = econ_live_rate() * _dt;
    global.G.fish += _gain;
    global.G.run_earned += _gain;
    global.G.lifetime_earned += _gain;
}

function econ_click_value() {
    var _flat  = 1 + global.G.click_upgrades.paw + up_flat_tap();
    var _share = global.G.click_upgrades.share * 0.01 + up_tap_share() * 0.01;
    return (_flat + econ_base_rate() * _share) * econ_mult()
         * (1 + journal_project_count(1) * 0.05 + global.G.journal.skills[1] * 0.10)
         * (1 + staff_bonus(0)) * era_tap_mult() * era_perk_tap();
}

function econ_can_buy(_tier) {
    return global.G.fish >= econ_cost(_tier);
}

/// A tier appears once the player has earned a quarter of its price, so the
/// shop never shows a wall of locks or a surprise first purchase.
function econ_unlocked(_tier) {
    if (_tier <= 0) return true;
    return global.G.lifetime_earned >= global.TIER[_tier].cost * 0.25;
}

/// The next owned-count that doubles this tier, or 0 once it is maxed.
function econ_next_double(_owned) {
    var _rungs = [up_double_step(10), up_double_step(20), up_double_step(40),
                  up_double_step(80), up_double_step(120)];
    for (var i = 0; i < array_length(_rungs); i++) {
        if (_owned < _rungs[i]) return _rungs[i];
    }
    return 0;
}

function econ_tier_label_pad(_tier) {
    return global.TIER[_tier].name;
}

function econ_buy(_tier) {
    var _c = econ_cost(_tier);
    if (global.G.fish < _c) return false;
    global.G.fish -= _c;
    global.G.tiers[_tier] += 1;
    global.G.stats.purchases += 1;
    global.G.journal.materials.scraps += 1;
    return true;
}

/// Kept for the old single-layer call sites: the yarn layer pays out.
function econ_yarn_gain() {
    return layer_gain(LAYER_YARN);
}

function econ_prestige() {
    return layer_reset(LAYER_YARN);
}

/// How many seconds of income a purchase takes to pay for itself.
function econ_payback(_tier) {
    var _o = global.G.tiers[_tier];
    var _add = global.TIER[_tier].rate * econ_tier_mult(_o) * econ_mult()
             * era_rate_mult() * era_perk_rate();
    if (_add <= 0) return 99999;
    return econ_cost(_tier) / _add;
}
