/* Local Lax-Friedrichs (Rusanov) numerical flux for compressible Euler plus
   a passively advected tracer. Positive orientation points left -> right.
   Supply the primitive states computed once for the current time level. */
if (isRemoteExecuted) exitWith {[]};
params ["_left", "_right", "_wl", "_wr", "_axis", ["_sign", 1]];
private _normal = _axis + 1;
private _ul = (_wl select _normal) * _sign;
private _ur = (_wr select _normal) * _sign;
private _speed = (abs _ul + (_wl select 5)) max (abs _ur + (_wr select 5));
private _flux = [];
for "_i" from 0 to 5 do {
    private _fl = (_left select _i) * _ul;
    private _fr = (_right select _i) * _ur;
    if (_i == _normal) then {
        _fl = _fl + (_wl select 4) * _sign;
        _fr = _fr + (_wr select 4) * _sign;
    };
    if (_i == 4) then {
        _fl = _fl + (_wl select 4) * _ul;
        _fr = _fr + (_wr select 4) * _ur;
    };
    _flux pushBack (0.5 * (_fl + _fr - _speed * ((_right select _i) - (_left select _i))));
};
_flux
