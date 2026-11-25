/// THE HOLLOW HOUR: the hidden layer's state and rules.
/// One owner for everything the layer persists: currencies, descents, upgrades,
/// relics, curses, closings and omens. This file never draws anything.
#macro VEIL_LOC_COUNT 5
#macro VEIL_CLOSINGS 13
#macro VEIL_RELICS 40
#macro VEIL_REAGENTS 8
#macro VEIL_TINCTURES 10
#macro VEIL_CURSES 6
#macro VEIL_GARDEN_PLOTS 12
#macro VEIL_PLOT_BASE 6
#macro VEIL_DEPTH_END 13

function veil_defaults() {
    return {
        found: false, knocks: 0, in_hollow: false,
        embers: 0.0, whispers: 0.0, blood: 0.0,
        closings: 0,
        closes_done: array_create(VEIL_CLOSINGS, 0),
        mastery: array_create(VEIL_LOC_COUNT, 0),
        relics: array_create(VEIL_RELICS, 0),
        throne: [],
        up: {},
        curses: [],
        gift: 0.0,
        ending: 0, night_best: 0,
        seance: { seed: 1, tier: 0, solved: false, placed: array_create(6, -1),
                  reveal: array_create(6, -1), sel: -1, free: 0, clue_top: 0,
                  feedback: "", tries: 0, hints: 0 },
        hall: { active: false, floor: 0, nerve: 0, seed: 0, mood: 0, last_mod: -1,
                floors: 3, doors: array_create(5, 0), taken: -1,
                peeked: array_create(5, 0), loot_e: 0.0, loot_w: 0.0,
                feedback: "", cleared: 0, free: 0 },
        garden: { plots: [], sel: -1, mode: 0, seed: 0, choose: -1, feedback: "" },
        bench: { slots: array_create(3, -1), heat: 1,
                 reagents: array_create(VEIL_REAGENTS, 0),
                  known: array_create(VEIL_TINCTURES, 0),
                 tinctures: array_create(VEIL_TINCTURES, 0),
                 starter: false, feedback: "" },
        night: { active: false, depth: 0, nerve: 0, seed: 0, solved: false,
                 placed: array_create(6, -1), reveal: array_create(6, -1), sel: -1, free: 0,
                 clue_top: 0, feedback: "", tries: 0, hints: 0, tier: 0 },
        omen: { id: -1, t: 0, next: 300 },
        buff: { kind: 0, t: 0 },
        stats: { solves: 0, seances: 0, fails: 0, halls: 0, floors: 0,
                 harvests: 0, brews: 0, relics: 0, cleansed: 0, nights: 0,
                 best_hall: 0, hints: 0, omens: 0 }
    };
}

function veil_num(_v, _def) {
    if (!is_numeric(_v) || is_nan(_v)) return _def;
    return real(_v);
}

