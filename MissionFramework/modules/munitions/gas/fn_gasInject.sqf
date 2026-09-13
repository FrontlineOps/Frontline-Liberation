/* Set explicit physical initial/source states and account for every change.
   No conversion from Arma damage numbers or ammo labels into physical energy. */
if (isRemoteExecuted) exitWith {false};
params ["_domain", "_indices", "_primitive"];
if (count _domain == 0 || {count _primitive != 6} || {_primitive findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {false};
private _cells = _domain get "cells";
if (_indices findIf {!(_x isEqualType 0) || {_x != floor _x} || {_x < 0} || {_x >= count _cells}} >= 0) exitWith {false};
_primitive params ["_rho", "_ux", "_uy", "_uz", "_pressure", "_tracer"];
private _gamma = _domain get "gamma";
private _state = [_rho, _rho * _ux, _rho * _uy, _rho * _uz, _pressure / (_gamma - 1) + 0.5 * _rho * (_ux^2 + _uy^2 + _uz^2), _rho * _tracer];
if (([_state, _gamma] call KPLIB_fnc_gasPrimitive) isEqualTo []) exitWith {false};
private _injected = _domain get "injected";
private _volume = (_domain get "spacing")^3;
{
    private _old = _cells select _x;
    for "_i" from 0 to 5 do {
        _injected set [_i, (_injected select _i) + ((_state select _i) - (_old select _i)) * _volume];
    };
    _cells set [_x, +_state];
    private _peak = _domain get "peak";
    _peak set [_x, (_peak select _x) max (_pressure - (_domain get "ambientPressure"))];
} forEach _indices;
true
