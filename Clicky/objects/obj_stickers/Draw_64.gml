/// @description the sticker sheet, native 1920 GUI
dui_begin();

var _fade = clamp(t / 10, 0, 1);
if (closing >= 0) _fade = clamp(1 - (t - closing) / 10, 0, 1);
dui_dim(0.62 * _fade);

var _u = stickers_ui();
var _c = _u.card;
dui_nine(spr_ui_panel, _c.x, _c.y, _c.w, _c.h, 6);

dui_text(_c.x + 40, _c.y + 30, "STICKERS", global.fnt_big, P_INK, fa_left);
dui_text(_u.close.x - 24, _c.y + 36,
         string(ach_earned()) + " / " + string(ach_count()) + " EARNED",
         global.fnt_small, P_BROWN, fa_right);
dui_square(_u.close, "X");

var _pages = ceil(ach_count() / per_page);
page = clamp(page, 0, _pages - 1);

var _cols = 4;
for (var _k = 0; _k < per_page; _k++) {
    var _i = page * per_page + _k;
    if (_i >= ach_count()) break;
    var _a = global.ACH[_i];
    var _x = _u.grid_x + (_k mod _cols) * (_u.cell_w + _u.gap);
    var _y = _u.grid_y + (_k div _cols) * (_u.cell_h + _u.gap);
    var _got = ach_has(_a.id);

    if (_got) {
        dui_nine(spr_ui_row, _x, _y, _u.cell_w, _u.cell_h, 4);
    } else {
        draw_set_alpha(0.24);
        draw_set_colour(P_INK);
        draw_roundrect_ext(_x, _y, _x + _u.cell_w, _y + _u.cell_h, 8, 8, false);
        draw_set_alpha(1);
    }

    sticker_badge(_x + (_u.cell_w - 64) * 0.5, _y + 20, 64, _a.icon, _got ? 1 : 0.22);
    var _nm = _got ? _a.name : "???";
    _nm = guide_fit_text_px(_nm, _u.cell_w - 24);
    dui_text(_x + _u.cell_w * 0.5, _y + 104, _nm, global.fnt_small,
             _got ? P_INK : P_WOOD, fa_center);
    dui_text(_x + _u.cell_w * 0.5, _y + 140,
             _got ? "EARNED" : "LOCKED", global.fnt_small,
             _got ? P_CORAL : P_WOOD, fa_center);
}

if (_pages > 1) {
    if (page > 0) {
        dui_button(_u.prev.x, _u.prev.y, _u.prev.w, _u.prev.h, "<",
                   dui_hover(_u.prev.x, _u.prev.y, _u.prev.w, _u.prev.h), false);
    } else {
        draw_set_alpha(0.4);
        dui_button(_u.prev.x, _u.prev.y, _u.prev.w, _u.prev.h, "<", false, false);
        draw_set_alpha(1);
    }
    if (page < _pages - 1) {
        dui_button(_u.next.x, _u.next.y, _u.next.w, _u.next.h, ">",
                   dui_hover(_u.next.x, _u.next.y, _u.next.w, _u.next.h), false);
    } else {
        draw_set_alpha(0.4);
        dui_button(_u.next.x, _u.next.y, _u.next.w, _u.next.h, ">", false, false);
        draw_set_alpha(1);
    }
    dui_text(_c.x + _c.w * 0.5, _c.y + 820,
             "SHEET " + string(page + 1) + " / " + string(_pages),
             global.fnt_small, P_BROWN, fa_center);
}
