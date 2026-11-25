/// @description settings card and the manual, native 1920 GUI
dui_begin();

var _fade = clamp(t / 10, 0, 1);
if (closing >= 0) _fade = clamp(1 - (t - closing) / 10, 0, 1);
dui_dim(0.62 * _fade);

if (guide) {
    // One page of the manual at a time. Four jump pills, five short lines and
    // a reading width wide enough that the copy never has to be cut off.
    var _u = manual_ui();
    var _c = _u.card;
    var _pages = guide_pages();
    var _n = array_length(_pages);
    var _pg = clamp(guide_page, 0, _n - 1);
    var _p = _pages[_pg];

    dui_nine(spr_ui_panel, _c.x, _c.y, _c.w, _c.h, 6);
    dui_text(_c.x + 48, _c.y + 30, "GUIDE", global.fnt_big, P_INK, fa_left);
    dui_text(_u.close.x - 24, _c.y + 36,
             "PAGE " + string(_pg + 1) + " / " + string(_n),
             global.fnt_small, P_BROWN, fa_right);
    dui_square(_u.close, "X");

    var _here = guide_section_of(_pg);
    for (var _i = 0; _i < array_length(_u.pills); _i++) {
        var _pill = _u.pills[_i];
        dui_pill(_pill.x, _pill.y, _pill.w, _pill.h, _pill.name, _here == _i,
                 dui_hover(_pill.x, _pill.y, _pill.w, _pill.h));
    }
    draw_set_colour(P_WOOD);
    draw_rectangle(_c.x + 48, _c.y + 180, _c.x + _c.w - 48, _c.y + 182, false);

    dui_text(_c.x + 48, _c.y + 200, _p.title, global.fnt_big, P_INK, fa_left);
    var _lines = guide_lines_px(_p, _u.lines_w);
    for (var _l = 0; _l < min(8, array_length(_lines)); _l++) {
        dui_text(_u.lines_x, _c.y + 256 + _l * 38, _lines[_l],
                 global.fnt_small, P_BROWN, fa_left);
    }

    if (_pg > 0) {
        dui_button(_u.prev.x, _u.prev.y, _u.prev.w, _u.prev.h, "<",
                   dui_hover(_u.prev.x, _u.prev.y, _u.prev.w, _u.prev.h), false);
    } else {
        draw_set_alpha(0.4);
        dui_button(_u.prev.x, _u.prev.y, _u.prev.w, _u.prev.h, "<", false, false);
        draw_set_alpha(1);
    }
    if (_pg < _n - 1) {
        dui_button(_u.next.x, _u.next.y, _u.next.w, _u.next.h, ">",
                   dui_hover(_u.next.x, _u.next.y, _u.next.w, _u.next.h), false);
    } else {
        draw_set_alpha(0.4);
        dui_button(_u.next.x, _u.next.y, _u.next.w, _u.next.h, ">", false, false);
        draw_set_alpha(1);
    }
    dui_button(_u.back.x, _u.back.y, _u.back.w, _u.back.h, "BACK",
               dui_hover(_u.back.x, _u.back.y, _u.back.w, _u.back.h), false);
    dui_text(_c.x + _c.w * 0.5, _c.y + 700,
             "ARROWS PAGE. PILLS JUMP. BACK RETURNS TO MORE.",
             global.fnt_small, P_WOOD, fa_center);
    exit;
}

var _u = settings_ui();
var _c = _u.card;
dui_nine(spr_ui_panel, _c.x, _c.y, _c.w, _c.h, 6);

dui_text(_c.x + 40, _c.y + 30, "MORE", global.fnt_big, P_INK, fa_left);
dui_square(_u.help, "?");
dui_square(_u.close, "X");

var _music_on = !global.G.settings.mute_music;
var _sfx_on   = !global.G.settings.mute_sfx;
var _motion_on = !global.G.settings.reduce_motion;

draw_set_alpha(_music_on ? 1 : 0.62);
dui_button(_u.music.x, _u.music.y, _u.music.w, _u.music.h,
           _music_on ? "MUSIC ON" : "MUSIC OFF",
           dui_hover(_u.music.x, _u.music.y, _u.music.w, _u.music.h), false);
