/// @description the layer card, native 1920 GUI
dui_begin();

var _fade = clamp(t / 12, 0, 1);
if (closing >= 0) _fade = clamp(1 - (t - closing) / 12, 0, 1);

dui_pixel_scene(4, 1);
dui_dim(0.62 * _fade);

var _u = prestige_ui();
var _c = _u.card;
var _nm = global.LAYER[selected_layer];
var _mid = _c.x + _c.w * 0.5;

dui_nine(spr_ui_panel, _c.x, _c.y, _c.w, _c.h, 6);

dui_square(_u.help, "?");
dui_text(_mid, _c.y + 30, _nm.title, global.fnt_big, P_INK, fa_center);
dui_square(_u.close, "X");

// layer tabs, each exactly as wide as its word
var _tabs = tab_layout();
if (array_length(_tabs) > 1) {
    for (var _i = 0; _i < array_length(_tabs); _i++) {
        var _tab = _tabs[_i];
        dui_pill(_tab.left, _u.tabs_y, _tab.width, UI_H_ROW,
                 global.LAYER[_tab.index].name, _tab.index == selected_layer,
                 dui_hover(_tab.left, _u.tabs_y, _tab.width, UI_H_ROW));
    }
}

dui_text(_mid, _c.y + 196, "Fish and furniture reset.",
         global.fnt_small, P_BROWN, fa_center);
dui_text(_mid, _c.y + 228, "Charms stay. " + _nm.blurb,
         global.fnt_small, P_BROWN, fa_center);

// the payout, or how far there is to go
if (can) {
    var _num = "+" + fmt_number(gain) + " " + _nm.name;
    var _tw = dui_text_w(_num, global.fnt_big) + 56;
    var _tx = _c.x + (_c.w - _tw) * 0.5;
    draw_sprite_ext(spr_ui_yarn_icon, 0, _tx + 24, _c.y + 302, 3, 3, 0, c_white, 1);
    dui_text(_tx + 56, _c.y + 270, _num, global.fnt_big, P_CORAL, fa_left);
} else {
    var _need = ceil(global.LAYER[selected_layer].need * up_need_mult(selected_layer));
    var _p = layer_progress(selected_layer);
    var _source = selected_layer == 0 ? "FISH" : global.LAYER[selected_layer - 1].name;
    dui_text(_mid, _c.y + 266, "Earn " + fmt_number(_need) + " " + _source,
             global.fnt_small, P_BROWN, fa_center);
    draw_set_colour(P_WOOD);
    draw_roundrect_ext(_u.bar.x, _u.bar.y, _u.bar.x + _u.bar.w,
                       _u.bar.y + _u.bar.h, 8, 8, false);
    if (_p > 0) {
        draw_set_colour(P_GOLD);
        draw_roundrect_ext(_u.bar.x, _u.bar.y,
                           _u.bar.x + max(8, _u.bar.w * _p),
                           _u.bar.y + _u.bar.h, 8, 8, false);
    }
    dui_text(_u.bar.x + _u.bar.w, _u.bar.y - 26,
             string(floor(_p * 100)) + "%", global.fnt_small, P_INK, fa_right);
}

dui_text(_mid, _c.y + 356,
         "You have " + fmt_number(global.G.layers[$ _nm.key]) + " " + _nm.name,
         global.fnt_small, P_BROWN, fa_center);

// What goes and what stays, side by side. This is the decision, not a mood.
var _py = _c.y + 420, _pw = 480, _ph = 180;
dui_nine(spr_ui_row, _c.x + 72, _py, _pw, _ph, 4);
dui_text(_c.x + 96, _py + 20, "RESETS", global.fnt_small, P_CORAL, fa_left);
dui_text(_c.x + 96, _py + 58, "Fish and furniture", global.fnt_small, P_BROWN, fa_left);
dui_text(_c.x + 96, _py + 94, "Shop rows and taps", global.fnt_small, P_BROWN, fa_left);
dui_text(_c.x + 96, _py + 130, "This run's progress", global.fnt_small, P_BROWN, fa_left);

dui_nine(spr_ui_row, _c.x + 648, _py, _pw, _ph, 4);
dui_text(_c.x + 672, _py + 20, "STAYS", global.fnt_small, P_GOLD, fa_left);
dui_text(_c.x + 672, _py + 58, "Charms and cats", global.fnt_small, P_BROWN, fa_left);
dui_text(_c.x + 672, _py + 94, "Journal and stickers", global.fnt_small, P_BROWN, fa_left);
dui_text(_c.x + 672, _py + 130, "Everything you earned", global.fnt_small, P_BROWN, fa_left);

// buttons: DO IT! then NAH, centred as a pair
var _hotb = dui_hover(_u.do_btn.x, _u.do_btn.y, _u.do_btn.w, _u.do_btn.h) && can;
if (can) {
    dui_button(_u.do_btn.x, _u.do_btn.y, _u.do_btn.w, _u.do_btn.h, "DO IT!",
               _hotb, _hotb && mouse_check_button(mb_left));
} else {
    draw_set_alpha(0.45);
    dui_button(_u.do_btn.x, _u.do_btn.y, _u.do_btn.w, _u.do_btn.h, "NOT YET", false, false);
    draw_set_alpha(1);
}
dui_button(_u.nah_btn.x, _u.nah_btn.y, _u.nah_btn.w, _u.nah_btn.h, "NAH",
           dui_hover(_u.nah_btn.x, _u.nah_btn.y, _u.nah_btn.w, _u.nah_btn.h), false);

dui_text(_mid, _c.y + 828,
         "Charms are permanent. Every level survives every reset.",
         global.fnt_small, P_WOOD, fa_center);

// the spin: the yarn ball grows, spins and lands before the reset
if (yarn_ball > 0) {
    var _k = clamp(yarn_ball / 26, 0, 1);
    var _s = 2 + _k * 4;
    draw_set_alpha(0.25 * (1 - _k * 0.4));
    draw_set_colour(P_CORAL);
    draw_circle(_mid, _c.y + 520, 18 * _s, false);
    draw_set_alpha(1);
    draw_sprite_ext(spr_ui_yarn_icon, 0, _mid, _c.y + 520, _s, _s,
                    yarn_ball * 18, c_white, 1);
    if (yarn_ball > 18) {
        var _yt = "+" + fmt_number(gain) + " " + global.LAYER[selected_layer].name + "!";
        // Keep the payout in the clear gap under the two panels. At +590 the
        // big label crossed the panel border while the ball was still rising.
        dui_text(_mid, _c.y + 630, _yt, global.fnt_big, P_INK, fa_center);
    }
}

if (flash > 0) {
    draw_set_alpha(flash * 0.8);
    draw_set_colour(P_WHITE);
    draw_rectangle(0, 0, UI_W, UI_H, false);
    draw_set_alpha(1);
}
