/* Secondary structural debris uses native collision projectiles as proxies.
   Its bounded game budget is not a material-fracture or fragment-mass model. */
if (isRemoteExecuted) exitWith {0};
params ["_object", "_position", "_normal", "_ammo", "_count", "_speed", "_parents", "_kind", ["_burst", []], ["_surface", ""]];
if (isNull _object || {!(_object isKindOf "House" || {_object isKindOf "Building"})}
    || {!isDamageAllowed _object} || {_object getVariable ["KPLIB_pressure_ignore", false]}) exitWith {0};
if (count _position != 3 || {count _normal != 3}
    || {(_position + _normal) findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}
    || {vectorMagnitude _normal < 0.5}) exitWith {0};
_normal = vectorNormalized _normal;
// Move off the observed surface only into its exposed side, never behind it.
private _origin = _position vectorAdd (_normal vectorMultiply 0.04);
if (_origin select 2 < getTerrainHeightASL _origin) exitWith {0};
private _directions = [(_count max 1) min 16] call KPLIB_fnc_munitionsFragDirections;
_directions = _directions apply {
    if (_x vectorDotProduct _normal < 0) then {_x vectorMultiply -1} else {_x}
};
private _types = ["ACE_frag_tiny_HD", "ACE_frag_small_HD"] select {isClass (configFile >> "CfgAmmo" >> _x)};
private _admitted = [_origin, _ammo, _directions, _types, _speed, _parents, _kind, _burst] call KPLIB_fnc_munitionsEmit;
[objNull, _kind + " SURFACE", _origin, [typeOf _object, "observed surface", [_position, _surface], "normal", _normal, "admitted", _admitted, "generic native debris proxies"], _object] call KPLIB_fnc_munitionsEvent;
_admitted
