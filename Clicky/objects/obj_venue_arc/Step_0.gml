/// @description venue story input: close, choose, claim
t += 1;
if (!opened) {
    venue_arc_open_card(idx);
    opened = true;
}

var _u = venue_arc_ui();
if (closing >= 0) {
    if (t - closing > 10) instance_destroy();
    exit;
}

if (dui_clicked(_u.close.x, _u.close.y, _u.close.w, _u.close.h)
    || keyboard_check_pressed(vk_escape)) {
    closing = t;
    exit;
}

// The manual is the only card allowed above a story. Everything underneath--
// the rooms panel and the service/festival card--waits for this one.
if (instance_exists(obj_settings) || instance_exists(obj_welcome)) exit;

if (venue_arc_done(idx)) {
    if (dui_clicked(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h)) {
        closing = t;
        exit;
    }
} else if (is_struct(venue_arc_choice(idx))) {
    var _d = venue_arc_choice(idx);
    if (dui_clicked(_u.choice_a.x, _u.choice_a.y, _u.choice_a.w, _u.choice_a.h)) {
        venue_arc_choose(idx, 0);
        sfx(snd_pop1, 1.15);
        exit;
    }
    if (dui_clicked(_u.choice_b.x, _u.choice_b.y, _u.choice_b.w, _u.choice_b.h)) {
        venue_arc_choose(idx, 1);
        sfx(snd_pop1, 0.9);
        exit;
    }
} else if (dui_clicked(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h)) {
    if (venue_arc_claim(idx)) {
        sfx(venue_arc_done(idx) ? snd_milestone : snd_buy, 1);
        exit;
    }
}

if (dui_clicked(_u.companion.x, _u.companion.y, _u.companion.w, _u.companion.h)) {
    closing = t;
    exit;
}
