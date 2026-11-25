/// @description the cat album: twenty-four cats, and what finds each one

function album_init() {
    global.CAT = [
        { n: "Mochi",   l: "sleeps in the sink",      at: 0 },
        { n: "Biscuit", l: "sits on warm laptops",    at: 25 },
        { n: "Pepper",  l: "chases the dot forever",  at: 120 },
        { n: "Tofu",    l: "bonks everything gently", at: 400 },
        { n: "Pickle",  l: "hides in boxes",          at: 1200 },
        { n: "Momo",    l: "yells at birds",          at: 3000 },
        { n: "Sardine", l: "smells like the sea",     at: 8000 },
        { n: "Noodle",  l: "climbs the curtains",     at: 20000 },
        { n: "Bean",    l: "sleeps in the garden",    at: 40000 },
        { n: "Waffle",  l: "steals warm bread",       at: 80000 },
        { n: "Clover",  l: "brings lucky leaves",     at: 150000 },
        { n: "Pudding", l: "jiggles when happy",      at: 300000 },
        { n: "Comet",   l: "races the pigeons",       at: 500000 },
        { n: "Marlow",  l: "guards the rooftop",      at: 800000 },
        { n: "Saffron", l: "suns in the window",      at: 1200000 },
        { n: "Kiwi",    l: "is small but loud",       at: 1800000 },
        { n: "Olive",   l: "reads over your shoulder", at: 2600000 },
        { n: "Puff",    l: "made of warm clouds",     at: 3500000 },
        { n: "Star",    l: "only naps at night",      at: 5000000 },
        { n: "Clementine", l: "shares her snacks",    at: 7500000 },
        { n: "Dumpling", l: "folds into a loaf",      at: 12000000 },
        { n: "Marmalade", l: "wears orange stripes",  at: 20000000 },
        { n: "Wisp",    l: "drifts between naps",     at: 35000000 },
        { n: "Big Boss", l: "runs the whole cafe",    at: 55000000 }
    ];
}

function album_count() { return array_length(global.CAT); }

function album_unlocked(_i) {
    return global.G.lifetime_earned >= global.CAT[_i].at;
}

function album_unlocked_count() {
    var _c = 0;
    for (var i = 0; i < album_count(); i++) if (album_unlocked(i)) _c++;
    return _c;
}

/// A coat index for the card portrait, cycled so the grid never looks flat.
/// Eight coats match the eight paper-doll sprites; a cat met late is visibly
/// a different animal rather than a recolored duplicate.
function album_coat(_i) {
    return _i mod 8;
}

// ---------------------------------------------------------------- bonds
// Every cat has its own 12-rung bond. Points come from tapping anywhere, but
// a tap in the cat's home room is worth double. Rungs are trait-specific, so
// two SUNNY cats are not the same prize, and the active companion is the cat
// whose rungs are live right now.
#macro CAT_BOND_MAX 12

/// Cat bond state and the active companion belong to this file. room_defaults()
/// no longer creates either, so there is one owner for each piece of state.
function bond_defaults() {
    return array_create(album_count(), 0);
}

/// Resize/normalize bonds and move the old rooms.bonds / rooms.companion
/// fields out of saves written before the split. New saves win if both exist.
function bond_normalize(_p) {
    if (!is_array(global.G.bonds)) global.G.bonds = bond_defaults();
    array_resize(global.G.bonds, album_count());
    for (var _i = 0; _i < album_count(); _i++) {
        if (!is_numeric(global.G.bonds[_i])) global.G.bonds[_i] = 0;
        global.G.bonds[_i] = max(0, global.G.bonds[_i]);
    }

    var _new_bonds = is_struct(_p) && variable_struct_exists(_p, "bonds")
                  && is_array(_p.bonds);
    if (!_new_bonds && is_struct(_p) && variable_struct_exists(_p, "rooms")
        && is_struct(_p.rooms) && variable_struct_exists(_p.rooms, "bonds")
        && is_array(_p.rooms.bonds)) {
        for (var _o = 0; _o < min(album_count(), array_length(_p.rooms.bonds)); _o++) {
            if (is_numeric(_p.rooms.bonds[_o])) {
                global.G.bonds[_o] = max(0, _p.rooms.bonds[_o]);
            }
        }
    }

    var _new_comp = is_struct(_p) && variable_struct_exists(_p, "companion");
    var _comp = _new_comp ? global.G.companion : 0;
    if (!_new_comp && is_struct(_p) && variable_struct_exists(_p, "rooms")
        && is_struct(_p.rooms) && variable_struct_exists(_p.rooms, "companion")) {
        _comp = _p.rooms.companion;
    }
    if (!is_numeric(_comp) || _comp < 0 || _comp >= album_count()
        || !album_unlocked(_comp)) _comp = 0;
    global.G.companion = _comp;
}

