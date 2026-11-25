/// @description the four rooms, drawn with primitives.
/// Every colour goes through zc() with plain RGB so nothing has to remember
/// that GameMaker's $ literals are BGR — that mistake turned a sunset blue.

function zc(_r, _g, _b) {
    return make_colour_rgb(_r, _g, _b);
}

// The Cozy Corner's pantry cupboard. It is drawn here, in the cafe wall
// itself, so the hidden entrance cannot exist in any other room: the other
// zone painters never call this and obj_veil_door only paints the secret
// seam on top of it.
//
// It is a floor-standing built-in, in the same timber as the wainscot, with a
// shelf of preserves above it. At rest it is simply the room's cabinetry; the
// only wrong thing is that the right-hand door never quite latches.
#macro CAFE_PANTRY_X 138
#macro CAFE_PANTRY_Y 86
#macro CAFE_PANTRY_W 50
#macro CAFE_PANTRY_H 120
#macro CAFE_PANTRY_DOOR_X 144
#macro CAFE_PANTRY_DOOR_Y 94
#macro CAFE_PANTRY_DOOR_W 38
#macro CAFE_PANTRY_DOOR_H 102

function zone_cozy_pantry() {
    var _x = CAFE_PANTRY_X, _y = CAFE_PANTRY_Y;
    var _w = CAFE_PANTRY_W, _h = CAFE_PANTRY_H;
    var _wood_dark  = zc(108, 70, 46);
    var _wood_mid   = zc(140, 90, 60);
    var _wood_light = zc(181, 120, 80);
    var _wood_lit   = zc(204, 142, 96);

    // It stands on the floor and casts a soft shadow to the right.
    draw_set_alpha(0.12);
    draw_set_colour(zc(70, 45, 60));
    draw_roundrect_ext(_x + 5, _y + 8, _x + _w + 7, _y + _h + 2, 4, 4, false);
    draw_set_alpha(1);

    // shelf above, with two small jars: this is the pantry, not a lone door
    draw_set_colour(_wood_mid);
    draw_rectangle(_x - 4, 80, _x + _w + 4, 84, false);
    draw_set_colour(zc(201, 138, 91));
    draw_rectangle(_x - 4, 80, _x + _w + 4, 81, false);
    draw_set_colour(_wood_mid);
    draw_rectangle(145, 69, 155, 71, false);
    draw_set_colour(zc(232, 106, 90));
    draw_rectangle(146, 72, 154, 80, false);
    draw_set_colour(zc(255, 245, 220));
    draw_rectangle(147, 73, 149, 79, false);
    draw_set_colour(_wood_mid);
    draw_rectangle(165, 71, 173, 73, false);
    draw_set_colour(zc(255, 201, 77));
    draw_rectangle(166, 74, 172, 80, false);
    draw_set_colour(zc(255, 245, 220));
    draw_rectangle(167, 75, 168, 79, false);

    // carcass: dark outline, mid frame, a lit top rail and a plinth on the floor
    draw_set_colour(_wood_dark);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_colour(_wood_mid);
    draw_rectangle(_x + 2, _y + 2, _x + _w - 2, _y + _h - 2, false);
    draw_set_colour(_wood_lit);
    draw_rectangle(_x + 3, _y + 3, _x + _w - 3, _y + 6, false);
    draw_set_colour(_wood_dark);
    draw_rectangle(_x - 2, _y + _h - 8, _x + _w + 2, _y + _h, false);
    draw_set_colour(_wood_mid);
    draw_rectangle(_x - 2, _y + _h - 8, _x + _w + 2, _y + _h - 6, false);

    var _dx = CAFE_PANTRY_DOOR_X, _dy = CAFE_PANTRY_DOOR_Y;
    var _dw = CAFE_PANTRY_DOOR_W, _dh = CAFE_PANTRY_DOOR_H;
    var _mid = _dx + _dw div 2;

    // left door: base, face, recessed panel with a lit top edge
    draw_set_colour(_wood_dark);
    draw_rectangle(_dx, _dy, _mid - 2, _dy + _dh, false);
    draw_set_colour(_wood_light);
    draw_rectangle(_dx + 1, _dy + 1, _mid - 3, _dy + _dh - 1, false);
    draw_set_colour(zc(158, 100, 68));
    draw_rectangle(_dx + 4, _dy + 8, _mid - 6, _dy + _dh - 8, false);
    draw_set_colour(_wood_lit);
    draw_rectangle(_dx + 5, _dy + 9, _mid - 7, _dy + 10, false);

    // right door, drawn a pixel out of true: it has not latched in years
    draw_set_colour(_wood_dark);
    draw_rectangle(_mid + 1, _dy, _dx + _dw + 1, _dy + _dh - 1, false);
    draw_set_colour(_wood_light);
    draw_rectangle(_mid + 2, _dy + 1, _dx + _dw, _dy + _dh - 2, false);
    draw_set_colour(zc(158, 100, 68));
    draw_rectangle(_mid + 5, _dy + 8, _dx + _dw - 4, _dy + _dh - 9, false);
    draw_set_colour(_wood_lit);
    draw_rectangle(_mid + 6, _dy + 9, _dx + _dw - 5, _dy + 10, false);

    // the seam between them is a dark gap, not a crack: two doors, one ajar
    draw_set_colour(zc(70, 45, 60));
    draw_rectangle(_mid, _dy + 1, _mid + 1, _dy + _dh - 1, false);

    // brass knobs, set either side of the seam
    draw_set_colour(zc(140, 96, 44));
    draw_circle(_mid - 4, _dy + 50, 2, false);
    draw_circle(_mid + 5, _dy + 50, 2, false);
    draw_set_colour(zc(255, 214, 122));
    draw_circle(_mid - 4, _dy + 49, 1.2, false);
    draw_circle(_mid + 5, _dy + 49, 1.2, false);

    // the little plate that answers knocks, on the base rail
    draw_set_colour(zc(112, 84, 52));
    draw_roundrect_ext(_mid - 8, _y + _h - 11, _mid + 8, _y + _h - 5, 1, 1, false);
    draw_set_colour(zc(190, 162, 110));
    draw_roundrect_ext(_mid - 7, _y + _h - 10, _mid + 7, _y + _h - 6, 1, 1, false);
}

