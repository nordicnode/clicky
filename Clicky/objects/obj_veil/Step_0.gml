/// One input path for the whole layer. Modals never stack: the omen card owns
/// the mouse while it is open, then the screen it interrupted resumes.
t += 1;
if (msg_t > 0) msg_t -= 1;

if (!veil_active()) {
    instance_destroy();
    exit;
}

if (intro > 0) {
    intro -= 1;
    if (mouse_check_button_pressed(mb_left) || keyboard_check_pressed(vk_space)) intro = 0;
    exit;
}

// A first-visit lesson owns the mouse until it is closed or postponed. The
// Hollow's clocks keep running; only its input is held.
if (guide_card_active()) exit;

if (global.G.occult.omen.id >= 0) {
    veil_omen_click();
    exit;
}

// A blighted bed owns the mouse and the shell until it is answered; the nav
// and WAKE buttons must not slide out from under the question.
if (mode == 2 && global.G.occult.garden.choose >= 0) {
    veil_garden_click();
    exit;
}

var _wake = veil_wake_rect();
if (keyboard_check_pressed(vk_escape)
    || dui_clicked(_wake.x, _wake.y, _wake.w, _wake.h)) {
    veil_wake();
    exit;
}

var _nav = veil_nav_click();
if (_nav >= 0) {
    mode = _nav;
    sfx(snd_pop2, 0.7);
    exit;
}

if (mode == 0) {
    var _action = veil_map_click();
    if (string_copy(_action, 1, 4) == "loc:") {
        loc = real(string_delete(_action, 1, 4));
        mode = (loc == 5) ? 8 : loc;
        if (loc == 4) veil_bench_starter();
        sfx(snd_pop1, 0.8);
    } else if (_action == "closing") {
        msg = "THE CLOSING IS HEARD.";
        msg_t = 180;
        sfx_milestone();
    } else if (_action == "locked") {
        msg = "THAT DOOR IS STILL BURIED.";
        msg_t = 150;
    }
    exit;
}

if (mode == 1) {
    var _tier = veil_seance_tier();
    if (global.G.occult.seance.tier != _tier) veil_seance_reset(global.G.occult.seance, _tier);
    veil_seance_click(global.G.occult.seance, _tier, false);
} else if (mode == 2) {
    veil_garden_click();
} else if (mode == 3) {
    veil_hall_click(0, 0);
} else if (mode == 4) {
    veil_bench_click(0, 0);
} else if (mode == 6) {
    if (veil_upgrades_click() == "bought") {
        sfx(snd_buy, 0.8);
    }
} else if (mode == 7) {
    veil_relics_click();
} else if (mode == 8) {
    veil_night_click();
}
