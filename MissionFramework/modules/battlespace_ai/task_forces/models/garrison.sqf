BATTLESPACE_TASK_FORCE_GARRISON_BUILD_ASSIGNMENT = {
    params ["_sector"];
    getMarkerPos _sector
};

BATTLESPACE_TASK_FORCE_GARRISON_ORDER = {
    params ["_taskForce", "_operation"];
    private _position = _operation getOrDefault ["targetPosition", _taskForce param [1, []]];
    private _groups = (_taskForce param [4, []]) select {
        !isNull _x && {(units _x) findIf {alive _x} >= 0}
    };
    private _buildings = nearestObjects [_position, ["Building"], 250] select {
        ([_x] call BIS_fnc_buildingPositions) isNotEqualTo []
    };
    {
        [_x, true, true] call KPLIB_fnc_taskReset;
        _x setVariable ["BATTLESPACE_DEFENDER_RETURNING", false];
        private _building = if (_buildings isEqualTo []) then {objNull} else {_buildings deleteAt 0};
        if (isNull _building) then {
            [_x, _position, 150, 4, [], false, true] call KPLIB_fnc_taskPatrol;
        } else {
            [_x, getPos _building] call KPLIB_fnc_garrison;
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
                    if (_success && {_onStation}) then {BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName};
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
                        _taskForce set [2, []];
                        BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
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
