/* Sparse air connectivity plus direct body samples. A closed geometric edge
   never transmits. Node count does not sum into damage: use the strongest path. */
if (isRemoteExecuted) exitWith {[0, 1e6, 0, 0, [0,0,0], [0,0,0]]};
params ["_job", "_unit", ["_radius", -1]];
private _profile = _job get "profile";
private _origin = _job get "origin";
private _body = aimPos _unit;
private _foot = getPosASL _unit;
private _samples = [eyePos _unit, _body, _foot vectorAdd [0,0,0.35]];
private _fraction = 0;
{
    if ([_origin, _x, _unit] call KPLIB_fnc_blastClear) then {_fraction = _fraction + 1 / 3};
} forEach _samples;
if (_radius < 0) then {_radius = _profile get "radius"};
private _distance = _origin distance _body;
private _best = ((1 - _distance / _radius) max 0)^2 * _fraction * (1 + 0.65 * (_job get "confinement"));
private _path = if (_fraction > 0) then {_distance} else {1e6};
private _from = _origin;
private _confined = _job get "confinement";
private _near = [];
{
    _x params ["_pos", "_cost", "_closed"];
    private _gap = _pos distance _body;
    if (_forEachIndex > 0 && {_gap < 2.5 * (_profile get "cell")} && {_cost + _gap < _radius}) then {
        _near pushBack [_cost + _gap, _forEachIndex];
    };
} forEach (_job get "nodes");
_near sort true;
{
    _x params ["_cost", "_index"];
    private _node = (_job get "nodes") select _index;
    private _pos = _node select 0;
    private _visible = 0;
    {
        if ([_pos, _x, _unit] call KPLIB_fnc_blastClear) then {_visible = _visible + 1 / 3};
    } forEach _samples;
    private _clear = _visible > 0;
    // Recheck the chosen air route: a door/vehicle can move after field creation.
    private _parent = _node select 3;
    private _cursor = _node;
    private _steps = 0;
    while {_clear && {_parent >= 0} && {_steps < 32}} do {
        private _next = (_job get "nodes") select _parent;
        _clear = [_cursor select 0, _next select 0, _unit] call KPLIB_fnc_blastClear;
        _cursor = _next;
        _parent = _cursor select 3;
        _steps = _steps + 1;
    };
    if (_clear && {_parent < 0}) then {
        private _value = ((1 - _cost / _radius) max 0)^2 * _visible * (1 + 0.65 * (_node select 2));
        if (_value > _best) then {
            _best = _value;
            _from = _pos;
            _confined = _node select 2;
        };
        _path = _path min _cost;
    };
} forEach (_near select [0, 8]);
private _pressure = ((_profile get "strength") * _best) min 24;
[_pressure, _path, _fraction, _confined, _from, _body]