function veil_init() {
    global.VEIL_UP = [
        // ---- RITE: the séance
        { id: "keen",    branch: 0, cur: "e", name: "KEEN EAR",   desc: "+1 CASE REVEAL", max: 3, base: 12, grow: 1.9 },
        { id: "focus",   branch: 0, cur: "e", name: "FOCUS",      desc: "+20% CASE EMBERS", max: 5, base: 14, grow: 1.7 },
        { id: "candle",  branch: 0, cur: "e", name: "TALL CANDLE", desc: "+25% FLAWLESS", max: 4, base: 18, grow: 1.8 },
        { id: "ear",     branch: 0, cur: "e", name: "THIRD EAR",  desc: "+1 WHISPER A CASE", max: 5, base: 20, grow: 1.7 },
        { id: "mask",    branch: 0, cur: "e", name: "WAX MASK",   desc: "+4% ALL EMBERS", max: 6, base: 16, grow: 1.65 },
        // ---- REACH: garden and hall
        { id: "plots",   branch: 1, cur: "e", name: "NEW BEDS",   desc: "+2 GARDEN PLOTS", max: 3, base: 16, grow: 1.9 },
        { id: "growth",  branch: 1, cur: "e", name: "WARM SOIL",  desc: "+12% GROWTH SPEED", max: 5, base: 14, grow: 1.7 },
        { id: "nerve",   branch: 1, cur: "e", name: "STEADY HAND",desc: "+1 HALL NERVE", max: 3, base: 18, grow: 1.9 },
        { id: "peek",    branch: 1, cur: "e", name: "SPYGLASS",   desc: "FREE PEEK A FLOOR", max: 1, base: 24, grow: 1.0 },
        { id: "harvest", branch: 1, cur: "e", name: "SICKLE",     desc: "+10% HARVEST", max: 5, base: 15, grow: 1.7 },
        { id: "doors",   branch: 1, cur: "e", name: "THREE KEYS", desc: "+1 HALL DOOR", max: 2, base: 26, grow: 2.0 },
        // ---- RESIDUE: automation and finds
        { id: "ember",   branch: 2, cur: "e", name: "EMBER VEIN", desc: "+8% EMBERS", max: 6, base: 12, grow: 1.6 },
        { id: "whisper", branch: 2, cur: "e", name: "QUIET ROOM", desc: "+8% WHISPERS", max: 6, base: 12, grow: 1.6 },
        { id: "chance",  branch: 2, cur: "e", name: "MAGPIE",     desc: "+3% RELIC FIND", max: 5, base: 22, grow: 1.8 },
        { id: "keeper",  branch: 2, cur: "e", name: "THE KEEPER", desc: "TENDS READY BEDS", max: 1, base: 30, grow: 1.0 },
        { id: "listener",branch: 2, cur: "e", name: "THE LISTENER",desc: "HEARS CASES", max: 1, base: 34, grow: 1.0 },
        // ---- ALTAR: blood, the deep end
        { id: "bloodgift",branch: 3, cur: "b", name: "WAKE GIFT", desc: "+5% CAFE OUTPUT", max: 5, base: 1, grow: 2.0 },
        { id: "reliquary",branch: 3, cur: "b", name: "RELIQUARY", desc: "+1 RELIC SLOT", max: 1, base: 2, grow: 1.0 },
        { id: "omenward", branch: 3, cur: "b", name: "OMEN WARD", desc: "OMENS COME LESS", max: 2, base: 1, grow: 2.0 },
        { id: "nightglass",branch: 3, cur: "b", name: "NIGHT GLASS",desc: "+1 NIGHT NERVE", max: 3, base: 1, grow: 2.0 }
    ];

    global.VEIL_RELIC = [];
    var _sets = ["WAX", "BONE", "ASH", "ROOT", "VEIL"];
    var _names = [
        ["WICK", "TALLOW", "SPILL", "SNUFF", "DRIP", "VOTIVE", "LANTERN", "FLAME"],
        ["KNUCKLE", "RIB", "TOOTH", "FEMUR", "SKULL", "SALT", "MOTH", "WING"],
        ["CINDER", "SOOT", "EMBER", "CLINKER", "SMOKE", "SCAR", "RUIN", "DUST"],
        ["TENDRIL", "THORN", "BULB", "MOSS", "BARK", "SPORE", "VINE", "POD"],
        ["MIRROR", "THREAD", "HUSH", "ECHO", "SHADE", "DOOR", "KEY", "NINE"]
    ];
    for (var _s = 0; _s < 5; _s++) {
        for (var _i = 0; _i < 8; _i++) {
            array_push(global.VEIL_RELIC,
                { set: _s, name: _names[_s][_i], set_name: _sets[_s] });
        }
    }

    global.VEIL_CLOSING = [
        { label: "SOLVE 3 CASES",          key: "solves",   target: 3 },
        { label: "CLEAR THE LONG HALL",    key: "halls",    target: 1 },
        { label: "FIND 2 RELICS",          key: "relics",   target: 2 },
        { label: "SOLVE 6 CASES",          key: "solves",   target: 6 },
        { label: "HARVEST 3 PLOTS",        key: "harvests", target: 3 },
        { label: "CLEANSE A CURSE",        key: "cleansed", target: 1 },
        { label: "CLEAR 3 HALL RUNS",      key: "halls",    target: 3 },
        { label: "BREW 3 TINCTURES",       key: "brews",    target: 3 },
        { label: "REACH MASTERY 1",        key: "mastery",  target: 1 },
        { label: "FIND 8 RELICS",          key: "relics",   target: 8 },
        { label: "SOLVE 12 CASES",         key: "solves",   target: 12 },
        { label: "GROW 10 HARVESTS",       key: "harvests", target: 10 },
        { label: "REACH NIGHT DEPTH 4",    key: "night",    target: 4 }
    ];

    // One empty bed per plot, so a save always has the full set to normalize.
    var _g = global.G.occult.garden;
    if (is_struct(_g) && array_length(_g.plots) == 0) {
        for (var _p = 0; _p < VEIL_GARDEN_PLOTS; _p++) {
            array_push(_g.plots, { seed: -1, planted: 0, need: 0, fed: 0, blight: 0 });
        }
    }
}

