/* Picks the best deterministic unit match for a Liberation role. */

params [
    ["_units", [], [[]]],
    ["_role", "rifleman", [""]]
];

if (_units isEqualTo []) exitWith {""};

private _roleLower = toLower _role;
private _needles = switch (_roleLower) do {
    case "officer": {["officer", "commander", "_co"]};
    case "squadleader": {["squad leader", "squadleader", "_sl", "sergeant"]};
    case "teamleader": {["team leader", "teamleader", "_tl"]};
    case "medic": {["medic", "corpsman", "paramedic"]};
    case "engineer": {["engineer", "repair", "sapper", "demo"]};
    case "rto": {["rto", "radio", "jtac", "fac"]};
    case "grenadier": {["grenadier", "_gl", "rif_grenadier"]};
    case "machinegunner": {["machine gun", "machinegun", "_mg", "autorifleman", "_ar"]};
    case "heavygunner": {["heavy gun", "heavygun", "hmg", "gunner"]};
    case "marksman": {["marksman", "sharpshooter"]};
    case "sniper": {["sniper"]};
    case "at": {["anti-tank", "antitank", "_hat", "_at", "missile"]};
    case "aa": {["anti-air", "antiair", "_aa"]};
    case "paratrooper": {["para", "airborne"]};
    case "crew": {["crew", "driver"]};
    case "pilot": {["pilot", "aviator"]};
    default {["rifleman", "soldier", "rif"]};
};

private _best = "";
private _bestScore = -1;

{
    private _class = _x;
    private _cfg = configFile >> "CfgVehicles" >> _class;
    private _text = toLower format ["%1 %2 %3", _class, getText (_cfg >> "displayName"), getText (_cfg >> "icon")];
    private _score = 0;

    {
        if ((_text find _x) >= 0) then {_score = _score + 4};
    } forEach _needles;

    switch (_roleLower) do {
        case "medic": {if (getNumber (_cfg >> "attendant") > 0) then {_score = _score + 20}};
        case "engineer": {
            if (getNumber (_cfg >> "engineer") > 0) then {_score = _score + 20};
            if (getNumber (_cfg >> "canDeactivateMines") > 0) then {_score = _score + 10};
        };
        case "rto": {if (getNumber (_cfg >> "uavHacker") > 0) then {_score = _score + 4}};
        case "officer": {if (getNumber (_cfg >> "cost") > 100000) then {_score = _score + 1}};
    };

    if (_score > _bestScore) then {
        _bestScore = _score;
        _best = _class;
    };
} forEach _units;

_best
