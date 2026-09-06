BATTLESPACE_DISABLE_ARTILLERY = false;
BATTLESPACE_ARTILLERY_DEBUG = false;
BATTLESPACE_ARTILLERY_SECTIONS = [];
BATTLESPACE_ARTILLERY_OBSERVER_TARGETS = createHashMap;
if (isNil "BATTLESPACE_ARTILLERY_RENDER_DATA") then {
	BATTLESPACE_ARTILLERY_RENDER_DATA = [[], [], [true, 0, 0]];
};
BATTLESPACE_ARTILLERY_PIECE_CLASSES = [];
BATTLESPACE_ARTILLERY_PIECES_PER_BATTERY = 2;
BATTLESPACE_ARTILLERY_SPAWN_COOLDOWN = 3600;
BATTLESPACE_LAST_ARTILLERY_SPAWN = -BATTLESPACE_ARTILLERY_SPAWN_COOLDOWN;
BATTLESPACE_ARTILLERY_MIN_SUPPRESSION_TIME_PER_SHELL = 50;
BATTLESPACE_ARTILLERY_MAX_SUPPRESSION_TIME_PER_SHELL = 75;

BATTLESPACE_ARTILLERY_RESOLVE_AMMUNITION = {
	params [["_vehicle", objNull, [objNull]]];
	if (isNull _vehicle) exitWith {["", "", []]};

	private _available = getArtilleryAmmo [_vehicle];
	private _heShell = "";
	private _heScore = -1;
	private _smokeShell = "";
	private _smokeScore = -1;

	{
		private _magazine = _x;
		private _magazineCfg = configFile >> "CfgMagazines" >> _magazine;
		if !(isClass _magazineCfg) then {continue};

		private _ammoClass = getText (_magazineCfg >> "ammo");
		private _ammoCfg = configFile >> "CfgAmmo" >> _ammoClass;
		if !(isClass _ammoCfg) then {continue};

		private _description = toLower format [
			"%1 %2 %3",
			_magazine,
			getText (_magazineCfg >> "displayName"),
			_ammoClass
		];
		private _usageFlags = getNumber (_ammoCfg >> "aiAmmoUsageFlags");
		private _hasConcealmentFlag = ((floor (_usageFlags / 4)) mod 2) == 1;
		private _hasWPName = (_description find "phosph") >= 0 || {(_description find "_wp") >= 0} || {(_description find "mmwp") >= 0} || {(_description find " wp") >= 0};
		private _hasSmokeName = (_description find "smoke") >= 0;
		// effectsSmoke is a visual projectile effect and is also configured on HE rounds.
		private _isSmoke = _hasConcealmentFlag || _hasWPName || _hasSmokeName;
		private _isIllumination = (_description find "illum") >= 0 || {(_description find "flare") >= 0};
		private _isGuided = (_description find "guided") >= 0 || {(_description find "laser") >= 0} || {(_description find "_lg") >= 0} || {(_description find "mmlg") >= 0};
		private _isAntiTank = (_description find "anti-tank") >= 0 || {(_description find "_at_") >= 0} || {(_description find "mmat_") >= 0} || {(_description find " at ") >= 0};
		private _indirectHit = getNumber (_ammoCfg >> "indirectHit");
		private _indirectHitRange = getNumber (_ammoCfg >> "indirectHitRange");

		if (_isSmoke) then {
			private _candidateScore = 100;
			if (_hasConcealmentFlag) then {_candidateScore = _candidateScore + 25};
			if (_hasSmokeName) then {_candidateScore = _candidateScore + 100};
			if (_hasWPName) then {_candidateScore = _candidateScore + 200};
			if (_candidateScore > _smokeScore) then {
				_smokeScore = _candidateScore;
				_smokeShell = _magazine;
			};
		};

		if ((_indirectHit > 0 || {_indirectHitRange > 0}) && {!_isSmoke} && {!_isIllumination} && {!_isGuided} && {!_isAntiTank}) then {
			private _hasHEName = (_description find "high explosive") >= 0 || {(_description find "_he") >= 0} || {(_description find "mmhe") >= 0} || {(_description find " he ") >= 0};
			private _candidateScore = _indirectHit + (5 * _indirectHitRange);
			if (_hasHEName) then {_candidateScore = _candidateScore + 10000};
			if (_candidateScore > _heScore) then {
				_heScore = _candidateScore;
				_heShell = _magazine;
			};
		};
	} forEach _available;

	[_heShell, _smokeShell, _available]
};

BATTLESPACE_ARTILLERY_GET_AI_FIRE_RANGES = {
	params ["_piece", "_shellType"];
	private _weapons = weapons _piece;
	private _cached = _piece getVariable ["BSAFireRanges", []];
	if (count _cached == 3 && {(_cached select 0) isEqualTo _weapons} && {(_cached select 1) == _shellType}) exitWith {_cached select 2};

	private _ranges = [];
	{
		if !(_shellType in compatibleMagazines _x) then {continue};
		private _weaponCfg = configFile >> "CfgWeapons" >> _x;
		{
			private _modeCfg = _weaponCfg >> _x;
			private _minimum = getNumber (_modeCfg >> "minRange");
			private _maximum = getNumber (_modeCfg >> "maxRange");
			if (getNumber (_modeCfg >> "artilleryCharge") > 0 && {_maximum > _minimum}) then {
				_ranges pushBackUnique [_minimum, _maximum];
			};
		} forEach getArray (_weaponCfg >> "modes");
	} forEach _weapons;
	_piece setVariable ["BSAFireRanges", [_weapons, _shellType, _ranges]];
	_ranges
};

BATTLESPACE_ARTILLERY_CAN_REACH_AREA = {
	params [
		["_piece", objNull, [objNull]],
		["_targetPos", [], [[]]],
		["_shellType", "", [""]],
		["_margin", 0, [0]]
	];
	if (isNull _piece || {_targetPos isEqualTo []} || {_shellType == ""}) exitWith {false};
	private _aiRanges = [_piece, _shellType] call BATTLESPACE_ARTILLERY_GET_AI_FIRE_RANGES;

	private _testPositions = [+_targetPos];
	if (_margin > 0) then {
		for "_bearing" from 0 to 315 step 45 do {
			_testPositions pushBack (_targetPos getPos [_margin, _bearing]);
		};
	};

	(_testPositions findIf {
		private _position = _x;
		private _distance = _piece distance2D _position;
		// The ballistic envelope can exceed the distances accepted by the weapon's AI modes.
		(_aiRanges findIf {_distance >= (_x select 0) && {_distance <= (_x select 1)}}) == -1
			|| {!(_position inRangeOfArtillery [[_piece], _shellType])}
	}) == -1
};

BATTLESPACE_ARTILLERY_GET_ROCKET_RIPPLE = {
	params [["_shellType", "", [""]]];
	private _magazineCapacity = getNumber (configFile >> "CfgMagazines" >> _shellType >> "count");
	if (_magazineCapacity <= 0) exitWith {[1, 1]};

	private _rippleSize = 5 min _magazineCapacity;
	if ((_magazineCapacity mod 6) == 0) then {
		_rippleSize = 3 min _magazineCapacity;
	};
	[_rippleSize max 1, _magazineCapacity]
};
// Base cooldown for a counter battery request to be generated.
// Base, because high readiness will tick faster.
// See POLL_REQUESTS function to further balance
BATTLESPACE_ARTILLERY_COUNTER_BATTERY_BASE_COOLDOWN = 0;
BATTLESPACE_ARTILLERY_BASE_ACCURACY_BUILDUP = 9;

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

	private _nearbyArty = _impactLocation nearEntities [BATTLESPACE_ARTILLERY_PIECE_CLASSES, 200];

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

