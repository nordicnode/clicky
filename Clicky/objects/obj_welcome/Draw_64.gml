/// @description welcome back card, native 1920 GUI
if (t > 12 && closing >= 0) exit;
dui_begin();

var _fade = clamp(t / 10, 0, 1);
if (closing >= 0) _fade = clamp(1 - (t - closing) / 12, 0, 1);
dui_dim(0.42 * _fade);

var _c = welcome_card_rect();
var _mid = _c.x + _c.w * 0.5;
dui_nine(spr_ui_panel, _c.x, _c.y, _c.w, _c.h, 6);

dui_text(_mid, _c.y + 32, "WELCOME BACK!", global.fnt_big, P_INK, fa_center);
dui_text(_mid, _c.y + 92, "You were away " + fmt_time(away_s),
         global.fnt_small, P_BROWN, fa_center);
dui_text(_mid, _c.y + 128, "The cats kept fishing!",
         global.fnt_small, P_BROWN, fa_center);

var _num = "+" + fmt_number(gain);
var _tw = dui_text_w(_num, global.fnt_big) + 56;
var _tx = _mid - _tw * 0.5;
draw_sprite_ext(spr_ui_fish_icon, 0, _tx, _c.y + 190, 2, 2, 0, c_white, 1);
dui_text(_tx + 56, _c.y + 184, _num, global.fnt_big, P_GOLD, fa_left);

var _b = { x: _mid - 120, y: _c.y + 292, w: 240, h: UI_H_CTA };
dui_button(_b.x, _b.y, _b.w, _b.h, "YAY",
           dui_hover(_b.x, _b.y, _b.w, _b.h), mouse_check_button(mb_left));
dui_text(_mid, _c.y + 374, "Offline pay is capped at 8 hours.",
         global.fnt_small, P_WOOD, fa_center);