draw_set_alpha(_sfx_on ? 1 : 0.62);
dui_button(_u.sfx.x, _u.sfx.y, _u.sfx.w, _u.sfx.h,
           _sfx_on ? "SOUND ON" : "SOUND OFF",
           dui_hover(_u.sfx.x, _u.sfx.y, _u.sfx.w, _u.sfx.h), false);
draw_set_alpha(1);

draw_set_alpha(_motion_on ? 1 : 0.62);
dui_button(_u.motion.x, _u.motion.y, _u.motion.w, _u.motion.h,
           _motion_on ? "MOTION ON" : "MOTION OFF",
           dui_hover(_u.motion.x, _u.motion.y, _u.motion.w, _u.motion.h), false);
draw_set_alpha(1);

var _hats = array_length(global.G.hats);
var _hat_lab = (_hats > 0)
    ? "HAT: " + string_upper(global.G.equipped_hat) : "NO HATS YET";
_hat_lab = guide_fit_text_px(_hat_lab, _u.hat.w - 24);
// With no hat owned the control is not a promise: it dims like the OFF
// toggles, and the helper says where hats actually come from.
draw_set_alpha(_hats > 0 ? 1 : 0.55);
dui_button(_u.hat.x, _u.hat.y, _u.hat.w, _u.hat.h, _hat_lab,
           _hats > 0 && dui_hover(_u.hat.x, _u.hat.y, _u.hat.w, _u.hat.h), false);
draw_set_alpha(1);
dui_text(_c.x + 40, _c.y + 240,
         _hats > 0 ? "Tap the hat to change it."
                  : "Hats arrive when a yarn reset pays out.",
         global.fnt_small, P_BROWN, fa_left);

// Stickers: the count is the reward, the badge is the signpost.
var _slab = "STICKERS " + string(ach_earned()) + " / " + string(ach_count());
dui_nine(spr_ui_btn_idle, _u.stickers.x, _u.stickers.y, _u.stickers.w, _u.stickers.h, 6);
sticker_badge(_u.stickers.x + 22, _u.stickers.y + 12, 32, spr_fx_sparkle, 0.9);
dui_text(_u.stickers.x + 68, _u.stickers.y + 16, _slab,
         global.fnt_small, P_INK, fa_left);
dui_text(_u.stickers.x + _u.stickers.w - 24, _u.stickers.y + 16, "VIEW",
         global.fnt_small, P_CORAL, fa_right);

// The manual, one explicit door from the settings card.
dui_nine(spr_ui_btn_idle, _u.guide.x, _u.guide.y, _u.guide.w, _u.guide.h, 6);
dui_text(_u.guide.x + 24, _u.guide.y + 16, "HOW TO PLAY",
         global.fnt_small, P_INK, fa_left);
dui_text(_u.guide.x + _u.guide.w - 24, _u.guide.y + 16, "GUIDE",
         global.fnt_small, P_CORAL, fa_right);

// Reset needs a second, deliberate press and says what survives.
if (confirm > 0) {
    draw_set_colour(P_CORAL);
    draw_roundrect_ext(_u.reset.x - 3, _u.reset.y - 3,
                       _u.reset.x + _u.reset.w + 3, _u.reset.y + _u.reset.h + 3,
                       12, 12, false);
}
var _reset_lab = (confirm > 0) ? "SURE? CLICK AGAIN" : "START OVER";
dui_button(_u.reset.x, _u.reset.y, _u.reset.w, _u.reset.h, _reset_lab,
           dui_hover(_u.reset.x, _u.reset.y, _u.reset.w, _u.reset.h), false);
dui_text(_c.x + 40, _c.y + 488,
         confirm > 0 ? "This wipes the cafe. Stickers and settings stay."
                     : "Resets the cafe. Stickers and settings stay.",
         global.fnt_small, confirm > 0 ? P_CORAL : P_BROWN, fa_left);

dui_text(_c.x + 40, _c.y + 600, "Clicky's Cat Cafe",
         global.fnt_small, P_INK, fa_left);
dui_text(_c.x + 40, _c.y + 624, "F11: FULLSCREEN",
         global.fnt_small, P_BROWN, fa_left);
