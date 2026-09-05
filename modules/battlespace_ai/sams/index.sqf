// SAMs
// Track how many sites are currently active
// Logic for spawning in a SAM site by traversing sector link graph and then finding suitable spawns.

BATTLESPACE_SAM_DEBUG = false;
BATTLESPACE_SAM_EXISTING_SITES = [];
BATTLESPACE_SAM_SITE_POOLS = createHashMap;
BATTLESPACE_SAM_SITE_AUTOINCREMENT = 1;

BATTLESPACE_SAM_LAST_SPAWN_TIME = 0;
BATTLESPACE_SAM_SPAWN_PENDING = false;

BATTLESPACE_SAM_BUILD_RESERVATION = {
    params ["_classes"];
    private _cost = createHashMap;
    private _strategicHardware = 0;
    private _tacticalLaunchers = 0;
    private _shorad = [];
    {{_shorad pushBackUnique _x} forEach _x} forEach BATTLESPACE_SAM_SITE_SHORAD;
    {
        if (_x in BATTLESPACE_SAM_SITE_TELS || {_x in BATTLESPACE_SAM_SITE_FCRS}) then {_strategicHardware = _strategicHardware + 1};
        if (_x in _shorad) then {_tacticalLaunchers = _tacticalLaunchers + 1};
    } forEach _classes;
    if (_strategicHardware > 0) then {_cost set ["strategic_sam", _strategicHardware]};
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

BATTLESPACE_SAM_SELECT_COMPOSITION = {
    private _radars = BATTLESPACE_SAM_SITE_FCRS;
    private _radarCount = (BATTLESPACE_SAM_SITE_COMPOSITION getOrDefault ["FCR", 1]) max 0;
    private _launchers = BATTLESPACE_SAM_SITE_TELS select {
        !(([_x] call KPLIB_fnc_getVehicleAirDefense) get "needsRadar")
        || {_radars isNotEqualTo [] && {_radarCount > 0}}
    };
    private _telCount = (BATTLESPACE_SAM_SITE_COMPOSITION getOrDefault ["TEL", 1]) max 0;
    if (_telCount <= 0) exitWith {[]};
    private _classes = [];
    if (_launchers isEqualTo []) exitWith {
        // An IR-only faction can defend the airspace without a radar/TEL pair.
        if (BATTLESPACE_SAM_SITE_SHORAD isNotEqualTo []) then {
            for "_i" from 1 to _telCount do {_classes append selectRandom BATTLESPACE_SAM_SITE_SHORAD};
        };
        _classes
    };
    // Keep the main battery one system; native Data Link uses same-side radars.
    private _launcher = selectRandom _launchers;
    for "_i" from 1 to _telCount do {_classes pushBack _launcher};
    if (_radars isNotEqualTo []) then {
        for "_i" from 1 to _radarCount do {_classes pushBack selectRandom _radars};
    };
    if (BATTLESPACE_SAM_SITE_SHORAD isNotEqualTo []) then {
        _classes append selectRandom BATTLESPACE_SAM_SITE_SHORAD;
    };
    _classes
};

// Refill only the launcher's missile magazines, with no more live rounds than
// its paid reserve. Hybrid gun ammunition and countermeasures are untouched.
BATTLESPACE_SAM_LOAD_MISSILES = {
    params ["_vehicle"];
    if (!isServer || {isRemoteExecuted} || {isNull _vehicle} || {!local _vehicle} || {!alive _vehicle}) exitWith {};
    private _capability = [typeOf _vehicle] call KPLIB_fnc_getVehicleAirDefense;
    private _missiles = _capability get "missileMagazines";
    private _budget = floor (_vehicle getVariable ["BSAMissilesRemaining", 0]);
    private _loaded = (magazinesAllTurrets _vehicle) select {(_x # 0) in _missiles};
    private _pairs = _vehicle getVariable ["BSAMissileSlots", []];
    if (_pairs isEqualTo []) then {
        {_pairs pushBackUnique [_x # 0, _x # 1]} forEach _loaded;
        _vehicle setVariable ["BSAMissileSlots", _pairs];
    };
    {
        private _pair = _x;
        private _present = _loaded select {[_x # 0, _x # 1] isEqualTo _pair};
        // Keep one magazine per type/seat; extra rounds live in the paid reserve.
        // Preserve a loaded magazine to avoid restarting native magazine reloads.
        if (count _present > 1) then {
            _vehicle removeMagazinesTurret _pair;
            _present = [];
        };
        if (_present isEqualTo []) then {_vehicle addMagazineTurret [_pair # 0, _pair # 1, 0]};
        private _amount = (getNumber (configFile >> "CfgMagazines" >> (_x # 0) >> "count")) min _budget;
        _vehicle setMagazineTurretAmmo [_pair # 0, _amount, _pair # 1];
        _budget = _budget - _amount;
    } forEach _pairs;
};

BATTLESPACE_SAM_TRY_RELOAD = {
    params ["_vehicle", "_siteId", "_resource"];
    if (!isServer || {isRemoteExecuted} || {isNull _vehicle} || {!alive _vehicle} || {!local _vehicle}) exitWith {false};
    if ((_vehicle getVariable ["BSAMissilesRemaining", 0]) > 0) exitWith {false};
    private _site = BATTLESPACE_SAM_SITE_POOLS getOrDefault [_siteId, createHashMap];
    if !(_vehicle in (_site getOrDefault ["Units", []]) && {_resource == _vehicle getVariable ["BSAMissileResource", ""]}) exitWith {false};
    private _sector = _site getOrDefault ["Sector", ""];
    private _state = BATTLESPACE_SECTOR_STATES getOrDefault [_sector, createHashMap];
    if ((_state getOrDefault ["owner", ""]) != "OPFOR") exitWith {false};
    private _available = (_state getOrDefault ["resources", createHashMap]) getOrDefault [_resource, 0];
    private _batch = floor (_available min (missionNamespace getVariable ["BATTLESPACE_SAM_RELOAD_BATCH", 4]));
    if (_batch <= 0 || {!([_sector, createHashMapFromArray [[_resource, -_batch]]] call BATTLESPACE_RESOURCE_APPLY_STRICT)}) exitWith {false};
    private _pools = _site get "Pools";
    _pools set [_resource, (_pools getOrDefault [_resource, 0]) + _batch];
    _vehicle setVariable ["BSAMissilesRemaining", (_vehicle getVariable ["BSAMissilesRemaining", 0]) + _batch];
    [_vehicle] call BATTLESPACE_SAM_LOAD_MISSILES;
    true
};

BATTLESPACE_SAM_RESUPPLY = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    if !(missionNamespace getVariable ["BATTLESPACE_LOGISTICS_READY", false]) exitWith {};
    {
        private _siteId = _x getOrDefault ["Id", ""];
        {
            private _resource = _x getVariable ["BSAMissileResource", ""];
            if (_resource != "" && {alive gunner _x} && {side group _x == GRLIB_side_enemy}
                && {(_x getVariable ["BSAMissilesRemaining", 0]) <= 0}) then {
                [_x, _siteId, _resource] call BATTLESPACE_SAM_TRY_RELOAD;
            };
        } forEach (_x getOrDefault ["Units", []]);
    } forEach BATTLESPACE_SAM_EXISTING_SITES;
};

BATTLESPACE_SAM_ON_FIRED = {
    params ["_vehicle", "_weapon", "_muzzle", "_mode", "_ammo"];
    if (!isServer || {isRemoteExecuted} || {!local _vehicle}) exitWith {};
    private _capability = [typeOf _vehicle] call KPLIB_fnc_getVehicleAirDefense;
    if !(_ammo in (_capability get "missileAmmo")) exitWith {};
    private _siteId = _vehicle getVariable ["BSASiteId", ""];
    private _resource = _vehicle getVariable ["BSAMissileResource", ""];
    private _site = BATTLESPACE_SAM_SITE_POOLS getOrDefault [_siteId, createHashMap];
    if !(_vehicle in (_site getOrDefault ["Units", []]) && {_resource != ""}) exitWith {};
    private _pools = _site get "Pools";
    _pools set [_resource, ((_pools getOrDefault [_resource, 0]) - 1) max 0];
    private _remaining = ((_vehicle getVariable ["BSAMissilesRemaining", 0]) - 1) max 0;
    _vehicle setVariable ["BSAMissilesRemaining", _remaining];
    // Wait until the engine has consumed the fired round before checking mags.
    [{
        params ["_vehicle", "_siteId", "_resource"];
        if (isNull _vehicle || {!alive _vehicle} || {!local _vehicle}) exitWith {};
        if ((_vehicle getVariable ["BSAMissilesRemaining", 0]) <= 0) exitWith {
            [_vehicle] call BATTLESPACE_SAM_LOAD_MISSILES;
            [_vehicle, _siteId, _resource] call BATTLESPACE_SAM_TRY_RELOAD;
        };
        private _magazines = ([typeOf _vehicle] call KPLIB_fnc_getVehicleAirDefense) get "missileMagazines";
        if (((magazinesAllTurrets _vehicle) findIf {(_x # 0) in _magazines && {(_x # 2) > 0}}) < 0) then {
            [_vehicle] call BATTLESPACE_SAM_LOAD_MISSILES;
        };
    }, [_vehicle, _siteId, _resource], 0.5] call CBA_fnc_waitAndExecute;
};

BATTLESPACE_EVALUATE_AIRSPACE = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    if (!BATTLESPACE_ENABLE_SAM_SPAWNS || {BATTLESPACE_SAM_SPAWN_PENDING}) exitWith {};
    if !(missionNamespace getVariable ["KPLIB_autoFactionActive", false]) exitWith {};

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
        private _unitsToSpawn = [] call BATTLESPACE_SAM_SELECT_COMPOSITION;
        if (_unitsToSpawn isEqualTo []) exitWith {};
        private _reservation = [_unitsToSpawn] call BATTLESPACE_SAM_BUILD_RESERVATION;
        private _debit = createHashMap;
        {_debit set [_x, -_y]} forEach _reservation;
        private _admitted = false;
        isNil {
            if (!BATTLESPACE_SAM_SPAWN_PENDING && {count BATTLESPACE_SAM_EXISTING_SITES < BATTLESPACE_SAM_SITE_LIMIT}) then {
                if ([_sectorToSpawnIn, _debit] call BATTLESPACE_RESOURCE_APPLY_STRICT) then {
                    BATTLESPACE_SAM_SPAWN_PENDING = true;
                    _admitted = true;
                };
            };
        };
        if (!_admitted) exitWith {};

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
    if (!isServer || {isRemoteExecuted}) exitWith {};
    private _state = BATTLESPACE_SECTOR_STATES getOrDefault [_sectorToSpawnIn, createHashMap];
    if ((_state getOrDefault ["owner", ""]) != "OPFOR") exitWith {
        [_sectorToSpawnIn, _reservation] call BATTLESPACE_RESOURCE_RESTORE_TRANSFER;
        BATTLESPACE_SAM_SPAWN_PENDING = false;
    };

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
        if (isNull _unit) then {continue};
        private _capability = [_className] call KPLIB_fnc_getVehicleAirDefense;
        _unit setVehicleReceiveRemoteTargets true;
        _unit setVehicleReportOwnPosition true;
        if (_capability get "radar") then {
            _unit engineOn true;
            _unit setVehicleRadar 1;
            _unit setVehicleReportRemoteTargets true;
        };

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
            _unit setVariable ["BSAMissilesRemaining", 0];
            [_unit] call BATTLESPACE_SAM_LOAD_MISSILES;
            _unit setVariable ["BSASiteId", _siteId, true];
            _unit setVariable ["BSAMissileResource", _missileResource, true];
            [_unit, "Fired", {_this call BATTLESPACE_SAM_ON_FIRED}] call CBA_fnc_addBISEventHandler;
        };
        private _crew = units (createVehicleCrew _unit);
        _crew joinSilent _grp;
        // SAM sites remain server-owned. Generic faction units use native AI;
        // only ammunition-profile-supported systems enter custom fire control.
        _grp setCombatMode "YELLOW";

        {
            _x setVariable ["Vcm_Disable", true, true];
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

            if(!(_className in BATTLESPACE_SAM_SITE_TELS) && !(_className in BATTLESPACE_SAM_SITE_FCRS)) then {
                _x disableAI "MOVE";
            };
        } forEach (_crew);




        _units pushBack _unit;
        _spawnedClasses pushBack _className;

        // Not MP because this is a server only matter
        [_unit, "Killed", { ["SAM", _this] call BATTLESPACE_SAM_KILLED }] call CBA_fnc_addBISEventHandler;

    } forEach _unitsToSpawn;

    // An external-radar launcher is not a usable partial site without radar.
    private _radarSurvived = (_units findIf {
        (typeOf _x) in BATTLESPACE_SAM_SITE_FCRS && {alive _x} && {alive gunner _x}
    }) >= 0;
    private _remove = _units select {
        !alive _x || {!alive gunner _x} || {!_radarSurvived && {([typeOf _x] call KPLIB_fnc_getVehicleAirDefense) get "needsRadar"}}
    };
    private _survivors = _units - _remove;
    if ((_survivors findIf {(_x getVariable ["BSAMissileResource", ""]) != ""}) < 0) then {
        _remove = +_units;
    };
    {
        {deleteVehicle _x} forEach crew _x;
        deleteVehicle _x;
    } forEach _remove;
    _units = _units - _remove;
    _spawnedClasses = _units apply {typeOf _x};
    if (units _fcrGrp isEqualTo []) then {deleteGroup _fcrGrp};
    _newSite set ["Units", _units];
    _newSite set ["Sector", _sectorToSpawnIn];
    _newSite set ["Id", _siteId];
    private _actualReservation = [_spawnedClasses] call BATTLESPACE_SAM_BUILD_RESERVATION;
    private _refund = createHashMap;
    {
        private _difference = _y - (_actualReservation getOrDefault [_x, 0]);
        if (_difference > 0) then {_refund set [_x, _difference]};
    } forEach _reservation;
    if (count _refund > 0) then {[_sectorToSpawnIn, _refund] call BATTLESPACE_RESOURCE_RESTORE_TRANSFER};
    private _pools = createHashMapFromArray [
        ["strategic_missiles", _actualReservation getOrDefault ["strategic_missiles", 0]],
        ["tactical_missiles", _actualReservation getOrDefault ["tactical_missiles", 0]]
    ];
    private _poolState = createHashMapFromArray [["Sector", _sectorToSpawnIn], ["Pools", _pools], ["Units", _units]];
    BATTLESPACE_SAM_SITE_POOLS set [_siteId, _poolState];
    {
        private _resource = _x getVariable ["BSAMissileResource", ""];
        if (_resource != "") then {
            private _rounds = if (_resource == "strategic_missiles") then {
                missionNamespace getVariable ["BATTLESPACE_SAM_STRATEGIC_MISSILES_PER_LAUNCHER", 8]
            } else {
                missionNamespace getVariable ["BATTLESPACE_SAM_TACTICAL_MISSILES_PER_LAUNCHER", 4]
            };
            _x setVariable ["BSAMissilesRemaining", _rounds];
            [{[_this # 0] call BATTLESPACE_SAM_LOAD_MISSILES}, [_x], 30] call CBA_fnc_waitAndExecute;
        };
    } forEach _units;
    BATTLESPACE_SAM_SPAWN_PENDING = false;

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

    if (!isServer || {isRemoteExecuted}) exitWith {};
    _event params ["_unit", "_killer", "_instigator", "_useEffects"];
    private _siteId = _unit getVariable ["BSASiteId", ""];
    private _site = BATTLESPACE_SAM_SITE_POOLS getOrDefault [_siteId, createHashMap];
    private _resource = _unit getVariable ["BSAMissileResource", ""];
    if (_resource != "" && {count _site > 0}) then {
        private _pools = _site get "Pools";
        _pools set [_resource, ((_pools getOrDefault [_resource, 0]) - (_unit getVariable ["BSAMissilesRemaining", 0])) max 0];
        _unit setVariable ["BSAMissilesRemaining", 0];
    };
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
                    // Existing bounded site list: retry empty launchers when
                    // logistics arrives, independently of new-site chance/cooldown.
                    [] call BATTLESPACE_SAM_RESUPPLY;
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
