// Emplacements, Roadblocks, Sandbags, etc..

[
	"Anti-Air",
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
						private _success = [_taskForceName, _taskForce, true, false, false, false, "LIMITED", [opfor_aa]] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;
						
						(BATTLESPACE_TASK_FORCES get _taskForceName) set [11, false];
						if(_success) then {

							private _grp = createGroup [_taskForce select 6, true];

							(_taskForce select 8) joinSilent _grp;

							// (BATTLESPACE_TASK_FORCES get _taskForceName) set [6, []];
							BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
						};
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

				if(isNil { _hpSector }) then {
					_hpSector = [sectors_allSectors, _homePoint] call BIS_fnc_nearestPosition;

					_taskForce set [12, _hpSector];
				};
				
				// Validate active groups
				if(count _activeGroups > 0) then {
					private _invalids = [];
					{
						private _aliveUnits = (units _x) select { alive _x };

						
			
						if(count _aliveUnits <= 0) then {
							_invalids pushBack _x;
						};
					} forEach _activeGroups;

					_taskForce set [4, _activeGroups - _invalids];
				};

				private _alive = true;

				if(count _activeObjects <= 0) then {
					private _currentManpower = _composition getOrDefault ["manpower", 0];
					private _currentVehicles = _composition getOrDefault ["vehicles", []];
					// For the sake of performance and etc.. need a minimal amount to continue to save / be valid.
					if((count _currentVehicles) <= 0) then {
						_alive = false;
					};
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

				_state params ["_status", ["_currentPathIndex", 0]];


				// If group is active don't do anything
				if(count _activeGroups > 0) exitWith {

					
					_taskForce set [1, getPos (leader (_activeGroups#0))];
					false
				};
			
				

				
				false
			}
		]
	]

] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;