/// Repairs the save after the generic merge. Everything here is additive, so
/// saves written before the layer existed simply arrive with the defaults.
function veil_normalize() {
    if (!variable_struct_exists(global.G, "occult") || !is_struct(global.G.occult)) {
        global.G.occult = veil_defaults();
    }
    var _o = global.G.occult;
    var _d = veil_defaults();
    var _keys = variable_struct_get_names(_d);
    for (var _i = 0; _i < array_length(_keys); _i++) {
        var _k = _keys[_i];
        if (!variable_struct_exists(_o, _k)) {
            _o[$ _k] = _d[$ _k];
        }
    }

    _o.found = (is_bool(_o.found) ? _o.found : veil_num(_o.found, 0) > 0);
    _o.in_hollow = (is_bool(_o.in_hollow) ? _o.in_hollow : veil_num(_o.in_hollow, 0) > 0);
    _o.knocks = clamp(veil_num(_o.knocks, 0), 0, 3);
    _o.embers = max(0, veil_num(_o.embers, 0));
    _o.whispers = max(0, veil_num(_o.whispers, 0));
    _o.blood = max(0, veil_num(_o.blood, 0));
    _o.closings = clamp(veil_num(_o.closings, 0), 0, VEIL_CLOSINGS);
    _o.gift = max(0, veil_num(_o.gift, 0));
    _o.ending = veil_num(_o.ending, 0) > 0;
    _o.night_best = max(0, veil_num(_o.night_best, 0));

    if (!is_array(_o.closes_done)) _o.closes_done = [];
    array_resize(_o.closes_done, VEIL_CLOSINGS);
    for (var _i = 0; _i < VEIL_CLOSINGS; _i++) {
        _o.closes_done[_i] = (veil_num(_o.closes_done[_i], 0) > 0) ? 1 : 0;
    }
    if (!is_array(_o.mastery)) _o.mastery = [];
    array_resize(_o.mastery, VEIL_LOC_COUNT);
    for (var _i = 0; _i < VEIL_LOC_COUNT; _i++) _o.mastery[_i] = max(0, veil_num(_o.mastery[_i], 0));
    if (!is_array(_o.relics)) _o.relics = [];
    array_resize(_o.relics, VEIL_RELICS);
    for (var _i = 0; _i < VEIL_RELICS; _i++) {
        _o.relics[_i] = clamp(veil_num(_o.relics[_i], 0), 0, 8);
    }
    if (!is_array(_o.throne)) _o.throne = [];
    for (var _i = array_length(_o.throne) - 1; _i >= 0; _i--) {
        var _idx = veil_num(_o.throne[_i], -1);
        if (_idx < 0 || _idx >= VEIL_RELICS || !is_array(_o.throne)) {
            array_delete(_o.throne, _i, 1);
        }
    }
    if (!is_struct(_o.up)) _o.up = {};
    if (!is_array(_o.curses)) _o.curses = [];
    for (var _i = array_length(_o.curses) - 1; _i >= 0; _i--) {
        var _c = veil_num(_o.curses[_i], -1);
        if (_c < 0 || _c >= VEIL_CURSES) array_delete(_o.curses, _i, 1);
    }

    if (!is_struct(_o.seance)) _o.seance = _d.seance;
    if (!is_array(_o.seance.placed)) _o.seance.placed = [];
    array_resize(_o.seance.placed, 6);
    for (var _i = 0; _i < 6; _i++) _o.seance.placed[_i] = veil_num(_o.seance.placed[_i], -1);
    _o.seance.seed = max(1, veil_num(_o.seance.seed, 1));
    _o.seance.tier = clamp(veil_num(_o.seance.tier, 0), 0, 2);
    _o.seance.solved = (veil_num(_o.seance.solved, 0) > 0);
    if (!is_array(_o.seance.reveal)) _o.seance.reveal = [];
    array_resize(_o.seance.reveal, 6);
    for (var _i = 0; _i < 6; _i++) _o.seance.reveal[_i] = veil_num(_o.seance.reveal[_i], -1);
    _o.seance.sel = clamp(veil_num(_o.seance.sel, -1), -1, 5);
    _o.seance.free = max(0, veil_num(_o.seance.free, 0));
    _o.seance.clue_top = max(0, veil_num(_o.seance.clue_top, 0));
    if (!is_string(_o.seance.feedback)) _o.seance.feedback = "";

    if (!is_struct(_o.hall)) _o.hall = _d.hall;
    if (!is_array(_o.hall.doors)) _o.hall.doors = [];
    if (!is_array(_o.hall.peeked)) _o.hall.peeked = [];
    array_resize(_o.hall.doors, 5);
    array_resize(_o.hall.peeked, 5);
    if (!variable_struct_exists(_o.hall, "mood")) _o.hall.mood = 0;
    if (!variable_struct_exists(_o.hall, "last_mod")) _o.hall.last_mod = -1;
    if (!variable_struct_exists(_o.hall, "floors")) _o.hall.floors = 3;
    _o.hall.mood = clamp(veil_num(_o.hall.mood, 0), 0, array_length(veil_hall_mods()) - 1);
    _o.hall.last_mod = clamp(veil_num(_o.hall.last_mod, -1), -1, array_length(veil_hall_mods()) - 1);
    _o.hall.floors = clamp(veil_num(_o.hall.floors, 3), 3, 5);
    _o.hall.active = (veil_num(_o.hall.active, 0) > 0);
    _o.hall.floor = clamp(veil_num(_o.hall.floor, 0), 0, 5);
    _o.hall.nerve = clamp(veil_num(_o.hall.nerve, 0), 0, 40);
    _o.hall.loot_e = max(0, veil_num(_o.hall.loot_e, 0));
    _o.hall.loot_w = max(0, veil_num(_o.hall.loot_w, 0));
    _o.hall.free = max(0, veil_num(_o.hall.free, 0));
    if (!is_string(_o.hall.feedback)) _o.hall.feedback = "";
    if (_o.hall.active && _o.hall.doors[0] == 0) _o.hall.active = false;

    if (!is_struct(_o.garden)) _o.garden = _d.garden;
    if (!is_array(_o.garden.plots)) _o.garden.plots = [];
    var _have = array_length(_o.garden.plots);
    for (var _i = 0; _i < _have; _i++) {
        var _p = _o.garden.plots[_i];
        if (!is_struct(_p)) _o.garden.plots[_i] = { seed: -1, planted: 0, need: 0, fed: 0, blight: 0 };
    }
    for (var _i = _have; _i < VEIL_GARDEN_PLOTS; _i++) {
        array_push(_o.garden.plots, { seed: -1, planted: 0, need: 0, fed: 0, blight: 0 });
    }
    array_resize(_o.garden.plots, VEIL_GARDEN_PLOTS);
    for (var _i = 0; _i < VEIL_GARDEN_PLOTS; _i++) {
        var _p = _o.garden.plots[_i];
        _p.seed = clamp(veil_num(_p.seed, -1), -1, 2);
        _p.planted = max(0, veil_num(_p.planted, 0));
        _p.need = max(0, veil_num(_p.need, 0));
        _p.fed = (veil_num(_p.fed, 0) > 0);
        _p.blight = (veil_num(_p.blight, 0) > 0);
    }
    _o.garden.sel = clamp(veil_num(_o.garden.sel, -1), -1, VEIL_GARDEN_PLOTS - 1);
    _o.garden.mode = clamp(veil_num(_o.garden.mode, 0), 0, 1);
    _o.garden.seed = clamp(veil_num(_o.garden.seed, 0), 0, 2);
    _o.garden.choose = clamp(veil_num(_o.garden.choose, -1), -1, VEIL_GARDEN_PLOTS - 1);
    if (!is_string(_o.garden.feedback)) _o.garden.feedback = "";

    if (!is_struct(_o.bench)) _o.bench = _d.bench;
    if (!is_array(_o.bench.slots)) _o.bench.slots = [];
    if (!is_array(_o.bench.reagents)) _o.bench.reagents = [];
    if (!is_array(_o.bench.known)) _o.bench.known = [];
    if (!is_array(_o.bench.tinctures)) _o.bench.tinctures = [];
    array_resize(_o.bench.slots, 3);
    array_resize(_o.bench.reagents, VEIL_REAGENTS);
    array_resize(_o.bench.known, VEIL_TINCTURES);
    array_resize(_o.bench.tinctures, VEIL_TINCTURES);
    for (var _i = 0; _i < 3; _i++) _o.bench.slots[_i] = clamp(veil_num(_o.bench.slots[_i], -1), -1, VEIL_REAGENTS - 1);
    for (var _i = 0; _i < VEIL_REAGENTS; _i++) _o.bench.reagents[_i] = max(0, veil_num(_o.bench.reagents[_i], 0));
    for (var _i = 0; _i < VEIL_TINCTURES; _i++) {
        _o.bench.known[_i] = (veil_num(_o.bench.known[_i], 0) > 0);
        _o.bench.tinctures[_i] = max(0, veil_num(_o.bench.tinctures[_i], 0));
    }
    _o.bench.heat = clamp(veil_num(_o.bench.heat, 1), 1, 3);
    _o.bench.starter = (veil_num(_o.bench.starter, 0) > 0);
    if (!is_string(_o.bench.feedback)) _o.bench.feedback = "";

    if (!is_struct(_o.night)) _o.night = _d.night;
    if (!is_array(_o.night.placed)) _o.night.placed = [];
    array_resize(_o.night.placed, 6);
    for (var _i = 0; _i < 6; _i++) _o.night.placed[_i] = veil_num(_o.night.placed[_i], -1);
    _o.night.active = (veil_num(_o.night.active, 0) > 0);
    _o.night.depth = max(0, veil_num(_o.night.depth, 0));
    _o.night.nerve = max(0, veil_num(_o.night.nerve, 0));
    _o.night.seed = max(1, veil_num(_o.night.seed, 1));
    _o.night.tier = clamp(veil_num(_o.night.tier, 0), 0, 2);
    _o.night.solved = (veil_num(_o.night.solved, 0) > 0);
    if (!is_array(_o.night.reveal)) _o.night.reveal = [];
    array_resize(_o.night.reveal, 6);
    for (var _i = 0; _i < 6; _i++) _o.night.reveal[_i] = veil_num(_o.night.reveal[_i], -1);
    _o.night.sel = clamp(veil_num(_o.night.sel, -1), -1, 5);
    _o.night.free = max(0, veil_num(_o.night.free, 0));
    _o.night.clue_top = max(0, veil_num(_o.night.clue_top, 0));
    if (!is_string(_o.night.feedback)) _o.night.feedback = "";

    if (!is_struct(_o.omen)) _o.omen = _d.omen;
    _o.omen.id = clamp(veil_num(_o.omen.id, -1), -1, 9);
    _o.omen.t = max(0, veil_num(_o.omen.t, 0));
    _o.omen.next = max(120, veil_num(_o.omen.next, 300));
    if (!is_struct(_o.buff)) _o.buff = _d.buff;
    _o.buff.kind = clamp(veil_num(_o.buff.kind, 0), 0, 2);
    _o.buff.t = max(0, veil_num(_o.buff.t, 0));

    if (!is_struct(_o.stats)) _o.stats = _d.stats;
    var _sk = variable_struct_get_names(_d.stats);
    for (var _i = 0; _i < array_length(_sk); _i++) {
        var _k = _sk[_i];
        var _v = variable_struct_exists(_o.stats, _k) ? _o.stats[$ _k] : 0;
        _o.stats[$ _k] = max(0, veil_num(_v, 0));
    }

    // A save from a broken interrupt should never strand the player in a
    // half-open layer: if the Hollow state cannot be trusted, wake them.
    if (_o.in_hollow && !_o.found) _o.in_hollow = false;
}

