/* Refine a bounded set of blocked faces using complete clear air routes.
   Each side segment is checked too: a visible offset cannot jump through a wall.
   Fractions describe sampled connectivity, not measured opening dimensions. */
if (!isServer || {isRemoteExecuted}) exitWith {};
params ["_job"];
private _edges = _job getOrDefault ["gasOpeningEdges", []];
private _cursor = _job getOrDefault ["gasOpeningCursor", 0];
if (_cursor >= count _edges) exitWith {
    _job set ["gasOpeningPasses", 1 + (_job getOrDefault ["gasOpeningPasses", 0])];
    _job set ["gasOpenConnections", {_x select 6 > 0} count _edges];
    _job set ["phase", _job getOrDefault ["gasOpeningAfter", "GAS_SEED"]];
};
private _batch = _edges select [_cursor, 4];
private _rays = [];
private _offsetSize = 0.4 * (_job get "gasCell");
{
    _x params ["", "", "_from", "_to", "_axis"];
    _rays pushBack [_from, _to];
    for "_tangent" from 0 to 2 do {
        if (_tangent == _axis) then {continue};
        {
            private _offset = [0, 0, 0];
            _offset set [_tangent, _x * _offsetSize];
            private _a = _from vectorAdd _offset;
            private _b = _to vectorAdd _offset;
            _rays append [[_from, _a], [_a, _b], [_b, _to]];
        } forEach [-1, 1];
    };
} forEach _batch;
private _clear = [_rays] call KPLIB_fnc_blastClearBatch;
{
    private _edge = _x;
    private _start = _forEachIndex * 13;
    private _open = [0, 1] select (_clear select _start);
    for "_route" from 0 to 3 do {
        if !(false in (_clear select [_start + 1 + 3 * _route, 3])) then {_open = _open + 1};
    };
    private _fraction = _open / 5;
    private _reply = ["openings", [_job get "gasHandle", _edge select 1, _fraction]] call KPLIB_fnc_gasNative;
    if !(_reply select 0) exitWith {
        _job set ["phase", "DONE"];
        _job set ["truncated", true];
        _job set ["gasReason", _reply select 2];
    };
    if (abs (_fraction - (_edge select 6)) > 0.001) then {
        _job set ["gasOpeningChanges", 1 + (_job getOrDefault ["gasOpeningChanges", 0])];
    };
    _edge set [6, _fraction];
} forEach _batch;
_job set ["gasOpeningCursor", _cursor + count _batch];
