/*
    Finite strategic reconnaissance force: infiltrate, observe, and return.
*/

BATTLESPACE_DEEP_RECON_BEGIN_RETURN = {
    params ["_taskForceId", "_taskForce", "_operation", ["_reason", "mission complete"]];
    private _returnSector = _operation getOrDefault ["originSector", ""];
    private _returnState = BATTLESPACE_SECTOR_STATES get _returnSector;

    if (isNil "_returnState" || {(_returnState getOrDefault ["owner", ""]) != "OPFOR"}) then {
        _returnSector = [(_taskForce param [1, [0, 0, 0]])] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
    };
    if (_returnSector == "") exitWith {
        _operation set ["outcome", "LOST"];
        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
        [format ["Deep Reconnaissance Patrol %1 was lost because no OPFOR return sector exists", _taskForceId], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };

    private _destination = getMarkerPos _returnSector;
    _operation set ["phase", "RETURNING"];
    _operation set ["originSector", _returnSector];
    _taskForce set [2, _destination];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceId;
    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
    BATTLESPACE_TASK_FORCES set [_taskForceId, _taskForce];
    [_taskForceId, _taskForce param [1, []], _destination] call QUEUE_PATHFIND_REQUEST;
    [format ["Deep Reconnaissance Patrol %1 returning to %2 (%3)", _taskForceId, _returnSector, _reason]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_DEEP_RECON_ON_DECISION_TICK = {
    params ["_taskForceId", "_taskForce"];
    private _activeGroups = _taskForce param [4, []];
    private _currentLocation = _taskForce param [1, []];

    if (_activeGroups isNotEqualTo []) then {
        private _leader = leader (_activeGroups select 0);
        if (!isNull _leader) then {
            _currentLocation = getPos _leader;
            _taskForce set [1, _currentLocation];
        };
    };

    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    if (isNil "_operation") exitWith {
        [format ["Deep Reconnaissance Patrol %1 has no strategic operation", _taskForceId], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        [_taskForce] call BATTLESPACE_STRATEGIC_RETIRE_PHYSICAL_FORCE;
        true
    };

    private _phase = _operation getOrDefault ["phase", "INFILTRATING"];
    private _originSector = _operation getOrDefault ["originSector", ""];
    private _targetSector = _operation getOrDefault ["targetSector", ""];
    private _originState = BATTLESPACE_SECTOR_STATES get _originSector;
    private _routeInvalid = _targetSector == ""
        || {!(_targetSector in blufor_sectors)}
        || {isNil "_originState"}
        || {(_originState getOrDefault ["owner", ""]) != "OPFOR"};
    private _strengthLow = ([_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO)
        < (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RETREAT_STRENGTH_RATIO", 0.35]);
    private _finished = false;

    if (_phase != "RETURNING" && {_routeInvalid || {_strengthLow}}) then {
        private _returnReason = if (_routeInvalid) then {"route invalid"} else {"combat losses"};
        if ([_taskForceId, _taskForce, _operation, _returnReason] call BATTLESPACE_DEEP_RECON_BEGIN_RETURN) then {
            _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
            _phase = "RETURNING";
        } else {
            _finished = true;
        };
    };
    if (_finished) exitWith {true};

    if (_phase in ["INFILTRATING", "OBSERVING"]) then {
        private _observationPosition = _operation getOrDefault ["targetPosition", []];
        private _positionValid = _observationPosition isEqualType []
            && {(count _observationPosition) in [2, 3]}
            && {_observationPosition findIf {!(_x isEqualType 0)} < 0};

        if (!_positionValid) then {
            [format ["Deep Reconnaissance Patrol %1 has an invalid observation position", _taskForceId], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
            if ([_taskForceId, _taskForce, _operation, "invalid observation position"] call BATTLESPACE_DEEP_RECON_BEGIN_RETURN) then {
                _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
                _phase = "RETURNING";
            } else {
                _finished = true;
            };
        } else {
            if (_phase == "INFILTRATING" && {_currentLocation distance2D _observationPosition <= 100}) then {
                _phase = "OBSERVING";
                _operation set ["phase", _phase];
                _operation set ["expiresAt", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEEP_RECON_DURATION", 1200])];
                BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
                [format ["Deep Reconnaissance Patrol %1 began observing %2", _taskForceId, _targetSector]] call BATTLESPACE_STRATEGIC_LOG;
            };
            if (
                _phase == "OBSERVING"
                && {CBA_missionTime >= (_operation getOrDefault ["expiresAt", CBA_missionTime])}
            ) then {
                if ([_taskForceId, _taskForce, _operation, "observation complete"] call BATTLESPACE_DEEP_RECON_BEGIN_RETURN) then {
                    _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
                    _phase = "RETURNING";
                } else {
                    _finished = true;
                };
            };
        };
    };
    if (_finished) exitWith {true};

    if (_phase == "RETURNING") then {
        private _returnSector = _operation getOrDefault ["originSector", ""];
        private _returnState = BATTLESPACE_SECTOR_STATES get _returnSector;
        if (isNil "_returnState" || {(_returnState getOrDefault ["owner", ""]) != "OPFOR"}) then {
            if ([_taskForceId, _taskForce, _operation, "return sector lost"] call BATTLESPACE_DEEP_RECON_BEGIN_RETURN) then {
                _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
                _returnSector = _operation getOrDefault ["originSector", ""];
            } else {
                _finished = true;
            };
        };
        if (!_finished && {_returnSector != ""} && {_currentLocation distance2D (getMarkerPos _returnSector) <= 100}) then {
            _operation set ["outcome", "RETURNED"];
            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
            [format ["Deep Reconnaissance Patrol %1 returned to %2", _taskForceId, _returnSector]] call BATTLESPACE_STRATEGIC_LOG;
            _finished = true;
        };
    };
    if (_finished) exitWith {true};

    if (_activeGroups isNotEqualTo [] || {_phase == "OBSERVING"}) exitWith {false};
    [_taskForceId, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
    false
};

[
    "Deep Reconnaissance Patrol",
    createHashMapFromArray [
        [
            "canProc",
            {
                params ["_taskForceName", "_taskForce"];
                private _currentLocation = _taskForce param [1, []];
                private _requiredPlayers = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
                private _procRange = ["Deep Reconnaissance Patrol"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
                (BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS findIf {
                    count (_x get "Players") >= _requiredPlayers
                    && {(_x get "Position") distance2D _currentLocation <= _procRange}
                }) >= 0
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
                        private _success = [_taskForceName, _taskForce, false] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
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

                if (_activeObjects isNotEqualTo []) exitWith {true};
                (_composition getOrDefault ["manpower", 0]) >= BATTLESPACE_TASK_FORCE_MINIMUM_SIZE
                || {(_composition getOrDefault ["vehicles", []]) isNotEqualTo []}
            }
        ],
        [
            "onDecisionTick",
            {
                _this call BATTLESPACE_DEEP_RECON_ON_DECISION_TICK
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
