BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP = {
	params ["_taskForceName", "_taskForce"];
	_taskForce params [
					"_taskForceType", // 0
					"_currentLoc", // 1
					["_destination", []], // 2
					"_composition", // 3
					["_activeGroups", []], // 4
					["_state", []], // 5
					["_taskForceSide", east], // 6
					["_despawnCounter", 0], // 7
					["_activeObjects", []], // 8
					["_wasDespawning", false], // 9
					["_homePoint", []], // 10
					["_spawning", false], // 11
					["_hpSector", nil] // 12
				];

	if !(_state isEqualType []) then {
		_state = ["IDLE", 0, 0];
		_taskForce set [5, _state];
	};
	private _status = _state param [0, "IDLE", [""]];
	private _currentPathIndex = _state param [1, 0, [0]];
	private _failureCounts = _state param [2, 0, [0]];
	_state set [0, _status];
	_state set [1, _currentPathIndex];
	_state set [2, _failureCounts];

	private _curPath = BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_taskForceName, []];
	private _routeNodeCount = if (_curPath isEqualType []) then {count _curPath} else {-1};
	private _queueReplacementRoute = {
		params ["_reason"];
		BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
		_state set [1, 0];
		_taskForce set [5, _state];
		diag_log format [
			"[BATTLESPACE][ROUTE][ERROR] Task Force %1 rejected route state: %2 | index=%3 | nodes=%4 | current=%5 | destination=%6. Replacement queued.",
			_taskForceName,
			_reason,
			_currentPathIndex,
			_routeNodeCount,
			_currentLoc,
			_destination
		];
		[_taskForceName, _currentLoc, _destination] call QUEUE_PATHFIND_REQUEST;
		false
	};

	if !(_curPath isEqualType []) exitWith {
		["route is not an array"] call _queueReplacementRoute
	};
	if (_curPath isEqualTo []) exitWith {

		_state set [1, 0];
		_taskForce set [5, _state];
		[_taskForceName, _currentLoc, _destination] call QUEUE_PATHFIND_REQUEST;
		false
		
	};
	if !(_currentPathIndex isEqualType 0) exitWith {
		["non-numeric path index"] call _queueReplacementRoute
	};
	_currentPathIndex = floor _currentPathIndex;
	if (_currentPathIndex < 0 || {_currentPathIndex >= count _curPath}) exitWith {
		[format ["path index %1 outside %2 nodes", _currentPathIndex, count _curPath]] call _queueReplacementRoute
	};
	if !([_curPath] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID) exitWith {
		["route contains a malformed node"] call _queueReplacementRoute
	};
	// Have a path, travel.

	private _travelSpeed = 160;
	private _manpower = _composition getOrDefault ["manpower", 0];
	private _vehicles = _composition getOrDefault ["vehicles", []];
	private _hasVehs = (count (_vehicles)) > 0;

	if(!_hasVehs && _manpower <= 0) exitWith {};

	if(!_hasVehs) then {
		_travelSpeed = 20;
	} else {

		private _air = 0;
		{
			if(_x isKindOf "Air") then {
				_air = _air + 1;
			};
		} forEach _vehicles;

		if(_air >= (count _vehicles)) then {
			_travelSpeed = 240;
		};
	};

	private _iterations = round (_travelSpeed / 20);

	private _iterDist = _travelSpeed / _iterations;

	private _newPos = _currentLoc;
	private _nextNode = _curPath param [_currentPathIndex, []];
	for "_i" from 1 to _iterations do {

		
		
		while { !(_nextNode isEqualTo []) && {(_newPos distance2D _nextNode) < 35} && {_currentPathIndex < (count _curPath - 1)} } do {
			if(_currentPathIndex < (count _curPath - 1)) then {
				_currentPathIndex = _currentPathIndex + 1;
				_nextNode = _curPath param [_currentPathIndex, []];
			};
		};

		_state set [1, _currentPathIndex];

		if !(_nextNode isEqualTo []) then {
			private _remainingDistance = _newPos distance2D _nextNode;
			if (_remainingDistance <= _iterDist) then {
				_newPos = +_nextNode;
			} else {
				private _dirUnitVec = _newPos vectorFromTo _nextNode;
				_newPos = _newPos vectorAdd (_dirUnitVec vectorMultiply _iterDist);
			};

			_newPos set [2, 0];

			
		};
	};

	
	_taskForce set [1, _newPos];
	
};

BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN = {
	params ["_taskForceName", "_spawnedTaskForce", "_success"];

	private _activeGroups = +(_spawnedTaskForce param [4, []]);
	private _activeObjects = +(_spawnedTaskForce param [8, []]);
	private _registeredTaskForce = BATTLESPACE_TASK_FORCES get _taskForceName;

	// A failed or cancelled materialization must not leave physical entities behind.
	if (!_success || {isNil "_registeredTaskForce"}) then {
		{
			if (!isNull _x) then {
				deleteVehicle _x;
			};
		} forEach _activeObjects;
		{
			if (!isNull _x) then {
				deleteGroup _x;
			};
		} forEach _activeGroups;
	};

	if (!isNil "_registeredTaskForce") then {
		if (_success) then {
			// Scheduled spawn arguments are isolated from the canonical hashmap entry.
			// Publish materialized state before releasing the lock so evaluation cannot
			// observe an unlocked task force with no active objects and spawn it again.
			_registeredTaskForce set [4, _activeGroups];
			_registeredTaskForce set [8, _activeObjects];
			private _route = BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_taskForceName, []];
			if (_route isNotEqualTo []) then {
				[_taskForceName, _registeredTaskForce, _route] call BATTLESPACE_TASK_FORCE_APPLY_ROUTE_TO_ACTIVE;
			} else {
				private _currentLocation = _registeredTaskForce param [1, []];
				private _destination = _registeredTaskForce param [2, []];
				private _type = _registeredTaskForce param [0, ""];
				if (
					_type in ["Battlegroup", "Convoy", "Defensive Patrol", "Reconnaissance Patrol", "Rotary Patrol", "Civilians"]
					&& {_currentLocation isNotEqualTo []}
					&& {_destination isNotEqualTo []}
				) then {
					[_taskForceName, _currentLocation, _destination] call QUEUE_PATHFIND_REQUEST;
				};
			};
		};
		_registeredTaskForce set [11, false];
		BATTLESPACE_TASK_FORCES set [_taskForceName, _registeredTaskForce];
	} else {
		diag_log format [
			"Task Force %1 was removed while spawning; cleaned %2 orphaned objects and %3 groups",
			_taskForceName,
			count _activeObjects,
			count _activeGroups
		];
	};

	BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS deleteAt _taskForceName;
	_success && {!isNil "_registeredTaskForce"}
};

BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN = {
	params ["_taskForceName", "_taskForce", ["_garrisonedInfantry", false], ["_infantryCombinedWithVehicles", false], ["_ambush", false], ["_civilian", false], ["_speed", "LIMITED"], ["_overrideSquadAdditions", []]];
	_taskForce params [
		"_type", // 0
		"_currentLoc", // 1
		["_destination", []], // 2
		"_composition", // 3
		["_activeGroups", []], // 4
		["_state", []], // 5
		["_taskForceSide", east], // 6
		["_despawnCounter", 0], // 7
		["_activeObjects", []], // 8
		["_wasDespawning", false], // 9
		["_homePoint", []] // 10
	];
	diag_log format ["Attempting to spawn Task Force %1 (%2)", _taskForceName, _type];
	_state params ["_status", ["_currentPathIndex", 0]];

	// Avoid spawning above unit cap to preserve server health, groups will pop in once units are cleared
	if (([] call KPLIB_fnc_getOpforCap) >= BATTLESPACE_UNIT_CAP) exitWith { false };

	private _side = _taskForceSide;

	private _manpower = _composition getOrDefault ["manpower", 0];
	private _vehicles = _composition getOrDefault ["vehicles", []];
	private _structures = _composition getOrDefault ["structures", []];

	diag_log format ["  Unit cap within bounds, spawning Task Force"];
	diag_log format ["    Manpower %1", _manpower];
	diag_log format ["    Vehicles %1", _vehicles];
	diag_log format ["    Structures %1", _structures];

	// Loop through structures and spawn them first
	{
		private _rawDir = _x getOrDefault ["rotation", 0];
		private _pos = _x getOrDefault ["position", []];
		private _class = _x get "className";
		private _ignoresCollision = _x getOrDefault ["ignoreCollision", false];

		private _dir = _rawDir;
		if ( (typeName _rawDir) == "BOOL") then {

			private _dirToBlufor = 0;
			private _lowest = 90001;
			{  
				private _dist = (getPos _x) distance2D (_currentLoc);
				if(_dist < _lowest) then {
					_lowest = _dist;
					_dirToBlufor = _currentLoc getDir (getPos _x);
				};
			} forEach (allPlayers - entities "HeadlessClient_F");

			_dir = _dirToBlufor;

			if(!_rawDir) then { _dir = _dir + 180; };
		};

		if (isNil { _class } || (_pos isEqualTo [])) then { continue };
		private _building = objNull;
		if(_class isKindOf "MineBase") then {
			_building = createMine [_class, _pos, [], 0];
		} else {
			_building = createVehicle [_class, _pos, [], 0, ["", "CAN_COLLIDE"] select _ignoresCollision];
		};
		_building setDir _dir;

		_building addMPEventHandler ["MPKilled", { ["STRUCTURE", _this] call BATTLESPACE_TASK_FORCE_OBJECT_KILLED}];
		_building setVariable ["TASKFORCEID", _taskForceName];

		if(_building isKindOf "StaticWeapon") then {
			private _grp = createVehicleCrew _building;
			private _crew = units (_grp);

			{
				_activeObjects pushBack _x;
			} forEach _crew;

			_activeGroups pushBack _grp;
		};
		_activeObjects pushBack _building;
	} forEach _structures;

	sleep 5;
	diag_log format ["  Spawning Infantry and Vehicles"];
	diag_log format ["    Manpower %1", _manpower];
	diag_log format ["    Vehicles %1", _vehicles];
	// Is the Task Force on a road currently
	// If yes, we spawn along the road. Spawn along road objects for the vehicles in a column

	private _remainingManpower = _manpower;
	private _taskForceOnRoad = (count (_currentLoc nearRoads 33) > 0);
	private _spawnPositions = [];

	if(_taskForceOnRoad && !(_destination isEqualTo [])) then {
		// Find which way points towards the back of the column
		private _unitVecToDestination = _currentLoc vectorFromTo _destination;
		private _dirToFace = _currentLoc getDir _destination;

		private _previousRoad = objNull;
		private _currentRoad = (_currentLoc nearRoads 33) select 0;

		private _nextRoad = (roadsConnectedTo _currentRoad) select {
			private _dirToThisRoad = (getPos _currentRoad) vectorFromTo (getPos _x);
			private _directionLikeness = _unitVecToDestination vectorDotProduct _dirToThisRoad;

			_directionLikeness > 0
		};

		if((count _nextRoad) > 0) then {
			_dirToFace = (getPos _currentRoad) getDir (getPos (_nextRoad#0));
		};

		private _execs = 0;
		while { !(isNil { _currentRoad }) && (count _spawnPositions) < (count _vehicles) && _execs < ((count _vehicles) + 10) } do {
			_execs = _execs + 1;
			if(!(isNull _previousRoad)) then {
				_dirToFace = (getPos _currentRoad) getDir (getPos _previousRoad);
			};
			private _pos = (getPos _currentRoad) findEmptyPosition [0, 40, "B_APC_Tracked_01_rcws_F"];

			if(!(_pos isEqualTo [])) then {
				_spawnPositions pushBack [_pos, _dirToFace];
			};
			private _nextRoads = roadsConnectedTo _currentRoad;

			_nextRoads = _nextRoads select {
				private _dirToThisRoad = (getPos _currentRoad) vectorFromTo (getPos _x);
				private _directionLikeness = _unitVecToDestination vectorDotProduct _dirToThisRoad;

				_directionLikeness < 0
			};
			_previousRoad = _currentRoad;
			_currentRoad = _nextRoads#0;
		};
	};
	diag_log format ["    Road Positions Picked: %1 | WasOnRoad: %2 | ", _spawnPositions, _taskForceOnRoad];
	// Fill remaining spawn positions with random pos
	if((count _spawnPositions) < (count _vehicles)) then {
		private _remainder = (count _vehicles) - (count _spawnPositions);
		private _start = (count _spawnPositions) - 1;
		for "_i" from 1 to _remainder do {
			private _pos = [];
			private _execs = 0;
			while { (_pos isEqualTo []) && _execs <= 20 } do {
				_execs = _execs + 1;
			 	_pos = ((_currentLoc getPos [_i * 5 + random (50 + _execs * 5), random 360]) findEmptyPosition [_i * 15, 150, "B_APC_Tracked_01_rcws_F"]);
			};

			private _dir = random 360;

			if(!(_destination isEqualTo [])) then { _dir = _pos getDir _destination };
			_spawnPositions pushBack [_pos, _dir];
		};
	};
	diag_log format ["    Road Positions Picked: %1 | WasOnRoad: %2 | ", _spawnPositions, _taskForceOnRoad];
	// Loop through vehicles and spawn them at the spawn positions
	{
		
		private _spawnPos = _spawnPositions select _forEachIndex;
		_spawnPos params ["_pos", "_dir"];

		diag_log format ["    Spawn Vehicle at %1 class %2", _pos, _x];

		// Spawn the vehicle, init it, etc..
		private _veh = [_pos, _x] call BATTLESPACE_TASK_FORCE_SPAWN_VEHICLE;
		_activeObjects pushBack _veh;
		_veh setDir _dir;
		{
			_activeObjects pushBack _x;
		} forEach (crew _veh);

		// Add killed manager to remove the vehicle from the vehicle list
		_veh setVariable ["TASKFORCEID", _taskForceName];
		_veh addMPEventHandler ["MPKilled", { ["VEHICLE", _this] call BATTLESPACE_TASK_FORCE_OBJECT_KILLED }];
		// _veh addEventHandler ["Killed", { ["VEHICLE", _this] call BATTLESPACE_TASK_FORCE_OBJECT_KILLED }];
		private _vehGrp = group _veh;
		private _infGrp = createGroup [_side, true];
		_vehGrp setVariable ["TASKFORCEID", _taskForceName];
		_infGrp setVariable ["TASKFORCEID", _taskForceName];
		
		// If remaining manpower is >= 2, try to spawn passengers if the vehicle supports it
		// Minimum squad size is SL and medic
		if(_remainingManpower >= 2) then {
			//private _compositionEnum = [_x] call classIsWhatCompositionEnum;
			//private _canHavePassengers = [_compositionEnum] call compositionEnumIsInfantryTransport;

			private _canHavePassengers = true;
			if(_canHavePassengers && !_garrisonedInfantry) then {
				private _cargoSpots = fullCrew [_veh, "cargo", true];
				_cargoSpots = _cargoSpots + (fullCrew [_veh, "turret", true]);
				_cargoSpots = _cargoSpots select {
					private _unit = _x#0;

					isNull _unit
				};

				private _spots = count _cargoSpots;
				if(_spots <= 2) exitWith {};

				private _squadSize = _spots;
				_remainingManpower = _remainingManpower - _squadSize;
				if(_remainingManpower < 0) then {
					_squadSize = _squadSize + _remainingManpower;
					_remainingManpower = 0;
				};

				private _baseSquad = [_squadSize, _overrideSquadAdditions, _ambush] call BATTLESPACE_TASK_FORCES_GET_SQUAD_COMPOSITION;
				if(_civilian) then {
					_baseSquad = [];

					for "_i" from 1 to _squadSize do {
						_baseSquad pushBack (selectRandom civilians);
					};
				};

				private _start_pos = _currentLoc findEmptyPosition [0, 300];
				{
					private _grp = _infGrp;
					if(_infantryCombinedWithVehicles) then {
						_grp = _vehGrp;
					};
					private _unit = [_x, _start_pos, _grp, "PRIVATE", 0.5] call BATTLESPACE_TASK_FORCE_SPAWN_INFANTRY;

					_activeObjects pushBack _unit;
					// _unit setVariable ["lambs_danger_enableGroupReinforce", true, true];
					//if(!_infantryCombinedWithVehicles) then { _unit moveInCargo _veh; };
					_unit moveInCargo _veh;
					_unit setVariable ["TASKFORCEID", _taskForceName];
					_unit addMPEventHandler ["MPKilled", { ["MANPOWER", _this] call BATTLESPACE_TASK_FORCE_OBJECT_KILLED }];
		
				} foreach _baseSquad;
			};
		};
		if((count (units _infGrp)) > 0) then {
			_activeGroups pushBack _infGrp;
		};
		_activeGroups pushBack _vehGrp;

		// TODO: Determine vehicle waypoints
		// Attack destination
		if(!(_destination isEqualTo [])) then {
			if((count (units _infGrp)) > 0) then {
				_vehGrp setVariable ["BATTLESPACE_TRANSPORT_VEHICLE", _veh];
				_vehGrp setVariable ["BATTLESPACE_TRANSPORT_CARGO_GROUP", _infGrp];
				_infGrp setVariable ["BATTLESPACE_TRANSPORT_PARENT_GROUP", _vehGrp];
				[_veh, _vehGrp, _infGrp, _destination, false] spawn BATTLESPACE_TASK_FORCE_TRANSPORT_AI;
			} else {
				[_vehGrp, _destination, _speed, _ambush, true] spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
			};
		} else {
			// Defensive orders, don't make it explicitly move.
		};
	} forEach _vehicles;

	// Spawn remaining infantry squads
	if(_remainingManpower >= 2) then {
		private _nearbyHouses = (_currentLoc) nearObjects ["Building", 200];
		// NOTE: Yes, for some reason lamps and power lines are considered a house. What the fuck.
		_nearbyHouses = _nearbyHouses select {
			private _actualPositions = [_x] call BIS_fnc_buildingPositions;

			(count _actualPositions) > 0
		};
		private _maxSquadSize = 9;
		private _infantrySquadCount = ceil (_remainingManpower / _maxSquadSize);
		for "_i" from 1 to _infantrySquadCount do {
			private _infGrp = createGroup [_side, true];
			_infGrp setVariable ["TASKFORCEID", _taskForceName];
        	private _squadSize = _maxSquadSize min (_remainingManpower);
			private _housePos = [];
			private _garrisoned = false;
			if(_garrisonedInfantry && (count _nearbyHouses) > 0) then {
				private _house = selectRandom _nearbyHouses;
				_housePos = getPos _house;
				_nearbyHouses = _nearbyHouses - [_house];
				_garrisoned = true;
			};

			private _baseSquad = [_squadSize, _overrideSquadAdditions, _ambush] call BATTLESPACE_TASK_FORCES_GET_SQUAD_COMPOSITION;
			if(_civilian) then {
				_baseSquad = [];
				for "_i" from 1 to _squadSize do {
					_baseSquad pushBack (selectRandom civilians);
				};
			};

			private _start_pos = (_currentLoc getPos [random 200, random 360]) findEmptyPosition [0, 300];
			{
				private _unit = [_x, _start_pos, _infGrp, "PRIVATE", 0.5] call BATTLESPACE_TASK_FORCE_SPAWN_INFANTRY;
				// _unit setVariable ["lambs_danger_enableGroupReinforce", true, true];
				_activeObjects pushBack _unit;
				_unit setVariable ["TASKFORCEID", _taskForceName];
				_unit addMPEventHandler ["MPKilled", { ["MANPOWER", _this] call BATTLESPACE_TASK_FORCE_OBJECT_KILLED }];

			} foreach _baseSquad;

			if(_garrisoned) then {
				// Task-force groups are created on the server; issue the order once where local.
				[_infGrp, _housePos] call KPLIB_fnc_garrison;
			} else {
				// Attack waypoints
				if(!(_destination isEqualTo [])) then {
					// Slow pace towards objective via patrol ig
					[_infGrp, _destination, _speed, _ambush] spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
				} else {
					// Defensive patrol
					[_infGrp, _currentLoc, 300, 4, [], false, true] call KPLIB_fnc_taskPatrol;
				};
			};

			_remainingManpower = _remainingManpower - _squadSize;
			_activeGroups pushBack _infGrp;
		};
	};

	_taskForce set [8, _activeObjects];
	_taskForce set [4, _activeGroups];

	diag_log format ["  Task Force Spawned, created %1 Groups", count _activeGroups];

	true
};

[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\outpost.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\convoy.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\defensivePatrol.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\reconnaissancePatrol.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\ambushPatrol.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\battlegroup.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\garrison.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\fortifications.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\civilians.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\minefield.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\rotaryPatrol.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\antiair.sqf";