function cat_bond_steps() {
    static _s = [20, 60, 140, 280, 500, 850, 1350, 2050, 3000, 4300, 6000, 8200];
    return _s;
}

function cat_home_zone(_cat) {
    return _cat mod ZONE_COUNT;
}

/// A short home label for the 233px card; the full room name is in ROOMS.
function cat_home_name(_cat) {
    static _n = ["CORNER", "GARDEN", "ROOFTOP", "CLOUD", "TEA", "LIBRARY"];
    return _n[cat_home_zone(_cat)];
}

function cat_bond_rank(_cat) {
    if (!variable_struct_exists(global.G, "bonds") || !is_array(global.G.bonds)) return 0;
    if (_cat < 0 || _cat >= array_length(global.G.bonds)) return 0;
    var _pts = global.G.bonds[_cat];
    var _steps = cat_bond_steps();
    var _r = 0;
    for (var _i = 0; _i < array_length(_steps); _i++) {
        if (_pts >= _steps[_i]) _r = _i + 1;
    }
    return _r;
}

/// Progress toward the next bond rung, 0..1.
function cat_bond_progress(_cat) {
    if (_cat < 0 || _cat >= album_count()) return 0;
    if (!variable_struct_exists(global.G, "bonds") || !is_array(global.G.bonds)
        || _cat >= array_length(global.G.bonds)) return 0;
    var _r = cat_bond_rank(_cat);
    if (_r >= CAT_BOND_MAX) return 1;
    var _steps = cat_bond_steps();
    var _pts = global.G.bonds[_cat];
    var _from = (_r == 0) ? 0 : _steps[_r - 1];
    return clamp((_pts - _from) / max(1, _steps[_r] - _from), 0, 1);
}

/// Every tap feeds the active companion. Home-room taps count double, and a
/// mastered room's BOND rungs stretch every point further.
function cat_bond_add(_cat, _z) {
    if (_cat < 0 || _cat >= album_count()) return;
    if (!album_unlocked(_cat)) return;
    if (!variable_struct_exists(global.G, "bonds") || !is_array(global.G.bonds)) {
        global.G.bonds = bond_defaults();
    }
    if (_cat >= array_length(global.G.bonds)) return;
    var _add = (cat_home_zone(_cat) == _z) ? 2 : 1;
    _add *= room_bond_mult(_z);
    global.G.bonds[_cat] += _add;
}

/// A story beat is an earned floor, not a tap substitute: it raises a cat to
/// the rung the beat represents and never lowers a player's existing bond.
function bond_award_floor(_cat, _points) {
    if (_cat < 0 || _cat >= album_count()) return false;
    if (!variable_struct_exists(global.G, "bonds") || !is_array(global.G.bonds)) {
        global.G.bonds = bond_defaults();
    }
    array_resize(global.G.bonds, album_count());
    if (!is_numeric(global.G.bonds[_cat])) global.G.bonds[_cat] = 0;
    global.G.bonds[_cat] = max(global.G.bonds[_cat], _points);
    return true;
}

function room_companion() {
    if (!variable_struct_exists(global.G, "companion")) return 0;
    var _c = global.G.companion;
    if (!is_numeric(_c) || _c < 0 || _c >= album_count() || !album_unlocked(_c)) return 0;
    return _c;
}

function room_companion_set(_cat) {
    if (_cat < 0 || _cat >= album_count() || !album_unlocked(_cat)) return false;
    global.G.companion = _cat;
    save_write();
    return true;
}

