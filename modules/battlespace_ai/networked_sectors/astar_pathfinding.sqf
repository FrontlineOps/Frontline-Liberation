// A* Pathfinding
// Upon evaluating the current node, you find new nodes that you then push to be unvisited still.
// Evaluating the current node, you make note of the actual cost. Unvisited nodes you mark with a new estimated cost. Only update the estimated cost if it is lower than previous
// Estimated cost is determined via a heuristic (simple manhattan heuristic of distance from node to goal)
// Keep looping until there are no more unvisited nodes or you found the end goal. 
// Once you found the end goal, you re-trace steps, going for the lowest cost nodes in reverse
// Once you reversed to start node, the array of paths you re-traced is the shortest path.
ROAD_PATH = [];
ROADS_EVALUATED = [];
ROAD_RENDER = false;
RENDER_EVALUATIONS = false;
RENDER_ROADS_PFH = {
	if(!ROAD_RENDER) exitWith {
		[_this select 1] call CBA_fnc_removePerFrameHandler;
	};

	if(accTime <= 0 || isGamePaused) exitWith {};
	{

		private _obj = _x get "RoadObject";

		private _color = [1,0,0,1];

		private _neighborAmount = _x get "NeighborAmount";

		if(_neighborAmount > 2) then {
			_color = [0,1,0,1];
		};
		drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", _color, getPos _obj, 0.75, 0.75, 0, "O", 1, 0.025, "TahomaB"];
	} forEach ROAD_PATH;
	if(RENDER_EVALUATIONS) then {
		{
			drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [0,0,1,0.4], getPos _x, 0.75, 0.75, 0, "X", 1, 0.025, "TahomaB"];
		} forEach (ROADS_EVALUATED);
	};
};



// Nodes would be a linked list.
// Each node would point back to the parent node.
A_STAR_CREATE_NODE = {
	params ["_cost", "_road", ["_previousNode", objNull], "_heuristicCost", ["_neighborAmount", 0]];


	createHashMapFromArray [
		["Cost", _cost],
		["RoadObject", _road],
		["Parent", _previousNode],
		["HeuristicCost", _heuristicCost],
		["NeighborAmount", _neighborAmount]
	]
};


// Calculate a path from point A to point B.
// Returns: Array of nodes in *reverse* order that would end up with tracing a path from B to A.
// Can utilize node information to determine road intersections.
A_STAR = {
	params [
		"_pointA",
		"_pointB",
		["_bailOut", missionNamespace getVariable ["BATTLESPACE_PATHFIND_ROAD_MAX_EXPANSIONS", 20000]],
		["_granular", false]
	];
	ROADS_EVALUATED = [];
	private _startTime = diag_tickTime;
	private _startNode = [_pointA, NETWORKED_SECTORS_CLOSEST_ROAD_SLOP] call BIS_fnc_nearestRoad;
	private _endNode = [_pointB, NETWORKED_SECTORS_CLOSEST_ROAD_SLOP] call BIS_fnc_nearestRoad;
	if (isNull _startNode || {isNull _endNode}) exitWith {
		diag_log format ["Not found valid start %1 or end %2", _startNode, _endNode];
		[[], diag_tickTime - _startTime]
	};

	if (isNil "BATTLESPACE_PATHFIND_ROAD_NEIGHBOR_CACHE") then {
		BATTLESPACE_PATHFIND_ROAD_NEIGHBOR_CACHE = createHashMap;
	};

	private _closedNodes = createHashMap;
	private _gScore = createHashMap;
	private _unvisitedNodes = [] call NEW_PRIORITY_QUEUE;
	private _startKey = str _startNode;
	private _startHeuristic = _endNode distance2D _startNode;
	_gScore set [_startKey, 0];
	[
		_unvisitedNodes,
		_startHeuristic,
		[[0, _startNode, nil, _startHeuristic] call A_STAR_CREATE_NODE, 0]
	] call PRIORITY_QUEUE_ENQUEUE;

	private _path = [];
	private _execs = 0;
	while {!([_unvisitedNodes] call PRIORITY_QUEUE_IS_EMPTY) && {_execs < _bailOut}} do {
		private _queued = [_unvisitedNodes] call PRIORITY_QUEUE_POP;
		if (isNil "_queued") then {continue};
		_queued params ["_currentNode", "_queuedCost"];
		private _currentRoadObject = _currentNode get "RoadObject";
		private _currentKey = str _currentRoadObject;
		private _bestCost = _gScore getOrDefault [_currentKey, 1e30];
		if (_queuedCost > _bestCost || {!isNil {_closedNodes get _currentKey}}) then {continue};

		_closedNodes set [_currentKey, true];
		ROADS_EVALUATED pushBack _currentRoadObject;
		if (_currentRoadObject isEqualTo _endNode) exitWith {
			while {!(_currentNode isEqualTo objNull)} do {
				_path pushBack _currentNode;
				_currentNode = _currentNode get "Parent";
			};
		};

		private _neighborCacheKey = format ["%1:%2", _currentKey, _granular];
		private _neighbors = BATTLESPACE_PATHFIND_ROAD_NEIGHBOR_CACHE get _neighborCacheKey;
		if (isNil "_neighbors") then {
			_neighbors = roadsConnectedTo [_currentRoadObject, _granular];
			BATTLESPACE_PATHFIND_ROAD_NEIGHBOR_CACHE set [_neighborCacheKey, _neighbors];
		};

		private _rows = [];
		{
			if (isNull _x) then {continue};
			private _nextKey = str _x;
			if (!isNil {_closedNodes get _nextKey}) then {continue};
			private _tentativeCost = _bestCost + (_x distance2D _currentRoadObject);
			if (_tentativeCost >= (_gScore getOrDefault [_nextKey, 1e30])) then {continue};

			_gScore set [_nextKey, _tentativeCost];
			private _heuristic = _x distance2D _endNode;
			private _newNode = [_tentativeCost, _x, _currentNode, _heuristic] call A_STAR_CREATE_NODE;
			_rows pushBack [_tentativeCost + _heuristic, [_newNode, _tentativeCost]];
		} forEach _neighbors;

		[_unvisitedNodes, _rows] call PRIORITY_QUEUE_ENQUEUE_MULTIPLE;
		_currentNode set ["NeighborAmount", count _neighbors];
		_execs = _execs + 1;
	};

	if (_execs >= _bailOut) then {
		diag_log format ["A* Pathfinding bailed out after %1 expansions", _execs];
	};
	ROAD_PATH = _path;
	if (missionNamespace getVariable ["BATTLESPACE_DEBUG_INDEPTH", false]) then {
		diag_log format ["A* Pathfinding took %1s and %2 expansions", diag_tickTime - _startTime, _execs];
	};

	[_path, diag_tickTime - _startTime]


};