function zone_draw(_z, _px) {
    switch (_z) {
        case 1: zone_garden(_px);  break;
        case 2: zone_rooftop(_px); break;
        case 3: zone_cloud(_px);   break;
        case 4: zone_tea(_px);     break;
        case 5: zone_library(_px); break;
        default: zone_cozy(_px);   break;
    }
}

/// Shared: the rug the big cat stands on.
function zone_rug(_rim, _mat, _inner) {
    draw_set_colour(zc(70, 45, 60)); draw_ellipse(41, 201, 259, 251, false);
    draw_set_colour(_rim);   draw_ellipse(44, 204, 256, 248, false);
    draw_set_colour(_mat);   draw_ellipse(54, 209, 246, 243, false);
    draw_set_colour(_inner); draw_ellipse(66, 214, 234, 238, false);
}

// ---------------------------------------------------------------- zone 0
function zone_cozy(_px) {
    // warm wallpaper
    draw_set_colour(zc(247, 231, 205));
    draw_rectangle(0, 24, 480, 180, false);
    draw_set_colour(zc(252, 240, 220));
    for (var sx = 8; sx < 480; sx += 32) {
        draw_rectangle(sx, 24, sx + 10, 180, false);
    }

    // picture rail, then wainscot
    draw_set_colour(zc(201, 138, 91));
    draw_rectangle(0, 180, 480, 206, false);
    draw_set_colour(zc(176, 118, 76));
    draw_rectangle(0, 180, 480, 184, false);

    // floorboards
    draw_set_colour(zc(160, 104, 62));
    draw_rectangle(0, 206, 480, 270, false);
    draw_set_colour(zc(138, 88, 52));
    for (var fy = 214; fy < 270; fy += 12) {
        draw_rectangle(0, fy, 480, fy + 1, false);
    }

    // window
    var _wx = 196;   // fixed to the wall
    draw_set_colour(zc(176, 118, 76));
    draw_rectangle(_wx, 44, _wx + 80, 140, false);
    draw_set_colour(zc(190, 226, 240));
    draw_rectangle(_wx + 4, 48, _wx + 76, 136, false);
    draw_set_colour(zc(255, 253, 247));
    draw_circle(_wx + 20, 66, 9, false);
    draw_circle(_wx + 52, 70, 7, false);
    draw_circle(_wx + 61, 74, 5, false);
    draw_circle(_wx + 44, 76, 4, false);
    draw_set_colour(zc(201, 138, 91));
    draw_rectangle(_wx + 38, 48, _wx + 42, 136, false);
    draw_rectangle(_wx + 4, 90, _wx + 76, 94, false);
    draw_set_colour(zc(201, 138, 91));
    draw_rectangle(_wx - 5, 136, _wx + 85, 145, false);

    // shelf with books
    draw_set_colour(zc(201, 138, 91));
    draw_rectangle(34, 108, 132, 112, false);
    draw_set_colour(zc(232, 106, 90));  draw_rectangle(46, 96, 58, 108, false);
    draw_set_colour(zc(143, 214, 192)); draw_rectangle(66, 92, 78, 108, false);
    draw_set_colour(zc(255, 201, 77));  draw_rectangle(88, 99, 100, 108, false);
    draw_set_colour(zc(245, 168, 200)); draw_rectangle(106, 94, 118, 108, false);

    // lamp
    var _lx = 72;    // fixed to the wall
    draw_set_colour(zc(140, 90, 60));   draw_rectangle(_lx - 6, 24, _lx + 6, 27, false);
    draw_set_colour(zc(70, 45, 60));    draw_rectangle(_lx - 1, 27, _lx + 1, 63, false);
    draw_set_colour(zc(224, 158, 40));  draw_triangle(_lx - 21, 75, _lx + 21, 75, _lx, 63, false);
    draw_set_colour(zc(255, 214, 122)); draw_triangle(_lx - 18, 72, _lx + 18, 72, _lx, 64, false);
    draw_set_colour(zc(255, 246, 208)); draw_circle(_lx, 77, 4, false);

    // the pantry cupboard belongs to this wall and to no other room
    zone_cozy_pantry();

    // the plant is a sprite, not primitives: hand-placed triangles and circles
    // never stop looking like triangles and circles
    draw_set_alpha(0.16);
    draw_set_colour(zc(70, 45, 60));
    draw_ellipse(250, 203, 273, 209, false);
    draw_set_alpha(1);
    draw_sprite(spr_room_plant, 0, 248, 166);

    zone_rug(zc(214, 128, 165), zc(246, 230, 200), zc(232, 106, 90));
}

