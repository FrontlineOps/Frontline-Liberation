/*
    Server-owned strategic minefield construction.

    This module extends the existing strategic decision pass. It does not own
    a scheduler, materializer, or save: funded task forces and logistics own
    those contracts.
*/

BATTLESPACE_MINEFIELDS_GET_OPERATIONS_FOR_SECTOR = {
    params ["_sector"];
    private _operations = [];
    {
        if (
            (_y getOrDefault ["kind", ""]) == "MINEFIELD"
            && {(_y getOrDefault ["targetSector", ""]) == _sector}
        ) then {
            _operations pushBack _x;
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _operations
};

BATTLESPACE_MINEFIELDS_SECTOR_IS_QUIET = {
    params ["_sector", "_state"];
    if (_sector in (missionNamespace getVariable ["active_sectors", []])) exitWith {false};

    private _quietTime = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MINEFIELD_QUIET_TIME", 600];
    if ((CBA_missionTime - (_state getOrDefault ["lastOwnerChange", CBA_missionTime])) < _quietTime) exitWith {false};
    private _lastCasualtyAt = _state getOrDefault ["lastCasualtyAt", -1];
    if (_lastCasualtyAt >= 0 && {(CBA_missionTime - _lastCasualtyAt) < _quietTime}) exitWith {false};

    private _origin = getMarkerPos _sector;
    private _exclusionRadius = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MINEFIELD_PLAYER_EXCLUSION_RADIUS", 2500];
    (allPlayers findIf {
        isPlayer _x
        && {alive _x}
        && {side group _x == GRLIB_side_friendly}
        && {_x distance2D _origin < _exclusionRadius}
    }) < 0
};

BATTLESPACE_MINEFIELDS_FIND_SITE = {
    params ["_sector"];
    private _origin = getMarkerPos _sector;
    private _frontline = [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_traverseGraphAndFindFirstBluforSector;
    private _frontDirection = random 360;
    if (!isNil "_frontline" && {_frontline != ""} && {_frontline != _sector}) then {
        _frontDirection = _origin getDir (getMarkerPos _frontline);
    };

    private _reserved = [_sector] call BATTLESPACE_FORTIFICATION_GET_RESERVED_POSITIONS;
    private _site = [];
    for "_attempt" from 1 to 12 do {
        if (_site isNotEqualTo []) exitWith {};
        private _direction = _frontDirection - 25 + random 50;
        private _distance = 260 + random 220;
        private _candidate = _origin getPos [_distance, _direction];
        if (count _candidate == 2) then {_candidate pushBack 0};
        _candidate set [2, 0];
        if (surfaceIsWater _candidate) then {continue};
        if ((_reserved findIf {(_candidate distance2D _x) < 150}) >= 0) then {continue};
        _site = [_candidate, _direction];
    };
    _site
};

BATTLESPACE_MINEFIELDS_BUILD = {
    params ["_sector"];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {false};

    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {false};
    if (CBA_missionTime < (_state getOrDefault ["nextMinefieldAt", 0])) exitWith {false};
    if !([_sector, _state] call BATTLESPACE_MINEFIELDS_SECTOR_IS_QUIET) exitWith {false};

    private _globalCap = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_MINEFIELDS", 36];
    if (["MINEFIELD"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= _globalCap) exitWith {false};
    private _perSectorCap = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_MINEFIELDS_PER_SECTOR", 1];
    if (count ([_sector] call BATTLESPACE_MINEFIELDS_GET_OPERATIONS_FOR_SECTOR) >= _perSectorCap) exitWith {false};

    private _frontDepth = [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
    private _maxFrontDepth = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MINEFIELD_MAX_FRONT_DEPTH", 1];
    if (_frontDepth < 0 || {_frontDepth > _maxFrontDepth}) exitWith {false};

    private _constructionCost = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MINEFIELD_CONSTRUCTION_COST", 6];
    private _sectorType = _state getOrDefault ["type", ""];
    private _resources = _state getOrDefault ["resources", createHashMap];
    private _threshold = ([_sectorType, "Fortification"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP) getOrDefault ["construction_supplies", -1];
    private _capacity = [_sectorType, "construction_supplies"] call BATTLESPACE_SECTOR_GET_CAPACITY;
    private _minimumStock = _constructionCost max (ceil (_capacity * _threshold));
    if (_constructionCost <= 0 || {_threshold < 0} || {(_resources getOrDefault ["construction_supplies", 0]) < _minimumStock}) exitWith {false};

    private _site = [_sector] call BATTLESPACE_MINEFIELDS_FIND_SITE;
    if (_site isEqualTo []) exitWith {
        [format ["No valid strategic minefield site found for %1", _sector], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };
    _site params ["_position", "_direction"];

    private _mineCount = round (((missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MINEFIELD_MINE_COUNT", 24]) max 1) min 120);
    private _atRatio = ((missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MINEFIELD_AT_RATIO", 0.25]) max 0) min 1;
    private _columns = 6 min _mineCount;
    private _rows = ceil (_mineCount / _columns);
    private _spacing = 12;
    private _structures = [];
    private _antiTankMines = 0;
    private _antiTankTarget = round (_mineCount * _atRatio);
    for "_i" from 0 to (_mineCount - 1) do {
        private _row = floor (_i / _columns);
        private _column = _i mod _columns;
        private _forward = (_row - ((_rows - 1) / 2)) * _spacing;
        private _right = (_column - ((_columns - 1) / 2)) * _spacing;
        private _minePosition = [
            (_position#0) + (_forward * sin _direction) + (_right * cos _direction),
            (_position#1) + (_forward * cos _direction) - (_right * sin _direction),
            0
        ];
        private _isAntiTank = floor (((_i + 1) * _antiTankTarget) / _mineCount) > floor ((_i * _antiTankTarget) / _mineCount);
        if (_isAntiTank) then {_antiTankMines = _antiTankMines + 1};
        _structures pushBack (createHashMapFromArray [
            ["position", _minePosition],
            ["rotation", _direction],
            ["className", ["APERSMine", "ATMine"] select _isAntiTank]
        ]);
    };

    private _composition = createHashMapFromArray [
        ["manpower", 0],
        ["vehicles", []],
        ["structures", _structures]
    ];
    private _taskForceId = [
        "Minefield",
        _composition,
        _position,
        [],
        getMarkerPos _sector,
        _sector,
        "MINEFIELD",
        createHashMapFromArray [
            ["phase", "BUILT"],
            ["assignedSector", _sector],
            ["targetSector", _sector],
            ["pressureSector", _sector],
            ["sitePosition", _position],
            ["siteDirection", _direction],
            ["mineCount", _mineCount],
            ["antiTankMines", _antiTankMines],
            ["constructionCost", _constructionCost]
        ],
        createHashMapFromArray [["construction_supplies", _constructionCost]]
    ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_taskForceId == "") exitWith {false};

    private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceId;
    if (!isNil "_taskForce") then {
        _taskForce set [12, _sector];
        BATTLESPACE_TASK_FORCES set [_taskForceId, _taskForce];
    };
    _state = BATTLESPACE_SECTOR_STATES get _sector;
    _state set ["nextMinefieldAt", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MINEFIELD_COOLDOWN", 3600])];
    BATTLESPACE_SECTOR_STATES set [_sector, _state];
    [] call BATTLESPACE_LOGISTICS_SAVE;
    [format ["Built paid persistent minefield %1 with %2 mines at %3 for %4", _taskForceId, _mineCount, _position, _sector]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_MINEFIELDS_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    private _globalRemaining = (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_MINEFIELDS", 36])
        - (["MINEFIELD"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS);
    private _remaining = _globalRemaining min (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_MINEFIELDS_PER_TICK", 1]);
    if (_remaining <= 0) exitWith {};

    private _sectorNames = keys BATTLESPACE_SECTOR_STATES;
    _sectorNames sort true;
    private _candidates = [];
    {
        private _sector = _x;
        private _sectorRank = _forEachIndex;
        private _state = BATTLESPACE_SECTOR_STATES get _sector;
        if ((_state getOrDefault ["owner", ""]) != "OPFOR") then {continue};
        if (CBA_missionTime < (_state getOrDefault ["nextMinefieldAt", 0])) then {continue};
        if (count ([_sector] call BATTLESPACE_MINEFIELDS_GET_OPERATIONS_FOR_SECTOR) >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_MINEFIELDS_PER_SECTOR", 1])) then {continue};
        if !([_sector, _state] call BATTLESPACE_MINEFIELDS_SECTOR_IS_QUIET) then {continue};

        private _depth = [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
        if (_depth < 0 || {_depth > (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MINEFIELD_MAX_FRONT_DEPTH", 1])}) then {continue};
        private _cost = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MINEFIELD_CONSTRUCTION_COST", 6];
        private _type = _state getOrDefault ["type", ""];
        private _capacity = [_type, "construction_supplies"] call BATTLESPACE_SECTOR_GET_CAPACITY;
        private _threshold = ([_type, "Fortification"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP) getOrDefault ["construction_supplies", -1];
        private _available = (_state getOrDefault ["resources", createHashMap]) getOrDefault ["construction_supplies", 0];
        if (_cost <= 0 || {_threshold < 0} || {_available < (_cost max (ceil (_capacity * _threshold)))}) then {continue};

        private _pressure = ((_state getOrDefault ["casualtyPressure", 0]) max 0) min 999;
        private _score = (_depth * 1000000) - (_pressure * 1000) + (_sectorRank / 10000);
        _candidates pushBack [_score, _sector];
    } forEach _sectorNames;

    _candidates = [_candidates, [], {_x#0}, "ASCEND"] call BIS_fnc_sortBy;
    {
        if (_remaining <= 0) exitWith {};
        if ([_x#1] call BATTLESPACE_MINEFIELDS_BUILD) then {_remaining = _remaining - 1};
    } forEach _candidates;
};

BATTLESPACE_MINEFIELDS_REFRESH_ACTIVE_COOLDOWNS = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    private _quietUntil = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MINEFIELD_QUIET_TIME", 600]);
    {
        private _state = BATTLESPACE_SECTOR_STATES get _x;
        if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) then {continue};
        if ((_state getOrDefault ["nextMinefieldAt", 0]) < _quietUntil) then {
            _state set ["nextMinefieldAt", _quietUntil];
            BATTLESPACE_SECTOR_STATES set [_x, _state];
        };
    } forEach (missionNamespace getVariable ["active_sectors", []]);
};

BATTLESPACE_MINEFIELDS_RETIRE_LEGACY = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {0};
    private _legacy = [];
    {
        if ((_y param [0, ""]) == "Minefield" && {isNil {BATTLESPACE_STRATEGIC_OPERATIONS get _x}}) then {
            _legacy pushBack _x;
        };
    } forEach BATTLESPACE_TASK_FORCES;

    {
        private _taskForce = BATTLESPACE_TASK_FORCES get _x;
        BATTLESPACE_TASK_FORCE_PATHS deleteAt _x;
        [_x] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
        BATTLESPACE_TASK_FORCES deleteAt _x;
        if (!isNil "_taskForce") then {[_taskForce] call BATTLESPACE_STRATEGIC_RETIRE_PHYSICAL_FORCE};
    } forEach _legacy;
    if (_legacy isNotEqualTo []) then {
        [format ["Retired %1 legacy unfunded minefield task forces", count _legacy], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        [] call BATTLESPACE_LOGISTICS_SAVE;
    };
    count _legacy
};
