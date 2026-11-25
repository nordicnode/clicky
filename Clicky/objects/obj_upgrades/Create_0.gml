/// @description the BOOST card: one charm tree per reset layer (native 1920)
// Card at 340..1580, 96..1016. Header 160, six 100px rows, a 12px gap.
BX = BOOST_X;
BY = BOOST_Y;
BW = BOOST_W;
BH = BOOST_H;

TAB_Y  = BY + 92;
TAB_H  = UI_H_ROW;
ROW_Y0 = BY + 176;
ROW_H  = 100;
ROW_GAP = 12;
ROWS   = 6;

ROW_X = BX + 32;
ROW_W = BW - 64;
ROW_R = ROW_X + ROW_W - 24;

TEXT_X = ROW_X + 112;
BAR_X  = ROW_X + 112;
BAR_W  = 820;
BAR_DY = 78;

tab    = 0;
scroll = 0;
closing = -1;
t      = 0;

up_card_rect = function() {
    return { x: BX, y: BY, w: BW, h: BH };
};

up_batch_rect = function() {
    return { x: BX + BW - 340, y: BY + 24, w: UI_W_CONTROL, h: UI_H_CONTROL };
};

up_help_rect = function() {
    return { x: BX + BW - 128, y: BY + 24, w: UI_W_SQUARE, h: UI_H_CONTROL };
};

up_close_rect = function() {
    return { x: BX + BW - 72, y: BY + 24, w: UI_W_SQUARE, h: UI_H_CONTROL };
};

up_arrow_rects = function() {
    return [
        { x: BX + BW - 104, y: BY + 92, w: UI_W_SQUARE, h: UI_H_CONTROL },
        { x: BX + BW - 56,  y: BY + 92, w: UI_W_SQUARE, h: UI_H_CONTROL }
    ];
};

/// A tree only appears once the player has ever touched that layer, so the
/// first card is not a wall of question marks.
tab_visible = function(_i) {
    return layer_unlocked(_i);
};

list = function() {
    return up_of_layer(tab);
};

row_at = function(_r) {
    return ROW_Y0 + _r * (ROW_H + ROW_GAP);
};

up_row_rect = function(_r) {
    return { x: ROW_X, y: row_at(_r), w: ROW_W, h: ROW_H };
};

try_buy = function(_r) {
    var _l = list();
    if (_r < 0 || _r >= array_length(_l)) return false;
    var _id = _l[_r].id;
    var _n = buy_count();
    if (!up_affordable_bulk(_id, _n)) return false;
    var _bought = up_buy_bulk(_id, _n);
    if (_bought <= 0) return false;
    sfx(snd_buy, 1);
    juice_pop(150, 150, 7, spr_fx_sparkle);
    if (_bought > 1) {
        juice_floater(150, 138, "+" + string(_bought), P_CORAL, false);
    }
    save_touch();
    return true;
};

close = function() {
    if (closing < 0) closing = t;
};