// ---------------------------------------------------------------- zone 1
function zone_garden(_px) {
    // sky
    draw_set_colour(zc(224, 246, 232));
    draw_rectangle(0, 24, 480, 176, false);
    draw_set_colour(zc(240, 251, 242));
    draw_rectangle(0, 24, 480, 96, false);

    // sun
    draw_set_alpha(0.30);
    draw_set_colour(zc(255, 214, 122));
    draw_circle(214 + _px, 52, 26, false);
    draw_set_alpha(1);
    draw_set_colour(zc(255, 226, 130));
    draw_circle(214 + _px, 52, 15, false);
    draw_set_colour(zc(255, 246, 190));
    draw_circle(210 + _px, 48, 8, false);

    // hills
    draw_set_colour(zc(155, 217, 138));
    draw_circle(80 + _px, 190, 90, false);
    draw_circle(250 + _px * 1.4, 200, 110, false);
    draw_set_colour(zc(122, 196, 112));
    draw_circle(400 + _px * 1.4, 196, 80, false);

    // hedge
    draw_set_colour(zc(95, 168, 92));
    for (var hx = -10; hx < 300; hx += 22) {
        draw_circle(hx + 10, 170, 13, false);
    }

    // picket fence
    draw_set_colour(zc(250, 242, 228));
    for (var fx = 12; fx < 300; fx += 20) {
        draw_rectangle(fx, 158, fx + 7, 196, false);
    }
    draw_rectangle(0, 168, 300, 172, false);
    draw_rectangle(0, 180, 300, 184, false);

    // sunflowers
    for (var i = 0; i < 4; i++) {
        var _sx = 22 + i * 74 + _px * 0.3;
        var _sy = 152 - (i mod 2) * 12;
        draw_set_colour(zc(95, 168, 92));
        draw_rectangle(_sx, _sy, _sx + 3, 202, false);
        draw_set_colour(zc(122, 196, 112));
        draw_circle(_sx + 11, _sy - 2, 5, false);
        draw_circle(_sx - 5, _sy + 8, 4, false);
        draw_set_colour(zc(255, 201, 77));
        draw_circle(_sx + 1, _sy - 10, 9, false);
        draw_set_colour(zc(140, 90, 60));
        draw_circle(_sx + 1, _sy - 10, 4, false);
    }

    // grass
    draw_set_colour(zc(127, 203, 92));
    draw_rectangle(0, 200, 480, 270, false);
    draw_set_colour(zc(107, 180, 78));
    for (var gy = 210; gy < 270; gy += 14) {
        draw_rectangle(0, gy, 480, gy + 2, false);
    }
    draw_set_colour(zc(95, 168, 92));
    for (var tx = 6; tx < 480; tx += 17) {
        var _th = 4 + (tx mod 5);
        draw_circle(tx, 256 + (tx mod 3) * 4, _th, false);
    }

    zone_rug(zc(232, 106, 90), zc(246, 230, 200), zc(232, 106, 90));
}

