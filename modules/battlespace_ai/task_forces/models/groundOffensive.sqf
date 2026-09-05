/* A finite maneuver model using the established Battlegroup save identity. */
BATTLESPACE_OFFENSIVE_CANCEL_ORDERS = {
    params ["_id", "_taskForce"];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _id;
    BATTLESPACE_PATHFIND_REQUEST_GENERATIONS set [_id, 1 + (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_id, 0])];
    QUEUED_PATHFIND_REQUESTS = QUEUED_PATHFIND_REQUESTS select {(_x select 0) != _id};
    {
        if (isNull _x || {!local _x}) then {continue};
        // Cancel sleeping route/unload workers before changing the group's orders.
        _x setVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", 1 + (_x getVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", 0])];
        _x setVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", 1 + (_x getVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", 0])];
        _x setVariable ["BATTLESPACE_OFFENSIVE_POSTURE", nil];
        [_x, true, true] call KPLIB_fnc_taskReset;
    } forEach (_taskForce param [4, []]);
};

BATTLESPACE_OFFENSIVE_SET_LEG = {
    params ["_id", "_taskForce", "_operation", "_phase", "_destination", "_reason"];
    _operation set ["phase", _phase];
    _operation set ["targetPosition", +_destination];
    _operation set ["legDeadline", CBA_missionTime + BATTLESPACE_OFFENSIVE_LEG_TIMEOUT];
    _operation set ["lastProgressPosition", +(_taskForce select 1)];
    _operation set ["nextManeuverAt", CBA_missionTime + 60];
    _taskForce set [2, +_destination];
    [_id, _taskForce] call BATTLESPACE_OFFENSIVE_CANCEL_ORDERS;
    [_id, _taskForce select 1, _destination] call QUEUE_PATHFIND_REQUEST;
    [format ["Ground offensive %1 %2: %3", _id, toLower _phase, _reason]] call BATTLESPACE_STRATEGIC_LOG;
};

BATTLESPACE_OFFENSIVE_BEGIN_RETURN = {
    params ["_id", "_taskForce", "_operation", "_reason"];
    private _home = _operation getOrDefault ["returnSector", _operation getOrDefault ["originSector", ""]];
    if (((BATTLESPACE_SECTOR_STATES getOrDefault [_home, createHashMap]) getOrDefault ["owner", ""]) != "OPFOR") then {
        _home = [_taskForce select 1] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
    };
    if (_home == "") exitWith {_operation set ["outcome", "LOST"]; true};
    _operation set ["returnSector", _home];
    [_id, _taskForce, _operation, "RETURNING", getMarkerPos _home, _reason] call BATTLESPACE_OFFENSIVE_SET_LEG;
    false
};

