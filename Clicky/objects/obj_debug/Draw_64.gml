/// @description diagnostics (demo builds only)
if (demo != "" && global.show_diag) {
    dui_begin();
    dui_text(8, 40, "FPS " + string(fps_real) + " RATE " + fmt_rate(econ_rate()),
             global.fnt_small, P_INK, fa_left);
}
