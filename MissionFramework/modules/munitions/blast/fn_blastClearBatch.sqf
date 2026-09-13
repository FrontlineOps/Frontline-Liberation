/* Same air-space rules as blastClear, with independent FIRE queries submitted
   together. Keep blocked terrain/water rays in their original result slots. */
params ["_rays"];
if ((productVersion select 2) < 220) exitWith {
    _rays apply {_x call KPLIB_fnc_blastClear}
};
private _clear = _rays apply {false};
private _queries = [];
private _indices = [];
{
    _x params ["_from", "_to", ["_ignore", objNull]];
    if ((_from select 2 < 0 && {surfaceIsWater _from})
        || {_to select 2 < 0 && {surfaceIsWater _to}}
        || {terrainIntersectASL [_from, _to]}) then {continue};
    _indices pushBack _forEachIndex;
    _queries pushBack [_from, _to, objNull, _ignore, true, 16, "FIRE", "NONE"];
} forEach _rays;
if (_queries isEqualTo []) exitWith {_clear};
{
    if (count _x >= 16) then {continue};
    _clear set [_indices select _forEachIndex, _x findIf {
        private _object = _x select 2;
        private _parent = _x select 3;
        !(_object isKindOf "CAManBase" || {_parent isKindOf "CAManBase"})
    } < 0];
} forEach (lineIntersectsSurfaces [_queries]);
_clear
