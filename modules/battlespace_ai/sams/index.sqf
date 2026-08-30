// SAMs 
// Track how many sites are currently active
// Logic for spawning in a SAM site by traversing sector link graph and then finding suitable spawns.

BATTLESPACE_SAM_DEBUG = false;
BATTLESPACE_SAM_EXISTING_SITES = [];
BATTLESPACE_SAM_SITE_POOLS = createHashMap;
BATTLESPACE_SAM_SITE_AUTOINCREMENT = 1;

BATTLESPACE_SAM_LAST_SPAWN_TIME = 0;

BATTLESPACE_SAM_BUILD_RESERVATION = {
	params ["_classes"];
	private _cost = createHashMap;
	private _strategicLaunchers = 0;
	private _tacticalLaunchers = 0;
	private _shorad = [];
	{{_shorad pushBackUnique _x} forEach _x} forEach BATTLESPACE_SAM_SITE_SHORAD;
	{
		if (_x in BATTLESPACE_SAM_SITE_TELS || {_x in BATTLESPACE_SAM_SITE_FCRS}) then {_strategicLaunchers = _strategicLaunchers + 1};
		if (_x in _shorad) then {_tacticalLaunchers = _tacticalLaunchers + 1};
	} forEach _classes;
	if (_strategicLaunchers > 0) then {_cost set ["strategic_sam", _strategicLaunchers]};
	if (_tacticalLaunchers > 0) then {_cost set ["tactical_sam", _tacticalLaunchers]};
	private _telCount = {_x in BATTLESPACE_SAM_SITE_TELS} count _classes;
	if (_telCount > 0) then {
		_cost set ["strategic_missiles", _telCount * (missionNamespace getVariable ["BATTLESPACE_SAM_STRATEGIC_MISSILES_PER_LAUNCHER", 8])];
	};
	if (_tacticalLaunchers > 0) then {
		_cost set ["tactical_missiles", _tacticalLaunchers * (missionNamespace getVariable ["BATTLESPACE_SAM_TACTICAL_MISSILES_PER_LAUNCHER", 4])];
	};
	_cost
};

BATTLESPACE_SAM_TRY_RELOAD = {
	params ["_vehicle", "_siteId", "_resource"];
	private _site = BATTLESPACE_SAM_SITE_POOLS get _siteId;
	if (isNil "_site") exitWith {false};
	private _sector = _site getOrDefault ["Sector", ""];
	private _state = BATTLESPACE_SECTOR_STATES get _sector;
	if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {false};
	private _available = (_state getOrDefault ["resources", createHashMap]) getOrDefault [_resource, 0];
	private _batch = _available min (missionNamespace getVariable ["BATTLESPACE_SAM_RELOAD_BATCH", 4]);
	if (_batch <= 0 || {!([_sector, createHashMapFromArray [[_resource, -_batch]]] call BATTLESPACE_RESOURCE_APPLY_STRICT)}) exitWith {false};
	private _pools = _site get "Pools";
	_pools set [_resource, (_pools getOrDefault [_resource, 0]) + _batch];
	_site set ["Pools", _pools];
	BATTLESPACE_SAM_SITE_POOLS set [_siteId, _site];
	if (!isNull _vehicle && {alive _vehicle}) then {_vehicle setVehicleAmmoDef 1};
	true
};

