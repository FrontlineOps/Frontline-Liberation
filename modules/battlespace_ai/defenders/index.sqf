/*
    Resource-backed defensive operations.

    Sector activation owns ambient civilians only. Military defenders are paid
    task forces formed at a reachable OPFOR source by the strategic decision
    loop, then routed to one explicit assignment. Ready mobile reserves are
    formed before contact and may be retasked by casualty pressure.
*/

BATTLESPACE_DEFENSE_GET_FRONT_DEPTH = {
    params ["_sector"];
    if (isNil "NETWORKED_SECTORS_LINKED" || {!NETWORKED_SECTORS_LINKED}) exitWith {69};
    [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE
};

BATTLESPACE_DEFENSE_GRAPH_DISTANCE = {
    params ["_origin", "_target", ["_maximum", 99]];
    if (_origin == _target) exitWith {0};
    private _originNode = NETWORKED_SECTORS get _origin;
    if (isNil "_originNode") exitWith {-1};

    private _open = [[_origin, 0]];
    private _visited = createHashMapFromArray [[_origin, true]];
    private _result = -1;
    while {_open isNotEqualTo [] && {_result < 0}} do {
        private _entry = _open deleteAt 0;
        _entry params ["_sector", "_distance"];
        if (_distance >= _maximum) then {continue};
        private _node = NETWORKED_SECTORS get _sector;
        if (isNil "_node") then {continue};
        {
            if (_x in blufor_sectors || {_visited getOrDefault [_x, false]}) then {continue};
            if (_x == _target) exitWith {_result = _distance + 1};
            _visited set [_x, true];
            _open pushBack [_x, _distance + 1];
        } forEach (_node getOrDefault ["Links", []]);
    };
    _result
};

BATTLESPACE_DEFENSE_SECTOR_COOLDOWN_ELAPSED = {
    params ["_sector", "_state"];
    private _quietTime = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEFENDER_QUIET_TIME", 300];
    if (CBA_missionTime - (_state getOrDefault ["lastOwnerChange", 0]) < _quietTime) exitWith {false};
    if (CBA_missionTime - (_state getOrDefault ["lastCasualtyAt", -1e9]) < _quietTime) exitWith {false};
    true
};

BATTLESPACE_DEFENSE_SOURCE_IS_AVAILABLE = {
    params ["_sector", "_state"];
    if (_sector in (missionNamespace getVariable ["active_sectors", []])) exitWith {false};
    [_sector, _state] call BATTLESPACE_DEFENSE_SECTOR_COOLDOWN_ELAPSED
};

BATTLESPACE_DEFENSE_COUNT_ROLE = {
    params ["_role", ["_targetSector", ""]];
    private _count = 0;
    {
        if ((_y getOrDefault ["kind", ""]) != "DEFENDER") then {continue};
        if ((_y getOrDefault ["defenseRole", ""]) != _role) then {continue};
        if ((_y getOrDefault ["phase", ""]) == "RETURNING") then {continue};
        if (_targetSector != "" && {(_y getOrDefault ["assignedSector", ""]) != _targetSector}) then {continue};
        _count = _count + 1;
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _count
};

BATTLESPACE_DEFENSE_COUNT_AT_SECTOR = {
    params ["_targetSector"];
    private _count = 0;
    {
        if (
            (_y getOrDefault ["kind", ""]) == "DEFENDER"
            && {(_y getOrDefault ["assignedSector", ""]) == _targetSector}
            && {(_y getOrDefault ["phase", ""]) != "RETURNING"}
        ) then {_count = _count + 1};
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _count
};

BATTLESPACE_DEFENSE_FIND_SOURCE = {
    params ["_targetSector", "_manpowerCost"];
    private _targetDepth = [_targetSector] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
    private _reserveRatio = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEFENDER_SOURCE_RESERVE_RATIO", 0.4];
    private _candidates = [];
    {
        private _source = _x;
        if (_source == _targetSector || {(_y getOrDefault ["owner", ""]) != "OPFOR"}) then {continue};
        if !([_source, _y] call BATTLESPACE_DEFENSE_SOURCE_IS_AVAILABLE) then {continue};
        private _sourceDepth = [_source] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
        if (_sourceDepth <= _targetDepth) then {continue};
        private _distance = [_source, _targetSector, 12] call BATTLESPACE_DEFENSE_GRAPH_DISTANCE;
        if (_distance < 0) then {continue};

        private _resources = _y getOrDefault ["resources", createHashMap];
        private _capacity = [_source, "manpower"] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        private _retained = ceil (_capacity * _reserveRatio);
        if ((_resources getOrDefault ["manpower", 0]) - _manpowerCost < _retained) then {continue};
        private _militaryPenalty = [500, 0] select ((_y getOrDefault ["type", ""]) == "military");
        _candidates pushBack [(_distance * 100) + _militaryPenalty - _sourceDepth, _source];
    } forEach BATTLESPACE_SECTOR_STATES;
    _candidates = [_candidates, [], {_x param [0, 0]}, "ASCEND"] call BIS_fnc_sortBy;
    if (_candidates isEqualTo []) then {""} else {(_candidates select 0) param [1, ""]}
};

BATTLESPACE_DEFENSE_PICK_PATROL_VEHICLE = {
    params ["_sourceSector"];
    private _chance = 0 max BATTLESPACE_STRATEGIC_DEFENSIVE_PATROL_VEHICLE_CHANCE min 1;
    if (random 1 >= _chance) exitWith {""};

    private _state = BATTLESPACE_SECTOR_STATES get _sourceSector;
    private _stock = _state getOrDefault ["resources", createHashMap];
    private _ratio = BATTLESPACE_STRATEGIC_DEFENDER_SOURCE_RESERVE_RATIO;
    private _candidates = (BATTLESPACE_RESOURCE_CLASS_POOLS getOrDefault ["car", []]) select {
        private _class = _x;
        private _categories = [_class] call KPLIB_fnc_classifyFactionVehicle;
        private _resource = [_class] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS;
        _class isKindOf "Car" && {!(_class isKindOf "Wheeled_APC_F")} && {!(_class isKindOf "Truck_F")}
        && {(_categories arrayIntersect ["heavy", "artillery", "aa", "atgm", "groundLogistics", "medical"]) isEqualTo []}
        && {_resource != ""} && {
            private _capacity = [_sourceSector, _resource] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
            (_stock getOrDefault [_resource, 0]) - 1 >= ceil (_capacity * _ratio)
        }
    };
    if (_candidates isEqualTo []) then {""} else {selectRandom _candidates}
};

BATTLESPACE_DEFENSE_DISPATCH_ROLE = {
    params ["_targetSector", "_roleDefinition"];
    _roleDefinition params ["_role", "_model", "_manpower", "_roleCap", "_maximumDepth", "_sectorTypes", ["_tourRange", [0, 0]]];
    if ([_role, _targetSector] call BATTLESPACE_DEFENSE_COUNT_ROLE > 0) exitWith {false};
    if ([_role] call BATTLESPACE_DEFENSE_COUNT_ROLE >= _roleCap) exitWith {false};

    private _sourceSector = [_targetSector, _manpower] call BATTLESPACE_DEFENSE_FIND_SOURCE;
    if (_sourceSector == "") exitWith {false};
    private _modelDefinition = BATTLESPACE_TASK_FORCE_MODELS get _model;
    if (isNil "_modelDefinition") exitWith {
        [format ["Defender role %1 references unknown task-force model %2", _role, _model], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };
    if !("buildAssignment" in _modelDefinition) exitWith {
        [format ["Defender model %1 has no assignment builder", _model], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };
    private _buildAssignment = _modelDefinition get "buildAssignment";
    private _targetPosition = [_targetSector] call _buildAssignment;
    if !(_targetPosition isEqualType [] && {(count _targetPosition) in [2, 3]}) exitWith {
        [format ["Defender model %1 returned an invalid assignment for %2", _model, _targetSector], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };
    _targetPosition set [2, 0];
    private _tourMinimum = (_tourRange param [0, 0]) max 0;
    private _tourMaximum = (_tourRange param [1, _tourMinimum]) max _tourMinimum;
    private _tourDuration = if (_tourMaximum <= 0) then {0} else {_tourMinimum + random (_tourMaximum - _tourMinimum)};
    private _composition = createHashMapFromArray [
        ["manpower", _manpower],
        ["vehicles", []],
        ["structures", []]
    ];
    if (_role == "DEFENSIVE_PATROL") then {
        private _vehicle = [_sourceSector] call BATTLESPACE_DEFENSE_PICK_PATROL_VEHICLE;
        if (_vehicle != "") then {_composition set ["vehicles", [_vehicle]]};
    };
    private _arguments = [
        _model,
        _composition,
        getMarkerPos _sourceSector,
        _targetPosition,
        getMarkerPos _targetSector,
        _sourceSector,
        "DEFENDER",
        createHashMapFromArray [
            ["phase", "DEPLOYING"],
            ["defenseRole", _role],
            ["assignedSector", _targetSector],
            ["targetSector", _targetSector],
            ["targetPosition", _targetPosition],
            ["pressureSector", _targetSector],
            ["tourDuration", _tourDuration]
        ]
    ];
    private _taskForceId = _arguments call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_taskForceId == "" && {(_composition get "vehicles") isNotEqualTo []}) then {
        [format ["Defensive patrol vehicle formation failed at %1; retrying the funded infantry patrol", _sourceSector]] call BATTLESPACE_STRATEGIC_LOG;
        _composition set ["vehicles", []];
        _taskForceId = _arguments call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    };
    if (_taskForceId == "") exitWith {false};
    (BATTLESPACE_TASK_FORCES get _taskForceId) set [12, _targetSector];
    [format [
        "Formed defender %1 (%2/%3) at %4 and assigned it to %5 (vehicles=%6)",
        _taskForceId,
        _role,
        _model,
        _sourceSector,
        _targetSector,
        _composition get "vehicles"
    ]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_RESERVE_BUILD_DEFINITION = {
    params ["_sourceSector"];
    private _empty = createHashMap;
    private _state = BATTLESPACE_SECTOR_STATES get _sourceSector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {_empty};
    private _resources = _state getOrDefault ["resources", createHashMap];
    private _ratio = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESERVE_SOURCE_RATIO", 0.5];
    private _manpower = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESERVE_MANPOWER", 14];
    private _manpowerCapacity = [_sourceSector, "manpower"] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
    if ((_resources getOrDefault ["manpower", 0]) - _manpower < ceil (_manpowerCapacity * _ratio)) exitWith {_empty};

    private _vehicles = [];
    {
        private _class = [_x] call BATTLESPACE_STRATEGIC_GET_CLASS_FOR_RESOURCE;
        if (_class == "") then {continue};
        // Generated pools may overlap. Validate the class against the resource
        // that the funded constructor will actually debit, not just this pool.
        private _resource = [_class] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS;
        private _capacity = [_sourceSector, _resource] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        private _available = _resources getOrDefault [_resource, 0];
        if (
            _resource != ""
            && {_capacity > 0}
            && {_available - 1 >= ceil (_capacity * _ratio)}
        ) exitWith {_vehicles pushBack _class};
    } forEach ["ifv", "apc", "car"];
    if (_vehicles isEqualTo []) exitWith {_empty};
    createHashMapFromArray [["manpower", _manpower], ["vehicles", _vehicles], ["structures", []]]
};

BATTLESPACE_RESERVE_GET_STAGING_CANDIDATES = {
    params [["_excludeId", ""], ["_fromSector", ""]];
    private _minimumDepth = BATTLESPACE_STRATEGIC_RESERVE_MIN_FRONT_DEPTH max 1;
    private _maximumDepth = BATTLESPACE_STRATEGIC_RESERVE_MAX_FRONT_DEPTH max _minimumDepth;
    private _candidates = [];
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR") then {continue};
        if !([_x, _y] call BATTLESPACE_DEFENSE_SECTOR_COOLDOWN_ELAPSED) then {continue};
        private _depth = [_x] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
        if (_depth < _minimumDepth || {_depth > _maximumDepth}) then {continue};
        private _stagingSector = _x;
        if (_fromSector != "" && {[_fromSector, _stagingSector, 99] call BATTLESPACE_DEFENSE_GRAPH_DISTANCE < 0}) then {continue};
        private _alreadyStaged = false;
        private _nearbyReserves = 0;
        {
            if (_x == _excludeId || {(_y getOrDefault ["kind", ""]) != "RESERVE"}) then {continue};
            private _home = _y getOrDefault ["assignedSector", ""];
            if (_home == _stagingSector) exitWith {_alreadyStaged = true};
            if ([_stagingSector, _home, 1] call BATTLESPACE_DEFENSE_GRAPH_DISTANCE >= 0) then {_nearbyReserves = _nearbyReserves + 1};
        } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
        if (_alreadyStaged) then {continue};
        _candidates pushBack [(_depth * 10000) + (_nearbyReserves * 100) + random 5, _stagingSector];
    } forEach BATTLESPACE_SECTOR_STATES;
    [_candidates, [], {_x select 0}, "ASCEND"] call BIS_fnc_sortBy
};

BATTLESPACE_RESERVE_FORM = {
    if (["RESERVE"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= BATTLESPACE_STRATEGIC_MAX_ACTIVE_RESERVES) exitWith {false};
    private _sources = [];
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR") then {continue};
        if !([_x, _y] call BATTLESPACE_DEFENSE_SOURCE_IS_AVAILABLE) then {continue};
        private _depth = [_x] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
        if (_depth < 1 || {_depth >= 69}) then {continue};
        private _definition = [_x] call BATTLESPACE_RESERVE_BUILD_DEFINITION;
        if (count _definition > 0) then {_sources pushBack [_x, _definition]};
    } forEach BATTLESPACE_SECTOR_STATES;
    private _formed = false;
    {
        private _stagingSector = _x select 1;
        private _fundingCandidates = [];
        {
            private _distance = [_x select 0, _stagingSector, 12] call BATTLESPACE_DEFENSE_GRAPH_DISTANCE;
            if (_distance >= 0) then {_fundingCandidates pushBack [_distance, _x]};
        } forEach _sources;
        _fundingCandidates = [_fundingCandidates, [], {_x select 0}, "ASCEND"] call BIS_fnc_sortBy;
        {
            (_x select 1) params ["_sourceSector", "_composition"];
            private _stagingPosition = getMarkerPos _stagingSector;
            private _phase = ["STAGING", "READY"] select (_sourceSector == _stagingSector);
            private _taskForceId = [
                "Mobile Reserve", _composition, getMarkerPos _sourceSector,
                [[], _stagingPosition] select (_phase == "STAGING"), _stagingPosition, _sourceSector, "RESERVE",
                createHashMapFromArray [["phase", _phase], ["defenseRole", "MOBILE_RESERVE"], ["assignedSector", _stagingSector], ["targetSector", ""], ["pressureSector", ""]]
            ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
            if (_taskForceId != "") exitWith {
                (BATTLESPACE_TASK_FORCES get _taskForceId) set [12, _stagingSector];
                [format ["Formed mobile reserve %1 at %2 for staging at %3 (frontDepth=%4, phase=%5)", _taskForceId, _sourceSector, _stagingSector, [_stagingSector] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH, _phase]] call BATTLESPACE_STRATEGIC_LOG;
                _formed = true;
            };
        } forEach _fundingCandidates;
        if (_formed) exitWith {};
    } forEach ([] call BATTLESPACE_RESERVE_GET_STAGING_CANDIDATES);
    _formed
};

BATTLESPACE_RESERVE_RESTAGE_READY = {
    private _restaged = 0;
    {
        if ((_y getOrDefault ["kind", ""]) != "RESERVE" || {(_y getOrDefault ["phase", ""]) != "READY"}) then {continue};
        private _operation = _y;
        private _home = _operation getOrDefault ["assignedSector", ""];
        private _depth = [_home] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
        if (_depth >= (BATTLESPACE_STRATEGIC_RESERVE_MIN_FRONT_DEPTH max 1) && {_depth <= BATTLESPACE_STRATEGIC_RESERVE_MAX_FRONT_DEPTH}) then {continue};
        private _taskForce = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_taskForce") then {continue};
        private _location = _taskForce param [1, []];
        private _currentSector = [_location] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
        if (_currentSector == "") then {continue};
        private _candidates = [_x, _currentSector] call BATTLESPACE_RESERVE_GET_STAGING_CANDIDATES;
        if (_candidates isEqualTo []) then {continue};
        private _stagingSector = (_candidates select 0) select 1;
        private _destination = getMarkerPos _stagingSector;
        _operation set ["phase", "STAGING"];
        _operation set ["assignedSector", _stagingSector];
        _operation set ["targetSector", ""];
        _operation set ["pressureSector", ""];
        _operation deleteAt "demobilizeOnReturn";
        _taskForce set [2, _destination];
        _taskForce set [10, _destination];
        _taskForce set [12, _stagingSector];
        BATTLESPACE_TASK_FORCE_PATHS deleteAt _x;
        {
            [_x, true, true] call KPLIB_fnc_taskReset;
            _x setVariable ["BATTLESPACE_DEFENDER_RETURNING", false];
        } forEach (_taskForce param [4, []]);
        [_x, _location, _destination] call QUEUE_PATHFIND_REQUEST;
        [format ["Restaging existing mobile reserve %1 from %2 to %3 (frontDepth=%4); no new force or debit", _x, _home, _stagingSector, [_stagingSector] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH]] call BATTLESPACE_STRATEGIC_LOG;
        _restaged = _restaged + 1;
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _restaged
};

BATTLESPACE_RESERVE_DISPATCH = {
    params ["_targetSector"];
    private _targetState = BATTLESPACE_SECTOR_STATES get _targetSector;
    if (isNil "_targetState" || {(_targetState getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {false};
    // Keep current-format responses exclusive while also respecting a legacy
    // ground reinforcement that may still be present in an unversioned save.
    private _blockedKinds = ["REINFORCEMENT", "AIRBORNE_TRANSPORT", "AIRBORNE_REINFORCEMENT", "BATTLEGROUP"];
    if (_blockedKinds findIf {[_x, _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET} >= 0) exitWith {false};
    private _alreadyResponding = false;
    {
        if (
            (_y getOrDefault ["kind", ""]) == "RESERVE"
            && {(_y getOrDefault ["targetSector", ""]) == _targetSector}
            && {(_y getOrDefault ["phase", ""]) in ["RESPONDING", "HOLDING"]}
        ) exitWith {_alreadyResponding = true};
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    if (_alreadyResponding) exitWith {false};

    private _maximumHops = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESERVE_RESPONSE_MAX_HOPS", 5];
    private _candidates = [];
    {
        if ((_y getOrDefault ["kind", ""]) != "RESERVE" || {(_y getOrDefault ["phase", ""]) != "READY"}) then {continue};
        private _taskForce = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_taskForce") then {continue};
        private _composition = _taskForce param [3, createHashMap];
        private _minimumManpower = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESERVE_MINIMUM_MANPOWER", 8];
        if (
            (_composition getOrDefault ["manpower", 0]) < _minimumManpower
            || {(_composition getOrDefault ["vehicles", []]) isEqualTo []}
        ) then {continue};
        private _homeSector = _y getOrDefault ["assignedSector", _y getOrDefault ["originSector", ""]];
        private _homeState = BATTLESPACE_SECTOR_STATES get _homeSector;
        if (_homeSector == "" || {isNil "_homeState"} || {(_homeState getOrDefault ["owner", ""]) != "OPFOR"}) then {continue};
        private _distance = [_homeSector, _targetSector, _maximumHops] call BATTLESPACE_DEFENSE_GRAPH_DISTANCE;
        if (_distance < 0 || {_distance > _maximumHops}) then {continue};
        _candidates pushBack [_distance, (_taskForce param [1, []]) distance2D (getMarkerPos _targetSector), _x];
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _candidates = [_candidates, [], {(_x param [0, 99]) * 100000 + (_x param [1, 1e9])}, "ASCEND"] call BIS_fnc_sortBy;
    if (_candidates isEqualTo []) exitWith {false};

    private _taskForceId = (_candidates select 0) param [2, ""];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceId;
    if (isNil "_operation" || {isNil "_taskForce"}) exitWith {false};
    private _destination = getMarkerPos _targetSector;
    _operation set ["phase", "RESPONDING"];
    _operation set ["targetSector", _targetSector];
    _operation set ["pressureSector", _targetSector];
    _operation deleteAt "holdUntil";
    _taskForce set [2, _destination];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceId;
    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
    BATTLESPACE_TASK_FORCES set [_taskForceId, _taskForce];
    {
        if (isNull _x) then {continue};
        [_x, true, true] call KPLIB_fnc_taskReset;
        _x setVariable ["BATTLESPACE_DEFENDER_RETURNING", false];
    } forEach (_taskForce param [4, []]);
    [_taskForceId, _taskForce param [1, []], _destination] call QUEUE_PATHFIND_REQUEST;
    [format ["Dispatched ready mobile reserve %1 from %2 to casualty response at %3", _taskForceId, _operation getOrDefault ["assignedSector", ""], _targetSector]] call BATTLESPACE_STRATEGIC_LOG;
    [] call BATTLESPACE_LOGISTICS_SAVE;
    true
};

BATTLESPACE_DEFENSE_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};

    private _reservesRestaged = [] call BATTLESPACE_RESERVE_RESTAGE_READY;
    private _reservesFormed = 0;
    private _reserveLimit = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_RESERVES_PER_TICK", 1];
    while {
        _reservesFormed < _reserveLimit
        && {["RESERVE"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS < (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_RESERVES", 3])}
    } do {
        if !([] call BATTLESPACE_RESERVE_FORM) exitWith {};
        _reservesFormed = _reservesFormed + 1;
    };

    private _maxActive = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_DEFENDERS", 24];
    private _activeDefenders = ["DEFENDER"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS;
    private _formationLimit = (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_DEFENDERS_PER_TICK", 2]) min ((_maxActive - _activeDefenders) max 0);
    private _candidates = [];
    private _roles = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEFENDER_ROLES", []];
    {
        private _targetSector = _x;
        if ((_y getOrDefault ["owner", ""]) != "OPFOR") then {continue};
        if !([_targetSector, _y] call BATTLESPACE_DEFENSE_SECTOR_COOLDOWN_ELAPSED) then {continue};

        private _depth = [_targetSector] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
        private _assignedCount = [_targetSector] call BATTLESPACE_DEFENSE_COUNT_AT_SECTOR;
        private _sectorType = _y getOrDefault ["type", ""];
        {
            _x params ["_role", "_model", "_manpower", "_roleCap", "_maximumDepth", "_sectorTypes", ["_tourRange", [0, 0]]];
            if (_depth < 0 || {_depth > _maximumDepth} || {!(_sectorType in _sectorTypes)}) then {continue};
            private _roleCount = [_role] call BATTLESPACE_DEFENSE_COUNT_ROLE;
            if (_roleCount >= _roleCap || {[_role, _targetSector] call BATTLESPACE_DEFENSE_COUNT_ROLE > 0}) then {continue};
            private _deficit = _roleCap - _roleCount;
            // Within each coverage tier, non-overlapping score bands preserve:
            // role shortage, front depth, existing coverage, military type, randomness.
            private _frontPriority = -(_depth * 10000);
            private _coveragePriority = -(_assignedCount * 100);
            private _typePriority = [0, 50] select (_sectorType == "military");
            _candidates pushBack [(_deficit * 1000000) + _frontPriority + _coveragePriority + _typePriority + random 25, _targetSector, _x, _assignedCount == 0];
        } forEach _roles;
    } forEach BATTLESPACE_SECTOR_STATES;
    _candidates = [_candidates, [], {_x param [0, 0]}, "DESCEND"] call BIS_fnc_sortBy;
    // Give eligible gaps their first defender before layering another role onto a covered objective.
    _candidates = (_candidates select {_x select 3}) + (_candidates select {!(_x select 3)});

    private _formed = 0;
    private _selectedTargets = [];
    {
        if (_formed >= _formationLimit) exitWith {};
        if (["DEFENDER"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= _maxActive) exitWith {};
        private _targetSector = _x param [1, ""];
        if (_targetSector in _selectedTargets) then {continue};
        if ([_targetSector, _x param [2, []]] call BATTLESPACE_DEFENSE_DISPATCH_ROLE) then {
            _selectedTargets pushBack _targetSector;
            _formed = _formed + 1;
        };
    } forEach _candidates;
    if (_formed > 0 || {_reservesFormed > 0} || {_reservesRestaged > 0}) then {
        [] call BATTLESPACE_LOGISTICS_SAVE;
        [format [
            "Defensive allocation pass formed %1 assigned defender(s) across %2 distinct target(s) [%3], formed %4 reserve(s), and restaged %5 existing reserve(s)",
            _formed,
            count _selectedTargets,
            _selectedTargets joinString ", ",
            _reservesFormed,
            _reservesRestaged
        ]] call BATTLESPACE_STRATEGIC_LOG;
    };
};

BATTLESPACE_DEFENDERS_CREATE_AMBIENT_CIVILIANS = {
    params ["_sector"];
    if (!isServer || {!(_sector in sectors_bigtown || {_sector in sectors_capture} || {_sector in sectors_factory})}) exitWith {0};
    private _position = getMarkerPos _sector;
    private _targetCount = round (2 * GRLIB_civilian_activity);
    private _existingCount = 0;
    {
        private _taskForce = _y;
        if ((_taskForce param [0, ""]) != "Civilians" || {(_taskForce param [6, GRLIB_side_enemy]) != GRLIB_side_civilian}) then {continue};
        private _homeSector = _taskForce param [12, ""];
        if (_homeSector == "") then {
            private _homePoint = _taskForce param [10, []];
            if (_homePoint isEqualType [] && {(count _homePoint) in [2, 3]}) then {
                _homeSector = [sectors_allSectors, _homePoint] call BIS_fnc_nearestPosition;
                _taskForce set [12, _homeSector];
            };
        };
        if (_homeSector == _sector) then {_existingCount = _existingCount + 1};
    } forEach BATTLESPACE_TASK_FORCES;

    private _created = 0;
    for "_i" from 1 to ((_targetCount - _existingCount) max 0) do {
        private _composition = createHashMapFromArray [["manpower", 1], ["vehicles", []], ["structures", []]];
        private _taskForceId = ["Civilians", _composition, _position, _position, _position, GRLIB_side_civilian] call BATTLESPACE_TASK_FORCES_INIT;
        if (_taskForceId != "") then {
            (BATTLESPACE_TASK_FORCES get _taskForceId) set [12, _sector];
            _created = _created + 1;
        };
    };
    if (_created > 0) then {
        [format ["Sector activation created %1 ambient civilian task force(s) at %2; no military defenders were created", _created, _sector]] call BATTLESPACE_STRATEGIC_LOG;
    };
    _created
};

if (isServer) then {
    [format ["Defensive allocation configured: uncovered objectives first, reserve staging depths %1-%2, patrol vehicle chance %3 percent", BATTLESPACE_STRATEGIC_RESERVE_MIN_FRONT_DEPTH, BATTLESPACE_STRATEGIC_RESERVE_MAX_FRONT_DEPTH, 100 * BATTLESPACE_STRATEGIC_DEFENSIVE_PATROL_VEHICLE_CHANCE], "BATTLESPACE"] call KPLIB_fnc_log;
};
