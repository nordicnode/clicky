/// @description story card input: close, choose, claim, walk with
t += 1;
if (!opened) {
    arc_open(cat);
    opened = true;
}

var _u = arc_ui();
if (closing >= 0) {
    if (t - closing > 10) instance_destroy();
    exit;
}

if (dui_clicked(_u.close.x, _u.close.y, _u.close.w, _u.close.h)
    || keyboard_check_pressed(vk_escape)) {
    closing = t;
    exit;
}

// While the story card is up the album underneath must not take a second click.
if (instance_exists(obj_settings) || instance_exists(obj_welcome)) exit;

if (arc_done(cat)) {
    if (dui_clicked(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h)) {
        closing = t;
        exit;
    }
} else if (arc_step_index(cat) == 2 && is_struct(arc_choice(cat))) {
    var _d = arc_choice(cat);
    if (dui_clicked(_u.choice_a.x, _u.choice_a.y, _u.choice_a.w, _u.choice_a.h)) {
        arc_choose(cat, 0);
        sfx(snd_pop1, 1.15);
        exit;
    }
    if (dui_clicked(_u.choice_b.x, _u.choice_b.y, _u.choice_b.w, _u.choice_b.h)) {
        arc_choose(cat, 1);
        sfx(snd_pop1, 0.9);
        exit;
    }
} else if (dui_clicked(_u.claim.x, _u.claim.y, _u.claim.w, _u.claim.h)) {
    if (arc_claim(cat)) {
        sfx(arc_done(cat) ? snd_milestone : snd_buy, 1);
        exit;
    }
}

var _walk = _u.companion;
if (dui_clicked(_walk.x, _walk.y, _walk.w, _walk.h)) {
    if (room_companion_set(cat)) sfx(snd_pop2, 1.1);
    exit;
}