BATTLESPACE_SAM_ON_FIRED = {
	params ["_vehicle", "_weapon", "_muzzle", "_mode", "_ammo"];
	if (!isServer) exitWith {};
	private _simulation = toLower getText (configFile >> "CfgAmmo" >> _ammo >> "simulation");
	if ((_simulation find "shotmissile") < 0) exitWith {};
	private _siteId = _vehicle getVariable ["BSASiteId", ""];
	private _resource = _vehicle getVariable ["BSAMissileResource", ""];
	private _site = BATTLESPACE_SAM_SITE_POOLS get _siteId;
	if (isNil "_site" || {_resource == ""}) exitWith {_vehicle setVehicleAmmoDef 0};
	private _pools = _site get "Pools";
	private _remaining = ((_pools getOrDefault [_resource, 0]) - 1) max 0;
	_pools set [_resource, _remaining];
	_site set ["Pools", _pools];
	BATTLESPACE_SAM_SITE_POOLS set [_siteId, _site];
	if (_remaining > 0) then {
		[{params ["_vehicle"]; if (!isNull _vehicle && {alive _vehicle}) then {_vehicle setVehicleAmmoDef 1}}, [_vehicle], 0.5] call CBA_fnc_waitAndExecute;
	} else {
		if !([_vehicle, _siteId, _resource] call BATTLESPACE_SAM_TRY_RELOAD) then {_vehicle setVehicleAmmoDef 0};
	};
};

