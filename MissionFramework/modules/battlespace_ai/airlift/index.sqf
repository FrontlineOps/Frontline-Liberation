/*
    A deployment method for paid RESERVE/BATTLEGROUP operations. The original
    ID owns passengers throughout insertion; only the returning carrier splits.
    Server owns the lifecycle/ledger. Flight and dismount orders run on owners.
    LandAt uses a helipad (Arma 2.18+) and never a paradrop/hover-unload fallback.
*/
BATTLESPACE_AIRLIFT_RUNTIME = createHashMap;

BATTLESPACE_AIRLIFT_COUNT = {
    private _count = 0;
    {if ((_y param [0, ""]) == "Airborne Transport") then {_count = _count + 1}} forEach BATTLESPACE_TASK_FORCES;
    _count
};

BATTLESPACE_AIRLIFT_SYNC = {
    params ["_id", "_force"];
    if (!isServer || {isRemoteExecuted} || {(_force select 0) != "Airborne Transport"} || {_force param [11, false]}) exitWith {};
    private _objects = _force param [8, []];
    if (_objects isEqualTo []) exitWith {};
    private _paid = _objects select {alive _x && {_x isKindOf "Man"} && {_x getVariable ["TASKFORCEID", ""] == _id}};
    private _composition = _force select 3;
    _composition set ["manpower", count _paid];
    _composition set ["aircrew", {_x getVariable ["BATTLESPACE_AIRLIFT_PILOT", false]} count _paid];
};

BATTLESPACE_AIRLIFT_PERSON_KILLED = {
    if (!isServer) exitWith {};
    private _unit = _this select 0;
    if (_unit getVariable ["BATTLESPACE_AIRLIFT_LOSS_RECORDED", false]) exitWith {};
    _unit setVariable ["BATTLESPACE_AIRLIFT_LOSS_RECORDED", true];
    private _id = _unit getVariable ["TASKFORCEID", ""];
    private _force = BATTLESPACE_TASK_FORCES getOrDefault [_id, []];
    if (_force isEqualTo []) exitWith {};
    if ((_force select 0) == "Airborne Transport") then {
        // A save may already have synchronized this death before its MP event.
        [_id, _force] call BATTLESPACE_AIRLIFT_SYNC;
        [_id, "MANPOWER", _unit] call BATTLESPACE_STRATEGIC_RECORD_CASUALTY;
    } else {
        ["MANPOWER", _this] call BATTLESPACE_TASK_FORCE_OBJECT_KILLED;
    };
};

BATTLESPACE_AIRLIFT_BUILD_DEFINITION = {
    params ["_source", "_desired", "_minimum", "_reserveRatio", ["_budget", 1e9]];
    if ([] call BATTLESPACE_AIRLIFT_COUNT >= BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIRBORNE_TRANSPORTS) exitWith {createHashMap};
    private _state = BATTLESPACE_SECTOR_STATES getOrDefault [_source, createHashMap];
    if ((_state getOrDefault ["owner", ""]) != "OPFOR") exitWith {createHashMap};
    private _stock = _state getOrDefault ["resources", createHashMap];
    if ((_stock getOrDefault ["aircraft", 0]) < 1) exitWith {createHashMap};
    private _available = floor ((_stock getOrDefault ["manpower", 0]) - ceil (([_source, "manpower"] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY) * _reserveRatio));
    // One paid pilot, separate from the ground combat strength budget.
    private _payload = _desired min (_available - 1) min floor _budget;
    if (_payload < _minimum) exitWith {createHashMap};
    private _catalog = (missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap]) getOrDefault ["opfor", createHashMap];
    private _candidates = (_catalog getOrDefault ["rotaryLogistics", []]) select {
        private _cfg = configFile >> "CfgVehicles" >> _x;
        _x isKindOf "Helicopter" && {getNumber (_cfg >> "scope") == 2}
        && {getNumber (_cfg >> "isUav") == 0}
        && {getNumber (_cfg >> "transportSoldier") >= _minimum}
        && {isClass (configFile >> "CfgVehicles" >> getText (_cfg >> "crew"))}
        && {([_x] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS) == "aircraft"}
    };
    if (_candidates isEqualTo []) exitWith {createHashMap};
    private _fitting = _candidates select {getNumber (configFile >> "CfgVehicles" >> _x >> "transportSoldier") >= _payload};
    private _class = selectRandom (if (_fitting isEqualTo []) then {_candidates} else {_fitting});
    _payload = _payload min getNumber (configFile >> "CfgVehicles" >> _class >> "transportSoldier");
    createHashMapFromArray [["manpower", _payload + 1], ["aircrew", 1], ["airlift", true], ["vehicles", [_class]], ["structures", []]]
};

