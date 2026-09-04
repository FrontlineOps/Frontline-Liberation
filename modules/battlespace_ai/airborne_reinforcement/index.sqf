/*
    Resource-backed airborne casualty response.

    Before the drop, one Airborne Transport owns the paid aircraft and cargo.
    At the drop point the already-paid infantry is transferred into a separate
    Airborne Infantry task force so carrier return and ground combat persist at
    their independent locations.
*/

if (isNil "BATTLESPACE_AIRBORNE_NEXT_CLASS_WARNING") then {
    BATTLESPACE_AIRBORNE_NEXT_CLASS_WARNING = 0;
};

BATTLESPACE_AIRBORNE_SELECT_TRANSPORT = {
    private _catalogs = missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap];
    private _opfor = _catalogs getOrDefault ["opfor", createHashMap];
    private _resourcePool = BATTLESPACE_RESOURCE_CLASS_POOLS getOrDefault ["aircraft", []];
    private _minimumSeats = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIRBORNE_MIN_MANPOWER", 4];
    private _candidates = [];

    {
        private _priority = _forEachIndex;
        {
            private _class = _x;
            private _cfg = configFile >> "CfgVehicles" >> _class;
            private _seats = getNumber (_cfg >> "transportSoldier");
            if (
                _class in _resourcePool
                && {isClass _cfg}
                && {getNumber (_cfg >> "scope") >= 2}
                && {_class isKindOf "Air"}
                && {!(_class isKindOf "ParachuteBase")}
                && {getNumber (_cfg >> "isUav") <= 0}
                && {getText (_cfg >> "crew") != ""}
                && {_seats >= _minimumSeats}
            ) then {
                _candidates pushBack [_priority, -_seats, _class, _seats];
            };
        } forEach _x;
    } forEach [
        +(_opfor getOrDefault ["rotaryLogistics", []]),
        +(_opfor getOrDefault ["fixedWing", []])
    ];

    if (_candidates isEqualTo []) exitWith {["", 0]};
    _candidates sort true;
    private _selected = _candidates select 0;
    [_selected select 2, _selected select 3]
};

