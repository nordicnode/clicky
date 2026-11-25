/// @description the permanent upgrade trees, one per reset layer.
/// Every upgrade is bought with that layer's currency and never lost, so a
/// reset only ever takes away progress you are about to make again. The
/// effect of each is read through the up_* helpers below, which is the only
/// place the rest of the game should look.

// The BOOST card is 1240x920, centred on the native canvas. Kept as macros
// so a test can budget the card without opening it.
#macro BOOST_X 340
#macro BOOST_Y 96
#macro BOOST_W 1240
#macro BOOST_H 920

function up_init() {
    global.UP = [
        // ---- yarn (bought with yarn, the first layer)
        { id: "paw",     layer: 0, name: "SOFT PAWS",  desc: "+1 fish a tap",
          max: 20, base: 2,   grow: 1.30 },
        { id: "share",   layer: 0, name: "FISH SHARE", desc: "taps earn 1% more of /s",
          max: 20, base: 3,   grow: 1.32 },
        { id: "cheap",   layer: 0, name: "BARGAIN",    desc: "furniture 2% cheaper",
          max: 12, base: 4,   grow: 1.55 },
        { id: "combo",   layer: 0, name: "BIG COMBO",  desc: "+5 combo top",
          max: 10, base: 3,   grow: 1.45 },
        { id: "crit",    layer: 0, name: "SHARP CLAWS", desc: "+1.5% lucky taps",
          max: 10, base: 4,   grow: 1.50 },
        { id: "crew",    layer: 0, name: "KITTY CREW", desc: "each kitten +2%",
          max: 10, base: 5,   grow: 1.55 },
        { id: "offline", layer: 0, name: "NIGHT SHIFT", desc: "away +3% faster",
          max: 10, base: 4,   grow: 1.50 },
        { id: "frenzy",  layer: 0, name: "LONG PARTY", desc: "frenzy +2s",
          max: 5,  base: 6,   grow: 1.70 },
        { id: "head",    layer: 0, name: "HEAD START", desc: "start with 1 more box",
          max: 10, base: 5,   grow: 1.60 },
        { id: "magnet",  layer: 0, name: "SPARKLE MAG", desc: "sparkles appear +4%",
          max: 5,  base: 6,   grow: 1.70 },
        { id: "hands",   layer: 0, name: "HELPING HANDS", desc: "taps itself +1/s",
          max: 10, base: 8,   grow: 1.70 },
        { id: "luck",    layer: 0, name: "GOOD YARN",  desc: "+10% yarn a reset",
          max: 10, base: 10,  grow: 1.80 },
        { id: "stock",   layer: 0, name: "SELF-STOCK", desc: "buys a shop row for you",
          max: 5,  base: 25,  grow: 1.90 },
        { id: "tipjar",  layer: 0, name: "TIP JAR",    desc: "+5% guest tips",
          max: 8,  base: 12,  grow: 1.55 },
        { id: "linger",  layer: 0, name: "LONG GLOW",  desc: "gold sparkles last +2s",
          max: 5,  base: 9,   grow: 1.65 },

        // ---- stars
        { id: "shine",   layer: 1, name: "STARLIGHT", desc: "+15% everything",
          max: 15, base: 1,   grow: 1.40 },
        { id: "quick",   layer: 1, name: "SHORTCUT",  desc: "yarn needs 10% less",
          max: 6,  base: 3,   grow: 1.60 },
        { id: "gift",    layer: 1, name: "GIFT BOX",  desc: "start with 2 of each tier",
          max: 5,  base: 6,   grow: 1.80 },
        { id: "comet",   layer: 1, name: "COMET",     desc: "lucky taps +2x",
          max: 5,  base: 5,   grow: 1.70 },
        { id: "pockets", layer: 1, name: "DEEP POCKETS", desc: "furniture 3% cheaper",
          max: 8,  base: 4,   grow: 1.60 },
        { id: "dew",     layer: 1, name: "MORNING DEW", desc: "+15% offline speed",
          max: 6,  base: 5,   grow: 1.65 },
        { id: "halo",    layer: 1, name: "HALO",      desc: "+1 combo top",
          max: 5,  base: 8,   grow: 1.80 },
        { id: "wish",    layer: 1, name: "WISH",      desc: "+20% stars a reset",
          max: 8,  base: 6,   grow: 1.70 },
        { id: "glean",   layer: 1, name: "SPARKLE HANDS", desc: "catches gold for you",
          max: 3,  base: 20,  grow: 2.20 },

        // ---- beans
        { id: "sprout",  layer: 2, name: "SPROUT",    desc: "+25% everything",
          max: 10, base: 1,   grow: 1.45 },
        { id: "roots",   layer: 2, name: "ROOTS",     desc: "doubles come sooner",
          max: 4,  base: 3,   grow: 1.70 },
        { id: "canopy",  layer: 2, name: "CANOPY",    desc: "+4h offline cap",
          max: 4,  base: 4,   grow: 1.70 },
        { id: "bloom",   layer: 2, name: "BLOOM",     desc: "sparkles appear +100%",
          max: 4,  base: 5,   grow: 1.75 },
        { id: "stalk",   layer: 2, name: "TALL STALK", desc: "+25% beans a reset",
          max: 6,  base: 6,   grow: 1.75 },

        // ---- aurora
        { id: "glow",    layer: 3, name: "GLOW",      desc: "double fish",
          max: 5,  base: 1,   grow: 1.60 },
        { id: "sky",     layer: 3, name: "OPEN SKY",  desc: "+2 kitten per box",
          max: 5,  base: 2,   grow: 1.70 },
        { id: "dawn",    layer: 3, name: "DAWN",      desc: "every layer pays +25%",
          max: 6,  base: 3,   grow: 1.75 },
        { id: "cosmos",  layer: 3, name: "COSMOS",    desc: "+50% everything",
          max: 8,  base: 2,   grow: 1.65 },

        // ---- moon: the next reveal after the aurora
        { id: "moonbeam", layer: 4, name: "MOONBEAM", desc: "+50% everything",
          max: 10, base: 1, grow: 1.65 },
        { id: "moonlit", layer: 4, name: "MOONLIT", desc: "away +25% faster",
          max: 6, base: 2, grow: 1.70 },
        { id: "orbit", layer: 4, name: "ORBIT", desc: "every layer pays +20%",
          max: 8, base: 3, grow: 1.75 },
        { id: "crater", layer: 4, name: "CRATER", desc: "furniture 5% cheaper",
          max: 8, base: 2, grow: 1.70 }
    ];
}

