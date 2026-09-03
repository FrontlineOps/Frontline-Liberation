/*
    Server-authoritative strategic sector stockpiles and logistics.

    Physical entities are always created by the existing Battlespace task-force
    models. This module owns only strategic state, transactions, dispatch, and
    settlement.
*/

BATTLESPACE_LOGISTICS_SAVE_KEY = format ["Battlespace/Logistics/%1", toUpper worldName];
BATTLESPACE_RESOURCE_TYPES = [
    "manpower",
    "construction_supplies",
    "strategic_sam",
    "strategic_missiles",
    "tactical_sam",
    "tactical_missiles",
    "aircraft",
    "tanks",
    "rocket_artillery",
    "rockets",
    "howitzers",
    "mortars",
    "spaag",
    "ifv",
    "apc",
    "car",
    "truck"
];

if (isNil "BATTLESPACE_SECTOR_STATES") then {
    BATTLESPACE_SECTOR_STATES = createHashMap;
};
if (isNil "BATTLESPACE_STRATEGIC_OPERATIONS") then {
    BATTLESPACE_STRATEGIC_OPERATIONS = createHashMap;
};
if (isNil "BATTLESPACE_LOGISTICS_MISSING_ENTRY_WARNED") then {
    BATTLESPACE_LOGISTICS_MISSING_ENTRY_WARNED = createHashMap;
};
if (isNil "BATTLESPACE_LOGISTICS_ENTRY_ANCHORS") then {
    BATTLESPACE_LOGISTICS_ENTRY_ANCHORS = createHashMap;
};

BATTLESPACE_RESOURCE_CLASS_POOLS = createHashMap;

BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED = {
    isServer && {!isRemoteExecuted || {remoteExecutedOwner == 2}}
};

BATTLESPACE_STRATEGIC_LOG = {
    params ["_message", ["_level", "BATTLESPACE"]];
    [_message, _level] call KPLIB_fnc_log;
};

BATTLESPACE_COPY_RESOURCE_MAP = {
    params ["_source"];
    private _copy = createHashMap;
    if (typeName _source == "HASHMAP") then {
        {
            _copy set [_x, _y];
        } forEach _source;
    };
    _copy
};

BATTLESPACE_SECTOR_GET_TYPE = {
    params ["_sector"];
    switch (true) do {
        case (_sector in sectors_military): { "military" };
        case (_sector in sectors_bigtown): { "bigtown" };
        case (_sector in sectors_capture): { "capture" };
        case (_sector in sectors_tower): { "tower" };
        case (_sector in sectors_factory): { "factory" };
        default { "" };
    }
};

BATTLESPACE_SECTOR_GET_THRESHOLD_MAP = {
    params ["_sectorType", "_thresholdType"];
    private _typeThresholds = BATTLESPACE_THRESHOLDS getOrDefault [_sectorType, createHashMap];
    _typeThresholds getOrDefault [_thresholdType, createHashMap]
};

