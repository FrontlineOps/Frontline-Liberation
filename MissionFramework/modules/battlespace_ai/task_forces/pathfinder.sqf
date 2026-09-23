/*
    Bounded server-owned hybrid A*.

    Ground vehicles: terrain-grid connector -> road-object trunk -> terrain-grid connector.
    Infantry: terrain-grid route.
    Optional rural mode: terrain-grid route with roads costlier but still traversable.
    All-air compositions: direct route.

    One CBA worker runs queued jobs segment by segment; each grid or road segment
    is searched by the native backend (pathfinder_native.sqf), which the server
    requires. Routes are transient and drive both virtual movement and physical
    group waypoints.
*/

QUEUED_PATHFIND_REQUESTS = [];
BATTLESPACE_PATHFIND_ACTIVE_JOB = nil;
BATTLESPACE_PATHFIND_REQUEST_GENERATIONS = createHashMap;
BATTLESPACE_PATHFIND_ROUTE_CACHE = createHashMap;
BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER = [];
BATTLESPACE_PATHFIND_ROUTE_CELLS = createHashMap;
BATTLESPACE_PATHFIND_NEXT_CACHE_PRUNE = 0;

BATTLESPACE_PATHFIND_NORMALIZE_POSITION = {
    params ["_position"];
    if (
        !(_position isEqualType [])
        || {!((count _position) in [2, 3])}
        || {_position findIf {!(_x isEqualType 0)} >= 0}
    ) exitWith {[]};
    [_position select 0, _position select 1, 0]
};

BATTLESPACE_PATHFIND_ROUTE_IS_VALID = {
    params ["_route"];
    _route isEqualType []
    && {_route isNotEqualTo []}
    && {
        _route findIf {
            !(_x isEqualType [])
            || {!((count _x) in [2, 3])}
            || {_x findIf {!(_x isEqualType 0)} >= 0}
        } < 0
    }
};

BATTLESPACE_PATHFIND_GET_PROFILE = {
    params ["_taskForce", ["_useRural", false, [true]]];
    private _composition = _taskForce param [3, createHashMap];
    private _vehicles = _composition getOrDefault ["vehicles", []];
    if (_vehicles isEqualTo []) exitWith {
        ["INFANTRY", "RURAL"] select _useRural
    };

    private _groundCount = {_x isKindOf "LandVehicle" || {_x isKindOf "Ship"}} count _vehicles;
    if (_groundCount > 0) exitWith {
        ["GROUND_VEHICLE", "RURAL_VEHICLE"] select _useRural
    };
    if ({_x isKindOf "Air"} count _vehicles == count _vehicles) exitWith {"AIR"};
    ["GROUND_VEHICLE", "RURAL_VEHICLE"] select _useRural
};

BATTLESPACE_PATHFIND_GRID_INDEX = {
    params ["_position"];
    private _size = missionNamespace getVariable ["BATTLESPACE_PATHFIND_GRID_SIZE", 100];
    [floor ((_position select 0) / _size), floor ((_position select 1) / _size)]
};

BATTLESPACE_PATHFIND_GRID_KEY = {
    params ["_index"];
    format ["%1:%2", _index select 0, _index select 1]
};

