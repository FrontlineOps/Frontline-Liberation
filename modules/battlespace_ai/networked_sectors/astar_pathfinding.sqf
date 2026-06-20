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
	params ["_pointA", "_pointB", ["_bailOut", 1000], ["_granular", false]];
	ROADS_EVALUATED = [];
	private _startTime = diag_tickTime;
	private _startNode = [_pointA, NETWORKED_SECTORS_CLOSEST_ROAD_SLOP] call BIS_fnc_nearestRoad;

	private _endNode = [_pointB, NETWORKED_SECTORS_CLOSEST_ROAD_SLOP] call BIS_fnc_nearestRoad;
	// No valid path was found.
	if((isNull _startNode) || (isNull _endNode)) exitWith { 
		diag_log format ["Not found valid start %1 or end %2", _startNode, _endNode];
		[]
	};

	private _visitedNodes = createHashMap;

	private _unvisitedNodes = [] call NEW_PRIORITY_QUEUE;

	[_unvisitedNodes, 0, [0, _startNode, nil, _endNode distance2D _startNode] call A_STAR_CREATE_NODE] call PRIORITY_QUEUE_ENQUEUE;
	private _path = [];


	private _currentNode = _startNode;

	private _execs = 0;

	

	
	while {!([_unvisitedNodes] call PRIORITY_QUEUE_IS_EMPTY) && _execs < _bailOut} do {
	
		if([_unvisitedNodes] call PRIORITY_QUEUE_IS_EMPTY) exitWith {
			diag_log format ["Queue empty"];
		};



		_currentNode = [_unvisitedNodes] call PRIORITY_QUEUE_POP;


		if(isNil "_currentNode") then {
			continue;
		};
		private _currentRoadObject = _currentNode get "RoadObject";

		

		_visitedNodes set [str _currentRoadObject, _currentRoadObject];
		if(_currentRoadObject isEqualTo _endNode) exitWith {
			// Construct our path


			while { !(_currentNode isEqualTo objNull) } do {

				_path pushBack _currentNode;

				_currentNode = _currentNode get "Parent";
			};
		};


		// Not end node, evaluate our neighbors and add to unvisited set if they haven't been visited.
		// Neighbors in this situation would be the next road segment that isn't in the visited set.
		private _neighbors = roadsConnectedTo [_currentRoadObject, _granular];

		private _rows = [];
		{

			if(isNull _x) then { continue; };
			// Visited node, skip, as its already been evaluated.
			if(!(isNil { _visitedNodes get (str _x) })) then {
				continue;
			};
			private _newCost = (_currentNode get "Cost") + (_x distance2D _currentRoadObject) + (_x distance2D _endNode);
			private _newNode = [(_currentNode get "Cost") + (_x distance2D _currentRoadObject), _x, _currentNode, _x distance2D _endNode ] call A_STAR_CREATE_NODE;
			_rows pushBack [_newCost, _newNode];
		} forEach _neighbors;

		[_unvisitedNodes, _rows] call PRIORITY_QUEUE_ENQUEUE_MULTIPLE;

		_currentNode set ["NeighborAmount", count _neighbors];
		_execs = _execs + 1;
	};

	iF(_execs >= _bailOut) then {
		diag_log format ["A* Pathfinding bailed out"];
	};
	diag_log format ["A* Pathfinding took %1s", diag_tickTime - _startTime];

	[_path, diag_tickTime - _startTime]


};

