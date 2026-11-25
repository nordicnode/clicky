/// THE HOLLOW HOUR, drawn. One owner for the layer's palette, chrome, rooms,
/// familiars and HUD so the dark screens cannot drift apart.
/// GameMaker colour literals are BGR, so every colour is made from plain RGB.

function vc(_r, _g, _b) {
    return make_colour_rgb(_r, _g, _b);
}

#macro V_VOID     make_colour_rgb(8, 5, 7)
#macro V_BLACK    make_colour_rgb(15, 11, 14)
#macro V_IRON     make_colour_rgb(37, 30, 35)
#macro V_IRON_HI  make_colour_rgb(68, 56, 62)
#macro V_BONE     make_colour_rgb(216, 204, 184)
#macro V_BONE_DIM make_colour_rgb(142, 130, 118)
#macro V_BLOOD    make_colour_rgb(104, 18, 24)
#macro V_BLOOD_HI make_colour_rgb(176, 42, 46)
#macro V_EMBER    make_colour_rgb(224, 108, 48)
#macro V_WAX      make_colour_rgb(196, 176, 138)
#macro V_PLUM     make_colour_rgb(30, 18, 24)
#macro V_MOSS     make_colour_rgb(56, 66, 48)

function veil_wrap(_txt, _max_chars) {
    var _out = [];
    var _words = string_split(_txt, " ");
    var _line = "";
    for (var _i = 0; _i < array_length(_words); _i++) {
        var _w = _words[_i];
        if (_line == "") {
            _line = _w;
        } else if (string_length(_line) + 1 + string_length(_w) <= _max_chars) {
            _line += " " + _w;
        } else {
            array_push(_out, _line);
            _line = _w;
        }
    }
    if (_line != "") array_push(_out, _line);
    if (array_length(_out) == 0) array_push(_out, "");
    return _out;
}

function veil_glow(_x, _y, _r, _col, _a) {
    draw_set_alpha(_a);
    draw_set_colour(_col);
    draw_circle(_x, _y, _r, false);
    draw_set_alpha(_a * 0.6);
    draw_circle(_x, _y, _r * 1.7, false);
    draw_set_alpha(1);
}

function veil_icon(_kind, _x, _y) {
    switch (_kind) {
        case 0: // ember
            draw_set_colour(V_BLOOD);
            draw_triangle(_x + 7, _y + 1, _x + 2, _y + 10, _x + 12, _y + 10, false);
            draw_set_colour(V_EMBER);
            draw_circle(_x + 7, _y + 8, 3, false);
            draw_set_colour(V_WAX);
            draw_circle(_x + 7, _y + 8, 1, false);
            break;
        case 1: // whisper
            draw_set_colour(V_BONE_DIM);
            draw_circle(_x + 6, _y + 6, 1.5, false);
            draw_circle(_x + 6, _y + 6, 4, true);
            draw_circle(_x + 6, _y + 6, 6, true);
            break;
        case 2: // blood
            draw_set_colour(V_BLOOD_HI);
            draw_circle(_x + 6, _y + 8, 4, false);
            draw_triangle(_x + 2, _y + 7, _x + 10, _y + 7, _x + 6, _y + 1, false);
            draw_set_colour(V_BLOOD);
            draw_circle(_x + 5, _y + 9, 1, false);
            break;
        case 3: // relic
            draw_set_colour(V_WAX);
            draw_triangle(_x + 6, _y + 1, _x + 11, _y + 6, _x + 6, _y + 11, false);
            draw_triangle(_x + 6, _y + 1, _x + 1, _y + 6, _x + 6, _y + 11, false);
            draw_set_colour(V_BLOOD);
            draw_circle(_x + 6, _y + 6, 1.5, false);
            break;
        case 4: // nerve / candle
            draw_set_colour(V_WAX);
            draw_rectangle(_x + 5, _y + 5, _x + 7, _y + 11, false);
            draw_set_colour(V_EMBER);
            draw_circle(_x + 6, _y + 3, 2, false);
            break;
    }
}

