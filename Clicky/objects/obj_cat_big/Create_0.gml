/// @description the big petting cat
cx = 150;
feet = 220;
S  = 2.0;combo   = 0;
last_tap = -9999;
pet_t   = 0;
squash  = 1;
idx     = 0;
hover   = false;
auto_t  = 0;
auto_gift = 0;
spr     = spr_cat_big_idle;

tap = function() {
    var _now = current_time;
    var _cap = 40 + up_combo_add() + cat_combo_add();
    var _window = room_combo_window(global.G.world.zone) + cat_combo_grace();
    if (cat_endless_combo()) {
        combo = min(combo + 1 + room_combo_bonus(global.G.world.zone), _cap);
    } else {
        combo = (_now - last_tap < _window)
              ? min(combo + 1 + room_combo_bonus(global.G.world.zone), _cap) : 0;
    }
    last_tap = _now;
    pet_t   = 12;
    squash  = 0.84;
    auto_t  = 0;

    global.G.stats.best_combo = max(global.G.stats.best_combo, combo);
    // Room crit rungs widen the same lucky-tap roll the charms and cat use;
    // the 0.75 cap stays in place so no ladder can make every tap a crit.
    var _crit = (random(1) < min(0.75, 0.10 + up_crit_add() + cat_crit_add()
                                  + room_crit_bonus(global.G.world.zone)));
    var _v = econ_click_value() * (1 + combo * 0.02) * cat_tap_mult()
           * (_crit ? up_crit_mult() * cat_crit_pay() : 1);
    global.G.fish += _v;
    global.G.run_earned += _v;
    global.G.lifetime_earned += _v;
    global.G.stats.clicks += 1;
    // SUNNY's fifth-tap rule pays before the next tap, not after it.
    if (cat_combo5() && global.G.stats.clicks mod 5 == 0) {
        combo = min(combo + 1, _cap);
        global.G.stats.best_combo = max(global.G.stats.best_combo, combo);
    }
    room_tap_add(global.G.world.zone);
    // Three treat paylines can land on one tap: the universal tenth tap, the
    // room rung's own interval, and the active cat's rung. Sum them so the
    // player sees the real total instead of three unrelated numbers.
    var _treat_gain = (global.G.stats.clicks mod 10 == 0) ? 1 : 0;
    var _room_treat = room_treat_every(global.G.world.zone);
    if (_room_treat > 0 && global.G.stats.clicks mod _room_treat == 0) _treat_gain += 1;
    var _cat_treat = cat_treat_every();
    if (_cat_treat > 0 && global.G.stats.clicks mod _cat_treat == 0) _treat_gain += 1;
    // Arc keepsakes feed the same treat floater as the room and bond rules.
    _treat_gain += arc_tap_treats(global.G.world.zone) + arc_crit_treats(_crit);
    if (_treat_gain > 0) {
        global.G.journal.materials.treats += _treat_gain;
        juice_floater(cx + random_range(-10, 10), feet - 92,
                      "+" + string(_treat_gain) + " TREAT"
                      + (_treat_gain > 1 ? "S" : ""), P_GOLD, false);
    }


    juice_floater(cx + random_range(-14, 14), feet - 74,
                  "+" + fmt_number(_v),
                  _crit ? P_CORAL : P_INK, _crit);

    juice_pop(cx, feet - 40, _crit ? 10 : 2,
              _crit ? spr_fx_sparkle : spr_fx_heart);
    juice_shake(_crit ? 2.4 : 0.35);

    // taps are the rhythm, so a meow only colours it now and then
    if (_crit) {
        sfx_crit();
        global.G.stats.crits += 1;
        if (cat_crit_combo()) combo = min(combo + 1, _cap);
    } else sfx_tap();
    if (irandom(9) == 0) sfx(snd_meow, random_range(0.94, 1.12));
    save_touch();
};

/// The room ladder's automatic pet is a reward, not a click. It deliberately
/// does not call tap(): no fish, no click count, no room mastery and no bond.
/// Every eighth pet leaves one treat, so the rung still gives something.
auto_pet = function() {
    pet_t  = 12;
    squash = 0.84;
    auto_t = 0;
    auto_gift += 1;
    if (auto_gift >= 8) {
        auto_gift = 0;
        global.G.journal.materials.treats += 1;
        juice_floater(cx + random_range(-10, 10), feet - 80, "+1 TREAT", P_GOLD, false);
        save_touch();
    } else {
        juice_pop(cx, feet - 40, 1, spr_fx_heart);
    }
    var _arc_t = arc_auto_treats();
    if (_arc_t > 0) {
        global.G.journal.materials.treats += _arc_t;
        juice_floater(cx + random_range(-10, 10), feet - 64,
                      "+" + string(_arc_t) + " TREAT" + (_arc_t > 1 ? "S" : ""),
                      P_GOLD, false);
        save_touch();
    }
    if (irandom(9) == 0) sfx(snd_meow, random_range(0.94, 1.12));
};