BATTLESPACE_EVALUATE_AIRSPACE = {

	if(isNil "blufor_sectors") exitWith {};
	if !(missionNamespace getVariable ["BATTLESPACE_LOGISTICS_READY", false]) exitWith {};

	if((BATTLESPACE_SAM_LAST_SPAWN_TIME + BATTLESPACE_SAM_SPAWN_COOLDOWN) >= CBA_missionTime && BATTLESPACE_SAM_LAST_SPAWN_TIME > 0) exitWith {};
	diag_log format ["Battlespace Evaluating Airspace..."];
	if (BATTLESPACE_SAM_DEBUG) then {systemChat "Battlespace Evaluating Airspace...";};

	private _frontlineSectors = [blufor_sectors, 1] call NETWORKED_SECTORS_GET_SECTORS_UP_TO_COST;

	diag_log format ["Frontline Sectors %1", _frontlineSectors];
	if (BATTLESPACE_SAM_DEBUG) then {systemChat format ["Frontline Sectors %1", _frontlineSectors];};
	private _detected = "";

	private _procPos = [];

	private _sectorsDetected = [];
	{
		private _pos = getMarkerPos (_x#1);
		private _nearAir = _pos nearObjects ["Air", BATTLESPACE_SAM_PROC_RANGE];

		_nearAir = _nearAir select {

			(side (group _x)) == GRLIB_side_friendly
		};

		if((count _nearAir) > 0) then {

			_sectorsDetected pushBack (_x#1);

			_procPos = getPos (_nearAir select 0);
		};

	} forEach _frontlineSectors;
	if((count _sectorsDetected) > 0) then {
		_detected = selectRandom _sectorsDetected;
	};
	diag_log format ["Detected %1", _detected];
	if (BATTLESPACE_SAM_DEBUG) then {systemChat format ["Detected %1", _detected];};

	if(_detected != "") then {


		// evaluate for limit 
		if((count BATTLESPACE_SAM_EXISTING_SITES) >= BATTLESPACE_SAM_SITE_LIMIT) exitWith {};

		private _sectorToSpawnIn = "";
		
		private _spawnSectors = [blufor_sectors, 7] call NETWORKED_SECTORS_GET_SECTORS_UP_TO_COST;

		if(count _spawnSectors > 0) then {

			private _costToPullFrom = 7;

			while { _sectorToSpawnIn == "" && (count _spawnSectors) > 0 && _costToPullFrom >= 1 } do {

				private _validSectors = _spawnSectors select {
					(_x#0) == _costToPullFrom
				};

				private _invalids = _validSectors select {

					private _mPos = getMarkerPos (_x#1);

					(_mPos distance2D (getMarkerPos _detected)) > 7000
				};

				_validSectors = _validSectors - _invalids;

				_spawnSectors = _spawnSectors - _invalids;
				// TODO: Can make it more complex and save state of which sam site spawned at what sector
				// Evaluate that sector's cost
				// And then select a sector that is not at the existing sectors and do not skip if the frontline has shifted where there's different costs.
				// Skip to next available sectors so there's less chances of stacking sites
				if(count _validSectors < (1 + (count BATTLESPACE_SAM_EXISTING_SITES))) then {
					_costToPullFrom = _costToPullFrom - 1;
					_spawnSectors = _spawnSectors - _validSectors;
					continue;
				};

				_sectorToSpawnIn = (selectRandom _validSectors) select 1;

				
			};
		};


		
		// spawn 
		if(_sectorToSpawnIn == "") exitWith {
			if (BATTLESPACE_SAM_DEBUG) then {systemChat format ["Unable to find acceptable SAM Site spawn location; Sector %1 detected air", _detected];};
			diag_log format ["Unable to find acceptable SAM Site spawn location; Sector %1 detected air", _detected];
		};
		
		if (BATTLESPACE_SAM_DEBUG) then {systemChat format ["Spawning at %1", _sectorToSpawnIn];};
		private _unitsToSpawn = [];

		private _amountOfTel = BATTLESPACE_SAM_SITE_COMPOSITION get "TEL";

		private _amountOfFcrs = BATTLESPACE_SAM_SITE_COMPOSITION get "FCR";


		for "_i" from 1 to _amountOfTel do {

			_unitsToSpawn pushBack (selectRandom BATTLESPACE_SAM_SITE_TELS);
		};

		for "_i" from 1 to _amountOfFcrs do {
			_unitsToSpawn pushBack (selectRandom BATTLESPACE_SAM_SITE_FCRS);

			
		};

		_unitsToSpawn append (selectRandom BATTLESPACE_SAM_SITE_SHORAD);
		private _reservation = [_unitsToSpawn] call BATTLESPACE_SAM_BUILD_RESERVATION;
		private _debit = createHashMap;
		{_debit set [_x, -_y]} forEach _reservation;
		if !([_sectorToSpawnIn, _debit] call BATTLESPACE_RESOURCE_APPLY_STRICT) exitWith {
			diag_log format ["SAM site at %1 skipped because stock cannot fund %2", _sectorToSpawnIn, _reservation];
		};
		
		[
			{
				_this call BATTLESPACE_SAM_SITE_CREATE
			},
			[_unitsToSpawn, _sectorToSpawnIn, _procPos, _reservation],
			0
		] call CBA_fnc_waitAndExecute;
		
	};
};



BATTLESPACE_SAM_SITE_CREATE = {
	params ["_unitsToSpawn", "_sectorToSpawnIn", "_procPos", ["_reservation", createHashMap]];

	if (BATTLESPACE_SAM_DEBUG) then {systemChat format ["SAMs to spawn %1 in sector %2", _unitsToSpawn, _sectorToSpawnIn];};
	diag_Log format ["SAMs to spawn %1 in sector %2", _unitsToSpawn, _sectorToSpawnIn];

	private _newSite = createHashMap;
	private _siteId = str BATTLESPACE_SAM_SITE_AUTOINCREMENT;
	BATTLESPACE_SAM_SITE_AUTOINCREMENT = BATTLESPACE_SAM_SITE_AUTOINCREMENT + 1;
	private _sideEnemy = EAST;

	if(!isNil "GRLIB_side_enemy") then {
		_sideEnemy = GRLIB_side_enemy;
	};
	
	private _fcrGrp = createGroup [_sideEnemy, true];
	
	private _units = [];
	private _spawnedClasses = [];
	private _shorad = [];
	{{_shorad pushBackUnique _x} forEach _x} forEach BATTLESPACE_SAM_SITE_SHORAD;
	{
		private _className = _x;
		private _wantHouses = false;
		// Determine a sufficient spawn point
		if(!isNil "IADS_VLS") then {

			if(_className in IADS_VLS) then {
				_wantHouses = true;
			};
		};

		private _grp = _fcrGrp;
		
		private _expr = format ["hills - (10 * sea) %1", ["- (2 *houses)", "+ (2 * houses)"] select _wantHouses];
		private _expr2 = format ["meadow - (10 * sea) %1", ["- (2 *houses)", "+ (2 * houses)"] select _wantHouses];
		private _potentialSpawnPoints = selectBestPlaces [getMarkerPos _sectorToSpawnIn, 600, _expr, 40, 10];

		_potentialSpawnPoints = _potentialSpawnPoints + (selectBestPlaces [getMarkerPos _sectorToSpawnIn, 600, _expr2, 40, 20]);
		
		private _spawnPoint = nil;

		{
			_x params ["_pos", "_expr"];
			private _spawn = _pos findEmptyPosition [0, 125, _className];

			if(!(_spawn isEqualTo [])) exitWith {

				private _nearObjects = _spawn nearObjects ["LandVehicle", 100];

				_nearObjects = _nearObjects select {
					(side (group _x)) == _sideEnemy
				};

				if((count _nearObjects) > 0) then {
					continue;
				};
				diag_log format ["Spawning %1 at position %2, expr: %3", _className, _spawn, _expr];
				_spawnPoint = _spawn;
			};
		} forEach _potentialSpawnPoints;


		if(isNil "_spawnPoint") then {
			diag_log format ["Could not find a valid spawn point to spawn %1 at %2", _className, _sectorToSpawnIn];
			continue;
		};
		
		private _unit = _className createVehicle _spawnPoint;

		private _dir = _spawnPoint getDir _procPos;

		_unit setDir _dir;
		_unit setVariable ["BSAFundingSector", _sectorToSpawnIn, true];
		
		if(!isNil "KPLIB_fnc_addObjectInit") then {
			[_unit] call KPLIB_fnc_addObjectInit;
		};

		if(_className in BATTLESPACE_SAM_SITE_TELS) then {
			_grp = createGroup [_sideEnemy, true];
		};
		private _missileResource = "";
		if (_className in BATTLESPACE_SAM_SITE_TELS) then {_missileResource = "strategic_missiles"};
		if (_className in _shorad) then {_missileResource = "tactical_missiles"};
		if (_missileResource != "") then {
			_unit setVehicleAmmoDef 0;
			_unit setVariable ["BSASiteId", _siteId, true];
			_unit setVariable ["BSAMissileResource", _missileResource, true];
			_unit addEventHandler ["Fired", {_this call BATTLESPACE_SAM_ON_FIRED}];
		};
		private _crew = units (createVehicleCrew _unit);
		_crew joinSilent _grp;

		{ 
			_x setVariable ["Vcm_Disable", true, true];
			_x setVariable ["BSAFundingSector", _sectorToSpawnIn, true];
			_x addEventHandler ["Killed", {
				params ["_unit"];
				if (!isNil "BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE") then {
					[_unit getVariable ["BSAFundingSector", ""], 1] call BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE;
				};
				if (!isNil "KPLIB_fnc_queueDeadObjectCleanup") then {
					[_unit] call KPLIB_fnc_queueDeadObjectCleanup;
				};
			}];

			if(!(_className in BATTLESPACE_SAM_SITE_TELS) && !(_className in BATTLESPACE_SAM_SITE_FCRS)) then {
				_x disableAI "MOVE";
			};
		} forEach (_crew);
		
		
		

		_units pushBack _unit;
		_spawnedClasses pushBack _className;

		// Not MP because this is a server only matter
		_unit addEventHandler ["Killed", { ["SAM", _this] call BATTLESPACE_SAM_KILLED }];

	} forEach _unitsToSpawn;

	_newSite set ["Units", _units];
	_newSite set ["Sector", _sectorToSpawnIn];
	_newSite set ["Id", _siteId];
	private _actualReservation = [_spawnedClasses] call BATTLESPACE_SAM_BUILD_RESERVATION;
	private _refund = createHashMap;
	{
		private _difference = _y - (_actualReservation getOrDefault [_x, 0]);
		if (_difference > 0) then {_refund set [_x, _difference]};
	} forEach _reservation;
	if (count _refund > 0) then {[_sectorToSpawnIn, _refund] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED};
	private _pools = createHashMapFromArray [
		["strategic_missiles", _actualReservation getOrDefault ["strategic_missiles", 0]],
		["tactical_missiles", _actualReservation getOrDefault ["tactical_missiles", 0]]
	];
	private _poolState = createHashMapFromArray [["Sector", _sectorToSpawnIn], ["Pools", _pools]];
	BATTLESPACE_SAM_SITE_POOLS set [_siteId, _poolState];
	{
		private _resource = _x getVariable ["BSAMissileResource", ""];
		if (_resource != "") then {
			[
				{params ["_unit", "_siteId", "_resource"]; private _site = BATTLESPACE_SAM_SITE_POOLS get _siteId; if (!isNil "_site" && {((_site get "Pools") getOrDefault [_resource, 0]) > 0} && {alive _unit}) then {_unit setVehicleAmmoDef 1}},
				[_x, _siteId, _resource], 30
			] call CBA_fnc_waitAndExecute;
		};
	} forEach _units;


	if((count _units) > 0) then {
		if (BATTLESPACE_SAM_DEBUG) then {systemChat format ["pushback new SAM site %1", _units];};

		BATTLESPACE_SAM_EXISTING_SITES pushBack _newSite;

		BATTLESPACE_SAM_LAST_SPAWN_TIME = CBA_missionTime;
		[] call BATTLESPACE_LOGISTICS_SAVE;
	} else {
		BATTLESPACE_SAM_SITE_POOLS deleteAt _siteId;
	};
};

BATTLESPACE_SAM_KILLED = {
	params ["_type", "_event"];

	_event params ["_unit", "_killer", "_instigator", "_useEffects"];
	if (!isNil "BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE") then {
		[_unit getVariable ["BSAFundingSector", ""], 4] call BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE;
	};
	if (!isNil "KPLIB_fnc_queueDeadObjectCleanup") then {
		[_unit] call KPLIB_fnc_queueDeadObjectCleanup;
	};

	if(_type == "SAM") then {

		BATTLESPACE_SAM_EXISTING_SITES = BATTLESPACE_SAM_EXISTING_SITES select {
			
			private _units = _x getOrDefault ["Units",[]];
		private _deadCount = 0;
			{
				if(isNull _x || !(alive _x)) then {
					_deadCount = _deadCount + 1;
				};
			} forEach _units;
			private _aliveSite = _deadCount < (count _units);
			if (!_aliveSite) then {BATTLESPACE_SAM_SITE_POOLS deleteAt (_x getOrDefault ["Id", ""])};
			_aliveSite
		};

		if(isNil "BATTLESPACE_SAM_EXISTING_SITES") then {
			BATTLESPACE_SAM_EXISTING_SITES = [];
		};
		
	
	};
};


if(isServer && BATTLESPACE_ENABLE_SAM_SPAWNS) then {

	if (BATTLESPACE_USE_SAM_SPAWN_DELAY) then {
		BATTLESPACE_SAM_DELAY = [1800,5400] call BIS_fnc_randomInt;
	};

	BATTLESPACE_SAM_SPAWN_CHANCE_VALUE = random 1;
	diag_log format ["SAM Spawn Delay: %1", BATTLESPACE_SAM_DELAY];
	diag_log format ["SAM Spawn Chance: %1", BATTLESPACE_SAM_SPAWN_CHANCE_VALUE];
	
	[
		{
			!isNil "NETWORKED_SECTORS" && !isNil "NETWORKED_SECTORS_LINKED"
		},
		{
			[
				{
					// potential expensive computations due to traversing the networked sector graph to build in-depth costs, prevent server from freezing and dying while doing this.
					if (BATTLESPACE_SAM_SPAWN_CHANCE_VALUE <= BATTLESPACE_SAM_SPAWN_CHANCE) then {
						[{_this spawn BATTLESPACE_EVALUATE_AIRSPACE}, [], BATTLESPACE_SAM_DELAY] call CBA_fnc_waitAndExecute;
					};
				},
				300,
				[]
			] call CBA_fnc_addPerFrameHandler;
		},
		[]
	] call CBA_fnc_waitUntilAndExecute;
};