/// A familiar. Feet rest exactly on _gy: body, paws and shadow are all derived
/// from that one line, which is what keeps the cats off tables and on floors.
function veil_cat(_x, _gy, _s, _coat, _frame, _eyes) {
    var _fur = vc(58, 50, 56);
    var _shade = vc(40, 34, 40);
    var _eye = V_EMBER;
    switch (_coat) {
        case 1:
            _fur = vc(80, 70, 60);
            _shade = vc(56, 48, 42);
            _eye = V_BLOOD_HI;
            break;
        case 2:
            _fur = vc(44, 48, 60);
            _shade = vc(28, 31, 40);
            _eye = vc(158, 196, 172);
            break;
    }
    var _bob = (_frame == 1) ? 1 : 0;
    var _blink = (_frame == 2);
    var _tail = sin(global.time * 2 + _x * 0.1) * 2;

    draw_set_alpha(0.4);
    draw_set_colour(V_VOID);
    draw_ellipse(_x - 10 * _s, _gy - 2 * _s, _x + 10 * _s, _gy + 2 * _s, false);
    draw_set_alpha(1);

    // tail
    draw_set_colour(_shade);
    for (var _t = 0; _t < 4; _t++) {
        draw_circle(_x + (8 + _t * 2) * _s, _gy - (6 + _t * 3 + _tail) * _s, (2.4 - _t * 0.4) * _s, false);
    }

    // body
    draw_set_colour(_fur);
    draw_roundrect_ext(_x - 8 * _s, _gy - (15 - _bob) * _s,
                       _x + 8 * _s, _gy - 2 * _s, 5 * _s, 5 * _s, false);
    draw_set_colour(_shade);
    draw_roundrect_ext(_x - 5 * _s, _gy - 8 * _s, _x + 5 * _s, _gy - 2 * _s,
                       3 * _s, 3 * _s, false);

    // paws
    draw_set_colour(_fur);
    draw_ellipse(_x - 6 * _s, _gy - 3 * _s, _x - 1 * _s, _gy, false);
    draw_ellipse(_x + 1 * _s, _gy - 3 * _s, _x + 6 * _s, _gy, false);

    // head
    var _hy = _gy - (21 - _bob) * _s;
    draw_set_colour(_fur);
    draw_circle(_x, _hy, 7 * _s, false);
    draw_set_colour(_shade);
    draw_triangle(_x - 7 * _s, _hy - 2 * _s, _x - 3 * _s, _hy - 10 * _s,
                  _x - 1 * _s, _hy - 5 * _s, false);
    draw_triangle(_x + 7 * _s, _hy - 2 * _s, _x + 3 * _s, _hy - 10 * _s,
                  _x + 1 * _s, _hy - 5 * _s, false);
    draw_set_colour(vc(120, 44, 50));
    draw_triangle(_x - 6 * _s, _hy - 3 * _s, _x - 3.5 * _s, _hy - 8 * _s,
                  _x - 2 * _s, _hy - 4.5 * _s, false);
    draw_triangle(_x + 6 * _s, _hy - 3 * _s, _x + 3.5 * _s, _hy - 8 * _s,
                  _x + 2 * _s, _hy - 4.5 * _s, false);

    if (_eyes > 0) {
        if (_blink) {
            draw_set_colour(_shade);
            draw_rectangle(_x - 5 * _s, _hy - 1, _x - 1 * _s, _hy + 1, false);
            draw_rectangle(_x + 1 * _s, _hy - 1, _x + 5 * _s, _hy + 1, false);
        } else {
            draw_set_alpha(0.20);
            draw_set_colour(_eye);
            draw_circle(_x - 3 * _s, _hy - 1 * _s, 4 * _s, false);
            draw_circle(_x + 3 * _s, _hy - 1 * _s, 4 * _s, false);
            draw_set_alpha(1);
            draw_set_colour(_eye);
            draw_ellipse(_x - 4.5 * _s, _hy - 3 * _s, _x - 1 * _s, _hy + 1 * _s, false);
            draw_ellipse(_x + 1 * _s, _hy - 3 * _s, _x + 4.5 * _s, _hy + 1 * _s, false);
            draw_set_colour(V_VOID);
            draw_rectangle(_x - 3 * _s, _hy - 3 * _s, _x - 2 * _s, _hy + 0.5 * _s, false);
            draw_rectangle(_x + 2 * _s, _hy - 3 * _s, _x + 3 * _s, _hy + 0.5 * _s, false);
        }
    }

    // nose and whiskers
    draw_set_colour(vc(150, 108, 108));
    draw_circle(_x, _hy + 2 * _s, 1 * _s, false);
    draw_set_alpha(0.4);
    draw_set_colour(V_BONE_DIM);
    draw_line(_x - 6 * _s, _hy + 2 * _s, _x - 10 * _s, _hy + 1 * _s);
    draw_line(_x - 6 * _s, _hy + 3 * _s, _x - 10 * _s, _hy + 4 * _s);
    draw_line(_x + 6 * _s, _hy + 2 * _s, _x + 10 * _s, _hy + 1 * _s);
    draw_line(_x + 6 * _s, _hy + 3 * _s, _x + 10 * _s, _hy + 4 * _s);
    draw_set_alpha(1);
}

