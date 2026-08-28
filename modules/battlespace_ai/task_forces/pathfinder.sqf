/*
    Bounded server-owned hybrid A*.

    Ground vehicles: terrain-grid connector -> road-object trunk -> terrain-grid connector.
    Infantry: terrain-grid route.
    All-air compositions: direct route.

    Searches share the binary heap from networked_sectors/priority_queue.sqf and
    are expanded incrementally by one CBA worker. Routes are transient and drive
    both virtual movement and physical group waypoints.
*/

QUEUED_PATHFIND_REQUESTS = [];
BATTLESPACE_PATHFIND_ACTIVE_JOB = nil;
BATTLESPACE_PATHFIND_REQUEST_GENERATIONS = createHashMap;
BATTLESPACE_PATHFIND_ROUTE_CACHE = createHashMap;
BATTLESPACE_PATHFIND_ROUTE_CACHE_ORDER = [];
BATTLESPACE_PATHFIND_TERRAIN_CACHE = createHashMap;
if (isNil "BATTLESPACE_PATHFIND_ROAD_NEIGHBOR_CACHE") then {
    BATTLESPACE_PATHFIND_ROAD_NEIGHBOR_CACHE = createHashMap;
};
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
    params ["_taskForce"];
    private _composition = _taskForce param [3, createHashMap];
    private _vehicles = _composition getOrDefault ["vehicles", []];
    if (_vehicles isEqualTo []) exitWith {"INFANTRY"};

    private _groundCount = {_x isKindOf "LandVehicle" || {_x isKindOf "Ship"}} count _vehicles;
    if (_groundCount > 0) exitWith {"GROUND_VEHICLE"};
    if ({_x isKindOf "Air"} count _vehicles == count _vehicles) exitWith {"AIR"};
    "GROUND_VEHICLE"
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

BATTLESPACE_PATHFIND_GET_TERRAIN_NODE = {
    params ["_index"];
    private _key = [_index] call BATTLESPACE_PATHFIND_GRID_KEY;
    private _cached = BATTLESPACE_PATHFIND_TERRAIN_CACHE get _key;
    if (!isNil "_cached") exitWith {_cached};

    private _size = missionNamespace getVariable ["BATTLESPACE_PATHFIND_GRID_SIZE", 100];
    private _position = [
        ((_index select 0) + 0.5) * _size,
        ((_index select 1) + 0.5) * _size,
        0
    ];
    private _valid = (_position select 0) >= 0
        && {(_position select 1) >= 0}
        && {(_position select 0) <= worldSize}
        && {(_position select 1) <= worldSize};
    private _height = if (_valid) then {getTerrainHeightASL _position} else {0};
    private _water = _valid && {surfaceIsWater _position};
    private _road = _valid && {isOnRoad _position};
    private _node = [_position, _height, _water, _road, _valid];

    private _limit = missionNamespace getVariable ["BATTLESPACE_PATHFIND_TERRAIN_CACHE_LIMIT", 24000];
    if (count BATTLESPACE_PATHFIND_TERRAIN_CACHE < _limit) then {
        BATTLESPACE_PATHFIND_TERRAIN_CACHE set [_key, _node];
    };
    _node
};