/// The rung's card. Each trait has a distinct table; the rank is 1-based.
function cat_bond_table(_trait) {
    static _t = [
        [ // SUNNY: tempo and combo rules, with tap percentages as filler
            { n: "COMBO +1", k: "combo", v: 1 },
            { n: "TAP +1%", k: "tap", v: 1 },
            { n: "PET 5: +1 COMBO", k: "combo5", v: 1 },
            { n: "TAP +1%", k: "tap", v: 1 },
            { n: "COMBO +100MS", k: "grace", v: 100 },
            { n: "TAP +2%", k: "tap", v: 2 },
            { n: "CRITS +1 COMBO", k: "critcombo", v: 1 },
            { n: "TAP +2%", k: "tap", v: 2 },
            { n: "COMBO +100MS", k: "grace", v: 100 },
            { n: "TAP +3%", k: "tap", v: 3 },
            { n: "COMBO +1", k: "combo", v: 1 },
            { n: "COMBO NEVER FADES", k: "endless", v: 1 }
        ],
        [ // NIGHT: nerve, peek and relic rules, with embers as filler
            { n: "HALL NERVE +1", k: "nerve", v: 1 },
            { n: "EMBERS +1%", k: "ember", v: 1 },
            { n: "PEEK -1", k: "peek", v: 1 },
            { n: "EMBERS +1%", k: "ember", v: 1 },
            { n: "HALL NERVE +1", k: "nerve", v: 1 },
            { n: "EMBERS +2%", k: "ember", v: 2 },
            { n: "PEEK -1", k: "peek", v: 1 },
            { n: "EMBERS +2%", k: "ember", v: 2 },
            { n: "HALL NERVE +1", k: "nerve", v: 1 },
            { n: "EMBERS +3%", k: "ember", v: 3 },
            { n: "PEEK -1", k: "peek", v: 1 },
            { n: "RELICS +5%", k: "relic", v: 5 }
        ],
        [ // COZY: offline-cap rules, with away percentages as filler
            { n: "CAP +1H", k: "offcap", v: 1 },
            { n: "AWAY +1%", k: "away", v: 1 },
            { n: "CAP +1H", k: "offcap", v: 1 },
            { n: "AWAY +1%", k: "away", v: 1 },
            { n: "CAP +2H", k: "offcap", v: 2 },
            { n: "AWAY +2%", k: "away", v: 2 },
            { n: "CAP +2H", k: "offcap", v: 2 },
            { n: "AWAY +2%", k: "away", v: 2 },
            { n: "CAP +3H", k: "offcap", v: 3 },
            { n: "AWAY +3%", k: "away", v: 3 },
            { n: "CAP +3H", k: "offcap", v: 3 },
            { n: "AWAY +5%", k: "away", v: 5 }
        ],
        [ // BUSY: staff-match rules, with staff/output percentages as filler
            { n: "STAFF +1%", k: "staff", v: 1 },
            { n: "OUTPUT +1%", k: "rate", v: 1 },
            { n: "MATCH BONUS +25%", k: "match", v: 0.25 },
            { n: "OUTPUT +1%", k: "rate", v: 1 },
            { n: "STAFF +2%", k: "staff", v: 2 },
            { n: "MATCH BONUS +25%", k: "match", v: 0.25 },
            { n: "OUTPUT +2%", k: "rate", v: 2 },
            { n: "STAFF +2%", k: "staff", v: 2 },
            { n: "MATCH BONUS +25%", k: "match", v: 0.25 },
            { n: "OUTPUT +2%", k: "rate", v: 2 },
            { n: "STAFF +3%", k: "staff", v: 3 },
            { n: "MATCH BONUS +50%", k: "match", v: 0.5 }
        ],
        [ // DREAMY: frenzy/crit-combo rules, with crit percentages as filler
            { n: "CRIT +1%", k: "crit", v: 1 },
            { n: "CRIT +0.5%", k: "crit", v: 0.5 },
            { n: "CRIT PAY +10%", k: "critpay", v: 10 },
            { n: "FRENZY +1S", k: "frenzy", v: 1 },
            { n: "CRIT +1%", k: "crit", v: 1 },
            { n: "CRITS +1 COMBO", k: "critcombo", v: 1 },
            { n: "CRIT PAY +10%", k: "critpay", v: 10 },
            { n: "CRIT +1%", k: "crit", v: 1 },
            { n: "FRENZY +1S", k: "frenzy", v: 1 },
            { n: "CRIT +1.5%", k: "crit", v: 1.5 },
            { n: "CRIT PAY +15%", k: "critpay", v: 15 },
            { n: "CRITS +1 COMBO", k: "critcombo", v: 1 }
        ],
        [ // HUNGRY: the garden
            { n: "PET 20: +1 TREAT", k: "treat", v: 20 },
            { n: "GROWTH +2%", k: "growth", v: 2 },
            { n: "PET 15: +1 TREAT", k: "treat", v: 15 },
            { n: "GROWTH +2%", k: "growth", v: 2 },
            { n: "HARVEST +1 REAGENT", k: "harvest", v: 1 },
            { n: "PET 12: +1 TREAT", k: "treat", v: 12 },
            { n: "GROWTH +2%", k: "growth", v: 2 },
            { n: "HARVEST +1 REAGENT", k: "harvest", v: 1 },
            { n: "PET 10: +1 TREAT", k: "treat", v: 10 },
            { n: "GROWTH +3%", k: "growth", v: 3 },
            { n: "HARVEST +1 REAGENT", k: "harvest", v: 1 },
            { n: "PET 5: +1 TREAT", k: "treat", v: 5 }
        ]
    ];
    return _t[clamp(_trait, 0, 5)];
}

function cat_bond_rung(_cat, _rank) {
    if (_cat < 0 || _cat >= album_count()) return undefined;
    var _t = cat_bond_table(staff_trait(_cat));
    return _t[clamp(_rank, 1, CAT_BOND_MAX) - 1];
}

