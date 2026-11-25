/// @description the cafe counter and festival, native 1920 GUI
dui_begin();

var _fade = clamp(t / 10, 0, 1);
if (closing >= 0) _fade = clamp(1 - (t - closing) / 10, 0, 1);
dui_pixel_scene(festival_mode ? 1 : 0, 1);
dui_dim(0.62 * _fade);

var _u = service_ui();
var _c = _u.card;
var _mid = _c.x + _c.w * 0.5;
dui_nine(spr_ui_panel, _c.x, _c.y, _c.w, _c.h, 6);

dui_text(_c.x + 40, _c.y + 30, festival_mode ? "FESTIVAL" : "COUNTER",
         global.fnt_big, P_INK, fa_left);
if (festival_unlocked()) {
    dui_button(_u.toggle.x, _u.toggle.y, _u.toggle.w, _u.toggle.h,
               festival_mode ? "COUNTER" : "FESTIVAL!",
               dui_hover(_u.toggle.x, _u.toggle.y, _u.toggle.w, _u.toggle.h), false);
}
dui_button(_u.help.x, _u.help.y, _u.help.w, _u.help.h, "?",
           dui_hover(_u.help.x, _u.help.y, _u.help.w, _u.help.h), false);
dui_button(_u.close.x, _u.close.y, _u.close.w, _u.close.h, "X",
           dui_hover(_u.close.x, _u.close.y, _u.close.w, _u.close.h), false);

if (festival_mode) {
    var _f = global.G.festival;
    if (_f.pending > 0) {
        dui_text(_mid, _c.y + 180, "FESTIVAL COMPLETE!", global.fnt_big,
                 P_CORAL, fa_center);
        dui_text(_mid, _c.y + 224, "CHOOSE ONE REWARD", global.fnt_small,
                 P_BROWN, fa_center);
        var _rewards = ["+" + string(6 * _f.pending) + " EACH MATERIAL",
                        "+" + string(2 * _f.pending) + " JOURNAL STAMPS",
                        "+" + string(_f.pending) + " MOON TO SPEND"];
        for (var _i = 0; _i < 3; _i++) {
            var _r = _u.rewards[_i];
            dui_button(_r.x, _r.y, _r.w, _r.h, _rewards[_i],
                       dui_hover(_r.x, _r.y, _r.w, _r.h), false);
        }
        dui_text(_mid, _c.y + 560, "Rewards survive closing the card.",
                 global.fnt_small, P_BROWN, fa_center);
        exit;
    }

    var _v = festival_venues()[festival_venue];
    var _rank = _f.ranks[festival_venue];
    dui_button(_u.venue_prev.x, _u.venue_prev.y, _u.venue_prev.w, _u.venue_prev.h,
               "<", dui_hover(_u.venue_prev.x, _u.venue_prev.y,
                              _u.venue_prev.w, _u.venue_prev.h), false);
    dui_button(_u.venue_next.x, _u.venue_next.y, _u.venue_next.w, _u.venue_next.h,
               ">", dui_hover(_u.venue_next.x, _u.venue_next.y,
                              _u.venue_next.w, _u.venue_next.h), false);
    dui_text(_mid, _c.y + 132, _v.name, global.fnt_big, P_INK, fa_center);
    var _vi = VA_ROOMS + festival_venue;
    if (venue_arc_open(_vi)) {
        var _slabel = "VENUE STORY";
        if (venue_arc_done(_vi)) _slabel = "STORY KEPT";
        else if (venue_arc_started(_vi)) _slabel = "STORY " + venue_arc_label(_vi);
        var _sr = _u.story;
        dui_button(_sr.x, _sr.y, _sr.w, _sr.h, _slabel,
                   dui_hover(_sr.x, _sr.y, _sr.w, _sr.h), false);
    }

    if (_rank < FESTIVAL_RANKS) {
        var _rules = _v.challenges[_rank];
        dui_text(_mid, _c.y + 196, festival_rule_label(_rules[0], true),
                 global.fnt_small, P_BROWN, fa_center);
        dui_text(_mid, _c.y + 228, festival_rule_label(_rules[1], false),
                 global.fnt_small, P_BROWN, fa_center);
    } else {
        dui_text(_mid, _c.y + 212, "ALL CHALLENGES COMPLETE",
                 global.fnt_small, P_BROWN, fa_center);
    }
    dui_text(_mid, _c.y + 276, "PICK 3 DIFFERENT DISCOVERED DISHES",
             global.fnt_small, P_INK, fa_center);
    dui_text(_mid, _c.y + 308, "RANK " + string(_rank) + "/3 - WIN 1 TO OPEN NEXT",
             global.fnt_small, P_BROWN, fa_center);

    var _bases = ["FISH", "CREAM", "GREENS"];
    var _toppings = ["CRUNCH", "BERRY", "HERBS"];
    for (var _i = 0; _i < 3; _i++) {
        var _dish = _f.menu[_i];
        var _label = "DISCOVER DISHES AT COUNTER";
        if (festival_recipe_known(_dish)) {
            _label = service_guests()[_dish div SERVICE_RECIPES].name + ": "
                   + _bases[global.G.service.known_base[_dish]] + " + "
                   + _toppings[global.G.service.known_topping[_dish]];
        }
        _label = guide_fit_text_px(_label, 880);
        var _p = _u.dish_prev[_i];
        var _n = _u.dish_next[_i];
        dui_button(_p.x, _p.y, _p.w, _p.h, "<",
                   dui_hover(_p.x, _p.y, _p.w, _p.h), false);
        dui_button(_n.x, _n.y, _n.w, _n.h, ">",
                   dui_hover(_n.x, _n.y, _n.w, _n.h), false);
        dui_text(_mid, _p.y + 18, _label, global.fnt_small, P_INK, fa_center);
    }

    if (_rank >= FESTIVAL_RANKS) {
        dui_text(_mid, _c.y + 620, "VENUE MASTERED!",
                 global.fnt_small, P_CORAL, fa_center);
    } else {
        var _result = festival_evaluate(festival_venue);
        var _status = festival_feedback != "" ? festival_feedback : _result.message;
        _status = guide_fit_text_px(_status, 1040);
        dui_text(_mid, _c.y + 620, _status, global.fnt_small,
                 _result.valid && festival_feedback == "" ? P_INK : P_CORAL, fa_center);
        dui_text(_mid, _c.y + 654,
                 "ENTRY " + string(festival_cost(festival_venue)) + " " + _v.label
                 + " (HAVE " + fmt_number(global.G.journal.materials[$ _v.material]) + ")",
                 global.fnt_small, P_BROWN, fa_center);
        dui_button(_u.entry.x, _u.entry.y, _u.entry.w, _u.entry.h, "ENTER",
                   dui_hover(_u.entry.x, _u.entry.y, _u.entry.w, _u.entry.h), false);
    }
    exit;
}