BATTLESPACE_PATHFIND_BUILD_SNAPSHOTS = {
    // Supplying state and a deadline resumes a partial snapshot. One-argument
    // diagnostic callers retain the original [threats, congestion] return value.
    params ["_taskForceName", ["_state", []], ["_deadline", 1e30]];
    if (_state isEqualTo []) then {
        private _threats = [];
        {
            private _position = _x getOrDefault ["Position", []];
            if (_position isEqualTo []) then {continue};
            private _normalized = [_position] call BATTLESPACE_PATHFIND_NORMALIZE_POSITION;
            if (_normalized isEqualTo []) then {continue};
            _threats pushBack [_normalized, count (_x getOrDefault ["Players", []])];
        } forEach BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS;
        // Keep the route references from this snapshot, not a deep copy of
        // every point. Published routes are replaced, never edited in place.
        (toArray BATTLESPACE_TASK_FORCE_PATHS) params ["_ids", "_routes"];
        _state append [_ids, _routes, 0, [], createHashMap, _threats,
            missionNamespace getVariable ["BATTLESPACE_PATHFIND_GRID_SIZE", 100]];
    };
    _state params ["_ids", "_routes", "_routeIndex", "_entry", "_congestion", "_threats", "_gridSize"];

    while {_routeIndex < count _ids && {diag_tickTime < _deadline}} do {
        private _id = _ids select _routeIndex;
        private _route = _routes select _routeIndex;
        if (_id == _taskForceName || {!(_route isEqualType [])} || {_route isEqualTo []}) then {
            _routeIndex = _routeIndex + 1;
            _state set [2, _routeIndex];
            continue;
        };
        if (_entry isEqualTo []) then {
            private _cached = BATTLESPACE_PATHFIND_ROUTE_CELLS getOrDefault [_id, []];
            private _ready = count _cached == 3
                && {(_cached select 0) isEqualRef _route}
                && {(_cached select 1) == _gridSize};
            _entry = [if (_ready) then {_cached select 2} else {createHashMap}, 0, _ready];
            _state set [3, _entry];
        };
        _entry params ["_cells", "_cursor", "_ready"];
        if (!_ready) then {
            // Validate and project each changed route once. Do not add any
            // of its cells to the snapshot until the entire route is valid.
            while {_cursor < count _route && {diag_tickTime < _deadline}} do {
                private _position = [_route select _cursor] call BATTLESPACE_PATHFIND_NORMALIZE_POSITION;
                _cursor = _cursor + 1;
                if (_position isEqualTo []) exitWith {
                    _cells = createHashMap;
                    _cursor = count _route;
                };
                private _key = format ["%1:%2", floor ((_position select 0) / _gridSize), floor ((_position select 1) / _gridSize)];
                _cells set [_key, true];
            };
            _entry set [0, _cells];
            _entry set [1, _cursor];
            if (_cursor >= count _route) then {
                _cells = keys _cells;
                BATTLESPACE_PATHFIND_ROUTE_CELLS set [_id, [_route, _gridSize, _cells]];
                _cursor = 0;
                _entry set [0, _cells];
                _entry set [1, 0];
                _entry set [2, true];
            };
        };
        if !(_entry select 2) exitWith {};
        // Reuse compact cell keys, with a cursor so even a cold/large snapshot
        // cannot monopolize a callback. Excluding self still preserves overlaps.
        while {_cursor < count _cells && {diag_tickTime < _deadline}} do {
            _congestion set [_cells select _cursor, true];
            _cursor = _cursor + 1;
        };
        _entry set [1, _cursor];
        if (_cursor < count _cells) exitWith {};
        _routeIndex = _routeIndex + 1;
        _state set [2, _routeIndex];
        _entry = [];
        _state set [3, _entry];
    };
    if (_routeIndex < count _ids) exitWith {[]};
    [_threats, _congestion]
};

BATTLESPACE_PATHFIND_CACHE_KEY = {
    params ["_origin", "_destination", "_profile"];
    private _start = [_origin] call BATTLESPACE_PATHFIND_GRID_INDEX;
    private _goal = [_destination] call BATTLESPACE_PATHFIND_GRID_INDEX;
    format ["%1:%2:%3:%4:%5", _profile, _start select 0, _start select 1, _goal select 0, _goal select 1]
};

