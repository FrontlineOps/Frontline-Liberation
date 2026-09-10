BATTLESPACE_TASK_FORCE_GARRISON_BUILD_ASSIGNMENT = {
    params ["_sector"];
    getMarkerPos _sector
};

BATTLESPACE_TASK_FORCE_GARRISON_STOP_ROUTE = {
    params ["_taskForceName", "_taskForce"];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    _taskForce set [2, []];
    private _registered = BATTLESPACE_TASK_FORCES get _taskForceName;
    if (!isNil "_registered") then {_registered set [2, []]};
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
    // A completed old route would otherwise be reported as a failure against
    // the now-empty destination and send an occupied garrison back home.
    BATTLESPACE_PATHFIND_REQUEST_GENERATIONS set [_taskForceName,
        1 + (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_taskForceName, 0])];
    QUEUED_PATHFIND_REQUESTS = QUEUED_PATHFIND_REQUESTS select {(_x select 0) != _taskForceName};
    if (!isNil "BATTLESPACE_PATHFIND_ACTIVE_JOB"
        && {(BATTLESPACE_PATHFIND_ACTIVE_JOB getOrDefault ["taskForceName", ""]) == _taskForceName}) then {
        BATTLESPACE_PATHFIND_ACTIVE_JOB = nil;
    };
};

BATTLESPACE_TASK_FORCE_GARRISON_ORDER = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    params ["_taskForce", "_operation"];
    private _position = _operation getOrDefault ["targetPosition", _taskForce param [1, []]];
    private _groups = (_taskForce param [4, []]) select {
        !isNull _x && {(units _x) findIf {alive _x} >= 0}
    };
    {
        private _args = [_x, _position, []];
        if (local _x) then {
            _args call BATTLESPACE_DEFENSE_GARRISON_GROUP;
        } else {
            _args remoteExecCall ["BATTLESPACE_DEFENSE_GARRISON_GROUP", groupOwner _x];
        };
    } forEach _groups;
};

[
    "Garrison",
    createHashMapFromArray [
        ["buildAssignment", BATTLESPACE_TASK_FORCE_GARRISON_BUILD_ASSIGNMENT],
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
                    private _onStation = _phase in ["", "ACTIVE", "ON_STATION"];
                    private _success = [_taskForceName, _taskForce, _onStation] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
                    if (_success && {_onStation}) then {
                        [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_GARRISON_STOP_ROUTE;
                    };
                    [_taskForceName, _taskForce, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN;
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
                    && {(_operation getOrDefault ["defenseRole", ""]) == "GARRISON"};

                if (!_assigned) exitWith {
                    private _retreat = [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_DEFENDER_RETREAT_TICK;
                    _retreat params ["_retreating", "_done"];
                    if (_retreating) exitWith {_done};
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
                if (_phase == "DEPLOYING") exitWith {
                    private _targetPosition = _operation getOrDefault ["targetPosition", getMarkerPos _assignedSector];
                    private _arrivalRadius = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEFENDER_ARRIVAL_RADIUS", 100];
                    if (_currentLocation distance2D _targetPosition <= _arrivalRadius) then {
                        _operation set ["phase", "ON_STATION"];
                        [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_GARRISON_STOP_ROUTE;
                        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                        [_taskForce, _operation] call BATTLESPACE_TASK_FORCE_GARRISON_ORDER;
                        [format ["Garrison %1 occupied %2", _taskForceName, _assignedSector]] call BATTLESPACE_STRATEGIC_LOG;
                    } else {
                        if (_activeGroups isEqualTo []) then {
                            [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                        };
                    };
                    false
                };
                false
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
