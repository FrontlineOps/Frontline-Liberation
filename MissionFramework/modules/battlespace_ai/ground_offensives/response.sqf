/* Threat is remembered local observation, not a scan of live BLUFOR positions.
   Strength units match contact memory: infantry 1, cars 3, tracked armor 8. */
BATTLESPACE_OFFENSIVE_COMPOSITION_STRENGTH = {
    params ["_composition"];
    private _strength = (_composition getOrDefault ["manpower", 0]) max 0;
    {
        _strength = _strength + (if (_x isKindOf "Tank") then {8} else {if (_x isKindOf "Car") then {3} else {0}});
    } forEach (_composition getOrDefault ["vehicles", []]);
    _strength
};

BATTLESPACE_OFFENSIVE_OBSERVED_STRENGTH = {
    params ["_position"];
    private _contacts = [_position, BATTLESPACE_OFFENSIVE_CONTACT_RADIUS, BATTLESPACE_OFFENSIVE_CONTACT_MAX_AGE] call BATTLESPACE_CONTACT_QUERY;
    private _targets = _contacts apply {_x select 5};
    private _counted = [];
    private _strength = 0;
    {
        private _target = _x select 5;
        if (isNull _target || {_target in _counted}) then {continue};
        _counted pushBack _target;
        // A reported vehicle already accounts for its mounted crew. Separate
        // dismounted soldiers remain separate contacts, including friendly AI.
        if (_target isKindOf "Man" && {!isNull objectParent _target} && {objectParent _target in _targets}) then {continue};
        _strength = _strength + ((_x select 2) max 0);
    } forEach _contacts;
    _strength
};

BATTLESPACE_OFFENSIVE_COMMITTED_STRENGTH = {
    params ["_position", ["_excludeId", ""]];
    private _strength = 0;
    {
        if (_x == _excludeId) then {continue};
        private _kind = _y getOrDefault ["kind", ""];
        if !(_kind in ["BATTLEGROUP", "DEFENDER", "RESERVE", "REINFORCEMENT", "AIRBORNE_TRANSPORT", "AIRBORNE_REINFORCEMENT", "DEEP RECONNAISSANCE PATROL"]) then {continue};
        if ((_y getOrDefault ["phase", ""]) in ["RETURNING", "LOST"] || {(_y getOrDefault ["outcome", ""]) != ""}) then {continue};
        if (_kind == "AIRBORNE_TRANSPORT" && {(_y getOrDefault ["childTaskForce", ""]) != ""}) then {continue};
        private _force = BATTLESPACE_TASK_FORCES getOrDefault [_x, []];
        if (_force isEqualTo []) then {continue};
        private _current = _force param [1, []];
        private _destination = _force param [2, []];
        private _near = _current isNotEqualTo [] && {_current distance2D _position <= BATTLESPACE_OFFENSIVE_CONTACT_RADIUS};
        private _incoming = _destination isNotEqualTo [] && {_destination distance2D _position <= BATTLESPACE_OFFENSIVE_CONTACT_RADIUS};
        if (!_near && {!_incoming}) then {continue};
        _strength = _strength + ([_force param [3, createHashMap]] call BATTLESPACE_OFFENSIVE_COMPOSITION_STRENGTH);
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _strength
};

BATTLESPACE_OFFENSIVE_RESPONSE_BUDGET = {
    params ["_position", "_sourceSector", ["_excludeId", ""]];
    private _observed = [_position] call BATTLESPACE_OFFENSIVE_OBSERVED_STRENGTH;
    if (_observed <= 0) exitWith {0};
    private _stock = (BATTLESPACE_SECTOR_STATES getOrDefault [_sourceSector, createHashMap]) getOrDefault ["resources", createHashMap];
    private _readiness = 0;
    private _types = 0;
    {
        private _capacity = [_sourceSector, _x] call BATTLESPACE_SECTOR_GET_EFFECTIVE_CAPACITY;
        if (_capacity <= 0) then {continue};
        _readiness = _readiness + ((_stock getOrDefault [_x, 0]) / _capacity max 0 min 1);
        _types = _types + 1;
    } forEach ["manpower", "tanks", "ifv", "apc", "car"];
    private _reserve = BATTLESPACE_OFFENSIVE_SOURCE_RESERVE_RATIO max 0 min 0.99;
    _readiness = ((_readiness / (_types max 1) - _reserve) / (1 - _reserve)) max 0 min 1;
    BATTLESPACE_OFFENSIVE_RESPONSE_RATIOS params ["_low", "_high"];
    private _desired = ceil (_observed * (_low + (_high - _low) * _readiness));
    _desired = _desired max BATTLESPACE_OFFENSIVE_MIN_RESPONSE_MANPOWER;
    (_desired - ([_position, _excludeId] call BATTLESPACE_OFFENSIVE_COMMITTED_STRENGTH)) max 0
};
