/// The lesson card and the objective strip. The cafe screens are native 1920;
/// the Hollow card keeps its 480-space pixel layout behind a 4x matrix, which
/// is still the same size it has always been on screen.
dui_begin();

if (veil_active()) {
    if (shown < 0) exit;
    var _vd = guide_lesson(def_id);
    if (!is_struct(_vd)) exit;
    var _vu = guide_dark_ui();
    var _vc = _vu.card;
    var _vpage = guide_pages()[_vd.pages[page]];
    var _vlines = guide_lines_px(_vpage, _vc.w - 64);

    // A lesson is a full-screen decision, not a note on top of a live room.
    // One scrim keeps the map, ledger and shell from competing with the copy.
    draw_set_alpha(0.82);
    draw_set_colour(V_VOID);
    draw_rectangle(0, 0, UI_W, UI_H, false);
    draw_set_alpha(1);

    draw_set_alpha(0.55);
    draw_set_colour(V_VOID);
    draw_rectangle(_vc.x + 8, _vc.y + 10, _vc.x + _vc.w + 8, _vc.y + _vc.h + 10, false);
    draw_set_alpha(1);
    dui_vpanel(_vc.x, _vc.y, _vc.w, _vc.h, 1);

    dui_vtext(_vc.x + 32, _vc.y + 22, "HOLLOW LESSON", global.fnt_small, V_EMBER, fa_left);
    dui_vtext(_vc.x + _vc.w - 108, _vc.y + 22,
              string(page + 1) + "/" + string(array_length(_vd.pages)),
              global.fnt_small, V_BONE_DIM, fa_right);
    dui_vtext(_vc.x + 32, _vc.y + 56, _vd.title, global.fnt_big, V_BONE, fa_left);

    var _xr = _vu.close;
    dui_vbutton(_xr.x, _xr.y, _xr.w, _xr.h, "X",
                dui_hover(_xr.x, _xr.y, _xr.w, _xr.h), false, true);

    draw_set_colour(V_IRON);
    draw_rectangle(_vc.x + 32, _vc.y + 110, _vc.x + _vc.w - 32, _vc.y + 113, false);
    for (var _l = 0; _l < min(6, array_length(_vlines)); _l++) {
        dui_vtext(_vc.x + 32, _vc.y + 132 + _l * 30, _vlines[_l],
                  global.fnt_small, V_BONE_DIM, fa_left);
    }
    dui_vtext(_vc.x + 32, _vc.y + _vc.h - 132,
              "You can read this again any time in GUIDE.",
              global.fnt_small, vc(112, 100, 90), fa_left);

    var _btns = _vu.buttons;
    dui_vbutton(_btns[0].x, _btns[0].y, _btns[0].w, _btns[0].h, "BACK",
                page > 0 && dui_hover(_btns[0].x, _btns[0].y, _btns[0].w, _btns[0].h),
                false, page > 0);
    dui_vbutton(_btns[1].x, _btns[1].y, _btns[1].w, _btns[1].h,
                (page < array_length(_vd.pages) - 1) ? "NEXT" : "DONE",
                dui_hover(_btns[1].x, _btns[1].y, _btns[1].w, _btns[1].h), false, true);
    dui_vbutton(_btns[2].x, _btns[2].y, _btns[2].w, _btns[2].h, "GUIDE",
                dui_hover(_btns[2].x, _btns[2].y, _btns[2].w, _btns[2].h), false, true);
    dui_vbutton(_btns[3].x, _btns[3].y, _btns[3].w, _btns[3].h, "LATER",
                dui_hover(_btns[3].x, _btns[3].y, _btns[3].w, _btns[3].h), false, true);
    exit;
}

