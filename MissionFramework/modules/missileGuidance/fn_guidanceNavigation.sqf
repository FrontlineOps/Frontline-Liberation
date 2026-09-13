/* Game intercept control. Inputs/outputs are world-space SI quantities. */
params ["_position", "_velocity", "_aim", "_targetVelocity", ["_targetAcceleration", [0,0,0]], ["_gain", 3]];
private _relative = _aim vectorDiff _position;
private _range = vectorMagnitude _relative;
private _speed = vectorMagnitude _velocity;
if (_range < 0.1 || {_speed < 1}) exitWith {[0,0,0]};
private _line = _relative vectorMultiply (1 / _range);
private _difference = _targetVelocity vectorDiff _velocity;
private _closing = -(_difference vectorDotProduct _line);
private _time = (_range / (_closing max (_speed * 0.25) max 1)) max 0.1 min 30;
private _miss = _relative vectorAdd (_difference vectorMultiply _time);
private _normal = _miss vectorDiff (_line vectorMultiply (_miss vectorDotProduct _line));
private _acceleration = (_normal vectorMultiply (_gain / (_time * _time))) vectorAdd (_targetAcceleration vectorMultiply 0.5);
// A missile initially pointed away still needs an explicit course correction.
if (_closing <= 0 || {(vectorNormalized _velocity) vectorDotProduct _line < 0.5}) then {
    _acceleration = ((_line vectorMultiply _speed) vectorDiff _velocity) vectorMultiply 2;
};
private _flight = vectorNormalized _velocity;
_acceleration vectorDiff (_flight vectorMultiply (_acceleration vectorDotProduct _flight))