function veil_dust() {
    if (global.G.settings.reduce_motion) return;
    for (var _i = 0; _i < 14; _i++) {
        var _x = (37 + _i * 71 + sin(global.time * 0.3 + _i) * 9) mod 470;
        var _y = 40 + ((_i * 53 + global.time * 4) mod 200);
        draw_set_alpha(0.06 + 0.04 * sin(global.time + _i));
        draw_set_colour(V_BONE);
        draw_circle(_x, _y, 1, false);
    }
    draw_set_alpha(1);
}

// ---------------------------------------------------------------- rooms

function veil_room(_loc) {
    switch (_loc) {
        case 1: veil_room_parlour(); break;
        case 2: veil_room_garden(); break;
        case 3: veil_room_hall(); break;
        case 4: veil_room_cellar(); break;
        case 5: veil_room_ninth(); break;
        default: veil_room_map(); break;
    }
    veil_dust();
}

/// The map is the same dining room the player knows, emptied and wrong.
function veil_room_map() {
    draw_set_colour(vc(26, 18, 24));
    draw_rectangle(0, 24, 480, 176, false);
    draw_set_colour(vc(33, 22, 28));
    for (var _x = 0; _x < 480; _x += 34) draw_rectangle(_x, 24, _x + 15, 176, false);
    // peeling paper curls
    draw_set_colour(vc(46, 32, 38));
    for (var _i = 0; _i < 9; _i++) {
        var _px = 18 + _i * 51;
        draw_triangle(_px, 24, _px + 22, 24, _px + 9, 40 + (_i mod 3) * 9, false);
    }
    // floor
    draw_set_colour(vc(22, 16, 18));
    draw_rectangle(0, 176, 480, 270, false);
    draw_set_colour(vc(30, 22, 24));
    for (var _y = 182; _y < 270; _y += 14) draw_rectangle(0, _y, 480, _y + 1, false);
    draw_set_colour(vc(16, 11, 13));
    for (var _i = 0; _i < 8; _i++) {
        var _fx = _i * 70 - 30;
        draw_line(240, 176, _fx, 270);
    }
    // blood stain, deliberately not centred on anything
    draw_set_alpha(0.5);
    draw_set_colour(V_BLOOD);
    draw_ellipse(118, 206, 172, 226, false);
    draw_ellipse(150, 200, 170, 216, false);
    draw_set_alpha(1);
    // hanging bulbs
    for (var _i = 0; _i < 3; _i++) {
        var _bx = 100 + _i * 140;
        draw_set_colour(vc(46, 38, 40));
        draw_line(_bx, 24, _bx, 44 + _i * 6);
        draw_set_colour(V_WAX);
        draw_circle(_bx, 48 + _i * 6, 3, false);
        var _lit = (_i != 1);
        if (_lit) {
            veil_glow(_bx, 50 + _i * 6, 3, V_EMBER, 0.35);
        }
        draw_set_colour(vc(50, 40, 42));
        draw_triangle(_bx - 7, 46 + _i * 6, _bx + 7, 46 + _i * 6, _bx, 56 + _i * 6, false);
    }
    // the clock is the hint, and it is stopped
    draw_set_colour(V_IRON);
    draw_circle(240, 52, 13, false);
    draw_set_colour(V_BLACK);
    draw_circle(240, 52, 11, false);
    draw_set_colour(V_BONE_DIM);
    draw_line(240, 52, 240, 46);
    draw_line(240, 52, 245, 54);
    // the five doors are drawn by the shell; the room leaves their wall clear
    veil_cat(56, 236, 1.5, 0, floor(global.time * 1.4) mod 4, 1);
    veil_cat(432, 240, 1.2, 2, floor(global.time * 1.1 + 2) mod 4, 1);
    // a lone chair
    draw_set_colour(vc(44, 30, 28));
    draw_rectangle(360, 210, 396, 218, false);
    draw_rectangle(364, 218, 370, 240, false);
    draw_rectangle(386, 218, 392, 240, false);
    draw_rectangle(360, 188, 396, 206, false);
}

