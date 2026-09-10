/* Consistent mission scroll-menu text. Keep action behavior and category colours.
   Legacy localized labels may include boundary dashes or all-capital lettering. */
params [["_label", "", [""]], ["_color", "#FFFFFF", [""]]];
private _chars = toArray _label;
while {_chars isNotEqualTo [] && {(_chars # 0) in [9, 10, 13, 32, 45]}} do {_chars deleteAt 0};
while {_chars isNotEqualTo [] && {(_chars # (count _chars - 1)) in [9, 10, 13, 32, 45]}} do {_chars deleteAt (count _chars - 1)};
private _words = (toLower (toString _chars)) splitString " ";
private _acronyms = ["fob", "pb", "ai", "gps", "ace", "hq", "nato", "csat"];
_words = _words apply {
    if (_x in _acronyms) then {toUpper _x} else {
        switch (_x) do {
            case "zeus": {"Zeus"};
            case "frontline": {"Frontline"};
            case "liberation": {"Liberation"};
            default {_x};
        }
    }
};
private _text = _words joinString " ";
if (_text != "") then {_text = toUpper (_text select [0, 1]) + (_text select [1])};
private _escaped = "";
{
    _escaped = _escaped + (switch (_x) do {
        case 38: {"&amp;"};
        case 60: {"&lt;"};
        case 62: {"&gt;"};
        default {toString [_x]};
    });
} forEach toArray _text;
format ["<t size='1' color='%1'>%2</t>", _color, _escaped]
