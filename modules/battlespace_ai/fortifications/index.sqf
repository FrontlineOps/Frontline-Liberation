/*
    Server-owned dynamic objective construction.

    This module extends the existing strategic decision pass. It does not own
    a scheduler, materializer, or save: funded task forces and logistics own
    those contracts.
*/

BATTLESPACE_FORTIFICATION_GET_OPERATIONS_FOR_SECTOR = {
    params ["_sector"];
    private _operations = [];
    {
        if (
            (_y getOrDefault ["kind", ""]) == "FORTIFICATION"
            && {(_y getOrDefault ["targetSector", ""]) == _sector}
        ) then {
            _operations pushBack _x;
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _operations
};

BATTLESPACE_FORTIFICATION_GET_NEXT_TIER = {
    params ["_sector"];
    private _tiers = [];
    {
        private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _x;
        if (!isNil "_operation") then {
            private _tier = _operation getOrDefault ["fortificationTier", 0];
            if (_tier > 0) then {_tiers pushBackUnique _tier};
        };
    } forEach ([_sector] call BATTLESPACE_FORTIFICATION_GET_OPERATIONS_FOR_SECTOR);
    private _nextTier = 0;
    for "_tier" from 1 to (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_FORTIFICATIONS_PER_SECTOR", 3]) do {
        if !(_tier in _tiers) exitWith {_nextTier = _tier};
    };
    _nextTier
};

BATTLESPACE_FORTIFICATION_GET_RESERVED_POSITIONS = {
    params ["_sector"];
    private _positions = [getMarkerPos _sector];
    {
        if !((_y getOrDefault ["kind", ""]) in ["DEFENDER", "FORTIFICATION", "MINEFIELD"]) then {continue};
        if (
            (_y getOrDefault ["fundingSector", ""]) != _sector
            && {(_y getOrDefault ["targetSector", ""]) != _sector}
        ) then {continue};
        private _taskForce = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_taskForce") then {continue};
        if !((_taskForce param [0, ""]) in ["Fortifications", "Outpost", "Garrison", "Minefield"]) then {continue};
        private _position = _taskForce param [1, []];
        if (_position isEqualType [] && {count _position >= 2}) then {_positions pushBackUnique _position};
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _positions
};

BATTLESPACE_FORTIFICATION_FIND_SITE = {
    params ["_sector", "_tier"];
    private _origin = getMarkerPos _sector;
    private _frontline = [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_traverseGraphAndFindFirstBluforSector;
    private _frontDirection = random 360;
    if (!isNil "_frontline" && {_frontline != ""} && {_frontline != _sector}) then {
        _frontDirection = _origin getDir (getMarkerPos _frontline);
    };

    private _rings = [[180, 450], [300, 650], [450, 850]];
    private _ring = _rings param [(_tier - 1) max 0 min 2, [180, 450]];
    private _reserved = [_sector] call BATTLESPACE_FORTIFICATION_GET_RESERVED_POSITIONS;
    private _site = [];

    for "_attempt" from 1 to 24 do {
        if (_site isNotEqualTo []) exitWith {};
        private _direction = _frontDirection - 60 + random 120;
        private _distance = (_ring#0) + random ((_ring#1) - (_ring#0));
        private _candidate = _origin getPos [_distance, _direction];

        if (_tier == 1) then {
            private _nearestRoad = objNull;
            private _nearestDistance = 1e12;
            {
                private _roadDistance = _candidate distance2D (getPos _x);
                if (_roadDistance < _nearestDistance) then {
                    _nearestDistance = _roadDistance;
                    _nearestRoad = _x;
                };
            } forEach (_candidate nearRoads 120);
            if (!isNull _nearestRoad) then {
                _candidate = getPosATL _nearestRoad;
                private _connected = roadsConnectedTo _nearestRoad;
                if (_connected isNotEqualTo []) then {
                    _direction = (getPos _nearestRoad) getDir (getPos (_connected#0));
                };
            };
        };

        if (count _candidate == 2) then {_candidate pushBack 0};
        _candidate set [2, 0];
        if (surfaceIsWater _candidate) then {continue};
        if ((_reserved findIf {(_candidate distance2D _x) < 150}) >= 0) then {continue};
        _site = [_candidate, _direction];
    };
    _site
};

BATTLESPACE_FORTIFICATION_GET_STATIC_CLASSES = {
    private _classes = missionNamespace getVariable ["BATTLESPACE_DEFENDERS_STATIC_CLASSES", []];
    (_classes select {
        _x isEqualType ""
        && {_x != ""}
        && {isClass (configFile >> "CfgVehicles" >> _x)}
        && {_x isKindOf "StaticWeapon"}
        && {([_x] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS) == "car"}
    }) arrayIntersect _classes
};

BATTLESPACE_FORTIFICATION_BUILD_DEFINITION = {
    params ["_sector", "_tier"];
    private _site = [_sector, _tier] call BATTLESPACE_FORTIFICATION_FIND_SITE;
    if (_site isEqualTo []) exitWith {createHashMap};
    _site params ["_position", "_direction"];

    private _structures = [];
    private _resolveClass = {
        params ["_candidates"];
        (_candidates select {isClass (configFile >> "CfgVehicles" >> _x)}) param [0, ""]
    };
    private _addStructure = {
        params ["_candidates", "_offset", ["_relativeDirection", 0]];
        private _class = [_candidates] call _resolveClass;
        if (_class == "") exitWith {};
        _offset params ["_forward", "_right"];
        private _worldPosition = [
            (_position#0) + (_forward * sin _direction) + (_right * cos _direction),
            (_position#1) + (_forward * cos _direction) - (_right * sin _direction),
            0
        ];
        _structures pushBack (createHashMapFromArray [
            ["position", _worldPosition],
            ["rotation", (_direction + _relativeDirection) mod 360],
            ["className", _class]
        ]);
    };

    private _barrier = ["Land_HBarrier_3_F", "Land_BagFence_Long_F"];
    private _fence = ["Land_BagFence_Long_F", "Land_HBarrier_3_F"];
    private _smallBunker = ["Land_BagBunker_01_small_green_F", "Land_BagBunker_Small_F"];
    private _largeBunker = ["Land_BagBunker_01_large_green_F", "Land_BagBunker_Large_F"];

    switch (_tier) do {
        case 1: {
            [_barrier, [0, -7], 90] call _addStructure;
            [_barrier, [0, 7], 90] call _addStructure;
            [_fence, [5, -4], 0] call _addStructure;
            [_fence, [5, 4], 0] call _addStructure;
            [_smallBunker, [8, 0], 0] call _addStructure;
        };
        case 2: {
            [_smallBunker, [-4, 0], 0] call _addStructure;
            [_barrier, [0, -8], 90] call _addStructure;
            [_barrier, [0, 8], 90] call _addStructure;
            [_fence, [5, -5], 0] call _addStructure;
            [_fence, [5, 5], 0] call _addStructure;
        };
        default {
            [_largeBunker, [-5, 0], 0] call _addStructure;
            [_barrier, [2, -11], 90] call _addStructure;
            [_barrier, [2, 11], 90] call _addStructure;
            [_fence, [8, -7], 0] call _addStructure;
            [_fence, [8, 7], 0] call _addStructure;
            [_barrier, [-9, -8], 90] call _addStructure;
            [_barrier, [-9, 8], 90] call _addStructure;
        };
    };

    private _staticClasses = [] call BATTLESPACE_FORTIFICATION_GET_STATIC_CLASSES;
    private _staticCount = [0, 1, 2] param [(_tier - 1) max 0 min 2, 0];
    private _staticOffsets = if (_tier == 2) then {[[3, 0]]} else {[[3, -7], [3, 7]]};
    for "_i" from 0 to (_staticCount - 1) do {
        if (_staticClasses isEqualTo []) exitWith {};
        [[selectRandom _staticClasses], _staticOffsets param [_i, [3, 0]], 0] call _addStructure;
    };

    if (_structures isEqualTo []) exitWith {createHashMap};
    private _siteKind = ["ROADBLOCK", "EMPLACEMENT", "HARDENED OUTPOST"] param [(_tier - 1) max 0 min 2, "ROADBLOCK"];
    private _manpowerByTier = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_FORTIFICATION_MANPOWER_BY_TIER", [4, 5, 7]];
    private _assignedManpower = floor ((_manpowerByTier param [(_tier - 1) max 0 min 2, 0]) max 0);
    createHashMapFromArray [
        ["type", ["Fortifications", "Fortifications", "Outpost"] param [(_tier - 1) max 0 min 2, "Fortifications"]],
        ["siteKind", _siteKind],
        ["position", _position],
        ["direction", _direction],
        ["composition", createHashMapFromArray [
            ["manpower", _assignedManpower],
            ["structureCrewFromManpower", true],
            ["vehicles", []],
            ["structures", _structures]
        ]]
    ]
};

BATTLESPACE_FORTIFICATION_DISPATCH = {
    params ["_sector"];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {false};
    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {false};
    if (CBA_missionTime < (_state getOrDefault ["nextFortificationAt", 0])) exitWith {false};

    private _globalCap = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_FORTIFICATIONS", 48];
    if (["FORTIFICATION"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= _globalCap) exitWith {false};
    private _operations = [_sector] call BATTLESPACE_FORTIFICATION_GET_OPERATIONS_FOR_SECTOR;
    private _perSectorCap = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_FORTIFICATIONS_PER_SECTOR", 3];
    if (count _operations >= _perSectorCap) exitWith {false};

    private _tier = [_sector] call BATTLESPACE_FORTIFICATION_GET_NEXT_TIER;
    if (_tier <= 0) exitWith {false};
    private _costs = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_FORTIFICATION_COSTS", [4, 7, 12]];
    private _constructionCost = _costs param [_tier - 1, -1];
    if (_constructionCost <= 0) exitWith {false};
    private _sectorType = _state getOrDefault ["type", ""];
    private _resources = _state getOrDefault ["resources", createHashMap];
    private _threshold = ([_sectorType, "Fortification"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP) getOrDefault ["construction_supplies", -1];
    private _capacity = [_sector, "construction_supplies", _sectorType] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
    private _minimumStock = _constructionCost max (ceil (_capacity * _threshold));
    if (_threshold < 0 || {(_resources getOrDefault ["construction_supplies", 0]) < _minimumStock}) exitWith {false};

    private _definition = [_sector, _tier] call BATTLESPACE_FORTIFICATION_BUILD_DEFINITION;
    if (count _definition == 0) exitWith {
        [format ["No valid dynamic fortification site found for %1 tier %2", _sector, _tier], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };
    private _position = _definition get "position";
    private _siteKind = _definition get "siteKind";
    private _taskForceId = [
        _definition get "type",
        _definition get "composition",
        _position,
        [],
        getMarkerPos _sector,
        _sector,
        "FORTIFICATION",
        createHashMapFromArray [
            ["phase", format ["BUILT T%1 %2", _tier, _siteKind]],
            ["targetSector", _sector],
            ["pressureSector", _sector],
            ["fortificationTier", _tier],
            ["siteKind", _siteKind],
            ["assignedManpower", (_definition get "composition") getOrDefault ["manpower", 0]],
            ["sitePosition", _position],
            ["siteDirection", _definition get "direction"]
        ],
        createHashMapFromArray [["construction_supplies", _constructionCost]]
    ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_taskForceId == "") exitWith {false};

    _state = BATTLESPACE_SECTOR_STATES get _sector;
    _state set ["nextFortificationAt", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_FORTIFICATION_COOLDOWN", 1800])];
    BATTLESPACE_SECTOR_STATES set [_sector, _state];
    [] call BATTLESPACE_LOGISTICS_SAVE;
    [format ["Constructed %1 %2 for %3 at %4", _siteKind, _taskForceId, _sector, _position]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_FORTIFICATION_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    private _globalRemaining = (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_FORTIFICATIONS", 48])
        - (["FORTIFICATION"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS);
    private _remaining = _globalRemaining min (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_FORTIFICATIONS_PER_TICK", 2]);
    if (_remaining <= 0) exitWith {};

    private _sectorNames = keys BATTLESPACE_SECTOR_STATES;
    _sectorNames sort true;
    private _candidates = [];
    {
        private _sector = _x;
        private _sectorRank = _forEachIndex;
        private _state = BATTLESPACE_SECTOR_STATES get _sector;
        if ((_state getOrDefault ["owner", ""]) != "OPFOR") then {continue};
        if (CBA_missionTime < (_state getOrDefault ["nextFortificationAt", 0])) then {continue};
        private _siteCount = count ([_sector] call BATTLESPACE_FORTIFICATION_GET_OPERATIONS_FOR_SECTOR);
        if (_siteCount >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_FORTIFICATIONS_PER_SECTOR", 3])) then {continue};
        private _tier = [_sector] call BATTLESPACE_FORTIFICATION_GET_NEXT_TIER;
        private _costs = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_FORTIFICATION_COSTS", [4, 7, 12]];
        private _cost = _costs param [_tier - 1, -1];
        private _type = _state getOrDefault ["type", ""];
        private _capacity = [_sector, "construction_supplies", _type] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        private _threshold = ([_type, "Fortification"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP) getOrDefault ["construction_supplies", -1];
        private _available = (_state getOrDefault ["resources", createHashMap]) getOrDefault ["construction_supplies", 0];
        if (_tier <= 0 || {_cost <= 0} || {_threshold < 0} || {_available < (_cost max (ceil (_capacity * _threshold)))}) then {continue};

        private _depth = [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
        if (_depth < 0) then {_depth = 999};
        private _pressure = ((_state getOrDefault ["casualtyPressure", 0]) max 0) min 999;
        private _score = (_depth * 1000000) - (_pressure * 1000) + (_siteCount * 10) + (_sectorRank / 10000);
        _candidates pushBack [_score, _sector];
    } forEach _sectorNames;

    _candidates = [_candidates, [], {_x#0}, "ASCEND"] call BIS_fnc_sortBy;
    {
        if (_remaining <= 0) exitWith {};
        if ([_x#1] call BATTLESPACE_FORTIFICATION_DISPATCH) then {_remaining = _remaining - 1};
    } forEach _candidates;
};