BATTLESPACE_ARTILLERY_GET_REQUEST_SALVOS = {
	params ["_request"];
	_request params [["_observer", objNull], ["_target", nil], ["_accuracy", 0], ["_systemTargeted", false], ["_targetedAt", CBA_missionTime], ["_wp", false]];
	private _salvos = 1 max (floor (_accuracy / 75));
	if (_accuracy >= 300) then {_salvos = 6};
	if (_wp) then {_salvos = _salvos max 3};
	if (_systemTargeted) then {
		_salvos = 6;
		if (_accuracy >= 300) then {_salvos = 12};
	};
	_salvos
};

BATTLESPACE_ARTILLERY_RESERVE_AMMUNITION = {
	params ["_battery", "_requestedRounds"];
	private _sector = _battery getVariable ["BSAFundingSector", ""];
	private _state = BATTLESPACE_SECTOR_STATES get _sector;
	if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {0};
	private _available = (_state getOrDefault ["resources", createHashMap]) getOrDefault ["rockets", 0];
	private _reserved = (round _requestedRounds) max 0 min _available;
	if (_reserved <= 0) exitWith {0};
	if !([_sector, createHashMapFromArray [["rockets", -_reserved]]] call BATTLESPACE_RESOURCE_APPLY_STRICT) exitWith {0};
	_reserved
};

