/// @description a cat story, native 1920 GUI
dui_begin();
dui_pixel_scene(2, 1);
dui_dim(0.64);

var _u = arc_ui();
var _c = _u.card;
var _d = arc_data(cat);
var _name = is_struct(_d) ? global.CAT[cat].n : "";
var _step = arc_step_index(cat);
var _done = arc_done(cat);
var _choice = arc_choice(cat);

dui_nine(spr_ui_panel, _c.x, _c.y, _c.w, _c.h, 6);
dui_square(_u.close, "X");

// header: the story title is the card's title, the cat and step are the line
// under it. The album is still visible through the dim behind the card.
story_text_fit(_c.x + 48, _c.y + 24, is_struct(_d) ? _d.title : "CAT STORY",
               global.fnt_big, P_INK, fa_left, _c.w - 120);
var _sub = "CAT STORY  -  " + _name + "  -  "
         + (_done ? "COMPLETE" : "STEP " + string(_step + 1) + "/" + string(ARC_STEPS));
story_text_fit(_c.x + 48, _c.y + 68, _sub,
               global.fnt_small, P_BROWN, fa_left, _c.w - 120);

// left column: portrait, identity, bond meter and the step pips
dui_nine(spr_ui_row, _u.left.x, _u.left.y, _u.left.w, _u.left.h, 4);
draw_sprite_stretched(arc_cat_sprite(cat), 0, _u.portrait.x, _u.portrait.y,
                      _u.portrait.w, _u.portrait.h);
story_text_fit(_u.left.x + _u.left.w * 0.5, _u.left.y + 148, _name,
               global.fnt_big, P_INK, fa_center, _u.left.w - 40);
story_text_fit(_u.left.x + _u.left.w * 0.5, _u.left.y + 184,
               staff_trait_name(cat) + "  -  " + cat_home_name(cat),
               global.fnt_small, P_CORAL, fa_center, _u.left.w - 16);

var _br = cat_bond_rank(cat);
story_text_fit(_u.left.x + _u.left.w * 0.5, _u.left.y + 212,
               "BOND " + string(_br) + "/" + string(CAT_BOND_MAX),
               global.fnt_small, _br >= CAT_BOND_MAX ? P_GOLD : P_BROWN,
               fa_center, _u.left.w - 16);
draw_set_colour(P_WOOD);
draw_roundrect_ext(_u.left.x + 22, _u.left.y + 238, _u.left.x + _u.left.w - 22,
                   _u.left.y + 244, 3, 3, false);
if (cat_bond_progress(cat) > 0) {
    draw_set_colour(P_GOLD);
    draw_roundrect_ext(_u.left.x + 22, _u.left.y + 238,
                       _u.left.x + 22 + (_u.left.w - 44) * cat_bond_progress(cat),
                       _u.left.y + 244, 3, 3, false);
}

// five pips: completed beats are gold, the current beat is coral
for (var _p = 0; _p < ARC_STEPS; _p++) {
    var _px = _u.left.x + 50 + _p * 48;
    var _py = _u.left.y + 280;
    draw_set_colour(_done || _p < _step ? P_GOLD : (_p == _step ? P_CORAL : P_WOOD));
    draw_circle(_px, _py, 7, false);
}
story_text_fit(_u.left.x + _u.left.w * 0.5, _u.left.y + 300,
               _done ? "STORY COMPLETE" : "THE NEXT BEAT EARNS BOND",
               global.fnt_small, P_WOOD, fa_center, _u.left.w);

if (_done) {
    story_text_fit(_u.left.x + 16, _u.left.y + 348, "KEEPSAKE",
                   global.fnt_small, P_GOLD, fa_left, _u.left.w - 32);
    story_text_fit(_u.left.x + 16, _u.left.y + 374, arc_perk_name(cat),
                   global.fnt_small, P_INK, fa_left, _u.left.w - 32);
    story_text_wrap(_u.left.x + 16, _u.left.y + 400, arc_perk_text(cat),
                    global.fnt_small, P_BROWN, fa_left, _u.left.w - 32, 3, 26);
} else {
    story_text_wrap(_u.left.x + 16, _u.left.y + 350,
                    "FINISH EACH BEAT TO EARN THE NEXT BOND RUNG. THE STORY ENDS WITH A KEEPSAKE, NOT A NUMBER.",
                    global.fnt_small, P_BROWN, fa_left, _u.left.w - 32, 5, 26);
}

story_button(_u.companion.x, _u.companion.y, _u.companion.w, _u.companion.h,
             room_companion() == cat ? "WALKING WITH YOU" : "WALK WITH " + _name,
             dui_hover(_u.companion.x, _u.companion.y, _u.companion.w, _u.companion.h),
             false);

// right column: the beat, or the finished keepsake
var _bx = _u.body.x;
var _by = _u.body.y;
var _bw = _u.body.w;
story_text_fit(_bx, _by, _done ? "THE KEEPSAKE" : arc_step_title(cat),
               global.fnt_big, P_INK, fa_left, _bw);

if (!_done) {
    story_text_wrap(_bx, _by + 48, arc_step_text(cat),
                    global.fnt_small, P_BROWN, fa_left, _bw, 4, 26);

    if (is_struct(_choice)) {
        story_text_wrap(_bx, _by + 228, _choice.prompt,
                        global.fnt_small, P_INK, fa_left, _bw, 2, 26);
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
        var _g = arc_goal(cat);
        var _ready = arc_goal_ready(cat);
        var _have = min(arc_progress(cat), is_struct(_g) ? _g.n : 0);
        var _target = is_struct(_g) ? _g.n : 1;

        dui_nine(spr_ui_row, _bx, _by + 318, _bw, 220, 4);
        story_text_fit(_bx + 24, _by + 338, "THE ASK",
                       global.fnt_small, P_CORAL, fa_left, _bw - 48);
        story_text_fit(_bx + 24, _by + 374, arc_goal_label(cat),
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
                     _step >= ARC_STEPS - 1 ? "FINISH THE STORY" : "CLAIM THIS BEAT",
                     _ready && dui_hover(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h),
                     false);
        draw_set_alpha(1);
    }
} else {
    var _r = arc_reward_data(cat);
    story_text_wrap(_bx, _by + 48, is_struct(_r) ? _r.text : "",
                    global.fnt_small, P_BROWN, fa_left, _bw, 3, 26);
    dui_nine(spr_ui_row, _bx, _by + 150, _bw, 260, 4);
    story_text_fit(_bx + 24, _by + 170, "YOU CHOSE",
                   global.fnt_small, P_CORAL, fa_left, _bw - 48);
    story_text_fit(_bx + 24, _by + 196, arc_choice_label(cat),
                   global.fnt_small, P_INK, fa_left, _bw - 48);
    story_text_wrap(_bx + 24, _by + 232, arc_choice_echo(cat),
                    global.fnt_small, P_BROWN, fa_left, _bw - 48, 2, 26);
    story_text_fit(_bx + 24, _by + 280, "KEPT",
                   global.fnt_small, P_GOLD, fa_left, _bw - 48);
    story_text_wrap(_bx + 24, _by + 306, arc_perk_text(cat),
                    global.fnt_small, P_INK, fa_left, _bw - 48, 2, 26);
    // Keep the rank inside the choice plate: +400 put the glyphs on its
    // bottom border instead of in its padding.
    story_text_fit(_bx + _bw * 0.5, _by + 372,
                   "BOND " + string(cat_bond_rank(cat)) + "/" + string(CAT_BOND_MAX),
                   global.fnt_small, P_GOLD, fa_center, _bw);
    story_button(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h, "CLOSE",
                 dui_hover(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h), false);
}
