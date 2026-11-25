/// @description debug keys, demo cheats and the scripted screenshot sequence

// F11 toggles fullscreen. Alt+Enter is GameMaker's own switch, also enabled.
if (keyboard_check_pressed(vk_f11)) {
    display_toggle_fullscreen();
}

// CLICKY_STRESS=1 fills the room with cats and records the measured frame rate
if (demo != "" && environment_get_variable("CLICKY_STRESS") == "1" && demo_t == 1) {
    // CLICKY_CATS sets the count, so the same build can measure 20 or 300
    var _cc = environment_get_variable("CLICKY_CATS");
    var _n = (_cc != "") ? real(_cc) : 20;
    var _coats = ["tabby", "calico", "tuxedo", "ginger", "grey", "snow", "mint", "rose"];
    for (var s = 0; s < _n; s++) {
        var _st = instance_create_depth(random_range(30, 250), random_range(226, 256),
                                        10, obj_cat_mini);
        _st.set_coat(_coats[irandom(7)]);
    }
}
// Cheat and wipe shortcuts must not be active in a normal player build.
if (debug_mode) {
if (keyboard_check_pressed(vk_f2)) {
    global.G.fish += 10000;
    global.G.run_earned += 10000;
    global.G.lifetime_earned += 10000;
}
if (keyboard_check_pressed(vk_f3)) {
    var _g = econ_rate() * 300;
    global.G.fish += _g;
    global.G.run_earned += _g;
    global.G.lifetime_earned += _g;
}
if (keyboard_check_pressed(vk_f5)) {
    global.frenzy = 2;
    global.frenzy_t = 8;
}
if (keyboard_check_pressed(vk_f6)) screen_save("shot_manual.png");
if (keyboard_check_pressed(vk_f9)) {
    state_reset();
    game_restart();
}
}

// Isolated Hollow run: assertions, then one screenshot per screen.
if (veil_test != "") {
    veil_test_tick();
}

// Isolated cafe-systems run: staff, guide, rooms and the cafe-only entrance.
if (cafe_test != "") {
    cafe_test_tick();
}

