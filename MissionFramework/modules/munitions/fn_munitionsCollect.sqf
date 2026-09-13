if (!isRemoteExecuted || {remoteExecutedOwner != 2}) exitWith {};
params [["_nonce", -1, [0]], ["_object", objNull, [objNull]]];
if (!finite _nonce) exitWith {};
// Scheduled outside the remote wrapper: pure observations may call local-only helpers.
[{
    params ["_nonce", "_object"];
    private _report = [_object] call KPLIB_fnc_munitionsReport;
    [_nonce, _report select 0, _report select 1, _report select 2] remoteExecCall ["KPLIB_fnc_munitionsDeliver", 2];
}, [_nonce, _object]] call CBA_fnc_execNextFrame;
