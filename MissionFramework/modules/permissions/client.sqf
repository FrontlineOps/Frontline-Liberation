KPLIB_fnc_openPermissions = {
    if !([player] call KPLIB_fnc_isPermissionAdmin) exitWith {};
    if (dialog) exitWith {};
    if !(createDialog "liberation_player_permissions") exitWith {};
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
    {
        (_display displayCtrl (110 + _forEachIndex)) cbSetChecked (_x in (_row select 2));
    } forEach KPLIB_PERMISSION_KEYS;
    (_display displayCtrl 104) ctrlSetText format ["%1%2", _row select 1, ["", " (admin: automatic access)"] select (_row select 4)];
};

KPLIB_fnc_receivePermissions = {
    if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2}) exitWith {};
    params ["_grants", "_rows", "_revision", "_message", "_roster"];
    localNamespace setVariable ["KPLIB_permissionGrants", +_grants];
    if (!isNil "KPLIB_INTEL_CLIENT_DIALOG_REFRESH") then {[] call KPLIB_INTEL_CLIENT_DIALOG_REFRESH};
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
        (_display displayCtrl 105) ctrlSetText (if (_message == "") then {"Select a player, choose permissions, then Apply."} else {_message});
    } else {
        if (_message != "") then {systemChat _message};
    };
};

KPLIB_fnc_applyPermissions = {
    private _display = findDisplay 75820;
    if (isNull _display) exitWith {};
    private _uid = _display getVariable ["selectedUID", ""];
    if (_uid == "") exitWith {};
    private _grants = [];
    {
        if (cbChecked (_display displayCtrl (110 + _forEachIndex))) then {_grants pushBack _x};
    } forEach KPLIB_PERMISSION_KEYS;
    [_uid, _grants, _display getVariable ["revision", -1]] remoteExecCall ["KPLIB_fnc_setPlayerPermissions", 2];
    (_display displayCtrl 105) ctrlSetText "Saving...";
};

KPLIB_fnc_toggleAllPermissions = {
    params ["_checked"];
    private _display = findDisplay 75820;
    if (isNull _display) exitWith {};
    {(_display displayCtrl _x) cbSetChecked _checked} forEach [110, 111, 112, 113];
};
