/* Shared OPFOR contact memory. Every group can report; consumers use perceived
   positions and report age. Observer evidence lives in the same record so an
   artillery observer cannot claim somebody else's sighting as its own. */
BATTLESPACE_CONTACT_MEMORY = createHashMap;
BATTLESPACE_CONTACT_REQUESTS = createHashMap;
BATTLESPACE_CONTACT_CURSOR = 0;
// Session grace starts here; expiring a short-lived report must not reset quiet time.
BATTLESPACE_CONTACT_LAST_PLAYER_SEEN = CBA_missionTime;
// Heard BLUFOR gunfire, per 200 m cell: shooter key -> [newest shot times (max 3), player, estimate].
BATTLESPACE_CONTACT_SOUNDS = createHashMap;
BATTLESPACE_CONTACT_SOUND_CELL = 200;
BATTLESPACE_CONTACT_SOUND_MIN_CUES = 3;
// Area reports without a seen target; only ground responders that opt in see them.
BATTLESPACE_CONTACT_UNCONFIRMED = ["KPLIB_SOUND", "KPLIB_LOSS", "KPLIB_LOST"];
// Survivors radio a loss after this many seconds; a group with no survivors is
// only noticed when it misses its check-in. Both stretch with comms disruption.
BATTLESPACE_CONTACT_LOSS_DELAY = 20;
BATTLESPACE_CONTACT_LOST_DELAY = 120;
BATTLESPACE_CONTACT_PENDING = [];
// Set by fresh sightings and casualty reports; the strategic loop runs an early
// battlegroup decision (at most every BATTLESPACE_CONTACT_DECISION_INTERVAL seconds).
BATTLESPACE_CONTACT_DECISION_DUE = false;
BATTLESPACE_CONTACT_DECISION_INTERVAL = 120;

// Every OPFOR ground casualty: casualty pressure now, an unconfirmed report later.
BATTLESPACE_CONTACT_LOSS = {
    params ["_unit", "_weight"];
    if (!isServer || {isNull _unit} || {_unit isKindOf "Air"} || {(vehicle _unit) isKindOf "Air"}) exitWith {};
    [_unit, _weight] call BATTLESPACE_RESERVE_RECORD_FIELD_LOSS;
    private _group = group _unit;
    private _survivors = (units _group) findIf {alive _x && {!captive _x}} >= 0;
    if (_survivors) then {[_group] call BATTLESPACE_CONTACT_SAMPLE_GROUP};
    if (count BATTLESPACE_CONTACT_PENDING >= 64) exitWith {};
    private _position = getPosATL _unit;
    BATTLESPACE_CONTACT_PENDING pushBack [
        CBA_missionTime + ([[BATTLESPACE_CONTACT_LOST_DELAY, BATTLESPACE_CONTACT_LOSS_DELAY] select _survivors] call KPLIB_RADIO_SERVER_COMMAND_DELAY),
        [_position select 0, _position select 1, 0],
        ["KPLIB_LOST", "KPLIB_LOSS"] select _survivors
    ];
};

// One area record per report cell and class; strength counts reports in the cell.
BATTLESPACE_CONTACT_UNCONFIRMED_REPORT = {
    params ["_position", "_class"];
    private _key = format ["%1:%2:%3", _class, floor ((_position select 0) / BATTLESPACE_CONTACT_SOUND_CELL), floor ((_position select 1) / BATTLESPACE_CONTACT_SOUND_CELL)];
    private _record = BATTLESPACE_CONTACT_MEMORY getOrDefault [_key, [_position, -1e9, 0, _position]];
    private _strength = if (CBA_missionTime - (_record select 1) > BATTLESPACE_CONTACT_MEMORY_MAX_AGE) then {1} else {((_record select 2) + 1) min 8};
    // BLUFOR is the only side the commander fights; a casualty is assumed player-caused.
    BATTLESPACE_CONTACT_MEMORY set [_key, [+_position, CBA_missionTime, _strength, +(_record select 0), true, objNull, _class, createHashMap, CBA_missionTime]];
    if (!isNil "BATTLESPACE_THEATER_NOTE") then {[_position, _class] call BATTLESPACE_THEATER_NOTE};
    BATTLESPACE_CONTACT_DECISION_DUE = true;
};

