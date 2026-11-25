/// @description switches, hat, stickers, reset with a second press, close
t += 1;

if (closing >= 0) {
    if (t - closing > 10) instance_destroy();
    exit;
}

// The sticker sheet is a child screen, not a sibling. It owns the mouse while
// it is open; this card stays behind it so closing the sheet returns here.
if (instance_exists(obj_stickers)) exit;

var _u = guide ? manual_ui() : settings_ui();
var _c = _u.card;

if (guide) {
    if (t <= 12) exit;
    var _pages = guide_pages();
    var _n = array_length(_pages);
    var _pg = clamp(guide_page, 0, _n - 1);
    if (dui_clicked(_u.close.x, _u.close.y, _u.close.w, _u.close.h)
        || keyboard_check_pressed(vk_escape)) {
        closing = t;
        exit;
    }
    if (dui_clicked(_u.prev.x, _u.prev.y, _u.prev.w, _u.prev.h) && _pg > 0) {
        guide_page = _pg - 1;
        sfx(snd_pop1, 1.15);
        exit;
    }
    if (dui_clicked(_u.next.x, _u.next.y, _u.next.w, _u.next.h) && _pg < _n - 1) {
        guide_page = _pg + 1;
        sfx(snd_pop1, 1.15);
        exit;
    }
    for (var _i = 0; _i < array_length(_u.pills); _i++) {
        var _pill = _u.pills[_i];
        if (dui_clicked(_pill.x, _pill.y, _pill.w, _pill.h)) {
            guide_page = _pill.first;
            sfx(snd_pop1, 1.25);
            exit;
        }
    }
    if (dui_clicked(_u.back.x, _u.back.y, _u.back.w, _u.back.h)) {
        guide = 0;
        sfx(snd_pop1, 1);
    }
    exit;
}

if (t <= 12) exit;

if (dui_clicked(_u.help.x, _u.help.y, _u.help.w, _u.help.h)) {
    guide = 1;
    guide_page = 0;
    sfx(snd_pop2, 1);
    exit;
}
if (dui_clicked(_u.music.x, _u.music.y, _u.music.w, _u.music.h)) {
    global.G.settings.mute_music = !global.G.settings.mute_music;
    music_refresh();
    sfx(snd_pop2, 1);
    save_touch();
    exit;
}
if (dui_clicked(_u.sfx.x, _u.sfx.y, _u.sfx.w, _u.sfx.h)) {
    global.G.settings.mute_sfx = !global.G.settings.mute_sfx;
    sfx(snd_pop3, 1);
    save_touch();
    exit;
}
if (dui_clicked(_u.motion.x, _u.motion.y, _u.motion.w, _u.motion.h)) {
    global.G.settings.reduce_motion = !global.G.settings.reduce_motion;
    global.shake = 0;
    sfx(snd_pop2, 1);
    save_touch();
    exit;
}

// the hat button cycles through what is owned. With none owned it is inert:
// the dimmed control and its helper text say why, so a click has nothing to do.
if (array_length(global.G.hats) > 0
    && dui_clicked(_u.hat.x, _u.hat.y, _u.hat.w, _u.hat.h)) {
    var _n = array_length(global.G.hats);
    var _i = 0;
    for (var k = 0; k < _n; k++) {
        if (global.G.hats[k] == global.G.equipped_hat) _i = k;
    }
    global.G.equipped_hat = global.G.hats[(_i + 1) mod _n];
    sfx(snd_pop4, 1);
    juice_pop(ui_room_x(_u.hat.x + _u.hat.w * 0.5),
              ui_room_y(_u.hat.y + _u.hat.h * 0.5), 5, spr_fx_heart);
    save_touch();
    exit;
}

if (dui_clicked(_u.stickers.x, _u.stickers.y, _u.stickers.w, _u.stickers.h)
    && !instance_exists(obj_stickers)) {
    sfx(snd_pop2, 1);
    ui_card_spawn(obj_stickers);
    exit;
}
if (dui_clicked(_u.guide.x, _u.guide.y, _u.guide.w, _u.guide.h)) {
    guide = 1;
    guide_page = 0;
    sfx(snd_pop2, 1);
    exit;
}

if (dui_clicked(_u.reset.x, _u.reset.y, _u.reset.w, _u.reset.h)) {
    if (confirm > 0) {
        // stickers and settings survive a reset; everything else goes
        var _keep = global.G.achievements;
        var _set  = global.G.settings;
        state_reset();
        global.G.achievements = _keep;
        global.G.settings = _set;
        save_write();
        game_restart();
    } else {
        confirm = t;
        sfx(snd_crit, 0.8);
    }
    exit;
}

if (dui_clicked(_u.close.x, _u.close.y, _u.close.w, _u.close.h)
    || keyboard_check_pressed(vk_escape)) {
    closing = t;
    exit;
}
if (mouse_check_button_pressed(mb_left) && !dui_hover(_c.x, _c.y, _c.w, _c.h)) {
    closing = t;
}

// a confirm that waits forever is a trap: forget it after four seconds
if (confirm > 0 && t - confirm > 240) confirm = 0;
