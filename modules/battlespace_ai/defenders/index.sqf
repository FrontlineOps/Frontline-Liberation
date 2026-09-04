
BATTLESPACE_DEFENDER_GARRISON_AI = {
    params ["_infGrp"];
    // This script is spawned.
    // We wait until blufor is nearby then we reset tasks and issue a task hunt order 33% of the time.
    // This causes grenadiers to basically resupply but will ensure they have flares and a vest to hold this incase there's the stupid equipment bug.

    private _shouldYeetIntoBlufor = (random 100) <= 40;
    private _lowCountYeet = (random 100) <= 60;

    if(!_shouldYeetIntoBlufor && !_lowCountYeet) exitWith {
        diag_log format ["Group %1 will not yeet into blufor", _infGrp];
    };

    diag_log format ["Group %1 will yeet into blufor. Low Count only: %2", _infGrp, !_shouldYeetIntoBlufor];
    waitUntil {
        sleep 5;
        private _nearby = false;
        private _lowCount = (count (units _infGrp)) <= 2;
        if(_shouldYeetIntoBlufor || _lowCount) then {
            {
                if((_x distance (leader _infGrp)) <= ([30, 60] select _lowCount) && (side _x) == GRLIB_side_friendly) exitWith { _nearby = true };
            } forEach (allPlayers);
        };
        _nearby
    };

    // Kind of a hack to make sure they have their stuff
    {
        if(typeOf _x != opfor_grenadier) then { continue };
        if (missionNamespace getVariable ["KPLIB_autoFactionActive", false]) then {continue};

        diag_log format ["Group %1 starting task hunt, changing vest of %2 to have flares", _infGrp, _x];
        removeVest _x;
        removeBackpackGlobal _x;

        _x addVest (selectRandom opfor_vests);
        _x addBackpackGlobal (selectRandom opfor_backpacks);
        _x forceAddUniform (selectRandom opfor_uniforms);

        waitUntil { !isNull backpackContainer _x && !isNull uniformContainer _x && !isNull vestContainer _x };

        // Provide gear
        _x addItemToVest "rhs_mag_rgd5";
        for "_i" from 1 to 5 do {
            _x addItemToVest "rhs_30Rnd_545x39_7N10_AK";
            _x addItemToVest "ACE_40mm_Flare_white";
            _x addItemToUniform "ACE_fieldDressing";
        };
        for "_i" from 1 to 4 do {
            _x addItemToVest "rhs_mag_M441_HE";
            _x addItemToBackpack "rhs_mag_rdg2_black";
            _x addItemToBackpack "rhs_mag_rdg2_white";
        };
        for "_i" from 1 to 10 do {
            _x addItemToBackpack "rhs_mag_M441_HE";
        };
    } forEach (units _infGrp);

    diag_log format ["Group %1 detected nearby blufor, starting Task Hunt.", _infGrp];

    // Reset the existing task where the group is local before assigning its replacement.
    [_infGrp] remoteExec ["BATTLESPACE_DEFENDER_TASK_RESET", groupOwner _infGrp];
    [
        {
            _this params ["_leader"];

            private _rushB = (random 100) <= 33;
            if(_rushB) then {
                [_leader, 200, 15, [], [], true] remoteExec ["BATTLESPACE_DEFENDER_TASK_RUSH", groupOwner (group _leader)];
            } else {
                [_leader, 200, 15, [], [], true, true, 2] remoteExec ["BATTLESPACE_DEFENDER_TASK_HUNT", groupOwner (group _leader)];
            };
        },
        [
            leader _infGrp
        ],
        5
    ] call CBA_fnc_waitAndExecute;
};

BATTLESPACE_DEFENDER_TASK_RESET = {
    params [["_group", grpNull, [grpNull]]];

    if (isNull _group || {!local _group}) exitWith {false};

    [_group, false, true] call KPLIB_fnc_taskReset;
};

BATTLESPACE_DEFENDER_TASK_HUNT = {
    diag_log format ["Task Hunt params %1", _this];

    _this spawn KPLIB_fnc_hunt;
};

BATTLESPACE_DEFENDER_TASK_RUSH = {
    diag_log format ["Task Rush params %1", _this];

    _this spawn KPLIB_fnc_rush;
};

