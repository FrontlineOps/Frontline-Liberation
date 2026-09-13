/* Bounded Cartesian finite-volume domain, initially uniform.
   Dimensions <= 512 cells. Spacing in m; primitive = rho kg/m3, velocity m/s,
   absolute p Pa, tracer fraction. Boundaries: xmin,xmax,ymin,ymax,zmin,zmax.
   WALL reflects normal velocity; OPEN uses the specified ambient reservoir;
   PERIODIC must be paired on an axis. Geometry is supplied separately.
   This solver has no ammo names, explosive formulations or injury thresholds. */
if (isRemoteExecuted) exitWith {createHashMap};
params ["_dimensions", "_spacing", "_primitive", ["_gamma", 1.4], ["_boundaries", ["OPEN","OPEN","OPEN","OPEN","OPEN","OPEN"]]];
if (count _dimensions != 3 || {_dimensions findIf {!(_x isEqualType 0) || {!finite _x} || {_x < 1} || {_x != floor _x}} >= 0}) exitWith {createHashMap};
if (!(_spacing isEqualType 0) || {!finite _spacing} || {_spacing <= 0} || {_gamma <= 1} || {!finite _gamma}) exitWith {createHashMap};
if (count _primitive != 6 || {_primitive findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {createHashMap};
if (count _boundaries != 6 || {_boundaries findIf {!(_x in ["OPEN", "WALL", "PERIODIC"])} >= 0}) exitWith {createHashMap};
private _paired = true;
for "_axis" from 0 to 2 do {
    if (((_boundaries select (2 * _axis)) == "PERIODIC") != ((_boundaries select (2 * _axis + 1)) == "PERIODIC")) then {_paired = false};
};
if (!_paired) exitWith {createHashMap};
_dimensions params ["_nx", "_ny", "_nz"];
private _count = _nx * _ny * _nz;
if (_count > 512) exitWith {createHashMap};
_primitive params ["_rho", "_ux", "_uy", "_uz", "_pressure", "_tracer"];
private _initial = [_rho, _rho * _ux, _rho * _uy, _rho * _uz, _pressure / (_gamma - 1) + 0.5 * _rho * (_ux^2 + _uy^2 + _uz^2), _rho * _tracer];
if (([_initial, _gamma] call KPLIB_fnc_gasPrimitive) isEqualTo []) exitWith {createHashMap};
private _cells = [];
private _faces = [];
private _impulse = [];
private _signedImpulse = [];
private _peak = [];
private _stride = [1, _nx, _nx * _ny];
for "_z" from 0 to (_nz - 1) do {
    for "_y" from 0 to (_ny - 1) do {
        for "_x" from 0 to (_nx - 1) do {
            private _index = _x + _nx * (_y + _ny * _z);
            private _coords = [_x, _y, _z];
            _cells pushBack +_initial;
            _impulse pushBack 0;
            _signedImpulse pushBack 0;
            _peak pushBack 0;
            for "_axis" from 0 to 2 do {
                private _coord = _coords select _axis;
                private _size = _dimensions select _axis;
                private _jump = _stride select _axis;
                private _mode = _boundaries select (2 * _axis + 1);
                if (_coord < _size - 1) then {
                    _faces pushBack [_index, _index + _jump, _axis, 1, "INTERIOR"];
                } else {
                    if (_mode == "PERIODIC") then {
                        _faces pushBack [_index, _index - (_size - 1) * _jump, _axis, 1, "INTERIOR"];
                    } else {
                        _faces pushBack [_index, -1, _axis, 1, _mode];
                    };
                };
                if (_coord == 0 && {(_boundaries select (2 * _axis)) != "PERIODIC"}) then {
                    _faces pushBack [_index, -1, _axis, -1, _boundaries select (2 * _axis)];
                };
            };
        };
    };
};
createHashMapFromArray [
    ["cells", _cells], ["faces", _faces], ["dimensions", +_dimensions], ["spacing", _spacing],
    ["gamma", _gamma], ["ambient", _initial], ["ambientPressure", _pressure],
    ["time", 0], ["steps", 0], ["impulse", _impulse], ["signedImpulse", _signedImpulse], ["peak", _peak],
    ["boundaryTransfer", [0,0,0,0,0,0]], ["injected", [0,0,0,0,0,0]],
    ["initialTotals", _initial apply {_x * _count * _spacing^3}], ["error", ""]
]
