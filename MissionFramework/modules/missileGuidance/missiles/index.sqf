IADS_Missiles = createHashMap;
IADS_AmmoToMissile = createHashMap;


IADS_RegisterAmmo = {
	params ["_ammoName", "_missileName"];

	IADS_AmmoToMissile set [_ammoName, _missileName]
};


// TODO:
// Refactor seeker options into new seeker head code similar to ACE3's missile guidance fork
IADS_RegisterNewMissileClass = {
	params ["_missileName", "_seekerName", "_fuzeCode", "_guidancePhases", "_seekerPerformance", "_flightParams", ["_ammosToAdd", []], ["_verticallyLaunched", false]];


	IADS_Missiles set [_missileName, [_seekerName, _fuzeCode, _guidancePhases, _seekerPerformance, _flightParams, _verticallyLaunched]];

	{
		[_x, _missileName] call IADS_RegisterAmmo;
	} forEach _ammosToAdd;
};



IADS_HookGuidanceLogic = {
	params ["_missileType", "_missile", "_target", "_launchVehicle", "_launcher"];

	private _missileParams = IADS_Missiles getOrDefault [_missileType, [{}, {}, [], [], []]];


	_missileParams params ["_seekerName", "_fuzeCode", "_guidancePhases", "_seekerPerformance", "_flightParams", "_verticallyLaunched"];

	if(_verticallyLaunched) then {
		_missile setDir (_missile getDir _target);
		[_missile, 90, 0] call BIS_fnc_setPitchBank;
	};

	private _seekerHead = IADS_Seekers get _seekerName;
	private _missileID = [_missileType, _missile] call IADS_RegisterNewMissile;
	
	if(!(isNil "_missileID")) then {
		[
			IADS_GuidanceComputer,
			0, 
			[
				_guidancePhases,
				_seekerHead,
				_fuzeCode,
				_missileID,
				_missile,
				_flightParams,
				_seekerPerformance,
				_target,
				_launchVehicle
			]
		] call CBA_fnc_addPerFrameHandler;

		private _missileList = _target getVariable ["missileList", []];

		_missileList pushBack _missileID;

		_target setVariable ["missileList", _missileList, true];

		if(!(isNull _launchVehicle)) then {

			[_missile, _launchVehicle] remoteExecCall ["disableCollisionWith", 0];
			private _currentVelocity = velocity _launchVehicle;

			_missile setVelocity _currentVelocity;
		
			
		};
	};
};

([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\fim92.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\sa18.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\sa24.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\sa15.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\aim9x.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\aim9m.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\aim120.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\sa6.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\sa20.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\patriot.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\essm.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\tamir.sqf");