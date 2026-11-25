/// @description first-run hint, native 1920 GUI
if (done || ui_modal_open()) exit;
dui_begin();

var _txt = ["TAP THE CAT", "KEEP TAPPING", "BUY A BOX", "NEW CAT!"][step];
var _bob = sin(t * 0.09) * 3;
var _w = min(dui_text_w(_txt, global.fnt_small) + 40, 360);
var _h = UI_H_CTA;
if (step == 2) {
    // The ask is a shop row, not a fixed point in the header. Aim at the
    // row's left edge, with the bubble to its left, so it still reads after
    // the rail's header and prices change.
    var _row = undefined;
    if (instance_exists(obj_shop)) {
        var _shop = instance_find(obj_shop, 0);
        _row = _shop.shop_row_rect(0);
    }
    var _px2 = is_struct(_row) ? _row.x - _w - 30 : 1240 - _w;
    var _py2 = is_struct(_row) ? _row.y + (_row.h - _h) * 0.5 + _bob : 168 + _bob;
    dui_nine(spr_ui_panel, _px2, _py2, _w, _h, 6);
    dui_text(_px2 + _w * 0.5, _py2 + 19, _txt, global.fnt_small, P_INK, fa_center);
    draw_set_colour(P_CORAL);
    var _ay = _py2 + _h * 0.5;
    var _tipx = is_struct(_row) ? _row.x - 8 : 1268 + _bob;
    draw_triangle(_px2 + _w + 10, _ay - 10, _px2 + _w + 10, _ay + 10,
                  _tipx, _ay, false);
} else {
    // Point at the big cat's head. Its origin is bottom-centre, so head top is
    // feet minus the sprite's scaled height; the arrow ends just above it.
    var _ax = 600;
    var _head_y = 600;
    if (instance_exists(obj_cat_big)) {
        var _cat = instance_find(obj_cat_big, 0);
        _ax = ui_room_to_gui(_cat.cx);
        _head_y = ui_room_to_gui(_cat.feet - sprite_get_height(_cat.spr) * _cat.S);
    }
    var _px = _ax - _w * 0.5;
    var _py = _head_y - _h - 32 + _bob;
    dui_nine(spr_ui_panel, _px, _py, _w, _h, 6);
    dui_text(_px + _w * 0.5, _py + 19, _txt, global.fnt_small, P_INK, fa_center);
    draw_set_colour(P_CORAL);
    draw_triangle(_ax - 10, _py + _h + 10, _ax + 10, _py + _h + 10,
                  _ax, _head_y - 6 + _bob, false);
}