function up_find(_id) {
    for (var i = 0; i < array_length(global.UP); i++) {
        if (global.UP[i].id == _id) return i;
    }
    return -1;
}

function up_level(_id) {
    if (!variable_struct_exists(global.G.up, _id)) return 0;
    return global.G.up[$ _id];
}

function up_max(_id) {
    var _i = up_find(_id);
    return (_i < 0) ? 0 : global.UP[_i].max;
}

/// A doubling price: the tenth level costs a lot, but the first is a treat.
function up_cost(_id) {
    var _i = up_find(_id);
    if (_i < 0) return 999999999;
    var _u = global.UP[_i];
    return ceil(_u.base * power(_u.grow, up_level(_id)));
}

/// How full this charm's progress strip is: 0 at level 0, 1 at max. Kept as
/// one function so the card, tests and any future screen cannot disagree.
function up_progress(_id) {
    var _i = up_find(_id);
    if (_i < 0 || global.UP[_i].max <= 0) return 0;
    return clamp(up_level(_id) / global.UP[_i].max, 0, 1);
}

function up_affordable(_id) {
    var _i = up_find(_id);
    if (_i < 0 || up_level(_id) >= global.UP[_i].max) return false;
    var _key = global.LAYER[global.UP[_i].layer].key;
    return global.G.layers[$ _key] >= up_cost(_id);
}

function up_buy(_id) {
    if (!up_affordable(_id)) return false;
    var _i = up_find(_id);
    var _key = global.LAYER[global.UP[_i].layer].key;
    var _c = up_cost(_id);
    global.G.layers[$ _key] -= _c;
    global.G.up[$ _id] = up_level(_id) + 1;
    return true;
}

/// The total price of the next `_count` levels, clamped to what is left. A
/// MAX display uses the next single level's price.
function up_bulk_cost(_id, _count) {
    var _i = up_find(_id);
    if (_i < 0) return 0;
    var _u = global.UP[_i];
    var _left = _u.max - up_level(_id);
    if (_left <= 0) return 0;
    var _n = (_count <= 0) ? 1 : min(_count, _left);
    var _total = 0;
    for (var _k = 0; _k < _n; _k++) {
        _total += ceil(_u.base * power(_u.grow, up_level(_id) + _k));
    }
    return _total;
}

