/// @description debug: cheats + scripted screenshot run
demo = "";
try { demo = environment_get_variable("CLICKY_DEMO"); } catch (_e) { demo = ""; }
demo_t = 0;

// the Hollow's isolated verification run; inert without the env var
veil_test = "";
try { veil_test = environment_get_variable("CLICKY_VEILTEST"); } catch (_e) { veil_test = ""; }

// the cafe-side isolated run (staff, guide, rooms, entrance)
cafe_test = "";
try { cafe_test = environment_get_variable("CLICKY_CAFETEST"); } catch (_e) { cafe_test = ""; }

global.show_diag = false;

// soak-test bookkeeping: game seconds of "play", and the next action times
soak_t     = 0;
soak_tap   = 0;
soak_buy   = 0;
soak_log   = 0;
soak_end   = 1800;
try { soak_end = real(environment_get_variable("CLICKY_SOAK_END")); } catch (_e) { soak_end = 1800; }
soak_s     = { prestiges: 0, yarn: 0 };
spint      = -1;   // prestige spin test log handle
