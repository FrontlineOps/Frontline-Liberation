BATTLESPACE_DEFENSE_FIND_SOURCE_RESULT = {
    params ["_targetSector", "_manpowerCost"];
    private _depth = [_targetSector] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
    private _candidates = [];
    private _reachable = false;
    private _quiet = false;
    {
        if (_x == _targetSector || {(_y getOrDefault ["owner", ""]) != "OPFOR"}) then {continue};
        if ([_x] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH <= _depth) then {continue};
        private _distance = [_x, _targetSector, 12] call BATTLESPACE_DEFENSE_GRAPH_DISTANCE;
        if (_distance < 0) then {continue};
        _reachable = true;
        if !([_x, _y] call BATTLESPACE_DEFENSE_SOURCE_IS_AVAILABLE) then {continue};
        _quiet = true;
        private _capacity = [_x, "manpower"] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        private _stock = (_y getOrDefault ["resources", createHashMap]) getOrDefault ["manpower", 0];
        if (_stock - _manpowerCost < ceil (_capacity * BATTLESPACE_STRATEGIC_DEFENDER_SOURCE_RESERVE_RATIO)) then {continue};
        _candidates pushBack [_distance, _x];
    } forEach BATTLESPACE_SECTOR_STATES;
    _candidates sort true;
    if (_candidates isNotEqualTo []) exitWith {[(_candidates select 0) select 1, ""]};
    ["", if (!_reachable) then {"No reachable rear supplier"} else {if (!_quiet) then {"Reachable suppliers are active or recovering from combat"} else {"Rear suppliers cannot spare the required manpower"}}]
};

BATTLESPACE_DEFENSE_RESET_GROUP = {
    params ["_group"];
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    if (isNull _group || {!local _group}) exitWith {};
    [_group, true, true] call KPLIB_fnc_taskReset;
    _group setVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", 1 + (_group getVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", 0])];
    _group setVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", 1 + (_group getVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", 0])];
    _group setVariable ["BATTLESPACE_DEFENDER_RETURNING", false];
    _group setVariable ["BATTLESPACE_RESERVE_FIELD_HUNT", false];
    _group setBehaviourStrong "AWARE";
    _group setCombatMode "YELLOW";
    {if (alive _x && {!captive _x}) then {_x enableAI "PATH"; _x forceSpeed -1; _x setUnitPos "AUTO"; _x doFollow leader _group}} forEach units _group;
};

BATTLESPACE_DEFENSE_APPLY_ROUTE = {
    params ["_group", "_destination", "_route", "_role", "_returning"];
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    if (isNull _group || {!local _group}) exitWith {};
    [_group] call BATTLESPACE_DEFENSE_RESET_GROUP;
    _group setVariable ["BATTLESPACE_DEFENDER_RETURNING", _returning];
    _group setVariable ["BATTLESPACE_COVERAGE_ROLE", _role];
    if (!isNull (_group getVariable ["BATTLESPACE_TRANSPORT_PARENT_GROUP", grpNull])) exitWith {};
    private _vehicle = _group getVariable ["BATTLESPACE_TRANSPORT_VEHICLE", objNull];
    private _cargo = _group getVariable ["BATTLESPACE_TRANSPORT_CARGO_GROUP", grpNull];
    if (!isNull _vehicle && {!isNull _cargo}) then {
        [_vehicle, _group, _cargo, _destination, false, _route] spawn BATTLESPACE_TASK_FORCE_TRANSPORT_AI;
    } else {
        [_group, _destination, "LIMITED", false, [_group] call BATTLESPACE_TASK_FORCE_HAS_VEHICLES, _route] spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
    };
};

BATTLESPACE_DEFENSE_GARRISON_GROUP = {
    params ["_group", "_position", "_buildingPosition"];
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    if (isNull _group || {!local _group}) exitWith {};
    [_group] call BATTLESPACE_DEFENSE_RESET_GROUP;
    if (_buildingPosition isEqualTo []) then {
        [_group, _position, 150, 4, [], false, true] call KPLIB_fnc_taskPatrol;
    } else {
        [_group, _buildingPosition] call KPLIB_fnc_garrison;
    };
};

BATTLESPACE_DEFENSE_AMBUSH_GROUP = {
    params ["_group", "_engaged"];
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    if (isNull _group || {!local _group}) exitWith {};
    [_group] call BATTLESPACE_DEFENSE_RESET_GROUP;
    _group setBehaviourStrong (["STEALTH", "COMBAT"] select _engaged);
    _group setCombatMode (["GREEN", "RED"] select _engaged);
    _group setSpeedMode "LIMITED";
    {
        if (!alive _x || {captive _x}) then {continue};
        if (_engaged) then {_x doFollow leader _group} else {doStop _x; _x setUnitPos "MIDDLE"};
    } forEach units _group;
};

