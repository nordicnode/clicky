/// Input for the pantry cupboard. It lives in the first room only, stays inert
/// until the cafe is far enough along, and never opens a modal: the reward is
/// the room itself.
if (!veil_door_here()) exit;

var _modal = ui_modal_open()
          || guide_card_active() || guide_strip_hover();
if (_modal) {
    hover_t = max(0, hover_t - 2);
    knock_t = max(0, knock_t - 1);
    exit;
}

if (knock_t > 0) knock_t -= 1;

// One target for the whole cupboard, so a child does not have to hit a 1px
// seam. The doors are x=144..182 and y=94..196; the frame adds a little air.
var _hx = 140, _hy = 90, _hw = 46, _hh = 116;
// GUI is 1920 now; the cupboard lives in the 480-space room.
var _mx = device_mouse_x_to_gui(0) / UI_LEGACY_S;
var _my = device_mouse_y_to_gui(0) / UI_LEGACY_S;
// The cat stands in front of the cupboard and is the larger, softer target.
// Do not let the door steal a click that landed on the cat.
hover = !veil_door_cat_claimed(_mx, _my)
        && point_in_rectangle(_mx, _my, _hx, _hy, _hx + _hw, _hy + _hh);

if (!global.G.occult.found) {
    // Dwelling on the cupboard is what reveals the seam. The cracks fade in
    // after about half a second of standing still and fade away just as quietly.
    if (hover) hover_t = min(60, hover_t + 1);
    else hover_t = max(0, hover_t - 2);

    if (hover && mouse_check_button_pressed(mb_left)) {
        global.G.occult.knocks = min(3, global.G.occult.knocks + 1);
        save_write();
        sfx(snd_pop3, 0.45 + global.G.occult.knocks * 0.12);
        knock_t = 30;
        if (global.G.occult.knocks >= 3) {
            if (veil_discover()) sfx_milestone();
        }
    }
} else {
    if (hover && mouse_check_button_pressed(mb_left)) {
        sfx(snd_pop2, 0.6);
        veil_enter();
    }
}
