BATTLESPACE_DISABLE_ARTILLERY = false;
BATTLESPACE_ARTILLERY_DEBUG = false;
BATTLESPACE_ARTILLERY_SECTIONS = [];
BATTLESPACE_ARTILLERY_OBSERVER_TARGETS = createHashMap;
BATTLESPACE_ARTILLERY_PIECE = "rhs_2s3_tv";
BATTLESPACE_ARTILLERY_PIECES_PER_BATTERY = 2;
BATTLESPACE_ARTILLERY_SPAWN_COOLDOWN = 3600;
BATTLESPACE_LAST_ARTILLERY_SPAWN = -BATTLESPACE_ARTILLERY_SPAWN_COOLDOWN;
BATTLESPACE_ARTILLERY_POLL_COOLDOWN = 10;
BATTLESPACE_ARTILLERY_COOLDOWN_PER_SHELL = 90;
BATTLESPACE_ARTILLERY_MIN_COOLDOWN = 90;
BATTLESPACE_ARTILLERY_MAX_COOLDOWN = 180;
BATTLESPACE_ARTILLERY_MIN_SUPPRESSION_TIME_PER_SHELL = 50;
BATTLESPACE_ARTILLERY_MAX_SUPPRESSION_TIME_PER_SHELL = 75;
BATTLESPACE_ARTILLERY_SHELL = "rhs_mag_HE_2a33";
BATTLESPACE_ARTILLERY_WP_SHELL = "rhs_mag_WP_2a33";
// Base cooldown for a counter battery request to be generated.
// Base, because high readiness will tick faster.
// See POLL_REQUESTS function to further balance
BATTLESPACE_ARTILLERY_COUNTER_BATTERY_BASE_COOLDOWN = 0;
BATTLESPACE_ARTILLERY_BASE_ACCURACY_BUILDUP = 9;

// Cycle range for it to roll a chance to swap from network on to network off.
// Minimum 40 * 15 to 240 * 15.
// See poll rate math in poll requests 
BATTLESPACE_ARTILLERY_MINIMUM_CYCLES_TO_SWAP = 17;
BATTLESPACE_ARTILLERY_MAXIMUM_CYCLES_TO_SWAP = 22;


BATTLESPACE_ARTILLERY_LAST_COUNTER_BATTERY_DATA = [];
BATTLESPACE_ARTILLERY_FIRING_LOCATIONS = [];



missionNameSpace setVariable ["itc_land_cobra_shells", []];
missionNameSpace setVariable ["itc_land_cobra_origins", []];
missionNameSpace setVariable ["itc_land_cobra_firingPositions", []];
missionNameSpace setVariable ["itc_land_cobra_engagements", []];
missionNameSpace setVariable ["itc_land_cobra_start", 1000];
missionNameSpace setVariable ["itc_land_cobra_engagementTime", 30];

missionNameSpace setVariable ["itc_land_cobra_activeShells", []];


