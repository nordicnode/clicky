/// @description juice: floating numbers, particle bursts, screen shake

function juice_floater(_x, _y, _txt, _col, _big) {
    // stagger spawns so rapid taps never stack into an illegible smudge
    if (!variable_global_exists("fcount")) global.fcount = 0;
    global.fcount += 1;
    var _slot = global.fcount mod 8;
    var _ang = -90 + (_slot - 3.5) * 17;
    var _rad = 22 + (_slot mod 2) * 7;
    _x += lengthdir_x(_rad, _ang);
    _y += lengthdir_y(_rad, _ang);

    // never let the screen fill with numbers
    if (!variable_global_exists("floaters")) global.floaters = [];
    while (array_length(global.floaters) >= 6) {
        var _old = array_shift(global.floaters);
        if (instance_exists(_old)) instance_destroy(_old);
    }

    var _i = instance_create_depth(_x, _y, -80, obj_floater);
    array_push(global.floaters, _i);
    _i.txt   = _txt;
    _i.col   = _col;
    _i.vy    = -0.55 - random(0.25);
    _i.vx    = random_range(-0.22, 0.22);
    _i.life  = 40 + irandom(10);
    _i.big   = _big;
    return _i;
}

function juice_pop(_x, _y, _n, _spr) {
    repeat (_n) {
        var _p = instance_create_depth(_x, _y, -70, obj_pop);
        _p.spr = _spr;
        var _a = random(360);
        var _s = random_range(0.5, 1.6);
        _p.hsp = lengthdir_x(_s, _a);
        _p.vsp = lengthdir_y(_s, _a) - 0.6;
        _p.life = 18 + irandom(12);
        _p.total = _p.life;
    }
}

function juice_shake(_amt) {
    if (global.G.settings.reduce_motion) return;
    global.shake = max(global.shake, _amt);
}

function juice_shake_update() {
    if (global.shake > 0) global.shake = max(0, global.shake - 0.35);
}