function veil_room_parlour() {
    // deep red wallpaper above a black wainscot
    draw_set_colour(vc(38, 16, 20));
    draw_rectangle(0, 24, 480, 178, false);
    draw_set_colour(vc(44, 19, 23));
    for (var _x = 10; _x < 480; _x += 26) draw_rectangle(_x, 24, _x + 11, 178, false);
    draw_set_colour(vc(24, 14, 16));
    draw_rectangle(0, 178, 480, 214, false);
    draw_set_colour(V_BLOOD);
    draw_rectangle(0, 178, 480, 180, false);
    // floor
    draw_set_colour(vc(20, 13, 14));
    draw_rectangle(0, 214, 480, 270, false);
    for (var _y = 220; _y < 270; _y += 11) {
        draw_set_colour(vc(27, 18, 19));
        draw_rectangle(0, _y, 480, _y + 1, false);
    }
    // a tall window behind the table, where the scene has room to be seen
    draw_set_colour(vc(16, 12, 18));
    draw_rectangle(186, 62, 292, 116, false);
    draw_set_colour(vc(28, 30, 44));
    draw_rectangle(190, 66, 288, 112, false);
    draw_set_colour(vc(86, 90, 112));
    draw_circle(212, 80, 8, false);
    draw_set_colour(vc(36, 40, 56));
    for (var _i = 0; _i < 12; _i++) {
        var _rx = 192 + (_i * 23) mod 92;
        var _ry = 68 + ((_i * 31 + global.time * 22) mod 42);
        draw_line(_rx, _ry, _rx - 2, _ry + 6);
    }
    draw_set_colour(vc(16, 12, 18));
    draw_rectangle(237, 66, 241, 112, false);
    draw_rectangle(190, 88, 288, 92, false);
    // water stains and a nailed-over shape, no readable portrait
    draw_set_alpha(0.20);
    draw_set_colour(vc(10, 8, 10));
    draw_ellipse(60, 70, 104, 112, false);
    draw_ellipse(360, 80, 404, 118, false);
    draw_set_alpha(1);
    draw_set_colour(vc(44, 30, 28));
    draw_rectangle(358, 62, 420, 110, false);
    draw_set_colour(vc(22, 14, 14));
    draw_rectangle(362, 66, 416, 106, false);
    draw_set_colour(V_BONE_DIM);
    draw_line(362, 66, 416, 106);
    draw_line(416, 66, 362, 106);
    // rug under the table
    draw_set_colour(vc(52, 18, 22));
    draw_ellipse(150, 202, 322, 244, false);
    draw_set_colour(vc(72, 24, 28));
    draw_ellipse(162, 206, 310, 240, false);
    draw_set_colour(vc(40, 16, 18));
    draw_ellipse(178, 211, 294, 236, false);

}

function veil_room_garden() {
    // night sky through a smashed greenhouse roof
    draw_set_colour(vc(12, 14, 20));
    draw_rectangle(0, 24, 480, 186, false);
    draw_set_colour(vc(26, 32, 40));
    draw_circle(70, 58, 15, false);
    draw_set_colour(vc(16, 18, 24));
    draw_circle(76, 53, 14, false);
    draw_set_colour(vc(32, 40, 44));
    for (var _i = 0; _i < 9; _i++) {
        var _gx = _i * 58 - 10;
        draw_line(_gx, 24, 30 + _gx * 0.7, 120);
        draw_line(_gx + 30, 24, 66 + _gx * 0.7, 120);
    }
    draw_set_colour(vc(22, 26, 24));
    draw_rectangle(0, 120, 480, 190, false);
    // dead trees
    draw_set_colour(vc(34, 28, 26));
    draw_rectangle(398, 92, 406, 176, false);
    draw_line(402, 120, 376, 96);
    draw_line(402, 132, 428, 110);
    draw_line(382, 100, 370, 88);
    draw_line(424, 114, 438, 100);
    draw_rectangle(50, 108, 56, 176, false);
    draw_line(52, 128, 34, 110);
    draw_line(52, 140, 68, 124);
    // ground
    draw_set_colour(vc(26, 22, 18));
    draw_rectangle(0, 190, 480, 270, false);
    draw_set_colour(vc(34, 28, 22));
    for (var _y = 196; _y < 270; _y += 10) draw_rectangle(0, _y, 480, _y + 2, false);
    // fog
    draw_set_alpha(0.10);
    draw_set_colour(vc(150, 160, 160));
    for (var _i = 0; _i < 4; _i++) {
        draw_ellipse(20 + _i * 110, 150 + _i * 12, 190 + _i * 110, 180 + _i * 12, false);
    }
    draw_set_alpha(1);
    // lantern post: the light pool reads as a surface to stand on
    draw_set_colour(vc(40, 32, 28));
    draw_rectangle(316, 128, 321, 200, false);
    draw_set_colour(V_IRON);
    draw_rectangle(310, 120, 327, 130, false);
    draw_set_colour(V_EMBER);
    draw_rectangle(314, 124, 323, 129, false);
    veil_glow(318, 126, 8, V_EMBER, 0.22);

    // roots creeping over the floor
    draw_set_colour(vc(40, 32, 24));
    for (var _i = 0; _i < 7; _i++) {
        var _rx = 20 + _i * 66;
        draw_line(_rx, 268, _rx + 18, 246);
        draw_line(_rx + 18, 246, _rx + 10, 236);
    }
}