// ---------------------------------------------------------------- unlocking

function veil_festival_ranks() {
    var _t = 0;
    var _r = global.G.festival.ranks;
    for (var _i = 0; _i < array_length(_r); _i++) _t += veil_num(_r[_i], 0);
    return _t;
}

/// Hidden, but findable: a seam in the wallpaper, a fleck of cold air, and the
/// guide's one line about the wall. It is never a button that advertises itself.
function veil_eligible() {
    if (!variable_global_exists("G")) return false;
    if (!variable_struct_exists(global.G, "occult")) return false;
    if (global.G.occult.found) return true;
    return global.G.earned.moon > 0 && veil_festival_ranks() > 0;
}

function veil_active() {
    if (!variable_global_exists("G")) return false;
    if (!variable_struct_exists(global.G, "occult")) return false;
    return global.G.occult.in_hollow;
}

function veil_discover() {
    var _o = global.G.occult;
    if (_o.found) return false;
    _o.found = true;
    _o.knocks = 3;
    _o.in_hollow = true;
    save_write();
    if (!instance_exists(obj_veil)) instance_create_depth(0, 0, -10000, obj_veil);
    music_refresh();
    return true;
}

function veil_enter() {
    if (!veil_eligible()) return false;
    global.G.occult.in_hollow = true;
    save_write();
    if (!instance_exists(obj_veil)) instance_create_depth(0, 0, -10000, obj_veil);
    music_refresh();
    return true;
}

function veil_wake() {
    global.G.occult.in_hollow = false;
    global.G.occult.omen.id = -1;
    global.G.occult.omen.t = 0;
    save_write();
    if (instance_exists(obj_veil)) instance_destroy(obj_veil);
    music_refresh();
    return true;
}

/// The entrance belongs to the Cozy Corner and nowhere else. Both the art and
/// the input ask this, so the wall can never be drawn in a room it cannot be
/// clicked in (or the reverse).
function veil_door_here() {
    return !veil_active() && veil_eligible() && global.G.world.zone == 0;
}

/// The cat is drawn in front of the pantry, so its generous 56px petting
/// circle owns any click inside it. The cupboard only receives the clicks
/// around that circle. Kept as a function so the door and the cat cannot
/// disagree about which one was clicked.
function veil_door_cat_claimed(_mx, _my) {
    if (!instance_exists(obj_cat_big)) return false;
    var _cat = instance_find(obj_cat_big, 0);
    return point_distance(_mx, _my, _cat.cx, _cat.feet - 34) < 56;
}

