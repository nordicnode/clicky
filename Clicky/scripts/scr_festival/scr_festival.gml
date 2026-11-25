/// The Moon reset reveals a festival circuit. Recipes learned at the service
/// counter become menu cards; festival progress survives all prestige resets.
#macro FESTIVAL_VENUES 9
#macro FESTIVAL_RANKS 3

function festival_defaults() {
    return { ranks: array_create(FESTIVAL_VENUES, 0), menu: [-1, -1, -1], pending: 0 };
}

function festival_normalize() {
    var _f = global.G.festival;
    if (!is_array(_f.ranks)) _f.ranks = [];
    if (!is_array(_f.menu)) _f.menu = [-1, -1, -1];
    var _old_menu = array_length(_f.menu);
    array_resize(_f.ranks, FESTIVAL_VENUES);
    array_resize(_f.menu, 3);
    for (var _i = _old_menu; _i < 3; _i++) _f.menu[_i] = -1;
}

function festival_unlocked() {
    return global.G.earned.moon > 0;
}

/// Each rank changes its exact menu composition, so the previous winning
/// menu cannot also pass the next rank. The second rule requires variety.
function festival_venues() {
    static _venues = [
        { name: "GARDEN PICNIC", material: "scraps", label: "SCRAP", challenges: [
            [{ kind: "base", item: 2, count: 2 }, { kind: "guests", count: 2 }],
            [{ kind: "base", item: 2, count: 1 }, { kind: "toppings", count: 2 }],
            [{ kind: "base", item: 2, count: 0 }, { kind: "guests", count: 3 }] ] },
        { name: "BERRY SOCIAL", material: "treats", label: "TREAT", challenges: [
            [{ kind: "topping", item: 1, count: 2 }, { kind: "bases", count: 2 }],
            [{ kind: "topping", item: 1, count: 1 }, { kind: "toppings", count: 3 }],
            [{ kind: "topping", item: 1, count: 0 }, { kind: "guests", count: 3 }] ] },
        { name: "FRIENDS TABLE", material: "dust", label: "DUST", challenges: [
            [{ kind: "guests", count: 1 }, { kind: "bases", count: 3 }],
            [{ kind: "guests", count: 2 }, { kind: "base_min", item: 2, count: 2 }],
            [{ kind: "guests", count: 3 }, { kind: "toppings", count: 3 }] ] },
        { name: "TASTING TOUR", material: "scraps", label: "SCRAP", challenges: [
            [{ kind: "bases", count: 1 }, { kind: "guests", count: 2 }],
            [{ kind: "bases", count: 2 }, { kind: "toppings", count: 3 }],
            [{ kind: "bases", count: 3 }, { kind: "guests", count: 2 }] ] },
        { name: "PAIRING NIGHT", material: "treats", label: "TREAT", challenges: [
            [{ kind: "topping", item: 2, count: 2 }, { kind: "bases", count: 2 }],
            [{ kind: "topping", item: 2, count: 1 }, { kind: "base_min", item: 1, count: 2 }],
            [{ kind: "topping", item: 2, count: 0 }, { kind: "bases", count: 3 }] ] },
        { name: "MOON BANQUET", material: "dust", label: "DUST", challenges: [
            [{ kind: "toppings", count: 1 }, { kind: "guests", count: 2 }],
            [{ kind: "toppings", count: 2 }, { kind: "guests", count: 3 }],
            [{ kind: "toppings", count: 3 }, { kind: "bases", count: 3 }] ] },
        { name: "NIGHT MARKET", material: "dust", label: "DUST", challenges: [
            [{ kind: "topping", item: 1, count: 2 }, { kind: "guests", count: 2 }],
            [{ kind: "topping", item: 0, count: 1 }, { kind: "bases", count: 3 }],
            [{ kind: "topping", item: 2, count: 0 }, { kind: "guests", count: 3 }] ] },
        { name: "HARVEST FAIR", material: "scraps", label: "SCRAP", challenges: [
            [{ kind: "guests", count: 3 }, { kind: "bases", count: 3 }],
            [{ kind: "base", item: 0, count: 2 }, { kind: "toppings", count: 2 }],
            [{ kind: "base", item: 1, count: 1 }, { kind: "guests", count: 3 }] ] },
        { name: "STAR BANQUET", material: "treats", label: "TREAT", challenges: [
            [{ kind: "toppings", count: 3 }, { kind: "guests", count: 2 }],
            [{ kind: "base", item: 2, count: 2 }, { kind: "toppings", count: 3 }],
            [{ kind: "topping", item: 0, count: 0 }, { kind: "bases", count: 3 }] ] }
    ];
    return _venues;
}

function festival_venue_open(_venue) {
    return festival_unlocked() && _venue >= 0 && _venue < FESTIVAL_VENUES
        && (_venue == 0 || global.G.festival.ranks[_venue - 1] > 0);
}

function festival_recipe_known(_slot) {
    return _slot >= 0 && _slot < SERVICE_GUESTS * SERVICE_RECIPES
        && global.G.service.known_base[_slot] >= 0 && global.G.service.known_topping[_slot] >= 0;
}

