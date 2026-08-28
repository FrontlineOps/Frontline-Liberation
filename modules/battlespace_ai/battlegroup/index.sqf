/*
    Resource-backed operational battlegroups.

    This layer selects and funds operations. The registered Battlegroup model
    continues to own virtual movement and physical materialization.
*/

BATTLESPACE_BATTLEGROUP_BUILD_DEFINITION = {
    params ["_originSector"];
    private _empty = createHashMap;
    private _state = BATTLESPACE_SECTOR_STATES get _originSector;
    if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) exitWith { _empty };
    if ((_state getOrDefault ["type", ""]) != "military") exitWith { _empty };

    private _sectorType = _state get "type";
    private _resources = _state get "resources";
    private _thresholds = [_sectorType, "Battlegroup"] call BATTLESPACE_SECTOR_GET_THRESHOLD_MAP;
    private _manpowerCost = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_BATTLEGROUP_MANPOWER", 28];
    private _manpowerCapacity = [_sectorType, "manpower"] call BATTLESPACE_SECTOR_GET_CAPACITY;
    private _manpowerThreshold = _thresholds getOrDefault ["manpower", 1];
    private _availableManpower = _resources getOrDefault ["manpower", 0];
    if (
        _availableManpower < _manpowerCost
        || {_manpowerThreshold < 0}
        || {_availableManpower < ceil (_manpowerCapacity * _manpowerThreshold)}
    ) exitWith { _empty };

    private _cost = createHashMapFromArray [["manpower", _manpowerCost]];
    private _vehicles = [];
    private _vehicleManifest = [];
    private _categories = ["tanks", "ifv", "apc", "spaag", "car"];
    private _vehicleLimit = (missionNamespace getVariable ["GRLIB_battlegroup_size", 4]) max 1;
    private _progress = true;

    while {_progress && {count _vehicles < _vehicleLimit}} do {
        _progress = false;
        {
            if (count _vehicles >= _vehicleLimit) exitWith {};
            private _resourceType = _x;
            private _threshold = _thresholds getOrDefault [_resourceType, -1];
            private _capacity = [_sectorType, _resourceType] call BATTLESPACE_SECTOR_GET_CAPACITY;
            private _available = _resources getOrDefault [_resourceType, 0];
            private _alreadyUsed = _cost getOrDefault [_resourceType, 0];
            if (
                _threshold < 0
                || {_capacity <= 0}
                || {_available <= _alreadyUsed}
                || {_available < ceil (_capacity * _threshold)}
            ) then { continue };

            private _class = [_resourceType] call BATTLESPACE_STRATEGIC_GET_CLASS_FOR_RESOURCE;
            if (_class == "") then { continue };
            _vehicles pushBack _class;
            _vehicleManifest pushBack [_class, _resourceType];
            _cost set [_resourceType, _alreadyUsed + 1];
            _progress = true;
        } forEach _categories;
    };

    if (_vehicles isEqualTo []) exitWith { _empty };
    createHashMapFromArray [
        ["cost", _cost],
        ["vehicleManifest", _vehicleManifest],
        ["initialStrength", _manpowerCost + (4 * count _vehicles)],
        ["composition", createHashMapFromArray [
            ["manpower", _manpowerCost],
            ["vehicles", _vehicles],
            ["structures", []]
        ]]
    ]
};

BATTLESPACE_BATTLEGROUP_SET_DESTINATION = {
    params ["_taskForceId", "_taskForce", "_operation", "_phase", "_sector"];
    private _destination = getMarkerPos _sector;
    _operation set ["phase", _phase];
    _taskForce set [2, _destination];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceId;
    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
    BATTLESPACE_TASK_FORCES set [_taskForceId, _taskForce];

    {
        if (isNull _x) then { continue };
        private _hasVehicles = [_x] call BATTLESPACE_TASK_FORCE_HAS_VEHICLES;
        [_x, _destination, "FULL", false, _hasVehicles] spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
    } forEach (_taskForce param [4, []]);
};

