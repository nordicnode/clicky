/// @description input, combo decay, animation
if (veil_active()) exit;   // the Hollow owns the mouse while it is open
squash = lerp(squash, 1, 0.22);
idx += 0.14;

var _now = current_time;
var _window = room_combo_window(global.G.world.zone) + cat_combo_grace();
if (!cat_endless_combo() && combo > 0 && _now - last_tap > _window) combo = 0;
if (pet_t > 0) pet_t -= 1;
global.combo = combo;

// A mastered room pets itself; a generous idle rhythm, never during a card
// or while the goal strip owns the pointer.
auto_t += 1;
var _auto_every = room_auto_pet_frames(global.G.world.zone);

// pick animation
if (pet_t > 0 || combo >= 6) {
    spr = spr_cat_big_pet;
} else {
    spr = spr_cat_big_idle;
}

// hit area is a generous circle; a 10-year-old should not miss
// GUI is 1920 now; the cat lives in the 480-space room.
var _mx = device_mouse_x_to_gui(0) / UI_LEGACY_S;
var _my = device_mouse_y_to_gui(0) / UI_LEGACY_S;
hover = point_distance(_mx, _my, cx, feet - 34) < 56;

// a card on screen owns the mouse: no taps or purchases behind a modal
var _modal = ui_card_open();
// The cat is drawn in front of the pantry. Its generous hit circle wins over
// the door's rectangle, so petting is never stolen by the cupboard.
if (hover && !_modal && !guide_card_active()
    && !guide_strip_hover() && mouse_check_button_pressed(mb_left)) {
    tap();
} else if (_auto_every > 0 && auto_t >= _auto_every
           && !_modal && !guide_card_active() && !guide_strip_hover()) {
    // A room reward, not a tap: auto-petting must never advance mastery/bond.
    auto_pet();
}
