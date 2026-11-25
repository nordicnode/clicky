/// @description draw the cat with squash and a soft shadow
var _w = sprite_get_width(spr);
var _h = sprite_get_height(spr);
var _n = sprite_get_number(spr);
var _f = floor(idx) mod _n;

var _sy = S * squash;
var _sx = S * (1 + (1 - squash) * 0.55);

// shadow
draw_set_alpha(0.18);
draw_set_colour(P_INK);
draw_ellipse(cx - 34, feet - 6, cx + 34, feet + 4, false);
draw_set_alpha(1);

var _dx = cx - (_w * _sx) * 0.5;
var _dy = feet - (_h * _sy);

draw_sprite_ext(spr, _f, _dx, _dy, _sx, _sy, 0, c_white, 1);

// a hat, if one is earned and worn: drawn by box so any hat size fits
var _hat = global.G.equipped_hat;
if (is_string(_hat) && _hat != "") {
    var _hspr = hat_sprite(_hat);
    if (_hspr != -1) {
        // measured from the art: the head is 17px wide and its crown is 10
        // rows down, so the brim rests on row 10 and the hat covers what is
        // above it — no floating, no covering the eyes
        var _hw = sprite_get_width(_hspr) * S * (1 + (1 - squash) * 0.35);
        var _hh = sprite_get_height(_hspr) * S * squash;
        var _brim = _dy + 10 * S + 1;
        draw_sprite_stretched(_hspr, 0, cx - _hw * 0.5, _brim - _hh, _hw, _hh);
    }
}

