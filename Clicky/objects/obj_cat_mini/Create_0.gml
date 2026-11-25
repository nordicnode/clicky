/// @description a small cat that lives in the cafe
set_coat = function(_coat) {
    switch (_coat) {
        case "calico": spr_i = spr_cat_calico_idle; spr_w = spr_cat_calico_walk;
                       spr_h = spr_cat_calico_happy; break;
        case "tuxedo": spr_i = spr_cat_tuxedo_idle; spr_w = spr_cat_tuxedo_walk;
                       spr_h = spr_cat_tuxedo_happy; break;
        case "ginger": spr_i = spr_cat_ginger_idle; spr_w = spr_cat_ginger_walk;
                       spr_h = spr_cat_ginger_happy; break;
        case "grey":   spr_i = spr_cat_grey_idle;   spr_w = spr_cat_grey_walk;
                       spr_h = spr_cat_grey_happy; break;
        case "snow":   spr_i = spr_cat_snow_idle;   spr_w = spr_cat_snow_walk;
                       spr_h = spr_cat_snow_happy; break;
        case "mint":   spr_i = spr_cat_mint_idle;   spr_w = spr_cat_mint_walk;
                       spr_h = spr_cat_mint_happy; break;
        case "rose":   spr_i = spr_cat_rose_idle;   spr_w = spr_cat_rose_walk;
                       spr_h = spr_cat_rose_happy; break;
        default:       spr_i = spr_cat_tabby_idle;  spr_w = spr_cat_tabby_walk;
                       spr_h = spr_cat_tabby_happy; break;
    }
    spr = spr_w;
};

set_coat("tabby");

dir      = choose(-1, 1);
speed_   = random_range(0.30, 0.62);
anim     = random(4);
state    = "walk";
sit_t    = 0;
bob      = 0;
min_x    = 26;
max_x    = 252;
base_y   = y;

depth = 120 - y;
