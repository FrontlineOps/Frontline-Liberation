/*
    Server-local native search backend for the Battlespace pathfinder
    (extensions/frontline_path, required on the server). The terrain lattice and
    road graph are exported once per mission; each grid or road segment is then
    searched to completion in one call. Queued requests wait until the export
    completes.
*/

BATTLESPACE_PATHFIND_NATIVE_LIBRARY = "frontline_path_v1";
BATTLESPACE_PATHFIND_NATIVE_READY = false;
BATTLESPACE_PATHFIND_NATIVE_ROADS = createHashMap;

// Returns the parsed reply, or nil on any extension or command error.
BATTLESPACE_PATHFIND_NATIVE_CALL = {
    params ["_command", ["_arguments", []]];
    private _reply = BATTLESPACE_PATHFIND_NATIVE_LIBRARY callExtension [_command, _arguments];
    if (count _reply == 3 && {(_reply select 1) == 0} && {(_reply select 2) == 0}) then {
        parseSimpleArray (_reply select 0)
    } else {
        diag_log format ["[BATTLESPACE][PATH][ERROR] Native %1 failed: %2", _command, _reply];
        nil
    }
};

BATTLESPACE_PATHFIND_NATIVE_EXPORT = {
    private _version = BATTLESPACE_PATHFIND_NATIVE_LIBRARY callExtension ["version", []];
    if (count _version != 3 || {(_version select 1) != 0} || {(_version select 2) != 0} || {((parseSimpleArray (_version select 0)) param [0, 0]) != 1}) exitWith {
        diag_log format ["[BATTLESPACE][PATH][ERROR] Native pathfinder %1 unavailable (%2); task forces cannot route. Load @FrontlinePath with -serverMod.", BATTLESPACE_PATHFIND_NATIVE_LIBRARY, _version];
    };
    private _started = diag_tickTime;
    private _size = missionNamespace getVariable ["BATTLESPACE_PATHFIND_GRID_SIZE", 100];
    // Same validity as GET_TERRAIN_NODE: a cell is valid when its centre is inside the map.
    private _cells = floor (worldSize / _size - 0.5) + 1;
    if (isNil {["reset"] call BATTLESPACE_PATHFIND_NATIVE_CALL} || {isNil {["gridBegin", [_size, _cells]] call BATTLESPACE_PATHFIND_NATIVE_CALL}}) exitWith {};

    // Half-cell lattice: cell centres and every neighbour midpoint (1 water, 2 road).
    private _half = _size / 2;
    private _failed = false;
    for "_row" from 0 to 2 * _cells do {
        private _y = _row * _half;
        private _flags = [];
        for "_column" from 0 to 2 * _cells do {
            private _position = [_column * _half, _y];
            _flags pushBack (48 + ([0, 1] select surfaceIsWater _position) + ([0, 2] select isOnRoad _position));
        };
        if (isNil {["gridFlags", [_row, toString _flags]] call BATTLESPACE_PATHFIND_NATIVE_CALL}) exitWith {_failed = true};
    };
    if (_failed) exitWith {};
    for "_row" from 0 to _cells - 1 do {
        private _y = (_row + 0.5) * _size;
        private _heights = [];
        for "_column" from 0 to _cells - 1 do {
            _heights pushBack ((round (100 * getTerrainHeightASL [(_column + 0.5) * _size, _y])) toFixed 0);
        };
        if (isNil {["gridHeights", [_row, _heights joinString ","]] call BATTLESPACE_PATHFIND_NATIVE_CALL}) exitWith {_failed = true};
    };
    if (_failed || {isNil {["gridSeal"] call BATTLESPACE_PATHFIND_NATIVE_CALL}}) exitWith {};

    // Road graph with the SQF search's identities (str road) and neighbour order.
    private _index = createHashMap;
    private _roads = [];
    private _tile = 1000;
    for "_tileX" from _tile / 2 to worldSize + _tile / 2 step _tile do {
        for "_tileY" from _tile / 2 to worldSize + _tile / 2 step _tile do {
            {
                private _key = str _x;
                if !(_key in _index) then {
                    _index set [_key, count _roads];
                    _roads pushBack _x;
                };
            } forEach ([_tileX, _tileY] nearRoads (_tile * 0.75));
        };
    };
    private _entries = [];
    private _next = 0;
    // Neighbours outside every tile query are appended and exported too.
    while {_next < count _roads} do {
        private _road = _roads select _next;
        _next = _next + 1;
        private _links = [];
        {
            if (isNull _x) then {continue};
            private _key = str _x;
            private _id = _index getOrDefault [_key, -1];
            if (_id < 0) then {
                _id = count _roads;
                _index set [_key, _id];
                _roads pushBack _x;
            };
            _links pushBack (_id toFixed 0);
        } forEach (roadsConnectedTo [_road, true]);
        private _position = getPos _road;
        _entries pushBack (([(round (100 * (_position select 0))) toFixed 0, (round (100 * (_position select 1))) toFixed 0] + _links) joinString ",");
    };
    if (isNil {["roadsBegin", [count _entries]] call BATTLESPACE_PATHFIND_NATIVE_CALL}) exitWith {};
    for "_first" from 0 to count _entries - 1 step 200 do {
        if (isNil {["roadsChunk", [_first, (_entries select [_first, 200]) joinString ";"]] call BATTLESPACE_PATHFIND_NATIVE_CALL}) exitWith {_failed = true};
    };
    if (_failed || {isNil {["roadsSeal"] call BATTLESPACE_PATHFIND_NATIVE_CALL}}) exitWith {};

    BATTLESPACE_PATHFIND_NATIVE_ROADS = _index;
    BATTLESPACE_PATHFIND_NATIVE_READY = true;
    diag_log format ["[BATTLESPACE][PATH] Native pathfinder ready: %1x%1 cells, %2 roads, exported in %3 s",
        _cells, count _roads, (diag_tickTime - _started) toFixed 1];
};