// ---------------------------------------------------------------- zone 2
function zone_rooftop(_px) {
    // sunset, banded so it stays pixel-crisp and warm at the horizon
    draw_set_colour(zc(51, 32, 74));    draw_rectangle(0, 24, 480, 62, false);
    draw_set_colour(zc(74, 46, 92));    draw_rectangle(0, 62, 480, 96, false);
    draw_set_colour(zc(122, 63, 110));  draw_rectangle(0, 96, 480, 126, false);
    draw_set_colour(zc(176, 85, 110));  draw_rectangle(0, 126, 480, 150, false);
    draw_set_colour(zc(224, 122, 90));  draw_rectangle(0, 150, 480, 172, false);
    draw_set_colour(zc(255, 141, 74));  draw_rectangle(0, 172, 480, 186, false);
    draw_set_colour(zc(255, 186, 92));  draw_rectangle(0, 186, 480, 196, false);

    // last of the sun, sitting on the skyline
    draw_set_alpha(0.35);
    draw_set_colour(zc(255, 217, 160));
    draw_circle(206, 196, 42, false);
    draw_set_alpha(1);
    draw_set_colour(zc(255, 240, 200));
    draw_circle(206, 194, 16, false);

    // stars fade in towards the top of the sky
    for (var s = 0; s < 26; s++) {
        var _sx = (s * 71 mod 300) + 8;
        var _sy = 30 + (s * 37 mod 90);
        var _tw = 0.5 + 0.5 * sin(global.time * 2 + s);
        draw_set_alpha((0.30 + _tw * 0.55) * clamp(1 - (_sy - 30) / 90, 0.15, 1));
        draw_set_colour(zc(255, 253, 247));
        draw_rectangle(_sx, _sy, _sx + 1, _sy + 1, false);
        draw_set_alpha(1);
    }

    // moon
    draw_set_colour(zc(246, 230, 200));
    draw_circle(96 + _px * 0.5, 58, 12, false);
    draw_set_colour(zc(255, 253, 247));
    draw_circle(92 + _px * 0.5, 54, 10, false);

    // far skyline
    draw_set_colour(zc(40, 27, 60));
    for (var b = 0; b < 14; b++) {
        var _bx = b * 34 + 4 + _px * 0.7;
        var _bh = 26 + ((b * 53) mod 46);
        draw_rectangle(_bx, 196 - _bh, _bx + 26, 200, false);
    }
    // lit windows, in a second pass so no building paints over them
    for (var b2 = 0; b2 < 14; b2++) {
        var _bx2 = b2 * 34 + 4 + _px * 0.7;
        var _bh2 = 26 + ((b2 * 53) mod 46);
        draw_set_colour(zc(255, 201, 122));
        for (var wy = 6; wy < _bh2 - 6; wy += 11) {
            for (var wx = 5; wx < 22; wx += 9) {
                if (((wx + wy + b2) mod 3) == 0) {
                    draw_rectangle(_bx2 + wx, 196 - _bh2 + wy, _bx2 + wx + 3, 196 - _bh2 + wy + 4, false);
                }
            }
        }
    }

    // a nearer row of rooftops, darker, to give the skyline depth
    draw_set_colour(zc(26, 17, 40));
    for (var n = 0; n < 9; n++) {
        var _nx = n * 52 - 14 + _px * 1.5;
        var _nh = 16 + ((n * 61) mod 26);
        draw_rectangle(_nx, 200 - _nh, _nx + 40, 202, false);
    }

    // string lights
    draw_set_colour(zc(46, 27, 43));
    for (var lx = 0; lx < 480; lx += 2) {
        var _ly2 = 40 + sin(lx / 60) * 10;
        draw_rectangle(lx, _ly2, lx + 2, _ly2 + 1, false);
    }
    for (var bx = 16; bx < 480; bx += 34) {
        var _by = 40 + sin(bx / 60) * 10 + 7;
        draw_set_alpha(0.32);
        draw_set_colour(zc(255, 201, 77));
        draw_circle(bx, _by, 7, false);
        draw_set_alpha(1);
        draw_set_colour(zc(255, 215, 102));
        draw_circle(bx, _by, 3.4, false);
        draw_set_colour(zc(255, 246, 208));
        draw_circle(bx - 1, _by - 1, 1.6, false);
    }

    // rooftop deck
    draw_set_colour(zc(84, 56, 96));
    draw_rectangle(0, 196, 480, 270, false);
    draw_set_colour(zc(74, 48, 86));
    for (var dy = 206; dy < 270; dy += 13) {
        draw_rectangle(0, dy, 480, dy + 2, false);
    }
    draw_set_colour(zc(96, 66, 110));
    for (var tx2 = 0; tx2 < 480; tx2 += 36) {
        draw_rectangle(tx2, 198, tx2 + 1, 270, false);
    }
    // warm light spilling across the deck from the sunset
    draw_set_alpha(0.15);
    draw_set_colour(zc(255, 179, 107));
    draw_rectangle(0, 196, 480, 216, false);
    draw_set_alpha(1);
    draw_set_colour(zc(46, 27, 43));
    draw_rectangle(0, 196, 480, 202, false);
    draw_set_colour(zc(122, 84, 136));
    draw_rectangle(0, 202, 480, 203, false);

    zone_rug(zc(232, 106, 90), zc(244, 162, 107), zc(232, 106, 90));
}

