if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2}
    || {isNull getAssignedCuratorLogic player} || {!(uiNamespace getVariable ["KPLIB_munitionsDebug", false])}) exitWith {};
params [["_session", -1, [0]], ["_owner", -1, [0]], ["_sequence", -1, [0]], ["_lines", [], [[]]], ["_meta", [], [[]]]];
if (_session != (uiNamespace getVariable ["KPLIB_munitionsDebugSession", -2])
    || {!finite _owner} || {_owner < 2} || {_owner != floor _owner} || {!finite _sequence}
    || {count _meta != 3} || {!([_lines, _meta, 4096] call KPLIB_fnc_munitionsPayload)}) exitWith {};
private _packets = uiNamespace getVariable ["KPLIB_munitionsLivePackets", createHashMap];
private _old = _packets getOrDefault [_owner, [-1,0,[]]];
if (_sequence <= (_old select 0) || {!(_owner in _packets) && {count _packets >= 16}}) exitWith {};
_packets set [_owner, [_sequence, diag_tickTime, [_owner, _lines, _meta select 1, _meta select 2]]];
uiNamespace setVariable ["KPLIB_munitionsLivePackets", _packets];
