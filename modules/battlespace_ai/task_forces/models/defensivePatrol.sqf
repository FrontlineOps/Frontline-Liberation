

[
	"Defensive Patrol",
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
						private _success = [_taskForceName, _taskForce, false, false] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;

						
						(BATTLESPACE_TASK_FORCES get _taskForceName) set [11, false];
						if(_success) then {
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

				private _currentManpower = _composition getOrDefault ["manpower", 0];
				// For the sake of performance and etc.. need a minimal amount to continue to save / be valid.
				if(_currentManpower < BATTLESPACE_TASK_FORCE_MINIMUM_SIZE) then {
					_alive = false;
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

				// Distance check to destination

				if((_currentLoc distance2D _destination) <= 25) exitWith {
					// Generate a new location to pathfind towards
					
					if(!(isNil { _homePoint })) then {
						if(isNil { _hpSector }) then {
							_hpSector = [sectors_allSectors, _homePoint] call BIS_fnc_nearestPosition;

							_taskForce set [12, _hpSector];
						};

						private _sector = _hpSector;
						private _closestBluforSector = [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_traverseGraphAndFindFirstBluforSector;
						// Fallback, not sure what will happen
						// TODO: Refactor and make this better and randomized direction
						if(isNil { _closestBluforSector }) then {
							_closestBluforSector = _sector;
						};
						private _maximumRange = (getMarkerPos _sector) distance2D (getMarkerPos _closestBluforSector);

						_maximumRange = _maximumRange * 0.75;
						_maximumRange = 500 max _maximumRange;
						_maximumRange = 1000 min _maximumRange;

						private _pos = (getMarkerPos _sector);

						private _dirToBlufor = _pos getDir (getMarkerPos _closestBluforSector);
						if(_closestBluforSector == _sector) then {
							_dirToBlufor = [random 1, random 1, 0];
						};

						private _dir = (_dirToBlufor - 110);
						if(_dir < 0) then {
							_dir = 360 + _dir;
						};

						_dir = _dir + (random 220);
						if(_dir > 360) then {
							_dir = _dir - 360;
						};

						private _minRange = _maximumRange / 2;
						private _step = _minRange / 50;

						private _newDestination = _pos getPos [_minRange + (random (_minRange * 0.9)), _dir];
						private _execs = 0;
						while { surfaceIsWater _newDestination && _execs < 5 } do {
							_dir = (_dirToBlufor - 110);

							if(_dir < 0) then {
								_dir = 360 + _dir;
							};

							_dir = _dir + (random 220);

							if(_dir > 360) then {
								_dir = _dir - 360;
							};
							_newDestination = _pos getPos [_minRange - (_execs * _step) + (random (_minRange * 0.9)), _dir];
							_execs = _execs + 1;
						};
						if(!(surfaceIsWater _newDestination)) then {
							_taskForce set [2, _newDestination];

							BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceName;
						};
						// _taskForce set [6, []];

						if((count _activeGroups > 0)) then {
							// Generate new waypoints.
							{
								private _hasVehicle = [_x] call BATTLESPACE_TASK_FORCE_HAS_VEHICLES;
								[_x, _newDestination, "LIMITED", false, _hasVehicle] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
							} forEach _activeGroups;
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
				_taskForce set [5, _state];

				false
			}
		]
	]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;