// CLICKY_DEMO=1 runs a fixed sequence so screenshots are comparable
if (demo != "") {
    demo_t += 1;

    // a breadcrumb trail, for the runs where the game stops without saying why
    var _tf = file_text_open_append("trace.txt");
    file_text_write_string(_tf, string(demo_t) + ",");
    file_text_close(_tf);

    // the formatter is what every number on screen goes through, so the
    // shipped code writes its own answers out for tools/check_fmt.py
    if (demo_t == 2) {
        var _f = file_text_open_write("fmt.txt");
        var _v = [0, 7, 999, 1000, 1500, 8420, 125000, 1500000, 3200000000];
        file_text_write_string(_f, "half=" + fmt_small(0.5) + ";quarter=" + fmt_small(4.25) + ";");
        for (var i = 0; i < array_length(_v); i++) {
            file_text_write_string(_f, string(_v[i]) + "=" + fmt_number(_v[i]) + ";");
        }
        file_text_write_string(_f, "t840=" + fmt_time(840) + ";t5400=" + fmt_time(5400));
        file_text_close(_f);
    }

    // offline math, checked against the shipped code by tools/check_offline.py
    if (demo_t == 2 && environment_get_variable("CLICKY_OFFTEST") == "1") {
        var _of = file_text_open_write("offline.txt");
        var _now = date_current_datetime();
        // GameMaker dates count DAYS, so a gap in seconds is / 86400
        global.G.last_seen = _now - 600 / 86400;
        file_text_write_string(_of, "tenmin=" + string(offline_seconds()) + ";");
        global.G.last_seen = _now - 6;
        file_text_write_string(_of, "sixdays=" + string(offline_seconds()) + ";");
        global.G.last_seen = 0;
        file_text_write_string(_of, "fresh=" + string(offline_seconds()) + ";");
        // payout must be exactly half the live rate for the clamped time
        global.G.tiers = [10, 5, 0, 0, 0, 0, 0, 0];
        global.G.last_seen = _now - 3600 / 86400;
        var _paid = offline_apply();
        var _expect = econ_rate() * global.offline_s * 0.5;
        file_text_write_string(_of, "paid=" + string(_paid) + ";expect=" + string(_expect)
            + ";ratio=" + string(_expect > 0 ? _paid / _expect : 0));
        // the frenzy double must reach the live rate and nothing else
        global.frenzy = 2;
        file_text_write_string(_of, ";frenzy=" + string(econ_live_rate() / max(1, econ_rate()))
            + ";base=" + string(econ_rate() / max(1, econ_rate())));
        global.frenzy = 1;
        file_text_close(_of);
    }

    // music and the mute path, checked by tools/check_audio.py
    if (environment_get_variable("CLICKY_ATEST") == "1") {
        if (demo_t == 2) {
            var _af = file_text_open_write("audio.txt");
            file_text_write_string(_af, "id=" + string(global.music_id) + ";");
            file_text_write_string(_af, "playing="
                + string(global.music_id >= 0 && audio_is_playing(global.music_id)) + ";");
            file_text_close(_af);
        }
        if (demo_t == 30) {
            global.G.settings.mute_music = true;
            music_refresh();
        }
        if (demo_t == 70) {
            var _af2 = file_text_open_write("audio_muted.txt");
            file_text_write_string(_af2, "gain=" + string(audio_sound_get_gain(global.music_id)));
            file_text_close(_af2);
        }
        if (demo_t == 74) {
            global.G.settings.mute_music = false;
            music_refresh();
        }
        if (demo_t == 120) {
            var _af3 = file_text_open_write("audio_on.txt");
            file_text_write_string(_af3, "gain=" + string(audio_sound_get_gain(global.music_id)));
            file_text_close(_af3);
        }
    }

    // edge cases, checked by tools/check_edge.py: absurd numbers, a maxed
    // cafe, one yarn, and a save that has to survive being written mid-run
    if (environment_get_variable("CLICKY_EDGE") == "1" && demo_t == 2) {
        var _ef = file_text_open_write("edge.txt");

        // 1. numbers far past what a 30-minute run reaches
        file_text_write_string(_ef, "big=" + fmt_number(1000000000000000) + ";");
        file_text_write_string(_ef, "bigrate=" + fmt_rate(987654321000) + ";");

        // 2. every tier maxed: costs must still fit their column (44px)
        global.G.tiers = [200, 200, 200, 200, 200, 200, 200, 200];
        var _widest = 0, _widest_i = -1;
        for (var _t = 0; _t < 8; _t++) {
            draw_set_font(global.fnt_small);
            var _cw = string_width(fmt_number(econ_cost(_t)));
            if (_cw > _widest) { _widest = _cw; _widest_i = _t; }
        }
        file_text_write_string(_ef, "maxcost_width=" + string(_widest) + ";");
        file_text_write_string(_ef, "maxcost_tier=" + string(_widest_i) + ";");
        file_text_write_string(_ef, "maxrate=" + fmt_rate(econ_rate()) + ";");
        global.G.tiers = [0, 0, 0, 0, 0, 0, 0, 0];

        // 3. exactly one yarn is the first hat, and not the second
        global.G.yarn = 1;
        global.G.hats = [];
        global.G.equipped_hat = "";
        global.G.run_earned = 55000000;
        var _g = econ_prestige();
        file_text_write_string(_ef, "yarn_gain=" + string(_g) + ";");
        file_text_write_string(_ef, "hats=" + string(array_length(global.G.hats)) + ";");
        file_text_write_string(_ef, "hat=" + global.G.equipped_hat + ";");

        // 4. a save written now must come back identical (alt-tab, crash, kill)
        global.G.fish = 4242;
        save_write();
        global.G.fish = 0;
        state_load();
        file_text_write_string(_ef, "reload_fish=" + string(global.G.fish) + ";");

        // 5. no fish and nothing owned: the click still pays something
        global.G.fish = 0;
        global.G.click_upgrades = { paw: 0, share: 0 };
        file_text_write_string(_ef, "click_at_zero=" + fmt_small(econ_click_value()) + ";");

        // 6. no sticker name may be wider than its 56px badge
        draw_set_font(global.fnt_small);
        var _wide = 0;
        for (var _si = 0; _si < ach_count(); _si++) {
            _wide = max(_wide, string_width(global.ACH[_si].name));
        }
        file_text_write_string(_ef, "sticker_name_width=" + string(_wide) + ";");
        file_text_write_string(_ef, "sticker_count=" + string(ach_count()) + ";");

        // 7. one kitten per purchase, with no cap in the way at small numbers
        global.G.fish = 1000000000;
        global.G.tiers = [0, 0, 0, 0, 0, 0, 0, 0];
        with (obj_cat_mini) instance_destroy();
        var _before = instance_number(obj_cat_mini);
        for (var _pb = 0; _pb < 6; _pb++) with (obj_shop) buy(0);
        file_text_write_string(_ef, "cats_before=" + string(_before) + ";");
        file_text_write_string(_ef, "cats_after_6=" + string(instance_number(obj_cat_mini)) + ";");

        file_text_close(_ef);
    }

    // the prestige card's spin, step by step: the card must finish the reset
    // and close itself, not leave a yarn ball spinning forever
    if (environment_get_variable("CLICKY_SPINTEST") == "1") {
        if (demo_t == 2) {
            global.G.run_earned = 60000000;
            global.G.lifetime_earned = 60000000;
            spint = file_text_open_write("spin.txt");
        }
        if (demo_t == 4) ui_card_spawn(obj_prestige);
        if (demo_t == 20) { with (obj_prestige) yarn_ball = 1; }
        if (demo_t == 28) screen_save("shot_spin.png");
        if (demo_t > 20 && demo_t < 140 && demo_t mod 8 == 0) {
            var _exists = instance_exists(obj_prestige);
            var _yb = _exists ? obj_prestige.yarn_ball : -1;
            var _cl = _exists ? obj_prestige.closing : -1;
            file_text_write_string(spint, "frame=" + string(demo_t) + " ball=" + string(_yb)
                + " closing=" + string(_cl) + " live=" + string(_exists)
                + " prestiges=" + string(global.G.stats.prestiges)
                + " yarn=" + string(global.G.yarn) + ";");
        }
        if (demo_t == 140) { file_text_close(spint); game_end(); }
    }

    // the maxed cafe, photographed: 200 of every tier and 1e15 fish
    if (environment_get_variable("CLICKY_MAXSHOT") == "1") {
        if (demo_t == 2) {
            global.G.fish = 1000000000000000;
            global.G.lifetime_earned = 1000000000000000;
            global.G.tiers = array_create(TIER_COUNT, 200);
            global.G.yarn = 9999;
        }
        if (demo_t == 40) screen_save("shot_max.png");   // after the welcome card has gone
    }

    // font metrics for the new cards, measured by tools/check_ui.py
    if (environment_get_variable("CLICKY_UIFIT") == "1" && demo_t == 2) {
        var _uf = file_text_open_write("uifit.txt");
        var _words = ["BOOST", "YARN TIME?", "AURORA TIME?", "YARN", "STARS",
                      "BEANS", "AURORA", "SOFT PAWS", "FISH SHARE",
                      "taps earn 1% more of /s", "+1 fish a tap",
                      "boxes 2% cheaper", "each kitten +2%", "400 YARN",
                      "Start the cafe over.", "+10% fish, forever",
                      "Next YARN at 600M", "DO IT!", "NAH", "NOT YET",
                      "+6 YARN", "0/20", "MAXED", "2", "STAR TIME?"];
        for (var _i = 0; _i < array_length(_words); _i++) {
            draw_set_font(global.fnt_big);
            var _bw = string_width(_words[_i]);
            draw_set_font(global.fnt_small);
            var _sw = string_width(_words[_i]);
            file_text_write_string(_uf, _words[_i] + "=" + string(_bw) + "/"
                + string(_sw) + ";");
        }
        draw_set_font(global.fnt_big);
        file_text_write_string(_uf, "BIGH=" + string(string_height("X")) + ";");
        draw_set_font(global.fnt_small);
        file_text_write_string(_uf, "SMALLH=" + string(string_height("X")) + ";");
        file_text_close(_uf);
    }

    // the two new cards, photographed: BOOST at demo_t 60, layers at demo_t 90
    if (environment_get_variable("CLICKY_CARDSHOT") == "1") {
        if (demo_t == 2) {
            global.G.layers.yarn = 400;
            global.G.layers.stars = 60;
            global.G.layers.beans = 20;
            global.G.earned.yarn = 900;
            global.G.earned.stars = 90;
            global.G.earned.beans = 30;
            global.G.yarn = 900;
            global.G.run_earned = 900000000;
        }
        if (demo_t == 30) ui_card_spawn(obj_upgrades);
        if (demo_t == 32) screen_save("shot_boost.png");
        if (demo_t == 50) { with (obj_upgrades) instance_destroy(); }
        if (demo_t == 60) ui_card_spawn(obj_prestige);
        if (demo_t == 62) screen_save("shot_layers.png");
    }

    // 30-minute scripted playtest, written by tools/check_soak.py. A pretend
    // player taps, buys whatever the economy says is best, and prestiges when
    // the button would light up, so every system gets exercised together.
    if (environment_get_variable("CLICKY_SOAK") == "1") {
        soak_t += delta_time / 1000000;
        soak_tap -= delta_time / 1000000;
        soak_log -= delta_time / 1000000;

        if (soak_tap <= 0) {
            soak_tap = 0.35;
            var _n = 1 + irandom(2);
            for (var _k = 0; _k < _n; _k++) {
                with (obj_cat_big) {
                    if (instance_exists(obj_album) || instance_exists(obj_prestige)
                        || instance_exists(obj_welcome) || instance_exists(obj_settings))
                        break;
                    tap();
                }
            }
            // grab a frenzy sparkle whenever one shows up
            with (obj_sparkle) {
                x = x;  // no-op, the pickup is a click
            }
        }

        if (soak_buy <= 0) {
            soak_buy = 0.7;
            // best payback that is actually affordable
            var _best = -1, _bestp = 99999;
            for (var _t2 = 0; _t2 < 8; _t2++) {
                if (!econ_unlocked(_t2)) continue;
                if (!econ_can_buy(_t2)) continue;
                var _p2 = econ_payback(_t2);
                if (_p2 < _bestp) { _bestp = _p2; _best = _t2; }
            }
            if (_best >= 0) with (obj_shop) buy(_best);

            // and take every reset the game would offer
            if (!instance_exists(obj_prestige) && econ_yarn_gain() > 0) {
                var _yg = econ_prestige();
                if (_yg > 0) {
                    soak_s.prestiges += 1;
                    soak_s.yarn = global.G.yarn;
                    zone_flash = 1;
                }
            }
        }

        if (soak_log <= 0) {
            soak_log = 5;
            var _f = file_text_open_append("soak.txt");
            var _cats = instance_number(obj_cat_mini);
            var _line = string(floor(soak_t)) + " fish=" + fmt_number(global.G.fish)
                      + " rate=" + fmt_rate(econ_rate())
                      + " zone=" + string(global.G.world.zone)
                      + " cats=" + string(_cats)
                      + " prestiges=" + string(global.G.stats.prestiges)
                      + " yarn=" + string(global.G.yarn)
                      + " clicks=" + string(global.G.stats.clicks)
                      + " fps=" + string(floor(fps));
            file_text_write_string(_f, _line + string(13) + string(10));
            file_text_close(_f);
        }

        if (soak_t >= soak_end) {
            var _f2 = file_text_open_append("soak.txt");
            file_text_write_string(_f2, "END fish=" + fmt_number(global.G.fish)
                + " lifetime=" + fmt_number(global.G.lifetime_earned)
                + " prestiges=" + string(global.G.stats.prestiges)
                + " yarn=" + string(global.G.yarn)
                + " cats=" + string(instance_number(obj_cat_mini))
                + " zone=" + string(global.G.world.zone)
                + " hats=" + string(array_length(global.G.hats))
                + " clicks=" + string(global.G.stats.clicks)
                + string(13) + string(10));
            file_text_close(_f2);
            save_write();
            game_end();
        }
    }

    // prestige: what it wipes and what it keeps, checked by tools/check_prestige.py
    if (demo_t == 2 && environment_get_variable("CLICKY_PTEST") == "1") {
        var _pf = file_text_open_write("prestige.txt");
        global.G.tiers = [5, 5, 3, 0, 0, 0, 0, 0];
        global.G.fish = 12345;
        global.G.run_earned = 60000000;
        global.G.lifetime_earned = 70000000;
        global.G.yarn = 0;
        global.G.hats = [];
        global.G.click_upgrades = { paw: 3, share: 2 };
        var _life = global.G.lifetime_earned;
        var _gain = econ_prestige();
        file_text_write_string(_pf, "gain=" + string(_gain) + ";");
        file_text_write_string(_pf, "yarn=" + string(global.G.yarn) + ";");
        file_text_write_string(_pf, "fish=" + string(global.G.fish) + ";");
        file_text_write_string(_pf, "run=" + string(global.G.run_earned) + ";");
        var _t = 0;
        for (var i = 0; i < 8; i++) _t += global.G.tiers[i];
        file_text_write_string(_pf, "tiersum=" + string(_t) + ";");
        file_text_write_string(_pf, "paw=" + string(global.G.click_upgrades.paw) + ";");
        file_text_write_string(_pf, "lifekept=" + string(global.G.lifetime_earned == _life ? 1 : 0) + ";");
        file_text_write_string(_pf, "mult=" + string(econ_mult()) + ";");
        file_text_write_string(_pf, "hats=" + string(array_length(global.G.hats)) + ";");
        file_text_write_string(_pf, "prestiges=" + string(global.G.stats.prestiges) + ";");
        file_text_write_string(_pf, "equipped=" + string(global.G.equipped_hat));
        file_text_close(_pf);
    }

    // welcome back card, with a believable offline payout
    if (demo_t == 4) {
        global.offline_s    = 14 * 60;
        global.offline_gain = 8420;
        ui_card_spawn(obj_welcome);
    }
    if (demo_t == 26) screen_save("shot_welcome.png");
    if (demo_t == 30) { with (obj_welcome) instance_destroy(); }

    if (demo_t == 44) {
        global.G.fish += 5000;
        global.G.run_earned += 5000;
        global.G.lifetime_earned += 5000;
    }
    if (demo_t >= 48 && demo_t <= 72 && (demo_t mod 4 == 0)) {
        var _tier = ((demo_t - 48) div 4) mod 3;
        with (obj_shop) buy(_tier);
    }
    if (demo_t >= 80 && demo_t <= 110 && (demo_t mod 10 == 0)) {
        with (obj_cat_big) tap();
    }
    if (demo_t == 114) screen_save("shot_1_combo.png");
    if (demo_t == 120) { with (obj_cat_big) { combo = 0; pet_t = 0; squash = 1; } }
    if (demo_t == 136) screen_save("shot_2_idle.png");
    if (demo_t == 140) { with (obj_cat_big) { combo = 12; pet_t = 999; } }
    if (demo_t == 156) screen_save("shot_3_pet.png");

    // a sparkle pickup, then the frenzy banner it turns on
    if (demo_t == 160) instance_create_depth(150, 170, 5, obj_sparkle);
    if (demo_t == 166) {
        with (obj_sparkle) {
            global.frenzy = 2;
            global.frenzy_t += 8;
            with (obj_hud) frenzy_kick = 1;
            juice_pop(x, y, 6, spr_fx_sparkle);
            instance_destroy();
        }
        with (obj_cat_big) { combo = 0; pet_t = 0; }
    }
    if (demo_t == 172) screen_save("shot_frenzy.png");

    // zone tour: each room, earned through the real zone_check() path
    if (demo_t == 190) global.G.lifetime_earned += 30000;
    if (demo_t == 196) screen_save("shot_zone_card.png");
    if (demo_t == 280) screen_save("shot_4_garden.png");
    if (demo_t == 286) global.G.lifetime_earned += 600000;
    if (demo_t == 376) screen_save("shot_5_rooftop.png");
    if (demo_t == 382) global.G.lifetime_earned += 6000000;
    if (demo_t == 472) screen_save("shot_6_cloud.png");

    // tutorial, settings and a hovered shop row
    if (demo_t == 440) screen_save("shot_tutorial.png");
    if (demo_t == 444) ui_card_spawn(obj_settings);
    if (demo_t == 452) screen_save("shot_settings.png");
    if (demo_t == 456) { with (obj_settings) instance_destroy(); }
    if (demo_t == 462) { with (obj_shop) hover_lock = 0; }
    if (demo_t == 466) screen_save("shot_tooltip.png");
    if (demo_t == 470) { with (obj_shop) hover_lock = -1; }

    // stickers: a sheet with a few earned, and one arriving
    if (demo_t == 470) {
        global.G.achievements = ["tap1", "tap200", "combo40", "cat10", "fish1k", "garden"];
    }
    if (demo_t == 474) {
        var _tst = instance_create_depth(150, 30, 40, obj_toast);
        _tst.aid = 3;
    }
    if (demo_t == 480) screen_save("shot_toast.png");
    if (demo_t == 484) {
        with (obj_toast) instance_destroy();
        ui_card_spawn(obj_stickers);
    }
    if (demo_t == 492) screen_save("shot_stickers.png");
    if (demo_t == 496) { with (obj_stickers) instance_destroy(); }

    // album and yarn cards
    if (demo_t == 480) ui_card_spawn(obj_album);
    if (demo_t == 488) screen_save("shot_album.png");
    if (demo_t == 492) { with (obj_album) instance_destroy(); }
    if (demo_t == 496) {
        global.G.run_earned += 60000000;
        ui_card_spawn(obj_prestige);
    }
    if (demo_t == 504) screen_save("shot_prestige.png");
    if (demo_t == 508) {
        with (obj_prestige) instance_destroy();
        // the first reset hands over a hat: show it on the cat
        global.G.yarn = 10;
        global.G.hats = ["beanie"];
        global.G.equipped_hat = "beanie";
        with (obj_cat_big) { pet_t = 999; }
    }
    if (demo_t == 514) screen_save("shot_hat.png");
    if (demo_t == 518) { global.G.equipped_hat = "crown"; }
    if (demo_t == 524) screen_save("shot_hat_crown.png");
    if (demo_t == 528) { global.G.equipped_hat = "wizard"; }
    if (demo_t == 534) screen_save("shot_hat_wizard.png");

    if (demo_t == 486 && environment_get_variable("CLICKY_STRESS") == "1") {
        var _f = file_text_open_write("perf.txt");
        file_text_write_string(_f, string(fps_real) + " " + string(fps));
        file_text_close(_f);
    }
    if (demo_t == 540) game_end();
}