BATTLESPACE_DEFENSE_SET_ASSIGNMENT = {
    params ["_id", "_force", "_operation", "_assignmentId", "_assignment"];
    private _field = (_assignment get "kind") == "FIELD";
    private _role = _assignment get "role";
    private _definition = (BATTLESPACE_STRATEGIC_DEFENDER_ROLES select {(_x select 0) == _role}) select 0;
    private _position = +(_assignment get "position");
    _force set [0, _definition select 1];
    _force set [2, _position];
    _force set [10, getMarkerPos (_assignment get "sector")];
    _force set [12, _assignment get "sector"];
    _operation set ["coverageId", _assignmentId];
    _operation set ["coveragePosition", [[], _position] select _field];
    _operation set ["coverageBearing", _assignment getOrDefault ["bearing", 0]];
    _operation set ["coverageLeg", 0];
    _operation set ["defenseRole", _role];
    _operation set ["assignedSector", _assignment get "sector"];
    _operation set ["targetSector", _assignment get "sector"];
    _operation set ["pressureSector", _assignment get "sector"];
    _operation set ["targetPosition", _position];
    _operation set ["phase", "DEPLOYING"];
    _operation set ["outcome", ""];
    _operation set ["expiresAt", -1];
    _operation set ["tourDuration", 0];
    _operation set ["lastProgressPosition", +(_force select 1)];
    _operation set ["legDeadline", CBA_missionTime + 900];
    _operation set ["allocationIssue", ""];
    _operation set ["nextManeuverAt", 0];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _id;
    {
        if (local _x) then {[_x] call BATTLESPACE_DEFENSE_RESET_GROUP} else {[_x] remoteExecCall ["BATTLESPACE_DEFENSE_RESET_GROUP", groupOwner _x]};
    } forEach (_force param [4, []]);
    [_id, _force select 1, _position] call QUEUE_PATHFIND_REQUEST;
};

BATTLESPACE_DEFENSE_FIND_REASSIGNMENT = {
    params ["_assignmentId", "_assignment", "_coverage"];
    private _candidates = [];
    {
        if ((_y getOrDefault ["kind", ""]) != "DEFENDER" || {(_y getOrDefault ["outcome", ""]) != ""}) then {continue};
        private _force = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_force" || {_force param [11, false]}) then {continue};
        private _manpower = (_force select 3) getOrDefault ["manpower", 0];
        if (_manpower < BATTLESPACE_STRATEGIC_DEFENDER_RETREAT_MANPOWER) then {continue};
        if ((_force param [4, []]) findIf {behaviour leader _x == "COMBAT"} >= 0) then {continue};
        private _oldId = [_y] call BATTLESPACE_DEFENSE_ASSIGNMENT_ID;
        if (_oldId == _assignmentId) then {continue};
        private _old = BATTLESPACE_DEFENSE_ASSIGNMENTS get _oldId;
        private _surplus = isNil "_old" || {(_y getOrDefault ["phase", ""]) == "RETURNING"};
        if (!_surplus && {(_old get "kind") == "OBJECTIVE"}) then {
            private _counts = _coverage getOrDefault [_oldId, [0, 0, []]];
            // Only actual troops can release a garrison; an incoming relief cannot.
            _surplus = (_counts select 0) - _manpower >= (_old get "target");
        };
        if (!_surplus) then {continue};
        private _from = [_force select 1] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
        if (_from == "" || {[_from, _assignment get "sector", 12] call BATTLESPACE_DEFENSE_GRAPH_DISTANCE < 0}) then {continue};
        _candidates pushBack [(_force select 1) distance2D (_assignment get "position"), _x];
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _candidates sort true;
    if (_candidates isEqualTo []) then {""} else {(_candidates select 0) select 1}
};

BATTLESPACE_DEFENSE_DISPATCH_ASSIGNMENT = {
    params ["_assignmentId", "_assignment", "_missing", "_coverage"];
    private _existing = [_assignmentId, _assignment, _coverage] call BATTLESPACE_DEFENSE_FIND_REASSIGNMENT;
    if (_existing != "") exitWith {
        [_existing, BATTLESPACE_TASK_FORCES get _existing, BATTLESPACE_STRATEGIC_OPERATIONS get _existing, _assignmentId, _assignment] call BATTLESPACE_DEFENSE_SET_ASSIGNMENT;
        [format ["Reassigned existing defender %1 to %2", _existing, _assignmentId]] call BATTLESPACE_STRATEGIC_LOG;
        [true, "Existing squad reassigned; relief incoming"]
    };
    private _block = [] call BATTLESPACE_GROUND_ALLOCATION_BLOCK;
    if (_block != "") exitWith {[false, _block]};
    private _role = _assignment get "role";
    private _definition = (BATTLESPACE_STRATEGIC_DEFENDER_ROLES select {(_x select 0) == _role}) select 0;
    private _manpower = if ((_assignment get "kind") == "FIELD") then {_definition select 2} else {3 max (_missing min (_definition select 2))};
    private _sourceResult = [_assignment get "sector", _manpower] call BATTLESPACE_DEFENSE_FIND_SOURCE_RESULT;
    _sourceResult params ["_source", "_reason"];
    if (_source == "") exitWith {[false, format ["Needs %1 infantry: %2", _manpower, _reason]]};
    private _vehicles = [];
    if (_role == "DEFENSIVE_PATROL") then {
        private _vehicle = [_source] call BATTLESPACE_DEFENSE_PICK_PATROL_VEHICLE;
        if (_vehicle != "") then {_vehicles pushBack _vehicle};
    };
    private _composition = createHashMapFromArray [["manpower", _manpower], ["vehicles", _vehicles], ["structures", []]];
    private _args = [_definition select 1, _composition, getMarkerPos _source, _assignment get "position", getMarkerPos (_assignment get "sector"), _source, "DEFENDER"];
    private _id = _args call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_id == "" && {_vehicles isNotEqualTo []}) then {
        _composition set ["vehicles", []];
        _id = _args call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    };
    if (_id == "") exitWith {[false, "Funding or formation creation failed; awaiting reevaluation"]};
    [_id, BATTLESPACE_TASK_FORCES get _id, BATTLESPACE_STRATEGIC_OPERATIONS get _id, _assignmentId, _assignment] call BATTLESPACE_DEFENSE_SET_ASSIGNMENT;
    [format ["Funded defender %1 from %2 for %3 with %4 infantry", _id, _source, _assignmentId, _manpower]] call BATTLESPACE_STRATEGIC_LOG;
    [true, "Relief incoming"]
};