/// Sum one effect kind across the active companion's unlocked rungs. Effects
/// that are intervals (treat) or one-shot rules use the dedicated helpers.
function cat_bond_active_sum(_kind) {
    var _c = room_companion();
    if (_c < 0) return 0;
    var _r = cat_bond_rank(_c);
    var _t = cat_bond_table(staff_trait(_c));
    var _s = 0;
    for (var _i = 0; _i < _r; _i++) {
        if (_t[_i].k == _kind) _s += _t[_i].v;
    }
    return _s;
}

function cat_bond_min_active(_kind) {
    var _c = room_companion();
    if (_c < 0) return 0;
    var _r = cat_bond_rank(_c);
    var _t = cat_bond_table(staff_trait(_c));
    var _best = 0;
    for (var _i = 0; _i < _r; _i++) {
        if (_t[_i].k != _kind) continue;
        if (_best == 0 || _t[_i].v < _best) _best = _t[_i].v;
    }
    return _best;
}

/// One rung of a specific trait, for copy and for the active-cat checks.
function cat_bond_trait_rank(_trait, _rank) {
    var _c = room_companion();
    return (_c >= 0) && (staff_trait(_c) == _trait) && (cat_bond_rank(_c) >= _rank);
}

function cat_tap_mult()        { return 1 + cat_bond_active_sum("tap") * 0.01; }
function cat_rate_mult()       { return 1 + cat_bond_active_sum("rate") * 0.01; }
function cat_away_add()        { return cat_bond_active_sum("away") * 0.01; }
function cat_offcap_add()      { return cat_bond_active_sum("offcap"); }
function cat_ember_mult()      { return 1 + cat_bond_active_sum("ember") * 0.01; }
function cat_crit_add()        { return cat_bond_active_sum("crit") * 0.01; }
function cat_crit_pay()        { return 1 + cat_bond_active_sum("critpay") * 0.01; }
function cat_staff_add()       { return cat_bond_active_sum("staff") * 0.01; }
function cat_staff_match_add() { return cat_bond_active_sum("match"); }
function cat_frenzy_add()      { return cat_bond_active_sum("frenzy"); }
function cat_combo_add()       { return cat_bond_active_sum("combo"); }
function cat_combo_grace()     { return cat_bond_active_sum("grace"); }
function cat_nerve_add()       { return cat_bond_active_sum("nerve"); }
function cat_peek_discount()   { return cat_bond_active_sum("peek"); }
function cat_relic_add()       { return cat_bond_active_sum("relic") * 0.01; }
function cat_growth_mult()     { return 1 + cat_bond_active_sum("growth") * 0.01; }
function cat_harvest_add()     { return cat_bond_active_sum("harvest"); }
function cat_treat_every()     { return cat_bond_min_active("treat"); }
function cat_endless_combo()   { return cat_bond_active_sum("endless") > 0; }
function cat_crit_combo()      { return cat_bond_active_sum("critcombo") > 0; }
function cat_combo5()          { return cat_bond_active_sum("combo5") > 0; }

/// The next rung's name, or a mastered line. Used by the album card and the
/// objective strip so the ladder is always visible at the moment of choice.
function cat_next_trick(_cat) {
    var _r = cat_bond_rank(_cat);
    if (_r >= CAT_BOND_MAX) return "BOND MASTERED";
    var _g = cat_bond_rung(_cat, _r + 1);
    return (is_struct(_g) && variable_struct_exists(_g, "n")) ? _g.n : "NEXT RUNG";
}

// The journal is deliberately independent of prestige: claims, projects and
// an active order all survive every reset. Goals are cumulative rather than
// timed, so visiting a chapter late never forfeits progress.
#macro JOURNAL_CHAPTERS 8

function journal_chapters() {
    return ["COZY BEGINNINGS", "GARDEN FRIENDS", "ROOFTOP CLUB",
            "CLOUD KITCHEN", "STAR WORKSHOP", "BEAN GARDEN",
            "AURORA FESTIVAL", "MOONLIGHT CAFE"];
}

