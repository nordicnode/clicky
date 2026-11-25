/// @description trade the layer below for this layer's currency
t    = 0;
var _c = prestige_card_rect();
cx   = _c.x;
cy   = _c.y;
cw   = _c.w;
ch   = _c.h;

// open on the deepest reset the player can actually do
selected_layer = 0;
for (var i = 0; i < LAYER_COUNT; i++) {
    if (layer_unlocked(i) && layer_can(i)) selected_layer = i;
}
gain    = layer_gain(selected_layer);
can     = gain > 0;
closing = -1;
yarn_ball = 0;      // spins up before the reset lands
flash   = 0;

/// One layout shared by input and drawing, derived from currently open layers.
tab_layout = function() {
    var _u = prestige_ui();
    var _gap = 12;
    var _list = [];
    var _width = 0;
    for (var _i = 0; _i < LAYER_COUNT; _i++) {
        if (layer_unlocked(_i)) {
            var _w = dui_pill_w(global.LAYER[_i].name) + 16;
            array_push(_list, { index: _i, width: _w, left: 0 });
            _width += _w + _gap;
        }
    }
    var _left = _u.card.x + round((_u.card.w - (_width - _gap)) * 0.5);
    for (var _i = 0; _i < array_length(_list); _i++) {
        _list[_i].left = _left;
        _left += _list[_i].width + _gap;
    }
    return _list;
};

pick = function(_i) {
    selected_layer = _i;
    gain  = layer_gain(selected_layer);
    can   = gain > 0;
};
