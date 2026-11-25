/// One card at a time. Nothing here pauses the cafe: the card is dismissed,
/// postponed or walked away from, and the economy keeps ticking behind it.
t += 1;
if (strip_grace > 0) strip_grace -= 1;
if (snooze_t > 0) {
    snooze_t -= 1;
    if (snooze_t <= 0) snooze_id = "";
}
if (cooldown > 0) cooldown -= 1;

var _dark = veil_active();

if (shown >= 0) {
    var _def = guide_lesson(def_id);
    if (!is_struct(_def)) {
        shown = -1;
        exit;
    }
    var _np = array_length(_def.pages);

    // Both lesson canvases are native now; only their palette differs.
    var _xr = undefined;
    var _btns = [];
    if (_dark) {
        var _vu = guide_dark_ui();
        _xr = _vu.close;
        _btns = _vu.buttons;
    } else {
        _xr = guide_card_close_rect();
        _btns = guide_card_button_rects();
    }

    var _closed = dui_clicked(_xr.x, _xr.y, _xr.w, _xr.h);
    if (_closed || keyboard_check_pressed(vk_escape)) {
        guide_mark(def_id);
        shown = -1;
        cooldown = 30;
        sfx(snd_pop1, 1);
        exit;
    }
    var _back = dui_clicked(_btns[0].x, _btns[0].y, _btns[0].w, _btns[0].h);
    if (_back) {
        page = max(0, page - 1);
        sfx(snd_pop2, 1.3);
        exit;
    }
    var _next = dui_clicked(_btns[1].x, _btns[1].y, _btns[1].w, _btns[1].h);
    if (_next) {
        if (page < _np - 1) {
            page += 1;
            sfx(snd_pop2, 1.1);
        } else {
            guide_mark(def_id);
            shown = -1;
            cooldown = 30;
            sfx(snd_pop1, 1);
        }
        exit;
    }
    var _guide = dui_clicked(_btns[2].x, _btns[2].y, _btns[2].w, _btns[2].h);
    if (_guide) {
        var _open = _def.pages[page];
        guide_mark(def_id);
        shown = -1;
        cooldown = 30;
        if (!instance_exists(obj_settings)) {
            var _set = ui_card_spawn(obj_settings);
            _set.guide = 1;
            _set.guide_page = _open;
        }
        sfx(snd_pop2, 1);
        exit;
    }
    var _later = dui_clicked(_btns[3].x, _btns[3].y, _btns[3].w, _btns[3].h);
    if (_later) {
        snooze_id = def_id;
        snooze_t = 1800;
        shown = -1;
        cooldown = 30;
        sfx(snd_pop3, 0.9);
        exit;
    }
    exit;
}

// The strip can always be put away or brought back; this is deliberately
// before the lesson cooldown so the control never feels unresponsive. The
// body is inert: only the ? and X buttons react, so a click on the panel
// cannot open the manual underneath the player's finger.
if (!_dark && !ui_card_open()
    && !instance_exists(obj_tutorial) && !instance_exists(obj_welcome)) {
    var _act = guide_strip_action(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0),
                                  mouse_check_button_pressed(mb_left));
    // A click that just collapsed the strip must not bounce it back open on
    // the same press; the tab waits a quarter second before it listens.
    if (_act == "show" && strip_grace > 0) _act = "";
    if (_act == "show") {
        guide_strip_toggle();
        strip_grace = 0;
        sfx(snd_pop2, 1.1);
        exit;
    } else if (_act == "hide") {
        guide_strip_toggle();
        strip_grace = 14;
        sfx(snd_pop3, 0.9);
        exit;
    } else if (_act == "help") {
        var _help_goal = objective_goal();
        if (!instance_exists(obj_settings)) {
            var _gset = ui_card_spawn(obj_settings);
            _gset.guide = 1;
            _gset.guide_page = _help_goal.page;
        }
        sfx(snd_pop2, 1);
        exit;
    }
}

if (cooldown > 0) exit;
if (ui_card_open()) exit;
if (instance_exists(obj_tutorial) || instance_exists(obj_welcome)) exit;

// The Hollow is a destination, not a modal. Its map is the only place a
// location lesson makes sense, and it waits for the title card to clear.
if (_dark) {
    if (!instance_exists(obj_veil)) exit;
    if (obj_veil.intro > 0 || obj_veil.mode != 0) exit;
    if (global.G.occult.omen.id >= 0) exit;
}

var _id = guide_pending(snooze_id);
if (_id == "") exit;

def_id = _id;
page = 0;
shown = 1;
cooldown = 0;
sfx(snd_pop2, 0.85);