function veil_room_hall() {
    // corridor in one-point perspective
    draw_set_colour(vc(18, 14, 17));
    draw_rectangle(0, 24, 480, 270, false);
    draw_set_colour(vc(28, 22, 26));
    draw_triangle(0, 24, 480, 24, 300, 96, false);
    draw_triangle(0, 270, 480, 270, 300, 96, false);
    draw_set_colour(vc(12, 9, 11));
    draw_rectangle(250, 84, 350, 196, false);
    // floor boards converging
    draw_set_colour(vc(30, 22, 24));
    draw_triangle(0, 196, 480, 196, 300, 128, false);
    draw_set_colour(vc(20, 14, 16));
    for (var _i = 0; _i < 9; _i++) {
        var _bx = _i * 60;
        draw_line(_bx, 270, 260 + _bx * 0.2, 138);
    }
    for (var _i = 0; _i < 4; _i++) {
        draw_line(0, 240 - _i * 26, 480, 240 - _i * 26);
    }
    // sconces between the door slots
    for (var _i = 0; _i < 4; _i++) {
        var _sx = 54 + _i * 124;
        draw_set_colour(V_IRON);
        draw_rectangle(_sx, 74, _sx + 4, 82, false);
        draw_set_colour(V_EMBER);
        draw_circle(_sx + 2, 72, 2, false);
        veil_glow(_sx + 2, 72, 3, V_EMBER, 0.14);
        draw_set_alpha(0.10);
        draw_set_colour(V_EMBER);
        draw_triangle(_sx - 14, 118, _sx + 18, 118, _sx + 2, 76, false);
        draw_set_alpha(1);
    }
    // a cat in the far doorway, small enough to be unsettling
    veil_cat(300, 196, 0.9, 0, floor(global.time * 1.2) mod 4, 1);
    // carpet runner
    draw_set_alpha(0.55);
    draw_set_colour(V_BLOOD);
    draw_triangle(160, 270, 320, 270, 300, 132, false);
    draw_set_alpha(1);
}

function veil_room_cellar() {
    // stone vault
    draw_set_colour(vc(20, 20, 18));
    draw_rectangle(0, 24, 480, 270, false);
    draw_set_colour(vc(28, 28, 25));
    for (var _y = 30; _y < 190; _y += 22) {
        var _off = ((_y div 22) mod 2) * 22;
        for (var _x = -22 + _off; _x < 480; _x += 44) {
            draw_rectangle(_x + 1, _y + 1, _x + 42, _y + 20, false);
        }
    }
    draw_set_colour(vc(15, 15, 13));
    draw_rectangle(0, 190, 480, 270, false);
    // puddle
    draw_set_alpha(0.4);
    draw_set_colour(vc(40, 46, 48));
    draw_ellipse(74, 214, 190, 246, false);
    draw_set_alpha(1);
    // shelves of jars
    draw_set_colour(vc(38, 32, 26));
    draw_rectangle(22, 96, 142, 102, false);
    draw_rectangle(22, 132, 142, 138, false);
    for (var _i = 0; _i < 6; _i++) {
        var _jx = 28 + _i * 18;
        draw_set_colour(vc(56, 64, 52));
        draw_rectangle(_jx, 88, _jx + 8, 96, false);
        draw_set_colour(vc(78, 88, 66));
        draw_rectangle(_jx + 1, 84, _jx + 7, 88, false);
    }
    for (var _i = 0; _i < 5; _i++) {
        var _jx = 32 + _i * 21;
        draw_set_colour(vc(46, 42, 50));
        draw_rectangle(_jx, 124, _jx + 9, 132, false);
    }
    // pipes
    draw_set_colour(vc(44, 42, 40));
    draw_rectangle(360, 36, 368, 140, false);
    draw_rectangle(360, 132, 452, 140, false);
    draw_set_alpha(0.25);
    draw_set_colour(V_BLOOD);
    draw_rectangle(364, 140, 366, 160, false);
    draw_set_alpha(1);
    // workbench
    draw_set_colour(vc(50, 38, 28));
    draw_rectangle(130, 176, 330, 188, false);
    draw_set_colour(vc(36, 27, 20));
    draw_rectangle(140, 188, 152, 230, false);
    draw_rectangle(308, 188, 320, 230, false);
    // hanging herbs
    draw_set_colour(vc(52, 58, 40));
    for (var _i = 0; _i < 4; _i++) {
        var _hx = 400 + _i * 18;
        draw_line(_hx, 24, _hx, 40);
        draw_triangle(_hx - 5, 40, _hx + 5, 40, _hx, 58, false);
    }
    veil_cat(360, 232, 1.2, 1, floor(global.time * 1.3) mod 4, 1);
    veil_glow(240, 150, 10, V_EMBER, 0.06);
}

