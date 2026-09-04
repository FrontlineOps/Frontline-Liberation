BATTLESPACE_TASK_FORCE_DEFENSIVE_PATROL_BUILD_ASSIGNMENT = {
    params ["_sector"];
    private _center = getMarkerPos _sector;
    private _position = _center getPos [150 + random 250, random 360];
    if (surfaceIsWater _position) then {
        _position = [_center, 0, 350, 10, 0, 0.35, 0] call BIS_fnc_findSafePos;
    };
    if !((count _position) in [2, 3]) then {_position = +_center};
    _position set [2, 0];
    _position
};

BATTLESPACE_TASK_FORCE_DEFENSIVE_PATROL_SELECT_LEG = {
    params ["_taskForceName", "_taskForce", ["_operation", createHashMap]];
    private _sector = _operation getOrDefault ["assignedSector", _taskForce param [12, ""]];
    if (_sector == "") then {
        _sector = [sectors_allSectors, _taskForce param [10, _taskForce param [1, []]]] call BIS_fnc_nearestPosition;
        _taskForce set [12, _sector];
    };
    private _center = getMarkerPos _sector;
    private _front = [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_traverseGraphAndFindFirstBluforSector;
    if (isNil "_front") then {_front = _sector};
    private _direction = if (_front == _sector) then {random 360} else {_center getDir (getMarkerPos _front)};
    private _destination = [];
    for "_attempt" from 1 to 8 do {
        private _candidate = _center getPos [350 + random 500, _direction - 110 + random 220];
        if (!surfaceIsWater _candidate) exitWith {_destination = _candidate};
    };
    if (_destination isEqualTo []) exitWith {false};
    _destination set [2, 0];
    _taskForce set [2, _destination];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
    [_taskForceName, _taskForce param [1, []], _destination] call QUEUE_PATHFIND_REQUEST;
    {
        _x setBehaviourStrong "AWARE";
        _x setCombatMode "YELLOW";
        _x setSpeedMode "LIMITED";
    } forEach (_taskForce param [4, []]);
    true
};

[
    "Defensive Patrol",
    createHashMapFromArray [
        ["buildAssignment", BATTLESPACE_TASK_FORCE_DEFENSIVE_PATROL_BUILD_ASSIGNMENT],
        ["canProc", BATTLESPACE_TASK_FORCE_DEFENSE_MODEL_CAN_PROC],
        [
            "doSpawn",
            {
                params ["_taskForceName", "_taskForce"];
                if (_taskForce param [11, false]) exitWith {};
                _taskForce set [11, true];
                [_taskForceName, _taskForce] spawn {
                    params ["_taskForceName", "_taskForce"];
                    private _success = [_taskForceName, _taskForce, false, false, false, false, "LIMITED"] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
                    [_taskForceName, _taskForce, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN;
                };
            }
        ],
        ["isAlive", BATTLESPACE_TASK_FORCE_DEFENSE_MODEL_IS_ALIVE],
        [
            "onDecisionTick",
            {
                params ["_taskForceName", "_taskForce"];
                private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceName;
                private _assigned = !isNil "_operation"
                    && {(_operation getOrDefault ["kind", ""]) == "DEFENDER"}
                    && {(_operation getOrDefault ["defenseRole", ""]) == "DEFENSIVE_PATROL"};

                if (!_assigned) exitWith {
                    private _retreat = [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_DEFENDER_RETREAT_TICK;
                    _retreat params ["_retreating", "_retreatDone"];
                    if (_retreating) exitWith {_retreatDone};
                    private _runtime = [_taskForce] call BATTLESPACE_TASK_FORCE_DEFENSE_UPDATE_LOCATION;
                    _runtime params ["_activeGroups", "_currentLocation"];
                    private _destination = _taskForce param [2, []];
                    if (_destination isEqualTo [] || {_currentLocation distance2D _destination <= 40}) then {
                        [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_DEFENSIVE_PATROL_SELECT_LEG;
                    };
                    if (_activeGroups isEqualTo []) then {
                        [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                    };
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

                if (_phase == "DEPLOYING") exitWith {
                    private _targetPosition = _operation getOrDefault ["targetPosition", _taskForce param [2, []]];
                    private _arrivalRadius = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEFENDER_ARRIVAL_RADIUS", 100];
                    if (_currentLocation distance2D _targetPosition <= _arrivalRadius) then {
                        _operation set ["phase", "ON_STATION"];
                        private _tourDuration = _operation getOrDefault ["tourDuration", 0];
                        if (_tourDuration > 0) then {_operation set ["expiresAt", CBA_missionTime + _tourDuration]};
                        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                        BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
                        [_taskForceName, _taskForce, _operation] call BATTLESPACE_TASK_FORCE_DEFENSIVE_PATROL_SELECT_LEG;
                        [format ["Defensive patrol %1 began its circuit around %2", _taskForceName, _assignedSector]] call BATTLESPACE_STRATEGIC_LOG;
                    } else {
                        if (_activeGroups isEqualTo []) then {
                            [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                        };
                    };
                    false
                };

                if (_phase == "ON_STATION") exitWith {
                    private _expiresAt = _operation getOrDefault ["expiresAt", -1];
                    if (
                        _expiresAt >= 0
                        && {CBA_missionTime >= _expiresAt}
                        && {!(_assignedSector in (missionNamespace getVariable ["active_sectors", []]))}
                    ) exitWith {
                        !([_taskForceName, _taskForce, _operation, "its defensive patrol completed"] call BATTLESPACE_TASK_FORCE_DEFENSE_BEGIN_RETURN)
                    };
                    private _destination = _taskForce param [2, []];
                    if (_destination isEqualTo [] || {_currentLocation distance2D _destination <= 40}) then {
                        [_taskForceName, _taskForce, _operation] call BATTLESPACE_TASK_FORCE_DEFENSIVE_PATROL_SELECT_LEG;
                    };
                    if (_activeGroups isEqualTo []) then {
                        [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                    };
                    false
                };
                false
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
