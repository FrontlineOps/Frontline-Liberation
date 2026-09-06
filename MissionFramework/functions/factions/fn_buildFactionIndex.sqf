/*
    Builds and caches the public CfgVehicles/CfgGroups faction index used by
    automatic presets. The expensive CfgVehicles walk runs once per machine.
*/

params [
    ["_force", false, [false]]
];

if (!_force && {!isNil "KPLIB_autoFactionIndex"}) exitWith {
    KPLIB_autoFactionIndex
};

private _started = diag_tickTime;
private _factionMeta = createHashMap;
private _vehiclesByFaction = createHashMap;
private _groupsByFaction = createHashMap;

{
    private _cfg = _x;
    if !(isClass _cfg) then {continue};

    private _class = configName _cfg;
    private _side = if (isNumber (_cfg >> "side")) then {getNumber (_cfg >> "side")} else {-1};
    if !(_side in [0, 1, 2, 3]) then {_side = -1};

    private _displayName = getText (_cfg >> "displayName");
    if (_displayName isEqualTo "") then {_displayName = _class};

    _factionMeta set [toLower _class, createHashMapFromArray [
        ["class", _class],
        ["displayName", _displayName],
        ["side", _side]
    ]];
} forEach ("isClass _x" configClasses (configFile >> "CfgFactionClasses"));

{
    private _cfg = _x;
    if (getNumber (_cfg >> "scope") < 2) then {continue};

    private _faction = toLower (getText (_cfg >> "faction"));
    if (_faction isEqualTo "" || {!(_faction in _factionMeta)}) then {continue};

    private _meta = _factionMeta get _faction;
    private _expectedSide = _meta get "side";
    private _classSide = getNumber (_cfg >> "side");
    if (_expectedSide < 0 && {_classSide in [0, 1, 2, 3]} && {(configName _cfg) isKindOf "Man"}) then {
        _meta set ["side", _classSide];
        _factionMeta set [_faction, _meta];
        _expectedSide = _classSide;
    };
    if (_expectedSide >= 0 && {_classSide != _expectedSide}) then {continue};

    private _bucket = _vehiclesByFaction getOrDefault [_faction, []];
    _bucket pushBackUnique (configName _cfg);
    _vehiclesByFaction set [_faction, _bucket];
} forEach ("isClass _x" configClasses (configFile >> "CfgVehicles"));

{
    _x params ["_sideName", "_sideId"];
    private _sideRoot = configFile >> "CfgGroups" >> _sideName;
    if !(isClass _sideRoot) then {continue};

    {
        private _factionRoot = _x;
        private _faction = toLower (configName _factionRoot);
        if !(_faction in _factionMeta) then {continue};
        private _meta = _factionMeta get _faction;
        if ((_meta get "side") < 0) then {
            _meta set ["side", _sideId];
            _factionMeta set [_faction, _meta];
        };
        if ((_meta get "side") != _sideId) then {continue};

        private _bucket = [];
        {
            private _category = _x;
            if !(isClass _category) then {continue};

            {
                if (isClass _x) then {
                    _bucket pushBack _x;
                };
            } forEach ("isClass _x" configClasses _category);
        } forEach ("isClass _x" configClasses _factionRoot);

        _groupsByFaction set [_faction, _bucket];
    } forEach ("isClass _x" configClasses _sideRoot);
} forEach [["East", 0], ["West", 1], ["Indep", 2], ["Civilian", 3]];

KPLIB_autoFactionIndex = createHashMapFromArray [
    ["factions", _factionMeta],
    ["vehicles", _vehiclesByFaction],
    ["groups", _groupsByFaction]
];

[format [
    "Automatic faction index built: factions=%1 vehicleBuckets=%2 groupBuckets=%3 timeMs=%4",
    count _factionMeta,
    count _vehiclesByFaction,
    count _groupsByFaction,
    round ((diag_tickTime - _started) * 1000)
], "FACTIONS"] call KPLIB_fnc_log;

KPLIB_autoFactionIndex
