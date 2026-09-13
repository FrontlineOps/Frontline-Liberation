params ["_unit", "_target", "_profile"];
if (!([_unit, _target] call KPLIB_fnc_vehicleCombatVisible)) exitWith {"Target obscured or no longer hostile"};
private _v = vehicle _unit;
private _from = eyePos _unit;
private _to = aimPos _target;
if (lineIntersects [_from, _to, _v, _target]) exitWith {"Solid obstruction"};
private _radius = ((_profile get "radius") * 3 + 5) max 8;
private _friends = (_target nearEntities [["CAManBase", "LandVehicle"], _radius]) select {
    alive _x && {_x != _v} && {side _x == civilian || {(side group _unit) getFriend (side _x) >= 0.6}}
};
if (_friends isNotEqualTo []) exitWith {"Friendly or civilian near impact"};
// The fire corridor's first geometry hit must be the target, never a friendly.
private _hits = lineIntersectsSurfaces [_from, _to, _v, objNull, true, 1, "FIRE", "GEOM"];
if (_hits isNotEqualTo [] && {(_hits select 0 select 2) != _target}
    && {(_hits select 0 select 3) != _target}) exitWith {"Fire corridor blocked"};
""