function veil_room_ninth() {
    draw_set_colour(vc(16, 10, 12));
    draw_rectangle(0, 24, 480, 270, false);
    // colossal cracked mirror
    draw_set_colour(vc(30, 22, 24));
    draw_rectangle(126, 34, 354, 180, false);
    draw_set_colour(vc(16, 16, 20));
    draw_rectangle(132, 40, 348, 174, false);
    // faint vertical glints in the glass, never a filled shape: a pale blob
    // on this wall reads as a giant cat head, not a mirror.
    draw_set_alpha(0.10);
    draw_set_colour(vc(120, 132, 146));
    draw_rectangle(196, 44, 208, 168, false);
    draw_rectangle(266, 44, 276, 168, false);
    draw_set_alpha(1);
    draw_set_colour(vc(56, 48, 52));
    draw_line(240, 40, 232, 108);
    draw_line(232, 108, 250, 174);
    draw_line(232, 108, 190, 130);
    draw_line(232, 108, 286, 92);
    // two eyes in the glass
    draw_set_alpha(0.6);
    draw_set_colour(V_BLOOD_HI);
    draw_ellipse(206, 88, 220, 94, false);
    draw_ellipse(254, 88, 268, 94, false);
    draw_set_alpha(1);
    // long table
    draw_set_colour(vc(52, 26, 24));
    draw_rectangle(24, 172, 456, 198, false);
    draw_set_colour(vc(36, 18, 18));
    draw_rectangle(34, 198, 446, 206, false);
    draw_set_colour(vc(64, 32, 28));
    draw_rectangle(24, 172, 456, 175, false);
    // thirteen candles
    for (var _i = 0; _i < 13; _i++) {
        var _cx = 52 + _i * 31;
        draw_set_colour(V_WAX);
        draw_rectangle(_cx, 158, _cx + 3, 172, false);
        draw_set_colour(V_EMBER);
        draw_circle(_cx + 1, 156, 1.6, false);
        veil_glow(_cx + 1, 156, 2, V_EMBER, 0.10);
    }
    // high-backed chairs
    for (var _i = 0; _i < 4; _i++) {
        var _cx = 60 + _i * 116;
        draw_set_colour(vc(34, 22, 20));
        draw_rectangle(_cx, 124, _cx + 26, 176, false);
        draw_set_colour(vc(24, 16, 14));
        draw_rectangle(_cx + 3, 128, _cx + 23, 160, false);
    }
    // floor circle
    draw_set_colour(vc(56, 20, 22));
    draw_ellipse(150, 206, 330, 250, false);
    draw_set_colour(vc(30, 12, 14));
    draw_ellipse(164, 210, 316, 246, false);
    draw_set_colour(V_BLOOD_HI);
    for (var _i = 0; _i < 30; _i++) {
        var _a = _i * 2 * pi / 30;
        var _x = 240 + cos(_a) * 76;
        var _y = 228 + sin(_a) * 18;
        draw_circle(_x, _y, 1, false);
    }
    veil_cat(240, 200, 2.0, 0, floor(global.time) mod 4, 1);
    veil_cat(86, 240, 1.2, 2, floor(global.time * 1.4 + 2) mod 4, 1);
}