// ---------------------------------------------------------------- zone 3
function zone_cloud(_px) {
    draw_set_colour(zc(245, 200, 228));   // pink sky
    draw_rectangle(0, 24, 480, 180, false);
    draw_set_colour(zc(252, 224, 240));
    draw_rectangle(0, 24, 480, 110, false);
    draw_set_colour(zc(255, 247, 252));
    draw_circle(300, 30, 60, false);

    // far clouds
    draw_set_colour(zc(255, 240, 248));
    for (var c = 0; c < 5; c++) {
        var _cx = (c * 96 + 30 + _px * (0.4 + c * 0.1)) mod 520 - 20;
        var _cy = 60 + (c * 37) mod 70;
        draw_circle(_cx, _cy, 20, false);
        draw_circle(_cx + 20, _cy + 6, 15, false);
        draw_circle(_cx - 18, _cy + 8, 13, false);
    }

    // a floating island: a green cap on a faceted rock, plus one small tree.
    // An earlier version had a parasol and a two-lobed bush, and at 480px it
    // read as a face with a propeller, so every shape here is a plain one.
    var _ix = 44 + _px * 0.7;
    var _top = 138;

    // rock underside: outline first, then two facets
    draw_set_colour(zc(70, 45, 60));
    draw_triangle(_ix - 26, _top - 2, _ix + 26, _top - 2, _ix, _top + 34, true);
    draw_set_colour(zc(198, 150, 196));
    draw_triangle(_ix - 24, _top, _ix + 2, _top, _ix, _top + 32, false);
    draw_set_colour(zc(160, 108, 168));
    draw_triangle(_ix + 2, _top, _ix + 24, _top, _ix, _top + 32, false);

    // grass cap: a wide shallow dome, sitting on the rock's rim
    draw_set_colour(zc(70, 45, 60));
    draw_ellipse(_ix - 28, _top - 16, _ix + 28, _top + 6, false);
    draw_set_colour(zc(127, 203, 92));
    draw_ellipse(_ix - 26, _top - 14, _ix + 26, _top + 2, false);
    draw_set_colour(zc(95, 168, 92));
    draw_ellipse(_ix - 26, _top - 2, _ix + 26, _top + 4, false);
    draw_set_colour(zc(127, 203, 92));
    draw_ellipse(_ix - 24, _top - 4, _ix + 24, _top + 1, false);

    // one little tree, because a tree is a tree at any size
    draw_set_colour(zc(70, 45, 60));
    draw_rectangle(_ix - 6, _top - 20, _ix - 2, _top - 4, false);
    draw_set_colour(zc(140, 90, 60));
    draw_rectangle(_ix - 5, _top - 19, _ix - 3, _top - 5, false);
    draw_set_colour(zc(70, 45, 60));
    draw_circle(_ix - 4, _top - 26, 9, false);
    draw_set_colour(zc(110, 186, 96));
    draw_circle(_ix - 4, _top - 26, 7, false);
    draw_set_colour(zc(150, 214, 128));
    draw_circle(_ix - 7, _top - 29, 3, false);

    // no extra shapes on the grass: at 480px every added blob reads as a hole
    // or a stray circle, so the island is one tree, one cap, one rock

    // gold trim band
    draw_set_colour(zc(255, 201, 77));
    draw_rectangle(0, 176, 480, 184, false);
    draw_set_colour(zc(224, 158, 40));
    draw_rectangle(0, 182, 480, 184, false);

    // cloud floor
    draw_set_colour(zc(252, 224, 240));
    draw_rectangle(0, 184, 480, 270, false);
    draw_set_colour(zc(255, 247, 252));
    for (var f = 0; f < 9; f++) {
        var _fx = f * 58 + 10;
        draw_circle(_fx, 250 + (f mod 2) * 8, 26, false);
    }
    draw_set_colour(zc(245, 200, 228));
    draw_rectangle(0, 262, 480, 270, false);

    zone_rug(zc(245, 168, 200), zc(255, 253, 247), zc(245, 168, 200));
}

