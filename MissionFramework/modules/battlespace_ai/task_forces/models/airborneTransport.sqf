[
    "Airborne Transport",
    createHashMapFromArray [
        ["canProc", { _this call BATTLESPACE_AIRLIFT_CAN_PROC }],
        ["doSpawn", {
            params ["_id", "_force"];
            if (_force param [11, false]) exitWith {};
            _force set [11, true];
            [_id, _force] spawn {
                params ["_id", "_force"];
                private _success = [_id, _force] call BATTLESPACE_AIRLIFT_SPAWN;
                [_id, _force, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN;
            };
        }],
        // Physical losses are handled by the controller, preserving wrecks and
        // dismounted survivors instead of deleting them through generic cleanup.
        ["isAlive", {
            params ["_id", "_force"];
            (_force param [8, []]) isNotEqualTo []
                || {((_force select 3) getOrDefault ["manpower", 0]) > 0}
                || {((_force select 3) getOrDefault ["vehicles", []]) isNotEqualTo []}
        }],
        ["onDecisionTick", { _this call BATTLESPACE_AIRLIFT_TICK }]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
