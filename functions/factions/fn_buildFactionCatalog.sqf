/*
    Builds a normalized, merged catalog for one side from selected faction
    classnames plus optional individual CfgVehicles additions. Returns an empty
    `factions` field when validation fails.
*/

params [
    ["_requestedFactions", [], [[]]],
    ["_expectedSide", -1, [0]],
    ["_extraClasses", [], [[]]]
];

private _empty = createHashMapFromArray [
    ["factions", []],
    ["side", _expectedSide],
    ["units", []],
    ["groups", []],
    ["infantryGroups", []],
    ["atGroups", []],
    ["aaGroups", []],
    ["reconGroups", []],
    ["paraGroups", []],
    ["allVehicles", []],
    ["light", []],
    ["recon", []],
    ["medical", []],
    ["groundLogistics", []],
    ["artillery", []],
    ["atgm", []],
    ["aa", []],
    ["samTel", []],
    ["samRadar", []],
    ["samShorad", []],
    ["aaGun", []],
    ["heavy", []],
    ["rotaryLogistics", []],
    ["rotaryCas", []],
    ["fixedWing", []],
    ["static", []],
    ["transport", []],
    ["boat", []],
    ["crates", []],
    ["containers", []]
];

if (_requestedFactions isEqualTo [] || {!(_expectedSide in [0, 1, 2, 3])}) exitWith {_empty};

private _index = [] call KPLIB_fnc_buildFactionIndex;
private _metaIndex = _index get "factions";
private _vehicleIndex = _index get "vehicles";
private _groupIndex = _index get "groups";
private _validFactions = [];

{
    if !(_x isEqualType "") then {continue};
    private _key = toLower _x;
    if !(_key in _metaIndex) then {
        [format ["Automatic faction '%1' does not exist in CfgFactionClasses", _x], "FACTIONS"] call KPLIB_fnc_log;
        continue;
    };

    private _meta = _metaIndex get _key;
    if ((_meta get "side") != _expectedSide) then {
        [format ["Automatic faction '%1' has side %2, expected %3", _x, _meta get "side", _expectedSide], "FACTIONS"] call KPLIB_fnc_log;
        continue;
    };

    _validFactions pushBackUnique (_meta get "class");
} forEach _requestedFactions;

if (_validFactions isEqualTo []) exitWith {_empty};

// Explicit additions may come from any faction or side. Keep the cached index
// unchanged so an addition to one side cannot leak into another side's catalog.
private _validExtras = [];
{
    if !(_x isEqualType "") then {
        [format ["Automatic faction addition %1 for side %2 must be a classname string; skipped", _x, _expectedSide], "FACTIONS"] call KPLIB_fnc_log;
        continue;
    };
    if (([_x] call KPLIB_fnc_classifyFactionVehicle) isEqualTo []) then {
        [format ["Automatic faction addition '%1' for side %2 is missing, hidden or unsupported; skipped", _x, _expectedSide], "FACTIONS"] call KPLIB_fnc_log;
        continue;
    };
    _validExtras pushBackUnique (configName (configFile >> "CfgVehicles" >> _x));
} forEach _extraClasses;
private _classSources = _validFactions apply {_vehicleIndex getOrDefault [toLower _x, []]};
_classSources pushBack _validExtras;

private _pools = createHashMap;
{
    _pools set [_x, []];
} forEach [
    "allVehicles", "light", "recon", "medical", "groundLogistics",
    "artillery", "atgm", "aa", "samTel", "samRadar", "samShorad", "aaGun", "heavy", "rotaryLogistics",
    "rotaryCas", "fixedWing", "static", "transport", "boat", "crates",
    "containers"
];

private _units = [];
private _groups = [];
private _infantryGroups = [];
private _atGroups = [];
private _aaGroups = [];
private _reconGroups = [];
private _paraGroups = [];

{
    {
        private _class = _x;
        private _categories = [_class] call KPLIB_fnc_classifyFactionVehicle;
        if ("infantry" in _categories) then {
            _units pushBackUnique _class;
        } else {
            if (!("crate" in _categories) && {!("container" in _categories)}) then {
                private _all = _pools get "allVehicles";
                _all pushBackUnique _class;
                _pools set ["allVehicles", _all];
            };

            {
                private _poolName = switch (_x) do {
                    case "crate": {"crates"};
                    case "container": {"containers"};
                    default {_x};
                };
                if (_poolName in _pools) then {
                    private _pool = _pools get _poolName;
                    _pool pushBackUnique _class;
                    _pools set [_poolName, _pool];
                };
            } forEach _categories;
        };
    } forEach _x;
} forEach _classSources;

{
    private _factionKey = toLower _x;
    {
        private _groupCfg = _x;
        private _groupUnits = [];
        {
            private _unitClass = getText (_x >> "vehicle");
            if (_unitClass != "" && {_unitClass in _units}) then {
                _groupUnits pushBack _unitClass;
            };
        } forEach ("isClass _x" configClasses _groupCfg);

        if (_groupUnits isEqualTo []) then {continue};
        _groups pushBack _groupUnits;

        private _label = toLower format ["%1 %2", configName _groupCfg, getText (_groupCfg >> "name")];
        if ((_label find "recon") >= 0 || {(_label find "spec") >= 0} || {(_label find "sniper") >= 0}) then {
            _reconGroups pushBack _groupUnits;
        } else {
            if ((_label find "para") >= 0 || {(_label find "airborne") >= 0}) then {
                _paraGroups pushBack _groupUnits;
            } else {
                if ((_label find "anti-air") >= 0 || {(_label find "_aa") >= 0} || {(_label find " aa") >= 0}) then {
                    _aaGroups pushBack _groupUnits;
                } else {
                    if ((_label find "anti-tank") >= 0 || {(_label find "_at") >= 0} || {(_label find " at") >= 0}) then {
                        _atGroups pushBack _groupUnits;
                    } else {
                        _infantryGroups pushBack _groupUnits;
                    };
                };
            };
        };
    } forEach (_groupIndex getOrDefault [_factionKey, []]);
} forEach _validFactions;

if (_units isEqualTo [] && {_expectedSide != 3}) exitWith {
    [format ["Automatic factions %1 contain no public infantry; catalog rejected", _validFactions], "FACTIONS"] call KPLIB_fnc_log;
    _empty
};

_units sort true;
{
    private _pool = _pools get _x;
    _pool sort true;
    _empty set [_x, _pool];
} forEach keys _pools;

_empty set ["factions", _validFactions];
_empty set ["units", _units];
_empty set ["groups", _groups];
_empty set ["infantryGroups", _infantryGroups];
_empty set ["atGroups", _atGroups];
_empty set ["aaGroups", _aaGroups];
_empty set ["reconGroups", _reconGroups];
_empty set ["paraGroups", _paraGroups];

[format [
    "Automatic catalog %1: units=%2 vehicles=%3 groups=%4 crates=%5",
    _validFactions,
    count _units,
    count (_empty get "allVehicles"),
    count _groups,
    count (_empty get "crates")
], "FACTIONS"] call KPLIB_fnc_log;

_empty