// ---------------------------------------------------------------- zone 4
/// The Tea House: shoji light, low tables, paper lanterns and steam. Warmer
/// and slower than the cafe, and the first room with a ceiling you can see.
function zone_tea(_px) {
    // paper wall and a dark timber frame
    draw_set_colour(zc(233, 222, 197));
    draw_rectangle(0, 24, 480, 176, false);
    draw_set_colour(zc(76, 62, 52));
    draw_rectangle(0, 24, 480, 30, false);
    draw_rectangle(0, 170, 480, 176, false);

    // shoji screens, left wall, with their lattice
    draw_set_colour(zc(90, 72, 58));
    draw_rectangle(16, 44, 156, 158, false);
    draw_set_colour(zc(250, 244, 224));
    draw_rectangle(20, 48, 152, 154, false);
    draw_set_colour(zc(160, 138, 110));
    for (var _sx = 42; _sx < 152; _sx += 22) draw_rectangle(_sx, 48, _sx + 2, 154, false);
    for (var _sy = 74; _sy < 154; _sy += 26) draw_rectangle(20, _sy, 152, _sy + 2, false);
    // bamboo showing through two panels, drawn as stems and leaves
    for (var _bp = 0; _bp < 2; _bp++) {
        var _bx2 = 26 + _bp * 24;
        draw_set_colour(zc(168, 198, 150));
        draw_rectangle(_bx2, 48, _bx2 + 2, 154, false);
        draw_rectangle(_bx2 + 9, 72, _bx2 + 11, 154, false);
        draw_set_colour(zc(140, 182, 126));
        for (var _bl = 0; _bl < 4; _bl++) {
            var _ly4 = 66 + _bl * 22;
            draw_ellipse(_bx2 - 5, _ly4, _bx2 + 2, _ly4 + 3, false);
            draw_ellipse(_bx2 + 11, _ly4 + 10, _bx2 + 18, _ly4 + 13, false);
        }
    }

    // hanging paper lanterns, warm and slightly uneven
    for (var _l = 0; _l < 3; _l++) {
        var _lx2 = 190 + _l * 44 + _px * 0.4;
        var _ly3 = 52 + (_l mod 2) * 12;
        draw_set_colour(zc(76, 62, 52));
        draw_rectangle(_lx2, 24, _lx2 + 1, _ly3 - 8, false);
        draw_set_alpha(0.16);
        draw_set_colour(zc(255, 214, 122));
        draw_circle(_lx2, _ly3, 16, false);
        draw_set_alpha(1);
        draw_set_colour(zc(246, 206, 138));
        draw_circle(_lx2, _ly3, 9, false);
        draw_set_colour(zc(255, 232, 176));
        draw_circle(_lx2 - 2, _ly3 - 2, 5, false);
        draw_set_colour(zc(76, 62, 52));
        draw_rectangle(_lx2 - 4, _ly3 - 9, _lx2 + 4, _ly3 - 8, false);
        draw_rectangle(_lx2 - 4, _ly3 + 8, _lx2 + 4, _ly3 + 9, false);
    }

    // tatami floor, mats across the room, laid before anything stands on it
    draw_set_colour(zc(196, 178, 132));
    draw_rectangle(0, 176, 480, 270, false);
    draw_set_colour(zc(176, 156, 112));
    for (var _ty = 186; _ty < 270; _ty += 18) draw_rectangle(0, _ty, 480, _ty + 1, false);
    for (var _tx3 = 0; _tx3 < 480; _tx3 += 96) draw_rectangle(_tx3, 176, _tx3 + 1, 270, false);
    draw_set_colour(zc(120, 82, 58));
    draw_rectangle(0, 176, 480, 179, false);

    zone_rug(zc(126, 152, 120), zc(216, 204, 168), zc(126, 152, 120));

    // low table with a teapot, standing on the tatami beside the rug
    draw_set_colour(zc(120, 82, 58));
    draw_roundrect_ext(190, 186, 280, 196, 3, 3, false);
    draw_set_colour(zc(150, 104, 72));
    draw_rectangle(196, 196, 202, 216, false);
    draw_rectangle(268, 196, 274, 216, false);
    draw_set_colour(zc(96, 66, 46));
    draw_rectangle(190, 193, 280, 196, false);
    draw_sprite_ext(spr_prop_teapot, 0, 216, 164, 1.2, 1.2, 0, c_white, 1);
    draw_set_colour(zc(232, 214, 176));
    draw_roundrect_ext(246, 176, 260, 186, 2, 2, false);
    // a cushion for the guest who is not there yet
    draw_set_colour(zc(196, 128, 112));
    draw_roundrect_ext(176, 214, 200, 222, 3, 3, false);
}