BATTLESPACE_ARTILLERY_REPORT_SHELL_IMPACT = {
	params ["_impactLocation"];

	private _nearbyArty = _impactLocation nearEntities [[BATTLESPACE_ARTILLERY_PIECE], 200];

	if((count _nearbyArty) > 0) then {

		private _batteryGroup = group (_nearbyArty#0);

		private _state = _batteryGroup getVariable ["BSAState", []];
		

		
		
		_state params [["_status", "NOT READY"], ["_initialSetupTime", 0], ["_loc", []], ["_target", objNull], ["_accuracy", 0], ["_observer", objNull], ["_tLocs", []], ["_tLoc", []], ["_systemTargeted", false], ["_cooldownExpiresAt", 0], ["_suppressedUntil", 0]];
		// Up to 20 minutes of suppression
		// Add a random amount of time to be suppressed

		private _rTime = BATTLESPACE_ARTILLERY_MIN_SUPPRESSION_TIME_PER_SHELL + floor (random (BATTLESPACE_ARTILLERY_MAX_SUPPRESSION_TIME_PER_SHELL - BATTLESPACE_ARTILLERY_MIN_SUPPRESSION_TIME_PER_SHELL));
		private _newSuppressedUntil = (CBA_missionTime + _rTime) max ((_suppressedUntil + _rTime) min (CBA_missionTime + 1200));
		
		_state set [0, "SUPPRESSED"];
		_state set [10, _newSuppressedUntil];


		_batteryGroup setVariable ["BSAState", _state, true];

	};
};
BATTLESPACE_ARTILLERY_REPORT_SHELL_FIRED = {
	params ["_vehicle", "_projectile"];


	BATTLESPACE_ARTILLERY_FIRING_LOCATIONS pushBack [getPosATLVisual _vehicle, CBA_missionTime];

	publicVariable "BATTLESPACE_ARTILLERY_FIRING_LOCATIONS";

	if(!(BATTLESPACE_ARTILLERY_LAST_COUNTER_BATTERY_DATA isEqualTo [])) then {
		BATTLESPACE_ARTILLERY_LAST_COUNTER_BATTERY_DATA params ["_loc", "_time"];

		if((CBA_missionTime - _time) <= 1800 && (CBA_missionTime - _time) > 90 && BATTLESPACE_ARTILLERY_NETWORK_ENABLED) then {

			if((_loc distance2D _vehicle) <= 300) then {
				// Add new counter battery request
				// Any system that is in COOLING DOWN reset to READY
				// High accuracy
				[getPosATLVisual _vehicle, objNull, 300, true] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_TARGET", 2]; 

				private _readyBatteries = [] call BATTLESPACE_ARTILLERY_GET_READY_BATTERIES;

				if((count _readyBatteries) <= 0) then {
					if((count BATTLESPACE_ARTILLERY_SECTIONS) > 0) then {
						{
							private _curState = _x getVariable "BSAState";

							if((_curState#0) == "COOLING DOWN") then {
								if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat "RESET COOLDOWN";};
								_curState set [0, "READY"];
								_curState set [3, objNull];
								_curState set [4, 0];
								_curState set [5, objNull];
								_curState set [6, []];
								_curState set [7, []];
								_curState set [8, false];

								_x setVariable ["BSAState", _curState, true];
							};
						} forEach BATTLESPACE_ARTILLERY_SECTIONS;
					} else {
						// Penalize for continuing to shoot from the same location, new battery spawn faster
						BATTLESPACE_LAST_ARTILLERY_SPAWN = BATTLESPACE_LAST_ARTILLERY_SPAWN - 60;
					};
				};

				
			};
		};
	};

	
};

BATTLESPACE_GET_MIN_DISPERSION = {
	params ["_timeInCombat", ["_wp", false]];

	private _dispersion = 0 max (300 - _timeInCombat) * 0.5;
	
	if(!_wp) then {
		if(_timeInCombat < 85) then {
			_dispersion = _dispersion + 100;
		} else {
			if(_timeInCombat < 150) then {
				_dispersion = _dispersion + 40;
			};
		};
	} else {
		_dispersion = 30;
	};


	
	_dispersion

};

BATTLESPACE_GET_MAX_DISPERSION = {
	params ["_timeInCombat", ["_wp", false]];

	private _dispersion = 0 max (300 - _timeInCombat) * 0.8 + 60;

	if(_timeInCombat < 85) then {
		_dispersion = _dispersion + 100;
	} else {
		if(_timeInCombat < 150) then {
			_dispersion = _dispersion + 40;
		};
	};

	if(_wp) then {
		_dispersion = 0 max (300 - _timeInCombat) * 0.45 + 100;
	};

	_dispersion
};

BATTLESPACE_SPAWN_BATTERY = {
	params ["_target"];

	if (BATTLESPACE_DISABLE_ARTILLERY) exitWith {};

	if((diag_tickTime - BATTLESPACE_LAST_ARTILLERY_SPAWN) < BATTLESPACE_ARTILLERY_SPAWN_COOLDOWN ) exitWith {};
	BATTLESPACE_LAST_ARTILLERY_SPAWN = diag_tickTime;
	publicVariable "BATTLESPACE_LAST_ARTILLERY_SPAWN";
	if((count BATTLESPACE_ARTILLERY_SECTIONS) >= 2) exitWith {};
	
	private _costDepth = 8;
	private _spawnSectors = [blufor_sectors, _costDepth] call NETWORKED_SECTORS_GET_SECTORS_UP_TO_COST;
	private _sectorToSpawnIn = "";

	if(count _spawnSectors > 0) then {

		private _costToPullFrom = _costDepth;

		while { _sectorToSpawnIn == "" && (count _spawnSectors) > 0 && _costToPullFrom >= 1 } do {

			private _validSectors = _spawnSectors select {
				(_x#0) == _costToPullFrom
			};

			private _invalids = _validSectors select {

				private _mPos = getMarkerPos (_x#1);

				private _alreadyHasArty = false;

				private _nearbyArty = _mPos nearEntities [[BATTLESPACE_ARTILLERY_PIECE] + BATTLESPACE_SAM_SITE_TELS + BATTLESPACE_SAM_SITE_FCRS, 1000];

				_nearbyArty = _nearbyArty select { alive _x };

				_alreadyHasArty = (count _nearbyArty) > 0;

				(_mPos distance2D (_target getPos [0,0])) > 9000 || _alreadyHasArty
			};

			_validSectors = _validSectors - _invalids;

			_spawnSectors = _spawnSectors - _invalids;
			// TODO: Can make it more complex and save state of which sam site spawned at what sector
			// Evaluate that sector's cost
			// And then select a sector that is not at the existing sectors and do not skip if the frontline has shifted where there's different costs.
			// Skip to next available sectors so there's less chances of stacking sites
			if((count _validSectors) <= 1) then {
				_costToPullFrom = _costToPullFrom - 1;
				_spawnSectors = _spawnSectors - _validSectors;
				continue;
			};

			_sectorToSpawnIn = (selectRandom _validSectors) select 1;

			
		};
	};

	if(_sectorToSpawnIn == "") exitWith {
		if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat "Unable to find sector to spawn artillery for";};
		diag_log format ["Unable to find sector to spawn artillery for"];
	};
	private _wantHouses = false;
	private _expr = format ["4 * hills - (10 * sea) - (3 * houses) - (2 * trees) - (4 * forest)"];
	private _expr2 = format ["4 * meadow - (10 * sea)  - (3 * houses) - (2 * trees) - (4 * forest)"];
	private _potentialSpawnPoints = selectBestPlaces [getMarkerPos _sectorToSpawnIn, 600, _expr, 40, 10];

	_potentialSpawnPoints = _potentialSpawnPoints + (selectBestPlaces [getMarkerPos _sectorToSpawnIn, 600, _expr2, 40, 20]);

	
	private _sideEnemy = GRLIB_side_enemy;

	private _fcrGrp = createGroup [_sideEnemy, true];

	private _spawnPoint = nil;

	{
		_x params ["_pos", "_expr"];
		private _spawn = _pos findEmptyPosition [0, 125, BATTLESPACE_ARTILLERY_PIECE];

		if(!(_spawn isEqualTo [])) exitWith {
			_spawnPoint = _pos;
		};
	} forEach _potentialSpawnPoints;

	if(isNil "_spawnPoint") exitWith {
		if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat format ["Could not find a valid spawn point for %1", BATTLESPACE_ARTILLERY_PIECE];};
		diag_log format ["Unable to find sector to spawn artillery for"];
	};
	private _vehs = [];

	
	for "_i" from 1 to BATTLESPACE_ARTILLERY_PIECES_PER_BATTERY do {

		private _spawn = _spawnPoint findEmptyPosition [10, 200, BATTLESPACE_ARTILLERY_PIECE];
		
		private _newVeh = BATTLESPACE_ARTILLERY_PIECE createVehicle _spawn;	


		_vehs pushBack _newVeh;

		_newVeh setVariable ["acex_headless_blacklist", true, true]; 
		_newVeh addEventHandler ["Killed", {
			params ["_vehicle"];
			if (!isNil "KPLIB_fnc_queueDeadObjectCleanup") then {
				[_vehicle] call KPLIB_fnc_queueDeadObjectCleanup;
			};
		}];

		private _crew = units (createVehicleCrew _newVeh);
		_crew joinSilent _fcrGrp;
		_newVeh disableAI "FSM";
		_newVeh disableAI "AUTOTARGET";
		{
			_x setUnitCombatMode "BLUE";
			_x disableAI "FSM";
			_x disableAI "AUTOTARGET";
			_x setVariable ["acex_headless_blacklist", true, true]; 
			_x addEventHandler ["Killed", {
				params ["_unit"];
				if (!isNil "KPLIB_fnc_queueDeadObjectCleanup") then {
					[_unit] call KPLIB_fnc_queueDeadObjectCleanup;
				};
			}];

		} forEach _crew;

		sleep 1;

		
	};
	_fcrGrp setVariable ["BSAState", ["READY", 0, getPos ((units _fcrGrp)#0)], true];
	_fcrGrp setVariable ["acex_headless_blacklist", true, true];
	_fcrGrp setVariable ["Vcm_Disable", true, true];
	BATTLESPACE_ARTILLERY_SECTIONS pushBack _fcrGrp;


	
	

	BATTLESPACE_LAST_ARTILLERY_SPAWN = diag_tickTime;
	publicVariable "BATTLESPACE_ARTILLERY_SECTIONS";
	publicVariable "BATTLESPACE_LAST_ARTILLERY_SPAWN";
};

BATTLESPACE_ARTILLERY_GET_READY_BATTERIES = {
	private _readyBatteries = [];
	private _invalids = [];
	{
		private _state = _x getVariable ["BSAState", []];

		private _vehs = [];

		{
			private _veh = (vehicle _x);

			if(_veh isEqualTo _x) then {
				continue;
			};

			if(!(canFire _veh)) then {
				continue;
			};
			_vehs pushBack _veh;
		} forEach (units _x);

		if((count _vehs) <= 0) then {
			_invalids pushBack _x;
			continue;
		};

		if(count ((units _x) select { alive _x }) <= 0) then {
			_invalids pushBack _x;
			continue;
		};
		_state params [["_status", "NOT READY"], ["_initialSetupTime", 0], ["_loc", []], ["_target", objNull], ["_accuracy", 0], ["_observer", objNull], ["_tLocs", []], ["_tLoc", []], ["_systemTargeted", false], ["_cooldownExpiresAt", 0], ["_suppressedUntil", 0]];
		// If status is READY
		if(_status == "READY") then {
			_readyBatteries pushBack _x;
		};

		if(_status == "SUPPRESSED") then {
			if(CBA_missionTime > _suppressedUntil) then {
				if(CBA_missionTime > _cooldownExpiresAt) then {
					_state set [0, "READY"];
				} else {
					_state set [0, "COOLING DOWN"];
				};
				_state set [10, 0];

				_x setVariable ["BSAState", _state, true];
				_readyBatteries pushBack _x;
			};
		};
	} forEach BATTLESPACE_ARTILLERY_SECTIONS;
	BATTLESPACE_ARTILLERY_SECTIONS = BATTLESPACE_ARTILLERY_SECTIONS - _invalids;

	publicVariable "BATTLESPACE_ARTILLERY_SECTIONS";
	_readyBatteries;
};
BATTLESPACE_ARTILLERY_POLL_REQUESTS = {
	(_this select 0) params [["_nextTick", 0], ["_counter", 0], ["_cycleCount", 0], ["_nextCycleSwap", 0], ["_networkEnabled", true]];


	if(CBA_missionTime < _nextTick) exitWith {};

	

	private _newNetworkEnabled = _networkEnabled;
	BATTLESPACE_ARTILLERY_CURRENT_CYCLE = _cycleCount + 1;

	publicVariable "BATTLESPACE_ARTILLERY_CURRENT_CYCLE";

	(_this select 0) set [2, BATTLESPACE_ARTILLERY_CURRENT_CYCLE];
	if(BATTLESPACE_ARTILLERY_CURRENT_CYCLE >= _nextCycleSwap) then {

		if(isNil { BATTLESPACE_ARTILLERY_SAME_ROLLS } ) then {
			BATTLESPACE_ARTILLERY_SAME_ROLLS = 0;
		};

		private _swap = (random 100) <= (50 + (BATTLESPACE_ARTILLERY_SAME_ROLLS * 20));
		
		if(_swap) then {
			_newNetworkEnabled = !_newNetworkEnabled;
		};

		if(_newNetworkEnabled == _networkEnabled) then {
			BATTLESPACE_ARTILLERY_SAME_ROLLS = BATTLESPACE_ARTILLERY_SAME_ROLLS + 1;
		} else {
			BATTLESPACE_ARTILLERY_SAME_ROLLS = 0;
		};

		publicVariable "BATTLESPACE_ARTILLERY_SAME_ROLLS";

		
		

		private _nextSwap = BATTLESPACE_ARTILLERY_MINIMUM_CYCLES_TO_SWAP + floor (random (BATTLESPACE_ARTILLERY_MAXIMUM_CYCLES_TO_SWAP - BATTLESPACE_ARTILLERY_MINIMUM_CYCLES_TO_SWAP));
		(_this select 0) set [2, 0];
		(_this select 0) set [3, _nextSwap];
		(_this select 0) set [4, _newNetworkEnabled];
		BATTLESPACE_ARTILLERY_CURRENT_CYCLE = 0;
		BATTLESPACE_ARTILLERY_CYCLES_REQUIRED = _nextSwap;
		BATTLESPACE_ARTILLERY_NETWORK_ENABLED = _newNetworkEnabled;
		publicVariable "BATTLESPACE_ARTILLERY_CURRENT_CYCLE";
		publicVariable "BATTLESPACE_ARTILLERY_CYCLES_REQUIRED";
		publicVariable "BATTLESPACE_ARTILLERY_NETWORK_ENABLED";
		
	};

	

	private _lowPop = ([] call KPLIB_fnc_getPlayerCount) <= 20;
	private _adjustedCooldown = BATTLESPACE_ARTILLERY_POLL_COOLDOWN;
	// 40 * 40 = 80
	if(combat_readiness < 100) then {
		_adjustedCooldown = _adjustedCooldown * 2;
	};
	// 80 * 80 = 160
	if(combat_readiness < 50) then {
		_adjustedCooldown = _adjustedCooldown * 2;
	};
	// 160 * 1.5 = 240
	// 80 * 1.5 = 120
	// 40 * 1.5 = 60
	if(_lowPop) then {
		_adjustedCooldown = _adjustedCooldown * 1.5;
	};
	

	private _counterBatteryMultiplier = 1;

	if(combat_readiness < 75) then {
		_counterBatteryMultiplier = 0.5;
	};

	if(combat_readiness >= 125) then {
		_counterBatteryMultiplier = 1.5;
	};
	

	
	
	BATTLESPACE_ARTILLERY_NEXT_TICK_TIME = CBA_missionTime + _adjustedCooldown;
	publicVariable "BATTLESPACE_ARTILLERY_NEXT_TICK_TIME";
	(_this select 0) set [0, BATTLESPACE_ARTILLERY_NEXT_TICK_TIME];

	(_this select 0) set [1, _counter + _adjustedCooldown * _counterBatteryMultiplier];
	

	BATTLESPACE_ARTILLERY_COUNTER_BATTERY_TIMER = _counter;
	publicVariable "BATTLESPACE_ARTILLERY_COUNTER_BATTERY_TIMER";

	private _counterBatteryCooldown = BATTLESPACE_ARTILLERY_COUNTER_BATTERY_BASE_COOLDOWN * ([1, 1.25] select _lowPop);
	if(_counter >= _counterBatteryCooldown) then {

		// Go through all vehicles

		private _timeRequired = 60 - (30 * (combat_readiness / 125));

		if((count BATTLESPACE_ARTILLERY_FIRING_LOCATIONS) >= 4) then {
			private _right = ((count BATTLESPACE_ARTILLERY_FIRING_LOCATIONS) - 1);
			private _mostRecentFiringData = [];
			private _left = ((count BATTLESPACE_ARTILLERY_FIRING_LOCATIONS) - 2);
			private _valid = false;
			while { _right >= 3 && _valid == false && _left > 0 } do {
				_mostRecentFiringData = (BATTLESPACE_ARTILLERY_FIRING_LOCATIONS select _right);
				_mostRecentFiringData params ["_location", "_time"];

				if((CBA_missionTime - _time) < _timeRequired) then {
					_right = _right - 1;
					continue;
				};

				if((CBA_missionTime - _time) >= 600) then {
					_right = _right - 1;
					continue;
				};

				private _firingData = (BATTLESPACE_ARTILLERY_FIRING_LOCATIONS select _left);
				_firingData params ["_loc", "_t"];

				if((CBA_missionTime - _t) < _timeRequired) then {
					_left = _left - 1;
					continue;
				};

				if((CBA_missionTime - _t) >= 600) then {
					_left = _left - 1;
					continue;
				};

				if((_loc distance2D _location) > 300) then {
					_right = _right - 1;
					
				};
				if((_right - _left) >= 3) exitWith {
					_valid = true;
				};
				_left = _left - 1;
			};


			if(_valid) then {
				_mostRecentFiringData params ["_location", "_time"];
			
			
				BATTLESPACE_ARTILLERY_LAST_COUNTER_BATTERY_DATA = [_location, CBA_missionTime];
				publicVariable "BATTLESPACE_ARTILLERY_LAST_COUNTER_BATTERY_DATA";
				
				[_location, objNull, 250, true, CBA_missionTime] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_TARGET", 2]; 
				// Clear all entries up to and including _right

				
				BATTLESPACE_ARTILLERY_FIRING_LOCATIONS deleteRange [0, _right + 1];

				publicVariable "BATTLESPACE_ARTILLERY_FIRING_LOCATIONS";
			};

			

			

			
			(_this select 0) set [1, 0];
			
		};
	};
	private _readyBatteries = [] call BATTLESPACE_ARTILLERY_GET_READY_BATTERIES;

	if((count _readyBatteries) <= 0 || !BATTLESPACE_ARTILLERY_NETWORK_ENABLED) exitWith {   
		private _targetToFire = nil;
		{
			_y params ["_observer", "_target", "_timeInCombat", ["_systemTargeted", false], ["_targetedAt", CBA_missionTime]];

			if((CBA_missionTime - _targetedAt) >= 600) then {
				[_x] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET", 2];
				continue;
			};

			// To fire on a request, the observer must be valid and alive, otherwise remove it
			// System Targeted means its a COBRA target and should always be prioritized to be fired upon and does not need a valid observer

			if(!_systemTargeted) then {
				if((typeName _observer) != "STRING") then {
					if((isNull _observer) || !(alive _observer)) then {
						[_x] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET", 2];
						continue;
					};
				};
			};
				
			if(!isNil { _target }) then {
				_targetToFire = _target;
			};

		} forEach BATTLESPACE_ARTILLERY_OBSERVER_TARGETS;

		if(!isNil{  _targetToFire }) then {
			[_targetToFire] spawn BATTLESPACE_SPAWN_BATTERY;
		};
	};
	if(!BATTLESPACE_ARTILLERY_NETWORK_ENABLED) exitWith {};
	
	
	// Loop through current observer - targets
	// Find highest accuracy mission to fulfill first

	

	private _currentSelectedTargets = [];

	{
		private _state = _x getVariable ["BSAState", []];
		_state params [["_status", "NOT READY"], ["_initialSetupTime", 0], ["_loc", []], ["_target", objNull], ["_accuracy", 0], ["_observer", objNull], ["_tLocs", []], ["_tLoc", []], ["_systemTargeted", false], ["_cooldownExpiresAt", 0], ["_suppressedUntil", 0]];
		

		if(!(_tLoc isEqualTo [])) then {
			_currentSelectedTargets pushBack _tLoc;
		};
	} forEach BATTLESPACE_ARTILLERY_SECTIONS;

	if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat "Exec";};


	
	{
		private _currentHighestAccuracyRequest = [objNull, objNull, 0];
		private _currentHighestAccuracyKey = nil;
		private _section = _x;
		{
			_y params ["_observer", "_target", "_timeInCombat", ["_systemTargeted", false], ["_targetedAt", CBA_missionTime]];

			// Out of range, arbitrary value
			if(_target distance2D (leader _section) >= 17000) then {
				if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat "Too far";};
				continue
			};

			if((CBA_missionTime - _targetedAt) >= 600) then {
				[_x] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET", 2];
				_valid = false;
				continue;
			};
			private _valid = true;
			// To fire on a request, the observer must be valid and alive, otherwise remove it
			// System Targeted means its a COBRA target and should always be prioritized to be fired upon and does not need a valid observer
			

			if(!_systemTargeted) then {
				if((typeName _observer) != "STRING") then {
					if((isNull _observer) || !(alive _observer)) then {
						[_x] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET", 2];
						_valid = false;
						continue;
					};
				};
			};
			{
				if((_x distance2D _target) < 200) exitWith {
					if (BATTLESPACE_ARTILLERY_DEBUG) then {
						systemChat format ["Skip target %1, too close to existing fire mission being fulfilled", _target];
					};
					_valid = false;
				};
			} forEach _currentSelectedTargets;
			

			if(!_valid) then {
				continue;
			};
			if(_systemTargeted) exitWith {
				_currentHighestAccuracyRequest = _y;
				_currentHighestAccuracyKey = _x;
			};

			if(!_systemTargeted && _timeInCombat > (_currentHighestAccuracyRequest select 2)) then {
				_currentHighestAccuracyRequest = _y;
				_currentHighestAccuracyKey = _x;
			};
		} forEach BATTLESPACE_ARTILLERY_OBSERVER_TARGETS;
		
		if((_currentHighestAccuracyRequest#2) > 0) then {
			_currentSelectedTargets pushBack ((_currentHighestAccuracyRequest#1) getPos [0,0]);

			if (BATTLESPACE_ARTILLERY_DEBUG) then {
				systemChat format ["Battery %1 fire at %2", str _x, str (_currentHighestAccuracyRequest#1)];
			};

			[_x, _currentHighestAccuracyRequest, _currentHighestAccuracyKey] call BATTLESPACE_ARTILLERY_FULFILL_REQUEST;
		};
	} forEach _readyBatteries;
};

BATTLESPACE_ARTILLERY_FULFILL_REQUEST = {
	_this params ["_battery", "_req", "_obsKey"];
	
	(_req) params [["_observer", objNull], ["_target", nil], ["_accuracy", 0], ["_systemTargeted", false], ["_targetedAt", CBA_missionTime], ["_wp", false]];

	private _state = _battery getVariable ["BSAState", []];
	

	_state params [["_status", "NOT READY"], ["_initialSetupTime", 0], ["_loc", []], ["_tgt", objNull], ["_acc", 0], ["_obs", objNull]];

	if(_status != "READY") exitWith { };

	_state set [0, "IN MISSION"];

	_state set [3, _target];
	_state set [4, _accuracy];
	_state set [5, _observer];
	_state set [6, []];
	_state set [7, _target getPos [0,0]];
	_state set [8, _systemTargeted];
	_state set [9, CBA_missionTime + 3600];
	_state set [11, _wp]; // WP?

	_battery setVariable ["BSAState", _state, true];


	[_battery, _req, _obsKey] spawn BATTLESPACE_ARTILLERY_DO_REQUEST;

};
BATTLESPACE_ARTILLERY_DO_REQUEST = {
	params ["_battery", "_req", "_obsKey"];

	(_req) params [["_observer", objNull], ["_target", nil], ["_accuracy", 0], ["_systemTargeted", false], ["_targetedAt", CBA_missionTime], ["_wp", false]];

	private _shells = 1;

	_shells = 1 max (floor (_accuracy / 75));


	if(_accuracy >= 300) then {
		_shells = 6;
	};

	if(_wp) then {
		_shells = _shells max 3;
	};
	// COUNTER-BATTERY is lower accuracy but still a lot of shells
	if(_systemTargeted) then {
		_shells = 6;

		if(_accuracy >= 300) then {
			_shells = 12;
		};
	};


	private _vehs = [];

	{
		private _veh = (vehicle _x);

		if(_veh isEqualTo _x) then {
		continue;
		};
		_veh doWatch (_target getPos [0,0]);
		_vehs pushBack _veh;
	} forEach (units _battery);

	_vehs = _vehs arrayIntersect _vehs;



		
	private _state = _battery getVariable ["BSAState", []];

	private _targets = [];
	private _shellsFired = 0;

	private _shellType = [BATTLESPACE_ARTILLERY_SHELL, BATTLESPACE_ARTILLERY_WP_SHELL] select _wp;

	if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat format ["We are shooting %1", _shellType];};
	for "_i" from 1 to _shells do {
		{	

			
			private _minDispersion = [_accuracy, _wp] call BATTLESPACE_GET_MIN_DISPERSION;
			private _maxDispersion = [_accuracy, _wp] call BATTLESPACE_GET_MAX_DISPERSION;

			

			private _tLoc = _target getPos [0,0];
			private _execs = 0;

			private _inRange = false;
			while { _execs < 25 } do {

				private _new = _target getPos [_minDispersion + (random (_maxDispersion - _minDispersion)), random 360 ];
				if(!(isNull _observer) && (typeName _observer) != "STRING") then {
					if((_target distance2D _observer) <= 200) exitWith {
						_execs = 26;
						_tLoc = _target getPos [0,0];
					};
					if((_new distance2D _observer) <= 300) then {
						_execs = _execs + 1;
						continue;
					};
				};

				_inRange = _tLoc inRangeOfArtillery [[_x], _shellType];

				if(_inRange) then {
					_shellsFired = _shellsFired + 1;
					_tLoc = _new;
					_execs = 26;
				};
				_execs = _execs + 1;
			};
			if(_inRange) then {

			
			

				_targets pushBack _tLoc;

				
				
				_state set [6, _targets];

				_battery setVariable ["BSAState", _state, true];

				

				_x commandArtilleryFire [_tLoc, _shellType, 1];
			};
		
		} forEach _vehs;
		waitUntil {
			sleep 1;
			private _readys = 0;

			{

				private _rdy = true;
				{
					_rdy = _rdy && (unitReady _x);
				} forEach [
					commander _x,
					gunner _x,
					driver _x
				];

				if(_rdy) then {
					_readys = _readys + 1;
				};
			} forEach _vehs;

			_readys == (count _vehs);
		};
	};

	

	waitUntil {
		sleep 2;
		private _readys = 0;

		{

			private _rdy = true;
			{
				_rdy = _rdy && (unitReady _x);
			} forEach [
				commander _x,
				gunner _x,
				driver _x
			];

			if(_rdy) then {
				_readys = _readys + 1;
			};
		} forEach _vehs;

		_readys == (count _vehs);
	};

	[_observer] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET", 2];
	[_obsKey] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET", 2];
	

	{
		[_x, 1] remoteExec ["setVehicleAmmo", _x];
	} forEach _vehs;

	
	
	private _lowPop = ([] call KPLIB_fnc_getPlayerCount) <= 35;

	private _cdMultiplier = 1;

	if(_lowPop) then {
		_cdMultiplier = 2;
	};

	if(combat_readiness < 50) then {
		_cdMultiplier = _cdMultiplier * 1.5;
	};
	private _cooldown =  (BATTLESPACE_ARTILLERY_MIN_COOLDOWN * _cdMultiplier) max (_shells * (BATTLESPACE_ARTILLERY_COOLDOWN_PER_SHELL));

	_cooldown = (BATTLESPACE_ARTILLERY_MAX_COOLDOWN * _cdMultiplier) min _cooldown;

	_state = _battery getVariable "BSAState";
	// Because now the battery may get suppressed mid way through the mission, we need to check if the state is same as before setting to the next state
	if((_state#0) == "IN MISSION") then {
		_state set [0, "COOLING DOWN"];
	};
	// We still set the cooldown time though, that way if something is suppressed and their timer elapses, then we'd set it to COOLING DOWN instead of READY
	_state set [9, CBA_missionTime + _cooldown];
	_battery setVariable ["BSAState", _state, true];
	_cooldown = _cooldown - 15;

	sleep 15;

	private _hasCobra = false;

	{
		if((typeOf _x) == "karmakut_mpq65" && (side _x) == GRLIB_side_friendly) exitWith {
			_hasCobra = true;
		};
	} forEach IADS_SearchRadars;
	if(_hasCobra) then {
		for "_i" from 1 to (_shellsFired) do {

			private _origin = (leader _battery) getPos [random 200, random 360];

			[objNull, _origin] call itc_land_cobra_fnc_processOrigin;
			[objNull, _origin] call itc_land_cobra_fnc_processEngagement;
		};

		_origins = missionNameSpace getVariable "itc_land_cobra_origins";
		_firingPositions = missionNameSpace getVariable "itc_land_cobra_firingPositions";
		_engagements = missionNameSpace getVariable "itc_land_cobra_engagements";
		_start = missionNameSpace getVariable "itc_land_cobra_start";

		missionNameSpace setVariable ["itc_land_cobra_firingPositions",_firingPositions,true];
		missionNameSpace setVariable ["itc_land_cobra_origins",_origins,true];
		missionNameSpace setVariable ["itc_land_cobra_engagements",_engagements, true];
		missionNameSpace setVariable ["itc_land_cobra_start", _start, true];
	};

	sleep (_cooldown);

	private _curState = _battery getVariable "BSAState";
	// If suppressed still, then we don't set to ready.
	if((_curState#0) == "COOLING DOWN") then {
		_curState set [0, "READY"];
	};
	// But we are done with our mission, so erase all mission related info
	_curState set [3, objNull];
	_curState set [4, 0];
	_curState set [5, objNull];
	_curState set [6, []];
	_curState set [7, []];
	_curState set [8, false];
	_curState set [9, 0];
	_battery setVariable ["BSAState", _curState, true];
};
BATTLESPACE_ARTILLERY_OBSERVER_REPORT_REMOTE = {
	params ["_observer"];


	private _targets = _observer targets [true, 0, [GRLIB_side_friendly], 45];


	[_observer, _targets] remoteExec ["BATTLESPACE_ARTILLERY_OBSERVER_REPORT_REMOTE_REPLY", remoteExecutedOwner];

};

BATTLESPACE_ARTILLERY_OBSERVER_REPORT_REMOTE_REPLY = {
	params ["_observer", "_targets"];


	_observer setVariable ["BSA_Targets", _targets, true];
};

BATTLESPACE_ARTILLERY_BROADCAST_TARGET = {
	params ["_target", "_observer", "_timeInCombat", ["_systemTargeted", false], ["_targetedAt", CBA_missionTime], ["_wp", false]];

	BATTLESPACE_ARTILLERY_OBSERVER_TARGETS set [str _observer, [_observer, _target, _timeInCombat, _systemTargeted, _targetedAt, _wp]];

	publicVariable "BATTLESPACE_ARTILLERY_OBSERVER_TARGETS";
};


BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET = {
	params ["_observer"];

	if ((typeName _observer) != "STRING") then {
		BATTLESPACE_ARTILLERY_OBSERVER_TARGETS deleteAt (str _observer);
	} else {
		BATTLESPACE_ARTILLERY_OBSERVER_TARGETS deleteAt _observer;
	};

	publicVariable "BATTLESPACE_ARTILLERY_OBSERVER_TARGETS";
};
BATTLESPACE_ARTILLERY_OBSERVER_COROUTINE = {

	(_this select 0) params [
		"_observer",
		["_state", []]
	];

	

	if(isNull _observer || !(alive _observer) || isNull (group _observer)) exitWith {
		[_this select 1] call CBA_fnc_removePerFrameHandler;
	};


	
	_state params [
		["_timeInCombat", 0],
		["_inCombat", false],
		["_callInWp", (random 100) < 50]
	];
	

	_state set [2, [_callInWp, !_callInWp] select ((random 100) >= 50)];

	


	private _shouldUpdateToBeInCombat = false;
	private _targets = [];

	if(!(local _observer)) then {
		[_observer] remoteExec ["BATTLESPACE_ARTILLERY_OBSERVER_REPORT_REMOTE", _observer];
		_targets = _observer getVariable ["BSA_Targets", []];
	} else {
		_targets = _observer targets [true, 0, [GRLIB_side_friendly], 45];
	};

	private _lowPop = ([] call KPLIB_fnc_getPlayerCount) <= 35;
	if((count _targets) > 0) then {
		_shouldUpdateToBeInCombat = true;

		private _sortedTargets = [];
		{
			if(_x isKindOf "Air") then { continue };
			if((side _x) != GRLIB_side_friendly) then { continue };
			if((_x getVariable ["ACE_isUnconscious", false])) then { continue };

			private _nearEntities = ((getPos _x) nearEntities [["Man"], 300]) select { (alive _x) && ((side _x) == GRLIB_side_enemy) };
			if((count _nearEntities) > 2) then { continue };

			_sortedTargets pushBack [(getPos _x) distance2D (getPos _observer), _x];
		} forEach _targets;

		if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat format ["Obs sees %1", _sortedTargets];};

		_observer setVariable ["BSASortedTargets", _sortedTargets, true];

		_sortedTargets sort true;
		private _multiplier = 1;
		private _retainMultiplier = 1;
		private _newTime = _timeInCombat;
		if((count _sortedTargets) > 0) then {
			private _tLoc = (((_sortedTargets select 0) select 1) getPos [0,0]);

			private _curReq = BATTLESPACE_ARTILLERY_OBSERVER_TARGETS getOrDefault [(str _observer), []];

			_curReq params ["", ["_prevLoc", []]];
			
			

			if(!(_prevLoc isEqualTo [])) then {
				if((_prevLoc distance2D _tLoc) <= 5) then {
					_multiplier = 4;
				} else {

					if((_prevLoc distance2D _tLoc) >= 100) then {
						_retainMultiplier = 0.4;
					} else {
						if((_prevLoc distance2D _tLoc) >= 12.5) then {
							_retainMultiplier = 0.9;
						};
					};
				};
			};

			_newTime = (_timeInCombat * _retainMultiplier) + BATTLESPACE_ARTILLERY_BASE_ACCURACY_BUILDUP * ([1, 0.33] select _lowPop) * _multiplier;
			[_tLoc, _observer, _newTime, false, CBA_missionTime, _callInWp] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_TARGET", 2]; 
		} else {
			[_observer] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET", 2];
		};

		if(!BATTLESPACE_ARTILLERY_NETWORK_ENABLED) then {
			_newTime = 0;
		};
		_state set [0, _newTime];
	} else {

		_state set [0, 0 max (_timeInCombat - (BATTLESPACE_ARTILLERY_BASE_ACCURACY_BUILDUP * 6 * ([1, 0.33] select _lowPop)))];
		if(!BATTLESPACE_ARTILLERY_NETWORK_ENABLED) then {
			_state set [0, 0];
		};
		[_observer] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET", 2];
	};


	_state set [1, _shouldUpdateToBeInCombat];

	(_this select 0) set [1, _state];
	
};
RENDER_BATTLESPACE_ARTILLERY = true;
RENDER_BATTLESPACE_ARTILLERY_PFH = {

	if(isNull curatorCamera) exitWith {};
	if(accTime <= 0 || isGamePaused) exitWith {};

	if(!RENDER_BATTLESPACE_ARTILLERY) exitWith { [_this select 1] call CBA_fnc_removePerFrameHandler; };
	
	{
		_y params ["_observer", "_target", "_timeInCombat", "_systemTargeted", "_targetedAt", "_wp"];
		private _targetPos = (_target getPos [0,0]) vectorAdd [0,0,25];
		private _cffType = "FIRE-FOR-EFFECT";

		private _targetMarker = "\A3\ui_f\data\map\markers\nato\b_inf.paa";
		if(_timeInCombat < 300) then {
			_cffType = "ADJUST FIRE";
		};

		if(_wp) then {
			_cffType = "IMMEDIATE SMOKE";
		};
		private _targetType = "TARGET";

	
		if(_systemTargeted) then {
			if(_timeInCombat >= 200) then {
				_cffType = "NEUTRALIZATION";
			} else {
				_cffType = "SUPPRESSION";
			};
			_targetType = "COUNTER-BATTERY TARGET";
			_targetMarker = "\A3\ui_f\data\map\markers\nato\b_art.paa";
		};
		if(!isNull (_observer) && (typeName _observer) != "STRING") then {

			private _observerPos = (getPos _observer) vectorAdd [0,0,25];
			
			private _dir = _observerPos vectorFromTo _targetPos;

			private _networkStr = [format ["NETWORK OFF (%1/%2)", BATTLESPACE_ARTILLERY_CURRENT_CYCLE, BATTLESPACE_ARTILLERY_CYCLES_REQUIRED] , format ["NETWORK ON (%1/%2)", BATTLESPACE_ARTILLERY_CURRENT_CYCLE, BATTLESPACE_ARTILLERY_CYCLES_REQUIRED]] select BATTLESPACE_ARTILLERY_NETWORK_ENABLED;

			drawIcon3D ["\A3\ui_f\data\map\markers\nato\n_hq.paa", [1,0.4,0.4,1], _observerPos, 1, 1, 0, format ["Accuracy: %1 | %2 | %3", _timeInCombat, _cffType, _networkStr], 1, 0.03, "TahomaB"];
			private _distance = _observerPos distance _targetPos;

			private _multi = _distance / 40;
			for "_i" from 1 to 39 do {

				private _dist = _multi * _i;
				drawIcon3D ["\a3\UI_F_Enoch\Data\CfgMarkers\dot1_ca.paa", [1,1,1,1], _observerPos vectorAdd (_dir vectorMultiply _dist), 0.5, 0.5, 0, "", 1, 0.02, "TahomaB"];
			};
			drawLine3D [_observerPos, _targetPos, [0,1,0,1]];
		};
		
		
		drawIcon3D [_targetMarker, [0.4,0.4,1,1], _targetPos, 1, 1, 0, _targetType, 1, 0.03, "TahomaB"];

		

		


	} forEach BATTLESPACE_ARTILLERY_OBSERVER_TARGETS;
	
	{

		private _leader = leader _x;

		private _state = _x getVariable ["BSAState", []];
		

		
		
		_state params [["_status", "NOT READY"], ["_initialSetupTime", 0], ["_loc", []], ["_target", objNull], ["_accuracy", 0], ["_observer", objNull], ["_tLocs", []], ["_tLoc", []], ["_systemTargeted", false], ["_cooldownExpiresAt", 0], ["_suppressedUntil", 0], ["_wp", false]];
		
		private _cffType = "FIRE-FOR-EFFECT";
		
		private _networkStr = [format ["NETWORK OFF (%1/%2)", BATTLESPACE_ARTILLERY_CURRENT_CYCLE, BATTLESPACE_ARTILLERY_CYCLES_REQUIRED] , format ["NETWORK ON (%1/%2)", BATTLESPACE_ARTILLERY_CURRENT_CYCLE, BATTLESPACE_ARTILLERY_CYCLES_REQUIRED]] select BATTLESPACE_ARTILLERY_NETWORK_ENABLED;

		if(_accuracy < 300) then {
			_cffType = "ADJUST FIRE";
		};
		if(_wp) then {
			_cffType = "IMMEDIATE SMOKE";
		};
		if(_systemTargeted) then {

			if(_accuracy >= 200) then {
				_cffType = "NEUTRALIZATION";
			} else {
				_cffType = "SUPPRESSION";
			};
		};

		private _statusStr = _status;

		if(_status == "SUPPRESSED") then {

			private _timeRemaining = 0 max ceil (_suppressedUntil - CBA_missionTime);

			if(_timeRemaining == 0) then {

				if(_cooldownExpiresAt > CBA_missionTime) then {
					private _cooldownRemaining = 0 max ceil (_cooldownExpiresAt - CBA_missionTime);
					private _mins = floor (_cooldownRemaining / 60);
					private _rem =_cooldownRemaining - (_mins * 60);

					if(_rem < 10) then {
						_rem = format ["0%1", _rem];
					};
					_statusStr = format ["COOLING DOWN (%1:%2)", _mins, _rem];
				} else {
					_statusStr = format ["AWAITING NETWORK CYCLE"];
				};
				
			} else {

				private _mins = floor (_timeRemaining / 60);
				private _rem =_timeRemaining - (_mins * 60);
				if(_rem < 10) then {
						_rem = format ["0%1", _rem];
					};
				_statusStr = format ["SUPPRESSED (%1:%2)", _mins, _rem];
			};
			
		};
		if(_status == "COOLING DOWN") then {
			private _cooldownRemaining = 0 max ceil (_cooldownExpiresAt - CBA_missionTime);
			private _mins = floor (_cooldownRemaining / 60);
			private _rem =_cooldownRemaining - (_mins * 60);
			if(_rem < 10) then {
				_rem = format ["0%1", _rem];
			};
			_statusStr = format ["COOLING DOWN (%1:%2)", _mins, _rem];
		};
		private _pos = (getPos _leader) vectorAdd [0,0,40];

		drawIcon3D ["\A3\ui_f\data\map\markers\nato\o_art.paa", [1,0.4,0.4,1], _pos, 1, 1, 0, format ["BATTERY %1 | STATUS: %2 | %3", str _x, _statusStr, _networkStr], 1, 0.03, "TahomaB"];

		if(!(_tLoc isEqualTo [])) then {
			private _targetPos = _tLoc vectorAdd [0,0,40];
			drawIcon3D ["\A3\ui_f\data\map\groupicons\selector_selectedEnemy_ca.paa", [1,0.4,0.4,1], _targetPos, 1, 1, 0, format ["BATTERY %1 %2 (%3)", str _x, _cffType, _accuracy], 1, 0.03, "TahomaB"];

			
			private _minDispersion = [_accuracy, _wp] call BATTLESPACE_GET_MIN_DISPERSION;
			private _maxDispersion = [_accuracy, _wp] call BATTLESPACE_GET_MAX_DISPERSION;

			for "_i" from 0 to 35 do {

				private _angle = _i * 10;

				private _pos = _targetPos getPos [_minDispersion, _angle];
				private _maxPos = _targetPos getPos [_maxDispersion, _angle];
				drawIcon3D ["\a3\UI_F_Enoch\Data\CfgMarkers\dot1_ca.paa", [1,0,0,1], _pos, 0.5, 0.5, 0, "", 1, 0.02, "TahomaB"];
				drawIcon3D ["\a3\UI_F_Enoch\Data\CfgMarkers\dot1_ca.paa", [0,1,0,1], _maxPos, 0.5, 0.5, 0, "", 1, 0.02, "TahomaB"];
			};
		};

		if((count _tLocs) > 0) then {

			{
				drawIcon3D ["\A3\ui_f\data\map\groupicons\waypoint.paa", [1,0,0,1], _x, 0.5, 0.5, 0, format ["TLOC%1", _forEachIndex+1], 1, 0.03, "TahomaB"];
			} forEach _tLocs;
		};


	} forEach BATTLESPACE_ARTILLERY_SECTIONS;
};

if(hasInterface) then {
	[
		{ _this call RENDER_BATTLESPACE_ARTILLERY_PFH },
		0,
		[]
	] call CBA_fnc_addPerFrameHandler;
};
if (isServer) then {

	[
		{ _this call BATTLESPACE_ARTILLERY_POLL_REQUESTS },
		1,
		[]
	] call CBA_fnc_addPerFrameHandler;


	
};

