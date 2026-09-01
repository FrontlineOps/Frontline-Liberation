KPLIB_INTEL_COVERAGE = createHashMap;
KPLIB_INTEL_OBSERVATIONS = createHashMap;
KPLIB_INTEL_ELIGIBLE_REGIONS = [];
KPLIB_INTEL_REGION_OWNERSHIP_KEY = "";
KPLIB_INTEL_LAST_FINGERPRINT = "";
KPLIB_INTEL_REVISION = 0;

KPLIB_INTEL_SERVER_GET_CALLER = {
    if (!isServer || {!isRemoteExecuted}) exitWith {objNull};
    private _ownerId = remoteExecutedOwner;
    (allPlayers select {isPlayer _x && {owner _x == _ownerId}}) param [0, objNull]
};

KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL = {
    params ["_player"];
    if (isNull _player) exitWith {false};

    private _distance = missionNamespace getVariable ["KPLIB_intelligence_terminal_distance", 75];
    private _nearTerminal = (_player distance2D (getMarkerPos GRLIB_respawn_marker)) <= _distance;
    if (!_nearTerminal) then {
        {
            if ((_player distance2D _x) <= _distance) exitWith {_nearTerminal = true};
        } forEach (missionNamespace getVariable ["GRLIB_all_fobs", []]);
    };
    _nearTerminal
};

KPLIB_INTEL_SERVER_RANDOM_YIELD = {
    params ["_range"];
    private _minimum = 0 max floor (_range param [0, 0]);
    private _maximum = _minimum max floor (_range param [1, _minimum]);
    _minimum + floor random ((_maximum - _minimum) + 1)
};

KPLIB_INTEL_SERVER_GET_REGION_SECTORS = {
    params ["_region"];
    private _maximumHops = 0 max floor (missionNamespace getVariable ["KPLIB_intelligence_region_hops", 1]);
    private _queue = [[_region, 0]];
    private _seen = createHashMap;

    while {_queue isNotEqualTo []} do {
        private _entry = _queue deleteAt 0;
        _entry params ["_sector", "_depth"];
        if (_seen getOrDefault [_sector, false]) then {continue};
        _seen set [_sector, true];
        if (_depth >= _maximumHops) then {continue};

        private _sectorData = NETWORKED_SECTORS get _sector;
        if (isNil "_sectorData") then {continue};
        {
            if !(_seen getOrDefault [_x, false]) then {
                _queue pushBack [_x, _depth + 1];
            };
        } forEach (_sectorData getOrDefault ["Links", []]);
    };

    keys _seen
};

