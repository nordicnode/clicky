/// The room is the backdrop; the interface is native. The 480x270 illustration
/// is blown up 4x behind a dark vignette, and every plate, label, bar and
/// button on top is drawn in 1920x1080 pixels by the shared dark kit.
if (!veil_active()) exit;
dui_begin();

var _room = (mode == 8) ? 5 : ((mode == 0 || mode == 6 || mode == 7) ? 0 : loc);
ui_legacy_begin();
veil_room(_room);
ui_canvas_reset();
veil_native_vignette();

var _title = "THE HOLLOW HOUR";
var _sub = "THE CAFE AFTER MIDNIGHT";
if (mode == 0) {
    _sub = "CLOSINGS " + string(global.G.occult.closings) + "/13"
           + (global.G.occult.ending ? "   THE NIGHT IS DONE" : "");
} else if (mode == 8) {
    _title = "THE LONG NIGHT";
    var _n = global.G.occult.night;
    _sub = _n.active
           ? ("DEPTH " + string(_n.depth) + "   NERVE " + string(_n.nerve))
           : ("BEST DEPTH " + string(global.G.occult.night_best));
} else if (mode == 6) {
    _title = "THE WALL OF CHARMS";
    _sub = "EMBERS FOR THE RITES. BLOOD FOR THE ALTAR.";
} else if (mode == 7) {
    _title = "THE CABINET";
    _sub = "FORTY RELICS. FIVE SETS OF EIGHT.";
} else {
    _title = veil_loc_name(loc);
    _sub = veil_loc_blurb(loc);
}
veil_header_draw(_title, _sub);

if (mode == 0) {
    veil_map_draw();
} else if (mode == 1) {
    veil_seance_draw(global.G.occult.seance, veil_seance_tier(), false);
} else if (mode == 2) {
    veil_garden_draw();
} else if (mode == 3) {
    veil_hall_draw();
} else if (mode == 4) {
    veil_bench_draw();
} else if (mode == 6) {
    veil_upgrades_draw();
} else if (mode == 7) {
    veil_relics_draw();
} else if (mode == 8) {
    veil_night_draw();
}

veil_nav_draw(mode);

// The blight question is drawn over the shell, after the nav, so no part of
// the garden or its controls competes with the choice.
if (mode == 2) veil_garden_modal_draw();

if (msg_t > 0) {
    dui_vtext(UI_W * 0.5, 932, msg, global.fnt_small, V_EMBER, fa_center);
}

veil_omen_draw();

if (intro > 0) {
    veil_title_card_native(clamp(intro / 64, 0, 1));
}
