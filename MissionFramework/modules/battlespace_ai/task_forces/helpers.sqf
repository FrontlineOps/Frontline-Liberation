BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC = {
	private _req = 1;

	if(([] call KPLIB_fnc_getPlayerCount) <= 20) then {
		_req = 1;
	};
	if((isServer && hasInterface) || DEBUG_PLAYER_COUNT_OVERRIDE != 1) then {
		// Running as local testing environment or test mode override on a server
		_req = 1;
	};
	_req
};

BATTLESPACE_TASK_FORCE_GET_PROC_RANGE = {
	params ["_taskForceType"];

	
	private _range = switch (_taskForceType) do {
		
		case "Minefield": { BATTLESPACE_MINEFIELD_PROC_RANGE };
		case "Anti-Air": { BATTLESPACE_AA_PROC_RANGE };
		case "Air Response": { BATTLESPACE_AIR_PROC_RANGE };
		case "Airborne Transport": { BATTLESPACE_AIR_PROC_RANGE };
		default { BATTLESPACE_UNIT_PROC_RANGE };

	};

	_range
};
BATTLESPACE_TASK_FORCE_SPAWN_VEHICLE = {
    params ["_pos", "_class", ["_airHeight", -1], ["_airDirection", 0]];

    private _veh = objNull;

    if(_class isKindOf "Air") then {
        _veh = createVehicle [_class, (_pos vectorAdd [0,0,50]), [], 0, "FLY"];
        _veh flyInHeight 45;
        if (_airHeight >= 0) then {
            // FLY can override the supplied Z. Initialize altitude and forward
            // airspeed before crew init; never reposition an active attack run.
            private _airPosition = +_pos;
            _airPosition set [2, (getTerrainHeightASL _pos max 0) + _airHeight];
            _veh setPosASL _airPosition;
            _veh setDir _airDirection;
            _veh flyInHeight _airHeight;
            _veh flyInHeightASL [_airPosition select 2, _airPosition select 2, _airPosition select 2];
            _veh setVelocityModelSpace [0, [20,160] select (_veh isKindOf "Plane"), 0];
        };
    } else {
        _veh = _class createVehicle _pos;
    };

    [_veh] call KPLIB_fnc_addObjectInit;
    private _crew = units (createVehicleCrew _veh);
    {
        _x addMPEventHandler ["MPKilled", {_this spawn kill_manager}];
        [_x] call KPLIB_fnc_addObjectInit;
    } forEach _crew;

    _veh addMPEventHandler ["MPKilled", {_this spawn kill_manager}];

    _veh

};

BATTLESPACE_TASK_FORCE_SPAWN_INFANTRY = {

	params [
		["_type", "", [""]],
		["_spawnPos", [0, 0, 0], [[], objNull, grpNull], [2, 3]],
		["_group", grpNull, [grpNull]],
		["_rank", "PRIVATE", [""]],
		["_placement", 0, [0]]
	];

	private ["_unit"];
	isNil {
		// Create temp group, as we need to let the unit join the "correct side group".
		// If we use the "correct side group" for the createUnit, the group would switch to the side of the unit written in the config.
		private _groupTemp = createGroup [CIVILIAN, true];

		_unit = _groupTemp createUnit [_type, _spawnPos, [], _placement, "FORM"];
		_unit addMPEventHandler ["MPKilled", {_this spawn kill_manager}];
		_unit setRank _rank;

		// Join to target group to preserve Side
		[_unit] joinSilent _group;
		deleteGroup _groupTemp;

		// Process KP object init

		[_unit] call KPLIB_fnc_addObjectInit;
	};

	_unit

};

BATTLESPACE_TASK_FORCE_HAS_VEHICLES = {
	params ["_group"];
	private _hasVehicle = false;
	{	
		if(!((vehicle _x) isEqualTo _x) && alive _x) exitWith { _hasVehicle = true };
	} forEach (units _group);
	_hasVehicle
};

