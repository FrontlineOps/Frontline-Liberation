/* Opportunity-led offensives. Battlegroup remains the stable operation/model
   save identity; this module owns planning/funding and the model owns movement.
   Observations and all authoritative writes stay on the server. */
BATTLESPACE_OFFENSIVE_CONTACTS = createHashMap;
BATTLESPACE_OFFENSIVE_OBSERVER_CURSOR = 0;

BATTLESPACE_OFFENSIVE_SAMPLE_CONTACTS = {
    if (!isServer) exitWith {};
    private _now = CBA_missionTime;
    {if (_now - (_y select 1) > BATTLESPACE_OFFENSIVE_CONTACT_MAX_AGE) then {BATTLESPACE_OFFENSIVE_CONTACTS deleteAt _x}} forEach BATTLESPACE_OFFENSIVE_CONTACTS;
    private _observers = [];
    {{private _leader = leader _x; if (local _x && {side _x == GRLIB_side_enemy} && {!isNull _leader} && {alive _leader}) then {_observers pushBackUnique _leader}} forEach (_y param [4, []])} forEach BATTLESPACE_TASK_FORCES;
    if (_observers isEqualTo []) exitWith {};
    for "_i" from 1 to (BATTLESPACE_OFFENSIVE_OBSERVERS_PER_TICK min count _observers) do {
        BATTLESPACE_OFFENSIVE_OBSERVER_CURSOR = BATTLESPACE_OFFENSIVE_OBSERVER_CURSOR mod count _observers;
        private _observer = _observers select BATTLESPACE_OFFENSIVE_OBSERVER_CURSOR;
        BATTLESPACE_OFFENSIVE_OBSERVER_CURSOR = BATTLESPACE_OFFENSIVE_OBSERVER_CURSOR + 1;
        // Perceived position and age, never a tracked object's live coordinates.
        private _reports = _observer targetsQuery [objNull, GRLIB_side_friendly, "", [], 45];
        {
            _x params ["_accuracy", "_target", "_side", "_class", "_position", "_age"];
            if (_side != GRLIB_side_friendly || {_class isKindOf "Air"} || {isNull _target} || {_accuracy <= 0} || {count _position < 2}) then {continue};
            private _key = str _target;
            private _seenAt = _now - (0 max _age);
            private _previous = BATTLESPACE_OFFENSIVE_CONTACTS getOrDefault [_key, [[], -1e9, 0, []]];
            if (_seenAt <= (_previous select 1) + 1) then {continue};
            private _weight = if (_class isKindOf "Tank") then {8} else {if (_class isKindOf "Car") then {3} else {1}};
            BATTLESPACE_OFFENSIVE_CONTACTS set [_key, [[_position select 0, _position select 1, 0], _seenAt, _weight, _previous select 0]];
        } forEach (_reports select [0, 12]);
    };
    if (count BATTLESPACE_OFFENSIVE_CONTACTS > 256) then {
        private _oldest = [];
        {_oldest pushBack [_y select 1, _x]} forEach BATTLESPACE_OFFENSIVE_CONTACTS;
        _oldest sort true;
        {BATTLESPACE_OFFENSIVE_CONTACTS deleteAt (_x select 1)} forEach (_oldest select [0, count _oldest - 256]);
    };
};

BATTLESPACE_OFFENSIVE_GET_CONTACT = {
    params ["_position", "_forward", ["_radius", BATTLESPACE_OFFENSIVE_CONTACT_RADIUS]];
    private _weight = 0;
    private _sum = [0, 0, 0];
    private _latest = -1e9;
    private _receding = false;
    {
        _y params ["_known", "_seenAt", "_strength", "_previous"];
        if (CBA_missionTime - _seenAt > BATTLESPACE_OFFENSIVE_CONTACT_MAX_AGE || {_known distance2D _position > _radius}) then {continue};
        _sum = _sum vectorAdd (_known vectorMultiply _strength);
        _weight = _weight + _strength;
        _latest = _latest max _seenAt;
        if (_previous isNotEqualTo [] && {((_known vectorDiff _previous) vectorDotProduct _forward) > 100}) then {_receding = true};
    } forEach BATTLESPACE_OFFENSIVE_CONTACTS;
    [if (_weight > 0) then {_sum vectorMultiply (1 / _weight)} else {[]}, _weight, _latest, _receding]
};

