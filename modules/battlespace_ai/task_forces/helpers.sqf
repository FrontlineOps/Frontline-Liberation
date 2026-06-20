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
		case "Rotary Patrol": { BATTLESPACE_AIR_PROC_RANGE };
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

BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS = {
	params ["_group", "_destination", ["_speed", "LIMITED"], ["_ambush", false], ["_isVehicle", false]];

	if(!canSuspend) exitWith { _this spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS };

	while {(count (waypoints _group)) != 0} do {deleteWaypoint ((waypoints _group) select 0);};

	sleep 1;

	private _behavior = "SAFE";

	if(_isVehicle) then {
		_behavior = "COMBAT";
	};

	if(!_ambush) then {
	
		private _waypoint = _group addWaypoint [_destination, 10];
		_waypoint setWaypointType "MOVE";
		_waypoint setWaypointSpeed _speed;
		_waypoint setWaypointBehaviour _behavior;
		_waypoint setWaypointCombatMode "YELLOW";
		_waypoint setWaypointCompletionRadius 30;

		_waypoint = _group addWaypoint [_destination, 200];
		_waypoint setWaypointType "MOVE";
		_waypoint = _group addWaypoint [_destination, 200];
		_waypoint setWaypointType "MOVE";
		_waypoint = _group addWaypoint [_destination, 200];
		_waypoint setWaypointType "MOVE";
		_waypoint = _group addWaypoint [_destination, 200];
		_waypoint setWaypointType "CYCLE";
	} else {
		private _pos = getPos (leader _group);
		private _waypoint = _group addWaypoint [_pos, 0];

		_waypoint setWaypointType "SENTRY";
		_waypoint setWaypointSpeed _speed;
		_waypoint setWaypointBehaviour "STEALTH";
		_waypoint setWaypointCombatMode "YELLOW";
	};
	

};

BATTLESPACE_TASK_FORCE_TRANSPORT_AI = {
	params ["_vehicle", "_transportGroup", "_group", "_destination", ["_willDismount", false]];

	if(!canSuspend) exitWith { _this spawn BATTLESPACE_TASK_FORCE_TRANSPORT_AI };


	while {(count (waypoints _transportGroup)) != 0} do {deleteWaypoint ((waypoints _transportGroup) select 0);};
	while {(count (waypoints _group)) != 0} do {deleteWaypoint ((waypoints _group) select 0);};


	private _unload_distance = 600 + random 300;
	sleep 2;

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
        _nearby
    };

	{unassignVehicle _vehicle} forEach (units _group);
	_group leaveVehicle _vehicle;
	(units _group) allowGetIn false;

	 while {(count (waypoints _transportGroup)) != 0} do {deleteWaypoint ((waypoints _transportGroup) select 0);};

	if(_willDismount) then {
		_transportGroup leaveVehicle _vehicle;
	};

	[_transportGroup, _destination] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
	[_group, _destination] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
};