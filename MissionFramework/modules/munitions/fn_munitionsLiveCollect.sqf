/* A solicited owner snapshot. Never build the expensive text report for a poll. */
if (!isRemoteExecuted || {remoteExecutedOwner != 2}) exitWith {};
params [["_session", -1, [0]], ["_sequence", -1, [0]]];
if (!finite _sequence || {_session != (localNamespace getVariable ["KPLIB_munitionsSession", -2])}
    || {!(localNamespace getVariable ["KPLIB_munitionsLive", false])}
    || {CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsUntil", -1])}) exitWith {};
private _shots = [] call KPLIB_fnc_munitionsRecent;
private _paths = [_shots] call KPLIB_fnc_munitionsLivePaths;
[_session, _sequence, _paths select 0, _paths select 1] remoteExecCall ["KPLIB_fnc_munitionsLiveDeliver", 2];
