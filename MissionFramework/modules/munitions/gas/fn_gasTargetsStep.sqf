/* Four recipients share one native sample call and one collision-query batch.
   Finish delivery before recording replay rows from this same fluid state. */
if (!isServer || {isRemoteExecuted}) exitWith {};
params ["_job"];
private _index = _job get "targetIndex";
private _count = count (_job get "targets");
if (_index >= _count) exitWith {
    _job set ["targetIndex", 0];
    _job set ["gasNextDose", (_job get "gasTime") + 0.1];
    private _next = if (_job get "gasTime" >= (_job get "gasEnd") - 0.00001) then {"GAS_ASSETS"} else {"GAS_EVOLVE"};
    if (_job getOrDefault ["gasFramePending", false]) then {
        _job set ["gasAfterFrame", _next];
        _job set ["gasFramePending", false];
        _next = "GAS_FRAME";
    };
    _job set ["phase", _next];
};
private _indices = [];
for "_i" from _index to ((_index + 3) min (_count - 1)) do {_indices pushBack _i};
private _rows = [_job, _indices] call KPLIB_fnc_gasTargetSamples;
private _cells = [];
{if (_x select 3 >= 0) then {_cells pushBackUnique (_x select 3)}} forEach _rows;
private _samples = [];
private _ok = true;
if (_cells isNotEqualTo []) then {
    private _command = ["samples", "responseSamples"] select (_job getOrDefault ["gasReference", false]);
    private _reply = [_command, [_job get "gasHandle"] + _cells] call KPLIB_fnc_gasNative;
    _ok = _reply select 0;
    if (_ok) then {_samples = _reply select 1} else {_job set ["gasReason", _reply select 2]};
};
if (!_ok) exitWith {
    _job set ["truncated", true];
    _job set ["phase", "DONE"];
};
{
    _x params ["_recipient", "_body", "_grid", "_cell", "_fraction"];
    private _sample = if (_cell >= 0) then {_samples select (_cells find _cell)} else {[]};
    [_job, _recipient, [_body, _grid, _cell, _fraction, _sample]] call KPLIB_fnc_gasBlastDose;
} forEach _rows;
_job set ["targetIndex", _index + count _indices];
