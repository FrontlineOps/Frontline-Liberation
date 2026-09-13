/* Preserve creation and the newest endpoint. Decimate interior samples when
   full instead of silently losing the terminal impact after a long flight. */
if (isRemoteExecuted) exitWith {};
params ["_shot", "_position", ["_terminal", false], ["_nativePosition", false]];
// Only the owner sampler passes getPosASL directly through this fast path.
// Event/external inputs retain the complete validation below.
if (!_nativePosition && {count _position != 3 || {_position findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}}) exitWith {};
// Retry association when ProjectileCreated initially supplied no position.
if ((_shot getOrDefault ["kind", "PROJECTILE"]) == "FRAGMENT"
    && {(_shot getOrDefault ["historyBurst", -1]) < 0}) then {
    [_shot, _position] call KPLIB_fnc_munitionsBurst;
};
private _points = _shot get "points";
private _append = _points isEqualTo [] || {_position distance (_points select (count _points - 1)) > 0.01};
if (!_append && {!_terminal}) exitWith {};
private _anchors = _shot getOrDefault ["anchors", []];
private _changed = false;
if (_append) then {
    private _limit = [64,16] select ((_shot getOrDefault ["kind", "PROJECTILE"]) == "FRAGMENT");
    if (localNamespace getVariable ["KPLIB_munitionsLive", false]) then {_limit = 128};
    if (count _points >= _limit) then {
        private _reduced = [_points select 0];
        private _keptAnchors = [];
        for "_i" from 1 to ((count _points) - 2) do {
            if ((_i in _anchors || {_i mod 2 == 0}) && {count _reduced < _limit - 2}) then {
                private _index = _reduced pushBack (_points select _i);
                if (_i in _anchors) then {_keptAnchors pushBack _index};
            };
        };
        _reduced pushBack (_points select ((count _points) - 1));
        if ((count _points - 1) in _anchors) then {_keptAnchors pushBack (count _reduced - 1)};
        _shot set ["pointOmissions", (_shot getOrDefault ["pointOmissions", 0]) + count _points - count _reduced];
        _points = _reduced;
        _anchors = _keptAnchors;
        _shot set ["points", _points];
    };
    _points pushBack +_position;
    _changed = true;
};
if (_terminal) then {
    _shot set ["hasEndpoint", true];
    if (!((count _points - 1) in _anchors)) then {
        _anchors pushBack (count _points - 1);
        _changed = true;
    };
};
_shot set ["anchors", _anchors];
if (_changed) then {_shot set ["pointVersion", 1 + (_shot getOrDefault ["pointVersion", 0])]};