NETWORKED_SECTORS_GET_LINK_UP_TO_DEPTH = {
	params ["_sector", "_bluforSectors", "_desiredDepth"];

	private _backlineSector = "";

	private _networkedSectorData = NETWORKED_SECTORS get _sector;
	private _openSet = +(_networkedSectorData get "Links");
	private _highestCost = 0;
	private _valid = false;
	private _visitedSet = createHashMap;
	private _execs = 0;
	while { (count _openSet) > 0 && _execs < 500 } do 
	{
		_execs = _execs + 1;
		private _currentNode = _openSet deleteAt ((count _openSet) - 1);

		_visitedSet set [_currentNode, true];

		private _data = NETWORKED_SECTORS get _currentNode;

		private _sectorCost = [_currentNode, _bluforSectors] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;

		if(_sectorCost >= _desiredDepth) exitWith { _backlineSector = _currentNode };

		if(_sectorCost > _highestCost) then {
			_highestCost = _sectorCost;
			_backlineSector = _currentNode;
		};
		

		

		private _newLinks = _data get "Links";
		diag_log format ["new links %1", _newLinks];
		{
			if(_x in _bluforSectors) then { continue; };
			
			if (!(isNil { _visitedSet get _x })) then { continue; };

			_visitedSet set [_x, true];
			_openSet pushBack _x;
		} forEach _newLinks;

	};

	if(_execs >= 500) then {
		diag_log format ["broke out due to loop"];
	};

	_backlineSector
};
NETWORKED_SECTORS_HAS_UP_TO_LINK_DEPTH = {
	params ["_sector", "_bluforSectors", "_desiredDepth"];


	private _networkedSectorData = NETWORKED_SECTORS get _sector;
	private _openSet = +(_networkedSectorData get "Links");

	private _highestCost = 0;

	private _valid = false;
	private _visitedSet = createHashMap;

	private _execs = 0;
	while { (count _openSet) > 0 && _execs < 500 } do 
	{
		_execs = _execs + 1;
		private _currentNode = _openSet deleteAt ((count _openSet) - 1);
		
		_visitedSet set [_currentNode, true];
		
		private _data = NETWORKED_SECTORS get _currentNode;

		private _sectorCost = [_currentNode, _bluforSectors] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;

		if(_sectorCost >= _desiredDepth) exitWith { _valid = true };

		

		

		private _newLinks = _data get "Links";


		{
			if(_x in _bluforSectors) then { continue; };
			if (!(isNil { _visitedSet get _x })) then { continue; };

			_visitedSet set [_x, true];
			_openSet pushBack _x;
		} forEach _newLinks;


	};

	if(_execs >= 500) then {
		diag_log format ["broke out due to loop"];
	};

	_valid
};
// Is _targetSector within _distance away from _sector in the Sector Graph.
NETWORKED_SECTORS_IS_NODE_WITHIN_DISTANCE_FOR_NODE = {
	params ["_sector", "_targetSector", "_bluforSectors", "_distance"];

	diag_log format ["NETWORKED_SECTORS_IS_NODE_WITHIN_DISTANCE_FOR_NODE (%1, %2, %3)", _sector, _targetSector, _distance];


	private _networkedSectorData = NETWORKED_SECTORS get _sector;
	private _openSet = [];

	{
		_openSet pushBack [_x, 1];
	} forEach (_networkedSectorData get "Links");
	private _highestCost = 0;

	private _valid = false;
	private _visitedSet = createHashMap;

	private _execs = 0;
	while { (count _openSet) > 0 && _execs < 500 && !_valid } do 
	{
		_execs = _execs + 1;
		private _currentNodeData = _openSet deleteAt ((count _openSet) - 1);

		_currentNodeData params ["_currentNode", "_currentCost"];
		
		_visitedSet set [_currentNode, true];
		
		private _data = NETWORKED_SECTORS get _currentNode;

		if(_currentNode == _targetSector) exitWith {
			_valid = true;
		};



		

		

		private _newLinks = _data get "Links";


		{
			if((_currentCost + 1) > _distance) then { continue; };
			if(_x in _bluforSectors) then { continue; };
			if (!(isNil { _visitedSet get _x })) then { continue; };

			_visitedSet set [_x, true];
			_openSet pushBack [_x, _currentCost + 1];

			if(_x == _targetSector) exitWith { _valid = true; };
		} forEach _newLinks;


	};

	if(_execs >= 500) then {
		diag_log format ["broke out due to loop"];
	};

	_valid
};
NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE = {
	params ["_sector", "_blacklist"];

	if(isNil "_blacklist") exitWith { 
		diag_log format ["Networked sectors get distance was passed nil blacklist"];
		systemChat format ["Networked sectors get distance was passed nil blacklist"];
		69
	};

	if(isNil "_sector") exitWith {
		diag_Log format ["Networked sectors get distance was passed nil sector"];
		systemChat format ["Networked sectors get distance was passed nil sector"];
		69
	};

	if(_sector in _blacklist) exitWith { -1 };
	// This function apparently is called 200+ times so async guard
	if(!isNil "NETWORKED_SECTOR_REBUILDING_COST_CACHE") exitWith { -1 };

	if(isNil "blufor_sectors") exitWith { -1 };

	if(isNil "NETWORKED_SECTORS") exitWith { -1 };

	if(isNil "NETWORKED_SECTORS_LINKED") exitWith { -1 };

	private _hadToRebuild = false;
	
	if(isNil "NETWORKED_SECTOR_COST_CACHE") then {
		NETWORKED_SECTOR_COST_CACHE = createHashMap;
		NETWORKED_SECTOR_COST_CACHE set ["BluforSectors", +blufor_sectors];
		diag_log format ["Cost cache nil, constructing"];
		diag_log format ["%2: Reconstructing Cost Cache..... Blufor sectors is %1", blufor_sectors, diag_tickTime];
		diag_log format ["%1: Cost cache networked sector at time is %2", diag_tickTime, NETWORKED_SECTORS];
		_hadToRebuild = true;
	};

	private _cachedCost = NETWORKED_SECTOR_COST_CACHE get _sector;

	
	private _bluforSectorsWhenCached = NETWORKED_SECTOR_COST_CACHE get "BluforSectors";
	// Kind of expensive but this function does not get run often enough that a simple numerical check can be sufficient at preventing stale cache

	private _whatExists = createHashMap;

	{
		_whatExists set [_x, true];
	} forEach _bluforSectorsWhenCached;
	private _valid = true;
	{
		if(isNil { _whatExists get _x }) exitWith {
			_valid = false;
		};
	} forEach blufor_sectors;

	if((count _bluforSectorsWhenCached) != (count blufor_sectors)) then {
		_valid = false;
	};
	if(!_valid) then {
		_cachedCost = nil;
		NETWORKED_SECTOR_COST_CACHE = createHashMap;
		NETWORKED_SECTOR_COST_CACHE set ["BluforSectors", +blufor_sectors];
		diag_log format ["Cost cache is not equal to previous cached blufor sectors"];
		diag_log format ["%2: Reconstructing Cost Cache..... Blufor sectors is %1", blufor_sectors, diag_tickTime];
		diag_log format ["%1: Cost cache networked sector at time is %2", diag_tickTime, NETWORKED_SECTORS];
		_hadToRebuild = true;
	};

	if(!isNil "_cachedCost") exitWith { _cachedCost };
	
	if(!_hadToRebuild) exitWith { 69 };

	systemChat format ["Rebuilding"];

	// Loop through from blacklisted sectors and radiate outwards. 

	private _openNodes = [];

	{
		_openNodes pushBack [_x, -2];
	} forEach _blacklist;

	private _visitedSet = createHashMap;

	NETWORKED_SECTOR_REBUILDING_COST_CACHE = true;
	while { (count _openNodes) > 0 } do {
		private _currentNode = _openNodes deleteAt 0;

		_currentNode params ["_sectorName", "_cost"];
		
		_cost = _cost + 1;
		diag_log format ["Determined cost for %1 to be %2", _sectorName, _cost];
		NETWORKED_SECTOR_COST_CACHE set [_sectorName, _cost];
		_visitedSet set [_sectorName, _cost];


		private _neighbors = NETWORKED_SECTORS get _sectorName;

		if (isNil "_neighbors") then {
			continue;
		};

		_neighbors = _neighbors get "Links";

		{
			if(_x in _blacklist) then { continue };

			private _visited = _visitedSet getOrDefault [_x, 9000];

			if(((_cost+1) < _visited)) then {
				diag_log format ["Sector %1 unvisited, push with %2", _x, _cost];
				_openNodes pushBack [_x, _cost];
				_visitedSet set [_x, _cost+1];
			};

		} forEach _neighbors;


	};
	diag_log format ["Cache rebuilt"];
	NETWORKED_SECTOR_REBUILDING_COST_CACHE = nil;

	NETWORKED_SECTOR_COST_CACHE getOrDefault [_sector, 69]
};
