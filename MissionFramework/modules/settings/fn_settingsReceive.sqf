/* Reject client-originated or replayed snapshots. JIP receives the active
   server session, including settings edited for the next mission only. */
if (isServer || {!isRemoteExecuted} || {remoteExecutedOwner != 2}) exitWith {false};
params [["_revision", -1, [0]], ["_values", [], [[]]]];
if (!finite _revision || {_revision != floor _revision}
    || {_revision <= (localNamespace getVariable ["KPLIB_settingsRevision", -1])}) exitWith {false};
private _check = [_values] call KPLIB_fnc_settingsValidate;
if !(_check select 0) exitWith {
    diag_log format ["[FL SETTINGS] Server configuration rejected by local schema: %1", _check select 2];
    false
};
// Remote execution context is inherited by call; defer to a local CBA callback.
[{
    private _KPLIB_settingsApplyContext = true;
    _this call KPLIB_fnc_settingsApply;
}, [_revision, _check select 1]] call CBA_fnc_execNextFrame;
true
