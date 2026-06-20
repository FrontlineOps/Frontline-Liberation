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
		_taskForceSide : Array of Pos from calculatePath
	]

*/

if(isNil { BATTLESPACE_TASK_FORCES }) then {
	BATTLESPACE_TASK_FORCES = createHashMap;
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
BATTLESPACE_TASK_FORCE_MINIMUM_SIZE = 4;
// Enable some more verbose diag logs and stuff.
BATTLESPACE_DEBUG_INDEPTH = false;

BATTLESPACE_TASK_FORCE_SAVE_KEY = format ["BATTLESPACE_TASK_FORCES_%1", toUpper worldName];

BATTLESPACE_TASK_FORCE_REGISTER_MODEL = {
	params ["_modelName", "_modelDefinition"];

	BATTLESPACE_TASK_FORCE_MODELS set [_modelName, _modelDefinition];
};

[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\models\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\pathfinder.sqf";
BATTLESPACE_TASK_FORCES_LOAD = {
	diag_log format ["Battlespace Task Forces Loading..."];
	private _save = profileNamespace getVariable BATTLESPACE_TASK_FORCE_SAVE_KEY;

	private _saveValid = !isNil "_save" && !isNil { _save get "AI" } && !isNil { _save get "TaskForces" };

	if(_saveValid) then {
		diag_log format ["  Save valid"];
		// Loop through and init
		BATTLESPACE_TASK_FORCE_AUTOINCREMENT = _save get "AI";
		_savedForces = _save get "TaskForces";

		{
			_y params ["_type", "_currentLoc", "_destination", "_composition", "_homePoint"];
			private _savedTaskForce = [
				_type,
				_currentLoc,
				_destination,
				_composition,
				[],
				["IDLE"],
				[]
			];

			_savedTaskForce set [10, _homePoint];
			BATTLESPACE_TASK_FORCES set [_x, _savedTaskForce];
		} forEach _savedForces;

		diag_log format ["  Loaded AI %1 | # of Task Forces: %2", BATTLESPACE_TASK_FORCE_AUTOINCREMENT, count BATTLESPACE_TASK_FORCES];

		// publicVariable "BATTLESPACE_TASK_FORCES";
		publicVariable "BATTLESPACE_TASK_FORCE_AUTOINCREMENT";
	};
	
};

BATTLESPACE_TASK_FORCES_PING = {


	remoteExecutedOwner publicVariableClient "BATTLESPACE_TASK_FORCES";
	remoteExecutedOwner publicVariableClient "BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS";

	
};

BATTLESPACE_TASK_FORCES_PONG = {
	params ["_taskForces", "_bluforClusters"];

	BATTLESPACE_TASK_FORCES = _taskForces;
	BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS = _bluforClusters;
};

// Save task forces that are active
// Save task forces as is, however sanitize and remove dead units / groups accordingly.
BATTLESPACE_TASK_FORCES_SAVE = {
	private _save = createHashMap;
	private _saveData = createHashMap;

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

		// Check if valid still
		private _isValid = [_x, _y] call (_model get "isAlive");

		if(!_isValid) then {
			BATTLESPACE_TASK_FORCES deleteAt _taskForceName;
			["BATTLESPACE/TASKFORCES/DESTROYED", [_x, _y]] call CBA_fnc_serverEvent;
			continue;
		};

		_saveData set [_x, [_taskForceType, _currentLoc, _destination, _composition, _homePoint]];

	} forEach BATTLESPACE_TASK_FORCES;

	_save set ["TaskForces", _saveData];
	_save set ["AI", BATTLESPACE_TASK_FORCE_AUTOINCREMENT];

	profileNamespace setVariable [BATTLESPACE_TASK_FORCE_SAVE_KEY, _save];
	saveProfileNamespace;
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

	if (typename _composition != "HASHMAP") exitWith {
		diag_log format ["  _composition is not a hashmap..."];
	};

	private _manpower = _composition get "manpower";

	private _newTaskForce = [_type, _originPoint, _initialTargetLocation, _composition];
	private _newHomePoint = _homePoint;
	if((_homePoint isEqualTo [])) then {
		_newHomePoint = _originPoint;
	};
	_newTaskForce set [6, _side];
	_newTaskForce set [10, _newHomePoint];

	BATTLESPACE_TASK_FORCES set [_taskForceName, _newTaskForce];

	publicVariable "BATTLESPACE_TASK_FORCE_AUTOINCREMENT";
};

BATTLESPACE_TASK_FORCE_PATH_FOUND = {
	params ["_taskForceName", "_path"];
	
	private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceName;
	
	if(isNil { _taskForce }) exitWith {};

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
	private _endNode = _path select ((count _path) - 1);

	_state set [2, 0];

	_taskForce set [5, _state];
	// This seems to be as a result of being stuck and no valid path can be found
	if((_endNode distance2D _destination) > 200) exitWith {

		[_taskForceName] call BATTLESPACE_TASK_FORCE_PATH_FAILED;
	};


	BATTLESPACE_TASK_FORCE_PATHS set [_taskForceName, _path];
	// _taskForce set [6, _path];
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
		["_state", []], // 5
		["_taskForceSide", east], // 6
		["_despawnCounter", 0], // 7
		["_activeObjects", []], // 8
		["_wasDespawning", false], // 9
		["_homePoint", []], // 10
		["_spawning", false], // 11
		["_hpSector", nil] // 12
	];

	_state params ["_status", ["_currentPathIndex", 0], ["_failureCounts", 0]];

	_failureCounts = _failureCounts + 1;
	diag_log format ["Task Force %1 failed to find a path, failure count now at %2", _taskForceName, _failureCounts];

	if (_failureCounts > 10) exitWith {
		diag_log format ["Task Force %1 failed too much, removing..."];
		BATTLESPACE_TASK_FORCES deleteAt _taskForceName;
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
			_taskForce set [1, _newDestination];
		};
	};

	_taskForce set [5, _state];
};

