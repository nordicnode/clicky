/// @description leave on its own; never block anything
// A card on screen owns the mouse and the player's attention, so the toast
// waits: it neither draws nor ages until the card closes. Otherwise a sticker
// badge pops up over the card the player is reading.
if (ui_card_open()) exit;

t += 1;
if (t > life) instance_destroy();
