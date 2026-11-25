/// @description economic tick + autosave
// F11 is the way out of fullscreen (and back in). The choice is saved.
if (keyboard_check_pressed(vk_f11)) display_toggle_fullscreen();

var _dt = delta_time / 1000000;
if (_dt > 0.25) _dt = 0.25;

// the soak test plays 30 minutes of game time in five, so the clock has to lie
if (environment_get_variable("CLICKY_SOAK") == "1") _dt *= 6;

global.time += _dt;

econ_tick(_dt);

// the hidden layer's idle systems: beds, omens, familiars
veil_tick(_dt);

// SELF-STOCK: on its own clock, buys the row with the fastest payback. The
// policy is in up_autostock_try(), so a test can ask for one purchase too.
var _stock_sec = up_autostock_sec();
if (_stock_sec > 0) {
    stock_t += _dt;
    if (stock_t >= _stock_sec) {
        stock_t = 0;
        var _pick = up_autostock_try();
        if (_pick >= 0) {
            with (obj_shop) {
                if (_pick >= shop_top && _pick < shop_top + SHOP_ROWS) {
                    juice_floater(150, 138, "STOCKED", P_MINT, false);
                }
                spawn_pet(_pick);
            }
            sfx_buy();
            save_touch();
        }
    }
} else stock_t = 0;

// Helping Hands adds automatic, non-critical taps to the cafe's income.
var _auto_gain = econ_click_value() * up_autotap() * _dt;
global.G.fish += _auto_gain;
global.G.run_earned += _auto_gain;
global.G.lifetime_earned += _auto_gain;
global.G.stats.playtime += _dt;
global.G.stats.best_rate = max(global.G.stats.best_rate, econ_rate());

// a new room is the biggest reward in the game, so it gets its own moment
var _zone = zone_check();
if (_zone >= 0) zone_enter(_zone);
juice_shake_update();

if (global.frenzy_t > 0) {
    global.frenzy_t -= _dt;
    if (global.frenzy_t <= 0) {
        global.frenzy_t = 0;
        global.frenzy = 1;
    }
}

// sparkles: one at a time, never in the first 30 seconds of a session,
// and never on top of a frenzy that is already running
global.run_time += _dt;

// stickers: cheap enough to poll, and they must land the moment they are earned
ach_t -= _dt;
if (ach_t <= 0) { ach_t = 0.4; ach_check(); }
music_apply_gain(_dt);
sparkle_t -= _dt;
if (sparkle_t <= 0) {
    sparkle_t = random_range(45, 75) / (up_magnet() * up_frenzy_chance());
    if (econ_rate() > 0 && global.frenzy_t <= 0 && !instance_exists(obj_sparkle)
        && global.run_time > 30) {
        var _s = instance_create_depth(random_range(40, 240), random_range(150, 190),
                                       5, obj_sparkle);
    }
}

// leaving the window is the most likely way a kid stops playing:
// pay the save for it immediately rather than waiting for the autosave
var _focus = window_has_focus();
if (had_focus && !_focus) save_write();
had_focus = _focus;

autosave_t += _dt;
if (autosave_t >= 15) {
    autosave_t = 0;
    save_write();
}
