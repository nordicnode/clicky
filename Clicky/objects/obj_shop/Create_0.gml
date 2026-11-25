/// @description shop geometry + row state (native 1920)
// The rail is 624x936 on the right edge: 96px header, ten 64px rows, a dock.
// Every rectangle is a function so Step, Draw and the harness share one map.
PANEL_X = 1264;
PANEL_Y = 112;
PANEL_W = 624;
PANEL_H = 936;

HEADER_H = 96;
ROW_H    = UI_H_NAV;
ROW_GAP  = UI_SPACE_XS;
SHOP_ROWS = 10;

ROW_X = PANEL_X + 20;
ROW_W = PANEL_W - 40;
ROW_R = ROW_X + ROW_W - 16;     // right edge for numbers
DOCK_Y = PANEL_Y + PANEL_H - 88;

shop_top  = 0;
last_unlocked = -1;
hover_lock = -1;   // set by the screenshot harness to force a hover
hover_i = -1;
pulse   = 0;

prop_spr = [
    spr_prop_box, spr_prop_bed, spr_prop_toys, spr_prop_post,
    spr_prop_jars, spr_prop_fount, spr_prop_sunbeam, spr_prop_yarnpit,
    spr_prop_mug, spr_prop_cake, spr_prop_teapot, spr_prop_lantern,
    spr_prop_quilt, spr_prop_aurora
];

shop_panel_rect = function() {
    return { x: PANEL_X, y: PANEL_Y, w: PANEL_W, h: PANEL_H };
};

shop_batch_rect = function() {
    return { x: PANEL_X + UI_SPACE_M, y: PANEL_Y + 56,
             w: UI_W_CONTROL, h: UI_H_CONTROL };
};

shop_service_rect = function() {
    return { x: PANEL_X + PANEL_W - 144, y: PANEL_Y + 16, w: 120, h: UI_H_CONTROL };
};

shop_arrow_rects = function() {
    return [
        { x: PANEL_X + PANEL_W - 100, y: PANEL_Y + 56, w: UI_H_CONTROL, h: UI_H_CONTROL },
        { x: PANEL_X + PANEL_W - 52, y: PANEL_Y + 56, w: UI_H_CONTROL, h: UI_H_CONTROL }
    ];
};

shop_row_rect = function(_i) {
    return { x: ROW_X, y: row_y(_i), w: ROW_W, h: ROW_H };
};

shop_dock_rects = function() {
    var _out = [];
    for (var _i = 0; _i < 4; _i++) {
        array_push(_out, { x: PANEL_X + 20 + _i * 148, y: DOCK_Y,
                           w: UI_W_CONTROL, h: UI_H_NAV });
    }
    return _out;
};

row_y = function(_i) {
    return PANEL_Y + HEADER_H + 12 + (_i - shop_top) * (ROW_H + ROW_GAP);
};

/// Keep the newest thing you can afford on screen without scrolling.
shop_scroll = function(_to) {
    var _want = 0;
    for (var i = 0; i < TIER_COUNT; i++) {
        if (econ_unlocked(i)) _want = i;
    }
    _want = max(_want, _to);
    shop_top = clamp(_want - SHOP_ROWS + 1, 0, max(0, TIER_COUNT - SHOP_ROWS));
};

/// One cat walks in per purchase, up to a cap so old laptops keep 60fps.
spawn_pet = function(_tier) {
    if (instance_number(obj_cat_mini) >= CAT_CAP) return;
    var _coats = ["tabby", "calico", "tuxedo", "ginger", "grey", "snow", "mint", "rose"];
    var _c = _coats[irandom(array_length(_coats) - 1)];
    var _inst = instance_create_depth(
        random_range(40, 240), random_range(236, 252), 10, obj_cat_mini);
    _inst.set_coat(_c);
};

buy = function(_tier) {
    if (!econ_unlocked(_tier)) return;
    var _before = global.G.tiers[_tier];
    var _count = buy_count();
    var _bought = econ_buy_bulk(_tier, _count);
    if (_bought <= 0) return;

    // Feedback lives in room space, near the cat, not under the native rail.
    var _tag = (_bought > 1) ? "+" + string(_bought) : "YAY";
    juice_floater(150, 150, _tag, P_CORAL, false);
    juice_pop(150, 160, 5, spr_fx_heart);
    sfx_buy();
    var _walk = min(_bought, 8);
    for (var _k = 0; _k < _walk; _k++) spawn_pet(_tier);
    if (_tier == 0) {
        var _extra = min(_walk * up_level("sky") * 2, 24);
        for (var _k2 = 0; _k2 < _extra; _k2++) spawn_pet(_tier);
    }
    save_touch();

    var _after = global.G.tiers[_tier];
    var _rungs = [up_double_step(10), up_double_step(20), up_double_step(40),
                  up_double_step(80), up_double_step(120)];
    for (var _r = 0; _r < array_length(_rungs); _r++) {
        if (_before < _rungs[_r] && _after >= _rungs[_r]) {
            juice_floater(150, 138,
                          "x" + string(econ_tier_mult(_after)), P_GOLD, true);
            juice_pop(150, 148, 14, spr_fx_sparkle);
            juice_shake(1.2);
            sfx_milestone();
            break;
        }
    }
};