// ---------------------------------------------------------------- zone 5
/// The Star Library: tall shelves, a ladder, a round window and books that
/// have decided not to stay on the shelf.
function zone_library(_px) {
    draw_set_colour(zc(44, 38, 70));
    draw_rectangle(0, 24, 480, 182, false);

    // round window onto the night
    draw_set_colour(zc(90, 74, 118));
    draw_circle(236, 82, 40, false);
    draw_set_colour(zc(22, 20, 46));
    draw_circle(236, 82, 36, false);
    for (var _s = 0; _s < 16; _s++) {
        var _sx2 = 236 + ((_s * 37) mod 66) - 33;
        var _sy2 = 82 + ((_s * 53) mod 62) - 31;
        if (point_distance(_sx2, _sy2, 236, 82) > 33) continue;
        draw_set_alpha(0.4 + 0.6 * (0.5 + 0.5 * sin(global.time * 2 + _s)));
        draw_set_colour(zc(255, 253, 247));
        draw_rectangle(_sx2, _sy2, _sx2 + 1, _sy2 + 1, false);
        draw_set_alpha(1);
    }
    draw_set_colour(zc(246, 230, 200));
    draw_circle(220, 74, 9, false);
    draw_set_colour(zc(90, 74, 118));
    draw_rectangle(200, 82, 272, 84, false);
    draw_rectangle(234, 46, 238, 118, false);

    // shelves, both sides, with books of every colour
    var _books = [zc(232, 106, 90), zc(255, 201, 77), zc(143, 214, 192),
                  zc(245, 168, 200), zc(160, 190, 240), zc(200, 176, 120)];
    for (var _side = 0; _side < 2; _side++) {
        var _bx0 = _side == 0 ? 8 : 268;
        var _bw0 = _side == 0 ? 84 : 84;
        draw_set_colour(zc(66, 46, 44));
        draw_rectangle(_bx0, 44, _bx0 + _bw0, 178, false);
        for (var _row = 0; _row < 4; _row++) {
            var _ry0 = 52 + _row * 32;
            draw_set_colour(zc(96, 68, 58));
            draw_rectangle(_bx0 + 2, _ry0 + 24, _bx0 + _bw0 - 2, _ry0 + 27, false);
            for (var _b = 0; _b < 7; _b++) {
                var _bh0 = 12 + ((_b * 7 + _row * 5) mod 9);
                draw_set_colour(_books[(_b + _row + _side) mod 6]);
                draw_rectangle(_bx0 + 5 + _b * 11, _ry0 + 24 - _bh0,
                               _bx0 + 12 + _b * 11, _ry0 + 24, false);
            }
        }
    }

    // a leaning ladder, and one book that got away
    draw_set_colour(zc(150, 116, 80));
    draw_rectangle(96, 46, 99, 180, false);
    draw_rectangle(110, 46, 113, 180, false);
    for (var _r = 0; _r < 6; _r++) draw_rectangle(96, 60 + _r * 20, 113, 62 + _r * 20, false);

    var _drift = sin(global.time * 0.8) * 4;
    draw_sprite_ext(spr_prop_post, 0, 176 + _drift, 96, 1, 1, sin(global.time) * 8, c_white, 1);
    draw_sprite_ext(spr_prop_post, 0, 158 - _drift, 124, 0.8, 0.8, -6, c_white, 1);

    // reading rug and the lamp that makes it readable
    draw_set_colour(zc(72, 60, 98));
    draw_rectangle(0, 182, 480, 270, false);
    draw_set_colour(zc(60, 50, 84));
    for (var _fy3 = 192; _fy3 < 270; _fy3 += 14) draw_rectangle(0, _fy3, 480, _fy3 + 1, false);
    draw_set_alpha(0.14);
    draw_set_colour(zc(255, 214, 122));
    draw_circle(236, 200, 60, false);
    draw_set_alpha(1);

    zone_rug(zc(120, 100, 160), zc(214, 202, 166), zc(120, 100, 160));

    // the reading table, with one book open and one candle keeping it readable
    draw_set_colour(zc(84, 64, 52));
    draw_roundrect_ext(196, 200, 272, 208, 3, 3, false);
    draw_set_colour(zc(66, 48, 40));
    draw_rectangle(202, 208, 206, 224, false);
    draw_rectangle(262, 208, 266, 224, false);
    draw_set_colour(zc(246, 230, 200));
    draw_rectangle(212, 192, 232, 200, false);
    draw_rectangle(234, 192, 254, 200, false);
    draw_set_colour(zc(140, 106, 78));
    draw_rectangle(232, 191, 234, 201, false);
    draw_set_colour(zc(196, 176, 138));
    draw_rectangle(258, 186, 261, 200, false);
    draw_set_colour(zc(224, 108, 48));
    draw_circle(259.5, 183, 2, false);
    draw_set_alpha(0.20);
    draw_set_colour(zc(255, 214, 122));
    draw_circle(259.5, 184, 14, false);
    draw_set_alpha(1);
}