function veil_loc_name(_i) {
    switch (_i) {
        case 1: return "THE COLD PARLOUR";
        case 2: return "THE ASH GARDEN";
        case 3: return "THE LONG HALL";
        case 4: return "THE TINCTURE CELLAR";
        case 5: return "THE NINTH TABLE";
    }
    return "THE HOLLOW HOUR";
}

function veil_loc_blurb(_i) {
    switch (_i) {
        case 1: return "THEY STILL WANT TO BE SEATED";
        case 2: return "WHAT GROWS HERE IS HUNGRY";
        case 3: return "EVERY DOOR REMEMBERS YOU";
        case 4: return "SOMETHING IS STILL BREWING";
        case 5: return "THE TABLE IS ALREADY SET";
    }
    return "THE CAFE AFTER MIDNIGHT";
}

/// Unlock each activity before the first closing that needs it.
function veil_loc_need(_i) {
    switch (_i) {
        case 1: return 0; // parlour: closing 1
        case 2: return 3; // garden: closing 5
        case 3: return 1; // hall: closing 2
        case 4: return 6; // cellar: closing 8
        case 5: return 12; // night: closing 13
    }
    return VEIL_CLOSINGS + 1;
}

function veil_loc_open(_i) {
    return global.G.occult.found && global.G.occult.closings >= veil_loc_need(_i);
}

// ---------------------------------------------------------------- upgrades

/// Charm ids are dynamic struct keys, so the defaults-based merge cannot copy
/// them. Read them straight from the parsed save, exactly as the cafe does for
/// its own upgrade tree.
function veil_load_up(_source) {
    var _o = global.G.occult;
    _o.up = {};
    if (!is_struct(_source) || !variable_struct_exists(_source, "occult")) return;
    if (!is_struct(_source.occult) || !variable_struct_exists(_source.occult, "up")) return;
    var _src = _source.occult.up;
    if (!is_struct(_src)) return;
    for (var _i = 0; _i < array_length(global.VEIL_UP); _i++) {
        var _id = global.VEIL_UP[_i].id;
        if (variable_struct_exists(_src, _id) && is_numeric(_src[$ _id])) {
            _o.up[$ _id] = clamp(floor(_src[$ _id]), 0, global.VEIL_UP[_i].max);
        }
    }
}

function veil_up_find(_id) {
    for (var _i = 0; _i < array_length(global.VEIL_UP); _i++) {
        if (global.VEIL_UP[_i].id == _id) return _i;
    }
    return -1;
}

function veil_lvl(_id) {
    if (!variable_struct_exists(global.G.occult.up, _id)) return 0;
    return veil_num(global.G.occult.up[$ _id], 0);
}

function veil_up_cost(_id) {
    var _i = veil_up_find(_id);
    if (_i < 0) return 999999999;
    var _u = global.VEIL_UP[_i];
    return ceil(_u.base * power(_u.grow, veil_lvl(_id)));
}

function veil_up_maxed(_id) {
    var _i = veil_up_find(_id);
    return _i < 0 || veil_lvl(_id) >= global.VEIL_UP[_i].max;
}

function veil_up_affordable(_id) {
    var _i = veil_up_find(_id);
    if (_i < 0 || veil_up_maxed(_id)) return false;
    var _u = global.VEIL_UP[_i];
    var _have = (_u.cur == "b") ? global.G.occult.blood : global.G.occult.embers;
    return _have >= veil_up_cost(_id);
}

function veil_up_buy(_id) {
    if (!veil_up_affordable(_id)) return false;
    var _i = veil_up_find(_id);
    var _u = global.VEIL_UP[_i];
    var _c = veil_up_cost(_id);
    if (_u.cur == "b") global.G.occult.blood -= _c;
    else global.G.occult.embers -= _c;
    global.G.occult.up[$ _id] = veil_lvl(_id) + 1;
    save_write();
    return true;
}

// ---------------------------------------------------------------- relics

function veil_relic_count(_i) {
    if (_i < 0 || _i >= VEIL_RELICS) return 0;
    return global.G.occult.relics[_i];
}

function veil_relic_owned_total() {
    var _n = 0;
    for (var _i = 0; _i < VEIL_RELICS; _i++) _n += global.G.occult.relics[_i];
    return _n;
}

function veil_relic_set_count(_set) {
    var _n = 0;
    for (var _i = 0; _i < VEIL_RELICS; _i++) {
        if (global.VEIL_RELIC[_i].set == _set) _n += global.G.occult.relics[_i];
    }
    return _n;
}

function veil_relic_grant(_i) {
    if (_i < 0 || _i >= VEIL_RELICS) _i = veil_relic_random();
    if (_i < 0) return -1;
    var _o = global.G.occult;
    if (_o.relics[_i] < 8) {
        _o.relics[_i] += 1;
        _o.stats.relics += 1;
        // The eighth piece finishes a set: the cafe gets a permanent gift.
        if (veil_relic_set_count(global.VEIL_RELIC[_i].set) == 8) {
            _o.gift += 5;
            _o.blood += 1;
        }
        save_write();
    }
    return _i;
}

/// Prefer a relic that still has room in its set, so the collection can finish.
function veil_relic_random() {
    var _pool = [];
    for (var _i = 0; _i < VEIL_RELICS; _i++) {
        if (global.G.occult.relics[_i] < 8) array_push(_pool, _i);
    }
    if (array_length(_pool) == 0) return -1;
    return _pool[irandom(array_length(_pool) - 1)];
}

function veil_throne_slots() {
    return 3 + veil_lvl("reliquary");
}

function veil_enthroned(_i) {
    return array_contains(global.G.occult.throne, _i);
}

