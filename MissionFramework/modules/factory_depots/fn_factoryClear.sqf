/* Server terrain/geometry check. A dense footprint sample also catches fences,
   walls and trees between pallet centres. Roads are allowed only in the lane.
   Returns false instead of moving a failed layout into an untested position. */
if (!isServer || {isRemoteExecuted}) exitWith {false};
params ["_center", "_direction", ["_approach", 20], ["_detail", []], ["_indoor", false]];
if (_detail isEqualType [] && {!(_detail isEqualTo [])}) exitWith {
    _detail findIf {!([_x select 0, _x select 1, _x select 3, true, _x param [4, false]] call KPLIB_fnc_factoryClear)} < 0
};
private _compact = _detail isEqualTo true;
private _clear = true;
private _referenceHeight = getTerrainHeightASL _center;
for "_along" from (-_approach) to ([12, 3] select _compact) step 2 do {
    if (!_clear) exitWith {};
    private _halfWidth = if (_compact) then {3} else {if (_along < -10) then {4} else {10}};
    for "_across" from (-_halfWidth) to _halfWidth step 2 do {
        private _position = (_center getPos [_along, _direction]) getPos [_across, _direction + 90];
        _position set [2, if (_indoor) then {(_center select 2) + _referenceHeight - getTerrainHeightASL _position} else {0}];
        if (surfaceIsWater _position || {!_indoor && {(surfaceNormal _position) select 2 < 0.985}}
            || {!_indoor && {_along >= -10} && {abs ((getTerrainHeightASL _position) - _referenceHeight) > 1.5}}) exitWith {_clear = false};
        private _base = ATLToASL _position;
        if (_indoor) then {
            private _floor = lineIntersectsSurfaces [_base vectorAdd [0, 0, 0.2], _base vectorAdd [0, 0, -0.25], objNull, objNull, true, 1, "GEOM", "NONE"];
            if (_floor isEqualTo [] || {((_floor select 0) select 1) select 2 < 0.95}) then {_clear = false};
        };
        if (!_clear) exitWith {};
        private _hits = lineIntersectsSurfaces [_base vectorAdd [0, 0, 0.15], _base vectorAdd [0, 0, [4.5, 2.2] select _compact], objNull, objNull, true, 1, "GEOM", "NONE"];
        if !(_hits isEqualTo []) exitWith {_clear = false};
        private _edge = (_position getPos [2, _direction + 90]);
        _edge set [2, if (_indoor) then {(_center select 2) + _referenceHeight - getTerrainHeightASL _edge + 0.6} else {0.6}];
        if (_across < _halfWidth && {lineIntersects [_base vectorAdd [0, 0, 0.6], ATLToASL _edge]}) exitWith {_clear = false};
        _edge = _position getPos [2, _direction];
        _edge set [2, if (_indoor) then {(_center select 2) + _referenceHeight - getTerrainHeightASL _edge + 0.6} else {0.6}];
        if (_along + 2 <= ([12, 3] select _compact) && {lineIntersects [_base vectorAdd [0, 0, 0.6], ATLToASL _edge]}) exitWith {_clear = false};
    };
};
if (!_clear) exitWith {false};
if (_indoor) exitWith {true};
// Keep pallets off roads and on level ground. isFlatEmpty's proximity filter
// uses surrounding objects' bounding spheres, rejecting clear factory yards
// beside large buildings/power equipment. Check actual pallet geometry instead.
private _slots = if (_compact) then {
    [_center, _direction, _approach, [[_center, _direction, 0, _approach]]] call KPLIB_fnc_factoryLayout
} else {[_center, _direction] call KPLIB_fnc_factoryLayout};
{
    private _position = _x select 0;
    if (isOnRoad _position || {count (_position isFlatEmpty [-1, -1, 0.10, 1.5, 0, false, objNull]) == 0}) exitWith {_clear = false};
    private _corners = [[-1.1, -1.1], [-1.1, 1.1], [1.1, 1.1], [1.1, -1.1]] apply {
        private _corner = (_position getPos [_x select 0, _direction + 90]) getPos [_x select 1, _direction];
        _corner set [2, 0];
        ATLToASL _corner
    };
    {
        private _height = _x;
        {
            private _a = (_corners select (_x select 0)) vectorAdd [0, 0, _height];
            private _b = (_corners select (_x select 1)) vectorAdd [0, 0, _height];
            if !(lineIntersectsSurfaces [_a, _b, objNull, objNull, true, 1, "GEOM", "NONE"] isEqualTo []) exitWith {_clear = false};
        } forEach [[0, 1], [1, 2], [2, 3], [3, 0], [0, 2], [1, 3]];
        if (!_clear) exitWith {};
    } forEach [0.15, 0.85, 1.7];
    if (!_clear) exitWith {};
} forEach _slots;
_clear
