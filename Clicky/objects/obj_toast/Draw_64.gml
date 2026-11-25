/// @description sticker toast, native 1920 GUI
if (ui_modal_open()) exit;
dui_begin();

var _in = clamp(t / 12, 0, 1);
var _out = clamp((life - t) / 12, 0, 1);
var _k = min(_in, _out);
var _x = 620;
var _y = 112 - (1 - _k) * 24;
draw_set_alpha(_k);
dui_nine(spr_ui_panel, _x, _y, 360, UI_H_NAV, 6);
var _a = global.ACH[aid];
sticker_badge(_x + 20, _y + 16, 32, _a.icon, 1);
dui_text(_x + 64, _y + 12, "NEW STICKER", global.fnt_small, P_CORAL, fa_left);
dui_text(_x + 64, _y + 36, _a.name, global.fnt_small, P_INK, fa_left);
draw_set_alpha(1);