// A listener's uncertain estimate, never a target. Only sustained fire (several
// distinct shots in one cell within the memory age) becomes an area contact, and
// only ground responders that opt in through BATTLESPACE_CONTACT_QUERY see it.
BATTLESPACE_CONTACT_HEARD = {
    params ["_position", "_heardAt", "_shooterKey", "_player"];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    private _key = format ["SOUND:%1:%2", floor ((_position select 0) / BATTLESPACE_CONTACT_SOUND_CELL), floor ((_position select 1) / BATTLESPACE_CONTACT_SOUND_CELL)];
    private _cell = BATTLESPACE_CONTACT_SOUNDS getOrDefault [_key, createHashMap, true];
    private _entry = _cell getOrDefault [_shooterKey, [[], _player, []], true];
    // Several listeners hearing one shot share its time and count once.
    if !(_heardAt in (_entry select 0)) then {
        (_entry select 0) pushBack _heardAt;
        _entry set [0, (_entry select 0) select [(count (_entry select 0) - 3) max 0]];
    };
    _entry set [1, (_entry select 1) || {_player}];
    _entry set [2, [_position select 0, _position select 1, 0]];
    private _cues = 0;
    private _anyPlayer = false;
    private _latest = [-1e9, []];
    {
        _y params ["_times", "_isPlayer", "_estimate"];
        _times = _times select {CBA_missionTime - _x <= BATTLESPACE_CONTACT_MEMORY_MAX_AGE};
        _cues = _cues + count _times;
        _anyPlayer = _anyPlayer || {_isPlayer};
        if (_times isNotEqualTo [] && {(_times select (count _times - 1)) > (_latest select 0)}) then {_latest = [_times select (count _times - 1), _estimate]};
    } forEach _cell;
    if (_cues < BATTLESPACE_CONTACT_SOUND_MIN_CUES) exitWith {};
    _latest params ["_seenAt", "_where"];
    private _previous = (BATTLESPACE_CONTACT_MEMORY getOrDefault [_key, [_where]]) select 0;
    // Position, seen time, strength (distinct shooters), prior position, player, no target, class, no observer evidence.
    BATTLESPACE_CONTACT_MEMORY set [_key, [+_where, _seenAt, 1 max count _cell min 8, +_previous, _anyPlayer, objNull, "KPLIB_SOUND", createHashMap, _seenAt]];
    if (!isNil "BATTLESPACE_THEATER_NOTE") then {[_where, "KPLIB_SOUND"] call BATTLESPACE_THEATER_NOTE};
};

// Local observation only. Records: target, perceived position, seen time, weight, player, class.
BATTLESPACE_CONTACT_COLLECT = {
    params ["_group"];
    if (isNull _group || {!local _group} || {side _group != GRLIB_side_enemy}) exitWith {[]};
    private _units = units _group select {alive _x && {!captive _x}};
    if (_units isEqualTo []) exitWith {[]};
    private _reports = [];
    // Fresh native sightings can have negative ages and disappear when the
    // engine age filter is enabled. Apply the same age limit below instead;
    // the receiver also checks age before accepting any local or HC report.
    {
        _x params ["_accuracy", "_target", "_side", "_class", "_position", "_age"];
        if (_accuracy <= 0 || {isNull _target} || {_side != GRLIB_side_friendly}
            || {count _position < 2} || {_age > BATTLESPACE_CONTACT_MEMORY_MAX_AGE}) then {continue};
        private _weight = if (_class isKindOf "Tank") then {8} else {([1, 3] select (_class isKindOf "Car"))};
        private _player = isPlayer _target || {(crew _target) findIf {alive _x && {isPlayer _x}} >= 0};
        _reports pushBack [_target, [_position select 0, _position select 1, 0], CBA_missionTime - (0 max _age), _weight, _player, _class];
        if (count _reports >= 12) exitWith {};
    } forEach ((_units select 0) targetsQuery [objNull, GRLIB_side_friendly, "", [], 0]);
    _reports
};

