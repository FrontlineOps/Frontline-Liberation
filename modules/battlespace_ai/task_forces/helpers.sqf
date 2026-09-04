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
	params ["_pos", "_class"];

	private _veh = objNull;

	if(_class isKindOf "Air") then {
		_veh = createVehicle [_class, (_pos vectorAdd [0,0,50]), [], 0, "FLY"];
		_veh flyInHeight 45;
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
		_route = +(BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_taskForceName, []]);
	};
	if (_route isEqualTo []) exitWith {[[], _taskForceName]};
	if !([_route] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID) exitWith {
		diag_log format ["Task Force %1 withheld an invalid route from active-group waypoints", _taskForceName];
		[[], _taskForceName]
	};

	private _startIndex = 0;
	if (_taskForceName != "") then {
		private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceName;
		if (!isNil "_taskForce") then {
			private _state = _taskForce param [5, []];
			_startIndex = 0 max ((_state param [1, 0]) - 1);
		};
	};
	if (!isNull _leader) then {
		private _leaderPosition = getPos _leader;
		private _closestIndex = 0;
		private _closestDistance = 1e30;
		{
			private _distance = _leaderPosition distance2D _x;
			if (_distance < _closestDistance) then {
				_closestDistance = _distance;
				_closestIndex = _forEachIndex;
			};
		} forEach _route;
		_startIndex = _startIndex max _closestIndex;
	};
	if (_startIndex > 0 && {_startIndex < count _route}) then {
		_route = _route select [_startIndex];
	};

	private _maximumWaypoints = 20;
	if (count _route > _maximumWaypoints) then {
		private _sampled = [];
		private _stride = ceil ((count _route - 1) / (_maximumWaypoints - 1));
		for "_i" from 0 to (count _route - 2) step _stride do {
			_sampled pushBack (_route select _i);
		};
		_sampled pushBack (_route select (count _route - 1));
		_route = _sampled;
	};
	_route set [count _route - 1, +_destination];
	[_route, _taskForceName]
};

BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS = {
	params ["_group", "_destination", ["_speed", "LIMITED"], ["_ambush", false], ["_isVehicle", false], ["_route", []]];

	if(!canSuspend) exitWith { _this spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS };
	if (isNull _group || {!local _group}) exitWith {};
	private _routeToken = (_group getVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", 0]) + 1;
	_group setVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", _routeToken];

	while {(count (waypoints _group)) != 0} do {deleteWaypoint ((waypoints _group) select 0);};

	sleep 1;
	if ((_group getVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", -1]) != _routeToken) exitWith {};

	if(!_ambush) then {
		private _routeData = [_group, _destination, _route] call BATTLESPACE_TASK_FORCE_GET_WAYPOINT_ROUTE;
		_routeData params ["_waypointRoute", "_taskForceName"];
		if (_waypointRoute isEqualTo [] && {_taskForceName != ""}) exitWith {
			private _hold = _group addWaypoint [getPos (leader _group), 0];
			_hold setWaypointType "HOLD";
		};
		if (_waypointRoute isEqualTo []) then {_waypointRoute = [+_destination]};

		{
			private _isFinal = _forEachIndex == count _waypointRoute - 1;
			private _waypoint = _group addWaypoint [_x, [20, 10] select _isFinal];
			_waypoint setWaypointType "MOVE";
			_waypoint setWaypointSpeed _speed;
			_waypoint setWaypointBehaviour (["SAFE", ["SAFE", "COMBAT"] select _isVehicle] select _isFinal);
			_waypoint setWaypointCombatMode "YELLOW";
			_waypoint setWaypointCompletionRadius ([60, 30] select _isFinal);
		} forEach _waypointRoute;

		private _hold = _group addWaypoint [_destination, 30];
		_hold setWaypointType "HOLD";
		_hold setWaypointBehaviour (["SAFE", "COMBAT"] select _isVehicle);
	} else {
		private _pos = getPos (leader _group);
		private _waypoint = _group addWaypoint [_pos, 0];

		_waypoint setWaypointType "SENTRY";
		_waypoint setWaypointSpeed _speed;
		_waypoint setWaypointBehaviour "STEALTH";
		_waypoint setWaypointCombatMode "YELLOW";
	};
	

};

BATTLESPACE_TASK_FORCE_APPLY_ROUTE_TO_ACTIVE = {
	params ["_taskForceName", "_taskForce", "_route"];
	if (_route isEqualTo []) exitWith {};
	private _type = _taskForce param [0, ""];
	private _destination = _taskForce param [2, []];
	private _speed = ["LIMITED", "FULL"] select (_type in ["Battlegroup", "Mobile Reserve", "Deep Reconnaissance Patrol", "Convoy", "Air Response", "Airborne Transport"]);
	{
		if (isNull _x || {!local _x}) then {continue};
		private _parentTransport = _x getVariable ["BATTLESPACE_TRANSPORT_PARENT_GROUP", grpNull];
		if (!isNull _parentTransport) then {continue};
		if (_type == "Airborne Transport") then {
			private _hasAirVehicle = units _x findIf {
				private _vehicle = vehicle _x;
				!(_vehicle isEqualTo _x) && {_vehicle isKindOf "Air"}
			} >= 0;
			if (_hasAirVehicle) then {
				[_x, _destination, "FULL", false, true, _route] spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
			};
			continue;
		};
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


	private _unload_distance = 600 + random 300;
	sleep 2;
	if ((_transportGroup getVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", -1]) != _routeToken) exitWith {};
	private _routeData = [_transportGroup, _destination, _route] call BATTLESPACE_TASK_FORCE_GET_WAYPOINT_ROUTE;
	_routeData params ["_waypointRoute", "_taskForceName"];
	if (_waypointRoute isEqualTo [] && {_taskForceName != ""}) exitWith {
		private _hold = _transportGroup addWaypoint [getPos (leader _transportGroup), 0];
		_hold setWaypointType "HOLD";
	};
	if (_waypointRoute isEqualTo []) then {_waypointRoute = [+_destination]};
	for "_i" from 0 to (count _waypointRoute - 2) do {
		private _routeWaypoint = _transportGroup addWaypoint [_waypointRoute select _i, 20];
		_routeWaypoint setWaypointType "MOVE";
		_routeWaypoint setWaypointSpeed "FULL";
		_routeWaypoint setWaypointBehaviour "SAFE";
		_routeWaypoint setWaypointCombatMode "YELLOW";
		_routeWaypoint setWaypointCompletionRadius 60;
	};

	private _transVehWp =  _transportGroup addWaypoint [_destination, 0,0];
    _transVehWp setWaypointType "TR UNLOAD";
    _transVehWp setWaypointCompletionRadius 200;

    private _infWp = _group addWaypoint [_destination, 0];
    _infWp setWaypointType "GETOUT";
    _infWp setWaypointCompletionRadius 200;

    _infWp synchronizeWaypoint [_transVehWp];

	waitUntil {
        sleep 5;

        private _nearby = false;
		private _targets = [];
		// Check for threats. If there are threats, should dismount.
		if(alive (driver _vehicle)) then {

			if(!(local (driver _vehicle))) then {
				[driver _vehicle] remoteExec ["BATTLESPACE_ARTILLERY_OBSERVER_REPORT_REMOTE", (driver _vehicle)];

				_targets = (driver _vehicle) getVariable ["BSA_Targets", []];
			} else {
				_targets = (driver _vehicle) targets [true, 0, [GRLIB_side_friendly], 45];
			};

			_targets = _targets select { !(_x isKindOf "Air") && alive _x };


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

	[_transportGroup, _destination, "LIMITED", false, true, _route] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
	[_group, _destination, "LIMITED", false, false, _route] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
};