function journal_goal(_chapter, _slot) {
    static _goals = [
        [{ kind: "clicks", target: 20, label: "Pet the cat" },
         { kind: "buys", target: 10, label: "Buy furniture" },
         { kind: "album", target: 6, label: "Meet cats" },
         { kind: "fish", target: 5000, label: "Earn fish" }],
        [{ kind: "zone", target: 1, label: "Reach the garden" },
         { kind: "buys", target: 50, label: "Buy furniture" },
         { kind: "album", target: 12, label: "Meet cats" },
         { kind: "sparkles", target: 2, label: "Catch sparkles" }],
        [{ kind: "zone", target: 2, label: "Reach the rooftop" },
         { kind: "clicks", target: 200, label: "Pet the cat" },
         { kind: "rate", target: 10000, label: "Reach fish per second" },
         { kind: "project", target: 3, label: "Build projects" }],
        [{ kind: "zone", target: 3, label: "Reach the cloud cafe" },
         { kind: "album", target: 24, label: "Complete the cat album" },
         { kind: "buys", target: 250, label: "Buy furniture" },
         { kind: "orders", target: 4, label: "Complete orders" }],
        [{ kind: "yarn", target: 15, label: "Earn yarn" },
         { kind: "stars", target: 1, label: "Earn stars" },
         { kind: "project", target: 8, label: "Build projects" },
         { kind: "orders", target: 8, label: "Complete orders" }],
        [{ kind: "beans", target: 1, label: "Earn beans" },
         { kind: "buys", target: 800, label: "Buy furniture" },
         { kind: "sparkles", target: 10, label: "Catch sparkles" },
         { kind: "orders", target: 16, label: "Complete orders" }],
        [{ kind: "aurora", target: 1, label: "Earn aurora" },
         { kind: "project", target: 16, label: "Build projects" },
         { kind: "clicks", target: 1500, label: "Pet the cat" },
         { kind: "orders", target: 28, label: "Complete orders" }],
        [{ kind: "moon", target: 1, label: "Earn moon" },
         { kind: "project", target: 24, label: "Build projects" },
         { kind: "prestiges", target: 40, label: "Complete resets" },
         { kind: "orders", target: 50, label: "Complete orders" }]
    ];
    return _goals[_chapter][_slot];
}

function journal_value(_kind) {
    switch (_kind) {
        case "clicks": return global.G.stats.clicks;
        case "buys": return global.G.stats.purchases;
        case "sparkles": return global.G.stats.sparkles;
        case "prestiges": return global.G.stats.prestiges;
        case "fish": return global.G.lifetime_earned;
        case "rate": return global.G.stats.best_rate;
        case "zone": return global.G.world.zone;
        case "album": return album_unlocked_count();
        case "orders": return global.G.journal.orders_done;
        case "project":
            var _total = 0;
            for (var _i = 0; _i < array_length(global.G.journal.projects); _i++) {
                _total += global.G.journal.projects[_i];
            }
            return _total;
        case "yarn": return global.G.earned.yarn;
        case "stars": return global.G.earned.stars;
        case "beans": return global.G.earned.beans;
        case "aurora": return global.G.earned.aurora;
        case "moon": return global.G.earned.moon;
    }
    return 0;
}

function journal_claim_count(_chapter) {
    var _n = 0;
    for (var _i = 0; _i < 4; _i++) _n += global.G.journal.claims[_chapter * 4 + _i];
    return _n;
}

function journal_unlocked(_chapter) {
    if (_chapter <= 0) return true;
    return journal_unlocked(_chapter - 1) && journal_claim_count(_chapter - 1) >= 3;
}

function journal_claim(_chapter, _slot) {
    if (!journal_unlocked(_chapter)) return false;
    var _index = _chapter * 4 + _slot;
    var _goal = journal_goal(_chapter, _slot);
    if (global.G.journal.claims[_index] || journal_value(_goal.kind) < _goal.target) return false;
    global.G.journal.claims[_index] = 1;
    global.G.journal.stamps += 1;
    save_write();
    return true;
}

// Each chapter has its own three projects. Their effects support production,
// tapping and away earnings, and each survives every prestige.
function journal_project_name(_chapter, _slot) {
    static _names = [
        ["BOX SHELF", "FEATHER TOY", "COZY BLANKET"],
        ["HERB PLANTER", "BUTTERFLY TOY", "GARDEN HAMMOCK"],
        ["ROOFTOP LAMPS", "KITE STRING", "STAR PILLOW"],
        ["CLOUD OVEN", "RAINBOW RIBBON", "CLOUD NEST"],
        ["STAR LANTERN", "COMET CHASER", "NIGHT QUILT"],
        ["BEAN TRELLIS", "LEAF MAZE", "FLOWER BED"],
        ["FESTIVAL STALL", "LIGHT PARADE", "AURORA TENT"],
        ["MOON KETTLE", "ORBIT MOBILE", "LUNAR LOUNGE"]
    ];
    return _names[_chapter][_slot];
}

function journal_project_cost(_chapter) {
    static _costs = [1000, 100000, 10000000, 1000000000,
                  100000000000, 10000000000000, 1000000000000000, 100000000000000000];
    return _costs[_chapter];
}

function journal_material_key(_slot) {
    if (_slot == 0) return "scraps";
    if (_slot == 1) return "treats";
    return "dust";
}

function journal_material_label(_slot) {
    if (_slot == 0) return "SCRAP";
    if (_slot == 1) return "TREAT";
    return "DUST";
}

