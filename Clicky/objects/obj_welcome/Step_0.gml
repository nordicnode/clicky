/// @description one button, one job: say hello, then get out of the way
t += 1;

var _c = welcome_card_rect();
var _b = { x: _c.x + _c.w * 0.5 - 120, y: _c.y + 292, w: 240, h: UI_H_CTA };

if (closing < 0 && t > 20) {
    if (dui_clicked(_b.x, _b.y, _b.w, _b.h)
        || keyboard_check_pressed(vk_escape)) {
        sfx(snd_buy, 1);
        closing = t;
        exit;
    }
    // never trap a kid: any click outside the card closes it too
    if (mouse_check_button_pressed(mb_left)
        && !dui_hover(_c.x, _c.y, _c.w, _c.h)) {
        closing = t;
    }
}

if (closing >= 0 && t - closing > 12) instance_destroy();
