/// @description authored cat stories: twenty-four arcs, five beats each.
///
/// This file is content only. It does not own save state or draw anything.
/// Every step asks for an action that already exists in the cafe, the journal,
/// a room, the counter, a festival or the Hollow. The middle beat is always a
/// two-way choice, and the chosen branch supplies the next beat's goal and the
/// final keepsake effect.

function arc_make_goal(_kind, _n) {
    return { k: _kind, n: _n };
}

function arc_step(_title, _text, _goal) {
    return { title: _title, text: _text, goal: _goal };
}

/// One branch is a different next goal, a different closing line and a
/// different keepsake effect. Both branches finish the same arc.
function arc_make_choice(_prompt, _a_label, _a_text, _a_echo, _a_goal,
                    _b_label, _b_text, _b_echo, _b_goal) {
    return {
        prompt: _prompt,
        a: { label: _a_label, text: _a_text, echo: _a_echo, goal: _a_goal },
        b: { label: _b_label, text: _b_text, echo: _b_echo, goal: _b_goal }
    };
}

function arc_make_perk(_kind, _n, _material, _zone, _text) {
    return { k: _kind, n: _n, m: _material, zone: _zone, text: _text };
}

function arc_reward(_name, _text, _a, _b) {
    return { name: _name, text: _text, a: _a, b: _b };
}

