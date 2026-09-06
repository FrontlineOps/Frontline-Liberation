/* Server-local records are never accepted through public variables or client snapshots.
   Persist independently of the positional campaign save and the retired permission slot. */
private _records = createHashMap;
private _saved = profileNamespace getVariable [KPLIB_permissions_save_key, []];
if (_saved isEqualType []) then {
    {
        if !(_x isEqualType [] && {count _x == 3}) then {continue};
        _x params ["_uid", "_name", "_grants"];
        if !(_uid isEqualType "" && {_uid != ""} && {_name isEqualType ""} && {_grants isEqualType []}) then {continue};
        private _valid = _grants arrayIntersect KPLIB_PERMISSION_KEYS;
        if (_valid isNotEqualTo []) then {_records set [_uid, [_name, _valid]]};
    } forEach _saved;
};
localNamespace setVariable ["KPLIB_permissionRecords", _records];
localNamespace setVariable ["KPLIB_permissionRevision", 0];
[format ["Loaded %1 player permission records", count _records], "PERMISSIONS"] call KPLIB_fnc_log;

KPLIB_fnc_permissionCaller = {
    if (!isServer || {!isRemoteExecuted}) exitWith {objNull};
    private _sender = remoteExecutedOwner;
    (allPlayers select {isPlayer _x && {owner _x == _sender}}) param [0, objNull]
};

KPLIB_fnc_permissionRejected = {
    params ["_caller", "_reason"];
    if (isNull _caller) exitWith {};
    private _last = _caller getVariable ["KPLIB_permissionLastDenial", ["", -30]];
    if (_reason != (_last select 0) || {diag_tickTime - (_last select 1) >= 10}) then {
        _caller setVariable ["KPLIB_permissionLastDenial", [_reason, diag_tickTime]];
        [format ["Request rejected for connection %1: %2", owner _caller, _reason], "PERMISSIONS"] call KPLIB_fnc_log;
    };
    [_reason] remoteExecCall ["hint", owner _caller];
};

KPLIB_fnc_permissionRequest = {
    params [["_permission", "", [""]]];
    private _caller = call KPLIB_fnc_permissionCaller;
    if (isNull _caller) exitWith {objNull};
    if (!alive _caller || {side group _caller != GRLIB_side_friendly} || {!isNull objectParent _caller}
        || {!([_caller, _permission] call KPLIB_fnc_hasPermission)}) exitWith {
        [_caller, format ["%1 is unavailable. Check your permissions and player state.", _permission]] call KPLIB_fnc_permissionRejected;
        objNull
    };
    _caller
};

KPLIB_fnc_permissionSnapshot = {
    params ["_caller", ["_includeRoster", false], ["_message", ""]];
    private _records = localNamespace getVariable ["KPLIB_permissionRecords", createHashMap];
    private _grants = +((_records getOrDefault [getPlayerUID _caller, ["", []]]) select 1);
    private _rows = [];
    if (_includeRoster && {[_caller] call KPLIB_fnc_isPermissionAdmin}) then {
        private _seen = [];
        {
            if (!isPlayer _x || {getPlayerUID _x == ""}) then {continue};
            private _uid = getPlayerUID _x;
            _seen pushBack _uid;
            _rows pushBack [_uid, name _x, +((_records getOrDefault [_uid, ["", []]]) select 1), true, [_x] call KPLIB_fnc_isPermissionAdmin];
        } forEach allPlayers;
        {
            if !(_x in _seen) then {
                private _record = _records get _x;
                _rows pushBack [_x, _record select 0, +(_record select 1), false, false];
            };
        } forEach keys _records;
    };
    [_grants, _rows, localNamespace getVariable ["KPLIB_permissionRevision", 0], _message, _includeRoster]
        remoteExecCall ["KPLIB_fnc_receivePermissions", owner _caller];
};

KPLIB_fnc_requestPermissions = {
    params [["_roster", false, [false]]];
    private _caller = call KPLIB_fnc_permissionCaller;
    if (isNull _caller) exitWith {};
    if (_roster && {!([_caller] call KPLIB_fnc_isPermissionAdmin)}) exitWith {
        [_caller, "Only a logged-in server admin can manage player permissions."] call KPLIB_fnc_permissionRejected;
    };
    [_caller, _roster] call KPLIB_fnc_permissionSnapshot;
};

KPLIB_fnc_setPlayerPermissions = {
    params [["_uid", "", [""]], ["_grants", [], [[]]], ["_revision", -1, [0]]];
    private _caller = call KPLIB_fnc_permissionCaller;
    if (isNull _caller) exitWith {};
    if !([_caller] call KPLIB_fnc_isPermissionAdmin) exitWith {
        [_caller, "Only a logged-in server admin can manage player permissions."] call KPLIB_fnc_permissionRejected;
    };
    if (canSuspend) exitWith {};
    if (_uid == "" || {count _grants > count KPLIB_PERMISSION_KEYS}
        || {(_grants findIf {!(_x in KPLIB_PERMISSION_KEYS)}) != -1}) exitWith {};
    private _currentRevision = localNamespace getVariable ["KPLIB_permissionRevision", 0];
    if (_revision != _currentRevision) exitWith {
        [_caller, true, "Permissions changed since you opened this list. Review them and apply again."] call KPLIB_fnc_permissionSnapshot;
    };
    private _records = localNamespace getVariable ["KPLIB_permissionRecords", createHashMap];
    private _target = (allPlayers select {isPlayer _x && {getPlayerUID _x == _uid}}) param [0, objNull];
    if (isNull _target && {!(_uid in _records)}) exitWith {};
    private _name = if (isNull _target) then {(_records get _uid) select 0} else {name _target};
    private _valid = _grants arrayIntersect KPLIB_PERMISSION_KEYS;
    if (_valid isEqualTo []) then {
        _records deleteAt _uid;
    } else {
        _records set [_uid, [_name, _valid]];
    };
    localNamespace setVariable ["KPLIB_permissionRevision", _currentRevision + 1];
    private _save = [];
    {
        private _record = _records get _x;
        _save pushBack [_x, _record select 0, +(_record select 1)];
    } forEach keys _records;
    profileNamespace setVariable [KPLIB_permissions_save_key, _save];
    saveProfileNamespace;
    [format ["Admin connection %1 updated player permissions: %2", owner _caller, _valid], "PERMISSIONS"] call KPLIB_fnc_log;
    if (!isNull _target) then {[_target, false, "Your permissions have been updated."] call KPLIB_fnc_permissionSnapshot};
    [_caller, true, "Permissions saved."] call KPLIB_fnc_permissionSnapshot;
};