BATTLESPACE_PATHFIND_GET_DYNAMIC_MULTIPLIER = {
    params ["_context", "_nodeKey", "_position"];
    private _multiplier = 1;
    private _destination = _context get "destination";
    private _approachRadius = missionNamespace getVariable ["BATTLESPACE_PATHFIND_FINAL_APPROACH_RADIUS", 600];
    private _distanceToDestination = _position distance2D _destination;
    private _approachFactor = if (_approachRadius <= 0) then {1} else {
        1 min (_distanceToDestination / _approachRadius)
    };

    if (_approachFactor > 0) then {
        private _threatRadius = missionNamespace getVariable ["BATTLESPACE_PATHFIND_THREAT_RADIUS", 1600];
        {
            _x params ["_threatPosition", "_strength"];
            private _distance = _position distance2D _threatPosition;
            if (_distance < _threatRadius) then {
                private _strengthFactor = 0.2 min (0.04 * _strength);
                _multiplier = _multiplier
                    + ((1 - (_distance / _threatRadius)) * (0.15 + _strengthFactor) * _approachFactor);
            };
        } forEach (_context getOrDefault ["threats", []]);

        if (!isNil {(_context get "congestion") get _nodeKey}) then {
            private _congestionMultiplier = 1 max (
                missionNamespace getVariable ["BATTLESPACE_PATHFIND_CONGESTION_MULTIPLIER", 1.2]
            );
            _multiplier = _multiplier * (1 + ((_congestionMultiplier - 1) * _approachFactor));
        };
    };
    _multiplier
};