function up_affordable_bulk(_id, _count) {
    var _i = up_find(_id);
    if (_i < 0 || up_level(_id) >= global.UP[_i].max) return false;
    var _key = global.LAYER[global.UP[_i].layer].key;
    if (_count <= 0) return global.G.layers[$ _key] >= up_cost(_id);
    return global.G.layers[$ _key] >= up_bulk_cost(_id, _count);
}

/// Buy a fixed batch only when the whole batch is affordable; MAX buys as
/// many levels as the held currency covers. Returns the levels bought.
function up_buy_bulk(_id, _count) {
    var _i = up_find(_id);
    if (_i < 0) return 0;
    var _u = global.UP[_i];
    var _key = global.LAYER[_u.layer].key;
    var _held = global.G.layers[$ _key];
    var _left = _u.max - up_level(_id);
    if (_left <= 0) return 0;
    var _bought = 0;
    if (_count > 0) {
        var _n = min(_count, _left);
        var _total = up_bulk_cost(_id, _n);
        if (_held < _total) return 0;
        global.G.layers[$ _key] -= _total;
        global.G.up[$ _id] = up_level(_id) + _n;
        return _n;
    }
    while (_bought < _left) {
        var _c = up_cost(_id);
        if (global.G.layers[$ _key] < _c) break;
        global.G.layers[$ _key] -= _c;
        global.G.up[$ _id] = up_level(_id) + 1;
        _bought += 1;
    }
    return _bought;
}

/// Upgrades bought with a lower currency stay bought, so the trees above them
/// are always reachable. Levels are summed across ids for the shared effects.
function up_bought(_id) {
    return up_level(_id);
}

// ---- what the rest of the game asks for --------------------------------

/// Producers get cheaper; both cheap and pockets are percentages, and they
/// multiply rather than add so neither tree can cancel the other out.
function up_cost_mult() {
    return power(0.98, up_level("cheap")) * power(0.97, up_level("pockets"))
         * power(0.95, up_level("crater"));
}

function up_flat_tap() {
    return up_level("paw");
}

function up_tap_share() {
    return up_level("share");
}

function up_combo_add() {
    return up_level("combo") * 5 + up_level("halo");
}

function up_crit_add() {
    return up_level("crit") * 0.015;
}

/// A crit pays 10x, plus 2x for every comet.
function up_crit_mult() {
    return 10 + up_level("comet") * 2;
}

function up_crew_mult() {
    // a kitten is worth more when the crew is trained
    return 1 + up_level("crew") * 0.02;
}

function up_offline_rate() {
    return (0.5 + up_level("offline") * 0.03 + up_level("dew") * 0.15
         + up_level("moonlit") * 0.25 + journal_project_count(2) * 0.05
         + global.G.journal.skills[2] * 0.10 + staff_bonus(2)
         + cat_away_add()) * era_offline_mult();
}

function up_offline_cap_h() {
    return 8 + up_level("canopy") * 4 + cat_offcap_add();
}

function up_frenzy_sec() {
    return 8 + up_level("frenzy") * 2 + cat_frenzy_add();
}

function up_frenzy_chance() {
    return 1 + up_level("bloom");
}

function up_head_start() {
    return up_level("head") + up_level("gift") * 2;
}

function up_autotap() {
    return up_level("hands");
}

function up_magnet() {
    return 1 + up_level("magnet") * 0.04;
}

/// A production multiplier from the trees, on top of the layer multiplier.
function up_rate_mult() {
    return power(1.15, up_level("shine"))
         * power(1.25, up_level("sprout"))
         * power(2.00, up_level("glow"))
         * power(1.50, up_level("cosmos"))
         * power(1.50, up_level("moonbeam"));
}

/// How much a reset pays, before the layer's own formula.
function up_gain_mult(_layer) {
    var _m = 1;
    if (_layer == 0) _m *= 1 + up_level("luck") * 0.10;
    if (_layer == 1) _m *= 1 + up_level("wish") * 0.20;
    if (_layer == 2) _m *= 1 + up_level("stalk") * 0.25;
    _m *= (1 + up_level("dawn") * 0.25) * (1 + up_level("orbit") * 0.20);
    return _m;
}

