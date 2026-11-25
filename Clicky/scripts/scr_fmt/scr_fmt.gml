/// @description number and time formatting — every visible number goes here

function fmt_number(_n) {
    // GML turns integers past 2^31 into int64, and is_real() says false for
    // those, so a big fish count used to print as "0". Cast first, then judge.
    if (!is_numeric(_n) || is_nan(_n)) return "0";
    _n = real(_n);
    if (_n < 0) return "-" + fmt_number(-_n);
    if (_n < 1000) return string(floor(_n));

    var _suf = ["K", "M", "B", "T", "aa", "ab", "ac", "ad"];
    var _i = 0;
    var _v = _n;
    while (_v >= 1000 && _i < array_length(_suf)) {
        _v /= 1000;
        _i++;
    }
    var _txt = (_v < 10)
        ? string_format(_v, 1, 1)
        : string(floor(_v));
    // _i counts divisions, so the suffix is one behind it: 8420 -> "8.4K"
    return _txt + _suf[_i - 1];
}

/// For numbers under ten where "0" would be a lie: rates per item, odds.
function fmt_small(_n) {
    if (!is_numeric(_n) || is_nan(_n)) return "0";
    _n = real(_n);
    if (abs(_n) >= 10) return fmt_number(_n);
    return string_format(_n, 1, 1);
}

function fmt_rate(_n) {
    if (_n <= 0) return "0/s";
    return (_n < 1 ? fmt_small(_n) : fmt_number(_n)) + "/s";
}

function fmt_time(_sec) {
    _sec = floor(_sec);
    if (_sec < 60) return string(_sec) + "s";
    if (_sec < 3600) return string(floor(_sec / 60)) + "m";
    if (_sec < 86400) return string(floor(_sec / 3600)) + "h";
    return string(floor(_sec / 86400)) + "d";
}
