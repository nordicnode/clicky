/// Café service is independent of prestige. Each guest has a favorite base and
/// topping; trying a dish gives feedback without consuming fish or materials.
#macro SERVICE_GUESTS 9
#macro SERVICE_RECIPES 3

function service_defaults() {
    return { guest: 0, base: -1, topping: -1, feedback: 0,
             served: array_create(SERVICE_GUESTS, 0),
             known_base: array_create(SERVICE_GUESTS * SERVICE_RECIPES, -1),
             known_topping: array_create(SERVICE_GUESTS * SERVICE_RECIPES, -1) };
}

/// Called after the generic save merge; the save keys and values stay unchanged.
function service_normalize() {
    var _s = global.G.service;
    if (!is_array(_s.served)) _s.served = [];
    if (!is_array(_s.known_base)) _s.known_base = [];
    if (!is_array(_s.known_topping)) _s.known_topping = [];
    var _base_count = array_length(_s.known_base);
    var _topping_count = array_length(_s.known_topping);
    array_resize(_s.served, SERVICE_GUESTS);
    array_resize(_s.known_base, SERVICE_GUESTS * SERVICE_RECIPES);
    array_resize(_s.known_topping, SERVICE_GUESTS * SERVICE_RECIPES);
    for (var _i = _base_count; _i < SERVICE_GUESTS * SERVICE_RECIPES; _i++) _s.known_base[_i] = -1;
    for (var _i = _topping_count; _i < SERVICE_GUESTS * SERVICE_RECIPES; _i++) _s.known_topping[_i] = -1;
    if (_s.guest < 0 || _s.guest >= SERVICE_GUESTS) _s.guest = 0;
}

function service_unlocked() {
    return global.G.lifetime_earned >= 1200;
}

function service_guests() {
    static _guests = [
        { name: "MOCHI", base: 0, topping: 1, album: 0, serves: 0 },
        { name: "PICKLE", base: 1, topping: 0, album: 4, serves: 2 },
        { name: "BEAN", base: 2, topping: 2, album: 8, serves: 4 },
        { name: "COMET", base: 0, topping: 2, album: 12, serves: 7 },
        { name: "SARDINE", base: 0, topping: 0, album: 14, serves: 9 },
        { name: "PUFF", base: 1, topping: 1, album: 17, serves: 11 },
        { name: "DUMPLING", base: 2, topping: 1, album: 18, serves: 13 },
        { name: "MARMALADE", base: 1, topping: 2, album: 20, serves: 16 },
        { name: "BIG BOSS", base: 2, topping: 0, album: 23, serves: 20 }
    ];
    return _guests;
}

/// Every guest rotates through three different dishes. The hint identifies the
/// base; the player experiments with toppings and keeps every discovery.
function service_recipe_slot(_guest) {
    return _guest * SERVICE_RECIPES + (global.G.service.served[_guest] mod SERVICE_RECIPES);
}

function service_recipe(_guest) {
    var _guest_info = service_guests()[_guest];
    var _dish = global.G.service.served[_guest] mod SERVICE_RECIPES;
    return { base: (_guest_info.base + _dish) mod 3,
             topping: (_guest_info.topping + _dish * 2) mod 3 };
}

function service_total() {
    var _total = 0;
    for (var _i = 0; _i < SERVICE_GUESTS; _i++) _total += global.G.service.served[_i];
    return _total;
}

function service_guest_open(_guest) {
    if (_guest < 0 || _guest >= SERVICE_GUESTS) return false;
    var _info = service_guests()[_guest];
    return album_unlocked(_info.album) && service_total() >= _info.serves;
}

function service_choose_guest(_guest) {
    if (!service_guest_open(_guest)) return false;
    global.G.service.guest = _guest;
    global.G.service.base = -1;
    global.G.service.topping = -1;
    global.G.service.feedback = 0;
    save_write();
    return true;
}

function service_choose_ingredient(_is_topping, _choice) {
    if (_choice < 0 || _choice > 2) return false;
    if (_is_topping) global.G.service.topping = _choice;
    else global.G.service.base = _choice;
    global.G.service.feedback = 0;
    save_write();
    return true;
}

/// Return a two-bit match mask. A mismatch costs nothing and can be retried.
/// A correct ingredient is recorded permanently as a recipe-book discovery.
function service_try() {
    var _s = global.G.service;
    if (!service_guest_open(_s.guest) || _s.served[_s.guest] >= SERVICE_RECIPES
        || _s.base < 0 || _s.base > 2
        || _s.topping < 0 || _s.topping > 2) return -1;
    var _recipe = service_recipe(_s.guest);
    var _slot = service_recipe_slot(_s.guest);
    var _match = 0;
    if (_s.base == _recipe.base) {
        _match += 1;
        _s.known_base[_slot] = _s.base;
    }
    if (_s.topping == _recipe.topping) {
        _match += 2;
        _s.known_topping[_slot] = _s.topping;
    }
    // 1..4 means tried, with the match mask stored as feedback - 1.
    _s.feedback = _match + 1;
    save_write();
    return _match;
}

/// Successful dishes can be exchanged for fish or journal crafting materials.
/// Each guest has three dishes; each completed dish pays its reward once.
function service_collect(_reward) {
    var _s = global.G.service;
    if (_s.feedback != 4 || _s.served[_s.guest] >= SERVICE_RECIPES
        || (_reward != 0 && _reward != 1)) return false;
    var _recipe = service_recipe(_s.guest);
    if (_s.base != _recipe.base || _s.topping != _recipe.topping) return false;
    _s.served[_s.guest] += 1;
    if (_reward == 0) {
        var _tip = service_tip();
        global.G.fish += _tip;
        global.G.run_earned += _tip;
        global.G.lifetime_earned += _tip;
    } else {
        global.G.journal.materials.scraps += 3;
        global.G.journal.materials.treats += 3;
        global.G.journal.materials.dust += 3;
    }
    var _arc_mat = arc_service_materials();
    global.G.journal.materials.treats += _arc_mat.treats;
    global.G.journal.materials.scraps += _arc_mat.scraps;
    global.G.journal.materials.dust += _arc_mat.dust;
    _s.feedback = 0;
    _s.base = -1;
    _s.topping = -1;
    save_write();
    return true;
}

function service_tip() {
    return max(100, floor(econ_rate() * 8 * up_tip_bonus()));
}
