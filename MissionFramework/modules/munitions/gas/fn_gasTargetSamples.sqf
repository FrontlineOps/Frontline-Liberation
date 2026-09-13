/* Batch the same nearest-visible-centre tests used by recipient sampling.
   Every candidate still checks head, torso and feet against current geometry. */
if (!isServer || {isRemoteExecuted}) exitWith {[]};
params ["_job", "_indices"];
private _n = _job get "gasN";
private _size = _job get "gasCell";
private _rays = [];
private _rows = [];
private _positions = createHashMap;
{
    private _unit = (_job get "targets") select _x;
    if (isNull _unit || {!alive _unit}) then {continue};
    private _body = aimPos _unit;
    private _grid = ((_body vectorDiff (_job get "origin")) vectorMultiply (1 / _size)) apply {floor (_x + _n / 2)};
    if (_grid findIf {_x < 0 || {_x >= _n}} >= 0) then {
        _rows pushBack [_x, _body, _grid, -1, 0, []];
        continue;
    };
    private _candidates = [];
    private _cell = (_grid select 0) + _n * ((_grid select 1) + _n * (_grid select 2));
    {
        private _coords = _grid vectorAdd _x;
        if (_coords findIf {_x < 0 || {_x >= _n}} < 0) then {
            private _index = (_coords select 0) + _n * ((_coords select 1) + _n * (_coords select 2));
            private _point = _positions get _index;
            if (isNil "_point") then {
                _point = [_job, _index] call KPLIB_fnc_gasPosition;
                _positions set [_index, _point];
            };
            _candidates pushBack [_point distance _body, _index, _point];
        };
    } forEach [[0,0,0],[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]];
    _candidates sort true;
    private _tests = [];
    {
        private _point = _x select 2;
        private _start = -1;
        if (_point select 2 >= getTerrainHeightASL _point) then {
            _start = count _rays;
            {_rays pushBack [_point, _x, _unit]} forEach [eyePos _unit, _body, (getPosASL _unit) vectorAdd [0,0,0.35]];
        };
        _tests pushBack [_x select 1, _start];
    } forEach _candidates;
    _rows pushBack [_x, _body, _grid, _cell, 0, _tests];
} forEach (_indices select [0, 8]);
private _clear = [_rays] call KPLIB_fnc_blastClearBatch;
{
    private _row = _x;
    {
        _x params ["_cell", "_start"];
        if (_start < 0) then {continue};
        private _visible = { _x } count (_clear select [_start, 3]);
        if (_visible > 0) exitWith {
            _row set [3, _cell];
            _row set [4, _visible / 3];
        };
    } forEach (_row select 5);
    _row resize 5;
} forEach _rows;
_rows

