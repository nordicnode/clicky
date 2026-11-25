/// The cafe stays cute. The only wrong thing in it is a pantry cupboard whose
/// right-hand door has never quite latched, and a draught coming through the
/// seam. The cupboard belongs to the Cozy Corner and to nowhere else:
/// zone_cozy_pantry() paints it, and this object asks veil_door_here() before
/// adding the secret.
if (!veil_door_here()) exit;

var _o = global.G.occult;
var _pulse = 0.5 + 0.5 * sin(global.time * 1.1);
var _reveal = clamp(hover_t / 30, 0, 1);

var _dx = CAFE_PANTRY_DOOR_X;       // 144
var _dy = CAFE_PANTRY_DOOR_Y;       // 94
var _dw = CAFE_PANTRY_DOOR_W;       // 38
var _dh = CAFE_PANTRY_DOOR_H;       // 102
var _mid = _dx + _dw div 2;
var _py = CAFE_PANTRY_Y + CAFE_PANTRY_H - 10;

if (!_o.found) {
    // No cracks and no glow. The tell is the dark seam already in the wood,
    // with the faintest thread of cold in it. At rest it is almost nothing;
    // looking at it for a moment brings the cold to the surface.
    draw_set_alpha(0.02 + 0.02 * _pulse + 0.16 * _reveal);
    draw_set_colour(make_colour_rgb(188, 218, 220));
    draw_rectangle(_mid, _dy + 2, _mid, _dy + _dh - 2, false);

    // One fleck of cold air every few seconds, escaping at the foot of the seam.
    // It only becomes visible while the player is actually looking at it.
    var _phase = (global.time * 60) mod 260;
    if (_reveal > 0.02 && _phase < 90) {
        var _k = _phase / 90;
        draw_set_alpha(0.12 * _reveal * (1 - _k));
        draw_set_colour(make_colour_rgb(255, 253, 247));
        draw_rectangle(_mid + _k * 3, _dy + _dh - 2 - _k * 4,
                       _mid + 1 + _k * 3, _dy + _dh - 1 - _k * 4, false);
    }

    // The brass plate answers knocks: three pips, one per knock.
    for (var _i = 0; _i < 3; _i++) {
        draw_set_colour(_o.knocks > _i ? make_colour_rgb(255, 214, 122)
                                       : make_colour_rgb(158, 128, 78));
        draw_rectangle(_mid - 5 + _i * 4, _py + 1, _mid - 4 + _i * 4, _py + 3, false);
    }
    if (knock_t > 0) {
        draw_set_alpha(min(1, knock_t / 14) * 0.40);
        draw_set_colour(make_colour_rgb(236, 246, 246));
        draw_circle(_mid, _dy + 50, 6 + (30 - knock_t) * 0.30, true);
        draw_set_alpha(1);
    }

    // Only the hovered cupboard gets a warm edge; at rest it is furniture.
    if (hover) {
        draw_set_alpha(0.16 + 0.05 * _pulse);
        draw_set_colour(P_GOLD);
        draw_rectangle(_dx - 1, _dy - 1, _dx + _dw + 1, _dy + _dh + 1, true);
    }
    draw_set_alpha(1);
} else {
    // The cupboard is open. The frame, shelf and jars stay; the two doors have
    // swung outward and the dark behind them goes down farther than it should.
    draw_set_colour(make_colour_rgb(16, 11, 13));
    draw_rectangle(_dx, _dy, _dx + _dw, _dy + _dh, false);

    // a little old stone at the lip of the opening
    draw_set_colour(make_colour_rgb(58, 40, 34));
    draw_rectangle(_dx, _dy, _dx + _dw, _dy + 2, false);
    draw_rectangle(_dx, _dy, _dx + 2, _dy + _dh, false);
    draw_rectangle(_dx + _dw - 2, _dy, _dx + _dw, _dy + _dh, false);

    // steps receding into the dark: wide at the bottom, narrowing upward
    for (var _s = 0; _s < 12; _s++) {
        var _sy = _dy + _dh - 5 - _s * 7;
        var _inset = 2 + _s * 1.4;
        draw_set_colour(make_colour_rgb(38, 27, 27));
        draw_rectangle(_dx + _inset, _sy, _dx + _dw - _inset, _sy + 6, false);
        draw_set_colour(make_colour_rgb(86, 58, 46));
        draw_rectangle(_dx + _inset, _sy, _dx + _dw - _inset, _sy + 1, false);
    }

    // something warm, a long way down
    draw_set_alpha(0.14 + 0.05 * _pulse);
    draw_set_colour(make_colour_rgb(176, 42, 46));
    draw_ellipse(_dx + 8, _dy + _dh - 8, _dx + _dw - 8, _dy + _dh, false);
    draw_set_alpha(1);

    // the two doors, swung out to either side
    draw_set_colour(make_colour_rgb(108, 70, 46));
    draw_rectangle(_dx - 8, _dy, _dx - 1, _dy + _dh, false);
    draw_set_colour(make_colour_rgb(181, 120, 80));
    draw_rectangle(_dx - 7, _dy + 1, _dx - 2, _dy + _dh - 1, false);
    draw_set_colour(make_colour_rgb(140, 90, 60));
    draw_rectangle(_dx - 8, _dy + 9, _dx - 1, _dy + 11, false);
    draw_rectangle(_dx - 8, _dy + _dh - 11, _dx - 1, _dy + _dh - 9, false);

    draw_set_colour(make_colour_rgb(108, 70, 46));
    draw_rectangle(_dx + _dw + 1, _dy, _dx + _dw + 8, _dy + _dh, false);
    draw_set_colour(make_colour_rgb(181, 120, 80));
    draw_rectangle(_dx + _dw + 2, _dy + 1, _dx + _dw + 7, _dy + _dh - 1, false);
    draw_set_colour(make_colour_rgb(140, 90, 60));
    draw_rectangle(_dx + _dw + 1, _dy + 9, _dx + _dw + 8, _dy + 11, false);
    draw_rectangle(_dx + _dw + 1, _dy + _dh - 11, _dx + _dw + 8, _dy + _dh - 9, false);

    // a second fleck of cold air, rising from the stairwell
    var _phase2 = (global.time * 60) mod 300;
    if (_phase2 < 110) {
        var _k2 = _phase2 / 110;
        draw_set_alpha(0.16 * (1 - _k2));
        draw_set_colour(make_colour_rgb(255, 253, 247));
        draw_rectangle(_dx + _dw * 0.5 - _k2 * 5, _dy + _dh - 3 - _k2 * 14,
                       _dx + _dw * 0.5 + 1 - _k2 * 5, _dy + _dh - 2 - _k2 * 14, false);
        draw_set_alpha(1);
    }

    if (hover) {
        draw_set_alpha(0.30 + 0.08 * _pulse);
        draw_set_colour(P_GOLD);
        draw_rectangle(_dx, _dy, _dx + _dw, _dy + _dh, true);
        draw_set_alpha(1);
        // one small chevron, low and quiet, so the opening reads as a way in
        draw_set_colour(P_GOLD);
        draw_triangle(_dx + _dw * 0.5 - 4, _dy + _dh - 8,
                      _dx + _dw * 0.5 + 4, _dy + _dh - 8,
                      _dx + _dw * 0.5, _dy + _dh - 3, false);
    }
}
