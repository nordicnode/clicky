/// @description draw particle
var _a = clamp(life / total, 0, 1);
var _sc = 0.55 + 0.45 * _a;
var _n = sprite_get_number(spr);
draw_sprite_ext(spr, floor((1 - _a) * _n) mod _n, x, y, _sc, _sc, rot, c_white, _a);
