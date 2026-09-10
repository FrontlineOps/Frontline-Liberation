/* Six four-pallet bays, grouped by resource, alongside an eight-metre lane.
   Pure layout data shared by the planner, spawner and native placement checks. */
params ["_center", "_direction", ["_approach", 20], ["_bays", []]];
private _slots = [];
if !(_bays isEqualTo []) exitWith {
    {
        _x params ["_bayCenter", "_bayDirection", "_resource", "", ["_indoor", false]];
        {
            _x params ["_across", "_along"];
            private _position = (_bayCenter getPos [_across, _bayDirection + 90]) getPos [_along, _bayDirection];
            _position set [2, if (_indoor) then {(_bayCenter select 2) + getTerrainHeightASL _bayCenter - getTerrainHeightASL _position} else {0}];
            _slots pushBack [_position, _resource, _bayDirection, if (_indoor) then {[0, 0, 1]} else {surfaceNormal _position}];
        } forEach [[-1.3, -1.3], [1.3, -1.3], [-1.3, 1.3], [1.3, 1.3]];
    } forEach _bays;
    _slots
};
{
    _x params ["_side", "_along", "_resource"];
    {
        _x params ["_across", "_forward"];
        private _position = _center getPos [(_side * (5.6 + _across)), _direction + 90];
        _position = _position getPos [_along + _forward, _direction];
        _position set [2, 0];
        _slots pushBack [_position, _resource];
    } forEach [[0, -1.3], [2.6, -1.3], [0, 1.3], [2.6, 1.3]];
} forEach [[-1, -6.2, 0], [-1, 0, 0], [-1, 6.2, 0], [1, -6.2, 1], [1, 0, 1], [1, 6.2, 2]];
_slots
