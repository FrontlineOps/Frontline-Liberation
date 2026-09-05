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
if (isNil "BATTLESPACE_LOGISTICS_EVACUATION_BLOCKED_WARNED") then {
    BATTLESPACE_LOGISTICS_EVACUATION_BLOCKED_WARNED = createHashMap;
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

BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY = {
    params ["_sector", "_resourceType", ["_sectorType", ""]];
    if (_sectorType == "") then {_sectorType = [_sector] call BATTLESPACE_SECTOR_GET_TYPE};
    private _baseCapacity = [_sectorType, _resourceType] call BATTLESPACE_SECTOR_GET_CAPACITY;
    if (_baseCapacity <= 0 || {_sector in blufor_sectors}) exitWith {_baseCapacity};
    private _multipliers = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS", [0.25, 0.5, 0.75, 1]];
    if (_multipliers isEqualTo []) exitWith {_baseCapacity};
    private _depth = [_sector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
    if (_depth < 0) exitWith {_baseCapacity};
    private _index = _depth min (count _multipliers - 1);
    floor (_baseCapacity * ((_multipliers param [_index, 1]) max 0 min 1))
};

BATTLESPACE_LOGISTICS_BUILD_FRONT_EXCESS = {
    params ["_sector"];
    private _excess = createHashMap;
    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {_excess};

    private _sectorType = _state getOrDefault ["type", ""];
    private _resources = _state getOrDefault ["resources", createHashMap];
    {
        private _capacity = [_sector, _x, _sectorType] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        private _amount = ((_resources getOrDefault [_x, 0]) - _capacity) max 0;
        if (_amount > 0) then {
            _excess set [_x, _amount];
        };
    } forEach BATTLESPACE_RESOURCE_TYPES;
    _excess
};

BATTLESPACE_SECTOR_CREATE_STATE = {
    params ["_sector", ["_fillRatio", 0]];

    private _sectorType = [_sector] call BATTLESPACE_SECTOR_GET_TYPE;
    if (_sectorType == "") exitWith { nil };

    private _owner = ["OPFOR", "BLUFOR"] select (_sector in blufor_sectors);
    private _resources = createHashMap;
    {
        private _capacity = [_sector, _x, _sectorType] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
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
        ["refillingResources", []],
        ["lastOwnerChange", CBA_missionTime],
        ["nextResupplyAt", 0],
        ["nextBattlegroupAt", 0],
        ["nextBattlegroupTargetAt", 0],
        ["nextEmergencyAt", 0],
        ["nextReinforcementAt", 0],
        ["nextDeepReconAt", 0],
        ["nextAirResponseAt", 0],
        ["nextFortificationAt", 0],
        ["nextMinefieldAt", 0],
        ["casualtyPressure", 0],
        ["lastCasualtyAt", -1]
    ]
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
    _state set ["refillingResources", []];
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
    _state set ["nextMinefieldAt", CBA_missionTime];
    _state set ["casualtyPressure", 0];
    _state set ["lastCasualtyAt", -1];
    BATTLESPACE_SECTOR_STATES set [_sector, _state];
    BATTLESPACE_LOGISTICS_EVACUATION_BLOCKED_WARNED deleteAt _sector;
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
        private _capacity = [_sector, _x, _sectorType] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        private _next = _current + _y;
        if (_next < 0 || {_y > 0 && {_next > _capacity}}) then {
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
    [_sector, false] call BATTLESPACE_LOGISTICS_UPDATE_REFILL_STATE;
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
        private _capacity = [_sector, _x, _sectorType] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        private _current = _resources getOrDefault [_x, 0];
        private _received = _requested min ((_capacity - _current) max 0);
        if (_received > 0) then {
            _resources set [_x, _current + _received];
            _accepted set [_x, _received];
        };
    } forEach _amounts;

    _state set ["resources", _resources];
    BATTLESPACE_SECTOR_STATES set [_sector, _state];
    [_sector, false] call BATTLESPACE_LOGISTICS_UPDATE_REFILL_STATE;
    _accepted
};

// Used only to roll back or return a previously committed transfer. Unlike
// ordinary ingress, restoration may remain over the current front-depth cap;
// that excess is then eligible for a later evacuation convoy.
BATTLESPACE_RESOURCE_RESTORE_TRANSFER = {
    params ["_sector", "_amounts"];
    private _restored = createHashMap;
    if (!([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) || {typeName _amounts != "HASHMAP"}) exitWith {_restored};

    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {_restored};

    private _resources = _state getOrDefault ["resources", createHashMap];
    {
        if !(_x in BATTLESPACE_RESOURCE_TYPES) then {continue};
        if !(_y isEqualType 0) then {continue};
        private _amount = (round _y) max 0;
        if (_amount <= 0) then {continue};
        _resources set [_x, (_resources getOrDefault [_x, 0]) + _amount];
        _restored set [_x, _amount];
    } forEach _amounts;

    _state set ["resources", _resources];
    BATTLESPACE_SECTOR_STATES set [_sector, _state];
    [_sector, false] call BATTLESPACE_LOGISTICS_UPDATE_REFILL_STATE;
    _restored
};

BATTLESPACE_STRATEGIC_SERIALIZE_OPERATION = {
    params ["_operation"];
    private _saved = [_operation] call BATTLESPACE_COPY_RESOURCE_MAP;
    _saved deleteAt "arrivalReservation";
    if ("captureStartedAt" in _saved) then {
        _saved set ["captureAge", (CBA_missionTime - (_saved getOrDefault ["captureStartedAt", CBA_missionTime])) max 0];
        _saved deleteAt "captureStartedAt";
    };
    {
        if (_x in _saved) then {
            _saved set [_x + "Remaining", ((_saved getOrDefault [_x, CBA_missionTime]) - CBA_missionTime) max 0];
            _saved deleteAt _x;
        };
    } forEach ["expiresAt", "loiterUntil", "contactGraceUntil", "holdUntil", "nextManeuverAt", "legDeadline"];
    _saved
};

BATTLESPACE_STRATEGIC_DESERIALIZE_OPERATION = {
    params ["_savedOperation"];
    private _operation = [_savedOperation] call BATTLESPACE_COPY_RESOURCE_MAP;
    _operation deleteAt "arrivalReservation";
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
    } forEach ["expiresAt", "loiterUntil", "contactGraceUntil", "holdUntil", "nextManeuverAt", "legDeadline"];
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
            ["refillingResources", +(_state getOrDefault ["refillingResources", []])],
            ["ownerAge", (CBA_missionTime - (_state getOrDefault ["lastOwnerChange", CBA_missionTime])) max 0],
            ["resupplyCooldown", ((_state getOrDefault ["nextResupplyAt", 0]) - CBA_missionTime) max 0],
            ["battlegroupCooldown", ((_state getOrDefault ["nextBattlegroupAt", 0]) - CBA_missionTime) max 0],
            ["battlegroupTargetCooldown", ((_state getOrDefault ["nextBattlegroupTargetAt", 0]) - CBA_missionTime) max 0],
            ["emergencyCooldown", ((_state getOrDefault ["nextEmergencyAt", 0]) - CBA_missionTime) max 0],
            ["reinforcementCooldown", ((_state getOrDefault ["nextReinforcementAt", 0]) - CBA_missionTime) max 0],
            ["deepReconCooldown", ((_state getOrDefault ["nextDeepReconAt", 0]) - CBA_missionTime) max 0],
            ["airResponseCooldown", ((_state getOrDefault ["nextAirResponseAt", 0]) - CBA_missionTime) max 0],
            ["fortificationCooldown", ((_state getOrDefault ["nextFortificationAt", 0]) - CBA_missionTime) max 0],
            ["minefieldCooldown", ((_state getOrDefault ["nextMinefieldAt", 0]) - CBA_missionTime) max 0],
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
                if (typeName _savedResources == "HASHMAP") then {
                    {
                        private _value = _savedResources getOrDefault [_x, 0];
                        if !(_value isEqualType 0) then { _value = 0 };
                        // Current-format saves may legitimately contain stock stranded
                        // above a newly reduced front-depth allowance. Preserve it as
                        // pending evacuation instead of deleting it during load.
                        _resources set [_x, (round _value) max 0];
                    } forEach BATTLESPACE_RESOURCE_TYPES;
                };
                _state set ["resources", _resources];
                private _refilling = _savedState getOrDefault ["refillingResources", []];
                if (_refilling isEqualType []) then {
                    _state set ["refillingResources", (_refilling arrayIntersect BATTLESPACE_RESOURCE_TYPES)];
                };
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
                _state set ["nextMinefieldAt", CBA_missionTime + (_savedState getOrDefault ["minefieldCooldown", 0])];
                _state set ["casualtyPressure", (_savedState getOrDefault ["casualtyPressure", 0]) max 0];
                private _lastCasualtyAge = _savedState getOrDefault ["lastCasualtyAge", -1];
                _state set ["lastCasualtyAt", if (_lastCasualtyAge < 0) then {-1} else {CBA_missionTime - _lastCasualtyAge}];
            };
        };
        BATTLESPACE_SECTOR_STATES set [_sector, _state];
        [_sector, false] call BATTLESPACE_LOGISTICS_UPDATE_REFILL_STATE;
    } forEach sectors_allSectors;

    BATTLESPACE_STRATEGIC_OPERATIONS = createHashMap;
    private _savedOperations = if (_saveValid) then {_save getOrDefault ["operations", createHashMap]} else {createHashMap};
    if (typeName _savedOperations == "HASHMAP") then {
        {
            if (!isNil {BATTLESPACE_TASK_FORCES get _x} && {typeName _y == "HASHMAP"}) then {
                private _operation = [_y] call BATTLESPACE_STRATEGIC_DESERIALIZE_OPERATION;
                BATTLESPACE_STRATEGIC_OPERATIONS set [_x, _operation];
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
    private _sam = [(_opfor getOrDefault ["samTel", []]) + (_opfor getOrDefault ["samRadar", []])] call _validClasses;
    private _shorad = [(_opfor getOrDefault ["samShorad", []])] call _validClasses;
    private _aaGuns = [(_opfor getOrDefault ["aaGun", []])] call _validClasses;
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
        ["strategic_sam", _sam],
        ["tactical_sam", _shorad],
        ["aircraft", _aircraft],
        ["tanks", _tanks],
        ["rocket_artillery", _rocketArtillery],
        ["howitzers", _howitzers],
        ["mortars", _mortars],
        ["spaag", [_aaGuns] call _mobileGround],
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

BATTLESPACE_CAPTURE_GET_OWNERSHIP = {
    params ["_sector"];
    private _position = getMarkerPos _sector;
    private _physicalOwner = [_position] call KPLIB_fnc_getSectorOwnership;
    if (_physicalOwner != GRLIB_side_civilian) exitWith {_physicalOwner};
    // A virtual force may occupy empty ground, but cannot defeat a real garrison
    // or complete an unseen capture while nearby opposition awaits materialization.
    if ([_position, BATTLESPACE_UNIT_PROC_RANGE, GRLIB_side_friendly] call KPLIB_fnc_getUnitsCount > 0) exitWith {_physicalOwner};
    private _occupied = false;
    {
        if ((_y getOrDefault ["kind", ""]) != "BATTLEGROUP" || {(_y getOrDefault ["phase", ""]) != "ASSAULTING"} || {(_y getOrDefault ["targetSector", ""]) != _sector}) then {continue};
        if ((_y getOrDefault ["stagePosition", []]) isEqualTo []) then {continue};
        private _taskForce = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_taskForce" || {(_taskForce param [4, []]) isNotEqualTo []} || {_taskForce param [11, false]}) then {continue};
        if ((_taskForce select 1) distance2D _position > GRLIB_capture_size) then {continue};
        if (((_taskForce select 3) getOrDefault ["manpower", 0]) <= 3) then {continue};
        if ([_taskForce, _y] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO < (_y getOrDefault ["retreatRatio", 0.5])) then {continue};
        _occupied = true;
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    [_physicalOwner, GRLIB_side_enemy] select _occupied
};

BATTLESPACE_CAPTURE_SECTOR_FOR_OPFOR = {
    params ["_sector"];
    if (!([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) || {!(_sector in blufor_sectors)} || {!(_sector in sectors_allSectors)}) exitWith { false };
    if ([_sector] call BATTLESPACE_CAPTURE_GET_OWNERSHIP != GRLIB_side_enemy) exitWith {false};

    blufor_sectors = blufor_sectors - [_sector];
    sector_to_blufor = createHashMap;
    {
        sector_to_blufor set [_x, true];
    } forEach blufor_sectors;

    if (isNil "BATTLESPACE_CIVILIANS_SECTORS_POPULATED") then {
        BATTLESPACE_CIVILIANS_SECTORS_POPULATED = createHashMap;
    };
    BATTLESPACE_CIVILIANS_SECTORS_POPULATED set [_sector, false];

    if (isNil "blufor_sectors_cap_times") then {
        blufor_sectors_cap_times = createHashMap;
    };
    blufor_sectors_cap_times set [_sector, CBA_missionTime];
    last_blufor_sector_change = CBA_missionTime;

    if (_sector in sectors_military) then {
        blufor_military_sectors = (missionNamespace getVariable ["blufor_military_sectors", []]) - [_sector];
        publicVariable "blufor_military_sectors";
    };

    if (!isNil "KP_liberation_production") then {
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
    [format ["OPFOR secured sector %1 through the common sector capture monitor", _sector]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_LOGISTICS_UPDATE_REFILL_STATE = {
    params ["_sector", ["_startNew", true]];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {[]};
    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state") exitWith {[]};
    if ((_state getOrDefault ["owner", ""]) != "OPFOR") exitWith {
        _state set ["refillingResources", []];
        []
    };

    private _previous = _state getOrDefault ["refillingResources", []];
    if (!_startNew && {_previous isEqualTo []}) exitWith {[]};
    private _sectorType = _state get "type";
    private _resources = _state get "resources";
    private _thresholds = [_sectorType, "Resupply"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
    private _targetRatio = (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESUPPLY_TARGET_RATIO", 1]) max 0 min 1;
    private _refilling = [];
    // Ledger updates only close existing cycles; ordinary evaluation starts
    // them. Completion is recorded immediately, before stock can be spent again.
    private _toCheck = if (_startNew) then {BATTLESPACE_RESOURCE_TYPES} else {_previous};
    {
        private _threshold = _thresholds getOrDefault [_x, -1];
        private _capacity = [_sector, _x, _sectorType] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        if (_threshold < 0 || {_capacity <= 0}) then {continue};
        private _current = _resources getOrDefault [_x, 0];
        private _trigger = ceil (_capacity * _threshold);
        private _target = ceil (_capacity * (_targetRatio max _threshold min 1));
        if (_current < _target && {_x in _previous || {_startNew && {_current < _trigger}}}) then {
            _refilling pushBack _x;
        };
    } forEach _toCheck;
    _state set ["refillingResources", _refilling];
    _refilling
};

BATTLESPACE_LOGISTICS_BUILD_REQUEST = {
    params ["_sector", ["_thresholdType", "Resupply"]];
    private _request = createHashMap;
    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith { _request };

    private _sectorType = _state get "type";
    private _resources = _state get "resources";
    private _thresholds = [_sectorType, _thresholdType] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
    private _normalResupply = _thresholdType == "Resupply";
    private _refilling = if (_normalResupply) then {[_sector] call BATTLESPACE_LOGISTICS_UPDATE_REFILL_STATE} else {[]};
    private _targetRatio = (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESUPPLY_TARGET_RATIO", 1]) max 0 min 1;
    {
        private _threshold = _thresholds getOrDefault [_x, -1];
        private _capacity = [_sector, _x, _sectorType] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        if (_threshold < 0 || {_capacity <= 0}) then { continue };
        if (_normalResupply && {!(_x in _refilling)}) then {continue};

        private _current = _resources getOrDefault [_x, 0];
        private _desiredRatio = if (_normalResupply) then {_targetRatio max _threshold min 1} else {_threshold};
        private _desired = ceil (_capacity * _desiredRatio);
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

    // Reduced forward capacity can leave the immediate neighbours with no
    // surplus. Exhaust the connected on-map supply network before importing.
    private _blocked = blufor_sectors + ["startbase_marker"];
    private _potentialSources = [];
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR") then {
            _blocked pushBackUnique _x;
        } else {
            if (_x != _targetSector) then {_potentialSources pushBack _x};
        };
    } forEach BATTLESPACE_SECTOR_STATES;
    private _reachable = [_targetSector, _potentialSources, _blocked] call NETWORKED_SECTORS_traverseGraphAndFindNodes;
    private _directLinks = _targetNetwork getOrDefault ["Links", []];
    private _targetPosition = getMarkerPos _targetSector;

    {
        private _source = _x;
        private _state = BATTLESPACE_SECTOR_STATES get _source;
        if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) then { continue };
        private _sectorType = _state get "type";
        private _resources = _state get "resources";
        private _sendThresholds = [_sectorType, "ResupplySend"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
        private _refilling = [_source, false] call BATTLESPACE_LOGISTICS_UPDATE_REFILL_STATE;
        private _cargo = createHashMap;
        private _total = 0;
        {
            private _resourceType = _x;
            // Keep incoming refill stock at its destination until that resource
            // has recovered; other resources remain available to the network.
            if (_resourceType in _refilling) then {continue};
            private _threshold = _sendThresholds getOrDefault [_resourceType, -1];
            if (_threshold < 0) then { continue };

            private _capacity = [_source, _resourceType, _sectorType] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
            private _reserve = ceil (_capacity * _threshold);
            // Excess above the local depth cap remains evacuation-only. Other
            // resources at the same objective can still support normal traffic.
            private _normalStock = (_resources getOrDefault [_resourceType, 0]) min _capacity;
            private _available = (_normalStock - _reserve) max 0;
            private _amount = _available min _y;
            if (_amount > 0) then {
                _cargo set [_resourceType, _amount];
                _total = _total + _amount;
            };
        } forEach _request;

        if (_total > 0) then {
            // Keep the existing neighbour-first policy and largest useful
            // load preference. Distance breaks ties within each tier.
            _candidates pushBack [
                [1, 0] select (_source in _directLinks),
                -_total,
                _targetPosition distance2D (getMarkerPos _source),
                _source,
                _cargo
            ];
        };
    } forEach _reachable;

    _candidates sort true;
    _candidates apply {[_x select 3, _x select 4]}
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
    params [["_allowOptionalApc", true, [true]]];
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
    if (_allowOptionalApc && {random 100 < _apcChance}) then {
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

BATTLESPACE_LOGISTICS_BUILD_CONVOY_FORCE_COST = {
    params ["_convoyDefinition"];
    private _composition = _convoyDefinition getOrDefault ["composition", createHashMap];
    private _cost = createHashMapFromArray [
        ["manpower", _composition getOrDefault ["manpower", 0]]
    ];
    {
        private _resourceType = _x param [1, ""];
        if (_resourceType != "") then {
            _cost set [_resourceType, (_cost getOrDefault [_resourceType, 0]) + 1];
        };
    } forEach (_convoyDefinition getOrDefault ["vehicleManifest", []]);
    _cost
};

BATTLESPACE_LOGISTICS_BUILD_CONVOY_DEBIT = {
    params ["_cargo", "_convoyDefinition"];
    private _debit = [_cargo] call BATTLESPACE_COPY_RESOURCE_MAP;
    private _forceCost = [_convoyDefinition] call BATTLESPACE_LOGISTICS_BUILD_CONVOY_FORCE_COST;
    {
        _debit set [_x, (_debit getOrDefault [_x, 0]) + _y];
    } forEach _forceCost;
    _debit
};

BATTLESPACE_LOGISTICS_BUILD_CONVOY_OPTIONS = {
    private _preferred = [true] call BATTLESPACE_LOGISTICS_BUILD_CONVOY;
    if (count _preferred == 0) exitWith {[]};
    private _options = [_preferred];
    if ((_preferred getOrDefault ["vehicleManifest", []]) findIf {(_x param [1, ""]) == "apc"} >= 0) then {
        private _base = [false] call BATTLESPACE_LOGISTICS_BUILD_CONVOY;
        if (count _base > 0) then {_options pushBack _base};
    };
    _options
};

BATTLESPACE_LOGISTICS_GET_TARGET_HEADROOM = {
    params ["_targetSector"];
    private _headroom = createHashMap;
    private _state = BATTLESPACE_SECTOR_STATES get _targetSector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {_headroom};

    private _sectorType = _state getOrDefault ["type", ""];
    private _resources = _state getOrDefault ["resources", createHashMap];
    {
        private _capacity = [_targetSector, _x, _sectorType] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        private _available = _capacity - (_resources getOrDefault [_x, 0]);
        _headroom set [_x, _available max 0];
    } forEach BATTLESPACE_RESOURCE_TYPES;
    _headroom
};

BATTLESPACE_LOGISTICS_BUILD_CONVOY_CURRENT_LOAD = {
    params ["_taskForce", "_operation"];
    private _crateCount = (_operation getOrDefault ["cargoCrateCount", 0]) max 0;
    private _cratesLost = (_operation getOrDefault ["cargoCratesLost", 0]) max 0 min _crateCount;
    private _ratio = if (_crateCount > 0) then {
        (_crateCount - _cratesLost) / _crateCount
    } else {
        [_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO
    };
    private _load = [
        _operation getOrDefault ["cargo", createHashMap],
        _ratio
    ] call BATTLESPACE_STRATEGIC_SCALE_RESOURCES;
    private _survivingForce = [_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVING_FORCE_RESOURCES;
    {
        _load set [_x, (_load getOrDefault [_x, 0]) + _y];
    } forEach _survivingForce;
    _load
};

BATTLESPACE_LOGISTICS_HAS_ACTIVE_CONVOY_FOR_TARGET = {
    params ["_targetSector", ["_ignoredOperationId", ""]];
    private _found = false;
    {
        if (
            _x != _ignoredOperationId
            && {(_y getOrDefault ["kind", ""]) == "CONVOY"}
            && {(_y getOrDefault ["targetSector", ""]) == _targetSector}
            && {(_y getOrDefault ["phase", ""]) != "RETURNING"}
            && {(_y getOrDefault ["outcome", ""]) == ""}
        ) exitWith {
            _found = true;
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _found
};

BATTLESPACE_LOGISTICS_HAS_ACTIVE_EVACUATION_FROM_SOURCE = {
    params ["_sourceSector"];
    private _found = false;
    {
        if (
            (_y getOrDefault ["kind", ""]) == "CONVOY"
            && {(_y getOrDefault ["convoyPurpose", ""]) == "EVACUATION"}
            && {(_y getOrDefault ["sourceSector", ""]) == _sourceSector}
            && {(_y getOrDefault ["outcome", ""]) == ""}
        ) exitWith {
            _found = true;
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _found
};

BATTLESPACE_LOGISTICS_GET_REACHABLE_DEEPER_TARGETS = {
    params ["_sourceSector", "_sourceDepth"];
    private _candidateRows = [];
    private _sourcePosition = getMarkerPos _sourceSector;
    {
        if (_x == _sourceSector || {(_y getOrDefault ["owner", ""]) != "OPFOR"}) then {continue};
        private _depth = [_x, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
        if (_depth <= _sourceDepth) then {continue};
        private _score = (_depth * 1000000) + (_sourcePosition distance2D (getMarkerPos _x));
        _candidateRows pushBack [_score, _x];
    } forEach BATTLESPACE_SECTOR_STATES;
    if (_candidateRows isEqualTo []) exitWith {[]};

    private _candidateNames = _candidateRows apply {_x param [1, ""]};
    private _reachable = [
        _sourceSector,
        _candidateNames,
        blufor_sectors + ["startbase_marker"]
    ] call NETWORKED_SECTORS_traverseGraphAndFindNodes;
    private _reachableRows = _candidateRows select {(_x param [1, ""]) in _reachable};
    _reachableRows = [_reachableRows, [], {_x param [0, 0]}, "ASCEND"] call BIS_fnc_sortBy;
    _reachableRows apply {_x param [1, ""]}
};

BATTLESPACE_LOGISTICS_TARGET_CAN_ACCEPT_LOAD = {
    params ["_targetSector", "_load"];
    if (typeName _load != "HASHMAP" || {count _load == 0}) exitWith {false};
    private _headroom = [_targetSector] call BATTLESPACE_LOGISTICS_GET_TARGET_HEADROOM;
    if (count _headroom == 0) exitWith {false};
    private _accepted = true;
    {
        if (
            !(_x in BATTLESPACE_RESOURCE_TYPES)
            || {!(_y isEqualType 0)}
            || {_y < 0}
            || {_y > (_headroom getOrDefault [_x, 0])}
        ) exitWith {
            _accepted = false;
        };
    } forEach _load;
    _accepted
};

BATTLESPACE_LOGISTICS_FIND_EVACUATION_TARGET = {
    params ["_sourceSector", "_sourceDepth", "_excess", "_convoyDefinition"];
    private _result = [];
    private _bestCargoTotal = 0;
    if (typeName _excess != "HASHMAP" || {count _excess == 0}) exitWith {_result};
    private _forceCost = [_convoyDefinition] call BATTLESPACE_LOGISTICS_BUILD_CONVOY_FORCE_COST;
    {
        private _targetSector = _x;
        if ([_targetSector] call BATTLESPACE_LOGISTICS_HAS_ACTIVE_CONVOY_FOR_TARGET) then {continue};
        if ([_targetSector] call BATTLESPACE_LOGISTICS_HAS_ACTIVE_EVACUATION_FROM_SOURCE) then {continue};
        private _headroom = [_targetSector] call BATTLESPACE_LOGISTICS_GET_TARGET_HEADROOM;
        private _forceFits = true;
        {
            if (_y > (_headroom getOrDefault [_x, 0])) exitWith {_forceFits = false};
        } forEach _forceCost;
        if (!_forceFits) then {continue};

        private _cargo = createHashMap;
        private _cargoTotal = 0;
        {
            private _available = ((_headroom getOrDefault [_x, 0]) - (_forceCost getOrDefault [_x, 0])) max 0;
            private _amount = _y min _available;
            if (_amount > 0) then {
                _cargo set [_x, _amount];
                _cargoTotal = _cargoTotal + _amount;
            };
        } forEach _excess;
        if (_cargoTotal <= 0) then {continue};

        // Use the largest safe load; equal loads retain the existing nearest
        // deeper-depth ordering from GET_REACHABLE_DEEPER_TARGETS.
        if (_cargoTotal > _bestCargoTotal) then {
            _bestCargoTotal = _cargoTotal;
            _result = [_targetSector, _cargo, [_cargo, _convoyDefinition] call BATTLESPACE_LOGISTICS_BUILD_CONVOY_DEBIT];
        };
    } forEach ([_sourceSector, _sourceDepth] call BATTLESPACE_LOGISTICS_GET_REACHABLE_DEEPER_TARGETS);
    _result
};

BATTLESPACE_LOGISTICS_WARN_EVACUATION_BLOCKED_ONCE = {
    params ["_sourceSector", "_reason", "_message"];
    if ((BATTLESPACE_LOGISTICS_EVACUATION_BLOCKED_WARNED getOrDefault [_sourceSector, ""]) != _reason) then {
        BATTLESPACE_LOGISTICS_EVACUATION_BLOCKED_WARNED set [_sourceSector, _reason];
        [_message, "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
    };
};

BATTLESPACE_LOGISTICS_CREATE_CONVOY = {
    params [
        "_purpose",
        "_sourceSector",
        "_sourceMarker",
        "_targetSector",
        "_cargo",
        "_debit",
        "_convoyDefinition",
        ["_metadata", createHashMap]
    ];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {""};
    private _restoreDebit = {
        if (_sourceSector != "" && {typeName _debit == "HASHMAP"} && {count _debit > 0}) then {
            [_sourceSector, _debit] call BATTLESPACE_RESOURCE_RESTORE_TRANSFER;
        };
    };
    if (
        _sourceMarker == ""
        || {_targetSector == ""}
        || {typeName _cargo != "HASHMAP"}
        || {count _cargo == 0}
        || {typeName _convoyDefinition != "HASHMAP"}
        || {count _convoyDefinition == 0}
    ) exitWith {
        [] call _restoreDebit;
        ""
    };
    private _targetState = BATTLESPACE_SECTOR_STATES get _targetSector;
    if (isNil "_targetState" || {(_targetState getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {
        [] call _restoreDebit;
        ""
    };

    private _origin = getMarkerPos _sourceMarker;
    private _roads = _origin nearRoads 200;
    if (_roads isNotEqualTo []) then {_origin = getPos (selectRandom _roads)};
    private _operation = createHashMapFromArray [
        ["kind", "CONVOY"],
        ["convoyPurpose", _purpose],
        ["phase", "ENROUTE"],
        ["sourceSector", _sourceSector],
        ["sourceMarker", _sourceMarker],
        ["targetSector", _targetSector],
        ["cargo", [_cargo] call BATTLESPACE_COPY_RESOURCE_MAP],
        ["debit", [_debit] call BATTLESPACE_COPY_RESOURCE_MAP],
        ["vehicleManifest", +(_convoyDefinition get "vehicleManifest")],
        ["cargoCrateCount", {(_x param [1, ""]) == "truck"} count (_convoyDefinition get "vehicleManifest")],
        ["cargoCratesLost", 0],
        ["initialStrength", _convoyDefinition get "initialStrength"],
        ["outcome", ""]
    ];
    if (typeName _metadata == "HASHMAP") then {
        {_operation set [_x, _y]} forEach _metadata;
    };
    private _taskForceId = "";
    // Admission and registration must be indivisible across scheduled normal,
    // evacuation and emergency producers. Physical spawning happens later.
    isNil {
        if (["CONVOY"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_CONVOYS", 3])) exitWith {};
        _taskForceId = [
            "Convoy",
            _convoyDefinition get "composition",
            _origin,
            getMarkerPos _targetSector,
            getMarkerPos _sourceMarker
        ] call BATTLESPACE_TASK_FORCES_INIT;
        if (_taskForceId != "") then {
            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
        };
    };
    if (_taskForceId == "") exitWith {
        [] call _restoreDebit;
        [format ["Convoy creation for %1 rejected by capacity or constructor; committed sector debit was restored", _targetSector], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        ""
    };

    _targetState set [
        "nextResupplyAt",
        CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RESUPPLY_COOLDOWN", 1800])
    ];
    BATTLESPACE_SECTOR_STATES set [_targetSector, _targetState];
    [] call BATTLESPACE_LOGISTICS_SAVE;
    [format [
        "Dispatched %1 convoy %2 from %3 to %4 with vehicles %5 and cargo %6",
        toLower _purpose,
        _taskForceId,
        _sourceMarker,
        _targetSector,
        _convoyDefinition get "vehicleManifest",
        _cargo
    ]] call BATTLESPACE_STRATEGIC_LOG;
    _taskForceId
};

BATTLESPACE_LOGISTICS_DISPATCH_EVACUATION = {
    params ["_sourceSector"];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {false};
    if (
        ["CONVOY"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS
        >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_CONVOYS", 3])
    ) exitWith {false};
    if ([_sourceSector] call BATTLESPACE_LOGISTICS_HAS_ACTIVE_EVACUATION_FROM_SOURCE) exitWith {false};
    if ([_sourceSector] call BATTLESPACE_LOGISTICS_HAS_ACTIVE_CONVOY_FOR_TARGET) exitWith {false};

    private _excess = [_sourceSector] call BATTLESPACE_LOGISTICS_BUILD_FRONT_EXCESS;
    if (count _excess == 0) exitWith {
        BATTLESPACE_LOGISTICS_EVACUATION_BLOCKED_WARNED deleteAt _sourceSector;
        false
    };
    private _sourceDepth = [_sourceSector, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
    if (_sourceDepth < 0) exitWith {false};

    private _convoyOptions = [] call BATTLESPACE_LOGISTICS_BUILD_CONVOY_OPTIONS;
    if (_convoyOptions isEqualTo []) exitWith {
        [
            _sourceSector,
            "NO_CONVOY_CLASSES",
            format ["Front-stock evacuation from %1 is blocked: generated OPFOR logistics vehicles are unavailable", _sourceSector]
        ] call BATTLESPACE_LOGISTICS_WARN_EVACUATION_BLOCKED_ONCE;
        false
    };

    private _selection = [];
    private _targetFound = false;
    {
        private _convoyDefinition = _x;
        private _targetData = [_sourceSector, _sourceDepth, _excess, _convoyDefinition] call BATTLESPACE_LOGISTICS_FIND_EVACUATION_TARGET;
        if (_targetData isNotEqualTo []) then {
            _targetFound = true;
            _targetData params ["_targetSector", "_cargo", "_debit"];
            private _negativeDebit = createHashMap;
            {_negativeDebit set [_x, -_y]} forEach _debit;
            if ([_sourceSector, _negativeDebit] call BATTLESPACE_RESOURCE_APPLY_STRICT) then {
                _selection = [_convoyDefinition, _targetSector, _cargo, _debit];
            };
        };
        if (_selection isNotEqualTo []) exitWith {};
    } forEach _convoyOptions;

    if (_selection isEqualTo []) exitWith {
        private _reason = ["NO_DEEP_CAPACITY", "CANNOT_FUND"] select _targetFound;
        private _message = if (_targetFound) then {
            format ["Front-stock evacuation from %1 is waiting: local stock cannot fund a viable cargo and convoy", _sourceSector]
        } else {
            format ["Front-stock evacuation from %1 is waiting: no reachable deeper OPFOR objective has room for the convoy's actual load", _sourceSector]
        };
        [
            _sourceSector,
            _reason,
            _message
        ] call BATTLESPACE_LOGISTICS_WARN_EVACUATION_BLOCKED_ONCE;
        false
    };
    _selection params ["_convoyDefinition", "_targetSector", "_cargo", "_debit"];
    private _taskForceId = [
        "EVACUATION",
        _sourceSector,
        _sourceSector,
        _targetSector,
        _cargo,
        _debit,
        _convoyDefinition,
        createHashMapFromArray [["evacuationSourceDepth", _sourceDepth]]
    ] call BATTLESPACE_LOGISTICS_CREATE_CONVOY;
    if (_taskForceId == "") exitWith {
        [
            _sourceSector,
            "TASK_FORCE_INIT",
            format ["Front-stock evacuation from %1 failed to create its convoy; the complete debit was restored", _sourceSector]
        ] call BATTLESPACE_LOGISTICS_WARN_EVACUATION_BLOCKED_ONCE;
        false
    };
    BATTLESPACE_LOGISTICS_EVACUATION_BLOCKED_WARNED deleteAt _sourceSector;
    true
};

BATTLESPACE_LOGISTICS_DISPATCH = {
    params ["_targetSector", "_request"];
    if (!([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) || {count _request == 0}) exitWith { false };
    if (["CONVOY"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_CONVOYS", 3])) exitWith {false};
    if ([_targetSector] call BATTLESPACE_LOGISTICS_HAS_ACTIVE_CONVOY_FOR_TARGET) exitWith { false };
    if ([_targetSector] call BATTLESPACE_LOGISTICS_HAS_ACTIVE_EVACUATION_FROM_SOURCE) exitWith { false };

    private _convoyOptions = [] call BATTLESPACE_LOGISTICS_BUILD_CONVOY_OPTIONS;
    if (_convoyOptions isEqualTo []) exitWith {
        [format ["No generated OPFOR logistics trucks/car escort can service %1", _targetSector], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };

    private _sourceCandidates = [_targetSector, _request] call BATTLESPACE_LOGISTICS_FIND_SECTOR_SOURCES;
    private _selection = [];
    {
        private _convoyDefinition = _x;
        {
            _x params ["_candidateSector", "_candidateCargo"];
            private _candidateDebit = [_candidateCargo, _convoyDefinition] call BATTLESPACE_LOGISTICS_BUILD_CONVOY_DEBIT;
            private _negativeDebit = createHashMap;
            {_negativeDebit set [_x, -_y]} forEach _candidateDebit;
            if ([_candidateSector, _negativeDebit] call BATTLESPACE_RESOURCE_APPLY_STRICT) exitWith {
                _selection = [_convoyDefinition, _candidateSector, _candidateSector, _candidateCargo, _candidateDebit];
            };
        } forEach _sourceCandidates;
        if (_selection isNotEqualTo []) exitWith {};
    } forEach _convoyOptions;

    if (_selection isEqualTo []) then {
        private _sourceMarker = [_targetSector] call BATTLESPACE_LOGISTICS_FIND_OFFMAP_SOURCE;
        if (_sourceMarker != "") then {
            _selection = [
                _convoyOptions select (count _convoyOptions - 1),
                "",
                _sourceMarker,
                [_request] call BATTLESPACE_COPY_RESOURCE_MAP,
                createHashMap
            ];
        };
    };
    if (_selection isEqualTo []) exitWith {
        if !(BATTLESPACE_LOGISTICS_MISSING_ENTRY_WARNED getOrDefault [_targetSector, false]) then {
            BATTLESPACE_LOGISTICS_MISSING_ENTRY_WARNED set [_targetSector, true];
            [format [
                "Convoy for %1 was not dispatched: no reachable OPFOR sector can fund it and no reachable logistics_spawn marker exists",
                _targetSector
            ], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        };
        false
    };
    _selection params ["_convoyDefinition", "_sourceSector", "_sourceMarker", "_cargo", "_debit"];
    private _taskForceId = [
        "RESUPPLY",
        _sourceSector,
        _sourceMarker,
        _targetSector,
        _cargo,
        _debit,
        _convoyDefinition
    ] call BATTLESPACE_LOGISTICS_CREATE_CONVOY;
    if (_taskForceId == "") exitWith {
        false
    };
    if (_sourceSector == "") then {
        private _reason = if (_sourceCandidates isEqualTo []) then {
            "no reachable OPFOR supplier offered surplus for the requested cargo"
        } else {
            format ["none of %1 reachable cargo suppliers could fund the convoy vehicles and crew", count _sourceCandidates]
        };
        [format ["Off-map resupply for %1 from %2: %3", _targetSector, _sourceMarker, _reason]] call BATTLESPACE_STRATEGIC_LOG;
    };
    BATTLESPACE_LOGISTICS_MISSING_ENTRY_WARNED deleteAt _targetSector;
    true
};

BATTLESPACE_LOGISTICS_EVACUATION_DECISION_TICK = {
    params [["_perTickOverride", -1]];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {0};
    private _activeLimit = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_CONVOYS", 3];
    private _remainingSlots = _activeLimit - (["CONVOY"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS);
    private _configuredPerTick = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_CONVOYS_PER_TICK", 2];
    private _perTick = [_configuredPerTick, _perTickOverride] select (_perTickOverride >= 0);
    private _remaining = (_remainingSlots min _perTick) max 0;
    if (_remaining <= 0) exitWith {0};

    private _candidates = [];
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR") then {continue};
        if ([_x] call BATTLESPACE_LOGISTICS_HAS_ACTIVE_EVACUATION_FROM_SOURCE) then {continue};
        if ([_x] call BATTLESPACE_LOGISTICS_HAS_ACTIVE_CONVOY_FOR_TARGET) then {continue};
        private _excess = [_x] call BATTLESPACE_LOGISTICS_BUILD_FRONT_EXCESS;
        if (count _excess == 0) then {
            BATTLESPACE_LOGISTICS_EVACUATION_BLOCKED_WARNED deleteAt _x;
            continue;
        };
        private _depth = [_x, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
        if (_depth < 0) then {continue};
        private _totalExcess = 0;
        {_totalExcess = _totalExcess + _y} forEach _excess;
        _candidates pushBack [(_depth * 1000000) - _totalExcess, _x];
    } forEach BATTLESPACE_SECTOR_STATES;

    _candidates = [_candidates, [], {_x param [0, 0]}, "ASCEND"] call BIS_fnc_sortBy;
    private _dispatched = 0;
    {
        if (_remaining <= 0) exitWith {};
        if ([_x param [1, ""]] call BATTLESPACE_LOGISTICS_DISPATCH_EVACUATION) then {
            _remaining = _remaining - 1;
            _dispatched = _dispatched + 1;
        };
    } forEach _candidates;
    _dispatched
};

BATTLESPACE_LOGISTICS_DECISION_TICK = {
    params [["_perTickOverride", -1]];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {0};
    private _activeLimit = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_CONVOYS", 3];
    private _remainingSlots = _activeLimit - (["CONVOY"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS);
    private _configuredPerTick = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_CONVOYS_PER_TICK", 2];
    private _perTick = [_configuredPerTick, _perTickOverride] select (_perTickOverride >= 0);
    private _remaining = (_remainingSlots min _perTick) max 0;
    if (_remaining <= 0) exitWith {0};

    private _candidates = [];
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR") then { continue };
        if (CBA_missionTime < (_y getOrDefault ["nextResupplyAt", 0])) then { continue };
        if (["CONVOY", _x] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET) then { continue };
        if ([_x] call BATTLESPACE_LOGISTICS_HAS_ACTIVE_EVACUATION_FROM_SOURCE) then { continue };

        private _request = [_x] call BATTLESPACE_LOGISTICS_BUILD_REQUEST;
        if (count _request == 0) then { continue };
        private _depth = [_x, blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
        if (_depth < 0) then { _depth = 999 };
        _candidates pushBack [_depth, _x, _request];
    } forEach BATTLESPACE_SECTOR_STATES;

    _candidates = [_candidates, [], {_x param [0, 999]}, "ASCEND"] call BIS_fnc_sortBy;
    private _dispatched = 0;
    {
        if (_remaining <= 0) exitWith {};
        _x params ["_depth", "_sector", "_request"];
        if ([_sector, _request] call BATTLESPACE_LOGISTICS_DISPATCH) then {
            _remaining = _remaining - 1;
            _dispatched = _dispatched + 1;
        };
    } forEach _candidates;
    _dispatched
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
                private _cargo = [_taskForce, _operation] call BATTLESPACE_LOGISTICS_BUILD_CONVOY_CURRENT_LOAD;
                private _purpose = _operation getOrDefault ["convoyPurpose", "RESUPPLY"];
                private _accepted = if (_outcome == "RETURNED") then {
                    // A return is a rollback of surviving committed material, not
                    // ordinary stock ingress, so a lower front cap cannot erase it.
                    [_destinationSector, _cargo] call BATTLESPACE_RESOURCE_RESTORE_TRANSFER
                } else {
                    [_destinationSector, _cargo] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED
                };
                [format [
                    "%1 convoy %2 %3 at %4 with %5/%6 cargo shares; cargo and surviving force accepted %7",
                    toLower _purpose,
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
        case "RESERVE";
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
                private _returningFundedDefense = _kind in ["DEFENDER", "RESERVE"]
                    && {(_operation getOrDefault ["outcome", ""]) == "RETURNED"};
                private _accepted = if (_returningFundedDefense) then {
                    [_destinationSector, _survivors] call BATTLESPACE_RESOURCE_RESTORE_TRANSFER
                } else {
                    [_destinationSector, _survivors] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED
                };
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
        if (!isNil "BATTLESPACE_MINEFIELDS_RETIRE_LEGACY") then {
            [] call BATTLESPACE_MINEFIELDS_RETIRE_LEGACY;
        };

        private _strategicInitialDelay = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_INITIAL_DELAY", 300];
        private _defenderDecisionInterval = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEFENDER_DECISION_INTERVAL", 600];
        private _nextDecision = CBA_missionTime + _strategicInitialDelay;
        private _nextDefenseDecision = CBA_missionTime + _strategicInitialDelay;
        private _nextAirResponse = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_INITIAL_DELAY", 600]);
        private _nextSave = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_SAVE_INTERVAL", 300]);
        [format [
            "Defender and offensive allocation scheduled: first pass in %1 seconds, then every %2 seconds; existing role and opportunity gates apply",
            _strategicInitialDelay,
            _defenderDecisionInterval
        ]] call BATTLESPACE_STRATEGIC_LOG;
        while {GRLIB_endgame == 0} do {
            [] call BATTLESPACE_SECTOR_SYNC_OWNERS;
            [] call BATTLESPACE_STRATEGIC_RECONCILE_OPERATIONS;
            [] call BATTLESPACE_OFFENSIVE_SAMPLE_CONTACTS;
            if (!isNil "BATTLESPACE_TACTICAL_MAINTENANCE_TICK") then {
                [] call BATTLESPACE_TACTICAL_MAINTENANCE_TICK;
            };

            if (CBA_missionTime >= _nextDecision) then {
                private _convoyBudget = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_CONVOYS_PER_TICK", 2];
                private _evacuationConvoys = [_convoyBudget] call BATTLESPACE_LOGISTICS_EVACUATION_DECISION_TICK;
                [(_convoyBudget - _evacuationConvoys) max 0] call BATTLESPACE_LOGISTICS_DECISION_TICK;
                if (!isNil "BATTLESPACE_DEEP_RECON_DECISION_TICK") then {
                    [] call BATTLESPACE_DEEP_RECON_DECISION_TICK;
                };
                if (!isNil "BATTLESPACE_FORTIFICATION_DECISION_TICK") then {
                    [] call BATTLESPACE_FORTIFICATION_DECISION_TICK;
                };
                if (!isNil "BATTLESPACE_MINEFIELDS_DECISION_TICK") then {
                    [] call BATTLESPACE_MINEFIELDS_DECISION_TICK;
                };
                _nextDecision = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DECISION_INTERVAL", 1800]);
            };

            if (CBA_missionTime >= _nextDefenseDecision) then {
                if (!isNil "BATTLESPACE_DEFENSE_DECISION_TICK") then {
                    [] call BATTLESPACE_DEFENSE_DECISION_TICK;
                };
                [] call BATTLESPACE_BATTLEGROUP_DECISION_TICK;
                _nextDefenseDecision = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DEFENDER_DECISION_INTERVAL", 600]);
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