function veil_throne_toggle(_i) {
    if (veil_relic_count(_i) <= 0) return false;
    var _t = global.G.occult.throne;
    var _at = -1;
    for (var _j = 0; _j < array_length(_t); _j++) {
        if (_t[_j] == _i) _at = _j;
    }
    if (_at >= 0) {
        array_delete(_t, _at, 1);
    } else {
        if (array_length(_t) >= veil_throne_slots()) return false;
        array_push(_t, _i);
    }
    save_write();
    return true;
}

/// How many enthroned relics belong to one set: the source of every set bonus.
function veil_throne_set(_set) {
    var _n = 0;
    var _t = global.G.occult.throne;
    for (var _i = 0; _i < array_length(_t); _i++) {
        if (global.VEIL_RELIC[_t[_i]].set == _set) _n += 1;
    }
    return _n;
}

// ---------------------------------------------------------------- curses

function veil_curses() {
    return [
        { name: "SHAKING HANDS", desc: "GARDEN GROWS 15% SLOWER", kind: "grow" },
        { name: "HOLLOW STOMACH", desc: "EMBERS COME 10% THINNER", kind: "ember" },
        { name: "SALT TONGUE", desc: "WHISPERS COME 10% THINNER", kind: "whisper" },
        { name: "ASH LUNG", desc: "HARVESTS ARE 20% LIGHTER", kind: "harvest" },
        { name: "HEAVY LID", desc: "PEEKS COST 1 MORE WHISPER", kind: "peek" },
        { name: "COLD WITNESS", desc: "CASE REWARDS 10% THINNER", kind: "seance" }
    ];
}

function veil_curse_count(_kind) {
    var _n = 0;
    var _all = veil_curses();
    var _c = global.G.occult.curses;
    for (var _i = 0; _i < array_length(_c); _i++) {
        if (_all[_c[_i]].kind == _kind) _n += 1;
    }
    return _n;
}

function veil_curse_add(_i) {
    if (_i < 0 || _i >= VEIL_CURSES) _i = irandom(VEIL_CURSES - 1);
    array_push(global.G.occult.curses, _i);
    save_write();
    return _i;
}

function veil_curse_cleanse_cost() {
    return 20 + array_length(global.G.occult.curses) * 10;
}

function veil_curse_cleanse() {
    var _o = global.G.occult;
    if (array_length(_o.curses) <= 0) return false;
    var _c = veil_curse_cleanse_cost();
    if (_o.embers < _c) return false;
    _o.embers -= _c;
    array_delete(_o.curses, 0, 1);
    _o.stats.cleansed += 1;
    save_write();
    return true;
}

// ---------------------------------------------------------------- mastery

function veil_mastery_rank(_loc) {
    var _v = veil_mastery_value(_loc);
    var _steps = [1, 3, 6, 10, 16];
    var _r = 0;
    for (var _i = 0; _i < array_length(_steps); _i++) {
        if (_v >= _steps[_i]) _r = _i + 1;
    }
    return _r;
}

/// The one source for location mastery: each door counts the activity its
/// effects read. The map pips, the rank and every consumer call this; a save
/// written under the old mapping keeps every solve/harvest/hall/brew/night
/// depth and simply displays the corrected rank. Location counts are derived,
/// never stored -- the old occult.mastery array is legacy and unread.
function veil_mastery_value(_loc) {
    var _s = global.G.occult.stats;
    switch (_loc) {
        case 1: return _s.solves;     // the Parlour -> case pay and whispers
        case 2: return _s.harvests;   // the Garden -> growth
        case 3: return _s.halls;      // the Long Hall -> hall nerve
        case 4: return _s.brews;      // the Cellar -> relic chance
        case 5: return global.G.occult.night_best; // the Ninth Table -> embers
    }
    return 0;
}

/// What the pips count, in the words the rest of the Hollow uses. Keep this
/// beside veil_mastery_value(): a remap that skips the caption would teach the
/// player the wrong activity every time they open the map.
function veil_mastery_label(_loc) {
    switch (_loc) {
        case 1: return "CASES SOLVED";
        case 2: return "PLOTS HARVESTED";
        case 3: return "HALL RUNS";
        case 4: return "BATCHES BREWED";
        case 5: return "BEST NIGHT DEPTH";
    }
    return "";
}

function veil_mastery_best() {
    var _b = 0;
    // The Ninth Table is a location too; depth 1 must count as mastery 1.
    for (var _i = 1; _i <= VEIL_LOC_COUNT; _i++) {
        _b = max(_b, veil_mastery_rank(_i));
    }
    return _b;
}

// ---------------------------------------------------------------- yields

function veil_ember_mult() {
    var _o = global.G.occult;
    var _m = 1 + 0.08 * veil_lvl("ember") + 0.04 * veil_lvl("mask")
           + 0.02 * veil_mastery_rank(1)
           + 0.06 * veil_throne_set(0)
           + 0.02 * veil_throne_set(4)
           + 0.005 * min(veil_mastery_value(5), 200)
           + staff_bonus(3);
    _m *= 1 - 0.10 * veil_curse_count("ember");
    if (_o.buff.kind == 2 && _o.buff.t > 0) _m *= 1.5;
    _m *= era_ember_mult() * era_perk_ember() * cat_ember_mult();
    return max(0.1, _m);
}

function veil_whisper_mult() {
    var _m = 1 + 0.08 * veil_lvl("whisper") + 0.05 * veil_throne_set(1)
           + 0.02 * veil_mastery_rank(1);
    _m *= 1 - 0.10 * veil_curse_count("whisper");
    return max(0.1, _m);
}

function veil_grow_mult() {
    var _m = 1 + 0.12 * veil_lvl("growth") + 0.05 * veil_throne_set(2)
           + 0.04 * veil_mastery_rank(2);
    _m *= 1 - 0.15 * veil_curse_count("grow");
    if (global.G.occult.buff.kind == 1 && global.G.occult.buff.t > 0) _m *= 2;
    _m *= cat_growth_mult();
    return max(0.15, _m);
}

