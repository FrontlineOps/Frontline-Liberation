/* One explicit conservative finite-volume step. Rusanov Euler flux and CFL
   control; ideal-gas energy evolves with pressure work, not a visual envelope.
   Boundary ledger is signed flux leaving the domain. Wall momentum transfers
   to its support, while wall mass and energy fluxes vanish.
   A failed step changes no conserved state/time/impulse; caller may retry at a
   smaller maximum dt. Failure is reported, never hidden by clipping energy. */
if (isRemoteExecuted) exitWith {[false, 0]};
params ["_domain", "_maxDt", ["_cfl", 0.4]];
if (count _domain == 0 || {!finite _maxDt} || {_maxDt <= 0} || {!finite _cfl} || {_cfl <= 0} || {_cfl > 0.5}) exitWith {[false, 0]};
private _cells = _domain get "cells";
private _gamma = _domain get "gamma";
private _dx = _domain get "spacing";
private _primitives = [];
private _maxSpeed = 0;
private _valid = true;
{
    private _w = [_x, _gamma] call KPLIB_fnc_gasPrimitive;
    if (_w isEqualTo []) exitWith {_valid = false};
    _primitives pushBack _w;
    _maxSpeed = _maxSpeed max (abs (_w select 1) + abs (_w select 2) + abs (_w select 3) + 3 * (_w select 5));
} forEach _cells;
if (!_valid) exitWith {_domain set ["error", "Invalid input state"]; [false, 0]};
private _dt = _maxDt min (_cfl * _dx / _maxSpeed);
private _factor = _dt / _dx;
private _delta = _cells apply {[0,0,0,0,0,0]};
private _boundary = [0,0,0,0,0,0];
private _ambient = _domain get "ambient";
private _wa = [_ambient, _gamma] call KPLIB_fnc_gasPrimitive;
{
    _x params ["_a", "_b", "_axis", "_sign", "_mode"];
    private _left = _cells select _a;
    private _wl = _primitives select _a;
    private _right = _ambient;
    private _wr = _wa;
    if (_b >= 0) then {
        _right = _cells select _b;
        _wr = _primitives select _b;
    } else {
        if (_mode == "WALL") then {
            _right = +_left;
            _wr = +_wl;
            _right set [_axis + 1, -(_right select (_axis + 1))];
            _wr set [_axis + 1, -(_wr select (_axis + 1))];
        };
    };
    private _flux = [_left, _right, _wl, _wr, _axis, _sign] call KPLIB_fnc_gasFlux;
    private _da = _delta select _a;
    for "_i" from 0 to 5 do {
        private _change = (_flux select _i) * _factor;
        _da set [_i, (_da select _i) - _change];
        if (_b >= 0) then {
            private _db = _delta select _b;
            _db set [_i, (_db select _i) + _change];
        } else {
            _boundary set [_i, (_boundary select _i) + (_flux select _i) * _dt * _dx^2];
        };
    };
} forEach (_domain get "faces");
private _next = [];
private _nextPressure = [];
{
    private _old = _x;
    private _change = _delta select _forEachIndex;
    private _new = [];
    for "_i" from 0 to 5 do {_new pushBack ((_old select _i) + (_change select _i))};
    private _w = [_new, _gamma] call KPLIB_fnc_gasPrimitive;
    if (_w isEqualTo []) exitWith {_valid = false};
    _next pushBack _new;
    _nextPressure pushBack (_w select 4);
} forEach _cells;
if (!_valid) exitWith {_domain set ["error", "Inadmissible trial state; reduce timestep"]; [false, _dt]};
private _impulse = _domain get "impulse";
private _signed = _domain get "signedImpulse";
private _peak = _domain get "peak";
private _p0 = _domain get "ambientPressure";
{
    private _oldP = ((_primitives select _forEachIndex) select 4) - _p0;
    private _newP = _x - _p0;
    _peak set [_forEachIndex, (_peak select _forEachIndex) max _oldP max _newP];
    _signed set [_forEachIndex, (_signed select _forEachIndex) + 0.5 * (_oldP + _newP) * _dt];
    // Integrate the positive part of the linear segment exactly at a crossing.
    private _area = 0;
    if (_oldP > 0 && {_newP > 0}) then {
        _area = 0.5 * (_oldP + _newP) * _dt;
    } else {
        if (_oldP > 0 || {_newP > 0}) then {
            private _positive = _oldP max _newP;
            _area = 0.5 * _positive^2 / (abs (_newP - _oldP)) * _dt;
        };
    };
    _impulse set [_forEachIndex, (_impulse select _forEachIndex) + _area];
} forEach _nextPressure;
private _transfer = _domain get "boundaryTransfer";
for "_i" from 0 to 5 do {_transfer set [_i, (_transfer select _i) + (_boundary select _i)]};
_domain set ["cells", _next];
_domain set ["time", (_domain get "time") + _dt];
_domain set ["steps", 1 + (_domain get "steps")];
_domain set ["error", ""];
[true, _dt]
