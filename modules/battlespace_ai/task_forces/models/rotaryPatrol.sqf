

[
	"Rotary Patrol",
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
						private _success = [_taskForceName, _taskForce, false, true, false, false, "LIMITED"] call BATTLESPACE_TASK_FORCE_DEFAULT_TRY_SPAWN;

						
						(BATTLESPACE_TASK_FORCES get _taskForceName) set [11, false];
						if(_success) then {

							private _objs = _taskForce select 8;
							private _grp = createGroup [_taskForce select 6, true];
							{
								(crew _x) joinSilent _grp;
							} forEach _objs;

							[_grp, _taskForce select 2, "LIMITED", false, true] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;

							_taskForce set [4, [_grp]];
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
				// Active groups don't matter, when a unit dies _composition will get updated.
			
				private _currentVehicles = _composition getOrDefault ["vehicles", []];
				// For the sake of performance and etc.. need a minimal amount to continue to save / be valid.
				if((count _currentVehicles) <= 0) exitWith { false };
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
				

				true
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

				if((_currentLoc distance2D _destination) <= 250) exitWith {
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

						_maximumRange = 2000 min _maximumRange;
						_maximumRange = 1000 max _maximumRange;

						private _pos = (getMarkerPos _sector);

						private _dirToBlufor = _pos getDir (getMarkerPos _closestBluforSector);
						if(_closestBluforSector == _sector) then {
							_dirToBlufor = [random 1, random 1, 0];
						};

						private _dir = (_dirToBlufor - 90);

						if(_dir < 0) then {
							_dir = 360 + _dir;
						};

						_dir = _dir + (random 180);

						if(_dir > 360) then {
							_dir = _dir - 360;
						};


						private _minRange = _maximumRange * 0.1;

						private _step = _minRange / 50;

						

					

						private _newDestination = _pos getPos [_maximumRange * 0.1 + (random (_maximumRange * 0.8)), _dir];
						private _execs = 0;
						while { surfaceIsWater _newDestination && _execs < 5 } do {
							_dir = (_dirToBlufor - 90);

							if(_dir < 0) then {
								_dir = 360 + _dir;
							};

							_dir = _dir + (random 180);

							if(_dir > 360) then {
								_dir = _dir - 360;
							};
							_newDestination = _pos getPos [_maximumRange * 0.1 - (_execs * _step) + (random (_maximumRange * 0.8)), _dir];
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
								[_x, _newDestination, "LIMITED", false, true] call BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
							} forEach _activeGroups;
						};
					};

					false
				};

				
				
				// If group is active don't do anything
				if(count _activeObjects > 0) exitWith {

					
					
					
					private _invalids = [];
					_taskForce set [1, getPos (leader (_activeGroups#0))];
					{
						{
							if(!(_x isEqualTo (vehicle _x))) then {
							} else {
								_invalids pushBack _x;
							}
						} forEach (units _x);
					} forEach _activeGroups;

					_invalids joinSilent grpNull;



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