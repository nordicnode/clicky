/// @description the journal / album, native 1920 GUI
dui_begin();

// The illustrated room stays pixel art at 4x; the card on top is native.
dui_pixel_scene(2, 1);
// The illustrated room is scenery behind the journal, never a second UI layer.
dui_dim(0.55);
dui_nine(spr_ui_panel, ALBUM_X, ALBUM_Y, ALBUM_W, ALBUM_H, 6);

var _have = album_unlocked_count();
var _title = (mode == 0) ? "CAT ALBUM" : "CAFE JOURNAL";
dui_text(ALBUM_X + 48, ALBUM_Y + 26, _title, global.fnt_big, P_INK, fa_left);
var _sub = (mode == 0)
    ? string(_have) + " OF " + string(album_count()) + " CATS MET"
    : "THE CAFE'S LONG STORY, ONE PAGE AT A TIME";
dui_text(ALBUM_X + 48, ALBUM_Y + 72, _sub, global.fnt_small, P_BROWN, fa_left);

// header controls, one 40px square size, aligned to the title's optical row
dui_square(album_help_rect(), "?");
dui_square(album_close_rect(), "X");

// six tabs, each exactly as wide as its word
var _tabs = album_nav_rects();
var _labs = album_nav_labels();
for (var _t = 0; _t < array_length(_tabs); _t++) {
    var _tr = _tabs[_t];
    dui_pill(_tr.left, _tr.y, _tr.width, _tr.h, _labs[_t], mode == _tr.index,
             dui_hover(_tr.left, _tr.y, _tr.width, _tr.h));
}
draw_set_colour(P_WOOD);
draw_rectangle(ALBUM_X + 48, ALBUM_Y + 196, ALBUM_X + ALBUM_W - 48, ALBUM_Y + 198, false);

