// Curator diagnostics read the authoritative assignments and shared sighting memory.
// Only compact snapshots are sent to the requesting curator; no JIP/global broadcast.
BATTLESPACE_ZEN_BUILD_COVERAGE = {
    if (!isServer || {isNil "BATTLESPACE_STRATEGIC_OPERATIONS"}) exitWith {[[], []]};
    private _coverage = [] call BATTLESPACE_DEFENSE_READ_COVERAGE;
    private _rows = [];
    {
        private _counts = _coverage getOrDefault [_x, [0, 0, []]];
        _counts params ["_present", "_incoming", "_ids"];
        private _target = _y get "target";
        private _field = (_y get "kind") == "FIELD";
        private _enough = if (_field) then {_present >= BATTLESPACE_STRATEGIC_DEFENDER_RETREAT_MANPOWER} else {_present >= _target};
        private _status = if (_enough) then {"COVERED"} else {if (_incoming > 0) then {"RELIEF INCOMING"} else {if (_present > 0) then {"UNDER STRENGTH"} else {"GAP"}}};
        private _reason = _y getOrDefault ["reason", "Awaiting allocation evaluation"];
        if (_enough) then {_reason = "Assigned troops operating here"};
        if (!_enough && {_incoming > 0}) then {_reason = "Relief has an assignment; it has not reached the area yet"};
        private _blocked = BATTLESPACE_DEFENSE_BLOCKED_ASSIGNMENTS getOrDefault [_x, [0, ""]];
        if (!_enough && {CBA_missionTime < (_blocked select 0)}) then {_reason = _blocked select 1};
        private _name = markerText (_y get "sector");
        if (_name == "") then {_name = _y get "sector"};
        if (_field) then {
            private _other = _y getOrDefault ["otherSector", ""];
            private _otherName = markerText _other;
            if (_otherName == "") then {_otherName = _other};
            _name = format ["%1 / %2 approach", _name, _otherName];
        };
        private _spawned = 0;
        private _position = _y get "position";
        private _radius = [350, BATTLESPACE_FIELD_COVERAGE_RADIUS + 100] select _field;
        {
            private _force = BATTLESPACE_TASK_FORCES get _x;
            if (isNil "_force") then {continue};
            {
                _spawned = _spawned + ({alive _x && {!captive _x} && {_x distance2D _position <= _radius}} count units _x);
            } forEach (_force param [4, []]);
        } forEach _ids;
        _rows pushBack [_x, _y get "kind", +_position, _name, _target, _present, _incoming, _status, _reason, +_ids, _y get "role", _spawned];
    } forEach BATTLESPACE_DEFENSE_ASSIGNMENTS;
    [[
        [] call BATTLESPACE_GROUND_FORCE_COUNT, BATTLESPACE_STRATEGIC_GROUND_FORCE_CAP,
        missionNamespace getVariable ["BATTLESPACE_GROUND_FORMATIONS_CREATED", 0], BATTLESPACE_STRATEGIC_GROUND_FORMATIONS_PER_TICK,
        [] call KPLIB_fnc_getOpforCap, BATTLESPACE_UNIT_CAP,
        missionNamespace getVariable ["BATTLESPACE_DEFENSE_LAST_EVALUATION", -1], CBA_missionTime
    ], _rows]
};

BATTLESPACE_ZEN_BUILD_CONTACTS = {
    private _rows = [];
    if (!isServer) exitWith {_rows};
    {
        _y params ["_position", "_seenAt", "_weight", "_previous", "_player", "_target", "_class", "_evidence"];
        if (CBA_missionTime - _seenAt > BATTLESPACE_CONTACT_MEMORY_MAX_AGE) then {continue};
        private _observers = [];
        {
            _y params ["_reportedPosition", "_reportedAt", "_owner", "_group"];
            if (isNull _group || {_owner != groupOwner _group} || {CBA_missionTime - _reportedAt > BATTLESPACE_CONTACT_MEMORY_MAX_AGE}) then {continue};
            _observers pushBack [groupId _group, ceil (CBA_missionTime - _reportedAt)];
        } forEach _evidence;
        private _name = getText (configFile >> "CfgVehicles" >> _class >> "displayName");
        if (_name == "") then {_name = _class};
        // _target is deliberately never dereferenced for its current position.
        _rows pushBack [_x, +_position, _seenAt, _name, _weight, _player, _observers, +_previous];
    } forEach BATTLESPACE_CONTACT_MEMORY;
    _rows
};

BATTLESPACE_ZEN_COVERAGE_REQUEST = {
    params [["_action", "", [""]], ["_position", [], [[]]]];
    if (!isServer || {!isRemoteExecuted}) exitWith {};
    if !(_action in ["COVERAGE", "CONTACTS", "INSPECT_COVERAGE", "INSPECT_CONTACT"]) exitWith {};
    private _owner = remoteExecutedOwner;
    private _caller = (allPlayers select {owner _x == _owner}) param [0, objNull];
    if (isNull _caller || {isNull getAssignedCuratorLogic _caller}) exitWith {};
    if !((count _position) in [2, 3] && {_position findIf {!(_x isEqualType 0) || {!finite _x}} < 0}) exitWith {};
    private _key = "BATTLESPACE_ZEN_REQUEST_" + _action;
    if (CBA_missionTime - (_caller getVariable [_key, -10]) < 2) exitWith {};
    _caller setVariable [_key, CBA_missionTime];
    private _contacts = _action in ["CONTACTS", "INSPECT_CONTACT"];
    private _payload = if (_contacts) then {[] call BATTLESPACE_ZEN_BUILD_CONTACTS} else {[] call BATTLESPACE_ZEN_BUILD_COVERAGE};
    if (_action in ["INSPECT_COVERAGE", "INSPECT_CONTACT"]) then {
        private _rows = if (_contacts) then {_payload} else {_payload select 1};
        private _positionIndex = [2, 1] select _contacts;
        _rows = [_rows, [], {(_x select _positionIndex) distance2D _position}, "ASCEND"] call BIS_fnc_sortBy;
        private _nearest = _rows param [0, []];
        if (_nearest isNotEqualTo [] && {(_nearest select _positionIndex) distance2D _position > 1500}) then {_nearest = []};
        _payload = if (_contacts) then {[_nearest, CBA_missionTime]} else {[_payload select 0, _nearest]};
    };
    [_action, _payload] remoteExecCall ["BATTLESPACE_ZEN_COVERAGE_RECEIVE", _owner];
};