function arc_content() {
    static _d = [
        {
            title: "THE DRIPPING SINK",
            hook: "MOCHI HAS OUTVOTED THE PLUMBING.",
            steps: [
                arc_step("THE DRIP", "MOCHI HAS DECIDED THE SINK IS A BED. THE TAP IS DRIPPING INTO HER EAR.", arc_make_goal("taps", 12)),
                arc_step("A DRY TOWEL", "SHE WILL NOT MOVE FOR A DRY TOWEL. SHE WANTS THE WARM ROW BY THE WINDOW INSTEAD.", arc_make_goal("buys", 1)),
                { title: "THE PLUMBER", text: "THE PLUMBER CAN FIX THE DRIP, OR YOU CAN LEAVE IT RUNNING. MOCHI IS LISTENING.", choice: arc_make_choice(
                    "THE PLUMBER IS WAITING. MOCHI IS NOT.",
                    "LEAVE IT DRIPPING", "A METRONOME IS A KIND OF LULLABY.", "THE TAP KEPT TIME.",
                    arc_make_goal("sparkles", 1),
                    "FIX THE DRIP", "SILENCE, THEN A SOFT PRESSURE ON YOUR ANKLE.", "THE SINK WENT QUIET.",
                    arc_make_goal("buys", 2)) },
                arc_step("A SMALL RITUAL", "SHE KNEADS THE SINK ONCE, THEN LEADS YOU TO THE CUPBOARD.", undefined),
                arc_step("THE SINK STONE", "SHE HAS FOUND SOMETHING AT THE BOTTOM OF THE DRAIN. IT IS STILL WARM.", arc_make_goal("taps", 20))
            ],
            reward: arc_reward("THE SINK STONE", "A SMOOTH STONE FROM THE DRAIN. IT NEVER GETS COLD.",
                arc_make_perk("tap_treat", 12, 0, 0, "EVERY 12TH TAP IN THE COZY CORNER LEAVES A TREAT."),
                arc_make_perk("spark_treat", 1, 0, -1, "EVERY GOLD SPARKLE LEAVES AN EXTRA TREAT."))
        },
        {
            title: "THE WARM KEYBOARD",
            hook: "BISCUIT HAS CLAIMED THE WARMEST MACHINE.",
            steps: [
                arc_step("WARM PLASTIC", "BISCUIT IS ASLEEP ON THE LAPTOP. THE FAN IS DOING MOST OF THE WORK.", arc_make_goal("taps", 15)),
                arc_step("CRUMB TRAIL", "THERE IS A TRAIL OF CRUMBS FROM THE COUNTER TO THE KEYBOARD. BISCUIT LOOKS PROUD.", arc_make_goal("sparkles", 1)),
                { title: "THE LID", text: "THE SCREEN IS GETTING HOT. BISCUIT HAS NOT NOTICED. THE ROOM HAS.", choice: arc_make_choice(
                    "OPEN OR CLOSED. BISCUIT WILL REMEMBER.",
                    "SHARE THE WARMTH", "YOU LEAVE THE LID OPEN. THE KEYS CLICK UNDER HER.", "YOU LEFT THE LID OPEN.",
                    arc_make_goal("buys", 2),
                    "CLOSE THE LID", "THE ROOM GETS COOLER. BISCUIT MOVES TO YOUR KNEE.", "THE ROOM GOT COOLER.",
                    arc_make_goal("taps", 25)) },
                arc_step("A BETTER SEAT", "SHE WANTS A PLACE THAT IS WARM WITHOUT BEING ELECTRIC.", undefined),
                arc_step("THE WARM KEY", "SHE BRINGS YOU A KEY THAT HAS NO LOCK. IT IS WARM TO THE TOUCH.", arc_make_goal("taps", 25))
            ],
            reward: arc_reward("THE WARM KEY", "A KEY WITH NO LOCK. IT HOLDS THE HEAT OF A LAPTOP.",
                arc_make_perk("spark_treat", 1, 0, -1, "EVERY GOLD SPARKLE LEAVES AN EXTRA TREAT."),
                arc_make_perk("tap_treat", 15, 0, 1, "EVERY 15TH TAP IN THE CAT GARDEN LEAVES A TREAT."))
        },
        {
            title: "THE RED DOT",
            hook: "PEPPER HAS SEEN THE DOT AGAIN.",
            steps: [
                arc_step("THE DOT", "PEPPER IS STARING AT A SPOT OF LIGHT ON THE WALL. THERE IS NO LIGHT.", arc_make_goal("sparkles", 1)),
                arc_step("THE CHASE", "SHE HAS BEEN RUNNING THE SAME ROUTE FOR TEN MINUTES. THE DOT IS ALWAYS AHEAD.", arc_make_goal("taps", 20)),
                { title: "THE HAND", text: "THE DOT IS COMING FROM YOUR HAND. PEPPER HAS NOT WORKED THIS OUT.", choice: arc_make_choice(
                    "KEEP THE GAME GOING, OR SHOW HER THE SOURCE.",
                    "KEEP CHASING", "SHE CATCHES IT ONCE. THE WALL IS VERY SATISFIED.", "THE DOT GOT AWAY.",
                    arc_make_goal("crits", 2),
                    "SHOW HER", "SHE SNIFFS YOUR FINGERS, THEN SITS DOWN. THE WALL IS EMPTY.", "SHE SAW THE HAND.",
                    arc_make_goal("sparkles", 2)) },
                arc_step("A NEW ROUTE", "SHE HAS FOUND A SHORTCUT ACROSS THE ROOFTOP. IT IS MOSTLY AIR.", undefined),
                arc_step("THE RED DOT", "SHE LEAVES A SMALL RED DISC ON YOUR PILLOW. IT DOES NOT ROLL AWAY.", arc_make_goal("taps", 30))
            ],
            reward: arc_reward("THE RED DOT", "A PAPER DISC THAT CATCHES THE LIGHT. IT NEVER MOVES ON ITS OWN.",
                arc_make_perk("crit_treat", 1, 0, -1, "EVERY CRITICAL TAP LEAVES AN EXTRA TREAT."),
                arc_make_perk("tap_treat", 10, 0, 2, "EVERY 10TH TAP ON THE ROOFTOP LEAVES A TREAT."))
        },
        {
            title: "THE GENTLE BONK",
            hook: "TOFU HAS A VERY SOFT HEAD.",
            steps: [
                arc_step("THE BONK", "TOFU BONKS THE BOX. THE BOX BONKS BACK. THIS IS GOING WELL.", arc_make_goal("buys", 2)),
                arc_step("THE APOLOGY", "SHE BONKS YOUR HAND, THEN LICKS IT. THE ORDER IS IMPORTANT.", arc_make_goal("taps", 25)),
                { title: "THE HARD EDGE", text: "THERE IS A HARD EDGE ON THE NEW SHELF. TOFU IS CONSIDERING IT.", choice: arc_make_choice(
                    "PAD IT OR LEAVE IT. TOFU WILL TEST IT EITHER WAY.",
                    "PAD THE SHELF", "THE EDGE IS SOFT NOW. TOFU LOOKS ALMOST DISAPPOINTED.", "THE EDGE WAS PADDED.",
                    arc_make_goal("service", 1),
                    "LEAVE IT", "SHE BONKS IT ONCE, LEARNS THE LESSON, AND BONKS IT AGAIN.", "THE EDGE STAYED HARD.",
                    arc_make_goal("buys", 3)) },
                arc_step("A SOFTER ROUND", "SHE IS TEACHING THE OTHER CATS TO BONK WITHOUT HURTING.", undefined),
                arc_step("THE SOFT HAT", "TOFU HAS LEFT YOU A TINY HAT. IT IS TOO SMALL FOR ANYONE BUT A KITTEN.", arc_make_goal("taps", 35))
            ],
            reward: arc_reward("THE SOFT HAT", "A TINY HAT WITH NO CROWN. IT MAKES EVERY BONK FEEL POLITE.",
                arc_make_perk("service_treat", 1, 0, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA TREAT."),
                arc_make_perk("crit_treat", 1, 0, -1, "EVERY CRITICAL TAP LEAVES AN EXTRA TREAT."))
        },
        {
            title: "THE BOX LID",
            hook: "PICKLE HAS FOUND A BOX THAT FITS EXACTLY.",
            steps: [
                arc_step("THE BOX", "PICKLE IS INSIDE A BOX. THE BOX IS INSIDE ANOTHER BOX. SHE IS VERY BUSY.", arc_make_goal("buys", 3)),
                arc_step("THE WRONG LID", "SOMEONE PUT THE LID ON SIDEWAYS. PICKLE HAS NOT COME OUT TO COMPLAIN.", arc_make_goal("taps", 30)),
                { title: "THE CHOICE", text: "THERE IS ROOM FOR ONE MORE THING IN THE BOX. PICKLE IS WAITING FOR YOU TO DECIDE.", choice: arc_make_choice(
                    "A BLANKET OR A SECOND LID. THE BOX CAN HOLD BOTH FOR A WHILE.",
                    "THE BLANKET", "SHE PULLS IT IN WITH ONE PAW. THE BOX BECOMES A ROOM.", "YOU CHOSE THE BLANKET.",
                    arc_make_goal("sparkles", 2),
                    "THE SECOND LID", "SHE TESTS THE FIT. IT CLICKS. SHE GOES VERY STILL.", "YOU CHOSE THE SECOND LID.",
                    arc_make_goal("buys", 4)) },
                arc_step("A DOOR IN THE SIDE", "PICKLE HAS CHEWED A SMALL DOOR IN THE BOX. IT ONLY OPENS FROM INSIDE.", undefined),
                arc_step("THE BOX LID", "SHE GIVES YOU THE LID. THERE IS A PAW PRINT DRYING ON THE UNDERSIDE.", arc_make_goal("sparkles", 2))
            ],
            reward: arc_reward("THE BOX LID", "A LID WITH A PAW PRINT. IT FITS ALMOST EVERYTHING.",
                arc_make_perk("service_treat", 1, 1, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA SCRAP."),
                arc_make_perk("tap_treat", 8, 0, 4, "EVERY 8TH TAP IN THE TEA HOUSE LEAVES A TREAT."))
        },
        {
            title: "THE BIRD FEATHER",
            hook: "MOMO HAS A LOT TO SAY ABOUT BIRDS.",
            steps: [
                arc_step("THE WINDOW", "MOMO IS YELLING AT A BIRD. THE BIRD IS NOT LISTENING. MOMO IS NOT STOPPING.", arc_make_goal("service", 1)),
                arc_step("THE FEATHER", "A FEATHER LANDED ON THE FLOOR. MOMO IS GUARDING IT FROM EVERYONE, INCLUDING YOU.", arc_make_goal("taps", 35)),
                { title: "THE OPEN WINDOW", text: "THE WINDOW IS OPEN. MOMO COULD GO OUT. SHE IS WAITING FOR A REASON.", choice: arc_make_choice(
                    "LET HER OUT, OR ASK HER TO STAY.",
                    "LET HER OUT", "SHE IS BACK IN TWENTY MINUTES, SMELLING OF WEATHER.", "SHE WENT OUT.",
                    arc_make_goal("crits", 2),
                    "ASK HER TO STAY", "SHE YELLS ONCE, THEN SITS ON THE SILL. THE BIRDS KEEP THEIR DISTANCE.", "SHE STAYED.",
                    arc_make_goal("service", 2)) },
                arc_step("A QUIETER WINDOW", "SHE HAS STARTED TALKING TO THE BIRDS INSTEAD OF YELLING AT THEM.", undefined),
                arc_step("THE BIRD FEATHER", "SHE PRESENTS THE FEATHER. IT IS BENT IN THE MIDDLE, LIKE A SMALL ARM.", arc_make_goal("service", 2))
            ],
            reward: arc_reward("THE BIRD FEATHER", "A BENT FEATHER THAT ALWAYS POINTS TOWARD A WINDOW.",
                arc_make_perk("spark_treat", 1, 0, -1, "EVERY GOLD SPARKLE LEAVES AN EXTRA TREAT."),
                arc_make_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."))
        },
        {
            title: "THE SALT SPOON",
            hook: "SARDINE SMELLS LIKE THE SEA AND WON'T EXPLAIN WHY.",
            steps: [
                arc_step("THE SMELL", "SARDINE HAS BEEN SLEEPING IN THE COLD PANTRY. THE PANTRY NOW SMELLS OF SALT.", arc_make_goal("taps", 40)),
                arc_step("THE TIDE", "THERE IS A WET LINE ACROSS THE FLOOR. IT STOPS AT THE CUPBOARD.", arc_make_goal("buys", 4)),
                { title: "THE SPOON", text: "SHE HAS A SILVER SPOON THAT TASTES OF THE SEA. SHE WON'T SAY WHERE IT CAME FROM.", choice: arc_make_choice(
                    "KEEP THE SPOON, OR PUT IT BACK.",
                    "KEEP IT", "THE SPOON IS COLD IN THE MORNING AND WARM AT NIGHT.", "THE SPOON STAYED.",
                    arc_make_goal("sparkles", 2),
                    "PUT IT BACK", "THE WET LINE RETREATS. SARDINE SLEEPS WITH ONE EYE OPEN.", "THE SPOON WENT BACK.",
                    arc_make_goal("taps", 50)) },
                arc_step("A SMALL LOW TIDE", "THE FLOOR IS DRY. SARDINE IS WATCHING THE CUPBOARD ANYWAY.", undefined),
                arc_step("THE SALT SPOON", "SHE LEAVES THE SPOON ON THE COUNTER. IT IS FULL OF SOMETHING THAT IS NOT SALT.", arc_make_goal("service", 2))
            ],
            reward: arc_reward("THE SALT SPOON", "A SPOON THAT TASTES OF A PLACE YOU HAVE NEVER BEEN.",
                arc_make_perk("tap_treat", 8, 0, 0, "EVERY 8TH TAP IN THE COZY CORNER LEAVES A TREAT."),
                arc_make_perk("service_treat", 1, 2, -1, "EVERY PERFECT COUNTER DISH LEAVES EXTRA DUST."))
        },
        {
            title: "THE CURTAIN RING",
            hook: "NOODLE HAS FOUND A NEW VERTICAL.",
            steps: [
                arc_step("THE CLIMB", "NOODLE IS ABOVE THE WINDOW. THE CURTAIN IS NOT HAPPY ABOUT IT.", arc_make_goal("taps", 45)),
                arc_step("THE RING", "A CURTAIN RING IS MISSING. NOODLE IS WEARING IT LIKE A SMALL COLLAR.", arc_make_goal("buys", 5)),
                { title: "THE HIGH SHELF", text: "THERE IS A SHELF ABOVE THE CURTAIN. NOODLE CAN REACH IT. YOU CANNOT.", choice: arc_make_choice(
                    "LEAVE IT TO HER, OR BRING A LADDER.",
                    "LET HER CLIMB", "SHE SLEEPS UP THERE ALL AFTERNOON. THE DUST DOES NOT SETTLE.", "SHE TOOK THE HIGH ROAD.",
                    arc_make_goal("staff_self", 1),
                    "BRING THE LADDER", "SHE USES THE LADDER ONCE, THEN GOES UP THE CURTAIN ANYWAY.", "THE LADDER STAYED OUT.",
                    arc_make_goal("taps", 60)) },
                arc_step("A NEW PERCH", "SHE HAS CLAIMED THE TOP OF THE CURTAIN. THE ROOM FEELS TALLER.", undefined),
                arc_step("THE CURTAIN RING", "SHE DROPS THE RING INTO YOUR LAP. IT HAS A TOOTH MARK IN IT.", arc_make_goal("sparkles", 3))
            ],
            reward: arc_reward("THE CURTAIN RING", "A BRASS RING WITH ONE SMALL TOOTH MARK.",
                arc_make_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."),
                arc_make_perk("tap_treat", 12, 0, 1, "EVERY 12TH TAP IN THE CAT GARDEN LEAVES A TREAT."))
        },
        {
            title: "THE GARDEN BELL",
            hook: "BEAN HAS BEEN SLEEPING WHERE THE PLANTS SHOULD BE.",
            steps: [
                arc_step("THE BARE PATCH", "THERE IS A BEAN-SHAPED HOLE IN THE GARDEN. BEAN IS NOT SORRY.", arc_make_goal("buys", 6)),
                arc_step("THE SEED", "SHE HAS A SEED IN HER MOUTH. SHE DOES NOT WANT TO PLANT IT. SHE WANTS YOU TO.", arc_make_goal("taps", 50)),
                { title: "THE BELL", text: "A SMALL BELL IS BURIED AT THE EDGE OF THE BED. IT RINGS WHEN THE SOIL MOVES.", choice: arc_make_choice(
                    "DIG IT UP, OR LEAVE IT BURIED.",
                    "DIG IT UP", "THE BELL IS HEAVY. THE SOIL UNDER IT IS WARM.", "THE BELL CAME UP.",
                    arc_make_goal("service", 2),
                    "LEAVE IT", "SOMETHING UNDER THE SOIL RINGS ONCE, THEN STOPS.", "THE BELL STAYED BURIED.",
                    arc_make_goal("sparkles", 3)) },
                arc_step("THE FIRST GREEN", "A SHOOT IS UP. BEAN IS PRETENDING SHE DID NOT NOTICE.", undefined),
                arc_step("THE GARDEN BELL", "SHE RINGS THE BELL. THE ROOM SMELLS OF RAIN FOR A MOMENT.", arc_make_goal("taps", 60))
            ],
            reward: arc_reward("THE GARDEN BELL", "A SMALL BELL THAT ONLY RINGS WHEN SOMETHING GROWS.",
                arc_make_perk("garden_plot", 1, 0, -1, "THE ASH GARDEN GAINS ONE EXTRA BED."),
                arc_make_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."))
        },
        {
            title: "THE BREAD CRUST",
            hook: "WAFFLE HAS BEEN NEAR THE OVEN FOR AN HOUR.",
            steps: [
                arc_step("THE LOAF", "WAFFLE HAS STOLEN THE END OF A LOAF. THE OVEN IS STILL WARM.", arc_make_goal("buys", 7)),
                arc_step("THE CRUST", "SHE ONLY EATS THE CRUST. THE REST OF THE BREAD IS IN A NEAT PILE.", arc_make_goal("service", 2)),
                { title: "THE SECOND LOAF", text: "THERE IS ONE LOAF LEFT. WAFFLE IS TRYING TO LOOK UNINTERESTED.", choice: arc_make_choice(
                    "BAKE ANOTHER, OR SHARE THIS ONE.",
                    "BAKE ANOTHER", "THE OVEN RUNS LATE. WAFFLE SLEEPS BESIDE IT.", "YOU BAKED ANOTHER.",
                    arc_make_goal("crits", 3),
                    "SHARE IT", "SHE TAKES THE CRUST. YOU GET THE MIDDLE. THIS IS FAIR.", "YOU SHARED THE LOAF.",
                    arc_make_goal("buys", 8)) },
                arc_step("A WARM COUNTER", "WAFFLE IS SITTING ON THE COOLING RACK. THE BREAD IS UNDER HER.", undefined),
                arc_step("THE BREAD CRUST", "SHE LEAVES YOU A CRUST IN THE SHAPE OF A SMALL CROWN.", arc_make_goal("service", 3))
            ],
            reward: arc_reward("THE BREAD CRUST", "A CRUST THAT STAYS WARM LONGER THAN IT SHOULD.",
                arc_make_perk("service_treat", 1, 0, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA TREAT."),
                arc_make_perk("tap_treat", 10, 0, 3, "EVERY 10TH TAP IN THE CLOUD CAFE LEAVES A TREAT."))
        },
        {
            title: "THE FOUR-LEAF PIN",
            hook: "CLOVER BRINGS LUCK THAT NOBODY ASKED FOR.",
            steps: [
                arc_step("THE LEAF", "CLOVER HAS LEFT A FOUR-LEAF CLOVER ON YOUR PILLOW. IT IS STILL DAMP.", arc_make_goal("sparkles", 3)),
                arc_step("THE PIN", "SHE HAS PINNED IT TO YOUR SLEEVE. THE PIN IS BENT AND SLIGHTLY WARM.", arc_make_goal("buys", 8)),
                { title: "THE LUCK", text: "THE PIN IS CATCHING THE LIGHT. CLOVER IS WAITING FOR YOU TO DECIDE WHAT IT MEANS.", choice: arc_make_choice(
                    "KEEP IT ON, OR PUT IT AWAY.",
                    "KEEP IT ON", "THE DAY GOES WELL. CLOVER LOOKS SMUG.", "YOU KEPT THE PIN ON.",
                    arc_make_goal("taps", 70),
                    "PUT IT AWAY", "THE DAY GOES FINE. CLOVER CHECKS YOUR SLEEVE ANYWAY.", "YOU PUT THE PIN AWAY.",
                    arc_make_goal("service", 3)) },
                arc_step("A SMALL RETURN", "CLOVER HAS BROUGHT ANOTHER LEAF. SHE IS NOT EXPLAINING THE FIRST ONE.", undefined),
                arc_step("THE FOUR-LEAF PIN", "SHE LEAVES THE PIN ON THE COUNTER. IT HAS THREE LEAVES NOW.", arc_make_goal("taps", 80))
            ],
            reward: arc_reward("THE FOUR-LEAF PIN", "A BENT PIN WITH THREE LEAVES AND ONE EMPTY SPACE.",
                arc_make_perk("spark_treat", 1, 0, -1, "EVERY GOLD SPARKLE LEAVES AN EXTRA TREAT."),
                arc_make_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."))
        },
        {
            title: "THE JIGGLE BELL",
            hook: "PUDDING HAS A VERY SPECIFIC HAPPY SOUND.",
            steps: [
                arc_step("THE JIGGLE", "PUDDING IS HAPPY. THE WHOLE TABLE IS JIGGLING. THIS IS NORMAL.", arc_make_goal("service", 3)),
                arc_step("THE BELL", "THERE IS A SMALL BELL UNDER THE TABLE. IT RINGS WHEN SHE JIGGLES.", arc_make_goal("taps", 75)),
                { title: "THE QUIET", text: "THE BELL HAS STOPPED. PUDDING IS SITTING VERY STILL. THE ROOM FEELS WRONG.", choice: arc_make_choice(
                    "RING IT, OR LET HER REST.",
                    "RING IT", "THE BELL SOUNDS. PUDDING JIGGLES ONCE AND PRETENDS SHE DIDN'T.", "YOU RANG THE BELL.",
                    arc_make_goal("buys", 9),
                    "LET HER REST", "SHE SLEEPS. THE BELL STAYS QUIET. THE ROOM SETTLES.", "YOU LET HER REST.",
                    arc_make_goal("service", 4)) },
                arc_step("A GENTLER JIGGLE", "SHE HAS FOUND A WAY TO JIGGLE WITHOUT SHAKING THE CUPS.", undefined),
                arc_step("THE JIGGLE BELL", "SHE GIVES YOU THE BELL. IT IS STICKY AND VERY LOUD.", arc_make_goal("crits", 4))
            ],
            reward: arc_reward("THE JIGGLE BELL", "A TINY BELL THAT RINGS WHEN SOMEONE IS HAPPY.",
                arc_make_perk("service_treat", 1, 1, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA SCRAP."),
                arc_make_perk("festival_entry", 1, 0, -1, "EVERY FESTIVAL ENTRY COSTS ONE LESS MATERIAL."))
        },
        {
            title: "THE RACING RIBBON",
            hook: "COMET HAS NEVER LOST A RACE TO A PIGEON.",
            steps: [
                arc_step("THE START", "COMET IS AT THE EDGE OF THE ROOF. THE PIGEONS ARE NOT RACING. SHE IS.", arc_make_goal("taps", 80)),
                arc_step("THE TURN", "SHE CUT THE CORNER SO HARD THE RUG MOVED. THE PIGEONS ARE STILL WINNING.", arc_make_goal("sparkles", 4)),
                { title: "THE LINE", text: "THERE IS A FINISH LINE CHALKED ON THE FLOOR. COMET IS WAITING FOR A FAIR START.", choice: arc_make_choice(
                    "RUN IT AGAIN, OR CALL IT A DRAW.",
                    "RUN AGAIN", "SHE WINS BY A WHISKER. THE PIGEONS LOOK SURPRISED.", "SHE RAN AGAIN.",
                    arc_make_goal("crits", 4),
                    "CALL A DRAW", "SHE SITS DOWN BESIDE THE PIGEONS. NOBODY ADMITS ANYTHING.", "YOU CALLED A DRAW.",
                    arc_make_goal("room", 40)) },
                arc_step("THE VICTORY LAP", "SHE DOES ONE LAP OF THE CAFE AND KNOCKS OVER NOTHING. ALMOST.", undefined),
                arc_step("THE RACING RIBBON", "SHE LEAVES A RIBBON ON THE RUG. IT HAS A NUMBER ONE ON IT, BACKWARDS.", arc_make_goal("sparkles", 5))
            ],
            reward: arc_reward("THE RACING RIBBON", "A BLUE RIBBON WITH A BACKWARDS NUMBER ONE.",
                arc_make_perk("tap_treat", 8, 0, 2, "EVERY 8TH TAP ON THE ROOFTOP LEAVES A TREAT."),
                arc_make_perk("crit_treat", 1, 0, -1, "EVERY CRITICAL TAP LEAVES AN EXTRA TREAT."))
        },
        {
            title: "THE ROOF SLATE",
            hook: "MARLOW HAS BEEN GUARDING THE ROOF FROM WEATHER.",
            steps: [
                arc_step("THE WATCH", "MARLOW IS STARING AT THE SKY. NOTHING IS UP THERE. SHE IS NOT CONVINCED.", arc_make_goal("buys", 10)),
                arc_step("THE SLATE", "A ROOF SLATE HAS COME LOOSE. MARLOW IS SITTING ON IT SO IT CANNOT GET AWAY.", arc_make_goal("taps", 90)),
                { title: "THE STORM", text: "CLOUDS ARE COMING IN. MARLOW WANTS TO STAY OUT. YOU WANT THE WINDOWS CLOSED.", choice: arc_make_choice(
                    "STAND WATCH, OR COME INSIDE.",
                    "STAND WATCH", "THE RAIN ARRIVES. MARLOW DOES NOT MOVE. NEITHER DO YOU.", "YOU STOOD WATCH.",
                    arc_make_goal("staff_self", 1),
                    "COME INSIDE", "SHE COMES IN ON THE THIRD CALL. THE ROOF CAN TAKE IT.", "YOU BOTH CAME INSIDE.",
                    arc_make_goal("service", 5)) },
                arc_step("A DRY ROOM", "THE STORM PASSES. MARLOW CHECKS EVERY WINDOW ANYWAY.", undefined),
                arc_step("THE ROOF SLATE", "SHE GIVES YOU THE SLATE. IT IS HEAVIER THAN IT LOOKS AND SMELLS OF RAIN.", arc_make_goal("sparkles", 5))
            ],
            reward: arc_reward("THE ROOF SLATE", "A LOOSE SLATE THAT ALWAYS FEELS LIKE IT JUST STOPPED RAINING.",
                arc_make_perk("hall_nerve", 1, 0, -1, "THE LONG HALL STARTS WITH ONE EXTRA NERVE."),
                arc_make_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."))
        },
        {
            title: "THE SUN SPOT",
            hook: "SAFFRON HAS FOUND THE ONLY WARM PATCH ON THE FLOOR.",
            steps: [
                arc_step("THE PATCH", "THE SUN HAS MOVED. SAFFRON HAS NOT. THIS IS A PROBLEM FOR THE SUN.", arc_make_goal("taps", 100)),
                arc_step("THE SHADOW", "THE PATCH IS GETTING SMALLER. SAFFRON IS TRYING TO STRETCH IT WITH HER PAWS.", arc_make_goal("buys", 11)),
                { title: "THE CURTAIN", text: "THE CURTAIN CAN STAY OPEN, OR YOU CAN LET THE ROOM COOL DOWN.", choice: arc_make_choice(
                    "KEEP THE SUN, OR SHARE THE SHADE.",
                    "KEEP THE SUN", "THE PATCH MOVES. SAFFRON FOLLOWS IT ACROSS THE FLOOR.", "YOU KEPT THE SUN.",
                    arc_make_goal("service", 5),
                    "SHARE THE SHADE", "THE ROOM COOLS. SAFFRON CURLS UP IN THE DARK AND SLEEPS.", "YOU SHARED THE SHADE.",
                    arc_make_goal("crits", 5)) },
                arc_step("A MOVING PATCH", "THE SUN IS LOWER NOW. SAFFRON HAS CLAIMED THE WHOLE RUG.", undefined),
                arc_step("THE SUN SPOT", "SHE LEAVES A WARM CIRCLE OF FLOOR IN THE SHAPE OF HER. IT DOES NOT COOL.", arc_make_goal("sparkles", 6))
            ],
            reward: arc_reward("THE SUN SPOT", "A WARM PATCH OF FLOOR THAT FOLLOWS SAFFRON AROUND.",
                arc_make_perk("tap_treat", 8, 0, 4, "EVERY 8TH TAP IN THE TEA HOUSE LEAVES A TREAT."),
                arc_make_perk("spark_treat", 1, 0, -1, "EVERY GOLD SPARKLE LEAVES AN EXTRA TREAT."))
        },
        {
            title: "THE TIN WHISTLE",
            hook: "KIWI IS SMALL. THE SOUND IS NOT.",
            steps: [
                arc_step("THE WHISTLE", "KIWI HAS FOUND A TIN WHISTLE. SHE HAS NOT STOPPED BLOWING IT.", arc_make_goal("service", 5)),
                arc_step("THE ANSWER", "SOMETHING IN THE KITCHEN WHISTLES BACK. KIWI IS DELIGHTED. THE KITCHEN IS NOT.", arc_make_goal("taps", 110)),
                { title: "THE VOLUME", text: "THE WHISTLE IS STILL GOING. THE OTHER CATS ARE STARTING TO LEAVE THE ROOM.", choice: arc_make_choice(
                    "KEEP IT LOUD, OR FIND A QUIETER NOTE.",
                    "KEEP IT LOUD", "THE WHOLE CAFE ANSWERS. IT IS AWFUL AND WONDERFUL.", "YOU KEPT IT LOUD.",
                    arc_make_goal("crits", 6),
                    "FIND A QUIET NOTE", "SHE FINDS ONE. THE KITCHEN WHISTLES BACK, SOFTLY.", "YOU FOUND A QUIET NOTE.",
                    arc_make_goal("buys", 12)) },
                arc_step("A SMALL CHORUS", "KIWI HAS TAUGHT THE KITTENS TO WHISTLE. THEY ARE NOT GOOD AT IT.", undefined),
                arc_step("THE TIN WHISTLE", "SHE GIVES YOU THE WHISTLE. IT IS DENTED IN THE SHAPE OF HER MOUTH.", arc_make_goal("service", 6))
            ],
            reward: arc_reward("THE TIN WHISTLE", "A DENTED WHISTLE THAT ONLY MAKES ONE NOTE.",
                arc_make_perk("festival_entry", 1, 0, -1, "EVERY FESTIVAL ENTRY COSTS ONE LESS MATERIAL."),
                arc_make_perk("service_treat", 1, 2, -1, "EVERY PERFECT COUNTER DISH LEAVES EXTRA DUST."))
        },
        {
            title: "THE READING LENS",
            hook: "OLIVE HAS BEEN READING OVER YOUR SHOULDER AGAIN.",
            steps: [
                arc_step("THE PAGE", "OLIVE IS READING THE LEDGER. SHE HAS TURNED IT UPSIDE DOWN. IT MAKES MORE SENSE.", arc_make_goal("journal", 1)),
                arc_step("THE LENS", "THERE IS A SMALL GLASS LENS ON THE SHELF. IT MAKES THE WORDS BIGGER AND SLIGHTLY WRONG.", arc_make_goal("buys", 13)),
                { title: "THE MARGIN", text: "OLIVE HAS WRITTEN IN THE MARGIN. IT IS A QUESTION, OR A PAW PRINT. YOU CAN'T TELL.", choice: arc_make_choice(
                    "ANSWER IT, OR LEAVE IT BLANK.",
                    "ANSWER IT", "SHE READS YOUR ANSWER TWICE, THEN NODS ONCE.", "YOU ANSWERED THE MARGIN.",
                    arc_make_goal("projects", 1),
                    "LEAVE IT BLANK", "SHE SITS WITH THE BLANK SPACE FOR A WHILE. THEN SHE SLEEPS ON IT.", "YOU LEFT IT BLANK.",
                    arc_make_goal("service", 7)) },
                arc_step("A NEW PAGE", "THE NEXT PAGE IS BLANK. OLIVE IS WAITING FOR YOU TO START IT.", undefined),
                arc_step("THE READING LENS", "SHE GIVES YOU THE LENS. THE CAFE LOOKS LARGER THROUGH IT, AND VERY FAR AWAY.", arc_make_goal("taps", 120))
            ],
            reward: arc_reward("THE READING LENS", "A SMALL LENS THAT MAKES EVERY PAGE FEEL IMPORTANT.",
                arc_make_perk("service_treat", 1, 0, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA TREAT."),
                arc_make_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."))
        },
        {
            title: "THE CLOUD BUTTON",
            hook: "PUFF IS WARMER THAN THE ROOM AND LIGHTER THAN AIR.",
            steps: [
                arc_step("THE WEIGHT", "PUFF IS SITTING ON THE SCALE. THE SCALE SAYS NOTHING AT ALL.", arc_make_goal("sparkles", 6)),
                arc_step("THE BUTTON", "SHE HAS A CLOUD-SHAPED BUTTON IN HER FUR. IT IS NOT ATTACHED TO ANYTHING.", arc_make_goal("service", 7)),
                { title: "THE CEILING", text: "PUFF IS DRIFTING. THE CEILING IS CLOSE. SHE IS WAITING FOR YOU TO CHOOSE A DIRECTION.", choice: arc_make_choice(
                    "LET HER FLOAT, OR GENTLY PULL HER DOWN.",
                    "LET HER FLOAT", "SHE NAPS AGAINST THE CEILING. THE LAMPS LOOK CONFUSED.", "SHE FLOATED.",
                    arc_make_goal("buys", 14),
                    "PULL HER DOWN", "SHE SETTLES INTO YOUR LAP. SHE IS STILL WARM AND STILL SLIGHTLY ABOVE IT.", "SHE CAME DOWN.",
                    arc_make_goal("journal", 2)) },
                arc_step("A SOFTER LANDING", "PUFF HAS FOUND A CUSHION THAT DOES NOT MIND BEING FLOATED OVER.", undefined),
                arc_step("THE CLOUD BUTTON", "SHE LEAVES THE BUTTON IN YOUR HAND. IT WEIGHS LESS THAN NOTHING.", arc_make_goal("taps", 130))
            ],
            reward: arc_reward("THE CLOUD BUTTON", "A BUTTON WITH NO THREAD HOLE. IT DRIFTS WHEN YOU ARE NOT LOOKING.",
                arc_make_perk("garden_plot", 1, 0, -1, "THE ASH GARDEN GAINS ONE EXTRA BED."),
                arc_make_perk("hall_nerve", 1, 0, -1, "THE LONG HALL STARTS WITH ONE EXTRA NERVE."))
        },
        {
            title: "THE NIGHT LAMP",
            hook: "STAR ONLY NAPS WHEN THE SUN IS GONE.",
            steps: [
                arc_step("THE DAY", "STAR IS AWAKE. THE SUN IS UP. SHE IS NOT HAPPY ABOUT EITHER.", arc_make_goal("taps", 140)),
                arc_step("THE LAMP", "A SMALL LAMP ON THE SHELF HAS BEEN ON ALL DAY. STAR KEEPS LOOKING AT IT.", arc_make_goal("crits", 7)),
                { title: "THE SWITCH", text: "THE LAMP CAN STAY ON, OR YOU CAN TURN IT OFF. STAR IS PRETENDING NOT TO CARE.", choice: arc_make_choice(
                    "LEAVE IT ON, OR TURN IT OFF.",
                    "LEAVE IT ON", "SHE SLEEPS IN THE DAYLIGHT. IT IS THE FIRST TIME ALL WEEK.", "YOU LEFT IT ON.",
                    arc_make_goal("sparkles", 7),
                    "TURN IT OFF", "THE ROOM GOES DARK. STAR IS AWAKE AND VERY PLEASED.", "YOU TURNED IT OFF.",
                    arc_make_goal("service", 8)) },
                arc_step("A LONGER NIGHT", "SHE HAS FOUND A CORNER WHERE THE LIGHT DOES NOT REACH. SHE IS NOT SHARING IT YET.", undefined),
                arc_step("THE NIGHT LAMP", "SHE GIVES YOU THE LAMP. IT IS COLD AND HAS NO BULB.", arc_make_goal("taps", 150))
            ],
            reward: arc_reward("THE NIGHT LAMP", "A LAMP THAT ONLY WORKS WHEN THE ROOM IS DARK.",
                arc_make_perk("night_nerve", 1, 0, -1, "THE NINTH TABLE STARTS WITH ONE EXTRA NERVE."),
                arc_make_perk("hall_nerve", 1, 0, -1, "THE LONG HALL STARTS WITH ONE EXTRA NERVE."))
        },
        {
            title: "THE SHARING PLATE",
            hook: "CLEMENTINE HAS NEVER EATEN ALONE.",
            steps: [
                arc_step("THE PLATE", "CLEMENTINE HAS PUSHED HER PLATE TO THE MIDDLE OF THE TABLE. THERE IS ROOM FOR YOU.", arc_make_goal("service", 8)),
                arc_step("THE SECOND PLATE", "SHE HAS BROUGHT ANOTHER PLATE. IT IS EMPTY. SHE IS WAITING.", arc_make_goal("buys", 15)),
                { title: "THE LAST BITE", text: "THERE IS ONE BITE LEFT. CLEMENTINE IS TRYING TO GIVE IT TO YOU WITHOUT LOOKING.", choice: arc_make_choice(
                    "TAKE IT, OR GIVE IT BACK.",
                    "TAKE IT", "SHE WATCHES YOU EAT IT. SHE LOOKS SATISFIED AND A LITTLE SAD.", "YOU TOOK THE LAST BITE.",
                    arc_make_goal("sparkles", 8),
                    "GIVE IT BACK", "SHE EATS IT IN ONE GO, THEN LICKS THE PLATE CLEAN.", "YOU GAVE IT BACK.",
                    arc_make_goal("journal", 2)) },
                arc_step("A FULL TABLE", "THERE ARE MORE PLATES NOW. NONE OF THEM ARE EMPTY.", undefined),
                arc_step("THE SHARING PLATE", "SHE LEAVES YOU THE PLATE. IT IS STILL WARM AND THERE IS A CRUMB IN THE CORNER.", arc_make_goal("taps", 160))
            ],
            reward: arc_reward("THE SHARING PLATE", "A PLATE THAT ALWAYS HAS ONE BITE LEFT ON IT.",
                arc_make_perk("service_treat", 1, 0, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA TREAT."),
                arc_make_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."))
        },
        {
            title: "THE LOAF TWINE",
            hook: "DUMPLING HAS FOLDED HERSELF INTO A PERFECT LOAF.",
            steps: [
                arc_step("THE FOLD", "DUMPLING HAS TUCKED EVERY PAW. THE SHAPE IS PERFECT. THE ROOM IS IMPRESSED.", arc_make_goal("buys", 16)),
                arc_step("THE TWINE", "THERE IS A PIECE OF BAKERY TWINE WRAPPED AROUND HER LOAF. SHE DID NOT PUT IT THERE.", arc_make_goal("taps", 170)),
                { title: "THE UNFOLD", text: "DUMPLING CAN STAY FOLDED, OR SHE CAN STRETCH. THE TWINE IS GETTING TIGHT.", choice: arc_make_choice(
                    "LET HER STAY, OR UNTIE THE TWINE.",
                    "LET HER STAY", "SHE SLEEPS THROUGH THE AFTERNOON. THE LOAF DOES NOT MOVE.", "SHE STAYED FOLDED.",
                    arc_make_goal("service", 9),
                    "UNTIE IT", "SHE STRETCHES ONE LEG, THEN ALL FOUR. THE LOAF BECOMES A CAT AGAIN.", "YOU UNTIED THE TWINE.",
                    arc_make_goal("crits", 8)) },
                arc_step("A WIDER LOAF", "SHE HAS FOUND A WAY TO FOLD THAT LEAVES ROOM FOR A KITTEN.", undefined),
                arc_step("THE LOAF TWINE", "SHE GIVES YOU THE TWINE. IT SMELLS OF BREAD AND IS TIED IN A KNOT YOU CANNOT UNDO.", arc_make_goal("sparkles", 9))
            ],
            reward: arc_reward("THE LOAF TWINE", "A LENGTH OF TWINE THAT ALWAYS SMELLS OF FRESH BREAD.",
                arc_make_perk("tap_treat", 6, 0, 3, "EVERY 6TH TAP IN THE CLOUD CAFE LEAVES A TREAT."),
                arc_make_perk("garden_plot", 1, 0, -1, "THE ASH GARDEN GAINS ONE EXTRA BED."))
        },
        {
            title: "THE ORANGE THREAD",
            hook: "MARMALADE HAS BEEN LEAVING ORANGE THREAD EVERYWHERE.",
            steps: [
                arc_step("THE THREAD", "THERE IS ORANGE THREAD ON THE STAIRS, THE SHELF AND YOUR COAT. MARMALADE IS FOLLOWING IT.", arc_make_goal("room", 60)),
                arc_step("THE SPOOL", "THE THREAD LEADS TO A SPOOL UNDER THE COUNTER. IT IS ALMOST EMPTY.", arc_make_goal("buys", 17)),
                { title: "THE PATTERN", text: "THE THREAD MAKES A SHAPE ON THE FLOOR. IT COULD BE A DOOR, OR A SUN, OR A MISTAKE.", choice: arc_make_choice(
                    "KEEP THE PATTERN, OR WIND IT UP.",
                    "KEEP THE PATTERN", "THE SHAPE STAYS ON THE FLOOR. THE CATS WALK AROUND IT.", "YOU KEPT THE PATTERN.",
                    arc_make_goal("service", 10),
                    "WIND IT UP", "THE SPOOL IS FULL AGAIN. MARMALADE LOOKS AT THE EMPTY FLOOR AND THEN AT YOU.", "YOU WOUND IT UP.",
                    arc_make_goal("taps", 180)) },
                arc_step("A NEW THREAD", "SHE HAS STARTED A SECOND PATTERN. THIS ONE HAS MORE CORNERS.", undefined),
                arc_step("THE ORANGE THREAD", "SHE WINDS THE LAST OF IT AROUND YOUR WRIST. IT FITS EXACTLY TWICE.", arc_make_goal("sparkles", 10))
            ],
            reward: arc_reward("THE ORANGE THREAD", "A THREAD THAT ALWAYS FINDS ITS WAY BACK TO THE SPOOL.",
                arc_make_perk("festival_entry", 1, 0, -1, "EVERY FESTIVAL ENTRY COSTS ONE LESS MATERIAL."),
                arc_make_perk("service_treat", 1, 1, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA SCRAP."))
        },
        {
            title: "THE DRIFTING CORK",
            hook: "WISP HAS BEEN BETWEEN NAPS FOR THREE DAYS.",
            steps: [
                arc_step("THE DRIFT", "WISP IS ABOVE THE TABLE, THEN BESIDE IT, THEN ASLEEP. THE ORDER IS NOT CLEAR.", arc_make_goal("sparkles", 9)),
                arc_step("THE CORK", "SHE HAS A CORK FROM A BOTTLE THAT WAS NEVER OPENED. IT FLOATS WHEN SHE HOLDS IT.", arc_make_goal("taps", 190)),
                { title: "THE ANCHOR", text: "THE CORK IS TUGGING TOWARD THE DOOR. WISP IS WAITING TO SEE IF YOU WILL FOLLOW.", choice: arc_make_choice(
                    "LET IT GO, OR HOLD IT DOWN.",
                    "LET IT GO", "THE CORK DRIFTS TO THE DOOR AND STOPS. WISP IS ALREADY ASLEEP THERE.", "YOU LET IT GO.",
                    arc_make_goal("buys", 18),
                    "HOLD IT DOWN", "THE CORK SETTLES. WISP SETTLES WITH IT, ONE PAW ON YOUR WRIST.", "YOU HELD IT DOWN.",
                    arc_make_goal("service", 11)) },
                arc_step("A STEADIER NAP", "SHE HAS FOUND A CORNER THAT DOES NOT DRIFT. SHE IS STILL DECIDING WHETHER TO TRUST IT.", undefined),
                arc_step("THE DRIFTING CORK", "SHE LEAVES THE CORK ON THE COUNTER. IT POINTS AT THE DOOR UNTIL YOU LOOK AWAY.", arc_make_goal("journal", 3))
            ],
            reward: arc_reward("THE DRIFTING CORK", "A CORK THAT ALWAYS POINTS TOWARD THE NEAREST DOOR.",
                arc_make_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."),
                arc_make_perk("garden_plot", 1, 0, -1, "THE ASH GARDEN GAINS ONE EXTRA BED."))
        },
        {
            title: "THE CAFE LEDGER",
            hook: "BIG BOSS HAS BEEN RUNNING THE PLACE FROM THE COUNTER.",
            steps: [
                arc_step("THE LEDGER", "BIG BOSS HAS OPENED THE LEDGER. EVERY PAGE IS A LIST OF THINGS YOU OWE THE CAFE.", arc_make_goal("service", 12)),
                arc_step("THE PEN", "SHE HAS A PEN IN HER MOUTH. SHE IS WAITING FOR YOU TO SIGN SOMETHING.", arc_make_goal("buys", 20)),
                { title: "THE SIGNATURE", text: "THE LEDGER HAS TWO LINES. ONE IS FOR THE CAFE. ONE IS FOR YOU.", choice: arc_make_choice(
                    "SIGN FOR THE CAFE, OR FOR YOURSELF.",
                    "SIGN FOR THE CAFE", "THE CATS GET A LONGER BREAK. THE LEDGER GETS A NEW PAGE.", "YOU SIGNED FOR THE CAFE.",
                    arc_make_goal("fest", 1),
                    "SIGN FOR YOURSELF", "THE CAFE KEEPS RUNNING. YOUR NAME LOOKS STRANGE IN HER HANDWRITING.", "YOU SIGNED FOR YOURSELF.",
                    arc_make_goal("hollow", 1)) },
                arc_step("A LONGER BREAK", "THE CATS ARE ASLEEP IN A WAY THAT LOOKS ORGANIZED. BIG BOSS IS NOT ONE OF THEM.", undefined),
                arc_step("THE CAFE LEDGER", "SHE CLOSES THE LEDGER AND PUSHES IT ACROSS THE COUNTER. THE LAST PAGE IS BLANK.", arc_make_goal("night", 3))
            ],
            reward: arc_reward("THE CAFE LEDGER", "A LEDGER WITH ONE BLANK PAGE AND A PEN THAT NEVER RUNS OUT.",
                arc_make_perk("night_nerve", 1, 0, -1, "THE NINTH TABLE STARTS WITH ONE EXTRA NERVE."),
                arc_make_perk("festival_entry", 1, 0, -1, "EVERY FESTIVAL ENTRY COSTS ONE LESS MATERIAL."))
        }
    ];
    return _d;
}