if (mode == 0) {
    // ---- CATS: 4x3 cards, same box, same baseline, every page
    var _pages = ceil(album_count() / per_page);
    var _hover = -1;
    var _coat = [spr_cat_tabby_idle, spr_cat_calico_idle,
                 spr_cat_tuxedo_idle, spr_cat_ginger_idle,
                 spr_cat_grey_idle, spr_cat_snow_idle,
                 spr_cat_mint_idle, spr_cat_rose_idle];

    for (var k = 0; k < per_page; k++) {
        var _i = page * per_page + k;
        if (_i >= album_count()) break;
        var _r = album_cat_rect(k);
        var _open = album_unlocked(_i);
        var _hot = dui_hover(_r.x, _r.y, _r.w, _r.h);
        if (_hot) _hover = _i;

        dui_nine(spr_ui_row, _r.x, _r.y, _r.w, _r.h, 4);
        if (_hot) {
            draw_set_alpha(0.14);
            draw_set_colour(P_GOLD);
            draw_roundrect_ext(_r.x + 2, _r.y + 2, _r.x + _r.w - 2,
                               _r.y + _r.h - 2, 6, 6, false);
            draw_set_alpha(1);
        }

        // The story label is the only addition to the card. It sits in the
        // card's left margin so the portrait keeps its full centre column.
        if (_open) {
            dui_text(_r.x + _r.w - 10, _r.y + 8, arc_album_label(_i),
                     global.fnt_small, arc_done(_i) ? P_GOLD : P_CORAL, fa_right);
        }

        var _spr = _coat[album_coat(_i)];
        var _pw = sprite_get_width(_spr) * 3.0;
        var _ph = sprite_get_height(_spr) * 3.0;
        var _px = _r.x + (_r.w - _pw) * 0.5;
        var _py = _r.y + 22;
        if (_open) {
            draw_sprite_stretched(_spr, 0, _px, _py, _pw, _ph);
            if (room_companion() == _i) {
                draw_set_alpha(0.16);
                draw_set_colour(P_GOLD);
                draw_roundrect_ext(_r.x + 2, _r.y + 2, _r.x + _r.w - 2,
                                   _r.y + _r.h - 2, 6, 6, false);
                draw_set_alpha(1);
                // The tint alone is too quiet to read as a selection. Say it.
                dui_text(_r.x + 12, _r.y + 4, "WITH YOU",
                         global.fnt_small, P_GOLD, fa_left);
            }
            dui_text(_r.x + _r.w * 0.5, _r.y + 124, global.CAT[_i].n,
                     global.fnt_small, P_INK, fa_center);
            dui_text(_r.x + _r.w * 0.5, _r.y + 144,
                     staff_trait_name(_i) + " - " + cat_home_name(_i),
                     global.fnt_small, P_CORAL, fa_center);
            var _br = cat_bond_rank(_i);
            dui_text(_r.x + _r.w * 0.5, _r.y + 164,
                     _br >= CAT_BOND_MAX
                     ? "BOND MASTERED"
                     : "BOND " + string(_br) + "/" + string(CAT_BOND_MAX),
                     global.fnt_small, _br > 0 ? P_GOLD : P_BROWN, fa_center);
            draw_set_colour(P_WOOD);
            draw_rectangle(_r.x + 16, _r.y + 184, _r.x + _r.w - 16, _r.y + 188, false);
            var _bp = cat_bond_progress(_i);
            if (_bp > 0) {
                draw_set_colour(P_GOLD);
                draw_rectangle(_r.x + 16, _r.y + 184,
                               _r.x + 16 + (_r.w - 32) * _bp, _r.y + 188, false);
            }
        } else {
            draw_set_alpha(0.25);
            draw_sprite_stretched(_spr, 0, _px, _py, _pw, _ph);
            draw_set_alpha(1);
            dui_text(_r.x + _r.w * 0.5, _r.y + 132, "???",
                     global.fnt_small, P_BROWN, fa_center);
            dui_text(_r.x + _r.w * 0.5, _r.y + 158,
                     "AT " + fmt_number(global.CAT[_i].at) + " FISH",
                     global.fnt_small, P_WOOD, fa_center);
            draw_sprite_ext(spr_ui_lock, 0, _r.x + _r.w - 44, _r.y + 12,
                            2, 2, 0, c_white, 1);
        }
    }

    // page arrows live on the card's bottom baseline
    if (_pages > 1) {
        var _pg = album_cat_page_rects();
        dui_button(_pg.left.x, _pg.left.y, _pg.left.w, _pg.left.h, "<",
                   dui_hover(_pg.left.x, _pg.left.y, _pg.left.w, _pg.left.h), false);
        dui_button(_pg.right.x, _pg.right.y, _pg.right.w, _pg.right.h, ">",
                   dui_hover(_pg.right.x, _pg.right.y, _pg.right.w, _pg.right.h), false);
        dui_text(ALBUM_X + ALBUM_W * 0.5, ALBUM_Y + 920,
                 "PAGE " + string(page + 1) + " / " + string(_pages),
                 global.fnt_small, P_BROWN, fa_center);
    }

    var _line = "Click a cat to choose it.";
    if (_hover >= 0) {
        if (album_unlocked(_hover)) {
            _line = global.CAT[_hover].n + ": BOND "
                  + string(cat_bond_rank(_hover)) + "/" + string(CAT_BOND_MAX)
                  + " - NEXT " + cat_next_trick(_hover);
        } else {
            _line = "Found at " + fmt_number(global.CAT[_hover].at) + " fish.";
        }
        // The page count owns the card's centre; never let a long quirk run
        // through it. The bond number is already on the card itself.
        _line = guide_fit_text_px(_line, 340);
    }
    dui_text(ALBUM_X + 176, ALBUM_Y + 920, _line, global.fnt_small, P_BROWN, fa_left);
    exit;
}

if (mode < 3) {
    var _ch = album_chapter_rects();
    dui_button(_ch.left.x, _ch.left.y, _ch.left.w, _ch.left.h, "<",
               chapter > 0 && dui_hover(_ch.left.x, _ch.left.y, _ch.left.w, _ch.left.h), false);
    dui_button(_ch.right.x, _ch.right.y, _ch.right.w, _ch.right.h, ">",
               chapter + 1 < JOURNAL_CHAPTERS && journal_unlocked(chapter + 1)
               && dui_hover(_ch.right.x, _ch.right.y, _ch.right.w, _ch.right.h), false);
    dui_text(ALBUM_X + ALBUM_W * 0.5, ALBUM_Y + 250,
             journal_chapters()[chapter], global.fnt_small, P_INK, fa_center);
}

