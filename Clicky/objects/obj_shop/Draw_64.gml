/// @description the shop rail, native 1920 GUI
dui_begin();

// A full-screen card owns the screen. Let its backdrop be the only thing
// behind it, rather than a live shop rail showing through at the edge.
if (ui_modal_open()) exit;

// --- panel board
dui_nine(spr_ui_panel, PANEL_X, PANEL_Y, PANEL_W, PANEL_H, 6);
dui_text(PANEL_X + 24, PANEL_Y + 12, "SHOP", global.fnt_big, P_INK, fa_left);

var _svc = shop_service_rect();
if (service_unlocked()) {
    dui_button(_svc.x, _svc.y, _svc.w, _svc.h, "CAFE",
               dui_hover(_svc.x, _svc.y, _svc.w, _svc.h), false);
}

// One shared batch control for every row and every charm.
if (!ui_modal_open() && !guide_card_active()) {
    var _br = shop_batch_rect();
    dui_pill(_br.x, _br.y, _br.w, _br.h, "BUY " + buy_label(), false,
             dui_hover(_br.x, _br.y, _br.w, _br.h));
}

// scroll arrows, ambient when the list is already at an end
var _arrows = shop_arrow_rects();
var _max_top = max(0, TIER_COUNT - SHOP_ROWS);
draw_set_colour(shop_top > 0 ? P_BROWN : P_WOOD);
draw_triangle(_arrows[0].x + 10, _arrows[0].y + 24, _arrows[0].x + 26, _arrows[0].y + 24,
              _arrows[0].x + 18, _arrows[0].y + 10, false);
draw_set_colour(shop_top < _max_top ? P_BROWN : P_WOOD);
draw_triangle(_arrows[1].x + 10, _arrows[1].y + 12, _arrows[1].x + 26, _arrows[1].y + 12,
              _arrows[1].x + 18, _arrows[1].y + 26, false);

// a hairline separates the header controls from the rows
draw_set_colour(P_WOOD);
draw_rectangle(PANEL_X + 24, PANEL_Y + 100, PANEL_X + PANEL_W - 24, PANEL_Y + 102, false);

for (var i = shop_top; i < min(TIER_COUNT, shop_top + SHOP_ROWS); i++) {
    var _r = shop_row_rect(i);
    var _qty  = buy_count();
    var _cost = (_qty == 0) ? econ_cost(i) : econ_bulk_cost(i, _qty);
    var _own  = global.G.tiers[i];
    var _open = econ_unlocked(i);
    var _can  = _open && ((_qty == 0) ? global.G.fish >= econ_cost(i)
                                      : global.G.fish >= _cost);
    var _hot  = (hover_i == i);

    dui_nine(spr_ui_row, _r.x, _r.y, _r.w, _r.h, 4);

    if (_can) {
        var _a = 0.14 + 0.10 * sin(pulse);
        draw_set_alpha(_a);
        draw_set_colour(P_GOLD);
        draw_roundrect_ext(_r.x + 2, _r.y + 2, _r.x + _r.w - 2, _r.y + _r.h - 2, 6, 6, false);
        draw_set_alpha(1);
    }
    if (_hot && _open) {
        draw_set_alpha(0.10);
        draw_set_colour(P_WHITE);
        draw_roundrect_ext(_r.x + 2, _r.y + 2, _r.x + _r.w - 2, _r.y + _r.h - 2, 6, 6, false);
        draw_set_alpha(1);
    }
    if (!_open) {
        draw_set_alpha(0.14);
        draw_set_colour(P_INK);
        draw_roundrect_ext(_r.x + 2, _r.y + 2, _r.x + _r.w - 2, _r.y + _r.h - 2, 6, 6, false);
        draw_set_alpha(1);
    }

    // icon plate + artwork share a fixed column, so every row lines up
    dui_icon_plate(_r.x + 38, _r.y + _r.h * 0.5, _open ? 1 : 0.55);
    dui_icon_fit(prop_spr[i], _r.x + 38, _r.y + _r.h * 0.5, 32, 32, _open ? 1 : 0.5);

    dui_text(_r.x + 78, _r.y + 7, global.TIER[i].name, global.fnt_small,
             _open ? P_INK : P_BROWN, fa_left);
    if (_own > 0) {
        dui_text(_r.x + 78, _r.y + 31, "x" + fmt_number(_own), global.fnt_small,
                 _open ? P_BROWN : P_WOOD, fa_left);
    }

    // cost, right aligned on the row's own baseline
    var _ct = fmt_number(_cost);
    var _cw = dui_text_w(_ct, global.fnt_small);
    if (_open) {
        draw_sprite_ext(spr_ui_fish_icon, 0, ROW_R - _cw - 40, _r.y + 13,
                        2, 2, 0, c_white, 1);
        dui_text(ROW_R, _r.y + 10, _ct, global.fnt_small,
                 _can ? P_INK : P_BROWN, fa_right);
    } else {
        draw_sprite_ext(spr_ui_lock, 0, ROW_R - _cw - 38, _r.y + 12,
                        2, 2, 0, c_white, 1);
        dui_text(ROW_R, _r.y + 10, _ct, global.fnt_small, P_BROWN, fa_right);
    }

    // doubling progress, measured from the same left edge as the name
    var _next = econ_next_double(_own);
    if (_next > 0) {
        var _p = clamp(_own / _next, 0, 1);
        var _bx = _r.x + 78;
        var _bw = _r.w - 94;
        draw_set_colour(P_WOOD);
        draw_rectangle(_bx, _r.y + _r.h - 11, _bx + _bw, _r.y + _r.h - 7, false);
        draw_set_colour(P_GOLD);
        draw_rectangle(_bx, _r.y + _r.h - 11, _bx + _bw * _p, _r.y + _r.h - 7, false);
    }
}

