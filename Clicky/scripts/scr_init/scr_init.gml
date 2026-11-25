/// @description one-time setup: render config, fonts, economy table, state
#macro GAME_W 480
#macro GAME_H 270
#macro HUD_H 96
#macro DOCK_H 36

// The room is still a 480x270 pixel canvas. The interface is not: it gets its
// own native 1920x1080 canvas, with a 2x type/sprite scale on that canvas. The
// old 480-space helpers remain for the handful of screens not converted yet.
#macro UI_W 1920
#macro UI_H 1080
#macro UI_S 2
#macro UI_LEGACY_S 4
#macro CAT_CAP 400   // kittens in the room at once; the whole point is a lot
#macro SAVE_FILE "save.json"
#macro SAVE_VERSION 1

function game_setup() {
    gpu_set_tex_filter(false);
    display_set_gui_size(UI_W, UI_H);

    // fit the display rather than assuming 1440x810: on a 1080p screen this is
    // x4, on a small laptop x2, and both stay pixel-exact
    var _scale = window_best_scale();
    global.scale = _scale;
    window_set_size(GAME_W * _scale, GAME_H * _scale);
    window_center();

    global.frenzy    = 1;
    global.frenzy_t  = 0;
    global.shake     = 0;
    global.time      = 0;
    global.offline_s = 0;
    global.offline_gain = 0;
    global.run_time = 0;
    global.par_x = 0;        // eased parallax offset, set by zone_parallax()

    font_setup();
    ui_audit_reset();
    econ_init();
    layer_init();
    up_init();
    zones_init();
    album_init();
    ach_init();
    state_defaults();
    veil_init();

    global.zone_flash  = 0;
    global.zone_banner = 0;
}

/// The game is a 480x270 pixel canvas; on a 1920x1080 display the GUI scales
/// exactly 4x, so fullscreen is sharp rather than a resample. The harness can
/// pin a window size, and the player can leave fullscreen with F11.
function display_apply() {
    // The windowed screenshot run always wins: its whole point is a known size.
    var _ws = environment_get_variable("CLICKY_WINSIZE");
    if (_ws != "") {
        var _w = real(string_copy(_ws, 1, string_pos("x", _ws) - 1));
        var _h = real(string_delete(_ws, 1, string_pos("x", _ws)));
        if (_w > 0 && _h > 0) {
            window_set_fullscreen(false);
            window_set_size(_w, _h);
            window_center();
        }
        return;
    }

    var _want = global.G.settings.fullscreen;
    if (environment_get_variable("CLICKY_FULLSCREEN") == "1") _want = true;
    if (_want) {
        window_set_size(1920, 1080);
        window_center();
        window_set_fullscreen(true);
    } else {
        window_set_fullscreen(false);
        var _s = window_best_scale();
        window_set_size(GAME_W * _s, GAME_H * _s);
        window_center();
    }
}

function display_toggle_fullscreen() {
    if (environment_get_variable("CLICKY_WINSIZE") != "") return;
    var _fs = !window_get_fullscreen();
    if (_fs) {
        window_set_size(1920, 1080);
        window_center();
        window_set_fullscreen(true);
    } else {
        window_set_fullscreen(false);
        var _s = window_best_scale();
        window_set_size(GAME_W * _s, GAME_H * _s);
        window_center();
    }
    global.G.settings.fullscreen = _fs;
    save_write();
}

function font_setup() {
    var _s = "";
    for (var i = 32; i < 127; i++) _s += chr(i);
    global.fnt_big   = font_add_sprite_ext(spr_font, _s, false, 0);
    global.fnt_small = font_add_sprite_ext(spr_font_small, _s, false, 0);
}

function state_defaults() {
    global.G = {
        v: SAVE_VERSION,
        fish: 0.0,
        run_earned: 0.0,
        lifetime_earned: 0.0,
        yarn: 0.0,
        // one currency per reset layer: held (to spend) and earned (for the
        // multiplier, so buying an upgrade never slows the cafe down)
        layers: { yarn: 0.0, stars: 0.0, beans: 0.0, aurora: 0.0, moon: 0.0 },
        earned: { yarn: 0.0, stars: 0.0, beans: 0.0, aurora: 0.0, moon: 0.0 },
        prog:   [0, 0, 0, 0, 0],
        up:     {},
        tiers: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        click_upgrades: { paw: 0, share: 0 },
        cats: [],
        hats: [],
        equipped_hat: "",
        achievements: [],
        // Journal progress survives every prestige. Arrays use fixed chapter
        // and project indices so saves can be extended without renaming keys.
        journal: { claims: array_create(32, 0), projects: array_create(24, 0),
                   stamps: 0, skills: [0, 0, 0], orders_done: 0,
                   materials: { treats: 0, scraps: 0, dust: 0 },
                   order_active: [0, 0, 0], order_chapter: [0, 0, 0],
                   order_start: [0, 0, 0] },
        service: service_defaults(),
        festival: festival_defaults(),
        // First-visit lessons already read; additive, so old saves get an
        // empty set rather than replaying everything at once.
        guide: guide_defaults(),
        // Cats met in the album can hold stations here; empty slots are -1.
        staff: staff_defaults(),
        // The hidden layer is additive: a save without it simply gets these
        // defaults and keeps every cafe value it already had.
        occult: veil_defaults(),
        // The post-MOON chapter and the per-room tap memory. Both are additive;
        // an old save gets zeros and starts its first era from today.
        eras: era_defaults(),
        rooms: room_defaults(),
        // Cat bonds and the active companion are album-owned state, separate
        // from room mastery so each has one owner.
        bonds: bond_defaults(),
        companion: 0,
        // Authored cat stories are additive. A save without this key gets the
        // default index arrays and keeps every existing bond and cat.
        arcs: arc_defaults(),
        // Authored room and festival stories. Additive like the cat arcs; an
        // old save gets the default index arrays and keeps every room and rank.
        venue_arcs: venue_arc_defaults(),
        world: { zone: 0, pinned: 0 },
        stats: { clicks: 0, playtime: 0, prestiges: 0, best_rate: 0,
                 best_combo: 0, crits: 0, purchases: 0, sparkles: 0 },
        settings: { mute_music: false, mute_sfx: false, reduce_motion: false,
                    buy: 1, fullscreen: true },
        last_seen: 0
    };
}
