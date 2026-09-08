/* Paid battlegroups use shared perceived contacts. Planning and funding remain
   server-owned; the persistent Battlegroup model owns movement and capture. */
call compile preprocessFileLineNumbers "modules\battlespace_ai\ground_offensives\response.sqf";

BATTLESPACE_OFFENSIVE_GET_CONTACT = {
    params ["_position", ["_sourceSector", ""], ["_excludeId", ""], ["_continuing", []], ["_minimumStrength", 0]];
    private _contacts = [[], 1e9, BATTLESPACE_OFFENSIVE_CONTACT_MAX_AGE] call BATTLESPACE_CONTACT_QUERY;
    private _ranked = [];
    {
        if (surfaceIsWater (_x select 0)) then {continue};
        _ranked pushBack [[1, 0] select (_x select 4), _position distance2D (_x select 0), _forEachIndex];
    } forEach _contacts;
    _ranked sort true;
    private _best = [];
    private _evaluatedAreas = [];
    {
        private _contact = _contacts select (_x select 2);
        private _point = _contact select 0;
        private _sameFight = _continuing isNotEqualTo [] && {_continuing distance2D _point <= BATTLESPACE_OFFENSIVE_CONTACT_RADIUS};
        if (_sourceSector != "" && {!_sameFight}) then {
            // This area's budget already includes these nearby reports. Evaluate
            // each area once, rather than repeating the force scan per soldier.
            if (_evaluatedAreas findIf {_x distance2D _point <= BATTLESPACE_OFFENSIVE_CONTACT_RADIUS} >= 0) then {continue};
            _evaluatedAreas pushBack _point;
            private _budget = [_point, _sourceSector, _excludeId] call BATTLESPACE_OFFENSIVE_RESPONSE_BUDGET;
            if (_budget < (_minimumStrength max BATTLESPACE_OFFENSIVE_MIN_RESPONSE_MANPOWER)) then {continue};
        };
        if (true) exitWith {_best = _contact};
    } forEach _ranked;
    _best
};

BATTLESPACE_OFFENSIVE_QUIET = {
    CBA_missionTime - BATTLESPACE_CONTACT_LAST_PLAYER_SEEN >= BATTLESPACE_OFFENSIVE_QUIET_ATTACK_DELAY
};

BATTLESPACE_OFFENSIVE_PICK_OBJECTIVE = {
    params ["_position", ["_excludeId", ""]];
    private _candidates = [];
    {
        private _target = _x;
        private _assigned = false;
        {
            if (_x != _excludeId && {(_y getOrDefault ["kind", ""]) == "BATTLEGROUP"}
                && {(_y getOrDefault ["phase", ""]) != "RETURNING"}
                && {(_y getOrDefault ["targetSector", ""]) == _target}) exitWith {_assigned = true};
        } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
        if (!_assigned) then {_candidates pushBack [_position distance2D getMarkerPos _target, _target]};
    } forEach (blufor_sectors arrayIntersect sectors_allSectors);
    _candidates sort true;
    if (_candidates isEqualTo []) then {""} else {(_candidates select 0) select 1}
};

BATTLESPACE_OFFENSIVE_PICK_POSITION = {
    params ["_anchor", "_target"];
    private _from = getMarkerPos _anchor;
    private _to = getMarkerPos _target;
    private _length = _from distance2D _to;
    private _standoff = BATTLESPACE_OFFENSIVE_TARGET_STANDOFF max (GRLIB_capture_size + 100);
    if (_length < _standoff + 250) exitWith {+_from};
    private _center = _from getPos [(_length * 0.30) max 150 min (_length - _standoff), _from getDir _to];
    private _places = selectBestPlaces [_center, 160, "(2*forest + trees + houses + hills) * (1-sea)", 40, 6];
    private _candidates = [];
    {
        private _point = +(_x select 0);
        _point set [2, 0];
        if ((_point select 0) < 0 || {(_point select 1) < 0} || {(_point select 0) > worldSize} || {(_point select 1) > worldSize}) then {continue};
        if (surfaceIsWater _point || {(surfaceNormal _point select 2) < 0.85} || {_point distance2D _to < _standoff}) then {continue};
        _candidates pushBack [_x select 1, _point];
    } forEach _places;
    _candidates sort false;
    if (_candidates isEqualTo []) then {+_from} else {(_candidates select 0) select 1}
};

