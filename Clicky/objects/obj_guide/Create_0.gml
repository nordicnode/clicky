/// One lesson card at a time, plus the always-on goal strip. Both read live
/// game state every frame; nothing here is authored per room.
shown = -1;         // -1 = no card, otherwise the card is open
def_id = "";        // guide_lessons() id currently on screen
page = 0;           // index into the lesson's pages array
t = 0;
cooldown = 30;      // let boot, the welcome card and the tutorial settle first
snooze_id = "";     // LATER postpones this lesson, it does not forget it
snooze_t = 0;
strip_grace = 0;    // a freshly collapsed strip ignores its ? for 14 steps