function veil_harvest_mult() {
    var _m = (1 + 0.10 * veil_lvl("harvest"))
           * (1 - 0.20 * veil_curse_count("harvest"));
    return max(0.2, _m);
}

function veil_seance_mult() {
    return max(0.2, (1 + 0.20 * veil_lvl("focus") + 0.02 * veil_mastery_rank(1))
           * (1 - 0.10 * veil_curse_count("seance")));
}

function veil_relic_chance() {
    return 0.06 + 0.03 * veil_lvl("chance") + 0.015 * veil_throne_set(4)
         + 0.01 * veil_mastery_rank(4) + cat_relic_add();
}

function veil_plot_count() {
    return clamp(VEIL_PLOT_BASE + 2 * veil_lvl("plots") + arc_garden_plots(),
                 VEIL_PLOT_BASE, VEIL_GARDEN_PLOTS);
}

function veil_hall_nerve() {
    var _m = veil_hall_mod();
    return max(1, 5 + veil_lvl("nerve") + floor(veil_throne_set(3) / 2)
               + veil_mastery_rank(3) + cat_nerve_add() + _m.nerve);
}

function veil_hall_doors() {
    return 3 + veil_lvl("doors");
}

function veil_peek_cost() {
    return max(1, 2 + veil_curse_count("peek") - cat_peek_discount());
}

function veil_case_seats(_tier) {
    return 4 + clamp(_tier, 0, 2);
}

function veil_case_reveals() {
    return veil_lvl("keen");
}

// ---------------------------------------------------------------- currency

function veil_gain_embers(_n) {
    var _g = max(0, _n) * veil_ember_mult();
    global.G.occult.embers += _g;
    return _g;
}

function veil_gain_whispers(_n) {
    var _g = max(0, _n) * veil_whisper_mult();
    global.G.occult.whispers += _g;
    return _g;
}

function veil_cafe_mult() {
    if (!variable_global_exists("G")) return 1;
    if (!variable_struct_exists(global.G, "occult")) return 1;
    // Closings and finished relic sets give the cafe a permanent gift; so do
    // the blood-bought Wake Gifts. The cafe never has to know where they came
    // from, but the player sees the number rise.
    return 1 + global.G.occult.gift * 0.01 + 0.05 * veil_lvl("bloodgift");
}

// ---------------------------------------------------------------- closings

function veil_closing_value(_key) {
    var _s = global.G.occult.stats;
    switch (_key) {
        case "solves":   return _s.solves;
        case "halls":    return _s.halls;
        case "relics":   return _s.relics;
        case "harvests": return _s.harvests;
        case "brews":    return _s.brews;
        case "cleansed": return _s.cleansed;
        case "mastery":  return veil_mastery_best();
        case "night":    return global.G.occult.night_best;
    }
    return 0;
}

function veil_closing_current() {
    var _c = global.G.occult.closings;
    if (_c >= VEIL_CLOSINGS) return -1;
    return _c;
}

function veil_closing_progress() {
    var _c = veil_closing_current();
    if (_c < 0) return 1;
    var _def = global.VEIL_CLOSING[_c];
    return clamp(veil_closing_value(_def.key) / _def.target, 0, 1);
}

function veil_closing_ready() {
    var _c = veil_closing_current();
    if (_c < 0) return false;
    var _def = global.VEIL_CLOSING[_c];
    return veil_closing_value(_def.key) >= _def.target;
}

/// Claiming the current closing is the only way the layer moves forward.
function veil_closing_claim() {
    var _c = veil_closing_current();
    if (_c < 0 || !veil_closing_ready()) return false;
    var _o = global.G.occult;
    _o.closes_done[_c] = 1;
    _o.closings = _c + 1;
    _o.blood += 1;
    _o.gift += 2;
    save_write();
    return true;
}

// ---------------------------------------------------------------- omens

function veil_omens() {
    return [
        { title: "THE KNOCK", text: "SOMETHING IS AT THE PANTRY DOOR.",
          a: "OPEN IT", b: "BOLT IT" },
        { title: "THE SPILL", text: "A CUP TIPPED OVER. IT IS NOT TEA.",
          a: "LAP IT UP", b: "WIPE IT AWAY" },
        { title: "THE STARING CAT", text: "IT HAS NOT BLINKED ONCE.",
          a: "STARE BACK", b: "LOOK AWAY" },
        { title: "THE COLD SPOT", text: "THE AIR HERE REMEMBERS WINTER.",
          a: "STEP IN", b: "STEP BACK" },
        { title: "THE CHOIR", text: "SOMETHING HUMS UNDER THE FLOOR.",
          a: "HUM ALONG", b: "STAY SILENT" },
        { title: "THE MIRROR", text: "YOUR REFLECTION IS ONE BREATH LATE.",
          a: "TOUCH IT", b: "COVER IT" },
        { title: "THE GIFT", text: "A SMALL PARCEL, WARM TO THE TOUCH.",
          a: "TAKE IT", b: "REFUSE IT" },
        { title: "THE HOUR", text: "THE CLOCK HAS STOPPED AT 3:33.",
          a: "WAIT", b: "LEAVE" },
        { title: "THE HUNGRY CAT", text: "IT SITS BY YOUR EMPTY PLATE.",
          a: "FEED IT", b: "SHOO IT" },
        { title: "THE NINTH CANDLE", text: "IT WAS NOT LIT A MOMENT AGO.",
          a: "LIGHT IT", b: "SNUFF IT" }
    ];
}

function veil_omen_roll() {
    var _o = global.G.occult;
    _o.omen.id = irandom(9);
    _o.omen.t = 0;
    _o.omen.next = (240 + irandom(180)) * (1 + 0.5 * veil_lvl("omenward"));
    _o.stats.omens += 1;
    save_write();
}