BATTLESPACE_BATTLEGROUP_BUILD_DEFINITION = {
    params ["_sourceSector", "_targetSector", ["_strengthBudget", 1e9]];
    private _state = BATTLESPACE_SECTOR_STATES getOrDefault [_sourceSector, createHashMap];
    if ((_state getOrDefault ["owner", ""]) != "OPFOR") exitWith {createHashMap};
    private _stock = _state getOrDefault ["resources", createHashMap];
    private _minimum = BATTLESPACE_OFFENSIVE_MIN_RESPONSE_MANPOWER;
    if (_strengthBudget < _minimum) exitWith {createHashMap};
    private _weighted = [];
    {_weighted append [_x, BATTLESPACE_OFFENSIVE_FORMATION_WEIGHTS param [_forEachIndex, 0]]} forEach BATTLESPACE_STRATEGIC_BATTLEGROUP_FORMATIONS;
    private _formation = selectRandomWeighted _weighted;
    _formation params ["_name", "_manpower", "_categories"];
    _manpower = _manpower min floor _strengthBudget;
    private _vehicles = [];
    private _used = createHashMap;
    private _canSpend = {
        params ["_resource", "_amount"];
        private _capacity = [_sourceSector, _resource] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        (_stock getOrDefault [_resource, 0]) - _amount >= ceil (_capacity * BATTLESPACE_OFFENSIVE_SOURCE_RESERVE_RATIO)
    };
    private _manpowerCapacity = [_sourceSector, "manpower"] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
    private _availableManpower = floor ((_stock getOrDefault ["manpower", 0]) - ceil (_manpowerCapacity * BATTLESPACE_OFFENSIVE_SOURCE_RESERVE_RATIO));
    _manpower = _manpower min _availableManpower;
    if (_manpower < _minimum) exitWith {createHashMap};
    {
        private _eligible = (BATTLESPACE_RESOURCE_CLASS_POOLS getOrDefault [_x, []]) select {
            private _resource = [_x] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS;
            private _roles = [_x] call KPLIB_fnc_classifyFactionVehicle;
            _resource != "" && {_x isKindOf "LandVehicle"} && {!(_x isKindOf "StaticWeapon")}
            && {(_roles arrayIntersect ["artillery", "aa", "groundLogistics", "medical"]) isEqualTo []}
            && {[_resource, 1 + (_used getOrDefault [_resource, 0])] call _canSpend}
            && {([createHashMapFromArray [["manpower", _minimum], ["vehicles", _vehicles + [_x]]]] call BATTLESPACE_OFFENSIVE_COMPOSITION_STRENGTH) <= _strengthBudget}
        };
        if (_eligible isEqualTo []) then {continue};
        private _class = selectRandom _eligible;
        private _resource = [_class] call BATTLESPACE_STRATEGIC_GET_RESOURCE_FOR_CLASS;
        _used set [_resource, 1 + (_used getOrDefault [_resource, 0])];
        _vehicles pushBack _class;
    } forEach _categories;
    private _vehicleStrength = [createHashMapFromArray [["vehicles", _vehicles]]] call BATTLESPACE_OFFENSIVE_COMPOSITION_STRENGTH;
    _manpower = _manpower min floor (_strengthBudget - _vehicleStrength);
    createHashMapFromArray [
        ["formation", [_name, "INFANTRY"] select (_vehicles isEqualTo [])],
        ["composition", createHashMapFromArray [
            ["manpower", _manpower], ["vehicles", _vehicles], ["structures", []]
        ]]
    ]
};