BATTLESPACE_DEFENSE_PATH_FAILED = {
    params ["_id", "_force"];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_id, createHashMap];
    private _assignmentId = [_operation] call BATTLESPACE_DEFENSE_ASSIGNMENT_ID;
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _id;
    _operation set ["allocationIssue", "Route failed; squad awaiting another assignment or return route"];
    _operation set ["nextManeuverAt", CBA_missionTime + 120];
    if ((_operation getOrDefault ["phase", ""]) != "RETURNING") then {
        BATTLESPACE_DEFENSE_BLOCKED_ASSIGNMENTS set [_assignmentId, [CBA_missionTime + 600, "Route failed; next evaluation will retry this approach"]];
        [_id, _force, _operation, "its assignment route failed"] call BATTLESPACE_TASK_FORCE_DEFENSE_BEGIN_RETURN;
    };
};

BATTLESPACE_DEFENSE_MAINTAIN = {
    if (!isServer) exitWith {};
    [] call BATTLESPACE_DEFENSE_REBUILD_LAYOUT;
    {
        if ((_y getOrDefault ["kind", ""]) != "DEFENDER") then {continue};
        private _force = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_force") then {continue};
        private _operation = _y;
        private _id = [_operation] call BATTLESPACE_DEFENSE_ASSIGNMENT_ID;
        private _phase = _operation getOrDefault ["phase", ""];
        // Older patrol tours are intentionally ignored after a saved campaign is loaded.
        _operation set ["expiresAt", -1];
        _operation set ["tourDuration", 0];
        if (_phase in ["RETURNING", "LOST"] || {_id == ""}) then {continue};
        private _assignment = BATTLESPACE_DEFENSE_ASSIGNMENTS get _id;
        if (isNil "_assignment") then {
            [_x, _force, _operation, "the frontline no longer needs its assignment"] call BATTLESPACE_TASK_FORCE_DEFENSE_BEGIN_RETURN;
            continue;
        };
        if (_phase == "ON_STATION" && {(_assignment get "kind") == "FIELD"}
            && {(_force select 1) distance2D (_assignment get "position") > BATTLESPACE_FIELD_COVERAGE_RADIUS + 100}
            && {(_force param [4, []]) findIf {behaviour leader _x == "COMBAT"} < 0}) then {
            [_x, _force, _operation, _id, _assignment] call BATTLESPACE_DEFENSE_SET_ASSIGNMENT;
            _phase = "DEPLOYING";
        };
        if (_phase in ["DEPLOYING", "DISPLACING"]) then {
            private _position = _force select 1;
            private _previous = _operation getOrDefault ["lastProgressPosition", []];
            if (_previous isEqualTo [] || {_previous distance2D _position > 75}) then {
                _operation set ["lastProgressPosition", +_position];
                _operation set ["legDeadline", CBA_missionTime + 900];
            };
            if (CBA_missionTime >= (_operation getOrDefault ["legDeadline", CBA_missionTime + 900])) then {
                [_x, _force] call BATTLESPACE_DEFENSE_PATH_FAILED;
                BATTLESPACE_DEFENSE_BLOCKED_ASSIGNMENTS set [_id, [CBA_missionTime + 120, "Relief stalled; existing squad released for reassignment"]];
            };
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
};

BATTLESPACE_DEFENSE_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    [] call BATTLESPACE_GROUND_ALLOCATION_BLOCK;
    [] call BATTLESPACE_DEFENSE_MAINTAIN;
    [] call BATTLESPACE_RESERVE_RESTAGE_READY;
    private _changed = false;
    if (["RESERVE"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS < BATTLESPACE_STRATEGIC_RESERVE_TARGET) then {
        _changed = [] call BATTLESPACE_RESERVE_FORM;
    };
    private _coverage = [] call BATTLESPACE_DEFENSE_READ_COVERAGE;
    private _attempted = createHashMap;
    private _priorities = createHashMap;
    {
        private _position = _y get "position";
        private _priority = count ([_position, 1200, BATTLESPACE_CONTACT_MEMORY_MAX_AGE] call BATTLESPACE_CONTACT_QUERY);
        {
            if ((_y get "position") distance2D _position < 1200) then {
                _priority = _priority + (_y getOrDefault ["pressure", 0]);
            };
        } forEach BATTLESPACE_RESERVE_FIELD_INCIDENTS;
        _priorities set [_x, _priority];
    } forEach BATTLESPACE_DEFENSE_ASSIGNMENTS;
    // Rebuild priorities after every successful assignment. A large objective can
    // receive several squads, while empty fronts and field gaps get their first allocation.
    for "_pass" from 1 to (count BATTLESPACE_DEFENSE_ASSIGNMENTS + BATTLESPACE_STRATEGIC_GROUND_FORMATIONS_PER_TICK + count BATTLESPACE_STRATEGIC_OPERATIONS) do {
        private _candidates = [];
        {
            if (_attempted getOrDefault [_x, false]) then {continue};
            private _counts = _coverage getOrDefault [_x, [0, 0, []]];
            _counts params ["_present", "_incoming", "_ids"];
            private _field = (_y get "kind") == "FIELD";
            if ((_field && {_ids isNotEqualTo []}) || {!_field && {_present + _incoming >= (_y get "target")}}) then {continue};
            private _blocked = BATTLESPACE_DEFENSE_BLOCKED_ASSIGNMENTS getOrDefault [_x, [0, ""]];
            if (CBA_missionTime < (_blocked select 0)) then {_y set ["reason", _blocked select 1]; continue};
            private _tier = if (_field) then {1} else {if ((_y get "depth") == 0) then {[2, 0] select (_present + _incoming == 0)} else {3}};
            private _priority = _priorities getOrDefault [_x, 0];
            _candidates pushBack [_tier, -_priority, -(((_y get "target") - _present - _incoming) / ((_y get "target") max 1)), _x];
        } forEach BATTLESPACE_DEFENSE_ASSIGNMENTS;
        _candidates sort true;
        if (_candidates isEqualTo []) exitWith {};
        private _id = (_candidates select 0) select 3;
        private _assignment = BATTLESPACE_DEFENSE_ASSIGNMENTS get _id;
        private _counts = _coverage getOrDefault [_id, [0, 0, []]];
        private _missing = (_assignment get "target") - (_counts select 0) - (_counts select 1);
        private _result = [_id, _assignment, _missing, _coverage] call BATTLESPACE_DEFENSE_DISPATCH_ASSIGNMENT;
        _assignment set ["reason", _result select 1];
        _assignment set ["evaluatedAt", CBA_missionTime];
        if (_result select 0) then {
            _changed = true;
            _coverage = [] call BATTLESPACE_DEFENSE_READ_COVERAGE;
        } else {
            _attempted set [_id, true];
        };
    };
    BATTLESPACE_DEFENSE_LAST_EVALUATION = CBA_missionTime;
    if (_changed) then {[] call BATTLESPACE_LOGISTICS_SAVE};
};