/// Choices are real trades: every gain here costs something elsewhere.
function veil_omen_apply(_choice) {
    var _o = global.G.occult;
    var _id = _o.omen.id;
    if (_id < 0) return false;
    switch (_id) {
        case 0:
            if (_choice == 0) { veil_gain_whispers(2); veil_curse_add(-1); }
            else veil_gain_embers(14);
            break;
        case 1:
            if (_choice == 0) { veil_gain_embers(22); _o.whispers = max(0, _o.whispers - 2); }
            else veil_gain_whispers(3);
            break;
        case 2:
            if (_choice == 0) { _o.buff.kind = 2; _o.buff.t = 120; }
            else veil_gain_embers(12);
            break;
        case 3:
            if (_choice == 0) veil_gain_whispers(3);
            else veil_gain_embers(16);
            break;
        case 4:
            if (_choice == 0) { _o.buff.kind = 1; _o.buff.t = 180; }
            else veil_gain_embers(13);
            break;
        case 5:
            if (_choice == 0) { veil_gain_whispers(2); veil_curse_add(-1); }
            else veil_gain_embers(11);
            break;
        case 6:
            if (_choice == 0) {
                for (var _i = 0; _i < 3; _i++) {
                    _o.bench.reagents[irandom(VEIL_REAGENTS - 1)] += 2;
                }
            } else veil_gain_embers(20);
            break;
        case 7:
            if (_choice == 0) veil_gain_whispers(4);
            else veil_gain_embers(15);
            break;
        case 8:
            if (_choice == 0) {
                _o.embers = max(0, _o.embers - 10);
                if (random(1) < veil_relic_chance() + 0.25) veil_relic_grant(-1);
            } else veil_gain_embers(9);
            break;
        case 9:
            if (_choice == 0) _o.blood += 1;
            else veil_gain_embers(28);
            break;
    }
    _o.omen.id = -1;
    _o.omen.t = 0;
    save_write();
    return true;
}

// ---------------------------------------------------------------- long night

function veil_night_tier(_depth) {
    if (_depth < 3) return 0;
    if (_depth < 7) return 1;
    return 2;
}

/// The endgame: one case after another, never resetting the collection. It is
/// the only place where the case tier keeps climbing without new content.
function veil_night_start() {
    var _o = global.G.occult;
    if (!veil_loc_open(5)) return false;
    var _n = _o.night;
    _n.active = true;
    _n.depth = 1;
    _n.nerve = 4 + veil_lvl("nightglass") + arc_night_nerve();
    _n.seed = irandom(999999) + 1;
    _n.tier = 0;
    _n.tries = 0;
    _n.feedback = "THIRTEEN CANDLES. ONE OF THEM IS YOURS.";
    veil_seance_reset(_n, 0);
    _o.stats.nights += 1;
    save_write();
    return true;
}

function veil_night_advance() {
    var _o = global.G.occult;
    var _n = _o.night;
    if (!_n.active || !_n.solved) return false;
    _n.depth += 1;
    _o.night_best = max(_o.night_best, _n.depth);
    _n.feedback = "DEPTH " + string(_n.depth) + ". THE HALL BREATHES.";

    if (_n.depth mod 3 == 0) {
        _o.blood += 1;
        var _cost = 2 + (_n.depth div 9);
        if (_n.nerve >= _cost) {
            _n.nerve -= _cost;
            _n.feedback = "A PRESENCE PASSES. NERVE -" + string(_cost) + ".";
        } else {
            _n.active = false;
            _n.feedback = "THE PRESENCE TAKES THE REST. DEPTH " + string(_n.depth) + ".";
            save_write();
            return true;
        }
    }
    if (_n.depth >= VEIL_DEPTH_END && !_o.ending) {
        _o.ending = true;
        _o.blood += 3;
        veil_relic_grant(39);
        _n.feedback = "THE NINE OF THEM TURN TO LOOK AT YOU. THE NIGHT OPENS AGAIN.";
    }
    // Every depth pays a little and asks a little more, so the endgame keeps
    // scaling after the apparent ending instead of stopping at a wall.
    veil_gain_embers(5 + _n.depth * 2);
    veil_gain_whispers(0.5 + _n.depth * 0.1);
    var _tier = veil_night_tier(_n.depth);
    veil_seance_reset(_n, _tier);
    _n.nerve = min(_n.nerve + (veil_lvl("nightglass") > 0 ? 1 : 0), 4 + veil_lvl("nightglass"));
    save_write();
    return true;
}

function veil_night_give_up() {
    var _o = global.G.occult;
    if (!_o.night.active) return false;
    _o.night.active = false;
    _o.night_best = max(_o.night_best, _o.night.depth);
    _o.night.feedback = "YOU WAKE AT THE TABLE. THE CANDLES ARE BACK.";
    save_write();
    return true;
}

// ---------------------------------------------------------------- tick

function veil_tick(_dt) {
    if (!variable_global_exists("G") || !variable_struct_exists(global.G, "occult")) return;
    var _o = global.G.occult;
    if (!_o.found) return;

    if (_o.buff.t > 0) {
        _o.buff.t -= _dt;
        if (_o.buff.t <= 0) { _o.buff.t = 0; _o.buff.kind = 0; }
    }
    veil_garden_tick(_dt);

    if (!_o.in_hollow) return;

    // The cafe keeps earning while you are under it; the Hollow never taxes it.
    if (econ_rate() > 0) {
        var _g = econ_rate() * 0.10 * _dt;
        global.G.fish += _g;
        global.G.run_earned += _g;
        global.G.lifetime_earned += _g;
    }

    if (_o.omen.id < 0) {
        _o.omen.t += _dt;
        if (_o.omen.t >= _o.omen.next) veil_omen_roll();
    }

    veil_familiar_tick(_dt);
}