BATTLESPACE_OFFENSIVE_PICK_POSITION = {
    params ["_anchor", "_target", "_current", ["_mode", "STAGE"], ["_flank", 1]];
    private _from = getMarkerPos _anchor;
    private _to = getMarkerPos _target;
    private _length = _from distance2D _to;
    private _standoff = BATTLESPACE_OFFENSIVE_TARGET_STANDOFF max (GRLIB_capture_size + 100);
    if (_length < _standoff + 250) exitWith {[]};
    private _direction = _from getDir _to;
    private _forward = _from vectorFromTo _to;
    private _along = ((_current vectorDiff _from) vectorDotProduct _forward) max 100;
    private _center = switch (_mode) do {
        case "STAGE": {_from getPos [(_length * 0.30) max 150 min (_length - _standoff), _direction]};
        case "SHIFT": {(_current getPos [100, _direction + 180]) getPos [BATTLESPACE_OFFENSIVE_LATERAL_DISTANCE, _direction + 90 * _flank]};
        default {_from getPos [(_along + BATTLESPACE_OFFENSIVE_STEP_DISTANCE) min (_length - _standoff), _direction]};
    };
    // Six coarse terrain candidates per maneuver; never scan the whole map.
    private _places = selectBestPlaces [_center, 160, "(2*forest + trees + houses + hills) * (1-sea)", 40, 6];
    if (_places isEqualTo []) then {_places = [[_center, 0]]};
    private _candidates = [];
    {
        private _point = +(_x select 0);
        _point set [2, 0];
        private _projection = (_point vectorDiff _from) vectorDotProduct _forward;
        private _axisPoint = _from vectorAdd (_forward vectorMultiply _projection);
        if ((_point select 0) < 0 || {(_point select 1) < 0} || {(_point select 0) > worldSize} || {(_point select 1) > worldSize}) then {continue};
        if (surfaceIsWater _point || {(surfaceNormal _point select 2) < 0.85}) then {continue};
        if (_projection < 50 || {_projection > _length - _standoff} || {_point distance2D _axisPoint > 700}) then {continue};
        if (_mode != "STAGE" && {_point distance2D _current < 100}) then {continue};
        _candidates pushBack [(_x select 1) - (_point distance2D _center) / 400, _point];
    } forEach _places;
    _candidates sort false;
    if (_candidates isEqualTo []) then {[]} else {(_candidates select 0) select 1}
};

BATTLESPACE_BATTLEGROUP_BUILD_DEFINITION = {
    params ["_sourceSector", "_targetSector"];
    private _state = BATTLESPACE_SECTOR_STATES getOrDefault [_sourceSector, createHashMap];
    if ((_state getOrDefault ["owner", ""]) != "OPFOR") exitWith {createHashMap};
    private _stock = _state getOrDefault ["resources", createHashMap];
    private _weighted = [];
    {_weighted append [_x, BATTLESPACE_OFFENSIVE_FORMATION_WEIGHTS param [_forEachIndex, 0]]} forEach BATTLESPACE_STRATEGIC_BATTLEGROUP_FORMATIONS;
    private _formation = selectRandomWeighted _weighted;
    _formation params ["_name", "_manpower", "_categories"];
    private _vehicles = [];
    private _used = createHashMap;
    private _canSpend = {
        params ["_resource", "_amount"];
        private _capacity = [_sourceSector, _resource] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        (_stock getOrDefault [_resource, 0]) - _amount >= ceil (_capacity * BATTLESPACE_OFFENSIVE_SOURCE_RESERVE_RATIO)
    };
    if !(["manpower", _manpower] call _canSpend) then {_manpower = 14};
    if !(["manpower", _manpower] call _canSpend) exitWith {createHashMap};
    {
        private _eligible = (BATTLESPACE_RESOURCE_CLASS_POOLS getOrDefault [_x, []]) select {
            private _resource = [_x] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS;
            private _roles = [_x] call KPLIB_fnc_classifyFactionVehicle;
            _resource != "" && {_x isKindOf "LandVehicle"} && {!(_x isKindOf "StaticWeapon")}
            && {(_roles arrayIntersect ["artillery", "aa", "groundLogistics", "medical"]) isEqualTo []}
            && {[_resource, 1 + (_used getOrDefault [_resource, 0])] call _canSpend}
        };
        if (_eligible isEqualTo []) then {continue};
        private _class = selectRandom _eligible;
        private _resource = [_class] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS;
        _used set [_resource, 1 + (_used getOrDefault [_resource, 0])];
        _vehicles pushBack _class;
    } forEach _categories;
    createHashMapFromArray [["formation", if (_vehicles isEqualTo []) then {"INFANTRY"} else {_name}], ["composition", createHashMapFromArray [["manpower", _manpower], ["vehicles", _vehicles], ["structures", []]]]]
};

