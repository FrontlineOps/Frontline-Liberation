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
BATTLESPACE_PATHFIND_NETWORK_ROADS = createHashMap;
// Sectors off the land mass that holds most sectors (islands); ground logistics skips them.
BATTLESPACE_PATHFIND_ISOLATED_SECTORS = [];

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

    // Road graph with str-road identities. Decoration patches (road type HIDE)
    // have no position or links and are not part of the network.
    private _index = createHashMap;
    private _roads = [];
    private _add = {
        params ["_road"];
        private _id = _index getOrDefault [str _road, -1];
        if (_id < 0 && {((getRoadInfo _road) param [0, "HIDE"]) != "HIDE"}) then {
            _id = count _roads;
            _index set [str _road, _id];
            _roads pushBack _road;
        };
        _id
    };
    private _tile = 1000;
    for "_tileX" from _tile / 2 to worldSize + _tile / 2 step _tile do {
        for "_tileY" from _tile / 2 to worldSize + _tile / 2 step _tile do {
            {[_x] call _add} forEach ([_tileX, _tileY] nearRoads (_tile * 0.75));
        };
    };
    private _links = [];
    private _next = 0;
    // Neighbours outside every tile query are appended and exported too.
    while {_next < count _roads} do {
        private _road = _roads select _next;
        _next = _next + 1;
        private _own = [];
        {
            if (isNull _x) then {continue};
            private _id = [_x] call _add;
            if (_id >= 0) then {_own pushBackUnique _id};
        } forEach (roadsConnectedTo [_road, true]);
        _links pushBack _own;
    };

    // roadsConnectedTo misses links at bridges and some junctions: also join
    // segments whose ends touch (getRoadInfo begin/end points within 6 m).
    private _join = 6;
    private _ends = _roads apply {
        private _info = getRoadInfo _x;
        [_info param [6, getPos _x], _info param [7, getPos _x], _info param [8, false]]
    };
    private _endCells = createHashMap;
    {
        private _id = _forEachIndex;
        {
            private _key = format ["%1:%2", floor ((_x select 0) / _join), floor ((_x select 1) / _join)];
            private _list = _endCells getOrDefault [_key, []];
            _list pushBack [_id, _x];
            _endCells set [_key, _list];
        } forEach (_x select [0, 2]);
    } forEach _ends;
    private _joined = 0;
    {
        private _id = _forEachIndex;
        {
            private _end = _x;
            private _cellX = floor ((_end select 0) / _join);
            private _cellY = floor ((_end select 1) / _join);
            for "_dx" from -1 to 1 do {
                for "_dy" from -1 to 1 do {
                    {
                        _x params ["_other", "_otherEnd"];
                        if (_other != _id && {_end distance2D _otherEnd <= _join} && {!(_other in (_links select _id))}) then {
                            (_links select _id) pushBack _other;
                            (_links select _other) pushBackUnique _id;
                            _joined = _joined + 1;
                        };
                    } forEach (_endCells getOrDefault [format ["%1:%2", _cellX + _dx, _cellY + _dy], []]);
                };
            };
        } forEach (_x select [0, 2]);
    } forEach _ends;

    // Routes snap only onto the largest connected network, never onto a bridge
    // (its grid cell is water) or a detached fragment the road search cannot leave.
    private _component = _roads apply {-1};
    private _main = -1;
    private _mainSize = 0;
    private _label = 0;
    {
        if ((_component select _forEachIndex) >= 0) then {continue};
        _component set [_forEachIndex, _label];
        private _open = [_forEachIndex];
        private _size = 0;
        while {_open isNotEqualTo []} do {
            private _id = _open deleteAt (count _open - 1);
            _size = _size + 1;
            {
                if ((_component select _x) < 0) then {_component set [_x, _label]; _open pushBack _x};
            } forEach (_links select _id);
        };
        if (_size > _mainSize) then {_main = _label; _mainSize = _size};
        _label = _label + 1;
    } forEach _roads;
    private _network = createHashMap;
    {
        if ((_component select _forEachIndex) == _main && {!((_ends select _forEachIndex) select 2)}) then {_network set [str _x, true]};
    } forEach _roads;

    private _entries = [];
    {
        private _position = getPos _x;
        _entries pushBack (([(round (100 * (_position select 0))) toFixed 0, (round (100 * (_position select 1))) toFixed 0]
            + ((_links select _forEachIndex) apply {_x toFixed 0})) joinString ",");
    } forEach _roads;
    if (isNil {["roadsBegin", [count _entries]] call BATTLESPACE_PATHFIND_NATIVE_CALL}) exitWith {};
    for "_first" from 0 to count _entries - 1 step 200 do {
        if (isNil {["roadsChunk", [_first, (_entries select [_first, 200]) joinString ";"]] call BATTLESPACE_PATHFIND_NATIVE_CALL}) exitWith {_failed = true};
    };
    if (_failed || {isNil {["roadsSeal"] call BATTLESPACE_PATHFIND_NATIVE_CALL}}) exitWith {};

    BATTLESPACE_PATHFIND_NATIVE_ROADS = _index;
    BATTLESPACE_PATHFIND_NETWORK_ROADS = _network;
    diag_log format ["[BATTLESPACE][PATH] Road network: %1 segments, %2 end-point joins, main network %3 segments across %4 components",
        count _roads, _joined, _mainSize, _label];
    private _labels = sectors_allSectors apply {
        private _position = markerPos _x;
        private _reply = ["component", [(_position select 0) toFixed 2, (_position select 1) toFixed 2]] call BATTLESPACE_PATHFIND_NATIVE_CALL;
        if (isNil "_reply") then {-1} else {_reply select 0}
    };
    private _counts = createHashMap;
    {if (_x >= 0) then {_counts set [_x, (_counts getOrDefault [_x, 0]) + 1]}} forEach _labels;
    private _main = -1;
    {if (_y > (_counts getOrDefault [_main, 0])) then {_main = _x}} forEach _counts;
    {
        if ((_labels select _forEachIndex) != _main) then {BATTLESPACE_PATHFIND_ISOLATED_SECTORS pushBack _x};
    } forEach sectors_allSectors;
    if (BATTLESPACE_PATHFIND_ISOLATED_SECTORS isNotEqualTo []) then {
        diag_log format ["[BATTLESPACE][PATH] Sectors unreachable by ground, skipped by ground logistics: %1", BATTLESPACE_PATHFIND_ISOLATED_SECTORS];
    };
    BATTLESPACE_PATHFIND_NATIVE_READY = true;
    diag_log format ["[BATTLESPACE][PATH] Native pathfinder ready: %1x%1 cells, %2 roads, exported in %3 s",
        _cells, count _roads, (diag_tickTime - _started) toFixed 1];
};

// Nearest main-network road within the radius, or objNull.
BATTLESPACE_PATHFIND_NEAREST_NETWORK_ROAD = {
    params ["_position", "_radius"];
    private _best = objNull;
    private _bestDistance = _radius;
    {
        private _distance = _position distance2D _x;
        if (_distance < _bestDistance && {str _x in BATTLESPACE_PATHFIND_NETWORK_ROADS}) then {
            _best = _x;
            _bestDistance = _distance;
        };
    } forEach (_position nearRoads _radius);
    _best
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
