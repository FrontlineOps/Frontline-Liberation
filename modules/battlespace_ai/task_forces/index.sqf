[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\createSquadComposition.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\helpers.sqf";

/*

	Current active task forces

	[key: task force name / number]: [
		_type : STRING
		_simulatedLocation : Location
		_targetLocation : Location
		_composition : {
			vehicles: Array of class names
			manpower: Number
			structures: [
				{
					rotation: Angle
					position: Location
					className: String
				}
			]	
		}
		_activeGroups : Array of Groups
		_state: Array of state specific stuff
		_taskForceSide : Side
	]

*/

if(isNil { BATTLESPACE_TASK_FORCES }) then {
	BATTLESPACE_TASK_FORCES = createHashMap;
};
if (isNil "BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS") then {
	BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS = [];
};
/*
	Pointer for next task force to use. Probably never going to get to overflow problems since it'd reset per map and probably would never reach 3.4028235e38
*/
BATTLESPACE_TASK_FORCE_AUTOINCREMENT = 1;

/*
	Models of Task Force types. Exposes several functions based on interface pattern.
	
	isAlive - Boolean - Evaluate if Task Force is still considered alive or not.
	onDone - Void -Task Force objectives accomplished, dissolve the force. (Usually absorption into another Entity)
	onDestroyed - Void -Task Force was destroyed.
	onDecisionTick - Boolean - True = Task Force is now 'done'
*/
BATTLESPACE_TASK_FORCE_MODELS = createHashMap;
BATTLESPACE_TASK_FORCE_PATHS = createHashMap;
if (isNil "BATTLESPACE_TASK_FORCE_ROUTE_SNAPSHOT") then {
	BATTLESPACE_TASK_FORCE_ROUTE_SNAPSHOT = createHashMap;
};
BATTLESPACE_TASK_FORCE_MINIMUM_SIZE = 4;
// Enable some more verbose diag logs and stuff.
BATTLESPACE_DEBUG_INDEPTH = false;
if (isNil "BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS") then {
	BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS = createHashMap;
};
if (isNil "BATTLESPACE_TASK_FORCE_SPAWN_QUEUE") then {
	BATTLESPACE_TASK_FORCE_SPAWN_QUEUE = [];
};
if (isNil "BATTLESPACE_TASK_FORCE_ACTIVE_SPAWNS") then {
	BATTLESPACE_TASK_FORCE_ACTIVE_SPAWNS = createHashMap;
};

BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION = {
	params ["_taskForceName"];
	BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS deleteAt _taskForceName;
	BATTLESPACE_TASK_FORCE_ACTIVE_SPAWNS deleteAt _taskForceName;
	BATTLESPACE_TASK_FORCE_SPAWN_QUEUE = BATTLESPACE_TASK_FORCE_SPAWN_QUEUE select {_x != _taskForceName};
};

BATTLESPACE_TASK_FORCE_REFRESH_SPAWN_RESERVATIONS = {
	private _reservationTotal = 0;
	private _expiredReservations = [];
	{
		private _reservedTaskForce = BATTLESPACE_TASK_FORCES get _x;
		_y params ["_reservedUnits", "_reservationExpiresAt"];
		private _isQueued = _x in BATTLESPACE_TASK_FORCE_SPAWN_QUEUE;
		if (
			isNil "_reservedTaskForce"
			|| {CBA_missionTime >= _reservationExpiresAt}
			|| {!_isQueued && {!(_reservedTaskForce param [11, false])}}
		) then {
			_expiredReservations pushBack _x;
		} else {
			_reservationTotal = _reservationTotal + _reservedUnits;
		};
	} forEach BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS;
	{
		[_x] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
	} forEach _expiredReservations;
	_reservationTotal
};

BATTLESPACE_TASK_FORCE_TRY_ADMIT_SPAWN = {
	params ["_taskForceName", "_taskForce", "_unitCount", "_reservationTotal", ["_source", ""]];

	private _hasSpawnReservation = !isNil {BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS get _taskForceName};
	private _spawning = _taskForce param [11, false];
	private _activeObjects = _taskForce param [8, []];
	if (_spawning || {_hasSpawnReservation} || {_activeObjects isNotEqualTo []}) exitWith {
		[false, _reservationTotal]
	};

	private _composition = _taskForce param [3, createHashMap];
	private _manpowerEstimate = _composition getOrDefault ["manpower", 0];
	private _vehicleEstimate = count (_composition getOrDefault ["vehicles", []]);
	private _staticEstimate = {
		private _className = _x getOrDefault ["className", ""];
		_className isKindOf "StaticWeapon"
	} count (_composition getOrDefault ["structures", []]);
	private _spawnEstimate = 1 max (_manpowerEstimate + (4 * (_vehicleEstimate + _staticEstimate)));
	if ((_unitCount + _reservationTotal + _spawnEstimate) > BATTLESPACE_UNIT_CAP) exitWith {
		[false, _reservationTotal]
	};

	BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS set [
		_taskForceName,
		[_spawnEstimate, CBA_missionTime + 180]
	];
	_taskForce set [9, false];
	BATTLESPACE_TASK_FORCE_SPAWN_QUEUE pushBackUnique _taskForceName;
	if (_source != "") then {
		[
			format [
				"Task Force %1 admitted to the existing spawn queue by %2 (estimate=%3 reservedTotal=%4)",
				_taskForceName,
				_source,
				_spawnEstimate,
				_reservationTotal + _spawnEstimate
			],
			"BATTLESPACE"
		] call KPLIB_fnc_log;
	};
	[true, _reservationTotal + _spawnEstimate]
};

BATTLESPACE_TASK_FORCE_SAVE_KEY = format ["BATTLESPACE_TASK_FORCES_%1", toUpper worldName];

BATTLESPACE_TASK_FORCE_REGISTER_MODEL = {
	params ["_modelName", "_modelDefinition"];

	BATTLESPACE_TASK_FORCE_MODELS set [_modelName, _modelDefinition];
};

[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\pathfinder.sqf";

if (isServer) then {
	private _losProcState = if (missionNamespace getVariable ["BATTLESPACE_LOS_PROC_ENABLED", false]) then {"ENABLED"} else {"DISABLED"};
	[
		format [
			"LoS proc prototype %1: closeRange=%2m footprintRadius=%3m scanInterval=%4s includeBluforAI=%5 groundHeight=%6m airHeight=%7m evaluatorCadence=10s",
			_losProcState,
			missionNamespace getVariable ["BATTLESPACE_LOS_PROC_CLOSE_RANGE", 200],
			missionNamespace getVariable ["BATTLESPACE_LOS_PROC_FOOTPRINT_RADIUS", 125],
			missionNamespace getVariable ["BATTLESPACE_LOS_PROC_SCAN_INTERVAL", 1],
			missionNamespace getVariable ["BATTLESPACE_LOS_PROC_INCLUDE_BLUFOR_AI", false],
			missionNamespace getVariable ["BATTLESPACE_LOS_PROC_GROUND_TARGET_HEIGHT", 1.5],
			missionNamespace getVariable ["BATTLESPACE_LOS_PROC_AIR_TARGET_HEIGHT", 50]
		],
		"BATTLESPACE"
	] call KPLIB_fnc_log;
};

BATTLESPACE_TASK_FORCE_PROCESS_SPAWN_QUEUE = {
	if (!isServer) exitWith {};

	private _now = CBA_missionTime;
	private _expiredActiveSpawns = [];
	{
		private _taskForce = BATTLESPACE_TASK_FORCES get _x;
		private _expiresAt = _y;
		if (
			isNil "_taskForce"
			|| {_now >= _expiresAt}
			|| {!(_taskForce param [11, false])}
		) then {
			_expiredActiveSpawns pushBack _x;
		};
	} forEach BATTLESPACE_TASK_FORCE_ACTIVE_SPAWNS;
	{
		[_x] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
	} forEach _expiredActiveSpawns;

	private _maxConcurrent = 1 max floor (missionNamespace getVariable ["BATTLESPACE_TASK_FORCE_SPAWN_MAX_CONCURRENT", 8]);
	if (count BATTLESPACE_TASK_FORCE_ACTIVE_SPAWNS >= _maxConcurrent) exitWith {};

	private _started = false;
	while {!_started && {BATTLESPACE_TASK_FORCE_SPAWN_QUEUE isNotEqualTo []}} do {
		private _taskForceName = BATTLESPACE_TASK_FORCE_SPAWN_QUEUE deleteAt 0;
		private _reservation = BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS get _taskForceName;
		private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceName;

		if (isNil "_reservation" || {isNil "_taskForce"}) then {
			[_taskForceName] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
		} else {
			private _model = BATTLESPACE_TASK_FORCE_MODELS get (_taskForce param [0, ""]);
			private _spawning = _taskForce param [11, false];
			private _activeObjects = _taskForce param [8, []];

			if (
				isNil "_model"
				|| {_activeObjects isNotEqualTo []}
				|| {!([_taskForceName, _taskForce] call (_model get "isAlive"))}
				|| {!([_taskForceName, _taskForce, _model] call BATTLESPACE_TASK_FORCE_CAN_PROC)}
			) then {
				[_taskForceName] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
			} else {
				private _reservationExpiresAt = _reservation param [1, _now + 180, [0]];
				if (_spawning) then {
					BATTLESPACE_TASK_FORCE_ACTIVE_SPAWNS set [_taskForceName, _reservationExpiresAt];
					_started = true;
				} else {
					[_taskForceName, _taskForce] call (_model get "doSpawn");
					if (_taskForce param [11, false]) then {
						BATTLESPACE_TASK_FORCE_ACTIVE_SPAWNS set [_taskForceName, _reservationExpiresAt];
						_started = true;
					} else {
						[_taskForceName] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
					};
				};
			};
		};
	};
};

BATTLESPACE_TASK_FORCES_LOAD = {
	diag_log format ["Battlespace Task Forces Loading..."];
	private _save = profileNamespace getVariable BATTLESPACE_TASK_FORCE_SAVE_KEY;

	private _saveValid = !isNil "_save"
		&& {typeName _save == "HASHMAP"}
		&& {(_save getOrDefault ["AI", -1]) isEqualType 0}
		&& {typeName (_save getOrDefault ["TaskForces", objNull]) == "HASHMAP"};

	if(_saveValid) then {
		diag_log format ["  Save valid"];
		// Loop through and init
		BATTLESPACE_TASK_FORCE_AUTOINCREMENT = _save get "AI";
		private _savedForces = _save get "TaskForces";

		{
			_y params [
				["_type", ""],
				["_currentLoc", []],
				["_destination", []],
				["_composition", createHashMap],
				["_homePoint", []],
				["_sideName", "EAST"],
				["_hpSector", ""]
			];
			private _savedSide = switch (toUpper _sideName) do {
				case "WEST": {west};
				case "INDEPENDENT": {resistance};
				case "GUER": {resistance};
				case "CIV";
				case "CIVILIAN": {civilian};
				default {east};
			};
			private _savedTaskForce = [
				_type,
				_currentLoc,
				_destination,
				_composition,
				[],
				["IDLE", 0, 0],
				_savedSide
			];

			_savedTaskForce set [10, _homePoint];
			if (_hpSector != "") then {_savedTaskForce set [12, _hpSector]};
			BATTLESPACE_TASK_FORCES set [_x, _savedTaskForce];
		} forEach _savedForces;

		diag_log format ["  Loaded AI %1 | # of Task Forces: %2", BATTLESPACE_TASK_FORCE_AUTOINCREMENT, count BATTLESPACE_TASK_FORCES];

		// publicVariable "BATTLESPACE_TASK_FORCES";
		publicVariable "BATTLESPACE_TASK_FORCE_AUTOINCREMENT";
	};
	
};

BATTLESPACE_TASK_FORCE_BUILD_ROUTE_SNAPSHOT = {
	params [["_taskForceIds", [], [[]]]];
	if (!isServer) exitWith {createHashMap};
	private _snapshot = createHashMap;
	private _pointLimit = 8 max floor (missionNamespace getVariable ["BATTLESPACE_ZEN_ROUTE_SNAPSHOT_POINT_LIMIT", 1024]);

	{
		private _taskForceName = _x;
		if (_taskForceIds isNotEqualTo [] && {!(_taskForceName in _taskForceIds)}) then {continue};
		private _route = _y;
		if !([_route] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID) then {continue};
		private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceName;
		if (isNil "_taskForce") then {continue};

		private _state = _taskForce param [5, ["IDLE", 0, 0]];
		private _absoluteIndex = if (_state isEqualType []) then {
			_state param [1, 0, [0]]
		} else {
			0
		};
		private _totalNodes = count _route;
		_absoluteIndex = (0 max floor _absoluteIndex) min (_totalNodes - 1);
		private _offset = 0;
		if (_totalNodes > _pointLimit) then {
			private _historyNodes = floor (_pointLimit * 0.2);
			_offset = (0 max (_absoluteIndex - _historyNodes)) min (_totalNodes - _pointLimit);
		};
		private _nodes = _route select [_offset, _pointLimit];
		_snapshot set [_taskForceName, [
			[_taskForce] call BATTLESPACE_PATHFIND_GET_PROFILE,
			_absoluteIndex,
			_totalNodes,
			_offset,
			_nodes
		]];
	} forEach BATTLESPACE_TASK_FORCE_PATHS;
	_snapshot
};

BATTLESPACE_TASK_FORCES_PING = {
	if (!isServer || {!isRemoteExecuted}) exitWith {};
	private _ownerId = remoteExecutedOwner;
	private _caller = (allPlayers select {owner _x == _ownerId}) param [0, objNull];
	if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {
		diag_log format ["Battlespace rejected task-force render snapshot from owner %1", _ownerId];
	};

	_ownerId publicVariableClient "BATTLESPACE_TASK_FORCES";
	_ownerId publicVariableClient "BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS";
	BATTLESPACE_TASK_FORCE_ROUTE_SNAPSHOT = [] call BATTLESPACE_TASK_FORCE_BUILD_ROUTE_SNAPSHOT;
	_ownerId publicVariableClient "BATTLESPACE_TASK_FORCE_ROUTE_SNAPSHOT";
};

BATTLESPACE_TASK_FORCES_PONG = {
	params ["_taskForces", "_bluforClusters"];

	BATTLESPACE_TASK_FORCES = _taskForces;
	BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS = _bluforClusters;
};

// Save task forces that are active
// Save task forces as is, however sanitize and remove dead units / groups accordingly.
BATTLESPACE_TASK_FORCES_SAVE = {
	params [["_flush", true]];
	private _save = createHashMap;
	private _saveData = createHashMap;
	private _invalidTaskForces = [];

	{
		_y params [
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
			["_homePoint", []] // 10
		];

		// Check if the registered model still exists and considers this force alive.
		private _model = BATTLESPACE_TASK_FORCE_MODELS get _taskForceType;
		private _isValid = !isNil "_model" && {[_x, _y] call (_model get "isAlive")};

		if(!_isValid) then {
			_invalidTaskForces pushBack [_x, _y];
			continue;
		};
		private _savedComposition = createHashMap;
		{_savedComposition set [_x, if (_y isEqualType []) then {+_y} else {_y}]} forEach _composition;
		private _savedVehicles = _savedComposition getOrDefault ["vehicles", []];
		private _savedStructures = _savedComposition getOrDefault ["structures", []];
		{
			if (isNull _x || {_x isKindOf "Man"} || {!(_x getVariable ["KPLIB_captured", false])}) then {continue};
			private _capturedObject = _x;
			private _vehicleIndex = _savedVehicles find (typeOf _capturedObject);
			if (_vehicleIndex >= 0) then {
				_savedVehicles deleteAt _vehicleIndex;
			} else {
				private _structureIndex = _savedStructures findIf {
					(_x getOrDefault ["className", ""]) == typeOf _capturedObject
					&& {(_x getOrDefault ["position", []]) distance2D (getPos _capturedObject) <= 1}
				};
				if (_structureIndex >= 0) then {_savedStructures deleteAt _structureIndex};
			};
		} forEach _activeObjects;
		_savedComposition set ["vehicles", _savedVehicles];
		_savedComposition set ["structures", _savedStructures];

		_saveData set [_x, [
			_taskForceType,
			_currentLoc,
			_destination,
			_savedComposition,
			_homePoint,
			toUpper str _taskForceSide,
			_y param [12, ""]
		]];

	} forEach BATTLESPACE_TASK_FORCES;

	{
		_x params ["_taskForceName", "_taskForce"];
		BATTLESPACE_TASK_FORCES deleteAt _taskForceName;
		[_taskForceName] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
		["BATTLESPACE/TASKFORCES/DESTROYED", [_taskForceName, _taskForce]] call CBA_fnc_serverEvent;
	} forEach _invalidTaskForces;

	_save set ["TaskForces", _saveData];
	_save set ["AI", BATTLESPACE_TASK_FORCE_AUTOINCREMENT];

	profileNamespace setVariable [BATTLESPACE_TASK_FORCE_SAVE_KEY, _save];
	if (_flush) then {saveProfileNamespace};
};

// Used for testing, spawns two basic patrols at the specified point
BATTLESPACE_TASK_FORCES_SEED = {
	{
		for "_i" from 1 to 2 do {
			private _pos = getMarkerPos _x;
			_pos set [2, 0]; 
			private _comp = createHashMap; 
			_comp set ["manpower", BATTLESPACE_SQUAD_SIZE];
			_comp set ["vehicles", []]; 

			private _spos = _pos getPos [random 1000, random 360];
			["Patrol",_comp, _spos ,_spos, _pos] call BATTLESPACE_TASK_FORCES_INIT; 
		};

	} forEach sectors_allSectors;
};

BATTLESPACE_TASK_FORCES_INIT = {
	params ["_type", "_composition", "_originPoint", ["_initialTargetLocation", []], ["_homePoint", []], ["_side", GRLIB_side_enemy]];
	if (!isServer) exitWith { "" };
	if !(_type in BATTLESPACE_TASK_FORCE_MODELS) exitWith {
		diag_log format ["Battlespace rejected unregistered task-force model %1", _type];
		""
	};
	if (typeName _composition != "HASHMAP") exitWith {
		diag_log "Battlespace rejected task force with non-hashmap composition";
		""
	};
	if (
		!(_originPoint isEqualType [])
		|| {!((count _originPoint) in [2, 3])}
		|| {_originPoint findIf {!(_x isEqualType 0)} >= 0}
	) exitWith {
		diag_log format ["Battlespace rejected task force %1 with invalid origin %2", _type, _originPoint];
		""
	};

	diag_log format ["Initialize Task Force (%1) at %2", _type, _originPoint];
	private _taskForceName = str BATTLESPACE_TASK_FORCE_AUTOINCREMENT;

	BATTLESPACE_TASK_FORCE_AUTOINCREMENT = BATTLESPACE_TASK_FORCE_AUTOINCREMENT + 1;

	/*
		_composition : {
			vehicles: Array of class names
			manpower: Number
			structures: [
				{
					rotation: Angle
					position: Location
					className: String
				}
			]	
		}
	*/

	private _newTaskForce = [_type, _originPoint, _initialTargetLocation, _composition, [], ["IDLE", 0, 0]];
	private _newHomePoint = _homePoint;
	if((_homePoint isEqualTo [])) then {
		_newHomePoint = _originPoint;
	};
	_newTaskForce set [6, _side];
	_newTaskForce set [10, _newHomePoint];

	BATTLESPACE_TASK_FORCES set [_taskForceName, _newTaskForce];

	publicVariable "BATTLESPACE_TASK_FORCE_AUTOINCREMENT";
	_taskForceName
};

BATTLESPACE_TASK_FORCE_PATH_FOUND = {
	params ["_taskForceName", "_path"];
	
	private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceName;
	
	if(isNil { _taskForce }) exitWith {false};
	if !([_path] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID) exitWith {
		[_taskForceName] call BATTLESPACE_TASK_FORCE_PATH_FAILED;
		false
	};

	_taskForce params [
		"_taskForceType", // 0
		"_currentLoc", // 1
		["_destination", []], // 2
		"_composition", // 3
		["_activeGroups", []], // 4
		["_state", ["IDLE", 0, 0]], // 5
		["_taskForceSide", east], // 6
		["_despawnCounter", 0], // 7
		["_activeObjects", []], // 8
		["_wasDespawning", false], // 9
		["_homePoint", []], // 10
		["_spawning", false], // 11
		["_hpSector", nil] // 12
	];
	if !(_state isEqualType []) then {_state = ["IDLE", 0, 0]};
	private _endNode = _path param [(count _path) - 1, []];
	private _normalizedDestination = [_destination] call BATTLESPACE_PATHFIND_NORMALIZE_POSITION;

	_state set [1, 0];
	_state set [2, 0];

	_taskForce set [5, _state];
	// This seems to be as a result of being stuck and no valid path can be found
	if (_normalizedDestination isEqualTo [] || {(_endNode distance2D _normalizedDestination) > 200}) exitWith {

		[_taskForceName] call BATTLESPACE_TASK_FORCE_PATH_FAILED;
		false
	};


	BATTLESPACE_TASK_FORCE_PATHS set [_taskForceName, +_path];
	[_taskForceName, _taskForce, _path] call BATTLESPACE_TASK_FORCE_APPLY_ROUTE_TO_ACTIVE;
	true
};

BATTLESPACE_TASK_FORCE_PATH_FAILED = {
	params ["_taskForceName"];

	private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceName;

	if(isNil { _taskForce }) exitWith {};

	_taskForce params [
		"_taskForceType", // 0
		"_currentLoc", // 1
		["_destination", []], // 2
		"_composition", // 3
		["_activeGroups", []], // 4
		["_state", ["IDLE", 0, 0]], // 5
		["_taskForceSide", east], // 6
		["_despawnCounter", 0], // 7
		["_activeObjects", []], // 8
		["_wasDespawning", false], // 9
		["_homePoint", []], // 10
		["_spawning", false], // 11
		["_hpSector", nil] // 12
	];

	if !(_state isEqualType []) then {_state = ["IDLE", 0, 0]};
	private _status = _state param [0, "IDLE", [""]];
	private _currentPathIndex = _state param [1, 0, [0]];
	private _failureCounts = _state param [2, 0, [0]];
	_state = [_status, _currentPathIndex, _failureCounts];

	BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
	_failureCounts = _failureCounts + 1;
	diag_log format ["Task Force %1 failed to find a path, failure count now at %2", _taskForceName, _failureCounts];

	if (_failureCounts > 10) exitWith {
		diag_log format ["Task Force %1 failed too much, removing..."];
		BATTLESPACE_TASK_FORCES deleteAt _taskForceName;
		[_taskForceName] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
	};

	if (_failureCounts > 4) then {
		diag_log format ["Task Force %1 was stuck (%2) could not reach (%3), randomizing position to unstick", _taskForceName, _currentLoc, _destination];

		private _newLoc = _currentLoc findEmptyPosition [50, _failureCounts * 25 + 25, "B_APC_Tracked_01_rcws_F"];
		if((_newLoc isEqualTo [])) then {
			_newLoc = _currentLoc getPos [random 100, random 360];
			private _execs = 0;
			while { surfaceIsWater _newLoc && _execs < 10 } do {
				_newLoc = _currentLoc getPos [random (100 + _execs * 10), random 360];
				_execs = _execs + 1;
			};
			if(_execs < 10) then {
				_taskForce set [1, _newLoc];
			};
		} else {
			_taskForce set [1, _newLoc];
		};
	};

	_state set [2, _failureCounts];

	// Find a flat pos
	private _newDestination = _destination findEmptyPosition [_failureCounts * 25, 25 + _failureCounts * 25, "B_APC_Tracked_01_rcws_F"];
	if(!(_newDestination isEqualTo [])) then {
		_taskForce set [2, _newDestination];
	} else {
		_newDestination = _destination getPos [random 100, random 360];
		private _execs = 0;
		while { surfaceIsWater _newDestination && _execs < 10 } do {
			_newDestination = _destination getPos [random (100 + _execs * 10), random 360];
			_execs = _execs + 1;
		};
		if(_execs < 10) then {
			_taskForce set [2, _newDestination];
		};
	};

	_taskForce set [5, _state];
};

BATTLESPACE_TASK_FORCES_CLUSTER_BLUFOR = {

	(_this select 0) params [
		["_nextTick", 0]
	];


	if(CBA_missionTime < _nextTick) exitWith {};
	private _clusterInterval = if (missionNamespace getVariable ["BATTLESPACE_LOS_PROC_ENABLED", false]) then {
		0.25 max (missionNamespace getVariable ["BATTLESPACE_LOS_PROC_SCAN_INTERVAL", 1])
	} else {
		10
	};
	(_this select 0) set [0, CBA_missionTime + _clusterInterval];
	BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS = [];
	

	private _remainingPlayers = +allPlayers;
	if (
		missionNamespace getVariable ["BATTLESPACE_LOS_PROC_ENABLED", false]
		&& {missionNamespace getVariable ["BATTLESPACE_LOS_PROC_INCLUDE_BLUFOR_AI", false]}
	) then {
		{
			if (!isPlayer _x && {alive _x} && {side _x == GRLIB_side_friendly}) then {
				_remainingPlayers pushBack _x;
			};
		} forEach allUnits;
	};

	_remainingPlayers = _remainingPlayers select {
		side _x == GRLIB_side_friendly
	};

	private _currentClusterPlayers = [];
	private _currentClusterAveragePosition = [];

	while { (count _remainingPlayers) > 0 } do {

		private _sourcePlayer = _remainingPlayers deleteAt 0;

		_currentClusterAveragePosition = getPos _sourcePlayer;
		_currentClusterPlayers = [_sourcePlayer];
		private _positionSum = +_currentClusterAveragePosition;
		private _clusteredIndices = [];

		// Loop through remaining players and see if we can cluster them.
		{
			private _playerPos = getPos _x;

			if((_playerPos distance2D _currentClusterAveragePosition) <= BLUFOR_CLUSTER_DISTANCE) then {
				_currentClusterPlayers pushBack _x;
				_positionSum = _positionSum vectorAdd _playerPos;
				private _count = count _currentClusterPlayers;
				_currentClusterAveragePosition = _positionSum vectorMultiply (1 / _count);
				_clusteredIndices pushBack _forEachIndex;
			};
		} forEach _remainingPlayers;

		reverse _clusteredIndices;
		{
			_remainingPlayers deleteAt _x;
		} forEach _clusteredIndices;

		BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS pushBack (createHashMapFromArray [
			["Position", _currentClusterAveragePosition],
			["Players", _currentClusterPlayers]
		]);

		_currentClusterAveragePosition = [];
	};
	
	// publicVariable "BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS";
	// diag_log format ["Blufor Clustering Process clustered %1 BLUFOR into %2 clusters", count allPlayers, count BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS];
};

BATTLESPACE_TASK_FORCES_FAST_PROC_ADMISSION = {
	if (!isServer || {!(missionNamespace getVariable ["BATTLESPACE_LOS_PROC_ENABLED", false])}) exitWith {};

	private _candidates = [];
	{
		private _taskForceName = _x;
		private _taskForce = _y;
		private _activeObjects = _taskForce param [8, []];
		private _spawning = _taskForce param [11, false];
		private _hasSpawnReservation = !isNil {BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS get _taskForceName};
		if (_spawning || {_hasSpawnReservation} || {_activeObjects isNotEqualTo []}) then {continue};

		private _model = BATTLESPACE_TASK_FORCE_MODELS get (_taskForce param [0, ""]);
		if (isNil "_model") then {continue};
		if !([_taskForceName, _taskForce] call (_model get "isAlive")) then {continue};
		if ([_taskForceName, _taskForce, _model] call BATTLESPACE_TASK_FORCE_CAN_PROC) then {
			_candidates pushBack [_taskForceName, _taskForce];
		};
	} forEach BATTLESPACE_TASK_FORCES;

	if (_candidates isEqualTo []) exitWith {};
	private _unitCount = [] call KPLIB_fnc_getOpforCap;
	private _reservationTotal = [] call BATTLESPACE_TASK_FORCE_REFRESH_SPAWN_RESERVATIONS;
	{
		_x params ["_taskForceName", "_taskForce"];
		private _admission = [
			_taskForceName,
			_taskForce,
			_unitCount,
			_reservationTotal,
			"FAST_LOS"
		] call BATTLESPACE_TASK_FORCE_TRY_ADMIT_SPAWN;
		_admission params ["_admitted", "_newReservationTotal"];
		_reservationTotal = _newReservationTotal;
		if (_admitted) then {
			_taskForce set [7, 0];
			BATTLESPACE_TASK_FORCES set [_taskForceName, _taskForce];
		};
	} forEach _candidates;
};

BATTLESPACE_TASK_FORCES_EVALUATE = {
	(_this select 0) params [
		["_nextTick", 0],
		["_tickCounter", 0],
		["_portion", 0]
	];

	if(CBA_missionTime < _nextTick) exitWith {};

	diag_log format ["Evaluating task forces at %1", CBA_missionTime];
	(_this select 0) set [0, CBA_missionTime + 10];
	
	private _startTime = diag_tickTime;
	private _unitCount = ([] call KPLIB_fnc_getOpforCap);
	private _reservationTotal = [] call BATTLESPACE_TASK_FORCE_REFRESH_SPAWN_RESERVATIONS;

	// 1. Loop through all Task Forces
	// 2. Validate task forces are still valid (the ones that are procced)
	// 3. Move simulated task forces along their routes 
	// 3a. If location reached, try to emit associated event
	// 4. Validate procced task forces are still procced, else despawn and reset them to simulated

	BATTLESPACE_AMOUNT_SKIPPED = 0;

	// 1. Loop through all Task Forces
	// 2. Validate task forces are still valid (the ones that are procced)
	// 3. Move simulated task forces along their routes 
	// 3a. If location reached, try to emit associated event
	// 4. Validate procced task forces are still procced, else despawn and reset them to simulated
	{
		private _taskForceName = _x;
		_y params [
			["_type", ""], // 0
			["_simulatedLocation", []], // 1
			["_targetLocation", []], // 2
			["_composition", createHashMap], // 3
			["_activeGroups", []], // 4
			["_state", []], // 5
			["_placeholderValue", []], // 6
			["_despawnCounter", 0], // 7
			["_activeObjects", []], // 8
			["_wasDespawning", false], // 9
			["_homePoint", []], // 10
			["_spawning", false] // 11
		];
		// Regardless of type, if something has no valid location its just not valid.
		if((isNil { _simulatedLocation }) || (_simulatedLocation isEqualTo [])) then {
			diag_log format ["Task Force %1 (%2) has invalid simulated location %3, deleting", _taskForceName, _type, _simulatedLocation];

			BATTLESPACE_TASK_FORCES deleteAt _taskForceName;
			[_taskForceName] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;

			["BATTLESPACE/TASKFORCES/DESTROYED", [_x, _y]] call CBA_fnc_serverEvent;
			continue;
		};
		private _model = BATTLESPACE_TASK_FORCE_MODELS get _type;

		if(isNil { _model }) then {
			BATTLESPACE_TASK_FORCES deleteAt _taskForceName;
			[_taskForceName] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
			continue;	
		};

		// Check if valid still
		private _isValid = [_x, _y] call (_model get "isAlive");

		if(!_isValid) then {
			BATTLESPACE_TASK_FORCES deleteAt _taskForceName;
			[_taskForceName] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;

			["BATTLESPACE/TASKFORCES/DESTROYED", [_x, _y]] call CBA_fnc_serverEvent;
			continue;
		};

		
		// Check for proccing if no active groups
		private _canProc = [_x, _y, _model] call BATTLESPACE_TASK_FORCE_CAN_PROC;
		if(_canProc) then {
			private _admission = [
				_taskForceName,
				_y,
				_unitCount,
				_reservationTotal
			] call BATTLESPACE_TASK_FORCE_TRY_ADMIT_SPAWN;
			_reservationTotal = _admission select 1;
			_y set [7, 0];
		} else {
			if(!_spawning && {count _activeObjects > 0}) then {
				// 90s
				if(_despawnCounter >= 9) then {
					diag_log format ["Task Force %1 despawning...", _taskForceName];
					_y set [9, true];
					private _vehicles = +(_composition getOrDefault ["vehicles", []]);
					private _structures = +(_composition getOrDefault ["structures", []]);
					// Captured equipment leaves this force permanently. Removing it from
					// the virtual manifest prevents it from being spawned a second time.
					{
						if (isNull _x) then { continue };
						private _activeObject = _x;
						if (!(_x isKindOf "Man") && {_x getVariable ["KPLIB_captured", false]}) then {
							private _vehicleIndex = _vehicles find (typeOf _x);
							if (_vehicleIndex >= 0) then {
								_vehicles deleteAt _vehicleIndex;
							} else {
								private _structureIndex = _structures findIf {
									(_x getOrDefault ["className", ""]) == typeOf _activeObject
								};
								if (_structureIndex >= 0) then {
									_structures deleteAt _structureIndex;
								};
							};
						} else {
							deleteVehicle _x;
						};
					} forEach _activeObjects;
					{
						if (!isNull _x) then {
							deleteGroup _x;
						};
					} forEach _activeGroups;
					_composition set ["vehicles", _vehicles];
					_composition set ["structures", _structures];
					_y set [3, _composition];
					// Reset states
					BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
					[_taskForceName] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
					_y set [8, []];
					_y set [4, []];
					_y set [7, 0];
					continue;
				};
				_y set [7, _despawnCounter + 1];
			};
		};

		// Task Force decision making (i.e. update group waypoints or update target location, etc.)
		private _done = [_x, _y] call (_model get "onDecisionTick");
		if(_done) then {
			BATTLESPACE_TASK_FORCES deleteAt _taskForceName;
			[_taskForceName] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;

			["BATTLESPACE/TASKFORCES/DONE", [_x, _y]] call CBA_fnc_serverEvent;
			continue;
		};
		BATTLESPACE_TASK_FORCES set [_x, _y];
	} forEach BATTLESPACE_TASK_FORCES;

	private _staleLoSDecisions = [];
	{
		if (isNil {BATTLESPACE_TASK_FORCES get _x}) then {
			_staleLoSDecisions pushBack _x;
		};
	} forEach BATTLESPACE_TASK_FORCE_LOS_PROC_DECISIONS;
	{
		BATTLESPACE_TASK_FORCE_LOS_PROC_DECISIONS deleteAt _x;
	} forEach _staleLoSDecisions;

	private _newTickCounter = _tickCounter + 1;
	if(_newTickCounter >= 9) then {
		_newTickCounter = 0;

		// [] call BATTLESPACE_TASK_FORCES_SAVE;
	};
	// TODO: Redo this
	// publicVariable "BATTLESPACE_TASK_FORCES";

	(_this select 0) set [1, _newTickCounter];
};

BATTLESPACE_TASK_FORCE_OBJECT_KILLED = {
	params ["_type", "_killedEvent"];
	if(!isServer) exitWith {};
	if(BATTLESPACE_DEBUG_INDEPTH) then {
		diag_log format ["Battlespace Task Force Object Killed (%1, %2)", _type, _killedEvent];
	};

	_killedEvent params ["_unit", "_killer", "_instigator", "_useEffects"];
	private _taskForceName = _unit getVariable "TASKFORCEID";
	if (isNil { _taskForceName }) exitWith {};

	private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceName;
	if (isNil { _taskForce }) exitWith {};

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
		["_homePoint", []] // 10
	];

	if(BATTLESPACE_DEBUG_INDEPTH) then {
		diag_log format ["Task Force Unit killed (%1, %2, %3)", _type, _unit, _taskForceName];
	};
	private _recordedLoss = false;
	if(_type == "STRUCTURE") then {
		private _structures = _composition getOrDefault ["structures", []];

		{
			private _loc = _x getOrDefault ["position", []];
			private _rot = _x getOrDefault ["rotation", 0];
			private _className = _x getOrDefault ["className", ""];

			if((typeOf _unit) == _className && {(getPos _unit) distance2D _loc <= 1} && {abs ((getDir _unit) - _rot) <= 1}) exitWith {
				_structures deleteAt _forEachIndex;
				_composition set ["structures", _structures];
				_taskForce set [3, _composition];
				_recordedLoss = true;
			}
		} forEach _structures;
	};

	if(_type == "VEHICLE") then {
		private _vehs = _composition getOrDefault ["vehicles", []];

		{
			if((typeOf _unit) == _x) exitWith {_vehs deleteAt _forEachIndex; _recordedLoss = true};
		} forEach _vehs;

		_composition set ["vehicles", _vehs];
	};

	if(_type == "MANPOWER") then {
		private _manpower = _composition getOrDefault ["manpower", 1];

		if (_manpower > 0) then {
			_manpower = _manpower - 1;
			_composition set ["manpower", _manpower];
			_recordedLoss = true;
		};
	};

	_taskForce set [3, _composition];
	BATTLESPACE_TASK_FORCES set [_taskForceName, _taskForce];
	if (_recordedLoss && {!isNil "BATTLESPACE_STRATEGIC_RECORD_CASUALTY"}) then {
		[_taskForceName, _type] call BATTLESPACE_STRATEGIC_RECORD_CASUALTY;
	};
	// publicVariable "BATTLESPACE_TASK_FORCES";
};

if (isServer) then {
	if(missionNamespace getVariable ["BATTLESPACE_TASK_FORCES_PERSISTENT", false]) then {
		[] call BATTLESPACE_TASK_FORCES_LOAD;
	};
	[] spawn {
		if (missionNamespace getVariable ["BATTLESPACE_TASK_FORCES_PERSISTENT", false]) then {
			waitUntil {sleep 0.25; missionNamespace getVariable ["BATTLESPACE_LOGISTICS_READY", false]};
		};
		private _state = [[], 0];

		private _clusteringState = [[], 1];
		while { true } do {
			_clusteringState call BATTLESPACE_TASK_FORCES_CLUSTER_BLUFOR;
			[] call BATTLESPACE_TASK_FORCES_FAST_PROC_ADMISSION;
			_state call BATTLESPACE_TASK_FORCES_EVALUATE;
			[] call BATTLESPACE_TASK_FORCE_PROCESS_SPAWN_QUEUE;
			sleep 1;
		};
	};

};

BATTLESPACE_TASK_FORCE_ROUTE_LABEL = {
	params ["_routeData"];
	if !(_routeData isEqualType [] && {count _routeData >= 5}) exitWith {"ROUTE PENDING"};
	_routeData params ["_profile", "_absoluteIndex", "_totalNodes", "_offset", "_nodes"];
	if !([_nodes] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID) exitWith {"ROUTE INVALID"};
	format [
		"%1 ROUTE %2/%3%4",
		_profile,
		(1 + _absoluteIndex) min _totalNodes,
		_totalNodes,
		["", " (CLIPPED)"] select (_totalNodes > count _nodes)
	]
};

BATTLESPACE_TASK_FORCE_DRAW_ROUTE_3D = {
	params ["_currentPosition", "_routeData", ["_baseColor", [1, 0.75, 0.1, 0.85]]];
	if !(_routeData isEqualType [] && {count _routeData >= 5}) exitWith {false};
	_routeData params ["_profile", "_absoluteIndex", "_totalNodes", "_offset", "_nodes"];
	if !(
		_absoluteIndex isEqualType 0
		&& {_totalNodes isEqualType 0}
		&& {_offset isEqualType 0}
		&& {[_nodes] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID}
	) exitWith {false};

	private _toVisualPosition = {
		params ["_position"];
		private _visual = +_position;
		if (count _visual == 2) then {_visual pushBack 0};
		_visual set [2, 7];
		_visual
	};
	private _futureColor = [
		_baseColor param [0, 1],
		_baseColor param [1, 0.75],
		_baseColor param [2, 0.1],
		_baseColor param [3, 0.85]
	];
	private _traversedColor = [
		(_futureColor select 0) * 0.4,
		(_futureColor select 1) * 0.4,
		(_futureColor select 2) * 0.4,
		0.3
	];

	if (count _nodes > 1) then {
		for "_i" from 0 to (count _nodes - 2) do {
			private _segmentEndIndex = _offset + _i + 1;
			private _segmentColor = [_futureColor, _traversedColor] select (_segmentEndIndex < _absoluteIndex);
			drawLine3D [
				[(_nodes select _i)] call _toVisualPosition,
				[(_nodes select (_i + 1))] call _toVisualPosition,
				_segmentColor
			];
		};
	};

	private _localIndex = _absoluteIndex - _offset;
	if (
		_localIndex >= 0
		&& {_localIndex < count _nodes}
		&& {([_currentPosition] call BATTLESPACE_PATHFIND_NORMALIZE_POSITION) isNotEqualTo []}
	) then {
		drawLine3D [
			[_currentPosition] call _toVisualPosition,
			[(_nodes select _localIndex)] call _toVisualPosition,
			[1, 1, 0.2, 1]
		];
	};

	private _nodeStride = 1 max ceil ((count _nodes) / 64);
	{
		if ((_forEachIndex mod _nodeStride) == 0 || {_forEachIndex == _localIndex} || {_forEachIndex == count _nodes - 1}) then {
			private _nodeColor = [[0.95, 0.95, 0.95, 0.65], [1, 1, 0.2, 1]] select (_forEachIndex == _localIndex);
			drawIcon3D ["\A3\ui_f\data\map\markers\military\dot_CA.paa", _nodeColor, [_x] call _toVisualPosition, 0.22, 0.22, 0, "", 0, 0.02, "TahomaB"];
		};
	} forEach _nodes;
	true
};

RENDER_BATTLESPACE_AI = false;
RENDER_BATTLESPACE_AI_PFH_ID = -1;
RENDER_BATTLESPACE_LOS_PROC = false;

BATTLESPACE_TASK_FORCE_DRAW_LOS_PROC_DEBUG = {
	params ["_taskForceName", "_taskForce"];
	if !(missionNamespace getVariable ["BATTLESPACE_LOS_PROC_ENABLED", false]) exitWith {
		private _position = +(_taskForce param [1, []]);
		if (count _position == 2) then {_position pushBack 0};
		_position set [2, (_position param [2, 0]) + 12];
		drawIcon3D [
			"\A3\ui_f\data\map\groupicons\selector_selectedEnemy_ca.paa",
			[1, 0.65, 0.1, 1],
			_position,
			0.8,
			0.8,
			0,
			"LOS PROC PROTOTYPE DISABLED",
			1,
			0.03,
			"TahomaB"
		];
	};

	private _cache = uiNamespace getVariable ["BATTLESPACE_ZEN_LOS_PROC_DEBUG_CACHE", ["", 0, false, []]];
	_cache params ["_cachedTaskForceName", "_nextProbe", "_broadPhase", "_probe"];
	if (_cachedTaskForceName != _taskForceName || {diag_tickTime >= _nextProbe}) then {
		private _model = BATTLESPACE_TASK_FORCE_MODELS get (_taskForce param [0, ""]);
		_broadPhase = !isNil "_model" && {[_taskForceName, _taskForce] call (_model get "canProc")};
		private _eligibleObservers = if (_broadPhase) then {
			[_taskForce] call BATTLESPACE_TASK_FORCE_GET_LOS_PROC_OBSERVERS
		} else {
			[]
		};
		_probe = [_taskForce, _eligibleObservers] call BATTLESPACE_TASK_FORCE_PROBE_LOS;
		if (!_broadPhase) then {
			_probe set [0, false];
			_probe set [1, "BROAD_PHASE"];
		};
		uiNamespace setVariable ["BATTLESPACE_ZEN_LOS_PROC_DEBUG_CACHE", [_taskForceName, diag_tickTime + 0.1, _broadPhase, _probe]];
	};

	_probe params ["_allowed", "_reason", "_nearestDistance", "_targetPositionsASL", "_rayRequests", "_intersections", "_observers"];
	if (_targetPositionsASL isEqualTo []) exitWith {};
	private _targetPositionAGL = ASLToAGL (_targetPositionsASL select 0);
	private _resultColor = switch (_reason) do {
		case "LINE_OF_SIGHT": {[0.1, 1, 0.2, 1]};
		case "CLOSE_RANGE": {[0.1, 0.8, 1, 1]};
		case "OCCLUDED": {[1, 0.15, 0.1, 1]};
		default {[0.65, 0.65, 0.65, 1]};
	};
	{
		drawIcon3D [
			"\A3\ui_f\data\map\markers\military\dot_CA.paa",
			_resultColor,
			ASLToAGL _x,
			0.24,
			0.24,
			0,
			"",
			0,
			0.02,
			"TahomaB"
		];
	} forEach _targetPositionsASL;

	if (_reason == "CLOSE_RANGE") then {
		{
			drawLine3D [ASLToAGL (eyePos _x), _targetPositionAGL, [0.1, 0.8, 1, 0.75], 2];
		} forEach _observers;
	} else {
		{
			private _request = _x;
			private _startPositionAGL = ASLToAGL (_request select 0);
			private _rayTargetPositionAGL = ASLToAGL (_request select 1);
			private _hits = _intersections param [_forEachIndex, []];
			if (_hits isEqualTo []) then {
				drawLine3D [_startPositionAGL, _rayTargetPositionAGL, [0.1, 1, 0.2, 0.9], 2];
			} else {
				private _firstIntersection = _hits select 0;
				private _intersectionPositionAGL = ASLToAGL (_firstIntersection select 0);
				drawLine3D [_startPositionAGL, _intersectionPositionAGL, [1, 0.1, 0.05, 0.95], 3];
				drawLine3D [_intersectionPositionAGL, _rayTargetPositionAGL, [1, 0.1, 0.05, 0.25], 1];
				drawIcon3D [
					"\A3\ui_f\data\map\markers\military\dot_CA.paa",
					[1, 0.1, 0.05, 1],
					_intersectionPositionAGL,
					0.3,
					0.3,
					0,
					"",
					0,
					0.02,
					"TahomaB"
				];
			};
		} forEach _rayRequests;
	};

	private _nearestText = if (_nearestDistance < 0) then {"N/A"} else {format ["%1m", round _nearestDistance]};
	private _decisionText = ["BLOCK", "ALLOW"] select _allowed;
	private _forceText = format ["%1 %2", _taskForce param [0, ""], _taskForceName];
	private _serverCheckInterval = missionNamespace getVariable ["BATTLESPACE_LOS_PROC_SCAN_INTERVAL", 1];
	private _label = format [
		"LOS PROC LIVE | %1 | %2/%3 | BROAD %4 | OBS %5 | SAMPLES %6 | RAYS %7 | NEAREST %8 | SERVER CHECK <=%9s",
		_forceText,
		_decisionText,
		_reason,
		["NO", "YES"] select _broadPhase,
		count _observers,
		count _targetPositionsASL,
		count _rayRequests,
		_nearestText,
		_serverCheckInterval
	];
	drawIcon3D [
		"\A3\ui_f\data\map\groupicons\selector_selectedEnemy_ca.paa",
		_resultColor,
		_targetPositionAGL,
		1,
		1,
		0,
		_label,
		1,
		0.03,
		"TahomaB"
	];
};

RENDER_BATTLESPACE_AI_PFH = {


	(_this select 0) params [["_nextTick", 0]];
	if(!RENDER_BATTLESPACE_AI) exitWith {
		[_this select 1] call CBA_fnc_removePerFrameHandler;
		RENDER_BATTLESPACE_AI_PFH_ID = -1;
	};
	if(isNull curatorCamera) exitWith {};
	if(accTime <= 0 || isGamePaused) exitWith {};

	if(CBA_missionTime > _nextTick) then {
		[] remoteExec ["BATTLESPACE_TASK_FORCES_PING", 2];
		(_this select 0) set [0, CBA_missionTime + 5];
	};

	private _mousePos = screenToWorld getMousePosition;
	private _losDebugCandidate = [];
	private _losDebugCandidateDistance = 1e10;
	{
		_y params [
			["_type", ""],
			["_simulatedLocation", []],
			["_targetLocation", []],
			["_composition", createHashMap],
			["_activeGroups", []],
			["_state", []],
			["_taskForceSide", east],
			["_despawnCounter", 0],
			["_activeObjects", []], // 8
			["_wasDespawning", false], // 9
			["_homePoint", []] // 10
		];

		private _color = [0.5, 0, 0, 1];
		switch (_taskForceSide) do {
			case GRLIB_side_friendly: { _color = [0.2, 0.2, 0.9, 1]; };
			case GRLIB_side_enemy: { _color = [0.9, 0.2, 0.2, 1]; };
			case GRLIB_side_civilian: { _color = [0.7, 0.2, 0.6, 1]; };
		};

		private _ind = _forEachIndex;
		private _targetMarker = "\A3\ui_f\data\map\markers\nato\o_inf.paa";

		_state params [["_status", "IDLE"], ["_currentPathIndex", 0]];

		private _manpower = _composition get "manpower";
		private _vehicles = _composition getOrDefault ["vehicles", []];

		private _hasMechanized = false;
		private _hasMotorized = false;
		private _hasArmor = false;
		private _hasAA = false;


		if((count _vehicles) > 0) then {
			_hasMechanized = true;
		};

		switch(true) do {
			case (_hasAA): { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_antiair.paa"; };
			case (_hasMotorized): { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_motor_inf.paa"; };
			case (_hasMechanized): { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_mech_inf.paa"; };
			case (_hasArmor): { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_armor.paa"; };
		};

		switch(_type) do {
			case "Outpost": { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_installation.paa"; };
			case "Convoy": { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_support.paa"; };
			case "Battlegroup": { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_armor.paa"; };
			case "Fortifications": { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_hq.paa"; };
			case "Ambush Patrol": { _targetMarker = "\A3\ui_f\data\map\markers\military\ambush_CA.paa"; };
			case "Minefield": { _targetMarker = "\a3\Ui_F_Curator\Data\CfgMarkers\minefield_ca.paa"; };
			case "Civilians": { _targetMarker = "\A3\ui_f\data\map\markers\nato\n_inf.paa"; };
			case "Air Response": { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_air.paa"; };
			case "Airborne Transport": { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_air.paa"; };
			case "Airborne Infantry": { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_inf.paa"; };
			case "Anti-Air": { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_antiair.paa"; };
		};

		private _pos = _simulatedLocation vectorAdd [0,0, 5 + _ind * 0];
		private _routeData = BATTLESPACE_TASK_FORCE_ROUTE_SNAPSHOT getOrDefault [_x, []];
		[_simulatedLocation, _routeData, _color] call BATTLESPACE_TASK_FORCE_DRAW_ROUTE_3D;
		private _text = "";
		private _scale = 0.5;

		private _dist = _pos distance2D _mousePos;
		if (RENDER_BATTLESPACE_LOS_PROC && {_dist <= 500} && {_dist < _losDebugCandidateDistance}) then {
			_losDebugCandidate = [_x, _y];
			_losDebugCandidateDistance = _dist;
		};
		if(_dist <= 500) then {
			_scale = 0.75 + 0.25 * ((500 - _dist) / 300);
			_scale = 1 min _scale;

			private _textScale = 0.03 * _scale;
			_text = format ["%1 %2 | MANPWR: %3 | VICS: %4 | %5", _type, _x, _manpower, count _vehicles, [_routeData] call BATTLESPACE_TASK_FORCE_ROUTE_LABEL];

			if((count _activeObjects) > 0) then {
				{
					private _gpos = getPos (leader _x);
					drawLine3D [_pos, _gpos, [0,1,0.1,1]];
				} forEach _activeGroups;

				_text = _text + format [" | PROCCED (%1)", _despawnCounter];
			};

			if(!(_targetLocation isEqualTo [])) then {
				if(_simulatedLocation distance2D _targetLocation > 25) then {
					drawIcon3D ["\A3\ui_f\data\map\groupicons\selector_selectedEnemy_ca.paa", _color, _targetLocation, 1, 1, 0, format ["%1 DESTINATION", _x], 1, _textScale, "TahomaB"];
				};
			};
		};
		drawIcon3D [_targetMarker, _color, _pos, _scale, _scale, 0, _text, 1, 0.03, "TahomaB"];
	} forEach BATTLESPACE_TASK_FORCES;
	if (_losDebugCandidate isNotEqualTo []) then {
		_losDebugCandidate call BATTLESPACE_TASK_FORCE_DRAW_LOS_PROC_DEBUG;
	};

	{
		private _cluster = _x;

		private _pos = +(_cluster get "Position");

		_pos set [2, 50];

		private _color = [0,0.4,0.8,1];
		
		private _players = _cluster get "Players";
		private _targetMarker = "\A3\ui_f\data\map\markers\nato\b_inf.paa";
		private _text = "";
		private _scale = 0.5;

		private _dist = _pos distance2D _mousePos;
		if(_dist <= 500) then {
			_scale = 0.75 + 0.25 * ((500 - _dist) / 300);
			_scale = 1 min _scale;

			private _textScale = 0.03 * _scale;
			
			{
				drawLine3D [_pos, getPos _x, [1,1,0,1]];
			} forEach _players;
			_text = format ["BLUFOR CLUSTER %1 | %2 PLAYERS", _forEachIndex + 1, count _players];
			drawLine3D [_pos, _pos vectorAdd [0, 0, -50], [1,0,0,1]];
		};

		drawIcon3D [_targetMarker, _color, _pos, _scale, _scale, 0, _text, 1, 0.03, "TahomaB"];
		
		
		
	} forEach BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS;
};

if(hasInterface) then {
	[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\zen\index.sqf";
};
