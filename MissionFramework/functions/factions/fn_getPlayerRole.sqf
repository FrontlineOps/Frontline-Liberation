/* Resolve an authored slot mapping or an authenticated, persisted admin assignment. */
params [["_unit", objNull, [objNull]]];
if (isNull _unit || {side group _unit != GRLIB_side_friendly}) exitWith {["", ""]};
private _sideKey = "blufor";
if !(localNamespace getVariable ["KPLIB_manualFactions", false]) exitWith {[_sideKey, [_unit] call KPLIB_fnc_getAutomaticRole]};
private _profiles = localNamespace getVariable ["KPLIB_factionProfiles", createHashMap];
private _profile = _profiles getOrDefault [_sideKey, createHashMap];
private _role = _profile getOrDefault ["defaultRole", ""];
private _slots = _profile getOrDefault ["slots", createHashMap];
private _description = trim ((roleDescription _unit splitString "@") param [0, ""]);
// Longest whole suffix wins: "Assassin 1-1 Squad Leader@..." can map "Squad Leader".
private _bestLength = -1;
{
    private _start = count _description - count _x;
    if (_start >= 0 && {count _x > _bestLength} && {(_description select _start) == _x}
        && {_start == 0 || {(_description select [_start - 1, 1]) == " "}}) then {
        _role = _y;
        _bestLength = count _x;
    };
} forEach _slots;
private _grants = if (isServer) then {
    private _records = localNamespace getVariable ["KPLIB_permissionRecords", createHashMap];
    (_records getOrDefault [getPlayerUID _unit, ["", []]]) select 1
} else {
    if (_unit isEqualTo player) then {localNamespace getVariable ["KPLIB_permissionGrants", []]} else {[]}
};
private _prefix = "ROLE:" + _sideKey + ":";
private _roles = _profile getOrDefault ["roles", createHashMap];
{
    if ((_x find _prefix) == 0) then {
        private _candidate = _x select (count _prefix);
        if (_candidate in _roles) then {_role = _candidate};
    };
} forEach _grants;
[_sideKey, _role]
