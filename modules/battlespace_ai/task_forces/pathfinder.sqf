
QUEUED_PATHFIND_REQUESTS = [];
NEXT_QUEUED_REQUEST = nil;
CALCULATING_PATHFIND_REQUEST = false;
CALCULATING_PATHFIND_START = 0;
QUEUE_PATHFIND_REQUEST = {
	params ["_taskForceName", "_origin", "_destination"];

	private _valid = true;

	{
		if(_taskForceName == (_x#0)) exitWith {
			_x set [1, _origin];
			_x set [2, _destination];
			_valid = false;
		};
	} forEach QUEUED_PATHFIND_REQUESTS;

	if(!_valid) exitWith {};

	QUEUED_PATHFIND_REQUESTS pushBack [_taskForceName, _origin, _destination];
	
};


LAST_PATHFIND_REQUEST = createHashMap;
FULFILL_PATHFIND_REQUESTS = {
	
	// Probably timed out / doesn't work, so we need to somehow break out of it
	if((CBA_missionTime - 10) > CALCULATING_PATHFIND_START) then {
		CALCULATING_PATHFIND_REQUEST = false;
		CALCULATING_PATHFIND_START = CBA_missionTime;
		private _failedReq = QUEUED_PATHFIND_REQUESTS deleteAt 0;

		[_failedReq#0] call BATTLESPACE_TASK_FORCE_PATH_FAILED;
	};
	if (CALCULATING_PATHFIND_REQUEST) exitWith {};
	if ((count QUEUED_PATHFIND_REQUESTS) <= 0) exitWith {};
	// Set that we calculating due to async shit
	CALCULATING_PATHFIND_REQUEST = true;
	CALCULATING_PATHFIND_START = CBA_missionTime;
	
	NEXT_QUEUED_REQUEST = QUEUED_PATHFIND_REQUESTS select 0;

	private _taskForce = BATTLESPACE_TASK_FORCES get (NEXT_QUEUED_REQUEST#0);
	// Insure validity of request
	while { (isNil { _taskForce }) && (count QUEUED_PATHFIND_REQUESTS) > 0 } do {
		NEXT_QUEUED_REQUEST = QUEUED_PATHFIND_REQUESTS deleteAt 0;
		if((count QUEUED_PATHFIND_REQUESTS) <= 0) exitWith {};
		_taskForce = BATTLESPACE_TASK_FORCES get (NEXT_QUEUED_REQUEST#0);
	};
	if((count QUEUED_PATHFIND_REQUESTS) <= 0) exitWith {};

	_taskForce params [
		"_taskForceType", // 0
		"_currentLoc", // 1
		["_destination", []], // 2
		"_composition", // 3
		["_activeGroups", []], // 4
		["_state", []], // 5
		["_taskForceSide", east], // 6
		["_despawnCounter", 0], // 7
		["_activeObjects", []], // 8
		["_wasDespawning", false], // 9
		["_homePoint", []] // 10
	];
	_state params ["_status", ["_currentPathIndex", 0], ["_failureCounts", 0]];
	// If failure counts are too high, try to use "man" instead
	private _pathFindClass = "wheeled_APC";
	if(_failureCounts > 1) then {
		_pathFindClass = "man";
	};
	private _vehicles = _composition getOrDefault ["vehicles", []];
	private _vehs = count (_vehicles);

	private _offset = [0,0,0];
	private _air = 0;
	if(_vehs <= 0) then { 
		_pathFindClass = "man";
	} else {
		{
			if(_x isKindOf "Air") then {
				_air = _air + 1;
			};
		} forEach _vehicles;
	};
	
	NEXT_QUEUED_REQUEST params ["_taskForceName", "_origin", "_destination"];
	
	if((_origin distance2D _destination) <= 200 || _air >= _vehs || _failureCounts >= -1) exitWith {
		QUEUED_PATHFIND_REQUESTS deleteAt 0;
		[_taskForceName, [_destination]] call BATTLESPACE_TASK_FORCE_PATH_FOUND;
		CALCULATING_PATHFIND_REQUEST = false;
	};
	diag_log format ["Fulfill Pathfind Requests (%1): Task Force %2; %3", diag_tickTime, _taskForceName, diag_fps];

	private _agent = calculatePath [_pathFindClass, "SAFE", _origin, _destination];
	_agent addEventHandler ["PathCalculated", {

		
		CALCULATING_PATHFIND_REQUEST = false;
		
		if((count (_this#1)) == 2) exitWith { 
			
			[NEXT_QUEUED_REQUEST#0] call BATTLESPACE_TASK_FORCE_PATH_FAILED;
			
		
		};

		QUEUED_PATHFIND_REQUESTS deleteAt 0;
		
		private _path = _this#1;

		
		
		
		private _oldCount = count _path;
		_path = _path arrayIntersect _path;
		if((count _path) != _oldCount) exitWith {
			diag_log format ["Path contained duplicate, potentially not valid?"];
		};

		
		[NEXT_QUEUED_REQUEST#0, _this#1] call BATTLESPACE_TASK_FORCE_PATH_FOUND;

	}];
};

if (isServer) then {
	[
		{ _this call FULFILL_PATHFIND_REQUESTS },
		1,
		[]
	] call CBA_fnc_addPerFrameHandler;
};
