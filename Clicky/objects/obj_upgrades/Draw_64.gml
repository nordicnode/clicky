/// @description the BOOST card, native 1920 GUI
dui_begin();
dui_pixel_scene(3, 1);
// The 4x backdrop is scenery, not interface: push it back before the card.
dui_dim(0.62);
dui_nine(spr_ui_panel, BX, BY, BW, BH, 6);

var _key = global.LAYER[tab].key;
var _held = floor(global.G.layers[$ _key]);

dui_text(BX + 32, BY + 20, "BOOST", global.fnt_big, P_INK, fa_left);
dui_text(BX + BW - 360, BY + 38, fmt_number(_held) + " " + global.LAYER[tab].name,
         global.fnt_small, P_BROWN, fa_right);

var _br = up_batch_rect();
dui_pill(_br.x, _br.y, _br.w, _br.h, buy_label(), false,
         dui_hover(_br.x, _br.y, _br.w, _br.h));
dui_square(up_help_rect(), "?");
dui_square(up_close_rect(), "X");

// tabs: each as wide as its word
var _tx = BX + 32;
for (var i = 0; i < LAYER_COUNT; i++) {
    if (!tab_visible(i)) continue;
    var _w = dui_pill_w(global.LAYER[i].name);
    dui_pill(_tx, TAB_Y, _w, TAB_H, global.LAYER[i].name, i == tab,
             dui_hover(_tx, TAB_Y, _w, TAB_H));
    _tx += _w + 10;
}

draw_set_colour(P_WOOD);
draw_rectangle(BX + 32, BY + 156, BX + BW - 32, BY + 158, false);

// charm rows
var _l = up_of_layer(tab);
for (var r = 0; r < ROWS; r++) {
    var _idx = scroll + r;
    if (_idx >= array_length(_l)) break;
    var _u  = _l[_idx];
    var _row = up_row_rect(r);
    var _lvl = up_level(_u.id);
    var _max = _u.max;
    var _qty = buy_count();
    var _can = up_affordable_bulk(_u.id, _qty);
    var _done = (_lvl >= _max);
    var _hot = dui_hover(_row.x, _row.y, _row.w, _row.h);

    dui_nine(spr_ui_row, _row.x, _row.y, _row.w, _row.h, 4);
    if (_can) {
        draw_set_alpha(0.14);
        draw_set_colour(P_GOLD);
        draw_roundrect_ext(_row.x + 2, _row.y + 2, _row.x + _row.w - 2,
                           _row.y + _row.h - 2, 6, 6, false);
        draw_set_alpha(1);
    }
    if (_hot && !_done) {
        draw_set_alpha(0.08);
        draw_set_colour(P_WHITE);
        draw_roundrect_ext(_row.x + 2, _row.y + 2, _row.x + _row.w - 2,
                           _row.y + _row.h - 2, 6, 6, false);
        draw_set_alpha(1);
    }

    // One icon plate, one icon centre, one text column: every row aligns.
    var _icy = _row.y + 44;
    dui_icon_plate(_row.x + 52, _icy, 1);
    dui_icon_fit(up_icon(_u.id), _row.x + 52, _icy, 46, 46, 1);
    dui_text(TEXT_X, _row.y + 14, _u.name, global.fnt_small,
             _done ? P_WOOD : P_INK, fa_left);
    dui_text(TEXT_X, _row.y + 44, _u.desc, global.fnt_small, P_BROWN, fa_left);

    // progress is always visible and always measured against this charm's max
    var _p = up_progress(_u.id);
    draw_set_colour(P_INK);
    draw_roundrect_ext(BAR_X, _row.y + BAR_DY, BAR_X + BAR_W,
                       _row.y + BAR_DY + 12, 6, 6, false);
    draw_set_colour(P_BROWN);
    draw_roundrect_ext(BAR_X + 2, _row.y + BAR_DY + 2, BAR_X + BAR_W - 2,
                       _row.y + BAR_DY + 10, 4, 4, false);
    if (_p > 0) {
        var _fill = BAR_X + 2 + max(4, floor((BAR_W - 4) * _p));
        draw_set_colour(_done ? P_MINT : P_GOLD);
        draw_roundrect_ext(BAR_X + 2, _row.y + BAR_DY + 2, _fill,
                           _row.y + BAR_DY + 10, 4, 4, false);
        draw_set_alpha(0.30);
        draw_set_colour(P_WHITE);
        draw_rectangle(BAR_X + 4, _row.y + BAR_DY + 4, _fill - 2,
                       _row.y + BAR_DY + 5, false);
        draw_set_alpha(1);
    }

    dui_text(ROW_R, _row.y + 14, string(_lvl) + " / " + string(_max),
             global.fnt_small, P_BROWN, fa_right);
    if (_done) {
        dui_text(ROW_R, _row.y + 48, "MAXED", global.fnt_small, P_BROWN, fa_right);
    } else {
        var _price = (_qty == 0) ? up_cost(_u.id) : up_bulk_cost(_u.id, _qty);
        dui_text(ROW_R, _row.y + 48, fmt_number(_price), global.fnt_small,
                 _can ? P_CORAL : P_WOOD, fa_right);
    }
}

if (array_length(_l) == 0) {
    dui_text(BX + BW * 0.5, BY + 360, "Yarn buys these",
             global.fnt_small, P_BROWN, fa_center);
}

// scroll arrows only when the tree is longer than the card
var _max_scroll = max(0, array_length(_l) - ROWS);
var _arrows = up_arrow_rects();
if (_max_scroll > 0) {
    var _a0 = _arrows[0], _a1 = _arrows[1];
    draw_set_colour(scroll > 0 ? P_BROWN : P_WOOD);
    draw_triangle(_a0.x + 11, _a0.y + 26, _a0.x + 29, _a0.y + 26,
                  _a0.x + 20, _a0.y + 12, false);
    draw_set_colour(scroll < _max_scroll ? P_BROWN : P_WOOD);
    draw_triangle(_a1.x + 11, _a1.y + 14, _a1.x + 29, _a1.y + 14,
                  _a1.x + 20, _a1.y + 28, false);
}

dui_text(BX + BW * 0.5, BY + 884,
         "Charms are permanent. Every level survives every reset.",
         global.fnt_small, P_WOOD, fa_center);