// ---------------------------------------------------------------- ambient
/// update + draw the little life in the air, per zone
function zone_ambient_init(_z) {
    global.amb = [];
    var _n = [12, 10, 14, 12, 10, 16][_z];
    for (var i = 0; i < _n; i++) {
        array_push(global.amb, {
            x: random(GAME_W), y: random_range(40, 230),
            vx: random_range(-0.25, 0.25),
            vy: random_range(-0.2, -0.05),
            ph: random(GAME_W), amp: random_range(4, 12),
            s: random_range(1, 2.4)
        });
    }
}

function zone_ambient_step() {
    if (!variable_global_exists("amb")) zone_ambient_init(global.G.world.zone);
    for (var i = 0; i < array_length(global.amb); i++) {
        var _p = global.amb[i];
        _p.y += _p.vy;
        _p.x += _p.vx + sin((global.time + _p.ph) * 1.4) * 0.25;
        if (_p.y < 34) { _p.y = 236; _p.x = random(GAME_W); }
        if (_p.x < -8)  _p.x = GAME_W + 8;
        if (_p.x > GAME_W + 8) _p.x = -8;
    }
}

function zone_ambient_draw(_z) {
    if (!variable_global_exists("amb")) return;
    for (var i = 0; i < array_length(global.amb); i++) {
        var _p = global.amb[i];
        switch (_z) {
            case 1:   // butterflies
                var _f = sin((global.time + _p.ph) * 6);
                draw_set_colour(zc(255, 201, 77));
                draw_ellipse(_p.x - 4.5, _p.y - 2 - abs(_f) * 2.5, _p.x, _p.y + 2, false);
                draw_set_colour(zc(255, 253, 247));
                draw_ellipse(_p.x, _p.y - 2 - abs(_f) * 2.5, _p.x + 4.5, _p.y + 2, false);
                draw_set_colour(zc(70, 45, 60));
                draw_rectangle(_p.x - 0.5, _p.y - 1, _p.x + 0.5, _p.y + 1, false);
                break;
            case 2:   // fireflies
                draw_set_alpha(0.30);
                draw_set_colour(zc(255, 201, 77));
                draw_circle(_p.x, _p.y, _p.s + 2.5, false);
                draw_set_alpha(1);
                draw_set_colour(zc(255, 246, 208));
                draw_circle(_p.x, _p.y, _p.s * 0.6, false);
                break;
            case 3:   // drifting sparkles
                draw_set_alpha(0.5 + 0.5 * sin((global.time + _p.ph) * 3));
                draw_set_colour(zc(255, 253, 247));
                draw_rectangle(_p.x, _p.y - 1, _p.x, _p.y + 1, false);
                draw_rectangle(_p.x - 1, _p.y, _p.x + 1, _p.y, false);
                draw_set_alpha(1);
                break;
            case 4:   // steam off the tea
                draw_set_alpha(0.10 + 0.10 * sin((global.time + _p.ph) * 1.6));
                draw_set_colour(zc(255, 250, 240));
                draw_ellipse(_p.x - 2.5, _p.y - 2, _p.x + 2.5, _p.y + 2, false);
                draw_set_alpha(1);
                break;
            case 5:   // stars, adrift indoors
                draw_set_alpha(0.25 + 0.55 * (0.5 + 0.5 * sin((global.time + _p.ph) * 2.4)));
                draw_set_colour(zc(255, 253, 247));
                draw_rectangle(_p.x, _p.y - 1, _p.x, _p.y + 1, false);
                draw_rectangle(_p.x - 1, _p.y, _p.x + 1, _p.y, false);
                draw_set_alpha(1);
                break;
            default:  // dust motes
                draw_set_alpha(0.30);
                draw_set_colour(zc(246, 230, 200));
                draw_circle(_p.x, _p.y, _p.s, false);
                draw_set_alpha(1);
                break;
        }
    }
}