// Is _targetSector within _distance away from _sector in the Sector Graph.
NETWORKED_SECTORS_IS_NODE_WITHIN_DISTANCE_FOR_NODE = {
    params ["_sector", "_targetSector", "_bluforSectors", "_distance"];
    if (isNil "NETWORKED_SECTORS" || {_distance < 0}) exitWith {false};
    if (!(_sector in NETWORKED_SECTORS) || {!(_targetSector in NETWORKED_SECTORS)}) exitWith {false};
    if (_sector == _targetSector) exitWith {true};

    // FIFO discovery visits each node at its shortest distance. A deeper
    // branch must never prevent a later, shorter route reaching the target.
    private _queue = [[_sector, 0]];
    private _visited = createHashMapFromArray [[_sector, true]];
    private _cursor = 0;
    private _found = false;
    while {_cursor < count _queue && {!_found}} do {
        (_queue select _cursor) params ["_current", "_cost"];
        _cursor = _cursor + 1;
        if (_cost >= _distance) then {continue};
        {
            // Graph repair has always admitted existing first-hop links,
            // applying ownership exclusions only to subsequent traversal.
            if ((_cost > 0 && {_x in _bluforSectors}) || {_x in _visited} || {!(_x in NETWORKED_SECTORS)}) then {continue};
            _visited set [_x, true];
            if (_x == _targetSector) exitWith {_found = true};
            _queue pushBack [_x, _cost + 1];
        } forEach ((NETWORKED_SECTORS get _current) getOrDefault ["Links", []]);
    };
    _found
};

NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE = {
    params ["_sector", "_blacklist"];
    if (isNil "_sector" || {isNil "_blacklist"}) exitWith {69};
    if (_sector in _blacklist) exitWith {-1};
    if (isNil "NETWORKED_SECTORS" || {!(missionNamespace getVariable ["NETWORKED_SECTORS_LINKED", false])}) exitWith {-1};

    // Cache the actual seed set, including startbase when the caller supplies
    // it. Graph reconstruction clears this cache in networked_sectors/index.
    private _seeds = _blacklist arrayIntersect _blacklist;
    _seeds sort true;
    private _key = str _seeds;
    if (isNil "NETWORKED_SECTOR_COST_CACHE") then {
        NETWORKED_SECTOR_COST_CACHE = createHashMap;
    };
    private _costs = NETWORKED_SECTOR_COST_CACHE get _key;
    if (!isNil "_costs") exitWith {_costs getOrDefault [_sector, 69]};

    // Build locally, then publish a complete map; other scheduled callers
    // never see a partially rebuilt cache or a temporary negative depth.
    _costs = createHashMap;
    private _queue = [];
    {
        _costs set [_x, -1];
        _queue pushBack _x;
    } forEach _seeds;
    private _cursor = 0;
    while {_cursor < count _queue} do {
        private _current = _queue select _cursor;
        _cursor = _cursor + 1;
        private _node = NETWORKED_SECTORS getOrDefault [_current, createHashMap];
        private _nextCost = (_costs get _current) + 1;
        {
            if (_x in _costs || {!(_x in NETWORKED_SECTORS)}) then {continue};
            _costs set [_x, _nextCost];
            _queue pushBack _x;
        } forEach (_node getOrDefault ["Links", []]);
    };
    // Bound storage across ownership changes and unusual caller seed sets.
    if (count NETWORKED_SECTOR_COST_CACHE >= 4) then {
        NETWORKED_SECTOR_COST_CACHE deleteAt ((keys NETWORKED_SECTOR_COST_CACHE) select 0);
    };
    NETWORKED_SECTOR_COST_CACHE set [_key, _costs];
    _costs getOrDefault [_sector, 69]
};
