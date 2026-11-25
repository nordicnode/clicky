/// @description boot: configure, load, spawn the cast
var _bf = file_text_open_append("boot.txt");
file_text_write_string(_bf, "start;");
file_text_close(_bf);
game_setup();
var _bf2 = file_text_open_append("boot.txt");
file_text_write_string(_bf2, "setup;");
file_text_close(_bf2);
state_load();
display_apply();
var _bf3 = file_text_open_append("boot.txt");
file_text_write_string(_bf3, "load;");
file_text_close(_bf3);
offline_apply();
var _bf4 = file_text_open_append("boot.txt");
file_text_write_string(_bf4, "offline;");
file_text_close(_bf4);

instance_create_depth(0, 0, 150, obj_bg);
instance_create_depth(0, 0, 900, obj_game);
instance_create_depth(0, 0, 800, obj_hud);
instance_create_depth(0, 0, 200, obj_shop);
instance_create_depth(0, 0, 0, obj_cat_big);
instance_create_depth(0, 0, 5, obj_veil_door);
instance_create_depth(0, 0, 950, obj_debug);

// The guide owns both the always-on goal strip and the first-visit cards. It
// sits above every screen, including the Hollow, so a lesson is readable in
// either palette; it draws nothing while a real modal owns the mouse.
instance_create_depth(0, 0, -11000, obj_guide);

// A player who saved inside the Hollow comes back to it; a broken state was
// already woken by veil_normalize().
if (global.G.occult.in_hollow) {
    instance_create_depth(0, 0, -10000, obj_veil);
}

// The hint is UI, not furniture: in front of the room so the pantry can
// never sit on top of the pill that points at the cat.
instance_create_depth(0, 0, -5000, obj_tutorial);

music_init();
if (!global.G.settings.mute_music) music_start();

// came back after a real break? explain the fish before anything else
if (global.offline_s >= 60) {
    ui_card_spawn(obj_welcome);
}

// bring back a couple of cats for every few tiers already bought
var _pets = min(12, floor((global.G.tiers[0] + global.G.tiers[1] * 2 +
                           global.G.tiers[2] * 3) / 2));
for (var i = 0; i < _pets; i++) {
    var _m = instance_create_depth(random_range(40, 240), random_range(236, 252),
                                   10, obj_cat_mini);
    var _coats = ["tabby", "calico", "tuxedo", "ginger"];
    _m.set_coat(_coats[irandom(3)]);
}

global.tutorial = (global.G.stats.clicks < 8);