BATTLESPACE_SPAWN_BATTERY = {
	params ["_target"];

	if (BATTLESPACE_DISABLE_ARTILLERY) exitWith {};
	if !(missionNamespace getVariable ["BATTLESPACE_LOGISTICS_READY", false]) exitWith {};

	if((diag_tickTime - BATTLESPACE_LAST_ARTILLERY_SPAWN) < BATTLESPACE_ARTILLERY_SPAWN_COOLDOWN ) exitWith {};
	if((count BATTLESPACE_ARTILLERY_SECTIONS) >= 2) exitWith {};
	if (BATTLESPACE_ARTILLERY_PIECE_CLASSES isEqualTo []) exitWith {
		BATTLESPACE_DISABLE_ARTILLERY = true;
		["Artillery battery spawn disabled (reason=generated artillery pool is empty)", "BATTLESPACE"] call KPLIB_fnc_log;
	};

	private _targetPos = _target getPos [0, 0];
	private _pieceClass = selectRandom BATTLESPACE_ARTILLERY_PIECE_CLASSES;
	private _pieceResource = [_pieceClass] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS;
	if !(_pieceResource in ["rocket_artillery", "howitzers", "mortars"]) then {_pieceResource = "howitzers"};
	private _targetRangeMargin = [400, 600] select (_pieceResource == "rocket_artillery");
	private _siteRangeMargin = _targetRangeMargin + 200;
	private _rangeProbe = _pieceClass createVehicle [0, 0, 1000];
	if (isNull _rangeProbe) exitWith {
		BATTLESPACE_ARTILLERY_PIECE_CLASSES = BATTLESPACE_ARTILLERY_PIECE_CLASSES - [_pieceClass];
		BATTLESPACE_DISABLE_ARTILLERY = BATTLESPACE_ARTILLERY_PIECE_CLASSES isEqualTo [];
		[format ["Artillery battery spawn rejected (pieceClass=%1, reason=range probe creation failed, remainingPool=%2)", _pieceClass, BATTLESPACE_ARTILLERY_PIECE_CLASSES], "BATTLESPACE"] call KPLIB_fnc_log;
	};
	_rangeProbe allowDamage false;
	_rangeProbe hideObjectGlobal true;
	_rangeProbe setVehicleAmmoDef 1;
	private _rangeProbeGroup = createVehicleCrew _rangeProbe;
	{_x allowDamage false; _x hideObjectGlobal true} forEach crew _rangeProbe;
	private _cleanupRangeProbe = {
		if (!isNull _rangeProbeGroup) then {_rangeProbeGroup deleteGroupWhenEmpty true};
		if (!isNull _rangeProbe) then {
			{_rangeProbe deleteVehicleCrew _x} forEach crew _rangeProbe;
			deleteVehicle _rangeProbe;
		};
		if (!isNull _rangeProbeGroup) then {deleteGroup _rangeProbeGroup};
	};
	sleep 0.1;
	if ((crew _rangeProbe) isEqualTo [] || {isNull gunner _rangeProbe}) exitWith {
		call _cleanupRangeProbe;
		BATTLESPACE_ARTILLERY_PIECE_CLASSES = BATTLESPACE_ARTILLERY_PIECE_CLASSES - [_pieceClass];
		BATTLESPACE_DISABLE_ARTILLERY = BATTLESPACE_ARTILLERY_PIECE_CLASSES isEqualTo [];
		[format ["Artillery battery spawn rejected (pieceClass=%1, reason=configured crew did not occupy range probe gunner seat, remainingPool=%2)", _pieceClass, BATTLESPACE_ARTILLERY_PIECE_CLASSES], "BATTLESPACE"] call KPLIB_fnc_log;
	};
	([_rangeProbe] call BATTLESPACE_ARTILLERY_RESOLVE_AMMUNITION) params ["_probeHE", "_probeWP", "_probeAvailable"];
	if (_probeHE == "") exitWith {
		call _cleanupRangeProbe;
		BATTLESPACE_ARTILLERY_PIECE_CLASSES = BATTLESPACE_ARTILLERY_PIECE_CLASSES - [_pieceClass];
		BATTLESPACE_DISABLE_ARTILLERY = BATTLESPACE_ARTILLERY_PIECE_CLASSES isEqualTo [];
		[format ["Artillery battery spawn rejected (pieceClass=%1, reason=no usable HE magazine, artilleryAmmo=%2, remainingPool=%3)", _pieceClass, _probeAvailable, BATTLESPACE_ARTILLERY_PIECE_CLASSES], "BATTLESPACE"] call KPLIB_fnc_log;
	};
	[format ["Artillery range probe ready (pieceClass=%1, crew=%2, HE=%3, artilleryAmmo=%4, aiFireRanges=%5)", _pieceClass, count crew _rangeProbe, _probeHE, _probeAvailable, [_rangeProbe, _probeHE] call BATTLESPACE_ARTILLERY_GET_AI_FIRE_RANGES], "BATTLESPACE"] call KPLIB_fnc_log;
	
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

				private _nearbyArty = _mPos nearEntities [BATTLESPACE_ARTILLERY_PIECE_CLASSES + BATTLESPACE_SAM_SITE_TELS + BATTLESPACE_SAM_SITE_FCRS, 1000];

				_nearbyArty = _nearbyArty select { alive _x };

				_alreadyHasArty = (count _nearbyArty) > 0;
				private _hasCandidateRange = false;
				private _candidateSourcePositions = [_mPos];
				for "_bearing" from 0 to 315 step 45 do {
					_candidateSourcePositions pushBack (_mPos getPos [600, _bearing]);
				};
				{
					_rangeProbe setPosATL _x;
					if ([_rangeProbe, _targetPos, _probeHE, 0] call BATTLESPACE_ARTILLERY_CAN_REACH_AREA) exitWith {
						_hasCandidateRange = true;
					};
				} forEach _candidateSourcePositions;

				!_hasCandidateRange || _alreadyHasArty
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
		call _cleanupRangeProbe;
		if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat "Unable to find sector to spawn artillery for";};
		[format ["Artillery battery spawn skipped (pieceClass=%1, shell=%2, target=%3, reason=no eligible sector inside weapon range)", _pieceClass, _probeHE, _targetPos], "BATTLESPACE"] call KPLIB_fnc_log;
	};
	private _wantHouses = false;
	private _expr = format ["4 * hills - (10 * sea) - (3 * houses) - (2 * trees) - (4 * forest)"];
	private _expr2 = format ["4 * meadow - (10 * sea)  - (3 * houses) - (2 * trees) - (4 * forest)"];
	private _potentialSpawnPoints = selectBestPlaces [getMarkerPos _sectorToSpawnIn, 600, _expr, 40, 10];

	_potentialSpawnPoints = _potentialSpawnPoints + (selectBestPlaces [getMarkerPos _sectorToSpawnIn, 600, _expr2, 40, 20]);

	
	private _sideEnemy = GRLIB_side_enemy;

	private _spawnPoint = nil;

	{
		_x params ["_pos", "_expr"];
		private _spawn = _pos findEmptyPosition [0, 125, _pieceClass];
		if (_spawn isEqualTo []) then {continue};

		_rangeProbe setPosATL _spawn;
		if ([_rangeProbe, _targetPos, _probeHE, _siteRangeMargin] call BATTLESPACE_ARTILLERY_CAN_REACH_AREA) exitWith {
			_spawnPoint = _spawn;
		};
	} forEach _potentialSpawnPoints;

	if(isNil "_spawnPoint") exitWith {
		call _cleanupRangeProbe;
		if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat format ["Could not find a valid spawn point for %1", _pieceClass];};
		[format ["Artillery battery spawn skipped (sector=%1, pieceClass=%2, shell=%3, targetDistance=%4, rangeMargin=%5, reason=no clear in-range spawn point)", _sectorToSpawnIn, _pieceClass, _probeHE, round ((getMarkerPos _sectorToSpawnIn) distance2D _targetPos), _siteRangeMargin], "BATTLESPACE"] call KPLIB_fnc_log;
	};
	private _crewPerPiece = missionNamespace getVariable ["BATTLESPACE_ARTILLERY_CREW_PER_PIECE", 3];
	private _batteryCost = createHashMapFromArray [
		[_pieceResource, BATTLESPACE_ARTILLERY_PIECES_PER_BATTERY],
		["manpower", BATTLESPACE_ARTILLERY_PIECES_PER_BATTERY * _crewPerPiece]
	];
	private _batteryDebit = createHashMap;
	{_batteryDebit set [_x, -_y]} forEach _batteryCost;
	if !([_sectorToSpawnIn, _batteryDebit] call BATTLESPACE_RESOURCE_APPLY_STRICT) exitWith {
		call _cleanupRangeProbe;
		[format ["Artillery battery spawn skipped (sector=%1, pieceClass=%2, reason=insufficient stock, cost=%3)", _sectorToSpawnIn, _pieceClass, _batteryCost], "BATTLESPACE"] call KPLIB_fnc_log;
	};
	private _fcrGrp = createGroup [_sideEnemy, true];
	private _vehs = [];
	private _heShell = "";
	private _wpShell = "";
	private _availableShells = [];
	private _ammunitionValidated = false;
	private _ammunitionRejected = false;
	private _rangeRejectedPieces = 0;

	
	for "_i" from 1 to BATTLESPACE_ARTILLERY_PIECES_PER_BATTERY do {
		if (_ammunitionRejected) then {continue};

		private _spawn = _spawnPoint findEmptyPosition [10, 200, _pieceClass];
		if (_spawn isEqualTo []) then {continue};
		_rangeProbe setPosATL _spawn;
		private _canCoverTargetArea = [_rangeProbe, _targetPos, _probeHE, _targetRangeMargin] call BATTLESPACE_ARTILLERY_CAN_REACH_AREA;
		_rangeProbe setPosATL [0, 0, 1000];
		if (!_canCoverTargetArea) then {
			_rangeRejectedPieces = _rangeRejectedPieces + 1;
			continue;
		};
		
		private _newVeh = _pieceClass createVehicle _spawn;
		if (!_ammunitionValidated) then {
			([_newVeh] call BATTLESPACE_ARTILLERY_RESOLVE_AMMUNITION) params ["_resolvedHE", "_resolvedWP", "_resolvedAvailable"];
			_heShell = _resolvedHE;
			_wpShell = _resolvedWP;
			_availableShells = _resolvedAvailable;
			_ammunitionValidated = true;
			if (_heShell == "") then {
				_ammunitionRejected = true;
				deleteVehicle _newVeh;
			};
		};
		if (_ammunitionRejected) then {continue};


		_vehs pushBack _newVeh;

		_newVeh setVehicleAmmoDef 0;
		_newVeh setVariable ["BSAFundingSector", _sectorToSpawnIn, true];
		[_newVeh, "Killed", {
			params ["_vehicle"];
			if (!isNil "BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE") then {
				[_vehicle getVariable ["BSAFundingSector", ""], 4] call BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE;
			};
			if (!isNil "KPLIB_fnc_queueDeadObjectCleanup") then {
				[_vehicle] call KPLIB_fnc_queueDeadObjectCleanup;
			};
		}] call CBA_fnc_addBISEventHandler;

		private _crew = units (createVehicleCrew _newVeh);
		_crew joinSilent _fcrGrp;
		_newVeh disableAI "FSM";
		_newVeh disableAI "AUTOTARGET";
		{
			_x setUnitCombatMode "BLUE";
			_x disableAI "FSM";
			_x disableAI "AUTOTARGET";
			_x setVariable ["BSAFundingSector", _sectorToSpawnIn, true];
			[_x, "Killed", {
				params ["_unit"];
				if (!isNil "BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE") then {
					[_unit getVariable ["BSAFundingSector", ""], 1] call BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE;
				};
				if (!isNil "KPLIB_fnc_queueDeadObjectCleanup") then {
					[_unit] call KPLIB_fnc_queueDeadObjectCleanup;
				};
			}] call CBA_fnc_addBISEventHandler;

		} forEach _crew;

		sleep 1;

		
	};
	call _cleanupRangeProbe;
	if (_ammunitionRejected) exitWith {
		BATTLESPACE_ARTILLERY_PIECE_CLASSES = BATTLESPACE_ARTILLERY_PIECE_CLASSES - [_pieceClass];
		BATTLESPACE_DISABLE_ARTILLERY = BATTLESPACE_ARTILLERY_PIECE_CLASSES isEqualTo [];
		[_sectorToSpawnIn, _batteryCost] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
		deleteGroup _fcrGrp;
		[format ["Artillery battery rejected (sector=%1, pieceClass=%2, reason=no usable HE magazine, artilleryAmmo=%3, remainingPool=%4)", _sectorToSpawnIn, _pieceClass, _availableShells, BATTLESPACE_ARTILLERY_PIECE_CLASSES], "BATTLESPACE"] call KPLIB_fnc_log;
	};
	private _missingPieces = (BATTLESPACE_ARTILLERY_PIECES_PER_BATTERY - count _vehs) max 0;
	if (_missingPieces > 0) then {
		[_sectorToSpawnIn, createHashMapFromArray [
			[_pieceResource, _missingPieces],
			["manpower", _missingPieces * _crewPerPiece]
		]] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
	};
	if (_vehs isEqualTo []) exitWith {
		deleteGroup _fcrGrp;
		[format ["Artillery battery spawn skipped (sector=%1, pieceClass=%2, shell=%3, targetDistance=%4, rangeMargin=%5, rejectedPieces=%6, reason=no final piece position can cover target area)", _sectorToSpawnIn, _pieceClass, _heShell, round (_spawnPoint distance2D _targetPos), _targetRangeMargin, _rangeRejectedPieces], "BATTLESPACE"] call KPLIB_fnc_log;
	};
	_fcrGrp setVariable ["BSAState", ["READY", 0, getPos ((units _fcrGrp)#0)], true];
	_fcrGrp setVariable ["BSAFundingSector", _sectorToSpawnIn, true];
	_fcrGrp setVariable ["BSAPieceResource", _pieceResource, true];
	_fcrGrp setVariable ["BSAHEShell", _heShell, true];
	_fcrGrp setVariable ["BSAWPShell", _wpShell, true];
	_fcrGrp setVariable ["Vcm_Disable", true, true];
	BATTLESPACE_ARTILLERY_SECTIONS pushBack _fcrGrp;
	[format ["Artillery battery registered (group=%1, sector=%2, pieceClass=%3, resource=%4, pieces=%5, crew=%6, HE=%7, WP=%8, artilleryAmmo=%9, targetDistance=%10, rangeMargin=%11, rejectedPieces=%12)", _fcrGrp, _sectorToSpawnIn, _pieceClass, _pieceResource, count _vehs, count units _fcrGrp, _heShell, _wpShell, _availableShells, round (_spawnPoint distance2D _targetPos), _targetRangeMargin, _rangeRejectedPieces], "BATTLESPACE"] call KPLIB_fnc_log;


	
	

	BATTLESPACE_LAST_ARTILLERY_SPAWN = diag_tickTime;
	[] call BATTLESPACE_LOGISTICS_SAVE;
};

BATTLESPACE_ARTILLERY_GET_READY_BATTERIES = {
	private _readyBatteries = [];
	private _invalids = [];
	{
		private _state = _x getVariable ["BSAState", []];

		private _vehs = [];

		{
			private _veh = (vehicle _x);

			if(!alive _x || {_veh isEqualTo _x} || {!alive _veh}) then {
				continue;
			};

			_vehs pushBackUnique _veh;
		} forEach (units _x);

		if((count _vehs) <= 0) then {
			[format ["Artillery battery removed (group=%1, sector=%2, reason=no living crewed pieces)", _x, _x getVariable ["BSAFundingSector", ""]], "BATTLESPACE"] call KPLIB_fnc_log;
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
	_readyBatteries;
};
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\artillery\trp.sqf";

BATTLESPACE_ARTILLERY_POLL_REQUESTS = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    call BATTLESPACE_TRP_PLAN;
	(_this select 0) params [["_nextTick", 0], ["_counter", 0], ["_cycleCount", 0], ["_nextCycleSwap", 0], ["_networkEnabled", true]];


	if(CBA_missionTime < _nextTick) exitWith {};
	if (_nextCycleSwap <= 0) then {
		_nextCycleSwap = BATTLESPACE_ARTILLERY_MINIMUM_CYCLES_TO_SWAP + floor (random (BATTLESPACE_ARTILLERY_MAXIMUM_CYCLES_TO_SWAP - BATTLESPACE_ARTILLERY_MINIMUM_CYCLES_TO_SWAP));
		_cycleCount = -1;
		(_this select 0) set [3, _nextCycleSwap];
		(_this select 0) set [4, _networkEnabled];
		BATTLESPACE_ARTILLERY_CYCLES_REQUIRED = _nextCycleSwap;
		BATTLESPACE_ARTILLERY_NETWORK_ENABLED = _networkEnabled;
		[format ["Artillery observer network initialized (enabled=%1, window=%2 seconds)", _networkEnabled, _nextCycleSwap * BATTLESPACE_ARTILLERY_POLL_COOLDOWN], "BATTLESPACE"] call KPLIB_fnc_log;
	};

	

	private _newNetworkEnabled = _networkEnabled;
	BATTLESPACE_ARTILLERY_CURRENT_CYCLE = _cycleCount + 1;

	(_this select 0) set [2, BATTLESPACE_ARTILLERY_CURRENT_CYCLE];
	if(BATTLESPACE_ARTILLERY_CURRENT_CYCLE >= _nextCycleSwap) then {
		_newNetworkEnabled = !_networkEnabled;
		private _nextSwap = BATTLESPACE_ARTILLERY_MINIMUM_CYCLES_TO_SWAP + floor (random (BATTLESPACE_ARTILLERY_MAXIMUM_CYCLES_TO_SWAP - BATTLESPACE_ARTILLERY_MINIMUM_CYCLES_TO_SWAP));
		(_this select 0) set [2, 0];
		(_this select 0) set [3, _nextSwap];
		(_this select 0) set [4, _newNetworkEnabled];
		BATTLESPACE_ARTILLERY_CURRENT_CYCLE = 0;
		BATTLESPACE_ARTILLERY_CYCLES_REQUIRED = _nextSwap;
		BATTLESPACE_ARTILLERY_NETWORK_ENABLED = _newNetworkEnabled;
		if ((count BATTLESPACE_ARTILLERY_OBSERVER_TARGETS) > 0) then {
			[format ["Artillery observer network toggled (enabled=%1, nextWindow=%2 seconds, activeTargets=%3)", _newNetworkEnabled, _nextSwap * BATTLESPACE_ARTILLERY_POLL_COOLDOWN, count BATTLESPACE_ARTILLERY_OBSERVER_TARGETS], "BATTLESPACE"] call KPLIB_fnc_log;
		};
	};

	

	private _lowPop = ([] call KPLIB_fnc_getPlayerCount) <= 20;
	private _pollCooldown = BATTLESPACE_ARTILLERY_POLL_COOLDOWN;
	

	private _counterBatteryMultiplier = 1;

	if(combat_readiness < 75) then {
		_counterBatteryMultiplier = 0.5;
	};

	if(combat_readiness >= 125) then {
		_counterBatteryMultiplier = 1.5;
	};
	

	
	
	BATTLESPACE_ARTILLERY_NEXT_TICK_TIME = CBA_missionTime + _pollCooldown;
	(_this select 0) set [0, BATTLESPACE_ARTILLERY_NEXT_TICK_TIME];

	(_this select 0) set [1, _counter + _pollCooldown * _counterBatteryMultiplier];
	

	BATTLESPACE_ARTILLERY_COUNTER_BATTERY_TIMER = _counter;

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
				
				[_location, objNull, 250, true, CBA_missionTime] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_TARGET", 2]; 
				// Clear all entries up to and including _right

				
				BATTLESPACE_ARTILLERY_FIRING_LOCATIONS deleteRange [0, _right + 1];
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
        private _currentHighestPriority = 0;
		private _section = _x;
		{
            private _candidate = [_section, _y] call BATTLESPACE_TRP_PREPARE_REQUEST;
            _candidate params ["_observer", "_target", "_timeInCombat", ["_systemTargeted", false], ["_targetedAt", CBA_missionTime], ["_wp", false]];

			// Out of range, arbitrary value
			if(_target distance2D (leader _section) >= 17000) then {
				if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat "Too far";};
				continue
			};
			private _requestShell = _section getVariable ["BSAHEShell", ""];
			if (_wp) then {_requestShell = _section getVariable ["BSAWPShell", ""]};
			if (_requestShell == "") then {_requestShell = _section getVariable ["BSAHEShell", ""]};
			// Ready batteries are unloaded, so check AI mode limits without an ammunition-dependent engine query.
			if ((units _section findIf {
				private _piece = vehicle _x;
				private _distance = _piece distance2D _target;
				alive _piece && {_piece isNotEqualTo _x} && {
					([_piece, _requestShell] call BATTLESPACE_ARTILLERY_GET_AI_FIRE_RANGES) findIf {
						_distance >= (_x select 0) && {_distance <= (_x select 1)}
					} != -1
				}
			}) == -1) then {continue};

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
                _currentHighestAccuracyRequest = _candidate;
				_currentHighestAccuracyKey = _x;
			};

            private _priority = _timeInCombat;
            if ((_candidate param [9, []]) isNotEqualTo []) then {_priority = _priority + BATTLESPACE_ARTILLERY_TRP_PRIORITY_BONUS};
            if (!_systemTargeted && {_timeInCombat > 0} && {_priority > _currentHighestPriority}) then {
                _currentHighestPriority = _priority;
                _currentHighestAccuracyRequest = _candidate;
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
    if (!isServer || {isRemoteExecuted}) exitWith {};
    _this params ["_battery", "_req", "_obsKey"];
    _req = +_req;
    if !([_battery, _req] call BATTLESPACE_TRP_MISSION_VALID) exitWith {};
	
	(_req) params [["_observer", objNull], ["_target", nil], ["_accuracy", 0], ["_systemTargeted", false], ["_targetedAt", CBA_missionTime], ["_wp", false]];

	private _state = _battery getVariable ["BSAState", []];
	

	_state params [["_status", "NOT READY"], ["_initialSetupTime", 0], ["_loc", []], ["_tgt", objNull], ["_acc", 0], ["_obs", objNull]];

	if(_status != "READY") exitWith { };
	private _vehicles = [];
	{
		private _vehicle = vehicle _x;
		if (_vehicle isNotEqualTo _x && {alive _vehicle}) then {_vehicles pushBackUnique _vehicle};
	} forEach units _battery;
	if (_vehicles isEqualTo []) exitWith {};
	private _heShell = _battery getVariable ["BSAHEShell", ""];
	private _wpShell = _battery getVariable ["BSAWPShell", ""];
	if (_heShell == "") exitWith {
		if !(_battery getVariable ["BSAAmmoFailureLogged", false]) then {
			_battery setVariable ["BSAAmmoFailureLogged", true];
			[format ["Artillery request rejected (group=%1, sector=%2, reason=battery has no resolved HE magazine)", _battery, _battery getVariable ["BSAFundingSector", ""]], "BATTLESPACE"] call KPLIB_fnc_log;
		};
	};
	if (_wp && {_wpShell == ""}) then {
		_wp = false;
		_req set [5, false];
		[format ["Artillery smoke request converted to HE (group=%1, sector=%2, pieceClass=%3, reason=no compatible smoke/WP magazine)", _battery, _battery getVariable ["BSAFundingSector", ""], typeOf (_vehicles select 0)], "BATTLESPACE"] call KPLIB_fnc_log;
	};
	private _shellType = [_heShell, _wpShell] select _wp;
	private _salvos = [_req] call BATTLESPACE_ARTILLERY_GET_REQUEST_SALVOS;
	if ((_battery getVariable ["BSAPieceResource", ""]) == "rocket_artillery") then {
		([_shellType] call BATTLESPACE_ARTILLERY_GET_ROCKET_RIPPLE) params ["_minimumRipple"];
		_salvos = _salvos max _minimumRipple;
	};
	private _requestedRounds = _salvos * count _vehicles;
	private _reservedRounds = [_battery, _requestedRounds] call BATTLESPACE_ARTILLERY_RESERVE_AMMUNITION;
	if (_reservedRounds <= 0) exitWith {
		if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat format ["Battery %1 has no paid ammunition", _battery]};
		if !(_battery getVariable ["BSANoPaidAmmoLogged", false]) then {
			_battery setVariable ["BSANoPaidAmmoLogged", true];
			[format ["Artillery battery awaiting ammunition (group=%1, sector=%2, requested=%3 rockets)", _battery, _battery getVariable ["BSAFundingSector", ""], _requestedRounds], "BATTLESPACE"] call KPLIB_fnc_log;
		};
	};
	_battery setVariable ["BSANoPaidAmmoLogged", false];
	{_x setVehicleAmmoDef 1} forEach _vehicles;
	private _readyVehicles = _vehicles select {canFire _x && {_shellType in getArtilleryAmmo [_x]}};
	if (_readyVehicles isEqualTo []) exitWith {
		{_x setVehicleAmmoDef 0} forEach _vehicles;
		[_battery getVariable ["BSAFundingSector", ""], createHashMapFromArray [["rockets", _reservedRounds]]] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
		[format ["Artillery battery removed (group=%1, sector=%2, shell=%3, reason=no compatible fire-capable pieces after paid reload)", _battery, _battery getVariable ["BSAFundingSector", ""], _shellType], "BATTLESPACE"] call KPLIB_fnc_log;
		BATTLESPACE_ARTILLERY_SECTIONS = BATTLESPACE_ARTILLERY_SECTIONS - [_battery];
	};
	private _usableReservation = _reservedRounds min (_salvos * count _readyVehicles);
	private _immediateRefund = _reservedRounds - _usableReservation;
	if (_immediateRefund > 0) then {
		[_battery getVariable ["BSAFundingSector", ""], createHashMapFromArray [["rockets", _immediateRefund]]] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
	};
	{if !(_x in _readyVehicles) then {_x setVehicleAmmoDef 0}} forEach _vehicles;
	_req set [6, _usableReservation];
	_req set [7, _shellType];
	_req set [8, _salvos];

    private _trpMetadata = _req param [9, []];
    _battery setVariable ["BSATRP", _trpMetadata param [0, ""]];
    _battery setVariable ["BSAAimAccuracy", _trpMetadata param [1, _accuracy]];
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

	private _fireControlChecks = _readyVehicles apply {
		[typeOf _x, local _x, round (_target distance2D _x), [_x, _target getPos [0,0], _shellType] call BATTLESPACE_ARTILLERY_CAN_REACH_AREA, unitCombatMode (gunner _x)]
	};
	[format ["Artillery mission accepted (group=%1, sector=%2, type=%3, shell=%4, pieces=%5, rounds=%6, checks[class,local,distance,inRange,gunnerMode]=%7)", _battery, _battery getVariable ["BSAFundingSector", ""], ["HE", "WP/SMOKE"] select _wp, _shellType, count _readyVehicles, _usableReservation, _fireControlChecks], "BATTLESPACE"] call KPLIB_fnc_log;
	[_battery, _req, _obsKey] spawn BATTLESPACE_ARTILLERY_DO_REQUEST;

};
BATTLESPACE_ARTILLERY_DO_REQUEST = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
	params ["_battery", "_req", "_obsKey"];

	(_req) params [["_observer", objNull], ["_target", nil], ["_accuracy", 0], ["_systemTargeted", false], ["_targetedAt", CBA_missionTime], ["_wp", false], ["_reservedRounds", 0], ["_shellType", ""], ["_plannedSalvos", -1]];

    private _trpMetadata = _req param [9, []];
    private _aimAccuracy = _trpMetadata param [1, _accuracy];
    private _shells = [_req] call BATTLESPACE_ARTILLERY_GET_REQUEST_SALVOS;
	if (_plannedSalvos > 0) then {_shells = _plannedSalvos};


	private _vehs = [];

	{
		private _veh = (vehicle _x);

		if(_veh isEqualTo _x || {!alive _veh} || {!canFire _veh} || {!(_shellType in getArtilleryAmmo [_veh])}) then {
		continue;
		};
		_veh doWatch (_target getPos [0,0]);
		_vehs pushBack _veh;
	} forEach (units _battery);

	_vehs = _vehs arrayIntersect _vehs;
	private _fireProgress = [];
	{
		// Server-local pieces retain one hook across missions; only the active magazine is counted.
		if (isNil {_x getVariable "BSAFiredHandler"}) then {
			private _handler = [_x, "Fired", {
				params ["_piece", "", "", "", "", "_magazine"];
				private _progress = _piece getVariable ["BSAFireProgress", []];
				if (count _progress == 3 && {_magazine == (_progress select 0)}) then {
					_progress set [2, (_progress select 2) + 1];
                    _piece setVariable ["BSAFireProgress", _progress];
                    private _trpId = _piece getVariable ["BSAFireTRP", ""];
                    private _trp = (localNamespace getVariable ["BSA_TRPS", createHashMap]) getOrDefault [_trpId, createHashMap];
                    if (count _trp > 0) then {_trp set ["lastFiredAt", CBA_missionTime]};
				};
			}] call CBA_fnc_addBISEventHandler;
			_x setVariable ["BSAFiredHandler", _handler];
		};
		private _progress = [_shellType, 0, 0];
		_fireProgress pushBack _progress;
		_x setVariable ["BSAFireProgress", _progress];
        _x setVariable ["BSAFireTRP", _trpMetadata param [0, ""]];
	} forEach _vehs;
	private _isRocketArtillery = (_battery getVariable ["BSAPieceResource", ""]) == "rocket_artillery";
	private _rocketMagazineCapacity = 0;
	private _rocketRippleSize = 1;
	private _roundsPerPiece = _shells;
	private _fireOrdersPerPiece = _shells;
	if (_isRocketArtillery) then {
		([_shellType] call BATTLESPACE_ARTILLERY_GET_ROCKET_RIPPLE) params ["_resolvedRippleSize", "_resolvedMagazineCapacity"];
		_rocketRippleSize = _resolvedRippleSize;
		_rocketMagazineCapacity = _resolvedMagazineCapacity;
		_roundsPerPiece = _shells min _rocketMagazineCapacity;
		_fireOrdersPerPiece = ceil (_roundsPerPiece / _rocketRippleSize);
		[format ["Rocket artillery ripple started (group=%1, shell=%2, pieces=%3, paidRounds=%4, roundsPerPiece=%5, rippleSize=%6, ordersPerPiece=%7)", _battery, _shellType, count _vehs, _reservedRounds, _roundsPerPiece, _rocketRippleSize, _fireOrdersPerPiece], "BATTLESPACE"] call KPLIB_fnc_log;
	};



		
	private _state = _battery getVariable ["BSAState", []];

	private _targets = [];
	private _shellsFired = 0;
	private _roundsOrdered = 0;
	private _roundsRemaining = _reservedRounds;
	private _rangeRejectedOrders = 0;
	private _timedOut = false;

	if (BATTLESPACE_ARTILLERY_DEBUG) then {systemChat format ["We are shooting %1", _shellType];};
	for "_i" from 1 to _fireOrdersPerPiece do {
        if (_roundsRemaining <= 0) exitWith {};
        if !([_battery, _req] call BATTLESPACE_TRP_MISSION_VALID) exitWith {
            [format ["Artillery TRP mission stopped (group=%1, point=%2, reason=plan invalidated or friendly troops entered fire area)", _battery, _trpMetadata param [0, ""]], "BATTLESPACE"] call KPLIB_fnc_log;
        };
		{	
			if (_roundsRemaining <= 0) then {continue};
			if (!alive _x || {!alive gunner _x}) then {continue};
			private _roundsThisOrder = 1;
			if (_isRocketArtillery) then {
				_roundsThisOrder = (_rocketRippleSize min (_roundsPerPiece - ((_i - 1) * _rocketRippleSize))) min _roundsRemaining;
			};
			if (_roundsThisOrder <= 0) then {continue};

			
            private _minDispersion = [_aimAccuracy, _wp] call BATTLESPACE_GET_MIN_DISPERSION;
            private _maxDispersion = [_aimAccuracy, _wp] call BATTLESPACE_GET_MAX_DISPERSION;
			if (_isRocketArtillery) then {
				_minDispersion = _minDispersion * 1.5;
				_maxDispersion = _maxDispersion * 1.5;
			};

			

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

				_inRange = [_x, _new, _shellType] call BATTLESPACE_ARTILLERY_CAN_REACH_AREA;

				if(_inRange) then {
					_roundsOrdered = _roundsOrdered + _roundsThisOrder;
					_roundsRemaining = _roundsRemaining - _roundsThisOrder;
					_tLoc = _new;
					_execs = 26;
				};
				_execs = _execs + 1;
			};
			if(_inRange) then {

			
			

				_targets pushBack _tLoc;

				
				
				_state set [6, _targets];

				_battery setVariable ["BSAState", _state, true];

				

				private _progress = _x getVariable "BSAFireProgress";
				_progress set [1, (_progress select 1) + _roundsThisOrder];
				_x setVariable ["BSAFireProgress", _progress];
                _x commandArtilleryFire [_tLoc, _shellType, _roundsThisOrder];

			} else {
				_rangeRejectedOrders = _rangeRejectedOrders + 1;
			};
		
		} forEach _vehs;
		private _deadline = CBA_missionTime + BATTLESPACE_ARTILLERY_FIRE_ORDER_TIMEOUT;
		waitUntil {
			sleep 1;
			private _pending = _vehs findIf {
				alive _x && {alive gunner _x} && {
					private _progress = _x getVariable "BSAFireProgress";
					(_progress select 2) < (_progress select 1)
				}
			};
			_timedOut = _pending != -1 && {CBA_missionTime >= _deadline};
			_pending == -1 || _timedOut
		};
		if (_timedOut) exitWith {};
	};
	sleep 2;

	[_observer] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET", 2];
	[_obsKey] remoteExec ["BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET", 2];
	

	{
		doStop gunner _x;
		_x setVehicleAmmoDef 0;
		// Keep the mission's counter even if a piece was deleted after firing.
		_shellsFired = _shellsFired + ((_fireProgress select _forEachIndex) select 2);
		_x setVariable ["BSAFireProgress", []];
	} forEach _vehs;
	private _unusedRounds = (_reservedRounds - _shellsFired) max 0;
	if (_unusedRounds > 0) then {
		private _fundingSector = _battery getVariable ["BSAFundingSector", ""];
		[_fundingSector, createHashMapFromArray [["rockets", _unusedRounds]]] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
	};
	private _cooldown = BATTLESPACE_ARTILLERY_MIN_COOLDOWN max (_shells * BATTLESPACE_ARTILLERY_COOLDOWN_PER_SHELL);
	_cooldown = BATTLESPACE_ARTILLERY_MAX_COOLDOWN min _cooldown;
	if(combat_readiness < 50) then {
		_cooldown = _cooldown * 1.5;
	};

	_state = _battery getVariable "BSAState";
	// Because now the battery may get suppressed mid way through the mission, we need to check if the state is same as before setting to the next state
	if((_state#0) == "IN MISSION") then {
		_state set [0, "COOLING DOWN"];
	};
	// We still set the cooldown time though, that way if something is suppressed and their timer elapses, then we'd set it to COOLING DOWN instead of READY
	_state set [9, CBA_missionTime + _cooldown];
	_battery setVariable ["BSAState", _state, true];
	[format ["Artillery mission completed (group=%1, sector=%2, type=%3, shell=%4, ordered=%5, refunded=%6, cooldown=%7 seconds, pieces=%8, noSafeRangeOrders=%9, fired=%10, timedOut=%11)", _battery, _battery getVariable ["BSAFundingSector", ""], ["HE", "WP/SMOKE"] select _wp, _shellType, _roundsOrdered, _unusedRounds, _cooldown, count _vehs, _rangeRejectedOrders, _shellsFired, _timedOut], "BATTLESPACE"] call KPLIB_fnc_log;
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
    params [["_observer", objNull, [objNull]], ["_targets", [], [[]]]];
    // Accept evidence only from the machine that owns this observer (including HC).
    if (!isRemoteExecuted || {isNull _observer} || {remoteExecutedOwner != owner _observer}) exitWith {};
    _targets = (_targets select {_x isEqualType objNull && {!isNull _x}}) select [0, 64];
    _observer setVariable ["BSA_Targets", _targets, true];
    if (isServer) then {
        private _contacts = localNamespace getVariable "BSA_TRP_CONTACTS";
        _contacts set [str _observer, [_observer, (_targets select {alive _x && {side _x == GRLIB_side_friendly} && {!(_x isKindOf "Air")} && {!(_x getVariable ["ACE_isUnconscious", false])}}) apply {getPosATL _x}, CBA_missionTime, remoteExecutedOwner]];
        if (count _contacts > 128) then {_contacts deleteAt ((keys _contacts) # 0)};
    };
};

BATTLESPACE_ARTILLERY_BROADCAST_TARGET = {
	params ["_target", "_observer", "_timeInCombat", ["_systemTargeted", false], ["_targetedAt", CBA_missionTime], ["_wp", false]];

	BATTLESPACE_ARTILLERY_OBSERVER_TARGETS set [str _observer, [_observer, _target, _timeInCombat, _systemTargeted, _targetedAt, _wp]];
};


BATTLESPACE_ARTILLERY_BROADCAST_CLEAR_TARGET = {
	params ["_observer"];

	if ((typeName _observer) != "STRING") then {
		BATTLESPACE_ARTILLERY_OBSERVER_TARGETS deleteAt (str _observer);
	} else {
		BATTLESPACE_ARTILLERY_OBSERVER_TARGETS deleteAt _observer;
	};
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
		["_callInWp", false]
	];
	

	_callInWp = (random 1) < (0 max BATTLESPACE_ARTILLERY_SMOKE_CHANCE min 1);
	_state set [2, _callInWp];

	


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
				private _targetMovement = _prevLoc distance2D _tLoc;
				if(_targetMovement <= 5) then {
					_multiplier = 4;
				} else {
					if(_targetMovement >= BATTLESPACE_ARTILLERY_TARGET_MOVEMENT_ACCURACY_LOSS_DISTANCE) then {
						_retainMultiplier = 0.6;
					} else {
						if(_targetMovement >= BATTLESPACE_ARTILLERY_TARGET_MOVEMENT_ACCURACY_LOSS_BAND_DISTANCE) then {
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
BATTLESPACE_ARTILLERY_BUILD_RENDER_SNAPSHOT = {
	if (!isServer) exitWith {[[], [], [true, 0, 0]]};

	private _observers = [];
	{
		_y params ["_observer", "_target", "_timeInCombat", "_systemTargeted", "_targetedAtUnused", "_wp"];
		private _targetPosition = if (_target isEqualType objNull) then {
			if (isNull _target) then {[]} else {getPos _target}
		} else {
			if (_target isEqualType []) then {+_target} else {[]}
		};
		if (_targetPosition isEqualTo []) then {continue};

		private _observerPosition = [];
		if (_observer isEqualType objNull && {!isNull _observer}) then {
			_observerPosition = getPos _observer;
		};
		_observers pushBack [_observerPosition, _targetPosition, _timeInCombat, _systemTargeted, _wp];
	} forEach BATTLESPACE_ARTILLERY_OBSERVER_TARGETS;

	private _batteries = [];
	{
		private _leader = leader _x;
		if (isNull _leader) then {continue};
		private _state = _x getVariable ["BSAState", []];
		_state params [
			["_status", "NOT READY"], ["_initialSetupTimeUnused", 0], ["_locationUnused", []],
			["_targetUnused", objNull], ["_accuracy", 0], ["_observerUnused", objNull],
			["_targetLocations", []], ["_targetLocation", []], ["_systemTargeted", false],
			["_cooldownExpiresAt", 0], ["_suppressedUntil", 0], ["_wp", false]
		];
		_batteries pushBack [
			str _x,
			getPos _leader,
			_status,
			_accuracy,
			+_targetLocations,
			+_targetLocation,
			_systemTargeted,
			_cooldownExpiresAt,
			_suppressedUntil,
            _wp,
            _x getVariable ["BSATRP", ""],
            _x getVariable ["BSAAimAccuracy", _accuracy],
            _x getVariable ["BSAPieceResource", ""]
        ];
    } forEach BATTLESPACE_ARTILLERY_SECTIONS;

	[
		_observers,
		_batteries,
		[
			missionNamespace getVariable ["BATTLESPACE_ARTILLERY_NETWORK_ENABLED", true],
			missionNamespace getVariable ["BATTLESPACE_ARTILLERY_CURRENT_CYCLE", 0],
            missionNamespace getVariable ["BATTLESPACE_ARTILLERY_CYCLES_REQUIRED", 0]
        ],
        call BATTLESPACE_TRP_SNAPSHOT
    ]
};

BATTLESPACE_ARTILLERY_RENDER_REQUEST = {
	if (!isServer || {!isRemoteExecuted}) exitWith {};
	private _ownerId = remoteExecutedOwner;
	private _requester = (allPlayers select {owner _x == _ownerId}) param [0, objNull];
	if (isNull _requester || {isNull (getAssignedCuratorLogic _requester)}) exitWith {};

	private _lastRequest = _requester getVariable ["KPLIB_battlespaceArtilleryRenderRequestAt", -10];
	if (CBA_missionTime - _lastRequest < 1) exitWith {};
	_requester setVariable ["KPLIB_battlespaceArtilleryRenderRequestAt", CBA_missionTime];

	private _snapshot = [] call BATTLESPACE_ARTILLERY_BUILD_RENDER_SNAPSHOT;
	["KPLIB_battlespaceArtilleryRenderSnapshot", [_snapshot], _requester] call CBA_fnc_targetEvent;
};

if (isServer) then {
	["Compact Battlespace artillery curator-render snapshot service initialized", "BATTLESPACE"] call KPLIB_fnc_log;
	[format ["Artillery observer smoke chance configured (%1 percent per update)", 100 * (0 max BATTLESPACE_ARTILLERY_SMOKE_CHANCE min 1)], "BATTLESPACE"] call KPLIB_fnc_log;
	[format ["Artillery observer movement accuracy bands configured (mild=%1m, severe=%2m)", BATTLESPACE_ARTILLERY_TARGET_MOVEMENT_ACCURACY_LOSS_BAND_DISTANCE, BATTLESPACE_ARTILLERY_TARGET_MOVEMENT_ACCURACY_LOSS_DISTANCE], "BATTLESPACE"] call KPLIB_fnc_log;
};

if (hasInterface) then {
	["KPLIB_battlespaceArtilleryRenderSnapshot", {
		params [["_snapshot", [[], [], [true, 0, 0]], [[]]]];
		BATTLESPACE_ARTILLERY_RENDER_DATA = _snapshot;
        BSA_RENDER_RECEIVED_AT = CBA_missionTime;
	}] call CBA_fnc_addEventHandler;
};

RENDER_BATTLESPACE_ARTILLERY = true;
RENDER_BATTLESPACE_ARTILLERY_TRPS = true;
RENDER_BATTLESPACE_ARTILLERY_PFH_ID = -1;

RENDER_BATTLESPACE_ARTILLERY_PFH = {
	(_this select 0) params [["_nextTick", 0]];
    if (!RENDER_BATTLESPACE_ARTILLERY) exitWith {
        [_this select 1] call CBA_fnc_removePerFrameHandler;
        RENDER_BATTLESPACE_ARTILLERY_PFH_ID = -1;
    };
	if(isNull curatorCamera) exitWith {};
	if(accTime <= 0 || isGamePaused) exitWith {};

	if(CBA_missionTime > _nextTick) then {
		[] remoteExecCall ["BATTLESPACE_ARTILLERY_RENDER_REQUEST", 2];
		(_this select 0) set [0, CBA_missionTime + 5];
	};

	BATTLESPACE_ARTILLERY_RENDER_DATA params [
		["_renderObservers", []],
		["_renderBatteries", []],
        ["_renderNetwork", [true, 0, 0]],
        ["_renderTRPs", []]
    ];
    if (RENDER_BATTLESPACE_ARTILLERY_TRPS && {!isNil "BATTLESPACE_TRP_DRAW"}) then {[_renderTRPs] call BATTLESPACE_TRP_DRAW};
	_renderNetwork params ["_networkEnabled", "_currentCycle", "_cyclesRequired"];
	private _networkStr = [
		format ["NETWORK OFF (%1/%2)", _currentCycle, _cyclesRequired],
		format ["NETWORK ON (%1/%2)", _currentCycle, _cyclesRequired]
	] select _networkEnabled;

	{
		_x params ["_observerPosition", "_targetPosition", "_timeInCombat", "_systemTargeted", "_wp"];
		private _targetPos = _targetPosition vectorAdd [0,0,25];
		private _cffType = "FIRE-FOR-EFFECT";
		private _targetMarker = "\A3\ui_f\data\map\markers\nato\b_inf.paa";
		if(_timeInCombat < 300) then {_cffType = "ADJUST FIRE"};
		if(_wp) then {_cffType = "IMMEDIATE SMOKE"};
		private _targetType = "TARGET";

		if(_systemTargeted) then {
			_cffType = ["SUPPRESSION", "NEUTRALIZATION"] select (_timeInCombat >= 200);
			_targetType = "COUNTER-BATTERY TARGET";
			_targetMarker = "\A3\ui_f\data\map\markers\nato\b_art.paa";
		};

		if(_observerPosition isNotEqualTo []) then {
			private _observerPos = _observerPosition vectorAdd [0,0,25];
			private _dir = _observerPos vectorFromTo _targetPos;
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
	} forEach _renderObservers;

	{
		_x params [
			"_batteryName", "_batteryPosition", "_status", "_accuracy", "_targetLocations",
            "_targetLocation", "_systemTargeted", "_cooldownExpiresAt", "_suppressedUntil", "_wp",
            ["_trp", ""], ["_aim", _accuracy], ["_pieceResource", ""]
        ];
		private _cffType = "FIRE-FOR-EFFECT";
		if(_accuracy < 300) then {_cffType = "ADJUST FIRE"};
		if(_wp) then {_cffType = "IMMEDIATE SMOKE"};
		if(_systemTargeted) then {
			_cffType = ["SUPPRESSION", "NEUTRALIZATION"] select (_accuracy >= 200);
		};

        if (_trp != "" && {_status == "IN MISSION"}) then {_cffType = "REGISTERED " + _trp};
        private _statusStr = _status;
		if(_status == "SUPPRESSED") then {
			private _timeRemaining = 0 max ceil (_suppressedUntil - CBA_missionTime);
			if(_timeRemaining == 0) then {
				if(_cooldownExpiresAt > CBA_missionTime) then {
					private _cooldownRemaining = 0 max ceil (_cooldownExpiresAt - CBA_missionTime);
					private _mins = floor (_cooldownRemaining / 60);
					private _rem = _cooldownRemaining - (_mins * 60);
					if(_rem < 10) then {_rem = format ["0%1", _rem]};
					_statusStr = format ["COOLING DOWN (%1:%2)", _mins, _rem];
				} else {
					_statusStr = "AWAITING NETWORK CYCLE";
				};
			} else {
				private _mins = floor (_timeRemaining / 60);
				private _rem = _timeRemaining - (_mins * 60);
				if(_rem < 10) then {_rem = format ["0%1", _rem]};
				_statusStr = format ["SUPPRESSED (%1:%2)", _mins, _rem];
			};
		};
		if(_status == "COOLING DOWN") then {
			private _cooldownRemaining = 0 max ceil (_cooldownExpiresAt - CBA_missionTime);
			private _mins = floor (_cooldownRemaining / 60);
			private _rem = _cooldownRemaining - (_mins * 60);
			if(_rem < 10) then {_rem = format ["0%1", _rem]};
			_statusStr = format ["COOLING DOWN (%1:%2)", _mins, _rem];
		};

		private _pos = _batteryPosition vectorAdd [0,0,40];
		drawIcon3D ["\A3\ui_f\data\map\markers\nato\o_art.paa", [1,0.4,0.4,1], _pos, 1, 1, 0, format ["BATTERY %1 | STATUS: %2 | %3", _batteryName, _statusStr, _networkStr], 1, 0.03, "TahomaB"];

		if(_targetLocation isNotEqualTo []) then {
			private _targetPos = _targetLocation vectorAdd [0,0,40];
			drawIcon3D ["\A3\ui_f\data\map\groupicons\selector_selectedEnemy_ca.paa", [1,0.4,0.4,1], _targetPos, 1, 1, 0, format ["BATTERY %1 %2 (%3)", _batteryName, _cffType, _accuracy], 1, 0.03, "TahomaB"];
            private _minDispersion = [_aim, _wp] call BATTLESPACE_GET_MIN_DISPERSION;
            private _maxDispersion = [_aim, _wp] call BATTLESPACE_GET_MAX_DISPERSION;
            if (_pieceResource == "rocket_artillery") then {
                _minDispersion = _minDispersion * 1.5;
                _maxDispersion = _maxDispersion * 1.5;
            };
			for "_i" from 0 to 35 do {
				private _angle = _i * 10;
				private _innerPos = _targetPos getPos [_minDispersion, _angle];
				private _outerPos = _targetPos getPos [_maxDispersion, _angle];
				drawIcon3D ["\a3\UI_F_Enoch\Data\CfgMarkers\dot1_ca.paa", [1,0,0,1], _innerPos, 0.5, 0.5, 0, "", 1, 0.02, "TahomaB"];
				drawIcon3D ["\a3\UI_F_Enoch\Data\CfgMarkers\dot1_ca.paa", [0,1,0,1], _outerPos, 0.5, 0.5, 0, "", 1, 0.02, "TahomaB"];
			};
		};

		{
			drawIcon3D ["\A3\ui_f\data\map\groupicons\waypoint.paa", [1,0,0,1], _x, 0.5, 0.5, 0, format ["TLOC%1", _forEachIndex + 1], 1, 0.03, "TahomaB"];
		} forEach _targetLocations;
	} forEach _renderBatteries;
};

if(hasInterface) then {
    RENDER_BATTLESPACE_ARTILLERY_PFH_ID = [
        { _this call RENDER_BATTLESPACE_ARTILLERY_PFH },
		0,
		[0]
	] call CBA_fnc_addPerFrameHandler;
};
if (isServer) then {

	[
		{ _this call BATTLESPACE_ARTILLERY_POLL_REQUESTS },
		1,
		[]
	] call CBA_fnc_addPerFrameHandler;


	
};
