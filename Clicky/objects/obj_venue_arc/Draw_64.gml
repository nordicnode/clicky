/// @description a room/festival story, native 1920 GUI
dui_begin();
dui_pixel_scene(venue_arc_kind(idx) == 1 ? 1 : 2, 1);
dui_dim(0.64);

var _u = venue_arc_ui();
var _c = _u.card;
var _left = _u.left;
var _name = venue_arc_name(idx);
var _steps = venue_arc_steps(idx);
var _count = array_length(_steps);
var _at = venue_arc_step_index(idx);
var _done = venue_arc_done(idx);
var _choice = venue_arc_choice(idx);
var _kind = venue_arc_kind(idx);
var _beat = venue_arc_current_step(idx);

dui_nine(spr_ui_panel, _c.x, _c.y, _c.w, _c.h, 6);
dui_square(_u.close, "X");

story_text_fit(_c.x + 48, _c.y + 24, venue_arc_title(idx),
               global.fnt_big, P_INK, fa_left, _c.w - 120);
var _sub = (_kind == 0 ? "ROOM STORY" : "FESTIVAL STORY") + "  -  " + _name + "  -  "
         + (_done ? "COMPLETE" : "BEAT " + string(_at + 1) + "/" + string(_count));
story_text_fit(_c.x + 48, _c.y + 68, _sub,
               global.fnt_small, P_BROWN, fa_left, _c.w - 120);

// left column: a flat postcard of the place, then its story state
dui_nine(spr_ui_row, _left.x, _left.y, _left.w, _left.h, 4);
var _pr = { x: _left.x + 24, y: _left.y + 12, w: _left.w - 48, h: 132 };
var _z = global.ZONE[venue_arc_room(idx)];
draw_set_colour(_z.wall);
draw_rectangle(_pr.x, _pr.y, _pr.x + _pr.w, _pr.y + _pr.h, false);
draw_set_colour(_z.floor);
draw_rectangle(_pr.x, _pr.y + _pr.h - 30, _pr.x + _pr.w, _pr.y + _pr.h, false);
// window: the one piece of room furniture every location shares
draw_set_colour(P_WOOD);
draw_rectangle(_pr.x + 20, _pr.y + 22, _pr.x + 96, _pr.y + 88, false);
draw_set_colour(P_CREAM);
draw_rectangle(_pr.x + 26, _pr.y + 28, _pr.x + 90, _pr.y + 82, false);
draw_set_colour(P_WOOD);
draw_rectangle(_pr.x + 57, _pr.y + 28, _pr.x + 60, _pr.y + 82, false);
draw_rectangle(_pr.x + 26, _pr.y + 53, _pr.x + 90, _pr.y + 56, false);
// a table and a cup, in the same flat shapes as the counters
draw_set_colour(P_BROWN);
draw_rectangle(_pr.x + 150, _pr.y + 82, _pr.x + 226, _pr.y + 88, false);
draw_rectangle(_pr.x + 158, _pr.y + 88, _pr.x + 164, _pr.y + 102, false);
draw_rectangle(_pr.x + 212, _pr.y + 88, _pr.x + 218, _pr.y + 102, false);
draw_set_colour(P_CORAL);
draw_rectangle(_pr.x + 172, _pr.y + 62, _pr.x + 192, _pr.y + 80, false);
draw_set_colour(P_CREAM);
draw_rectangle(_pr.x + 176, _pr.y + 66, _pr.x + 188, _pr.y + 76, false);
draw_rectangle(_pr.x + 192, _pr.y + 68, _pr.x + 197, _pr.y + 74, false);
if (_kind == 1) {
    for (var _b = 0; _b < 5; _b++) {
        draw_set_colour((_b mod 2) == 0 ? P_CORAL : P_GOLD);
        var _bx = _pr.x + 18 + _b * 44;
        draw_triangle(_bx, _pr.y + 4, _bx + 26, _pr.y + 4, _bx + 13, _pr.y + 20, false);
    }
}

// The display face is 32px and the reading face is 18px. A long venue name
// steps down to the reading face rather than crossing the panel border.
var _nm_w = _left.w - 40;
var _nm_font = text_width_px(_name, global.fnt_big) > _nm_w ? global.fnt_small : global.fnt_big;
story_text_fit(_left.x + _left.w * 0.5, _left.y + 156, _name,
               _nm_font, P_INK, fa_center, _left.w - 8);
story_text_fit(_left.x + _left.w * 0.5, _left.y + 194,
               _kind == 0 ? "A PLACE STORY" : "A FESTIVAL STORY",
               global.fnt_small, P_CORAL, fa_center, _left.w - 16);

// one pip per beat; the current beat is coral, finished beats are gold
var _px0 = _left.x + _left.w * 0.5 - (_count - 1) * 24;
for (var _p = 0; _p < _count; _p++) {
    draw_set_colour(_done || _p < _at ? P_GOLD : (_p == _at ? P_CORAL : P_WOOD));
    draw_circle(_px0 + _p * 48, _left.y + 232, 7, false);
}
story_text_fit(_left.x + _left.w * 0.5, _left.y + 250,
               _done ? "STORY COMPLETE" : "EACH BEAT = 1 STAMP",
               global.fnt_small, P_BROWN, fa_center, _left.w - 16);

