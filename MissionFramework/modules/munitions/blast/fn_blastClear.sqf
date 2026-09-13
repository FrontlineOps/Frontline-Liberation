/* Air-space geometry query in ASL. Personnel do not form solid blast walls;
   vehicle/building FIRE geometry and terrain do. Dense-hit overflow is blocked. */
params ["_from", "_to", ["_ignore", objNull]];
if ((_from select 2 < 0 && {surfaceIsWater _from}) || {_to select 2 < 0 && {surfaceIsWater _to}}) exitWith {false};
if (terrainIntersectASL [_from, _to]) exitWith {false};
private _hits = lineIntersectsSurfaces [_from, _to, objNull, _ignore, true, 16, "FIRE", "NONE"];
if (count _hits >= 16) exitWith {false};
_hits findIf {
    private _object = _x select 2;
    private _parent = _x select 3;
    !(_object isKindOf "CAManBase" || {_parent isKindOf "CAManBase"})
} < 0
