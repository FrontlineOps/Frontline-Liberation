/* Projectile-owner HitPart: entry-face chips and an observed contact for the
   explosion worker. Confirmed exit spall remains a separate native event. */
if (isRemoteExecuted) exitWith {};
params ["_projectile", "_object", "", "_position", "_velocity", "_normal", "", "", "_surface"];
if (isNull _projectile || {!local _projectile}
    || {!(_projectile getVariable ["KPLIB_munitionsImpactHook", false])}
    || {_projectile getVariable ["KPLIB_munitionsParticle", false]}
    || {isNull _object} || {!(_object isKindOf "House" || {_object isKindOf "Building"})}
    || {!isDamageAllowed _object} || {_object getVariable ["KPLIB_pressure_ignore", false]}) exitWith {};
if (count _position != 3 || {count _velocity != 3} || {count _normal != 3}
    || {(_position + _velocity + _normal) findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {};
private _hits = _projectile getVariable ["KPLIB_munitionsImpactHits", []];
if (count _hits >= 4 || {_hits findIf {(_x select 0) isEqualTo _object && {(_x select 1) distance _position < 0.1}} >= 0}) exitWith {};
_hits pushBack [_object, +_position];
_projectile setVariable ["KPLIB_munitionsImpactHits", _hits];
_projectile setVariable ["KPLIB_munitionsSurfaceContact", [CBA_missionTime, _object, +_position, +_normal, _surface]];
private _cfg = configOf _projectile;
// Explosive impacts get one structural-debris path from their actual detonation.
if (getNumber (_cfg >> "explosive") >= 0.5) exitWith {};
private _speed = vectorMagnitude _velocity;
if (_speed < 20) exitWith {};
private _count = round linearConversion [0, 200, getNumber (_cfg >> "hit"), 2, 4, true];
[_object, _position, _normal, typeOf _projectile, _count, (_speed * 0.1) min 80, getShotParents _projectile, "IMPACT DEBRIS", [], _surface] call KPLIB_fnc_munitionsSurfaceDebris;