BATTLESPACE_BATTLEGROUP_DISPATCH = {
    params ["_originSector", "_targetSector", ["_anchorSector", ""]];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {false};
    if (["BATTLEGROUP"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= BATTLESPACE_STRATEGIC_MAX_ACTIVE_BATTLEGROUPS) exitWith {false};
    if !(_targetSector in blufor_sectors) exitWith {false};
    if (["BATTLEGROUP", _targetSector] call BATTLESPACE_STRATEGIC_HAS_OPERATION_FOR_TARGET) exitWith {false};
    private _source = BATTLESPACE_SECTOR_STATES getOrDefault [_originSector, createHashMap];
    private _target = BATTLESPACE_SECTOR_STATES getOrDefault [_targetSector, createHashMap];
    if (CBA_missionTime < (_source getOrDefault ["nextBattlegroupAt", 0]) || {CBA_missionTime < (_target getOrDefault ["nextBattlegroupTargetAt", 0])}) exitWith {false};
    if !([_originSector, _source] call BATTLESPACE_DEFENSE_SOURCE_IS_AVAILABLE) exitWith {false};
    private _anchors = ((NETWORKED_SECTORS getOrDefault [_targetSector, createHashMap]) getOrDefault ["Links", []]) select {
        ((BATTLESPACE_SECTOR_STATES getOrDefault [_x, createHashMap]) getOrDefault ["owner", ""]) == "OPFOR"
        && {[_originSector, _x, 12] call BATTLESPACE_DEFENSE_GRAPH_DISTANCE >= 0}
    };
    if (_anchors isEqualTo []) exitWith {false};
    if !(_anchorSector in _anchors) then {_anchorSector = _anchors select 0};
    private _forward = (getMarkerPos _anchorSector) vectorFromTo (getMarkerPos _targetSector);
    private _contact = [getMarkerPos _targetSector, _forward] call BATTLESPACE_OFFENSIVE_GET_CONTACT;
    private _capturedAt = (missionNamespace getVariable ["blufor_sectors_cap_times", createHashMap]) getOrDefault [_targetSector, -1e9];
    if ((_contact select 1) <= 0 && {CBA_missionTime - _capturedAt > BATTLESPACE_OFFENSIVE_RECENT_CAPTURE_WINDOW}) exitWith {false};
    private _position = [_anchorSector, _targetSector, getMarkerPos _anchorSector] call BATTLESPACE_OFFENSIVE_PICK_POSITION;
    if (_position isEqualTo []) exitWith {false};
    private _overlap = false;
    {
        if ((_y getOrDefault ["kind", ""]) != "BATTLEGROUP") then {continue};
        if ((_y getOrDefault ["approachSector", ""]) == _anchorSector || {(_y getOrDefault ["stagePosition", getMarkerPos (_y getOrDefault ["targetSector", ""])]) distance2D _position < 1000}) exitWith {_overlap = true};
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    if (_overlap) exitWith {false};
    private _definition = [_originSector, _targetSector] call BATTLESPACE_BATTLEGROUP_BUILD_DEFINITION;
    if (count _definition == 0) exitWith {false};
    private _range = BATTLESPACE_OFFENSIVE_RETREAT_RATIO;
    private _id = ["Battlegroup", _definition get "composition", getMarkerPos _originSector, _position, getMarkerPos _originSector, _originSector, "BATTLEGROUP",
        createHashMapFromArray [["phase", "STAGING"], ["targetSector", _targetSector], ["approachSector", _anchorSector], ["stagePosition", _position], ["targetPosition", _position], ["lastProgressPosition", getMarkerPos _originSector], ["probes", 0], ["shifts", 0], ["flank", selectRandom [-1, 1]], ["retreatRatio", (_range select 0) + random ((_range select 1) - (_range select 0))], ["expiresAt", CBA_missionTime + BATTLESPACE_OFFENSIVE_TOUR_DURATION], ["legDeadline", CBA_missionTime + BATTLESPACE_OFFENSIVE_LEG_TIMEOUT], ["outcome", ""]]
    ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_id == "") exitWith {false};
    _source set ["nextBattlegroupAt", CBA_missionTime + BATTLESPACE_STRATEGIC_BATTLEGROUP_COOLDOWN];
    private _cooldown = BATTLESPACE_STRATEGIC_BATTLEGROUP_TARGET_COOLDOWN;
    _target set ["nextBattlegroupTargetAt", CBA_missionTime + (_cooldown select 0) + random ((_cooldown select 1) - (_cooldown select 0))];
    stats_hostile_battlegroups = (missionNamespace getVariable ["stats_hostile_battlegroups", 0]) + 1;
    [format ["Ground offensive %1 formed %2 at %3, staging on the %4-%5 approach; opportunity=%6", _id, _definition get "formation", _originSector, _anchorSector, _targetSector, ["recent capture", "reported contact"] select ((_contact select 1) > 0)]] call BATTLESPACE_STRATEGIC_LOG;
    [] call BATTLESPACE_LOGISTICS_SAVE;
    true
};

BATTLESPACE_BATTLEGROUP_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    private _remaining = BATTLESPACE_STRATEGIC_MAX_BATTLEGROUPS_PER_TICK min (BATTLESPACE_STRATEGIC_MAX_ACTIVE_BATTLEGROUPS - (["BATTLEGROUP"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS));
    if (_remaining <= 0) exitWith {};
    private _targets = blufor_sectors arrayIntersect sectors_allSectors;
    _targets = [_targets, [], {(BATTLESPACE_SECTOR_STATES getOrDefault [_x, createHashMap]) getOrDefault ["nextBattlegroupTargetAt", 0]}, "ASCEND"] call BIS_fnc_sortBy;
    {
        if (_remaining <= 0) exitWith {};
        private _target = _x;
        private _sources = [];
        {
            if ((_y getOrDefault ["owner", ""]) != "OPFOR" || {[_x] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH < 1}) then {continue};
            if !([_x, _y] call BATTLESPACE_DEFENSE_SOURCE_IS_AVAILABLE) then {continue};
            _sources pushBack [(getMarkerPos _x) distance2D getMarkerPos _target, _x];
        } forEach BATTLESPACE_SECTOR_STATES;
        _sources sort true;
        {if ([_x select 1, _target] call BATTLESPACE_BATTLEGROUP_DISPATCH) exitWith {_remaining = _remaining - 1}} forEach _sources;
    } forEach _targets;
};

BATTLESPACE_BATTLEGROUP_SETTLE = {
    params ["_id", "_taskForce", "_operation"];
    private _sector = _operation getOrDefault ["returnSector", _operation getOrDefault ["originSector", ""]];
    if (_sector != "" && {(_operation getOrDefault ["outcome", ""]) == "RETURNED"}) then {
        private _survivors = [_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVING_FORCE_RESOURCES;
        private _returned = [_sector, _survivors] call BATTLESPACE_RESOURCE_RESTORE_TRANSFER;
        [format ["Ground offensive %1 returned surviving paid assets to %2: %3", _id, _sector, _returned]] call BATTLESPACE_STRATEGIC_LOG;
    };
};

if (isServer) then {
    [format ["Ground offensives use opportunity-led staging/probing/shifting; allocation check %1 seconds, no periodic automatic assault", BATTLESPACE_OFFENSIVE_DECISION_INTERVAL]] call BATTLESPACE_STRATEGIC_LOG;
};
