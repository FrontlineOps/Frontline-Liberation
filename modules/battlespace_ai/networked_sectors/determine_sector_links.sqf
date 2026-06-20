
highest_cost = 0;
RENDER_IN_DEPTH_LINKS = false;
RENDER_LINKS = false;
RENDER_NETWORK_PFH = {
	if(!RENDER_NETWORK) exitWith {
		[_this select 1] call CBA_fnc_removePerFrameHandler;
	};

	if(accTime <= 0 || isGamePaused) exitWith {};

	if(isNil "NETWORK_MARKER_CACHE") then {
		NETWORK_MARKER_CACHE = createHashMap;
	};
	if(isNil "blufor_sectors") exitWith {};


	private _cacheThisFrame = createHashMap;

	{

		private _sector = _x;


		if(isNil "_sector") then { continue };

		

		private _data = _y;

		private _links = _y get "Links";


		private _roadObj = NETWORK_MARKER_CACHE get _x;

		if(isNil "_roadObj") then {
			_roadObj = [getMarkerPos _x, NETWORKED_SECTORS_CLOSEST_ROAD_SLOP] call BIS_fnc_nearestRoad;
			NETWORK_MARKER_CACHE set [_x, _roadObj];
		};

		

		private _cost = [_sector, blufor_sectors] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;

		
		if(_cost > highest_cost) then { highest_cost = _cost };
		

		private _center = (getMarkerPos _x) vectorAdd [0,0,100];

		private _centerInScreen = worldToScreen _center;

		if(_centerInScreen isEqualTo []) then {
			continue;
		};
		private _cap = (highest_cost / 4);
			
		private _color = [1 - ([0, 0.25] select (_cost > 0)),_cost / _cap + ([0, 0.25] select (_cost > 0)),0,1];

		if(_cost > (highest_cost / 4)) then {

			_color = [1 - (_cost / (highest_cost)),1,0,1];
		};

		if(_cost > (highest_cost / 2)) then {
			_color = [0,1,0,1];
		};

		if(_cost <= -1) then {
			_color = [0,0,1,1];
		};
		
		drawIcon3D ["\A3\ui_f\data\map\markers\military\flag_CA.paa", _color, _center, 1, 1, 0, format ["%1 | %2",markerText _x, _cost], 1, 0.03, "TahomaB"];
		drawLine3D [_center, (getPosVisual _roadObj), [0,0,1,1]];

		
		private _linksDrawn = (_cacheThisFrame getOrDefault [_x, createHashMap]);
		if (RENDER_LINKS) then {
			drawIcon3D ["\A3\ui_f\data\map\groupicons\waypoint.paa", [0,0,1,1], (getPosVisual _roadObj), 0.6, 0.6, 0, _x, 1, 0.0225, "TahomaB"];
			{

				
				
				private _dir = _center vectorFromTo (getMarkerPos _x);

				private _dist = (_center distance2D (getMarkerPos _x));

				_dir set [2, 0];
				drawLine3D [_center, _center vectorAdd (_dir vectorMultiply _dist), [1,0,0,1]];
				private _multi = 300;
				if(_dist < 300) then {
					_multi = 100;
				};

				if(_dist < 100) then {
					_multi = 50;
				};
				drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [0,1,0,1], _center vectorAdd (_dir vectorMultiply (_multi)), 0.6, 0.6, 0, markerText _x, 1, 0.0225, "TahomaB"];

				private _drawnThis = _linksDrawn getOrDefault [_x, false];

				if(_drawnThis) then {
					continue;
				};

				_linksDrawn set [_x, true];

				private _targetCache = _cacheThisFrame getOrDefault [_x, createHashMap];

				_targetCache set [_sector, true];
				
				_cacheThisFrame set [_x, _targetCache];

				if(RENDER_IN_DEPTH_LINKS) then {

					private _loops = 20;

					private _interval = _dist / _loops;


					for "_i" from 1 to (_loops - 1) do {
						private _pos = _center vectorAdd (_dir vectorMultiply (_i * _interval));
						private _inScreen = worldToScreen _pos;

						if(_inScreen isEqualTo []) exitWith {};
						drawIcon3D ["\a3\UI_F_Enoch\Data\CfgMarkers\dot1_ca.paa", [1,0,0,1], _pos, 0.5, 0.5, 0, "", 1, 0.02, "TahomaB"];
					};
				};
			
				
			} forEach _links;
		};

		_cacheThisFrame set [_x, _linksDrawn];

	} forEach NETWORKED_SECTORS;


};
// Distance where we just auto link due to the extreme close proximity
NETWORKED_SECTORS_AUTO_LINK_DISTANCE = 400;
// Max distance to consider sectors at. Too high and it'll take an extremely long time to index, especially as certain locations can traverse extremely large road lengths depending on layout.
NETWORKED_SECTORS_MAX_DISTANCE = 3500;
// Consider roads that are much more in-depth. Takes significantly longer if enabled but will fix some weird issues where some points don't get linked properly due to missing segments of road.
NETWORKED_SECTORS_GRANULAR_LINK = true;
// When a sector has already been evaluated, it has an exclusion radius that would prevent links from being formed if the calculated path goes through the radius.
NETWORKED_SECTORS_EXCLUSION_DISTANCE = 250;

