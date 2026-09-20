/* Convoy materialization and waypoint handoff use the same directed route. */
BATTLESPACE_CONVOY_ROUTE_PROJECT = {
    params ["_position", "_route", ["_firstSegment", 0]];
    private _nearest = 1e30;
    private _result = [0, 0, 0, 1e30];
    private _offset = 0;
    // The caller owns the route cursor; proximity cannot choose a future branch.
    _firstSegment = (0 max _firstSegment) min (count _route - 2);
    for "_i" from 0 to _firstSegment do {
        private _a = +(_route select _i);
        private _b = +(_route select (_i + 1));
        _a set [2, 0];
        _b set [2, 0];
        private _length = _a distance2D _b;
        if (_length > 0.1 && {_i >= _firstSegment}) then {
            private _direction = _a vectorFromTo _b;
            private _along = ((_position vectorDiff _a) vectorDotProduct _direction);
            private _bounded = (_along max 0) min _length;
            private _distance = _position distance2D (_a vectorAdd (_direction vectorMultiply _bounded));
            if (_distance < _nearest) then {
                _nearest = _distance;
                _result = [_i, _bounded, _offset + _bounded, _distance];
            };
        };
        _offset = _offset + _length;
    };
    _result
};

BATTLESPACE_CONVOY_ROUTE_POSE = {
    params ["_route", "_distance"];
    private _pose = [];
    for "_i" from 0 to (count _route - 2) do {
        private _a = +(_route select _i);
        private _b = +(_route select (_i + 1));
        _a set [2, 0];
        _b set [2, 0];
        private _length = _a distance2D _b;
        if (_length <= 0.1) then {continue};
        if (_distance <= _length || {_i == count _route - 2}) exitWith {
            _pose = [_a vectorAdd ((_a vectorFromTo _b) vectorMultiply (_distance min _length)), _a getDir _b];
        };
        _distance = _distance - _length;
    };
    _pose
};

BATTLESPACE_CONVOY_SPAWN_POSITIONS = {
    params ["_taskForceName", "_taskForce"];
    if (!isServer || {isRemoteExecuted}) exitWith {[]};
    private _route = BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_taskForceName, []];
    if (count _route < 2 || {!([_route] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID)}) exitWith {[]};
    private _classes = (_taskForce select 3) getOrDefault ["vehicles", []];
    private _position = _taskForce select 1;
    private _first = 0 max (((_taskForce param [5, []]) param [1, 0]) - 1);
    private _progress = ([_position, _route, _first] call BATTLESPACE_CONVOY_ROUTE_PROJECT) select 2;
    private _spacing = ((missionNamespace getVariable ["BATTLESPACE_CONVOY_SPACING", 30]) max 20) min 60;
    private _positions = [];
    private _behind = 0;
    {
        private _class = _x;
        private _pose = [_route, _progress - _behind] call BATTLESPACE_CONVOY_ROUTE_POSE;
        if (_pose isEqualTo []) exitWith {};
        _pose params ["_planned", "_direction"];
        private _found = [];
        // Search locally along the route; do not scatter the column around a hillside.
        for "_attempt" from 0 to 4 do {
            private _candidate = (_planned getPos [_attempt * 5, _direction + 180]) findEmptyPosition [0, 8, _class];
            if (_candidate isEqualTo [] || {surfaceIsWater _candidate}) then {continue};
            if ((surfaceNormal _candidate select 2) < 0.91) then {continue};
            if (_positions findIf {(_x select 0) distance2D _candidate < (_spacing * 0.65)} >= 0) then {continue};
            if (_candidate isNotEqualTo []) exitWith {_found = _candidate};
        };
        if (_found isEqualTo []) exitWith {};
        _positions pushBack [_found, _direction];
        _behind = _behind + (_spacing max (sizeOf _class + 8));
    } forEach _classes;
    if (count _positions != count _classes) exitWith {[]};
    _positions
};
