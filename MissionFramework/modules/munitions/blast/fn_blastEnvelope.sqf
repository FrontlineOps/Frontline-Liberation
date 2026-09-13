/* Normalized game cloud envelope. The concentration is a visual/exposure proxy,
   not fuel mass, temperature, oxygen concentration or a combustion calculation. */
params ["_path", "_radius", "_age", "_duration", "_closed"];
private _front = _radius * ((_age / (0.4 * _duration)) max 0 min 1);
if (_path > _radius || {_path < 0}) exitWith {[_front, 0, 0, 0]};
private _arrival = 0.4 * _duration * _path / (_radius max 0.1);
private _span = (_duration - _arrival) max 0.01;
private _u = ((_age - _arrival) / _span) max 0 min 1;
private _retained = (0.25 + 0.75 * _closed) * ((1 - _path / (_radius max 0.1)) max 0)^2;
private _concentration = if (_age >= _arrival && {_age < _duration}) then {(1 - _u) * _retained} else {0};
[_front, _concentration, 6 * _u * (1 - _u) / _span * _retained, (3 * _u^2 - 2 * _u^3) * _retained]
