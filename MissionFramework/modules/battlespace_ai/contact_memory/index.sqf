/* Shared OPFOR contact memory. Every group can report; consumers use perceived
   positions and report age. Observer evidence lives in the same record so an
   artillery observer cannot claim somebody else's sighting as its own. */
BATTLESPACE_CONTACT_MEMORY = createHashMap;
BATTLESPACE_CONTACT_REQUESTS = createHashMap;
BATTLESPACE_CONTACT_CURSOR = 0;

// Local observation only. Records: target, perceived position, seen time, weight, player, class.
BATTLESPACE_CONTACT_COLLECT = {
    params ["_group"];
    if (isNull _group || {!local _group} || {side _group != GRLIB_side_enemy}) exitWith {[]};
    private _units = units _group select {alive _x && {!captive _x}};
    if (_units isEqualTo []) exitWith {[]};
    private _reports = [];
    {
        _x params ["_accuracy", "_target", "_side", "_class", "_position", "_age"];
        if (_accuracy <= 0 || {isNull _target} || {_side != GRLIB_side_friendly} || {count _position < 2}) then {continue};
        private _weight = if (_class isKindOf "Tank") then {8} else {if (_class isKindOf "Car") then {3} else {1}};
        private _player = isPlayer _target || {(crew _target) findIf {alive _x && {isPlayer _x}} >= 0};
        _reports pushBack [_target, [_position select 0, _position select 1, 0], CBA_missionTime - (0 max _age), _weight, _player, _class];
        if (count _reports >= 12) exitWith {};
    } forEach ((_units select 0) targetsQuery [objNull, GRLIB_side_friendly, "", [], BATTLESPACE_CONTACT_MEMORY_MAX_AGE]);
    _reports
};

BATTLESPACE_CONTACT_RECEIVE = {
    params ["_group", "_token", "_reports"];
    if (!isServer || {isNull _group}) exitWith {};
    private _owner = groupOwner _group;
    if (isRemoteExecuted && {remoteExecutedOwner != _owner}) exitWith {};
    private _request = BATTLESPACE_CONTACT_REQUESTS getOrDefault [str _group, []];
    if (count _request != 4 || {(_request select 0) != _token} || {(_request select 1) != _owner} || {!(_request select 2)} || {(_request select 3) isNotEqualTo _group}) exitWith {};
    _request set [2, false];
    if !(_reports isEqualType []) exitWith {};
    {
        if !(_x isEqualType [] && {count _x == 6}) then {continue};
        _x params ["_target", "_position", "_seenAt", "_weight", "_player", "_class"];
        if !(_target isEqualType objNull && {!isNull _target} && {_position isEqualType []} && {count _position == 3} && {_position findIf {!(_x isEqualType 0)} < 0} && {_seenAt isEqualType 0} && {_weight isEqualType 0} && {_player isEqualType true} && {_class isEqualType ""}) then {continue};
        if (_seenAt > CBA_missionTime || {CBA_missionTime - _seenAt > BATTLESPACE_CONTACT_MEMORY_MAX_AGE}) then {continue};
        private _key = str _target;
        // Position, seen time, strength, prior position, player, target, class, observer evidence.
        private _record = BATTLESPACE_CONTACT_MEMORY getOrDefault [_key, [[], -1e9, 0, [], false, _target, _class, createHashMap, -1e9]];
        if ((_record select 5) isNotEqualTo _target) then {_record = [[], -1e9, 0, [], false, _target, _class, createHashMap, -1e9]};
        private _evidence = _record select 7;
        private _previous = _evidence getOrDefault [str _group, [[], -1e9, _owner, _group]];
        if (_seenAt > (_previous select 1) || {(_previous select 2) != _owner} || {(_previous select 3) isNotEqualTo _group}) then {_evidence set [str _group, [+_position, _seenAt, _owner, _group]]};
        if (_seenAt > (_record select 1)) then {
            // Keep a movement baseline long enough for offensive withdrawal detection.
            private _motionPosition = +(_record select 3);
            private _motionAt = _record select 8;
            if (_motionPosition isEqualTo [] || {_seenAt - _motionAt >= 30}) then {
                _motionPosition = +(_record select 0);
                _motionAt = _record select 1;
            };
            _record = [+_position, _seenAt, _weight max 1 min 8, _motionPosition, _player, _target, _class, _evidence, _motionAt];
        };
        BATTLESPACE_CONTACT_MEMORY set [_key, _record];
    } forEach (_reports select [0, 12]);
};