BATTLESPACE_PATHFIND_BUILD_SNAPSHOTS = {
    params ["_taskForceName"];
    private _threats = [];
    {
        private _position = _x getOrDefault ["Position", []];
        if (_position isEqualTo []) then {continue};
        private _normalized = [_position] call BATTLESPACE_PATHFIND_NORMALIZE_POSITION;
        if (_normalized isEqualTo []) then {continue};
        _threats pushBack [
            _normalized,
            count (_x getOrDefault ["Players", []])
        ];
    } forEach BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS;

    private _congestion = createHashMap;
    {
        if (_x == _taskForceName) then {continue};
        if !([_y] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID) then {continue};
        {
            private _index = [_x] call BATTLESPACE_PATHFIND_GRID_INDEX;
            _congestion set [[_index] call BATTLESPACE_PATHFIND_GRID_KEY, true];
        } forEach _y;
    } forEach BATTLESPACE_TASK_FORCE_PATHS;
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

BATTLESPACE_PATHFIND_RECONSTRUCT_GRID = {
    params ["_search"];
    private _cameFrom = _search get "cameFrom";
    private _nodes = _search get "nodes";
    private _startKey = _search get "startKey";
    private _key = _search get "goalKey";
    private _route = [];
    private _guard = 0;
    while {_key != "" && {_guard < 50000}} do {
        private _node = _nodes get _key;
        if (isNil "_node") exitWith {_route = []};
        _route pushBack +(_node select 0);
        if (_key == _startKey) exitWith {};
        _key = _cameFrom getOrDefault [_key, ""];
        _guard = _guard + 1;
    };
    if (_route isEqualTo [] || {_key != _startKey}) exitWith {[]};
    reverse _route;
    _route set [0, +(_search get "startPos")];
    _route set [count _route - 1, +(_search get "goalPos")];
    _route
};

BATTLESPACE_PATHFIND_RECONSTRUCT_ROAD = {
    params ["_search"];
    private _cameFrom = _search get "cameFrom";
    private _nodes = _search get "nodes";
    private _startKey = _search get "startKey";
    private _key = _search get "goalKey";
    private _route = [];
    private _guard = 0;
    while {_key != "" && {_guard < 100000}} do {
        private _road = _nodes get _key;
        if (isNil "_road" || {isNull _road}) exitWith {_route = []};
        _route pushBack getPos _road;
        if (_key == _startKey) exitWith {};
        _key = _cameFrom getOrDefault [_key, ""];
        _guard = _guard + 1;
    };
    if (_route isEqualTo [] || {_key != _startKey}) exitWith {[]};
    reverse _route;
    _route
};

BATTLESPACE_PATHFIND_CAN_TRAVERSE_LINE = {
    params ["_from", "_to", "_profile"];
    private _distance = _from distance2D _to;
    if (_distance <= 1) exitWith {true};
    private _gridSize = missionNamespace getVariable ["BATTLESPACE_PATHFIND_GRID_SIZE", 100];
    private _steps = 1 max ceil (_distance / (_gridSize * 0.5));
    private _maxSlope = missionNamespace getVariable [
        ["BATTLESPACE_PATHFIND_INFANTRY_MAX_SLOPE", "BATTLESPACE_PATHFIND_VEHICLE_MAX_SLOPE"] select (_profile == "GROUND_VEHICLE"),
        [1.0, 0.45] select (_profile == "GROUND_VEHICLE")
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
    params ["_route", "_profile"];
    if (count _route <= 2) exitWith {_route};
    private _result = [_route select 0];
    private _anchor = 0;
    private _last = count _route - 1;
    while {_anchor < _last} do {
        private _candidate = _last min (_anchor + 12);
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
    private _lastKept = _route select 0;
    for "_i" from 1 to (count _route - 2) do {
        private _previous = _route select (_i - 1);
        private _current = _route select _i;
        private _next = _route select (_i + 1);
        private _turn = abs ((((_previous getDir _current) - (_current getDir _next) + 540) % 360) - 180);
        if (_lastKept distance2D _current >= 250 || {_turn >= 18}) then {
            _result pushBack _current;
            _lastKept = _current;
        };
    };
    _result pushBack (_route select (count _route - 1));
    _result
};

BATTLESPACE_PATHFIND_CREATE_GRID_SEARCH = {
    params ["_startPos", "_goalPos", "_profile", "_job"];
    private _startIndex = [_startPos] call BATTLESPACE_PATHFIND_GRID_INDEX;
    private _goalIndex = [_goalPos] call BATTLESPACE_PATHFIND_GRID_INDEX;
    private _startKey = [_startIndex] call BATTLESPACE_PATHFIND_GRID_KEY;
    private _goalKey = [_goalIndex] call BATTLESPACE_PATHFIND_GRID_KEY;
    private _startNode = [_startIndex] call BATTLESPACE_PATHFIND_GET_TERRAIN_NODE;
    private _goalNode = [_goalIndex] call BATTLESPACE_PATHFIND_GET_TERRAIN_NODE;
    private _valid = (_startNode select 4) && {(_goalNode select 4)}
        && {!((_startNode select 2) && {!(_startNode select 3)})}
        && {!((_goalNode select 2) && {!(_goalNode select 3)})};
    if (!_valid) exitWith {createHashMapFromArray [["status", "FAILED"], ["kind", "GRID"]]};

    private _open = [] call NEW_PRIORITY_QUEUE;
    private _gScore = createHashMapFromArray [[_startKey, 0]];
    private _nodes = createHashMapFromArray [[_startKey, _startNode], [_goalKey, _goalNode]];
    private _heuristic = (_startNode select 0) distance2D (_goalNode select 0);
    [_open, _heuristic, [_startKey, 0]] call PRIORITY_QUEUE_ENQUEUE;

    createHashMapFromArray [
        ["kind", "GRID"],
        ["status", "SEARCHING"],
        ["startPos", +_startPos],
        ["goalPos", +_goalPos],
        ["startKey", _startKey],
        ["goalKey", _goalKey],
        ["goalNode", _goalNode],
        ["open", _open],
        ["gScore", _gScore],
        ["cameFrom", createHashMap],
        ["closed", createHashMap],
        ["nodes", _nodes],
        ["expansions", 0],
        ["profile", _profile],
        ["costContext", _job get "costContext"]
    ]
};

BATTLESPACE_PATHFIND_CREATE_ROAD_SEARCH = {
    params ["_startRoad", "_goalRoad", "_job"];
    if (isNull _startRoad || {isNull _goalRoad}) exitWith {
        createHashMapFromArray [["status", "FAILED"], ["kind", "ROAD"]]
    };

    private _startKey = str _startRoad;
    private _goalKey = str _goalRoad;
    private _open = [] call NEW_PRIORITY_QUEUE;
    private _gScore = createHashMapFromArray [[_startKey, 0]];
    private _nodes = createHashMapFromArray [[_startKey, _startRoad], [_goalKey, _goalRoad]];
    [_open, _startRoad distance2D _goalRoad, [_startKey, 0]] call PRIORITY_QUEUE_ENQUEUE;

    createHashMapFromArray [
        ["kind", "ROAD"],
        ["status", "SEARCHING"],
        ["startKey", _startKey],
        ["goalKey", _goalKey],
        ["goalRoad", _goalRoad],
        ["open", _open],
        ["gScore", _gScore],
        ["cameFrom", createHashMap],
        ["closed", createHashMap],
        ["nodes", _nodes],
        ["expansions", 0],
        ["costContext", _job get "costContext"]
    ]
};

BATTLESPACE_PATHFIND_STEP_GRID = {
    params ["_search", "_budget"];
    private _used = 0;
    private _open = _search get "open";
    private _gScore = _search get "gScore";
    private _cameFrom = _search get "cameFrom";
    private _closed = _search get "closed";
    private _nodes = _search get "nodes";
    private _goalKey = _search get "goalKey";
    private _goalPosition = (_search get "goalNode") select 0;
    private _profile = _search get "profile";
    private _costContext = _search get "costContext";
    private _weight = missionNamespace getVariable ["BATTLESPACE_PATHFIND_WEIGHT", 1.12];
    private _gridSize = missionNamespace getVariable ["BATTLESPACE_PATHFIND_GRID_SIZE", 100];
    private _maxSlope = missionNamespace getVariable [
        ["BATTLESPACE_PATHFIND_INFANTRY_MAX_SLOPE", "BATTLESPACE_PATHFIND_VEHICLE_MAX_SLOPE"] select (_profile == "GROUND_VEHICLE"),
        [1.0, 0.45] select (_profile == "GROUND_VEHICLE")
    ];
    private _maxExpansions = missionNamespace getVariable ["BATTLESPACE_PATHFIND_MAX_EXPANSIONS", 12000];
    private _offsets = [[-1,-1],[0,-1],[1,-1],[-1,0],[1,0],[-1,1],[0,1],[1,1]];

    while {_used < _budget && {(_search get "status") == "SEARCHING"}} do {
        if ([_open] call PRIORITY_QUEUE_IS_EMPTY) exitWith {_search set ["status", "FAILED"]};
        private _queued = [_open] call PRIORITY_QUEUE_POP;
        _used = _used + 1;
        if (isNil "_queued") then {continue};
        _queued params ["_currentKey", "_queuedCost"];
        private _bestCost = _gScore getOrDefault [_currentKey, 1e30];
        if (_queuedCost > _bestCost || {!isNil {_closed get _currentKey}}) then {continue};

        _closed set [_currentKey, true];
        private _expansions = (_search get "expansions") + 1;
        _search set ["expansions", _expansions];
        if (_currentKey == _goalKey) exitWith {
            _search set ["result", [_search] call BATTLESPACE_PATHFIND_RECONSTRUCT_GRID];
            _search set ["status", "FOUND"];
        };
        if (_expansions >= _maxExpansions) exitWith {_search set ["status", "FAILED"]};

        private _currentNode = _nodes get _currentKey;
        private _currentPosition = _currentNode select 0;
        private _currentHeight = _currentNode select 1;
        private _parts = _currentKey splitString ":";
        private _currentIndex = [parseNumber (_parts select 0), parseNumber (_parts select 1)];
        {
            private _nextIndex = [(_currentIndex select 0) + (_x select 0), (_currentIndex select 1) + (_x select 1)];
            private _nextKey = [_nextIndex] call BATTLESPACE_PATHFIND_GRID_KEY;
            if (!isNil {_closed get _nextKey}) then {continue};
            private _nextNode = [_nextIndex] call BATTLESPACE_PATHFIND_GET_TERRAIN_NODE;
            if (!(_nextNode select 4)) then {continue};
            private _nextPosition = _nextNode select 0;
            private _nextRoad = _nextNode select 3;
            if ((_nextNode select 2) && {!_nextRoad}) then {continue};

            private _midpoint = [
                ((_currentPosition select 0) + (_nextPosition select 0)) / 2,
                ((_currentPosition select 1) + (_nextPosition select 1)) / 2,
                0
            ];
            if (surfaceIsWater _midpoint && {!isOnRoad _midpoint}) then {continue};

            private _edgeDistance = _currentPosition distance2D _nextPosition;
            private _slope = abs ((_nextNode select 1) - _currentHeight) / (1 max _edgeDistance);
            if (_slope > _maxSlope) then {continue};

            private _terrainMultiplier = if (_nextRoad) then {1} else {
                [1.05, 1.35] select (_profile == "GROUND_VEHICLE")
            };
            private _slopeMultiplier = 1 + (2 min (_slope * 2));
            private _dynamicMultiplier = [_costContext, _nextKey, _nextPosition] call BATTLESPACE_PATHFIND_GET_DYNAMIC_MULTIPLIER;
            private _newCost = _bestCost + (_edgeDistance * _terrainMultiplier * _slopeMultiplier * _dynamicMultiplier);
            if (_newCost >= (_gScore getOrDefault [_nextKey, 1e30])) then {continue};

            _gScore set [_nextKey, _newCost];
            _cameFrom set [_nextKey, _currentKey];
            _nodes set [_nextKey, _nextNode];
            private _heuristic = _nextPosition distance2D _goalPosition;
            [_open, _newCost + (_weight * _heuristic), [_nextKey, _newCost]] call PRIORITY_QUEUE_ENQUEUE;
        } forEach _offsets;
    };
    [_search get "status", _used]
};

BATTLESPACE_PATHFIND_STEP_ROAD = {
    params ["_search", "_budget"];
    private _used = 0;
    private _open = _search get "open";
    private _gScore = _search get "gScore";
    private _cameFrom = _search get "cameFrom";
    private _closed = _search get "closed";
    private _nodes = _search get "nodes";
    private _goalKey = _search get "goalKey";
    private _goalRoad = _search get "goalRoad";
    private _costContext = _search get "costContext";
    private _weight = missionNamespace getVariable ["BATTLESPACE_PATHFIND_WEIGHT", 1.12];
    private _maxExpansions = missionNamespace getVariable ["BATTLESPACE_PATHFIND_ROAD_MAX_EXPANSIONS", 20000];

    while {_used < _budget && {(_search get "status") == "SEARCHING"}} do {
        if ([_open] call PRIORITY_QUEUE_IS_EMPTY) exitWith {_search set ["status", "FAILED"]};
        private _queued = [_open] call PRIORITY_QUEUE_POP;
        _used = _used + 1;
        if (isNil "_queued") then {continue};
        _queued params ["_currentKey", "_queuedCost"];
        private _bestCost = _gScore getOrDefault [_currentKey, 1e30];
        if (_queuedCost > _bestCost || {!isNil {_closed get _currentKey}}) then {continue};

        _closed set [_currentKey, true];
        private _expansions = (_search get "expansions") + 1;
        _search set ["expansions", _expansions];
        if (_currentKey == _goalKey) exitWith {
            _search set ["result", [_search] call BATTLESPACE_PATHFIND_RECONSTRUCT_ROAD];
            _search set ["status", "FOUND"];
        };
        if (_expansions >= _maxExpansions) exitWith {_search set ["status", "FAILED"]};

        private _currentRoad = _nodes get _currentKey;
        private _neighbors = BATTLESPACE_PATHFIND_ROAD_NEIGHBOR_CACHE get _currentKey;
        if (isNil "_neighbors") then {
            _neighbors = roadsConnectedTo [_currentRoad, true];
            BATTLESPACE_PATHFIND_ROAD_NEIGHBOR_CACHE set [_currentKey, _neighbors];
        };
        {
            if (isNull _x) then {continue};
            private _nextKey = str _x;
            if (!isNil {_closed get _nextKey}) then {continue};
            private _nextPosition = getPos _x;
            private _gridKey = [[_nextPosition] call BATTLESPACE_PATHFIND_GRID_INDEX] call BATTLESPACE_PATHFIND_GRID_KEY;
            private _dynamicMultiplier = [_costContext, _gridKey, _nextPosition] call BATTLESPACE_PATHFIND_GET_DYNAMIC_MULTIPLIER;
            private _newCost = _bestCost + ((_currentRoad distance2D _x) * _dynamicMultiplier);
            if (_newCost >= (_gScore getOrDefault [_nextKey, 1e30])) then {continue};

            _gScore set [_nextKey, _newCost];
            _cameFrom set [_nextKey, _currentKey];
            _nodes set [_nextKey, _x];
            private _heuristic = _x distance2D _goalRoad;
            [_open, _newCost + (_weight * _heuristic), [_nextKey, _newCost]] call PRIORITY_QUEUE_ENQUEUE;
        } forEach _neighbors;
    };
    [_search get "status", _used]
};

BATTLESPACE_PATHFIND_APPEND_SEGMENT = {
    params ["_combined", "_segment"];
    {
        if (_combined isEqualTo [] || {(_combined select (count _combined - 1)) distance2D _x > 5}) then {
            _combined pushBack _x;
        };
    } forEach _segment;
};

BATTLESPACE_PATHFIND_CREATE_JOB = {
    params ["_taskForceName", "_origin", "_destination", "_generation"];
    private _taskForce = BATTLESPACE_TASK_FORCES get _taskForceName;
    if (isNil "_taskForce") exitWith {
        createHashMapFromArray [
            ["status", "CANCELLED"],
            ["taskForceName", _taskForceName],
            ["generation", _generation],
            ["destination", +_destination]
        ]
    };
    private _profile = [_taskForce] call BATTLESPACE_PATHFIND_GET_PROFILE;
    private _cacheKey = [_origin, _destination, _profile] call BATTLESPACE_PATHFIND_CACHE_KEY;
    private _cached = [_cacheKey, _origin, _destination] call BATTLESPACE_PATHFIND_GET_CACHED_ROUTE;
    private _snapshots = [_taskForceName] call BATTLESPACE_PATHFIND_BUILD_SNAPSHOTS;
    private _costContext = createHashMapFromArray [
        ["destination", +_destination],
        ["threats", _snapshots select 0],
        ["congestion", _snapshots select 1]
    ];

    private _job = createHashMapFromArray [
        ["status", ["SEARCHING", "FOUND"] select (_cached isNotEqualTo [])],
        ["taskForceName", _taskForceName],
        ["generation", _generation],
        ["origin", +_origin],
        ["destination", +_destination],
        ["profile", _profile],
        ["cacheKey", _cacheKey],
        ["segments", []],
        ["segmentIndex", 0],
        ["combined", []],
        ["fallbackUsed", false],
        ["costContext", _costContext],
        ["result", _cached]
    ];
    if (_cached isNotEqualTo []) exitWith {_job};
    if (_profile == "AIR") exitWith {
        _job set ["status", "FOUND"];
        _job set ["result", [+_destination]];
        _job
    };

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
    params ["_job", "_budget"];
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
        _search = if (_kind == "ROAD") then {
            [_start, _goal, _job] call BATTLESPACE_PATHFIND_CREATE_ROAD_SEARCH
        } else {
            [_start, _goal, _job get "profile", _job] call BATTLESPACE_PATHFIND_CREATE_GRID_SEARCH
        };
        _job set ["search", _search];
    };

    private _status = _search get "status";
    if (_status == "SEARCHING") then {
        _status = if ((_search get "kind") == "ROAD") then {
            ([_search, _budget] call BATTLESPACE_PATHFIND_STEP_ROAD) select 0
        } else {
            ([_search, _budget] call BATTLESPACE_PATHFIND_STEP_GRID) select 0
        };
    };

    if (_status == "FOUND") then {
        private _segmentRoute = _search getOrDefault ["result", []];
        if ((_search get "kind") == "ROAD") then {
            _segmentRoute = [_segmentRoute] call BATTLESPACE_PATHFIND_REDUCE_ROAD_ROUTE;
        } else {
            _segmentRoute = [_segmentRoute, _job get "profile"] call BATTLESPACE_PATHFIND_SMOOTH_GRID_ROUTE;
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
    params ["_taskForceName", "_origin", "_destination"];
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
            && {_activeDestination isNotEqualTo []}
            && {_activeDestination distance2D _destination <= 1}
        ) then {_alreadyQueued = true};
    };
    if (_alreadyQueued) exitWith {true};
    private _pendingIndex = QUEUED_PATHFIND_REQUESTS findIf {
        (_x select 0) == _taskForceName && {(_x select 2) distance2D _destination <= 1}
    };
    if (_pendingIndex >= 0) exitWith {true};

    private _generation = (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_taskForceName, 0]) + 1;
    BATTLESPACE_PATHFIND_REQUEST_GENERATIONS set [_taskForceName, _generation];
    QUEUED_PATHFIND_REQUESTS = QUEUED_PATHFIND_REQUESTS select {(_x select 0) != _taskForceName};
    QUEUED_PATHFIND_REQUESTS pushBack [_taskForceName, _origin, _destination, _generation];
    true
};

FULFILL_PATHFIND_REQUESTS = {
    if (!isServer) exitWith {};
    if (isNil "BATTLESPACE_PATHFIND_ACTIVE_JOB") then {
        while {isNil "BATTLESPACE_PATHFIND_ACTIVE_JOB" && {QUEUED_PATHFIND_REQUESTS isNotEqualTo []}} do {
            private _request = QUEUED_PATHFIND_REQUESTS deleteAt 0;
            _request params ["_taskForceName", "_origin", "_destination", "_generation"];
            if (
                !isNil {BATTLESPACE_TASK_FORCES get _taskForceName}
                && {_generation == (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_taskForceName, -1])}
            ) then {
                BATTLESPACE_PATHFIND_ACTIVE_JOB = [_taskForceName, _origin, _destination, _generation] call BATTLESPACE_PATHFIND_CREATE_JOB;
            };
        };
    };

    if (!isNil "BATTLESPACE_PATHFIND_ACTIVE_JOB") then {
        private _job = BATTLESPACE_PATHFIND_ACTIVE_JOB;
        private _status = [_job, missionNamespace getVariable ["BATTLESPACE_PATHFIND_EXPANSIONS_PER_TICK", 120]] call BATTLESPACE_PATHFIND_STEP_JOB;
        if (_status in ["FOUND", "FAILED", "CANCELLED"]) then {
            private _taskForceName = _job getOrDefault ["taskForceName", ""];
            private _generation = _job getOrDefault ["generation", -1];
            private _isCurrent = _taskForceName != ""
                && {_generation == (BATTLESPACE_PATHFIND_REQUEST_GENERATIONS getOrDefault [_taskForceName, -2])}
                && {!isNil {BATTLESPACE_TASK_FORCES get _taskForceName}};
            if (_isCurrent && {_status == "FOUND"}) then {
                private _route = _job getOrDefault ["result", []];
                if ([_route] call BATTLESPACE_PATHFIND_ROUTE_IS_VALID) then {
                    if ([_taskForceName, _route] call BATTLESPACE_TASK_FORCE_PATH_FOUND) then {
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
    };
};

if (isServer) then {
    [
        {call FULFILL_PATHFIND_REQUESTS},
        missionNamespace getVariable ["BATTLESPACE_PATHFIND_WORKER_INTERVAL", 0.1],
        []
    ] call CBA_fnc_addPerFrameHandler;
};
