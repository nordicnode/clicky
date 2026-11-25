/// @description a friendly little glow that asks to be tapped
var _py = y + bob;
var _pulse = 1 + sin(t * 0.12) * 0.12;
// it fades as its welcome runs out, so it never vanishes without warning
var _fade = (life < 90) ? clamp(life / 90, 0, 1) : 1;

draw_set_alpha(0.22 * _fade);
draw_set_colour(P_GOLD);
draw_circle(x, _py, 13 * _pulse, false);
draw_set_alpha(0.45 * _fade);
draw_circle(x, _py, 7 * _pulse, false);
draw_set_alpha(_fade);

draw_sprite_ext(spr_fx_sparkle, floor(t * 0.12) mod 4, x, _py, _pulse, _pulse, 0, c_white, 1);
draw_set_alpha(1);
