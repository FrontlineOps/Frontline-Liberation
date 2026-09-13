/* Retains the ACE-derived module's separation of guidance and servos.
   New bounded body steering preserves native motor, drag, gravity and velocity. */
if (isRemoteExecuted) exitWith {};
params ["_record", "_command", "_dt"];
private _missile = _record get "missile";
if (isNull _missile || {!local _missile} || {_dt <= 0}) exitWith {};
private _profile = _record get "profile";
private _velocity = velocity _missile;
private _speed = vectorMagnitude _velocity;
if (_speed < 1) exitWith {};
private _maxAcceleration = (_profile get "maxG") * 9.80665;
private _magnitude = vectorMagnitude _command;
if (_magnitude > _maxAcceleration) then {_command = _command vectorMultiply (_maxAcceleration / _magnitude)};
// Lift requires body/velocity slip. Native side drag converts that slip to force.
private _sideDrag = (_profile get "sideDrag") max 0.001;
private _slip = (vectorNormalized _command) vectorMultiply sqrt ((vectorMagnitude _command) / _sideDrag);
private _desired = vectorNormalized (_velocity vectorAdd _slip);
private _current = vectorDir _missile;
private _angle = acos (-1 max (1 min (_current vectorDotProduct _desired)));
private _rate = (_profile get "pitchRate") min (_profile get "yawRate");
private _turn = _angle min (_rate * _dt);
if (_angle < 0.001) exitWith {};
private _axis = vectorNormalized (_current vectorCrossProduct _desired);
if (vectorMagnitude _axis < 0.5) then {_axis = vectorUp _missile};
private _rotate = {
    params ["_vector", "_axis", "_angle"];
    (_vector vectorMultiply cos _angle)
        vectorAdd ((_axis vectorCrossProduct _vector) vectorMultiply sin _angle)
        vectorAdd (_axis vectorMultiply ((_axis vectorDotProduct _vector) * (1 - cos _angle)))
};
private _direction = [_current, _axis, _turn] call _rotate;
private _up = [vectorUp _missile, _axis, _turn] call _rotate;
_missile setVectorDirAndUp [_direction, _up];
