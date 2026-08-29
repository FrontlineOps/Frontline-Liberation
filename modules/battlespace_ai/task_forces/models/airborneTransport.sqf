[
    "Airborne Transport",
    createHashMapFromArray [
        [
            "canProc",
            {
                params ["_taskForceName", "_taskForce"];
                if ((_taskForce param [8, []]) isNotEqualTo []) exitWith {true};
                private _currentLocation = _taskForce param [1, []];
                private _requiredPlayers = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
                private _procRange = ["Airborne Transport"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
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
                        _taskForceName, _taskForce, false, false, false, false, "FULL", [opfor_paratrooper]
                    ] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
                    if (_success) then {
                        private _height = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIRBORNE_FLIGHT_HEIGHT", 300];
                        {
                            if (!isNull _x && {!(_x isKindOf "Man")} && {_x isKindOf "Air"}) then {
                                private _position = getPosATL _x;
                                _position set [2, _height];
                                _x setPosATL _position;
                                _x flyInHeight _height;
                                _x engineOn true;
                            };
                        } forEach (_taskForce param [8, []]);
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
                if ((_composition getOrDefault ["vehicles", []]) isEqualTo []) exitWith {false};
                private _activeObjects = _taskForce param [8, []];
                if (_activeObjects isEqualTo []) exitWith {true};
                _activeObjects findIf {
                    !isNull _x
                    && {!(_x isKindOf "Man")}
                    && {_x isKindOf "Air"}
                    && {alive _x}
                    && {canMove _x}
                    && {!(_x getVariable ["KPLIB_captured", false])}
                    && {!isNull (driver _x)}
                    && {alive (driver _x)}
                } >= 0
            }
        ],
        [
            "onDecisionTick",
            {
                params ["_taskForceName", "_taskForce"];
                if (isNil "BATTLESPACE_AIRBORNE_TRANSPORT_ON_DECISION_TICK") exitWith {false};
                [_taskForceName, _taskForce] call BATTLESPACE_AIRBORNE_TRANSPORT_ON_DECISION_TICK
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
