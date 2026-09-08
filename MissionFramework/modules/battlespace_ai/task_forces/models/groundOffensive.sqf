/* Direct combat and quiet-period objective attacks retain the Battlegroup identity. */
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
    _operation deleteAt "captureStartedAt";
    _operation set ["targetPosition", +_destination];
    _operation set ["legDeadline", CBA_missionTime + BATTLESPACE_OFFENSIVE_LEG_TIMEOUT];
    _operation set ["lastProgressPosition", +(_taskForce select 1)];
    _operation set ["nextManeuverAt", CBA_missionTime + BATTLESPACE_OFFENSIVE_RETARGET_INTERVAL];
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
    params ["_id", "_taskForce", "_operation", ["_phase", "STAGING"]];
    _operation set ["phase", _phase];
    _operation set ["targetPosition", +(_taskForce select 1)];
    _operation set ["nextManeuverAt", CBA_missionTime];
    _taskForce set [2, []];
    [_id, _taskForce] call BATTLESPACE_OFFENSIVE_CANCEL_ORDERS;
    [_taskForce, _operation] call BATTLESPACE_OFFENSIVE_APPLY_POSTURE;
    [format ["Battlegroup %1 %2 at %3", _id, toLower _phase, _taskForce select 1]] call BATTLESPACE_STRATEGIC_LOG;
};

