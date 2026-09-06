/*
    Finite strategic reconnaissance force: infiltrate, interdict, and return.

    TODO: Minic Russian DRG Tactics, as DRGs get behind the first frontline sectors of BLUFOR.
    They can also begin attempting to capture undefended sectors if there's 2+ DRGs nearby.
    They also seperate throughout the backlines using the exist arc type pattern we have.
    This will expand into a zone control mechanic for OPFOR in which DRGs will try to capture influence over in-between zones
    That will be between every connection of sectors. This basically means that if BLUFOR doesn't secure the sectors behind them,
    OPFOR can begin to capture the sectors behind BLUFOR, creating a dynamic frontline and potentially cutting off BLUFOR forces and collapsing fronts.
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
    [_taskForceId, _taskForce param [1, []], _destination, true] call QUEUE_PATHFIND_REQUEST;
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
    private _targetSector = _operation getOrDefault ["targetSector", ""];
    private _targetState = BATTLESPACE_SECTOR_STATES get _targetSector;
    private _routeInvalid = _targetSector == "" || {isNil "_targetState"};
    private _strengthLow = ([_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO)
        < (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RETREAT_STRENGTH_RATIO", 0.35]);
    private _finished = false;

    private _friendlyPlayerNearPatrol = {
        private _targetPosition = _operation getOrDefault ["targetPosition", _currentLocation];
        private _procRange = ["Deep Reconnaissance Patrol"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
        (allPlayers findIf {
            alive _x
            && {side group _x == GRLIB_side_friendly}
            && {
                _x distance2D _targetPosition <= _procRange
                || {_x distance2D _currentLocation <= _procRange}
            }
        }) >= 0
    };

    if (
        _phase != "RETURNING"
        && {!isNil "_targetState"}
        && {(_targetState getOrDefault ["owner", ""]) == "OPFOR"}
        && {!(call _friendlyPlayerNearPatrol)}
    ) exitWith {
        _operation set ["outcome", "REINFORCED"];
        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
        [format ["Deep Reconnaissance Patrol %1 was absorbed into %2", _taskForceId, _targetSector]] call BATTLESPACE_STRATEGIC_LOG;
        true
    };

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
                private _durationRange = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEEP_RECON_DURATION", [2400, 3600]];
                private _minimumDuration = (_durationRange param [0, 2400, [0]]) max 1;
                private _maximumDuration = (_durationRange param [1, 3600, [0]]) max _minimumDuration;
                private _duration = _minimumDuration + random (_maximumDuration - _minimumDuration);
                _operation set ["phase", _phase];
                _operation set ["expiresAt", CBA_missionTime + _duration];
                BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
                [format ["Deep Reconnaissance Patrol %1 began interdicting %2 for %3 minutes", _taskForceId, _targetSector, round (_duration / 60)]] call BATTLESPACE_STRATEGIC_LOG;
            };
            if (
                _phase == "OBSERVING"
                && {CBA_missionTime >= (_operation getOrDefault ["expiresAt", CBA_missionTime])}
                && {!(call _friendlyPlayerNearPatrol)}
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
    [_taskForceId, _taskForce, true] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
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
                        [_taskForceName, _taskForce, _success, true] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN;
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
