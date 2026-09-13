if (isRemoteExecuted || {!(localNamespace getVariable ["KPLIB_munitionsEffectsReady", false])}) exitWith {};
params [["_projectile", objNull, [objNull]]];
if (isNull _projectile || {!local _projectile} || {_projectile getVariable ["KPLIB_blastObserved", false]}) exitWith {};
if !(([typeOf _projectile] call KPLIB_fnc_blastProfile) get "eligible") exitWith {};
_projectile setVariable ["KPLIB_blastObserved", true];
private _serial = 1 + (localNamespace getVariable ["KPLIB_blastSerial", 0]);
localNamespace setVariable ["KPLIB_blastSerial", _serial];
_projectile setVariable ["KPLIB_blastSerial", _serial];
if (isServer) then {
    ["SHOT", _serial, _projectile] call KPLIB_fnc_blastRequest;
} else {
    ["SHOT", _serial, _projectile] remoteExecCall ["KPLIB_fnc_blastRequest", 2];
};
_projectile addEventHandler ["Explode", {
    params ["_projectile", "_position"];
    if (!local _projectile || {!(_projectile getShotInfo 5)}) exitWith {};
    if (CBA_missionTime < (localNamespace getVariable ["KPLIB_munitionsUntil", -1])) then {
        [_projectile] call KPLIB_fnc_munitionsTrack;
        [_projectile, "EXPLODED", _position, [_projectile getShotInfo 5, typeOf _projectile]] call KPLIB_fnc_munitionsEvent;
    };
    [_projectile, _position] call KPLIB_fnc_munitionsFrag;
    [_projectile, _position] call KPLIB_fnc_munitionsDebris;
    private _serial = _projectile getVariable ["KPLIB_blastSerial", -1];
    if (isServer) then {
        ["BURST", _serial, objNull, _position] call KPLIB_fnc_blastRequest;
    } else {
        ["BURST", _serial, objNull, _position] remoteExecCall ["KPLIB_fnc_blastRequest", 2];
    };
}];
