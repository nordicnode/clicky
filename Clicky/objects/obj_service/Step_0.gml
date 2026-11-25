/// Select a guest and assemble a dish; each action is saved by the service.
t += 1;
if (closing >= 0) {
    if (t - closing > 10) instance_destroy();
    exit;
}
if (t <= 10) exit;

var _u = service_ui();
if (dui_clicked(_u.close.x, _u.close.y, _u.close.w, _u.close.h)
    || keyboard_check_pressed(vk_escape)) {
    closing = t;
    exit;
}

// the manual opens on whichever page this card is showing
if (dui_clicked(_u.help.x, _u.help.y, _u.help.w, _u.help.h)) {
    var _help = ui_card_spawn(obj_settings);
    _help.guide = 1;
    _help.guide_page = festival_mode ? 5 : 4;
    sfx(snd_pop2, 1);
    exit;
}
if (instance_exists(obj_settings)) exit;
// The venue story is a card above this one. This card must not also answer
// the same click while the story is open.
if (instance_exists(obj_venue_arc)) exit;

if (festival_unlocked()
    && dui_clicked(_u.toggle.x, _u.toggle.y, _u.toggle.w, _u.toggle.h)) {
    festival_mode = !festival_mode;
    festival_feedback = "";
    sfx(snd_pop1, 1);
    exit;
}

if (festival_mode) {
    if (global.G.festival.pending > 0) {
        for (var _i = 0; _i < 3; _i++) {
            var _r = _u.rewards[_i];
            if (dui_clicked(_r.x, _r.y, _r.w, _r.h) && festival_reward(_i)) sfx_buy();
        }
        exit;
    }
    var _vi = VA_ROOMS + festival_venue;
    if (venue_arc_open(_vi)
        && dui_clicked(_u.story.x, _u.story.y, _u.story.w, _u.story.h)) {
        var _card = ui_card_spawn(obj_venue_arc);
        _card.idx = _vi;
        sfx(snd_pop2, 1.05);
        exit;
    }
    if (dui_clicked(_u.venue_prev.x, _u.venue_prev.y,
                    _u.venue_prev.w, _u.venue_prev.h)) {
        festival_venue = max(0, festival_venue - 1);
        festival_feedback = "";
    }
    if (dui_clicked(_u.venue_next.x, _u.venue_next.y,
                    _u.venue_next.w, _u.venue_next.h)
        && festival_venue + 1 < FESTIVAL_VENUES
        && festival_venue_open(festival_venue + 1)) {
        festival_venue += 1;
        festival_feedback = "";
    }
    for (var _i = 0; _i < 3; _i++) {
        var _p = _u.dish_prev[_i];
        var _n = _u.dish_next[_i];
        if (dui_clicked(_p.x, _p.y, _p.w, _p.h) && festival_cycle(_i, -1)) {
            festival_feedback = "";
        }
        if (dui_clicked(_n.x, _n.y, _n.w, _n.h) && festival_cycle(_i, 1)) {
            festival_feedback = "";
        }
    }
    if (dui_clicked(_u.entry.x, _u.entry.y, _u.entry.w, _u.entry.h)) {
        var _result = festival_evaluate(festival_venue);
        var _venue = festival_venues()[festival_venue];
        if (!_result.valid) {
            festival_feedback = _result.message;
        } else if (global.G.journal.materials[$ _venue.material] < festival_cost(festival_venue)) {
            festival_feedback = "NEED " + string(festival_cost(festival_venue))
                              + " " + _venue.label;
        } else if (festival_enter(festival_venue)) {
            festival_feedback = "";
            sfx_milestone();
        }
    }
    exit;
}

var _s = global.G.service;
// Finish a successful order before changing the guest or ingredients.
if (_s.feedback == 4) {
    if (dui_clicked(_u.tip[0].x, _u.tip[0].y, _u.tip[0].w, _u.tip[0].h)
        && service_collect(0)) sfx_buy();
    if (dui_clicked(_u.tip[1].x, _u.tip[1].y, _u.tip[1].w, _u.tip[1].h)
        && service_collect(1)) sfx_buy();
    exit;
}

if (dui_clicked(_u.guest_prev.x, _u.guest_prev.y,
                _u.guest_prev.w, _u.guest_prev.h)) {
    for (var _i = _s.guest - 1; _i >= 0; _i--) {
        if (service_choose_guest(_i)) { sfx(snd_pop1, 1); break; }
    }
}
if (dui_clicked(_u.guest_next.x, _u.guest_next.y,
                _u.guest_next.w, _u.guest_next.h)) {
    for (var _i = _s.guest + 1; _i < SERVICE_GUESTS; _i++) {
        if (service_choose_guest(_i)) { sfx(snd_pop1, 1); break; }
    }
}
if (_s.served[_s.guest] >= SERVICE_RECIPES) exit;
for (var _i = 0; _i < 3; _i++) {
    var _b = _u.base[_i];
    if (dui_clicked(_b.x, _b.y, _b.w, _b.h)) {
        service_choose_ingredient(false, _i);
        sfx(snd_pop1, 1);
    }
    var _t = _u.topping[_i];
    if (dui_clicked(_t.x, _t.y, _t.w, _t.h)) {
        service_choose_ingredient(true, _i);
        sfx(snd_pop2, 1);
    }
}
if (dui_clicked(_u.serve.x, _u.serve.y, _u.serve.w, _u.serve.h)) {
    var _result = service_try();
    if (_result >= 0) {
        if (_result == 3) sfx_milestone();
        else sfx(snd_pop3, 1);
    }
}