/// Cycle discovered dishes only; -1 remains the empty slot if none are known.
function festival_cycle(_slot, _direction) {
    if (_slot < 0 || _slot >= 3 || global.G.festival.pending > 0) return false;
    var _count = SERVICE_GUESTS * SERVICE_RECIPES;
    var _current = global.G.festival.menu[_slot];
    if (_current < 0 || _current >= _count) _current = _direction > 0 ? -1 : 0;
    for (var _i = 0; _i < _count; _i++) {
        _current = (_current + _direction + _count) mod _count;
        if (festival_recipe_known(_current)) {
            global.G.festival.menu[_slot] = _current;
            save_write();
            return true;
        }
    }
    return false;
}

/// The same authored rules generate both the instructions and failure text.
function festival_rule_label(_rule, _exact) {
    var _prefix = _exact ? "EXACTLY " : "AT LEAST ";
    var _count = string(_rule.count);
    var _bases = ["FISH", "CREAM", "GREENS"];
    var _toppings = ["CRUNCH", "BERRY", "HERBS"];
    switch (_rule.kind) {
        case "base":
        case "base_min": return _prefix + _count + " " + _bases[_rule.item] + " DISHES";
        case "topping": return _prefix + _count + " " + _toppings[_rule.item] + " DISHES";
        case "guests": return _prefix + _count + " DIFFERENT GUESTS";
        case "bases": return _prefix + _count + " DIFFERENT BASES";
        case "toppings": return _prefix + _count + " DIFFERENT TOPPINGS";
    }
    return "";
}

function festival_rule_value(_rule, _base_counts, _top_counts, _guests, _bases, _toppings) {
    switch (_rule.kind) {
        case "base":
        case "base_min": return _base_counts[_rule.item];
        case "topping": return _top_counts[_rule.item];
        case "guests": return _guests;
        case "bases": return _bases;
        case "toppings": return _toppings;
    }
    return 0;
}

/// Returns the first actionable problem without spending materials. Once the
/// menu is complete, each rule reports its current count and its requirement.
function festival_evaluate(_venue) {
    var _rank = global.G.festival.ranks[_venue];
    if (_rank >= FESTIVAL_RANKS) return { valid: false, message: "VENUE MASTERED" };
    var _menu = global.G.festival.menu;
    var _base_counts = [0, 0, 0], _top_counts = [0, 0, 0];
    var _guests = array_create(SERVICE_GUESTS, 0);
    var _guest_count = 0, _base_variety = 0, _top_variety = 0;
    for (var _i = 0; _i < 3; _i++) {
        var _dish = _menu[_i];
        if (!festival_recipe_known(_dish)) return { valid: false, message: "FILL ALL 3 MENU SLOTS" };
        for (var _j = 0; _j < _i; _j++) {
            if (_menu[_j] == _dish) return { valid: false, message: "CHOOSE 3 DIFFERENT DISHES" };
        }
        var _guest = _dish div SERVICE_RECIPES;
        var _base = global.G.service.known_base[_dish];
        var _top = global.G.service.known_topping[_dish];
        if (!_guests[_guest]) { _guests[_guest] = 1; _guest_count += 1; }
        if (_base_counts[_base] == 0) _base_variety += 1;
        if (_top_counts[_top] == 0) _top_variety += 1;
        _base_counts[_base] += 1;
        _top_counts[_top] += 1;
    }
    var _rules = festival_venues()[_venue].challenges[_rank];
    for (var _i = 0; _i < 2; _i++) {
        var _rule = _rules[_i];
        var _value = festival_rule_value(_rule, _base_counts, _top_counts,
                                         _guest_count, _base_variety, _top_variety);
        var _exact = _i == 0;
        if ((_exact && _value != _rule.count) || (!_exact && _value < _rule.count)) {
            return { valid: false, message: "HAVE " + string(_value) + " - "
                     + festival_rule_label(_rule, _exact) };
        }
    }
    return { valid: true, message: "MENU READY" };
}

function festival_cost(_venue) {
    return 2 + global.G.festival.ranks[_venue];
}

function festival_enter(_venue) {
    if (!festival_venue_open(_venue) || global.G.festival.pending > 0
        || global.G.festival.ranks[_venue] >= FESTIVAL_RANKS) return false;
    var _v = festival_venues()[_venue];
    var _result = festival_evaluate(_venue);
    var _cost = max(0, festival_cost(_venue) - arc_festival_discount());
    if (!_result.valid || global.G.journal.materials[$ _v.material] < _cost) return false;
    global.G.journal.materials[$ _v.material] -= _cost;
    global.G.festival.ranks[_venue] += 1;
    // Pending reward is stored so closing or reloading cannot lose it.
    global.G.festival.pending = global.G.festival.ranks[_venue];
    save_write();
    return true;
}

/// Pick one: crafting supplies, journal stamps, or spendable Moon currency.
function festival_reward(_choice) {
    var _rank = global.G.festival.pending;
    if (_rank <= 0 || _choice < 0 || _choice > 2) return false;
    if (_choice == 0) {
        global.G.journal.materials.scraps += 6 * _rank;
        global.G.journal.materials.treats += 6 * _rank;
        global.G.journal.materials.dust += 6 * _rank;
    } else if (_choice == 1) {
        global.G.journal.stamps += 2 * _rank;
    } else {
        global.G.layers.moon += _rank;
    }
    global.G.festival.pending = 0;
    save_write();
    return true;
}
