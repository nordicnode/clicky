/// @description draw the current zone, its ambient life and the swap flourish
// Room art is drawn in 480x270 space; clear any GUI matrix left by a card.
matrix_set(matrix_world, matrix_build_identity());
var _z  = global.G.world.zone;
var _px = zone_parallax();

zone_draw(_z, _px);
zone_ambient_draw(_z);

// day -> dusk tint, but only in the room that has a real day: the other
// zones are already lit on purpose and a wash on top just muddies them
if (_z == 0) {
    var _ph = (global.time / 240) mod 1;
    var _tint = sin(_ph * 2 * pi) * 0.5 + 0.5;
    draw_set_alpha(0.06 + _tint * 0.10);
    draw_set_colour($5C3A6E);
    draw_rectangle(0, 0, GAME_W, GAME_H, false);
    draw_set_alpha(1);
}

// zone swap: cream flash. The name card is native and lives in obj_hud.
if (global.zone_flash > 0) {
    draw_set_alpha(clamp(global.zone_flash, 0, 1) * 0.85);
    draw_set_colour(P_WHITE);
    draw_rectangle(0, 0, GAME_W, GAME_H, false);
    draw_set_alpha(1);
}
