/* Server-issued transient capture command. No JIP replay and no persistent state. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (!isRemoteExecuted && {!isServer}) exitWith {};
params [["_session", -1, [0]], ["_position", [], [[]]], ["_duration", 0, [0]], ["_live", false, [true]]];
if (!finite _session || {!finite _duration}) exitWith {};
if (_live && {_duration <= 0} && {_session != (localNamespace getVariable ["KPLIB_munitionsSession", -2])}) exitWith {};
if (!_live && {_duration > 0} && {count _position != 3 || {_position findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}}) exitWith {};
// Renew the same live capture without losing objects already in flight.
if (_live && {_duration > 0} && {localNamespace getVariable ["KPLIB_munitionsLive", false]}
    && {_session == (localNamespace getVariable ["KPLIB_munitionsSession", -2])}
    && {(localNamespace getVariable ["KPLIB_munitionsPFH", -1]) >= 0}) exitWith {
    localNamespace setVariable ["KPLIB_munitionsUntil", CBA_missionTime + (_duration min 15)];
};
localNamespace setVariable ["KPLIB_munitionsLive", _live && {_duration > 0}];
private _pfh = localNamespace getVariable ["KPLIB_munitionsPFH", -1];
if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler};
localNamespace setVariable ["KPLIB_munitionsPFH", -1];
localNamespace setVariable ["KPLIB_munitionsUntil", -1];
localNamespace setVariable ["KPLIB_munitionsBursts", []];
{
    private _projectile = _x get "projectile";
    if (!isNull _projectile) then {
        {_projectile removeEventHandler _x} forEach (_x get "handlers");
    };
} forEach (localNamespace getVariable ["KPLIB_munitionsShots", []]);
localNamespace setVariable ["KPLIB_munitionsActiveTraces", []];
localNamespace setVariable ["KPLIB_munitionsLivePathCache", []];
if (_duration <= 0) exitWith {};
localNamespace setVariable ["KPLIB_munitionsSession", _session];
localNamespace setVariable ["KPLIB_munitionsCenter", +_position];
localNamespace setVariable ["KPLIB_munitionsUntil", CBA_missionTime + (_duration min 120)];
localNamespace setVariable ["KPLIB_munitionsShots", []];
localNamespace setVariable ["KPLIB_munitionsEvents", []];
localNamespace setVariable ["KPLIB_blastTrace", []];
localNamespace setVariable ["KPLIB_blastTraceRetired", 0];
localNamespace setVariable ["KPLIB_munitionsTargets", []];
localNamespace setVariable ["KPLIB_munitionsDropped", 0];
localNamespace setVariable ["KPLIB_munitionsCaptureMetrics", [0,0,0,0,0]];
localNamespace setVariable ["KPLIB_munitionsCaptureCounts", [0,0]];
localNamespace setVariable ["KPLIB_munitionsNextShot", 0];
localNamespace setVariable ["KPLIB_munitionsEvicted", 0];
localNamespace setVariable ["KPLIB_munitionsNextBurst", 0];
localNamespace setVariable ["KPLIB_munitionsBurstEvicted", 0];
localNamespace setVariable ["KPLIB_munitionsLogAt", CBA_missionTime + 10];
localNamespace setVariable ["KPLIB_munitionsPFH", [KPLIB_fnc_munitionsTick, [0.05,0.025] select _live] call CBA_fnc_addPerFrameHandler];
