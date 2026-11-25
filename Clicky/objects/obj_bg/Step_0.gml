/// @description keep ambient life in step with the room
zone_ambient_step();

// a zone can change at any time; move the ambient life with it
if (global.G.world.zone != last_zone) {
    last_zone = global.G.world.zone;
    zone_ambient_init(last_zone);
}

if (global.zone_flash > 0) global.zone_flash -= 0.035;
if (global.zone_banner > 0) global.zone_banner -= 1;

// The ROOMS control only exists once there is somewhere else to go, and it
// steps aside for every card.
var _blocked = ui_modal_open()
            || guide_card_active() || guide_strip_hover();
if (_blocked) {
    travel_open = false;
    exit;
}

var _pick = zone_travel_click(travel_open);
if (_pick == -2) {
    travel_open = !travel_open;
    if (travel_open) sfx(snd_pop2, 1);
} else if (_pick == -3) {
    var _card = ui_card_spawn(obj_venue_arc);
    _card.idx = global.G.world.zone;
    sfx(snd_pop2, 1.05);
    travel_open = false;
} else if (_pick >= 0) {
    if (_pick != global.G.world.zone) {
        zone_enter(_pick);
        sfx(snd_pop1, 1);
    }
    travel_open = false;
}