var _s = global.G.service;
var _hints = ["Wants something fishy", "Wants something creamy", "Wants garden greens"];
var _bases = ["FISH", "CREAM", "GREENS"];
var _toppings = ["CRUNCH", "BERRY", "HERBS"];
var _guest = service_guests()[_s.guest];

dui_button(_u.guest_prev.x, _u.guest_prev.y, _u.guest_prev.w, _u.guest_prev.h,
           "<", dui_hover(_u.guest_prev.x, _u.guest_prev.y,
                          _u.guest_prev.w, _u.guest_prev.h), false);
dui_button(_u.guest_next.x, _u.guest_next.y, _u.guest_next.w, _u.guest_next.h,
           ">", dui_hover(_u.guest_next.x, _u.guest_next.y,
                          _u.guest_next.w, _u.guest_next.h), false);
dui_text(_mid, _c.y + 132, _guest.name, global.fnt_big, P_INK, fa_center);
dui_text(_mid, _c.y + 196,
         _s.served[_s.guest] >= SERVICE_RECIPES ? "All dishes discovered!"
         : _hints[service_recipe(_s.guest).base],
         global.fnt_small, P_BROWN, fa_center);

var _slot = service_recipe_slot(_s.guest);
var _known_base = _s.known_base[_slot] >= 0 ? _bases[_s.known_base[_slot]] : "?";
var _known_topping = _s.known_topping[_slot] >= 0 ? _toppings[_s.known_topping[_slot]] : "?";
dui_text(_mid, _c.y + 228, "RECIPE: " + _known_base + " + " + _known_topping,
         global.fnt_small, P_BROWN, fa_center);

dui_text(_c.x + 48, _c.y + 280, "PICK A BASE", global.fnt_small, P_INK, fa_left);
dui_text(_c.x + 48, _c.y + 402, "PICK A TOPPING", global.fnt_small, P_INK, fa_left);
for (var _i = 0; _i < 3; _i++) {
    var _br = _u.base[_i];
    dui_pill(_br.x, _br.y, _br.w, _br.h, _bases[_i], _s.base == _i,
             dui_hover(_br.x, _br.y, _br.w, _br.h));
    var _tr = _u.topping[_i];
    dui_pill(_tr.x, _tr.y, _tr.w, _tr.h, _toppings[_i], _s.topping == _i,
             dui_hover(_tr.x, _tr.y, _tr.w, _tr.h));
}

var _message = _s.served[_s.guest] >= SERVICE_RECIPES
             ? "All dishes served! Choose a guest" : "Choose both, then serve!";
if (_s.feedback == 1) _message = "Try another base and topping";
if (_s.feedback == 2) _message = "Base right! Try another topping";
if (_s.feedback == 3) _message = "Topping right! Try another base";
if (_s.feedback == 4) _message = "Perfect! Choose your tip";
dui_text(_mid, _c.y + 536, _message, global.fnt_small, P_INK, fa_center);
dui_text(_mid, _c.y + 570,
         "DISH " + string(min(SERVICE_RECIPES, _s.served[_s.guest] + 1)) + "/3 - SERVED "
         + string(service_total()), global.fnt_small, P_BROWN, fa_center);

if (_s.feedback == 4) {
    var _t0 = _u.tip[0], _t1 = _u.tip[1];
    dui_button(_t0.x, _t0.y, _t0.w, _t0.h, "+" + fmt_number(service_tip()) + " FISH",
               dui_hover(_t0.x, _t0.y, _t0.w, _t0.h), false);
    dui_button(_t1.x, _t1.y, _t1.w, _t1.h, "+3 MATERIALS",
               dui_hover(_t1.x, _t1.y, _t1.w, _t1.h), false);
} else if (_s.served[_s.guest] < SERVICE_RECIPES) {
    dui_button(_u.serve.x, _u.serve.y, _u.serve.w, _u.serve.h, "SERVE",
               dui_hover(_u.serve.x, _u.serve.y, _u.serve.w, _u.serve.h), false);
}

var _next = -1;
for (var _i = 0; _i < SERVICE_GUESTS; _i++) {
    if (!service_guest_open(_i)) { _next = _i; break; }
}
if (_next >= 0) {
    var _next_guest = service_guests()[_next];
    dui_text(_mid, _c.y + 760,
             "NEXT: " + string(_next_guest.serves) + " SERVED + CAT "
             + string(_next_guest.album + 1), global.fnt_small, P_BROWN, fa_center);
} else {
    dui_text(_mid, _c.y + 760, "All guests have found the cafe!",
             global.fnt_small, P_BROWN, fa_center);
}
