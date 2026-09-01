

[
	"Civilians",
	createHashMapFromArray [
		[
			"canProc",
			{
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

				private _meetsReq = false;
				private _req = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
				private _procRange = [_taskForceType] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
				{
					private _pos = _x get "Position";
					private _players = _x get "Players";

					if((count _players) < _req) then {
						continue;
					};
					

					if((_pos distance2D _currentLoc) <= _procRange) exitWith {
						_meetsReq = true;
						true
					};
					
				} forEach BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS;
				
	
				_meetsReq
			}
		],
		[
			"doSpawn",
			{
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

				if(!_spawning) then {
					_taskForce set [11, true];
					[_taskForceName, _taskForce] spawn {
						params ["_taskForceName", "_taskForce"];
						private _success = [_taskForceName, _taskForce, false, true, false, true] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;

						
						[_taskForceName, _taskForce, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN;
						//publicVariable "BATTLESPACE_TASK_FORCES";
						
					};
				};
				
			}	
		],
		[
			"isAlive",
			{
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
				
				_activeGroups = _activeGroups select {
					!isNull _x && {(units _x) findIf {alive _x} >= 0}
				};
				_activeObjects = _activeObjects select {
					!isNull _x && {alive _x}
				};
				_taskForce set [4, _activeGroups];
				_taskForce set [8, _activeObjects];

				private _currentManpower = _composition getOrDefault ["manpower", 0];
				private _alive = _currentManpower > 0 || {_activeObjects isNotEqualTo []};
				if (!_alive) then {
					diag_log format [
						"[BATTLESPACE][CIVILIANS] Retiring zero strength task force %1",
						_taskForceName
					];
				};
				_alive
			}
		],
		[
			"onDecisionTick",
			{
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
				

				// Distance check to destination

				if((_currentLoc distance2D _destination) <= 25) exitWith {
					// Generate a new location to pathfind towards
					
					if(!(isNil { _homePoint })) then {

						if(isNil { _hpSector }) then {
							_hpSector = [sectors_allSectors, _homePoint] call BIS_fnc_nearestPosition;

							_taskForce set [12, _hpSector];
						};

					private _sector =  _hpSector;
						

						

					

						private _newDestination = _homePoint getPos [random 200, random 360];
						private _execs = 0;
						while { surfaceIsWater _newDestination && _execs < 5 } do {
							
							_newDestination = _homePoint getPos [random 200, random 360];
							_execs = _execs + 1;
						};
						if(!(surfaceIsWater _newDestination)) then {
							_taskForce set [2, _newDestination];
							BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
							[_taskForceName, _currentLoc, _newDestination] call QUEUE_PATHFIND_REQUEST;
						};
					};

					false
				};
				
				// If group is active don't do anything
				if(count _activeGroups > 0) exitWith {

					
					_taskForce set [1, getPos (leader (_activeGroups#0))];
					false
				};
				
				// Else
				// Navigate terrain

				[_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;

				_taskForce set [4, _activeGroups];
				

				
				false
			}
		]
	]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
