/*
    Resource-backed tactical Battlespace operations and curator diagnostics.

    This file does not materialize units. It reserves sector stock for logical
    task forces and lets the registered task-force models own physical state.
*/

BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS = {
    params [["_class", "", [""]]];
    if (_class == "" || {!isClass (configFile >> "CfgVehicles" >> _class)}) exitWith {""};

    if (_class in (missionNamespace getVariable ["BATTLESPACE_SAM_SITE_TELS", []])
        || {_class in (missionNamespace getVariable ["BATTLESPACE_SAM_SITE_FCRS", []])}) exitWith {"strategic_sam"};
    private _shorad = [];
    {{_shorad pushBackUnique _x} forEach _x} forEach (missionNamespace getVariable ["BATTLESPACE_SAM_SITE_SHORAD", []]);
    if (_class in _shorad) exitWith {"tactical_sam"};

    private _resource = "";
    {
        if (_class in (BATTLESPACE_RESOURCE_CLASS_POOLS getOrDefault [_x, []])) exitWith {_resource = _x};
    } forEach ["aircraft", "rocket_artillery", "mortars", "howitzers", "spaag", "tanks", "ifv", "apc", "truck", "car"];
    if (_resource != "") exitWith {_resource};

    private _categories = [_class] call KPLIB_fnc_classifyFactionVehicle;
    private _text = toLower format ["%1 %2", _class, getText (configFile >> "CfgVehicles" >> _class >> "displayName")];
    if (_class isKindOf "Air") exitWith {"aircraft"};
    if ("artillery" in _categories) exitWith {
        if ((_text find "mortar") >= 0) then {"mortars"} else {
            if ((_text find "rocket") >= 0 || {(_text find "mlrs") >= 0} || {(_text find "grad") >= 0}) then {"rocket_artillery"} else {"howitzers"}
        }
    };
    if ("aa" in _categories) exitWith {if (_class isKindOf "StaticWeapon") then {"tactical_sam"} else {"spaag"}};
    if (_class isKindOf "StaticWeapon") exitWith {"car"};
    if (_class isKindOf "Tank") exitWith {if (getNumber (configFile >> "CfgVehicles" >> _class >> "transportSoldier") > 0) then {"ifv"} else {"tanks"}};
    if ("groundLogistics" in _categories) exitWith {"truck"};
    if (_class isKindOf "Car") exitWith {if (getNumber (configFile >> "CfgVehicles" >> _class >> "transportSoldier") >= 6) then {"apc"} else {"car"}};
    ""
};

BATTLESPACE_STRATEGIC_BUILD_COMPOSITION_MANIFEST = {
    params ["_composition"];
    private _cost = createHashMap;
    private _vehicleManifest = [];
    private _valid = typeName _composition == "HASHMAP";
    if (!_valid) exitWith {createHashMapFromArray [["valid", false], ["cost", _cost], ["vehicleManifest", _vehicleManifest]]};

    private _manpower = round ((_composition getOrDefault ["manpower", 0]) max 0);
    if (_manpower > 0) then {_cost set ["manpower", _manpower]};
    {
        private _resource = [_x] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS;
        if (_resource == "") then {
            _valid = false;
        } else {
            _cost set [_resource, (_cost getOrDefault [_resource, 0]) + 1];
            _vehicleManifest pushBack [_x, _resource];
        };
    } forEach (_composition getOrDefault ["vehicles", []]);

    {
        private _class = _x getOrDefault ["className", ""];
        if (_class == "" || {!(_class isKindOf "StaticWeapon")}) then {continue};
        private _resource = [_class] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS;
        if (_resource != "") then {
            _cost set [_resource, (_cost getOrDefault [_resource, 0]) + 1];
        };
    } forEach (_composition getOrDefault ["structures", []]);

    createHashMapFromArray [
        ["valid", _valid],
        ["cost", _cost],
        ["vehicleManifest", _vehicleManifest],
        ["initialStrength", _manpower + (4 * count _vehicleManifest)]
    ]
};

BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE = {
    params [
        "_type", "_composition", "_originPoint", "_initialTargetLocation", "_homePoint",
        "_fundingSector", ["_kind", "DEFENDER"], ["_metadata", createHashMap], ["_extraCost", createHashMap]
    ];
    if (!([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED)) exitWith {""};
    private _fundingState = BATTLESPACE_SECTOR_STATES get _fundingSector;
    if (isNil "_fundingState" || {(_fundingState getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {""};

    private _manifest = [_composition] call BATTLESPACE_STRATEGIC_BUILD_COMPOSITION_MANIFEST;
    if !(_manifest getOrDefault ["valid", false]) exitWith {
        [format ["Rejected funded %1 at %2 because its vehicle manifest was not classifiable", _type, _fundingSector], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        ""
    };
    private _cost = _manifest get "cost";
    private _extraCostValid = typeName _extraCost == "HASHMAP";
    if (_extraCostValid) then {
        {
            if !(_x in BATTLESPACE_RESOURCE_TYPES) then {_extraCostValid = false; continue};
            if !(_y isEqualType 0) then {_extraCostValid = false; continue};
            private _amount = round _y;
            if (_amount <= 0) then {_extraCostValid = false; continue};
            _cost set [_x, (_cost getOrDefault [_x, 0]) + _amount];
        } forEach _extraCost;
    };
    if (!_extraCostValid) exitWith {
        [format ["Rejected funded %1 at %2 because its extra resource cost was invalid", _type, _fundingSector], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        ""
    };
    private _debit = createHashMap;
    {_debit set [_x, -_y]} forEach _cost;
    if (count _debit > 0 && {!([_fundingSector, _debit] call BATTLESPACE_RESOURCE_APPLY_STRICT)}) exitWith {""};

    private _taskForceId = [_type, _composition, _originPoint, _initialTargetLocation, _homePoint] call BATTLESPACE_TASK_FORCES_INIT;
    if (_taskForceId == "") exitWith {
        if (count _cost > 0) then {[_fundingSector, _cost] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED};
        ""
    };

    private _operation = createHashMapFromArray [
        ["kind", toUpper _kind],
        ["phase", "ACTIVE"],
        ["fundingSector", _fundingSector],
        ["originSector", _fundingSector],
        ["pressureSector", _fundingSector],
        ["cost", [_cost] call BATTLESPACE_COPY_RESOURCE_MAP],
        ["vehicleManifest", +(_manifest get "vehicleManifest")],
        ["initialStrength", _manifest getOrDefault ["initialStrength", 1]],
        ["createdAt", CBA_missionTime],
        ["outcome", ""]
    ];
    if (typeName _metadata == "HASHMAP") then {
        {_operation set [_x, _y]} forEach _metadata;
    };
    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
    _taskForceId
};

BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE = {
    params ["_sector", ["_weight", 1]];
    if (!isServer) exitWith {};
    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {};
    _state set ["casualtyPressure", (_state getOrDefault ["casualtyPressure", 0]) + (_weight max 0)];
    _state set ["lastCasualtyAt", CBA_missionTime];
    BATTLESPACE_SECTOR_STATES set [_sector, _state];
};

BATTLESPACE_STRATEGIC_ADD_DEPLOYED_ASSETS_TO_SNAPSHOT = {
    params ["_sector", "_sectorType", "_snapshot"];
    private _addClamped = {
        params ["_resource", "_amount"];
        if (_amount <= 0 || {!(_resource in BATTLESPACE_RESOURCE_TYPES)}) exitWith {};
        private _capacity = [_sectorType, _resource] call BATTLESPACE_SECTOR_GET_CAPACITY;
        _snapshot set [_resource, ((_snapshot getOrDefault [_resource, 0]) + _amount) min _capacity];
    };

    {
        if ((_x getVariable ["BSAFundingSector", ""]) != _sector) then {continue};
        private _resource = _x getVariable ["BSAPieceResource", "howitzers"];
        private _vehicles = [];
        {
            private _vehicle = vehicle _x;
            if (_vehicle isNotEqualTo _x && {alive _vehicle}) then {_vehicles pushBackUnique _vehicle};
        } forEach units _x;
        [_resource, count _vehicles] call _addClamped;
        ["manpower", {alive _x} count units _x] call _addClamped;
    } forEach (missionNamespace getVariable ["BATTLESPACE_ARTILLERY_SECTIONS", []]);

    {
        if ((_x getOrDefault ["Sector", ""]) != _sector) then {continue};
        private _aliveClasses = (_x getOrDefault ["Units", []]) select {!isNull _x && {alive _x}} apply {typeOf _x};
        private _reservation = [_aliveClasses] call BATTLESPACE_SAM_BUILD_RESERVATION;
        ["strategic_sam", _reservation getOrDefault ["strategic_sam", 0]] call _addClamped;
        ["tactical_sam", _reservation getOrDefault ["tactical_sam", 0]] call _addClamped;
        private _siteId = _x getOrDefault ["Id", ""];
        private _poolState = BATTLESPACE_SAM_SITE_POOLS get _siteId;
        if (!isNil "_poolState") then {
            private _pools = _poolState getOrDefault ["Pools", createHashMap];
            ["strategic_missiles", _pools getOrDefault ["strategic_missiles", 0]] call _addClamped;
            ["tactical_missiles", _pools getOrDefault ["tactical_missiles", 0]] call _addClamped;
        };
    } forEach (missionNamespace getVariable ["BATTLESPACE_SAM_EXISTING_SITES", []]);
};

BATTLESPACE_STRATEGIC_RECORD_CASUALTY = {
    params ["_taskForceId", "_lossType"];
    if (!isServer) exitWith {};
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    if (isNil "_operation") exitWith {};
    if !((_operation getOrDefault ["kind", ""]) in ["DEFENDER", "PATROL", "REINFORCEMENT", "AIRBORNE_REINFORCEMENT"]) exitWith {};
    [
        _operation getOrDefault ["pressureSector", ""],
        if (_lossType == "MANPOWER") then {1} else {4}
    ] call BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE;
};

BATTLESPACE_REINFORCEMENT_BUILD_DEFINITION = {
    params ["_sourceSector"];
    private _empty = createHashMap;
    private _state = BATTLESPACE_SECTOR_STATES get _sourceSector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {_empty};
    private _sectorType = _state get "type";
    private _resources = _state get "resources";
    private _thresholds = [_sectorType, "SendReinforcements"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
    private _manpower = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_REINFORCEMENT_MANPOWER", 14];
    private _manpowerReserve = ceil (([_sectorType, "manpower"] call BATTLESPACE_SECTOR_GET_CAPACITY) * (_thresholds getOrDefault ["manpower", 1]));
    if ((_resources getOrDefault ["manpower", 0]) - _manpowerReserve < _manpower) exitWith {_empty};

    private _vehicles = [];
    {
        private _threshold = _thresholds getOrDefault [_x, -1];
        private _capacity = [_sectorType, _x] call BATTLESPACE_SECTOR_GET_CAPACITY;
        if (_threshold < 0 || {(_resources getOrDefault [_x, 0]) <= ceil (_capacity * _threshold)}) then {continue};
        private _class = [_x] call BATTLESPACE_STRATEGIC_GET_CLASS_FOR_RESOURCE;
        if (_class != "") exitWith {_vehicles pushBack _class};
    } forEach ["ifv", "apc", "car"];
    createHashMapFromArray [["manpower", _manpower], ["vehicles", _vehicles], ["structures", []]]
};

BATTLESPACE_REINFORCEMENT_DISPATCH = {
    params ["_targetSector"];
    if ((["REINFORCEMENT", _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET)
        || {["AIRBORNE_TRANSPORT", _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET}
        || {["AIRBORNE_REINFORCEMENT", _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET}
        || {["BATTLEGROUP", _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET}) exitWith {false};
    if (!isNil "BATTLESPACE_AIRBORNE_DISPATCH" && {[_targetSector] call BATTLESPACE_AIRBORNE_DISPATCH}) exitWith {true};
    if (["REINFORCEMENT"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_REINFORCEMENTS", 3])) exitWith {false};
    private _network = NETWORKED_SECTORS get _targetSector;
    if (isNil "_network") exitWith {false};
    private _sources = (_network getOrDefault ["Links", []]) select {
        private _state = BATTLESPACE_SECTOR_STATES get _x;
        !isNil "_state" && {(_state getOrDefault ["owner", ""]) == "OPFOR"}
    };
    private _dispatched = false;
    {
        private _composition = [_x] call BATTLESPACE_REINFORCEMENT_BUILD_DEFINITION;
        if (count _composition == 0) then {continue};
        private _id = [
            "Battlegroup", _composition, getMarkerPos _x, getMarkerPos _targetSector, getMarkerPos _x,
            _x, "REINFORCEMENT", createHashMapFromArray [
                ["phase", "ENROUTE"], ["targetSector", _targetSector], ["pressureSector", _targetSector]
            ]
        ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
        if (_id != "") exitWith {
            _dispatched = true;
            [format ["Dispatched casualty reinforcement %1 from %2 to %3", _id, _x, _targetSector]] call BATTLESPACE_STRATEGIC_LOG;
        };
    } forEach _sources;
    if (_dispatched) then {[] call BATTLESPACE_LOGISTICS_SAVE};
    _dispatched
};

BATTLESPACE_PATROL_GET_FRONTLINE_TARGETS = {
    params ["_originSector"];
    private _network = NETWORKED_SECTORS get _originSector;
    if (isNil "_network") exitWith {[]};
    private _capturableBlufor = blufor_sectors arrayIntersect sectors_allSectors;
    (_network getOrDefault ["Links", []]) select {_x in _capturableBlufor}
};

BATTLESPACE_PATROL_HAS_ACTIVE_CORRIDOR = {
    params ["_originSector", "_targetSector"];
    private _found = false;
    {
        if (
            (_y getOrDefault ["kind", ""]) == "PATROL"
            && {
                (_y getOrDefault ["originSector", ""]) == _originSector
                || {(_y getOrDefault ["targetSector", ""]) == _targetSector}
            }
        ) exitWith {_found = true};
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _found
};

BATTLESPACE_PATROL_BUILD_PROBE_POSITIONS = {
    params ["_originSector", "_targetSector"];
    private _origin = getMarkerPos _originSector;
    private _target = getMarkerPos _targetSector;
    private _distance = _origin distance2D _target;
    if (_distance < 400) exitWith {[]};

    private _direction = _origin getDir _target;
    private _standoff = 100 max (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_PATROL_BLUFOR_STANDOFF", 350]);
    private _lateralLimit = 0 max (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_PATROL_LATERAL_OFFSET", 250]);
    private _positions = [];
    private _project = {
        params ["_forward", "_lateral"];
        private _axis = _direction;
        if (_forward < 0) then {_axis = _axis + 180};
        private _position = _origin getPos [abs _forward, _axis];
        if (_lateral != 0) then {
            private _lateralDirection = _direction + ([90, -90] select (_lateral < 0));
            _position = _position getPos [abs _lateral, _lateralDirection];
        };
        _position set [2, 0];
        _position
    };
    private _isValid = {
        params ["_position"];
        if (
            (_position param [0, -1]) < 0
            || {(_position param [1, -1]) < 0}
            || {(_position param [0, worldSize + 1]) > worldSize}
            || {(_position param [1, worldSize + 1]) > worldSize}
            || {surfaceIsWater _position}
            || {_position distance2D _target < _standoff}
            || {_positions findIf {_x distance2D _position < 150} >= 0}
        ) exitWith {false};
        true
    };

    private _rearRange = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_PATROL_REAR_SCREEN_RANGE", [150, 350]];
    private _rearMinimum = 50 max (_rearRange param [0, 150]);
    private _rearMaximum = _rearMinimum max (_rearRange param [1, 350]);
    for "_attempt" from 1 to 8 do {
        private _rearDistance = -(_rearMinimum + random (_rearMaximum - _rearMinimum));
        private _lateral = -_lateralLimit + random (2 * _lateralLimit);
        private _candidate = [_rearDistance, _lateral] call _project;
        if ([_candidate] call _isValid) exitWith {_positions pushBack _candidate};
    };

    private _forwardRatios = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_PATROL_FORWARD_RATIOS", [0.35, 0.60]];
    private _maximumForward = (_distance - _standoff) max 0;
    {
        private _baseRatio = (_x max 0.15) min 0.80;
        for "_attempt" from 1 to 8 do {
            private _ratio = (((_baseRatio - 0.08) + random 0.16) max 0.15) min 0.80;
            private _forwardDistance = (_distance * _ratio) min _maximumForward;
            if (_forwardDistance < 100) then {continue};
            private _legLateralLimit = _lateralLimit min (_distance * 0.2);
            private _lateral = -_legLateralLimit + random (2 * _legLateralLimit);
            private _candidate = [_forwardDistance, _lateral] call _project;
            if ([_candidate] call _isValid) exitWith {_positions pushBack _candidate};
        };
    } forEach _forwardRatios;

    if (count _positions < 2) exitWith {[]};
    _positions
};

BATTLESPACE_PATROL_DISPATCH = {
    params ["_originSector", "_targetSector"];
    if (["PATROL"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_PATROLS", 8])) exitWith {false};
    if !(_targetSector in ([_originSector] call BATTLESPACE_PATROL_GET_FRONTLINE_TARGETS)) exitWith {false};
    if ([_originSector, _targetSector] call BATTLESPACE_PATROL_HAS_ACTIVE_CORRIDOR) exitWith {false};
    private _state = BATTLESPACE_SECTOR_STATES get _originSector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith {false};
    private _sectorType = _state get "type";
    private _resources = _state get "resources";
    private _thresholds = [_sectorType, "Patrol"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
    private _manpower = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_PATROL_MANPOWER", 7];
    private _threshold = _thresholds getOrDefault ["manpower", -1];
    if (_threshold < 0 || {(_resources getOrDefault ["manpower", 0]) < ceil (([_sectorType, "manpower"] call BATTLESPACE_SECTOR_GET_CAPACITY) * _threshold)}) exitWith {false};

    private _vehicles = [];
    {
        private _vehicleThreshold = _thresholds getOrDefault [_x, -1];
        private _capacity = [_sectorType, _x] call BATTLESPACE_SECTOR_GET_CAPACITY;
        if (_vehicleThreshold < 0 || {(_resources getOrDefault [_x, 0]) <= ceil (_capacity * _vehicleThreshold)}) then {continue};
        private _class = [_x] call BATTLESPACE_STRATEGIC_GET_CLASS_FOR_RESOURCE;
        if (_class != "") exitWith {_vehicles pushBack _class};
    } forEach ["car", "apc", "ifv"];
    private _composition = createHashMapFromArray [["manpower", _manpower], ["vehicles", _vehicles], ["structures", []]];
    private _origin = getMarkerPos _originSector;
    private _probePositions = [_originSector, _targetSector] call BATTLESPACE_PATROL_BUILD_PROBE_POSITIONS;
    if (count _probePositions < 2) exitWith {
        [format ["Rejected patrol corridor %1 -> %2 because fewer than two valid probe legs were found", _originSector, _targetSector], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };
    private _target = _probePositions select 0;
    private _id = [
        "Battlegroup", _composition, _origin, _target, _origin, _originSector, "PATROL",
        createHashMapFromArray [
            ["phase", "OUTBOUND"], ["targetSector", _targetSector], ["targetPosition", _target],
            ["probePositions", _probePositions], ["probeIndex", 0]
        ]
    ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_id == "") exitWith {false};
    _state set ["nextPatrolAt", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_PATROL_COOLDOWN", 2400])];
    BATTLESPACE_SECTOR_STATES set [_originSector, _state];
    [] call BATTLESPACE_LOGISTICS_SAVE;
    [format ["Dispatched strategic patrol %1 through corridor %2 -> %3", _id, _originSector, _targetSector]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_PATROL_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    private _candidates = [];
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR" || {CBA_missionTime < (_y getOrDefault ["nextPatrolAt", 0])}) then {continue};
        private _originSector = _x;
        private _priority = ((_y getOrDefault ["casualtyPressure", 0]) * 1000000) + ((CBA_missionTime - (_y getOrDefault ["nextPatrolAt", 0])) max 0);
        {
            if !([_originSector, _x] call BATTLESPACE_PATROL_HAS_ACTIVE_CORRIDOR) then {
                _candidates pushBack [_priority, _originSector, _x];
            };
        } forEach ([_originSector] call BATTLESPACE_PATROL_GET_FRONTLINE_TARGETS);
    } forEach BATTLESPACE_SECTOR_STATES;
    _candidates = [_candidates, [], {_x param [0, 0]}, "DESCEND"] call BIS_fnc_sortBy;
    {
        if (["PATROL"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_PATROLS", 8])) exitWith {};
        [_x param [1, ""], _x param [2, ""]] call BATTLESPACE_PATROL_DISPATCH;
    } forEach _candidates;
};

BATTLESPACE_TACTICAL_ABANDON_CAPTURED_DEFENDERS = {
    private _abandoned = [];
    {
        if !((_y getOrDefault ["kind", ""]) in ["DEFENDER", "FORTIFICATION"]) then {continue};
        private _sector = _y getOrDefault ["fundingSector", ""];
        private _state = BATTLESPACE_SECTOR_STATES get _sector;
        if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) then {_abandoned pushBack _x};
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    {
        private _taskForce = BATTLESPACE_TASK_FORCES get _x;
        BATTLESPACE_STRATEGIC_OPERATIONS deleteAt _x;
        BATTLESPACE_TASK_FORCES deleteAt _x;
        BATTLESPACE_TASK_FORCE_PATHS deleteAt _x;
        BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS deleteAt _x;
        if (!isNil "_taskForce") then {[_taskForce] call BATTLESPACE_STRATEGIC_RETIRE_PHYSICAL_FORCE};
    } forEach _abandoned;
    if (_abandoned isNotEqualTo []) then {
        [format ["Abandoned %1 funded defensive task forces after sector ownership changes", count _abandoned]] call BATTLESPACE_STRATEGIC_LOG;
        [] call BATTLESPACE_LOGISTICS_SAVE;
    };
};

BATTLESPACE_TACTICAL_MAINTENANCE_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    [] call BATTLESPACE_TACTICAL_ABANDON_CAPTURED_DEFENDERS;
    private _threshold = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_CASUALTY_RESPONSE_THRESHOLD", 8];
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR" || {(_y getOrDefault ["casualtyPressure", 0]) < _threshold}) then {continue};
        private _handled = false;
        if (CBA_missionTime >= (_y getOrDefault ["nextReinforcementAt", 0])) then {
            _handled = [_x] call BATTLESPACE_REINFORCEMENT_DISPATCH;
            if (_handled) then {
                _y set ["nextReinforcementAt", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_REINFORCEMENT_COOLDOWN", 1200])];
            };
        };
        if (!_handled && {CBA_missionTime >= (_y getOrDefault ["nextEmergencyAt", 0])}
            && {!(["CONVOY", _x] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET)}) then {
            private _request = [_x, "EmergencyResupply"] call BATTLESPACE_LOGISTICS_BUILD_REQUEST;
            if (count _request > 0) then {_handled = [_x, _request] call BATTLESPACE_LOGISTICS_DISPATCH};
            if (_handled) then {
                _y set ["nextEmergencyAt", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_EMERGENCY_COOLDOWN", 900])];
            };
        };
        if (_handled) then {
            _y set ["casualtyPressure", ((_y getOrDefault ["casualtyPressure", 0]) - _threshold) max 0];
            BATTLESPACE_SECTOR_STATES set [_x, _y];
        };
    } forEach BATTLESPACE_SECTOR_STATES;
};

BATTLESPACE_STRATEGIC_BUILD_SECTOR_SNAPSHOT = {
    params ["_sector"];
    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state") exitWith {[]};
    private _type = _state getOrDefault ["type", ""];
    private _resources = _state getOrDefault ["resources", createHashMap];
    private _emergencyThresholds = [_type, "EmergencyResupply"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
    private _stock = [];
    {
        private _capacity = [_type, _x] call BATTLESPACE_SECTOR_GET_CAPACITY;
        private _amount = _resources getOrDefault [_x, 0];
        private _thresholds = if (_x == "construction_supplies") then {
            [_type, "Fortification"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP
        } else {
            _emergencyThresholds
        };
        private _threshold = _thresholds getOrDefault [_x, -1];
        _stock pushBack [_x, _amount, _capacity, _threshold >= 0 && {_amount < ceil (_capacity * _threshold)}];
    } forEach BATTLESPACE_RESOURCE_TYPES;
    private _operations = [];
    {
        if ((_y getOrDefault ["targetSector", ""]) == _sector || {(_y getOrDefault ["fundingSector", ""]) == _sector}) then {
            _operations pushBack [_x, _y getOrDefault ["kind", ""], _y getOrDefault ["phase", ""]];
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    {
        if ((_x getVariable ["BSAFundingSector", ""]) == _sector) then {
            private _status = (_x getVariable ["BSAState", ["UNKNOWN"]]) param [0, "UNKNOWN"];
            _operations pushBack ["ARTY-" + str _x, "ARTILLERY", _status];
        };
    } forEach (missionNamespace getVariable ["BATTLESPACE_ARTILLERY_SECTIONS", []]);
    {
        if ((_x getOrDefault ["Sector", ""]) == _sector) then {
            private _siteId = _x getOrDefault ["Id", ""];
            private _poolState = BATTLESPACE_SAM_SITE_POOLS get _siteId;
            private _pools = if (isNil "_poolState") then {createHashMap} else {_poolState getOrDefault ["Pools", createHashMap]};
            _operations pushBack [
                "SAM-" + _siteId,
                "SAM",
                format ["ACTIVE S:%1 T:%2", _pools getOrDefault ["strategic_missiles", 0], _pools getOrDefault ["tactical_missiles", 0]]
            ];
        };
    } forEach (missionNamespace getVariable ["BATTLESPACE_SAM_EXISTING_SITES", []]);
    [
        _sector, _type, _state getOrDefault ["owner", ""], _stock,
        _state getOrDefault ["casualtyPressure", 0],
        [
            ((_state getOrDefault ["nextResupplyAt", 0]) - CBA_missionTime) max 0,
            ((_state getOrDefault ["nextEmergencyAt", 0]) - CBA_missionTime) max 0,
            ((_state getOrDefault ["nextReinforcementAt", 0]) - CBA_missionTime) max 0,
            ((_state getOrDefault ["nextPatrolAt", 0]) - CBA_missionTime) max 0,
            ((_state getOrDefault ["nextBattlegroupAt", 0]) - CBA_missionTime) max 0,
            ((_state getOrDefault ["nextAirResponseAt", 0]) - CBA_missionTime) max 0,
            ((_state getOrDefault ["nextFortificationAt", 0]) - CBA_missionTime) max 0
        ],
        _operations
    ]
};

BATTLESPACE_STRATEGIC_BUILD_INTEGRITY_AUDIT = {
    private _errors = [];
    private _warnings = [];
    private _fortificationsBySector = createHashMap;
    {
        private _sector = _x;
        private _state = _y;
        private _type = _state getOrDefault ["type", ""];
        private _expectedOwner = ["OPFOR", "BLUFOR"] select (_sector in blufor_sectors);
        if ((_state getOrDefault ["owner", ""]) != _expectedOwner) then {_errors pushBack format ["%1 owner is stale", _sector]};
        private _resources = _state getOrDefault ["resources", createHashMap];
        {
            private _amount = _resources getOrDefault [_x, -1];
            private _capacity = [_type, _x] call BATTLESPACE_SECTOR_GET_CAPACITY;
            if !(_amount isEqualType 0) then {_errors pushBack format ["%1/%2 is non-numeric", _sector, _x]; continue};
            if (_amount < 0 || {_amount > _capacity}) then {_errors pushBack format ["%1/%2 is %3 outside 0..%4", _sector, _x, _amount, _capacity]};
        } forEach BATTLESPACE_RESOURCE_TYPES;
    } forEach BATTLESPACE_SECTOR_STATES;
    {
        private _taskForce = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_taskForce") then {_errors pushBack format ["Operation %1 has no task force", _x]};
        if ((_y getOrDefault ["kind", ""]) == "AIR_RESPONSE" && {!isNil "_taskForce"}) then {
            private _phase = _y getOrDefault ["phase", ""];
            private _position = _y getOrDefault ["contactPosition", []];
            private _composition = _taskForce param [3, createHashMap];
            private _vehicles = if (typeName _composition == "HASHMAP") then {_composition getOrDefault ["vehicles", []]} else {[]};
            private _manifest = _y getOrDefault ["vehicleManifest", []];
            private _cost = _y getOrDefault ["cost", createHashMap];
            if ((_taskForce param [0, ""]) != "Air Response") then {
                _errors pushBack format ["Air response operation %1 uses the wrong task-force model", _x];
            };
            if !(_phase in ["INTERCEPT", "ON_STATION", "RETURNING"]) then {
                _errors pushBack format ["Air response operation %1 has invalid phase %2", _x, _phase];
            };
            if !(_position isEqualType [] && {(count _position) in [2, 3]} && {_position findIf {!(_x isEqualType 0)} < 0}) then {
                _errors pushBack format ["Air response operation %1 has malformed contact position", _x];
            };
            private _vehicleCompositionValid = _vehicles isEqualType []
                && {_vehicles isNotEqualTo []}
                && {_vehicles findIf {!(_x isEqualType "") || {!(_x isKindOf "Air")}} < 0};
            if (!_vehicleCompositionValid) then {
                _errors pushBack format ["Air response operation %1 has a non-aircraft composition", _x];
            };
            private _manifestValid = _manifest isEqualType []
                && {_vehicles isEqualType []}
                && {count _manifest == count _vehicles}
                && {_manifest findIf {!(_x isEqualType []) || {(_x param [1, ""]) != "aircraft"}} < 0};
            if (!_manifestValid) then {
                _errors pushBack format ["Air response operation %1 has an invalid aircraft manifest", _x];
            };
            if (typeName _cost != "HASHMAP" || {count _cost != 1} || {(_cost getOrDefault ["aircraft", 0]) != 1}) then {
                _errors pushBack format ["Air response operation %1 does not own exactly one paid aircraft", _x];
            };
            if !((_y getOrDefault ["targetKind", ""]) in ["AIR", "ARMOR"]) then {
                _errors pushBack format ["Air response operation %1 has an invalid target kind", _x];
            };
        };
        if ((_y getOrDefault ["kind", ""]) == "AIRBORNE_TRANSPORT" && {!isNil "_taskForce"}) then {
            private _phase = _y getOrDefault ["phase", ""];
            private _composition = _taskForce param [3, createHashMap];
            private _vehicles = _composition getOrDefault ["vehicles", []];
            if ((_taskForce param [0, ""]) != "Airborne Transport") then {
                _errors pushBack format ["Airborne transport operation %1 uses the wrong task-force model", _x];
            };
            if !(_phase in ["ENROUTE", "DEPLOYING", "RETURNING"]) then {
                _errors pushBack format ["Airborne transport operation %1 has invalid phase %2", _x, _phase];
            };
            if (count _vehicles != 1 || {_vehicles findIf {!(_x isKindOf "Air")} >= 0}) then {
                _errors pushBack format ["Airborne transport operation %1 does not own exactly one aircraft", _x];
            };
        };
        if ((_y getOrDefault ["kind", ""]) == "AIRBORNE_REINFORCEMENT" && {!isNil "_taskForce"}) then {
            private _composition = _taskForce param [3, createHashMap];
            if ((_taskForce param [0, ""]) != "Airborne Infantry") then {
                _errors pushBack format ["Airborne infantry operation %1 uses the wrong task-force model", _x];
            };
            if ((_y getOrDefault ["phase", ""]) != "DEPLOYED") then {
                _errors pushBack format ["Airborne infantry operation %1 is not deployed", _x];
            };
            if ((_composition getOrDefault ["vehicles", []]) isNotEqualTo []) then {
                _errors pushBack format ["Airborne infantry operation %1 still owns a vehicle", _x];
            };
        };
        if ((_y getOrDefault ["kind", ""]) == "FORTIFICATION") then {
            private _sector = _y getOrDefault ["targetSector", ""];
            private _tier = _y getOrDefault ["fortificationTier", 0];
            private _position = _y getOrDefault ["sitePosition", []];
            if (_sector == "" || {_tier < 1} || {_tier > 3} || {!(_position isEqualType [])} || {count _position < 2}) then {
                _errors pushBack format ["Fortification operation %1 has malformed site metadata", _x];
            };
            if (!isNil "_taskForce" && {_tier >= 1} && {_tier <= 3}) then {
                private _composition = _taskForce param [3, createHashMap];
                if (typeName _composition != "HASHMAP") then {
                    _errors pushBack format ["Fortification operation %1 has a malformed composition", _x];
                } else {
                    private _expectedManpower = (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_FORTIFICATION_MANPOWER_BY_TIER", [4, 5, 7]]) param [_tier - 1, -1];
                    private _assignedManpower = _y getOrDefault ["assignedManpower", -1];
                    private _currentManpower = _composition getOrDefault ["manpower", -1];
                    if !(_assignedManpower isEqualType 0) then {
                        _errors pushBack format ["Fortification operation %1 has non-numeric assigned manpower", _x];
                    } else {
                        if (_assignedManpower != _expectedManpower) then {
                            _errors pushBack format ["Fortification operation %1 tier %2 assigned manpower is %3, expected %4", _x, _tier, _assignedManpower, _expectedManpower];
                        };
                    };
                    if !((_composition getOrDefault ["structureCrewFromManpower", false]) isEqualTo true) then {
                        _errors pushBack format ["Fortification operation %1 does not charge static crews to manpower", _x];
                    };
                    if !(_currentManpower isEqualType 0) then {
                        _errors pushBack format ["Fortification operation %1 has non-numeric current manpower", _x];
                    } else {
                        if (_currentManpower < 0 || {_assignedManpower isEqualType 0 && {_currentManpower > _assignedManpower}}) then {
                            _errors pushBack format ["Fortification operation %1 current manpower %2 is outside 0..%3", _x, _currentManpower, _assignedManpower];
                        };
                    };
                };
            };
            _fortificationsBySector set [_sector, (_fortificationsBySector getOrDefault [_sector, 0]) + 1];
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    private _perSectorCap = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_FORTIFICATIONS_PER_SECTOR", 3];
    {
        if (_y > _perSectorCap) then {_errors pushBack format ["%1 owns %2 fortification operations above cap %3", _x, _y, _perSectorCap]};
    } forEach _fortificationsBySector;
    private _globalFortificationCap = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_FORTIFICATIONS", 48];
    if (["FORTIFICATION"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS > _globalFortificationCap) then {
        _errors pushBack format ["Global fortification operation count exceeds %1", _globalFortificationCap];
    };
    private _globalAirResponseCap = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIR_RESPONSES", 2];
    if (["AIR_RESPONSE"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS > _globalAirResponseCap) then {
        _errors pushBack format ["Global air-response operation count exceeds %1", _globalAirResponseCap];
    };
    private _globalAirborneCap = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIRBORNE_TRANSPORTS", 2];
    if (["AIRBORNE_TRANSPORT"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS > _globalAirborneCap) then {
        _errors pushBack format ["Global airborne-transport operation count exceeds %1", _globalAirborneCap];
    };
    {
        private _type = _y param [0, ""];
        if (_type in ["Battlegroup", "Convoy", "Air Response", "Airborne Transport", "Airborne Infantry"] && {isNil {BATTLESPACE_STRATEGIC_OPERATIONS get _x}}) then {
            _warnings pushBack format ["Task force %1 (%2) has no operation", _x, _type];
        };
    } forEach BATTLESPACE_TASK_FORCES;
    private _saved = profileNamespace getVariable [BATTLESPACE_LOGISTICS_SAVE_KEY, createHashMap];
    if (
        typeName _saved != "HASHMAP"
        || {typeName (_saved getOrDefault ["sectors", objNull]) != "HASHMAP"}
        || {typeName (_saved getOrDefault ["operations", objNull]) != "HASHMAP"}
    ) then {
        _warnings pushBack "No structurally valid persisted strategic snapshot exists";
    };
    [_errors, _warnings, count BATTLESPACE_SECTOR_STATES, count BATTLESPACE_STRATEGIC_OPERATIONS]
};

BATTLESPACE_STRATEGIC_BUILD_BALANCE_REPORT = {
    private _resourceRows = [];
    {
        private _resource = _x;
        private _total = 0;
        private _capacity = 0;
        private _shortages = 0;
        {
            if ((_y getOrDefault ["owner", ""]) != "OPFOR") then {continue};
            private _type = _y getOrDefault ["type", ""];
            private _amount = (_y getOrDefault ["resources", createHashMap]) getOrDefault [_resource, 0];
            private _sectorCapacity = [_type, _resource] call BATTLESPACE_SECTOR_GET_CAPACITY;
            private _thresholdType = ["EmergencyResupply", "Fortification"] select (_resource == "construction_supplies");
            private _threshold = ([_type, _thresholdType] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP) getOrDefault [_resource, -1];
            _total = _total + _amount;
            _capacity = _capacity + _sectorCapacity;
            if (_threshold >= 0 && {_amount < ceil (_sectorCapacity * _threshold)}) then {_shortages = _shortages + 1};
        } forEach BATTLESPACE_SECTOR_STATES;
        _resourceRows pushBack [_resource, _total, _capacity, _shortages];
    } forEach BATTLESPACE_RESOURCE_TYPES;

    private _operationRows = [];
    {
        _x params ["_kind", "_cap"];
        _operationRows pushBack [_kind, [_kind] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS, _cap];
    } forEach [
        ["CONVOY", missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_CONVOYS", 3]],
        ["BATTLEGROUP", missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_BATTLEGROUPS", 2]],
        ["REINFORCEMENT", missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_REINFORCEMENTS", 3]],
        ["AIRBORNE_TRANSPORT", missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIRBORNE_TRANSPORTS", 2]],
        ["AIRBORNE_REINFORCEMENT", -1],
        ["PATROL", missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_PATROLS", 8]],
        ["AIR_RESPONSE", missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIR_RESPONSES", 2]],
        ["FORTIFICATION", missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_FORTIFICATIONS", 48]],
        ["DEFENDER", -1]
    ];
    [_resourceRows, _operationRows, [
        missionNamespace getVariable ["BATTLESPACE_STRATEGIC_DECISION_INTERVAL", 1800],
        missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_DECISION_INTERVAL", 60],
        missionNamespace getVariable ["BATTLESPACE_STRATEGIC_CASUALTY_RESPONSE_THRESHOLD", 8],
        missionNamespace getVariable ["BATTLESPACE_STRATEGIC_EMERGENCY_COOLDOWN", 900],
        missionNamespace getVariable ["BATTLESPACE_STRATEGIC_REINFORCEMENT_COOLDOWN", 1200],
        missionNamespace getVariable ["BATTLESPACE_STRATEGIC_PATROL_COOLDOWN", 2400],
        missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_COOLDOWN", 1800],
        missionNamespace getVariable ["BATTLESPACE_STRATEGIC_FORTIFICATION_COOLDOWN", 1800]
    ]]
};

BATTLESPACE_STRATEGIC_RUN_SELF_TEST = {
    params ["_sector"];
    private _errors = [];
    private _warnings = [];
    private _state = BATTLESPACE_SECTOR_STATES get _sector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) then {
        _errors pushBack "Select a position nearest to an OPFOR sector before running the self-test";
    } else {
        private _before = [(_state getOrDefault ["resources", createHashMap])] call BATTLESPACE_COPY_RESOURCE_MAP;
        private _available = _before getOrDefault ["manpower", 0];
        if ([_sector, createHashMapFromArray [["manpower", -(_available + 1)]]] call BATTLESPACE_RESOURCE_APPLY_STRICT) then {
            _errors pushBack "An impossible strict debit was accepted";
        };
        private _afterRejectedDebit = (BATTLESPACE_SECTOR_STATES get _sector) getOrDefault ["resources", createHashMap];
        {
            if ((_afterRejectedDebit getOrDefault [_x, -1]) != _y) then {
                _errors pushBack format ["Rejected debit changed %1", _x];
            };
        } forEach _before;

        if (_available > 0) then {
            if !([_sector, createHashMapFromArray [["manpower", -1]]] call BATTLESPACE_RESOURCE_APPLY_STRICT) then {
                _errors pushBack "A valid one-point debit was rejected";
            } else {
                [_sector, createHashMapFromArray [["manpower", 1]]] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
                private _afterRoundTrip = (BATTLESPACE_SECTOR_STATES get _sector) getOrDefault ["resources", createHashMap];
                {
                    if ((_afterRoundTrip getOrDefault [_x, -1]) != _y) then {
                        _errors pushBack format ["Debit/refund round trip changed %1", _x];
                    };
                } forEach _before;
            };
        } else {
            _warnings pushBack "Selected sector has no manpower, so the successful debit/refund check was skipped";
        };

        private _sectorType = _state getOrDefault ["type", ""];
        private _constructionCapacity = [_sectorType, "construction_supplies"] call BATTLESPACE_SECTOR_GET_CAPACITY;
        private _constructionThreshold = ([_sectorType, "Fortification"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP) getOrDefault ["construction_supplies", -1];
        if (_constructionCapacity <= 0 || {_constructionThreshold < 0}) then {
            _errors pushBack "Selected sector has no valid construction-supplies policy";
        } else {
            private _constructionAvailable = _before getOrDefault ["construction_supplies", 0];
            if (_constructionAvailable > 0) then {
                if !([_sector, createHashMapFromArray [["construction_supplies", -1]]] call BATTLESPACE_RESOURCE_APPLY_STRICT) then {
                    _errors pushBack "A valid construction-supplies debit was rejected";
                } else {
                    [_sector, createHashMapFromArray [["construction_supplies", 1]]] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
                    private _afterConstructionRoundTrip = (BATTLESPACE_SECTOR_STATES get _sector) getOrDefault ["resources", createHashMap];
                    if ((_afterConstructionRoundTrip getOrDefault ["construction_supplies", -1]) != _constructionAvailable) then {
                        _errors pushBack "Construction-supplies debit/refund round trip changed the balance";
                    };
                };
            } else {
                _warnings pushBack "Selected sector has no construction supplies, so its successful debit/refund check was skipped";
            };
        };
        _state = BATTLESPACE_SECTOR_STATES get _sector;
        _state set ["resources", [_before] call BATTLESPACE_COPY_RESOURCE_MAP];
        BATTLESPACE_SECTOR_STATES set [_sector, _state];
    };

    if !([] call BATTLESPACE_LOGISTICS_SAVE) then {_errors pushBack "Strategic save call failed"};
    private _strategicSave = profileNamespace getVariable [BATTLESPACE_LOGISTICS_SAVE_KEY, createHashMap];
    private _taskForceSave = profileNamespace getVariable [BATTLESPACE_TASK_FORCE_SAVE_KEY, createHashMap];
    if (
        typeName _strategicSave != "HASHMAP"
        || {typeName (_strategicSave getOrDefault ["sectors", objNull]) != "HASHMAP"}
        || {typeName (_strategicSave getOrDefault ["operations", objNull]) != "HASHMAP"}
    ) then {
        _errors pushBack "Structurally valid strategic snapshot was not written";
    } else {
        private _savedSectors = _strategicSave getOrDefault ["sectors", createHashMap];
        private _savedOperations = _strategicSave getOrDefault ["operations", createHashMap];
        if (typeName _savedSectors != "HASHMAP" || {count _savedSectors != count BATTLESPACE_SECTOR_STATES}) then {
            _errors pushBack "Persisted sector count does not match live state";
        };
        {
            if (isNil {_savedOperations get _x}) then {_errors pushBack format ["Operation %1 was not persisted", _x]};
        } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    };
    if (
        typeName _taskForceSave != "HASHMAP"
        || {!((_taskForceSave getOrDefault ["AI", -1]) isEqualType 0)}
        || {typeName (_taskForceSave getOrDefault ["TaskForces", objNull]) != "HASHMAP"}
    ) then {
        _errors pushBack "Structurally valid task-force snapshot was not written";
    } else {
        private _savedTaskForces = _taskForceSave getOrDefault ["TaskForces", createHashMap];
        {
            if (isNil {_savedTaskForces get _x}) then {_errors pushBack format ["Task force %1 was not persisted", _x]};
        } forEach BATTLESPACE_TASK_FORCES;
    };
    [_errors, _warnings, count BATTLESPACE_SECTOR_STATES, count BATTLESPACE_STRATEGIC_OPERATIONS]
};

BATTLESPACE_ZEN_SERVER_CREATE_TASK_FORCE = {
    params ["_type", "_composition", "_origin", "_destination", "_home"];
    if (!isServer || {!isRemoteExecuted}) exitWith {};
    private _caller = (allPlayers select {owner _x == remoteExecutedOwner}) param [0, objNull];
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {};
    if !(_type in ["Defensive Patrol", "Outpost"]) exitWith {};
    if (typeName _composition != "HASHMAP") exitWith {};
    if !(_origin isEqualType [] && {(count _origin) in [2, 3]} && {_origin findIf {!(_x isEqualType 0)} < 0}) exitWith {};
    if !(_home isEqualType [] && {(count _home) in [2, 3]} && {_home findIf {!(_x isEqualType 0)} < 0}) exitWith {};
    if !(_destination isEqualType [] && {count _destination == 0 || {(count _destination) in [2, 3] && {_destination findIf {!(_x isEqualType 0)} < 0}}}) exitWith {};
    private _manpower = _composition getOrDefault ["manpower", -1];
    private _vehicles = _composition getOrDefault ["vehicles", []];
    private _structures = _composition getOrDefault ["structures", []];
    if !(_manpower isEqualType 0 && {_manpower >= 0} && {_manpower <= 60} && {_vehicles isEqualType []} && {count _vehicles <= 16} && {_structures isEqualType []} && {count _structures <= 100}) exitWith {};
    if (_vehicles findIf {
        !(_x isEqualType "") || {!isClass (configFile >> "CfgVehicles" >> _x)} || {!(_x isKindOf "LandVehicle")}
    } >= 0) exitWith {};
    if (_structures findIf {
        if (typeName _x != "HASHMAP") exitWith {true};
        private _class = _x getOrDefault ["className", ""];
        private _position = _x getOrDefault ["position", []];
        _class == "" || {!isClass (configFile >> "CfgVehicles" >> _class)}
        || {!(_class isKindOf "Building" || {_class isKindOf "StaticWeapon"})}
        || {!(_position isEqualType [])} || {_position distance2D _origin > 1500}
    } >= 0) exitWith {};
    [_type, _composition, _origin, _destination, _home] call BATTLESPACE_TASK_FORCES_INIT;
};

BATTLESPACE_ZEN_EXECUTE_VALIDATED_ACTION = {
    params ["_action", "_nearest", "_ownerId"];
    switch (_action) do {
        case "RUN_DECISION": {
            [] call BATTLESPACE_LOGISTICS_DECISION_TICK;
            [] call BATTLESPACE_BATTLEGROUP_DECISION_TICK;
            [] call BATTLESPACE_PATROL_DECISION_TICK;
            [] call BATTLESPACE_AIR_RESPONSE_DECISION_TICK;
            [] call BATTLESPACE_FORTIFICATION_DECISION_TICK;
        };
        case "SAVE": {[] call BATTLESPACE_LOGISTICS_SAVE};
        case "SELF_TEST": {
            private _result = [_nearest] call BATTLESPACE_STRATEGIC_RUN_SELF_TEST;
            ["SELF_TEST", _result] remoteExecCall ["BATTLESPACE_ZEN_RECEIVE_SNAPSHOT", _ownerId];
        };
        case "EMERGENCY": {
            private _state = BATTLESPACE_SECTOR_STATES get _nearest;
            if (!isNil "_state" && {(_state getOrDefault ["owner", ""]) == "OPFOR"}) then {
                _state set ["casualtyPressure", missionNamespace getVariable ["BATTLESPACE_STRATEGIC_CASUALTY_RESPONSE_THRESHOLD", 8]];
                _state set ["nextEmergencyAt", 0];
                _state set ["nextReinforcementAt", 0];
                BATTLESPACE_SECTOR_STATES set [_nearest, _state];
                [] call BATTLESPACE_TACTICAL_MAINTENANCE_TICK;
            };
        };
        case "REFILL";
        case "DRAIN": {
            private _state = BATTLESPACE_SECTOR_STATES get _nearest;
            if (!isNil "_state" && {(_state getOrDefault ["owner", ""]) == "OPFOR"}) then {
                private _resources = _state get "resources";
                private _type = _state get "type";
                {
                    _resources set [_x, if (_action == "REFILL") then {[_type, _x] call BATTLESPACE_SECTOR_GET_CAPACITY} else {0}];
                } forEach BATTLESPACE_RESOURCE_TYPES;
                _state set ["resources", _resources];
                BATTLESPACE_SECTOR_STATES set [_nearest, _state];
                [] call BATTLESPACE_LOGISTICS_SAVE;
            };
        };
        case "FORTIFY": {
            private _state = BATTLESPACE_SECTOR_STATES get _nearest;
            if (!isNil "_state" && {(_state getOrDefault ["owner", ""]) == "OPFOR"}) then {
                private _previousCooldown = _state getOrDefault ["nextFortificationAt", 0];
                _state set ["nextFortificationAt", 0];
                BATTLESPACE_SECTOR_STATES set [_nearest, _state];
                if !([_nearest] call BATTLESPACE_FORTIFICATION_DISPATCH) then {
                    _state = BATTLESPACE_SECTOR_STATES get _nearest;
                    if (!isNil "_state") then {
                        _state set ["nextFortificationAt", _previousCooldown];
                        BATTLESPACE_SECTOR_STATES set [_nearest, _state];
                    };
                };
            };
        };
    };
    if (_action == "SELF_TEST") exitWith {};
    private _payload = if (_action in ["RUN_DECISION", "SAVE"]) then {
        private _counts = [];
        {_counts pushBack [_x, [_x] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS]} forEach ["CONVOY", "BATTLEGROUP", "DEFENDER", "REINFORCEMENT", "AIRBORNE_TRANSPORT", "AIRBORNE_REINFORCEMENT", "PATROL", "AIR_RESPONSE", "FORTIFICATION"];
        [count BATTLESPACE_SECTOR_STATES, count BATTLESPACE_TASK_FORCES, _counts]
    } else {
        [_nearest] call BATTLESPACE_STRATEGIC_BUILD_SECTOR_SNAPSHOT
    };
    [_action, _payload] remoteExecCall ["BATTLESPACE_ZEN_RECEIVE_SNAPSHOT", _ownerId];
};

BATTLESPACE_ZEN_SERVER_REQUEST = {
    params [["_action", "", [""]], ["_position", [], [[]]]];
    if (!isServer || {!isRemoteExecuted}) exitWith {};
    private _ownerId = remoteExecutedOwner;
    private _caller = (allPlayers select {owner _x == _ownerId}) param [0, objNull];
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {
        [format ["Rejected Battlespace ZEN request %1 from owner %2", _action, _ownerId], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
    };
    if !(_action in ["OVERVIEW", "INSPECT", "OVERLAY", "AUDIT", "BALANCE", "RUN_DECISION", "SAVE", "SELF_TEST", "EMERGENCY", "REFILL", "DRAIN", "FORTIFY"]) exitWith {};
    private _nearest = "";
    if (_position isEqualType [] && {(count _position) in [2, 3]} && {_position findIf {!(_x isEqualType 0)} < 0}) then {
        _nearest = [sectors_allSectors, _position] call BIS_fnc_nearestPosition;
    };

    if (_action in ["RUN_DECISION", "SAVE", "SELF_TEST", "EMERGENCY", "REFILL", "DRAIN", "FORTIFY"]) exitWith {
        [{_this call BATTLESPACE_ZEN_EXECUTE_VALIDATED_ACTION}, [_action, _nearest, _ownerId], 0] call CBA_fnc_waitAndExecute;
    };

    private _payload = [];
    if (_action == "AUDIT") then {
        _payload = [] call BATTLESPACE_STRATEGIC_BUILD_INTEGRITY_AUDIT;
    } else {
    if (_action == "BALANCE") then {
        _payload = [] call BATTLESPACE_STRATEGIC_BUILD_BALANCE_REPORT;
    } else {
        if (_action == "OVERVIEW") then {
            private _counts = [];
            {_counts pushBack [_x, [_x] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS]} forEach ["CONVOY", "BATTLEGROUP", "DEFENDER", "REINFORCEMENT", "AIRBORNE_TRANSPORT", "AIRBORNE_REINFORCEMENT", "PATROL", "AIR_RESPONSE", "FORTIFICATION"];
            _payload = [count BATTLESPACE_SECTOR_STATES, count BATTLESPACE_TASK_FORCES, _counts];
        } else {
            if (_action == "OVERLAY") then {
                private _sectors = [];
                {
                    private _resources = _y getOrDefault ["resources", createHashMap];
                    private _type = _y getOrDefault ["type", ""];
                    private _amount = 0;
                    private _capacity = 0;
                    {_amount = _amount + (_resources getOrDefault [_x, 0]); _capacity = _capacity + ([_type, _x] call BATTLESPACE_SECTOR_GET_CAPACITY)} forEach BATTLESPACE_RESOURCE_TYPES;
                    _sectors pushBack [_x, getMarkerPos _x, _y getOrDefault ["owner", ""], if (_capacity > 0) then {_amount / _capacity} else {0}, _y getOrDefault ["casualtyPressure", 0]];
                } forEach BATTLESPACE_SECTOR_STATES;
                private _operations = [];
                private _routeSnapshot = [(keys BATTLESPACE_STRATEGIC_OPERATIONS)] call BATTLESPACE_TASK_FORCE_BUILD_ROUTE_SNAPSHOT;
                {
                    private _taskForce = BATTLESPACE_TASK_FORCES get _x;
                    if (!isNil "_taskForce") then {
                        _operations pushBack [
                            _x,
                            _y getOrDefault ["kind", ""],
                            _y getOrDefault ["phase", ""],
                            _taskForce param [1, []],
                            _taskForce param [2, []],
                            _routeSnapshot getOrDefault [_x, []]
                        ];
                    };
                } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
                _payload = [_sectors, _operations];
            } else {
                _payload = [_nearest] call BATTLESPACE_STRATEGIC_BUILD_SECTOR_SNAPSHOT;
            };
        };
    };
    };
    [_action, _payload] remoteExecCall ["BATTLESPACE_ZEN_RECEIVE_SNAPSHOT", _ownerId];
};
