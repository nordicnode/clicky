/// @description bob, invite a tap, time out politely
t += 1;
bob = sin(t * 0.09) * 3 + sin(t * 0.031) * 1.5;
life -= 1;

// a generous circle again: small things should never be fiddly
var _mx = device_mouse_x_to_gui(0) / UI_LEGACY_S;
var _my = device_mouse_y_to_gui(0) / UI_LEGACY_S;
var _hot = point_distance(_mx, _my, x, y + bob) < 20;

var _modal = ui_modal_open();
// SPARKLE HANDS reaches for it once it has settled, so a player who bought
// the charm never loses a gold sparkle to a full screen of cats.
var _auto = up_autoglean() > 0 && t > 45 && !_modal;
if (_auto || (_hot && !_modal && mouse_check_button_pressed(mb_left))) {
    global.G.stats.sparkles += 1;
    global.G.journal.materials.dust += 5;
    var _arc_spark = arc_spark_treats();
    if (_arc_spark > 0) {
        global.G.journal.materials.treats += _arc_spark;
        juice_floater(x, y + bob - 24, "+" + string(_arc_spark) + " TREAT", P_GOLD, false);
    }
    save_touch();
    global.frenzy   = 2;
    global.frenzy_t += up_frenzy_sec();
    juice_pop(x, y + bob, 6, spr_fx_sparkle);
    juice_floater(x, y + bob - 8, "DOUBLE!", P_GOLD, true);
    sfx_frenzy();
    with (obj_hud) { frenzy_kick = 1; }
    instance_destroy();
    exit;
}

if (life <= 0) {
    juice_pop(x, y + bob, 3, spr_fx_sparkle);
    instance_destroy();
}
