[
    "Mobile Reserve",
    createHashMapFromArray [
        ["canProc", BATTLESPACE_TASK_FORCE_DEFENSE_MODEL_CAN_PROC],
        [
            "doSpawn",
            {
                params ["_taskForceName", "_taskForce"];
                if (_taskForce param [11, false]) exitWith {};
                _taskForce set [11, true];
                [_taskForceName, _taskForce] spawn {
                    params ["_taskForceName", "_taskForce"];
                    private _success = [_taskForceName, _taskForce, false, false, false, false, "FULL"] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
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
                if (isNil "_operation" || {(_operation getOrDefault ["kind", ""]) != "RESERVE"}) exitWith {false};

                private _activeGroups = (_taskForce param [4, []]) select {!isNull _x && {(units _x) findIf {alive _x} >= 0}};
                _taskForce set [4, _activeGroups];
                private _currentLocation = _taskForce param [1, []];
                if (_activeGroups isNotEqualTo []) then {
                    private _leader = leader (_activeGroups select 0);
                    if (!isNull _leader) then {_currentLocation = getPos _leader; _taskForce set [1, _currentLocation]};
                };

                private _homeSector = _operation getOrDefault ["assignedSector", _operation getOrDefault ["originSector", ""]];
                private _homeState = BATTLESPACE_SECTOR_STATES get _homeSector;
                private _homeRelocated = false;
                if (_homeSector == "" || {isNil "_homeState"} || {(_homeState getOrDefault ["owner", ""]) != "OPFOR"}) then {
                    _homeSector = [_currentLocation] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
                    _operation set ["assignedSector", _homeSector];
                    _operation set ["originSector", _homeSector];
                    _homeRelocated = true;
                };
                if (_homeSector == "") exitWith {
                    _operation set ["outcome", "LOST"];
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                    true
                };

                private _phase = _operation getOrDefault ["phase", "READY"];
                private _composition = _taskForce param [3, createHashMap];
                private _minimumManpower = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESERVE_MINIMUM_MANPOWER", 8];
                private _mustDemobilize = (_composition getOrDefault ["manpower", 0]) < _minimumManpower
                    || {(_composition getOrDefault ["vehicles", []]) isEqualTo []};
                private _homeQuiet = !(_homeSector in (missionNamespace getVariable ["active_sectors", []]));
                private _beginReturn = {
                    params ["_reason"];
                    private _destination = getMarkerPos _homeSector;
                    _operation set ["phase", "RETURNING"];
                    _operation set ["returnSector", _homeSector];
                    _operation set ["demobilizeOnReturn", _mustDemobilize];
                    _taskForce set [2, _destination];
                    BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                    {
                        [_x, true, true] call KPLIB_fnc_taskReset;
                        _x setVariable ["BATTLESPACE_DEFENDER_RETURNING", true];
                    } forEach _activeGroups;
                    [_taskForceName, _currentLocation, _destination] call QUEUE_PATHFIND_REQUEST;
                    [format ["Mobile reserve %1 returning to %2 because %3", _taskForceName, _homeSector, _reason]] call BATTLESPACE_STRATEGIC_LOG;
                };

                if (_mustDemobilize && {_phase != "RETURNING"} && {_phase != "READY" || {_homeQuiet}}) then {
                    ["its deployable strength fell below the reserve minimum"] call _beginReturn;
                    _phase = "RETURNING";
                };
                if (_homeRelocated && {_phase in ["READY", "STAGING"]}) then {
                    ["its staging objective was lost"] call _beginReturn;
                    _phase = "RETURNING";
                };

                if (_phase == "READY") exitWith {
                    _taskForce set [2, []];
                    _operation set ["targetSector", ""];
                    _operation set ["pressureSector", ""];
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                    false
                };

                if (_phase == "RESPONDING") then {
                    private _targetSector = _operation getOrDefault ["targetSector", ""];
                    private _targetState = BATTLESPACE_SECTOR_STATES get _targetSector;
                    if (_targetSector == "" || {isNil "_targetState"} || {(_targetState getOrDefault ["owner", ""]) != "OPFOR"}) then {
                        ["its response objective was lost"] call _beginReturn;
                        _phase = "RETURNING";
                    } else {
                        private _arrivalRadius = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESERVE_ARRIVAL_RADIUS", 150];
                        if (_currentLocation distance2D (getMarkerPos _targetSector) <= _arrivalRadius) then {
                            _operation set ["phase", "HOLDING"];
                            _operation set ["holdUntil", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESERVE_HOLD_DURATION", 900])];
                            _taskForce set [2, []];
                            BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
                            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                            {
                                [_x, true, true] call KPLIB_fnc_taskReset;
                                [_x, getMarkerPos _targetSector, 300, 4, [], false, true] call KPLIB_fnc_taskPatrol;
                            } forEach _activeGroups;
                            [format ["Mobile reserve %1 reached %2 and is holding the response area", _taskForceName, _targetSector]] call BATTLESPACE_STRATEGIC_LOG;
                            _phase = "HOLDING";
                        };
                    };
                };

                if (_phase == "HOLDING") then {
                    private _targetSector = _operation getOrDefault ["targetSector", ""];
                    private _targetState = BATTLESPACE_SECTOR_STATES get _targetSector;
                    if (_targetSector == "" || {isNil "_targetState"} || {(_targetState getOrDefault ["owner", ""]) != "OPFOR"}) then {
                        ["its held objective was lost"] call _beginReturn;
                        _phase = "RETURNING";
                    } else {
                        private _holdComplete = CBA_missionTime >= (_operation getOrDefault ["holdUntil", CBA_missionTime]);
                        private _sectorQuiet = !(_targetSector in (missionNamespace getVariable ["active_sectors", []]));
                        if (_holdComplete && {_sectorQuiet}) then {
                            ["its response hold completed"] call _beginReturn;
                            _phase = "RETURNING";
                        };
                    };
                };

                if (_phase in ["STAGING", "RETURNING"]) exitWith {
                    private _destination = getMarkerPos _homeSector;
                    private _arrivalRadius = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESERVE_ARRIVAL_RADIUS", 150];
                    private _arrived = if (_activeGroups isNotEqualTo []) then {
                        _activeGroups findIf {
                            private _groupLeader = leader _x;
                            isNull _groupLeader || {_groupLeader distance2D _destination > _arrivalRadius}
                        } < 0
                    } else {
                        _currentLocation distance2D _destination <= _arrivalRadius
                    };
                    if (_arrived && {_homeQuiet || {_phase == "STAGING" && {!_mustDemobilize}}}) then {
                        if (_operation getOrDefault ["demobilizeOnReturn", _mustDemobilize]) then {
                            _operation set ["outcome", "RETURNED"];
                            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                            [format ["Mobile reserve %1 returned to %2 and demobilized its survivors into stock", _taskForceName, _homeSector]] call BATTLESPACE_STRATEGIC_LOG;
                            true
                        } else {
                            _operation set ["phase", "READY"];
                            _operation set ["targetSector", ""];
                            _operation set ["pressureSector", ""];
                            _operation deleteAt "returnSector";
                            _operation deleteAt "holdUntil";
                            _operation deleteAt "demobilizeOnReturn";
                            _taskForce set [2, []];
                            BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
                            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                            {
                                _x setVariable ["BATTLESPACE_DEFENDER_RETURNING", false];
                                [_x, true, true] call KPLIB_fnc_taskReset;
                                [_x, _destination, 300, 4, [], false, true] call KPLIB_fnc_taskPatrol;
                            } forEach _activeGroups;
                            [format ["Mobile reserve %1 is ready at %2 after %3", _taskForceName, _homeSector, toLower _phase]] call BATTLESPACE_STRATEGIC_LOG;
                            false
                        };
                    } else {
                        if (_activeGroups isEqualTo []) then {
                            [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                        };
                        false
                    }
                };

                if (_phase == "RESPONDING") then {
                    if (_activeGroups isEqualTo []) then {
                        [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                    };
                };
                false
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