BATTLESPACE_CONTACT_RECEIVE = {
    params ["_group", "_token", "_reports"];
    if (!isServer || {isNull _group}) exitWith {};
    private _owner = groupOwner _group;
    if (isRemoteExecuted && {remoteExecutedOwner != _owner}) exitWith {};
    private _request = BATTLESPACE_CONTACT_REQUESTS getOrDefault [str _group, []];
    if (count _request != 5 || {(_request select 0) != _token} || {(_request select 1) != _owner} || {!(_request select 2)} || {(_request select 3) isNotEqualTo _group}) exitWith {};
    _request set [2, false];
    if !(_reports isEqualType []) exitWith {};
    {
        if !(_x isEqualType [] && {count _x == 6}) then {continue};
        _x params ["_target", "_position", "_seenAt", "_weight", "_player", "_class"];
        if !(_target isEqualType objNull && {!isNull _target} && {_position isEqualType []} && {count _position == 3} && {_position findIf {!(_x isEqualType 0)} < 0} && {_seenAt isEqualType 0} && {_weight isEqualType 0} && {_player isEqualType true} && {_class isEqualType ""}) then {continue};
        if (_seenAt > CBA_missionTime || {CBA_missionTime - _seenAt > BATTLESPACE_CONTACT_MEMORY_MAX_AGE}) then {continue};
        if (_player) then {
            BATTLESPACE_CONTACT_LAST_PLAYER_SEEN = BATTLESPACE_CONTACT_LAST_PLAYER_SEEN max _seenAt;
        };
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
            if (!isNil "BATTLESPACE_THEATER_NOTE") then {[_position, _class] call BATTLESPACE_THEATER_NOTE};
            if !(_class isKindOf "Air") then {BATTLESPACE_CONTACT_DECISION_DUE = true};
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
    if (!isServer || {isRemoteExecuted} || {isNull _group} || {side _group != GRLIB_side_enemy}) exitWith {};
    private _previous = BATTLESPACE_CONTACT_REQUESTS getOrDefault [str _group, [-1e9, -1, false, grpNull, -1e9]];
    if (CBA_missionTime - (_previous select 0) < 5 && {(_previous select 1) == groupOwner _group} && {(_previous select 3) isEqualTo _group}) exitWith {};
    private _commandTime = call KPLIB_RADIO_SERVER_COMMAND_TIME;
    if (_commandTime - (_previous select 4) < 5 && {(_previous select 1) == groupOwner _group} && {(_previous select 3) isEqualTo _group}) exitWith {};
    private _token = CBA_missionTime;
    // Private request metadata: real token, owner, pending, identity, command-clock time.
    BATTLESPACE_CONTACT_REQUESTS set [str _group, [_token, groupOwner _group, true, _group, _commandTime]];
    if (local _group) then {[_group, _token] call BATTLESPACE_CONTACT_REPORT} else {[_group, _token] remoteExecCall ["BATTLESPACE_CONTACT_REPORT", groupOwner _group]};
};

BATTLESPACE_CONTACT_QUERY = {
    params [["_center", []], ["_radius", 1e9], ["_maxAge", BATTLESPACE_CONTACT_MEMORY_MAX_AGE], ["_playersOnly", false], ["_observerGroup", grpNull], ["_groundOnly", true], ["_includeUnconfirmed", false]];
    if (!isServer) exitWith {[]};
    private _matches = [];
    {
        // Heard-gunfire, casualty and lost-contact areas have no observer evidence
        // and are opt-in for ground responders.
        if (!_includeUnconfirmed && {(_y select 6) in BATTLESPACE_CONTACT_UNCONFIRMED}) then {continue};
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
    if (!isServer || {isRemoteExecuted} || {isNil "GRLIB_side_enemy"}) exitWith {};
    if (BATTLESPACE_CONTACT_PENDING isNotEqualTo []) then {
        private _due = BATTLESPACE_CONTACT_PENDING select {(_x select 0) <= CBA_missionTime};
        BATTLESPACE_CONTACT_PENDING = BATTLESPACE_CONTACT_PENDING select {(_x select 0) > CBA_missionTime};
        {[_x select 1, _x select 2] call BATTLESPACE_CONTACT_UNCONFIRMED_REPORT} forEach _due;
    };
    {
        if (CBA_missionTime - (_y select 1) > BATTLESPACE_CONTACT_MEMORY_MAX_AGE) then {BATTLESPACE_CONTACT_MEMORY deleteAt _x; continue};
        private _evidence = _y select 7;
        {if (CBA_missionTime - (_y select 1) > BATTLESPACE_CONTACT_MEMORY_MAX_AGE) then {_evidence deleteAt _x}} forEach _evidence;
    } forEach BATTLESPACE_CONTACT_MEMORY;
    {if (isNull (_y select 3) || {CBA_missionTime - (_y select 0) > BATTLESPACE_CONTACT_MEMORY_MAX_AGE}) then {BATTLESPACE_CONTACT_REQUESTS deleteAt _x}} forEach BATTLESPACE_CONTACT_REQUESTS;
    {
        private _cell = _y;
        {if (((_y select 0) findIf {CBA_missionTime - _x <= BATTLESPACE_CONTACT_MEMORY_MAX_AGE}) < 0) then {_cell deleteAt _x}} forEach _cell;
        if (count _cell == 0) then {BATTLESPACE_CONTACT_SOUNDS deleteAt _x};
    } forEach BATTLESPACE_CONTACT_SOUNDS;
    if (count BATTLESPACE_CONTACT_MEMORY > 256) then {
        private _oldest = []; {_oldest pushBack [_y select 1, _x]} forEach BATTLESPACE_CONTACT_MEMORY; _oldest sort true;
        {BATTLESPACE_CONTACT_MEMORY deleteAt (_x select 1)} forEach (_oldest select [0, count _oldest - 256]);
    };
    private _commandTime = call KPLIB_RADIO_SERVER_COMMAND_TIME;
    if (_commandTime < (localNamespace getVariable ["KPLIB_RADIO_NEXT_CONTACT_REPORT", 0])) exitWith {};
    localNamespace setVariable ["KPLIB_RADIO_NEXT_CONTACT_REPORT", _commandTime + 5];
    private _groups = allGroups select {side _x == GRLIB_side_enemy && {units _x findIf {alive _x && {!captive _x}} >= 0}};
    if (_groups isEqualTo []) exitWith {};
    for "_i" from 1 to (BATTLESPACE_CONTACT_GROUPS_PER_TICK min count _groups) do {
        BATTLESPACE_CONTACT_CURSOR = BATTLESPACE_CONTACT_CURSOR mod count _groups;
        [_groups select BATTLESPACE_CONTACT_CURSOR] call BATTLESPACE_CONTACT_SAMPLE_GROUP;
        BATTLESPACE_CONTACT_CURSOR = BATTLESPACE_CONTACT_CURSOR + 1;
    };
};

if (isServer) then {BATTLESPACE_CONTACT_PFH = [{[] call BATTLESPACE_CONTACT_TICK}, 5] call CBA_fnc_addPerFrameHandler};
