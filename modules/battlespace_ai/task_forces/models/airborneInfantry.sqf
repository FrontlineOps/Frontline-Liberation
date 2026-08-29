[
    "Airborne Infantry",
    createHashMapFromArray [
        [
            "canProc",
            {
                params ["_taskForceName", "_taskForce"];
                private _currentLocation = _taskForce param [1, []];
                private _requiredPlayers = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
                private _procRange = ["Airborne Infantry"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
                private _canProc = false;
                {
                    if (
                        count (_x getOrDefault ["Players", []]) >= _requiredPlayers
                        && {(_x getOrDefault ["Position", []]) distance2D _currentLocation <= _procRange}
                    ) exitWith {_canProc = true};
                } forEach BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS;
                _canProc
            }
        ],
        [
            "doSpawn",
            {
                params ["_taskForceName", "_taskForce"];
                if (_taskForce param [11, false]) exitWith {};
                _taskForce set [11, true];
                [_taskForceName, _taskForce] spawn {
                    params ["_taskForceName", "_taskForce"];
                    private _success = [
                        _taskForceName, _taskForce, false, false, false, false, "NORMAL", [opfor_paratrooper]
                    ] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
                    if (_success) then {
                        private _target = _taskForce param [2, []];
                        {[_x, _target] call BATTLESPACE_AIRBORNE_ORDER_DEPLOYED_GROUP} forEach (_taskForce param [4, []]);
                    };
                    [_taskForceName, _taskForce, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN;
                };
            }
        ],
        [
            "isAlive",
            {
                params ["_taskForceName", "_taskForce"];
                private _composition = _taskForce param [3, createHashMap];
                private _activeObjects = (_taskForce param [8, []]) select {!isNull _x && {alive _x}};
                if (_activeObjects isNotEqualTo []) exitWith {true};
                (_composition getOrDefault ["manpower", 0]) >= BATTLESPACE_TASK_FORCE_MINIMUM_SIZE
            }
        ],
        [
            "onDecisionTick",
            {
                params ["_taskForceName", "_taskForce"];
                if (isNil "BATTLESPACE_AIRBORNE_INFANTRY_ON_DECISION_TICK") exitWith {false};
                [_taskForceName, _taskForce] call BATTLESPACE_AIRBORNE_INFANTRY_ON_DECISION_TICK
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
