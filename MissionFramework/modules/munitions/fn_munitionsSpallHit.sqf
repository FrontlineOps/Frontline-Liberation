/* Native Penetrated supplies a real exit surface. No guessed penetration,
   armor-thickness solver, victim search, or behind-armor damage command. */
if (isRemoteExecuted) exitWith {};
params ["_projectile", "_object", "_surface", "_entry", "_exit", "_velocity"];
if (isNull _projectile || {!local _projectile} || {isNull _object}
    || {_object isKindOf "CAManBase"} || {!isDamageAllowed _object}
    || {_object getVariable ["KPLIB_pressure_ignore", false]}
    || {!(_projectile getVariable ["KPLIB_munitionsSpall", false])}) exitWith {};
if (count _exit != 3 || {_exit isEqualTo [0,0,0]} || {count _velocity != 3}
    || {(_exit + _velocity) findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}
    || {_exit select 2 < getTerrainHeightASL _exit}) exitWith {};
private _material = [_surface] call KPLIB_fnc_munitionsMaterial;
if !(_material in ["MASONRY", "METAL"]) exitWith {};
private _cfg = configOf _projectile;
private _smallArms = toLower getText (_cfg >> "simulation") == "shotbullet" && {getNumber (_cfg >> "hit") < 40};
private _hits = _projectile getVariable ["KPLIB_munitionsSpallHits", []];
if (count _hits >= 4 || {_hits findIf {(_x select 0) isEqualTo _object && {(_x select 1) distance _exit < 0.1}} >= 0}) exitWith {};
_hits pushBack [_object, +_exit];
_projectile setVariable ["KPLIB_munitionsSpallHits", _hits];
private _speed = vectorMagnitude _velocity;
if (_speed < 1) exitWith {};
private _forward = vectorNormalized _velocity;
private _ammo = typeOf _projectile;
// Share the allowance across layers: masonry permits one, confirmed metal three.
private _used = _projectile getVariable ["KPLIB_munitionsSmallSpallCount", 0];
private _count = if (_smallArms) then {([1, 3] select (_material == "METAL")) - _used} else {round linearConversion [0, 200, getNumber (_cfg >> "hit"), 2, 16, true]};
if (_count <= 0) exitWith {};
if (_smallArms) then {_projectile setVariable ["KPLIB_munitionsSmallSpallCount", _used + _count]};
private _directions = [_count] call KPLIB_fnc_munitionsFragDirections;
// Reflect only the RNG direction into the exit hemisphere; no target cones.
_directions = _directions apply {
    if (_x vectorDotProduct _forward < 0) then {_x vectorMultiply -1} else {_x}
};
private _types = ["ACE_frag_tiny_HD", "ACE_frag_small_HD"] select {isClass (configFile >> "CfgAmmo" >> _x)};
[_exit, _ammo, _directions, _types, (_speed * 0.3) min 300, getShotParents _projectile, "SPALL"] call KPLIB_fnc_munitionsEmit;
