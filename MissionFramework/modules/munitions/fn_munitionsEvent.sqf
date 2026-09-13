/* Local event observations only; telemetry is never used to apply damage. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsUntil", -1])) exitWith {};
params ["_projectile", "_kind", "_position", ["_detail", []], ["_target", objNull]];
if (!isNull _projectile && {!local _projectile}) exitWith {};
if !(_position isEqualType [] && {count _position == 3} && {_position findIf {!(_x isEqualType 0) || {!finite _x}} < 0}) exitWith {};
if (!(localNamespace getVariable ["KPLIB_munitionsLive", false]) && {_position distance (localNamespace getVariable "KPLIB_munitionsCenter") > 750}) exitWith {};
private _events = localNamespace getVariable "KPLIB_munitionsEvents";
private _stamp = _projectile getVariable ["KPLIB_munitionsStamp", [-2, -1]];
private _id = if ((_stamp select 0) == (localNamespace getVariable "KPLIB_munitionsSession")) then {_stamp select 1} else {-1};
if (_id >= 0 && {_kind in ["HIT", "PENETRATED", "EXPLODED", "DEFLECTED", "DELETED"]}) then {
    private _shot = (localNamespace getVariable "KPLIB_munitionsShots") select _id;
    if ((_shot get "projectile") isEqualTo _projectile) then {
        if (_kind == "EXPLODED") then {
            [_shot, _position, true] call KPLIB_fnc_munitionsBurst;
        };
        [_shot, _position, true] call KPLIB_fnc_munitionsPoint;
        if (_kind == "DELETED") then {
            _shot set ["ended", true];
            _shot set ["endedAt", CBA_missionTime];
            _shot set ["terminalKind", "native deletion"];
        };
    };

};
_id = _stamp param [2, _id];
if (!isNull _target) then {
    private _targets = localNamespace getVariable "KPLIB_munitionsTargets";
    if (count _targets < 16) then {_targets pushBackUnique _target};
};
// Text saturation must never prevent recording an already tracked impact.
if (count _events >= 192) exitWith {
    private _metrics = localNamespace getVariable ["KPLIB_munitionsCaptureMetrics", [0,0,0,0,0]];
    _metrics set [4, 1 + (_metrics select 4)];
    localNamespace setVariable ["KPLIB_munitionsCaptureMetrics", _metrics];
    localNamespace setVariable ["KPLIB_munitionsDropped", 1 + (localNamespace getVariable "KPLIB_munitionsDropped")];
};
_events pushBack [CBA_missionTime, _id, _kind, +_position, (str _detail) select [0, 600]];