BATTLESPACE_OFFENSIVE_HOLD = {
    params ["_id", "_taskForce", "_operation", ["_phase", "OBSERVING"]];
    _operation set ["phase", _phase];
    _operation set ["targetPosition", +(_taskForce select 1)];
    _operation set ["holdStrength", [_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO];
    private _duration = BATTLESPACE_OFFENSIVE_OBSERVE_DURATION;
    _operation set ["nextManeuverAt", CBA_missionTime + (_duration select 0) + random ((_duration select 1) - (_duration select 0))];
    _taskForce set [2, []];
    [_id, _taskForce] call BATTLESPACE_OFFENSIVE_CANCEL_ORDERS;
    [_taskForce, _operation] call BATTLESPACE_OFFENSIVE_APPLY_POSTURE;
    [format ["Ground offensive %1 %2 on the %3-%4 approach", _id, toLower _phase, _operation getOrDefault ["approachSector", ""], _operation getOrDefault ["targetSector", ""]]] call BATTLESPACE_STRATEGIC_LOG;
};

BATTLESPACE_OFFENSIVE_APPLY_POSTURE = {
    params ["_taskForce", "_operation"];
    private _phase = _operation getOrDefault ["phase", ""];
    if !(_phase in ["OBSERVING", "SECURING"]) exitWith {};
    private _center = _operation getOrDefault ["targetPosition", _taskForce select 1];
    private _facing = getMarkerPos (_operation getOrDefault ["targetSector", ""]);
    private _direction = _center getDir _facing;
    private _stamp = str [_phase, _center];
    {
        if (!local _x || {isNull leader _x} || {(_x getVariable ["BATTLESPACE_OFFENSIVE_POSTURE", ""]) == _stamp}) then {continue};
        _x setVariable ["BATTLESPACE_OFFENSIVE_POSTURE", _stamp];
        _x setBehaviourStrong "AWARE";
        _x setCombatMode "YELLOW";
        private _parent = _x getVariable ["BATTLESPACE_TRANSPORT_PARENT_GROUP", grpNull];
        if (!isNull _parent) then {
            {unassignVehicle _x; [_x] allowGetIn false} forEach units _x;
            doGetOut units _x;
            _x setVariable ["BATTLESPACE_TRANSPORT_PARENT_GROUP", nil];
            _parent setVariable ["BATTLESPACE_TRANSPORT_CARGO_GROUP", nil];
            _parent setVariable ["BATTLESPACE_TRANSPORT_VEHICLE", nil];
        };
        private _mounted = isNull _parent && {units _x findIf {vehicle _x != _x} >= 0};
        private _point = _center getPos [[70, 120] select _mounted, _direction + ([[-90, 90] select (_forEachIndex mod 2), 180] select _mounted)];
        if (surfaceIsWater _point || {(surfaceNormal _point select 2) < 0.85}) then {_point = _center};
        if (!_mounted) then {{unassignVehicle _x; [_x] allowGetIn false} forEach units _x};
        [_x, true, true] call KPLIB_fnc_taskReset;
        [_x, _point, _mounted, _stamp, _facing] spawn {
            params ["_group", "_point", "_mounted", "_stamp", "_facing"];
            [_group, _point, "LIMITED", false, _mounted, [getPos leader _group, _point]] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
            if ((_group getVariable ["BATTLESPACE_OFFENSIVE_POSTURE", ""]) != _stamp) exitWith {};
            {_x setWaypointBehaviour "AWARE"} forEach waypoints _group;
            _group setBehaviourStrong "AWARE";
            (leader _group) doWatch _facing;
        };
    } forEach (_taskForce param [4, []]);
};

BATTLESPACE_OFFENSIVE_ON_DECISION_TICK = {
    params ["_id", "_taskForce"];
    if (!isServer) exitWith {false};
    // Do not change a spawn's destination/phase before its physical groups publish.
    if (_taskForce param [11, false]) exitWith {false};
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _id;
    if (isNil "_operation") exitWith {false};
    private _groups = (_taskForce param [4, []]) select {!isNull _x && {(units _x) findIf {alive _x} >= 0}};
    _taskForce set [4, _groups];
    if (_groups isNotEqualTo []) then {_taskForce set [1, getPos leader (_groups select 0)]};
    private _position = _taskForce select 1;
    private _phase = _operation getOrDefault ["phase", ""];
    private _target = _operation getOrDefault ["targetSector", ""];
    private _anchor = _operation getOrDefault ["approachSector", ""];
    private _targetPosition = getMarkerPos _target;
    private _ratio = [_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO;
    private _arrive = BATTLESPACE_OFFENSIVE_ARRIVAL_RADIUS;
    private _return = {params ["_reason"]; [_id, _taskForce, _operation, _reason] call BATTLESPACE_OFFENSIVE_BEGIN_RETURN};
    if (_phase in ["STAGING", "PROBING", "SHIFTING", "PRESSING", "ASSAULTING", "RETURNING"]
        && {CBA_missionTime < (_operation getOrDefault ["legDeadline", 0])}
        && {_position distance2D (_operation getOrDefault ["lastProgressPosition", _position]) >= _arrive}) then {
        // A long but progressing march is not a failed path. The tour still expires.
        _operation set ["lastProgressPosition", +_position];
        _operation set ["legDeadline", CBA_missionTime + BATTLESPACE_OFFENSIVE_LEG_TIMEOUT];
    };

    if (_phase == "RETURNING") exitWith {
        private _home = _operation getOrDefault ["returnSector", _operation getOrDefault ["originSector", ""]];
        if (((BATTLESPACE_SECTOR_STATES getOrDefault [_home, createHashMap]) getOrDefault ["owner", ""]) != "OPFOR") exitWith {["return objective lost"] call _return};
        private _arrived = _position distance2D getMarkerPos _home <= _arrive;
        private _safe = !(_home in active_sectors) && {[_position, BATTLESPACE_UNIT_PROC_RANGE, GRLIB_side_friendly] call KPLIB_fnc_getUnitsCount == 0};
        if (_arrived && {_safe}) then {
            _operation set ["outcome", "RETURNED"];
            true
        } else {
            if (!_arrived && {CBA_missionTime >= (_operation getOrDefault ["legDeadline", 0])}) then {
                [_id, _taskForce, _operation, "RETURNING", getMarkerPos _home, "retrying the return route; retaining surviving assets"] call BATTLESPACE_OFFENSIVE_SET_LEG;
            };
            private _routeReady = (BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_id, []]) isNotEqualTo [];
            if (_groups isEqualTo [] && {!_arrived} && {_routeReady || {CBA_missionTime >= (_operation getOrDefault ["nextManeuverAt", 0])}}) then {[_id, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP};
            false
        }
    };
    // Invalid plans (including already-paid forces with no approach assignment)
    // return through their existing identity; never convert or recreate a save.
    if (_anchor == "" || {_target == ""} || {(_operation getOrDefault ["stagePosition", []]) isEqualTo []}) exitWith {["no usable approach assignment"] call _return};
    if (((BATTLESPACE_SECTOR_STATES getOrDefault [_anchor, createHashMap]) getOrDefault ["owner", ""]) != "OPFOR") exitWith {["approach anchor lost"] call _return};
    if (_ratio < (_operation getOrDefault ["retreatRatio", 0.5])) exitWith {["combat losses exceed the force's withdrawal threshold"] call _return};
    if (CBA_missionTime >= (_operation getOrDefault ["expiresAt", CBA_missionTime])) exitWith {["operation window ended"] call _return};
    if !(_target in blufor_sectors) then {
        if (_phase != "SECURING") then {
            if (_phase == "ASSAULTING" && {_position distance2D _targetPosition <= GRLIB_capture_size + _arrive}) then {
                [_id, _taskForce, _operation, "SECURING"] call BATTLESPACE_OFFENSIVE_HOLD;
                _operation set ["holdUntil", CBA_missionTime + BATTLESPACE_OFFENSIVE_SECURE_DURATION];
                _phase = "SECURING";
            } else {_phase = "RETURNING"};
        };
    };
    if (_phase == "RETURNING") exitWith {["objective already secured by another force"] call _return};
    if (_phase == "SECURING") exitWith {
        if (_target in blufor_sectors) exitWith {["secured objective was lost again"] call _return};
        if (CBA_missionTime >= (_operation getOrDefault ["holdUntil", 0])) exitWith {["survivors completed their security hold"] call _return};
        [_taskForce, _operation] call BATTLESPACE_OFFENSIVE_APPLY_POSTURE;
        false
    };
    private _forward = (getMarkerPos _anchor) vectorFromTo _targetPosition;
    private _contact = [_position, _forward] call BATTLESPACE_OFFENSIVE_GET_CONTACT;
    _contact params ["_knownPosition", "_threat", "_reportedAt", "_receding"];
    private _composition = _taskForce select 3;
    private _strength = (_composition getOrDefault ["manpower", 0]) + 4 * count (_composition getOrDefault ["vehicles", []]);
    private _strongOpposition = _threat >= _strength;
    private _shift = {
        if ((_operation getOrDefault ["shifts", 0]) >= BATTLESPACE_OFFENSIVE_MAX_SHIFTS) exitWith {["no useful opening after bounded repositioning"] call _return};
        private _flank = -(_operation getOrDefault ["flank", 1]);
        private _point = [_anchor, _target, _position, "SHIFT", _flank] call BATTLESPACE_OFFENSIVE_PICK_POSITION;
        if (_point isEqualTo []) exitWith {["no reachable terrain candidate for disengagement"] call _return};
        _operation set ["shifts", 1 + (_operation getOrDefault ["shifts", 0])];
        _operation set ["flank", _flank];
        [_id, _taskForce, _operation, "SHIFTING", _point, "giving ground and changing the angle"] call BATTLESPACE_OFFENSIVE_SET_LEG;
        false
    };
    if (_phase in ["PROBING", "PRESSING", "ASSAULTING"] && {_strongOpposition} && {CBA_missionTime >= (_operation getOrDefault ["nextManeuverAt", 0])}) exitWith {call _shift};
    if (_phase in ["STAGING", "PROBING", "SHIFTING", "PRESSING"]) exitWith {
        private _destination = _taskForce param [2, []];
        if (_destination isEqualTo []) exitWith {["maneuver destination missing"] call _return};
        if (_position distance2D _destination <= _arrive) exitWith {
            [_id, _taskForce, _operation] call BATTLESPACE_OFFENSIVE_HOLD;
            false
        };
        if (CBA_missionTime >= (_operation getOrDefault ["legDeadline", 0])) exitWith {["maneuver stalled"] call _return};
        if (_groups isEqualTo []) then {[_id, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP};
        false
    };
    if (_phase == "ASSAULTING") exitWith {
        // The common sector monitor alone owns confirmation, capture time and flip.
        if (_position distance2D _targetPosition <= _arrive) exitWith {false};
        if (CBA_missionTime >= (_operation getOrDefault ["legDeadline", 0])) exitWith {["objective approach stalled"] call _return};
        if (_groups isEqualTo []) then {[_id, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP};
        false
    };
    if (_phase != "OBSERVING") exitWith {["unsupported maneuver state"] call _return};
    [_taskForce, _operation] call BATTLESPACE_OFFENSIVE_APPLY_POSTURE;
    if (CBA_missionTime < (_operation getOrDefault ["nextManeuverAt", CBA_missionTime])) exitWith {false};
    if (_strongOpposition || {_ratio < (_operation getOrDefault ["holdStrength", _ratio]) - 0.1}) exitWith {call _shift};
    private _probes = _operation getOrDefault ["probes", 0];
    private _capturedAt = (missionNamespace getVariable ["blufor_sectors_cap_times", createHashMap]) getOrDefault [_target, -1e9];
    private _recentCapture = CBA_missionTime - _capturedAt <= BATTLESPACE_OFFENSIVE_RECENT_CAPTURE_WINDOW;
    private _opening = _probes > 0 && {(_threat > 0 && {_threat < _strength * ([0.45, 0.80] select _receding)}) || {_recentCapture && {_threat == 0}}};
    if (_opening) exitWith {
        if (_position distance2D _targetPosition <= BATTLESPACE_OFFENSIVE_TARGET_STANDOFF + BATTLESPACE_OFFENSIVE_STEP_DISTANCE) exitWith {
            [_id, _taskForce, _operation, "ASSAULTING", _targetPosition, "exploiting the controlled approach toward the objective"] call BATTLESPACE_OFFENSIVE_SET_LEG;
            false
        };
        private _point = [_anchor, _target, _position, "PRESS"] call BATTLESPACE_OFFENSIVE_PICK_POSITION;
        if (_point isEqualTo []) exitWith {call _shift};
        [_id, _taskForce, _operation, "PRESSING", _point, "limited advance against a reported opening"] call BATTLESPACE_OFFENSIVE_SET_LEG;
        false
    };
    if (_probes < BATTLESPACE_OFFENSIVE_MAX_PROBES && {_threat > 0 || {_recentCapture}}) exitWith {
        private _point = [_anchor, _target, _position, "PROBE"] call BATTLESPACE_OFFENSIVE_PICK_POSITION;
        if (_point isEqualTo []) exitWith {call _shift};
        _operation set ["probes", _probes + 1];
        [_id, _taskForce, _operation, "PROBING", _point, "testing ground before committing to an assault"] call BATTLESPACE_OFFENSIVE_SET_LEG;
        false
    };
    call _shift
};

[
    "Battlegroup",
    createHashMapFromArray [
        ["canProc", {
            params ["_id", "_taskForce"];
            private _position = _taskForce select 1;
            private _range = ["Battlegroup"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
            (BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS findIf {(_x get "Position") distance2D _position <= _range}) >= 0
            // AI garrisons must meet physical attackers even without human players.
            || {[_position, _range, GRLIB_side_friendly] call KPLIB_fnc_getUnitsCount > 0}
        }],
        ["doSpawn", {
            params ["_id", "_taskForce"];
            if (_taskForce param [11, false]) exitWith {};
            _taskForce set [11, true];
            [_id, _taskForce] spawn {
                params ["_id", "_taskForce"];
                private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_id, createHashMap];
                private _holding = (_operation getOrDefault ["phase", ""]) in ["OBSERVING", "SECURING"];
                private _success = [_id, _taskForce, false, false, false, false, "NORMAL", [], !_holding] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
                if ([_id, _taskForce, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN) then {
                    [BATTLESPACE_TASK_FORCES get _id, _operation] call BATTLESPACE_OFFENSIVE_APPLY_POSTURE;
                };
            };
        }],
        ["onPathFailed", {
            params ["_id", "_taskForce"];
            BATTLESPACE_TASK_FORCE_PATHS deleteAt _id;
            private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_id, createHashMap];
            private _phase = _operation getOrDefault ["phase", ""];
            if (_phase in ["OBSERVING", "SECURING"]) exitWith {};
            // The model owns disengagement; failed routes cannot teleport/delete it.
            private _retryAt = CBA_missionTime + ([0, BATTLESPACE_OFFENSIVE_DECISION_INTERVAL] select (_phase == "RETURNING"));
            _operation set ["legDeadline", _retryAt];
            _operation set ["nextManeuverAt", _retryAt];
            [format ["Ground offensive %1 route failed during %2; retaining its force for withdrawal/retry", _id, toLower _phase]] call BATTLESPACE_STRATEGIC_LOG;
        }],
        ["isAlive", {
            params ["_id", "_taskForce"];
            private _composition = _taskForce param [3, createHashMap];
            (_composition getOrDefault ["manpower", 0]) > 0 || {(_composition getOrDefault ["vehicles", []]) isNotEqualTo []}
        }],
        ["onDecisionTick", BATTLESPACE_OFFENSIVE_ON_DECISION_TICK]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
