/// @description a soft drop shadow, then the cat itself
var _n = sprite_get_number(spr);
if (_n > 0) {
    var _f = floor(anim) mod _n;

    // Kittens have no outline (a 1px ring on a 20px cat reads as a black
    // frame), so they are grounded with a soft shadow instead. The sprite
    // origin is bottom-centre, so y is the ground line: the shadow sits
    // across it and turns with the same pivot as the cat.
    draw_set_alpha(0.16);
    draw_set_colour(P_INK);
    draw_ellipse(x - 7, y - 2, x + 7, y + 2, false);
    draw_set_alpha(1);

    draw_sprite_ext(spr, _f, x, y, image_xscale, 1, 0, c_white, 1);
}