BATTLESPACE_TASK_FORCE_GET_WAYPOINT_ROUTE = {
    params ["_group", "_destination", ["_route", []]];
    private _leader = leader _group;
    private _taskForceName = _group getVariable ["TASKFORCEID", ""];
    if (_taskForceName == "" && {!isNull _leader}) then {
        _taskForceName = _leader getVariable ["TASKFORCEID", ""];
    };
    if (_route isEqualTo [] && {_taskForceName != ""}) then {
        _route = BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_taskForceName, []];
    };
    if (_route isEqualTo []) exitWith {[[], _taskForceName, 0]};
    if !([_route] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID) exitWith {
        diag_log format ["Task Force %1 withheld an invalid route from active-group waypoints", _taskForceName];
        [[], _taskForceName, 0]
    };
    private _state = _group getVariable ["BATTLESPACE_ROUTE_STATE", []];
    private _index = 0;
    if ((_state param [0, []]) isEqualTo _route) then {
        _index = _state select 2;
    } else {
        private _force = BATTLESPACE_TASK_FORCES getOrDefault [_taskForceName, []];
        if (_route isEqualTo (BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_taskForceName, []])) then {
            _index = ((_force param [5, []]) param [1, 0]) max 0;
        };
        _index = _index min (count _route - 1);
        // Materialized followers can be behind the simulated leader. Walk only
        // adjacent predecessors, never search for a nearby future road branch.
        private _position = getPosATL vehicle _leader;
        while {_index > 0 && {_position distance2D (_route select (_index - 1)) < _position distance2D (_route select _index)}} do {
            _index = _index - 1;
        };
        if (_index < count _route - 1 && {_position distance2D (_route select _index) < 1}) then {_index = _index + 1};
    };
    [_route, _taskForceName, _index min (count _route - 1)]
};

BATTLESPACE_TASK_FORCE_WAYPOINT_RADIUS = {
    params ["_route", "_index"];
    private _spacing = 40;
    if (_index > 0) then {_spacing = _spacing min ((_route select _index) distance2D (_route select (_index - 1)))};
    if (_index < count _route - 1) then {_spacing = _spacing min ((_route select _index) distance2D (_route select (_index + 1)))};
    // Adjacent completion circles must not overlap across a bend or junction.
    0.01 max (12 min (_spacing * 0.35))
};