if (shown >= 0) {
    var _ld = guide_lesson(def_id);
    if (!is_struct(_ld)) exit;
    var _lpage = guide_pages()[_ld.pages[page]];
    var _llines = guide_lines_px(_lpage, 872);
    var _c = guide_card_rect();
    var _btns = guide_card_button_rects();

    // A soft shadow lifts the card off the room without dimming the whole cafe.
    draw_set_alpha(0.35);
    draw_set_colour(P_INK);
    draw_roundrect_ext(_c.x + 6, _c.y + 8, _c.x + _c.w + 6, _c.y + _c.h + 8, 14, 14, false);
    draw_set_alpha(1);
    dui_nine(spr_ui_panel, _c.x, _c.y, _c.w, _c.h, 6);

    dui_text(_c.x + 32, _c.y + 24, "NEW SYSTEM", global.fnt_small, P_CORAL, fa_left);
    dui_text(_c.x + _c.w - 96, _c.y + 24,
             string(page + 1) + "/" + string(array_length(_ld.pages)),
             global.fnt_small, P_BROWN, fa_right);
    dui_text(_c.x + 32, _c.y + 54, _ld.title, global.fnt_big, P_INK, fa_left);

    dui_square(guide_card_close_rect(), "X");

    draw_set_colour(P_WOOD);
    draw_rectangle(_c.x + 32, _c.y + 106, _c.x + _c.w - 32, _c.y + 108, false);
    for (var _l2 = 0; _l2 < min(5, array_length(_llines)); _l2++) {
        dui_text(_c.x + 32, _c.y + 126 + _l2 * 30, _llines[_l2],
                 global.fnt_small, P_BROWN, fa_left);
    }
    dui_text(_c.x + 32, _c.y + 300, "You can read this again any time in GUIDE.",
             global.fnt_small, P_WOOD, fa_left);

    if (page > 0) {
        dui_button(_btns[0].x, _btns[0].y, _btns[0].w, _btns[0].h, "BACK",
                   dui_hover(_btns[0].x, _btns[0].y, _btns[0].w, _btns[0].h), false);
    } else {
        draw_set_alpha(0.4);
        dui_button(_btns[0].x, _btns[0].y, _btns[0].w, _btns[0].h, "BACK", false, false);
        draw_set_alpha(1);
    }
    dui_button(_btns[1].x, _btns[1].y, _btns[1].w, _btns[1].h,
               (page < array_length(_ld.pages) - 1) ? "NEXT" : "DONE",
               dui_hover(_btns[1].x, _btns[1].y, _btns[1].w, _btns[1].h), false);
    dui_button(_btns[2].x, _btns[2].y, _btns[2].w, _btns[2].h, "GUIDE",
               dui_hover(_btns[2].x, _btns[2].y, _btns[2].w, _btns[2].h), false);
    dui_button(_btns[3].x, _btns[3].y, _btns[3].w, _btns[3].h, "LATER",
               dui_hover(_btns[3].x, _btns[3].y, _btns[3].w, _btns[3].h), false);
    exit;
}

if (veil_active()) exit;
if (global.tutorial || instance_exists(obj_tutorial)) exit;
if (ui_card_open()) exit;

var _sr = guide_strip_rects();

// Collapsed: one explicit 56x56 ? is the whole footprint.
if (guide_strip_collapsed()) {
    var _show = _sr.show;
    dui_nine(spr_ui_btn_idle, _show.x, _show.y, _show.w, _show.h, 4);
    draw_set_colour(P_CORAL);
    draw_rectangle(_show.x, _show.y, _show.x + 6, _show.y + _show.h, false);
    dui_text(_show.x + _show.w * 0.5, _show.y + 11, "?", global.fnt_small,
             P_CORAL, fa_center);
    exit;
}

var _goal = objective_goal();
var _p = _sr.panel;

draw_set_alpha(0.34);
draw_set_colour(P_INK);
draw_roundrect_ext(_p.x + 6, _p.y + 8, _p.x + _p.w + 6, _p.y + _p.h + 8, 14, 14, false);
draw_set_alpha(1);
dui_nine(spr_ui_panel, _p.x, _p.y, _p.w, _p.h, 6);

// The coral flag is the one constant: it marks the next action.
draw_set_colour(P_CORAL);
draw_rectangle(_p.x + 10, _p.y + 20, _p.x + 16, _p.y + _p.h - 20, false);

dui_text(_p.x + 32, _p.y + 20, "NEXT", global.fnt_small, P_CORAL, fa_left);
dui_text(_p.x + 112, _p.y + 18,
         guide_fit_text_px(_goal.short, _p.w - 280), global.fnt_small, P_INK, fa_left);

var _why = guide_wrap_px(_goal.why, 600);
for (var _w = 0; _w < min(2, array_length(_why)); _w++) {
    dui_text(_p.x + 32, _p.y + 58 + _w * 28,
             _why[_w], global.fnt_small, P_BROWN, fa_left);
}

// progress hairline
draw_set_colour(P_WOOD);
draw_rectangle(_p.x + 32, _p.y + _p.h - 24, _p.x + _p.w - 152, _p.y + _p.h - 18, false);
draw_set_colour(P_GOLD);
draw_rectangle(_p.x + 32, _p.y + _p.h - 24,
               _p.x + 32 + (_p.w - 184) * _goal.bar, _p.y + _p.h - 18, false);

// two explicit buttons; the body between them stays inert
dui_square(_sr.help, "?");
dui_square(_sr.hide, "X");
