/* Fixed sign colors with a readable floor. No per-frame normalization. */
params ["_sample", "_thermal", ["_ambient", false]];
_sample params ["_pressure", "_temperature", "_tracer"];
if (_thermal && {_tracer > 0.01} && {_temperature > 101325 / (1.2 * 287.05) + 3}) exitWith {[1,0.5,0,1]};
if (abs _pressure < 1) exitWith {if (_ambient) then {[0.7,0.75,0.8,0.55]} else {[]}};
private _alpha = 0.85 + 0.15 * ((abs _pressure / 1000) min 1);
if (_pressure > 0) then {[1,0.12,0.05,_alpha]} else {[0.05,0.65,1,_alpha]}