BATTLESPACE_PATHFIND_GET_CACHED_ROUTE = {
    params ["_cacheKey", "_origin", "_destination"];
    private _entry = BATTLESPACE_PATHFIND_ROUTE_CACHE get _cacheKey;
    if (isNil "_entry" || {!(_entry isEqualType [])} || {count _entry != 2}) exitWith {[]};
    _entry params ["_expiresAt", "_route"];
    if (
        !(_expiresAt isEqualType 0)
        || {CBA_missionTime >= _expiresAt}
        || {!([_route] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID)}
    ) exitWith {
        BATTLESPACE_PATHFIND_ROUTE_CACHE deleteAt _cacheKey;
        BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER = BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER - [_cacheKey];
        []
    };

    private _result = +_route;
    _result set [0, +_origin];
    _result set [count _result - 1, +_destination];
    _result
};

BATTLESPACE_PATHFIND_CACHE_ROUTE = {
    params ["_cacheKey", "_route"];
    if !([_route] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID) exitWith {false};
    private _ttl = missionNamespace getVariable ["BATTLESPACE_PATHFIND_CACHE_TTL", 300];
    BATTLESPACE_PATHFIND_ROUTE_CACHE set [_cacheKey, [CBA_missionTime + _ttl, +_route]];
    BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER = BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER - [_cacheKey];
    BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER pushBack _cacheKey;

    private _limit = missionNamespace getVariable ["BATTLESPACE_PATHFIND_CACHE_LIMIT", 128];
    while {count BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER > _limit} do {
        private _oldest = BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER deleteAt 0;
        BATTLESPACE_PATHFIND_ROUTE_CACHE deleteAt _oldest;
    };
    true
};

BATTLESPACE_PATHFIND_CAN_TRAVERSE_LINE = {
    params ["_from", "_to", "_profile"];
    private _distance = _from distance2D _to;
    if (_distance <= 1) exitWith {true};
    private _gridSize = missionNamespace getVariable ["BATTLESPACE_PATHFIND_GRID_SIZE", 100];
    private _steps = 1 max ceil (_distance / (_gridSize * 0.5));
    private _vehicleProfile = _profile in ["GROUND_VEHICLE", "RURAL_VEHICLE"];
    private _maxSlope = missionNamespace getVariable [
        ["BATTLESPACE_PATHFIND_INFANTRY_MAX_SLOPE", "BATTLESPACE_PATHFIND_VEHICLE_MAX_SLOPE"] select _vehicleProfile,
        [1.0, 0.45] select _vehicleProfile
    ];
    private _previous = +_from;
    private _previousHeight = getTerrainHeightASL _previous;
    private _valid = true;
    for "_i" from 1 to _steps do {
        private _factor = _i / _steps;
        private _position = [
            (_from select 0) + (((_to select 0) - (_from select 0)) * _factor),
            (_from select 1) + (((_to select 1) - (_from select 1)) * _factor),
            0
        ];
        if (surfaceIsWater _position && {!isOnRoad _position}) exitWith {_valid = false};
        private _height = getTerrainHeightASL _position;
        private _stepDistance = 1 max (_previous distance2D _position);
        if ((abs (_height - _previousHeight)) / _stepDistance > _maxSlope) exitWith {_valid = false};
        _previous = _position;
        _previousHeight = _height;
    };
    _valid
};

BATTLESPACE_PATHFIND_SMOOTH_GRID_ROUTE = {
    params ["_route", "_profile", ["_lookahead", 12]];
    if (count _route <= 2) exitWith {_route};
    private _result = [_route select 0];
    private _anchor = 0;
    private _last = count _route - 1;
    while {_anchor < _last} do {
        private _candidate = _last min (_anchor + _lookahead);
        while {
            _candidate > _anchor + 1
            && {!([_route select _anchor, _route select _candidate, _profile] call BATTLESPACE_PATHFIND_CAN_TRAVERSE_LINE)}
        } do {
            _candidate = _candidate - 1;
        };
        _result pushBack (_route select _candidate);
        _anchor = _candidate;
    };
    _result
};