function journal_project_buy(_chapter, _slot) {
    if (!journal_unlocked(_chapter)) return false;
    var _index = _chapter * 3 + _slot;
    var _cost = journal_project_cost(_chapter);
    var _key = journal_material_key(_slot);
    var _materials = 3 + _chapter;
    if (global.G.journal.projects[_index] || global.G.fish < _cost
        || global.G.journal.materials[$ _key] < _materials) return false;
    global.G.fish -= _cost;
    global.G.journal.materials[$ _key] -= _materials;
    global.G.journal.projects[_index] = 1;
    save_write();
    return true;
}

function journal_project_count(_slot) {
    var _n = 0;
    for (var _i = 0; _i < JOURNAL_CHAPTERS; _i++) {
        _n += global.G.journal.projects[_i * 3 + _slot];
    }
    return _n;
}

function journal_skill_cost(_slot) {
    return 1 + global.G.journal.skills[_slot];
}

function journal_skill_buy(_slot) {
    var _level = global.G.journal.skills[_slot];
    var _cost = journal_skill_cost(_slot);
    if (_level >= 10 || global.G.journal.stamps < _cost) return false;
    global.G.journal.stamps -= _cost;
    global.G.journal.skills[_slot] += 1;
    save_write();
    return true;
}

// Three independent orders can run together. They never expire and are
// measured from acceptance, not from all-time stats.
function journal_order_kind(_order) {
    switch (_order) {
        case 0: return "clicks";
        case 1: return "buys";
        default: return "fish";
    }
}

function journal_order_target(_order, _chapter) {
    if (_order == 0) return 20 + _chapter * 10;
    if (_order == 1) return 5 + _chapter * 2;
    return journal_project_cost(_chapter);
}

function journal_order_start(_order, _chapter) {
    if (_order < 0 || _order > 2 || !journal_unlocked(_chapter)) return false;
    if (global.G.journal.order_active[_order]) return false;
    global.G.journal.order_active[_order] = 1;
    global.G.journal.order_chapter[_order] = _chapter;
    global.G.journal.order_start[_order] = journal_value(journal_order_kind(_order));
    save_write();
    return true;
}

function journal_order_progress(_order) {
    if (_order < 0 || _order > 2 || !global.G.journal.order_active[_order]) return 0;
    return max(0, journal_value(journal_order_kind(_order)) - global.G.journal.order_start[_order]);
}

// ---------------------------------------------------------------- staff
// Cats you have met can hold one of four stations. Every cat has a natural
// station (its quirk); matching it doubles the bonus, so the roster becomes a
// set of choices rather than a checklist. Slots open as the album fills.
#macro STAFF_STATIONS 4
#macro STAFF_PER_STATION 3

function staff_defaults() {
    return { slots: array_create(STAFF_STATIONS * STAFF_PER_STATION, -1) };
}

function staff_normalize() {
    var _s = global.G.staff;
    if (!is_struct(_s) || !is_array(_s.slots)) _s = staff_defaults();
    array_resize(_s.slots, STAFF_STATIONS * STAFF_PER_STATION);
    var _seen = array_create(album_count(), 0);
    for (var _i = 0; _i < array_length(_s.slots); _i++) {
        var _cat = is_numeric(_s.slots[_i]) ? floor(_s.slots[_i]) : -1;
        if (_cat < 0 || _cat >= album_count() || !album_unlocked(_cat) || _seen[_cat] > 0) {
            _s.slots[_i] = -1;
        } else {
            _seen[_cat] = 1;
        }
    }
    global.G.staff = _s;
}

function staff_station_name(_i) {
    return ["COUNTER", "OVEN", "WINDOW", "CELLAR"][_i];
}

function staff_station_effect(_i) {
    return ["TAP VALUE", "CAFE OUTPUT", "AWAY RATE", "HOLLOW EMBERS"][_i];
}

/// One quirk per cat, cycling with the roster so early cats stay useful.
function staff_trait(_cat) {
    return _cat mod 6;
}

function staff_trait_name(_cat) {
    return ["SUNNY", "NIGHT", "COZY", "BUSY", "DREAMY", "HUNGRY"][staff_trait(_cat)];
}

/// The station this cat is naturally good at, or -1 for a drifter.
function staff_trait_station(_cat) {
    switch (staff_trait(_cat)) {
        case 0: return 0;
        case 1: return 3;
        case 2: return 2;
        case 3: return 1;
    }
    return -1;
}

/// Each slot needs a fuller album, so staffing grows with the collection.
function staff_slot_open(_slot) {
    var _need = [0, 8, 18][_slot];
    return album_unlocked_count() >= _need;
}

function staff_slot_open_need(_slot) {
    return [0, 8, 18][_slot];
}

