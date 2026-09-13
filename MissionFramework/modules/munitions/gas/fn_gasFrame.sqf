/* UI interpolation only: never advances the simulation or creates new samples. */
params ["_frames", "_elapsed", ["_playbackSeconds", 8]];
if (_frames isEqualTo []) exitWith {[0,[]]};
private _last = (_frames select ((count _frames) - 1)) select 0;
private _time = ((((_elapsed max 0) mod (_playbackSeconds + 1)) / (_playbackSeconds max 0.001)) min 1) * _last;
private _upper = _frames findIf {(_x select 0) >= _time};
if (_upper < 0) then {_upper = (count _frames) - 1};
private _a = _frames select ((_upper - 1) max 0);
private _b = _frames select _upper;
private _mix = ((_time - (_a select 0)) / (((_b select 0) - (_a select 0)) max 0.000001)) max 0 min 1;
private _rows = [];
{
    private _before = (_a select 1) select _forEachIndex;
    private _after = _x;
    private _row = [];
    for "_i" from 0 to 3 do {_row pushBack ((_before select _i) + _mix * ((_after select _i) - (_before select _i)))};
    _rows pushBack _row;
} forEach (_b select 1);
[_time,_rows]
