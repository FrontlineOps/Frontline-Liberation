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

BATTLESPACE_DEFENSE_SECTOR_IS_QUIET = {
    params ["_sector", "_state"];
    if (_sector in (missionNamespace getVariable ["active_sectors", []])) exitWith {false};
    private _quietTime = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEFENDER_QUIET_TIME", 600];
    if (CBA_missionTime - (_state getOrDefault ["lastOwnerChange", 0]) < _quietTime) exitWith {false};
    if (CBA_missionTime - (_state getOrDefault ["lastCasualtyAt", -1e9]) < _quietTime) exitWith {false};
    private _position = getMarkerPos _sector;
    private _playerExclusion = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEFENDER_PLAYER_EXCLUSION_RADIUS", 2500];
    allPlayers findIf {
        alive _x
        && {side group _x == GRLIB_side_friendly}
        && {_x distance2D _position < _playerExclusion}
    } < 0
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
        if !([_source, _y] call BATTLESPACE_DEFENSE_SECTOR_IS_QUIET) then {continue};
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

BATTLESPACE_DEFENSE_DISPATCH_ROLE = {
    params ["_targetSector", "_roleDefinition"];
    _roleDefinition params ["_role", "_model", "_manpower", "_roleCap", "_maximumDepth", "_sectorTypes", ["_tourRange", [0, 0]]];
    if ([_role, _targetSector] call BATTLESPACE_DEFENSE_COUNT_ROLE > 0) exitWith {false};
    if ([_role] call BATTLESPACE_DEFENSE_COUNT_ROLE >= _roleCap) exitWith {false};
    if ([_targetSector] call BATTLESPACE_DEFENSE_COUNT_AT_SECTOR >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_DEFENDERS_PER_SECTOR", 2])) exitWith {false};

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
    private _taskForceId = [
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
    ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_taskForceId == "") exitWith {false};
    (BATTLESPACE_TASK_FORCES get _taskForceId) set [12, _targetSector];
    [format [
        "Formed defender %1 (%2/%3) at %4 and assigned it to %5",
        _taskForceId,
        _role,
        _model,
        _sourceSector,
        _targetSector
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

BATTLESPACE_RESERVE_FORM = {
    if (["RESERVE"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_RESERVES", 3])) exitWith {false};
    private _minimumDepth = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESERVE_MIN_FRONT_DEPTH", 2];
    private _candidates = [];
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR") then {continue};
        if !([_x, _y] call BATTLESPACE_DEFENSE_SECTOR_IS_QUIET) then {continue};
        private _depth = [_x] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
        if (_depth < _minimumDepth || {_depth >= 69}) then {continue};
        private _sourceSector = _x;
        private _sourceType = _y getOrDefault ["type", ""];
        private _alreadyStaged = false;
        {
            if (
                (_y getOrDefault ["kind", ""]) == "RESERVE"
                && {(_y getOrDefault ["assignedSector", ""]) == _sourceSector}
            ) exitWith {_alreadyStaged = true};
        } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
        if (_alreadyStaged) then {continue};
        private _definition = [_sourceSector] call BATTLESPACE_RESERVE_BUILD_DEFINITION;
        if (count _definition == 0) then {continue};
        private _militaryBonus = [0, 1000] select (_sourceType == "military");
        _candidates pushBack [_militaryBonus + (_depth * 10) + random 5, _sourceSector, _definition];
    } forEach BATTLESPACE_SECTOR_STATES;
    _candidates = [_candidates, [], {_x param [0, 0]}, "DESCEND"] call BIS_fnc_sortBy;
    if (_candidates isEqualTo []) exitWith {false};
    private _candidate = _candidates select 0;
    _candidate params ["_score", "_sourceSector", "_composition"];
    private _origin = getMarkerPos _sourceSector;
    private _taskForceId = [
        "Mobile Reserve",
        _composition,
        _origin,
        [],
        _origin,
        _sourceSector,
        "RESERVE",
        createHashMapFromArray [
            ["phase", "READY"],
            ["defenseRole", "MOBILE_RESERVE"],
            ["assignedSector", _sourceSector],
            ["targetSector", ""],
            ["pressureSector", ""]
        ]
    ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_taskForceId == "") exitWith {false};
    (BATTLESPACE_TASK_FORCES get _taskForceId) set [12, _sourceSector];
    [format ["Formed ready mobile reserve %1 at %2 with %3 manpower and %4 vehicle(s)", _taskForceId, _sourceSector, _composition getOrDefault ["manpower", 0], count (_composition getOrDefault ["vehicles", []])]] call BATTLESPACE_STRATEGIC_LOG;
    true
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
        if !([_targetSector, _y] call BATTLESPACE_DEFENSE_SECTOR_IS_QUIET) then {continue};
        if ([_targetSector] call BATTLESPACE_DEFENSE_COUNT_AT_SECTOR >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_DEFENDERS_PER_SECTOR", 2])) then {continue};

        private _depth = [_targetSector] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
        private _sectorType = _y getOrDefault ["type", ""];
        {
            _x params ["_role", "_model", "_manpower", "_roleCap", "_maximumDepth", "_sectorTypes", ["_tourRange", [0, 0]]];
            if (_depth < 0 || {_depth > _maximumDepth} || {!(_sectorType in _sectorTypes)}) then {continue};
            private _roleCount = [_role] call BATTLESPACE_DEFENSE_COUNT_ROLE;
            if (_roleCount >= _roleCap || {[_role, _targetSector] call BATTLESPACE_DEFENSE_COUNT_ROLE > 0}) then {continue};
            private _deficit = _roleCap - _roleCount;
            private _frontPriority = (_maximumDepth - _depth + 1) * 100;
            private _typePriority = [0, 50] select (_sectorType == "military");
            _candidates pushBack [(_deficit * 1000) + _frontPriority + _typePriority + random 25, _targetSector, _x];
        } forEach _roles;
    } forEach BATTLESPACE_SECTOR_STATES;
    _candidates = [_candidates, [], {_x param [0, 0]}, "DESCEND"] call BIS_fnc_sortBy;

    private _formed = 0;
    {
        if (_formed >= _formationLimit) exitWith {};
        if (["DEFENDER"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= _maxActive) exitWith {};
        if ([_x param [1, ""], _x param [2, []]] call BATTLESPACE_DEFENSE_DISPATCH_ROLE) then {
            _formed = _formed + 1;
        };
    } forEach _candidates;
    if (_formed > 0 || {_reservesFormed > 0}) then {
        [] call BATTLESPACE_LOGISTICS_SAVE;
        [format ["Defensive allocation pass formed %1 assigned defender(s) and %2 ready reserve(s)", _formed, _reservesFormed]] call BATTLESPACE_STRATEGIC_LOG;
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