// --- hovered row explains itself in the room, to the left of the rail
if (hover_i >= 0) {
    var _ti = hover_i;
    var _hq = buy_count();
    var _base_add = econ_bulk_base_gain(_ti, (_hq == 0) ? 1 : _hq);
    var _cats = 0;
    for (var _ci = 0; _ci < TIER_COUNT; _ci++) _cats += global.G.tiers[_ci];
    _cats += global.G.tiers[0] * up_level("sky") * 2;
    _cats += 1 + (_ti == 0 ? up_level("sky") * 2 : 0);
    var _next_crew = 1 + min(CAT_CAP, _cats) * up_level("crew") * 0.02;
    var _journal_mult = 1 + journal_project_count(0) * 0.05 + global.G.journal.skills[0] * 0.10;
    var _rt = (econ_base_rate() + _base_add) * layer_mult() * up_rate_mult()
              * _next_crew * _journal_mult - econ_rate();
    var _tag = (_hq == 0) ? " max" : ((_hq == 1) ? "" : " x" + string(_hq));
    var _line = global.TIER[_ti].name + _tag + " next +" + fmt_small(_rt) + "/s";
    var _tw = dui_text_w(_line, global.fnt_small) + 40;
    var _tx = PANEL_X - 24 - _tw;
    var _ty = row_y(_ti) + 6;
    dui_nine(spr_ui_panel, _tx, _ty, _tw, 52, 5);
    dui_text(_tx + 20, _ty + 16, _line, global.fnt_small, P_INK, fa_left);
    draw_set_colour(P_BROWN);
    draw_triangle(PANEL_X - 4, _ty + 26, PANEL_X - 16, _ty + 18,
                  PANEL_X - 16, _ty + 34, false);
}

// --- dock: four doors, the things a kid wants to peek at
var _dock = shop_dock_rects();
var _have = album_unlocked_count();

var _ready = 0;
for (var _li = 0; _li < LAYER_COUNT; _li++) {
    if (layer_can(_li)) _ready = 1;
}
if (_ready > 0) {
    draw_set_alpha(0.20 + 0.14 * sin(pulse * 1.4));
    draw_set_colour(P_GOLD);
    draw_roundrect_ext(_dock[1].x - 2, _dock[1].y - 2, _dock[1].x + _dock[1].w + 2,
                       _dock[1].y + _dock[1].h + 2, 8, 8, false);
    draw_set_alpha(1);
}
if (up_any_affordable() > 0) {
    draw_set_alpha(0.20 + 0.14 * sin(pulse * 1.4));
    draw_set_colour(P_MINT);
    draw_roundrect_ext(_dock[2].x - 2, _dock[2].y - 2, _dock[2].x + _dock[2].w + 2,
                       _dock[2].y + _dock[2].h + 2, 8, 8, false);
    draw_set_alpha(1);
}

var _labels = ["CATS " + string(_have), "RESET", "BOOST", "MORE"];
for (var _di = 0; _di < 4; _di++) {
    var _d = _dock[_di];
    dui_button(_d.x, _d.y, _d.w, _d.h, _labels[_di],
               dui_hover(_d.x, _d.y, _d.w, _d.h), false);
}