BATTLESPACE_PATHFIND_REDUCE_ROAD_ROUTE = {
    params ["_route"];
    if (count _route <= 2) exitWith {_route};
    private _result = [_route select 0];
    private _anchor = _route select 0;
    private _delta = (_route select 1) vectorDiff _anchor;
    _delta set [2, 0];
    private _axis = vectorNormalized _delta;
    private _normal = [-(_axis select 1), _axis select 0, 0];
    private _previousAlong = vectorMagnitude _delta;
    for "_i" from 2 to (count _route - 1) do {
        private _point = _route select _i;
        _delta = _point vectorDiff _anchor;
        private _along = _delta vectorDotProduct _axis;
        // All omitted points stay within a 0.35 m fixed-axis corridor. The
        // resulting chord is therefore at most 0.7 m from any omitted node.
        // Monotonic projection also preserves switchbacks and U-turns.
        if (_along < _previousAlong || {_anchor distance2D _point > 60}
            || {abs (_delta vectorDotProduct _normal) > 0.35} || {_previousAlong == 0}) then {
            _anchor = _route select (_i - 1);
            _result pushBack _anchor;
            _delta = _point vectorDiff _anchor;
            _delta set [2, 0];
            _axis = vectorNormalized _delta;
            _normal = [-(_axis select 1), _axis select 0, 0];
            _previousAlong = vectorMagnitude _delta;
        } else {
            _previousAlong = _along;
        };
    };
    _result pushBack (_route select (count _route - 1));
    _result
};

BATTLESPACE_PATHFIND_APPEND_SEGMENT = {
    params ["_combined", "_segment"];
    {
        if (_combined isEqualTo [] || {(_combined select (count _combined - 1)) distance2D _x > 0.1}) then {
            _combined pushBack _x;
        };
    } forEach _segment;
};

BATTLESPACE_PATHFIND_CREATE_JOB = {
    params ["_taskForceName", "_origin", "_destination", "_generation", ["_useRural", false, [true]]];
    private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceName;
    if (isNil "_taskForce") exitWith {
        createHashMapFromArray [
            ["status", "CANCELLED"],
            ["taskForceName", _taskForceName],
            ["generation", _generation],
            ["destination", +_destination]
        ]
    };
    private _profile = [_taskForce, _useRural] call BATTLESPACE_PATHFIND_GET_PROFILE;
    if (_useRural) then {
        diag_log format [
            "[BATTLESPACE][PATH] %1 selected %2 routing from %3 to %4",
            _taskForceName,
            _profile,
            _origin,
            _destination
        ];
    };
    private _convoy = (_taskForce param [0, ""]) == "Convoy";
    private _cacheProfile = _profile + (["", ":CONVOY"] select _convoy);
    private _cacheKey = [_origin, _destination, _cacheProfile] call BATTLESPACE_PATHFIND_CACHE_KEY;
    private _cached = [_cacheKey, _origin, _destination] call BATTLESPACE_PATHFIND_GET_CACHED_ROUTE;

    private _job = createHashMapFromArray [
        ["status", ["SEARCHING", "FOUND"] select (_cached isNotEqualTo [])],
        ["taskForceName", _taskForceName],
        ["generation", _generation],
        ["origin", +_origin],
        ["destination", +_destination],
        ["profile", _profile],
        ["convoy", _convoy],
        ["cacheKey", _cacheKey],
        ["segments", []],
        ["segmentIndex", 0],
        ["combined", []],
        ["fallbackUsed", false],
        ["costContext", createHashMap],
        ["result", _cached]
    ];
    if (_cached isNotEqualTo []) exitWith {_job};
    if (_profile == "AIR") exitWith {
        _job set ["status", "FOUND"];
        _job set ["result", [+_destination]];
        _job
    };

    // Cache hits and direct AIR routes never need a congestion snapshot.
    _job set ["snapshot", []];
    private _segments = [];
    if (_profile == "GROUND_VEHICLE") then {
        private _snap = missionNamespace getVariable ["BATTLESPACE_PATHFIND_ROAD_SNAP", 900];
        private _startRoad = [_origin, _snap] call BIS_fnc_nearestRoad;
        private _endRoad = [_destination, _snap] call BIS_fnc_nearestRoad;
        if (!isNull _startRoad && {!isNull _endRoad}) then {
            _segments pushBack ["GRID", +_origin, getPos _startRoad];
            _segments pushBack ["ROAD", _startRoad, _endRoad];
            _segments pushBack ["GRID", getPos _endRoad, +_destination];
        } else {
            _segments pushBack ["GRID", +_origin, +_destination];
            _job set ["fallbackUsed", true];
        };
    } else {
        _segments pushBack ["GRID", +_origin, +_destination];
        _job set ["fallbackUsed", true];
    };
    _job set ["segments", _segments];
    _job
};

