/* Calorically perfect ideal-gas EOS. Conserved state:
   [rho, rho*ux, rho*uy, rho*uz, total energy density, tracer mass density].
   SI primitives: [rho, ux, uy, uz, pressure, sound speed, tracer fraction].
   Empty result rejects an inadmissible state; no pressure/energy clipping.
   Equations: NASA Euler equations; Clawpack Riemann book, Euler chapter. */
if (isRemoteExecuted) exitWith {[]};
params ["_state", ["_gamma", 1.4]];
if (count _state != 6 || {_state findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {[]};
_state params ["_rho", "_mx", "_my", "_mz", "_energy", "_tracer"];
if (_rho <= 0 || {_gamma <= 1} || {!finite _gamma}) exitWith {[]};
private _ux = _mx / _rho;
private _uy = _my / _rho;
private _uz = _mz / _rho;
private _pressure = (_gamma - 1) * (_energy - 0.5 * (_mx * _ux + _my * _uy + _mz * _uz));
if (_pressure <= 0 || {!finite _pressure} || {_tracer < -0.000001 * _rho} || {_tracer > 1.000001 * _rho}) exitWith {[]};
[_rho, _ux, _uy, _uz, _pressure, sqrt (_gamma * _pressure / _rho), _tracer / _rho]
