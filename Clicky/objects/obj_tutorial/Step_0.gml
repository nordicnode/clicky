/// @description advance on what the player actually did, never on a timer
if (done) { instance_destroy(); exit; }
if (ui_modal_open()) exit;

t += 1;
pulse += 0.08;

var _clicks = global.G.stats.clicks;
var _owned  = 0;
for (var i = 0; i < 8; i++) _owned += global.G.tiers[i];
if (_owned > 0 && buy_t < 0) buy_t = t;

if (_clicks < 3)       step = 0;   // TAP THE CAT
else if (_clicks < 8)  step = 1;   // KEEP TAPPING
else if (_owned == 0)  step = 2;   // BUY A BOX
else                   step = 3;   // NEW CAT!

// the last step is a celebration, not an instruction
if (step == 3 && buy_t >= 0 && t - buy_t > 210) done = true;

// never guide a returning player: they already know
if (_clicks > 40 && _owned == 0) done = true;
