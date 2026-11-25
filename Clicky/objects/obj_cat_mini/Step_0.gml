/// @description wander, sit, occasionally cheer

anim += 0.16;

if (state == "walk") {
    spr = spr_w;
    x += dir * speed_;

    if (x <= min_x) { dir = 1;  state = "walk"; }
    if (x >= max_x) { dir = -1; state = "walk"; }

    // cats stop for no reason, constantly
    if (random(1) < 0.004) {
        state = "sit";
        sit_t = irandom_range(60, 200);
    }
} else {
    sit_t -= 1;
    spr = (sit_t mod 90 < 20) ? spr_h : spr_i;
    if (sit_t <= 0) {
        state = "walk";
        dir = choose(-1, 1);
    }
}

image_xscale = dir;
