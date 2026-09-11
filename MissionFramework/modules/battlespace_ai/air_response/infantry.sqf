BATTLESPACE_AIR_INFANTRY_IS_TARGET = {
    params ["_unit"];
    !isNull _unit && {alive _unit} && {_unit isKindOf "Man"}
        && {vehicle _unit == _unit} && {side group _unit == GRLIB_side_friendly}
        && {!captive _unit} && {lifeState _unit != "INCAPACITATED"}
        && {!(_unit getVariable ["ACE_isUnconscious", false])}
};

/* Infantry CAS requests use shared OPFOR reports, not live player positions.
   Pressure and sector cooldowns are session-local and bounded by objective count. */
BATTLESPACE_AIR_INFANTRY_REPORTS = {
    if (!isServer || {isNil "BATTLESPACE_CONTACT_QUERY"}) exitWith {[]};
    private _reports = [[], 1e9, BATTLESPACE_AIR_INFANTRY_CONTACT_MAX_AGE] call BATTLESPACE_CONTACT_QUERY;
    _reports select {
        (_x select 6) isKindOf "Man"
        && {[_x select 5] call BATTLESPACE_AIR_INFANTRY_IS_TARGET}
    }
};

BATTLESPACE_AIR_INFANTRY_CONTACTS = {
    if (!isServer || {isRemoteExecuted}) exitWith {[]};
    private _reports = [] call BATTLESPACE_AIR_INFANTRY_REPORTS;
    private _pressure = localNamespace getVariable ["BATTLESPACE_AIR_INFANTRY_PRESSURE", createHashMap];
    private _cooldowns = localNamespace getVariable ["BATTLESPACE_AIR_INFANTRY_COOLDOWNS", createHashMap];
    {if (CBA_missionTime >= _y) then {_cooldowns deleteAt _x}} forEach +_cooldowns;
    private _observed = createHashMap;
    private _contacts = [];
    {
        if !(_x select 4) then {continue};
        private _anchor = _x;
        private _position = _anchor select 0;
        private _members = _reports select {(_x select 0) distance2D _position <= BATTLESPACE_AIR_INFANTRY_CLUSTER_RADIUS};
        if (count _members < BATTLESPACE_AIR_INFANTRY_MIN_COUNT) then {continue};
        private _sector = "";
        private _distance = BATTLESPACE_AIR_INFANTRY_OBJECTIVE_RADIUS;
        {
            if ((_y getOrDefault ["owner", ""]) != "OPFOR" || {_x in blufor_sectors} || {markerShape _x == ""}) then {continue};
            private _range = _position distance2D getMarkerPos _x;
            if (_range <= _distance) then {
                _distance = _range;
                _sector = _x;
            };
        } forEach BATTLESPACE_SECTOR_STATES;
        if (_sector == "" || {_sector in _observed} || {CBA_missionTime < (_cooldowns getOrDefault [_sector, 0])}) then {continue};
        _observed set [_sector, true];
        private _previous = _pressure getOrDefault [_sector, []];
        private _seenAt = _anchor select 1;
        if (_previous isEqualTo [] || {(_previous select 0) distance2D _position > BATTLESPACE_AIR_INFANTRY_CLUSTER_RADIUS}
            || {_seenAt - (_previous select 2) > BATTLESPACE_AIR_INFANTRY_CONTACT_MAX_AGE}) then {
            _previous = [+_position, CBA_missionTime, _seenAt];
        };
        _previous set [2, _seenAt];
        _pressure set [_sector, _previous];
        if (CBA_missionTime - (_previous select 1) < BATTLESPACE_AIR_INFANTRY_PRESSURE_DURATION) then {continue};
        private _unit = _anchor select 5;
        _contacts pushBack [50 + (count _members min 30), "INFANTRY", +_position, netId _unit, typeOf _unit, _sector];
    } forEach _reports;
    {if !(_x in _observed) then {_pressure deleteAt _x}} forEach +_pressure;
    localNamespace setVariable ["BATTLESPACE_AIR_INFANTRY_PRESSURE", _pressure];
    localNamespace setVariable ["BATTLESPACE_AIR_INFANTRY_COOLDOWNS", _cooldowns];
    _contacts
};

BATTLESPACE_AIR_INFANTRY_COOLDOWN = {
    params ["_operation"];
    private _sector = _operation getOrDefault ["infantrySector", ""];
    if (!isServer || {isRemoteExecuted} || {_sector == ""}) exitWith {};
    private _cooldowns = localNamespace getVariable ["BATTLESPACE_AIR_INFANTRY_COOLDOWNS", createHashMap];
    _cooldowns set [_sector, CBA_missionTime + BATTLESPACE_STRATEGIC_AIR_RESPONSE_TARGET_COOLDOWN];
    localNamespace setVariable ["BATTLESPACE_AIR_INFANTRY_COOLDOWNS", _cooldowns];
    (localNamespace getVariable ["BATTLESPACE_AIR_INFANTRY_PRESSURE", createHashMap]) deleteAt _sector;
};