BATTLESPACE_OFFENSIVE_APPLY_POSTURE = {
    params ["_taskForce", "_operation"];
    private _phase = _operation getOrDefault ["phase", ""];
    if !(_phase in ["STAGING", "SECURING"]) exitWith {};
    if ((_taskForce param [2, []]) isNotEqualTo []) exitWith {};
    private _center = _operation getOrDefault ["targetPosition", _taskForce select 1];
    private _target = _operation getOrDefault ["targetSector", ""];
    private _facing = if (_target == "") then {_center getPos [100, 0]} else {getMarkerPos _target};
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
        private _mounted = isNull _parent && {units _x findIf {!isNull objectParent _x} >= 0};
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
    if (!isServer || {_taskForce param [11, false]}) exitWith {false};
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _id;
    if (isNil "_operation") exitWith {false};
    private _groups = (_taskForce param [4, []]) select {!isNull _x && {(units _x) findIf {alive _x} >= 0}};
    _taskForce set [4, _groups];
    if (_groups isNotEqualTo []) then {_taskForce set [1, getPos leader (_groups select 0)]};
    private _position = _taskForce select 1;
    private _phase = _operation getOrDefault ["phase", "STAGING"];
    private _arrive = BATTLESPACE_OFFENSIVE_ARRIVAL_RADIUS;
    private _return = {params ["_reason"]; [_id, _taskForce, _operation, _reason] call BATTLESPACE_OFFENSIVE_BEGIN_RETURN};
    if (_position distance2D (_operation getOrDefault ["lastProgressPosition", _position]) >= _arrive) then {
        _operation set ["lastProgressPosition", +_position];
        _operation set ["legDeadline", CBA_missionTime + BATTLESPACE_OFFENSIVE_LEG_TIMEOUT];
    };
    private _move = {
        if (_groups isEqualTo [] && {(_taskForce param [2, []]) isNotEqualTo []}
            && {(BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_id, []]) isNotEqualTo [] || {CBA_missionTime >= (_operation getOrDefault ["nextManeuverAt", 0])}}) then {
            [_id, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
        };
        false
    };
    if (_phase == "RETURNING") exitWith {
        private _home = _operation getOrDefault ["returnSector", _operation getOrDefault ["originSector", ""]];
        if (((BATTLESPACE_SECTOR_STATES getOrDefault [_home, createHashMap]) getOrDefault ["owner", ""]) != "OPFOR") exitWith {["return objective lost"] call _return};
        private _arrived = _position distance2D getMarkerPos _home <= _arrive;
        if (_arrived && {!(_home in active_sectors)} && {[_position, BATTLESPACE_UNIT_PROC_RANGE, GRLIB_side_friendly] call KPLIB_fnc_getUnitsCount == 0}) exitWith {
            _operation set ["outcome", "RETURNED"];
            true
        };
        if (!_arrived && {CBA_missionTime >= (_operation getOrDefault ["legDeadline", 0])}) then {
            [_id, _taskForce, _operation, "RETURNING", getMarkerPos _home, "retrying return with surviving paid assets"] call BATTLESPACE_OFFENSIVE_SET_LEG;
        };
        call _move
    };
    private _ratio = [_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO;
    if (_ratio < (_operation getOrDefault ["retreatRatio", 0.5])) exitWith {["combat losses exceed withdrawal threshold"] call _return};

    // Continue the current fight, but don't redirect another full formation to
    // an already covered report. Paid forces keep their existing staging orders.
    private _continuing = if (_phase == "ENGAGING") then {_operation getOrDefault ["targetPosition", []]} else {[]};
    private _strength = [_taskForce param [3, createHashMap]] call BATTLESPACE_OFFENSIVE_COMPOSITION_STRENGTH;
    private _source = _operation getOrDefault ["fundingSector", _operation getOrDefault ["originSector", ""]];
    private _contact = [_position, _source, _id, _continuing, _strength] call BATTLESPACE_OFFENSIVE_GET_CONTACT;
    if (_contact isNotEqualTo []) exitWith {
        private _known = _contact select 0;
        private _destination = _taskForce param [2, []];
        private _moved = _destination isEqualTo [] || {_destination distance2D _known >= BATTLESPACE_OFFENSIVE_RETARGET_DISTANCE};
        private _retry = CBA_missionTime >= (_operation getOrDefault ["legDeadline", 0]) && {_position distance2D _known > _arrive};
        if (_phase != "ENGAGING" || {(_moved || {_retry}) && {CBA_missionTime >= (_operation getOrDefault ["nextManeuverAt", 0])}}) then {
            _operation set ["targetSector", ""];
            _operation deleteAt "captureStartedAt";
            [_id, _taskForce, _operation, "ENGAGING", _known, "pursuing reported contact"] call BATTLESPACE_OFFENSIVE_SET_LEG;
        };
        call _move
    };
    if (_phase == "ENGAGING") then {
        [_id, _taskForce, _operation] call BATTLESPACE_OFFENSIVE_HOLD;
        _phase = "STAGING";
    };

    private _target = _operation getOrDefault ["targetSector", ""];
    private _capturable = blufor_sectors arrayIntersect sectors_allSectors;
    if (_phase == "ASSAULTING" && {!(_target in _capturable)}) then {
        if (_target != "" && {_position distance2D getMarkerPos _target <= GRLIB_capture_size + _arrive}
            && {((BATTLESPACE_SECTOR_STATES getOrDefault [_target, createHashMap]) getOrDefault ["owner", ""]) == "OPFOR"}) then {
            [_id, _taskForce, _operation, "SECURING"] call BATTLESPACE_OFFENSIVE_HOLD;
            _operation set ["holdUntil", CBA_missionTime + BATTLESPACE_OFFENSIVE_SECURE_DURATION];
            _phase = "SECURING";
        } else {
            _operation set ["targetSector", ""];
            _target = "";
            [_id, _taskForce, _operation] call BATTLESPACE_OFFENSIVE_HOLD;
            _phase = "STAGING";
        };
    };
    if (_phase == "SECURING" && {CBA_missionTime < (_operation getOrDefault ["holdUntil", 0])} && {!(_target in _capturable)}) exitWith {
        [_taskForce, _operation] call BATTLESPACE_OFFENSIVE_APPLY_POSTURE;
        false
    };
    if ([] call BATTLESPACE_OFFENSIVE_QUIET) exitWith {
        if !(_target in _capturable) then {_target = [_position, _id] call BATTLESPACE_OFFENSIVE_PICK_OBJECTIVE};
        if (_target == "") exitWith {
            if (_phase != "STAGING") then {[_id, _taskForce, _operation] call BATTLESPACE_OFFENSIVE_HOLD};
            false
        };
        _operation set ["targetSector", _target];
        if ((_operation getOrDefault ["stagePosition", []]) isEqualTo []) then {_operation set ["stagePosition", +_position]};
        if (_phase != "ASSAULTING") then {
            [_id, _taskForce, _operation, "ASSAULTING", getMarkerPos _target, "30 minutes without player sightings; capture objective"] call BATTLESPACE_OFFENSIVE_SET_LEG;
        };
        // The common capture monitor owns control, timing and the actual flip.
        if (_position distance2D getMarkerPos _target <= _arrive) exitWith {false};
        if (CBA_missionTime >= (_operation getOrDefault ["legDeadline", 0])) exitWith {["objective route stalled"] call _return};
        call _move
    };
    // Normalize older saved probe/shift plans in place, retaining their paid identity.
    if (_phase != "STAGING") then {
        [_id, _taskForce, _operation] call BATTLESPACE_OFFENSIVE_HOLD;
    };
    private _destination = _taskForce param [2, []];
    if (_destination isEqualTo []) exitWith {
        [_taskForce, _operation] call BATTLESPACE_OFFENSIVE_APPLY_POSTURE;
        false
    };
    if (_position distance2D _destination <= _arrive) exitWith {
        [_id, _taskForce, _operation] call BATTLESPACE_OFFENSIVE_HOLD;
        false
    };
    if (CBA_missionTime >= (_operation getOrDefault ["legDeadline", 0])) exitWith {["staging route stalled"] call _return};
    call _move
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
                private _holding = (_taskForce param [2, []]) isEqualTo [];
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
            if ((_taskForce param [2, []]) isEqualTo []) exitWith {};
            // The model owns disengagement; failed routes cannot teleport/delete it.
            private _retryAt = CBA_missionTime + BATTLESPACE_OFFENSIVE_RETURN_RETRY_INTERVAL;
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
