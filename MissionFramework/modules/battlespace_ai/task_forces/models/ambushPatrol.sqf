BATTLESPACE_TASK_FORCE_AMBUSH_BUILD_ASSIGNMENT = {
    params ["_sector"];
    private _center = getMarkerPos _sector;
    private _front = [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_traverseGraphAndFindFirstBluforSector;
    if (isNil "_front") then {_front = _sector};
    private _direction = if (_front == _sector) then {random 360} else {_center getDir (getMarkerPos _front)};
    private _searchCenter = _center getPos [450, _direction - 45 + random 90];
    private _places = selectBestPlaces [
        _searchCenter,
        350,
        "4 * forest + 3 * trees + 1.5 * hills + meadow - 2 * houses - 100 * sea",
        35,
        16
    ];
    _places = _places select {
        private _candidate = _x param [0, []];
        _candidate isNotEqualTo [] && {!surfaceIsWater _candidate}
    };
    private _position = if (_places isEqualTo []) then {_searchCenter} else {(selectRandom _places) param [0, _searchCenter]};
    if (surfaceIsWater _position) then {
        _position = [_center, 0, 800, 10, 0, 0.35, 0] call BIS_fnc_findSafePos;
    };
    if !((count _position) in [2, 3]) then {_position = +_center};
    _position set [2, 0];
    _position
};

BATTLESPACE_TASK_FORCE_AMBUSH_CONCEAL = {
    params ["_taskForceName", "_taskForce"];
    _taskForce set [2, []];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
    {
        if (local _x) then {[_x, false] call BATTLESPACE_DEFENSE_AMBUSH_GROUP} else {[_x, false] remoteExecCall ["BATTLESPACE_DEFENSE_AMBUSH_GROUP", groupOwner _x]};
    } forEach (_taskForce param [4, []]);
};

BATTLESPACE_TASK_FORCE_AMBUSH_HAS_CONTACT = {
    params ["_taskForce"];
    private _contact = false;
    {
        private _leader = leader _x;
        if (isNull _leader) then {continue};
        if ([getPosATL _leader, 350, 45, false, _x] call BATTLESPACE_CONTACT_QUERY isNotEqualTo []) exitWith {_contact = true};
    } forEach (_taskForce param [4, []]);
    _contact
};

BATTLESPACE_TASK_FORCE_AMBUSH_BEGIN_DISPLACE = {
    params ["_taskForceName", "_taskForce", "_operation"];
    private _sector = _operation getOrDefault ["assignedSector", ""];
    if (_sector == "") exitWith {false};
    private _destination = +(_operation getOrDefault ["coveragePosition", []]);
    if (_destination isEqualTo []) then {_destination = [_sector] call BATTLESPACE_TASK_FORCE_AMBUSH_BUILD_ASSIGNMENT};
    if (_destination isEqualTo []) exitWith {false};
    _operation set ["phase", "DISPLACING"];
    _operation set ["targetPosition", _destination];
    _operation set ["lastProgressPosition", +(_taskForce select 1)];
    _operation set ["legDeadline", CBA_missionTime + 900];
    _taskForce set [2, _destination];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
    [_taskForceName, _taskForce param [1, []], _destination] call QUEUE_PATHFIND_REQUEST;
    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
    {
        if (local _x) then {[_x] call BATTLESPACE_DEFENSE_RESET_GROUP} else {[_x] remoteExecCall ["BATTLESPACE_DEFENSE_RESET_GROUP", groupOwner _x]};
    } forEach (_taskForce param [4, []]);
    true
};

[
    "Ambush Patrol",
    createHashMapFromArray [
        ["buildAssignment", BATTLESPACE_TASK_FORCE_AMBUSH_BUILD_ASSIGNMENT],
        ["canProc", BATTLESPACE_TASK_FORCE_DEFENSE_MODEL_CAN_PROC],
        [
            "doSpawn",
            {
                params ["_taskForceName", "_taskForce"];
                if (_taskForce param [11, false]) exitWith {};
                _taskForce set [11, true];
                [_taskForceName, _taskForce] spawn {
                    params ["_taskForceName", "_taskForce"];
                    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceName;
                    private _phase = if (isNil "_operation") then {""} else {_operation getOrDefault ["phase", ""]};
                    private _concealed = _phase in ["", "ACTIVE", "ON_STATION"];
                    private _success = [_taskForceName, _taskForce, false, true, true, false, "LIMITED"] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
                    if (_success && {_concealed}) then {BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName};
                    private _finished = [_taskForceName, _taskForce, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN;
                    if (_finished && {_concealed}) then {
                        private _registered = BATTLESPACE_TASK_FORCES get _taskForceName;
                        if (!isNil "_registered") then {
                            [_taskForceName, _registered] call BATTLESPACE_TASK_FORCE_AMBUSH_CONCEAL;
                        };
                    };
                };
            }
        ],
        ["isAlive", BATTLESPACE_TASK_FORCE_DEFENSE_MODEL_IS_ALIVE],
        ["onPathFailed", BATTLESPACE_DEFENSE_PATH_FAILED],
        [
            "onDecisionTick",
            {
                params ["_taskForceName", "_taskForce"];
                private _retryAt = (BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_taskForceName, createHashMap]) getOrDefault ["nextManeuverAt", 0];
                if (CBA_missionTime < _retryAt) exitWith {false};
                private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceName;
                private _assigned = !isNil "_operation"
                    && {(_operation getOrDefault ["kind", ""]) == "DEFENDER"}
                    && {(_operation getOrDefault ["defenseRole", ""]) == "AMBUSH"};

                if (!_assigned) exitWith {
                    private _retreat = [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_DEFENDER_RETREAT_TICK;
                    _retreat params ["_retreating", "_retreatDone"];
                    if (_retreating) exitWith {_retreatDone};
                    [_taskForce] call BATTLESPACE_TASK_FORCE_DEFENSE_UPDATE_LOCATION;
                    false
                };

                private _phase = _operation getOrDefault ["phase", "DEPLOYING"];
                if (_phase == "LOST") exitWith {true};
                private _assignedSector = _operation getOrDefault ["assignedSector", ""];
                private _assignedState = BATTLESPACE_SECTOR_STATES get _assignedSector;
                if (
                    _phase != "RETURNING"
                    && {_assignedSector == "" || {isNil "_assignedState"} || {(_assignedState getOrDefault ["owner", ""]) != "OPFOR"}}
                ) then {
                    _phase = ["LOST", "RETURNING"] select (
                        [_taskForceName, _taskForce, _operation, "its assigned objective was lost"] call BATTLESPACE_TASK_FORCE_DEFENSE_BEGIN_RETURN
                    );
                };
                if (_phase == "LOST") exitWith {true};

                private _retreat = [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_DEFENDER_RETREAT_TICK;
                _retreat params ["_retreating", "_retreatDone"];
                if (_retreating) exitWith {_retreatDone};

                private _runtime = [_taskForce] call BATTLESPACE_TASK_FORCE_DEFENSE_UPDATE_LOCATION;
                _runtime params ["_activeGroups", "_currentLocation"];
                if (_phase in ["DEPLOYING", "DISPLACING"]) exitWith {
                    private _targetPosition = _operation getOrDefault ["targetPosition", _taskForce param [2, []]];
                    private _arrivalRadius = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEFENDER_ARRIVAL_RADIUS", 100];
                    if (_currentLocation distance2D _targetPosition <= _arrivalRadius) then {
                        _operation set ["phase", "ON_STATION"];
                        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                        [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_AMBUSH_CONCEAL;
                        [format ["Ambush patrol %1 concealed near %2", _taskForceName, _assignedSector]] call BATTLESPACE_STRATEGIC_LOG;
                    } else {
                        if (_activeGroups isEqualTo []) then {
                            [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                        };
                    };
                    false
                };

                private _hasContact = [_taskForce] call BATTLESPACE_TASK_FORCE_AMBUSH_HAS_CONTACT;
                if (_phase == "ON_STATION") exitWith {
                    if (_hasContact) then {
                        _operation set ["phase", "ENGAGED"];
                        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                        {
                            if (local _x) then {[_x, true] call BATTLESPACE_DEFENSE_AMBUSH_GROUP} else {[_x, true] remoteExecCall ["BATTLESPACE_DEFENSE_AMBUSH_GROUP", groupOwner _x]};
                        } forEach _activeGroups;
                        [format ["Ambush patrol %1 engaged near %2", _taskForceName, _assignedSector]] call BATTLESPACE_STRATEGIC_LOG;
                    };
                    false
                };

                if (_phase == "ENGAGED" && {!_hasContact}) then {
                    [_taskForceName, _taskForce, _operation] call BATTLESPACE_TASK_FORCE_AMBUSH_BEGIN_DISPLACE;
                };
                false
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
