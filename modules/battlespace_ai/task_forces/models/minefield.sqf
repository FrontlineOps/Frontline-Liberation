// Emplacements, Roadblocks, Sandbags, etc..

[
	"Minefield",
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
						private _success = [_taskForceName, _taskForce, true] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;

						
						(BATTLESPACE_TASK_FORCES get _taskForceName) set [11, false];
						if(_success) then {
							// (BATTLESPACE_TASK_FORCES get _taskForceName) set [6, []];
							BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;

							private _activeObjs = _taskForce select 8;

					
							{
								GRLIB_side_enemy revealMine _x;
							} forEach _activeObjs;
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
				// Only dies when the sector it belongs to is blufor controlled
				private _closestSector = _hpSector;

				private _structures = _composition getOrDefault ["structures", []];

				
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
					if((count _structures) <= 0) then {
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
				private _noExists = [];
				{
					if(isNull _x) then {
						_noExists pushBack _forEachIndex;
						continue;
					};
					GRLIB_side_enemy revealMine _x;
				} forEach _activeObjects;

				if((count _noExists) > 0) then {
					private _offset = 0;

					private _compositionStructs = _composition get "structures";
					{
						systemChat format ["Deleting mine at %1 | %2", _x, _offset];
						_compositionStructs deleteAt (_x - _offset);
						_offset = _offset + 1;
					} forEach _noExists; 
					
					

					_taskForce set [3, _composition];
					_taskForce set [8, _activeObjects - [objNull]];
				};


				
			
				

				
				false
			}
		]
	]

] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;