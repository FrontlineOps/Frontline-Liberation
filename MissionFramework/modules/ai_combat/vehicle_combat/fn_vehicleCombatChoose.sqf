/* Score only available rounds. No ammo names, faction lists or invented penetration. */
params ["_vehicle", "_target", "_profiles", ["_previous", ""]];
private _range = _vehicle distance _target;
private _armor = _target isKindOf "Tank" || {_target isKindOf "Wheeled_APC_F"};
private _heavy = _target isKindOf "Tank" && {getNumber (configOf _target >> "transportSoldier") == 0};
private _man = _target isKindOf "CAManBase";
private _best = createHashMap;
private _score = -1;
{
    private _p = _x;
    if (_range < _p get "minimum" || {_range > _p get "range"}) then {continue};
    private _kind = _p get "kind";
    private _rank = 0;
    if (_armor) then {
        _rank = switch (_kind) do {
            case "AP": {if (_heavy && {_p get "caliber" < 10}) then {15} else {90}};
            case "HEAT": {85};
            case "ATGM": {if (_heavy) then {95} else {75}};
            default {-1};
        };
    } else {
        _rank = switch (_kind) do {
            case "MG": {if (_man) then {95} else {50}};
            case "HE": {90};
            case "HEAT": {60};
            case "AP": {if (_man) then {-1} else {65}};
            case "ATGM": {if (_man) then {-1} else {30}};
            default {-1};
        };
    };
    if (_rank < 0) then {continue};
    // Keep a suitable loaded feed; a distinctly better role still wins.
    if (_p get "magazine" == _previous) then {_rank = _rank + 3};
    if (_rank > _score) then {
        _best = _p;
        _score = _rank;
    };
} forEach _profiles;
_best
