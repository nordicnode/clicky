/// @description authored room and festival stories: six rooms, nine festivals.
///
/// Content only. State lives in scr_venue_arcs; this file never reads or writes
/// the save and never draws. Room arcs are four beats with the choice third;
/// festival arcs are three beats with the choice second, so neither is a second
/// mechanics layer, only a different amount of story.

#macro VA_ROOMS 6
#macro VA_FESTS 9

function va_goal(_kind, _n) {
    return { k: _kind, n: _n };
}

function va_step(_title, _text, _goal) {
    return { title: _title, text: _text, goal: _goal };
}

function va_choice(_prompt, _a_label, _a_text, _a_echo, _a_goal,
                   _b_label, _b_text, _b_echo, _b_goal) {
    return {
        prompt: _prompt,
        a: { label: _a_label, text: _a_text, echo: _a_echo, goal: _a_goal },
        b: { label: _b_label, text: _b_text, echo: _b_echo, goal: _b_goal }
    };
}

function va_perk(_kind, _n, _material, _zone, _text) {
    return { k: _kind, n: _n, m: _material, zone: _zone, text: _text };
}

function va_reward(_name, _text, _a, _b) {
    return { name: _name, text: _text, a: _a, b: _b };
}

function venue_arc_content() {
    static _d = [
        // ---------------------------------------------------------- rooms
        {
            kind: 0, idx: 0, title: "THE FIRST CUP",
            steps: [
                va_step("A COLD CUP", "THE MUG BY THE WINDOW HAS GONE COLD. MOCHI IS SITTING ON THE WARM ONE.",
                        va_goal("room", 20)),
                va_step("THE SECOND CUP", "SHE WILL NOT DRINK FROM A CHIPPED MUG. THE SHELF HAS ONE THAT IS NOT CHIPPED.",
                        va_goal("buys", 1)),
                { title: "POUR OR WAIT", text: "THE KETTLE IS STILL HOT. MOCHI IS WAITING TO SEE WHICH CUP YOU CHOOSE.",
                  choice: va_choice(
                    "POUR IT FRESH, OR LET IT COOL.",
                    "POUR IT FRESH", "THE STEAM CURLS TOWARD HER. SHE PRETENDS NOT TO NOTICE.",
                    "YOU POURED IT FRESH.", va_goal("service", 1),
                    "LET IT COOL", "SHE WAITS UNTIL IT IS ROOM TEMPERATURE. THEN SHE WAITS LONGER.",
                    "YOU LET IT COOL.", va_goal("sparkles", 1)) },
                va_step("THE FIRST CUP", "SHE LEAVES THE MUG ON YOUR LEDGER. IT IS STILL WARM. THE LEDGER IS NOT.",
                        va_goal("room", 40))
            ],
            reward: va_reward("THE FIRST CUP", "A MUG THAT NEVER QUITE GOES COLD.",
                va_perk("tap_treat", 8, 0, 0, "EVERY 8TH TAP IN THE COZY CORNER LEAVES A TREAT."),
                va_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."))
        },
        {
            kind: 0, idx: 1, title: "THE SPARE TROWEL",
            steps: [
                va_step("THE BARE ROW", "ONE ROW OF THE GARDEN IS EMPTY. BEAN IS LYING IN IT, WHICH IS NOT THE SAME THING.",
                        va_goal("room", 40)),
                va_step("THE SEED PACKET", "THE PACKET SAYS BASIL. BEAN SAYS OTHERWISE. THE PACKET IS PROBABLY RIGHT.",
                        va_goal("service", 1)),
                { title: "PLANT OR LEAVE", text: "THE SOIL IS READY. BEAN HAS ALREADY MOVED HER TAIL OUT OF THE WAY.",
                  choice: va_choice(
                    "PLANT THE ROW, OR LEAVE IT TO HER.",
                    "PLANT IT", "THE SOIL IS COLD. BEAN SUPERVISES FROM THE WARM END.",
                    "YOU PLANTED THE ROW.", va_goal("room", 60),
                    "LEAVE IT", "SHE ROLLS ONCE. THE ROW IS NOW A BED WITH A VIEW.",
                    "YOU LEFT THE ROW.", va_goal("sparkles", 2)) },
                va_step("A SPARE HANDLE", "SHE DIGS UP A TROWEL NO ONE HAS USED IN YEARS. THE HANDLE IS WARM.",
                        va_goal("room", 80))
            ],
            reward: va_reward("THE SPARE TROWEL", "A TROWEL THAT ALWAYS TURNS UP ONE MORE BED.",
                va_perk("garden_plot", 1, 0, -1, "THE ASH GARDEN GAINS ONE EXTRA BED."),
                va_perk("tap_treat", 8, 0, 1, "EVERY 8TH TAP IN THE CAT GARDEN LEAVES A TREAT."))
        },
        {
            kind: 0, idx: 2, title: "THE ROOF BELL",
            steps: [
                va_step("THE WIND", "THE ROOF IS LOUD TONIGHT. MARLOW IS SITTING ON THE NOISIEST PART OF IT.",
                        va_goal("room", 60)),
                va_step("THE BELL", "A SMALL BELL IS TIED TO THE RAILING. IT RINGS WHEN THE WIND CHANGES.",
                        va_goal("crits", 2)),
                { title: "TIE OR CUT", text: "THE BELL IS KEEPING THE WHOLE ROOF AWAKE. MARLOW HAS NOT BLINKED.",
                  choice: va_choice(
                    "TIE IT TIGHTER, OR CUT IT LOOSE.",
                    "TIE IT", "THE BELL GOES QUIET. MARLOW LOOKS AT THE RAILING ANYWAY.",
                    "YOU TIED THE BELL.", va_goal("buys", 3),
                    "CUT IT LOOSE", "THE WIND TAKES IT. FOR A MOMENT THE ROOF IS VERY QUIET.",
                    "YOU CUT IT LOOSE.", va_goal("service", 2)) },
                va_step("THE ROOF BELL", "SHE BRINGS YOU THE BELL. IT IS DENTED AND STILL WARM FROM THE SUN.",
                        va_goal("room", 100))
            ],
            reward: va_reward("THE ROOF BELL", "A BELL THAT RINGS ONLY WHEN THE WIND IS RIGHT.",
                va_perk("crit_treat", 1, 0, -1, "EVERY CRITICAL TAP LEAVES AN EXTRA TREAT."),
                va_perk("tap_treat", 10, 0, 2, "EVERY 10TH TAP ON THE ROOFTOP LEAVES A TREAT."))
        },
        {
            kind: 0, idx: 3, title: "THE CLOUD TRAY",
            steps: [
                va_step("THE TRAY", "PUFF IS ASLEEP ON THE SERVING TRAY. THE TRAY IS FLOATING. NOBODY IS SURPRISED.",
                        va_goal("room", 80)),
                va_step("THE ORDER", "A TABLE HAS ORDERED EVERYTHING. PUFF HAS ORDERED NOTHING AND IS STILL FIRST.",
                        va_goal("service", 2)),
                { title: "WAKE OR SERVE", text: "THE PLATES ARE GETTING COLD. PUFF IS GETTING WARMER.",
                  choice: va_choice(
                    "WAKE HER, OR SERVE AROUND HER.",
                    "WAKE HER", "SHE OPENS ONE EYE. THE TRAY LOWERS ITSELF.",
                    "YOU WOKE HER.", va_goal("journal", 1),
                    "SERVE AROUND", "THE PLATES GO OVER HER. SHE DOES NOT MOVE. THE TABLE APPLAUDS.",
                    "YOU SERVED AROUND HER.", va_goal("buys", 4)) },
                va_step("THE CLOUD TRAY", "SHE LEAVES THE TRAY ON THE COUNTER. IT IS LIGHTER THAN THE PLATES ON IT.",
                        va_goal("room", 120))
            ],
            reward: va_reward("THE CLOUD TRAY", "A TRAY THAT CARRIES ONE MORE THING THAN IT SHOULD.",
                va_perk("service_treat", 1, 0, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA TREAT."),
                va_perk("spark_treat", 1, 0, -1, "EVERY GOLD SPARKLE LEAVES AN EXTRA TREAT."))
        },
        {
            kind: 0, idx: 4, title: "THE TEA STRAINER",
            steps: [
                va_step("THE LEAVES", "THE TEA HAS STEEPED TOO LONG. SAFFRON IS WATCHING THE CUP AS IF IT OWED HER MONEY.",
                        va_goal("room", 100)),
                va_step("THE STRAINER", "THERE IS A STRAINER IN THE DRAWER. IT HAS NEVER BEEN USED. SAFFRON HAS OPINIONS.",
                        va_goal("journal", 2)),
                { title: "STRAIN OR SIP", text: "THE CUP IS DARK. SAFFRON IS PRETENDING SHE DOES NOT CARE EITHER WAY.",
                  choice: va_choice(
                    "STRAIN IT, OR DRINK IT AS IT IS.",
                    "STRAIN IT", "THE TEA IS CLEAR. SAFFRON DRINKS IT AND FALLS ASLEEP IN THE CUP.",
                    "YOU STRAINED IT.", va_goal("fest", 1),
                    "DRINK IT AS IT IS", "THE LEAVES STAY. SAFFRON CHEWS ONE THOUGHTFULLY.",
                    "YOU DRANK IT AS IT WAS.", va_goal("hollow", 1)) },
                va_step("THE TEA STRAINER", "SHE PUSHES THE STRAINER ACROSS THE TABLE. THERE IS A LEAF CAUGHT IN IT.",
                        va_goal("room", 150))
            ],
            reward: va_reward("THE TEA STRAINER", "A STRAINER THAT KEEPS THE LEAVES AND LOSES THE WAIT.",
                va_perk("festival_entry", 1, 0, -1, "EVERY FESTIVAL ENTRY COSTS ONE LESS MATERIAL."),
                va_perk("hall_nerve", 1, 0, -1, "THE LONG HALL STARTS WITH ONE EXTRA NERVE."))
        },
        {
            kind: 0, idx: 5, title: "THE BOOKMARK",
            steps: [
                va_step("THE SHELF", "THE LIBRARY HAS A SHELF NO ONE CAN REACH. STAR IS ON IT.",
                        va_goal("room", 120)),
                va_step("THE BLANK PAGE", "SHE HAS OPENED A BOOK TO A PAGE WITH NO WORDS. SHE IS READING IT VERY CAREFULLY.",
                        va_goal("night", 1)),
                { title: "CALL OR LEAVE", text: "THE LAMPS ARE LOW. STAR IS STILL ON THE SHELF WITH THE BOOK.",
                  choice: va_choice(
                    "ASK HER TO COME DOWN, OR LEAVE HER TO IT.",
                    "ASK HER DOWN", "SHE COMES DOWN ON THE THIRD ASK, CARRYING THE BOOK.",
                    "YOU ASKED HER DOWN.", va_goal("prestige", 1),
                    "LEAVE HER", "SHE STAYS UNTIL THE LAMPS GO OUT. THE PAGE IS STILL BLANK.",
                    "YOU LEFT HER TO IT.", va_goal("hollow", 2)) },
                va_step("THE BOOKMARK", "SHE LEAVES A STRIP OF DARK CLOTH IN THE BLANK PAGE. IT HOLDS THE PLACE.",
                        va_goal("room", 180))
            ],
            reward: va_reward("THE BOOKMARK", "A BOOKMARK THAT KEEPS A PAGE YOU HAVE NOT READ.",
                va_perk("night_nerve", 1, 0, -1, "THE NINTH TABLE STARTS WITH ONE EXTRA NERVE."),
                va_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."))
        },

        // ------------------------------------------------------- festivals
        {
            kind: 1, idx: 0, title: "THE PICNIC CLOTH",
            steps: [
                va_step("THE CLOTH", "SOMEONE HAS LAID A CLOTH ON THE GRASS. THE GRASS IS INDOORS. NOBODY IS EXPLAINING.",
                        va_goal("service", 1)),
                { title: "FOLD OR LIE", text: "THE CLOTH IS TOO BIG FOR THE TABLE AND TOO SMALL FOR THE FLOOR.",
                  choice: va_choice(
                    "FOLD IT, OR LET IT LIE.",
                    "FOLD IT", "THE CLOTH FITS THE BASKET EXACTLY. THE BASKET WAS NOT THERE BEFORE.",
                    "YOU FOLDED THE CLOTH.", va_goal("rank", 1),
                    "LET IT LIE", "THE PICNIC CONTINUES. A PIGEON JOINS. IT IS NOT INVITED.",
                    "YOU LET IT LIE.", va_goal("service", 2)) },
                va_step("THE PICNIC CLOTH", "THE CLOTH IS FOLDED ON YOUR PLATE. IT SMELLS OF CUT GRASS.",
                        undefined)
            ],
            reward: va_reward("THE PICNIC CLOTH", "A CLOTH THAT MAKES ANY FLOOR A PICNIC.",
                va_perk("spark_treat", 1, 0, -1, "EVERY GOLD SPARKLE LEAVES AN EXTRA TREAT."),
                va_perk("service_treat", 1, 0, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA TREAT."))
        },
        {
            kind: 1, idx: 1, title: "THE JAM SPOON",
            steps: [
                va_step("THE JAM", "THE JAM IS OPEN. EVERY CAT IN THE ROOM HAS A DIFFERENT OPINION ABOUT THAT.",
                        va_goal("service", 1)),
                { title: "SEAL OR SHARE", text: "THE SPOON IS STILL IN THE JAR. NOBODY WILL ADMIT TO PUTTING IT THERE.",
                  choice: va_choice(
                    "SEAL IT, OR SHARE IT.",
                    "SEAL IT", "THE LID GOES ON. THE ROOM GOES QUIET IN A DISAPPOINTED WAY.",
                    "YOU SEALED THE JAM.", va_goal("rank", 1),
                    "SHARE IT", "THERE IS ENOUGH FOR EVERYONE, INCLUDING THE ONE WHO ALREADY ATE.",
                    "YOU SHARED THE JAM.", va_goal("service", 2)) },
                va_step("THE JAM SPOON", "THE SPOON IS STICKY AND HAS BEEN LICKED CLEAN. IT IS STILL YOURS.",
                        undefined)
            ],
            reward: va_reward("THE JAM SPOON", "A SPOON THAT NEVER COMES OUT OF THE JAR EMPTY.",
                va_perk("service_treat", 1, 0, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA TREAT."),
                va_perk("tap_treat", 10, 0, 1, "EVERY 10TH TAP IN THE CAT GARDEN LEAVES A TREAT."))
        },
        {
            kind: 1, idx: 2, title: "THE EXTRA CHAIR",
            steps: [
                va_step("THE CHAIR", "THERE IS AN EXTRA CHAIR AT THE TABLE. NOBODY KNOWS WHO IT IS FOR. EVERYONE IS BEING POLITE.",
                        va_goal("service", 1)),
                { title: "SIT OR STAND", text: "THE MEAL IS GETTING COLD WHILE EVERYONE WAITS TO SEE WHO SITS FIRST.",
                  choice: va_choice(
                    "TAKE IT, OR LEAVE IT EMPTY.",
                    "TAKE IT", "YOU SIT. THE TABLE SHIFTS TO MAKE ROOM THAT WAS NOT THERE.",
                    "YOU TOOK THE CHAIR.", va_goal("rank", 1),
                    "LEAVE IT", "THE CHAIR STAYS EMPTY. THE MEAL IS STILL WARM WHEN YOU COME BACK.",
                    "YOU LEFT IT EMPTY.", va_goal("service", 2)) },
                va_step("THE EXTRA CHAIR", "THE CHAIR IS AT YOUR TABLE NOW. IT DOES NOT TAKE UP ANY ROOM.",
                        undefined)
            ],
            reward: va_reward("THE EXTRA CHAIR", "A CHAIR THAT ALWAYS HAS ROOM FOR ONE MORE.",
                va_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."),
                va_perk("service_treat", 1, 1, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA SCRAP."))
        },
        {
            kind: 1, idx: 3, title: "THE TASTING SPOON",
            steps: [
                va_step("THE ROUTE", "THE TOUR STARTS AT THE COUNTER AND ENDS AT THE COUNTER. THE MIDDLE IS THE INTERESTING PART.",
                        va_goal("service", 1)),
                { title: "LONG OR SHORT", text: "THERE ARE TWO ROUTES. BOTH END AT THE SAME PLACE. ONE TAKES LONGER.",
                  choice: va_choice(
                    "TAKE THE LONG ROUTE, OR THE SHORT ONE.",
                    "LONG ROUTE", "YOU PASS EVERY TABLE. EACH ONE OFFERS SOMETHING. YOU ACCEPT ALL OF IT.",
                    "YOU TOOK THE LONG ROUTE.", va_goal("rank", 1),
                    "SHORT ROUTE", "YOU ARRIVE FIRST. THE DISHES ARE STILL COMING. YOU WAIT.",
                    "YOU TOOK THE SHORT ROUTE.", va_goal("service", 2)) },
                va_step("THE TASTING SPOON", "THE SPOON HAS BEEN USED FOR EVERY DISH AND WASHED FOR NONE OF THEM.",
                        undefined)
            ],
            reward: va_reward("THE TASTING SPOON", "A SPOON THAT MAKES EVERY DISH WORTH TASTING TWICE.",
                va_perk("festival_entry", 1, 0, -1, "EVERY FESTIVAL ENTRY COSTS ONE LESS MATERIAL."),
                va_perk("crit_treat", 1, 0, -1, "EVERY CRITICAL TAP LEAVES AN EXTRA TREAT."))
        },
        {
            kind: 1, idx: 4, title: "THE PAIRING CARD",
            steps: [
                va_step("THE PAIR", "TWO DISHES HAVE BEEN PLACED TOGETHER. THEY ARE NOT SPEAKING.",
                        va_goal("service", 1)),
                { title: "SWAP OR STAY", text: "THE CARD SAYS THEY BELONG TOGETHER. THE PLATES DISAGREE.",
                  choice: va_choice(
                    "SWAP THEM, OR LEAVE THEM.",
                    "SWAP THEM", "THEY FIT BETTER THE OTHER WAY. NOBODY ADMITS IT.",
                    "YOU SWAPPED THEM.", va_goal("rank", 1),
                    "LEAVE THEM", "THEY EVENTUALLY BECOME FRIENDS. THE ROOM PRETENDS NOT TO WATCH.",
                    "YOU LEFT THEM.", va_goal("service", 2)) },
                va_step("THE PAIRING CARD", "THE CARD IS BLANK ON BOTH SIDES. IT STILL KNOWS WHAT GOES TOGETHER.",
                        undefined)
            ],
            reward: va_reward("THE PAIRING CARD", "A CARD THAT ALWAYS KNOWS WHAT TO PUT NEXT TO WHAT.",
                va_perk("crit_treat", 1, 0, -1, "EVERY CRITICAL TAP LEAVES AN EXTRA TREAT."),
                va_perk("service_treat", 1, 2, -1, "EVERY PERFECT COUNTER DISH LEAVES EXTRA DUST."))
        },
        {
            kind: 1, idx: 5, title: "THE MOON CUP",
            steps: [
                va_step("THE POUR", "THE CUP IS FULL. THE MOON IS NOT. SOMETHING ABOUT THAT IS WRONG.",
                        va_goal("service", 1)),
                { title: "DRINK OR POUR", text: "THE CUP IS HEAVY. THE MOON IS WAITING TO SEE WHAT YOU DO WITH IT.",
                  choice: va_choice(
                    "DRINK IT, OR POUR IT OUT.",
                    "DRINK IT", "THE ROOM TILTS. THE MOON STAYS WHERE IT IS.",
                    "YOU DRANK IT.", va_goal("rank", 1),
                    "POUR IT OUT", "THE FLOOR DRINKS IT. THE LIGHT GETS SLIGHTLY BETTER.",
                    "YOU POURED IT OUT.", va_goal("hollow", 1)) },
                va_step("THE MOON CUP", "THE CUP IS EMPTY AND COLD. THE MOON IS STILL IN THE WINDOW.",
                        undefined)
            ],
            reward: va_reward("THE MOON CUP", "A CUP THAT IS ALWAYS FULL WHEN THE ROOM IS DARK.",
                va_perk("night_nerve", 1, 0, -1, "THE NINTH TABLE STARTS WITH ONE EXTRA NERVE."),
                va_perk("service_treat", 1, 2, -1, "EVERY PERFECT COUNTER DISH LEAVES EXTRA DUST."))
        },
        {
            kind: 1, idx: 6, title: "THE NIGHT TOKEN",
            steps: [
                va_step("THE STALL", "THE STALL SELLS ONE THING AND WILL NOT SAY WHAT IT COSTS.",
                        va_goal("service", 1)),
                { title: "PAY OR WALK", text: "THE TOKEN IS ON THE COUNTER. THE STALL KEEPS ITS HAND OUT.",
                  choice: va_choice(
                    "PAY, OR WALK AWAY.",
                    "PAY", "THE TOKEN IS COLD. THE STALL KEEPS THE CHANGE.",
                    "YOU PAID.", va_goal("rank", 1),
                    "WALK AWAY", "THE STALL IS STILL THERE WHEN YOU LOOK BACK. IT HAS NOT MOVED.",
                    "YOU WALKED AWAY.", va_goal("hollow", 1)) },
                va_step("THE NIGHT TOKEN", "THE TOKEN IS IN YOUR POCKET. IT IS WARM NOW. IT WAS NOT BEFORE.",
                        undefined)
            ],
            reward: va_reward("THE NIGHT TOKEN", "A TOKEN THAT OPENS ONE DOOR AND CLOSES ANOTHER.",
                va_perk("hall_nerve", 1, 0, -1, "THE LONG HALL STARTS WITH ONE EXTRA NERVE."),
                va_perk("auto_treat", 1, 0, -1, "EVERY AUTOMATIC PET LEAVES A TREAT."))
        },
        {
            kind: 1, idx: 7, title: "THE HARVEST RIBBON",
            steps: [
                va_step("THE CRATE", "THE CRATE IS FULL. THE LABEL SAYS EMPTY. THE LABEL IS LYING.",
                        va_goal("service", 1)),
                { title: "OPEN OR SEAL", text: "THE CRATE HAS BEEN SEALED SINCE MORNING. SOMETHING INSIDE IS MOVING.",
                  choice: va_choice(
                    "OPEN IT, OR LEAVE IT SEALED.",
                    "OPEN IT", "THE CRATE IS FULL OF SMALLER CRATES. THIS IS CONSIDERED A GOOD HARVEST.",
                    "YOU OPENED IT.", va_goal("rank", 1),
                    "LEAVE IT", "THE CRATE SITS BY THE DOOR. THE ROOM SMELLS OF APPLES ANYWAY.",
                    "YOU LEFT IT SEALED.", va_goal("service", 2)) },
                va_step("THE HARVEST RIBBON", "THE RIBBON IS TIED AROUND NOTHING. IT STILL HOLDS ITS SHAPE.",
                        undefined)
            ],
            reward: va_reward("THE HARVEST RIBBON", "A RIBBON THAT MAKES EVERY CRATE FEEL FULL.",
                va_perk("garden_plot", 1, 0, -1, "THE ASH GARDEN GAINS ONE EXTRA BED."),
                va_perk("service_treat", 1, 1, -1, "EVERY PERFECT COUNTER DISH LEAVES AN EXTRA SCRAP."))
        },
        {
            kind: 1, idx: 8, title: "THE STAR NAPKIN",
            steps: [
                va_step("THE NAPKIN", "THE NAPKIN HAS BEEN FOLDED INTO A STAR. IT DOES NOT UNFOLD.",
                        va_goal("service", 1)),
                { title: "KEEP OR OPEN", text: "THE STAR SITS ON THE PLATE. IT IS TAKING UP MORE ROOM THAN IT SHOULD.",
                  choice: va_choice(
                    "KEEP IT FOLDED, OR TRY TO OPEN IT.",
                    "KEEP IT", "IT SITS ON THE PLATE ALL NIGHT. NOBODY USES IT.",
                    "YOU KEPT IT FOLDED.", va_goal("rank", 1),
                    "OPEN IT", "IT OPENS INTO A LONG PIECE OF CLOTH WITH NO END.",
                    "YOU OPENED IT.", va_goal("hollow", 1)) },
                va_step("THE STAR NAPKIN", "THE NAPKIN IS FOLDED AGAIN. YOU DID NOT SEE WHO DID IT.",
                        undefined)
            ],
            reward: va_reward("THE STAR NAPKIN", "A NAPKIN THAT IS ALWAYS FOLDED INTO SOMETHING ELSE.",
                va_perk("service_treat", 1, 2, -1, "EVERY PERFECT COUNTER DISH LEAVES EXTRA DUST."),
                va_perk("spark_treat", 1, 0, -1, "EVERY GOLD SPARKLE LEAVES AN EXTRA TREAT."))
        }
    ];
    return _d;
}