BATTLESPACE_TASK_FORCE_ROUTE_ADVANCE = {
    params ["_group", "_token", "_completed"];
    if (isRemoteExecuted || {isNull _group} || {!local _group} || {(_group getVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", -1]) != _token}) exitWith {};
    private _state = _group getVariable ["BATTLESPACE_ROUTE_STATE", []];
    if (_state isEqualTo []) exitWith {};
    _state params ["_route", "_loaded", "_cursor", "_speed", "_combatMode", "_finalType", "_finalBehaviour", "_payload"];
    _state set [2, _cursor max (_completed + 1)];
    if (_loaded >= count _route || {_loaded - (_state select 2) > 5}) exitWith {};
    // Keep the current native waypoint alive during its completion callback.
    // Refill ahead of it, without polling or stopping at window boundaries.
    while {currentWaypoint _group > 1} do {deleteWaypoint [_group, 0]};
    private _end = (count _route) min (_loaded + (20 - count waypoints _group));
    for "_i" from _loaded to (_end - 1) do {
        private _final = _i == count _route - 1;
        private _position = _route select _i;
        if (count _position == 2) then {_position = [_position select 0, _position select 1, 0]};
        // Radius zero still permits native placement shifts. -1 uses exact ASL.
        private _wp = _group addWaypoint [ATLToASL _position, -1];
        _wp setWaypointType (["MOVE", _finalType] select _final);
        _wp setWaypointSpeed _speed;
        _wp setWaypointBehaviour ([( ["SAFE", "AWARE"] select (_finalType == "SAD")), _finalBehaviour] select _final);
        _wp setWaypointCombatMode _combatMode;
        _wp setWaypointCompletionRadius ([_route, _i] call BATTLESPACE_TASK_FORCE_WAYPOINT_RADIUS);
        _wp setWaypointStatements ["true", format ["[group this, %1, %2] call BATTLESPACE_TASK_FORCE_ROUTE_ADVANCE", _token, _i]];
        if (_final && {_finalType == "TR UNLOAD"}) then {
            // Keep the existing unloading envelope; only transit targets tighten.
            _wp setWaypointCompletionRadius 200;
            _payload synchronizeWaypoint [_wp];
        };
        if (_final && {_finalType == "MOVE"}) then {
            private _hold = _group addWaypoint [ATLToASL _position, -1];
            _hold setWaypointType "HOLD";
            _hold setWaypointCompletionRadius 30;
            _hold setWaypointBehaviour _finalBehaviour;
            _hold setWaypointCombatMode _combatMode;
        };
    };
    _state set [1, _end];
};


BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS = {
	params ["_group", "_destination", ["_speed", "LIMITED"], ["_ambush", false], ["_isVehicle", false], ["_route", []]];

	if(!canSuspend) exitWith { _this spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS };
	if (isNull _group || {!local _group}) exitWith {};
    private _force = BATTLESPACE_TASK_FORCES getOrDefault [_group getVariable ["TASKFORCEID", ""], []];
    if ((_force param [0, ""]) == "Air Response") exitWith {};
	private _routeToken = (_group getVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", 0]) + 1;
	_group setVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", _routeToken];

	while {(count (waypoints _group)) != 0} do {deleteWaypoint ((waypoints _group) select 0);};

	sleep 1;
    if (!local _group || {(_group getVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", -1]) != _routeToken}) exitWith {};

	if(!_ambush) then {
		private _routeData = [_group, _destination, _route] call BATTLESPACE_TASK_FORCE_GET_WAYPOINT_ROUTE;
        _routeData params ["_waypointRoute", "_taskForceName", "_startIndex"];
        private _force = BATTLESPACE_TASK_FORCES getOrDefault [_taskForceName, []];
        private _type = _force param [0, ""];
        private _phase = (BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_taskForceName, createHashMap]) getOrDefault ["phase", ""];
        private _fieldHunt = (_group getVariable ["BATTLESPACE_RESERVE_FIELD_HUNT", false])
            || {_type == "Battlegroup" && {_phase in ["ENGAGING", "ASSAULTING"]}};
        private _combatMode = "YELLOW";
        if (_type == "Deep Reconnaissance Patrol") then {
            _combatMode = [_group] call BATTLESPACE_DEEP_RECON_GET_COMBAT_MODE;
            [_group] call BATTLESPACE_DEEP_RECON_APPLY_ROE;
        };
        if (_type == "Battlegroup") then {
            _group setCombatMode _combatMode;
            {_x setUnitCombatMode _combatMode} forEach units _group;
        };
		if (_waypointRoute isEqualTo [] && {_taskForceName != ""}) exitWith {
			private _hold = _group addWaypoint [getPos (leader _group), 0];
            _hold setWaypointCompletionRadius 30;
            _hold setWaypointType "HOLD";
            _hold setWaypointCombatMode _combatMode;
		};
		if (_waypointRoute isEqualTo []) then {_waypointRoute = [+_destination]};
        private _finalType = ["MOVE", "SAD"] select _fieldHunt;
        private _finalBehaviour = [(["SAFE", "COMBAT"] select _isVehicle), "AWARE"] select _fieldHunt;
        if (_type == "Convoy") then {_finalBehaviour = "SAFE"};
        _group setVariable ["BATTLESPACE_ROUTE_STATE", [_waypointRoute, _startIndex, _startIndex, [_speed, "FULL"] select _fieldHunt, _combatMode, _finalType, _finalBehaviour, []]];
        [_group, _routeToken, _startIndex - 1] call BATTLESPACE_TASK_FORCE_ROUTE_ADVANCE;
	} else {
		private _pos = getPos (leader _group);
		private _waypoint = _group addWaypoint [_pos, 0];

		_waypoint setWaypointType "SENTRY";
        _waypoint setWaypointCompletionRadius 30;
		_waypoint setWaypointSpeed _speed;
		_waypoint setWaypointBehaviour "STEALTH";
		_waypoint setWaypointCombatMode "YELLOW";
	};
	

};

BATTLESPACE_TASK_FORCE_APPLY_ROUTE_TO_ACTIVE = {
	params ["_taskForceName", "_taskForce", "_route"];
	if (_route isEqualTo []) exitWith {};
	private _type = _taskForce param [0, ""];
    // Aircraft controllers own landing/attack runs; route workers must not replace them.
    if (_type in ["Airborne Transport", "Air Response"]) exitWith {};
	private _destination = _taskForce param [2, []];
	private _speed = ["LIMITED", "FULL"] select (_type in ["Battlegroup", "Mobile Reserve", "Deep Reconnaissance Patrol", "Convoy", "Air Response", "Airborne Transport"]);
	{
		if (_type in ["Garrison", "Defensive Patrol", "Reconnaissance Patrol", "Ambush Patrol"] && {!isNull _x}) then {
			private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_taskForceName, createHashMap];
			private _args = [_x, _destination, _route, _operation getOrDefault ["defenseRole", ""], (_operation getOrDefault ["phase", ""]) == "RETURNING"];
			if (local _x) then {_args call BATTLESPACE_DEFENSE_APPLY_ROUTE} else {_args remoteExecCall ["BATTLESPACE_DEFENSE_APPLY_ROUTE", groupOwner _x]};
			continue;
		};
		if (_type == "Mobile Reserve" && {!isNull _x}) then {
			private _phase = (BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_taskForceName, createHashMap]) getOrDefault ["phase", "READY"];
			private _args = [_x, _destination, _route, _phase == "FIELD_HUNT", _phase == "RETURNING"];
			if (local _x) then {_args call BATTLESPACE_RESERVE_APPLY_ROUTE} else {_args remoteExecCall ["BATTLESPACE_RESERVE_APPLY_ROUTE", groupOwner _x]};
			continue;
		};
		if (isNull _x || {!local _x}) then {continue};
		private _parentTransport = _x getVariable ["BATTLESPACE_TRANSPORT_PARENT_GROUP", grpNull];
		if (!isNull _parentTransport) then {continue};
		private _transportVehicle = _x getVariable ["BATTLESPACE_TRANSPORT_VEHICLE", objNull];
		private _cargoGroup = _x getVariable ["BATTLESPACE_TRANSPORT_CARGO_GROUP", grpNull];
		if (!isNull _transportVehicle && {!isNull _cargoGroup}) then {
			[_transportVehicle, _x, _cargoGroup, _destination, false, _route] spawn BATTLESPACE_TASK_FORCE_TRANSPORT_AI;
			continue;
		};
		private _hasVehicles = [_x] call BATTLESPACE_TASK_FORCE_HAS_VEHICLES;
		[_x, _destination, _speed, false, _hasVehicles, _route] spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
	} forEach (_taskForce param [4, []]);
};

BATTLESPACE_TASK_FORCE_TRANSPORT_AI = {
	params ["_vehicle", "_transportGroup", "_group", "_destination", ["_willDismount", false], ["_route", []]];

	if(!canSuspend) exitWith { _this spawn BATTLESPACE_TASK_FORCE_TRANSPORT_AI };
	if (isNull _vehicle || {isNull _transportGroup} || {!local _vehicle} || {!local _transportGroup}) exitWith {};


	while {(count (waypoints _transportGroup)) != 0} do {deleteWaypoint ((waypoints _transportGroup) select 0);};
	while {(count (waypoints _group)) != 0} do {deleteWaypoint ((waypoints _group) select 0);};
	private _routeToken = (_transportGroup getVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", 0]) + 1;
	_transportGroup setVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", _routeToken];
    private _waypointToken = (_transportGroup getVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", 0]) + 1;
    _transportGroup setVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", _waypointToken];


	private _unload_distance = 600 + random 300;
	sleep 2;
    if (!local _transportGroup || {!local _vehicle} || {(_transportGroup getVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", -1]) != _routeToken}) exitWith {};
	private _routeData = [_transportGroup, _destination, _route] call BATTLESPACE_TASK_FORCE_GET_WAYPOINT_ROUTE;
    _routeData params ["_waypointRoute", "_taskForceName", "_startIndex"];
	if (_waypointRoute isEqualTo [] && {_taskForceName != ""}) exitWith {
		private _hold = _transportGroup addWaypoint [getPos (leader _transportGroup), 0];
		_hold setWaypointType "HOLD";
        _hold setWaypointCompletionRadius 30;
	};
	if (_waypointRoute isEqualTo []) then {_waypointRoute = [+_destination]};
    private _infWp = _group addWaypoint [_destination, 0];
    _infWp setWaypointType "GETOUT";
    _infWp setWaypointCompletionRadius 200;
    _transportGroup setVariable ["BATTLESPACE_ROUTE_STATE", [_waypointRoute, _startIndex, _startIndex, "FULL", "YELLOW", "TR UNLOAD", "SAFE", _infWp]];
    [_transportGroup, _waypointToken, _startIndex - 1] call BATTLESPACE_TASK_FORCE_ROUTE_ADVANCE;

	waitUntil {
        sleep 5;

        private _nearby = false;
		private _targets = [];
		// Check for threats. If there are threats, should dismount.
		if(alive (driver _vehicle)) then {

            _targets = ([_transportGroup] call BATTLESPACE_CONTACT_COLLECT) select {
                !((_x select 5) isKindOf "Air") && {CBA_missionTime - (_x select 2) <= 45}
            };


			if((count _targets) > 0) then {
				_nearby = true;
			};
			
		};
        !(alive _vehicle) ||
        !(alive (driver _vehicle)) ||
        ((_vehicle distance2D _destination) <= _unload_distance) ||
		_nearby ||
		{(_transportGroup getVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", -1]) != _routeToken}
    };
	if ((_transportGroup getVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", -1]) != _routeToken) exitWith {};

	{unassignVehicle _vehicle} forEach (units _group);
	_group leaveVehicle _vehicle;
	(units _group) allowGetIn false;

	 while {(count (waypoints _transportGroup)) != 0} do {deleteWaypoint ((waypoints _transportGroup) select 0);};

	if(_willDismount) then {
		_transportGroup leaveVehicle _vehicle;
	};

    // Dismounted passengers inherit the carrier's ordered cursor, not its origin.
    _group setVariable ["BATTLESPACE_ROUTE_STATE", +(_transportGroup getVariable ["BATTLESPACE_ROUTE_STATE", []])];
	[_transportGroup, _destination, "LIMITED", false, true, _route] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
	[_group, _destination, "LIMITED", false, false, _route] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
};
