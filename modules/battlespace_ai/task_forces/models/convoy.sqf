[
    "Convoy",
    createHashMapFromArray [
        [
            "canProc",
            {
                params ["_taskForceName", "_taskForce"];
                private _currentLoc = _taskForce param [1, []];
                private _meetsRequirement = false;
                private _requiredPlayers = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
                private _procRange = ["Convoy"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
                {
                    if (count (_x get "Players") < _requiredPlayers) then { continue };
                    if ((_x get "Position") distance2D _currentLoc <= _procRange) exitWith {
                        _meetsRequirement = true;
                    };
                } forEach BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS;
                _meetsRequirement
            }
        ],
        [
            "doSpawn",
            {
                params ["_taskForceName", "_taskForce"];
                if !(_taskForce param [11, false]) then {
                    _taskForce set [11, true];
                    [_taskForceName, _taskForce] spawn {
                        params ["_taskForceName", "_taskForce"];
                        private _success = [_taskForceName, _taskForce, false, true] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
                        if (_success) then {
                            BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
                        };
                        [_taskForceName, _taskForce, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN;
                    };
                };
            }
        ],
        [
            "isAlive",
            {
                params ["_taskForceName", "_taskForce"];
                private _composition = _taskForce param [3, createHashMap];
                private _activeGroups = (_taskForce param [4, []]) select {
                    !isNull _x && {units _x findIf {alive _x} >= 0}
                };
                private _activeObjects = (_taskForce param [8, []]) select {
                    !isNull _x && {alive _x}
                };
                _taskForce set [4, _activeGroups];
                _taskForce set [8, _activeObjects];

                if (_activeObjects isNotEqualTo []) exitWith { true };
                (_composition getOrDefault ["manpower", 0]) >= BATTLESPACE_TASK_FORCE_MINIMUM_SIZE
                || {(_composition getOrDefault ["vehicles", []]) isNotEqualTo []}
            }
        ],
        [
            "onDecisionTick",
            {
                params ["_taskForceName", "_taskForce"];
                private _currentLoc = _taskForce param [1, []];
                private _destination = _taskForce param [2, []];
                private _activeGroups = _taskForce param [4, []];

                if (_activeGroups isNotEqualTo []) then {
                    private _leader = leader (_activeGroups select 0);
                    if (!isNull _leader) then {
                        _currentLoc = getPos _leader;
                        _taskForce set [1, _currentLoc];
                    };
                };

                private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceName;
                if (!isNil "_operation") then {
                    private _phase = _operation getOrDefault ["phase", "ENROUTE"];
                    private _targetSector = _operation getOrDefault ["targetSector", ""];
                    private _targetIsOpfor = !(_targetSector in blufor_sectors);
                    if (_targetIsOpfor) then {
                        [_targetSector, "OPFOR"] call BATTLESPACE_SECTOR_SET_OWNER;
                    };

                    if (_phase == "ENROUTE" && {!_targetIsOpfor}) then {
                        private _sourceSector = _operation getOrDefault ["sourceSector", ""];
                        if (
                            _sourceSector != ""
                            && {!(_sourceSector in blufor_sectors)}
                        ) then {
                            [_sourceSector, "OPFOR"] call BATTLESPACE_SECTOR_SET_OWNER;
                            _phase = "RETURNING";
                            _destination = getMarkerPos _sourceSector;
                            _operation set ["phase", _phase];
                            _taskForce set [2, _destination];
                            BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
                            {
                                private _hasVehicles = [_x] call BATTLESPACE_TASK_FORCE_HAS_VEHICLES;
                                [_x, _destination, "FULL", false, _hasVehicles] spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
                            } forEach _activeGroups;
                            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                            false
                        } else {
                            _operation set ["outcome", "ABORTED"];
                            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                            true
                        };
                    } else {
                        if (_currentLoc distance2D _destination <= 100) then {
                            _operation set ["outcome", ["DELIVERED", "RETURNED"] select (_phase == "RETURNING")];
                            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                            true
                        } else {
                            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                            if (_activeGroups isEqualTo []) then {
                                [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                            };
                            false
                        }
                    }
                } else {
                    if (_activeGroups isNotEqualTo []) exitWith { false };
                    if (_currentLoc distance2D _destination <= 100) exitWith { true };
                    [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                    false
                }
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
