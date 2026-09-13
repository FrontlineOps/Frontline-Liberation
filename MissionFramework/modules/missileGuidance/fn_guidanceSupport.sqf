/* Track support is a real living sensor, with range, emission and visibility limits. */
if (isRemoteExecuted) exitWith {false};
params ["_record", "_target"];
private _carrier = _record get "carrier";
if (isNull _carrier || {!alive _carrier} || {isNull _target} || {!alive _target}) exitWith {false};
private _support = _record get "support";
private _candidates = [_carrier];
if (!isNull _support) then {_candidates pushBackUnique _support};
// Only server-owned SAM fire control shares radar support. Player missiles use their launcher.
if (isServer && {local _carrier} && {vehicleReceiveRemoteTargets _carrier}
    && {_carrier in (missionNamespace getVariable ["IADS_LaunchVehicles", []])}) then {
    {
        if (side group _x == side group _carrier && {vehicleReportRemoteTargets _x}) then {_candidates pushBackUnique _x};
    } forEach (missionNamespace getVariable ["IADS_SearchRadars", []]);
};
private _range = (_record get "profile") get "range";
private _found = objNull;
{
    if (isNull _x || {!alive _x} || {_x distance _target > _range} || {!isVehicleRadarOn _x}) then {continue};
    private _known = (getSensorTargets _x) findIf {
        (_x param [0, objNull]) isEqualTo _target && {"activeradar" in (_x param [3, []])}
    } >= 0;
    if (!_known) then {continue};
    private _from = (getPosASL _x) vectorAdd [0,0,3];
    if ([_from, aimPos _target, _x, _target] call KPLIB_fnc_guidanceVisible) exitWith {_found = _x};
} forEach _candidates;
_record set ["support", _found];
!isNull _found