// Searches one segment to completion; returns and records "FOUND" or "FAILED".
BATTLESPACE_PATHFIND_NATIVE_SEARCH = {
    params ["_search"];
    private _fail = {
        _search set ["status", "FAILED"];
        "FAILED"
    };
    private _grid = (_search get "kind") == "GRID";
    private _context = _search get "costContext";
    private _ends = if (_grid) then {
        private _start = _search get "startPos";
        private _goal = _search get "goalPos";
        [_start select 0, _start select 1, _goal select 0, _goal select 1] apply {_x toFixed 2}
    } else {
        [
            BATTLESPACE_PATHFIND_NATIVE_ROADS getOrDefault [_search get "startKey", -1],
            BATTLESPACE_PATHFIND_NATIVE_ROADS getOrDefault [_search get "goalKey", -1],
            0, 0
        ]
    };
    if (!_grid && {(_ends select 0) < 0 || {(_ends select 1) < 0}}) exitWith {call _fail};
    // Serialize the job's shared snapshot once; every segment of the job reuses it.
    if (isNil {_context get "nativeThreats"}) then {
        _context set ["nativeThreats", ((_context getOrDefault ["threats", []]) apply {
            _x params ["_position", "_strength"];
            [(round (100 * (_position select 0))) toFixed 0, (round (100 * (_position select 1))) toFixed 0, (round _strength) toFixed 0] joinString ","
        }) joinString ";"];
        _context set ["nativeCongestion", (keys (_context getOrDefault ["congestion", createHashMap])) joinString ";"];
    };
    private _profile = _search getOrDefault ["profile", ""];
    private _vehicle = _profile in ["GROUND_VEHICLE", "RURAL_VEHICLE"];
    private _destination = _context getOrDefault ["destination", [0, 0, 0]];
    private _reply = ["find", [[0, 1] select !_grid] + _ends + [
        [0, 1] select _vehicle,
        [0, 1] select (_profile in ["RURAL", "RURAL_VEHICLE"]),
        missionNamespace getVariable [["BATTLESPACE_PATHFIND_INFANTRY_MAX_SLOPE", "BATTLESPACE_PATHFIND_VEHICLE_MAX_SLOPE"] select _vehicle, [1.0, 0.45] select _vehicle],
        missionNamespace getVariable ["BATTLESPACE_PATHFIND_RURAL_ROAD_MULTIPLIER", 2.25],
        missionNamespace getVariable ["BATTLESPACE_PATHFIND_WEIGHT", 1.12],
        missionNamespace getVariable [["BATTLESPACE_PATHFIND_MAX_EXPANSIONS", "BATTLESPACE_PATHFIND_ROAD_MAX_EXPANSIONS"] select !_grid, [12000, 20000] select !_grid],
        (_destination select 0) toFixed 2,
        (_destination select 1) toFixed 2,
        missionNamespace getVariable ["BATTLESPACE_PATHFIND_FINAL_APPROACH_RADIUS", 600],
        missionNamespace getVariable ["BATTLESPACE_PATHFIND_THREAT_RADIUS", 1600],
        missionNamespace getVariable ["BATTLESPACE_PATHFIND_CONGESTION_MULTIPLIER", 1.2],
        _context get "nativeThreats",
        _context get "nativeCongestion"
    ]] call BATTLESPACE_PATHFIND_NATIVE_CALL;
    if (isNil "_reply") exitWith {call _fail};
    _reply params ["_found", "_expansions", "_points"];
    _search set ["expansions", _expansions];
    if (_found != 1) exitWith {call _fail};
    private _route = [];
    for "_first" from 0 to _points - 1 step 150 do {
        private _page = ["route", [_first, 150]] call BATTLESPACE_PATHFIND_NATIVE_CALL;
        if (isNil "_page") exitWith {_route = []};
        {_route pushBack [_x select 0, _x select 1, 0]} forEach _page;
    };
    if (count _route != _points) exitWith {call _fail};
    if (_grid) then {
        _route set [0, +(_search get "startPos")];
        _route set [count _route - 1, +(_search get "goalPos")];
    };
    _search set ["result", _route];
    _search set ["status", "FOUND"];
    "FOUND"
};

if (isServer) then {
    [] spawn BATTLESPACE_PATHFIND_NATIVE_EXPORT;
};
