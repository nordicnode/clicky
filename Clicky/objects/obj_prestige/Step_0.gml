/// @description pick a layer, confirm, spin the ball, then actually reset
t += 1;
if (yarn_ball <= 0) {
    gain = layer_gain(selected_layer);
    can = gain > 0;
}

var _u = prestige_ui();
if (instance_exists(obj_settings)) exit;

if (closing < 0 && t > 14 && yarn_ball <= 0) {
    if (dui_clicked(_u.help.x, _u.help.y, _u.help.w, _u.help.h)) {
        var _help = ui_card_spawn(obj_settings);
        _help.guide = 1;
        _help.guide_page = 3;
        sfx(snd_pop2, 1);
        exit;
    }
    if (dui_clicked(_u.close.x, _u.close.y, _u.close.w, _u.close.h)) {
        closing = t;
        exit;
    }
    var _tabs = tab_layout();
    if (array_length(_tabs) > 1) {
        for (var _i = 0; _i < array_length(_tabs); _i++) {
            var _tab = _tabs[_i];
            if (dui_clicked(_tab.left, _u.tabs_y, _tab.width, 52)
                && _tab.index != selected_layer) {
                pick(_tab.index);
                sfx(snd_pop1, 1.25);
            }
        }
    }
    if (can && dui_clicked(_u.do_btn.x, _u.do_btn.y, _u.do_btn.w, _u.do_btn.h)) {
        sfx(snd_buy, 1);
        yarn_ball = 1;          // the one moment that should feel big
    }
    if (dui_clicked(_u.nah_btn.x, _u.nah_btn.y, _u.nah_btn.w, _u.nah_btn.h)) {
        closing = t;
    }
    if (keyboard_check_pressed(vk_escape)) closing = t;
}

if (yarn_ball > 0) {
    yarn_ball += 1;
    if (yarn_ball == 26) {
        gain = layer_reset(selected_layer);
        flash = 1;
        juice_pop(ui_room_x(_u.card.x + _u.card.w * 0.5), 135, 10, spr_fx_heart);
        juice_pop(ui_room_x(_u.card.x + _u.card.w * 0.5), 135, 8, spr_fx_sparkle);
        sfx(snd_zone, 1);
        with (obj_shop) { pulse = 0; }
        global.combo = 0;
        with (obj_cat_big) { combo = 0; pet_t = 999; }
    }
    if (yarn_ball > 44 && closing < 0) closing = t;
}

if (flash > 0) flash = max(0, flash - 0.04);

if (closing >= 0 && t - closing > 12) instance_destroy();