if (mode == 1) {
    // ---- GOALS: four rows, one progress bar each, claim by clicking the row
    for (var _gi = 0; _gi < 4; _gi++) {
        var _goal = journal_goal(chapter, _gi);
        var _value = journal_value(_goal.kind);
        var _done = global.G.journal.claims[chapter * 4 + _gi];
        var _r = journal_goal_rect(_gi);
        var _ready = _value >= _goal.target;

        dui_nine(spr_ui_row, _r.x, _r.y, _r.w, _r.h, 4);
        if (_ready && !_done) {
            draw_set_alpha(0.14 + 0.06 * sin(t * 0.12));
            draw_set_colour(P_GOLD);
            draw_roundrect_ext(_r.x + 2, _r.y + 2, _r.x + _r.w - 2, _r.y + _r.h - 2, 6, 6, false);
            draw_set_alpha(1);
        }
        dui_text(_r.x + 28, _r.y + 18, _goal.label, global.fnt_small, P_INK, fa_left);
        dui_text(_r.x + 28, _r.y + 48,
                 fmt_number(min(_value, _goal.target)) + " / " + fmt_number(_goal.target),
                 global.fnt_small, P_BROWN, fa_left);
        var _status = _done ? "DONE" : (_ready ? "CLAIM +1" : "+1 STAMP");
        dui_text(_r.x + _r.w - 28, _r.y + 18, _status, global.fnt_small,
                 (!_done && _ready) ? P_CORAL : P_BROWN, fa_right);

        var _p = clamp(_value / max(1, _goal.target), 0, 1);
        draw_set_colour(P_WOOD);
        draw_rectangle(_r.x + 28, _r.y + 100, _r.x + _r.w - 28, _r.y + 108, false);
        draw_set_colour(_done ? P_MINT : P_GOLD);
        draw_rectangle(_r.x + 28, _r.y + 100,
                       _r.x + 28 + (_r.w - 56) * _p, _r.y + 108, false);
    }
    dui_text(ALBUM_X + ALBUM_W * 0.5, ALBUM_Y + 930,
             chapter == JOURNAL_CHAPTERS - 1 ? "Keep building your cafe!"
             : "Claim 3 goals to reveal the next chapter",
             global.fnt_small, P_BROWN, fa_center);
} else if (mode == 2) {
    // ---- BUILD: three projects with their cost, material and effect
    var _effects = ["+5% production", "+5% taps", "+5% away rate"];
    for (var _pi = 0; _pi < 3; _pi++) {
        var _pr = journal_project_rect(_pi);
        var _built = global.G.journal.projects[chapter * 3 + _pi];
        var _mat = journal_material_key(_pi);
        var _need = 3 + chapter;
        var _cost = journal_project_cost(chapter);
        var _can = !_built && global.G.fish >= _cost
                   && global.G.journal.materials[$ _mat] >= _need;

        dui_nine(spr_ui_row, _pr.x, _pr.y, _pr.w, _pr.h, 4);
        if (_can) {
            draw_set_alpha(0.12);
            draw_set_colour(P_GOLD);
            draw_roundrect_ext(_pr.x + 2, _pr.y + 2, _pr.x + _pr.w - 2, _pr.y + _pr.h - 2, 6, 6, false);
            draw_set_alpha(1);
        }
        dui_text(_pr.x + 28, _pr.y + 20, journal_project_name(chapter, _pi),
                 global.fnt_big, P_INK, fa_left);
        dui_text(_pr.x + 28, _pr.y + 60, _effects[_pi], global.fnt_small, P_CORAL, fa_left);
        dui_text(_pr.x + 28, _pr.y + 104,
                 string(global.G.journal.materials[$ _mat]) + " / " + string(_need)
                 + " " + journal_material_label(_pi), global.fnt_small, P_BROWN, fa_left);
        dui_text(_pr.x + _pr.w - 28, _pr.y + 20,
                 _built ? "BUILT" : fmt_number(_cost) + " FISH",
                 global.fnt_small, (_built || _can) ? P_CORAL : P_BROWN, fa_right);
        dui_text(_pr.x + _pr.w - 28, _pr.y + 60,
                 _built ? "COMPLETE" : (_can ? "CLICK TO BUILD" : "NOT ENOUGH YET"),
                 global.fnt_small, _can ? P_GOLD : P_WOOD, fa_right);
    }
    dui_text(ALBUM_X + ALBUM_W * 0.5, ALBUM_Y + 930,
             "BUY = SCRAP   PET = TREAT   SPARKLE = DUST",
             global.fnt_small, P_BROWN, fa_center);
} else if (mode == 3) {
    // ---- ORDERS + SKILLS
    var _names = ["PET ORDER", "BUILD ORDER", "FISH ORDER"];
    var _skill_names = ["CAFE", "PLAY", "REST"];
    dui_text(ALBUM_X + 48, ALBUM_Y + 220, "ORDER REWARD: 1 STAMP + MATERIAL",
             global.fnt_small, P_BROWN, fa_left);

    for (var _oi = 0; _oi < 3; _oi++) {
        var _or = journal_order_rect(_oi);
        var _active = global.G.journal.order_active[_oi];
        var _target = journal_order_target(_oi, _active ? global.G.journal.order_chapter[_oi] : chapter);
        var _progress = _active ? journal_order_progress(_oi) : 0;
        var _ready = _active && _progress >= _target;

        dui_nine(spr_ui_row, _or.x, _or.y, _or.w, _or.h, 4);
        dui_text(_or.x + 24, _or.y + 18, _names[_oi], global.fnt_small, P_INK, fa_left);
        var _status = _active
            ? fmt_number(min(_progress, _target)) + " / " + fmt_number(_target)
            : "START " + fmt_number(_target);
        if (_ready) _status = "CLAIM +1";
        dui_text(_or.x + _or.w - 24, _or.y + 18, _status, global.fnt_small,
                 _active ? P_CORAL : P_BROWN, fa_right);
        var _op = _active ? clamp(_progress / max(1, _target), 0, 1) : 0;
        draw_set_colour(P_WOOD);
        draw_rectangle(_or.x + 24, _or.y + 58, _or.x + _or.w - 24, _or.y + 66, false);
        if (_op > 0) {
            draw_set_colour(P_GOLD);
            draw_rectangle(_or.x + 24, _or.y + 58,
                           _or.x + 24 + (_or.w - 48) * _op, _or.y + 66, false);
        }
    }

    dui_text(ALBUM_X + 48, ALBUM_Y + 610,
             "STAMPS " + fmt_number(global.G.journal.stamps) + "  -  CHOOSE A BOOST",
             global.fnt_small, P_INK, fa_left);
    for (var _si = 0; _si < 3; _si++) {
        var _sk = journal_skill_rect(_si);
        var _level = global.G.journal.skills[_si];
        dui_nine(spr_ui_row, _sk.x, _sk.y, _sk.w, _sk.h, 4);
        dui_text(_sk.x + 24, _sk.y + 16,
                 _skill_names[_si] + "  +" + string(_level * 10) + "%",
                 global.fnt_small, P_INK, fa_left);
        var _sc = journal_skill_cost(_si);
        dui_text(_sk.x + _sk.w - 24, _sk.y + 16,
                 _level >= 10 ? "MAX" : string(_sc) + (_sc == 1 ? " STAMP" : " STAMPS"),
                 global.fnt_small, P_BROWN, fa_right);
    }
} else if (mode == 4) {
    // ---- STAFF: four stations, three aligned slots
    dui_text(ALBUM_X + 48, ALBUM_Y + 218,
             "A CAT IN ITS MATCHING STATION EARNS DOUBLE",
             global.fnt_small, P_BROWN, fa_left);
    var _srects = staff_station_rects();
    for (var _st = 0; _st < array_length(_srects); _st++) {
        var _sr = _srects[_st];
        dui_pill(_sr.left, _sr.y, _sr.width, _sr.h, staff_station_name(_sr.index),
                 staff_station == _sr.index,
                 dui_hover(_sr.left, _sr.y, _sr.width, _sr.h));
    }

    for (var _sl2 = 0; _sl2 < STAFF_PER_STATION; _sl2++) {
        var _row = staff_slot_rect(_sl2);
        dui_nine(spr_ui_row, _row.x, _row.y, _row.w, _row.h, 4);
        var _cat = global.G.staff.slots[staff_station * STAFF_PER_STATION + _sl2];
        dui_text(_row.x + 24, _row.y + 12, "SLOT " + string(_sl2 + 1),
                 global.fnt_small, P_BROWN, fa_left);
        if (!staff_slot_open(_sl2)) {
            dui_text(_row.x + 24, _row.y + 44,
                     "MEET " + string(staff_slot_open_need(_sl2)) + " CATS TO OPEN",
                     global.fnt_small, P_WOOD, fa_left);
            continue;
        }
        var _label = "EMPTY";
        var _col = P_BROWN;
        if (_cat >= 0) {
            _label = string_upper(global.CAT[_cat].n) + "  -  " + staff_trait_name(_cat);
            _col = staff_trait_station(_cat) == staff_station ? P_CORAL : P_INK;
        }
        dui_text(_row.x + 24, _row.y + 44, _label, global.fnt_small, _col, fa_left);
        var _sa = staff_arrow_rects(_row);
        dui_button(_sa.left.x, _sa.left.y, _sa.left.w, _sa.left.h, "<",
                   dui_hover(_sa.left.x, _sa.left.y, _sa.left.w, _sa.left.h), false);
        dui_button(_sa.right.x, _sa.right.y, _sa.right.w, _sa.right.h, ">",
                   dui_hover(_sa.right.x, _sa.right.y, _sa.right.w, _sa.right.h), false);
    }

    dui_text(ALBUM_X + 48, ALBUM_Y + 790,
             staff_station_name(staff_station) + "  +"
             + string(floor(staff_bonus(staff_station) * 100)) + "%  "
             + staff_station_effect(staff_station),
             global.fnt_small, P_INK, fa_left);
    var _staffed = 0;
    for (var _sc2 = 0; _sc2 < array_length(global.G.staff.slots); _sc2++) {
        if (global.G.staff.slots[_sc2] >= 0) _staffed += 1;
    }
    dui_text(ALBUM_X + ALBUM_W - 48, ALBUM_Y + 790,
             "STAFFED " + string(_staffed) + " / "
             + string(STAFF_STATIONS * STAFF_PER_STATION),
             global.fnt_small, P_BROWN, fa_right);
    dui_text(ALBUM_X + ALBUM_W * 0.5, ALBUM_Y + 838,
             "ONE CAT, ONE STATION. MATCHING A CAT'S QUIRK DOUBLES ITS BONUS.",
             global.fnt_small, P_WOOD, fa_center);
} else {
    // ---- ERAS: the post-MOON chapter. Three deeds, one House Rule, one seal.
    var _el = era_list();
    if (era_all_sealed()) {
        dui_text(ALBUM_X + ALBUM_W * 0.5, ALBUM_Y + 300, "ALL SIX ERAS SEALED",
                 global.fnt_big, P_INK, fa_center);
        dui_text(ALBUM_X + ALBUM_W * 0.5, ALBUM_Y + 360,
                 "LEGACY: " + era_perk_name(ERA_COUNT - 1),
                 global.fnt_small, P_GOLD, fa_center);
        dui_text(ALBUM_X + ALBUM_W * 0.5, ALBUM_Y + 400,
                 "The cafe keeps every room and every perk.",
                 global.fnt_small, P_BROWN, fa_center);
        exit;
    }

    var _era = _el[era_cur()];
    dui_text(ALBUM_X + ALBUM_W * 0.5, ALBUM_Y + 224, _era.name,
             global.fnt_big, P_INK, fa_center);
    dui_text(ALBUM_X + ALBUM_W * 0.5, ALBUM_Y + 268,
             zone_name(_era.room) + "   -   TAPS x2   -   RENOWN "
             + string(global.G.eras.renown), global.fnt_small, P_GOLD, fa_center);

    for (var _di = 0; _di < 3; _di++) {
        var _deed = _era.deeds[_di];
        var _val = era_deed_value(era_cur(), _di);
        var _dr = era_deed_rect(_di);
        var _done = _val >= _deed.target;
        dui_nine(spr_ui_row, _dr.x, _dr.y, _dr.w, _dr.h, 4);
        dui_text(_dr.x + 24, _dr.y + 12, _deed.label, global.fnt_small, P_INK, fa_left);
        dui_text(_dr.x + _dr.w - 24, _dr.y + 12,
                 fmt_number(min(_val, _deed.target)) + " / " + fmt_number(_deed.target),
                 global.fnt_small, _done ? P_GOLD : P_BROWN, fa_right);
        var _p = clamp(_val / max(1, _deed.target), 0, 1);
        draw_set_colour(P_WOOD);
        draw_rectangle(_dr.x + 24, _dr.y + 54, _dr.x + _dr.w - 24, _dr.y + 62, false);
        if (_p > 0) {
            draw_set_colour(_done ? P_GOLD : P_CORAL);
            draw_rectangle(_dr.x + 24, _dr.y + 54,
                           _dr.x + 24 + (_dr.w - 48) * _p, _dr.y + 62, false);
        }
    }

    var _rule = global.G.eras.rule;
    // The rule cards begin at +594, so the +616 heading was painted underneath
    // the first card. Sit it in the gap above them instead.
    dui_text(ALBUM_X + 48, ALBUM_Y + 570,
             "HOUSE RULE: " + (_rule < 0 ? "PICK ONE FOR THIS ERA" : era_rules()[_rule].name),
             global.fnt_small, P_INK, fa_left);

    if (_rule < 0) {
        var _rules = era_rules();
        for (var _ri = 0; _ri < ERA_RULE_COUNT; _ri++) {
            var _rr = era_rule_rect(_ri);
            dui_nine(spr_ui_row, _rr.x, _rr.y, _rr.w, _rr.h, 4);
            if (dui_hover(_rr.x, _rr.y, _rr.w, _rr.h)) {
                draw_set_alpha(0.14);
                draw_set_colour(P_GOLD);
                draw_roundrect_ext(_rr.x + 2, _rr.y + 2, _rr.x + _rr.w - 2,
                                   _rr.y + _rr.h - 2, 6, 6, false);
                draw_set_alpha(1);
            }
            dui_text(_rr.x + 24, _rr.y + 10, _rules[_ri].name,
                     global.fnt_small, P_INK, fa_left);
            dui_text(_rr.x + 24, _rr.y + 38, _rules[_ri].blurb,
                     global.fnt_small, P_BROWN, fa_left);
        }
    } else {
        var _pick = era_rules()[_rule];
        var _cr = era_change_rect();
        dui_button(_cr.x, _cr.y, _cr.w, _cr.h, "CHANGE",
                   dui_hover(_cr.x, _cr.y, _cr.w, _cr.h), false);
        var _rr2 = era_rule_rect(0);
        dui_nine(spr_ui_row, _rr2.x, _rr2.y, _rr2.w, _rr2.h, 4);
        dui_text(_rr2.x + 24, _rr2.y + 14, _pick.blurb, global.fnt_small, P_BROWN, fa_left);
        dui_text(_rr2.x + 24, _rr2.y + 44,
                 string(era_deeds_done(era_cur())) + " / 3 DEEDS DONE",
                 global.fnt_small, era_ready() ? P_GOLD : P_BROWN, fa_left);
    }

    var _seal = era_seal_rect();
    if (era_ready()) {
        dui_button(_seal.x, _seal.y, _seal.w, _seal.h, "SEAL ERA",
                   dui_hover(_seal.x, _seal.y, _seal.w, _seal.h), false);
    } else {
        draw_set_alpha(0.45);
        dui_button(_seal.x, _seal.y, _seal.w, _seal.h, "FINISH ALL THREE DEEDS", false, false);
        draw_set_alpha(1);
    }
}
