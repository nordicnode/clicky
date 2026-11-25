/// @description top status bar, native 1920 GUI
if (veil_active()) exit;   // obj_veil paints its own HUD inside its screen
dui_begin();

// One calm strip, 96px tall, with a 4px lip. Everything on it shares a
// baseline grid: icon 48, primary number 32, secondary number 18.
draw_set_alpha(0.97);
draw_set_colour(P_CREAM);
draw_rectangle(0, 0, UI_W, 96, false);
draw_set_alpha(1);
draw_set_colour(P_WOOD);
draw_rectangle(0, 96, UI_W, 100, false);
draw_set_colour(P_BROWN);
draw_rectangle(0, 100, UI_W, 104, false);

// fish + rolling odometer
draw_sprite_ext(spr_ui_fish_icon, 0, 32, 30, 2, 2, 0, c_white, 1);
if (!variable_instance_exists(id, "disp")) disp = global.G.fish;
disp += (global.G.fish - disp) * 0.28;
if (abs(global.G.fish - disp) < 0.6) disp = global.G.fish;

var _fish_txt = fmt_number(floor(disp));
dui_text(92, 20, _fish_txt, global.fnt_big, P_INK, fa_left);
var _fw = dui_text_w(_fish_txt, global.fnt_big);

var _rate = global.frenzy > 1 ? econ_live_rate() : econ_rate();
var _rate_txt = "+" + fmt_rate(_rate);
dui_text(92, 62, _rate_txt, global.fnt_small, P_INK, fa_left);
var _rate_w = dui_text_w(_rate_txt, global.fnt_small);

// combo keeps its own pill and never collides with the rate
if (variable_global_exists("combo") && global.combo >= 3) {
    var _bx = 104 + max(_fw, _rate_w) + 32;
    var _ct = "COMBO x" + string(global.combo);
    var _cw = dui_text_w(_ct, global.fnt_small) + 32;
    dui_nine(spr_ui_panel, _bx, 28, _cw, 40, 5);
    dui_text(_bx + _cw * 0.5, 38, _ct, global.fnt_small, P_CORAL, fa_center);
}

// yarn on the right, with its permanent multiplier as a separate chip
var _yarn_txt = fmt_number(global.G.layers.yarn);
var _yw = dui_text_w(_yarn_txt, global.fnt_big);
dui_text(UI_W - 88, 20, _yarn_txt, global.fnt_big, P_INK, fa_right);
draw_sprite_ext(spr_ui_yarn_icon, 0, UI_W - 64, 46, 2, 2, 0, c_white, 1);

if (econ_mult() > 1) {
    var _mt = "x" + fmt_small(econ_mult());
    var _mw = dui_text_w(_mt, global.fnt_small) + 28;
    dui_nine(spr_ui_panel, UI_W - 72 - max(_yw, 0) - 24 - _mw, 28,
             _mw, UI_H_CONTROL, 4);
    dui_text(UI_W - 72 - max(_yw, 0) - 24 - _mw * 0.5, 37, _mt,
             global.fnt_small, P_CORAL, fa_center);
}

// frenzy sits in the open middle, never over the cat
if (global.frenzy_t > 0) {
    var _secs = ceil(global.frenzy_t);
    var _ft = "FRENZY " + string(_secs) + "s";
    var _ftw = dui_text_w(_ft, global.fnt_small) + 44;
    var _fx = 700 - _ftw * 0.5;
    frenzy_kick = max(0, frenzy_kick - 0.05);

    draw_set_alpha(0.18 + 0.10 * sin(global.time * 8));
    draw_set_colour(P_CORAL);
    draw_roundrect(_fx - 6, 24, _fx + _ftw + 6, 72, false);
    draw_set_alpha(1);

    dui_nine(spr_ui_panel, _fx, 28, _ftw, 40, 5);
    dui_text(_fx + _ftw * 0.5, 38, _ft, global.fnt_small, P_CORAL, fa_center);
}

// The room rail and its one-shot room-name card belong to the native GUI, not
// to the 480x270 room canvas. obj_bg owns the input state; this owns the pixels.
if (instance_exists(obj_bg)) {
    zone_travel_draw(obj_bg.travel_open);
}
if (!ui_modal_open()) zone_banner_draw_gui();

// Overlay objects own their own native draw events. Keep this event to the
// persistent café furniture so an overlay cannot drift between owners again.
