/* Owner replies are untrusted UI telemetry, never authoritative game state. */
if (!isServer || {!isRemoteExecuted}) exitWith {};
params [["_session", -1, [0]], ["_sequence", -1, [0]], ["_lines", [], [[]]], ["_meta", [], [[]]]];
if (_session != (localNamespace getVariable ["KPLIB_munitionsLiveSession", -2])) exitWith {};
private _sender = remoteExecutedOwner;
private _pending = localNamespace getVariable ["KPLIB_munitionsLivePending", createHashMap];
private _ticket = _pending getOrDefault [_sender, [-2,-1]];
if (_sequence != (_ticket select 0) || {CBA_missionTime > (_ticket select 1)}) exitWith {};
_pending deleteAt _sender;
if (count _meta != 3 || {!([_lines, _meta, 4096] call KPLIB_fnc_munitionsPayload)}) exitWith {};
private _followers = localNamespace getVariable ["KPLIB_munitionsLiveFollowers", createHashMap];
{
    (_followers get _x) params ["_caller", "_until"];
    if (!isNull _caller && {isPlayer _caller} && {owner _caller == _x}
        && {!isNull getAssignedCuratorLogic _caller} && {CBA_missionTime < _until}) then {
        // The viewer samples its own local objects faster without a network trip.
        if (_sender != _x) then {
            [_session, _sender, _sequence, _lines, _meta] remoteExecCall ["KPLIB_fnc_munitionsLiveReceive", _x];
        };
    };
} forEach keys _followers;