BATTLESPACE_AIRLIFT_FIND_LZ = {
    params ["_center", ["_minimum", 0], ["_ignore", objNull]];
    private _result = [];
    // Fixed work bound. Never accept the origin/default returned by a failed search.
    for "_i" from 0 to 23 do {
        private _point = _center getPos [_minimum + random (BATTLESPACE_AIRLIFT_LZ_RADIUS - _minimum max 1), random 360];
        private _flat = _point isFlatEmpty [20, -1, 0.15, 20, 0, false, _ignore];
        if (_flat isEqualTo [] || {_flat distance2D _center > BATTLESPACE_AIRLIFT_LZ_RADIUS}) then {continue};
        if (_flat distance2D _center < _minimum || {surfaceIsWater _flat}) then {continue};
        // isFlatEmpty can shift its result. Recheck the returned site's obstacles.
        if ((nearestTerrainObjects [_flat, ["TREE", "SMALL TREE", "HOUSE", "BUILDING", "ROCK", "WALL"], 20, false, true]) isNotEqualTo []) then {continue};
        if ((nearestObjects [_flat, ["LandVehicle", "Air", "Ship"], 25]) findIf {_x != _ignore} >= 0) then {continue};
        _flat set [2, 0];
        _result = _flat;
        break;
    };
    _result
};

BATTLESPACE_AIRLIFT_CLEANUP = {
    params ["_id"];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    private _runtime = BATTLESPACE_AIRLIFT_RUNTIME getOrDefault [_id, createHashMap];
    private _pad = _runtime getOrDefault ["pad", objNull];
    if (!isNull _pad) then {deleteVehicle _pad};
    BATTLESPACE_AIRLIFT_RUNTIME deleteAt _id;
};