BATTLESPACE_DEFENDERS_CREATE_TASK_FORCES = {
    params ["_sector"];
    waitUntil {sleep 0.25; missionNamespace getVariable ["BATTLESPACE_LOGISTICS_READY", false]};
    private _sectorState = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_sectorState" || {(_sectorState getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {};

    private _createFundedDefender = {
        params ["_type", "_composition", "_origin", "_destination", "_home"];
        [
            _type, _composition, _origin, _destination, _home, _sector, "DEFENDER",
            createHashMapFromArray [["targetSector", _sector], ["pressureSector", _sector]]
        ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE
    };

    diag_log format ["Defender Create Task Forces at %1 (%2)", _sector, diag_tickTime];

    private _objPos = getMarkerPos _sector;

    // Treat the Ops Base as a sector to provide fairer spawn boundaries around it
    private _closestBluforSector = [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_traverseGraphAndFindFirstBluforSector;
    // Fallback, not sure what will happen
    // TODO: Refactor and make this better and randomized direction
    if(isNil { _closestBluforSector }) then {
        _closestBluforSector = _sector;
    };

    // Maximum range at which a task force may spawn around a point, cap between bounds
    private _maximumRange = _objPos distance2D (getMarkerPos _closestBluforSector);
    _maximumRange = _maximumRange * 0.75;
    _maximumRange = 500 max _maximumRange;
    _maximumRange = 1050 min _maximumRange;

    private _dirToBluforSector = _objPos vectorFromTo (getMarkerPos _closestBluforSector);
    // TODO: Maybe needs refactor
    if(_closestBluforSector == _sector) then {
        _dirToBluforSector = [random 1, random 1, 0];
    };

    // Handle scaling to adapt to player count
    private _scaledNumbers = [_sector] call BATTLESPACE_DEFENDERS_SECTOR_SCALING;
    private _infantrySquadCount = _scaledNumbers#0;
    private _numberOfStatics = _scaledNumbers#1;

    // Numbers of each type of squad to create
    // Split total between types giving priority to on-point defenders
    private _remainingInfantrySquads = _infantrySquadCount;
    private _garrisonCount = _remainingInfantrySquads min ceil(_infantrySquadCount * 0.30);
    _remainingInfantrySquads = 0 max (_remainingInfantrySquads - _garrisonCount);
    private _defensivePatrols = _remainingInfantrySquads min ceil(_infantrySquadCount * 0.30);
    _remainingInfantrySquads = 0 max (_remainingInfantrySquads - _defensivePatrols);
    private _patrollingSquads = _remainingInfantrySquads min ceil(_infantrySquadCount * 0.20);
    _remainingInfantrySquads = 0 max (_remainingInfantrySquads - _patrollingSquads);
    private _ambushSquads = _remainingInfantrySquads min ceil(_infantrySquadCount * 0.20);
    // _remainingInfantrySquads = 0 max (_remainingInfantrySquads - _ambushSquads);

    private _logMsg = format [
        "Sector %1 defenders: Statics: %2, Infantry: [%3, %4, %5, %6]",
        str _sector, _numberOfStatics, _garrisonCount, _defensivePatrols, _patrollingSquads, _ambushSquads
    ];
    diag_log _logMsg;

    // Patrolling infantry squads
    for "_i" from 1 to _patrollingSquads do {
        private _def = selectRandom BATTLESPACE_DEFENDERS_MECHANIZED_PATROL_DEFS;
        private _mechanized = (random 100) < 20;

        private _composition = createHashMapFromArray [
            ["manpower", [BATTLESPACE_SQUAD_SIZE,_def#1] select _mechanized],
            ["vehicles", [[], _def#0] select _mechanized],
            ["structures", []]
        ];
        // TODO: Make it more intelligent and go towards BLUFOR sectors

        // Keep infantry patrols relatively tight around the point to avoid random wanderers from nearby points
        private _position = _objPos getPos [150 + random 250, random 360];
        private _execs = 0;
        while { surfaceIsWater _position && _execs < 5 } do {
            // Use more relaxed position if water is involved to maximise chance of spawning
            _position = _objPos getPos [250 + (random 250) + (_execs * 5), random 360];
            _execs = _execs + 1;
        };
        if(_execs < 5) then {
            ["Reconnaissance Patrol", _composition, _position, _position, _objPos] call _createFundedDefender;
        };
    };

    // Prepare valid non-water fortification positions
    private _outpostPlaces = selectBestPlaces [_objPos vectorAdd (_dirToBluforSector vectorMultiply 200), _maximumRange * 0.45, "5 * meadow + 10 * hills - 10 * houses + 5 * forest - 50 * sea", 50, 50];
    _outpostPlaces = _outpostPlaces select {
        _x params ["_pos", "_expr"];

        private _likeness = _objPos vectorFromTo (_pos);
        _likeness = _likeness vectorDotProduct _dirToBluforSector;
     
        _likeness >= 0 && !surfaceIsWater _pos
    };

    // Spawn fortifications with garrisons
    private _positions = [];
    // Dynamic sites can exist before this sector is first materialized. Seed
    // the legacy defender placement guard so later outposts/ambushes/statics
    // do not build on top of already funded construction.
    if (!isNil "BATTLESPACE_FORTIFICATION_GET_OPERATIONS_FOR_SECTOR") then {
        {
            private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _x;
            if (!isNil "_operation") then {
                private _position = _operation getOrDefault ["sitePosition", []];
                if (_position isEqualType [] && {count _position >= 2}) then {_positions pushBackUnique _position};
            };
        } forEach ([_sector] call BATTLESPACE_FORTIFICATION_GET_OPERATIONS_FOR_SECTOR);
    };
    private _outpostsCount = (count _outpostPlaces);
    if(_outpostsCount > 0) then {
        for "_i" from 1 to 2 do {
            private _pos = (selectRandom _outpostPlaces)#0;
            private _execs = 0;
            while { 
                private _invalid = false;
                {
                    if((_x distance2D _pos) <= 200) exitWith { _invalid = true };
                } forEach _positions;

                if(surfaceIsWater _pos) then {
                    _invalid = false;
                };

                _invalid && _execs < _outpostsCount
            } do {
                _pos = (selectRandom _outpostPlaces)#0;
                _execs = _execs + 1;
            };

            if(_execs < _outpostsCount) then {
                _positions pushBack _pos;

                private _structures = [];
                private _vehicles = [];

                // Add a primary machinegun emplacement
                if (BATTLESPACE_DEFENDERS_STATIC_CLASSES isNotEqualTo []) then {
                    _vehicles pushBack (selectRandom BATTLESPACE_DEFENDERS_STATIC_CLASSES);
                };

                // Add a bunker for cover
                _structures pushBack (createHashMapFromArray [
                    ["position", _pos],
                    ["rotation", false],
                    ["className", "Land_BagBunker_01_large_green_F"]
                ]);

                // Whether to include an AGS
                if((random 100) <= 99 && {BATTLESPACE_DEFENDERS_STATIC_CLASSES isNotEqualTo []}) then {
                    _vehicles pushBack (selectRandom BATTLESPACE_DEFENDERS_STATIC_CLASSES);
                };

                // Include some supporting infantry
                private _composition = createHashMapFromArray [
                    ["manpower", round(BATTLESPACE_SQUAD_SIZE + random(BATTLESPACE_SQUAD_SIZE))],
                    ["vehicles", _vehicles],
                    ["structures",
                        _structures
                    ]
                ];

                ["Outpost", _composition, _pos, _pos, _objPos] call _createFundedDefender;
            };
        };
    };

    // Prepare valid non-water overlook ambush positions
    private _overlookPlaces = selectBestPlaces [_objPos vectorAdd (_dirToBluforSector vectorMultiply 200), _maximumRange, "5 * meadow + 10 * hills - 10 * houses + 5 * forest - 50 * sea", 50, 50];
    _overlookPlaces = _overlookPlaces select {
        _x params ["_pos", "_expr"];

        private _likeness = _objPos vectorFromTo (_pos);
        _likeness = _likeness vectorDotProduct _dirToBluforSector;

        _likeness >= 0 && !surfaceIsWater _pos
    };

    // Spawn ambush patrols in wait
    private _overlookCount = (count _overlookPlaces);
    if(_overlookCount > 0 && {BATTLESPACE_DEFENDERS_STATIC_CLASSES isNotEqualTo []}) then {
        for "_i" from 1 to _ambushSquads do {
            private _spotToUse = selectRandom _overlookPlaces;
            private _pos = _spotToUse#0;

            private _execs = 0;
            while {
                private _invalid = false;
                {
                    if((_x distance2D _pos) <= 200) exitWith { _invalid = true };
                } forEach _positions;

                if(surfaceIsWater _pos) then {
                    _invalid = false;
                };
                _invalid && _execs < _overlookCount
            } do {
                _pos = (selectRandom _overlookPlaces)#0;
                _execs = _execs + 1;
            };
            
            if(_execs < _overlookCount) then {
                _positions pushBack _pos;
                private _staticClass = selectRandom BATTLESPACE_DEFENDERS_STATIC_CLASSES;
                private _composition = createHashMapFromArray [
                    ["manpower", round(BATTLESPACE_SQUAD_SIZE + random(BATTLESPACE_SQUAD_SIZE))],
                    ["vehicles", [_staticClass]],
                    ["structures", []]
                ];

                ["Ambush Patrol", _composition, _pos, _pos, _objPos] call _createFundedDefender;
            };
        };
    };

    // Spawn defenders around the point itself
    for "_i" from 1 to _defensivePatrols do {
        private _def = selectRandom BATTLESPACE_DEFENDERS_MECHANIZED_PATROL_DEFS;
        private _mechanized = (random 100) < 25;

        private _composition = createHashMapFromArray [
            ["manpower", [BATTLESPACE_SQUAD_SIZE,_def#1] select _mechanized],
            ["vehicles", [[], _def#0] select _mechanized],
            ["structures", []]
        ];
        // TODO: Make it more intelligent and go towards BLUFOR sectors
        private _position = _objPos getPos [100 + random 150, random 360];

        private _execs = 0;
        while { surfaceIsWater _position && _execs < 25 } do {
            // Use more relaxed position if water is involved to maximise chance of spawning
            _position = _objPos getPos [100 + (random 350) + (_execs * 5), random 360];
            _execs = _execs + 1;
        };

        if(_execs < 25) then {
            ["Defensive Patrol", _composition, _position, _position, _objPos] call _createFundedDefender;
        };
    };

    // Spawn defenders on top in the actual point
    if (BATTLESPACE_DEFENDERS_VEHICLE_CLASSES isEqualTo []) then {_garrisonCount = 0};
    for "_i" from 1 to _garrisonCount do {
        private _vehicleClass = selectRandom BATTLESPACE_DEFENDERS_VEHICLE_CLASSES;
        private _pos = _objPos getPos [random 150, random 360];

        private _execs = 0;
        while { surfaceIsWater _pos && _execs < 25 } do {
            // Use more relaxed position if water is involved to maximise chance of spawning
            _pos = _objPos getPos [50 + (random 300) + (_execs * 5), random 360];
            _execs = _execs + 1;
        };

        if(_execs < 25) then {
            private _composition = createHashMapFromArray [
                ["manpower", round(BATTLESPACE_SQUAD_SIZE + random(BATTLESPACE_SQUAD_SIZE))],
                ["vehicles", [_vehicleClass]],
                ["structures", []]
            ];
            private _position = _objPos getPos [random 200, random 360];

            ["Garrison", _composition, _position, [], _objPos] call _createFundedDefender;
        };
    };

    // Spawning static guns/mortars/etc around a point
    private _statics = [];
    if (BATTLESPACE_DEFENDERS_STATIC_CLASSES isEqualTo []) then {_numberOfStatics = 0};
    for "_i" from 1 to _numberOfStatics do {
        private _vehicleClass = selectRandom BATTLESPACE_DEFENDERS_STATIC_CLASSES;

        private _expr = selectRandom BATTLESPACE_DEFENDERS_STATIC_EXPRESSIONS;

        if(_vehicleClass in BATTLESPACE_MORTARS) then {
            _expr = selectRandom BATTLESPACE_MORTAR_OVERRIDE_EXPRESSIONS;
        };

        private _potentialSpawns = selectBestPlaces [_objPos, 350, _expr, 20, 25];
        private _pos = (selectRandom _potentialSpawns)#0;
        private _execs = 0;
        private _potentialSpawnsCount = (count _potentialSpawns);

        while { 
            private _invalid = false;
            {
                if((_x distance2D _pos) <= 100) exitWith { _invalid = true };
            } forEach _positions;

            _invalid && _execs < _potentialSpawnsCount
        } do {
            _pos = (selectRandom _potentialSpawns)#0;
            _execs = _execs + 1;
        };

        if(_execs < _potentialSpawnsCount) then {
            private _spawnPoint = _pos findEmptyPosition [0, 100, _vehicleClass];


            if((isNil { _spawnPoint }) || (_spawnPoint isEqualTo [])) then {
                diag_log format ["  No valid spawn point was found for %1!"];
                continue;
            } else {
                private _spawn = [_spawnPoint, 0, 15, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;

                if((isNil { _spawn }) || (_spawn isEqualTo [])) then {
                    diag_log format ["  Could not find a valid spawn point with BIS_fnc_findSafePos for %1. Found %2, spawnPoint is %3", _vehicleClass, _spawn, _spawnPoint];
                    _spawn = _spawnPoint;
                };

                
                _statics pushBack (createHashMapFromArray [
                    ["className", _vehicleClass],
                    ["rotation", true],
                    ["position", _spawn vectorAdd [0,0,0.2]]
                ]);

                _positions pushBack _pos;
            };
        };
    };
    private _comp = createHashMapFromArray [
        ["manpower", 0],
        ["vehicles", []],
        ["structures", _statics]
    ];
    ["Fortifications", _comp, _objPos, [], _objPos] call _createFundedDefender;

    // Ambient civilians are persistent Battlespace forces. Reuse the sector
    // identity across ownership changes so OPFOR recapture cannot duplicate them.
    private _spawnCivilians = _sector in sectors_bigtown || _sector in sectors_capture || _sector in sectors_factory;
    if (_spawnCivilians) then {
        private _targetCivilianCount = round (2 * GRLIB_civilian_activity);
        private _existingCivilianCount = 0;

        {
            private _taskForce = _y;
            if ((_taskForce param [0, ""]) != "Civilians") then {continue};
            if ((_taskForce param [6, GRLIB_side_enemy]) != GRLIB_side_civilian) then {continue};

            private _homeSector = _taskForce param [12, ""];
            if (_homeSector == "") then {
                private _homePoint = _taskForce param [10, []];
                if (_homePoint isEqualType [] && {(count _homePoint) in [2, 3]}) then {
                    _homeSector = [sectors_allSectors, _homePoint] call BIS_fnc_nearestPosition;
                    _taskForce set [12, _homeSector];
                };
            };

            if (_homeSector == _sector) then {
                _existingCivilianCount = _existingCivilianCount + 1;
            };
        } forEach BATTLESPACE_TASK_FORCES;

        private _missingCivilianCount = _targetCivilianCount - _existingCivilianCount;
        if (_missingCivilianCount > 0) then {
            for "_i" from 1 to _missingCivilianCount do {
                private _composition = createHashMapFromArray [
                    ["manpower", 1],
                    ["vehicles", []],
                    ["structures", []]
                ];
                private _taskForceName = ["Civilians", _composition, _objPos, _objPos, _objPos, GRLIB_side_civilian] call BATTLESPACE_TASK_FORCES_INIT;
                if (_taskForceName != "") then {
                    (BATTLESPACE_TASK_FORCES get _taskForceName) set [12, _sector];
                };
            };
        };
    };

    // Roll for AA groups
    private _aaCount = 0;
    if((random 100) <= 10) then {
        _aaCount = 1;
    };
    if((random 100) <= 5) then {
        _aaCount = 2;
    };
    if (BATTLESPACE_SAM_SITE_TELS isEqualTo []) then {_aaCount = 0};

    // Spawn AA groups
    for "_i" from 1 to _aaCount do {
        private _aaPlaces = selectBestPlaces [_objPos vectorAdd (_dirToBluforSector vectorMultiply -200), 350, "2 * hills + 3 * meadow - 1 * houses - 1 * trees - 1 * forest - 50 * sea", 50, 40];
        _aaPlaces = _aaPlaces select {
            _x params ["_pos", "_expr"];
            
            private _likeness = _objPos vectorFromTo (_pos);
            _likeness = _likeness vectorDotProduct _dirToBluforSector;

            _likeness < 0 && !surfaceIsWater _pos
        };
        private _aaPlacesCount = (count _aaPlaces);
        if (_aaPlacesCount == 0) then {continue};

        private _vehicles = [];
        if (BATTLESPACE_SAM_SITE_TELS isNotEqualTo []) then {_vehicles pushBack (selectRandom BATTLESPACE_SAM_SITE_TELS)};

        if((random 100) <= 65 && {BATTLESPACE_SAM_SITE_TELS isNotEqualTo []}) then {
            _vehicles pushBack (selectRandom BATTLESPACE_SAM_SITE_TELS);
        };

        private _aaComp = createHashMapFromArray [
            ["manpower", [0, 4] select ((random 100) <= 20)],
            ["vehicles", _vehicles],
            ["structures", []]
        ];
        private _pos = (selectRandom _aaPlaces)#0;
        private _execs = 0;
        while { 
            private _invalid = false;
            {
                if((_x distance2D _pos) <= 200) exitWith { _invalid = true };
            } forEach _positions;

            if(surfaceIsWater _pos) then {
                _invalid = false;
            };
            _invalid && _execs < _aaPlacesCount
        } do {
            _pos = (selectRandom _aaPlaces)#0;
            _execs = _execs + 1;
        };

        if(_execs < _aaPlacesCount) then {
            _positions pushBack _pos;
            ["Anti-Air", _aaComp, _pos, _pos, _objPos] call _createFundedDefender;
        };
    };

    diag_log format ["Defender Create Task Forces done at %1 (%2)", _sector, diag_tickTime];
};