BATTLESPACE_CONTACT_REPORT = {
    params ["_group", "_token"];
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    if (isNull _group || {!local _group}) exitWith {};
    private _reports = [_group] call BATTLESPACE_CONTACT_COLLECT;
    if (isServer) then {[_group, _token, _reports] call BATTLESPACE_CONTACT_RECEIVE} else {[_group, _token, _reports] remoteExecCall ["BATTLESPACE_CONTACT_RECEIVE", 2]};
};

BATTLESPACE_CONTACT_SAMPLE_GROUP = {
    params ["_group"];
    if (!isServer || {isNull _group} || {side _group != GRLIB_side_enemy}) exitWith {};
    private _previous = BATTLESPACE_CONTACT_REQUESTS getOrDefault [str _group, [-1e9, -1, false, grpNull]];
    if (CBA_missionTime - (_previous select 0) < 5 && {(_previous select 1) == groupOwner _group} && {(_previous select 3) isEqualTo _group}) exitWith {};
    private _token = CBA_missionTime;
    BATTLESPACE_CONTACT_REQUESTS set [str _group, [_token, groupOwner _group, true, _group]];
    if (local _group) then {[_group, _token] call BATTLESPACE_CONTACT_REPORT} else {[_group, _token] remoteExecCall ["BATTLESPACE_CONTACT_REPORT", groupOwner _group]};
};

BATTLESPACE_CONTACT_QUERY = {
    params [["_center", []], ["_radius", 1e9], ["_maxAge", BATTLESPACE_CONTACT_MEMORY_MAX_AGE], ["_playersOnly", false], ["_observerGroup", grpNull], ["_groundOnly", true]];
    if (!isServer) exitWith {[]};
    private _matches = [];
    {
        private _record = +_y;
        if (!isNull _observerGroup) then {
            private _evidence = (_record select 7) getOrDefault [str _observerGroup, []];
            if (count _evidence != 4 || {(_evidence select 2) != groupOwner _observerGroup} || {(_evidence select 3) isNotEqualTo _observerGroup}) then {continue};
            _record set [0, +(_evidence select 0)];
            _record set [1, _evidence select 1];
        };
        if (CBA_missionTime - (_record select 1) > _maxAge || {_playersOnly && {!(_record select 4)}} || {_groundOnly && {(_record select 6) isKindOf "Air"}}) then {continue};
        if (_center isNotEqualTo [] && {(_record select 0) distance2D _center > _radius}) then {continue};
        _matches pushBack (_record select [0, 7]);
    } forEach BATTLESPACE_CONTACT_MEMORY;
    _matches
};

BATTLESPACE_CONTACT_TICK = {
    if (!isServer || {isNil "GRLIB_side_enemy"}) exitWith {};
    {
        if (CBA_missionTime - (_y select 1) > BATTLESPACE_CONTACT_MEMORY_MAX_AGE) then {BATTLESPACE_CONTACT_MEMORY deleteAt _x; continue};
        private _evidence = _y select 7;
        {if (CBA_missionTime - (_y select 1) > BATTLESPACE_CONTACT_MEMORY_MAX_AGE) then {_evidence deleteAt _x}} forEach _evidence;
    } forEach BATTLESPACE_CONTACT_MEMORY;
    {if (isNull (_y select 3) || {CBA_missionTime - (_y select 0) > BATTLESPACE_CONTACT_MEMORY_MAX_AGE}) then {BATTLESPACE_CONTACT_REQUESTS deleteAt _x}} forEach BATTLESPACE_CONTACT_REQUESTS;
    if (count BATTLESPACE_CONTACT_MEMORY > 256) then {
        private _oldest = []; {_oldest pushBack [_y select 1, _x]} forEach BATTLESPACE_CONTACT_MEMORY; _oldest sort true;
        {BATTLESPACE_CONTACT_MEMORY deleteAt (_x select 1)} forEach (_oldest select [0, count _oldest - 256]);
    };
    private _groups = allGroups select {side _x == GRLIB_side_enemy && {units _x findIf {alive _x && {!captive _x}} >= 0}};
    if (_groups isEqualTo []) exitWith {};
    for "_i" from 1 to (BATTLESPACE_CONTACT_GROUPS_PER_TICK min count _groups) do {
        BATTLESPACE_CONTACT_CURSOR = BATTLESPACE_CONTACT_CURSOR mod count _groups;
        [_groups select BATTLESPACE_CONTACT_CURSOR] call BATTLESPACE_CONTACT_SAMPLE_GROUP;
        BATTLESPACE_CONTACT_CURSOR = BATTLESPACE_CONTACT_CURSOR + 1;
    };
};

if (isServer) then {BATTLESPACE_CONTACT_PFH = [{[] call BATTLESPACE_CONTACT_TICK}, 5] call CBA_fnc_addPerFrameHandler};