if (_done) {
    story_text_fit(_left.x + 16, _left.y + 300, "KEEPSAKE",
                   global.fnt_small, P_GOLD, fa_left, _left.w - 32);
    story_text_fit(_left.x + 16, _left.y + 326, venue_arc_perk_name(idx),
                   global.fnt_small, P_INK, fa_left, _left.w - 32);
    story_text_wrap(_left.x + 16, _left.y + 352, venue_arc_perk_text(idx),
                    global.fnt_small, P_BROWN, fa_left, _left.w - 32, 4, 26);
    story_text_wrap(_left.x + 16, _left.y + 488, "THE LAST BEAT KEPT IT FOR GOOD.",
                    global.fnt_small, P_WOOD, fa_left, _left.w - 32, 2, 26);
} else {
    story_text_wrap(_left.x + 16, _left.y + 310,
                    "FINISH EVERY BEAT TO EARN THIS PLACE'S KEEPSAKE. THE STORY IS YOURS TO KEEP.",
                    global.fnt_small, P_BROWN, fa_left, _left.w - 32, 5, 26);
}

story_button(_u.companion.x, _u.companion.y, _u.companion.w, _u.companion.h,
             "CLOSE", dui_hover(_u.companion.x, _u.companion.y,
                                _u.companion.w, _u.companion.h), false);

// right column: the beat, or the finished keepsake
var _bx = _u.body.x;
var _by = _u.body.y;
var _bw = _u.body.w;
story_text_fit(_bx, _by, _done ? "THE KEEPSAKE" : (is_struct(_beat) ? _beat.title : ""),
               global.fnt_big, P_INK, fa_left, _bw);

if (!_done) {
    story_text_wrap(_bx, _by + 48, is_struct(_beat) ? _beat.text : "",
                    global.fnt_small, P_BROWN, fa_left, _bw, 4, 26);

    if (is_struct(_choice)) {
        story_text_wrap(_bx, _by + 300, _choice.a.text,
                        global.fnt_small, P_BROWN, fa_left, _bw, 2, 26);
        story_text_wrap(_bx, _by + 454, _choice.b.text,
                        global.fnt_small, P_BROWN, fa_left, _bw, 2, 26);
        story_button(_u.choice_a.x, _u.choice_a.y, _u.choice_a.w, _u.choice_a.h,
                     _choice.a.label,
                     dui_hover(_u.choice_a.x, _u.choice_a.y, _u.choice_a.w, _u.choice_a.h), false);
        story_button(_u.choice_b.x, _u.choice_b.y, _u.choice_b.w, _u.choice_b.h,
                     _choice.b.label,
                     dui_hover(_u.choice_b.x, _u.choice_b.y, _u.choice_b.w, _u.choice_b.h), false);
    } else {
        var _g = venue_arc_goal(idx);
        var _ready = venue_arc_goal_ready(idx);
        var _have = min(venue_arc_progress(idx), is_struct(_g) ? _g.n : 0);
        var _target = is_struct(_g) ? _g.n : 1;

        dui_nine(spr_ui_row, _bx, _by + 318, _bw, 220, 4);
        story_text_fit(_bx + 24, _by + 338, "THE ASK",
                       global.fnt_small, P_CORAL, fa_left, _bw - 48);
        story_text_fit(_bx + 24, _by + 374, venue_arc_goal_label(idx),
                       global.fnt_small, P_INK, fa_left, _bw - 48);
        draw_set_colour(P_WOOD);
        draw_roundrect_ext(_bx + 24, _by + 420, _bx + _bw - 24, _by + 432, 6, 6, false);
        if (_target > 0 && _have > 0) {
            draw_set_colour(_ready ? P_MINT : P_GOLD);
            draw_roundrect_ext(_bx + 24, _by + 420,
                               _bx + 24 + (_bw - 48) * clamp(_have / _target, 0, 1),
                               _by + 432, 6, 6, false);
        }
        story_text_fit(_bx + 24, _by + 446, string(_have) + " / " + string(_target),
                       global.fnt_small, _ready ? P_GOLD : P_BROWN, fa_left, _bw * 0.5);
        story_text_fit(_bx + _bw - 24, _by + 446,
                       _ready ? "READY TO CLAIM" : "KEEP GOING",
                       global.fnt_small, _ready ? P_GOLD : P_WOOD, fa_right, _bw * 0.5);

        draw_set_alpha(_ready ? 1 : 0.45);
        story_button(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h,
                     _at >= _count - 1 ? "FINISH THE STORY" : "CLAIM THIS BEAT",
                     _ready && dui_hover(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h),
                     false);
        draw_set_alpha(1);
    }
} else {
    var _r = venue_arc_reward(idx);
    story_text_wrap(_bx, _by + 48, is_struct(_r) ? _r.text : "",
                    global.fnt_small, P_BROWN, fa_left, _bw, 3, 26);
    dui_nine(spr_ui_row, _bx, _by + 150, _bw, 300, 4);
    story_text_fit(_bx + 24, _by + 170, "YOU CHOSE",
                   global.fnt_small, P_CORAL, fa_left, _bw - 48);
    story_text_fit(_bx + 24, _by + 196, venue_arc_choice_label(idx),
                   global.fnt_small, P_INK, fa_left, _bw - 48);
    story_text_wrap(_bx + 24, _by + 232, venue_arc_choice_echo(idx),
                    global.fnt_small, P_BROWN, fa_left, _bw - 48, 2, 26);
    story_text_fit(_bx + 24, _by + 300, "KEPT",
                   global.fnt_small, P_GOLD, fa_left, _bw - 48);
    story_text_wrap(_bx + 24, _by + 326, venue_arc_perk_text(idx),
                    global.fnt_small, P_INK, fa_left, _bw - 48, 2, 26);
    story_text_fit(_bx + _bw * 0.5, _by + 400,
                   _kind == 0 ? "THIS PLACE REMEMBERS YOU" : "THE CIRCUIT REMEMBERS YOU",
                   global.fnt_small, P_GOLD, fa_center, _bw);
    story_button(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h, "CLOSE",
                 dui_hover(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h), false);
}
