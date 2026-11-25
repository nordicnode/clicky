/// @description sound helpers with pitch variation, and the one music loop

function sfx(_snd, _pitch) {
    if (global.G.settings.mute_sfx) return -1;
    if (_pitch == undefined) _pitch = 1;
    var _i = audio_play_sound(_snd, 50, false);
    audio_sound_pitch(_i, _pitch + random_range(-0.02, 0.02));
    return _i;
}

/// taps climb a pentatonic scale with the combo, so a fast run sounds musical
function sfx_tap() {
    var _scale = [snd_pop1, snd_pop2, snd_pop3, snd_pop4, snd_pop5];
    sfx(_scale[global.combo mod 5], 1 + min(global.combo, 24) * 0.015);
}

function sfx_crit() { sfx(snd_crit, 1); }
function sfx_buy()  { sfx(snd_buy, 1); }

// ---------------------------------------------------------------- music
/// One looping track, one instance, and a volume that follows two things:
/// the mute setting and whether a card is open. Ducking is the difference
/// between a soundtrack and a nuisance while a kid reads.
function music_init() {
    global.music_id  = -1;
    global.music_old = -1;       // the outgoing track during a crossfade
    global.music_fade = 1;       // 0..1, new track fading in
    global.music_track = "cafe";
    global.music_vol = 0.5;
    global.music_duck = 1;
}

function music_snd(_track) {
    return (_track == "hollow") ? snd_music_hollow : snd_music_cafe;
}

function music_start() {
    if (global.music_id >= 0 && audio_is_playing(global.music_id)) return;
    global.music_track = veil_active() ? "hollow" : "cafe";
    global.music_id = audio_play_sound(music_snd(global.music_track), 20, true);
    audio_sound_gain(global.music_id, 0, 0);
    global.music_old = -1;
    global.music_fade = 0;
    music_apply_gain(0);
}

/// Crossfade to the other room's score. The outgoing track keeps playing for
/// about half a second, so entering the Hollow is a change of air, not a cut.
function music_switch(_track) {
    if (global.music_old >= 0) audio_stop_sound(global.music_old);
    if (global.music_id >= 0) global.music_old = global.music_id;
    global.music_track = _track;
    global.music_id = audio_play_sound(music_snd(_track), 20, true);
    audio_sound_gain(global.music_id, 0, 0);
    global.music_fade = 0;
}

function music_apply_gain(_dt) {
    if (global.music_id < 0) return;

    // The Hollow has its own score. This check is here, not in the Hollow UI,
    // so every path in and out (door, save, wake, omen) gets the same fade.
    var _want_track = veil_active() ? "hollow" : "cafe";
    if (_want_track != global.music_track) music_switch(_want_track);

    var _want = global.music_vol;
    if (global.G.settings.mute_music) _want = 0;
    // a card on screen means the player is reading, so step back
    var _modal = ui_card_open() || instance_exists(obj_toast);
    var _target = _want * (_modal ? 0.3 : 1);

    global.music_duck = lerp(global.music_duck, _target, 0.06);
    global.music_fade = min(1, global.music_fade + 0.025);
    audio_sound_gain(global.music_id, global.music_duck * global.music_fade, 0);
    if (global.music_old >= 0) {
        audio_sound_gain(global.music_old, global.music_duck * (1 - global.music_fade), 0);
        if (global.music_fade >= 1) {
            audio_stop_sound(global.music_old);
            global.music_old = -1;
        }
    }
}

/// Called when the mute setting changes so it takes effect in the same frame.
function music_refresh() {
    if (global.music_id < 0) {
        if (!global.G.settings.mute_music) music_start();
        return;
    }
    music_apply_gain(0);
}

function sfx_milestone() { sfx(snd_milestone, 1); }
function sfx_frenzy()    { sfx(snd_frenzy, 1); }