BATTLESPACE_AIRLIFT_ORDER = {
    params ["_heli", "_pad", "_depart"];
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    if (isNull _heli || {!local _heli} || {isNull _pad} || {_heli getVariable ["KPLIB_captured", false]}) exitWith {};
    private _pilot = driver _heli;
    if (isNull _pilot || {!alive _pilot}) exitWith {};
    private _group = group _pilot;
    _group setVariable ["lambs_danger_disableGroupAI", true, true];
    _group setCombatMode "BLUE";
    _group setBehaviourStrong "CARELESS";
    _group setSpeedMode "FULL";
    _pilot disableAI "AUTOCOMBAT";
    _pilot disableAI "TARGET";
    _pilot disableAI "AUTOTARGET";
    _pilot enableAI "MOVE";
    _pilot enableAI "PATH";
    _pilot enableAI "FSM";
    for "_i" from (count waypoints _group - 1) to 0 step -1 do {deleteWaypoint [_group, _i]};
    if (_depart) then {
        _heli land "NONE";
        _heli landAt [_pad, "NONE"];
    };
    _heli flyInHeight BATTLESPACE_AIRLIFT_FLIGHT_HEIGHT;
    _heli engineOn true;
    private _wp = _group addWaypoint [getPosATL _pad, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "FULL";
    _wp setWaypointBehaviour "CARELESS";
    _group setCurrentWaypoint _wp;
    if (!_depart) then {_heli landAt [_pad, "LAND"]};
};

BATTLESPACE_AIRLIFT_UNLOAD = {
    params ["_unit", "_heli", ["_fallback", false]];
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    if (isNull _unit || {!local _unit} || {isNull _heli} || {!isTouchingGround _heli} || {abs speed _heli > 3}) exitWith {};
    if (vehicle _unit != _heli || {_unit == driver _heli}) exitWith {};
    unassignVehicle _unit;
    [_unit] allowGetIn false;
    doGetOut _unit;
    if (_fallback) then {_unit action ["GetOut", _heli]};
};

BATTLESPACE_AIRLIFT_CAN_PROC = {
    params ["_id", "_force"];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_id, createHashMap];
    // Legacy fixed-wing carriers return virtually; no new fixed-wing insertion.
    if (((_force select 3) getOrDefault ["vehicles", []]) findIf {!(_x isKindOf "Helicopter")} >= 0) exitWith {false};
    // A physical flight remains physical until landing/RTB. This also prevents
    // virtualization halfway through unloading and a second copy of passengers.
    if ((_force param [8, []]) isNotEqualTo [] && {(_operation getOrDefault ["phase", ""]) != "READY"}) exitWith {true};
    private _current = _force select 1;
    private _destination = _force param [2, []];
    private _range = ["Airborne Transport"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
    private _needed = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
    private _near = false;
    {
        private _position = _x getOrDefault ["Position", []];
        if (count (_x getOrDefault ["Players", []]) >= _needed && {_position distance2D _current < _range || {_destination isNotEqualTo [] && {_position distance2D _destination < _range}}}) exitWith {_near = true};
    } forEach BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS;
    _near || {_destination isNotEqualTo [] && {allUnits findIf {alive _x && {side group _x == GRLIB_side_friendly} && {_x distance2D _destination < 1200}} >= 0}}
};

BATTLESPACE_AIRLIFT_SPAWN = {
    params ["_id", "_force"];
    if (!isServer || {isRemoteExecuted}) exitWith {false};
    private _composition = _force select 3;
    if ((_composition getOrDefault ["aircrew", 0]) == 0 && {!(_composition getOrDefault ["legacyAircrew", false])}) exitWith {false};
    private _class = (_composition getOrDefault ["vehicles", []]) param [0, ""];
    if (!(_class isKindOf "Helicopter") || {[] call KPLIB_fnc_getOpforCap >= BATTLESPACE_UNIT_CAP}) exitWith {false};
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _id;
    if ((_operation getOrDefault ["airliftPhase", ""]) == "DISABLED") exitWith {false};
    private _ready = (_operation getOrDefault ["phase", ""]) == "READY"
        || {(_operation getOrDefault ["airliftPhase", ""]) == "UNLOADING"};
    private _position = +(_force select 1);
    if (_ready) then {_position = [_position] call BATTLESPACE_AIRLIFT_FIND_LZ};
    if (_position isEqualTo []) exitWith {false};
    if (!_ready) then {_position set [2, BATTLESPACE_AIRLIFT_FLIGHT_HEIGHT]};
    private _heli = createVehicle [_class, _position, [], 0, ["FLY", "NONE"] select _ready];
    if (isNull _heli) exitWith {false};
    private _objects = [_heli];
    private _groups = [];
    _force set [8, _objects];
    _force set [4, _groups];
    _heli setVariable ["TASKFORCEID", _id];
    _heli addMPEventHandler ["MPKilled", {["VEHICLE", _this] call BATTLESPACE_TASK_FORCE_OBJECT_KILLED}];
    [_heli] call KPLIB_fnc_addObjectInit;
    private _crewGroup = createGroup [_force select 6, true];
    if (isNull _crewGroup) exitWith {false};
    _crewGroup setVariable ["lambs_danger_disableGroupAI", true, true];
    _crewGroup setBehaviourStrong "CARELESS";
    _crewGroup setCombatMode "BLUE";
    _groups pushBack _crewGroup;
    _crewGroup setVariable ["TASKFORCEID", _id];
    private _pilot = [getText (configFile >> "CfgVehicles" >> _class >> "crew"), _position, _crewGroup, "PRIVATE", 0.7] call BATTLESPACE_TASK_FORCE_SPAWN_INFANTRY;
    if (isNull _pilot) exitWith {false};
    _objects pushBack _pilot;
    _pilot moveInDriver _heli;
    _pilot setVariable ["BATTLESPACE_AIRLIFT_PILOT", true];
    _pilot allowFleeing 0;
    _pilot disableAI "AUTOCOMBAT";
    if ((_composition getOrDefault ["aircrew", 0]) > 0) then {
        _pilot setVariable ["TASKFORCEID", _id];
        _pilot addMPEventHandler ["MPKilled", {_this call BATTLESPACE_AIRLIFT_PERSON_KILLED}];
    };
    private _payload = (_composition getOrDefault ["manpower", 0]) - (_composition getOrDefault ["aircrew", 0]);
    if (_payload > 0) then {
        private _cargoGroup = createGroup [_force select 6, true];
        if (isNull _cargoGroup) exitWith {};
        _groups pushBack _cargoGroup;
        _cargoGroup setVariable ["TASKFORCEID", _id];
        _cargoGroup setVariable ["lambs_danger_disableGroupAI", true, true];
        private _squad = [_payload, [], false, true] call BATTLESPACE_TASK_FORCES_GET_SQUAD_COMPOSITION;
        for "_i" from 0 to (_payload - 1) do {
            private _unit = [_squad select (_i mod count _squad), _position, _cargoGroup, "PRIVATE", 0.5] call BATTLESPACE_TASK_FORCE_SPAWN_INFANTRY;
            if (isNull _unit) exitWith {};
            _objects pushBack _unit;
            _unit setVariable ["TASKFORCEID", _id];
            _unit addMPEventHandler ["MPKilled", {_this call BATTLESPACE_AIRLIFT_PERSON_KILLED}];
            _unit assignAsCargo _heli;
            _unit moveInCargo _heli;
        };
    };
    private _success = !isNull driver _heli && {count (_objects select {_x isKindOf "Man"}) == _payload + 1}
        && {(_objects select {_x isKindOf "Man"}) findIf {vehicle _x != _heli} < 0};
    [_id] call BATTLESPACE_AIRLIFT_CLEANUP;
    if (_ready) then {_heli engineOn false};
    _success
};

BATTLESPACE_AIRLIFT_BEGIN_RETURN = {
    params ["_id", "_force", "_operation", ["_reason", "insertion complete"]];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    private _home = _operation getOrDefault ["originSector", ""];
    if (((BATTLESPACE_SECTOR_STATES getOrDefault [_home, createHashMap]) getOrDefault ["owner", ""]) != "OPFOR") then {
        _home = [_force select 1] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
    };
    _operation set ["phase", "RETURNING"];
    _operation set ["returnSector", _home];
    _operation set ["airliftPhase", "ENROUTE"];
    _operation set ["airliftAttempts", 0];
    _operation deleteAt "airliftLZ";
    _operation deleteAt "airliftDeadline";
    _force set [2, if (_home == "") then {[]} else {getMarkerPos _home}];
    [_id] call BATTLESPACE_AIRLIFT_CLEANUP;
    [format ["Airlift %1 returning to %2: %3", _id, _home, _reason]] call BATTLESPACE_STRATEGIC_LOG;
};

BATTLESPACE_AIRLIFT_DEPLOY = {
    params ["_id", "_force", "_operation", ["_lostCarrier", false]];
    if (!isServer || {isRemoteExecuted} || {(_force select 0) != "Airborne Transport"}) exitWith {false};
    private _objects = _force param [8, []];
    private _physical = _objects isNotEqualTo [];
    private _cargo = _objects select {_x isKindOf "Man" && {alive _x} && {!(_x getVariable ["BATTLESPACE_AIRLIFT_PILOT", false])} && {_x getVariable ["TASKFORCEID", ""] == _id}};
    if (_physical && {_cargo findIf {!isNull objectParent _x} >= 0}) exitWith {false};
    private _oldComposition = _force select 3;
    private _crew = _oldComposition getOrDefault ["aircrew", 0];
    private _payload = if (_physical) then {count _cargo} else {(_oldComposition getOrDefault ["manpower", 0]) - _crew};
    private _carrierObjects = _objects - _cargo;
    private _cargoGroups = (_force param [4, []]) select {units _x findIf {_x in _cargo} >= 0};
    private _carrierGroups = (_force param [4, []]) - _cargoGroups;
    private _carrierCreated = true;
    if (!_lostCarrier) then {
        private _carrierComposition = createHashMapFromArray [
            ["manpower", _crew], ["aircrew", _crew], ["legacyAircrew", _oldComposition getOrDefault ["legacyAircrew", false]],
            ["vehicles", +(_oldComposition getOrDefault ["vehicles", []])], ["structures", []]
        ];
        private _carrierId = ["Airborne Transport", _carrierComposition, +(_force select 1), [], _force param [10, []], _force select 6] call BATTLESPACE_TASK_FORCES_INIT;
        if (_carrierId == "") exitWith {_carrierCreated = false};
        private _carrier = BATTLESPACE_TASK_FORCES get _carrierId;
        _carrier set [4, _carrierGroups];
        _carrier set [8, _carrierObjects];
        {_x setVariable ["TASKFORCEID", _carrierId]} forEach (_carrierObjects + _carrierGroups);
        if (_crew == 0) then {
            {if (_x isKindOf "Man") then {_x setVariable ["TASKFORCEID", nil]}} forEach _carrierObjects;
        };
        private _carrierOperation = createHashMapFromArray [
            ["kind", "AIRBORNE_TRANSPORT"], ["phase", "RETURNING"], ["airliftVersion", 1], ["childTaskForce", _id],
            ["originSector", _operation getOrDefault ["originSector", ""]], ["fundingSector", _operation getOrDefault ["fundingSector", ""]],
            ["cost", createHashMapFromArray [["aircraft", 1], ["manpower", _crew]]],
            ["vehicleManifest", +(_operation getOrDefault ["vehicleManifest", []])], ["initialStrength", _crew + 4], ["outcome", ""]
        ];
        BATTLESPACE_STRATEGIC_OPERATIONS set [_carrierId, _carrierOperation];
        [_carrierId, _carrier, _carrierOperation] call BATTLESPACE_AIRLIFT_BEGIN_RETURN;
    } else {
        // A wreck/disabled carrier remains in the world. Never refund it or
        // delete its surviving crew when the ground force continues.
        {_x setVariable ["TASKFORCEID", nil]} forEach (_carrierObjects + _carrierGroups);
    };
    if (!_carrierCreated) exitWith {false};
    _force set [0, ["Mobile Reserve", "Battlegroup"] select ((_operation getOrDefault ["kind", ""]) == "BATTLEGROUP")];
    _force set [3, createHashMapFromArray [["manpower", _payload], ["vehicles", []], ["structures", []]]];
    _force set [4, _cargoGroups];
    _force set [8, _cargo];
    _force set [5, ["IDLE", 0, 0]];
    _operation set ["airInserted", true];
    private _initialPayload = _operation getOrDefault ["airliftInitialPayload", _payload];
    _operation set ["cost", createHashMapFromArray [["manpower", _initialPayload]]];
    _operation set ["vehicleManifest", []];
    _operation set ["initialStrength", _initialPayload max 1];
    _operation set ["legDeadline", CBA_missionTime + BATTLESPACE_OFFENSIVE_LEG_TIMEOUT];
    {_operation deleteAt _x} forEach ["airliftLZ", "airliftDeadline", "airliftPhase", "airliftAttempts"];
    {
        _x setVariable ["lambs_danger_disableGroupAI", false, true];
        _x setVariable ["BATTLESPACE_TRANSPORT_VEHICLE", nil];
        _x setVariable ["BATTLESPACE_TRANSPORT_PARENT_GROUP", nil];
    } forEach _cargoGroups;
    [_id] call BATTLESPACE_AIRLIFT_CLEANUP;
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _id;
    // An AIR path job for this ID must not become the infantry's ground route.
    BATTLESPACE_PATHFIND_REQUEST_GENERATIONS set [_id, 1 + (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_id, 0])];
    QUEUED_PATHFIND_REQUESTS = QUEUED_PATHFIND_REQUESTS select {(_x select 0) != _id};
    if ((_force param [2, []]) isNotEqualTo []) then {[_id, _force select 1, _force select 2] call QUEUE_PATHFIND_REQUEST};
    [format ["Airlift %1 landed %2 infantry; continuing as %3", _id, _payload, _force select 0]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_AIRLIFT_TICK = {
    params ["_id", "_force"];
    if (!isServer || {isRemoteExecuted} || {_force param [11, false]}) exitWith {false};
    [_id, _force] call BATTLESPACE_AIRLIFT_SYNC;
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_id, createHashMap];
    private _phase = _operation getOrDefault ["phase", ""];
    private _objects = _force param [8, []];
    private _heli = (_objects select {!isNull _x && {_x isKindOf "Air"}}) param [0, objNull];
    private _physical = _objects isNotEqualTo [];
    private _composition = _force select 3;
    if (!_physical && {
        (_composition getOrDefault ["vehicles", []]) isEqualTo []
        || {(_operation getOrDefault ["airliftPhase", ""]) == "DISABLED"}
        || {(_composition getOrDefault ["aircrew", 0]) == 0 && {!(_composition getOrDefault ["legacyAircrew", false])}}
    }) exitWith {
        // A restart cannot supply a replacement pilot for a lost paid crew.
        // Keep surviving payload as an ordinary ground force; the airframe is lost.
        if ((_operation getOrDefault ["kind", ""]) in ["RESERVE", "BATTLEGROUP"] && {(_composition getOrDefault ["manpower", 0]) > 0}) exitWith {
            [_id, _force, _operation, true] call BATTLESPACE_AIRLIFT_DEPLOY;
            false
        };
        _operation set ["outcome", "LOST"];
        [_id] call BATTLESPACE_AIRLIFT_CLEANUP;
        true
    };
    if (_physical && {!isNull _heli}) then {
        private _position = getPosATL _heli;
        _position set [2, 0];
        _force set [1, _position];
    };
    private _disabled = _physical && {isNull _heli || {!alive _heli} || {!canMove _heli} || {!alive driver _heli} || {_heli getVariable ["KPLIB_captured", false]}};
    if (_disabled) exitWith {
        private _cargo = _objects select {alive _x && {_x isKindOf "Man"} && {!(_x getVariable ["BATTLESPACE_AIRLIFT_PILOT", false])}};
        if (!isNull _heli && {isTouchingGround _heli}) then {
            {[_x, _heli] remoteExecCall ["BATTLESPACE_AIRLIFT_UNLOAD", owner _x]} forEach _cargo;
        };
        if (_cargo isNotEqualTo [] && {_cargo findIf {!isNull objectParent _x} < 0} && {(_operation getOrDefault ["kind", ""]) in ["RESERVE", "BATTLEGROUP"]}) exitWith {
            [_id, _force, _operation, true] call BATTLESPACE_AIRLIFT_DEPLOY;
            false
        };
        private _until = _operation getOrDefault ["airliftDeadline", -1];
        if ((_operation getOrDefault ["airliftPhase", ""]) != "DISABLED") then {
            _operation set ["airliftPhase", "DISABLED"];
            _until = CBA_missionTime + 90;
            _operation set ["airliftDeadline", _until];
        };
        if (CBA_missionTime < _until) exitWith {false};
        {_x setVariable ["TASKFORCEID", nil]} forEach (_objects + (_force param [4, []]));
        _force set [8, []];
        _force set [4, []];
        _operation set ["outcome", "LOST"];
        [_id] call BATTLESPACE_AIRLIFT_CLEANUP;
        true
    };
    // Ready reserves keep their paid helicopter until dispatched or restaged.
    private _home = _operation getOrDefault ["assignedSector", _operation getOrDefault ["originSector", ""]];
    private _target = _operation getOrDefault ["targetSector", ""];
    private _return = _phase == "RETURNING";
    private _targetLost = (_operation getOrDefault ["kind", ""]) == "RESERVE" && {
        (_phase in ["READY", "STAGING"] && {((BATTLESPACE_SECTOR_STATES getOrDefault [_home, createHashMap]) getOrDefault ["owner", ""]) != "OPFOR"})
        || {_phase == "RESPONDING" && {((BATTLESPACE_SECTOR_STATES getOrDefault [_target, createHashMap]) getOrDefault ["owner", ""]) != "OPFOR"}}
        || {_phase == "FIELD_HUNT" && {CBA_missionTime >= (_operation getOrDefault ["contactGraceUntil", 0])}}
    };
    if ((_targetLost && {(_operation getOrDefault ["airliftPhase", ""]) != "UNLOADING"})
        || {_return && {((BATTLESPACE_SECTOR_STATES getOrDefault [_operation getOrDefault ["returnSector", ""], createHashMap]) getOrDefault ["owner", ""]) != "OPFOR"}}) then {
        [_id, _force, _operation, "destination lost or contact expired"] call BATTLESPACE_AIRLIFT_BEGIN_RETURN;
        _return = true;
        _phase = "RETURNING";
    };
    if (_phase == "READY") exitWith {false};
    private _destination = _force param [2, []];
    if (_destination isEqualTo []) exitWith {
        // No friendly base remains: release physical survivors without credit.
        {_x setVariable ["TASKFORCEID", nil]} forEach (_objects + (_force param [4, []]));
        _force set [4, []];
        _force set [8, []];
        _operation set ["outcome", "LOST"];
        [_id] call BATTLESPACE_AIRLIFT_CLEANUP;
        true
    };
    if (!_physical && {[_id, _force] call BATTLESPACE_AIRLIFT_CAN_PROC}) exitWith {false};
    private _lz = _operation getOrDefault ["airliftLZ", []];
    if (_lz isEqualTo []) then {
        private _minimum = if (!_return && {_phase in ["ENGAGING", "ASSAULTING", "FIELD_HUNT"]}) then {250} else {0};
        _lz = [_destination, _minimum, _heli] call BATTLESPACE_AIRLIFT_FIND_LZ;
        _operation set ["airliftLZ", _lz];
        _operation set ["airliftDeadline", CBA_missionTime + BATTLESPACE_AIRLIFT_LEG_TIMEOUT];
    };
    private _expired = CBA_missionTime >= (_operation getOrDefault ["airliftDeadline", 0]);
    if (_expired && {(_operation getOrDefault ["airliftPhase", ""]) == "UNLOADING"}) exitWith {
        // Never fly away/settle a partly unloaded group at a different base.
        // A broken dismount leaves the physical survivors in the world, spent.
        {_x setVariable ["TASKFORCEID", nil]} forEach (_objects + (_force param [4, []]));
        _force set [4, []];
        _force set [8, []];
        _operation set ["outcome", "LOST"];
        [_id] call BATTLESPACE_AIRLIFT_CLEANUP;
        true
    };
    if (_lz isEqualTo [] || {_expired}) exitWith {
        private _attempts = 1 + (_operation getOrDefault ["airliftAttempts", 0]);
        _operation set ["airliftAttempts", _attempts];
        _operation deleteAt "airliftLZ";
        [_id] call BATTLESPACE_AIRLIFT_CLEANUP;
        if (_attempts < 3) exitWith {false};
        if (!_return) exitWith {[_id, _force, _operation, "landing attempts exhausted"] call BATTLESPACE_AIRLIFT_BEGIN_RETURN; false};
        // A failed RTB is a loss, never a mid-air refund/delete. Engine cleanup
        // can later reclaim abandoned survivors under the ordinary world rules.
        {_x setVariable ["TASKFORCEID", nil]} forEach (_objects + (_force param [4, []]));
        _force set [4, []];
        _force set [8, []];
        _operation set ["outcome", "LOST"];
        true
    };
    private _landed = false;
    if (_physical) then {
        private _runtime = BATTLESPACE_AIRLIFT_RUNTIME getOrDefault [_id, createHashMap];
        private _pad = _runtime getOrDefault ["pad", objNull];
        if (isNull _pad) then {
            _pad = createVehicle ["Land_HelipadEmpty_F", _lz, [], 0, "CAN_COLLIDE"];
            _runtime set ["pad", _pad];
        };
        // Reissue only on a new leg/materialization or locality change.
        if ((_runtime getOrDefault ["owner", -1]) != owner _heli) then {
            private _depart = isTouchingGround _heli || {(getPosATL _heli select 2) < 10};
            [_heli, _pad, _depart] remoteExecCall ["BATTLESPACE_AIRLIFT_ORDER", owner _heli];
            _runtime set ["owner", owner _heli];
            _runtime set ["departing", _depart];
        };
        if (_runtime getOrDefault ["departing", false] && {(getPosATL _heli select 2) > 20} && {abs speed _heli > 15}) then {
            [_heli, _pad, false] remoteExecCall ["BATTLESPACE_AIRLIFT_ORDER", owner _heli];
            _runtime set ["departing", false];
        };
        BATTLESPACE_AIRLIFT_RUNTIME set [_id, _runtime];
        _landed = isTouchingGround _heli && {abs speed _heli < 3} && {_heli distance2D _lz < 60};
    } else {
        private _current = _force select 1;
        private _distance = _current distance2D _lz;
        if (_distance <= 240) then {_force set [1, +_lz]; _landed = true} else {
            _force set [1, _current getPos [240, _current getDir _lz]];
        };
    };
    if (!_landed) exitWith {false};
    if (_return) exitWith {
        _operation set ["outcome", "RETURNED"];
        [_id] call BATTLESPACE_AIRLIFT_CLEANUP;
        true
    };
    if ((_operation getOrDefault ["kind", ""]) == "RESERVE" && {_phase == "STAGING"}) exitWith {
        _operation set ["phase", "READY"];
        _operation set ["airliftPhase", "READY"];
        _operation deleteAt "airliftLZ";
        _operation deleteAt "airliftDeadline";
        _force set [2, []];
        [_id] call BATTLESPACE_AIRLIFT_CLEANUP;
        false
    };
    if ((_operation getOrDefault ["airliftPhase", ""]) != "UNLOADING") then {
        _operation set ["airliftPhase", "UNLOADING"];
        _operation set ["airliftDeadline", CBA_missionTime + 180];
    };
    if (_physical) then {
        {
            if (_x isKindOf "Man" && {alive _x} && {!(_x getVariable ["BATTLESPACE_AIRLIFT_PILOT", false])}) then {
                [_x, _heli, CBA_missionTime >= (_operation get "airliftDeadline") - 120] remoteExecCall ["BATTLESPACE_AIRLIFT_UNLOAD", owner _x];
            };
        } forEach _objects;
    };
    [_id, _force, _operation] call BATTLESPACE_AIRLIFT_DEPLOY;
    false
};

BATTLESPACE_AIRLIFT_MIGRATE = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    // Invoked after both saved containers load, before strategic evaluation.
    {
        private _force = BATTLESPACE_TASK_FORCES getOrDefault [_x, []];
        if (_force isEqualTo []) then {continue};
        private _kind = _y getOrDefault ["kind", ""];
        if (_kind == "AIRBORNE_REINFORCEMENT" || {(_force select 0) == "Airborne Infantry"}) then {
            _force set [0, "Mobile Reserve"];
            _y set ["kind", "RESERVE"];
            _y set ["defenseRole", "MOBILE_RESERVE"];
            _y set ["phase", "HOLDING"];
            _y set ["airInserted", true];
            _y set ["assignedSector", _y getOrDefault ["originSector", ""]];
            _y set ["holdUntil", _y getOrDefault ["expiresAt", CBA_missionTime + BATTLESPACE_STRATEGIC_RESERVE_HOLD_DURATION]];
            _force set [2, []];
        };
        if ((_force select 0) == "Airborne Transport" && {!(_y getOrDefault ["airliftVersion", 0] == 1)}) then {
            private _composition = _force select 3;
            private _manpower = _composition getOrDefault ["manpower", 0];
            _composition set ["aircrew", 0];
            _composition set ["legacyAircrew", true];
            _y set ["airliftVersion", 1];
            _y set ["airliftPhase", "ENROUTE"];
            private _rotary = (_composition getOrDefault ["vehicles", []]) findIf {!(_x isKindOf "Helicopter")} < 0;
            if ((_y getOrDefault ["phase", ""]) in ["ENROUTE", "DEPLOYING"] && {_manpower > 0} && {_rotary}) then {
                _y set ["kind", "RESERVE"];
                _y set ["defenseRole", "MOBILE_RESERVE"];
                _y set ["phase", "RESPONDING"];
                _y set ["assignedSector", _y getOrDefault ["originSector", ""]];
                _composition set ["airlift", true];
                _y set ["airliftInitialPayload", (_y getOrDefault ["cost", createHashMap]) getOrDefault ["manpower", _manpower]];
            } else {
                [_x, _force, _y, "legacy carrier return"] call BATTLESPACE_AIRLIFT_BEGIN_RETURN;
            };
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
};
