/// @description journal tabs, rows and close, native 1920
t += 1;

if (closing >= 0) {
    if (t - closing > 10) instance_destroy();
    exit;
}

var _close = album_close_rect();
if (dui_clicked(_close.x, _close.y, _close.w, _close.h)
    || keyboard_check_pressed(vk_escape)) {
    closing = t;
    exit;
}

// the story card sits above the journal; this card waits while it is open
if (instance_exists(obj_cat_arc)) exit;

// the manual sits above the journal; this card waits while it is open
if (instance_exists(obj_settings)) exit;

var _help = album_help_rect();
if (dui_clicked(_help.x, _help.y, _help.w, _help.h)) {
    var _set = ui_card_spawn(obj_settings);
    _set.guide = 1;
    _set.guide_page = (mode == 4) ? 7 : (mode == 5 ? 39 : 6);
    sfx(snd_pop2, 1);
    exit;
}

// Tabs are always present now: CATS is a tab, not a separate album screen.
var _tabs = album_nav_rects();
for (var _t = 0; _t < array_length(_tabs); _t++) {
    var _tr = _tabs[_t];
    if (dui_clicked(_tr.left, _tr.y, _tr.width, _tr.h) && mode != _tr.index) {
        mode = _tr.index;
        sfx(snd_pop1, 1.05);
        exit;
    }
}

if (mode == 1 || mode == 2) {
    var _ch = album_chapter_rects();
    if (dui_clicked(_ch.left.x, _ch.left.y, _ch.left.w, _ch.left.h)
        && chapter > 0) {
        chapter -= 1;
        sfx(snd_pop1, 1.2);
        exit;
    }
    if (dui_clicked(_ch.right.x, _ch.right.y, _ch.right.w, _ch.right.h)
        && chapter + 1 < JOURNAL_CHAPTERS && journal_unlocked(chapter + 1)) {
        chapter += 1;
        sfx(snd_pop1, 1.2);
        exit;
    }
}

if (mode == 0) {
    // A card is also the companion picker: the choice is saved immediately so
    // the ROOMS panel and the big cat agree on the active bond.
    var _pages = ceil(album_count() / per_page);
    for (var _ci = 0; _ci < per_page; _ci++) {
        var _cat_i = page * per_page + _ci;
        if (_cat_i >= album_count()) break;
        var _cr = album_cat_rect(_ci);
        // The story corner is a small, deliberate target. It is checked before
        // the card body so opening a story never changes the companion.
        var _sr = arc_album_rect(_cr);
        if (album_unlocked(_cat_i) && dui_clicked(_sr.x, _sr.y, _sr.w, _sr.h)) {
            var _card = ui_card_spawn(obj_cat_arc);
            _card.cat = _cat_i;
            sfx(snd_pop2, 1.05);
            exit;
        }
        if (dui_clicked(_cr.x, _cr.y, _cr.w, _cr.h)
            && room_companion_set(_cat_i)) {
            sfx(snd_pop2, 1.1);
            exit;
        }
    }
    var _pg = album_cat_page_rects();
    if (dui_clicked(_pg.left.x, _pg.left.y, _pg.left.w, _pg.left.h)) {
        page = (page - 1 + _pages) mod _pages;
        sfx(snd_pop1, 1);
        exit;
    }
    if (dui_clicked(_pg.right.x, _pg.right.y, _pg.right.w, _pg.right.h)) {
        page = (page + 1) mod _pages;
        sfx(snd_pop1, 1);
        exit;
    }
} else if (mode == 1) {
    for (var _i = 0; _i < 4; _i++) {
        var _r = journal_goal_rect(_i);
        if (dui_clicked(_r.x, _r.y, _r.w, _r.h) && journal_claim(chapter, _i)) {
            sfx_milestone();
        }
    }
} else if (mode == 2) {
    for (var _p = 0; _p < 3; _p++) {
        var _pr = journal_project_rect(_p);
        if (dui_clicked(_pr.x, _pr.y, _pr.w, _pr.h) && journal_project_buy(chapter, _p)) {
            sfx_buy();
        }
    }
} else if (mode == 3) {
    for (var _o = 0; _o < 3; _o++) {
        var _or = journal_order_rect(_o);
        if (dui_clicked(_or.x, _or.y, _or.w, _or.h)) {
            if (global.G.journal.order_active[_o]) {
                if (journal_order_claim(_o)) sfx_milestone();
            } else if (journal_order_start(_o, chapter)) sfx(snd_pop2, 1);
        }
    }
    for (var _s = 0; _s < 3; _s++) {
        var _sk = journal_skill_rect(_s);
        if (dui_clicked(_sk.x, _sk.y, _sk.w, _sk.h) && journal_skill_buy(_s)) sfx_buy();
    }
} else if (mode == 4) {
    var _srects = staff_station_rects();
    for (var _st = 0; _st < array_length(_srects); _st++) {
        var _sr = _srects[_st];
        if (dui_clicked(_sr.left, _sr.y, _sr.width, _sr.h) && staff_station != _sr.index) {
            staff_station = _sr.index;
            sfx(snd_pop1, 1.2);
            exit;
        }
    }
    for (var _sl = 0; _sl < STAFF_PER_STATION; _sl++) {
        if (!staff_slot_open(_sl)) continue;
        var _row = staff_slot_rect(_sl);
        var _sa = staff_arrow_rects(_row);
        if (dui_clicked(_sa.left.x, _sa.left.y, _sa.left.w, _sa.left.h)
            && staff_cycle(staff_station, _sl, -1)) sfx(snd_pop2, 1);
        if (dui_clicked(_sa.right.x, _sa.right.y, _sa.right.w, _sa.right.h)
            && staff_cycle(staff_station, _sl, 1)) sfx(snd_pop2, 1);
    }
} else if (mode == 5) {
    // ERAS: choose a House Rule, then seal once all three deeds are done.
    if (!era_all_sealed()) {
        if (global.G.eras.rule < 0) {
            for (var _r2 = 0; _r2 < ERA_RULE_COUNT; _r2++) {
                var _rr = era_rule_rect(_r2);
                if (dui_clicked(_rr.x, _rr.y, _rr.w, _rr.h) && era_choose_rule(_r2)) {
                    sfx(snd_pop1, 1.1);
                    exit;
                }
            }
        } else {
            var _cr = era_change_rect();
            if (dui_clicked(_cr.x, _cr.y, _cr.w, _cr.h)) {
                global.G.eras.rule = -1;
                save_write();
                sfx(snd_pop2, 1);
                exit;
            }
            var _seal = era_seal_rect();
            if (dui_clicked(_seal.x, _seal.y, _seal.w, _seal.h) && era_ready()) {
                var _sealed_before = global.G.eras.sealed;
                if (era_seal()) {
                    sfx_milestone();
                    juice_floater(150, 150, "ERA SEALED  " + era_perk_name(_sealed_before),
                                  P_GOLD, true);
                }
            }
        }
    }
}