BATTLESPACE_TASK_FORCES_CLUSTER_BLUFOR = {

	(_this select 0) params [
		["_nextTick", 0]
	];


	if(CBA_missionTime < _nextTick) exitWith {};
	// Update clusters every 10s for now.
	(_this select 0) set [0, CBA_missionTime + 10];
	BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS = [];
	

	private _remainingPlayers = allPlayers - entities "HeadlessClient_F";

	_remainingPlayers = _remainingPlayers select {
		side _x == GRLIB_side_friendly
	};

	private _currentClusterPlayers = [];
	private _currentClusterAveragePosition = [];

	while { (count _remainingPlayers) > 0 } do {

		private _sourcePlayer = _remainingPlayers#0;
		_remainingPlayers = _remainingPlayers - [_sourcePlayer];

		_currentClusterAveragePosition = getPos _sourcePlayer;
		_currentClusterPlayers = [_sourcePlayer];

		// Loop through remaining players and see if we can cluster them.
		{
			private _playerPos = getPos _x;

			if((_playerPos distance2D _currentClusterAveragePosition) <= BLUFOR_CLUSTER_DISTANCE) then {
			
				_currentClusterPlayers pushBack _x;

				

				private _xComp = 0;
				private _yComp = 0;
				private _zComp = 0;
				{
					private _pPos = getPos _x;

					_xComp = _xComp + (_pPos#0);
					_yComp = _yComp + (_pPos#1);
					_zComp = _zComp + (_pPos#2);
				} forEach _currentClusterPlayers;

				
				private _count = count _currentClusterPlayers;
				_currentClusterAveragePosition = [_xComp / _count, _yComp / _count, _zComp / _count];
			};
		} forEach _remainingPlayers;
		
		_remainingPlayers = _remainingPlayers - _currentClusterPlayers;

		BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS pushBack (createHashMapFromArray [
			["Position", _currentClusterAveragePosition],
			["Players", _currentClusterPlayers]
		]);

		_currentClusterAveragePosition = [];


	};


	if(!(_currentClusterAveragePosition isEqualTo [])) then {
		BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS pushBack (createHashMapFromArray [
			["Position", _currentClusterAveragePosition],
			["Players", _currentClusterPlayers]
		]);
	};
	
	// publicVariable "BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS";
	// diag_log format ["Blufor Clustering Process clustered %1 BLUFOR into %2 clusters", count allPlayers, count BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS];
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

	// 1. Loop through all Task Forces
	// 2. Validate task forces are still valid (the ones that are procced)
	// 3. Move simulated task forces along their routes 
	// 3a. If location reached, try to emit associated event
	// 4. Validate procced task forces are still procced, else despawn and reset them to simulated

	BATTLESPACE_AMOUNT_SKIPPED = 0;

	private _startTime = diag_tickTime;

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
			["_homePoint", []] // 10
		];
		// Regardless of type, if something has no valid location its just not valid.
		if((isNil { _simulatedLocation }) || (_simulatedLocation isEqualTo [])) then {
			diag_log format ["Task Force %1 (%2) has invalid simulated location %3, deleting", _taskForceName, _type, _simulatedLocation];

			BATTLESPACE_TASK_FORCES deleteAt _taskForceName;

			["BATTLESPACE/TASKFORCES/DESTROYED", [_x, _y]] call CBA_fnc_serverEvent;
			continue;
		};
		private _model = BATTLESPACE_TASK_FORCE_MODELS get _type;

		if(isNil { _model }) then {
			BATTLESPACE_TASK_FORCES deleteAt _taskForceName;
			continue;	
		};

		// Check if valid still
		private _isValid = [_x, _y] call (_model get "isAlive");

		if(!_isValid) then {
			BATTLESPACE_TASK_FORCES deleteAt _taskForceName;

			["BATTLESPACE/TASKFORCES/DESTROYED", [_x, _y]] call CBA_fnc_serverEvent;
			continue;
		};

		
		// Check for proccing if no active groups
		private _canProc = [_x, _y] call (_model get "canProc");
		if(_canProc) then {
			// Ensure units are below cap to preserve server health, groups may spawn in later once other opfor cleared
			if(_unitCount <= BATTLESPACE_UNIT_CAP && count _activeObjects <= 0) then {
				_y set [9, false];
				[_x, _y] call (_model get "doSpawn");

				private _objsSpawned = 0;
				{
					_objsSpawned = _objsSpawned + (count (units _x));
				} forEach (_y select 4);
				_unitCount = _unitCount + _objsSpawned;
			};
			_y set [7, 0];
		} else {
			if(count _activeObjects > 0) then {
				// 90s
				if(_despawnCounter >= 9) then {
					diag_log format ["Task Force %1 despawning...", _taskForceName];
					_y set [9, true];
					// Just delete everything, simple as that.
					// Active Objects contain every object spawned
					{
						if(!(isNull _x)) then {
							deleteVehicle _x;
						};
					} forEach _activeObjects;
					// Reset states
					BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
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

			["BATTLESPACE/TASKFORCES/DONE", [_x, _y]] call CBA_fnc_serverEvent;
			continue;
		};
		BATTLESPACE_TASK_FORCES set [_x, _y];
	} forEach BATTLESPACE_TASK_FORCES;

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
	if(_type == "STRUCTURE") then {
		private _structures = _composition getOrDefault ["structures", []];

		{
			private _loc = _y get "location";
			private _rot = _y get "rotation";
			private _className = _y get "className";

			if((typeOf _unit) == _className && ((getPos _unit) isEqualTo _loc) && ((getDir _unit) isEqualTo _rot)) exitWith {
				_structures deleteAt _forEachIndex;
				_composition set ["structures", _structures];
				_taskForce set [3, _composition];
			}
		} forEach _structures;
	};

	if(_type == "VEHICLE") then {
		private _vehs = _composition getOrDefault ["vehicles", []];

		{
			if((typeOf _unit) == _x) exitWith { _vehs deleteAt _forEachIndex };
		} forEach _vehs;

		_composition set ["vehicles", _vehs];
	};

	if(_type == "MANPOWER") then {
		private _manpower = _composition getOrDefault ["manpower", 1];

		_manpower = _manpower - 1;
		_composition set ["manpower", _manpower];
	};

	_taskForce set [3, _composition];
	BATTLESPACE_TASK_FORCES set [_taskForceName, _taskForce];
	// publicVariable "BATTLESPACE_TASK_FORCES";
};

if (isServer) then {
	if(!(isNil { BATTLESPACE_TASK_FORCES_PERSISTENT })) then {
		[] call BATTLESPACE_TASK_FORCES_LOAD;
	};
	[] spawn {
		private _state = [[], 0];

		private _clusteringState = [[], 1];
		while { true } do {
			_state call BATTLESPACE_TASK_FORCES_EVALUATE;
			_clusteringState call BATTLESPACE_TASK_FORCES_CLUSTER_BLUFOR;
			sleep 0.5;
		};
	};

};

RENDER_BATTLESPACE_AI = false;
RENDER_BATTLESPACE_AI_PFH = {


	(_this select 0) params [["_nextTick", 0]];
	if(isNull curatorCamera) exitWith {};
	if(accTime <= 0 || isGamePaused) exitWith {};

	if(CBA_missionTime > _nextTick) then {
		[] remoteExec ["BATTLESPACE_TASK_FORCES_PING", 2];
		(_this select 0) set [0, CBA_missionTime + 5];
	};

	if(!RENDER_BATTLESPACE_AI) exitWith { [_this select 1] call CBA_fnc_removePerFrameHandler; };

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
			case "Rotary Patrol": { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_air.paa"; };
			case "Anti-Air": { _targetMarker = "\A3\ui_f\data\map\markers\nato\o_antiair.paa"; };
		};

		private _pos = _simulatedLocation vectorAdd [0,0, 5 + _ind * 0];
		private _text = "";
		private _mousePos = screenToWorld getMousePosition;
		private _scale = 0.5;

		private _dist = _pos distance2D _mousePos;
		if(_dist <= 500) then {
			_scale = 0.75 + 0.25 * ((500 - _dist) / 300);
			_scale = 1 min _scale;

			private _textScale = 0.03 * _scale;
			_text = format ["%1 %2 | MANPWR: %3 | VICS: %4", _type, _x, _manpower, count _vehicles, _currentPathIndex];

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
					
					drawLine3D [_pos, _targetLocation, [1,1,0,1]];
				};
			};
		};
		drawIcon3D [_targetMarker, _color, _pos, _scale, _scale, 0, _text, 1, 0.03, "TahomaB"];
	} forEach BATTLESPACE_TASK_FORCES;

	{
		private _cluster = _x;

		private _pos = +(_cluster get "Position");

		_pos set [2, 50];

		private _color = [0,0.4,0.8,1];
		
		private _players = _cluster get "Players";
		private _targetMarker = "\A3\ui_f\data\map\markers\nato\b_inf.paa";
		private _text = "";
		private _mousePos = screenToWorld getMousePosition;
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
