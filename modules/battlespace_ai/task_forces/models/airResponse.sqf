[
    "Air Response",
    createHashMapFromArray [
        [
            "canProc",
            {
                params ["_taskForceName", "_taskForce"];
                private _currentLocation = _taskForce param [1, []];
                private _requiredPlayers = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
                private _procRange = ["Air Response"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
                private _canProc = false;
                {
                    if (
                        (count (_x getOrDefault ["Players", []])) >= _requiredPlayers
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
                    private _success = [_taskForceName, _taskForce, false, true, false, false, "FULL"] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
                    if (_success) then {
                        private _oldGroups = +(_taskForce param [4, []]);
                        private _responseGroup = createGroup [_taskForce param [6, east], true];
                        _responseGroup setVariable ["TASKFORCEID", _taskForceName];
                        {
                            if (!isNull _x && {!(_x isKindOf "Man")} && {_x isKindOf "Air"}) then {
                                (crew _x) joinSilent _responseGroup;
                            };
                        } forEach (_taskForce param [8, []]);
                        {
                            if (!isNull _x && {_x isNotEqualTo _responseGroup} && {units _x isEqualTo []}) then {
                                deleteGroup _x;
                            };
                        } forEach _oldGroups;

                        if (units _responseGroup isEqualTo []) then {
                            deleteGroup _responseGroup;
                            _success = false;
                        } else {
                            [_responseGroup, _taskForce param [2, []], "FULL", false, true] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
                            _taskForce set [4, [_responseGroup]];
                        };
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
                private _activeObjects = _taskForce param [8, []];
                if (_activeObjects isNotEqualTo []) exitWith {
                    _activeObjects findIf {
                        !isNull _x
                        && {!(_x isKindOf "Man")}
                        && {_x isKindOf "Air"}
                        && {_x getVariable ["KPLIB_captured", false]}
                    } < 0
                };
                (_composition getOrDefault ["vehicles", []]) isNotEqualTo []
            }
        ],
        [
            "onDecisionTick",
            {
                params ["_taskForceName", "_taskForce"];
                if ([_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_RELEASE_DISABLED_AIRCRAFT) exitWith {true};
                private _activeGroups = (_taskForce param [4, []]) select {!isNull _x && {units _x isNotEqualTo []}};
                private _activeObjects = _taskForce param [8, []];
                _taskForce set [4, _activeGroups];

                if (_activeObjects isNotEqualTo [] && {_activeGroups isNotEqualTo []}) then {
                    private _leader = leader (_activeGroups select 0);
                    if (!isNull _leader) then {_taskForce set [1, getPosATL _leader]};
                };

                private _done = false;
                if (!isNil "BATTLESPACE_AIR_RESPONSE_ON_DECISION_TICK") then {
                    _done = [_taskForceName, _taskForce] call BATTLESPACE_AIR_RESPONSE_ON_DECISION_TICK;
                };
                if (_done) exitWith {true};

                if (_activeObjects isEqualTo []) then {
                    [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                };
                false
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