function staff_assigned(_cat) {
    var _slots = global.G.staff.slots;
    for (var _i = 0; _i < array_length(_slots); _i++) {
        if (_slots[_i] == _cat) return _i;
    }
    return -1;
}

function staff_set(_station, _slot, _cat) {
    if (_station < 0 || _station >= STAFF_STATIONS) return false;
    if (_slot < 0 || _slot >= STAFF_PER_STATION || !staff_slot_open(_slot)) return false;
    if (_cat >= 0) {
        if (!album_unlocked(_cat)) return false;
        var _used = staff_assigned(_cat);
        if (_used >= 0) global.G.staff.slots[_used] = -1;
    }
    global.G.staff.slots[_station * STAFF_PER_STATION + _slot] = _cat;
    save_write();
    return true;
}

/// Cycle a slot through EMPTY, then every met cat not working elsewhere.
function staff_cycle(_station, _slot, _dir) {
    if (!staff_slot_open(_slot)) return false;
    var _index = _station * STAFF_PER_STATION + _slot;
    var _cur = global.G.staff.slots[_index];
    var _list = [-1];
    for (var _c = 0; _c < album_count(); _c++) {
        if (!album_unlocked(_c)) continue;
        var _where = staff_assigned(_c);
        if (_where >= 0 && _where != _index) continue;
        array_push(_list, _c);
    }
    var _at = 0;
    for (var _i = 0; _i < array_length(_list); _i++) {
        if (_list[_i] == _cur) _at = _i;
    }
    var _next = (_at + _dir + array_length(_list)) mod array_length(_list);
    return staff_set(_station, _slot, _list[_next]);
}

/// The bonus one cat contributes: later cats are a little stronger and a cat
/// in its natural station gives twice as much.
function staff_cat_bonus(_cat, _station) {
    var _base = 0.02 + 0.004 * (_cat div 6);
    // BUSY bond rungs improve the natural-station match; they do not replace
    // the base 2x match, so the rule is visible even before the first rung.
    var _match = 2 + cat_staff_match_add();
    return _base * (staff_trait_station(_cat) == _station ? _match : 1);
}

function staff_bonus(_station) {
    var _sum = 0;
    for (var _s = 0; _s < STAFF_PER_STATION; _s++) {
        var _cat = global.G.staff.slots[_station * STAFF_PER_STATION + _s];
        if (_cat >= 0) _sum += staff_cat_bonus(_cat, _station);
    }
    // BUSY companions train the whole floor, not one station.
    return _sum + cat_staff_add();
}

// ------------------------------------------------------- journal layout map
// The journal is a native 1920 card. One set of functions is the authority for
// Step, Draw and the harness, so no hit box can drift away from its artwork.
#macro ALBUM_X 64
#macro ALBUM_Y 56
#macro ALBUM_W 1100
#macro ALBUM_H 968
#macro ALBUM_BODY_Y 268

function album_close_rect() {
    return { x: ALBUM_X + ALBUM_W - 72, y: ALBUM_Y + UI_SPACE_M,
             w: UI_W_SQUARE, h: UI_H_CONTROL };
}

function album_help_rect() {
    return { x: ALBUM_X + ALBUM_W - 128, y: ALBUM_Y + UI_SPACE_M,
             w: UI_W_SQUARE, h: UI_H_CONTROL };
}

/// The journal card's tabs, laid out once so draw and input cannot disagree.
function staff_station_rects() {
    // The station filter is its own row between the hint and the three slots.
    // At 44px it clears the first slot at +302 instead of hiding under it.
    var _gap = 10;
    var _total = 0;
    for (var _i = 0; _i < STAFF_STATIONS; _i++) _total += dui_pill_w(staff_station_name(_i)) + _gap;
    var _x = ALBUM_X + max(0, floor((ALBUM_W - (_total - _gap)) * 0.5));
    var _out = [];
    for (var _i = 0; _i < STAFF_STATIONS; _i++) {
        var _w = dui_pill_w(staff_station_name(_i));
        array_push(_out, { left: _x, width: _w, index: _i, y: ALBUM_Y + 246, h: UI_H_ROW });
        _x += _w + _gap;
    }
    return _out;
}

function album_nav_labels() {
    // CATS is the first tab now; the journal and the album are one card rather
    // than two different screens. ERAS only exists once the first moon paid.
    var _l = ["CATS", "GOALS", "BUILD", "ORDERS", "STAFF"];
    if (era_unlocked()) array_push(_l, "ERAS");
    return _l;
}