KPLIB_INTEL_SERVER_REBUILD_REGIONS = {
    private _ownership = +(missionNamespace getVariable ["blufor_sectors", []]);
    _ownership sort true;
    private _ownershipKey = str _ownership;
    if (_ownershipKey == KPLIB_INTEL_REGION_OWNERSHIP_KEY && {KPLIB_INTEL_ELIGIBLE_REGIONS isNotEqualTo []}) exitWith {false};

    private _maximumDepth = 0 max floor (missionNamespace getVariable ["KPLIB_intelligence_max_frontline_depth", 2]);
    private _regions = [];
    {
        private _sector = _x;
        if (_sector == "startbase_marker" || {_sector in _ownership}) then {continue};
        private _depth = [_sector, _ownership + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
        if (_depth < 0 || {_depth > _maximumDepth}) then {continue};
        private _label = markerText _sector;
        if (_label == "") then {_label = _sector};
        _regions pushBack [_sector, _label, _depth];
    } forEach (keys NETWORKED_SECTORS);

    KPLIB_INTEL_ELIGIBLE_REGIONS = [_regions, [], {_x # 2}, "ASCEND"] call BIS_fnc_sortBy;
    KPLIB_INTEL_REGION_OWNERSHIP_KEY = _ownershipKey;
    true
};

KPLIB_INTEL_SERVER_IS_REGION_ELIGIBLE = {
    params ["_region"];
    (KPLIB_INTEL_ELIGIBLE_REGIONS findIf {(_x # 0) == _region}) != -1
};

KPLIB_INTEL_SERVER_NEAREST_SECTOR = {
    params ["_position", ["_fallback", ""]];
    if !(_position isEqualType [] && {count _position >= 2}) exitWith {_fallback};
    private _sector = [GRLIB_sector_size * 1.5, _position] call KPLIB_fnc_getNearestSector;
    if (_sector == "") then {_fallback} else {_sector}
};

KPLIB_INTEL_SERVER_TRIM_ROUTE = {
    params ["_route", "_taskForce"];
    if !(_route isEqualType [] && {_route isNotEqualTo []}) exitWith {[]};
    private _state = _taskForce param [5, ["IDLE", 0, 0]];
    private _routeIndex = if (_state isEqualType []) then {0 max floor (_state param [1, 0])} else {0};
    if (_routeIndex >= count _route) exitWith {[]};
    _route select [_routeIndex]
};

KPLIB_INTEL_SERVER_COLLECT_RAW_REPORTS = {
    private _rawReports = [];
    private _allowedKinds = missionNamespace getVariable ["KPLIB_intelligence_operation_kinds", []];

    {
        private _id = if (_x isEqualType "") then {_x} else {str _x};
        private _operation = _y;
        private _kind = toUpper (_operation getOrDefault ["kind", ""]);
        if !(_kind in _allowedKinds) then {continue};

        private _taskForce = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_taskForce") then {continue};
        private _position = _taskForce param [1, []];
        private _destinationPosition = _taskForce param [2, []];
        private _fallbackSector = _operation getOrDefault [
            "pressureSector",
            _operation getOrDefault [
                "targetSector",
                _operation getOrDefault ["fundingSector", _operation getOrDefault ["originSector", ""]]
            ]
        ];
        private _sector = [_position, _fallbackSector] call KPLIB_INTEL_SERVER_NEAREST_SECTOR;
        private _destinationSector = _operation getOrDefault ["targetSector", _operation getOrDefault ["pressureSector", ""]];
        if (_destinationSector != "") then {_destinationPosition = getMarkerPos _destinationSector};

        private _composition = _taskForce param [3, createHashMap];
        private _manpower = 0;
        private _vehicles = 0;
        if (typeName _composition == "HASHMAP") then {
            _manpower = floor (_composition getOrDefault ["manpower", 0]);
            private _vehicleData = _composition getOrDefault ["vehicles", []];
            _vehicles = switch (typeName _vehicleData) do {
                case "ARRAY": {count _vehicleData};
                case "SCALAR": {floor _vehicleData};
                default {0};
            };
        };
        if (_vehicles == 0) then {
            _vehicles = count (_operation getOrDefault ["vehicleManifest", []]);
        };

        private _route = [BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_x, []], _taskForce] call KPLIB_INTEL_SERVER_TRIM_ROUTE;
        _rawReports pushBack [
            _id,
            _kind,
            toUpper (_operation getOrDefault ["phase", "ACTIVE"]),
            _position,
            _sector,
            _destinationSector,
            _destinationPosition,
            _manpower,
            _vehicles,
            _route
        ];
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;

    {
        private _group = _x;
        if (isNull _group) then {continue};
        private _aliveVehicles = [];
        {
            private _vehicle = vehicle _x;
            if (_vehicle isNotEqualTo _x && {alive _vehicle}) then {_aliveVehicles pushBackUnique _vehicle};
        } forEach units _group;
        private _aliveCrew = {alive _x} count units _group;
        if (_aliveVehicles isEqualTo [] && {_aliveCrew == 0}) then {continue};
        private _sector = _group getVariable ["BSAFundingSector", ""];
        private _position = if (_aliveVehicles isNotEqualTo []) then {getPosATL (_aliveVehicles # 0)} else {getPosATL leader _group};
        private _groupIdentity = groupId _group;
        if (_groupIdentity == "") then {_groupIdentity = str _forEachIndex};
        private _stateValue = _group getVariable ["BSAState", "READY"];
        private _phase = switch (typeName _stateValue) do {
            case "ARRAY": {toUpper (_stateValue param [0, "READY"])};
            case "STRING": {toUpper _stateValue};
            default {"READY"};
        };
        _rawReports pushBack [
            format ["ARTILLERY_%1_%2", _sector, _groupIdentity],
            "ARTILLERY",
            _phase,
            _position,
            _sector,
            "",
            [],
            _aliveCrew,
            count _aliveVehicles,
            []
        ];
    } forEach (missionNamespace getVariable ["BATTLESPACE_ARTILLERY_SECTIONS", []]);

    {
        private _units = (_x getOrDefault ["Units", []]) select {!isNull _x && {alive _x}};
        if (_units isEqualTo []) then {continue};
        private _sector = _x getOrDefault ["Sector", ""];
        private _aliveCrew = 0;
        {_aliveCrew = _aliveCrew + ({alive _x} count crew _x)} forEach _units;
        _rawReports pushBack [
            format ["SAM_%1", _x getOrDefault ["Id", _forEachIndex]],
            "SAM",
            "ACTIVE",
            getPosATL (_units # 0),
            _sector,
            "",
            [],
            _aliveCrew,
            count _units,
            []
        ];
    } forEach (missionNamespace getVariable ["BATTLESPACE_SAM_EXISTING_SITES", []]);

    _rawReports
};

KPLIB_INTEL_SERVER_SAMPLE_ROUTE = {
    params ["_route"];
    private _limit = 2 max floor (missionNamespace getVariable ["KPLIB_intelligence_route_point_limit", 12]);
    if !(_route isEqualType [] && {_route isNotEqualTo []}) exitWith {[]};
    if ((count _route) <= _limit) exitWith {+_route};

    private _sample = [];
    private _lastIndex = (count _route) - 1;
    for "_index" from 0 to (_limit - 1) do {
        _sample pushBack (_route # round ((_index / (_limit - 1)) * _lastIndex));
    };
    _sample
};

KPLIB_INTEL_SERVER_BUILD_OBSERVATION = {
    params ["_raw", "_tier", "_region"];
    _raw params ["_id", "_kind", "_phase", "_position", "_sector", "_destinationSector", "_destinationPosition", "_manpower", "_vehicles", "_route"];

    private _uncertaintyValues = missionNamespace getVariable ["KPLIB_intelligence_uncertainty_radii", [1200, 600, 200]];
    private _uncertainty = _uncertaintyValues param [_tier - 1, 1200];
    private _angle = random 360;
    private _offset = sqrt (random 1) * _uncertainty;
    private _observedPosition = [
        (_position param [0, 0]) + (sin _angle * _offset),
        (_position param [1, 0]) + (cos _angle * _offset),
        0
    ];

    private _displayKind = _kind;
    if (_tier == 1) then {
        _displayKind = switch true do {
            case (_kind find "AIR" >= 0): {"AIR ACTIVITY"};
            case (_kind == "CONVOY"): {"LOGISTICS ACTIVITY"};
            case (_kind in ["ARTILLERY", "SAM", "FORTIFICATION"]): {"FIXED DEFENSE"};
            default {"GROUND ACTIVITY"};
        };
    };

    private _strength = "UNKNOWN";
    if (_tier == 2) then {
        private _weight = _manpower + (_vehicles * (missionNamespace getVariable ["KPLIB_intelligence_vehicle_strength_weight", 4]));
        private _bands = missionNamespace getVariable ["KPLIB_intelligence_strength_bands", [12, 30]];
        _strength = if (_weight >= (_bands param [1, 30])) then {"HEAVY"} else {if (_weight >= (_bands param [0, 12])) then {"MODERATE"} else {"LIGHT"}};
    };
    if (_tier >= 3) then {
        _strength = format ["%1 personnel / %2 vehicles", _manpower, _vehicles];
    };

    private _sampledRoute = if (_tier >= 3) then {[_route] call KPLIB_INTEL_SERVER_SAMPLE_ROUTE} else {[]};
    if (_sampledRoute isNotEqualTo []) then {
        private _deltaX = (_observedPosition # 0) - (_position param [0, 0]);
        private _deltaY = (_observedPosition # 1) - (_position param [1, 0]);
        _sampledRoute = _sampledRoute apply {[
            (_x param [0, 0]) + _deltaX,
            (_x param [1, 0]) + _deltaY,
            0
        ]};
    };

    private _displayPhase = [_phase, "DETECTED"] select (_tier == 1);
    [
        _id,
        _displayKind,
        _displayPhase,
        _region,
        _observedPosition,
        _uncertainty,
        CBA_missionTime,
        [_destinationSector, ""] select (_tier < 2),
        [_destinationPosition, []] select (_tier < 2),
        _strength,
        _sampledRoute,
        _tier
    ]
};

KPLIB_INTEL_SERVER_BUILD_PAYLOAD = {
    private _coverages = [];
    {
        _coverages pushBack [_x, _y get "tier", _y get "expiresAt"];
    } forEach KPLIB_INTEL_COVERAGE;
    _coverages = [_coverages, [], {_x # 0}, "ASCEND"] call BIS_fnc_sortBy;

    private _reports = [];
    {_reports pushBack +(_y get "report")} forEach KPLIB_INTEL_OBSERVATIONS;
    _reports = [_reports, [], {_x # 0}, "ASCEND"] call BIS_fnc_sortBy;

    [
        KPLIB_INTEL_REVISION,
        missionNamespace getVariable ["resources_intel", 0],
        _coverages,
        _reports,
        +KPLIB_INTEL_ELIGIBLE_REGIONS
    ]
};

KPLIB_INTEL_SERVER_SEND_PAYLOAD = {
    params [["_targets", [], [[], objNull]]];
    if (_targets isEqualType [] && {_targets isEqualTo []}) exitWith {};
    [call KPLIB_INTEL_SERVER_BUILD_PAYLOAD] remoteExecCall ["KPLIB_INTEL_CLIENT_RECEIVE_SNAPSHOT", _targets];
};

KPLIB_INTEL_SERVER_RECONCILE = {
    params [["_force", false, [false]]];
    if (!isServer || {!(missionNamespace getVariable ["KPLIB_intelligence_enabled", true])}) exitWith {};
    if (isNil "BATTLESPACE_STRATEGIC_OPERATIONS" || {isNil "BATTLESPACE_TASK_FORCES"}) exitWith {};

    private _changed = call KPLIB_INTEL_SERVER_REBUILD_REGIONS;
    private _now = CBA_missionTime;
    {
        private _region = _x;
        private _coverage = KPLIB_INTEL_COVERAGE get _region;
        if ((_coverage getOrDefault ["expiresAt", 0]) <= _now || {!([_region] call KPLIB_INTEL_SERVER_IS_REGION_ELIGIBLE)}) then {
            KPLIB_INTEL_COVERAGE deleteAt _region;
            _changed = true;
        };
    } forEach (keys KPLIB_INTEL_COVERAGE);

    if (count KPLIB_INTEL_COVERAGE == 0) exitWith {
        if (count KPLIB_INTEL_OBSERVATIONS > 0) then {
            KPLIB_INTEL_OBSERVATIONS = createHashMap;
            _changed = true;
        };
        private _payload = call KPLIB_INTEL_SERVER_BUILD_PAYLOAD;
        private _fingerprint = str (_payload select [1]);
        if (_force || {_changed} || {_fingerprint != KPLIB_INTEL_LAST_FINGERPRINT}) then {
            KPLIB_INTEL_REVISION = KPLIB_INTEL_REVISION + 1;
            KPLIB_INTEL_LAST_FINGERPRINT = _fingerprint;
            private _targets = allPlayers select {isPlayer _x && {side group _x == GRLIB_side_friendly}};
            [_targets] call KPLIB_INTEL_SERVER_SEND_PAYLOAD;
        };
    };

    private _rawReports = call KPLIB_INTEL_SERVER_COLLECT_RAW_REPORTS;
    private _candidates = createHashMap;
    private _regionCounts = createHashMap;
    private _totalLimit = 1 max floor (missionNamespace getVariable ["KPLIB_intelligence_max_reports", 40]);
    private _regionLimit = 1 max floor (missionNamespace getVariable ["KPLIB_intelligence_max_reports_per_region", 10]);

    {
        private _region = _x;
        private _coverage = _y;
        private _tier = _coverage get "tier";
        private _coveredSectors = _coverage get "sectors";
        {
            private _raw = _x;
            private _sector = _raw # 4;
            private _inside = _sector in _coveredSectors;
            if (!_inside && {(_raw # 3) isEqualType []} && {count (_raw # 3) >= 2}) then {
                {
                    if (((getMarkerPos _x) distance2D (_raw # 3)) <= GRLIB_sector_size) exitWith {_inside = true};
                } forEach _coveredSectors;
            };
            if (!_inside) then {continue};

            private _id = _raw # 0;
            private _existingCandidate = _candidates get _id;
            if (isNil "_existingCandidate") then {
                if (count _candidates >= _totalLimit) then {continue};
                private _regionCount = _regionCounts getOrDefault [_region, 0];
                if (_regionCount >= _regionLimit) then {continue};
                _regionCounts set [_region, _regionCount + 1];
                _candidates set [_id, [_raw, _tier, _region]];
            } else {
                if (_tier > (_existingCandidate # 1)) then {
                    _candidates set [_id, [_raw, _tier, _region]];
                };
            };
        } forEach _rawReports;
    } forEach KPLIB_INTEL_COVERAGE;

    {
        private _id = _x;
        _y params ["_raw", "_tier", "_region"];
        private _observation = KPLIB_INTEL_OBSERVATIONS get _id;
        private _refreshValues = missionNamespace getVariable ["KPLIB_intelligence_refresh_intervals", [180, 90, 30]];
        private _refreshInterval = _refreshValues param [_tier - 1, 180];
        private _mustRefresh = isNil "_observation";
        if (!_mustRefresh) then {
            _mustRefresh = (_observation getOrDefault ["tier", 0]) != _tier
                || {(_observation getOrDefault ["region", ""]) != _region}
                || {_now >= (_observation getOrDefault ["refreshAt", 0])};
        };
        if (_mustRefresh) then {
            KPLIB_INTEL_OBSERVATIONS set [_id, createHashMapFromArray [
                ["tier", _tier],
                ["region", _region],
                ["refreshAt", _now + _refreshInterval],
                ["report", [_raw, _tier, _region] call KPLIB_INTEL_SERVER_BUILD_OBSERVATION]
            ]];
            _changed = true;
        };
    } forEach _candidates;

    {
        if (isNil {_candidates get _x}) then {
            KPLIB_INTEL_OBSERVATIONS deleteAt _x;
            _changed = true;
        };
    } forEach (keys KPLIB_INTEL_OBSERVATIONS);

    private _payload = call KPLIB_INTEL_SERVER_BUILD_PAYLOAD;
    private _fingerprint = str (_payload select [1]);
    if (_force || {_changed} || {_fingerprint != KPLIB_INTEL_LAST_FINGERPRINT}) then {
        KPLIB_INTEL_REVISION = KPLIB_INTEL_REVISION + 1;
        KPLIB_INTEL_LAST_FINGERPRINT = _fingerprint;
        private _targets = allPlayers select {isPlayer _x && {side group _x == GRLIB_side_friendly}};
        [_targets] call KPLIB_INTEL_SERVER_SEND_PAYLOAD;
    };
};

KPLIB_INTEL_SERVER_ADD_RESERVE = {
    params ["_amount", "_source"];
    if (!isServer || {_amount <= 0}) exitWith {};
    resources_intel = (missionNamespace getVariable ["resources_intel", 0]) + floor _amount;
    publicVariable "resources_intel";
    private _targets = allPlayers select {isPlayer _x && {side group _x == GRLIB_side_friendly}};
    ["EARNED", floor _amount, _source] remoteExecCall ["KPLIB_INTEL_CLIENT_NOTIFY", _targets];
    [true] call KPLIB_INTEL_SERVER_RECONCILE;
};

KPLIB_INTEL_SERVER_REJECT = {
    params ["_player", "_message"];
    if (!isNull _player) then {
        ["REJECTED", 0, _message] remoteExecCall ["KPLIB_INTEL_CLIENT_NOTIFY", _player];
    };
};

KPLIB_INTEL_SERVER_COMMIT_PRISONER = {
    params [
        ["_unit", objNull, [objNull]],
        ["_caller", objNull, [objNull]],
        ["_source", "unknown", [""]]
    ];

    private _unitId = if (isNull _unit) then {"null"} else {netId _unit};
    if !(missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=disabled)", _unitId, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };
    if (isNull _caller || {!alive _caller} || {side group _caller != GRLIB_side_friendly}) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=invalid escort)", _unitId, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };
    if (isNull _unit || {!alive _unit} || {!(_unit isKindOf "Man")} || {isPlayer _unit}) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=invalid prisoner)", _unitId, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };
    if !(_unit getVariable ["KPLIB_intelligencePrisoner", false]) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=missing prisoner flag)", _unitId, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };
    if (_unit getVariable ["KPLIB_intelligenceDelivered", false]) exitWith {true};

    private _deliveryDistance = missionNamespace getVariable ["KPLIB_intelligence_delivery_distance", 40];
    if ((_caller distance _unit) > _deliveryDistance) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=escort beyond %3m)", _unitId, _source, _deliveryDistance], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };
    if !([_caller] call KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=escort outside terminal)", _unitId, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };

    _unit setVariable ["KPLIB_intelligenceDelivered", true, true];
    private _range = if ((typeOf _unit) in militia_squad) then {
        missionNamespace getVariable ["KPLIB_intelligence_prisoner_yield_militia", [3, 6]]
    } else {
        missionNamespace getVariable ["KPLIB_intelligence_prisoner_yield_opfor", [6, 12]]
    };
    private _amount = [_range] call KPLIB_INTEL_SERVER_RANDOM_YIELD;
    stats_prisoners_captured = (missionNamespace getVariable ["stats_prisoners_captured", 0]) + 1;
    [_amount, "prisoner"] call KPLIB_INTEL_SERVER_ADD_RESERVE;
    [format ["Prisoner intelligence delivery committed (unit=%1, source=%2, intel=%3)", _unitId, _source, _amount], "INTELLIGENCE"] call KPLIB_fnc_log;
    [format ["Prisoner intelligence cleanup (unit=%1, class=%2)", _unitId, typeOf _unit], "INTELLIGENCE"] call KPLIB_fnc_log;
    deleteVehicle _unit;
    true
};

KPLIB_INTEL_SERVER_REGISTER_PRISONER_ESCORT = {
    params [["_unit", objNull, [objNull]]];

    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    private _unitId = if (isNull _unit) then {"null"} else {netId _unit};
    if (isNull _caller || {!alive _caller} || {vehicle _caller isNotEqualTo _caller} || {side group _caller != GRLIB_side_friendly}) exitWith {
        [format ["Prisoner intelligence escort registration rejected (unit=%1, reason=invalid player)", _unitId], "INTELLIGENCE"] call KPLIB_fnc_log;
    };
    if (isNull _unit || {!alive _unit} || {!(_unit isKindOf "Man")} || {isPlayer _unit} || {!(_unit getVariable ["KPLIB_intelligencePrisoner", false])}) exitWith {
        [format ["Prisoner intelligence escort registration rejected (unit=%1, reason=invalid prisoner)", _unitId], "INTELLIGENCE"] call KPLIB_fnc_log;
    };
    if (_unit getVariable ["KPLIB_intelligenceDelivered", false]) exitWith {};

    private _interactionDistance = missionNamespace getVariable ["KPLIB_intelligence_interaction_distance", 4];
    if ((_caller distance _unit) > _interactionDistance) exitWith {
        [format ["Prisoner intelligence escort registration rejected (unit=%1, reason=player beyond %2m)", _unitId, _interactionDistance], "INTELLIGENCE"] call KPLIB_fnc_log;
    };

    private _previousEscort = _unit getVariable ["KPLIB_intelligenceEscort", objNull];
    _unit setVariable ["KPLIB_intelligenceEscort", _caller];
    if (_previousEscort isNotEqualTo _caller) then {
        [format ["Prisoner intelligence escort registered (unit=%1, class=%2, playerOwner=%3)", _unitId, typeOf _unit, owner _caller], "INTELLIGENCE"] call KPLIB_fnc_log;
    };

    if ([_caller] call KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL) then {
        [_unit, _caller, "terminal escort action"] call KPLIB_INTEL_SERVER_COMMIT_PRISONER;
    };
};

KPLIB_INTEL_SERVER_COMPLETE_REGISTERED_PRISONER = {
    params [["_unit", objNull, [objNull]]];
    if (!isRemoteExecuted || {isNull _unit} || {remoteExecutedOwner != owner _unit}) exitWith {
        private _unitId = if (isNull _unit) then {"null"} else {netId _unit};
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=registered escort, reason=invalid unit locality)", _unitId], "INTELLIGENCE"] call KPLIB_fnc_log;
    };
    private _caller = if (isNull _unit) then {objNull} else {_unit getVariable ["KPLIB_intelligenceEscort", objNull]};
    [_unit, _caller, "registered escort"] call KPLIB_INTEL_SERVER_COMMIT_PRISONER;
};

KPLIB_INTEL_SERVER_ACTIVATE_COVERAGE = {
    params [["_region", "", [""]], ["_tier", 0, [0]]];
    if !(missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) exitWith {};
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller || {!alive _caller} || {vehicle _caller isNotEqualTo _caller} || {side group _caller != GRLIB_side_friendly}) exitWith {};
    if !([_caller] call KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL) exitWith {[_caller, "Intelligence analysis is only available at the start base or a FOB."] call KPLIB_INTEL_SERVER_REJECT};
    call KPLIB_INTEL_SERVER_REBUILD_REGIONS;
    if !([_region] call KPLIB_INTEL_SERVER_IS_REGION_ELIGIBLE) exitWith {[_caller, "That region is no longer eligible for coverage."] call KPLIB_INTEL_SERVER_REJECT};

    private _costs = missionNamespace getVariable ["KPLIB_intelligence_tier_costs", [10, 25, 45]];
    if (_tier < 1 || {_tier > count _costs}) exitWith {[_caller, "Invalid intelligence tier."] call KPLIB_INTEL_SERVER_REJECT};
    private _activeCoverage = KPLIB_INTEL_COVERAGE get _region;
    if (!isNil "_activeCoverage" && {_tier < (_activeCoverage getOrDefault ["tier", 1])}) exitWith {[_caller, "Select the active tier or a higher tier; live coverage cannot be downgraded."] call KPLIB_INTEL_SERVER_REJECT};
    private _cost = _costs # (_tier - 1);
    if ((missionNamespace getVariable ["resources_intel", 0]) < _cost) exitWith {[_caller, "The shared reserve does not contain enough intelligence."] call KPLIB_INTEL_SERVER_REJECT};

    resources_intel = resources_intel - _cost;
    publicVariable "resources_intel";
    KPLIB_INTEL_COVERAGE set [_region, createHashMapFromArray [
        ["tier", _tier],
        ["expiresAt", CBA_missionTime + (missionNamespace getVariable ["KPLIB_intelligence_coverage_duration", 1800])],
        ["sectors", [_region] call KPLIB_INTEL_SERVER_GET_REGION_SECTORS]
    ]];
    private _label = markerText _region;
    if (_label == "") then {_label = _region};
    private _targets = allPlayers select {isPlayer _x && {side group _x == GRLIB_side_friendly}};
    ["ACTIVATED", _tier, _label] remoteExecCall ["KPLIB_INTEL_CLIENT_NOTIFY", _targets];
    [true] call KPLIB_INTEL_SERVER_RECONCILE;
};

KPLIB_INTEL_SERVER_COLLECT_DOCUMENT = {
    params [["_object", objNull, [objNull]]];
    if !(missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) exitWith {};
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller || {isNull _object} || {!alive _caller} || {vehicle _caller isNotEqualTo _caller} || {side group _caller != GRLIB_side_friendly}) exitWith {};
    private _distance = missionNamespace getVariable ["KPLIB_intelligence_interaction_distance", 4];
    if ((_caller distance _object) > _distance || {!((typeOf _object) in KPLIB_intelObjectClasses)}) exitWith {};
    if (_object getVariable ["KPLIB_intelligenceCollected", false]) exitWith {};
    _object setVariable ["KPLIB_intelligenceCollected", true, true];
    deleteVehicle _object;
    [[missionNamespace getVariable ["KPLIB_intelligence_document_yield", [8, 15]]] call KPLIB_INTEL_SERVER_RANDOM_YIELD, "documents"] call KPLIB_INTEL_SERVER_ADD_RESERVE;
};

KPLIB_INTEL_SERVER_DELIVER_PRISONER = {
    params [["_unit", objNull, [objNull]]];
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    [_unit, _caller, "player request"] call KPLIB_INTEL_SERVER_COMMIT_PRISONER;
};

KPLIB_INTEL_SERVER_DELIVER_INFORMANT = {
    params [["_unit", objNull, [objNull]]];
    if !(missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) exitWith {};
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller || {!alive _caller} || {isNull _unit} || {!alive _unit} || {side group _caller != GRLIB_side_friendly}) exitWith {};
    if !(_unit getVariable ["KPLIB_intelligenceInformant", false]) exitWith {};
    if (_unit getVariable ["KPLIB_intelligenceDelivered", false]) exitWith {};
    if ((_caller distance _unit) > (missionNamespace getVariable ["KPLIB_intelligence_delivery_distance", 40]) || {!([_caller] call KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL)}) exitWith {};
    _unit setVariable ["KPLIB_intelligenceDelivered", true, true];
    [2] spawn F_cr_changeCR;
    [1] remoteExec ["civinfo_notifications"];
    [missionNamespace getVariable ["KP_liberation_civinfo_intel", 15], "informant"] call KPLIB_INTEL_SERVER_ADD_RESERVE;
};

KPLIB_INTEL_SERVER_REQUEST_SYNC = {
    if !(missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) exitWith {};
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller || {side group _caller != GRLIB_side_friendly}) exitWith {};
    [false] call KPLIB_INTEL_SERVER_RECONCILE;
    [_caller] call KPLIB_INTEL_SERVER_SEND_PAYLOAD;
};

KPLIB_INTEL_SERVER_INIT = {
    if (missionNamespace getVariable ["KPLIB_INTEL_SERVER_INITIALIZED", false]) exitWith {};
    if (isNil "resources_intel" || {isNil "NETWORKED_SECTORS"} || {count NETWORKED_SECTORS == 0} || {isNil "BATTLESPACE_STRATEGIC_OPERATIONS"}) exitWith {
        [KPLIB_INTEL_SERVER_INIT, [], 2] call CBA_fnc_waitAndExecute;
    };

    KPLIB_INTEL_SERVER_INITIALIZED = true;
    [true] call KPLIB_INTEL_SERVER_RECONCILE;
    KPLIB_INTEL_SERVER_PFH = [{[false] call KPLIB_INTEL_SERVER_RECONCILE}, missionNamespace getVariable ["KPLIB_intelligence_reconcile_interval", 15]] call CBA_fnc_addPerFrameHandler;
};
