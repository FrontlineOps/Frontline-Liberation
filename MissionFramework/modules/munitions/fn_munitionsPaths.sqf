/* Allocate full observed flights. Reduced detail spans the entire flight;
   it never selects only the tail. UI-only v1 telemetry, never damage. */
params ["_shots", ["_geometry", []], ["_limit", 128]];
_limit = floor (_limit max 128 min 4096);
private _groups = [[],[],[],[]];
private _potential = 0;
private _undersampled = 0;
private _decimated = 0;
private _captured = [0,0,0];
{
    private _kind = _x getOrDefault ["kind", "PROJECTILE"];
    private _category = (["PROJECTILE","CHILD","FRAGMENT"] find _kind) max 0;
    _captured set [_category, 1 + (_captured select _category)];
    private _points = _x get "points";
    _decimated = _decimated + (_x getOrDefault ["pointOmissions", 0]);
    if (count _points < 2) then {
        _undersampled = _undersampled + 1;
    } else {
        private _label = format ["%1 #%2 %3", _kind, _x get "id", _x get "ammo"];
        if ((_x getOrDefault ["historyBurst", -1]) >= 0) then {
            _label = _label + format [" | burst #%1", _x get "historyBurst"];
        };
        _label = _label + ([" | last observed", " | ended"] select (_x getOrDefault ["ended", false]));
        (_groups select _category) pushBack [_points, _x getOrDefault ["anchors", []], _kind, _label select [0,128], 0, _x];
        _potential = _potential + count _points - 1;
    };
} forEach _shots;
{
    (_groups select 3) pushBack [[_x select 0,_x select 1],[],"GEOMETRY",format ["GEOMETRY #%1: sampled connection", _forEachIndex],0,createHashMap];
    _potential = _potential + 1;
} forEach (_geometry select [0,96]);
private _traces = [];
private _largest = 0;
{_largest = _largest max count _x} forEach _groups;
for "_i" from 0 to (_largest - 1) do {
    {if (_i < count _x) then {_traces pushBack (_x select _i)}} forEach _groups;
};
private _remaining = _limit;
private _share = floor (_limit / ((count _traces) max 1)) max 1;
{
    private _quota = _share min (count (_x select 0) - 1) min _remaining;
    _x set [4, _quota];
    _remaining = _remaining - _quota;
} forEach _traces;
// Redistribute unused capacity after every trace has had its fair first share.
{
    if (_remaining <= 0) exitWith {};
    private _extra = (count (_x select 0) - 1 - (_x select 4)) min _remaining;
    _x set [4, (_x select 4) + _extra];
    _remaining = _remaining - _extra;
} forEach _traces;
private _lines = [];
private _tags = [];
{
    _x params ["_points", "_anchors", "_kind", "_label", "_quota", "_shot"];
    if (_quota == 0) then {continue};
    private _key = [_shot getOrDefault ["pointVersion", -1], count _points, _quota];
    private _cache = _shot getOrDefault ["pathCache", []];
    if (_cache isNotEqualTo [] && {(_cache select 0) isEqualTo _key}) then {
        _lines append (_cache select 1);
        {_tags pushBack [_kind, _label]} forEach (_cache select 1);
        continue;
    };
    private _last = count _points - 1;
    private _indices = [0, _last];
    {
        if (count _indices >= _quota + 1) exitWith {};
        if (_x > 0 && {_x < _last}) then {_indices pushBackUnique _x};
    } forEach _anchors;
    // Distribute timed samples over the full flight after contact anchors.
    for "_i" from 1 to (_quota - 1) do {
        if (count _indices >= _quota + 1) exitWith {};
        _indices pushBackUnique round (_i * _last / _quota);
    };
    // Fill any holes caused by anchors overlapping the regular sample grid.
    for "_i" from 1 to (_last - 1) do {
        if (count _indices >= _quota + 1) exitWith {};
        _indices pushBackUnique _i;
    };
    _indices sort true;
    private _path = [];
    for "_i" from 1 to (count _indices - 1) do {
        _path pushBack [_points select (_indices select (_i - 1)), _points select (_indices select _i)];
        _tags pushBack [_kind, _label];
    };
    _shot set ["pathCache", [_key, _path]];
    _lines append _path;
} forEach _traces;
private _stats = +(localNamespace getVariable ["KPLIB_munitionsCaptureMetrics", [0,0,0,0,0]]);
_stats append _captured;
_stats append [_undersampled,_decimated,_potential,count _lines,(_potential - count _lines) max 0];
[_lines, [1,_tags,_stats]]
