// Curator diagnostics read the authoritative assignments and shared sighting memory.
// Only compact snapshots are sent to the requesting curator; no JIP/global broadcast.
// Objective garrisons only; dead-space squads are shown on the strategic overlay's cells.
BATTLESPACE_ZEN_BUILD_COVERAGE = {
    if (!isServer || {isNil "BATTLESPACE_STRATEGIC_OPERATIONS"}) exitWith {[]};
    private _coverage = [] call BATTLESPACE_DEFENSE_READ_COVERAGE;
    private _rows = [];
    {
        if ((_y get "kind") != "OBJECTIVE") then {continue};
        ((_coverage getOrDefault [_x, [0, 0, []]]) select [0, 2]) params ["_present", "_incoming"];
        private _target = _y get "target";
        private _status = if (_present >= _target) then {"COVERED"} else {if (_incoming > 0) then {"RELIEF INCOMING"} else {(["GAP", "UNDER STRENGTH"] select (_present > 0))}};
        private _name = markerText (_y get "sector");
        if (_name == "") then {_name = _y get "sector"};
        _rows pushBack [_x, +(_y get "position"), _name, _target, _present, _incoming, _status];
    } forEach BATTLESPACE_DEFENSE_ASSIGNMENTS;
    _rows
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
        private _unconfirmed = BATTLESPACE_CONTACT_UNCONFIRMED find _class;
        if (_unconfirmed >= 0) then {_name = ["Heard gunfire", "Casualties reported", "Lost contact"] select _unconfirmed};
        if (_name == "") then {_name = _class};
        // _target is deliberately never dereferenced for its current position.
        _rows pushBack [_x, +_position, _seenAt, _name, _weight, _player, _observers, +_previous];
    } forEach BATTLESPACE_CONTACT_MEMORY;
    _rows
};

BATTLESPACE_ZEN_COVERAGE_REQUEST = {
    params [["_action", "", [""]], ["_position", [], [[]]]];
    if (!isServer || {!isRemoteExecuted}) exitWith {};
    if !(_action in ["COVERAGE", "CONTACTS", "INSPECT_CONTACT"]) exitWith {};
    private _owner = remoteExecutedOwner;
    private _caller = (allPlayers select {owner _x == _owner}) param [0, objNull];
    if (isNull _caller || {isNull getAssignedCuratorLogic _caller}) exitWith {};
    if !((count _position) in [2, 3] && {_position findIf {!(_x isEqualType 0) || {!finite _x}} < 0}) exitWith {};
    private _key = "BATTLESPACE_ZEN_REQUEST_" + _action;
    if (CBA_missionTime - (_caller getVariable [_key, -10]) < 2) exitWith {};
    _caller setVariable [_key, CBA_missionTime];
    private _contacts = _action in ["CONTACTS", "INSPECT_CONTACT"];
    private _payload = if (_contacts) then {[] call BATTLESPACE_ZEN_BUILD_CONTACTS} else {[] call BATTLESPACE_ZEN_BUILD_COVERAGE};
    if (_action == "INSPECT_CONTACT") then {
        private _rows = [_payload, [], {(_x select 1) distance2D _position}, "ASCEND"] call BIS_fnc_sortBy;
        private _nearest = _rows param [0, []];
        if (_nearest isNotEqualTo [] && {(_nearest select 1) distance2D _position > 1500}) then {_nearest = []};
        _payload = [_nearest, CBA_missionTime];
    };
    [_action, _payload] remoteExecCall ["BATTLESPACE_ZEN_COVERAGE_RECEIVE", _owner];
};