BATTLESPACE_SECTOR_GET_CAPACITY = {
    params ["_sectorType", "_resourceType"];
    private _capacities = [_sectorType, "MaximumCapacity"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
    _capacities getOrDefault [_resourceType, 0]
};

BATTLESPACE_SECTOR_CREATE_STATE = {
    params ["_sector", ["_fillRatio", 0]];

    private _sectorType = [_sector] call BATTLESPACE_SECTOR_GET_TYPE;
    if (_sectorType == "") exitWith { nil };

    private _owner = ["OPFOR", "BLUFOR"] select (_sector in blufor_sectors);
    private _resources = createHashMap;
    {
        private _capacity = [_sectorType, _x] call BATTLESPACE_SECTOR_GET_CAPACITY;
        private _amount = 0;
        if (_owner == "OPFOR") then {
            _amount = floor (_capacity * (_fillRatio max 0 min 1));
        };
        _resources set [_x, _amount];
    } forEach BATTLESPACE_RESOURCE_TYPES;

    createHashMapFromArray [
        ["sector", _sector],
        ["type", _sectorType],
        ["owner", _owner],
        ["resources", _resources],
        ["lastOwnerChange", CBA_missionTime],
        ["nextResupplyAt", 0],
        ["nextBattlegroupAt", 0],
        ["nextBattlegroupTargetAt", 0],
        ["nextEmergencyAt", 0],
        ["nextReinforcementAt", 0],
        ["nextDeepReconAt", 0],
        ["nextAirResponseAt", 0],
        ["nextFortificationAt", 0],
        ["casualtyPressure", 0],
        ["lastCasualtyAt", -1]
    ]
};

BATTLESPACE_SECTOR_GET_STATE = {
    params ["_sector"];
    BATTLESPACE_SECTOR_STATES get _sector
};

BATTLESPACE_SECTOR_SET_OWNER = {
    params ["_sector", "_owner"];
    if (!([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) || {!(_owner in ["OPFOR", "BLUFOR"])}) exitWith { false };

    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state") exitWith { false };
    if ((_state getOrDefault ["owner", ""]) == _owner) exitWith { true };

    private _resources = _state get "resources";
    {
        _resources set [_x, 0];
    } forEach BATTLESPACE_RESOURCE_TYPES;

    _state set ["owner", _owner];
    _state set ["resources", _resources];
    _state set ["lastOwnerChange", CBA_missionTime];
    _state set [
        "nextResupplyAt",
        CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESUPPLY_COOLDOWN", 1800])
    ];
    _state set [
        "nextBattlegroupAt",
        CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_BATTLEGROUP_COOLDOWN", 3600])
    ];
    _state set ["nextEmergencyAt", CBA_missionTime];
    _state set ["nextReinforcementAt", CBA_missionTime];
    _state set ["nextDeepReconAt", CBA_missionTime];
    _state set ["nextAirResponseAt", CBA_missionTime];
    _state set ["nextFortificationAt", CBA_missionTime];
    _state set ["casualtyPressure", 0];
    _state set ["lastCasualtyAt", -1];
    BATTLESPACE_SECTOR_STATES set [_sector, _state];
    true
};

BATTLESPACE_SECTOR_SYNC_OWNERS = {
    if (!isServer) exitWith {};
    private _ownerChanges = [];
    {
        private _expectedOwner = ["OPFOR", "BLUFOR"] select (_x in blufor_sectors);
        if ((_y getOrDefault ["owner", ""]) != _expectedOwner) then {
            _ownerChanges pushBack [_x, _expectedOwner];
        };
    } forEach BATTLESPACE_SECTOR_STATES;
    {
        _x params ["_sector", "_owner"];
        [_sector, _owner] call BATTLESPACE_SECTOR_SET_OWNER;
        [format ["Strategic ownership reconciled for %1 to %2", _sector, _owner]] call BATTLESPACE_STRATEGIC_LOG;
    } forEach _ownerChanges;
};

BATTLESPACE_RESOURCE_APPLY_STRICT = {
    params ["_sector", "_deltas"];
    if (!([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) || {typeName _deltas != "HASHMAP"}) exitWith { false };

    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith { false };

    private _sectorType = _state get "type";
    private _resources = _state get "resources";
    private _proposed = createHashMap;
    private _valid = true;

    {
        if !(_x in BATTLESPACE_RESOURCE_TYPES) then {
            _valid = false;
            continue;
        };
        if !(_y isEqualType 0) then {
            _valid = false;
            continue;
        };

        private _current = _resources getOrDefault [_x, 0];
        private _capacity = [_sectorType, _x] call BATTLESPACE_SECTOR_GET_CAPACITY;
        private _next = _current + _y;
        if (_next < 0 || {_next > _capacity}) then {
            _valid = false;
        } else {
            _proposed set [_x, _next];
        };
    } forEach _deltas;

    if (!_valid) exitWith { false };
    {
        _resources set [_x, _y];
    } forEach _proposed;
    _state set ["resources", _resources];
    BATTLESPACE_SECTOR_STATES set [_sector, _state];
    true
};

BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED = {
    params ["_sector", "_amounts"];
    private _accepted = createHashMap;
    if (!([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) || {typeName _amounts != "HASHMAP"}) exitWith { _accepted };

    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith { _accepted };

    private _sectorType = _state get "type";
    private _resources = _state get "resources";
    {
        if !(_x in BATTLESPACE_RESOURCE_TYPES) then { continue };
        if !(_y isEqualType 0) then { continue };

        private _requested = (round _y) max 0;
        private _capacity = [_sectorType, _x] call BATTLESPACE_SECTOR_GET_CAPACITY;
        private _current = _resources getOrDefault [_x, 0];
        private _received = _requested min ((_capacity - _current) max 0);
        if (_received > 0) then {
            _resources set [_x, _current + _received];
            _accepted set [_x, _received];
        };
    } forEach _amounts;

    _state set ["resources", _resources];
    BATTLESPACE_SECTOR_STATES set [_sector, _state];
    _accepted
};

BATTLESPACE_STRATEGIC_SERIALIZE_OPERATION = {
    params ["_operation"];
    private _saved = [_operation] call BATTLESPACE_COPY_RESOURCE_MAP;
    if ("captureStartedAt" in _saved) then {
        _saved set ["captureAge", (CBA_missionTime - (_saved getOrDefault ["captureStartedAt", CBA_missionTime])) max 0];
        _saved deleteAt "captureStartedAt";
    };
    {
        if (_x in _saved) then {
            _saved set [_x + "Remaining", ((_saved getOrDefault [_x, CBA_missionTime]) - CBA_missionTime) max 0];
            _saved deleteAt _x;
        };
    } forEach ["expiresAt", "loiterUntil", "contactGraceUntil"];
    _saved
};

BATTLESPACE_STRATEGIC_DESERIALIZE_OPERATION = {
    params ["_savedOperation"];
    private _operation = [_savedOperation] call BATTLESPACE_COPY_RESOURCE_MAP;
    if ("captureAge" in _operation) then {
        _operation set ["captureStartedAt", CBA_missionTime - (_operation getOrDefault ["captureAge", 0])];
        _operation deleteAt "captureAge";
    };
    {
        private _remainingKey = _x + "Remaining";
        if (_remainingKey in _operation) then {
            _operation set [_x, CBA_missionTime + (_operation getOrDefault [_remainingKey, 0])];
            _operation deleteAt _remainingKey;
        };
    } forEach ["expiresAt", "loiterUntil", "contactGraceUntil"];
    _operation
};

BATTLESPACE_LOGISTICS_SAVE = {
    if (!isServer || {missionNamespace getVariable ["BATTLESPACE_LOGISTICS_SAVING", false]}) exitWith { false };
    BATTLESPACE_LOGISTICS_SAVING = true;
    if (missionNamespace getVariable ["BATTLESPACE_TASK_FORCES_PERSISTENT", false]) then {
        [false] call BATTLESPACE_TASK_FORCES_SAVE;
    };
    private _savedSectors = createHashMap;
    {
        private _state = _y;
        private _persistedResources = [(_state getOrDefault ["resources", createHashMap])] call BATTLESPACE_COPY_RESOURCE_MAP;
        if (!isNil "BATTLESPACE_STRATEGIC_ADD_DEPLOYED_ASSETS_TO_SNAPSHOT") then {
            [_x, _state getOrDefault ["type", ""], _persistedResources] call BATTLESPACE_STRATEGIC_ADD_DEPLOYED_ASSETS_TO_SNAPSHOT;
        };
        _savedSectors set [_x, createHashMapFromArray [
            ["owner", _state getOrDefault ["owner", "BLUFOR"]],
            ["resources", _persistedResources],
            ["ownerAge", (CBA_missionTime - (_state getOrDefault ["lastOwnerChange", CBA_missionTime])) max 0],
            ["resupplyCooldown", ((_state getOrDefault ["nextResupplyAt", 0]) - CBA_missionTime) max 0],
            ["battlegroupCooldown", ((_state getOrDefault ["nextBattlegroupAt", 0]) - CBA_missionTime) max 0],
            ["battlegroupTargetCooldown", ((_state getOrDefault ["nextBattlegroupTargetAt", 0]) - CBA_missionTime) max 0],
            ["emergencyCooldown", ((_state getOrDefault ["nextEmergencyAt", 0]) - CBA_missionTime) max 0],
            ["reinforcementCooldown", ((_state getOrDefault ["nextReinforcementAt", 0]) - CBA_missionTime) max 0],
            ["deepReconCooldown", ((_state getOrDefault ["nextDeepReconAt", 0]) - CBA_missionTime) max 0],
            ["airResponseCooldown", ((_state getOrDefault ["nextAirResponseAt", 0]) - CBA_missionTime) max 0],
            ["fortificationCooldown", ((_state getOrDefault ["nextFortificationAt", 0]) - CBA_missionTime) max 0],
            ["casualtyPressure", (_state getOrDefault ["casualtyPressure", 0]) max 0],
            ["lastCasualtyAge", if ((_state getOrDefault ["lastCasualtyAt", -1]) < 0) then {-1} else {(CBA_missionTime - (_state get "lastCasualtyAt")) max 0}]
        ]];
    } forEach BATTLESPACE_SECTOR_STATES;

    private _savedOperations = createHashMap;
    {
        _savedOperations set [_x, [_y] call BATTLESPACE_STRATEGIC_SERIALIZE_OPERATION];
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;

    profileNamespace setVariable [BATTLESPACE_LOGISTICS_SAVE_KEY, createHashMapFromArray [
        ["sectors", _savedSectors],
        ["operations", _savedOperations]
    ]];
    saveProfileNamespace;
    BATTLESPACE_LOGISTICS_SAVING = false;
    true
};

BATTLESPACE_LOGISTICS_LOAD = {
    if (!isServer) exitWith { false };

    if (
        (missionNamespace getVariable ["GRLIB_param_wipe_savegame_1", 0]) == 1
        && {(missionNamespace getVariable ["GRLIB_param_wipe_savegame_2", 0]) == 1}
    ) then {
        profileNamespace setVariable [BATTLESPACE_LOGISTICS_SAVE_KEY, nil];
        saveProfileNamespace;
    };

    private _save = profileNamespace getVariable [BATTLESPACE_LOGISTICS_SAVE_KEY, createHashMap];
    private _saveValid = typeName _save == "HASHMAP"
        && {typeName (_save getOrDefault ["sectors", objNull]) == "HASHMAP"}
        && {typeName (_save getOrDefault ["operations", objNull]) == "HASHMAP"};
    private _savedSectors = if (_saveValid) then {_save get "sectors"} else {createHashMap};
    private _initialFill = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_INITIAL_STOCK_RATIO", 0.75];

    if (!_saveValid && {missionNamespace getVariable ["BATTLESPACE_TASK_FORCES_PERSISTENT", false]}) then {
        BATTLESPACE_TASK_FORCES = createHashMap;
        BATTLESPACE_TASK_FORCE_PATHS = createHashMap;
        BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS = createHashMap;
    };

    BATTLESPACE_SECTOR_STATES = createHashMap;
    {
        private _sector = _x;
        private _state = [_sector, _initialFill] call BATTLESPACE_SECTOR_CREATE_STATE;
        if (isNil "_state") then { continue };

        private _savedState = _savedSectors get _sector;
        private _currentOwner = _state get "owner";
        if (!isNil "_savedState" && {typeName _savedState == "HASHMAP"}) then {
            private _savedOwner = _savedState getOrDefault ["owner", ""];
            if (_savedOwner == _currentOwner && {_currentOwner == "OPFOR"}) then {
                private _savedResources = _savedState getOrDefault ["resources", createHashMap];
                private _resources = _state get "resources";
                private _sectorType = _state get "type";
                if (typeName _savedResources == "HASHMAP") then {
                    {
                        private _capacity = [_sectorType, _x] call BATTLESPACE_SECTOR_GET_CAPACITY;
                        private _value = _savedResources getOrDefault [_x, 0];
                        if !(_value isEqualType 0) then { _value = 0 };
                        _resources set [_x, (round _value) max 0 min _capacity];
                    } forEach BATTLESPACE_RESOURCE_TYPES;
                };
                _state set ["resources", _resources];
            };

            if (_savedOwner == _currentOwner) then {
                _state set ["lastOwnerChange", CBA_missionTime - (_savedState getOrDefault ["ownerAge", 0])];
                _state set ["nextResupplyAt", CBA_missionTime + (_savedState getOrDefault ["resupplyCooldown", 0])];
                _state set ["nextBattlegroupAt", CBA_missionTime + (_savedState getOrDefault ["battlegroupCooldown", 0])];
                _state set ["nextBattlegroupTargetAt", CBA_missionTime + (_savedState getOrDefault ["battlegroupTargetCooldown", 0])];
                _state set ["nextEmergencyAt", CBA_missionTime + (_savedState getOrDefault ["emergencyCooldown", 0])];
                _state set ["nextReinforcementAt", CBA_missionTime + (_savedState getOrDefault ["reinforcementCooldown", 0])];
                _state set ["nextDeepReconAt", CBA_missionTime + (_savedState getOrDefault ["deepReconCooldown", 0])];
                _state set ["nextAirResponseAt", CBA_missionTime + (_savedState getOrDefault ["airResponseCooldown", 0])];
                _state set ["nextFortificationAt", CBA_missionTime + (_savedState getOrDefault ["fortificationCooldown", 0])];
                _state set ["casualtyPressure", (_savedState getOrDefault ["casualtyPressure", 0]) max 0];
                private _lastCasualtyAge = _savedState getOrDefault ["lastCasualtyAge", -1];
                _state set ["lastCasualtyAt", if (_lastCasualtyAge < 0) then {-1} else {CBA_missionTime - _lastCasualtyAge}];
            };
        };
        BATTLESPACE_SECTOR_STATES set [_sector, _state];
    } forEach sectors_allSectors;

    BATTLESPACE_STRATEGIC_OPERATIONS = createHashMap;
    private _savedOperations = if (_saveValid) then {_save getOrDefault ["operations", createHashMap]} else {createHashMap};
    if (typeName _savedOperations == "HASHMAP") then {
        {
            if (!isNil {BATTLESPACE_TASK_FORCES get _x} && {typeName _y == "HASHMAP"}) then {
                private _operation = [_y] call BATTLESPACE_STRATEGIC_DESERIALIZE_OPERATION;
                BATTLESPACE_STRATEGIC_OPERATIONS set [_x, _operation];
                if ((_operation getOrDefault ["kind", ""]) == "DEFENDER") then {
                    if (isNil "BATTLESPACE_DEFENDERS_SECTORS_SPAWNED") then {BATTLESPACE_DEFENDERS_SECTORS_SPAWNED = createHashMap};
                    BATTLESPACE_DEFENDERS_SECTORS_SPAWNED set [_operation getOrDefault ["fundingSector", ""], true];
                };
            };
        } forEach _savedOperations;
    };

    [format [
        "Strategic sector state %1: %2 current sectors",
        ["initialized", "loaded"] select _saveValid,
        count BATTLESPACE_SECTOR_STATES
    ]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_STRATEGIC_BUILD_CLASS_POOLS = {
    private _catalogs = missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap];
    private _opfor = _catalogs getOrDefault ["opfor", createHashMap];
    if (typeName _opfor != "HASHMAP") exitWith { false };

    private _validClasses = {
        params ["_classes"];
        (_classes select {
            _x isEqualType ""
            && {_x != ""}
            && {isClass (configFile >> "CfgVehicles" >> _x)}
        }) arrayIntersect _classes
    };
    private _containsText = {
        params ["_class", "_needles"];
        private _cfg = configFile >> "CfgVehicles" >> _class;
        private _haystack = toLower format ["%1 %2 %3", _class, getText (_cfg >> "displayName"), getText (_cfg >> "editorSubcategory")];
        (_needles findIf {(_haystack find _x) >= 0}) >= 0
    };

    private _all = [(_opfor getOrDefault ["allVehicles", []])] call _validClasses;
    private _aircraft = _all select {_x isKindOf "Air"};
    private _heavy = [(_opfor getOrDefault ["heavy", []])] call _validClasses;
    private _transport = [(_opfor getOrDefault ["transport", []])] call _validClasses;
    private _aa = [(_opfor getOrDefault ["aa", []])] call _validClasses;
    private _artillery = [(_opfor getOrDefault ["artillery", []])] call _validClasses;
    private _light = [(_opfor getOrDefault ["light", []]) + (_opfor getOrDefault ["recon", []])] call _validClasses;
    private _mobileGround = {
        params ["_classes"];
        _classes select {
            _x isKindOf "LandVehicle"
            && {!(_x isKindOf "StaticWeapon")}
        }
    };
    private _groundTransport = [_transport] call _mobileGround;
    private _trucks = [
        [(_opfor getOrDefault ["groundLogistics", []]) + _groundTransport] call _validClasses
    ] call _mobileGround;

    private _armoredTransport = _heavy select {
        getNumber (configFile >> "CfgVehicles" >> _x >> "transportSoldier") > 0
    };
    private _tanks = _heavy select {
        getNumber (configFile >> "CfgVehicles" >> _x >> "transportSoldier") <= 0
    };
    if (_tanks isEqualTo []) then { _tanks = +_heavy };
    if (_armoredTransport isEqualTo []) then {
        _armoredTransport = _transport select {_x isKindOf "Tank"};
    };
    private _apcs = +_groundTransport;
    if (_apcs isEqualTo []) then { _apcs = +_armoredTransport };

    private _rocketArtillery = _artillery select {[_x, ["mlrs", "rocket", "grad", "bm21", "bm-21"]] call _containsText};
    private _mortars = _artillery select {[_x, ["mortar"]] call _containsText};
    private _howitzers = _artillery - _rocketArtillery - _mortars;
    if (_howitzers isEqualTo []) then { _howitzers = +_artillery };

    BATTLESPACE_RESOURCE_CLASS_POOLS = createHashMapFromArray [
        ["strategic_sam", +_aa],
        ["tactical_sam", +_aa],
        ["aircraft", _aircraft],
        ["tanks", _tanks],
        ["rocket_artillery", _rocketArtillery],
        ["howitzers", _howitzers],
        ["mortars", _mortars],
        ["spaag", [_aa] call _mobileGround],
        ["ifv", _armoredTransport],
        ["apc", _apcs],
        ["car", _light],
        ["truck", _trucks],
        ["all", _all]
    ];
    true
};

BATTLESPACE_STRATEGIC_GET_CLASS_FOR_RESOURCE = {
    params ["_resourceType"];
    private _pool = BATTLESPACE_RESOURCE_CLASS_POOLS getOrDefault [_resourceType, []];
    if (_pool isEqualTo []) exitWith { "" };
    selectRandom _pool
};

BATTLESPACE_STRATEGIC_COUNT_OPERATIONS = {
    params ["_kind"];
    private _count = 0;
    {
        if ((_y getOrDefault ["kind", ""]) == _kind) then {
            _count = _count + 1;
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _count
};

BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET = {
    params ["_kind", "_targetSector"];
    private _found = false;
    {
        if (
            (_y getOrDefault ["kind", ""]) == _kind
            && {(_y getOrDefault ["targetSector", ""]) == _targetSector}
        ) exitWith {
            _found = true;
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _found
};

BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO = {
    params ["_taskForce", "_operation"];
    private _composition = _taskForce param [3, createHashMap];
    private _manpower = (_composition getOrDefault ["manpower", 0]) max 0;
    private _vehicles = _composition getOrDefault ["vehicles", []];
    private _currentStrength = _manpower + (4 * count _vehicles);
    private _initialStrength = (_operation getOrDefault ["initialStrength", _currentStrength]) max 1;
    (_currentStrength / _initialStrength) max 0 min 1
};

BATTLESPACE_STRATEGIC_SCALE_RESOURCES = {
    params ["_resources", "_ratio"];
    private _scaled = createHashMap;
    {
        private _amount = round ((_y max 0) * (_ratio max 0 min 1));
        if (_amount > 0) then {
            _scaled set [_x, _amount];
        };
    } forEach _resources;
    _scaled
};

BATTLESPACE_STRATEGIC_GET_SURVIVING_FORCE_RESOURCES = {
    params ["_taskForce", "_operation"];
    private _result = createHashMap;
    private _composition = _taskForce param [3, createHashMap];
    private _manpower = round ((_composition getOrDefault ["manpower", 0]) max 0);
    if (_manpower > 0) then { _result set ["manpower", _manpower] };

    private _activeObjects = _taskForce param [8, []];
    private _vehicleClasses = _composition getOrDefault ["vehicles", []];
    if (_activeObjects isNotEqualTo []) then {
        _vehicleClasses = (_activeObjects select {
            !isNull _x
            && {alive _x}
            && {!(_x isKindOf "Man")}
            && {!(_x getVariable ["KPLIB_captured", false])}
        }) apply {typeOf _x};
    };

    private _remainingManifest = +(_operation getOrDefault ["vehicleManifest", []]);
    {
        private _class = _x;
        private _index = _remainingManifest findIf {(_x param [0, ""]) == _class};
        if (_index >= 0) then {
            private _entry = _remainingManifest deleteAt _index;
            private _resourceType = _entry param [1, ""];
            if (_resourceType in BATTLESPACE_RESOURCE_TYPES) then {
                _result set [_resourceType, (_result getOrDefault [_resourceType, 0]) + 1];
            };
        };
    } forEach _vehicleClasses;
    _result
};

BATTLESPACE_STRATEGIC_RETIRE_PHYSICAL_FORCE = {
    params ["_taskForce"];
    private _activeObjects = +(_taskForce param [8, []]);
    private _activeGroups = +(_taskForce param [4, []]);

    // Delete personnel first, then vehicles. Player-captured vehicles leave the
    // strategic force and must remain in the world.
    {
        if (!isNull _x && {_x isKindOf "Man"}) then {
            deleteVehicle _x;
        };
    } forEach _activeObjects;
    {
        if (
            !isNull _x
            && {!(_x isKindOf "Man")}
            && {!(_x getVariable ["KPLIB_captured", false])}
        ) then {
            deleteVehicle _x;
        };
    } forEach _activeObjects;
    {
        if (!isNull _x) then {
            deleteGroup _x;
        };
    } forEach _activeGroups;
};

BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR = {
    params ["_position"];
    private _nearest = "";
    private _distance = 1e12;
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR") then { continue };
        private _candidateDistance = _position distance2D (getMarkerPos _x);
        if (_candidateDistance < _distance) then {
            _distance = _candidateDistance;
            _nearest = _x;
        };
    } forEach BATTLESPACE_SECTOR_STATES;
    _nearest
};

BATTLESPACE_CAPTURE_SECTOR_FOR_OPFOR = {
    params ["_sector"];
    if (!([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) || {!(_sector in blufor_sectors)} || {!(_sector in sectors_allSectors)}) exitWith { false };

    blufor_sectors = blufor_sectors - [_sector];
    sector_to_blufor = createHashMap;
    {
        sector_to_blufor set [_x, true];
    } forEach blufor_sectors;

    if (isNil "BATTLESPACE_DEFENDERS_SECTORS_SPAWNED") then {
        BATTLESPACE_DEFENDERS_SECTORS_SPAWNED = createHashMap;
    };
    BATTLESPACE_DEFENDERS_SECTORS_SPAWNED set [_sector, false];

    if (isNil "blufor_sectors_cap_times") then {
        blufor_sectors_cap_times = createHashMap;
    };
    blufor_sectors_cap_times set [_sector, CBA_missionTime];
    last_blufor_sector_change = CBA_missionTime;

    if (_sector in sectors_military) then {
        blufor_military_sectors = (missionNamespace getVariable ["blufor_military_sectors", []]) - [_sector];
        publicVariable "blufor_military_sectors";
    };

    if (_sector in sectors_factory && {!isNil "KP_liberation_production"}) then {
        {
            if !(_sector in _x) then { continue };
            private _storageDefinition = _x param [3, []];
            if (count _storageDefinition == 3) then {
                private _storage = (nearestObjects [
                    _storageDefinition param [0, markerPos _sector],
                    [KP_liberation_small_storage_building],
                    10
                ]) param [0, objNull];
                if (!isNull _storage) then {
                    {
                        detach _x;
                        deleteVehicle _x;
                    } forEach attachedObjects _storage;
                    deleteVehicle _storage;
                };
            };
            KP_liberation_production = KP_liberation_production - [_x];
        } forEach +KP_liberation_production;
    };

    [_sector, "OPFOR"] call BATTLESPACE_SECTOR_SET_OWNER;
    publicVariable "blufor_sectors";
    publicVariable "last_blufor_sector_change";
    [_sector, 2] remoteExec ["remote_call_sector", 0];

    if (!isNil "sectors_under_attack") then {
        sectors_under_attack set [_sector, false];
    };
    stats_sectors_lost = (missionNamespace getVariable ["stats_sectors_lost", 0]) + 1;
    if (!isNil "KPLIB_fnc_doSave") then {
        [] spawn KPLIB_fnc_doSave;
    };
    [format ["Strategic battlegroup captured sector %1", _sector]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_LOGISTICS_BUILD_REQUEST = {
    params ["_sector", ["_thresholdType", "Resupply"]];
    private _request = createHashMap;
    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith { _request };

    private _sectorType = _state get "type";
    private _resources = _state get "resources";
    private _thresholds = [_sectorType, _thresholdType] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
    {
        private _threshold = _thresholds getOrDefault [_x, -1];
        private _capacity = [_sectorType, _x] call BATTLESPACE_SECTOR_GET_CAPACITY;
        if (_threshold < 0 || {_capacity <= 0}) then { continue };

        private _current = _resources getOrDefault [_x, 0];
        private _desired = ceil (_capacity * _threshold);
        if (_current < _desired) then {
            private _batchLimit = (ceil (_capacity * 0.25)) max 1;
            _request set [_x, (_desired - _current) min _batchLimit];
        };
    } forEach BATTLESPACE_RESOURCE_TYPES;
    _request
};

BATTLESPACE_LOGISTICS_FIND_SECTOR_SOURCES = {
    params ["_targetSector", "_request"];
    private _candidates = [];
    private _targetNetwork = NETWORKED_SECTORS get _targetSector;
    if (isNil "_targetNetwork") exitWith { _candidates };

    {
        private _source = _x;
        private _state = BATTLESPACE_SECTOR_STATES get _source;
        if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) then { continue };

        private _sectorType = _state get "type";
        private _resources = _state get "resources";
        private _sendThresholds = [_sectorType, "ResupplySend"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
        private _cargo = createHashMap;
        private _total = 0;
        {
            private _resourceType = _x;
            private _threshold = _sendThresholds getOrDefault [_resourceType, -1];
            if (_threshold < 0) then { continue };

            private _capacity = [_sectorType, _resourceType] call BATTLESPACE_SECTOR_GET_CAPACITY;
            private _reserve = ceil (_capacity * _threshold);
            private _available = ((_resources getOrDefault [_resourceType, 0]) - _reserve) max 0;
            private _amount = _available min _y;
            if (_amount > 0) then {
                _cargo set [_resourceType, _amount];
                _total = _total + _amount;
            };
        } forEach _request;

        if (_total > 0) then {
            _candidates pushBack [_total, _source, _cargo];
        };
    } forEach (_targetNetwork getOrDefault ["Links", []]);

    _candidates = [_candidates, [], {_x param [0, 0]}, "DESCEND"] call BIS_fnc_sortBy;
    _candidates apply {[_x param [1, ""], _x param [2, createHashMap]]}
};

BATTLESPACE_LOGISTICS_BUILD_ENTRY_ANCHORS = {
    BATTLESPACE_LOGISTICS_ENTRY_ANCHORS = createHashMap;
    private _entries = allMapMarkers select {
        _x find "logistics_spawn" == 0
    };
    private _anchors = sectors_allSectors select {
        !isNil {NETWORKED_SECTORS get _x}
    };

    if (_anchors isNotEqualTo []) then {
        // An entry stops at its first/nearest gameplay objective; it never becomes a graph node.
        {
            private _entry = _x;
            private _anchor = [_anchors, getMarkerPos _entry] call BIS_fnc_nearestPosition;
            BATTLESPACE_LOGISTICS_ENTRY_ANCHORS set [_entry, _anchor];
        } forEach _entries;
    };

    [count _entries, count BATTLESPACE_LOGISTICS_ENTRY_ANCHORS]
};

BATTLESPACE_LOGISTICS_FIND_OFFMAP_SOURCE = {
    params ["_targetSector"];
    if (isNil {NETWORKED_SECTORS get _targetSector}) exitWith { "" };
    private _entryAnchors = BATTLESPACE_LOGISTICS_ENTRY_ANCHORS;
    if (count _entryAnchors == 0) exitWith { "" };

    private _anchorCandidates = [];
    {
        _anchorCandidates pushBackUnique _y;
    } forEach _entryAnchors;
    private _reachableAnchors = [
        _targetSector,
        _anchorCandidates,
        blufor_sectors + ["startbase_marker"]
    ] call NETWORKED_SECTORS_traverseGraphAndFindNodes;
    private _sources = [];
    {
        if (_y in _reachableAnchors) then {
            _sources pushBack _x;
        };
    } forEach _entryAnchors;
    if (_sources isEqualTo []) exitWith { "" };

    private _sorted = [_sources, [_targetSector], {
        (getMarkerPos _x) distance2D (getMarkerPos _input0)
    }, "ASCEND"] call BIS_fnc_sortBy;
    _sorted param [0, ""]
};

BATTLESPACE_LOGISTICS_CLAIM_CONVOY_CRATE = {
    params [
        ["_crate", objNull, [objNull]],
        ["_reason", "recovered", [""]]
    ];
    if (
        !isServer
        || {isNull _crate}
        || {_crate getVariable ["BATTLESPACE_CONVOY_CARGO_CLAIMED", false]}
    ) exitWith { false };

    private _taskForceId = _crate getVariable ["TASKFORCEID", ""];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    if (isNil "_operation" || {(_operation getOrDefault ["kind", ""]) != "CONVOY"}) exitWith { false };

    _crate setVariable ["BATTLESPACE_CONVOY_CARGO_CLAIMED", true, true];
    _crate setVariable ["KPLIB_captured", true, true];
    detach _crate;
    [_crate, true] remoteExec ["enableRopeAttach"];
    private _originalCarrier = _crate getVariable ["BATTLESPACE_CONVOY_CARGO_CARRIER", objNull];
    if (!isNull _originalCarrier) then {
        _originalCarrier setVariable ["BATTLESPACE_CONVOY_CARGO_OBJECT", objNull];
        _originalCarrier setVariable ["GRLIB_ammo_truck_load", 0, true];
    };

    private _total = (_operation getOrDefault ["cargoCrateCount", 0]) max 0;
    private _lost = ((_operation getOrDefault ["cargoCratesLost", 0]) + 1) min _total;
    _operation set ["cargoCratesLost", _lost];
    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];

    [format [
        "Convoy %1 cargo crate claimed (%2); %3/%4 cargo shares lost",
        _taskForceId,
        _reason,
        _lost,
        _total
    ]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_LOGISTICS_ATTACH_CONVOY_CRATES = {
    params ["_taskForceId", "_taskForce"];
    if (!isServer) exitWith { false };

    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    if (isNil "_operation" || {(_operation getOrDefault ["kind", ""]) != "CONVOY"}) exitWith { false };

    private _activeObjects = +(_taskForce param [8, []]);
    if (_activeObjects findIf {
        !isNull _x && {_x getVariable ["BATTLESPACE_CONVOY_CARGO_CRATE", false]}
    } >= 0) exitWith { true };

    private _remainingTruckClasses = ((_operation getOrDefault ["vehicleManifest", []]) select {
        (_x param [1, ""]) == "truck"
    }) apply {
        _x param [0, ""]
    };
    private _trucks = [];
    {
        if (isNull _x || {_x isKindOf "Man"}) then { continue };
        private _truckIndex = _remainingTruckClasses find (typeOf _x);
        if (_truckIndex >= 0) then {
            _trucks pushBack _x;
            _remainingTruckClasses deleteAt _truckIndex;
        };
    } forEach _activeObjects;

    private _crateValue = round (
        (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_CONVOY_CRATE_VALUE", 100])
        * GRLIB_resources_multiplier
    ) max 1;
    private _attached = 0;
    {
        private _truck = _x;
        private _crate = [selectRandom KPLIB_crates, _crateValue, getPosATL _truck] call KPLIB_fnc_createCrate;
        if (isNull _crate) then { continue };

        private _offset = [0, -1, 1];
        private _configIndex = KPLIB_transportConfigs findIf {
            toLower (_x param [0, ""]) == toLower (typeOf _truck)
        };
        if (_configIndex >= 0) then {
            _offset = (KPLIB_transportConfigs select _configIndex) param [2, _offset];
        };

        _crate setVariable ["BATTLESPACE_CONVOY_CARGO_CRATE", true, true];
        _crate setVariable ["BATTLESPACE_CONVOY_CARGO_CLAIMED", false, true];
        _crate setVariable ["BATTLESPACE_CONVOY_CARGO_CARRIER", _truck, true];
        _crate setVariable ["TASKFORCEID", _taskForceId];
        _crate attachTo [_truck, _offset];
        [_crate, false] remoteExec ["enableRopeAttach"];

        _truck setVariable ["BATTLESPACE_CONVOY_CARGO_OBJECT", _crate];
        _truck setVariable ["GRLIB_ammo_truck_load", 1, true];
        _truck addMPEventHandler ["MPKilled", {
            params ["_vehicle"];
            private _crate = _vehicle getVariable ["BATTLESPACE_CONVOY_CARGO_OBJECT", objNull];
            if (!isNull _crate) then {
                detach _crate;
                _crate setPosATL ((getPosATL _vehicle) vectorAdd [0, 0, 0.5]);
                [_crate, "carrier destroyed"] call BATTLESPACE_LOGISTICS_CLAIM_CONVOY_CRATE;
            };
        }];
        _crate addMPEventHandler ["MPKilled", {
            params ["_crate"];
            [_crate, "crate destroyed"] call BATTLESPACE_LOGISTICS_CLAIM_CONVOY_CRATE;
        }];

        _activeObjects pushBack _crate;
        _attached = _attached + 1;
    } forEach _trucks;

    _taskForce set [8, _activeObjects];
    BATTLESPACE_TASK_FORCES set [_taskForceId, _taskForce];
    [format [
        "Convoy %1 materialized with %2/%3 recoverable crates at %4 resources each",
        _taskForceId,
        _attached,
        _operation getOrDefault ["cargoCrateCount", 0],
        _crateValue
    ]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_LOGISTICS_BUILD_CONVOY = {
    private _vehicles = [];
    private _manifest = [];
    private _truckCount = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_CONVOY_TRUCKS", 2];
    for "_i" from 1 to _truckCount do {
        private _class = ["truck"] call BATTLESPACE_STRATEGIC_GET_CLASS_FOR_RESOURCE;
        if (_class == "") exitWith {};
        _vehicles pushBack _class;
        _manifest pushBack [_class, "truck"];
    };
    if (_vehicles isEqualTo []) exitWith { createHashMap };

    private _car = ["car"] call BATTLESPACE_STRATEGIC_GET_CLASS_FOR_RESOURCE;
    if (_car == "") exitWith { createHashMap };
    _vehicles pushBack _car;
    _manifest pushBack [_car, "car"];

    private _apcChance = ((missionNamespace getVariable ["BATTLESPACE_STRATEGIC_CONVOY_APC_CHANCE", 25]) max 0) min 100;
    if (random 100 < _apcChance) then {
        private _apc = ["apc"] call BATTLESPACE_STRATEGIC_GET_CLASS_FOR_RESOURCE;
        if (_apc != "") then {
            _vehicles pushBack _apc;
            _manifest pushBack [_apc, "apc"];
        };
    };

    private _manpower = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_CONVOY_MANPOWER", 8];
    createHashMapFromArray [
        ["composition", createHashMapFromArray [
            ["manpower", _manpower],
            ["vehicles", _vehicles],
            ["structures", []]
        ]],
        ["vehicleManifest", _manifest],
        ["initialStrength", _manpower + (4 * count _vehicles)]
    ]
};

BATTLESPACE_LOGISTICS_DISPATCH = {
    params ["_targetSector", "_request"];
    if (!([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) || {count _request == 0}) exitWith { false };

    private _convoyDefinition = [] call BATTLESPACE_LOGISTICS_BUILD_CONVOY;
    if (count _convoyDefinition == 0) exitWith {
        [format ["No generated OPFOR logistics trucks/car escort can service %1", _targetSector], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };

    private _sourceCandidates = [_targetSector, _request] call BATTLESPACE_LOGISTICS_FIND_SECTOR_SOURCES;
    private _sourceSector = "";
    private _sourceMarker = "";
    private _cargo = createHashMap;
    private _debit = createHashMap;
    private _debited = false;

    {
        _x params ["_candidateSector", "_candidateCargo"];
        private _candidateDebit = [_candidateCargo] call BATTLESPACE_COPY_RESOURCE_MAP;
        private _composition = _convoyDefinition get "composition";
        _candidateDebit set ["manpower", (_candidateDebit getOrDefault ["manpower", 0]) + (_composition get "manpower")];
        {
            private _resourceType = _x param [1, ""];
            _candidateDebit set [_resourceType, (_candidateDebit getOrDefault [_resourceType, 0]) + 1];
        } forEach (_convoyDefinition get "vehicleManifest");

        private _negativeDebit = createHashMap;
        {
            _negativeDebit set [_x, -_y];
        } forEach _candidateDebit;

        if ([_candidateSector, _negativeDebit] call BATTLESPACE_RESOURCE_APPLY_STRICT) exitWith {
            _sourceSector = _candidateSector;
            _sourceMarker = _candidateSector;
            _cargo = _candidateCargo;
            _debit = _candidateDebit;
            _debited = true;
        };

        [format [
            "Linked convoy donor %1 skipped for %2 because it cannot fund the complete cargo, manpower, and vehicle debit %3",
            _candidateSector,
            _targetSector,
            _candidateDebit
        ], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
    } forEach _sourceCandidates;

    if (!_debited) then {
        _sourceMarker = [_targetSector] call BATTLESPACE_LOGISTICS_FIND_OFFMAP_SOURCE;
        _cargo = [_request] call BATTLESPACE_COPY_RESOURCE_MAP;
        _debit = createHashMap;
    };
    if (_sourceMarker == "") exitWith {
        if !(BATTLESPACE_LOGISTICS_MISSING_ENTRY_WARNED getOrDefault [_targetSector, false]) then {
            BATTLESPACE_LOGISTICS_MISSING_ENTRY_WARNED set [_targetSector, true];
            [format [
                "Convoy for %1 was not dispatched: no linked OPFOR sector can fund it and no reachable logistics_spawn marker exists",
                _targetSector
            ], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        };
        false
    };
    BATTLESPACE_LOGISTICS_MISSING_ENTRY_WARNED deleteAt _targetSector;
    if (count _cargo == 0) exitWith { false };

    private _origin = getMarkerPos _sourceMarker;
    private _roads = _origin nearRoads 200;
    if (_roads isNotEqualTo []) then {
        _origin = getPos (selectRandom _roads);
    };
    private _target = getMarkerPos _targetSector;
    private _taskForceId = [
        "Convoy",
        _convoyDefinition get "composition",
        _origin,
        _target,
        getMarkerPos _sourceMarker
    ] call BATTLESPACE_TASK_FORCES_INIT;

    if (_taskForceId == "") exitWith {
        if (_debited) then {
            [_sourceSector, _debit] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
        };
        [format ["Convoy creation for %1 failed; sector debit refunded", _targetSector], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };

    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, createHashMapFromArray [
        ["kind", "CONVOY"],
        ["phase", "ENROUTE"],
        ["sourceSector", _sourceSector],
        ["sourceMarker", _sourceMarker],
        ["targetSector", _targetSector],
        ["cargo", _cargo],
        ["debit", _debit],
        ["vehicleManifest", _convoyDefinition get "vehicleManifest"],
        ["cargoCrateCount", {
            (_x param [1, ""]) == "truck"
        } count (_convoyDefinition get "vehicleManifest")],
        ["cargoCratesLost", 0],
        ["initialStrength", _convoyDefinition get "initialStrength"],
        ["outcome", ""]
    ]];

    private _targetState = BATTLESPACE_SECTOR_STATES get _targetSector;
    _targetState set [
        "nextResupplyAt",
        CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESUPPLY_COOLDOWN", 1800])
    ];
    BATTLESPACE_SECTOR_STATES set [_targetSector, _targetState];
    [] call BATTLESPACE_LOGISTICS_SAVE;
    [format [
        "Dispatched convoy %1 from %2 to %3 with vehicles %4 and cargo %5",
        _taskForceId,
        _sourceMarker,
        _targetSector,
        _convoyDefinition get "vehicleManifest",
        _cargo
    ]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_LOGISTICS_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    private _activeLimit = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_CONVOYS", 3];
    private _remainingSlots = _activeLimit - (["CONVOY"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS);
    private _perTick = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_CONVOYS_PER_TICK", 2];
    private _remaining = _remainingSlots min _perTick;
    if (_remaining <= 0) exitWith {};

    private _candidates = [];
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR") then { continue };
        if (CBA_missionTime < (_y getOrDefault ["nextResupplyAt", 0])) then { continue };
        if (["CONVOY", _x] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET) then { continue };

        private _request = [_x] call BATTLESPACE_LOGISTICS_BUILD_REQUEST;
        if (count _request == 0) then { continue };
        private _depth = [_x, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
        if (_depth < 0) then { _depth = 999 };
        _candidates pushBack [_depth, _x, _request];
    } forEach BATTLESPACE_SECTOR_STATES;

    _candidates = [_candidates, [], {_x param [0, 999]}, "ASCEND"] call BIS_fnc_sortBy;
    {
        if (_remaining <= 0) exitWith {};
        _x params ["_depth", "_sector", "_request"];
        if ([_sector, _request] call BATTLESPACE_LOGISTICS_DISPATCH) then {
            _remaining = _remaining - 1;
        };
    } forEach _candidates;
};

BATTLESPACE_STRATEGIC_HANDLE_TASK_FORCE_EVENT = {
    params ["_eventType", "_eventData"];
    _eventData params ["_taskForceId", "_taskForce"];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    if (isNil "_operation") exitWith {};

    // Claim settlement before doing any side effects so duplicate events are harmless.
    BATTLESPACE_STRATEGIC_OPERATIONS deleteAt _taskForceId;
    private _kind = _operation getOrDefault ["kind", ""];
    if (_kind == "AIR_RESPONSE") then {
        [_taskForceId, _operation, _eventType] call BATTLESPACE_AIR_RESPONSE_APPLY_TARGET_COOLDOWN;
    };

    if (_eventType == "DESTROYED") exitWith {
        if (_operation getOrDefault ["attackNotified", false]) then {
            [_operation getOrDefault ["targetSector", ""], 3] remoteExec ["remote_call_sector", 0];
        };
        [format ["Strategic %1 operation %2 was destroyed", _kind, _taskForceId]] call BATTLESPACE_STRATEGIC_LOG;
        [_taskForce] call BATTLESPACE_STRATEGIC_RETIRE_PHYSICAL_FORCE;
        [] call BATTLESPACE_LOGISTICS_SAVE;
    };

    switch (_kind) do {
        case "CONVOY": {
            private _outcome = _operation getOrDefault ["outcome", "DELIVERED"];
            private _destinationSector = switch (_outcome) do {
                case "RETURNED": {_operation getOrDefault ["sourceSector", ""]};
                case "DELIVERED": {_operation getOrDefault ["targetSector", ""]};
                default {""};
            };

            if (_destinationSector != "") then {
                private _crateCount = (_operation getOrDefault ["cargoCrateCount", 0]) max 0;
                private _cratesLost = (_operation getOrDefault ["cargoCratesLost", 0]) max 0 min _crateCount;
                private _ratio = if (_crateCount > 0) then {
                    (_crateCount - _cratesLost) / _crateCount
                } else {
                    [_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO
                };
                private _cargo = [
                    _operation getOrDefault ["cargo", createHashMap],
                    _ratio
                ] call BATTLESPACE_STRATEGIC_SCALE_RESOURCES;
                private _survivingForce = [
                    _taskForce,
                    _operation
                ] call BATTLESPACE_STRATEGIC_GET_SURVIVING_FORCE_RESOURCES;
                {
                    _cargo set [_x, (_cargo getOrDefault [_x, 0]) + _y];
                } forEach _survivingForce;
                private _accepted = [_destinationSector, _cargo] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
                [format [
                    "Convoy %1 %2 at %3 with %4/%5 cargo shares; cargo and surviving force accepted %6",
                    _taskForceId,
                    toLower _outcome,
                    _destinationSector,
                    _crateCount - _cratesLost,
                    _crateCount,
                    _accepted
                ]] call BATTLESPACE_STRATEGIC_LOG;
            };
        };
        case "BATTLEGROUP": {
            if (!isNil "BATTLESPACE_BATTLEGROUP_SETTLE") then {
                [_taskForceId, _taskForce, _operation] call BATTLESPACE_BATTLEGROUP_SETTLE;
            };
        };
        case "DEFENDER";
        case "REINFORCEMENT";
        case "AIRBORNE_TRANSPORT";
        case "AIRBORNE_REINFORCEMENT";
        case "DEEP RECONNAISSANCE PATROL";
        case "AIR_RESPONSE": {
            private _destinationSector = switch (_operation getOrDefault ["outcome", ""]) do {
                case "REINFORCED": {_operation getOrDefault ["targetSector", ""]};
                case "RETURNED": {_operation getOrDefault ["returnSector", _operation getOrDefault ["originSector", ""]]};
                default {""};
            };
            if (_destinationSector != "") then {
                private _survivors = [_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVING_FORCE_RESOURCES;
                private _accepted = [_destinationSector, _survivors] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
                [format ["Strategic %1 %2 settled at %3 with %4", _kind, _taskForceId, _destinationSector, _accepted]] call BATTLESPACE_STRATEGIC_LOG;
            };
        };
    };

    [_taskForce] call BATTLESPACE_STRATEGIC_RETIRE_PHYSICAL_FORCE;
    [] call BATTLESPACE_LOGISTICS_SAVE;
};

BATTLESPACE_STRATEGIC_RECONCILE_OPERATIONS = {
    private _stale = [];
    {
        if (isNil {BATTLESPACE_TASK_FORCES get _x}) then {
            _stale pushBack [_x, _y];
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    {
        _x params ["_taskForceId", "_operation"];
        BATTLESPACE_STRATEGIC_OPERATIONS deleteAt _taskForceId;
        if (_operation getOrDefault ["attackNotified", false]) then {
            [_operation getOrDefault ["targetSector", ""], 3] remoteExec ["remote_call_sector", 0];
        };
        [format ["Removed stale strategic operation %1", _taskForceId], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
    } forEach _stale;
};

BATTLESPACE_LOGISTICS_INIT = {
    if (!isServer) exitWith { false };
    if !([] call BATTLESPACE_STRATEGIC_BUILD_CLASS_POOLS) exitWith {
        ["Generated OPFOR catalog could not build strategic vehicle pools", "ERROR"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };
    private _loaded = [] call BATTLESPACE_LOGISTICS_LOAD;
    private _entryAnchorCounts = [] call BATTLESPACE_LOGISTICS_BUILD_ENTRY_ANCHORS;
    _entryAnchorCounts params ["_entryCount", "_mappedEntryCount"];
    BATTLESPACE_LOGISTICS_READY = _loaded;
    [format [
        "Strategic logistics initialized with %1/%2 off-map convoy entries mapped to their nearest objective anchors",
        _mappedEntryCount,
        _entryCount
    ], ["WARNING", "BATTLESPACE"] select (_entryCount > 0 && {_mappedEntryCount == _entryCount})] call BATTLESPACE_STRATEGIC_LOG;
    _loaded
};

if (isServer) then {
    ["BATTLESPACE/TASKFORCES/DONE", {
        ["DONE", _this] call BATTLESPACE_STRATEGIC_HANDLE_TASK_FORCE_EVENT;
    }] call CBA_fnc_addEventHandler;
    ["BATTLESPACE/TASKFORCES/DESTROYED", {
        ["DESTROYED", _this] call BATTLESPACE_STRATEGIC_HANDLE_TASK_FORCE_EVENT;
    }] call CBA_fnc_addEventHandler;

    [] spawn {
        waitUntil {sleep 1; !isNil "save_is_loaded" && {save_is_loaded}};
        waitUntil {sleep 1; !isNil "NETWORKED_SECTORS_LINKED" && {NETWORKED_SECTORS_LINKED}};
        waitUntil {sleep 1; !isNil "KPLIB_autoFactionCatalogs"};
        if !(missionNamespace getVariable ["BATTLESPACE_STRATEGIC_ENABLED", true]) exitWith {};
        if !([] call BATTLESPACE_LOGISTICS_INIT) exitWith {};

        private _nextDecision = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_INITIAL_DELAY", 300]);
        private _nextAirResponse = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_INITIAL_DELAY", 600]);
        private _nextSave = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_SAVE_INTERVAL", 300]);
        while {GRLIB_endgame == 0} do {
            [] call BATTLESPACE_SECTOR_SYNC_OWNERS;
            [] call BATTLESPACE_STRATEGIC_RECONCILE_OPERATIONS;
            if (!isNil "BATTLESPACE_TACTICAL_MAINTENANCE_TICK") then {
                [] call BATTLESPACE_TACTICAL_MAINTENANCE_TICK;
            };

            if (CBA_missionTime >= _nextDecision) then {
                [] call BATTLESPACE_LOGISTICS_DECISION_TICK;
                if (!isNil "BATTLESPACE_BATTLEGROUP_DECISION_TICK") then {
                    [] call BATTLESPACE_BATTLEGROUP_DECISION_TICK;
                };
                if (!isNil "BATTLESPACE_DEEP_RECON_DECISION_TICK") then {
                    [] call BATTLESPACE_DEEP_RECON_DECISION_TICK;
                };
                if (!isNil "BATTLESPACE_FORTIFICATION_DECISION_TICK") then {
                    [] call BATTLESPACE_FORTIFICATION_DECISION_TICK;
                };
                _nextDecision = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DECISION_INTERVAL", 1800]);
            };

            if (CBA_missionTime >= _nextAirResponse) then {
                if (!isNil "BATTLESPACE_AIR_RESPONSE_DECISION_TICK") then {
                    [] call BATTLESPACE_AIR_RESPONSE_DECISION_TICK;
                };
                _nextAirResponse = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_DECISION_INTERVAL", 60]);
            };

            if (CBA_missionTime >= _nextSave) then {
                [] call BATTLESPACE_LOGISTICS_SAVE;
                _nextSave = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_SAVE_INTERVAL", 300]);
            };
            sleep 30;
        };
        [] call BATTLESPACE_LOGISTICS_SAVE;
    };
};
