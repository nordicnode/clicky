/// @description stickers: small goals, earned once and kept forever.
/// Every one is reachable in normal play, and none of them punishes anything —
/// a sticker only ever says "you did the thing". The sheet pages through them.

function ach_init() {
    // icons are literal sprite handles, never asset_get_index on a built name
    global.ACH = [
        { id: "tap1",    name: "FIRST!",   icon: spr_fx_heart,    hint: "Tap the cat" },
        { id: "tap200",  name: "TAP 200",   icon: spr_fx_heart,    hint: "200 taps" },
        { id: "combo40", name: "COMBO!",   icon: spr_fx_sparkle,  hint: "Fill the combo" },
        { id: "crit10",  name: "LUCKY",   icon: spr_fx_sparkle,  hint: "10 big crits" },
        { id: "cat10",   name: "10 CATS",    icon: spr_cat_tabby_idle, hint: "10 things bought" },
        { id: "cat50",   name: "50 CATS",   icon: spr_cat_ginger_idle, hint: "50 things bought" },
        { id: "fish1k",  name: "1K FISH",  icon: spr_ui_fish_icon, hint: "Earn 1,000" },
        { id: "fish1m",  name: "1M FISH",   icon: spr_ui_fish_icon, hint: "Earn a million" },
        { id: "fish1b",  name: "1B FISH",   icon: spr_ui_fish_icon, hint: "Earn a billion" },
        { id: "garden",  name: "GARDEN",  icon: spr_fx_sparkle,     hint: "Unlock the garden" },
        { id: "cloud",   name: "CLOUD",  icon: spr_fx_fish,  hint: "Reach the sky" },
        { id: "reset1",  name: "1 YARN",  icon: spr_ui_yarn_icon, hint: "Reset once" },
        { id: "yarn20",  name: "20 YARN",  icon: spr_ui_yarn_icon, hint: "Hold 20 yarn" },
        { id: "star1",   name: "1 STAR",  icon: spr_fx_sparkle,   hint: "Earn a star" },
        { id: "bean1",   name: "1 BEAN",  icon: spr_prop_yarnpit, hint: "Earn a bean" },
        { id: "aurora1", name: "AURORA",  icon: spr_prop_aurora,  hint: "Earn aurora" },
        { id: "moon1",   name: "1 MOON",  icon: spr_prop_lantern, hint: "Earn a moon" },
        { id: "tea",     name: "TEA TIME", icon: spr_prop_teapot, hint: "Reach the tea house" },
        { id: "library", name: "LIBRARY", icon: spr_prop_post,    hint: "Reach the library" },
        { id: "fest1",   name: "FESTIVAL", icon: spr_prop_cake,   hint: "Win a festival rank" },
        { id: "serve10", name: "10 DISHES", icon: spr_ui_fish_icon, hint: "Serve ten dishes" },
        { id: "journal8", name: "8 GOALS", icon: spr_prop_quilt,  hint: "Claim eight goals" },
        { id: "night3",  name: "NIGHT 3",  icon: spr_prop_box,    hint: "Reach night depth 3" },
        { id: "relic5",  name: "5 RELICS", icon: spr_prop_jars,   hint: "Find five relics" }
    ];
}

function ach_count() { return array_length(global.ACH); }

function ach_has(_id) {
    for (var i = 0; i < array_length(global.G.achievements); i++) {
        if (global.G.achievements[i] == _id) return true;
    }
    return false;
}

function ach_earned() { return array_length(global.G.achievements); }

function ach_index(_id) {
    for (var i = 0; i < ach_count(); i++) {
        if (global.ACH[i].id == _id) return i;
    }
    return -1;
}

function ach_total_cats() {
    var _n = 0;
    for (var i = 0; i < TIER_COUNT; i++) _n += global.G.tiers[i];
    return _n;
}

/// A plain switch, because the condition has to be re-read every check.
function ach_met(_id) {
    switch (_id) {
        case "tap1":    return global.G.stats.clicks >= 1;
        case "tap200":  return global.G.stats.clicks >= 200;
        case "combo40": return global.G.stats.best_combo >= 40;
        case "crit10":  return global.G.stats.crits >= 10;
        case "cat10":   return ach_total_cats() >= 10;
        case "cat50":   return ach_total_cats() >= 50;
        case "fish1k":  return global.G.lifetime_earned >= 1000;
        case "fish1m":  return global.G.lifetime_earned >= 1000000;
        case "fish1b":  return global.G.lifetime_earned >= 1000000000;
        case "garden":  return global.G.world.zone >= 1;
        case "cloud":   return global.G.world.zone >= 3;
        case "reset1":  return global.G.stats.prestiges >= 1;
        case "yarn20":  return global.G.layers.yarn >= 20;
        case "star1":   return global.G.earned.stars >= 1;
        case "bean1":   return global.G.earned.beans >= 1;
        case "aurora1": return global.G.earned.aurora >= 1;
        case "moon1":   return global.G.earned.moon >= 1;
        case "tea":     return global.G.world.zone >= 4;
        case "library": return global.G.world.zone >= 5;
        case "fest1":   return ach_festival_best() >= 1;
        case "serve10": return service_total() >= 10;
        case "journal8": return ach_journal_claims() >= 8;
        case "night3":  return global.G.occult.night_best >= 3;
        case "relic5":  return veil_relic_owned_total() >= 5;
    }
    return false;
}

function ach_festival_best() {
    var _best = 0;
    for (var i = 0; i < FESTIVAL_VENUES; i++) _best = max(_best, global.G.festival.ranks[i]);
    return _best;
}

function ach_journal_claims() {
    var _n = 0;
    for (var i = 0; i < array_length(global.G.journal.claims); i++) _n += global.G.journal.claims[i];
    return _n;
}

/// Called a few times a second. Cheap: one switch per unearned sticker.
function ach_check() {
    for (var i = 0; i < ach_count(); i++) {
        var _a = global.ACH[i];
        if (ach_has(_a.id)) continue;
        if (!ach_met(_a.id)) continue;

        array_push(global.G.achievements, _a.id);
        var _t = instance_create_depth(150, 30, 40, obj_toast);
        _t.aid = i;
        sfx(snd_zone, 1.1);   // the same chime a new room gets
        save_touch();
    }
}