BATTLESPACE_PATHFIND_STEP_JOB = {
    params ["_job", "_deadline"];
    private _taskForceName = _job get "taskForceName";
    private _generation = _job get "generation";
    if (
        isNil {BATTLESPACE_TASK_FORCES get _taskForceName}
        || {_generation != (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_taskForceName, -1])}
    ) exitWith {
        _job set ["status", "CANCELLED"];
        "CANCELLED"
    };
    if ((_job get "status") != "SEARCHING") exitWith {_job get "status"};
    if (diag_tickTime >= _deadline) exitWith {"SEARCHING"};

    private _snapshot = _job get "snapshot";
    if (!isNil "_snapshot") then {
        private _result = [_taskForceName, _snapshot, _deadline] call BATTLESPACE_PATHFIND_BUILD_SNAPSHOTS;
        if (_result isNotEqualTo []) then {
            _job set ["costContext", createHashMapFromArray [
                ["destination", +(_job get "destination")],
                ["threats", _result select 0],
                ["congestion", _result select 1]
            ]];
            _job set ["snapshot", nil];
        };
    };
    if (!isNil {_job get "snapshot"} || {diag_tickTime >= _deadline}) exitWith {"SEARCHING"};

    private _segments = _job get "segments";
    private _segmentIndex = _job get "segmentIndex";
    if (_segmentIndex >= count _segments) exitWith {
        private _result = _job get "combined";
        if (_result isEqualTo []) then {_result = [+(_job get "destination")]};
        _result set [count _result - 1, +(_job get "destination")];
        _job set ["result", _result];
        _job set ["status", "FOUND"];
        "FOUND"
    };

    private _search = _job get "search";
    if (isNil "_search") then {
        private _segment = _segments select _segmentIndex;
        _segment params ["_kind", "_start", "_goal"];
        _search = createHashMapFromArray [["kind", _kind], ["status", "SEARCHING"], ["costContext", _job get "costContext"]];
        if (_kind == "ROAD") then {
            if (isNull _start || {isNull _goal}) exitWith {_search set ["status", "FAILED"]};
            _search set ["startKey", str _start];
            _search set ["goalKey", str _goal];
        } else {
            _search set ["startPos", +_start];
            _search set ["goalPos", +_goal];
            _search set ["profile", _job get "profile"];
        };
        _job set ["search", _search];
    };

    private _status = _search get "status";
    if (_status == "SEARCHING") then {
        _status = [_search] call BATTLESPACE_PATHFIND_NATIVE_SEARCH;
    };

    // Finish a completed segment on the next tick if searching used the slice.
    if (diag_tickTime >= _deadline) exitWith {_job get "status"};
    if (_status == "FOUND") then {
        private _segmentRoute = _search getOrDefault ["result", []];
        if ((_search get "kind") == "ROAD") then {
            _segmentRoute = [_segmentRoute] call BATTLESPACE_PATHFIND_REDUCE_ROAD_ROUTE;
        } else {
            // Trucks need intermediate terrain targets through valleys and bends;
            // a kilometre-long smoothed connector leaves all local planning to AI.
            private _lookahead = [12, 2] select (_job getOrDefault ["convoy", false]);
            _segmentRoute = [_segmentRoute, _job get "profile", _lookahead] call BATTLESPACE_PATHFIND_SMOOTH_GRID_ROUTE;
        };
        [_job get "combined", _segmentRoute] call BATTLESPACE_PATHFIND_APPEND_SEGMENT;
        _job set ["segmentIndex", _segmentIndex + 1];
        _job set ["search", nil];
        if ((_segmentIndex + 1) >= count _segments) then {
            private _result = _job get "combined";
            if (_result isEqualTo []) then {_result = [+(_job get "destination")]};
            _result set [count _result - 1, +(_job get "destination")];
            _job set ["result", _result];
            _job set ["status", "FOUND"];
        };
    };

    if (_status == "FAILED") then {
        if ((_job get "profile") == "GROUND_VEHICLE" && {!(_job get "fallbackUsed")}) then {
            _job set ["segments", [["GRID", +(_job get "origin"), +(_job get "destination")]]];
            _job set ["segmentIndex", 0];
            _job set ["search", nil];
            _job set ["combined", []];
            _job set ["fallbackUsed", true];
        } else {
            _job set ["status", "FAILED"];
        };
    };
    _job get "status"
};

