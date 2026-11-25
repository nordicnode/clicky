/// The shell owns only what is on screen. Every persistent number lives in
/// global.G.occult, so closing and reopening the layer loses nothing.
t = 0;
intro = 64;
mode = 0;          // 0 map, 1 parlour, 2 garden, 3 hall, 4 cellar, 5 rites, 6 relics, 7 night
loc = 0;
msg = "";
msg_t = 0;

/// The layer opens on a title card once; afterwards the map is immediate.
if (global.G.occult.closings >= 1) intro = 0;
