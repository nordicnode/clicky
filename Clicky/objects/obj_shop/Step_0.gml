/// @description hover + click on the native shop rail
hover_i = -1;
pulse += 0.09;

// Only auto-scroll when a new tier unlocks; otherwise manual scrolling sticks.
var _latest = 0;
for (var _i = 0; _i < TIER_COUNT; _i++) {
    if (econ_unlocked(_i)) _latest = _i;
}
if (_latest > last_unlocked) {
    shop_top = clamp(_latest - SHOP_ROWS + 1, 0, max(0, TIER_COUNT - SHOP_ROWS));
    last_unlocked = _latest;
}

// a card on screen owns the mouse
if (ui_modal_open() || guide_card_active()) exit;

var _batch = shop_batch_rect();
if (dui_clicked(_batch.x, _batch.y, _batch.w, _batch.h)) {
    buy_cycle();
    sfx(snd_pop1, 1.1);
    exit;
}

// The service counter opens after the first handful of cats have arrived.
var _svc = shop_service_rect();
if (service_unlocked() && dui_clicked(_svc.x, _svc.y, _svc.w, _svc.h)) {
    sfx(snd_pop2, 1);
    ui_card_spawn(obj_service);
    exit;
}

// wheel scrolls only while the pointer is over the rail; the room stays the
// room. The two arrows are always available for a player without a wheel.
var _max_top = max(0, TIER_COUNT - SHOP_ROWS);
if (dui_hover(PANEL_X, PANEL_Y, PANEL_W, PANEL_H)) {
    if (mouse_wheel_up())   shop_top = clamp(shop_top - 1, 0, _max_top);
    if (mouse_wheel_down()) shop_top = clamp(shop_top + 1, 0, _max_top);
}
var _arrows = shop_arrow_rects();
if (dui_clicked(_arrows[0].x, _arrows[0].y, _arrows[0].w, _arrows[0].h)) {
    shop_top = clamp(shop_top - 1, 0, _max_top);
    sfx(snd_pop1, 1.2);
}
if (dui_clicked(_arrows[1].x, _arrows[1].y, _arrows[1].w, _arrows[1].h)) {
    shop_top = clamp(shop_top + 1, 0, _max_top);
    sfx(snd_pop1, 1.2);
}

for (var i = shop_top; i < min(TIER_COUNT, shop_top + SHOP_ROWS); i++) {
    if (i < 0) continue;
    var _r = shop_row_rect(i);
    if (dui_hover(_r.x, _r.y, _r.w, _r.h)) {
        hover_i = i;
        if (mouse_check_button_pressed(mb_left)) buy(i);
    }
}
if (hover_lock >= 0) hover_i = hover_lock;

// the dock under the rail: cats, layers, boosts, more
var _dock = shop_dock_rects();
if (dui_clicked(_dock[0].x, _dock[0].y, _dock[0].w, _dock[0].h)
    && !instance_exists(obj_album)) {
    sfx(snd_pop2, 1);
    ui_card_spawn(obj_album);
}
if (dui_clicked(_dock[1].x, _dock[1].y, _dock[1].w, _dock[1].h)
    && !instance_exists(obj_prestige)) {
    sfx(snd_pop2, 1);
    ui_card_spawn(obj_prestige);
}
if (dui_clicked(_dock[2].x, _dock[2].y, _dock[2].w, _dock[2].h)
    && !instance_exists(obj_upgrades)) {
    sfx(snd_pop2, 1);
    ui_card_spawn(obj_upgrades);
}
if (dui_clicked(_dock[3].x, _dock[3].y, _dock[3].w, _dock[3].h)
    && !instance_exists(obj_settings) && !instance_exists(obj_stickers)) {
    sfx(snd_pop2, 1);
    ui_card_spawn(obj_settings);
}
