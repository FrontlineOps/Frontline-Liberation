KPLIB_fnc_openPermissions = {
    if !([player] call KPLIB_fnc_isPermissionAdmin) exitWith {};
    if (dialog) exitWith {};
    if !(createDialog "liberation_player_permissions") exitWith {};
    private _combo = (findDisplay 75820) displayCtrl 130;
    _combo lbAdd "Role: follow slot / faction default";
    _combo lbSetData [0, ""];
    {
        private _row = _combo lbAdd (_x select 1);
        _combo lbSetData [_row, _x select 0];
    } forEach KPLIB_ROLE_OPTIONS;
    _combo ctrlEnable (KPLIB_ROLE_OPTIONS isNotEqualTo []);
    [true] remoteExecCall ["KPLIB_fnc_requestPermissions", 2];
};

KPLIB_fnc_selectPermissionPlayer = {
    private _display = findDisplay 75820;
    if (isNull _display) exitWith {};
    private _index = lbCurSel (_display displayCtrl 101);
    private _rows = _display getVariable ["rows", []];
    private _valid = _index >= 0 && {_index < count _rows};
    (_display displayCtrl 120) ctrlEnable _valid;
    (_display displayCtrl 121) ctrlEnable _valid;
    (_display displayCtrl 122) ctrlEnable _valid;
    if (!_valid) exitWith {};
    private _row = _rows select _index;
    _display setVariable ["selectedUID", _row select 0];
    _display setVariable ["draftGrants", +(_row select 2)];
    [] call KPLIB_fnc_renderPermissionOptions;
    private _role = ((_row select 2) select {(_x find "ROLE:") == 0}) param [0, ""];
    private _combo = _display displayCtrl 130;
    private _index = (KPLIB_ROLE_OPTIONS findIf {(_x select 0) == _role}) + 1;
    _combo lbSetCurSel _index;
    (_display displayCtrl 104) ctrlSetText format ["%1%2", _row select 1, ["", " (admin: automatic access)"] select (_row select 4)];
};

KPLIB_fnc_receivePermissions = {
    if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2}) exitWith {};
    params ["_grants", "_rows", "_revision", "_message", "_roster"];
    localNamespace setVariable ["KPLIB_permissionGrants", +_grants];
    localNamespace setVariable ["KPLIB_permissionsReady", true];
    [] call KPLIB_fnc_refreshRoleEquipment;
    private _display = findDisplay 75820;
    if (!isNull _display && {_roster}) then {
        private _selected = _display getVariable ["selectedUID", ""];
        _display setVariable ["rows", _rows];
        _display setVariable ["revision", _revision];
        private _list = _display displayCtrl 101;
        lbClear _list;
        {
            _list lbAdd format ["%1 (%2)", _x select 1, ["offline", "online"] select (_x select 3)];
        } forEach _rows;
        private _index = _rows findIf {(_x select 0) == _selected};
        _list lbSetCurSel (_index max 0);
        [] call KPLIB_fnc_selectPermissionPlayer;
        (_display displayCtrl 105) ctrlSetText (([_message, "Double-click permissions, choose a role, then Apply."] select (_message == "")));
    } else {
        if (_message != "") then {systemChat _message};
    };
};

KPLIB_fnc_applyPermissions = {
    private _display = findDisplay 75820;
    if (isNull _display) exitWith {};
    private _uid = _display getVariable ["selectedUID", ""];
    if (_uid == "") exitWith {};
    private _grants = (_display getVariable ["draftGrants", []]) select {(_x find "ROLE:") != 0};
    private _combo = _display displayCtrl 130;
    private _role = _combo lbData lbCurSel _combo;
    if (_role != "") then {_grants pushBack _role};
    [_uid, _grants, _display getVariable ["revision", -1]] remoteExecCall ["KPLIB_fnc_setPlayerPermissions", 2];
    (_display displayCtrl 105) ctrlSetText "Saving...";
};

KPLIB_fnc_toggleAllPermissions = {
    params ["_checked"];
    private _display = findDisplay 75820;
    if (isNull _display) exitWith {};
    _display setVariable ["draftGrants", if (_checked) then {KPLIB_PERMISSION_OPTIONS apply {_x select 0}} else {[]}];
    [] call KPLIB_fnc_renderPermissionOptions;
};

KPLIB_fnc_renderPermissionOptions = {
    private _display = findDisplay 75820;
    private _list = _display displayCtrl 110;
    private _selected = lbCurSel _list;
    private _grants = _display getVariable ["draftGrants", []];
    lbClear _list;
    {
        _list lbAdd format ["[%1] %2", [" ", "X"] select ((_x select 0) in _grants), _x select 1];
    } forEach KPLIB_PERMISSION_OPTIONS;
    _list lbSetCurSel _selected;
};

KPLIB_fnc_togglePermission = {
    private _display = findDisplay 75820;
    private _index = lbCurSel (_display displayCtrl 110);
    if (_index < 0 || {(_display getVariable ["selectedUID", ""]) == ""}) exitWith {};
    private _key = (KPLIB_PERMISSION_OPTIONS select _index) select 0;
    private _grants = _display getVariable ["draftGrants", []];
    if (_key in _grants) then {_grants = _grants - [_key]} else {_grants pushBack _key};
    _display setVariable ["draftGrants", _grants];
    [] call KPLIB_fnc_renderPermissionOptions;
};