/// How much easier the next reset of a layer is. Roots pull the doubling
/// rungs in; quick shortens the yarn gate.
function up_need_mult(_layer) {
    if (_layer == 0) return power(0.90, up_level("quick"));
    return 1;
}

/// Every eighth level instead of every tenth, with roots bought.
function up_double_step(_base) {
    return max(4, _base - up_level("roots") * 1);
}

/// Automation: a self-stocker buys the best-value affordable row every few
/// seconds, and Sparkle Hands reaches for a gold sparkle on its own. Both are
/// opt-in and both stop when their charm has no levels.
function up_autostock_sec() {
    var _l = up_level("stock");
    if (_l <= 0) return 0;
    return 30 - _l * 5;
}

function up_autoglean() {
    return up_level("glean");
}

/// One purchase for SELF-STOCK: the affordable row with the fastest payback,
/// and only when the player can still afford four of it. Returns the tier it
/// bought, or -1. The clock lives in obj_game; the policy lives here.
function up_autostock_try() {
    if (up_autostock_sec() <= 0) return -1;
    var _pick = -1, _pay = 99999;
    for (var _i = 0; _i < TIER_COUNT; _i++) {
        if (!econ_unlocked(_i) || !econ_can_buy(_i)) continue;
        if (global.G.fish < econ_cost(_i) * 4) continue;
        var _p = econ_payback(_i);
        if (_p < _pay) { _pay = _p; _pick = _i; }
    }
    if (_pick < 0 || !econ_buy(_pick)) return -1;
    return _pick;
}

function up_tip_bonus() {
    return 1 + up_level("tipjar") * 0.05;
}

function up_sparkle_sec() {
    return 12 + up_level("linger") * 2;
}

/// How many upgrades the player could buy right now, for the dock's glow.
function up_any_affordable() {
    var _n = 0;
    for (var i = 0; i < array_length(global.UP); i++) {
        if (up_affordable(global.UP[i].id)) _n += 1;
    }
    return _n;
}

/// One icon per charm, so the rows read as different things rather than a
/// column of the same generic ball.
function up_icon(_id) {
    switch (_id) {
        // yarn
        case "paw":      return spr_prop_toys;
        case "share":    return spr_ui_fish_icon;
        case "cheap":    return spr_prop_jars;
        case "combo":    return spr_fx_heart;
        case "crit":     return spr_fx_sparkle;
        case "crew":     return spr_prop_bed;
        case "offline":  return spr_prop_lantern;
        case "frenzy":   return spr_prop_fount;
        case "head":     return spr_prop_box;
        case "magnet":   return spr_fx_puff;
        case "hands":    return spr_prop_mug;
        case "luck":     return spr_ui_yarn_icon;
        case "stock":    return spr_prop_post;
        case "tipjar":   return spr_prop_cake;
        case "linger":   return spr_prop_teapot;
        // stars
        case "shine":    return spr_prop_sunbeam;
        case "quick":    return spr_prop_post;
        case "gift":     return spr_prop_cake;
        case "comet":    return spr_fx_sparkle;
        case "pockets":  return spr_prop_quilt;
        case "dew":      return spr_prop_teapot;
        case "halo":     return spr_prop_aurora;
        case "wish":     return spr_fx_heart;
        case "glean":    return spr_fx_puff;
        // beans
        case "sprout":   return spr_room_plant;
        case "roots":    return spr_prop_yarnpit;
        case "canopy":   return spr_prop_quilt;
        case "bloom":    return spr_prop_fount;
        case "stalk":    return spr_prop_sunbeam;
        // aurora
        case "glow":     return spr_prop_lantern;
        case "sky":      return spr_prop_box;
        case "dawn":     return spr_prop_aurora;
        case "cosmos":   return spr_prop_sunbeam;
        // moon
        case "moonbeam": return spr_prop_sunbeam;
        case "moonlit":  return spr_prop_quilt;
        case "orbit":    return spr_ui_yarn_icon;
        case "crater":   return spr_prop_jars;
    }
    return spr_ui_yarn_icon;
}

/// The upgrades belonging to one layer, in tree order.
function up_of_layer(_layer) {
    var _out = [];
    for (var i = 0; i < array_length(global.UP); i++) {
        if (global.UP[i].layer == _layer) array_push(_out, global.UP[i]);
    }
    return _out;
}