BATTLESPACE_BATTLEGROUP_DISPATCH = {
    params ["_originSector", ["_targetSector", ""], ["_anchorSector", ""]];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {false};
    if ([] call BATTLESPACE_GROUND_ALLOCATION_BLOCK != "") exitWith {false};
    private _source = BATTLESPACE_SECTOR_STATES getOrDefault [_originSector, createHashMap];
    if !([_originSector, _source] call BATTLESPACE_DEFENSE_SOURCE_IS_AVAILABLE) exitWith {false};
    private _origin = getMarkerPos _originSector;
    private _contact = [_origin, _originSector] call BATTLESPACE_OFFENSIVE_GET_CONTACT;
    // A covered contact is not a quiet period: do not buy an objective force
    // merely because the nearest reported battle already has enough troops.
    if (_contact isEqualTo [] && {([_origin] call BATTLESPACE_OFFENSIVE_GET_CONTACT) isNotEqualTo []}) exitWith {false};
    private _phase = "STAGING";
    private _position = +_origin;
    if (_contact isNotEqualTo []) then {
        _phase = "ENGAGING";
        _position = +(_contact select 0);
        _targetSector = "";
    } else {
        if !(_targetSector in (blufor_sectors arrayIntersect sectors_allSectors)) then {
            _targetSector = [_origin] call BATTLESPACE_OFFENSIVE_PICK_OBJECTIVE;
        };
        if (_targetSector != "") then {
            if ([] call BATTLESPACE_OFFENSIVE_QUIET) then {
                _phase = "ASSAULTING";
                _position = getMarkerPos _targetSector;
            } else {
                private _anchors = ((NETWORKED_SECTORS getOrDefault [_targetSector, createHashMap]) getOrDefault ["Links", []]) select {
                    ((BATTLESPACE_SECTOR_STATES getOrDefault [_x, createHashMap]) getOrDefault ["owner", ""]) == "OPFOR"
                    && {[_originSector, _x, 12] call BATTLESPACE_DEFENSE_GRAPH_DISTANCE >= 0}
                };
                if !(_anchorSector in _anchors) then {_anchorSector = _anchors param [0, _originSector]};
                _position = [_anchorSector, _targetSector] call BATTLESPACE_OFFENSIVE_PICK_POSITION;
            };
        };
    };
    if (_contact isEqualTo [] && {_targetSector == ""}) exitWith {false};
    // Keep objective exclusivity; contact responses use remaining local strength.
    private _covered = false;
    {
        if ((_y getOrDefault ["kind", ""]) != "BATTLEGROUP" || {(_y getOrDefault ["phase", ""]) == "RETURNING"}) then {continue};
        if (_targetSector != "" && {(_y getOrDefault ["targetSector", ""]) == _targetSector}) exitWith {_covered = true};
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    if (_covered) exitWith {false};
    private _budget = if (_phase == "ENGAGING") then {[_position, _originSector] call BATTLESPACE_OFFENSIVE_RESPONSE_BUDGET} else {1e9};
    private _definition = [_originSector, _targetSector, _budget] call BATTLESPACE_BATTLEGROUP_BUILD_DEFINITION;
    if (count _definition == 0) exitWith {false};
    private _range = BATTLESPACE_OFFENSIVE_RETREAT_RATIO;
    private _id = ["Battlegroup", _definition get "composition", _origin, _position, _origin, _originSector, "BATTLEGROUP",
        createHashMapFromArray [
            ["phase", _phase], ["targetSector", _targetSector], ["approachSector", _anchorSector],
            ["stagePosition", +_position], ["targetPosition", +_position], ["lastProgressPosition", +_origin],
            ["retreatRatio", (_range select 0) + random ((_range select 1) - (_range select 0))],
            ["legDeadline", CBA_missionTime + BATTLESPACE_OFFENSIVE_LEG_TIMEOUT], ["outcome", ""]
        ]
    ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_id == "") exitWith {false};
    stats_hostile_battlegroups = (missionNamespace getVariable ["stats_hostile_battlegroups", 0]) + 1;
    [format ["Battlegroup %1 formed %2 at %3: %4 toward %5", _id, _definition get "formation", _originSector, toLower _phase, _position]] call BATTLESPACE_STRATEGIC_LOG;
    [] call BATTLESPACE_LOGISTICS_SAVE;
    true
};

BATTLESPACE_BATTLEGROUP_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    if ([] call BATTLESPACE_GROUND_ALLOCATION_BLOCK != "") exitWith {};
    private _remaining = BATTLESPACE_OFFENSIVE_FORMATIONS_PER_TICK;
    private _sources = [];
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR" || {[_x] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH < 1}) then {continue};
        if ([_x, _y] call BATTLESPACE_DEFENSE_SOURCE_IS_AVAILABLE) then {_sources pushBack _x};
    } forEach BATTLESPACE_SECTOR_STATES;
    // Nearest funded source first for each known area; quiet sources prepare the
    // nearest unassigned objective. No contact must be near a sector marker.
    private _ranked = [];
    {
        private _position = getMarkerPos _x;
        private _contact = [_position] call BATTLESPACE_OFFENSIVE_GET_CONTACT;
        private _distance = if (_contact isEqualTo []) then {0} else {_position distance2D (_contact select 0)};
        _ranked pushBack [_distance, _x];
    } forEach _sources;
    _ranked sort true;
    {
        if (_remaining <= 0 || {[] call BATTLESPACE_GROUND_ALLOCATION_BLOCK != ""}) exitWith {};
        if ([_x select 1] call BATTLESPACE_BATTLEGROUP_DISPATCH) then {_remaining = _remaining - 1};
    } forEach _ranked;
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
    ["Battlegroups prioritize reported contacts; objective attacks follow 30 minutes without player sightings"] call BATTLESPACE_STRATEGIC_LOG;
};
