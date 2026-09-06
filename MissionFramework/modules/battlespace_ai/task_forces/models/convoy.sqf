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
                        private _finished = [_taskForceName, _taskForce, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN;
                        if (_finished) then {
                            private _registeredTaskForce = BATTLESPACE_TASK_FORCES get _taskForceName;
                            if (!isNil "_registeredTaskForce") then {
                                [_taskForceName, _registeredTaskForce] call BATTLESPACE_LOGISTICS_ATTACH_CONVOY_CRATES;
                            };
                        };
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
                private _allActiveObjects = +(_taskForce param [8, []]);
                {
                    if (
                        !isNull _x
                        && {_x getVariable ["BATTLESPACE_CONVOY_CARGO_CRATE", false]}
                        && {!(_x getVariable ["BATTLESPACE_CONVOY_CARGO_CLAIMED", false])}
                    ) then {
                        private _carrier = attachedTo _x;
                        private _originalCarrier = _x getVariable ["BATTLESPACE_CONVOY_CARGO_CARRIER", objNull];
                        if (!alive _x) then {
                            [_x, "crate destroyed"] call BATTLESPACE_LOGISTICS_CLAIM_CONVOY_CRATE;
                        } else {
                            if (isNull _carrier || {_carrier != _originalCarrier}) then {
                                [_x, "unloaded"] call BATTLESPACE_LOGISTICS_CLAIM_CONVOY_CRATE;
                            } else {
                                if (!alive _carrier) then {
                                    [_x, "carrier destroyed"] call BATTLESPACE_LOGISTICS_CLAIM_CONVOY_CRATE;
                                } else {
                                    if (_carrier getVariable ["KPLIB_captured", false]) then {
                                        [_x, "carrier captured"] call BATTLESPACE_LOGISTICS_CLAIM_CONVOY_CRATE;
                                    };
                                };
                            };
                        };
                    };
                } forEach _allActiveObjects;
                private _activeObjects = _allActiveObjects select {
                    !isNull _x && {alive _x}
                };
                _taskForce set [4, _activeGroups];
                _taskForce set [8, _activeObjects];

                private _forceObjects = _activeObjects select {
                    !(_x getVariable ["BATTLESPACE_CONVOY_CARGO_CRATE", false])
                    && {!(_x getVariable ["KPLIB_captured", false])}
                };
                if (_forceObjects isNotEqualTo []) exitWith { true };
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
                    private _purpose = _operation getOrDefault ["convoyPurpose", "RESUPPLY"];
                    private _targetSector = _operation getOrDefault ["targetSector", ""];
                    private _arrived = _currentLoc distance2D _destination <= 100;
                    private _targetIsOpfor = _targetSector != "" && {!(_targetSector in blufor_sectors)};
                    if (_targetIsOpfor) then {
                        [_targetSector, "OPFOR"] call BATTLESPACE_SECTOR_SET_OWNER;
                    };
                    if (_purpose == "EVACUATION" && {_phase == "ENROUTE"} && {_targetIsOpfor}) then {
                        private _sourceDepth = _operation getOrDefault ["evacuationSourceDepth", -1];
                        private _targetDepth = [_targetSector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
                        _targetIsOpfor = _targetDepth > _sourceDepth;
                        if (_targetIsOpfor && {_arrived}) then {
                            private _actualLoad = [_taskForce, _operation] call BATTLESPACE_LOGISTICS_BUILD_CONVOY_CURRENT_LOAD;
                            _targetIsOpfor = [_targetSector, _actualLoad] call BATTLESPACE_LOGISTICS_TARGET_CAN_ACCEPT_LOAD;
                        };
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
                            [_taskForceName, _currentLoc, _destination] call QUEUE_PATHFIND_REQUEST;
                            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                            if (_purpose == "EVACUATION") then {
                                [format [
                                    "Front-stock evacuation convoy %1 is returning to %2 because its deeper destination no longer honors ownership, depth, or capacity",
                                    _taskForceName,
                                    _sourceSector
                                ]] call BATTLESPACE_STRATEGIC_LOG;
                            };
                            false
                        } else {
                            _operation set ["outcome", "ABORTED"];
                            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                            if (_purpose == "EVACUATION") then {
                                [format [
                                    "Front-stock evacuation convoy %1 was lost after its destination became invalid and source %2 was unavailable",
                                    _taskForceName,
                                    _sourceSector
                                ]] call BATTLESPACE_STRATEGIC_LOG;
                            };
                            true
                        };
                    } else {
                        if (_arrived) then {
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