BATTLESPACE_AIRBORNE_TARGET_IS_COVERED = {
    params ["_targetSector"];
    (["REINFORCEMENT", _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET)
    || {["RESERVE", _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET}
    || {["AIRBORNE_TRANSPORT", _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET}
    || {["AIRBORNE_REINFORCEMENT", _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET}
    || {["BATTLEGROUP", _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET}
};

BATTLESPACE_AIRBORNE_BUILD_SOURCE_CANDIDATES = {
    params ["_targetSector", "_transportSeats"];
    private _targetPosition = getMarkerPos _targetSector;
    private _maximumRange = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIRBORNE_MAX_RANGE", 20000];
    private _desiredManpower = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIRBORNE_MANPOWER", 14];
    private _minimumManpower = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIRBORNE_MIN_MANPOWER", 4];
    private _candidates = [];

    {
        private _sourceSector = _x;
        private _state = _y;
        if (_sourceSector == _targetSector || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) then {continue};
        private _distance = _targetPosition distance2D (getMarkerPos _sourceSector);
        if (_distance > _maximumRange) then {continue};

        private _resources = _state getOrDefault ["resources", createHashMap];
        if ((_resources getOrDefault ["aircraft", 0]) < 1) then {continue};
        private _sectorType = _state getOrDefault ["type", ""];
        private _thresholds = [_sectorType, "SendReinforcements"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
        private _manpowerThreshold = _thresholds getOrDefault ["manpower", -1];
        if (_manpowerThreshold < 0) then {continue};
        private _reserve = ceil (([_sourceSector, "manpower", _sectorType] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY) * _manpowerThreshold);
        private _excess = ((_resources getOrDefault ["manpower", 0]) - _reserve) max 0;
        private _assigned = floor (_desiredManpower min _transportSeats min _excess);
        if (_assigned < _minimumManpower) then {continue};
        _candidates pushBack [_distance, _sourceSector, _assigned];
    } forEach BATTLESPACE_SECTOR_STATES;

    _candidates sort true;
    _candidates
};

BATTLESPACE_AIRBORNE_BEGIN_RETURN = {
    params ["_taskForceId", "_taskForce", "_operation"];
    private _returnSector = _operation getOrDefault ["originSector", ""];
    private _returnState = BATTLESPACE_SECTOR_STATES get _returnSector;
    if (isNil "_returnState" || {(_returnState getOrDefault ["owner", ""]) != "OPFOR"}) then {
        _returnSector = [(_taskForce param [1, [0, 0, 0]])] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
    };
    if (_returnSector == "") exitWith {
        _operation set ["phase", "LOST"];
        _operation set ["outcome", "LOST"];
        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
        false
    };

    private _destination = getMarkerPos _returnSector;
    _operation set ["phase", "RETURNING"];
    _operation set ["returnSector", _returnSector];
    _taskForce set [2, _destination];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceId;
    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
    BATTLESPACE_TASK_FORCES set [_taskForceId, _taskForce];
    [_taskForceId, _taskForce param [1, []], _destination] call QUEUE_PATHFIND_REQUEST;
    true
};

BATTLESPACE_AIRBORNE_ORDER_DEPLOYED_GROUP = {
    params ["_group", "_targetPosition"];
    if (isNull _group || {!local _group}) exitWith {};
    while {count waypoints _group > 0} do {deleteWaypoint ((waypoints _group) select 0)};
    private _waypoint = _group addWaypoint [_targetPosition, 250];
    _waypoint setWaypointType "SAD";
    _waypoint setWaypointBehaviour "COMBAT";
    _waypoint setWaypointCombatMode "YELLOW";
    _waypoint setWaypointSpeed "NORMAL";
    _waypoint setWaypointCompletionRadius 100;
    _waypoint = _group addWaypoint [_targetPosition, 350];
    _waypoint setWaypointType "SAD";
    _waypoint = _group addWaypoint [_targetPosition, 350];
    _waypoint setWaypointType "CYCLE";
};

BATTLESPACE_AIRBORNE_DEPLOY = {
    params ["_taskForceId"];
    private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceId;
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    if (isNil "_taskForce" || {isNil "_operation"}) exitWith {false};
    if ((_operation getOrDefault ["phase", ""]) != "DEPLOYING") exitWith {false};

    private _targetSector = _operation getOrDefault ["targetSector", ""];
    private _targetState = BATTLESPACE_SECTOR_STATES get _targetSector;
    if (isNil "_targetState" || {(_targetState getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {
        [_taskForceId, _taskForce, _operation] call BATTLESPACE_AIRBORNE_BEGIN_RETURN
    };

    private _composition = _taskForce param [3, createHashMap];
    private _manpower = floor ((_composition getOrDefault ["manpower", 0]) max 0);
    if (_manpower < BATTLESPACE_TASK_FORCE_MINIMUM_SIZE) exitWith {
        [_taskForceId, _taskForce, _operation] call BATTLESPACE_AIRBORNE_BEGIN_RETURN
    };

    private _targetPosition = getMarkerPos _targetSector;
    private _childComposition = createHashMapFromArray [
        ["manpower", _manpower], ["vehicles", []], ["structures", []]
    ];
    private _childId = [
        "Airborne Infantry", _childComposition, _targetPosition, _targetPosition, _targetPosition
    ] call BATTLESPACE_TASK_FORCES_INIT;
    if (_childId == "") exitWith {
        [format ["Airborne transport %1 could not create its infantry child and is returning", _taskForceId], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        [_taskForceId, _taskForce, _operation] call BATTLESPACE_AIRBORNE_BEGIN_RETURN
    };

    private _activeObjects = +(_taskForce param [8, []]);
    private _activeGroups = +(_taskForce param [4, []]);
    private _aircraft = objNull;
    {
        if (!isNull _x && {!(_x isKindOf "Man")} && {_x isKindOf "Air"}) exitWith {_aircraft = _x};
    } forEach _activeObjects;
    private _transportGroup = if (isNull _aircraft) then {grpNull} else {group driver _aircraft};
    private _infantryGroups = _activeGroups select {
        !isNull _x && {_x isNotEqualTo _transportGroup} && {units _x findIf {alive _x} >= 0}
    };
    private _allInfantryObjects = _activeObjects select {
        !isNull _x && {_x isKindOf "Man"} && {isNull _transportGroup || {group _x isNotEqualTo _transportGroup}}
    };
    private _infantryObjects = _allInfantryObjects select {alive _x};

    {
        _x setVariable ["TASKFORCEID", _childId];
        _x setVariable ["BATTLESPACE_TRANSPORT_PARENT_GROUP", nil];
        [_x, _targetPosition] call BATTLESPACE_AIRBORNE_ORDER_DEPLOYED_GROUP;
    } forEach _infantryGroups;
    {
        _x setVariable ["TASKFORCEID", _childId];
        if (!isNull (objectParent _x)) then {
            unassignVehicle _x;
            removeBackpack _x;
            _x addBackpack "B_Parachute";
            moveOut _x;
        };
    } forEach _infantryObjects;

    if (!isNull _transportGroup) then {
        _transportGroup setVariable ["BATTLESPACE_TRANSPORT_CARGO_GROUP", nil];
    };
    if (!isNull _aircraft) then {
        _aircraft setVariable ["BATTLESPACE_TRANSPORT_CARGO_GROUP", nil];
    };

    private _childTaskForce = BATTLESPACE_TASK_FORCES get _childId;
    _childTaskForce set [4, _infantryGroups];
    _childTaskForce set [8, _infantryObjects];
    BATTLESPACE_TASK_FORCES set [_childId, _childTaskForce];
    BATTLESPACE_STRATEGIC_OPERATIONS set [_childId, createHashMapFromArray [
        ["kind", "AIRBORNE_REINFORCEMENT"],
        ["phase", "DEPLOYED"],
        ["fundingSector", _operation getOrDefault ["fundingSector", ""]],
        ["originSector", _operation getOrDefault ["originSector", ""]],
        ["targetSector", _targetSector],
        ["pressureSector", _targetSector],
        ["cost", createHashMapFromArray [["manpower", _manpower]]],
        ["vehicleManifest", []],
        ["initialStrength", _manpower],
        ["createdAt", _operation getOrDefault ["createdAt", CBA_missionTime]],
        ["deployedAt", CBA_missionTime],
        ["expiresAt", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIRBORNE_DEPLOYMENT_DURATION", 900])],
        ["parentTransport", _taskForceId],
        ["outcome", ""]
    ]];

    _composition set ["manpower", 0];
    _taskForce set [3, _composition];
    _taskForce set [4, _activeGroups select {!isNull _x && {_x isEqualTo _transportGroup}}];
    _taskForce set [8, _activeObjects select {!(_x in _allInfantryObjects)}];
    private _parentCost = _operation getOrDefault ["cost", createHashMap];
    _parentCost deleteAt "manpower";
    _operation set ["cost", _parentCost];
    _operation set ["initialStrength", 4];
    _operation set ["childTaskForce", _childId];
    BATTLESPACE_TASK_FORCES set [_taskForceId, _taskForce];
    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];

    private _returning = [_taskForceId, _taskForce, _operation] call BATTLESPACE_AIRBORNE_BEGIN_RETURN;
    [] call BATTLESPACE_LOGISTICS_SAVE;
    [format ["Airborne transport %1 deployed infantry %2 at %3", _taskForceId, _childId, _targetSector]] call BATTLESPACE_STRATEGIC_LOG;
    _returning || {(_operation getOrDefault ["outcome", ""]) == "LOST"}
};

BATTLESPACE_AIRBORNE_QUEUE_DEPLOY = {
    params ["_taskForceId", "_operation"];
    if ((_operation getOrDefault ["phase", ""]) != "ENROUTE") exitWith {false};
    _operation set ["phase", "DEPLOYING"];
    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
    [{[_this select 0] call BATTLESPACE_AIRBORNE_DEPLOY}, [_taskForceId], 0] call CBA_fnc_waitAndExecute;
    true
};

BATTLESPACE_AIRBORNE_TRANSPORT_ON_DECISION_TICK = {
    params ["_taskForceId", "_taskForce"];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    if (isNil "_operation") exitWith {false};
    private _phase = _operation getOrDefault ["phase", "ENROUTE"];
    private _activeObjects = (_taskForce param [8, []]) select {!isNull _x && {alive _x}};
    private _activeGroups = (_taskForce param [4, []]) select {!isNull _x && {units _x isNotEqualTo []}};
    _taskForce set [8, _activeObjects];
    _taskForce set [4, _activeGroups];

    private _aircraft = objNull;
    {
        if (!(_x isKindOf "Man") && {_x isKindOf "Air"} && {alive _x}) exitWith {_aircraft = _x};
    } forEach _activeObjects;
    if (!isNull _aircraft) then {
        private _position = getPosATL _aircraft;
        _position set [2, 0];
        _taskForce set [1, _position];
    };
    private _current = _taskForce param [1, []];

    if (_phase == "LOST") exitWith {true};
    if (_phase == "DEPLOYING") exitWith {false};

    if (_phase == "ENROUTE") then {
        private _targetSector = _operation getOrDefault ["targetSector", ""];
        private _targetState = BATTLESPACE_SECTOR_STATES get _targetSector;
        if (isNil "_targetState" || {(_targetState getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {
            !([_taskForceId, _taskForce, _operation] call BATTLESPACE_AIRBORNE_BEGIN_RETURN)
        };
        if (_current distance2D (getMarkerPos _targetSector) <= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIRBORNE_DROP_RADIUS", 600])) exitWith {
            !([_taskForceId, _operation] call BATTLESPACE_AIRBORNE_QUEUE_DEPLOY)
        };
    };

    if (_phase == "RETURNING") then {
        private _returnSector = _operation getOrDefault ["returnSector", ""];
        private _returnState = BATTLESPACE_SECTOR_STATES get _returnSector;
        if (isNil "_returnState" || {(_returnState getOrDefault ["owner", ""]) != "OPFOR"}) then {
            if !([_taskForceId, _taskForce, _operation] call BATTLESPACE_AIRBORNE_BEGIN_RETURN) exitWith {true};
            _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
            _returnSector = _operation getOrDefault ["returnSector", ""];
        };
        if (_returnSector != "" && {_current distance2D (getMarkerPos _returnSector) <= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIRBORNE_RETURN_RADIUS", 500])}) exitWith {
            _operation set ["outcome", "RETURNED"];
            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
            true
        };
    };

    if (_activeGroups isEqualTo []) then {
        [_taskForceId, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
    };
    false
};

BATTLESPACE_AIRBORNE_INFANTRY_ON_DECISION_TICK = {
    params ["_taskForceId", "_taskForce"];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    if (isNil "_operation") exitWith {false};
    private _targetSector = _operation getOrDefault ["targetSector", ""];
    private _targetState = BATTLESPACE_SECTOR_STATES get _targetSector;
    private _activeGroups = (_taskForce param [4, []]) select {!isNull _x && {units _x findIf {alive _x} >= 0}};
    private _activeObjects = (_taskForce param [8, []]) select {!isNull _x && {alive _x}};
    _taskForce set [4, _activeGroups];
    _taskForce set [8, _activeObjects];
    if (_activeGroups isNotEqualTo []) then {
        private _leader = leader (_activeGroups select 0);
        if (!isNull _leader) then {_taskForce set [1, getPosATL _leader]};
    };

    private _targetPosition = getMarkerPos _targetSector;
    private _currentPosition = _taskForce param [1, _targetPosition];
    private _procRange = ["Airborne Infantry"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
    private _friendlyPlayerNearFight = (allPlayers findIf {
        alive _x
        && {side group _x == GRLIB_side_friendly}
        && {
            _x distance2D _targetPosition <= _procRange
            || {_x distance2D _currentPosition <= _procRange}
        }
    }) >= 0;

    if (isNil "_targetState" || {(_targetState getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {
        if (_friendlyPlayerNearFight) then {
            false
        } else {
            _operation set ["outcome", "LOST"];
            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
            true
        }
    };

    if (CBA_missionTime >= (_operation getOrDefault ["expiresAt", CBA_missionTime])) exitWith {
        if (_friendlyPlayerNearFight) then {
            false
        } else {
            _operation set ["outcome", "REINFORCED"];
            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
            true
        }
    };
    false
};

BATTLESPACE_AIRBORNE_DISPATCH = {
    params ["_targetSector"];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {false};
    private _targetState = BATTLESPACE_SECTOR_STATES get _targetSector;
    if (isNil "_targetState" || {(_targetState getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {false};
    if ([_targetSector] call BATTLESPACE_AIRBORNE_TARGET_IS_COVERED) exitWith {false};
    if (["AIRBORNE_TRANSPORT"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIRBORNE_TRANSPORTS", 2])) exitWith {false};

    private _transport = [] call BATTLESPACE_AIRBORNE_SELECT_TRANSPORT;
    _transport params ["_transportClass", "_transportSeats"];
    if (_transportClass == "") exitWith {
        if (CBA_missionTime >= BATTLESPACE_AIRBORNE_NEXT_CLASS_WARNING) then {
            ["No generated OPFOR aircraft can carry a Battlespace airborne reinforcement", "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
            BATTLESPACE_AIRBORNE_NEXT_CLASS_WARNING = CBA_missionTime + 600;
        };
        false
    };

    private _dispatched = false;
    {
        _x params ["_distance", "_sourceSector", "_manpower"];
        private _origin = getMarkerPos _sourceSector;
        private _target = getMarkerPos _targetSector;
        private _composition = createHashMapFromArray [
            ["manpower", _manpower], ["vehicles", [_transportClass]], ["structures", []]
        ];
        private _id = [
            "Airborne Transport", _composition, _origin, _target, _origin,
            _sourceSector, "AIRBORNE_TRANSPORT", createHashMapFromArray [
                ["phase", "ENROUTE"],
                ["targetSector", _targetSector],
                ["pressureSector", _targetSector],
                ["transportClass", _transportClass],
                ["assignedManpower", _manpower]
            ]
        ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
        if (_id != "") exitWith {
            _dispatched = true;
            stats_reinforcements_called = stats_reinforcements_called + 1;
            [] call BATTLESPACE_LOGISTICS_SAVE;
            [format ["Dispatched airborne transport %1 from %2 to %3 with %4 manpower", _id, _sourceSector, _targetSector, _manpower]] call BATTLESPACE_STRATEGIC_LOG;
        };
    } forEach ([_targetSector, _transportSeats] call BATTLESPACE_AIRBORNE_BUILD_SOURCE_CANDIDATES);
    _dispatched
};
