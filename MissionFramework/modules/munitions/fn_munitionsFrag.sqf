/* Native damage-producing explosion on its projectile owner. No networked
   projectile reference or remote position/ammo request is needed for fragments. */
if (isRemoteExecuted || {!(missionNamespace getVariable ["KPLIB_munitions_spatial_fragments", true])}) exitWith {0};
params [["_projectile", objNull, [objNull]], ["_origin", [], [[]]]];
if (isNull _projectile || {!local _projectile} || {!(_projectile getShotInfo 5)}
    || {!(_projectile getVariable ["KPLIB_blastObserved", false])}
    || {_projectile getVariable ["KPLIB_munitionsFragmented", false]}) exitWith {0};
_projectile setVariable ["KPLIB_munitionsFragmented", true];
private _ammo = typeOf _projectile;
private _profile = [_ammo] call KPLIB_fnc_munitionsFragProfile;
_profile params ["_count", "_types", "_speed", "_reason"];
if (_count < 1) exitWith {0};
[_origin, _ammo, _count, _speed, _types, getShotParents _projectile] call KPLIB_fnc_munitionsFragSpatial
