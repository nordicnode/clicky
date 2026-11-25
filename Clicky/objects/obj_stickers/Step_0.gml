/// @description close on X, Esc or a click outside; page the sheet
t += 1;
if (closing >= 0) {
    if (t - closing > 10) instance_destroy();
    exit;
}
if (t <= 8) exit;

var _u = stickers_ui();
var _pages = ceil(ach_count() / per_page);
if (dui_clicked(_u.prev.x, _u.prev.y, _u.prev.w, _u.prev.h) && page > 0) {
    page -= 1;
    sfx(snd_pop1, 1.2);
    exit;
}
if (dui_clicked(_u.next.x, _u.next.y, _u.next.w, _u.next.h) && page < _pages - 1) {
    page += 1;
    sfx(snd_pop1, 1.2);
    exit;
}
if (dui_clicked(_u.close.x, _u.close.y, _u.close.w, _u.close.h)) {
    closing = t;
    exit;
}
if (keyboard_check_pressed(vk_escape)) {
    closing = t;
    exit;
}
if (mouse_check_button_pressed(mb_left)
    && !dui_hover(_u.card.x, _u.card.y, _u.card.w, _u.card.h)) {
    closing = t;
}
