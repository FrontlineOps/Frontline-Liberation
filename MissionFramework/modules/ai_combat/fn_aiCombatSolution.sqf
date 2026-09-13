/* Scheduled low-arc estimate from loaded config. Native projectiles remain
   authoritative. BI CfgAmmo reference: rocket drag = -0.002 * airFriction*v^2.
   At most 21 bounded integrations; no live simulation or projectile changes. */
params ["_origin", "_target", "_profile"];
if (!isServer || {isRemoteExecuted}) exitWith {[]};
private _delta = _target vectorDiff _origin;
private _distance = vectorMagnitude [_delta select 0, _delta select 1, 0];
if (_distance < 1) exitWith {[]};
private _height = _delta select 2;
private _cfg = configFile >> "CfgAmmo" >> (_profile get "ammo");
private _rocket = _profile get "kind" == "RPG";
private _sideFriction = getNumber (_cfg >> "sideAirFriction");
private _friction = getNumber (_cfg >> "airFriction");
if (_rocket) then {_friction = -0.002 * _friction};
if (getNumber (_cfg >> "artilleryLock") > 0) then {_friction = 0};
private _gravity = 9.80665 * (if (isNumber (_cfg >> "coefGravity")) then {getNumber (_cfg >> "coefGravity")} else {1});
private _thrust = if (_rocket) then {getNumber (_cfg >> "thrust")} else {0};
private _delay = getNumber (_cfg >> "initTime");
private _burn = getNumber (_cfg >> "thrustTime");
private _maximum = if (_rocket) then {getNumber (_cfg >> "maxSpeed")} else {0};
private _life = 12 min (_profile get "ttl");
if (_life <= 0) exitWith {[]};
private _simulate = {
    params ["_angle"];
    private _vx = (_profile get "speed") * cos _angle;
    private _vy = (_profile get "speed") * sin _angle;
    private _x = 0;
    private _y = 0;
    private _previousX = 0;
    private _previousY = 0;
    private _time = 0;
    private _dt = 0.01;
    for "_step" from 1 to ceil (_life / _dt) do {
        _previousX = _x;
        _previousY = _y;
        private _speed = sqrt (_vx * _vx + _vy * _vy);
        private _acceleration = if (_time >= _delay && {_time < _delay + _burn}) then {_thrust} else {0};
        private _ax = _friction * _speed * _vx + _acceleration * cos _angle;
        private _ay = _friction * _speed * _vy + _acceleration * sin _angle - _gravity;
        if (_rocket) then {
            private _forward = _vx * cos _angle + _vy * sin _angle;
            private _lateral = -_vx * sin _angle + _vy * cos _angle;
            private _along = 1.2 * _friction * _forward * abs _forward + _acceleration;
            private _across = -1.2 * _sideFriction * _lateral * abs _lateral;
            _ax = _along * cos _angle - _across * sin _angle;
            _ay = _along * sin _angle + _across * cos _angle - _gravity;
        };
        _x = _x + _vx * _dt + 0.5 * _ax * _dt * _dt;
        _y = _y + _vy * _dt + 0.5 * _ay * _dt * _dt;
        _vx = _vx + _ax * _dt;
        _vy = _vy + _ay * _dt;
        if (_maximum > 0) then {
            private _newSpeed = sqrt (_vx * _vx + _vy * _vy);
            if (_newSpeed > _maximum) then {
                _vx = _vx * _maximum / _newSpeed;
                _vy = _vy * _maximum / _newSpeed;
            };
        };
        _time = _time + _dt;
        if (_x >= _distance || {_vx <= 0}) exitWith {};
    };
    if (_x < _distance) exitWith {[]};
    [_previousY + (_y - _previousY) * ((_distance - _previousX) / (0.001 max (_x - _previousX))), _time]
};
private _low = -15;
private _high = -100;
// A 45-degree shot can expire before reaching a distant target even when a
// lower arc reaches it. Find a bracket before refining the low solution.
for "_candidate" from 0 to 45 step 5 do {
    private _top = [_candidate] call _simulate;
    if (_top isNotEqualTo [] && {_top select 0 >= _height}) exitWith {_high = _candidate};
    if (_top isNotEqualTo []) then {_low = _candidate};
};
if (_high == -100) exitWith {[]};
private _angle = 0;
private _flight = 0;
for "_iteration" from 1 to 11 do {
    _angle = (_low + _high) / 2;
    private _result = [_angle] call _simulate;
    if (_result isEqualTo []) exitWith {_flight = -1};
    _flight = _result select 1;
    if (_result select 0 < _height) then {_low = _angle} else {_high = _angle};
};
if (_flight <= 0) exitWith {[]};
private _aim = _target select [0, 2];
_aim pushBack ((_origin select 2) + _distance * tan _angle);
[_aim, _angle, _flight]