function album_nav_rects() {
    var _labels = album_nav_labels();
    var _gap = 10;
    var _total = 0;
    for (var _i = 0; _i < array_length(_labels); _i++) {
        _total += dui_pill_w(_labels[_i]) + _gap;
    }
    var _x = ALBUM_X + max(0, floor((ALBUM_W - (_total - _gap)) * 0.5));
    var _out = [];
    for (var _i = 0; _i < array_length(_labels); _i++) {
        var _w = dui_pill_w(_labels[_i]);
        array_push(_out, { left: _x, width: _w, index: _i,
                           y: ALBUM_Y + 136, h: UI_H_ROW });
        _x += _w + _gap;
    }
    return _out;
}

function album_chapter_rects() {
    return {
        left:  { x: ALBUM_X + 48, y: ALBUM_Y + 236, w: UI_W_SQUARE, h: UI_H_CONTROL },
        right: { x: ALBUM_X + ALBUM_W - 48 - UI_W_SQUARE, y: ALBUM_Y + 236,
                 w: UI_W_SQUARE, h: UI_H_CONTROL }
    };
}

/// The CATS sheet's page arrows, shared by draw and input.
function album_cat_page_rects() {
    var _y = ALBUM_Y + 912;
    return {
        left:  { x: ALBUM_X + 48, y: _y, w: UI_W_SQUARE, h: UI_H_CONTROL },
        right: { x: ALBUM_X + ALBUM_W - 48 - UI_W_SQUARE, y: _y,
                 w: UI_W_SQUARE, h: UI_H_CONTROL }
    };
}

/// One pair of staff arrows, in the slot row's own coordinates.
function staff_arrow_rects(_row) {
    return {
        left:  { x: _row.x + _row.w - 128, y: _row.y + 42,
                 w: UI_W_SQUARE, h: UI_H_CONTROL },
        right: { x: _row.x + _row.w - 80, y: _row.y + 42,
                 w: UI_W_SQUARE, h: UI_H_CONTROL }
    };
}

function album_cat_rect(_k) {
    var _w = 233, _h = 196, _gx = 24, _gy = 24;
    return { x: ALBUM_X + 48 + (_k mod 4) * (_w + _gx),
             y: ALBUM_Y + 236 + (_k div 4) * (_h + _gy), w: _w, h: _h };
}

function journal_goal_rect(_i) {
    return { x: ALBUM_X + 48, y: ALBUM_Y + 236 + _i * 164,
             w: ALBUM_W - 96, h: 150 };
}

function journal_project_rect(_i) {
    return { x: ALBUM_X + 48, y: ALBUM_Y + 236 + _i * 214,
             w: ALBUM_W - 96, h: 190 };
}

function journal_order_rect(_i) {
    return { x: ALBUM_X + 48, y: ALBUM_Y + 254 + _i * 110,
             w: ALBUM_W - 96, h: 96 };
}

function journal_skill_rect(_i) {
    return { x: ALBUM_X + 48, y: ALBUM_Y + 634 + _i * 100,
             w: ALBUM_W - 96, h: 88 };
}

function staff_slot_rect(_i) {
    return { x: ALBUM_X + 48, y: ALBUM_Y + 302 + _i * 136,
             w: ALBUM_W - 96, h: 124 };
}

/// Where the three House Rule rows sit in the Era tab. Kept as one function so
/// the Step and Draw can never disagree about a hit box.
function era_rule_rect(_i) {
    return { x: ALBUM_X + 48, y: ALBUM_Y + 594 + _i * 92,
             w: ALBUM_W - 96, h: 84 };
}

function era_deed_rect(_i) {
    return { x: ALBUM_X + 48, y: ALBUM_Y + 296 + _i * 88,
             w: ALBUM_W - 96, h: 80 };
}

function era_seal_rect() {
    return { x: ALBUM_X + 360, y: ALBUM_Y + 880, w: 380, h: UI_H_CTA };
}

function era_change_rect() {
    return { x: ALBUM_X + ALBUM_W - 208, y: ALBUM_Y + 606,
             w: UI_W_CONTROL, h: UI_H_CONTROL };
}

function journal_order_claim(_order) {
    if (_order < 0 || _order > 2 || !global.G.journal.order_active[_order]) return false;
    var _chapter = global.G.journal.order_chapter[_order];
    if (_chapter < 0 || _chapter >= JOURNAL_CHAPTERS) return false;
    if (journal_order_progress(_order) < journal_order_target(_order, _chapter)) return false;
    global.G.journal.order_active[_order] = 0;
    global.G.journal.orders_done += 1;
    global.G.journal.stamps += 1;
    // Orders also provide materials, so players can finish projects without
    // relying exclusively on a particular timed sparkle pickup.
    if (_order == 0) global.G.journal.materials.treats += 3;
    if (_order == 1) global.G.journal.materials.scraps += 3;
    if (_order == 2) global.G.journal.materials.dust += 3;
    save_write();
    return true;
}
