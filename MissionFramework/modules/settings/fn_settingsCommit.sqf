/* No caller-supplied values. CBA validates admin edits and replicates requested
   settings; this server-only boundary freezes restart-required runtime values. */
if (!isServer || {isRemoteExecuted} || {isNil "_KPLIB_settingsCommitContext"}) exitWith {false};
private _rows = localNamespace getVariable ["KPLIB_settingsCatalog", []];
if (_rows isEqualTo []) exitWith {false};
// Read CBA's resolved setting store, not writable missionNamespace mirrors.
private _requested = _rows apply {[_x select 1] call CBA_settings_fnc_get};
private _check = [_requested] call KPLIB_fnc_settingsValidate;
private _values = _check select 1;
private _old = localNamespace getVariable ["KPLIB_settingsValues", []];
private _pending = [];
if (_old isNotEqualTo []) then {
    {
        if (!(_x select 4)) then {
            if ((_requested select _forEachIndex) isNotEqualTo (_old select _forEachIndex)) then {_pending pushBack (_x select 5)};
            _values set [_forEachIndex, _old select _forEachIndex];
        };
    } forEach _rows;
};
if !(_check select 0) then {
    diag_log format ["[FL SETTINGS] Invalid requested values; using validated defaults where necessary: %1", _check select 2];
};
if (_pending isNotEqualTo (localNamespace getVariable ["KPLIB_settingsPending", []])) then {
    localNamespace setVariable ["KPLIB_settingsPending", _pending];
    diag_log format ["[FL SETTINGS] %1 option(s) pending mission restart: %2", count _pending, _pending];
};
if (_values isEqualTo _old) exitWith {true};
private _revision = 1 + (localNamespace getVariable ["KPLIB_settingsRevision", -1]);
private _KPLIB_settingsApplyContext = true;
[_revision, _values] call KPLIB_fnc_settingsApply;
[_revision, _values] remoteExecCall ["KPLIB_fnc_settingsReceive", -2, "KPLIB_settingsSession"];
diag_log format ["[FL SETTINGS] Active configuration revision %1 applied (%2 controls). ZEN controls retained.", _revision, count _rows];
true
