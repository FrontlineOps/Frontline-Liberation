[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\networked_sectors\priority_queue.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\networked_sectors\determine_sector_links.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\networked_sectors\astar_pathfinding.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\networked_sectors\zeusEnhancedActions.sqf";

NETWORKED_SECTORS_SAVE_KEY = format ["NETWORKED_SECTORS_%1", toUpper worldName];

// List of prefixes that markers will start with that would constitute a sector to be linked
NETWORKED_SECTORS_MARKER_PREFIXES = [
	"capture",
	"bigtown",
	"military",
	"tower",
	"factory",
	"startbase_marker",
	"logistics_spawn"
];

// Key-Value
// Sector name: { "Links": array of sectors linked to
//   "Position": marker position
// }

if (isNil { NETWORKED_SECTORS }) then {
	NETWORKED_SECTORS = createHashMap;
};
// TODO: move to zeus enhanced toggle

NETWORKED_SECTORS_IS_FRONTLINE = {
	params ["_sectorName", "_bluforSectors"];
	private _distance = [_sectorName, _bluforSectors] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;

	_distance == 0
};

NETWORKED_SECTORS_GET_SECTORS_UP_TO_COST = {
	params ["_bluforSectors", "_desiredCost"];

	private _frontlineSectors = [];
	private _markers = allMapMarkers select { 
		private _marker = _x;
		private _valid = false;

		{
			if((_marker find _x) == 0) exitWith { _valid = true };
		} forEach NETWORKED_SECTORS_MARKER_PREFIXES;

		_valid
	};

	{
		private _cost = [_x, _bluforSectors] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;

		if(_cost <= _desiredCost && _cost >= 0) then {
			_frontlineSectors pushBack [_cost, _x];
		};
	} forEach _markers;

	private _sortedSectors = [
		_frontlineSectors,
		[],
		{
			(_x#0)
		},
		"DESCEND"
	] call BIS_fnc_sortBy;

	_sortedSectors
};


NETWORKED_SECTORS_GET_SECTORS_AT_COST = {
	params ["_bluforSectors", "_desiredCost"];

	private _frontlineSectors = [];
	private _markers = allMapMarkers select { 
		private _marker = _x;
		private _valid = false;
		{
			if((_marker find _x) == 0) exitWith { _valid = true };
		} forEach NETWORKED_SECTORS_MARKER_PREFIXES;

		_valid
	};

	{
		private _cost = [_x, _bluforSectors] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;

		if(_cost == _desiredCost) then {
			_frontlineSectors pushBack _x;
		};
	} forEach _markers;

	_frontlineSectors
};

// BFS - Returns nil if no sectors capped yet
BLUFOR_TRAVERSE_CACHE = createHashMap;
NETWORKED_SECTORS_traverseGraphAndFindFirstBluforSector = {
	params ["_startingSector", "_bluforSectors"];

	// When the map first starts there will be no blufor sectors captured, exit out
	// Be sure to use _bluforSectors instead of blufor_sectors public var so any extra provided sectors are processed
	private _numBluforSectors = (count _bluforSectors);
	if(_numBluforSectors == 0) exitWith {
		nil
	};

	private _whatExists = createHashMap;
	private _bluforSectorsAtCache = BLUFOR_TRAVERSE_CACHE getOrDefault ["blufor_sectors", []];
	{
		_whatExists set [_x, true];
	} forEach _bluforSectorsAtCache;
	
	private _valid = true;
	if((count _bluforSectorsAtCache) != _numBluforSectors) then {
		_valid = false;	
	};

	if(_valid) then {
		{
			if(isNil { _whatExists get _x }) exitWith {
				_valid = false;
			};
		} forEach _bluforSectors;
	};

	if(!_valid) then {
		BLUFOR_TRAVERSE_CACHE = createHashMap;
		BLUFOR_TRAVERSE_CACHE set ["blufor_sectors", +_bluforSectors];
	};

	if(_startingSector in BLUFOR_TRAVERSE_CACHE) exitWith {
		BLUFOR_TRAVERSE_CACHE get _startingSector;
	};

	private _networkedSectorData = NETWORKED_SECTORS get _startingSector;
	private _openSet = +(_networkedSectorData get "Links");
	private _visitedSet = createHashMap;

	private _foundSector = nil;
	while { (count _openSet) > 0 } do {
		private _currentNode = _openSet deleteAt 0;
		_visitedSet set [_currentNode, true];

		if(_currentNode in _bluforSectors) exitWith { _foundSector = _currentNode };

		private _data = NETWORKED_SECTORS get _currentNode;
		private _newLinks = _data get "Links";

		{
			if (!(isNil { _visitedSet get _x })) then { continue; };

			_visitedSet set [_x, true];
			_openSet pushBack _x;
		} forEach _newLinks;
	};
	if(!(isNil { _foundSector })) then {
		BLUFOR_TRAVERSE_CACHE set [_startingSector, _foundSector];
	};
	
	_foundSector
};

NETWORKED_SECTORS_traverseGraphAndFindSectorsOfType = {
	params ["_startingSector", "_targetSectorType", "_bluforSectors"];
	
	private _networkedSectorData = NETWORKED_SECTORS get _startingSector;
	private _openSet = +(_networkedSectorData get "Links");
	private _visitedSet = createHashMap;
	private _foundSectors = [];

	while { (count _openSet) > 0 } do {
		private _currentNode = _openSet deleteAt ((count _openSet) - 1);
		_visitedSet set [_currentNode, true];

		if(_currentNode find _targetSectorType >= 0) then {
			_foundSectors pushBack _currentNode;
		};

		private _data = NETWORKED_SECTORS get _currentNode;
		private _newLinks = _data get "Links";

		{
			if(_x in _bluforSectors) then { continue; };
			if (!(isNil { _visitedSet get _x })) then { continue; };

			_visitedSet set [_x, true];
			_openSet pushBack _x;
		} forEach _newLinks;
	};

	_foundSectors
};

NETWORKED_SECTORS_INIT = {
	params ["_forceCacheMiss"];
	private _startTime = diag_tickTime;
	private _cache = profileNamespace getVariable NETWORKED_SECTORS_SAVE_KEY;
	private _cacheValid = !isNil "_cache";
	private _markers = allMapMarkers select { 
		private _marker = _x;

		private _valid = false;
		{
			if((_marker find _x) == 0) exitWith { _valid = true };
		} forEach NETWORKED_SECTORS_MARKER_PREFIXES;

		_valid
	};

	if(_forceCacheMiss) then {
		_cacheValid = false;
	};
	if(_cacheValid) then {
		private _sectors = _cache get "Sectors";
		private _markerCountAtCache = _cache get "MarkerCount";
		private _cachedAutoLinkDistance = _cache getOrDefault ["AutoLinkDistance", 0];
		private _cachedMaxDistance = _cache getOrDefault ["MaxDistance", 0];
		private _cachedGranular = _cache getOrDefault ["GranularlyLinked", false];
		private _cachedExclusion = _cache getOrDefault ["ExclusionRadius", 0];
		private _cachedSlop = _cache getOrDefault ["Slop", 0];

		// Determine if the cache is still valid by checking markers are still the same count
		// Loop through all sectors and make sure all positions are the same
		_cacheValid = ((count _markers) == _markerCountAtCache) && _cachedAutoLinkDistance == NETWORKED_SECTORS_AUTO_LINK_DISTANCE && _cachedMaxDistance == NETWORKED_SECTORS_MAX_DISTANCE && _cachedGranular == NETWORKED_SECTORS_GRANULAR_LINK && _cachedExclusion == NETWORKED_SECTORS_EXCLUSION_DISTANCE && _cachedSlop == NETWORKED_SECTORS_CLOSEST_ROAD_SLOP;

		if(_cacheValid) then {
			{
				private _sectorName = _x;
				private _sectorData = _y;
				private _pos = _y get "Position";

				if (!((getMarkerPos _x) isEqualTo _pos)) exitWith {
					_cacheValid = false;
				};
			} forEach _sectors;
		};
	};
	diag_log format ["Networked Sector Cached %1", _cacheValid];
	systemChat format ["Networked Sector Cached %1", _cacheValid];
	
	// Then we need to reconstruct
	if(!_cacheValid) then {
		diag_log format ["Sector Cache Invalid, reconstructing at %1", diag_tickTime];
		systemChat format ["Sector Cache Invalid, reconstructing at %1", diag_tickTime];
		NETWORKED_SECTORS = createHashMap;
		COST_CACHE = createHashMap;
		// used to keep track of state, enable some optimization.
		private _state = createHashMap;

		// Loop through all sectors and construct a Graph.
		{
			private _links = [_x, _state] call NETWORKED_SECTORS_DETERMINE_LINKS;
		} forEach _markers;

		// Resolve Graph outliers
		// 1. Resolve 'islands'
		// If there are nearby sectors that are not linked and no valid path exists from the current sector's Graph or is too long, then a direct link should be made which should enable it to link islands together. 

		// Loop through all sectors and remove duplicate data
		// We will also resolve Graph outlier 1.
		{
			private _sector = _x;
			private _data = _y;
			private _links = _data get "Links";

			// Loop through nearby sectors
			// 1. Traverse Graph up to a distance of 4 from the current sector. If nearby sector X is not in the list of Nodes that are up to 4 distance away from the current sector, then a valid link is assumed to not exist
			// 2. Further validity checks: Water? Steepness? Etc.. TODO?
			// 3. Add forced link between the two sectors
			diag_log format ["Doing final data validation for sector %1", _x];
			private _nearbySectors = allMapMarkers select { 
				private _marker = _x;
				private _valid = false;
				{
					if((_marker find _x) == 0) exitWith { _valid = true };
				} forEach NETWORKED_SECTORS_MARKER_PREFIXES;
				_valid && ((getMarkerPos _x) distance2D (getMarkerPos _sector)) <= (NETWORKED_SECTORS_MAX_DISTANCE) && _marker != _sector
			};
			{	
				private _isSectorLinked = [_sector, _x, blufor_sectors, 4] call NETWORKED_SECTORS_IS_NODE_WITHIN_DISTANCE_FOR_NODE;
				
				if(!_isSectorLinked) then {
					diag_log format ["  Determined Sector %1 and Target Sector %2 is not properly linked in the Sector Graph, evaluating forced linkage...", _sector, _x];
					// TODO: Additional considerations here
					_links pushBack _x;
					private _targetSectorData = NETWORKED_SECTORS get _x;
					private _targetLinks = _targetSectorData get "Links";
					_targetLinks pushBack _sector;

					_targetSectorData set ["Links", _targetLinks];
					NETWORKED_SECTORS set [_x, _targetSectorData];

					diag_log format ["  Sector %1 and Target Sector %2 force linked", _sector, _x];
				};
			} forEach _nearbySectors;

			_links = _links arrayIntersect _links;
			_links = _links arrayIntersect _markers;

			_data set ["Links", _links];
		} forEach NETWORKED_SECTORS;

		private _count = count _markers;
		private _cacheData = createHashMap;

		_cacheData set ["MarkerCount", _count];
		_cacheData set ["Sectors", NETWORKED_SECTORS];
		_cacheData set ["AutoLinkDistance", NETWORKED_SECTORS_AUTO_LINK_DISTANCE];
		_cacheData set ["MaxDistance", NETWORKED_SECTORS_MAX_DISTANCE];
		_cacheData set ["GranularlyLinked", NETWORKED_SECTORS_GRANULAR_LINK];
		_cacheData set ["ExclusionRadius", NETWORKED_SECTORS_EXCLUSION_DISTANCE];
		_cacheData set ["Slop", NETWORKED_SECTORS_CLOSEST_ROAD_SLOP];

		diag_log format ["Networked Sectors reconstructed at %1", diag_tickTime];
		profileNamespace setVariable [NETWORKED_SECTORS_SAVE_KEY, _cacheData];
		saveProfileNamespace;
	} else {
		NETWORKED_SECTORS = _cache get "Sectors";

		{
			private _sector = _x;
			private _data = _y;
			private _links = _data get "Links";

			_links = _links arrayIntersect _links;
			_links = _links arrayIntersect _markers;
			_data set ["Links", _links];
		} forEach NETWORKED_SECTORS;
	};

	NETWORKED_SECTORS_LINKED = true;

	private _timeElapsed = diag_tickTime - _startTime;

	NETWORKED_SECTOR_LINK_TIME = _timeElapsed;

	publicVariable "NETWORKED_SECTORS";
	publicVariable "NETWORKED_SECTORS_LINKED";
	publicVariable "NETWORKED_SECTOR_LINK_TIME";

	NETWORKED_SECTOR_COST_CACHE = nil;

	diag_log format ["Sector linking complete. Time elapsed %1s", _timeElapsed];
	systemChat format ["Sector linking complete. Time elapsed %1s", _timeElapsed];
};

if(isServer) then {
	[ 
		{
			[false] call NETWORKED_SECTORS_INIT;
		},
		[],
		1
	] call CBA_fnc_waitAndExecute;
};