BATTLESPACE_AIR_INFANTRY_OBSERVATION = {
    params ["_state", "_target"];
    if (isNull _target) exitWith {[]};
    private _observation = _state getOrDefault ["infantryObservation", []];
    if (count _observation != 3 || {(_observation select 0) isNotEqualTo _target}
        || {CBA_missionTime - (_observation select 2) > BATTLESPACE_AIR_INFANTRY_ATTACK_MEMORY}) exitWith {[]};
    +(_observation select 1)
};

BATTLESPACE_AIR_INFANTRY_FIND_CONTACT = {
    params ["_id", "_operation"];
    private _targetId = _operation getOrDefault ["targetNetId", ""];
    private _state = (localNamespace getVariable ["BATTLESPACE_AIR_RUNTIME", createHashMap]) getOrDefault [_id, createHashMap];
    private _target = _state getOrDefault ["target", objNull];
    private _remembered = [_state, _target] call BATTLESPACE_AIR_INFANTRY_OBSERVATION;
    if ((_state getOrDefault ["visible", false] || {_remembered isNotEqualTo []}) && {netId _target == _targetId}
        && {[_target] call BATTLESPACE_AIR_INFANTRY_IS_TARGET}) exitWith {
        [_target, if (_remembered isEqualTo []) then {+(_operation get "contactPosition")} else {ASLToATL _remembered}, _targetId]
    };
    private _anchor = _operation getOrDefault ["contactPosition", [0,0,0]];
    private _best = [];
    private _distance = BATTLESPACE_AIR_INFANTRY_CLUSTER_RADIUS * 2;
    {
        private _unit = _x select 5;
        private _position = _x select 0;
        if ([_position, netId _unit, _id] call BATTLESPACE_AIR_RESPONSE_CONTACT_IS_COVERED) then {continue};
        if (netId _unit == _targetId) exitWith {_best = [_unit, +_position, netId _unit]};
        if (_position distance2D _anchor <= _distance) then {
            _distance = _position distance2D _anchor;
            _best = [_unit, +_position, netId _unit];
        };
    } forEach ([] call BATTLESPACE_AIR_INFANTRY_REPORTS);
    _best
};

BATTLESPACE_AIR_INFANTRY_SEARCH = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    params ["_state", "_operation", "_anchor"];
    _state set ["visible", false];
    _state set ["infantryMemoryAttack", false];
    [_state, objNull, false] call BATTLESPACE_AIR_GUIDE;
    if (_state get "stage" != "SEARCH") then {
        [_state, "SEARCH"] call BATTLESPACE_AIR_SET_STAGE;
        {
            if (local _x) then {
                _x doTarget objNull;
                _x doWatch objNull;
            };
        } forEach crew (_state get "aircraft");
    };
    private _plane = (_state get "aircraft") isKindOf "Plane";
    private _search = _anchor getPos [1800, (floor (CBA_missionTime / 20) * 45) mod 360];
    [_state, _search, (getTerrainHeightASL _anchor max 0) + ([200,1000] select _plane), [40,160] select _plane] call BATTLESPACE_AIR_ORDER;
};

BATTLESPACE_AIR_INFANTRY_SELECT_CLASS = {
    private _catalogs = missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap];
    private _opfor = _catalogs getOrDefault ["opfor", createHashMap];
    private _pool = BATTLESPACE_RESOURCE_CLASS_POOLS getOrDefault ["aircraft", []];
    private _preferred = +(_opfor getOrDefault ["rotaryCas", []]);
    _preferred append (_opfor getOrDefault ["fixedWing", []]);
    private _valid = [];
    {
        if (_x in _pool && {[_x] call BATTLESPACE_AIR_RESPONSE_IS_COMBAT_AIRCRAFT}
            && {[_x] call BATTLESPACE_AIR_CLASS_HAS_INFANTRY_WEAPON}) then {_valid pushBackUnique _x};
    } forEach _preferred;
    if (_valid isEqualTo []) then {
        {
            if ([_x] call BATTLESPACE_AIR_RESPONSE_IS_COMBAT_AIRCRAFT
                && {[_x] call BATTLESPACE_AIR_CLASS_HAS_INFANTRY_WEAPON}) then {_valid pushBackUnique _x};
        } forEach _pool;
    };
    if (_valid isEqualTo []) then {""} else {selectRandom _valid}
};
