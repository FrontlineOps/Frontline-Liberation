// Due to nature of missiles only work to whoever is local, this code must run for everyone so SAMs can work properly across multitude of clients.
// However a minor optimization can happen which is having a polling rate, and a early terminate condition.
// Since the code is shared, there shouldn't be much desync across the networked environment as the only thing that would fire is the  closest launch vehicle with ammo in range
IADS_Sweep = {
	(_this select 0) params [
		["_nextSweep", 0],
		["_lastTracks", 0]	
	];

	
	
	if(accTime <= 0 || isGamePaused) exitWith {};
	if(_nextSweep > CBA_missionTime) exitWith {
		if(((IADS_SAM_DEBUG == true) || (IADS_FCR_DEBUG == true))) then {

			{
				private _track = nil;

				_x params ["_threat", "_lastTime"];

				if(_lastTime < 0) then {
					continue;
				};

				{
					if((_x get "Entity") isEqualTo _threat) exitWith {
						_track = _x;
					};
				} forEach IADS_Tracks;
					

				private _pos = ASLToAGL getPosASLVisual _threat;
				private _color = [0,0,0,1];

				if(!(isNil "_track")) then {
					private _rank = _track getOrDefault ["rank", 10];


					
					private _isOrdinance = [typeOf _threat] call IADS_IsOrdinance;

					private _div = 8;

					if(_isOrdinance) then { _div = 2; };
					_color set [0, 1 - (_rank / _div)];
					_color set [1, (_rank / _div)];
			
					drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", _color, _pos vectorAdd [0,0,20], 0.75, 0.75, 0, format ["RANK %1", _rank], 1, 0.025, "TahomaB"];

					drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", _color, _pos, 0.75, 0.75, 0, format ["%1 - %2", typeOf (_track get "Entity"), _track get "Count"], 1, 0.025, "TahomaB"];

					private _pip = _track get "pip";

					if(!isNil "_pip") then {

						drawLine3D [ASLToAGL getPosASLVisual _threat, _pip, [1,0,0,1]];
						drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", _color, _pip, 0.75, 0.75, 0, format ["PIP"], 1, 0.025, "TahomaB"];
					};

					drawLine3D [ASLToAGL getPosASLVisual _threat, (ASLToAGL getPosASLVisual _threat) vectorAdd (vectorDir _threat vectorMultiply 100), [0,0,1,1]];
				} else {
					_color set [2, 1];


					
					drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", _color, _pos, 0.75, 0.75, 0, format ["%1", typeOf _threat], 1, 0.025, "TahomaB"];
				};

			

		

			} forEach (listRemoteTargets east + listRemoteTargets west);
		};
	};
	IADS_LaunchersUsedThisFrame = []; 
	(_this select 0) set [0, CBA_missionTime + 1];
	private _uniques = [];

	private _removes = [];

	private _hasOne = false;
	{
		if((local _x) && (alive _x)) then {
			_hasOne = true;
		};
	} forEach IADS_LaunchVehicles;
	
	if(!_hasOne) exitWith {
		IADS_Tracks = [];
	};

	

	{

		if(!(alive _x) || isNull (_x)) then {
			_removes pushBack _x;
		};
		private _remoteTargets = listRemoteTargets (side group _x);
	
		

		private _radar = _x;

		{

			_x params ["_potentialTarget", "_detectionTime"];
			if(!(alive _potentialTarget)) then {
				continue;
			};

			if(!(_potentialTarget isKindOf "Air")) then {
				continue;
			};

			
			

			private _distance = _radar distance2D _potentialTarget;
			private _type = typeOf _potentialTarget;
			private _isMissile = [_type] call IADS_IsOrdinance;
			// TODO: Better target prediction to enable point defense

			if(unitIsUAV _potentialTarget) then {

				if(_distance > 5750) then {
					continue;
				};
			};
			
			private _timer = 0;
		
			if(!(_isMissile)) then {
				_timer = 7;
			};
			if(_detectionTime <= _timer) then {
				continue;
			};
			
			

			private _distRange = 40000;

			if(_isMissile) then {

				_distRange = 40000;
			};
			if(_distance > _distRange) then {
				continue;
			};
			
			private _adjustedPos = getPosASLVisual _potentialTarget;
			// 0.45 deg downwards if theres a terrain intersection theres clutter.

			private _sinDeg = 0.00785390088;

			if(_type == "ITC_Land_B_UAV_AR2i") then {
				// 0.7deg
				_sinDeg = 0.01221700083;
			};
			_adjustedPos = _adjustedPos vectorAdd [0, 0, _distance * -1 * _sinDeg];
			private _terrainIntersection = terrainIntersectASL [(getPosASLVisual _radar vectorAdd [0,0,4]), _adjustedPos];

			if(_terrainIntersection) then {
				continue;
			};

			
			private _isEnemy = [side group _radar, side group _potentialTarget] call BIS_fnc_sideIsEnemy;

	
			if(!_isEnemy) then {
				continue;
			};

			_uniques pushBack _potentialTarget;
		} forEach _remoteTargets;



	} forEach IADS_SearchRadars;


	_uniques = _uniques arrayIntersect _uniques;






	IADS_SearchRadars = IADS_SearchRadars - _removes;

	IADS_Tracks = IADS_Tracks select {
		private _lastTime = _x getOrDefault ["LastTime", 0];

		((CBA_missionTime - _lastTime) <= 5) 
	};
	
	// TODO: Rank by threats for fire order


	private _systemsWithIDFIncoming = [];

	_uniques = [_uniques, [], {

		private _threatRank = 40000;

		private _realDist = 40000;

		private _threat = _x;

		
		// TODO: This only works for 2 concurrent IADS. Does not work with 3.
		private _hostileSystems = (IADS_LaunchVehicles + IADS_SearchRadars) select {
			[side group _x, side group _threat] call BIS_fnc_sideIsEnemy
		};
		private _type = typeOf _threat;

		// If artillery, we predict an impact point and assign a threat rank off of that.
		// Otherwise aircraft is a threat rank based on distance
		// TODO: other factors like speed, aspect.
		// Don't need to evaluate for missiles because they get filtered if they aren't proper aspect
		private _isRAM = [_type] call IADS_IsArtilleryOrdinance;

		private _track = nil;
		{
			if((_x get "Entity") isEqualTo _threat) exitWith {
				_track = _x;
			};
		} forEach IADS_Tracks;

		{

			private _dist = (_x distance2D _threat) / 1000;

			if(_dist < _threatRank) then {
				_threatRank = _dist;
				_realDist = _x distance _threat;
			};
		} forEach _hostileSystems;


		if(_isRAM) then {

		
			
			private _pip = _track get "pip";
			private _tof = _track get "tof";

			if(!(isNil "_pip")) then {
				// Calculate impact point
				{
					private _dist = (_pip distance2D _x) / 1000;

					if(_dist < _threatRank) then {
						_threatRank = _dist;
					};	


					if(_dist <= 1.5) then {
						if((typeOf _x) in IADS_SearchRadarClasses) then {
							_systemsWithIDFIncoming pushBack _x;
						};
					}
				} forEach _hostileSystems;
	
				
			};
				
			[_threat, _track] spawn {
				_this params ["_threat", "_track"];

				private _pip = [_threat] call IADS_CalculateImpactPoint;

				if(!isNil "_track") then {
					_track set ["pip", _pip#0];
					_track set ["tof", _pip#1];
				};
			};

			// Only a threat if it lands close to positions that are hostile to the threat.
			// Threats are always hostile to something, but ranking needs to be based on to hostile IADS, not everything or else unexpected behavior.
			
		

		};

	

		


		if(!(isNil "_track")) then {
			_track set ["rank", _threatRank];
			_track set ["threatDistanceToClosestSystem", _realDist];
		};
		
		

		_threatRank
	}, "ASCEND", {

		private _threat = _x;

		private _isRAM = [_type] call IADS_IsArtilleryOrdinance;
		private _isOrdinance = [_type] call IADS_IsOrdinance;
		private _isMissile = (_isOrdinance && !_isRAM);

		if(_isMissile) exitWith {
			private _hostileSystems = (IADS_LaunchVehicles + IADS_SearchRadars) select {
				[side group _x, side group _threat] call BIS_fnc_sideIsEnemy
			};
			private _hotAspect = false;
			{
				private _los = (getPosASLVisual _x) vectorDiff (getPosASLVisual _threat);
				private _threatVelocity = velocity _threat;

				_los = vectorNormalized _los;
				_threatVelocity = vectorNormalized _threatVelocity;

				private _likeness = _threatVelocity vectorCos _los;

				if(_likeness >= 0.97) exitWith {
					_hotAspect = true;
				};
			} forEach _hostileSystems;

			_hotAspect
		};
		true
	}] call BIS_fnc_sortBy;


	{


		private _type = typeOf _x;
		// TODO: Remove this for point defense, however must be combined with more intelligent state tracking to determine if its a true threat or not to waste a missile on.

		private _track = nil;
		private _potentialTarget = _x;
		{
			if((_x get "Entity") isEqualTo _potentialTarget) exitWith {
				_track = _x;
			};
		} forEach IADS_Tracks;


		if(isNil "_track") then {
			_track = createHashMap;

			_track set ["Entity", _potentialTarget];

			IADS_Tracks pushBack _track;

			[_potentialTarget] remoteExec ["IADS_NewThreat", 0];
		};

		private _trackCount = _track getOrDefault ["Count", 0];
		private _trackLastTime = _track getOrDefault ["LastTime", CBA_missionTime];

		_trackCount = _trackCount + 1;

		_trackLastTime = CBA_missionTime;

		
		_track set ["LastTime", _trackLastTime];
		private _isOrdinance = [_type] call IADS_IsOrdinance;

		private _isRAM = [_type] call IADS_IsArtilleryOrdinance;
		private _trackThreatRank = _track getOrDefault ["rank", 10];

		if(_trackThreatRank >= 9.1 && !_isOrdinance) then {
			_trackCount = 0;
		};
		_track set ["Count", _trackCount];

		private _threatRankForLaunch = 8;

		

		if(_isOrdinance) then {
			_threatRankForLaunch = 16;
		};
		if(_isRAM) then {
			_threatRankForLaunch = 0.8;
			
		};

		private _inDistance = (_trackThreatRank <= _threatRankForLaunch) || (_trackCount >= 8 && !_isRAM);
		private _canLaunch = false;
		
		if(_inDistance) then {
			_canLaunch = ((_isRAM == true) && (_trackCount >= 1)) || (_trackCount >= 5) || (_isOrdinance && _trackCount >= 2);
		};



		
		if(_canLaunch == true) then {

			_queuedFire = true;
			[_x] call IADS_QueueFire;		
		};
		// For RWR info
		_x setVariable ["TrackData", _track, true];

		_track set ["lastRank", _trackThreatRank];
	} forEach _uniques;


	_systemsWithIDFIncoming = _systemsWithIDFIncoming arrayIntersect _systemsWithIDFIncoming;

	{
		private _lastPlay = _x getVariable ["sirenPlayTime", 0];
		if((CBA_missionTime - _lastPlay) >= 6.8) then {
			playSound3D [getMissionPath "res\idf.ogg", _x, false, getPosASLVisual _x, 4, 1, 2000];
			_x setVariable ["sirenPlayTime", CBA_missionTime, true];
		};
	} forEach _systemsWithIDFIncoming;


	
	if(IADS_SAM_DEBUG == true) then {

			{
			private _track = _x;

			private _pos = ASLTOAGL getPosASLVisual (_x get "Entity");
			private _rank = _x getOrDefault ["rank", 10];


			private _color = [0,0,0,1];
			
			private _isOrdinance = [typeOf (_x get "Entity")] call IADS_IsOrdinance;

			private _div = 8;

			if(_isOrdinance) then { _div = 2; };
			_color set [0, 1 - (_rank / _div)];
			_color set [1, (_rank / _div)];
		
			drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", _color, _pos vectorAdd [0,0,20], 0.75, 0.75, 0, format ["RANK %1", _rank], 1, 0.025, "TahomaB"];
			drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", _color, _pos, 0.75, 0.75, 0, format ["%1 - %2", typeOf (_x get "Entity"), _x get "Count"], 1, 0.025, "TahomaB"];
		} forEach IADS_Tracks;
	};


};

