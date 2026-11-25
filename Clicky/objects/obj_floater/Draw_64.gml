/// @description floating gain text, native 1920 GUI
if (ui_modal_open()) exit;
dui_begin();

var _fa = clamp(life / 14, 0, 1);
var _fx = x * UI_LEGACY_S;
var _fy = y * UI_LEGACY_S;
var _ff = big ? global.fnt_big : global.fnt_small;
draw_set_alpha(_fa * 0.65);
dui_text(_fx + 2, _fy + 2, txt, _ff, P_INK, fa_center);
draw_set_alpha(_fa);
dui_text(_fx, _fy, txt, _ff, col, fa_center);
draw_set_alpha(1);
