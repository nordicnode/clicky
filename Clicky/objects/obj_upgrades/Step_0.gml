/// @description tab / scroll / buy / close, native 1920
t += 1;

if (closing >= 0) {
    if (t - closing > 10) instance_destroy();
    exit;
}

// the manual can sit on top of this card; it owns the mouse while it is there
if (instance_exists(obj_settings)) exit;

var _br = up_batch_rect();
if (dui_clicked(_br.x, _br.y, _br.w, _br.h)) {
    buy_cycle();
    sfx(snd_pop1, 1.1);
    exit;
}

var _hr = up_help_rect();
if (dui_clicked(_hr.x, _hr.y, _hr.w, _hr.h)) {
    var _help = ui_card_spawn(obj_settings);
    _help.guide = 1;
    _help.guide_page = 2;
    sfx(snd_pop2, 1);
    exit;
}

// tabs, laid out with the same widths the Draw uses
var _tx = BX + 32;
for (var i = 0; i < LAYER_COUNT; i++) {
    if (!tab_visible(i)) continue;
    var _w = dui_pill_w(global.LAYER[i].name);
    if (dui_clicked(_tx, TAB_Y, _w, TAB_H) && tab != i) {
        tab = i;
        scroll = 0;
        sfx(snd_pop1, 1.3);
        exit;
    }
    _tx += _w + 10;
}

var _l = list();
var _max_scroll = max(0, array_length(_l) - ROWS);
scroll = clamp(scroll, 0, _max_scroll);
if (dui_hover(BX, BY, BW, BH)) {
    if (mouse_wheel_up())   scroll = clamp(scroll - 1, 0, _max_scroll);
    if (mouse_wheel_down()) scroll = clamp(scroll + 1, 0, _max_scroll);
}

for (var r = 0; r < ROWS; r++) {
    var _idx = scroll + r;
    if (_idx >= array_length(_l)) break;
    var _row = up_row_rect(r);
    if (dui_clicked(_row.x, _row.y, _row.w, _row.h)) try_buy(_idx);
}

var _arrows = up_arrow_rects();
if (dui_clicked(_arrows[0].x, _arrows[0].y, _arrows[0].w, _arrows[0].h)) {
    scroll = clamp(scroll - 1, 0, _max_scroll);
    sfx(snd_pop1, 1.2);
}
if (dui_clicked(_arrows[1].x, _arrows[1].y, _arrows[1].w, _arrows[1].h)) {
    scroll = clamp(scroll + 1, 0, _max_scroll);
    sfx(snd_pop1, 1.2);
}

var _xr = up_close_rect();
if (dui_clicked(_xr.x, _xr.y, _xr.w, _xr.h)) close();
if (keyboard_check_pressed(vk_escape)) close();