QUEUE_PATHFIND_REQUEST = {
    params ["_taskForceName", "_origin", "_destination", ["_useRural", false, [true]]];
    if (!isServer) exitWith {false};
    _origin = [_origin] call BATTLESPACE_PATHFIND_NORMALIZE_POSITION;
    _destination = [_destination] call BATTLESPACE_PATHFIND_NORMALIZE_POSITION;
    if (_origin isEqualTo [] || {_destination isEqualTo []}) exitWith {
        diag_log format ["Battlespace pathfinder rejected invalid request for %1", _taskForceName];
        false
    };
    if (isNil {BATTLESPACE_TASK_FORCES get _taskForceName}) exitWith {false};

    private _alreadyQueued = false;
    if (!isNil "BATTLESPACE_PATHFIND_ACTIVE_JOB") then {
        private _activeTaskForce = BATTLESPACE_PATHFIND_ACTIVE_JOB getOrDefault ["taskForceName", ""];
        private _activeDestination = BATTLESPACE_PATHFIND_ACTIVE_JOB getOrDefault ["destination", []];
        if (
            _activeTaskForce == _taskForceName
            && {(BATTLESPACE_PATHFIND_ACTIVE_JOB getOrDefault ["generation", -1]) == (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_taskForceName, -2])}
            && {_activeDestination isNotEqualTo []}
            && {_activeDestination distance2D _destination <= 1}
        ) then {_alreadyQueued = true};
    };
    if (_alreadyQueued) exitWith {true};
    private _pendingIndex = QUEUED_PATHFIND_REQUESTS findIf {
        (_x select 0) == _taskForceName
        && {(_x select 2) distance2D _destination <= 1}
    };
    if (_pendingIndex >= 0) exitWith {true};

    private _generation = (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_taskForceName, 0]) + 1;
    BATTLESPACE_PATHFIND_REQUEST_GENERATIONS set [_taskForceName, _generation];
    QUEUED_PATHFIND_REQUESTS = QUEUED_PATHFIND_REQUESTS select {(_x select 0) != _taskForceName};
    QUEUED_PATHFIND_REQUESTS pushBack [_taskForceName, _origin, _destination, _generation, _useRural];
    true
};