BATTLESPACE_BATTLEGROUP_SETTLE = {
    params ["_taskForceId", "_taskForce", "_operation"];
    private _outcome = _operation getOrDefault ["outcome", "LOST"];
    private _destinationSector = switch (_outcome) do {
        case "RETURNED": {_operation getOrDefault ["originSector", ""]};
        case "CAPTURED": {_operation getOrDefault ["targetSector", ""]};
        case "REINFORCED": {_operation getOrDefault ["targetSector", ""]};
        default {""};
    };

    if (_destinationSector != "") then {
        private _survivors = [_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVING_FORCE_RESOURCES;
        private _accepted = [_destinationSector, _survivors] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
        [format [
            "Battlegroup %1 %2 at %3; survivors absorbed %4",
            _taskForceId,
            toLower _outcome,
            _destinationSector,
            _accepted
        ]] call BATTLESPACE_STRATEGIC_LOG;
    } else {
        [format ["Battlegroup %1 ended without a valid settlement sector", _taskForceId], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
    };
};

BATTLESPACE_BATTLEGROUP_BEGIN_RETREAT = {
    params ["_taskForceId", "_taskForce", "_operation"];
    private _originSector = _operation getOrDefault ["originSector", ""];
    private _originState = BATTLESPACE_SECTOR_STATES get _originSector;
    if (isNil "_originState" || {(_originState getOrDefault ["owner", ""]) != "OPFOR"}) then {
        _originSector = [(_taskForce param [1, [0, 0, 0]])] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
        _operation set ["originSector", _originSector];
    };

    if (_operation getOrDefault ["attackNotified", false]) then {
        [_operation getOrDefault ["targetSector", ""], 3] remoteExec ["remote_call_sector", 0];
        _operation set ["attackNotified", false];
    };
    if (_originSector == "") exitWith {
        _operation set ["outcome", "LOST"];
        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
        false
    };

    [_taskForceId, _taskForce, _operation, "RETURNING", _originSector] call BATTLESPACE_BATTLEGROUP_SET_DESTINATION;
    [format ["Battlegroup %1 retreating to %2", _taskForceId, _originSector]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_BATTLEGROUP_ON_DECISION_TICK = {
    params ["_taskForceId", "_taskForce"];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    if (isNil "_operation") exitWith { false };

    private _phase = _operation getOrDefault ["phase", "ENROUTE"];
    private _targetSector = _operation getOrDefault ["targetSector", ""];
    private _currentLocation = _taskForce param [1, []];
    private _retreatRatio = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RETREAT_STRENGTH_RATIO", 0.35];

    if (_phase in ["ENROUTE", "ASSAULTING"] && {
        ([_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO) < _retreatRatio
    }) then {
        if !([_taskForceId, _taskForce, _operation] call BATTLESPACE_BATTLEGROUP_BEGIN_RETREAT) then {
            true
        } else {
            false
        };
    } else {
        switch (_phase) do {
            case "ENROUTE": {
                if !(_targetSector in blufor_sectors) then {
                    [_targetSector, "OPFOR"] call BATTLESPACE_SECTOR_SET_OWNER;
                    _operation set ["phase", "REINFORCING"];
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
                    _phase = "REINFORCING";
                };

                if (_phase == "ENROUTE" && {_currentLocation distance2D (getMarkerPos _targetSector) <= 100}) then {
                    _operation set ["phase", "ASSAULTING"];
                    _operation set ["captureStartedAt", CBA_missionTime];
                    _operation set ["attackNotified", true];
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
                    [_targetSector, 1] remoteExec ["remote_call_sector", 0];
                    [format ["Battlegroup %1 began assaulting %2", _taskForceId, _targetSector]] call BATTLESPACE_STRATEGIC_LOG;
                };
                false
            };
            case "REINFORCING": {
                if (_targetSector in blufor_sectors) then {
                    _operation set ["phase", "ENROUTE"];
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
                    false
                } else {
                    if (_currentLocation distance2D (getMarkerPos _targetSector) <= 100) then {
                        _operation set ["outcome", "REINFORCED"];
                        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
                        true
                    } else {
                        false
                    }
                }
            };
            case "ASSAULTING": {
                if !(_targetSector in blufor_sectors) exitWith {
                    [_targetSector, "OPFOR"] call BATTLESPACE_SECTOR_SET_OWNER;
                    _operation set ["outcome", "CAPTURED"];
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
                    true
                };

                private _captureDelay = missionNamespace getVariable ["GRLIB_vulnerability_timer", 840];
                private _captureStartedAt = _operation getOrDefault ["captureStartedAt", CBA_missionTime];
                if (CBA_missionTime - _captureStartedAt < _captureDelay) exitWith { false };

                private _procRange = missionNamespace getVariable ["BATTLESPACE_UNIT_PROC_RANGE", 1175];
                private _friendlyPlayers = (allPlayers - entities "HeadlessClient_F") select {
                    alive _x
                    && {side group _x == GRLIB_side_friendly}
                    && {_x distance2D (getMarkerPos _targetSector) <= _procRange}
                };
                if (_friendlyPlayers isNotEqualTo []) exitWith { false };

                if ([_targetSector] call BATTLESPACE_CAPTURE_SECTOR_FOR_OPFOR) then {
                    _operation set ["outcome", "CAPTURED"];
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
                    true
                } else {
                    false
                }
            };
            case "RETURNING": {
                private _originSector = _operation getOrDefault ["originSector", ""];
                private _originState = BATTLESPACE_SECTOR_STATES get _originSector;
                if (isNil "_originState" || {(_originState getOrDefault ["owner", ""]) != "OPFOR"}) then {
                    _originSector = [_currentLocation] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
                    if (_originSector != "") then {
                        _operation set ["originSector", _originSector];
                        [_taskForceId, _taskForce, _operation, "RETURNING", _originSector] call BATTLESPACE_BATTLEGROUP_SET_DESTINATION;
                    };
                };
                if (_originSector == "") exitWith {
                    _operation set ["outcome", "LOST"];
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
                    true
                };

                if (_currentLocation distance2D (getMarkerPos _originSector) <= 100) then {
                    _operation set ["outcome", "RETURNED"];
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
                    true
                } else {
                    false
                }
            };
            default { false };
        }
    }
};

BATTLESPACE_BATTLEGROUP_DISPATCH = {
    params ["_originSector", "_targetSector"];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith { false };
    private _definition = [_originSector] call BATTLESPACE_BATTLEGROUP_BUILD_DEFINITION;
    if (count _definition == 0) exitWith { false };

    private _cost = _definition get "cost";
    private _debit = createHashMap;
    {
        _debit set [_x, -_y];
    } forEach _cost;
    if !([_originSector, _debit] call BATTLESPACE_RESOURCE_APPLY_STRICT) exitWith { false };

    private _taskForceId = [
        "Battlegroup",
        _definition get "composition",
        getMarkerPos _originSector,
        getMarkerPos _targetSector,
        getMarkerPos _originSector
    ] call BATTLESPACE_TASK_FORCES_INIT;

    if (_taskForceId == "") exitWith {
        [_originSector, _cost] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED;
        [format ["Battlegroup creation from %1 failed; resource debit refunded", _originSector], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
        false
    };

    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, createHashMapFromArray [
        ["kind", "BATTLEGROUP"],
        ["phase", "ENROUTE"],
        ["originSector", _originSector],
        ["targetSector", _targetSector],
        ["cost", _cost],
        ["vehicleManifest", _definition get "vehicleManifest"],
        ["initialStrength", _definition get "initialStrength"],
        ["captureStartedAt", -1],
        ["attackNotified", false],
        ["outcome", ""]
    ]];

    private _originState = BATTLESPACE_SECTOR_STATES get _originSector;
    _originState set [
        "nextBattlegroupAt",
        CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_BATTLEGROUP_COOLDOWN", 3600])
    ];
    BATTLESPACE_SECTOR_STATES set [_originSector, _originState];
    stats_hostile_battlegroups = (missionNamespace getVariable ["stats_hostile_battlegroups", 0]) + 1;
    [] call BATTLESPACE_LOGISTICS_SAVE;
    [format ["Dispatched battlegroup %1 from %2 toward %3 for %4", _taskForceId, _originSector, _targetSector, _cost]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_BATTLEGROUP_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    private _activeLimit = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_BATTLEGROUPS", 2];
    private _remainingSlots = _activeLimit - (["BATTLEGROUP"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS);
    private _perTick = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_BATTLEGROUPS_PER_TICK", 1];
    private _remaining = _remainingSlots min _perTick;
    if (_remaining <= 0) exitWith {};
    private _capturableBlufor = blufor_sectors arrayIntersect sectors_allSectors;
    if (_capturableBlufor isEqualTo []) exitWith {};

    {
        if (_remaining <= 0) exitWith {};
        private _originSector = _x;
        private _state = BATTLESPACE_SECTOR_STATES get _originSector;
        if (isNil "_state" || {(_state getOrDefault ["owner", ""]) != "OPFOR"}) then { continue };
        if (CBA_missionTime < (_state getOrDefault ["nextBattlegroupAt", 0])) then { continue };

        private _network = NETWORKED_SECTORS get _originSector;
        if (isNil "_network") then { continue };
        private _targets = (_network getOrDefault ["Links", []]) select {
            _x in _capturableBlufor
            && {!(["BATTLEGROUP", _x] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET)}
        };
        if (_targets isEqualTo []) then {
            private _reachableTarget = [_originSector, _capturableBlufor] call NETWORKED_SECTORS_traverseGraphAndFindFirstBluforSector;
            if (
                !isNil "_reachableTarget"
                && {_reachableTarget in _capturableBlufor}
                && {!(["BATTLEGROUP", _reachableTarget] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET)}
            ) then {
                _targets pushBack _reachableTarget;
            };
        };
        if (_targets isEqualTo []) then { continue };

        private _targetSector = selectRandom _targets;
        if ([_originSector, _targetSector] call BATTLESPACE_BATTLEGROUP_DISPATCH) then {
            _remaining = _remaining - 1;
        };
    } forEach sectors_military;
};
