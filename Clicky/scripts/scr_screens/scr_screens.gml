/// @description card-screen lifecycle: one list, one stack, one z-order
///
/// A card is a screen that dims the room, owns the pointer and pauses the
/// ambient overlays. The Hollow is a destination, not a card. Callers open a
/// card through ui_card_spawn() and never pass a depth: this module stacks the
/// new card above whatever card is already open. The stack is derived from the
/// live instances, so there is no parallel list that can drift out of date.

#macro UI_CARD_Z -10000
// The welcome card is intentionally behind the HUD: it must not dim the top bar
// the player is meant to see while the offline gain is explained.
#macro UI_WELCOME_Z 940

/// The one registry. Adding a card screen means adding it here once; modal,
/// depth and input policy elsewhere use this list instead of copying it.
function ui_cards() {
    return [
        obj_welcome,
        obj_service,
        obj_upgrades,
        obj_album,
        obj_cat_arc,
        obj_venue_arc,
        obj_prestige,
        obj_settings,
        obj_stickers
    ];
}

/// True while any card owns the screen. Screens that need "the Hollow too"
/// use ui_modal_open(); screens that only care about café cards use this.
function ui_card_open() {
    var _cards = ui_cards();
    for (var _i = 0; _i < array_length(_cards); _i++) {
        if (instance_exists(_cards[_i])) return true;
    }
    return false;
}

/// The next depth above the current stack. Never stored: counting existing
/// cards is the stack, so a destroyed child cannot leave a stale level.
function ui_card_depth() {
    var _cards = ui_cards();
    var _n = 0;
    for (var _i = 0; _i < array_length(_cards); _i++) {
        if (instance_exists(_cards[_i])) _n += 1;
    }
    return UI_CARD_Z - _n;
}

/// The only way a card is created. Returns the instance so the opener can seed
/// it (for example the settings card's first guide page) without a lookup.
function ui_card_spawn(_obj) {
    var _z = (_obj == obj_welcome) ? UI_WELCOME_Z : ui_card_depth();
    return instance_create_depth(0, 0, _z, _obj);
}

/// A card owns the pointer; the Hollow owns the whole room. Both suppress the
/// café HUD and world input, so they share one predicate.
function ui_modal_open() {
    return ui_card_open() || veil_active();
}