FULFILL_PATHFIND_REQUESTS = {
    // Requests wait in the queue until the native backend has its terrain.
    if (!isServer || {!BATTLESPACE_PATHFIND_NATIVE_READY}) exitWith {};
    // One soft deadline shared by queue intake, snapshot building and search.
    // A native search call and route finalization may overrun it.
    private _deadline = diag_tickTime + 0.001 * (missionNamespace getVariable ["BATTLESPACE_PATHFIND_BUDGET_MS", 1]);
    if (isNil "BATTLESPACE_PATHFIND_ACTIVE_JOB") then {
        while {isNil "BATTLESPACE_PATHFIND_ACTIVE_JOB" && {QUEUED_PATHFIND_REQUESTS isNotEqualTo []} && {diag_tickTime < _deadline}} do {
            private _request = QUEUED_PATHFIND_REQUESTS deleteAt 0;
            _request params ["_taskForceName", "_origin", "_destination", "_generation", ["_useRural", false, [true]]];
            if (
                !isNil {BATTLESPACE_TASK_FORCES get _taskForceName}
                && {_generation == (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_taskForceName, -1])}
            ) then {
                BATTLESPACE_PATHFIND_ACTIVE_JOB = [_taskForceName, _origin, _destination, _generation, _useRural] call BATTLESPACE_PATHFIND_CREATE_JOB;
            };
        };
    };

    if (!isNil "BATTLESPACE_PATHFIND_ACTIVE_JOB") then {
        private _job = BATTLESPACE_PATHFIND_ACTIVE_JOB;
        private _status = [_job, _deadline] call BATTLESPACE_PATHFIND_STEP_JOB;
        if (_status in ["FOUND", "FAILED", "CANCELLED"] && {diag_tickTime < _deadline}) then {
            private _taskForceName = _job getOrDefault ["taskForceName", ""];
            private _generation = _job getOrDefault ["generation", -1];
            private _isCurrent = _taskForceName != ""
                && {_generation == (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_taskForceName, -2])}
                && {!isNil {BATTLESPACE_TASK_FORCES get _taskForceName}};
            if (_isCurrent && {_status == "FOUND"}) then {
                private _route = _job getOrDefault ["result", []];
                if ([_route] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID) then {
                    if ([_taskForceName, _route, _job getOrDefault ["profile", ""]] call BATTLESPACE_TASK_FORCE_PATH_FOUND) then {
                        [_job get "cacheKey", _route] call BATTLESPACE_PATHFIND_CACHE_ROUTE;
                    };
                } else {
                    diag_log format ["Battlespace pathfinder produced an invalid route for %1; treating the job as failed", _taskForceName];
                    [_taskForceName] call BATTLESPACE_TASK_FORCE_PATH_FAILED;
                };
            };
            if (_isCurrent && {_status == "FAILED"}) then {
                [_taskForceName] call BATTLESPACE_TASK_FORCE_PATH_FAILED;
            };
            BATTLESPACE_PATHFIND_ACTIVE_JOB = nil;
        };
    };

    if (CBA_missionTime >= BATTLESPACE_PATHFIND_NEXT_CACHE_PRUNE) then {
        BATTLESPACE_PATHFIND_NEXT_CACHE_PRUNE = CBA_missionTime + 30;
        private _expired = BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER select {
            private _entry = BATTLESPACE_PATHFIND_ROUTE_CACHE get _x;
            isNil "_entry" || {CBA_missionTime >= (_entry param [0, 0])}
        };
        {
            BATTLESPACE_PATHFIND_ROUTE_CACHE deleteAt _x;
        } forEach _expired;
        BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER = BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER - _expired;
        {
            if (isNil {BATTLESPACE_TASK_FORCE_PATHS get _x}) then {
                BATTLESPACE_PATHFIND_ROUTE_CELLS deleteAt _x;
            };
        } forEach (keys BATTLESPACE_PATHFIND_ROUTE_CELLS);
    };
};

if (isServer) then {
    [
        {call FULFILL_PATHFIND_REQUESTS},
        missionNamespace getVariable ["BATTLESPACE_PATHFIND_WORKER_INTERVAL", 0.1],
        []
    ] call CBA_fnc_addPerFrameHandler;
};