// Slop for finding nearest road for a sector 

NETWORKED_SECTORS_CLOSEST_ROAD_SLOP = 600;
NETWORKED_SECTORS_DETERMINE_LINKS = {

	params ["_center", "_state"];

	private _startTime = diag_tickTime;

	private _links = [];

	private _otherNodeCenters = createHashMap;

	private _amountShortcutted = 0;

	private _markers = allMapMarkers select { 
		private _marker = _x;
		private _valid = false;
		{
			if((_marker find _x) == 0) exitWith { _valid = true };
		} forEach NETWORKED_SECTORS_MARKER_PREFIXES;
		_valid && ((getMarkerPos _x) distance2D (getMarkerPos _center)) <= NETWORKED_SECTORS_MAX_DISTANCE && _marker != _center
	};

	private _otherNodeCenterMarkers = [];
	private _sortedMarkers = [
		_markers,
		[_center],
		{
			private _center = _input0;


			(getMarkerPos _center) distance2D (getMarkerPos _x)

		},
		"ASCEND"
	] call BIS_fnc_sortBy;

	NETWORK_MARKER_CACHE = createHashMap;

	private _linkedTo = createHashMap;
	{
		// Check if this marker had been visited before.
		// If our center had been visited before, then it contains an array of previous points that had visited and linked to it already.
		// Shortcut and add the linked nodes immediately and not run an expensive op.
		private _existing = _state getOrDefault [_center, []];

		private _existingFallbacks = _state getOrDefault [format ["%1_fallback", _center], []];

		private _roadObj = NETWORK_MARKER_CACHE get _x;

		if(isNil "_roadObj") then {
			_roadObj = [getMarkerPos _x, NETWORKED_SECTORS_CLOSEST_ROAD_SLOP] call BIS_fnc_nearestRoad;
			NETWORK_MARKER_CACHE set [_x, _roadObj];
		};
		// If this node has already been visited before 
		if(_x in _existing) then {
			diag_log format ["%1 was already visited by %2 previously, shortcutting", _center, _x];
			_otherNodeCenters set [str _roadObj, _x];
			_otherNodeCenterMarkers pushBack _x;
			continue;
		};
		// If this node has already been assigned before with simple radius add
		if(_x in _existingFallbacks) then {
			// So we can fallback to radius add if all the points being added are from shortcutting and no new paths..
			diag_log format ["%1 was visited by %2 previously as a fallback simple radius addition, shortcutting", _center, _x];
			_otherNodeCenterMarkers pushBack _x;
			_amountShortcutted = _amountShortcutted + 1;
			continue;
		};

		private _dist = (getMarkerPos _center) distance2D (getMarkerPos _x);

		private _centerRoad = NETWORK_MARKER_CACHE get _center;

		if (isNil "_centerRoad") then {
			_centerRoad = [getMarkerPos _center, NETWORKED_SECTORS_CLOSEST_ROAD_SLOP] call BIS_fnc_nearestRoad;

			NETWORK_MARKER_CACHE set [_center, _centerRoad];
		};

		

		private _distBetweenRoads = (getPos _centerRoad) distance2D (getPos _roadObj);

		_dist = _dist min _distBetweenRoads;

		private _distFromCenterMarkerToTargetRoad = (getMarkerPos _center) distance2D (getPos _roadObj);

		_dist = _dist min _distFromCenterMarkerToTargetRoad;

		private _distFromCenterRoadToTargetMarker = (getPos _centerRoad) distance2D (getMarkerPos _x);

		_dist = _dist min _distFromCenterRoadToTargetMarker;
		
		if(_dist <= NETWORKED_SECTORS_AUTO_LINK_DISTANCE) then {

			if(!isNull _roadObj) then {
				_otherNodeCenters set [str _roadObj, _x];
			};
			_otherNodeCenterMarkers pushBack _x;
			continue;
		};
		([getMarkerPos _center, getMarkerPos _x, nil, true] call A_STAR) params ["_path", "_time"];
		private _invalid = false;
		if((count _path) <= 0) then {
			_invalid = true;
			continue;
		};
		systemChat format ["%1 evaluating path to %2, returned %3", _center, _x, count _path];
		if((count _path) > 0) then {
			{

				private _obj = _x get "RoadObject";
				

				if(!isNil {_otherNodeCenters get (str _obj) }) exitWith {
					_invalid = true;
				};

				{

					
					private _distance = getPos _obj distance2D (getMarkerPos _x);

					private _otherRoadObj = NETWORK_MARKER_CACHE get _x;

					if(isNil "_otherRoadObj") then {
						_otherRoadObj = [getMarkerPos _x, NETWORKED_SECTORS_CLOSEST_ROAD_SLOP] call BIS_fnc_nearestRoad;
						NETWORK_MARKER_CACHE set [_x, _otherRoadObj];
					};

					private _distanceToMarkerRoad = (getPos _obj) distance2D (getPos _otherRoadObj);

					_distance = _distance min _distanceToMarkerRoad;
					
					if(_distance <= NETWORKED_SECTORS_EXCLUSION_DISTANCE) exitWith {
						_invalid = true;
					};
				} forEach _otherNodeCenterMarkers;

				if(_invalid) exitWith {};
			} forEach _path;

			if(!_invalid) then {

				_otherNodeCenters set [str _roadObj, _x];
				_otherNodeCenterMarkers pushBack _x;

				// From center to _x, its valid. So check if _x is defined in linkedTo.
				// If defined, push our marker to it for some better optimization?

				private _targetExisting = _state getOrDefault [_x, []];

				_targetExisting pushBack _center;

				_state set [_x, _targetExisting];

				private _targetData = NETWORKED_SECTORS get _x;

				if(!isNil "_targetData") then {

					private _targetLinks = _targetData get "Links";

					_targetLinks pushBack _center;

					_targetData set ["Links", _targetLinks];
				};
			};
		};
		
	} forEach _sortedMarkers;

	{
		_links pushBack _x;
	} forEach _otherNodeCenterMarkers;

	

	// Fallback to basic radius addition
	// 1. This node has been visited by all its neighbors already
	// 2. This node could not find any valid connections and should attempt basic addition through plain radius
	if(_amountShortcutted == (count _links)) then {
		
		diag_log format ["!!!! %1 only contained shortcutted links or no links: %2, falling back to simple radius addition for additional !!!!", _center, _links];
		private _nearbySectors = allMapMarkers select { 
			private _marker = _x;
			private _valid = false;
			{
				if((_marker find _x) == 0) exitWith { _valid = true };
			} forEach NETWORKED_SECTORS_MARKER_PREFIXES;
			_valid && ((getMarkerPos _x) distance2D (getMarkerPos _center)) <= (NETWORKED_SECTORS_MAX_DISTANCE) && _marker != _center
		};
		{
			// Prevent duplicates
			if(_x in _links) then { continue; };
			private _targetExisting = _state getOrDefault [format ["%1_fallback", _x], []];

			_targetExisting pushBack _center;

			_state set [format ["%1_fallback", _x], _targetExisting];

			private _targetData = NETWORKED_SECTORS get _x;

			if(!isNil "_targetData") then {

				private _targetLinks = _targetData get "Links";

				_targetLinks pushBack _center;

				_targetData set ["Links", _targetLinks];
			};

			_links pushBack _x;
		} forEach _nearbySectors;
	};
	diag_log format ["%1 links evaluated, %2, time elapsed %3", _center, _links, diag_tickTime - _startTime];
	systemChat format ["%1 links evaluated, %2, time elapsed %3", _center, _links, diag_tickTime - _startTime];
	NETWORKED_SECTORS set [
		_center,
		createHashMapFromArray [
			["Position", getMarkerPos _center],
			["Links", _links]
		]
	];
	[_links, (diag_tickTime - _startTime)]
};
